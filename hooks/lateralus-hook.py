#!/usr/bin/env python3
"""
lateralus PostToolUse hook.

Fires after every Claude Code tool call. Tracks failure signatures across
edit attempts and nudges the lateralus skill when the same root failure
recurs — converting "did the agent notice it's stalled?" into a deterministic
counter crossing a threshold.

State file: ~/.claude/lateralus-state.json (keyed by session_id)
Threshold:  LATERALUS_THRESHOLD env var, default 2

Hook flow:
  Edit/Write/Create  → mark edit_since_last = True for all tracked signatures
  Bash (exit 0)      → clear session failure state (stall resolved)
  Bash (exit != 0)   → normalize error signature, increment if edit happened,
                        exit 2 with nudge message when count >= threshold
  All other tools    → pass through (exit 0)

Signature normalization strips: line numbers, file paths, timestamps,
hex addresses, long hashes. Keeps the semantic shape of the error.
Two different stack traces from the same root cause collapse to the same hash.
Too many false positives → tighten the strip regexes.
Too many misses → loosen them or lower the threshold.
"""

import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────────

def _safe_int(val: str | None, default: int) -> int:
    try:
        return int(val)  # type: ignore[arg-type]
    except (ValueError, TypeError):
        return default

THRESHOLD = _safe_int(os.environ.get("LATERALUS_THRESHOLD"), 2)
CLAUDE_DIR = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude"))
STATE_FILE = CLAUDE_DIR / "lateralus-state.json"
SESSION_TTL_HOURS = 24  # prune sessions not seen in this window

EDIT_TOOLS = {"Edit", "Write", "Create", "MultiEdit", "NotebookEditCell"}
BASH_TOOLS = {"Bash"}
# Known limitation: failures surfaced via MCP or custom lint tools are not tracked.

# ── Signature normalization ───────────────────────────────────────────────────

def normalize(text: str) -> str:
    """
    Strip volatile tokens from error output and return a 12-char hex hash.

    Goal: two different-looking stack traces from the same root cause
    should produce the same hash. Two genuinely different failures
    should not collide.

    Tune the strip rules here if the hook over- or under-triggers.
    """
    # Use last 30 lines, not first 20.
    # JVM / PySpark / Py4J tracebacks bury the real exception at the bottom;
    # the first 20 lines are often identical boilerplate for different root causes.
    lines = text.strip().splitlines()
    text = "\n".join(lines[-30:])

    # Line numbers: :42:  line 42  L42  #42
    text = re.sub(r":\d+:", ":N:", text)
    text = re.sub(r"\bline \d+\b", "line N", text, flags=re.IGNORECASE)
    text = re.sub(r"\bL\d+\b", "LN", text)
    text = re.sub(r"#\d+\b", "#N", text)

    # Absolute file paths — keep basename only
    text = re.sub(r"(?:/[^\s:\"'()\[\]]+/)+([^\s:/\"'()\[\]]+)", r"<path>/\1", text)
    text = re.sub(r"(?:[A-Za-z]:\\[^\s:\"'()\[\]]+\\)+([^\s:\\\"'()\[\]]+)", r"<path>/\1", text)

    # Timestamps (ISO 8601 and common log formats)
    text = re.sub(
        r"\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?",
        "<ts>", text,
    )
    text = re.sub(r"\b\d{2}:\d{2}:\d{2}(?:\.\d+)?\b", "<ts>", text)

    # Hex addresses and long commit/content hashes
    text = re.sub(r"\b0x[0-9a-fA-F]{4,}\b", "<addr>", text)
    text = re.sub(r"\b[0-9a-f]{7,64}\b", "<hash>", text)

    # Process IDs and port numbers in context
    text = re.sub(r"\bpid[= ]\d+\b", "pid=N", text, flags=re.IGNORECASE)
    text = re.sub(r"\bport[= ]\d+\b", "port=N", text, flags=re.IGNORECASE)

    # Collapse whitespace
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)

    return hashlib.sha256(text.strip().encode()).hexdigest()[:12]


