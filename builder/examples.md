# Builder worked examples

Pattern-match anchors for common fast-lane cases.

## Example 1: Typo fix (simplest fast-lane)

**Issue:** "Fix typo in propiq-reports-web homepage: 'propety' should be 'property'."

**My action:**

1. Read CLAUDE.md in propiq-reports-web for test command
2. Grep for 'propety' in the codebase — one match in `pages/index.tsx`
3. Fix the typo
4. Run `npm test` — passes
5. Run `npm run lint` — passes
6. Open PR with:

```
<!-- propiq-bot:builder -->

## Summary
Fixes a typo on the homepage: "propety" → "property".

## Changes
- `pages/index.tsx`: Fixed typo in the hero copy.

## Tested
- [Manual]: Ran `npm test` and `npm run lint`, both pass.

## Deliberately not touched
- Did not grep for other typos in the codebase — this Issue is scoped to the specific instance reported.

## Design reference
fast-lane, no design required

## Acceptance criteria
- [x] "propety" no longer appears on the homepage

Fixes #42
```

7. Apply `needs-validation` to the PR
8. Remove `needs-build` from Issue #42

## Example 2: Dependency bump (typical fast-lane)

**Issue:** "Update `axios` from 1.6.0 to 1.7.2 in propiq-data-api — security advisory."

**My action:**

1. Read CLAUDE.md — uses `pip` not `npm`. Wait — re-check. Issue mentions axios which is a JS library. CLAUDE.md says Python. This is contradictory. STOP and surface.
2. Apply `needs-attention`. Comment:

> Builder stopped — Issue references `axios` (JS library) but CLAUDE.md says this repo is Python/FastAPI. Please clarify: is this the wrong repo, or is there a JS subdirectory I should look at?

3. Do not open a PR.

## Example 3: Single-file behavior change

**Issue:** "Add `min_price` and `max_price` query params to `/api/areas/{area_id}/listings` in propiq-data-api. Filter results before pagination."

Refinement decision: `fastlane` (reconsidered as simple enough). Label: `needs-build`.

**My action:**

1. Read CLAUDE.md for test command: `pytest`
2. Find the endpoint handler — one file: `src/api/areas.py`, function `list_listings`
3. Add `min_price: Optional[float] = None, max_price: Optional[float] = None` to signature
4. Add filter before pagination:
   ```python
   if min_price is not None:
       query = query.filter(Listing.price >= min_price)
   if max_price is not None:
       query = query.filter(Listing.price <= max_price)
   ```
5. Add tests: `test_listings_with_min_price`, `test_listings_with_max_price`, `test_listings_with_both`, `test_listings_with_invalid_range_min_gt_max`
6. Run `pytest` — new tests pass, old tests pass
7. Update OpenAPI docs if auto-generated (FastAPI handles this)
8. Update `propiq-docs/qa/test-registry.md` to add a new registry entry for the filtered listings endpoint (spec §10.8.3 — Builder owns registry updates)
9. Open PR with full description, apply `needs-validation`.

## Anti-example: Scope creep

**Issue:** "Fix chart legend color on `/reports/area/{slug}` — should be gold not black."

**Wrong approach:**

- Fix the legend color
- "While I'm here, also fix the chart axis label font"
- "And standardize the color across all 3 chart types"
- Open a PR with all three changes

**Correct approach:**

- Fix ONLY the legend color
- If I notice other issues, file SEPARATE Issues for them via comment on the original Issue ("Separately: the axis label font is inconsistent — worth its own Issue?")
- Let Martin/PM decide whether to batch them

Fast-lane = minimum diff to close the Issue. Anything more is a Refinement failure, not a Builder opportunity.

## Anti-example: Introducing legacy

**Issue:** "Remove `include_legacy_format` param from `/api/reports/{id}`."

**Wrong approach:** Remove the param but keep the internal branching logic behind a default "just in case."

**Correct approach:** Remove the param and the branching logic. If downstream code breaks, fix downstream code. Per constitution § "No legacy code", there are zero production consumers. Clean deletion, no compatibility layer.
