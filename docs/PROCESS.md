# Process — Build Log and Decision Record

This document records the build process for ACF, including the original
implementation, the rename from ContextForge to ACF, and the addition of
context compaction and caveman mode.

## Phase 1: Initial Implementation (ContextForge)

### Source

The project was born from a conversation between `lil. vector` and `D4MAG3`
(31/7/26) about making issues and PRs richer in context for AI-driven
development. The full conversation is analyzed in [IDEAS.md](IDEAS.md).

### Architecture decisions

1. **Follow the deepwork + oracle pattern**: one orchestrator skill with
   separate sub-skills, each phase delegated. The orchestrator is a scheduler,
   not an implementation worker.

2. **Separate repo, not part of homedir or Herne**: ACF is inspired by homedir
   and Herne but does NOT touch them. It is a standalone repo that can be
   installed into any project.

3. **Source of truth + mirrors**: `skills/` is the source of truth for
   sub-skill content; `.devin/skills/*-*` are kept-in-sync mirrors so a single
   `cp -r .devin/skills/*` installs everything for Devin.

4. **6 initial sub-skills**: context-load, stack-audit, issue-craft, pr-context,
   frontend-preview, label-metadata.

5. **Labels over body text**: structured labels as the primary retrieval
   mechanism, body text as secondary context. This saves tokens and enables
   automation.

6. **Context compression from the start**: paths not contents, commands not
   configs, check names not YAML, counts not lists.

### Initial structure

```
contextforge/
├── .devin/skills/
│   ├── contextforge/SKILL.md          ← orchestrator
│   ├── 01-context-load/SKILL.md       ← phase mirrors
│   ├── 02-stack-audit/SKILL.md
│   ├── 03-issue-craft/SKILL.md
│   ├── 04-pr-context/SKILL.md
│   ├── 05-frontend-preview/SKILL.md
│   └── 06-label-metadata/SKILL.md
├── skills/                            ← portable source of truth
│   └── (same 6 sub-skills)
├── docs/
│   ├── ARCHITECTURE.md
│   ├── FLOW.md
│   └── IDEAS.md
├── templates/
│   ├── issue-contextualized.md
│   └── pr-contextualized.md
├── AGENTS.md
├── README.md
├── LICENSE
├── .gitignore
└── .ignore
```

## Phase 2: Rename to ACF

### Trigger

The user requested the project be renamed from "ContextForge" to "ACF".

### Changes

- All references to "ContextForge", "Contextforge", and "contextforge" replaced
  with "ACF", "ACF", and "acf" respectively across all `.md` files
- `.devin/skills/contextforge/` renamed to `.devin/skills/acf/`
- `.slim/contextforge/` path references updated to `.slim/acf/`
- `.gitignore` and `.ignore` updated to use `.slim/acf/`
- LICENSE copyright updated to "Copyright (c) 2026 vector (ACF)"

### Verification

- `grep -rn "ContextForge\|contextforge\|Contextforge" --include="*.md" .`
  returns no results (excluding `.git/`)
- All mirrors verified in sync via `diff`

## Phase 3: Context Compaction (Phase 7)

### Trigger

The user requested "compaction de contexto" and pointed to Kimi CLI's
compaction system as the reference.

### Research

The following Kimi CLI sources were studied (see [COMPACTION.md](COMPACTION.md)
for details):

1. `src/kimi_cli/soul/compaction.py` — `SimpleCompaction`, `should_auto_compact`
2. `src/kimi_cli/prompts/compact.md` — compression priorities, XML-tagged output
3. PR #1214 — first-person handoff rework
4. PR #1313 — head+tail preservation
5. PR #1300 — custom `/compact` instructions
6. Kimi Code CLI Docs — context compression
7. DeepWiki — Context Compaction architectural overview

### Implementation

Created `skills/07-compaction/SKILL.md` (source of truth) and
`.devin/skills/07-compaction/SKILL.md` (Devin mirror).

