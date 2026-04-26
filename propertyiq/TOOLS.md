# TOOLS.md — PropertyIQ PM Environment

## GitHub CLI

Always prefix with `GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm`. This authenticates as the `propiq-pm` user. The prefix is mandatory on every `gh` invocation — including the examples below.

Common commands PM actually uses:

```bash
# Create an Issue from a Martin request.
# Use exactly one routing label per Issue:
#   route:pipeline — clear, actionable pipeline work (default)
#   route:manual   — Martin handles it himself, or it's an out-of-pipeline service
#   route:idea     — someday/maybe, not actionable now
# The old `needs-refinement` label is deprecated — do not use it.
#
# This is ONE command, not a two-step chain. Pass the body inline with
# --body "...". Do not write a temp file first — that makes filing a
# two-call dance and PM tends to stop after the file write.
GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm gh issue create \
  --repo property-iq/{repo} \
  --title "[title]" \
  --body "## Context

{1-2 sentence summary of Martin's request}

## Acceptance criteria
- {criterion 1}
- {criterion 2}" \
  --label "route:pipeline,from:martin,p{0-3}"   # swap route:pipeline → route:manual / route:idea per classification

# List PRs awaiting Martin's review across the org
GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm gh pr list --search "org:property-iq is:open review-requested:@me"

# Read recent notifications
GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm gh api notifications --jq '.[] | select(.repository.owner.login == "property-iq")'

# View a specific PR's review state
GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm gh pr view {N} --repo property-iq/{repo} \
  --json reviews,mergeable,statusCheckRollup
```

Never use `gh merge`. Martin merges PRs (except QA report PRs, which self-merge).

## Board API

```bash
# Health — public, no auth
curl -s https://propiq-pm-board.vercel.app/api/health

# Full board state — Bearer auth
curl -s https://propiq-pm-board.vercel.app/api/board \
  -H "Authorization: Bearer ${BOARD_API_KEY}"
```

PM only reads. Board state comes from GitHub via the webhook and sync worker — never PATCH to the board.

## Telegram

- Bot: @ariju_propiq_bot with `accountId: "propertyiq"`
- Martin's chat: resolved from environment at runtime — `${MARTIN_TELEGRAM_CHAT_ID}`
- Always include `accountId: "propertyiq"` when calling the message tool.

## Workspace paths

- Prompts (read-only, pulled from propiq-prompts): `~/.openclaw/workspace/agents/propertyiq/.prompts-src/`
- Daily memory: `~/.openclaw/workspace/agents/propertyiq/memory/YYYY-MM-DD.md`
- Gatekeeper beacon: `~/.openclaw/workspace/agents/propertyiq/.last-heartbeat`

## Browser — READ ONLY

For visual validation tasks: chart renders on `reports.propertyiq.ae`, deploy previews, board UI checks, anything where a screenshot or DOM read answers a question faster than reading code.

### Tools available

- **Playwright Chromium headless** — primary path for public URLs. No auth, no shared state with the operator's browser. Use this for `reports.propertyiq.ae`, public GitHub pages, public Vercel previews.
- **Playwright CDP** (port 18800) — connects to the operator's running Chrome on `--remote-debugging-port=18800`, `--user-data-dir="$HOME/.config/chrome-openclaw"`. Has saved login sessions. Only use when an authenticated page is needed; default to headless.

Connect example (Python):

```python
from playwright.sync_api import sync_playwright
# Headless (default)
with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("https://reports.propertyiq.ae/chart/median_price_trend")
    page.wait_for_load_state("networkidle")
    page.screenshot(path="/tmp/chart.png", full_page=True)
    # ...read DOM, accessibility tree, console messages...
    browser.close()
```

### What I do with it

- Navigate to URLs (no clicks beyond link navigation)
- Read: screenshot (`page.screenshot`), DOM text, accessibility tree, console messages, network requests
- Visual validation: screenshot a chart and describe what's rendered (axes labeled, expected series present, no overlapping elements, no JS errors in console)
- Structural validation: read the Chart.js config from the page, verify expected data series, count rendered DOM elements

### What I never do

- Click anything that modifies state (no "submit," no form fills, no add-to-cart, no Telegram/WhatsApp send via web)
- Navigate to authenticated URLs without an explicit reason in Martin's request (don't leak session data through screenshots)

### When to use this

- Martin asks "did this chart render correctly?" or "is this deploy live?" or "does this PR's preview look right?"
- After a charts-img, charts-api, or reports-web PR merges, optionally proactive-validate that a known-good URL still renders (only if explicitly asked or if it's part of a documented validation routine — don't browse autonomously by default).
- Validating an Issue I filed has a working linked URL.

### Failure handling

If Playwright is unavailable, the connection fails, or the page errors:

- Report the error verbatim to Martin in Telegram.
- Do not retry silently. Do not make claims about what the page contains without a successful screenshot or DOM read.

## GCP (reference only)

- Project: `crowdproperty-440707`
- Region: `me-central1`
- Services: Cloud Run (data-api, charts-api, charts-img, etl-dld, reports-api, scout-news)
- Data warehouse: BigQuery
- Frontend: Vercel (reports-web, pm-board)

PM doesn't deploy or touch GCP directly. CI/CD handles Cloud Run auto-deploys on merge to main.
