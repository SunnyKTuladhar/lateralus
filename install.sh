#!/usr/bin/env bash
# lateralus — install script
#
# Copies lateralus skills and agents into your Claude Code config directory.
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.sh | bash
#
# Local clone:
#   bash install.sh

set -euo pipefail

REPO="SunnyKTuladhar/lateralus"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

SKILLS=(
  "skills/lateralus/SKILL.md:lateralus"
  "skills/lateralus-brainstorm/SKILL.md:lateralus-brainstorm"
)
AGENTS=(
  "agents/lateralus-ideator-ground.md"
  "agents/lateralus-ideator-balanced.md"
  "agents/lateralus-ideator-wild.md"
  "agents/lateralus-workaround.md"
)
HOOKS=(
  "hooks/lateralus-hook.py"
)

echo "Installing lateralus → ${CLAUDE_DIR}"

# Determine source: local clone or remote
here="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || here=""

copy_file() {
  local src="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  if [ -n "$here" ] && [ -f "$here/$src" ]; then
    cp "$here/$src" "$dest_dir/$(basename "$src")"
  else
    curl -fsSL "${RAW}/${src}" -o "$dest_dir/$(basename "$src")"
  fi
}

for skill_entry in "${SKILLS[@]}"; do
  skill_src="${skill_entry%%:*}"
  skill_name="${skill_entry##*:}"
  dest_dir="${CLAUDE_DIR}/skills/${skill_name}"
  mkdir -p "$dest_dir"
  if [ -n "$here" ] && [ -f "$here/$skill_src" ]; then
    cp "$here/$skill_src" "$dest_dir/SKILL.md"
  else
    curl -fsSL "${RAW}/${skill_src}" -o "$dest_dir/SKILL.md"
  fi
  echo "  ✓ skill: ${skill_name}"
done

for agent_path in "${AGENTS[@]}"; do
  copy_file "$agent_path" "${CLAUDE_DIR}/agents"
  echo "  ✓ agent: $(basename "$agent_path")"
done

# Install hook
for hook_path in "${HOOKS[@]}"; do
  copy_file "$hook_path" "${CLAUDE_DIR}/hooks"
  chmod +x "${CLAUDE_DIR}/hooks/$(basename "$hook_path")"
  echo "  ✓ hook:  $(basename "$hook_path")"
done

# Wire hook into ~/.claude/settings.json (idempotent)
SETTINGS="${CLAUDE_DIR}/settings.json"
HOOK_CMD="python3 \"${CLAUDE_DIR}/hooks/lateralus-hook.py\""

python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF' || echo "  ! Hook wiring skipped — see above."
import sys, json, shutil
from pathlib import Path

settings_file = Path(sys.argv[1])
hook_cmd      = sys.argv[2]

settings = {}
if settings_file.exists():
    raw = settings_file.read_text()
    raw = "\n".join(l for l in raw.splitlines() if not l.strip().startswith("//"))
    try:
        settings = json.loads(raw)
    except Exception:
        print(f"  ! Could not parse {settings_file} — skipping hook wiring.", file=sys.stderr)
        print(f"    Wire the hook manually: https://github.com/SunnyKTuladhar/lateralus#manual-hook-wiring", file=sys.stderr)
        sys.exit(1)

hooks = settings.setdefault("hooks", {})
post  = hooks.setdefault("PostToolUse", [])
if not isinstance(post, list):
    post = []
    hooks["PostToolUse"] = post

# Check if already wired (idempotent) — defensive against non-dict entries
already = any(
    isinstance(entry, dict) and
    any(isinstance(h, dict) and h.get("command") == hook_cmd
        for h in entry.get("hooks", []) if isinstance(h, dict))
    for entry in post
    if isinstance(entry, dict)
)
if not already:
    post.append({
        "matcher": "Edit|Write|Create|MultiEdit|NotebookEditCell|Bash",
        "hooks": [{"type": "command", "command": hook_cmd}]
    })

settings_file.parent.mkdir(parents=True, exist_ok=True)
if settings_file.exists():
    shutil.copy2(settings_file, str(settings_file) + ".bak")
settings_file.write_text(json.dumps(settings, indent=2))
print(f"  ✓ hook wired in: {settings_file}")
PYEOF

echo ""
echo "Done. Open Claude Code and type /lateralus to use."
echo "For workarounds: /lateralus-workaround"
echo ""
echo "Hook: lateralus-hook.py fires on every Bash tool call and nudges /lateralus when a"
echo "      failure signature recurs after edits. Set LATERALUS_THRESHOLD to adjust sensitivity."
