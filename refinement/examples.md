# Refinement worked examples

Pattern-match anchors for common cases. These are concrete to PropertyIQ, not generic.

## Example 1: Passed (straightforward feature)

**Issue body (paraphrased):**

> "Add min_price and max_price query params to `/api/areas/{area_id}/listings` in propiq-data-api. Should filter results before pagination."

**My decision:** Passed — needs-design

**Rationale:**

- Single repo, single endpoint, clear param signature
- Acceptance criteria inferred: new params, filter applies pre-pagination, existing tests still pass
- Non-trivial enough that Architect should spec the edge cases (what if min > max? string vs int coercion?)
- No constitutional violation

**Comment posted:**

```
<!-- propiq-bot:refinement -->
DECISION: passed
CONFIDENCE: high

**Refinement: Passed**

**Decision:** Clear, scoped feature addition to data-api filtering.

**Next stage:** needs-design

(Architect will spec edge case handling before Builder.)
```

## Example 2: Refined (ambiguous acceptance criteria)

**Issue body (paraphrased):**

> "The chart colors look wrong on the Dubai Marina area report."

**My decision:** Refined — needs-design

**Rationale:**

- Intent recoverable: chart color issue on a specific report
- Missing: which chart specifically, which colors, what "wrong" means
- I can edit body to add a "Pending clarification" section without changing meaning: mark that the specific chart identifier, expected color, actual color, and screenshot are needed before Design

But wait — this is borderline. Since my edits would be asking for more info, not clarifying, Bounced is actually better here.

**Revised decision:** Bounced

(See Example 3.)

## Example 3: Bounced (missing info)

**Issue body (same as Example 2, revised analysis):**

> "The chart colors look wrong on the Dubai Marina area report."

**My decision:** Bounced — needs-clarification

**Rationale:**

- Cannot identify which chart, which colors, what "wrong" means
- Can't Refine without adding meaning the filer didn't provide
- Can't Reject — it's a legitimate bug report, just incomplete

**Comment posted:**

```
<!-- propiq-bot:refinement -->
DECISION: bounced
CONFIDENCE: high

**Refinement: Bounced — awaiting clarification**

**Questions:**
1. Which specific chart in the Dubai Marina report? (e.g., price trend, transaction volume, area comparison)
2. What colors are you seeing that look wrong?
3. What color did you expect, and why? (e.g., brand palette mismatch, specific series confused with another)
4. If possible, paste the report URL or a screenshot.

**Next step:** Please answer in a comment, then re-apply the `needs-refinement` label.
```

## Example 4: Rejected (constitutional violation)

**Issue body (paraphrased):**

> "Add backward-compatibility aliases in the charts-api so old client code using `chart_type` param still works. Current code uses `intent` param."

**My decision:** Rejected

**Rationale:**

- `constitution.md` § Build philosophy: "State-of-the-art, resilient structure over quick fixes. Build solid, not fast."
- `constitution.md` is consistent with the established decision in `CLAUDE.md`: "NEVER add legacy/compound intent aliases"
- This is an unambiguous violation of a principle I can cite directly.

**Comment posted:**

```
<!-- propiq-bot:refinement -->
DECISION: rejected
CONFIDENCE: high

**Refinement: Rejected**

**Violation:** Adding backward-compatibility aliases to charts-api.

**Citation:** propiq-docs/constitution.md § Build philosophy, quoted: "State-of-the-art, resilient structure over quick fixes. Build solid, not fast." Also: propiq-charts-api CLAUDE.md explicitly forbids legacy/compound intent aliases (EPIC 2 alias PRs #121-124 rejected, March 2026).

**Rationale:** The pre-migration project state has zero production consumers. Adding compatibility shims creates debt without benefit. If there is active internal client code using `chart_type`, update the client code directly.

**Next step:** If the compatibility requirement comes from an external dependency we must honor, comment with details and re-apply `needs-refinement`.
```

## Example 5: Fastlaned (trivial fix)

**Issue body (paraphrased):**

> "Fix typo in propiq-reports-web homepage: 'propety' should be 'property'."

**My decision:** Fastlaned — needs-build

**Rationale:**

- Single-file change, obvious fix
- No design surface — Architect would have nothing to add
- Builder can execute directly

**Comment posted:**

```
<!-- propiq-bot:refinement -->
DECISION: fastlaned
CONFIDENCE: high

**Refinement: Fastlaned**

**Decision:** Trivial typo fix, skipping Design.

**Next stage:** needs-build

**Rationale for skipping Design:** Single-file text change.
```

## Anti-example: over-rejection

The temptation to reject anything that smells like "could conflict with constitution" is wrong. When constraints files are empty, I cannot cite them for rejection. When constitution says "X is forbidden" but the Issue merely implies X ambiguously, I Bounce and ask.

Over-rejection destroys Martin's trust in the pipeline. Under-rejection merely creates more downstream work. Prefer the second failure mode.
