---
name: contextforge
description: >-
  Orchestrator workflow for crafting context-rich GitHub issues and PRs that pass
  CI checks on the first try. Reads project MDs (AGENTS.md, ARCHITECTURE, test docs,
  templates), audits the open stack (orphan PRs, unclosed issues, missing references),
  suggests libraries, and produces issues with structured labels/metadata instead of
  free-text bodies. Use when the user wants to "create an issue", "open a PR",
  "craft a contextualized issue", "audit the stack", "check for orphan PRs", or any
  SDLC planning activity where context quality matters. Also triggers on "armar un
  issue", "lanzar un PR", "revisar el stack", or "contextualizar el issue".
---

# ContextForge

ContextForge is an orchestrator workflow for the issue→PR loop. It maximizes the
context an AI agent (or human) has before writing a single line of code, so PRs
pass checks faster and alucinaciones are minimized.

## When to use

Use ContextForge when the work involves **creating issues or PRs where context
quality is the bottleneck**. This is the case when:

- The user wants to create an issue and needs it to be rich in context (stack,
  checks, tests, affected files, acceptance criteria)
- The user wants to audit the current stack for orphan PRs, unclosed issues, or
  PRs that don't reference issues
- The user wants to launch a PR and needs the PR body to carry the right context
  for CI to pass without back-and-forth
- The user wants to suggest a library that could improve the codebase (separate
  enhancement issue)
- The user wants a frontend preview of changes before opening a PR

Do NOT use ContextForge for:

- Routine bug fixes where the issue already exists and is well-contextualized
- Quick docs changes with no CI impact
- Situations where the user already has the issue and PR body ready

## Core Contract

When Contextforge is active, the orchestrator must manage the work as a pipeline
of context-gathering phases, not as a default implementation worker.

Required behavior:

- before any issue or PR is created, run **context-load** to read all project MDs
  and build a compressed context snapshot;
- before crafting an issue, run **stack-audit** to detect orphan PRs, unclosed
  issues, and missing issue↔PR references;
- every issue MUST use **label-metadata** conventions (structured labels, not
  free-text-only bodies) to save tokens and enable automation;
- every issue MUST include acceptance criteria that reference the project's test
  suite and CI checks (learned during context-load);
- if a library suggestion emerges during stack-audit, create a **separate
  enhancement issue** — never bundle it into the current issue;
- before launching a PR, run **pr-context** to verify the PR body carries the
  issue's acceptance criteria, test commands, and CI check names;
- if the change touches frontend, offer to run **frontend-preview** for a visual
  diff and optional screenshot;
- keep a local progress file under `.slim/contextforge/` for session state;
- compress context aggressively — reference files by path, don't inline contents.

