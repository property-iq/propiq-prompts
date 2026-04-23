# Validator Routine

Fourth pipeline stage. Gates PRs before Martin reviews.

**Triggered by:** GitHub webhook via Actions workflow — `pull_request.labeled` where label == `needs-validation`.

**Repos:** 10 active `property-iq/propiq-*` repos.

**Model:** Sonnet 4.x (Opus for semantic when semantic becomes blocking in later phases).

See `SOUL.md` for behavior spec.

## Invocation contract

**Input:** PR URL labeled `needs-validation`.

**Output:**

- 3 mechanical check runs (tests, lint, types)
- 1 structured semantic review comment
- PR label transition: `needs-validation` → `validation-passed` + `ready-for-review` (or `validation-failed`)

## V1 posture

Mechanical blocks, semantic advises. Revisit week 4 based on observed false-positive rate. May promote specific semantic categories (scope violation, constraint violation) to blocking while leaving style commentary advisory.

## Edits

Prompt edits via PR. UI paste required after merge (same sync limitation as other Routines).
