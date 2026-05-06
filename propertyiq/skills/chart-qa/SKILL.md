# SKILL.md — Chart Visual Audit

## Purpose

Validate rendered charts against the authoritative contract at `propiq-docs/charts/spec.yaml`. Every value PM checks comes from the resolved spec — never from memory, never from inline prompt values.

## Two audit paths

PM has two audit paths. **Pick the one that matches the audit target**, not your habit:

| Target | Path | Why |
|---|---|---|
| **Single chart** with a known intent + entities | **REST first** (`audit_via_rest.sh`) | Sub-second when no vision needed; ~3–8s with vision. No screenshot, no Playwright. |
| **Page** (rendered report or playground) with multiple charts in context | **Playwright + screenshots** (steps 1–3 below) | Catches surface-level issues: cross-chart layout, banners, console errors, viewport breakage. |
| **Sweep** of N > 3 charts | **REST in parallel, async** (see "Pacing protocol → Sweep mode" below) | Avoids serial round-trips; bundles findings into one Telegram summary. |

REST-first means: most single-chart audits skip the screenshot path entirely. Playwright is reserved for surface audits and Layer 2b vision review.

## Audit target selection

Pick the audit target deliberately. PM defaults are explicit; surface choice is a load-bearing decision because findings against different surfaces route differently and have different stability properties.

| Target | When to use | Routing of findings |
|---|---|---|
| **Canonical fixtures** *(default once Tranche E lands)* | Baseline regression detection — the production-shaped chart requests `propiq-reports-api/app/generation/visual_rendering.py` actually emits | `propiq-charts-api` (runtime regression) or `propiq-docs` (spec lag), per drift classification |
| **PageQA matrix** *(opt-in)* | Surface coverage — exhaustive variants generated from runtime capabilities, used by the visualizer | Tag findings with `surface=pageqa-only` and route to `propiq-visualizer` issues. PageQA generates variants that production never uses; findings only on the matrix are surface-level, not production defects |
| **Latest rendered report** *(opt-in, never default)* | Report-specific QA when Martin asks about a specific report run | When used, name the report identifier explicitly in every reply (`market 2026-04`, etc.). Never elide the target — different runs have different defects |

Until canonical fixtures (Tranche E) ship, the **default is the deterministic PageQA matrix snapshot** at the spec.yaml version current at audit time. Document the snapshot version in the audit reply so reviewers can correlate findings.

**Why this matters.** The 2026-05-03 sweep transcript showed the agent anchoring on the latest rendered report by default — which means audit results were a function of which report had run most recently, not a stable basis for evaluation. The target selection above makes the basis explicit.

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

The script's output is the `AuditResult` JSON: `error_count`, `warning_count`, `severity_breakdown`, `violations[]`, `summary`, `audit_coverage`, plus the deprecated `passed` field for backward compat. Each violation carries a `layer` field (`existence` / `layout` / `style` / `visual`). **Exit 0 iff `error_count == 0`** (no error-severity findings); warnings do not change the exit code. The `passed` field is deprecated — read `error_count` directly when you need the gate.

If the chart isn't already rendered (you have a `ChartRequest` rather than a `chart_response.config`), pass `render_request` and the API renders + audits in one round-trip.

## Pacing protocol

The 2026-05-03 sweep transcript exposed PM leaking background-sweep summaries into Telegram while Martin had explicitly asked to proceed one-by-one. The bridge is purely reactive (it doesn't surface tool-completion events the agent didn't author); the discipline is fully agent-side. Pacing is not optional.

### One-by-one mode

When Martin says *"one by one"*, *"one at a time"*, or any equivalent (the user is asking PM to pace itself):

1. **Suspend any in-flight bulk sweep.** Do not start a new one.
2. **Emit exactly one chart's audit result per turn.** Include `error_count`, `warning_count`, `audit_target`, layer breakdown.
3. **Wait for explicit user advance** (*"next"*, *"continue"*, or equivalent). Do not advance autonomously.
4. **Do not surface bulk-sweep summaries** in this mode, even if a background sweep completes. Surfacing background-completion events is what the 2026-05-03 transcript exposed; the bridge cannot suppress what PM emits.

