# Architecture

## Design Principle

ACF follows the **deepwork + oracle** pattern: one orchestrator skill
that manages a pipeline of phases, each delegated to a separate sub-skill. The
orchestrator is a scheduler, not an implementation worker. It also includes
**context compaction** (phase 7, inspired by Kimi CLI) and **caveman mode**
(phase 8, extreme compression) so the same pipeline runs on any context window.

```
                    ┌─────────────────┐
                    │      acf        │  (orchestrator skill)
                    │  .devin/skills/ │
                    └────────┬────────┘
                             │
          ┌────────┬─────────┼──────────┬──────────┬──────────┬──────────┐
          ▼        ▼         ▼          ▼          ▼          ▼          ▼
    ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────────┐ ┌────────┐ ┌────────┐
    │ context- │ │ stack- │ │ issue- │ │ pr-    │ │ frontend-      │ │compac- │ │caveman │
    │ load     │ │ audit  │ │ craft  │ │ context│ │ preview        │ │tion    │ │        │
    │ (01)     │ │ (02)   │ │ (03)   │ │ (04)   │ │ (05, optional) │ │(07)    │ │(08)    │
    └──────────┘ └────────┘ └────────┘ └────────┘ └────────────────┘ └────────┘ └────────┘
          │        │         │          │          │                   │          │
          └────────┴─────────┴──────────┴──────────┘                   │          │
                             │                                          │          │
                    ┌────────▼────────┐                                 │          │
                    │ label-metadata   │  (cross-cutting, all phases)   │          │
                    │ (06)             │                                 │          │
                    └─────────────────┘                                 │          │
                                                                        │          │
                                                                        ▼          │
                                                              [compacted snapshot]   │
                                                                        │          │
                                                                        ▼          │
                                                              [caveman snapshot]─────┘
```

## Skill Placement

```
acf/
├── .devin/skills/
│   ├── acf/SKILL.md                    ← orchestrator (Devin-native)
│   ├── 01-context-load/SKILL.md        ← phase 1 mirror (Devin-native)
│   ├── 02-stack-audit/SKILL.md         ← phase 2 mirror (Devin-native)
│   ├── 03-issue-craft/SKILL.md         ← phase 3 mirror (Devin-native)
│   ├── 04-pr-context/SKILL.md          ← phase 4 mirror (Devin-native)
│   ├── 05-frontend-preview/SKILL.md    ← phase 5 mirror (Devin-native)
│   ├── 06-label-metadata/SKILL.md      ← label taxonomy mirror (Devin-native)
│   ├── 07-compaction/SKILL.md          ← compaction mirror (Devin-native)
│   └── 08-caveman/SKILL.md             ← caveman mirror (Devin-native)
├── skills/                             ← portable source of truth (OpenCode, Claude Code, etc.)
│   ├── 01-context-load/SKILL.md        ← phase 1: read MDs, build snapshot
│   ├── 02-stack-audit/SKILL.md         ← phase 2: audit open stack
│   ├── 03-issue-craft/SKILL.md         ← phase 3: craft issue
│   ├── 04-pr-context/SKILL.md          ← phase 4: build PR body
│   ├── 05-frontend-preview/SKILL.md    ← phase 5: visual diff (optional)
│   ├── 06-label-metadata/SKILL.md      ← cross-cutting: label taxonomy
│   ├── 07-compaction/SKILL.md          ← phase 7: Kimi-inspired compaction
│   └── 08-caveman/SKILL.md             ← phase 8: extreme compression
├── docs/
│   ├── ARCHITECTURE.md                 ← this file
│   ├── FLOW.md                         ← end-to-end flow diagram
│   ├── IDEAS.md                        ← source conversation analysis
│   ├── PROCESS.md                      ← build process and decision log
│   └── COMPACTION.md                   ← compaction research (Kimi CLI) and caveman design
├── templates/
│   ├── issue-contextualized.md         ← issue body template
│   └── pr-contextualized.md            ← PR body template
├── AGENTS.md                           ← agent directives
└── README.md
```

`skills/` is the **source of truth** for sub-skill content; `.devin/skills/*-*`
are kept in sync mirrors so a single `cp -r .devin/skills/* /target/.devin/skills/`
installs the orchestrator and every sub-skill for Devin. When editing a sub-skill,
edit the copy in `skills/` and re-mirror into `.devin/skills/`.

## Why Sub-Skills Are Separate

Following the deepwork model, each phase is a separate SKILL.md because:

1. **Independent invocation** — a user can run `stack-audit` alone without the
   full pipeline
2. **Composable** — other orchestrators can reuse individual phases
3. **Token efficiency** — the orchestrator loads only the phase it needs
4. **Testability** — each phase has clear inputs and outputs

## Data Flow

