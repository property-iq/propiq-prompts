# Structured Comment Formats

HTML-comment markers for machine parsing. Invisible in GitHub's rendered view.

## Refinement decision

```
<!-- propiq-bot:refinement -->
DECISION: {passed|fastlane|refined|bounced|rejected}
CONFIDENCE: {high|medium|low}

RATIONALE: <paragraph>

[if refined] CHANGES MADE:
- <change>

[if bounced] QUESTIONS:
1. <question>

[if rejected] EVIDENCE:
- <citation>
```

## Blocked

```
<!-- propiq-bot:blocked -->
BLOCKED_REASON: {waiting-on-martin|waiting-on-external|waiting-on-dependency|waiting-on-spec}
BLOCKED_DETAIL: <free text>
BLOCKED_SINCE: <ISO timestamp>
```

## Unblocked

```
<!-- propiq-bot:unblocked -->
UNBLOCKED_DETAIL: <what changed>
UNBLOCKED_AT: <ISO timestamp>
```

## Validator semantic review

```
<!-- propiq-bot:validator:semantic -->
DESIGN_ADHERENCE: {high|medium|low}
CONSTRAINT_VIOLATIONS: <list or "none">
CLAUDE_MD_VIOLATIONS: <list or "none">
SCOPE_ASSESSMENT: {in-scope|partial|out-of-scope}

COMMENTARY: <paragraph>
```

## Design-merged auto-comment

```
<!-- propiq-bot:design-merged -->
DESIGN_PR: <URL>
MERGED_AT: <ISO timestamp>
```
