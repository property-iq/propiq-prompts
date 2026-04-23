# Architect worked examples

## Example 1: New UI feature (typical first-time invocation)

**Issue:** property-iq/propiq-visualizer#107

Adds a new page in Visualizer that takes a full HTTP request as input, renders the chart response, with auto device detection and a desktop-only cross-device preview.

**My action:**

1. Read Issue body + Refinement passed decision
2. Read propiq-visualizer CLAUDE.md (stack, patterns)
3. Read propiq-visualizer source — understand existing page structure, how charts are currently rendered, existing HTTP clients
4. Read constitution.md — no immediate conflict
5. Draft design covering:
   - New route `/playground` or similar
   - Component: request editor (method + URL + headers + body)
   - Chart rendering reuses existing chart component
   - Device detection via `window.matchMedia` or existing utility if present
   - Preview mode: iframe triple-render on desktop only, or CSS transform approach — I'd pick the approach matching existing patterns
   - State management per existing patterns
6. Create `designs/visualizer/107-http-request-playground.md` with the full template
7. Open PR against propiq-docs on `claude/107-design-http-request-playground`
8. Apply `design-pending-review` on Issue #107, remove `needs-design`

## Example 2: Revision (Martin asked for changes)

**Scenario:** Martin reviewed the Example 1 design PR, left comments: "Prefer server-side request execution over client-side for CORS reasons" and "Use the existing breakpoints from reports-web, don't invent new ones."

He applied `revise-design`.

**My action:**

1. Read Martin's review comments + existing design PR
2. Check out existing branch `claude/107-design-http-request-playground`
3. Amend design.md:
   - Update "Detailed design" to specify server-side execution via a new Next.js API route
   - Update "Architecture" to reference `propiq-reports-web/styles/breakpoints.ts` (or wherever breakpoints live)
   - Update "Alternatives considered" to note client-side rejected for CORS
4. Commit: `design: incorporate server-side execution and shared breakpoints`
5. Post PR comment:

> **Revision 1/3 per Martin's review:**
> - Server-side request execution (CORS concern addressed)
> - Breakpoints reference existing reports-web values

6. Remove `revise-design` from Issue, apply `design-pending-review`

## Example 3: Constitutional violation in Issue body

**Issue:** "Add a fallback mode to charts-api that returns v1 response format if the client sends `Accept: application/vnd.propiq.v1+json`"

**My action:**

1. Read constitution.md § "No legacy code": "No legacy parameters, no legacy intents, no fallback mechanisms."
2. This is a direct violation. Not ambiguous — no design can resolve it.
3. Post comment on Issue:

```
<!-- propiq-bot:architect -->

**Architect: Rejected — constitutional violation**

**Violation:** Issue asks for a fallback response format based on the Accept header, which is a compatibility shim.

**Citation:** propiq-docs/constitution.md § "No legacy code", quoted:

> "No legacy parameters, no legacy intents, no fallback mechanisms."

**Rationale:** The constitution forbids compatibility shims. The project has zero production consumers to preserve format compatibility for.

**Next step:** If there is a specific external consumer we must preserve compatibility with, document it and re-file. Otherwise, update the relevant clients to the current format instead of adding server-side fallback.
```

4. Apply `rejected`, remove `needs-design`. Do not open a design PR.

## Example 4: Structural ambiguity → surface back

**Issue:** "Improve the reports page loading experience."

**My action:**

1. Read Issue — vague. No specific page, no specific metric, no specific user journey.
2. This isn't a design decision I can make; it's a scoping decision that needs Martin.
3. Post comment:

```
<!-- propiq-bot:architect -->

**Architect: Surfacing — structural ambiguity**

**What's unclear:**
1. Which reports page? (there are 3: /reports/area, /reports/developer, /reports/project)
2. What does "loading experience" mean specifically? (initial page render, chart hydration, scroll performance, navigation transitions)
3. What's the target? (specific perceived-latency number, subjective "faster", specific browser/device class)

**My recommendation:** Refinement didn't catch this — re-opening to Refinement with specific questions would produce a much better-formed Issue than me designing against assumed scope.
```

4. Apply `needs-attention`. Do not remove `needs-design`.

## Anti-example: Design overload

**Wrong approach:** For a simple "add sorting to the areas list" Issue, produce a 500-line design covering:
- Sort algorithm choice (merge sort vs. quicksort)
- Database query optimization strategies
- Frontend state management patterns
- ARIA accessibility implications
- i18n considerations for sort keys
- Performance benchmarks

**Correct approach:** Design is ~50-100 lines covering:
- Which field(s) can be sorted (from Issue + existing UI)
- Backend: add `sort` and `order` query params to endpoint
- Frontend: add column-click handler with asc/desc toggle
- Acceptance criteria per Issue

Depth should match task complexity. Over-designing wastes Builder time and makes Martin's review harder.
