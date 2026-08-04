# Architecture

## Design Principle

ContextForge follows the **deepwork + oracle** pattern: one orchestrator skill
that manages a pipeline of phases, each delegated to a separate sub-skill. The
orchestrator is a scheduler, not an implementation worker.

```
                    ┌─────────────────┐
                    │   contextforge   │  (orchestrator skill)
                    │   .devin/skills/  │
                    └────────┬────────┘
                             │
          ┌────────┬─────────┼──────────┬──────────┐
          ▼        ▼         ▼          ▼          ▼
    ┌──────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────────────┐
    │ context- │ │ stack- │ │ issue- │ │ pr-    │ │ frontend-      │
    │ load     │ │ audit  │ │ craft  │ │ context│ │ preview        │
    │ (01)     │ │ (02)   │ │ (03)   │ │ (04)   │ │ (05, optional) │
    └──────────┘ └────────┘ └────────┘ └────────┘ └────────────────┘
          │        │         │          │          │
          └────────┴─────────┴──────────┴──────────┘
                             │
                    ┌────────▼────────┐
                    │ label-metadata   │  (cross-cutting, all phases)
                    │ (06)             │
                    └─────────────────┘
```

## Skill Placement

```
contextforge/
├── .devin/skills/contextforge/SKILL.md   ← orchestrator (Devin-native)
├── skills/
│   ├── 01-context-load/SKILL.md          ← phase 1: read MDs, build snapshot
│   ├── 02-stack-audit/SKILL.md           ← phase 2: audit open stack
│   ├── 03-issue-craft/SKILL.md           ← phase 3: craft issue
│   ├── 04-pr-context/SKILL.md            ← phase 4: build PR body
│   ├── 05-frontend-preview/SKILL.md      ← phase 5: visual diff (optional)
│   └── 06-label-metadata/SKILL.md        ← cross-cutting: label taxonomy
├── docs/
│   ├── ARCHITECTURE.md                   ← this file
│   ├── FLOW.md                           ← end-to-end flow diagram
│   └── IDEAS.md                          ← source conversation analysis
├── templates/
│   ├── issue-contextualized.md           ← issue body template
│   └── pr-contextualized.md              ← PR body template
├── AGENTS.md                             ← agent directives
└── README.md
```

## Why Sub-Skills Are Separate

Following the deepwork model, each phase is a separate SKILL.md because:

1. **Independente invocation** — a user can run `stack-audit` alone without the
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
```

All intermediate state lives in `.slim/contextforge/<slug>.md`.

## Context Compression Strategy

The core innovation is **compressed context**:

| Traditional issue | ContextForge issue |
|---|---|
| Body: 500 words of context | Body: 50 words + labels |
| "Priority: High, needs fix soon" | Label: `priority:P1` |
| "This affects the backend API service" | Label: `area:backend` |
| Full architecture description | `See ARCHITECTURE.md §3` |
| Full test list | `lune run scripts/test_core.luau` (113 tests) |
| Full CI config | `test (lune)` check expected |

This reduces token consumption by ~70% and makes automation trivial.

## Relationship to homedir and Herne

ContextForge is **inspired by** but **independent from**:

- **homedir** — autonomous SDLC pipeline with scc-* labels, admission review,
  worker timer. ContextForge borrows: label taxonomy, issue metadata validation,
  autonomous-implementation template structure.
- **Herne** — AAA game development loop with AC patterns, test suites, PR
  template. ContextForge borrows: AC patterns by issue type, test command
  references, scope lock concept.
- **deepwork** — orchestrator pattern with oracle review gates. ContextForge
  borrows: orchestrator-as-scheduler, progress file, sub-skill delegation.

ContextForge does NOT touch homedir or Herne. It is a standalone repo that can
be installed into any project.
