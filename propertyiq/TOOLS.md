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
GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm gh issue create \
  --repo property-iq/{repo} \
  --title "[title]" \
  --body-file /tmp/issue-body.md \
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

## GCP (reference only)

- Project: `crowdproperty-440707`
- Region: `me-central1`
- Services: Cloud Run (data-api, charts-api, charts-img, etl-dld, reports-api, scout-news)
- Data warehouse: BigQuery
- Frontend: Vercel (reports-web, pm-board)

PM doesn't deploy or touch GCP directly. CI/CD handles Cloud Run auto-deploys on merge to main.
