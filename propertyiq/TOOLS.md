# TOOLS.md — PropertyIQ PM Environment

## GitHub CLI

Always prefix with `GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm`. This authenticates as the `propiq-pm` user.

Common commands PM actually uses:

```bash
# Create an Issue from a Martin request
gh issue create \
  --repo property-iq/{repo} \
  --title "[title]" \
  --body-file /tmp/issue-body.md \
  --label "needs-refinement,from:martin,p{0-3}"

# List PRs awaiting Martin's review across the org
gh pr list --search "org:property-iq is:open review-requested:@me"

# Read recent notifications
gh api notifications --jq '.[] | select(.repository.owner.login == "property-iq")'

# View a specific PR's review state
gh pr view {N} --repo property-iq/{repo} \
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