# ── State helpers ─────────────────────────────────────────────────────────────

def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return {}


def save_state(state: dict) -> None:
    # Prune sessions not active in the last SESSION_TTL_HOURS to keep the file bounded.
    cutoff = datetime.now(timezone.utc) - timedelta(hours=SESSION_TTL_HOURS)
    pruned = {}
    for sid, sdata in state.items():
        sigs = sdata.get("signatures", {})
        # Keep session if any signature was seen recently
        keep = any(
            _parse_ts(sd.get("last_seen")) > cutoff
            for sd in sigs.values()
            if sd.get("last_seen")
        )
        # Only keep sessions with active (non-empty) signatures seen recently.
        # Sessions cleared by a successful Bash run (sigs == {}) are dropped — they
        # have no useful state and would accumulate indefinitely otherwise.
        if keep:
            pruned[sid] = sdata
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(json.dumps(pruned, indent=2))
    except Exception:
        pass  # non-fatal; stale state is harmless, write errors should not disrupt tool flow


def _parse_ts(ts: str) -> datetime:
    try:
        return datetime.fromisoformat(ts).replace(tzinfo=timezone.utc)
    except Exception:
        return datetime.min.replace(tzinfo=timezone.utc)


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    try:
        event = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    session_id = event.get("session_id", "unknown")
    tool_name = event.get("tool_name", "")

    state = load_state()
    session = state.setdefault(session_id, {"signatures": {}})

    # ── Edit/Write/Create: mark that a genuine fix attempt happened ───────────
    if tool_name in EDIT_TOOLS:
        for sig_data in session.get("signatures", {}).values():
            sig_data["edit_since_last"] = True
        save_state(state)
        sys.exit(0)

    # ── Non-Bash tools: ignore ────────────────────────────────────────────────
    if tool_name not in BASH_TOOLS:
        sys.exit(0)

    response = event.get("tool_response", {})
    if not isinstance(response, dict):
        sys.exit(0)

    try:
        exit_code = int(response.get("exit_code") or 0)
    except (ValueError, TypeError):
        exit_code = 0

    # ── Success: clear failure state (stall resolved) ─────────────────────────
    if exit_code == 0:
        session["signatures"] = {}
        save_state(state)
        sys.exit(0)

    # ── Failure: extract error text ───────────────────────────────────────────
    stderr = (response.get("stderr") or "").strip()
    stdout = (response.get("stdout") or "").strip()
    error_text = stderr if stderr else stdout

    if not error_text:
        sys.exit(0)

    signature = normalize(error_text)
    sigs = session.setdefault("signatures", {})
    sig_data = sigs.setdefault(signature, {"count": 0, "edit_since_last": False})

    # Only increment when a real edit happened since the last failure.
    # First occurrence always counts (seeds the counter).
    # If the signature last fired > SESSION_TTL_HOURS ago, treat as a new stall.
    now = datetime.now(timezone.utc)
    last_seen = _parse_ts(sig_data.get("last_seen", ""))
    stale = (now - last_seen) > timedelta(hours=SESSION_TTL_HOURS)

    if sig_data["count"] == 0 or sig_data["edit_since_last"] or stale:
        if stale:
            sig_data["count"] = 1  # reset — different stall window
        else:
            sig_data["count"] += 1
        sig_data["edit_since_last"] = False
        sig_data["last_seen"] = now.isoformat()

    count = sig_data["count"]
    save_state(state)

    if count >= THRESHOLD:
        print(
            f"[lateralus] Failure signature {signature!r} has recurred {count}x "
            f"after edit attempts — this loop is stalled. "
            f"Invoke the lateralus skill before making another fix attempt.",
            file=sys.stderr,
        )
        sys.exit(2)


if __name__ == "__main__":
    main()