## Pipeline Phases

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. CONTEXT-LOAD  →  Read all project MDs, build compressed snapshot │
│                      (architecture, challenge, templates, tests)     │
│  2. STACK-AUDIT   →  Detect orphan PRs, unclosed issues, missing     │
│                      refs, library opportunities                     │
│  3. ISSUE-CRAFT   →  Craft contextualized issue with AC, labels,     │
│                      metadata; separate enhancement issues for libs  │
│  4. PR-CONTEXT    →  Build PR body with issue context, test cmds,    │
│                      CI checks, AC verification checkboxes           │
│  5. FRONTEND-PREVIEW (optional) → Launch local view, visual diff,    │
│                      screenshot with vision models                   │
│  6. LAUNCH        →  Create issue/PR via gh, verify labels applied    │
└─────────────────────────────────────────────────────────────────────┘
```

### Phase 1: Context-Load

Delegate to `skills/01-context-load/SKILL.md`.

Reads in order (skip missing):
1. `AGENTS.md` — workflow, conventions, file reference
2. `ARCHITECTURE.md` / `docs/ARCHITECTURE.md` — architecture decisions
3. `docs/DEVELOPMENT.md` — dev guide, test commands
4. `docs/ACCEPTANCE_CRITERIA.md` (or equivalent) — AC patterns
5. `.github/ISSUE_TEMPLATE/*` — issue templates
6. `.github/PULL_REQUEST_TEMPLATE/*` — PR templates
7. `.github/workflows/*` — CI check names (for AC and PR body)
8. `README.md` — project snapshot

Output: a compressed context snapshot written to the progress file. Reference
files by path only — never inline full contents.

### Phase 2: Stack-Audit

Delegate to `skills/02-stack-audit/SKILL.md`.

Checks:
- Open PRs that reference no issue (orphan PRs)
- Issues marked "ready" or "in-progress" with no open PR (stale issues)
- PRs merged but issue still open (close gap)
- Issues closed but no merged PR (escaped issues)
- Library opportunities: if a dependency could simplify the solution, flag it
  for a separate enhancement issue

Commands:
```bash
gh pr list --state open --json number,title,headRefName,body
gh issue list --state open --json number,title,labels,body
gh pr list --state merged --json number,title,body --limit 20
```

### Phase 3: Issue-Craft

Delegate to `skills/03-issue-craft/SKILL.md`.

Every crafted issue MUST have:
- **Title**: `<type>: <description>` (type = feat/fix/docs/refactor/chore/test)
- **Labels**: type label + priority label + area label (from label-metadata)
- **Body sections** (compressed, not verbose):
  - Summary (1-2 sentences)
  - Context (links to architecture files, not inline)
  - Affected files (best guess, paths only)
  - Acceptance criteria (checkboxes, referencing test commands and CI checks)
  - Validation command (the exact command to verify)
  - Complexity (Simple/Medium/Complex)
- **Metadata over text**: use labels for type/priority/area; keep body minimal

If stack-audit found a library opportunity:
- Create a **separate** issue with label `enhancement` and `library-review`
- Reference it from the main issue: `Related: #NN (library review)`

### Phase 4: PR-Context

Delegate to `skills/04-pr-context/SKILL.md`.

The PR body MUST carry:
- `Closes #N` (or `Refs #N` if not closing)
- Acceptance criteria copied from the issue, each with a checkbox
- Test commands that were run (from context-load)
- CI check names that are expected to pass (from context-load)
- Scope lock: confirm the PR doesn't exceed the issue scope

### Phase 5: Frontend-Preview (optional)

Delegate to `skills/05-frontend-preview/SKILL.md`.

Triggered only when the change touches frontend files. Launches:
- Local dev server (if running) at the affected route
- Visual diff: before/after comparison (like git red/green but on the web)
- Optional screenshot for vision-model review

### Phase 6: Launch

- Create issue: `gh issue create --title "..." --body "..." --label "..." --label "..."`
- Create PR: `gh pr create --title "..." --body "..." --base main`
- Verify labels were applied
- Update progress file with issue/PR numbers

## Progress File

Create a task-specific file:

```text
.slim/contextforge/<short-task-slug>.md
```

Before creating this file, inspect `.gitignore` and `.ignore`. Add only missing
entries:

```gitignore
# .gitignore
.slim/contextforge/
```

```gitignore
# .ignore
!.slim/contextforge/
!.slim/contextforge/**
```

The file captures:
- current goal
- compressed context snapshot (file paths + key facts, not full contents)
- stack-audit findings
- crafted issue draft (title, labels, body)
- PR draft
- issue/PR numbers after launch
- unresolved questions

## Context Compression Rules

ContextForge's primary value is **compressed context**. Follow these rules:

1. **Reference files by path**, don't inline contents — `See AGENTS.md §Testing`
   instead of pasting the testing section
2. **Use labels for taxonomy**, not body text — `priority:P1` instead of
   "Priority: High" in the body
3. **Use CI check names**, not full CI configs — "Tests pass (test.yml)" instead
   of pasting the workflow YAML
4. **Use test command strings**, not test file contents — `lune run scripts/test_core.luau`
   instead of pasting the test file
5. **Compress AC to checkboxes** — one line per criterion, referencing the
   validation command
6. **Maximum 2 AC for autonomous issues** — more than 2 = decompose or add
   `batch-delivery` label

## Label & Metadata Conventions

Delegate to `skills/06-label-metadata/SKILL.md`.

Every issue and PR MUST use structured labels:

| Category | Labels | Purpose |
|----------|--------|---------|
| Type | `bug`, `enhancement`, `documentation`, `refactor`, `chore`, `test` | What kind of change |
| Priority | `priority:P0`, `priority:P1`, `priority:P2`, `priority:P3` | SLA urgency |
| Area | `area:backend`, `area:frontend`, `area:ci`, `area:docs`, `area:security` | Where in the stack |
| Status | `ready-to-implement`, `needs-metadata`, `blocked` | Workflow state |
| Enhancement | `library-review` | Library suggestion issue |

Labels are the primary retrieval mechanism for automation. Body text is
secondary context, not the primary index.

## Scheduler Discipline

- follow Orchestrator delegation rules
- record issue/PR numbers and ownership boundaries
- run context-load and stack-audit in parallel when possible
- don't craft an issue until context-load is complete
- don't launch a PR until pr-context is complete
- if frontend-preview is offered, wait for user decision before proceeding
