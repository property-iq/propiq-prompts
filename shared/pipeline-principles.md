# Pipeline Principles

Every Routine reads this file. These are non-negotiable.

## The pipeline

Six stages, each with one actor, one artifact:

| # | Stage | Actor | Artifact | Entry label | Exit |
|---|-------|-------|----------|-------------|------|
| 1 | Intake | PM (Telegram) | GitHub Issue | Issue opened | `needs-refinement` |
| 2 | Refinement | Refinement Routine | Amended Issue + decision comment | `needs-refinement` | `needs-design` / `needs-build` / `needs-clarification` / `rejected` |
| 3 | Design | Architect Routine | PR against `propiq-docs/designs/` | `needs-design` | `design-ready` (on merge) |
| 4 | Build | Builder Routine | PR against target repo (`Fixes #N`) | `design-ready` or `needs-build` | `needs-validation` |
| 5 | Validate | Validator Routine | Check runs + review comment | `needs-validation` | `ready-for-review` / `validation-failed` |
| 6 | Review | Martin | Merge or bounce | `ready-for-review` | Issue closed |

## Core contracts

- **Each stage has one job.** Don't combine Refinement + Design. Don't skip Validation.
- **Labels are the state machine.** Your only way to advance work is to change labels. Don't set status in comments or files.
- **Cheap checks first.** Refinement runs before Design. Design runs before Build. Filter early.
- **Derive, don't store.** Task status is computed from labels + PR state. No Redis-only state.
- **Artifacts are PRs, Issues, or comments.** No file-based handoffs. No local-only state.

## Invariants (spec §16)

1. Every task's state is derivable from GitHub alone. No Redis-only fields on tasks.
2. Labels are the state machine. No code reads status from anywhere else.
3. Martin reviews every code PR. One exception: QA report PRs (append-only, path-restricted self-merge).
4. The sync worker wins over the webhook handler. On disagreement, sync's recomputation is authoritative.
5. Every Routine artifact is a PR, an Issue, or a PR/Issue comment. No file-based handoffs.
6. Every PR is linked to an Issue. Unlinked merged PRs are orphans and surface as alerts.
7. `propiq-bot` is the only Routine write identity. PM's credential is separate and narrower.
8. Routine prompts live only in `propiq-prompts`. No prompt content in Routine configs or elsewhere.
9. Blocked state requires a structured comment. No label-only blocks. Reason must be parseable.
10. Drift is detected, surfaced, and healed within 10 minutes.

## Read before every invocation

- `propiq-docs/constitution.md` — authoritative principles
- `propiq-docs/constraints/*.md` — codified rejections
- Target repo's `CLAUDE.md` — repo-specific invariants
- `shared/label-reference.md` — label schema
- `shared/comment-formats.md` — structured comment formats
