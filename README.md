# propiq-prompts

Generic Claude Code **Routine** prompts and cross-Routine shared references.

> ## ⚠️ RETIRED (2026-06/07) — kept for reference
>
> The routed multi-agent pipeline described here (Refinement → Architect →
> Builder → Validator, label-dispatched, webhook-triggered) **is no longer in
> use**. It was replaced by the `/spec` + native sub-issues + long-running
> **overnight-builder** model: specs are written with `/spec`, eligibility is
> implicit (a `spec`-labelled issue that is unclaimed and not `hold`), and the
> builder claims work on `claw/<issue>-*` branches. See the root `CLAUDE.md`
> §Spec Discipline for the current workflow.
>
> Nothing in this repo is read at runtime today. Do not implement against it.


> **2026-05-07: scope narrowed.** The PropertyIQ PM agent prompts (`propertyiq/`) and the chart-qa skill moved to `property-iq/propiq-openclaw` (**now deprecated** — the canonical OpenClaw fork lives outside this org, and OpenClaw itself is being decommissioned, propiq-infrastructure#19). This repo no longer hosts propertyiq-scoped content. See `propertyiq/README.md` for the path map.

## Structure

One directory per Routine, each containing `SOUL.md` (core identity + task) plus any supporting files. `shared/` holds cross-cutting references every Routine prompt includes.

```
propiq-prompts/
├── refinement/          # Refinement Routine
├── architect/           # Architect Routine
├── builder/             # Builder Routine
├── validator/           # Validator Routine
├── challenger/          # Challenger Routine
├── visioner/            # Visioner Routine
├── shared/              # Cross-cutting references (canonical for Routines)
│   ├── pipeline-principles.md
│   ├── label-reference.md
│   ├── comment-formats.md
│   └── chart-spec-fetch.md
├── docs/adr/            # Cross-Routine architectural decision records
└── propertyiq/          # Stub — points at propiq-openclaw (see README inside)
```

## Contributing

Contributions are PRs. Prompt changes take effect on next Routine invocation.

Every Routine prompt must include `shared/pipeline-principles.md` + `shared/label-reference.md` via preamble or inline reference.

For propertyiq-scoped prompts (PM agent, chart-qa skill), open PRs against [propiq-openclaw](https://github.com/property-iq/propiq-openclaw) instead.
