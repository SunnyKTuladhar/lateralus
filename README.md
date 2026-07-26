# lateralus

Lateral-thinking skill for AI coding agents when debugging gets stuck.

Understands your end goal (long-term fix, MVP, POC, workaround) and generates goal-appropriate alternatives — or tactical makeshift bypasses when you just need to move.

## Install

**GitHub Copilot (gh CLI)**
```bash
gh skill install SunnyKTuladhar/lateralus
```

**macOS / Linux / WSL**
```bash
curl -fsSL https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/SunnyKTuladhar/lateralus/main/install.ps1 | iex
```

See [INSTALL.md](./INSTALL.md) for Copilot, manual, and per-directory options.

## How it works

1. First establishes your **goal and horizon** — long-term fix, MVP, POC, or just need to unblock now.
2. Routes accordingly:
   - **Just unblock / demo** → makeshift bypasses with explicit debt logging
   - **Long-term / MVP** → Tier 1 + Tier 3 ideation (parallel)
   - **Time-pressured / single pass** → Tier 2 balanced ideation
   - **POC / test** → Tier 1 only
3. Generates testable hypotheses and/or wild reframes depending on horizon.

Only triggers after normal debugging has genuinely stalled — not on first attempt.

## Commands

| Command | Use when |
|---|---|
| `/lateralus` | Default — full analysis, maximum detail |
| `/lateralus-caveman` | Context window is nearly full, or you want faster/cheaper responses (~60% fewer tokens) |

## Agents

The skill auto-routes to the right agents after the interrogation step. You can also invoke agents directly as a shortcut if you already know what you need.

| Agent | Tier | Use directly when… |
|---|---|---|
| `lateralus-ideator-ground` | Tier 1 | You want concrete, testable hypotheses — paste your context block and go |
| `lateralus-ideator-balanced` | Tier 2 | You want assumption-questioning ideas that are still loosely verifiable |
| `lateralus-ideator-wild` | Tier 3 | You want speculative reframes to break tunnel vision |
| `lateralus-workaround` | — | You just need to unblock now, root cause can wait |

## Repository layout

```
skills/lateralus/          source-of-truth skill
skills/lateralus-caveman/  compressed variant
agents/                    four subagents
.github/skills/            Copilot-discoverable mirrors
```
