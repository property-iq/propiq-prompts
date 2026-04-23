# Refinement Routine

Second pipeline stage. Gates every Issue before Design or Build.

**Triggered by:** GitHub webhook — `issues.labeled` where label = `needs-refinement`.

**Repos:** all 10 active `property-iq/propiq-*` repos.

**Model:** Claude Sonnet 4.x.

**Write identity:** `propiq-bot` GitHub App.

See `SOUL.md` for the Routine's behavior spec and `examples.md` for worked decisions.

## Invocation contract

**Input:** an Issue URL on a repo labeled `needs-refinement`.

**Output:**

- exactly 1 comment posted (decision)
- 0 or 1 body edit (only for Refined)
- exactly 1 label removed (`needs-refinement`)
- exactly 1 label added (one of: `needs-design`, `needs-build`, `needs-clarification`, `rejected`)

## Calibration

Conservative. Err toward Bounced over Rejected. Empty constraint files = cannot cite = cannot Reject on that constraint.

## Edits

All prompt edits via PR to this repo. Routine picks up changes on next invocation — no cache issue. Prompt iteration is fast.

## Observability

Every decision includes an HTML-comment marker (`<!-- propiq-bot:refinement -->`) enabling downstream analysis (grep Issues for decision distribution, audit rejected-without-citation, etc.).
