# ACF — Multi-Agent Compatibility

This document explains how ACF (Agent Context Forge) is compatible with all
major AI coding agents, how it complies with the Agent Skills specification,
and how to install it into any supported agent's project.

---

## Supported Agents

ACF is designed to be agent-agnostic. The skills are written as plain
Markdown files with YAML frontmatter, following the
[Agent Skills specification](https://agentskills.io). Any agent that loads
skills from a local directory can consume ACF.

The following agents are explicitly supported:

| Agent | Vendor / Project | Skill directory |
|-------|------------------|-----------------|
| Claude Code | Anthropic | `.claude/skills/` |
| Cursor | Cursor | `.cursor/skills/` |
| Codex CLI | OpenAI | `.codex/skills/` |
| OpenCode | OpenCode (OSS) | `.opencode/skills/` |
| OpenClaw | OpenClaw (OSS) | `.agents/skills/` |
| Devin | Cognition | `.devin/skills/` |

> **Note on OpenClaw:** OpenClaw uses a generic `.agents/skills/` directory
> that is shared across agent runtimes that follow the common-agents
> convention. ACF installs into it the same way as the others.

---

## The Agent Skills Specification (agentskills.io)

The [Agent Skills specification](https://agentskills.io) defines a portable
format for AI agent skills. A skill is a directory containing a `SKILL.md`
file with:

1. **YAML frontmatter** delimited by `---` lines, containing:
   - `name` — a unique identifier, lowercase letters and hyphens only,
     maximum 64 characters.
   - `description` — a human-readable summary of what the skill does and when
     to use it, maximum 1024 characters.
2. **A Markdown body** describing the skill's instructions, kept under 500
   lines so it fits comfortably in an agent's context window.

### How ACF Complies

Every ACF skill file follows this format:

- **Frontmatter present** — every `SKILL.md` starts with a `---`-delimited
  YAML block containing `name` and `description`.
- **`name` convention** — names are lowercase with hyphens
  (`acf`, `context-load`, `stack-audit`, `issue-craft`, `pr-context`,
  `frontend-preview`, `label-metadata`, `compaction`, `caveman`). The
  directory name uses a numeric prefix (`01-context-load/`) for ordering,
  while the `name` field inside the frontmatter is the bare skill name.
- **`description` length** — descriptions are kept well under 1024 characters
  and include trigger phrases so the agent knows when to invoke the skill.
- **Body length** — every skill body is under 500 lines.
- **Portable structure** — each skill is a self-contained directory with a
  single `SKILL.md`, so it can be copied into any agent's skill folder.

You can verify compliance at any time by running:

```bash
./scripts/validate-skills.sh
```

This checks every `SKILL.md` in the repository against the rules above.

---

## Installation Paths

Each agent loads skills from a specific directory inside the target project.
ACF ships an orchestrator (`acf/`) plus 8 sub-skills (`01-context-load/`
through `08-caveman/`). The installer copies all of them into the chosen
agent's skill directory.

| Agent | Skill directory (relative to project root) |
|-------|---------------------------------------------|
| Devin | `.devin/skills/` |
| Claude Code | `.claude/skills/` |
| Cursor | `.cursor/skills/` |
| Codex CLI | `.codex/skills/` |
| OpenCode | `.opencode/skills/` |
| OpenClaw | `.agents/skills/` |

After installation, the target project contains, for example:

```
.claude/skills/
├── acf/                  # Orchestrator
│   └── SKILL.md
├── 01-context-load/      # Phase 1
│   └── SKILL.md
├── 02-stack-audit/       # Phase 2
│   └── SKILL.md
├── 03-issue-craft/       # Phase 3
│   └── SKILL.md
├── 04-pr-context/        # Phase 4
│   └── SKILL.md
├── 05-frontend-preview/  # Phase 5
│   └── SKILL.md
├── 06-label-metadata/    # Phase 6
│   └── SKILL.md
├── 07-compaction/        # Phase 7
│   └── SKILL.md
└── 08-caveman/           # Phase 8
    └── SKILL.md
```

---

## Using the Installer

The `install.sh` script at the repository root installs ACF into one or more
agent directories in a target project.

### Auto-detect (default)

Installs into every agent directory that already exists in the target project:

```bash
./install.sh /path/to/target-project
```

### Install to all supported agents

Creates every supported agent directory if it does not exist and installs
into all of them:

```bash
./install.sh /path/to/target-project --all
```

### Install to a specific agent

Installs only into the named agent's directory (creating it if needed).
Valid names: `devin`, `claude`, `cursor`, `codex`, `agents`, `opencode`.

```bash
./install.sh /path/to/target-project --agent claude
```

### Properties

- **Idempotent** — safe to re-run; existing files are overwritten in place.
- **Validates input** — the target path must exist before anything is copied.
- **Exit codes** — `0` on success, `1` on error.
- **Safe** — uses `set -euo pipefail` and never touches repositories other
  than the target you specify.

### Manual installation

If you prefer not to use the installer, you can copy the files directly:

```bash
# Orchestrator
cp -r .devin/skills/acf /target-project/.claude/skills/

# All 8 sub-skills
cp -r skills/* /target-project/.claude/skills/
```

Repeat for each agent directory you want to populate.

---

## The "Caveman" Naming: ACF vs OpenCode

Both ACF and OpenCode ship a skill called "caveman", and both share the
spirit of **extreme compression** — reducing verbosity to the bare minimum.
However, they operate on different sides of the agent's context window and
do **not** collide with each other.

| Aspect | ACF caveman (phase 8) | OpenCode caveman |
|--------|------------------------|------------------|
| **Directory** | `08-caveman/` | `caveman/` |
| **What it compresses** | The **input** context snapshot | The **output** model communication |
| **Purpose** | Shrink the accumulated project context (architecture, stack, tests, CI) to under 500 tokens so the agent can keep working inside a small context budget. | Shrink the agent's responses to a terse, telegraphic style to save output tokens and reduce noise. |
| **When it triggers** | After context-load, when compaction (phase 7) is not enough and the token budget is critical. | When the user or runtime requests maximally compressed output. |
| **Direction** | Context → Agent (inbound) | Agent → User/Runtime (outbound) |

Because ACF uses the numeric-prefixed directory `08-caveman/` while OpenCode
uses the bare `caveman/` directory, **no directory collision occurs** when
both are installed into the same project. An agent can load both skills
simultaneously: ACF's caveman compresses what the agent *reads*, and
OpenCode's caveman compresses what the agent *writes*.

See [`docs/COMPACTION.md`](./COMPACTION.md) for the full design notes on
ACF's compaction (phase 7) and caveman (phase 8) modes.

---

## Quick Reference: Agent → Path Table

| Agent | Skill directory | Installer `--agent` name |
|-------|-----------------|--------------------------|
| Devin | `.devin/skills/` | `devin` |
| Claude Code | `.claude/skills/` | `claude` |
| Cursor | `.cursor/skills/` | `cursor` |
| Codex CLI | `.codex/skills/` | `codex` |
| OpenClaw | `.agents/skills/` | `agents` |
| OpenCode | `.opencode/skills/` | `opencode` |
