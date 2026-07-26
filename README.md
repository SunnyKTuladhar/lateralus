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
| `/lateralus` | Default — full debugging analysis, maximum detail |
| `/lateralus-caveman` | Context window nearly full, want faster responses (~60% fewer tokens) |
| `/lateralus-brainstorm` | Planning new work — Grounded, Balanced, or Wild idea generation. Also activates in plan mode. |
| `/lateralus-brainstorm-caveman` | Same as above, compressed (~60% fewer tokens) |

## Usage examples

### `/lateralus` — debugging stalled

```
> I've tried three different approaches to fix this memory leak and none of them worked.
  The heap keeps growing after every request cycle.

/lateralus
```

```
> same error again after my last edit. going in circles.

/lateralus
```

The hook also fires automatically — if the same failure signature recurs after edit attempts,
it nudges you to invoke `/lateralus` before making another fix attempt.

---

### `/lateralus-brainstorm` — planning your next work

Invoke directly:

```
> /lateralus-brainstorm I want to add real-time notifications to the app
```

Or just describe what you're planning — the skill activates automatically in plan mode:

```
> let's brainstorm how to handle auth for the new API
```

```
> thinking through the data model for multi-tenancy
```

```
> what are our options for caching here?
```

After reading your codebase context, it presents three modes to pick from:

- **Grounded** — practical ideas you could ship soon, within current constraints
- **Balanced** — ideas that question some assumptions but stay loosely feasible  
- **Wild** — constraint-free, blue-sky, no wrong answers

---

### Direct agent invocation (shortcut)

Skip the interrogation step if you already have a context block:

```
> @lateralus-ideator-wild
  Goal: replace our polling mechanism. Horizon: long-term.
  Ruled out: WebSockets (infra constraint), SSE (proxy strips headers).
```

```
> @lateralus-workaround
  Blocking: auth service is down in staging, need to demo in 2 hours.
```

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
skills/lateralus/          SKILL.md + SKILL-caveman.md
skills/lateralus-brainstorm/ SKILL.md + SKILL-caveman.md
agents/                    four subagents
.github/skills/            Copilot-discoverable mirrors (CI-synced)
```
