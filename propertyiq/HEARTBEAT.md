# HEARTBEAT.md — PropertyIQ PM

This heartbeat fires every 30 minutes on `openai-codex/gpt-5.3-codex`. Single-tier operation — every beat runs the full PM loop.

## PM Loop

**P0. Pull latest prompts.** Before anything else:

```bash
cd ~/.openclaw/workspace/agents/propertyiq/.prompts-src && \
  git pull --quiet origin main || echo "prompt pull failed — continuing with cached prompts"
```

If the pull fails (network, auth, conflict), log to today's daily memory and continue. Never halt the heartbeat on a pull failure.

**P0.5. Heartbeat timestamp.** Write the Gatekeeper beacon:

```bash
date -u +"%Y-%m-%dT%H:%M:%SZ" > /Users/agent/.openclaw/workspace/agents/propertyiq/.last-heartbeat
```

**P1. Read Telegram inbox.** Check for messages from Martin since the last heartbeat. If he wrote something, respond or act; don't wait for the next beat.

**P2. Read GitHub notifications.** Scan for events in the 10 active property-iq repos. Every gh command MUST be prefixed with `GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm`:

```bash
export GH_CONFIG_DIR=/Users/agent/.config/gh-propiq-pm
gh api notifications --jq '.[] | select(.repository.owner.login == "property-iq") | {repo: .repository.name, reason: .reason, subject: .subject.title, url: .subject.url}'
gh pr list --search "org:property-iq is:open review-requested:@me"
```

Focus on: PRs awaiting Martin's review, new comments on open PRs, new Issues from Martin via Telegram intake, CI failures.

**P3. Read board health.** Fetch the PM board health endpoint:

```bash
curl -s https://propiq-pm-board.vercel.app/api/health
```

What to watch for:
- `drift_events_this_sync > 0` — the board disagreed with GitHub this sync; something upstream is wrong.
- `orphans.pr > 0` or `orphans.issue > 0` — merged PRs without linked Issues, or closed Issues without merged PRs. Investigate if they're post-baseline.
- `stale` non-zero in any category — tasks sitting too long without movement.
- `last_sync_at` older than ~90 minutes — sync may be broken.

If any of these are elevated compared to the last heartbeat, mention in the status report.

**P3.5. (chart-stack merges only) Refresh spec cache.** If P2 surfaced merges to chart-stack repos (`propiq-charts-img`, `propiq-charts-api`, `propiq-reports-web`, `propiq-charts-maps`), run `propertyiq/skills/chart-qa/fetch_spec.sh` to confirm the fetch path is healthy before the audit needs it. Skip on heartbeats with no chart-stack activity.

**P4. Triage.** Based on what P1–P3 surfaced:

- **Martin messaged with a build/decide/audit request** → evaluate using the four-outcomes decision tree in SOUL.md. File a GitHub Issue using the matching template (`.github/ISSUE_TEMPLATE/builder-task.md` for work, `audit-finding.md` for findings, `martin-direct.md` for decisions). Apply the appropriate routing label (`route:pipeline`, `route:manual`, or `route:idea`), plus `from:martin`, a priority (default `p2` unless Martin specified), and epic if obvious. The Refinement Routine will pick up `route:pipeline` Issues.
- **Martin messaged with a status question** → fetch board state (`curl /api/board`), format a concise answer, reply via Telegram.
- **PR is waiting for Martin's review for >24h** → surface it to him with the PR URL. Don't nag more than once per day per PR.
- **New GitHub comment on a PR** → if it's a `[BLOCKER]` or `[AGENT-REQUEST]` tagged by Routines, surface to Martin. If it's a discussion comment, do nothing.
- **Drift/orphan/stale alert from /api/health** → surface to Martin with the count and which category.
- **Nothing new** → reply with a status digest or stay silent if no signal has changed since last beat.

## Monday grooming (09:00 DXB only)

On Monday heartbeats only, surface two grooming lists to Martin before normal triage. Skip any list whose result set is empty (no noise when nothing's aged).

### Ideas older than 90 days

Query: `gh search issues --owner property-iq --state open --label "route:idea" --updated "<$(date -u -v-90d +%Y-%m-%d)"`

If non-empty, post to Telegram:

```
Weekly ideas review — {N} idea(s) older than 90 days:

- #{num} {title} (filed {days} days ago)
- #{num} {title} (filed {days} days ago)

Reply `close #N` / `promote #N` / `keep #N` for each:
- `close`: close the Issue.
- `promote`: relabel `route:idea` → `route:pipeline` (I apply the swap; Refinement Routine picks it up on next fire).
- `keep`: touch `updated_at` so it drops off the list for another 90 days.

No reply = no action (will surface again next week).
```

### Manual queue items older than 30 days with no PR

Query: `gh search issues --owner property-iq --state open --label "route:manual" --updated "<$(date -u -v-30d +%Y-%m-%d)"` — filter client-side for no linked PR.

If non-empty, post to Telegram:

```
Manual queue check — {N} item(s) older than 30 days with no PR:

- #{num} {title} (filed {days} days ago)
- #{num} {title} (filed {days} days ago)

Reply `defer #N` / `drop #N` / `keep #N` for each:
- `defer`: relabel `route:manual` → `route:idea` (I apply).
- `drop`: close the Issue.
- `keep`: touch `updated_at`; next review in 30 days.

No reply = no action.
```

Groom messages are distinct from normal heartbeat status reports — both can happen in the same Monday beat, but groom comes first.

## Gate check (internal — not shown to Martin)

Before exiting the heartbeat, verify:

1. Did I pull prompts in P0?
2. Did I check Telegram in P1?
3. Did I check GitHub in P2?
4. Did I check /api/health in P3?
5. Did I either take an action or consciously decide there was nothing to do?

If yes to all → `HEARTBEAT_OK`.
If any step was skipped → go back and do it before exiting.

## Reply format (when sending a heartbeat status to Martin)

Only send a heartbeat digest if Martin asked for one, if something new needs surfacing, or if it's the 06:00 morning summary window. Don't send a heartbeat reply every 30 minutes — Telegram noise is worse than silence.

When a reply is warranted:
📋 PropIQ — {HH:MM}
Board: {N} tasks · {N} in-progress · {N} needs-review · {N} blocked
PRs waiting on you: {N} ({list or "none"})
Health: {all green / drift:N / orphans:N / stale:N}
{Key things that changed since last beat, or "Nothing new."}

Keep it 5–10 lines. Natural language, no internal gate output, no ⛔ emoji.

## Morning summary (first heartbeat after 06:00 Madrid)

Send a daily digest regardless of signal:
Good morning — {date}
Overnight:

{N} PRs merged
{N} new Issues filed
{N} sync drift events handled
{any Routine activity — Refinement/Builder/Validator firings}

Waiting on you:

{PRs to review}
{any decisions needed}

Health: {summary}

## What NOT to do in a heartbeat

- Don't dispatch to Builder or QA. Those don't exist anymore — Routines fire on label transitions.
- Don't write to `workflow-state.md`. That file is obsolete.
- Don't maintain task state locally — always read `/api/board` and `/api/health`.
- Don't auto-merge PRs. Martin merges everything except QA regression reports (which self-merge via path-restricted carve-out).
- Don't spawn subagents (sessions_spawn). That machinery is gone.
- Don't touch the gateway (no restart, no kickstart, no pkill). Surface the need to Martin if it arises.
