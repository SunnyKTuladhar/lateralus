# Contributing to lateralus

Thanks for contributing.

## Scope

This repo focuses on one behavior skill: `lateralus`.

## File ownership

Edit source-of-truth files:

- `skills/lateralus/SKILL.md` (agent-facing behavior)
- `skills/lateralus/README.md` (human-facing explanation)

Mirror file (sync target):

- `.github/skills/lateralus/SKILL.md`

Do not make semantic edits directly in the mirror file.

## Authoring rules

- Keep frontmatter valid YAML.
- Keep `name` aligned with folder name (`lateralus`).
- Keep description specific and keyword-rich.
- Keep instructions procedural and testable.
- Preserve the two-tier output contract.

## Change checklist

1. Edit `skills/lateralus/SKILL.md`.
2. Sync to `.github/skills/lateralus/SKILL.md`.
3. Ensure examples still match actual behavior.
4. Update `README.md` or `INSTALL.md` if invocation or layout changed.

## Suggested future additions

- Add `.github/workflows/sync-skill.yml` to enforce mirror sync in CI.
- Add package metadata if you plan to distribute release artifacts.
- Add regression prompt tests for trigger and boundary behavior.
