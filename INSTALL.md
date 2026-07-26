# Install lateralus

## One-liner

**macOS / Linux / WSL / Git Bash**
```bash
curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.sh | bash
```

**Windows (PowerShell 5.1+, hook wiring requires pwsh 6+)**
```powershell
irm https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.ps1 | iex
```

Copies skills, agents, and a `PostToolUse` hook into `~/.claude/`. Also wires the hook into `~/.claude/settings.json`. Safe to re-run.

## GitHub Copilot (repo-local)

```bash
mkdir -p .github/skills/lateralus
curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/skills/lateralus/SKILL.md \
  > .github/skills/lateralus/SKILL.md
```

## Manual (local clone)

```bash
git clone https://github.com/SunnyKTuladhar/lateralus.git
cd lateralus
bash install.sh
```

## What gets installed

| File | Destination |
|---|---|
| `skills/lateralus/SKILL.md` | `~/.claude/skills/lateralus/` |
| `skills/lateralus-caveman/SKILL.md` | `~/.claude/skills/lateralus-caveman/` |
| `agents/lateralus-ideator-ground.md` | `~/.claude/agents/` |
| `agents/lateralus-ideator-balanced.md` | `~/.claude/agents/` |
| `agents/lateralus-ideator-wild.md` | `~/.claude/agents/` |
| `agents/lateralus-workaround.md` | `~/.claude/agents/` |
| `hooks/lateralus-hook.py` | `~/.claude/hooks/` (macOS/Linux/WSL) |
| `hooks/lateralus-hook.ps1` | `~/.claude/hooks/` (Windows) |

The hook is also wired into `~/.claude/settings.json` under `hooks.PostToolUse`. A `.bak` copy of `settings.json` is written before any modification. If the file can't be parsed, wiring is skipped and the file is left untouched.

## Usage

| Command | What |
|---|---|
| `/lateralus` | Full lateral-thinking pass after debugging stalls |
| `/lateralus-caveman` | Same, 60% fewer tokens |

Natural language triggers: `"still broken"`, `"same error"`, `"tried that already"`, `"going in circles"`

Not for first-attempt debugging — straight-line reasoning first.

## Custom install directory

Set `CLAUDE_CONFIG_DIR` to override the default `~/.claude`:
```bash
CLAUDE_CONFIG_DIR=/custom/path bash install.sh
```
