# RUNBOOK.md — PropertyIQ PM operations

Operational reference for PropertyIQ PM (the OpenClaw agent at propertyiq on the Mini). Covers known regressions, validation procedures, and detection triggers. Distinct from SOUL.md / TOOLS.md which describe the agent's behavior and environment — this doc is for the human operator.

---

## Known regression: PM stops tool-calling

### Symptom

PM appears to understand and classify requests correctly in Telegram replies but does not execute any tool calls. No corresponding GitHub Issue appears. Reply pattern escalates over time:

- "I'll file this as a pipeline task" (future tense)
- "Filed as pipeline work" (past-tense claim, no Issue exists)
- "I've captured it as a pipeline task" (past-tense claim, hallucinated success)

The Telegram replies look correct in classification language and tone, so the bug is hard to catch from chat alone. Verification requires the session log on the Mini.

### Detection

Run on the Mini after any session you want to verify:

```bash
LATEST=$(ls -t ~/.openclaw/agents/propertyiq/sessions/*.jsonl | head -1)
echo "thinkingLevel: $(grep -m1 '"type":"thinking_level_change"' $LATEST | python3 -c 'import sys,json; print(json.loads(sys.stdin.read()).get("thinkingLevel"))')"
echo "toolCall count: $(grep -c '"type":"toolCall"' $LATEST)"
```

If thinkingLevel: off and toolCall count: 0 after a turn where PM claimed to file something — you're looking at this regression.

### Root cause

`~/.openclaw/openclaw.json` is missing `agents.defaults.thinkingDefault`. OpenClaw's runtime cascade falls through to the literal "off" when no override is set. Codex models at thinkingLevel: off do not invoke tools — they produce text replies only.

### Fix

Add one line to `agents.defaults` in `~/.openclaw/openclaw.json`:

```diff
       "subagents": {
         "maxConcurrent": 2,
         "archiveAfterMinutes": 240
-      }
+      },
+      "thinkingDefault": "low"
```

Then restart the gateway and wipe propertyiq sessions so the next cold-start picks up the new default:

```bash
openclaw gateway restart
mv ~/.openclaw/agents/propertyiq/sessions ~/.openclaw/agents/propertyiq/sessions.pre-fix-$(date +%Y%m%d-%H%M%S)
mkdir ~/.openclaw/agents/propertyiq/sessions
```

Wait for the next heartbeat (≤30 min) or fire a Telegram intake to validate.

### Schema gotcha

`thinkingDefault` is the config key (where new sessions default to). `thinkingLevel` is the per-session runtime property (set via the dashboard or session API). They are not interchangeable. `thinkingLevel` in `openclaw.json` is rejected as `Unrecognized key` everywhere.

The only accepted slot for `thinkingDefault` in this schema version is `agents.defaults.thinkingDefault` (global). Per-agent and per-model overrides via `agents.list[].model.thinkingDefault` and `agents.defaults.models.<id>.thinkingDefault` are both rejected as of OpenClaw 2026.2.26 (bc50708).

### When to re-check

After any of these, re-run the detection check:

- OpenClaw binary upgraded (`npm i -g openclaw@latest` or equivalent)
- `openclaw configure` wizard run
- `openclaw doctor --fix` run (strips unrecognized keys)
- Agent migration touching `agents.defaults` or per-agent model blocks
- After restoring `openclaw.json` from a backup file

---

## Validation procedure (Front 1 routing triad)

After any prompt change, config edit, or fix, run all three classification tests via Telegram. PR ships only when all three pass.

### Test A — route:pipeline (default actionable work)

```
Add a validator check for missing acceptance criteria on Issues labeled route:pipeline
```

Expected: PM asks one clarifying question, then files in propiq-pm-board with `route:pipeline,from:martin,p{2-3}`.

### Test B — route:manual (Martin handles it)

```
I'm already working on a CSV export bug in propiq-reports-web. File it for tracking — I'll handle the fix myself.
```

Expected: filed in propiq-reports-web with `route:manual,from:martin,p{2-3}`. No clarifying question needed.

### Test C — route:idea (someday/maybe)

```
What if PropertyIQ pulled in Dubai Land Dept transaction data monthly?
```

Expected: filed in propiq-etl-dld with `route:idea,from:martin,p{2-3}`. Clarifying question is acceptable here too.

### Verification from the laptop

```bash
gh search issues --owner property-iq --created ">=$(date -u +%Y-%m-%d)" --limit 10
```

All three Issues should appear with their distinct routing labels.

### Mini-side session check

```bash
LATEST=$(ls -t ~/.openclaw/agents/propertyiq/sessions/*.jsonl | head -1)
grep -c '"type":"toolCall"' "$LATEST"
grep -c 'gh issue create' "$LATEST"
```

Pass: both counts ≥ number of Issues expected from the test cycle.

---

## Prompt PR retrospective (Apr 24–26)

All against property-iq/propiq-prompts.

| PR | Title | Verdict |
|---|---|---|
| #1 | feat: PM routing classification (four outcomes) + Monday grooming | Keep — independent of the bug; routing triad validated end-to-end |
| #2 | fix(pm): sync TOOLS.md to routing triad + add announce-and-act directive | Keep — label cleanup + GH_CONFIG_DIR inline were correct hygiene |
| #3 | fix(pm): lift announce-and-act above outcomes tree + collapse filing to one command | Keep — inline --body pattern is visibly used in Issue #22's well-formed body |
| #4 | fix(pm): rename 'I never write code' boundary to lift tool-use inhibition | Wrong hypothesis — the cause was config, not boundary language |
| #5 | revert(pm): restore "I never write code" boundary (PR #4 was wrong-hypothesis) | Reverted #4, restored original constitutional guard |

---

## Appendix: diagnostic timeline (compressed)

- 2026-04-24 02:25 UTC — last propertyiq session at thinkingLevel: low (working state)
- 2026-04-24 06:32 UTC — model migration (anthropic→openai-codex); agents.defaults.thinkingDefault dropped from config
- 2026-04-24 17:55 UTC — first propertyiq session at thinkingLevel: off (bug active)
- 2026-04-24 → 2026-04-26 — four prompt PRs shipped (none addressed root cause)
- 2026-04-26 ~17:00 UTC — diagnostic session identified missing thinkingDefault
- 2026-04-26 ~18:00 UTC — config fix applied; PM filed Issue #22 successfully
- 2026-04-26 ~18:30 UTC — Tests B and C validated (Issues #96, #50)
