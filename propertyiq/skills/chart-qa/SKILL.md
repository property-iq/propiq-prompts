# SKILL.md — Chart Visual Audit

## Purpose

Validate rendered charts against the authoritative contract at `propiq-docs/charts/spec.yaml`. Every value PM checks comes from the resolved spec — never from memory, never from inline prompt values.

## Two audit paths

PM has two audit paths. **Pick the one that matches the audit target**, not your habit:

| Target | Path | Why |
|---|---|---|
| **Single chart** with a known intent + entities | **REST first** (`audit_via_rest.sh`) | Sub-second when no vision needed; ~3–8s with vision. No screenshot, no Playwright. |
| **Page** (rendered report or playground) with multiple charts in context | **Playwright + screenshots** (steps 1–3 below) | Catches surface-level issues: cross-chart layout, banners, console errors, viewport breakage. |
| **Sweep** of N > 3 charts | **REST in parallel, async** (see "Sweep-mode dispatch" below) | Avoids serial round-trips; bundles findings into one Telegram summary. |

REST-first means: most single-chart audits skip the screenshot path entirely. Playwright is reserved for surface audits and Layer 2b vision review.

## Pre-audit: fetch the spec

Before any evaluation, run:

```bash
bash propertyiq/skills/chart-qa/fetch_spec.sh
```

This writes:
- `$WORKSPACE_TMP/charts-spec/spec-resolved.yaml` — the contract with all `$tokens` references resolved
- `$WORKSPACE_TMP/charts-spec/spec-manifest.txt` — `spec_version` and `fetched_at` timestamp

**If the fetch fails, abort the audit.** Report the error verbatim to Martin. Never fall back to memorized or cached values — proceeding with stale data defeats the purpose of the spec contract.

## REST-first single-chart audit

When the target is one chart with a known intent and entities (the common case), use the REST path:

```bash
# Synchronous, sub-second. Layers: existence + layout + style. No vision.
echo '{"render_request": {"intent": "trend", "metric": "price", "entities": [{"type": "area", "identifier": "dubai-marina"}]}}' \
  | bash propertyiq/skills/chart-qa/audit_via_rest.sh --no-vision \
       --output "$WORKSPACE_TMP/audit_result.json"

# With Layer 2b vision audit (renders + uploads PNG; ~3–8s).
echo '{"render_request": {...}}' \
  | bash propertyiq/skills/chart-qa/audit_via_rest.sh --include-image \
       --output "$WORKSPACE_TMP/audit_result.json"
```

The script's output is the `AuditResult` JSON: `passed`, `violations[]`, `summary`, `audit_coverage`. Each violation carries a `layer` field (`existence` / `layout` / `style` / `visual`). Exit 0 iff `passed: true`.

If the chart isn't already rendered (you have a `ChartRequest` rather than a `chart_response.config`), pass `render_request` and the API renders + audits in one round-trip.

## Sweep-mode dispatch

When auditing N > 3 charts (e.g. *"audit all charts in the April market report"*):

1. **Acknowledge immediately on Telegram**: *"Auditing N charts; will report back when complete."*
2. **Run audits in parallel**, bounded at 5 concurrent (matches `chart_concurrency` elsewhere in the stack). Use `xargs -P 5` or a small async wrapper.
3. **Post a follow-up Telegram message** with a structured summary: per-chart pass/fail, per-layer counts, top violations. Don't surface findings in real time — batch them.
4. **For each chart with violations**, file Issues per the drift-classification mapping below.

For ≤ 3 charts, dispatch synchronously and post findings inline.

For single-chart audits where Martin needs sub-second turnaround, use `--no-vision`.

## Evaluation flow (page-level / surface audit / Layer 2b)

When the target is a full page or you specifically need Layer 2b vision review on rendered output, follow steps 1–6 below. This path uses Playwright + screenshots.

### 1. Identify the surface

Pick one canonical surface per audit (see SOUL.md "Canonical chart surfaces"):
- Rendered reports: `https://reports.propertyiq.ae/reports/market/{YYYY-MM}`
- Visualizer playground: `https://propiq-visualizer.vercel.app/playground`

### 2. Screenshot every state