### Sweep mode

When the request is a sweep (e.g. *"audit all charts in the April market report"*, N > 3 charts):

1. **Acknowledge scope upfront.** *"Auditing N charts in [target]; will report back when complete."* Name the audit target (canonical fixtures / PageQA matrix / specific report).
2. **Run audits in parallel**, bounded at 5 concurrent (matches `chart_concurrency` elsewhere in the stack). Use `xargs -P 5` or a small async wrapper.
3. **Post one consolidated summary at the end.** Per-chart `error_count` / `warning_count`, per-layer counts, top violations across the sweep. **Do not interleave per-chart findings during the sweep** — batch them.
4. **For each chart with violations**, file Issues per the drift-classification mapping below.

For ≤ 3 charts and not in one-by-one mode, dispatch synchronously and post findings inline.
For single-chart audits where Martin needs sub-second turnaround, use `--no-vision`.

### Mode disambiguation

If Martin's request is ambiguous between one-by-one and sweep, **default to one-by-one and ask**: *"Sweep all N or proceed one at a time?"* Sweep mode commits to a longer turnaround; getting it wrong wastes time twice (sweep when one-by-one was wanted, or vice versa).

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

## Attaching chart images to replies (α envelope)

When a finding warrants a rendered chart image (proof of a visual defect, before/after for Martin's review), emit images via the **α envelope** shape, not via path strings.

### Do this

When PM's reply includes images, the structured envelope is:

```json
{
  "schema_version": "1",
  "text": "<reply body — audit summary, findings, etc.>",
  "attachments": [
    {
      "url": "<signed URL from render_chart_image>",
      "content_type": "image/png",
      "alt_text": "<chart title or '<metric> <intent> chart — <entities> — <viewport>'>",
      "width": 1600,
      "height": 1000
    }
  ]
}
```

The OpenClaw → Telegram bridge consumes `attachments[]` and dispatches `sendPhoto` with `caption=alt_text` for image content types. Multiple attachments → one `sendPhoto` per entry. Non-image content types fall back to a labeled link in the text body.

The signed URL comes from the `render_chart_image` MCP tool, which returns the envelope-shaped `attachments[]` field directly. Pass it through unchanged.

### Do NOT do this

**Never emit `MEDIA: /tmp/...png` strings in chat output.** That convention was an attempt to signal image attachment via in-band text, observed on 2026-05-03 leaving file paths in user-visible Telegram messages. The bridge does not parse `MEDIA:` strings and never will. The α envelope is the only protocol.

PM does not write paths, file:// URIs, or inline image markup either. Image references are structured metadata in `attachments[]` or they don't exist.

### During the deprecation window

The bridge accepts both the legacy `{text, mediaUrls}` reply shape and the α envelope `{schema_version, text, attachments[]}` for one release cycle (per the OpenClaw α envelope spec, Conflict-4 resolution). PM emits the α envelope by default; the bridge falls back to its existing `mediaUrls` extraction for any legacy reply that doesn't include `attachments[]`. After the bridge's `OPENCLAW_DISPATCHER_ALPHA_ENVELOPE` flag flips on permanently and the `MEDIA:` smoke detector quiets, the legacy shape is deprecated.

## Boundaries

- PM does not fix what it finds. PM files Issues or surfaces to Martin.
- PM does not write to `propiq-docs/charts/`. Spec updates go through the normal pipeline (Issue → Refinement → design → build).
- PM does not autonomously browse beyond the canonical surfaces.
- When reporting a finding, cite the spec rule and paraphrase from `charts/guidelines.md` for human-readable rationale — never quote guidelines verbatim.
- PM does not emit `MEDIA:` path strings in chat output (per α envelope section above). Image references are always structured metadata.
- PM does not amplify background-sweep completion events into Telegram during one-by-one mode (per pacing protocol). Surfacing what Martin didn't ask for is the failure mode that motivates this section.
