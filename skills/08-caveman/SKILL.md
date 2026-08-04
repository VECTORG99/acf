---
name: caveman
description: >-
  Phase 8 of ACF (optional, extreme mode). Reduces the context snapshot to
  the absolute minimum — bare paths, counts, labels, and commands with zero
  prose. Target: under 500 tokens for the entire snapshot. Use when token
  budget is critical, when the model has a very small context window, or
  when the user asks for "caveman mode", "extreme compression", or "bare
  minimum context".
---

# Caveman

Extreme compression mode. Named "caveman" because the output looks like
cave paintings — nothing but the essential marks, no decoration.

## When to Trigger

- The compacted snapshot (from phase 7) is still too large for the target model
- The model has a small context window (<8K tokens)
- The user explicitly asks for "caveman mode" or "extreme compression"
- Running ACF on a budget-constrained API (pay-per-token)
- The snapshot needs to fit in a single system prompt

## Caveman Principles

1. **No prose** — every word must earn its place; if it's not a path, command,
   label, or number, it doesn't belong
2. **Paths, not descriptions** — `AGENTS.md` not "the agent directives file"
3. **Counts, not lists** — `26 services` not a list of 26 service names
4. **Labels, not sentences** — `priority:P1` not "this is high priority"
5. **Commands, not explanations** — `lune run scripts/test_core.luau` not
   "run the core test suite with lune"
6. **Symbols over words** — `→` instead of "leads to", `|` instead of "or",
   `#N` instead of "issue number N"

## Caveman Snapshot Format

The entire context snapshot in caveman mode fits in this structure:

```
ACF@<project> | branch:<name> | issues:<N> | PRs:<M>

STACK
orphan:<N> | stale:<N> | gaps:[PR#→Issue#] | escaped:[#N] | lib:[N]

TESTS
<cmd1> → <N>pass
<cmd2> → <N>pass
cov:<cmd|none>

CI
<check1>@<workflow1>
<check2>@<workflow2>

ARCH
stack:<lang+fw, 1line>
dirs:<src/ scripts/ docs/>
arch:<path|none>

LABELS
type:bug|enhancement|docs|refactor|chore|test|security
pri:P0|P1|P2|P3
area:backend|frontend|ci|docs|security|devops

CONV
commit:conventional
branch:feature/|fix/|docs/

NOW
<current issue/PR — 1line>
NEXT
<next action — 1line>
```

## Token Budget

| Mode | Target tokens | Chars (approx) | When to use |
|------|--------------|----------------|-------------|
| Full | ~2000 | ~8000 | Default, large context window |
| Compacted (phase 7) | ~800 | ~3200 | Standard compression |
| Caveman (phase 8) | <500 | <2000 | Extreme, small context window |

## Caveman Compression Techniques

### Path compression
- `src/server/Services/CycleManager.luau` → `srv/CycleManager`
- `docs/ARCHITECTURE.md` → `arch.md`
- `.github/workflows/ci.yml` → `ci.yml`

Only compress paths when the project structure is known from context-load.
Never compress a path that could be ambiguous.

### Command compression
- `lune run scripts/test_core.luau` → `lune test_core`
- `bash scripts/dev.sh --test` → `dev.sh --test`
- `gh pr list --state open --json number,title,body` → `gh pr list --open`

Only compress commands that are unambiguous in the project context.

### Finding compression
- "PR #42 has no issue reference — orphan PR" → `orphan:42`
- "Issue #17 is ready but no PR is open — stale issue" → `stale:17`
- "PR #38 merged but issue #29 still open — close gap" → `gap:38→29`
- "Issue #51 closed but no merged PR — escaped issue" → `esc:51`

### Label compression
- `priority:P0` → `P0`
- `area:backend` → `backend`
- `ready-to-implement` → `ready`

## Degradation Path

```
Full snapshot (~2000 tokens)
    │
    ▼  [trigger_ratio exceeded]
Compacted snapshot (~800 tokens, phase 7)
    │
    ▼  [still too large or caveman requested]
Caveman snapshot (<500 tokens, phase 8)
    │
    ▼  [still too large]
Bare caveman: only NOW + NEXT + TESTS + CI (~100 tokens)
```

## Bare Caveman (last resort)

When even the caveman snapshot is too large, strip to the absolute minimum:

```
NOW:<issue/PR 1line>
NEXT:<action 1line>
TEST:<cmd> → <N>pass
CI:<check>@<wf>
```

This is ~100 tokens. It loses all stack context but preserves the ability
to craft an issue or PR with the right test command and CI check.

## Relationship to Compaction

Caveman is NOT a replacement for compaction (phase 7). It is the next step
when compaction is not enough. The typical flow is:

```
context-load → stack-audit → [compaction if needed] → [caveman if still needed] → issue-craft → pr-context
```

Caveman can also be triggered directly (skipping compaction) when the user
knows upfront that the context budget is very small.

## What Caveman Loses

Be explicit about what caveman mode sacrifices:
- **Architecture context** — only a one-line stack summary remains
- **Convention details** — only label names, no rules
- **Library opportunities** — reduced to a count, no details
- **Stale issue titles** — reduced to issue numbers
- **Template structure** — not included at all

If any of these are critical for the current issue/PR, do NOT use caveman.
Use compaction (phase 7) instead.

## Sources

- Inspired by Kimi CLI's compaction system ([MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli))
- Caveman takes Kimi's compression rules to their logical extreme
- The "bare caveman" last-resort format is original to ACF
