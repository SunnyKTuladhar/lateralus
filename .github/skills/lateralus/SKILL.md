---
name: lateralus
description: "Lateral-thinking escape hatch for stalled debugging. Surfaces the user's end goal and solution horizon (long-term, MVP, POC, workaround), then generates goal-appropriate alternatives in two tiers. Use only after normal debugging has genuinely stalled."
argument-hint: "What was tried, what failed, current error, end goal"
user-invocable: true
---

Understand the goal first. Break tunnel vision. Generate from outside the failed approach.

## Step 0 — Goal context (always first)

Before ideating, establish:
- **Horizon**: long-term / MVP / POC / test / just-unblock
- **Constraints**: what can't change
- **Success signal**: how will the user know it's fixed

| Horizon | Route |
| --- | --- |
| Long-term / production | Tier 1 + Tier 2, correctness and maintainability first |
| MVP | Tier 1 + Tier 2, flag tech debt explicitly |
| POC / test | Tier 1 acceptable alone; flag if production fix differs |
| Just unblock / demo | Skip tiers — spawn `lateralus-workaround` |
| Unknown | Spawn `lateralus-questioner` before ideating |

## When

Trigger only after normal debugging stalled:
- 2+ fix attempts on the same bug failed
- User says "still broken", "already tried", "same error", or "going in circles"
- Agent about to suggest a variant of something already ruled out

Not on first attempt. Straight-line reasoning first.

## Rules

State dead ends first — one line, what's ruled out and why. Never repeat a ruled-out idea.

Always output both tiers, always labeled, never blended.

Pattern: `Goal: [horizon]. Ruled out: [x]. Tier 1: [grounded]. Tier 2: [wild].`

## Tiers

| Tier | What | Length |
| --- | --- | --- |
| Tier 1 — Unlikely but plausible | 3-5 concrete testable causes outside the obvious category. Cache, encoding, timezone, race, stale build, dep drift, inverted baseline, adjacent component. Depth calibrated to horizon. | One line naming it + one line on how to test it. |
| Tier 2 — Wild reframes | 3-5 speculative reframes. Not literal fixes — state this up front. Goal: jolt a new association. Question an ignored premise, solve with data not code, distrust error location, unify two bugs, question whether the problem needs solving given horizon. | 1-2 sentences each. Don't over-justify. |

## Boundaries

No real fix attempt yet → skip. Normal debugging first.
Don't fire twice on same stall without new info.
User picks a direction → investigate before generating a fresh batch.
End every ideation pass by asking which direction to explore next.
