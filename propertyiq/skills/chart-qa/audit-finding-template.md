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
