# lateralus skill

Lateralus is a stuck-debugging skill for coding agents.

It is designed for situations where normal debugging loops are not producing progress.
Instead of repeating nearby fixes, it forces an explicit three-tier ideation pass:

1. Tier 1 · Ground: concrete, testable hypotheses outside the obvious failure category
2. Tier 2 · Balanced: assumption-questioning hypotheses that remain loosely verifiable
3. Tier 3 · Wild: speculative reframes designed to jolt new associations

## Use this skill when

- The same bug survives multiple attempted fixes
- The user reports repeated failure (for example: "still broken")
- The agent detects it is about to repeat a rejected fix category

## Do not use this skill when

- It is the first attempt to debug a bug
- The issue has not been reproduced yet
- There is still an obvious untried baseline path

## Output contract

1. Dead ends already ruled out
2. Tier 1 (Ground) list — each with exact diagnostic to run before fixing
3. Tier 2 (Balanced) list — assumption + loose test signal
4. Tier 3 (Wild) list — non-literal reframes
5. Closing question asking which direction to investigate

## Source of truth

- Main file: `skills/lateralus/SKILL.md`
- Copilot mirror: `.github/skills/lateralus/SKILL.md`
