# ContextForge

> Orchestrator skill for crafting context-rich GitHub issues and PRs that pass CI
> on the first try. Inspired by deepwork + oracle, homedir's SDLC pipeline, and
> Herne's acceptance criteria patterns.

## What it does

ContextForge runs a 5-phase pipeline before any issue or PR is created:

1. **Context-Load** — reads all project MDs (AGENTS.md, ARCHITECTURE, test docs,
   templates, CI workflows) and builds a compressed snapshot
2. **Stack-Audit** — detects orphan PRs, unclosed issues, missing issue↔PR
   references, and library opportunities
3. **Issue-Craft** — crafts an issue with structured labels, acceptance criteria
   referencing real test commands and CI checks, and a compressed body
4. **PR-Context** — builds a PR body that carries the issue's AC, test commands,
   CI check names, and scope lock
5. **Frontend-Preview** (optional) — launches a local view of the changes,
   produces a visual diff (git-style red/green on the web), and captures a
   screenshot for vision-model review

A cross-cutting 6th skill (**Label-Metadata**) defines the label taxonomy that
replaces free-text body content as the primary retrieval mechanism.

## Why

- **Reduce alucinaciones** — the AI has the full project context before writing
  anything
- **Pass checks faster** — AC reference real test commands and CI checks, so the
  PR is built to pass
- **Save tokens** — labels and path references instead of inlined content (~70%
  reduction)
- **Nothing escapes the stack** — orphan PRs and unclosed issues are detected
  before new work starts
- **Library suggestions are documented** — separate enhancement issues, not
  buried in a bug fix

## Architecture

```
contextforge (orchestrator)
├── 01-context-load      → read MDs, build snapshot
├── 02-stack-audit       → audit open stack
├── 03-issue-craft       → craft issue with AC + labels
├── 04-pr-context        → build PR body with context
├── 05-frontend-preview  → visual diff (optional)
└── 06-label-metadata    → label taxonomy (cross-cutting)
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Flow

```
context-load → stack-audit → issue-craft → gh issue create
                                            ↓
                                    [implementation]
                                            ↓
                                    pr-context → frontend-preview (optional)
                                            ↓
                                    gh pr create → CI passes ✅
```

See [docs/FLOW.md](docs/FLOW.md) for the full diagram.

## Installation

### Devin

```bash
cp -r .devin/skills/contextforge /target-project/.devin/skills/
```

### OpenCode

```bash
cp -r .devin/skills/contextforge /target-project/.config/opencode/skills/
cp -r skills/* /target-project/.config/opencode/skills/
```

### Claude Code

```bash
cp -r .devin/skills/contextforge /target-project/.claude/skills/
cp -r skills/* /target-project/.claude/skills/
```

### Labels

Run the label setup commands from
[skills/06-label-metadata/SKILL.md](skills/06-label-metadata/SKILL.md) in the
target repo.

## Usage

Once installed, the skill triggers when the user asks to create an issue, open a
PR, audit the stack, or any SDLC planning activity where context quality matters.

Example triggers:
- "arma un issue para arreglar el flashlight"
- "create a PR for the contributors color change"
- "check the stack for orphan PRs"
- "contextualiza este issue antes de lanzarlo"

## Origin

ContextForge was built from a conversation between `lil. vector` and `D4MAG3`
(31/7/26) about making issues and PRs richer in context for AI-driven
development. See [docs/IDEAS.md](docs/IDEAS.md) for the full idea mapping.

The architecture follows the **deepwork + oracle** pattern (orchestrator skill
with separate sub-skills), and borrows patterns from:
- **homedir** — label taxonomy, issue metadata validation, autonomous-implementation
  template
- **Herne** — acceptance criteria patterns, test command references, scope lock

## License

MIT
