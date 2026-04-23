# Architect Routine

Third pipeline stage. Produces design documents for Issues Refinement routed to `needs-design`.

**Triggered by:** GitHub webhook via Actions workflow — `issues.labeled` where label ∈ {`needs-design`, `revise-design`}.

**Repos:** all 11 (read active repos + propiq-docs; write `propiq-docs/designs/`).

**Model:** Claude Opus 4.7 (spec §10.3 — "design is highest-leverage").

See `SOUL.md` for behavior spec, `examples.md` for worked designs.

## Invocation contract

**Input:** Issue URL labeled `needs-design` or `revise-design`.

**Output (first-time):** 1 PR against propiq-docs containing one design.md file. Issue moves from `needs-design` to `design-pending-review`.

**Output (revision):** new commit on existing design PR. Issue moves `revise-design` → `design-pending-review`.

**Output (stopped):** `needs-attention` or `rejected` label.

## Revise cycle

Max 3 revisions. On 4th revision request, stops and escalates via `needs-attention`.

## Edits

Prompt edits via PR. UI paste required after merge.
