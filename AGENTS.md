# ContextForge — AI Agent Directives

> **Canonical workflow for every agent using ContextForge to craft issues and PRs.**
> Read this file top-to-bottom before using the skill.

## Reading Order

1. **AGENTS.md** (this file) — Agent workflow and conventions
2. **docs/ARCHITECTURE.md** — Skill architecture and data flow
3. **docs/FLOW.md** — End-to-end pipeline diagram
4. **docs/IDEAS.md** — Source conversation and idea mapping
5. **.devin/skills/contextforge/SKILL.md** — Orchestrator skill
6. **skills/01-context-load/SKILL.md** — Phase 1: context loading
7. **skills/02-stack-audit/SKILL.md** — Phase 2: stack auditing
8. **skills/03-issue-craft/SKILL.md** — Phase 3: issue crafting
9. **skills/04-pr-context/SKILL.md** — Phase 4: PR context building
10. **skills/05-frontend-preview/SKILL.md** — Phase 5: frontend preview (optional)
11. **skills/06-label-metadata/SKILL.md** — Label taxonomy
12. **templates/issue-contextualized.md** — Issue body template
13. **templates/pr-contextualized.md** — PR body template

---

## Project Snapshot

| Metric | Value |
|--------|-------|
| Orchestrator skill | 1 (contextforge) |
| Sub-skills | 6 (context-load, stack-audit, issue-craft, pr-context, frontend-preview, label-metadata) |
| Templates | 2 (issue, PR) |
| Docs | 3 (ARCHITECTURE, FLOW, IDEAS) |
| Skill format | Devin-native (`.devin/skills/`) + portable (`skills/`) |
| Dependencies | `gh` CLI, optional: Playwright (frontend-preview) |

---

## Preferred Workflow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. CONTEXT-LOAD  →  Read all project MDs, build snapshot        │
│  2. STACK-AUDIT   →  Detect orphan PRs, stale issues, libs       │
│  3. ISSUE-CRAFT   →  Craft issue with AC, labels, metadata       │
│  4. PR-CONTEXT    →  Build PR body with issue context            │
│  5. FRONTEND-PREVIEW (optional) → Visual diff, screenshot        │
│  6. LAUNCH        →  gh issue create / gh pr create              │
└─────────────────────────────────────────────────────────────────┘
```

### Phase Rules

- **Never skip context-load** — every issue and PR must be built from a snapshot
- **Never skip stack-audit** — always check for orphan PRs and escaped issues
- **Max 2 AC for autonomous issues** — more than 2 = decompose or `batch-delivery`
- **Library suggestions are separate issues** — never bundle into the main issue
- **Labels are mandatory** — type + priority + area, minimum 3 labels per issue
- **Context is compressed** — reference paths, never inline file contents

---

## Context Compression Rules

1. **Paths, not contents** — `src/shared/Constants.luau` not the file's code
2. **Commands, not configs** — `lune run scripts/test_core.luau` not the test file
3. **Check names, not YAML** — `test (lune)` not the full workflow
4. **Counts, not lists** — "26 services" not all 26 service names
5. **Labels, not body text** — `priority:P1` not "Priority: High" in body
6. **Max 5 bullets per section** in the snapshot

---

## Label Taxonomy (summary)

See `skills/06-label-metadata/SKILL.md` for full taxonomy.

| Category | Labels |
|----------|--------|
| Type | `bug`, `enhancement`, `documentation`, `refactor`, `chore`, `test`, `security` |
| Priority | `priority:P0`, `priority:P1`, `priority:P2`, `priority:P3` |
| Area | `area:backend`, `area:frontend`, `area:ci`, `area:docs`, `area:security`, `area:devops` |
| Status | `ready-to-implement`, `needs-metadata`, `blocked`, `needs-human` |
| Enhancement | `library-review`, `batch-delivery` |

**Every issue MUST have**: 1 type + 1 priority + 1 area label (minimum).

---

## Installation

### Into a Devin project

Copy or symlink `.devin/skills/contextforge/` into the target project's
`.devin/skills/` directory:

```bash
cp -r .devin/skills/contextforge /target/project/.devin/skills/
```

### Into an OpenCode project

Copy the orchestrator and sub-skills into the target project's skill directory:

```bash
cp -r .devin/skills/contextforge /target/project/.config/opencode/skills/
cp -r skills/* /target/project/.config/opencode/skills/
```

### Into a Claude Code project

Copy into `.claude/skills/`:

```bash
cp -r .devin/skills/contextforge /target/project/.claude/skills/
cp -r skills/* /target/project/.claude/skills/
```

### Label setup

Run the label creation commands from `skills/06-label-metadata/SKILL.md` in the
target repo to create all canonical labels.

---

## Git Commits

```
feat:     New skill phase or feature
fix:      Bug fix in a skill
docs:     Documentation change
refactor: Skill reorganization
chore:    Build, config, tooling
```

---

## Key File Reference

| Purpose | File |
|---------|------|
| Orchestrator skill | `.devin/skills/contextforge/SKILL.md` |
| Phase 1: context-load | `skills/01-context-load/SKILL.md` |
| Phase 2: stack-audit | `skills/02-stack-audit/SKILL.md` |
| Phase 3: issue-craft | `skills/03-issue-craft/SKILL.md` |
| Phase 4: pr-context | `skills/04-pr-context/SKILL.md` |
| Phase 5: frontend-preview | `skills/05-frontend-preview/SKILL.md` |
| Label taxonomy | `skills/06-label-metadata/SKILL.md` |
| Issue template | `templates/issue-contextualized.md` |
| PR template | `templates/pr-contextualized.md` |
| Architecture | `docs/ARCHITECTURE.md` |
| Flow diagram | `docs/FLOW.md` |
| Ideas mapping | `docs/IDEAS.md` |
