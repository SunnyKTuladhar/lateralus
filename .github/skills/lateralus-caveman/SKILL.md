---
name: lateralus-caveman
description: "Caveman-compressed lateral-thinking escape hatch for stalled debugging. Surfaces end goal and horizon (long-term, MVP, POC, workaround) then generates goal-appropriate alternatives in two tiers. 60% fewer tokens. Use only after normal debugging genuinely stalled."
argument-hint: "What tried, what failed, current error, end goal"
user-invocable: true
---

Goal first. Break tunnel vision. Generate outside failed approach.

## Step 0 — Goal context

| Horizon | Route |
| --- | --- |
| Long-term / prod | T1 + T2, correctness first |
| MVP | T1 + T2, flag debt |
| POC / test | T1 OK alone; flag if prod fix differs |
| Just unblock / demo | → `lateralus-workaround` |
| Unknown | → `lateralus-questioner` |

Constraints + success signal before ideating.

## When

Fire only after debugging stalled:
- 2+ fixes on same bug failed
- "still broken" / "already tried" / "same error" / "going in circles"
- About to repeat variant of ruled-out fix

NOT first attempt.

## Rules

Dead ends first. One line: ruled out + why. Never repeat.

Two tiers. Both. Always labeled. Never blend.

Pattern: `Goal: [horizon]. Ruled out: [x]. T1: [grounded]. T2: [wild].`

## Tiers

| Tier | What | Length |
| --- | --- | --- |
| **T1 — Plausible** | 3-5 testable causes outside obvious. Cache, encoding, timezone, race, stale build, dep drift, inverted baseline, adjacent component. Depth = horizon. | Name it. How to test it. |
| **T2 — Wild** | 3-5 reframes. Not literal. Jolt associations: ignored premise, data not code, distrust error location, unify bugs, question if problem needs solving. State non-literal up front. | 1-2 sentences. No over-justification. |

## Boundaries

No prior attempt → skip.
Don't fire twice same stall without new info.
User picks direction → investigate before new batch.
End: ask which direction next.
