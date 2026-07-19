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

echo ""
echo "Done. Open Claude Code and type /lateralus to use."
echo "For workarounds: /lateralus-workaround"
echo "For compressed mode: /lateralus-caveman"
