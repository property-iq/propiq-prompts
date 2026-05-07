# propertyiq prompts — moved

The propertyiq PM agent prompts and the chart-qa skill have moved to **[property-iq/propiq-openclaw](https://github.com/property-iq/propiq-openclaw)** as of 2026-05-07.

## New paths

| Old (this repo) | New (`propiq-openclaw`) |
|---|---|
| `propertyiq/SOUL.md` | `workspace/agents/propertyiq/SOUL.md` |
| `propertyiq/HEARTBEAT.md` | `workspace/agents/propertyiq/HEARTBEAT.md` |
| `propertyiq/IDENTITY.md`, `TOOLS.md`, `USER.md`, `BOOTSTRAP.md`, `MEMORY.md`, `RUNBOOK.md` | `workspace/agents/propertyiq/<same>` |
| `propertyiq/skills/chart-qa/` | `workspace/agents/propertyiq/skills/chart-qa/` |
| `scripts/regen_quickref.py` | `scripts/regen_quickref.py` (in propiq-openclaw) |
| `scripts/lint_no_hardcoded_values.sh` | `scripts/lint_no_hardcoded_values.sh` (in propiq-openclaw) |
| `.github/workflows/ci.yml` (the propertyiq portions) | `.github/workflows/prompts-ci.yml` (in propiq-openclaw) |

The four shared references the propertyiq agent loads at runtime (`pipeline-principles.md`, `label-reference.md`, `comment-formats.md`, `chart-spec-fetch.md`) are vendored at `workspace/agents/propertyiq/shared/` in `propiq-openclaw`. Canonical copies for the generic Routines remain in this repo at `shared/`.

## What still lives here

This repo (`propiq-prompts`) remains active for **generic** Claude Code Routines and cross-Routine references — content that is not propertyiq-project-specific:

- `architect/`, `builder/`, `challenger/`, `refinement/`, `validator/`, `visioner/` — the six Routine profiles
- `shared/` — cross-Routine references
- `docs/adr/` — architectural decision records that span Routines

Edit those here. Edit propertyiq-scoped prompts in [propiq-openclaw](https://github.com/property-iq/propiq-openclaw).
