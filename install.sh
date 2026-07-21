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
  "skills/lateralus/SKILL.md"
  "skills/lateralus-caveman/SKILL.md"
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

for skill_path in "${SKILLS[@]}"; do
  skill_name="$(basename "$(dirname "$skill_path")")"
  copy_file "$skill_path" "${CLAUDE_DIR}/skills/${skill_name}"
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
HOOK_CMD="python3 ${CLAUDE_DIR}/hooks/lateralus-hook.py"

python3 - "$SETTINGS" "$HOOK_CMD" <<'PYEOF'
import sys, json, os
from pathlib import Path

settings_file = sys.argv[1]
hook_cmd      = sys.argv[2]

# Load existing settings (strip // comments best-effort)
if Path(settings_file).exists():
    raw = Path(settings_file).read_text()
    raw = "\n".join(l for l in raw.splitlines() if not l.strip().startswith("//"))
    try:
        settings = json.loads(raw)
    except Exception:
        settings = {}
else:
    settings = {}

hooks = settings.setdefault("hooks", {})
post  = hooks.setdefault("PostToolUse", [])

# Check if already wired (idempotent)
already = any(
    any(h.get("command") == hook_cmd for h in entry.get("hooks", []))
    for entry in post
)
if not already:
    post.append({
        "matcher": "",
        "hooks": [{"type": "command", "command": hook_cmd}]
    })

Path(settings_file).parent.mkdir(parents=True, exist_ok=True)
Path(settings_file).write_text(json.dumps(settings, indent=2))
PYEOF

echo "  ✓ hook wired in: ${SETTINGS}"
echo ""
echo "Done. Open Claude Code and type /lateralus to use."
echo "For workarounds: /lateralus-workaround"
echo "For compressed mode: /lateralus-caveman"
echo ""
echo "Hook: lateralus-hook.py fires on every Bash tool call and nudges /lateralus when a"
echo "      failure signature recurs after edits. Set LATERALUS_THRESHOLD to adjust sensitivity."
