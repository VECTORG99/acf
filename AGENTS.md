# ACF — AI Agent Directives

> **Canonical workflow for every agent using ACF to craft issues and PRs.**
> Read this file top-to-bottom before using the skill.

## Reading Order

1. **AGENTS.md** (this file) — Agent workflow and conventions
2. **docs/ARCHITECTURE.md** — Skill architecture and data flow
3. **docs/FLOW.md** — End-to-end pipeline diagram
4. **docs/IDEAS.md** — Source conversation and idea mapping
5. **docs/PROCESS.md** — Build process and decision log
6. **docs/COMPACTION.md** — Context compaction research (Kimi CLI) and caveman mode
7. **docs/COMPATIBILITY.md** — Multi-agent compatibility (agentskills.io spec)
8. **docs/ROADMAP.md** — Product roadmap and maturity assessment
9. **.devin/skills/acf/SKILL.md** — Orchestrator skill
10. **skills/01-context-load/SKILL.md** — Phase 1: context loading (mirrored at `.devin/skills/01-context-load/`)
11. **skills/02-stack-audit/SKILL.md** — Phase 2: stack auditing (mirrored at `.devin/skills/02-stack-audit/`)
12. **skills/03-issue-craft/SKILL.md** — Phase 3: issue crafting (mirrored at `.devin/skills/03-issue-craft/`)
13. **skills/04-pr-context/SKILL.md** — Phase 4: PR context building (mirrored at `.devin/skills/04-pr-context/`)
14. **skills/05-frontend-preview/SKILL.md** — Phase 5: frontend preview (optional) (mirrored at `.devin/skills/05-frontend-preview/`)
15. **skills/06-label-metadata/SKILL.md** — Label taxonomy (mirrored at `.devin/skills/06-label-metadata/`)
16. **skills/07-compaction/SKILL.md** — Phase 7: context compaction (mirrored at `.devin/skills/07-compaction/`)
17. **skills/08-caveman/SKILL.md** — Phase 8: extreme compression (mirrored at `.devin/skills/08-caveman/`)
18. **templates/issue-contextualized.md** — Issue body template
19. **templates/pr-contextualized.md** — PR body template
20. **SECURITY.md** — Security policy
21. **CONTRIBUTING.md** — Contributing guidelines

---

## Project Snapshot

| Metric | Value |
|--------|-------|
| Orchestrator skill | 1 (acf) |
| Sub-skills | 8 (context-load, stack-audit, issue-craft, pr-context, frontend-preview, label-metadata, compaction, caveman) |
| Templates | 2 (issue, PR) |
| Docs | 7 (ARCHITECTURE, FLOW, IDEAS, PROCESS, COMPACTION, COMPATIBILITY, ROADMAP) |
| Skill format | Agent Skills spec (agentskills.io) — compatible with Claude Code, Cursor, Codex CLI, OpenCode, OpenClaw, Devin |
| Source of truth | `skills/` (portable) + `.devin/skills/` (Devin mirror) |
| Installer | `install.sh` — auto-detect, `--all`, `--agent <name>` |
| Dependencies | `gh` CLI, optional: Playwright (frontend-preview) |
| Compaction | Kimi CLI-inspired (phase 7) + caveman extreme mode (phase 8) |
| Security | SECURITY.md, CODEOWNERS, CI secret scan, skill validation CI |
| Tests | 4 suites (validate, install, integration, benchmark) — 35 tests, all passing |

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
│  7. COMPACTION (auto/optional) → Kimi-inspired context compaction│
│  8. CAVEMAN (optional, extreme) → <500 tokens extreme compression│
└─────────────────────────────────────────────────────────────────┘
```

Phases 7 and 8 can trigger at any point after context-load when the
accumulated context exceeds the token budget.

### Phase Rules

- **Never skip context-load** — every issue and PR must be built from a snapshot
- **Never skip stack-audit** — always check for orphan PRs and escaped issues
- **Max 2 AC for autonomous issues** — more than 2 = decompose or `batch-delivery`
- **Library suggestions are separate issues** — never bundle into the main issue
- **Labels are mandatory** — type + priority + area, minimum 3 labels per issue
- **Context is compressed** — reference paths, never inline file contents
- **Compaction triggers at ~2000 tokens** — auto-compact using Kimi techniques
- **Caveman triggers when compaction is not enough** — target <500 tokens

---

## Context Compression Rules

ACF has three compression tiers:

| Tier | Phase | Target tokens | When to use |
|------|-------|--------------|-------------|
| Full | 1-6 | ~2000 | Default, large context window |
| Compacted | 7 | ~800 | Standard compression (Kimi-inspired) |
| Caveman | 8 | <500 | Extreme, small context window or budget |

### Compression principles (all tiers)

1. **Paths, not contents** — `src/shared/Constants.luau` not the file's code
2. **Commands, not configs** — `lune run scripts/test_core.luau` not the test file
3. **Check names, not YAML** — `test (lune)` not the full workflow
4. **Counts, not lists** — "26 services" not all 26 service names
5. **Labels, not body text** — `priority:P1` not "Priority: High" in body
6. **Max 5 bullets per section** in the snapshot

### Compaction-specific (phase 7)

- **Tail-preservation**: keep recent phase output verbatim, compact older
- **Priority-based**: preserve task state, errors, test commands, CI checks
- **XML-tagged output**: `<current_focus>`, `<stack>`, `<tests>`, `<ci>`
- **First-person handoff**: progress file reads as agent's own working notes

### Caveman-specific (phase 8)

- **No prose** — only paths, commands, labels, numbers
- **Symbols over words** — `→`, `|`, `#N`
- **Bare caveman last resort** — only `NOW + NEXT + TESTS + CI` (~100 tokens)

