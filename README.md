# lateralus

Lateral-thinking skill for AI coding agents when debugging gets stuck.

Understands your end goal (long-term fix, MVP, POC, workaround) and generates goal-appropriate alternatives — or tactical makeshift bypasses when you just need to move.

## Install

**macOS / Linux / WSL**
```bash
curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.ps1 | iex
```

**Claude Code plugin**
```bash
claude plugin marketplace add SunnyKTuladhar/lateralus && claude plugin install lateralus@lateralus
```

See [INSTALL.md](./INSTALL.md) for Copilot, manual, and per-directory options.

## How it works

1. First establishes your **goal and horizon** — long-term fix, MVP, POC, or just need to unblock now.
2. Routes accordingly:
   - **Just unblock / demo** → makeshift bypasses with explicit debt logging
   - **Unknown horizon** → asks targeted questions first
   - **Long-term / MVP** → two-tier lateral ideation
3. Generates **Tier 1** (plausible, testable alternatives) and **Tier 2** (wild reframes to break tunnel vision).

Only triggers after normal debugging has genuinely stalled — not on first attempt.

## Commands

| Command | What |
|---|---|
| `/lateralus` | Full skill — goal context + two-tier ideation |
| `/lateralus-caveman` | Same, 60% fewer tokens |

Natural language: `"still broken"`, `"same error"`, `"tried that already"`, `"going in circles"`

## Agents

| Agent | What |
|---|---|
| `lateralus-questioner` | Asks 5 questions to surface goal, horizon, constraints |
| `lateralus-investigator` | Audits what was tried and builds the dead-ends list |
| `lateralus-ideator` | Generates Tier 1 + Tier 2 ideas filtered by horizon |
| `lateralus-verifier` | Tests one chosen hypothesis with a minimal probe |
| `lateralus-workaround` | Makeshift bypasses with debt logging |

## Repository layout

```
skills/lateralus/          source-of-truth skill
skills/lateralus-caveman/  compressed variant
agents/                    five subagents
.github/skills/            Copilot-discoverable mirrors
.claude-plugin/            Claude Code plugin manifest
```
