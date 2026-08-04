# ACF — Agentic Context Forger

> A composable repertoire of high-level skills that give AI coding agents
> surgical precision over project context. Decompose projects into navigable
> dependency graphs, compact context to fit any model's window, and craft
> issues and PRs that pass CI on the first try.

ACF is not a single skill — it's a **repertoire**. Each skill works
independently ("just compact this", "just audit the stack", "just map the
graph"), but together they form a pipeline that takes an agent from "what
should I do?" to "here's the exact scope, the exact context, and the exact
issue/PR — all compressed to fit your token budget."

## The Three Layers

ACF organizes its skills into three layers. Each layer can be used alone,
combined with another, or run end-to-end through the orchestrator.

### 1. Scope — graph-scope

The project is decomposed into a **dependency graph**. When a change is
requested, only the affected subgraph is loaded — not the entire project.
The agent reads what matters, not everything.

- Build the graph with grep/find (no external dependencies, no runtime)
- Forward traversal: blast radius (what might break)
- Backward traversal: context scope (what to load)
- 60-90% context reduction on large projects

### 2. Context — context-load + compaction + caveman

A compressed snapshot of the relevant scope is built, then compressed
again to fit the model's context window.

- **Full**: ~21K tokens (all skills concatenated, baseline)
- **Compacted** (phase 7): ~284 tokens — **98% savings** (tail-preservation,
  priority-based, XML-tagged, first-person handoff)
- **Caveman** (phase 8): ~64 tokens — **99% savings** (no prose, symbols
  over words, bare minimum)
- **Bare caveman**: ~26 tokens — **99% savings** (only NOW + NEXT + TESTS + CI)

The same pipeline runs on a 200K context window or a 4K one.

### 3. Craft — issue-craft + pr-context + stack-audit + label-metadata

Structured GitHub artifacts with acceptance criteria that reference real
test commands and CI checks. Labels replace free text as the primary
retrieval mechanism.

- Issues with AC checkboxes, test commands, CI check names, complexity
- PRs that carry the issue's context forward (scope lock, AC verification)
- Stack audit: orphan PRs, unclosed issues, missing issue↔PR references
- Label taxonomy: type + priority + area + status (minimum 3 per issue)

## The Repertoire

| Skill | Layer | Works standalone | Synergy |
|-------|-------|-----------------|---------|
| `graph-scope` | Scope | Yes — "map dependencies", "what breaks if I change X" | Narrows context-load to the affected subgraph |
| `context-load` | Context | Yes — "load context", "read the project docs" | Feeds issue-craft and pr-context |
| `stack-audit` | Context | Yes — "check the stack", "find orphan PRs" | Surfaces blockers before issue-craft |
| `issue-craft` | Craft | Yes — "create an issue", "armar un issue" | Consumes context-load + stack-audit output |
| `pr-context` | Craft | Yes — "open a PR", "lanzar un PR" | Carries issue-craft AC into the PR body |
| `frontend-preview` | Craft | Yes — "preview the frontend", "visual diff" | Optional, triggered on frontend changes |
| `label-metadata` | Craft | Yes — "label conventions", "taxonomy" | Cross-cutting, used by issue-craft and pr-context |
| `compaction` | Context | Yes — "compact context", "compress the snapshot" | Compresses any accumulated context |
| `caveman` | Context | Yes — "modo caveman", "extreme compression" | Last resort when compaction isn't enough |

**All-in-one**: the `acf` orchestrator runs all skills as a pipeline:
`graph-scope → context-load → stack-audit → issue-craft → pr-context → launch`,
with `compaction` and `caveman` triggering automatically when the token
budget is exceeded.

## Architecture

```
.devin/skills/
├── acf/                 → orchestrator (all skills as a pipeline)
├── 01-context-load/     → read MDs + scoped files, build snapshot
├── 02-stack-audit/      → audit open GitHub stack
├── 03-issue-craft/      → craft issue with AC + labels
├── 04-pr-context/       → build PR body with context
├── 05-frontend-preview/ → visual diff (optional)
├── 06-label-metadata/   → label taxonomy (cross-cutting)
├── 07-compaction/       → context compaction
├── 08-caveman/          → extreme compression <500 tokens
└── 09-graph-scope/      → dependency graph + blast radius (cross-cutting)

skills/                  → portable source of truth (same 9 sub-skills)
```

`skills/` is the source of truth; `.devin/skills/*` are kept-in-sync
mirrors. The installer copies both into any supported agent's directory.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Flow

```
graph-scope → context-load (scoped) → stack-audit → issue-craft → gh issue create
                                                                     ↓
                                                             [implementation]
                                                                     ↓
                                                             pr-context → frontend-preview (optional)
                                                                     ↓
                                                             gh pr create → CI passes ✅

[compaction triggers when snapshot > ~2000 tokens]
[caveman triggers when compacted snapshot still too large]
```

In `full` mode (small projects or explicit request), graph-scope is skipped
and context-load reads everything.

See [docs/FLOW.md](docs/FLOW.md) for the full diagram.

## Context Compaction

Two compression modes, measured by the benchmark suite:

| Mode | Phase | Tokens | Savings | Technique |
|------|-------|--------|---------|-----------|
| Full | 1-6 | ~21,000 | baseline | Paths, labels, counts |
| Compacted | 7 | ~284 | 98% | Tail-preservation, priority-based, XML-tagged, first-person handoff |
| Caveman | 8 | ~64 | 99% | No prose, symbols over words, bare minimum |
| Bare caveman | 8 (last resort) | ~26 | 99% | Only NOW + NEXT + TESTS + CI |

See [docs/COMPACTION.md](docs/COMPACTION.md) for the full design notes.

## Graph-Scope

The differentiator. Existing tools (change-impact-analysis, project-understanding,
Hawkeye, Constrictor) build dependency graphs with AST parsers and external
dependencies. ACF graph-scope does it with **grep and agent reasoning** — no
runtime, no tree-sitter, no Python.

| Tool | Dependencies | ACF integration | Compaction |
|------|--------------|-----------------|------------|
| change-impact-analysis | Python, PyYAML | None | No |
| project-understanding | Node, tree-sitter | None | Token budgeting |
| Hawkeye | Python | None | Compact JSON |
| Constrictor | Python | None | No |
| **ACF graph-scope** | **None** | **Yes (pipeline)** | **Yes (phase 7/8)** |

The trade-off: less precise than AST-based tools (regex, not parsing). The
advantage: zero dependencies, any language, integrates with compaction and
issue-craft, produces agent-readable markdown.

## Testing

```bash
bash scripts/test-all.sh
```

| Suite | Tests | What it covers |
|-------|-------|----------------|
| `test-validate.sh` | 9 | Frontmatter, name, description, body length, mirror sync |
| `test-install.sh` | 12 | All 6 agents, --all, --agent, auto-detect, errors, idempotency |
| `test-integration.sh` | 6 | Install → validate, byte-identical, preserves existing, no leaks |
| `benchmark-compaction.sh` | — | Token counts: full → compacted (98%) → caveman (99%) → bare (99%) |

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

Once installed, skills trigger individually or together:

**Standalone:**
- "map this project's dependencies" → graph-scope
- "compacta el contexto — keep the stack-audit findings" → compaction
- "check the stack for orphan PRs" → stack-audit
- "modo caveman para este issue" → caveman

**All-in-one (orchestrator):**
- "arma un issue para arreglar el flashlight" → full pipeline
- "create a PR for the contributors color change" → full pipeline
- "contextualiza este issue antes de lanzarlo" → full pipeline
- "que se rompe si cambio Constants.luau?" → graph-scope + issue-craft

## Origin

ACF was built from a conversation between `lil. vector` and `D4MAG3`
(31/7/26) about making issues and PRs richer in context for AI-driven
development. The name stands for **Agentic Context Forger** — the project
forges context for agents, not just loads it.

See [docs/IDEAS.md](docs/IDEAS.md) for the full idea mapping and
[docs/PROCESS.md](docs/PROCESS.md) for the build process.

## License

MIT