See `docs/COMPACTION.md` for the full research and design notes.

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

### Universal installer (recommended)

Use `install.sh` to install ACF into any project. It auto-detects which agent
directories exist and installs to all of them:

```bash
./install.sh /target/project
```

Install to ALL supported agents (creating directories as needed):

```bash
./install.sh /target/project --all
```

Install to a specific agent only:

```bash
./install.sh /target/project --agent claude
```

Supported agents: `devin`, `claude`, `cursor`, `codex`, `agents`, `opencode`

See `docs/COMPATIBILITY.md` for the full compatibility matrix.

### Manual installation

If you prefer to copy files manually:

**Devin:**
```bash
cp -r .devin/skills/* /target/project/.devin/skills/
```

**Claude Code / Cursor / Codex / OpenCode / OpenClaw:**
```bash
cp -r .devin/skills/acf /target/project/.claude/skills/
cp -r skills/* /target/project/.claude/skills/
```

(Replace `.claude/skills/` with the appropriate path for your agent — see
`docs/COMPATIBILITY.md` for the path table.)

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

| Purpose | File (portable) | Devin mirror |
|---------|------|------|
| Orchestrator skill | `.devin/skills/acf/SKILL.md` | — |
| Phase 1: context-load | `skills/01-context-load/SKILL.md` | `.devin/skills/01-context-load/SKILL.md` |
| Phase 2: stack-audit | `skills/02-stack-audit/SKILL.md` | `.devin/skills/02-stack-audit/SKILL.md` |
| Phase 3: issue-craft | `skills/03-issue-craft/SKILL.md` | `.devin/skills/03-issue-craft/SKILL.md` |
| Phase 4: pr-context | `skills/04-pr-context/SKILL.md` | `.devin/skills/04-pr-context/SKILL.md` |
| Phase 5: frontend-preview | `skills/05-frontend-preview/SKILL.md` | `.devin/skills/05-frontend-preview/SKILL.md` |
| Phase 6: label-metadata | `skills/06-label-metadata/SKILL.md` | `.devin/skills/06-label-metadata/SKILL.md` |
| Phase 7: compaction | `skills/07-compaction/SKILL.md` | `.devin/skills/07-compaction/SKILL.md` |
| Phase 8: caveman | `skills/08-caveman/SKILL.md` | `.devin/skills/08-caveman/SKILL.md` |
| Issue template | `templates/issue-contextualized.md` | — |
| PR template | `templates/pr-contextualized.md` | — |
| Architecture | `docs/ARCHITECTURE.md` | — |
| Flow diagram | `docs/FLOW.md` | — |
| Ideas mapping | `docs/IDEAS.md` | — |
| Build process | `docs/PROCESS.md` | — |
| Compaction research | `docs/COMPACTION.md` | — |
| Multi-agent compatibility | `docs/COMPATIBILITY.md` | — |
| Roadmap | `docs/ROADMAP.md` | — |
| Installer | `install.sh` | — |
| Skill validator | `scripts/validate-skills.sh` | — |
| Validator tests | `scripts/test-validate.sh` | — |
| Installer tests | `scripts/test-install.sh` | — |
| Integration tests | `scripts/test-integration.sh` | — |
| Compaction benchmark | `scripts/benchmark-compaction.sh` | — |
| Full test runner | `scripts/test-all.sh` | — |
| Security policy | `SECURITY.md` | — |
| Contributing guide | `CONTRIBUTING.md` | — |
| Code of conduct | `CODE_OF_CONDUCT.md` | — |
