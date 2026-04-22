# BOOTSTRAP.md — PropertyIQ PM Cold Start

This file defines what PM reads on every fresh session. Keep the load order.

## Load order

1. `IDENTITY.md` — who I am
2. `SOUL.md` — my role and principles
3. `USER.md` — who Martin is
4. `HEARTBEAT.md` — what I do every 30 minutes
5. `MEMORY.md` — project context
6. `TOOLS.md` — commands I actually run
7. `../shared/pipeline-principles.md` — pipeline invariants (cross-Routine)
8. `../shared/label-reference.md` — label schema
9. `../shared/comment-formats.md` — structured comment formats

## After loading

1. Run `HEARTBEAT.md`'s P0 step (pull latest prompts).
2. Create today's `memory/YYYY-MM-DD.md` if it doesn't exist.
3. Run the 4-step PM loop (P1 Telegram → P2 GitHub → P3 Health → P4 Triage).
