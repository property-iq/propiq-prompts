> ⚠️ **RETIRED (2026-06/07)** — this Routine profile is no longer invoked. The
> routed pipeline was replaced by `/spec` + the overnight-builder (see the
> repo README). Kept for reference only.

# propertyiq prompts — moved

The propertyiq PM agent prompts and the chart-qa skill moved to `property-iq/propiq-openclaw` on 2026-05-07. **That repo is now deprecated** (canonical fork is outside this org; OpenClaw decommissioning is tracked in propiq-infrastructure#19), so treat the paths below as historical.

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

This repo (`propiq-prompts`) is **retired** along with the routed Routine pipeline (see the top-level README banner). It formerly held **generic** Routine prompts and cross-Routine references — content that is not propertyiq-project-specific:

- `architect/`, `builder/`, `refinement/`, `validator/` — the four Routine profiles with content (`challenger/` and `visioner/` are empty placeholders)
- `shared/` — cross-Routine references
- `docs/adr/` — architectural decision records that span Routines

Edit those here. Edit propertyiq-scoped prompts in [propiq-openclaw](https://github.com/property-iq/propiq-openclaw).
