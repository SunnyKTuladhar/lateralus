# CLAUDE.md — lateralus

## Project overview

Lateralus is a lateral-thinking skill for AI coding agents that breaks debugging tunnel vision.
It surfaces the user's end goal and solution horizon (long-term, MVP, POC, workaround), then generates
goal-appropriate alternatives in two tiers: grounded-but-unlikely and wild/speculative reframes.

Ships as a Claude Code plugin, Copilot repo skill, and direct install via `install.sh` / `install.ps1`.

---

## What lives where

```
lateralus/
├── README.md                         # Front door (product pitch + install one-liners)
├── INSTALL.md                        # Full install matrix
├── CONTRIBUTING.md                   # Dev guide and file ownership
├── CLAUDE.md                         # This file (maintainer instructions)
├── AGENTS.md / GEMINI.md             # Autodiscovery files (must stay at root)
│
├── install.sh                        # macOS / Linux / WSL installer
├── install.ps1                       # Windows PowerShell installer
│
├── skills/                           # ALL skills — single source of truth
│   ├── lateralus/{SKILL.md, README.md}
│   └── lateralus-caveman/SKILL.md    # Caveman-compressed variant
│
├── agents/                           # Subagents — single source of truth
│   ├── lateralus-investigator.md     # Audits dead ends
│   ├── lateralus-questioner.md       # Surfaces goal and horizon
│   ├── lateralus-ideator.md          # Generates Tier 1 + Tier 2 ideas
│   ├── lateralus-verifier.md         # Tests one hypothesis
│   └── lateralus-workaround.md       # Makeshift bypasses with debt log
│
├── .claude-plugin/                   # Claude Code plugin manifest
│   ├── plugin.json                   # Plugin metadata and agents array
│   └── marketplace.json              # Marketplace listing
│
├── .github/skills/                   # Copilot-discoverable mirrors (CI-synced)
│   ├── lateralus/SKILL.md
│   └── lateralus-caveman/SKILL.md
│
└── .github/workflows/
    └── sync-skill.yml                # Syncs skills/ → .github/skills/ on push to main
```

---

## File ownership — edit only these

| I want to change... | Edit this file |
|---|---|
| Core skill behavior (tiers, horizon routing, rules) | `skills/lateralus/SKILL.md` |
| Caveman-compressed variant | `skills/lateralus-caveman/SKILL.md` |
| Dead-end auditing behavior | `agents/lateralus-investigator.md` |
| Question interview flow | `agents/lateralus-questioner.md` |
| Idea generation rules | `agents/lateralus-ideator.md` |
| Hypothesis verification behavior | `agents/lateralus-verifier.md` |
| Makeshift bypass rules | `agents/lateralus-workaround.md` |
| Plugin metadata | `.claude-plugin/plugin.json` |
| Marketplace listing | `.claude-plugin/marketplace.json` |
| Install steps | `install.sh`, `install.ps1`, `INSTALL.md` |

Do NOT edit `.github/skills/` directly — those are CI-synced mirrors.

---

## CI sync workflow

`.github/workflows/sync-skill.yml` triggers on push to `main` when any `skills/**/SKILL.md` changes.

What it does:
1. Copies `skills/lateralus/SKILL.md` → `.github/skills/lateralus/SKILL.md`
2. Copies `skills/lateralus-caveman/SKILL.md` → `.github/skills/lateralus-caveman/SKILL.md`
3. Commits with `[skip ci]` to avoid loops.

After merging a skill change, wait for the workflow before declaring the release complete.

---

## Skill system

Two skills ship from this repo:

| Skill | File | Purpose |
|---|---|---|
| `lateralus` | `skills/lateralus/SKILL.md` | Full skill — goal context + two-tier ideation |
| `lateralus-caveman` | `skills/lateralus-caveman/SKILL.md` | Same behavior, ~60% fewer tokens |

Each skill has:
- A `SKILL.md` (LLM-facing prompt body — what the agent loads)
- A `README.md` alongside for humans browsing GitHub

Don't merge them. Different audiences, different formats.

---

## Agent system

Five subagents covering the full lateralus workflow:

| Stage | Agent | Model |
|---|---|---|
| 1. Audit | `lateralus-investigator` | haiku |
| 2. Interview | `lateralus-questioner` | sonnet |
| 3. Ideate | `lateralus-ideator` | sonnet |
| 4. Verify | `lateralus-verifier` | sonnet |
| 5. Bypass | `lateralus-workaround` | sonnet |

Horizon routing determines which agents fire:
- Unknown horizon → questioner first
- Just unblock / demo → workaround directly
- Long-term / MVP → investigator → ideator → verifier

---

## Install system

Two plain shell scripts — no Node, no JSONC parser, no settings.json merge needed.
Lateralus has no hooks, so there is nothing to wire into `settings.json`.

`install.sh` and `install.ps1`:
- Copy `skills/lateralus/` and `skills/lateralus-caveman/` to `~/.claude/skills/`
- Copy all five agent files to `~/.claude/agents/`
- Respect `CLAUDE_CONFIG_DIR` env var
- Work from curl-pipe or local clone
- Safe to re-run

If hooks are added in future, a JSONC-tolerant settings.json writer will be needed before the scripts touch `settings.json`.

---

## Key rules for agents working here

- Edit `skills/<name>/SKILL.md` for behavior changes. Never edit the `.github/skills/` mirrors.
- Edit `agents/<name>.md` for subagent behavior. All agents are single-source at the repo root.
- Keep skill descriptions keyword-rich — the `description` field is how agents discover when to load the skill.
- Keep SKILL.md under 500 lines. Use reference files if it grows.
- `install.sh` and `install.ps1` are the single source for install logic. Don't add OS-specific logic to one without the other.
- After merging a skill edit, confirm CI synced the `.github/skills/` mirror before marking done.
- README is user-facing. Keep install one-liners accurate. If an install path changes, update README, INSTALL.md, and both install scripts.
