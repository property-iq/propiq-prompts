# Label Reference

Canonical label schema. Applied to all 10 active repos.

## Pipeline — Issue-side

| Label | Applied by | Triggers |
|-------|-----------|----------|
| `needs-refinement` | PM | Refinement Routine |
| `needs-clarification` | Refinement | PM surfaces questions to Martin |
| `needs-design` | Refinement | Architect Routine |
| `design-in-progress` | Architect | (in-flight marker) |
| `design-pending-review` | Architect | Martin reviews design PR |
| `revise-design` | Martin | Architect re-runs with comments |
| `design-ready` | Webhook (on design PR merge) | Builder Routine |
| `needs-build` | Refinement (fast-lane) | Builder Routine |
| `build-in-progress` | Builder | (in-flight marker) |
| `build-failed` | Builder | Escalation; self-iteration exhausted |
| `blocked` | PM | Board shows blocked; structured comment required |
| `rejected` | Refinement | Board shows done+rejected chip |
| `force-accept` | Martin | Overrides rejection; skips Refinement |
| `needs-attention` | Any Routine | Human escalation needed |

## Pipeline — PR-side

| Label | Applied by | Triggers |
|-------|-----------|----------|
| `needs-validation` | Builder | Validator Routine |
| `validation-in-progress` | Validator | (in-flight marker) |
| `validation-passed` | Validator | (informational) |
| `validation-failed` | Validator | Builder amends + re-applies `needs-validation` |
| `ready-for-review` | Validator | PM pings Martin |

## Taxonomy

| Label | Purpose |
|-------|---------|
| `p0` / `p1` / `p2` / `p3` | Priority (red / orange / yellow / gray) |
| `epic:{slug}` | Epic membership (e.g., `epic:quality`) |
| `from:telegram` / `from:audit` / `from:proposal` / `from:martin` / `from:qa` | Provenance |
| `audit-finding` | Issue created by Challenger |
| `stale-in-progress` | Sync worker flag; no PR linked, >48h |

## Skip / Override

| Label | Effect |
|-------|--------|
| `force-accept` | Bypass Refinement rejection |
| `no-validation` | Bypass Validator (docs-only PRs) |
| `no-epic` | Explicit opt-out of epic membership |
