# ACF - Agentic Context Forger

> Orchestrator skill for crafting context-rich GitHub issues and PRs that pass CI
> on the first try. Inspired by deepwork + oracle, homedir's SDLC pipeline, and
> Herne's acceptance criteria patterns. Includes Kimi CLI-inspired context
> compaction and caveman extreme-compression mode.

## What it does

ACF runs an 8-phase pipeline before any issue or PR is created:

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
6. **Launch** — creates the issue/PR via `gh`, verifies labels were applied
7. **Compaction** (auto/optional) — Kimi CLI-inspired context compaction when
   the snapshot exceeds the token budget (tail-preservation, priority-based
   compression, XML-tagged output, first-person handoff)
8. **Caveman** (optional, extreme) — extreme compression to under 500 tokens
   for small context windows or budget-constrained runs

A cross-cutting 6th skill (**Label-Metadata**) defines the label taxonomy that
replaces free-text body content as the primary retrieval mechanism.

## Why

- **Reduce alucinaciones** — the AI has the full project context before writing
  anything
- **Pass checks faster** — AC reference real test commands and CI checks, so the
  PR is built to pass
- **Save tokens** — labels and path references instead of inlined content (~70%
  reduction with compaction, ~90% with caveman)
- **Nothing escapes the stack** — orphan PRs and unclosed issues are detected
  before new work starts
- **Library suggestions are documented** — separate enhancement issues, not
  buried in a bug fix
- **Runs on any context window** — compaction and caveman modes adapt the
  pipeline to small models and budget-constrained APIs

## Architecture

```
.devin/skills/
├── acf/                 → orchestrator (Devin-native)
├── 01-context-load/     → read MDs, build snapshot (mirror)
├── 02-stack-audit/      → audit open stack (mirror)
├── 03-issue-craft/      → craft issue with AC + labels (mirror)
├── 04-pr-context/       → build PR body with context (mirror)
├── 05-frontend-preview/ → visual diff, optional (mirror)
├── 06-label-metadata/   → label taxonomy, cross-cutting (mirror)
├── 07-compaction/       → Kimi-inspired context compaction (mirror)
└── 08-caveman/          → extreme compression <500 tokens (mirror)

skills/                  → portable source of truth (same 8 sub-skills)
```

`skills/` is the source of truth for sub-skill content; `.devin/skills/*-*`
are kept-in-sync mirrors so a single `cp -r .devin/skills/*` installs
everything for Devin.

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

[compaction triggers when snapshot > ~2000 tokens]
[caveman triggers when compacted snapshot still too large]
```

See [docs/FLOW.md](docs/FLOW.md) for the full diagram.

## Context Compaction

ACF includes two context compression modes inspired by Kimi CLI's open-source
compaction system ([MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli)):

| Mode | Phase | Target tokens | Technique |
|------|-------|--------------|-----------|
| Full | 1-6 | ~2000 | Paths, labels, counts (default) |
| Compacted | 7 | ~800 | Tail-preservation, priority-based, XML-tagged, first-person handoff |
| Caveman | 8 | <500 | No prose, symbols over words, bare minimum |
| Bare caveman | 8 (last resort) | ~100 | Only NOW + NEXT + TESTS + CI |

See [docs/COMPACTION.md](docs/COMPACTION.md) for the full research and design notes.

## Testing

ACF includes a full test suite covering the installer, validator, integration,
and compaction benchmark:

```bash
bash scripts/test-all.sh
```

| Suite | Tests | What it covers |
|-------|-------|----------------|
| `test-validate.sh` | 9 | Frontmatter, name, description, body length, mirror sync |
| `test-install.sh` | 12 | All 6 agents, --all, --agent, auto-detect, errors, idempotency |
| `test-integration.sh` | 6 | Install → validate, byte-identical, preserves existing, no leaks |
| `benchmark-compaction.sh` | — | Token counts: full (21082) → compacted (284, 98%) → caveman (64, 99%) → bare (26, 99%) |

All 35 tests pass. CI runs them on every push and PR.

## Installation

### Universal installer (recommended)

```bash
./install.sh /target-project              # auto-detect agent directories
./install.sh /target-project --all        # install to all 6 supported agents
./install.sh /target-project --agent claude  # install to a specific agent
```

Supported agents: Claude Code, Cursor, Codex CLI, OpenCode, OpenClaw, Devin.

See [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) for the full compatibility
matrix and installation paths.

### Manual installation

**Devin:**
```bash
cp -r .devin/skills/* /target-project/.devin/skills/
```

**Claude Code / Cursor / Codex / OpenCode / OpenClaw:**
```bash
cp -r .devin/skills/acf /target-project/.claude/skills/
cp -r skills/* /target-project/.claude/skills/
```

### Labels

Run the label setup commands from
[skills/06-label-metadata/SKILL.md](skills/06-label-metadata/SKILL.md) in the
target repo.

## Usage

Once installed, the skill triggers when the user asks to create an issue, open a
PR, audit the stack, compact context, or any SDLC planning activity where
context quality matters.

Example triggers:
- "arma un issue para arreglar el flashlight"
- "create a PR for the contributors color change"
- "check the stack for orphan PRs"
- "contextualiza este issue antes de lanzarlo"
- "compacta el contexto — keep the stack-audit findings"
- "modo caveman para este issue"

## Origin

ACF was built from a conversation between `lil. vector` and `D4MAG3`
(31/7/26) about making issues and PRs richer in context for AI-driven
development. See [docs/IDEAS.md](docs/IDEAS.md) for the full idea mapping and
[docs/PROCESS.md](docs/PROCESS.md) for the build process.

The architecture follows the **deepwork + oracle** pattern (orchestrator skill
with separate sub-skills), and borrows patterns from:
- **deepwork** — orchestrator-as-scheduler, progress file, sub-skill delegation
- **homedir** — label taxonomy, issue metadata validation, autonomous-implementation
  template
- **Herne** — acceptance criteria patterns, test command references, scope lock
- **Kimi CLI** — context compaction (tail-preservation, priority-based
  compression, XML-tagged output, first-person handoff)

## License

MIT
