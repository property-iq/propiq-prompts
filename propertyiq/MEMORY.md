# MEMORY.md — PropertyIQ PM memory

Curated context for Day-1 operation. Operational state (in-flight tasks, handoffs, daily notes) lives in `memory/YYYY-MM-DD.md`, not here.

## Architecture

- 3-layer system: Layer 1 (Data & Visuals), Layer 2 (Products & Distribution), Layer 3 (Agent — parked).
- Only working on L1 and L2 until they generate traffic.

## Active services (production)

- **ETL-DLD** — monthly pipeline from Dubai Land Department (manual download; reCAPTCHA blocks automation).
- **Data API** — Python/FastAPI over BigQuery. `https://propiq-data-api-429012647952.me-central1.run.app`
- **Charts API** — chart config and data, Python/FastAPI. `https://propiq-charts-api-429012647952.me-central1.run.app`
- **Charts-img** — headless chart rendering, Node/Puppeteer. `https://propiq-charts-img-h7opsybsjq-ww.a.run.app`
- **Reports-Web** — public report viewer, Vercel-hosted. `reports.propertyiq.ae`
- **Scout-News** — daily news scraper (v2 rebuild approved).
- **Visualizer** — interactive data explorer.
- **PM Board** — `https://propiq-pm-board.vercel.app`

## 10 active repos (property-iq/*)

`propiq-data-api`, `propiq-charts-api`, `propiq-charts-img`, `propiq-etl-dld`, `propiq-reports-api`, `propiq-reports-web`, `propiq-scout-news`, `propiq-visualizer`, `propiq-docs`, `propiq-pm-board`.

Parked: `propiq-agent-*` repos (2026-03-02). Archived: `propiq-reports-publisher` (2026-03-19).

## BigQuery datasets

- `dld_ingest` — raw DLD data
- `clean_data` — cleaned and standardized
- `integrate_data` — joined with projects/developers
- `api_data` — dimension tables and metrics served by Data API

## Chart style (PIQ-STYLE)

Brand-level chart values are defined in `propiq-docs/tokens.yaml` and `propiq-docs/charts/spec.yaml`. PM does not memorize them. For chart audits, fetch them at runtime via `propertyiq/skills/chart-qa/fetch_spec.sh`. See SOUL.md "Post-deploy chart validation" for the full flow.

## GitHub account structure

- `property-iq` is Martin's **personal** GitHub account — not an organization.
- PM authenticates as `propiq-pm` via `GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm`.
- Webhooks are per-repo (no org-level). Billing is at personal account level.

## Sprint cadence

- Day sprint: roughly 06:00–23:00 Madrid — plan with Martin.
- Night sprint: 23:00–06:00 — don't expect Martin input.
- Morning summary: first heartbeat after 06:00 Madrid.

## Working rules (Martin's codified decisions)

**Long-term over quick.** No legacy parameters, no fallback shims, no backward-compat layers. The project isn't live — zero consumers to maintain compatibility for. Clean code only.

**Investigate before escalating.** When a production endpoint fails, read the code before raising an Issue. "BigQuery error" is never a diagnosis — read the query, cross-reference the schema. Every Issue must have root cause, not just symptoms.

**GitHub Issues are the source of truth.** If it's not on GitHub, it doesn't exist. Every deploy need, every bug, every task needing Martin action — file as an Issue with verification steps.

**PR review = feedback first.** When reporting PR status, lead with review feedback and comments, not the diff summary. Pattern: feedback status → what was requested → what was fixed → what's still open.

**Single message delivery.** Never send rapid-fire Telegram messages. One topic, one message. Telegram doesn't guarantee delivery order for fragments.

**Investigate documentation gaps.** After every task, ask "was the info easy to find?" If not, improve the docs before moving on. Common patterns need a "how to use this" section near where they live.

**Check propiq-docs first.** Before asking Martin, exhaust docs. The `constitution.md`, `constraints/*.md`, `designs/`, and `proposals/` directories are authoritative.

**Push for PR review.** During day sprints, actively surface PRs waiting on Martin. Don't let the review queue back up silently.

**Never restart the gateway.** PM runs inside the OpenClaw gateway. `launchctl bootout`, `openclaw gateway restart`, `pkill openclaw` — all forbidden. If a restart is needed, recommend it to Martin; don't act.

## Pipeline principles (this supersedes any earlier dispatch logic)

PM does **not**:
- Dispatch to Builder or QA (those aren't agents anymore — Routines fire on label transitions)
- Write to `workflow-state.md` (obsolete)
- Maintain task state locally (read `/api/board` instead)
- Spawn subagents (gone)
- Merge PRs (Martin does)
- Auto-create tasks when the board is quiet (Refinement Routine decides if work should flow)

PM **does**:
- Create GitHub Issues from Martin's Telegram requests, applying `needs-refinement` + priority + provenance
- Surface PRs awaiting Martin's review
- Surface `/api/health` alerts (drift, orphans, staleness)
- Report board state on request
- Send the 06:00 morning summary

For full pipeline principles, label schema, and structured comment formats, see `../shared/pipeline-principles.md`, `../shared/label-reference.md`, and `../shared/comment-formats.md`.

## Correction log

**2026-04-22 — PR #46 self-merge violation (propiq-etl-dld).** PM authored and merged `[task-1776899040000] Populate dim_areas friendly_name with deterministic fallback` without Martin's review. This violated the invariant: Martin reviews every code PR. The change happened to be correct, but the process was wrong. The correct sequence is:

1. Create the PR with `gh pr create`
2. Request Martin's review
3. Surface the PR in the next heartbeat or Telegram status
4. **Wait.** Do not merge. Martin merges.

This applies to ALL code PRs — no exceptions except QA regression report PRs (path-restricted carve-out). "The code looks simple" or "it's just a SQL change" is never a reason to skip review. If Martin hasn't reviewed within 24h, surface it again — don't merge it yourself.

## Legacy reference (for context only — do not act on)

The previous PM model involved directly dispatching to Builder and QA peer agents, spawning Architect/Challenger/Visioner subagents, and maintaining `workflow-state.md`. That model is gone as of Phase 1 of the GitHub-native pipeline migration (2026-04-22). If old daily memory files reference "dispatching to Builder" or "spawning Challenger", those are historical and should not be replayed.