```
context-load ──► snapshot (paths + facts, compressed)
                        │
stack-audit ──► findings (orphan PRs, stale issues, lib opportunities)
                        │
                        ▼
                 issue-craft ──► issue draft (title, labels, body)
                        │              │
                        │              ▼
                        │         gh issue create ──► issue #N
                        │
                        ▼
                 pr-context ──► PR draft (body with AC, test cmds, CI checks)
                        │              │
                        │              ▼
                        │         gh pr create ──► PR #M
                        │
                        ▼
              frontend-preview (if frontend changes)
                        │
                        ▼
                 screenshot ──► attached to PR

              ┌─────────────────────────────────────────────┐
              │  COMPACTION (triggers when snapshot > 2K tok)│
              │  Full → Compacted (~800 tok, XML-tagged)     │
              │  Compacted → Caveman (<500 tok, no prose)    │
              │  Caveman → Bare caveman (~100 tok, last resort)│
              └─────────────────────────────────────────────┘
```

All intermediate state lives in `.slim/acf/<slug>.md`.

## Context Compression Strategy

ACF has three compression tiers, each building on the previous:

| Tier | Phase | Target tokens | Technique | Token savings |
|------|-------|--------------|-----------|---------------|
| Full | 1-6 | ~2000 | Paths, labels, counts | ~70% vs traditional |
| Compacted | 7 | ~800 | Tail-preservation, priority-based, XML-tagged, first-person handoff | ~88% vs traditional |
| Caveman | 8 | <500 | No prose, symbols over words, bare minimum | ~93% vs traditional |
| Bare caveman | 8 (last resort) | ~100 | Only NOW + NEXT + TESTS + CI | ~97% vs traditional |

### Traditional vs ACF comparison

| Traditional issue | ACF issue |
|---|---|
| Body: 500 words of context | Body: 50 words + labels |
| "Priority: High, needs fix soon" | Label: `priority:P1` |
| "This affects the backend API service" | Label: `area:backend` |
| Full architecture description | `See ARCHITECTURE.md §3` |
| Full test list | `lune run scripts/test_core.luau` (113 tests) |
| Full CI config | `test (lune)` check expected |
| Full conversation history | Compacted: `<current_focus>` + `<stack>` + `<tests>` |
| Compacted snapshot still too large | Caveman: `orphan:3 | stale:2 | gap:38→29` |

### Compaction data flow (phase 7)

```
Full snapshot (~2000 tokens)
        │
        ▼  [trigger: token_count >= max * 0.75]
        │
   ┌────┴────┐
   │ to_compact │ (older phases → summarized)
   │ to_preserve│ (recent phase → verbatim)
   └────┬────┘
        │
        ▼  [Kimi-inspired compaction]
        │
   <current_focus> ... </current_focus>
   <stack> ... </stack>
   <tests> ... </tests>
   <ci> ... </ci>
   <architecture> ... </architecture>
   <conventions> ... </conventions>
   <completed_phases> ... </completed_phases>
        │
        ▼
   Compacted snapshot (~800 tokens)
   + first-person handoff note
```

### Caveman degradation path (phase 8)

```
Compacted snapshot (~800 tokens)
        │
        ▼  [still too large or caveman requested]
        │
   ACF@<project> | branch:<name> | issues:<N> | PRs:<M>
   STACK: orphan:<N> | stale:<N> | gaps:[PR#→Issue#]
   TESTS: <cmd> → <N>pass
   CI: <check>@<workflow>
   NOW: <current issue/PR — 1line>
   NEXT: <next action — 1line>
        │
        ▼  [still too large]
        │
   NOW:<issue/PR 1line>
   NEXT:<action 1line>
   TEST:<cmd> → <N>pass
   CI:<check>@<wf>
   (~100 tokens — bare caveman)
```

## Relationship to homedir, Herne, deepwork, and Kimi CLI

ACF is **inspired by** but **independent from**:

- **homedir** — autonomous SDLC pipeline with scc-* labels, admission review,
  worker timer. ACF borrows: label taxonomy, issue metadata validation,
  autonomous-implementation template structure.
- **Herne** — AAA game development loop with AC patterns, test suites, PR
  template. ACF borrows: AC patterns by issue type, test command
  references, scope lock concept.
- **deepwork** — orchestrator pattern with oracle review gates. ACF
  borrows: orchestrator-as-scheduler, progress file, sub-skill delegation.
- **Kimi CLI** ([MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli)) —
  open-source context compaction system. ACF borrows: tail-preservation,
  priority-based compression, XML-tagged output structure, first-person
  handoff, auto-trigger threshold logic (`should_auto_compact`).

ACF does NOT touch homedir, Herne, or Kimi CLI. It is a standalone repo that can
be installed into any project.
