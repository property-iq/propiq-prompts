# ADR 0001: Agent consumes chart spec at runtime, never bakes values into prompts

## Status

Accepted — 2026-04-29

## Context

propiq-docs#44 replaced `CHART_DESIGN_GUIDELINES.md` with a three-layer architecture: `charts/spec.yaml` (machine-readable contract), `charts/guidelines.md` (human prose), `charts/checklist.md` (auto-generated). Bilateral CI checks in propiq-charts-api, propiq-charts-img, and propiq-reports-web fetch spec at test time and fail builds on drift.

The OpenClaw PM agent runs post-deploy chart audits using inline hardcoded copies of the same brand values that the new architecture treats as authoritative. Three independent copies lived in `SOUL.md`, `MEMORY.md`, and `TOOLS.md`, plus a fourth in a Mini-workspace-local skill. None had an enforcement link to the contract.

This is the same drift pattern propiq-docs#44 fixed at the doc layer, reproduced in the prompt layer. Evidence: `SOUL.md` listed `tension 0.25` while spec.yaml rule U006 specifies `0.35` — the inline copy had already silently diverged.

## Decision

The agent consumes `charts/spec.yaml` at audit invocation time via a shell helper (`fetch_spec.sh`) that uses the same `curl`-to-raw-GitHub pattern as the bilateral CI checks. Resolved spec is the contract; prompts cite spec rule IDs only; no chart values are hardcoded in any prompt file.

The Mini-workspace-local `chart-qa` skill migrates into propiq-prompts to bring it under PR review and the same drift checks.

A `lint_no_hardcoded_values.sh` CI check runs on every PR, mechanically preventing re-introduction of inline values in any prompt file.

When the agent observes runtime-spec drift, it does not assume which side is wrong. It investigates and files an Issue against whichever side needs to change — runtime repo (regression) or propiq-docs (spec lag) — with the audit-finding template's "Drift classification" field populated. PM never writes directly to `propiq-docs/charts/`.

## Consequences

**Positive:**

- Drift between the agent's view of brand values and runtime becomes mechanically impossible. Inline values fail CI; lookup happens every audit against current spec.
- Audit Issues cite specific rule IDs, making them precise and machine-checkable.
- The migrated chart-qa skill is PR-reviewable; structural changes are now visible to Refinement and Martin.
- The pattern generalizes: future audit-style Routines can pick up `shared/chart-spec-fetch.md` without redesign.

**Negative:**

- propiq-prompts now requires CI (didn't before).
- Audit invocation gains a network call. Failure mode: audits abort rather than fall back. Acceptable; matches the failure mode of bilateral CI checks.
- The migrated skill loses Mini-workspace operator-local edit flexibility. PR is the only edit path now.

## Alternatives considered

**Update the inline values to current runtime.** Rejected. The same defect propiq-docs#44 ruled out — a discipline-based fix has already failed at the doc layer; reproducing it at the prompt layer is no more robust.

**Embed spec.yaml content into MEMORY.md as auto-generated text.** Rejected. Adds context-load on every PM session for values that aren't needed every session. The runtime fetch is invocation-scoped — it loads context only when an audit actually runs.

**Build a Python module that loads spec.yaml and exposes a typed API for the agent.** Rejected as over-engineering for current scale. The shell-script + YAML-resolver path matches the bilateral CI checks and is small enough to read in one screen.

## References

- propiq-docs#44 — chart visual standards architecture
- propiq-docs ADR 0001 — chart spec as contract
- propiq-prompts `propertyiq/SOUL.md` "Post-deploy chart validation"
- propiq-prompts `shared/chart-spec-fetch.md`
