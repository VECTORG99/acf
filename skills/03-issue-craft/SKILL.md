---
name: issue-craft
description: >-
  Phase 3 of ACF. Crafts a context-rich GitHub issue with structured
  labels, acceptance criteria referencing test commands and CI checks, and
  compressed body. Use when ACF delegates issue creation, or when the
  user asks to "create an issue", "armar un issue", or "write a contextualized
  issue".
---

# Issue-Craft

Produces issues that give an AI agent (or human) everything needed to implement
and verify a change — without reading the entire codebase.

## Prerequisites

- Context-load snapshot is complete (phase 1)
- Stack-audit findings are available (phase 2)

## Issue Structure

Every crafted issue MUST have:

### Title
```
<type>: <concise description>
```
Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `test`, `security`

### Labels (from label-metadata)
- **Type label**: `bug`, `enhancement`, `documentation`, `refactor`, `chore`, `test`, `security`
- **Priority label**: `priority:P0` | `priority:P1` | `priority:P2` | `priority:P3`
- **Area label**: `area:backend` | `area:frontend` | `area:ci` | `area:docs` | `area:security` | `area:devops`
- **Status label**: `ready-to-implement` (if ready for autonomous work) | `needs-human` (if it requires a human decision) | `blocked` (if blocked by a dependency)
- **Enhancement label** (if applicable): `library-review` (separate lib issue) | `batch-delivery` (>2 AC, needs decomposition)

### Body (compressed)

```markdown
## Summary
[1-2 sentences: what is broken or missing]

## Context
- Architecture: [path to architecture doc, not inline]
- Related: #[issue numbers from stack-audit, if any]

## Affected Files (best guess)
- `path/to/likely/file1`
- `path/to/likely/file2`

## Acceptance Criteria
- [ ] [Specific, verifiable behavior — reference file:function]
- [ ] [Test added in `path/to/test_file` reproducing/verifying the change]
- [ ] [N tests pass — `exact test command from context-load`]
- [ ] [CI check name passes — e.g., "test (lune)"]
- [ ] [Convention rule from AGENTS.md — e.g., "--!strict in all new files"]

## Validation
[Exact command to verify, e.g., `bash scripts/dev.sh --test`]

## Complexity
Simple | Medium | Complex
- **Simple**: 1 file, <50 lines, obvious fix
- **Medium**: 2-3 files, <200 lines, clear scope
- **Complex**: >3 files or architectural decision — consider decomposition
```

## Acceptance Criteria Rules

1. **Specific** — name the file, function, or behavior exactly
2. **Verifiable** — can be confirmed with a test or manual step
3. **Binario** — se cumple o no, sin ambigüedad
4. **Contextualizado** — reference the project's architecture (services,
   controllers, signals, constants — whatever the stack uses)
5. **Max 2 AC for autonomous issues** — more than 2 = decompose or add
   `batch-delivery` label

## AC Patterns by Issue Type

### Bug Fix (`fix:`)
```markdown
- [ ] [Behavior] no longer occurs when [reproduction steps]
- [ ] Regression test added in `[test_file]`
- [ ] [N] tests pass — `[test command]`
```

### Feature (`feat:`)
```markdown
- [ ] [Component] implemented in `[path]`
- [ ] Follows [convention from AGENTS.md — e.g., "--!strict"]
- [ ] Tests added in `[test_file]`
- [ ] [N] tests + new tests pass — `[test command]`
- [ ] CI check `[check name]` passes
```

### Refactor (`refactor:`)
```markdown
- [ ] [File:function] refactored — [measurable metric, e.g., "≤50 lines"]
- [ ] No behavior change (tests pass unchanged)
- [ ] [N] tests pass — `[test command]`
```

### Documentation (`docs:`)
```markdown
- [ ] Content reflects current code state
- [ ] No stale references
- [ ] No duplication with other docs (reference instead)
```

## Library Suggestion Handling

If stack-audit found a library opportunity:

1. Create the **main issue** (the actual change)
2. Create a **separate enhancement issue**:
   ```markdown
   ## Summary
   Evaluate [library name] for [problem it solves]

   ## Context
   - Could simplify: #[main issue number]
   - License: [license]
   - Bundle size: [size or "N/A"]
   - Maintenance: [active/abandoned]

   ## Acceptance Criteria
   - [ ] Library evaluated against project conventions
   - [ ] Trade-offs documented (license, size, deps)
   - [ ] Decision recorded (adopt/reject + reason)
   ```
3. Reference from main issue: `Related: #NN (library review)`

## Launch

```bash
gh issue create \
  --title "fix: flashlight uses :Fire() instead of :FireServer()" \
  --body-file /tmp/issue-body.md \
  --label "bug" \
  --label "priority:P0" \
  --label "area:backend" \
  --label "ready-to-implement"
```

Record the issue number in the progress file.
