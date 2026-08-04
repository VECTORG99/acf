---
name: pr-context
description: >-
  Phase 4 of ACF. Builds a PR body that carries the issue's acceptance
  criteria, test commands, CI check names, and scope lock. Use when ACF
  delegates PR creation, or when the user asks to "open a PR", "lanzar un PR",
  or "create a pull request with context".
---

# PR-Context

Produces PR bodies that give reviewers (human or AI) everything needed to verify
the change — without re-reading the issue or the codebase.

## Prerequisites

- Context-load snapshot is complete (test commands, CI check names)
- The issue being closed is known (from issue-craft or stack-audit)
- Implementation is complete and tests pass locally

## PR Body Structure

```markdown
## Summary
[1-2 sentences: what changed and why]

## Closes
Closes #N

## Scope Lock
- [x] This PR stays within the issue scope
- [ ] Out-of-scope changes: [none / list]

## Changes
- `path/to/file` — [what changed, one line per file]
- `path/to/test` — [test added/modified]

## Verification
- [x] `[test command 1 from context-load]` — [N tests pass]
- [x] `[test command 2 from context-load]` — [N tests pass]
- [x] `[build command]` — build succeeds
- [x] `[typecheck command]` — no new errors

## CI Checks Expected
- [ ] `[check name 1]` (from workflow: `[workflow file]`)
- [ ] `[check name 2]` (from workflow: `[workflow file]`)

## Acceptance Criteria
- [x] [AC 1 from issue — copied verbatim]
- [x] [AC 2 from issue — copied verbatim]
- [ ] [AC 3 — if not yet verified, leave unchecked]

## Production Plan (if applicable)
- Verification: [how to verify in production]
- Rollback: [how to revert]
```

## Rules

1. **`Closes #N` is mandatory** — every PR must reference an issue
2. **AC are copied verbatim from the issue** — don't paraphrase
3. **Test commands are exact** — from context-load, not invented
4. **CI check names are real** — from workflow files, not guessed
5. **Scope lock is explicit** — checkbox confirming no out-of-scope changes
6. **Unverified AC stay unchecked** — don't lie about verification status

## Pre-Launch Checklist

Before `gh pr create`:

- [ ] All tests pass locally (exact commands from context-load)
- [ ] Build succeeds
- [ ] No secrets, API keys, or tokens in the diff
- [ ] PR body has `Closes #N`
- [ ] AC checkboxes match actual verification status
- [ ] CI check names match workflow job names
- [ ] Branch is based on `main` (or the project's base branch)
- [ ] Branch naming follows convention (`feature/`, `fix/`, etc.)

## Launch

```bash
gh pr create \
  --title "fix: flashlight uses :FireServer() instead of :Fire()" \
  --body-file /tmp/pr-body.md \
  --base main \
  --head fix/flashlight-fireserver
```

Record the PR number in the progress file.

## Post-Launch

- Verify CI checks start running
- If frontend-preview was used, attach the screenshot to the PR
- Monitor for `scc-failing-checks` or equivalent labels (if the project uses
  autonomous SDLC labels)
