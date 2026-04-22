# propiq-prompts

PropertyIQ Routine prompts and PM agent prompts. Authoritative source, read at runtime by Claude Code Routines and by OpenClaw PM on startup and periodic pull.

## Structure

One directory per Routine or agent, each containing `SOUL.md` (core identity + task) plus any supporting files. `shared/` holds cross-cutting references every prompt includes.

```
propiq-prompts/
├── propertyiq/          # PM agent prompts (loaded by OpenClaw)
├── refinement/          # Refinement Routine
├── architect/           # Architect Routine
├── builder/             # Builder Routine
├── validator/           # Validator Routine
├── challenger/          # Challenger Routine
├── visioner/            # Visioner Routine
└── shared/              # Cross-cutting references
    ├── pipeline-principles.md
    ├── label-reference.md
    └── comment-formats.md
```

## Contributing

Contributions are PRs. Prompt changes take effect on next Routine invocation / next PM heartbeat pull.

Every prompt must include `shared/pipeline-principles.md` + `shared/label-reference.md` via preamble or inline reference.
