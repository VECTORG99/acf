---
name: context-load
description: >-
  Phase 1 of ACF. Reads all project MDs and builds a compressed context
  snapshot (architecture, challenge, templates, tests, CI checks). Use when
  ACF orchestrator delegates context gathering, or when the user asks to
  "load context", "read the project docs", or "understand the stack before making
  an issue".
---

# Context-Load

Reads project documentation and builds a compressed snapshot that later phases
(issue-craft, pr-context) consume. The snapshot is **never a copy of file
contents** — it is a structured index of paths + key facts.

## Reading Order

Read in order, skip missing files:

1. `AGENTS.md` — workflow, conventions, file reference table
2. `ARCHITECTURE.md` or `docs/ARCHITECTURE.md` — architecture decisions
3. `docs/DEVELOPMENT.md` — dev guide, build/test commands
4. `docs/ACCEPTANCE_CRITERIA.md` (or equivalent) — AC patterns by issue type
5. `.github/ISSUE_TEMPLATE/*` — issue template fields and auto-labels
6. `.github/PULL_REQUEST_TEMPLATE/*` — PR template required sections
7. `.github/workflows/*` — CI check names (extract job names, not full YAML)
8. `README.md` — project snapshot (test counts, file counts, stack)

## Snapshot Schema

Write to the progress file (`.slim/acf/<slug>.md`):

```markdown
## Context Snapshot

### Architecture
- Stack: [languages, frameworks, build tools — one line]
- Key dirs: [src/, scripts/, docs/ — paths only]
- Architecture doc: [path or "none"]

### Challenge
- Current branch: [name]
- Open issues: [count] (from stack-audit)
- Open PRs: [count] (from stack-audit)

### Templates
- Issue templates: [list names + auto-labels]
- PR template: [path, required sections]

### Tests
- Test commands: [exact commands, one per line]
- Test count: [N tests across M suites]
- Coverage tool: [command or "none"]

### CI Checks
- Check names: [list job names from workflows]
- Required checks: [which ones gate merge]

### Conventions
- Code style: [key rules from AGENTS.md, max 5 bullets]
- Commit format: [conventional commits or custom]
- Branch naming: [prefix rules]
```

## Compression Rules

1. **Paths, not contents** — `src/shared/Constants.luau` not the file's code
2. **Command strings, not configs** — `lune run scripts/test_core.luau` not the
   test file
3. **Check names, not YAML** — `test (lune)` not the full workflow
4. **Counts, not lists** — "26 services" not a list of all 26 service names
5. **Max 5 bullets per section** — if more, summarize

## Output

The snapshot is consumed by:
- **stack-audit** (phase 2) — uses test commands and CI check names
- **issue-craft** (phase 3) — uses AC patterns, templates, conventions
- **pr-context** (phase 4) — uses test commands, CI check names, PR template
