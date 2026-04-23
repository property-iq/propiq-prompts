# Validator worked examples

## Example 1: Clean fast-lane PR (happy path)

**PR:** Builder's typo fix PR (from builder/examples.md Ex. 1).

**My action:**

1. Clone branch `claude/42-fix-homepage-typo`
2. Run `npm test` — passes. Post check run `builder/tests` = success.
3. Run `npm run lint` — passes. Post `builder/lint` = success.
4. Run `tsc --noEmit` — passes. Post `builder/types` = success.
5. Read PR diff: single-line change in pages/index.tsx. Matches Issue exactly.
6. Post semantic comment:

```
<!-- propiq-bot:validator:semantic -->
DESIGN_ADHERENCE: high
CONSTRAINT_VIOLATIONS: none
CLAUDE_MD_VIOLATIONS: none
SCOPE_ASSESSMENT: in-scope
MECHANICAL_SUMMARY: passed

**Validator review**

**Mechanical:** passed — all 3 check runs green

**Semantic:**
- **Design adherence:** Implementation matches the Issue exactly.
- **Constraint violations:** none
- **CLAUDE.md violations:** none
- **Scope:** In scope — single-file typo fix.

Looks clean — merge at Martin's discretion.

---
_Semantic checks are advisory in v1. Only mechanical failures block merge._
```

7. Remove `needs-validation`, apply `validation-passed` + `ready-for-review`.

## Example 2: Mechanical failure

**PR:** Same as Ex. 1 but Builder's change broke an unrelated snapshot test.

**My action:**

1. Clone, run `npm test` — 1 test fails (`__tests__/homepage.test.tsx.snap`).
2. Post check run `builder/tests` = failure with snippet of the diff.
3. Continue to lint + types — both pass. Post them as success.
4. Post semantic comment (still posted — Builder can see where they stand on semantic even while fixing mechanical):

```
<!-- propiq-bot:validator:semantic -->
DESIGN_ADHERENCE: high
CONSTRAINT_VIOLATIONS: none
CLAUDE_MD_VIOLATIONS: none
SCOPE_ASSESSMENT: in-scope
MECHANICAL_SUMMARY: failed

**Validator review**

**Mechanical:** failed — 1 test failure in `builder/tests` (snapshot mismatch in homepage.test.tsx.snap). Other checks pass.

**Semantic:**
- **Design adherence:** Implementation matches the Issue.
- **Constraint violations:** none
- **CLAUDE.md violations:** none
- **Scope:** In scope.

Snapshot needs updating — `npm test -- -u` likely fixes it. Re-push after updating and re-apply `needs-validation`.

---
_Semantic checks are advisory in v1. Only mechanical failures block merge._
```

5. Remove `needs-validation`, apply `validation-failed`.

## Example 3: Environment failure

**PR:** Builder's PR against a repo where CLAUDE.md doesn't exist.

**My action:**

1. Try to read `CLAUDE.md` — not found.
2. Post check run `builder/environment` = failure with message "CLAUDE.md missing — cannot determine test/lint/type commands."
3. Post semantic comment with a single-line elaboration acknowledging I can't semantic-evaluate without repo conventions.
4. Remove `needs-validation`, apply `validation-failed`.
5. File a meta-Issue recommendation: "CLAUDE.md missing in {repo} — block further fast-lane Builder work until resolved." This is a one-line comment on the PR, not a new Issue (Validator doesn't file Issues).

## Example 4: Clean mechanical, soft semantic concern

**PR:** Builder added min_price/max_price filters (from builder/examples.md Ex. 3), but forgot to update the OpenAPI response schema.

**My action:**

1. Mechanical: all 3 pass.
2. Semantic: notice the schema mismatch. Post:

```
<!-- propiq-bot:validator:semantic -->
DESIGN_ADHERENCE: medium
CONSTRAINT_VIOLATIONS: none
CLAUDE_MD_VIOLATIONS: none
SCOPE_ASSESSMENT: partial
MECHANICAL_SUMMARY: passed

**Validator review**

**Mechanical:** passed — all 3 check runs green

**Semantic:**
- **Design adherence:** Implementation works but OpenAPI schema doesn't reflect new query params — consumers won't see them.
- **Constraint violations:** none
- **CLAUDE.md violations:** none
- **Scope:** Partial — API works, docs don't reflect it.

Note the OpenAPI schema for GET /areas/{area_id}/listings doesn't include the new min_price/max_price params. Consumers won't discover them via /docs. Worth adding before merge.

---
_Semantic checks are advisory in v1. Only mechanical failures block merge._
```

3. Remove `needs-validation`, apply `validation-passed` + `ready-for-review`. Mechanical passed; the OpenAPI concern is semantic and advisory. Martin sees the comment on review and decides whether to bounce for a docs fix or merge and file a followup.
