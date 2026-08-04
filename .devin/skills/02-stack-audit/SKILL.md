---
name: stack-audit
description: >-
  Phase 2 of ContextForge. Audits the open GitHub stack for orphan PRs, unclosed
  issues, missing issue↔PR references, and library opportunities. Use when
  ContextForge delegates stack analysis, or when the user asks to "check the
  stack", "find orphan PRs", "review open issues", or "what's missing in the
  stack".
---

# Stack-Audit

Detects gaps in the issue↔PR pipeline so nothing escapes the current stack.

## Checks

### 1. Orphan PRs (PR with no issue reference)

```bash
gh pr list --state open --json number,title,body,headRefName
```

For each PR, check if the body contains `Closes #N`, `Fixes #N`, `Refs #N`, or
`Resolves #N`. If none found → **orphan PR**.

Flag: `orphan-pr` label suggestion + comment recommending issue creation.

### 2. Stale Issues (issue ready/in-progress with no PR)

```bash
gh issue list --state open --json number,title,labels
```

For each issue with label `ready-to-implement` (or equivalent), check if there's
an open PR referencing it. If not → **stale issue**.

Flag: comment with "No PR open for this issue — consider creating one or closing
if obsolete."

### 3. Merged PR, Issue Still Open

```bash
gh pr list --state merged --json number,title,body --limit 20
```

For each merged PR with `Closes #N`, verify issue #N is closed. If open →
**close gap**.

Action: **do not close automatically.** Surface the gap in the findings list and
let the user confirm. Only after explicit user approval run:

```bash
gh issue close #N --reason completed
```

Closing an issue is a state change on the tracker; never perform it without user
confirmation, and never batch-close multiple issues in one pass.

### 4. Closed Issue, No Merged PR

```bash
gh issue list --state closed --json number,title,body --limit 20
```

For each closed issue, check if there's a merged PR referencing it. If not →
**escaped issue** (closed without implementation evidence).

Flag: `escaped-issue` label suggestion. May need reopening or a follow-up issue.

### 5. Library Opportunities

During context-load and stack-audit, if a dependency or library could simplify
the solution to an open issue:

- Do NOT bundle it into the current issue
- Create a **separate enhancement issue** with labels `enhancement` +
  `library-review`
- Reference it from the main issue: `Related: #NN (library review)`

The library-review issue should contain:
- Library name and link
- What problem it solves
- Which open issues it could improve
- Trade-offs (license, bundle size, maintenance status)

## Output

Write findings to the progress file:

```markdown
## Stack-Audit Findings

### Orphan PRs
- PR #NN "title" — no issue reference

### Stale Issues
- Issue #NN "title" — no open PR

### Close Gaps
- PR #NN merged but issue #MM still open

### Escaped Issues
- Issue #NN closed but no merged PR

### Library Opportunities
- [library name] could simplify issue #NN — create enhancement issue
```

## Parallel Execution

Stack-audit can run in parallel with context-load. Both feed into issue-craft.
