# Contributing to ACF

Thank you for your interest in contributing to ACF! This document covers the
workflow, skill development guidelines, and conventions you need to follow.

## How to Contribute

1. **Fork** the repository.
2. **Create a branch** from `master`:
   ```bash
   git checkout -b feat/my-contribution
   ```
3. **Make your changes** following the guidelines below.
4. **Run validation** locally before pushing:
   ```bash
   bash scripts/validate-skills.sh
   ```
5. **Commit** using [Conventional Commits](#commit-format).
6. **Open a Pull Request** against `master` and fill in the PR template.
7. Ensure CI passes (skill validation + security check).

## Skill Development Guidelines

ACF skills follow the [agentskills.io](https://agentskills.io) specification.

### SKILL.md rules

- **Follow the agentskills.io spec** — each skill is a directory containing a
  `SKILL.md` with YAML frontmatter (`name`, `description`).
- **Keep `SKILL.md` under 500 lines** — skills must be concise. If a skill
  grows beyond 500 lines, decompose it or move detail into a referenced doc.
- **Name format**: lowercase with hyphens (e.g. `context-load`, `stack-audit`).
  No spaces, no underscores, no CamelCase.
- **YAML frontmatter is required** — must include `name` and `description`.
  `description` should explain when to use the skill.
- **No secrets** — never include API keys, tokens, or passwords in a skill.
- **No external API calls** — skills use local tools and the `gh` CLI only.
- **No hardcoded non-documentation URLs** — only documentation links are
  allowed in `SKILL.md` files.

### Directory structure

```
skills/<NN-name>/
  SKILL.md
```

Where `NN` is a two-digit phase number for pipeline skills, or omitted for
cross-cutting skills.

## Mirror Convention

ACF ships skills in **two locations**:

| Location | Role |
|----------|------|
| `skills/` | **Source of truth** — edit here |
| `.devin/skills/` | **Devin-native mirror** — re-mirror after editing |

### Rules

1. **Always edit `skills/` first.** This is the source of truth.
2. **Re-mirror to `.devin/skills/`** after every change:
   ```bash
   # Mirror a single skill
   cp skills/<NN-name>/SKILL.md .devin/skills/<NN-name>/SKILL.md

   # Mirror all skills
   for d in skills/*/; do
     name=$(basename "$d")
     mkdir -p ".devin/skills/$name"
     cp "$d/SKILL.md" ".devin/skills/$name/SKILL.md"
   done
   ```
3. **Never edit the mirror directly.** Changes in `.devin/skills/` without a
   corresponding change in `skills/` will be rejected in review.
4. **Both copies must stay in sync.** CI checks that mirrors match their
   source.

## Commit Format

ACF uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <description>
```

| Type | Use for |
|------|---------|
| `feat` | New skill phase or feature |
| `fix` | Bug fix in a skill |
| `docs` | Documentation change |
| `refactor` | Skill reorganization (no behavior change) |
| `chore` | Build, config, tooling |
| `test` | Test or validation changes |
| `security` | Security-related fix |

Examples:
```
feat: add stack-audit orphan-PR detection
fix: correct label taxonomy priority mapping
docs: update ARCHITECTURE with mirror convention
```

## Code of Conduct

Participation in this project is governed by the
[Code of Conduct](CODE_OF_CONDUCT.md). Please be respectful and professional.

## Security

- **Never commit secrets** — no API keys, tokens, or passwords. CI scans
  every push and PR for secret patterns.
- **Report vulnerabilities privately** — see [SECURITY.md](SECURITY.md) for
  the reporting process. Do not open public issues for security vulnerabilities.
- **Review skill content carefully** — skills are agent instructions; a
  malicious skill is the primary security risk. See SECURITY.md for details.

## Questions?

Open a discussion or an issue with the `documentation` label if anything in
this guide is unclear.
