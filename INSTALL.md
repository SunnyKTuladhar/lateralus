# Install lateralus

## One-liner

**macOS / Linux / WSL / Git Bash**
```bash
curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.sh | bash
```

**Windows (PowerShell 5.1+)**
```powershell
irm https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.ps1 | iex
```

Copies skills and agents into `~/.claude/skills/` and `~/.claude/agents/`. Safe to re-run.

## Claude Code plugin

```bash
claude plugin marketplace add SunnyKTuladhar/lateralus && claude plugin install lateralus@lateralus
```

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
| `agents/lateralus-investigator.md` | `~/.claude/agents/` |
| `agents/lateralus-questioner.md` | `~/.claude/agents/` |
| `agents/lateralus-ideator.md` | `~/.claude/agents/` |
| `agents/lateralus-verifier.md` | `~/.claude/agents/` |
| `agents/lateralus-workaround.md` | `~/.claude/agents/` |

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
