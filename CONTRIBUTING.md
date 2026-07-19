# Contributing to lateralus

Thanks for contributing.

## Scope

This repo has two skills and four agents.

## File ownership

Edit source-of-truth files only:

**Skills:**
- `skills/lateralus/SKILL.md` — agent-facing behavior (full)
- `skills/lateralus/README.md` — human-facing explanation
- `skills/lateralus-caveman/SKILL.md` — compressed variant

**Agents:**
- `agents/lateralus-ideator-ground.md` — Tier 1
- `agents/lateralus-ideator-balanced.md` — Tier 2
- `agents/lateralus-ideator-wild.md` — Tier 3
- `agents/lateralus-workaround.md` — bypass generator

**Mirrors (CI-synced — do not edit directly):**
- `.github/skills/lateralus/SKILL.md`
- `.github/skills/lateralus-caveman/SKILL.md`

## Authoring rules

- Keep frontmatter valid YAML.
- Keep `name` aligned with folder name.
- Keep description specific and keyword-rich.
- Keep instructions procedural and testable.
- Preserve the three-tier output contract (Ground / Balanced / Wild).

## Change checklist

1. Edit the source-of-truth file(s) in `skills/` or `agents/`.
2. If a skill changed: sync to the matching `.github/skills/` mirror (CI does this on push to main, but sync manually for local testing).
3. Ensure examples still match actual behavior.
4. Update `README.md` or `INSTALL.md` if invocation or layout changed.
5. Update `CLAUDE.md` agent table if an agent is added, removed, or renamed.

## Suggested future additions

- Add package metadata if you plan to distribute release artifacts.
- Add regression prompt tests for trigger and boundary behavior.