Four key techniques adapted from Kimi:
1. **Tail-preservation**: keep recent phase output verbatim, compact older
2. **Priority-based compression**: preserve task state, errors, test commands,
   CI checks; compress architecture and conventions
3. **XML-tagged output**: `<current_focus>`, `<stack>`, `<tests>`, `<ci>`,
   `<architecture>`, `<conventions>`, `<completed_phases>`
4. **First-person handoff**: progress file reads as agent's own working notes

Auto-trigger threshold (following Kimi's `should_auto_compact`):
- `trigger_ratio`: 0.75 (vs Kimi's 0.85 — ACF context is already compressed)
- `max_context_size`: 8000 tokens
- `reserved_context_size`: 2000 tokens

## Phase 4: Caveman Mode (Phase 8)

### Trigger

The user requested "un posible caveman" — clarified as extreme compression for
tokens, building on the compaction work.

### Design

Caveman mode is original to ACF (not from Kimi). It takes Kimi's compression
rules to their logical extreme:

- **No prose** — only paths, commands, labels, numbers
- **Symbols over words** — `→`, `|`, `#N`
- **Counts not lists** — `26 services` not 26 service names
- **Bare caveman last resort** — only `NOW + NEXT + TESTS + CI` (~100 tokens)

Target: <500 tokens for the entire snapshot (vs ~800 for compacted, ~2000 for
full).

### Implementation

Created `skills/08-caveman/SKILL.md` (source of truth) and
`.devin/skills/08-caveman/SKILL.md` (Devin mirror).

### Degradation path

```
Full (~2000 tok) → Compacted (~800 tok) → Caveman (<500 tok) → Bare caveman (~100 tok)
```

## Phase 5: Documentation Update

### Changes

- `AGENTS.md` — updated reading order, project snapshot, phase rules, key file
  reference to include phases 7 and 8
- `README.md` — updated to reflect 8-phase pipeline, compaction, caveman
- `docs/ARCHITECTURE.md` — updated diagrams, skill placement, data flow,
  compression strategy
- `docs/FLOW.md` — updated pipeline diagram
- `docs/IDEAS.md` — updated to reflect new phases
- `docs/PROCESS.md` — this file (new)
- `docs/COMPACTION.md` — new, full research and design notes

## Phase 6: Issue for artemisa and homedir adoption

### Trigger

The user requested an issue in the ACF repo (public) for implementing the ACF
idea in artemisa (to automate and test it) and homedir (to test it). The issue
must be in the ACF repo only — no other repos are touched.

### Implementation

Created a GitHub issue in the ACF repo with:
- Title: `feat: adopt ACF in artemisa and homedir for testing`
- Labels: `enhancement`, `priority:P2`, `area:devops`, `needs-human`
- Body: contextualized with AC, affected repos, and validation steps

See the issue in the ACF repo for details.

## Constraints Respected

Throughout the entire process:

- **homedir was NOT touched** — verified with `git status` (clean)
- **Herne was NOT touched** — verified with `git status` (clean)
- **artemisa was NOT touched** — no changes made to artemisa (the issue is in
  the ACF repo only, proposing future adoption)
- **All work is in the ACF repo only** — no other repos were modified

## Decision Log

| Decision | Rationale | Date |
|----------|-----------|------|
| Follow deepwork + oracle pattern | Proven orchestrator pattern, sub-skill delegation | Phase 1 |
| Separate repo, not part of homedir/Herne | ACF is portable, installs into any project | Phase 1 |
| Source of truth + mirrors | Single `cp -r` installs everything for Devin | Phase 1 |
| Labels over body text | Token efficiency, automation-friendly | Phase 1 |
| Rename to ACF | User request, shorter name | Phase 2 |
| Adapt Kimi CLI compaction | Open-source, battle-tested, directly applicable | Phase 3 |
| trigger_ratio 0.75 (vs Kimi's 0.85) | ACF context is already compressed | Phase 3 |
| Caveman as separate phase | Different need from compaction (structure vs bare minimum) | Phase 4 |
| Issue in ACF repo only | Constraint: do not touch artemisa or homedir | Phase 6 |