For each chart on the surface:
- **Dual viewport** — desktop (1280x800) AND mobile (390x844). One viewport breaking = breakage.
- **State enumeration** — if the chart has tabs, period toggles, segment selectors, or comparison toggles, screenshot each visible state. Default-only is insufficient.
- Save screenshots to `$WORKSPACE_TMP/` (not `/tmp/` — the image tool's allowed-directories list excludes `/tmp/`).

### 3. Evaluate against the resolved spec

Open `$WORKSPACE_TMP/charts-spec/spec-resolved.yaml` and check each applicable rule:

**Universal rules** (apply to all charts):
- `U001` — opaque background matching `chart_background` token
- `U002` — single non-regression series uses gold accent; benchmark styling only when 2+ series
- `U003` — Y-axis grid subtle, X-axis grid hidden
- `U004` — no currency in tick labels; compact K/M/B notation
- `U005` — font family matches `font_family` token
- `U006` — line tension matches spec value
- `U007` — benchmark styling: dashed, order 1, no fill

**Context-specific rules:**
- Dynamic mode: `D001`–`D004` (tick font sizes, legend visibility, animation, tooltips)
- Static mode: `S001`–`S003` (no callbacks, no gradients, title in frame)

**Per-intent rules** — check the rules for the specific intent being rendered:
- Horizontal bar: `I001`–`I005`
- Trendline: `I010`–`I013`
- Scatter: `I020`–`I023`
- Quadrant: `I030`–`I031`
- Matrix: `I040`–`I043`
- Box plot: `I050`–`I052`
- Data table: `I060`–`I061`

**Format assignments** — verify tick/label formatting matches the `format_assignments` section for each metric.

For quick human scanning during evaluation, reference `piq-style-quickref.md` — it's the same content as the spec, formatted for readability.

### 4. Check for errors

- Read `console.error` events during render
- Check for failed network requests
- Note any JS exceptions or rendering timeouts

### 5. Classify findings

For each deviation found, determine whether it's:

1. **Runtime regression** — runtime drifted from spec; runtime is wrong.
   - No recent runtime change explains the deviation.
   - File an Issue against the relevant runtime repo (charts-api / charts-img / reports-web).

2. **Spec lag** — runtime is correct; spec hasn't caught up to a recent intentional change.
   - A runtime change post-dates `last_reviewed` in spec.yaml.
   - The rendered behaviour matches the runtime change.
   - File an Issue against `propiq-docs` proposing the spec update, citing the runtime commit SHA.

3. **Ambiguous** — unclear which side is wrong (e.g., partial migration in flight).
   - Do not file. Surface to Martin in Telegram with both possibilities listed.

#### Drift-classification by layer

When the violation came from REST, the `layer` field on each Violation tightens routing. Drift-classification is preserved per finding — there is no blanket route.

| Layer | Typical drift routing |
|---|---|
| **`existence` (Layer 1)** | Drift-classify case-by-case. Most route to `propiq-charts-api` (chart contract issue) or upstream (`propiq-data-api`, `propiq-docs`) when the data itself is missing. Empty datasets often indicate a data-api gap, not a charts-api bug. |
| **`layout` (Layer 2a)** | Drift-classify between `propiq-charts-api` (sizing logic), `propiq-docs/charts/spec.yaml` (rule thresholds), and `app/styling/themes/base.yaml` (token values). A predicate firing at high false-positive rate is itself a signal — file against `propiq-docs` to revisit the threshold. |
| **`visual` (Layer 2b)** | Always `propiq-charts-api` or `propiq-charts-img` — vision findings are about rendering output, never about spec drift. |
| **`style` (Layer 3)** | Existing routing preserved. Spec-rule predicates → `propiq-charts-api` (runtime regression) or `propiq-docs` (spec lag). |

When the violation came from a screenshot evaluation (Playwright path), the legacy classification rules above apply unchanged.

### 6. Report

- **No findings** — silent. Don't notify on healthy deploys.
- **Findings exist** — use `audit-finding-template.md` for each Issue body. Always include:
  - The violated rule ID(s)
  - The `spec_version` from `spec-manifest.txt`
  - The drift classification
  - Screenshots from both viewports
- **Audit aborted** (fetch failure, Playwright failure) — report verbatim to Martin.

## Boundaries

- PM does not fix what it finds. PM files Issues or surfaces to Martin.
- PM does not write to `propiq-docs/charts/`. Spec updates go through the normal pipeline (Issue → Refinement → design → build).
- PM does not autonomously browse beyond the canonical surfaces.
- When reporting a finding, cite the spec rule and paraphrase from `charts/guidelines.md` for human-readable rationale — never quote guidelines verbatim.
