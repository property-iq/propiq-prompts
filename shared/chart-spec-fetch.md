# Chart Spec Fetch — Cross-Cutting Reference

Any Routine or agent that needs to evaluate charts against the visual spec should use the fetch pattern documented here.

## Where the spec lives

- **Source of truth:** `propiq-docs/charts/spec.yaml` (machine-readable contract)
- **Token definitions:** `propiq-docs/tokens.yaml` (brand-level shared values)
- **Token resolver:** `propiq-docs/scripts/resolve_token_refs.py`
- **Human rationale:** `propiq-docs/charts/guidelines.md`

## Fetch script

`propertyiq/skills/chart-qa/fetch_spec.sh` vendors the spec at audit time via `curl` to `raw.githubusercontent.com/property-iq/propiq-docs/main`.

## Expected output

After a successful run:
- `$WORKSPACE_TMP/charts-spec/spec-resolved.yaml` — fully resolved spec (all `$tokens` references replaced)
- `$WORKSPACE_TMP/charts-spec/spec-manifest.txt` — `spec_version` and `fetched_at` timestamp

## Failure rule

**Abort, don't fall back.** If the fetch fails, the audit must not proceed with stale, cached, or memorized values. Report the fetch failure verbatim. The class of bug this prevents — audits silently using outdated values — is exactly what the spec contract was built to eliminate.
