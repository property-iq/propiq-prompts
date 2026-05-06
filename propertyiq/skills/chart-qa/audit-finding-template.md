# Audit Finding Template

Use this template for the Issue body when filing a chart-audit finding. Every field in the **Required** section must be populated. Omit the **Spec lag provenance** section when drift classification is not "spec lag."

---

```markdown
## Finding

<one-sentence summary of the violation>

## Spec rule violated

- `<rule_id>` — <paraphrase the rule from guidelines.md>
- (additional rules if multiple)

## Layer

`<existence | layout | visual | style>` — populated from the `layer` field on the Violation when the audit ran via REST. Omit when the finding came from a screenshot-only Playwright evaluation (legacy path).

## Audit summary

- **Error count:** `<error_count>` — populated from `AuditResult.error_count` (Tranche A.4 step 1). Read this for blocking decisions; the deprecated `passed` flag is no longer load-bearing in this template.
- **Warning count:** `<warning_count>` — informational; warnings annotate but do not block.
- **Severity breakdown:** `<severity_breakdown>` — per-severity counts including info-level (e.g. `{"error": 0, "warning": 2, "info": 0}`). Surface this when relevant for triage.
- **Dataset scope:** `<dataset_scope>` — the class of datasets the rule was evaluated against (`is_data` / `is_non_regression` / `is_regression` / `is_benchmark` / `all_datasets`). Per Tranche A.2, every rule declares its scope; surfacing this lets a reviewer see which subset the predicate iterated.

## Audit target

`<canonical fixtures | PageQA matrix | latest report (<grain>/<identifier>/<period>)>` — populated from the SKILL.md "Audit target selection" rule. Findings on PageQA-only variants are tagged `surface=pageqa-only` and route to `propiq-visualizer`; findings on canonical fixtures or production reports route per the drift-classification table. The audit target is a load-bearing context fact; never elide it.

## Predicate behavior anomaly suspected

_(populate this section only when the heuristic below fires; otherwise omit)_

When a rule fires across **100% of canonical fixtures** in a sweep, that's a strong signal the predicate is misbehaving (matching too broadly), not that every chart in the corpus is genuinely defective. The 2026-05-03 sweep's I020 cluster — every scatter chart "failing" because the rule iterated over the regression line — is the prototype.

If this finding is one of those:

- **State the suspicion explicitly.** Don't file as a chart defect.
- **Route to `propiq-charts-api`** as a predicate-bug Issue, not as a per-chart violation.
- **Cite the firing rate** (e.g., "fires on 100% of canonical scatter fixtures").
- Cross-reference the rule's `dataset_scope` declaration in `app/audit/rules/` for the reviewer.

## Context

- **Spec version:** <from spec-manifest.txt>
- **Surface:** <url, OR "REST audit" when no rendered surface>
- **Viewport:** <desktop / mobile / both, OR "n/a" for REST audits>
- **State:** <which tab/toggle was active, OR omit for REST audits>

## Evidence

- Screenshot(s): <attached>
- Console errors: <if any, verbatim>
- Network errors: <if any, verbatim>

## Drift classification

<one of: runtime regression / spec lag / ambiguous>

## Provenance for spec lag

_(omit this section if classification is not "spec lag")_

- Recent runtime change: <commit SHA + repo>
- Spec `last_reviewed`: <YYYY-MM-DD>

## Severity

<P0 / P1 / P2 / P3>

## Recommended fix

<concrete: which file/repo to amend>
```

---

## Labels

Apply these labels when filing:

- `route:pipeline` (or `route:manual` if ambiguous and Martin needs to decide)
- `from:audit`
- `p{0-3}` (matching severity above)
- `epic:charts`
