# Builder Routine

Third pipeline stage. Writes code to resolve Issues labeled `needs-build` (fast-lane) or `design-ready` (post-Architect).

**Triggered by:** GitHub webhook via Actions workflow — `issues.labeled` where label ∈ {`needs-build`, `design-ready`}.

**Repos:** 10 active `property-iq/propiq-*` repos.

**Model:** Sonnet 4.x.

**Branch prefix:** `claude/` (Routines default).

See `SOUL.md` for behavior spec.

## Invocation contract

**Input:** Issue URL + label that triggered (for routing fast-lane vs design-ready).

**Output (successful):** 1 PR on `claude/*` branch with `needs-validation` label. Issue loses its entry label.

**Output (failed build):** `build-failed` label + diagnostic comment.

**Output (uncertain):** `needs-attention` label + ambiguity comment.

## Edits

Prompt edits via PR to `propiq-prompts`. Routine picks up on next invocation. Same SOUL.md sync limitation as Refinement — UI-pasted instructions don't auto-update from repo. Manual paste after each PR merge.
