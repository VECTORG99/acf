# End-to-End Flow

## The ACF Pipeline

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│  USER: "Quiero armar un issue para [descripción]"                    │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ PHASE 1: CONTEXT-LOAD                                        │   │
│  │                                                               │   │
│  │  Read AGENTS.md → ARCHITECTURE.md → DEVELOPMENT.md           │   │
│  │  → ACCEPTANCE_CRITERIA.md → ISSUE_TEMPLATE/*                 │   │
│  │  → PR_TEMPLATE/* → workflows/* → README.md                   │   │
│  │                                                               │   │
│  │  Output: compressed snapshot (paths + facts)                 │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ PHASE 2: STACK-AUDIT (parallel with phase 1)                 │   │
│  │                                                               │   │
│  │  gh pr list --state open → find orphan PRs                   │   │
│  │  gh issue list --state open → find stale issues              │   │
│  │  gh pr list --state merged → find close gaps                 │   │
│  │  gh issue list --state closed → find escaped issues          │   │
│  │  Identify library opportunities                               │   │
│  │                                                               │   │
│  │  Output: findings list                                        │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ PHASE 7: COMPACTION (auto, if snapshot > ~2000 tokens)       │   │
│  │                                                               │   │
│  │  Tail-preservation: keep recent phase verbatim               │   │
│  │  Priority-based: preserve task state, errors, test cmds      │   │
│  │  XML-tagged output: <current_focus> <stack> <tests> <ci>     │   │
│  │  First-person handoff: progress file as agent's own notes    │   │
│  │                                                               │   │
│  │  Output: compacted snapshot (~800 tokens)                    │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ PHASE 8: CAVEMAN (optional, if compacted still too large)    │   │
│  │                                                               │   │
│  │  No prose — only paths, commands, labels, numbers             │   │
│  │  Symbols over words — → | #N                                  │   │
│  │  Bare caveman last resort: NOW+NEXT+TESTS+CI (~100 tok)      │   │
│  │                                                               │   │
│  │  Output: caveman snapshot (<500 tokens)                      │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ PHASE 3: ISSUE-CRAFT                                          │   │
│  │                                                               │   │
│  │  Use snapshot + findings                                      │   │
│  │  Determine type (feat/fix/docs/refactor/chore/test)          │   │
│  │  Assign labels (type + priority + area + status)             │   │
│  │  Write AC referencing test commands + CI checks              │   │
│  │  If library opportunity → separate enhancement issue         │   │
│  │                                                               │   │
│  │  Output: issue draft (title, labels, body)                   │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│                    gh issue create                                    │
│                         │                                            │
│                    issue #N created                                   │
│                         │                                            │
│         ┌───────────────┴───────────────┐                            │
│         ▼                               ▼                            │
│  [Implementation happens here]   [Library review issue #M]          │
│         │                               (separate, enhancement)      │
│         ▼                                                            │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ PHASE 4: PR-CONTEXT                                           │   │
│  │                                                               │   │
│  │  Copy AC from issue #N                                        │   │
│  │  Add test commands (from snapshot)                            │   │
│  │  Add CI check names (from snapshot)                           │   │
│  │  Add scope lock checkbox                                      │   │
│  │  Add Closes #N                                                │   │
│  │                                                               │   │
│  │  Output: PR draft (body)                                      │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│  ┌──────────────────────▼───────────────────────────────────────┐   │
│  │ PHASE 5: FRONTEND-PREVIEW (optional, if frontend changes)    │   │
│  │                                                               │   │
│  │  Detect affected routes from diff                             │   │
│  │  Launch/reuse dev server                                      │   │
│  │  Navigate to route, screenshot before/after                   │   │
│  │  Visual diff (red/green overlay)                              │   │
│  │  Attach screenshot to PR                                      │   │
│  └──────────────────────┬───────────────────────────────────────┘   │
│                         │                                            │
│                    gh pr create                                       │
│                         │                                            │
│                    PR #K created                                      │
│                         │                                            │
│                    CI checks run                                      │
│                         │                                            │
│                    ✅ PR passes on first try                          │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

Note: Phases 7 (compaction) and 8 (caveman) can trigger at any point after
context-load when the accumulated context exceeds the token budget. They are
shown between phases 2 and 3 for illustration, but can also run between
phases 4 and 5, or whenever needed.

## Token Budget (approximate)

### Without compaction (large context window)

| Phase | Tokens (input) | Tokens (output) | Notes |
|-------|----------------|-----------------|-------|
| Context-load | ~2K (MDs are read, not pasted) | ~500 (snapshot) | Compressed |
| Stack-audit | ~500 (gh JSON output) | ~300 (findings) | Minimal |
| Issue-craft | ~800 (snapshot + findings) | ~400 (issue body) | Labels save tokens |
| PR-context | ~600 (issue + snapshot) | ~400 (PR body) | AC copied, not rewritten |
| Frontend-preview | ~200 (diff analysis) | ~100 (route list) | Screenshot is visual |
| **Total** | **~4K** | **~1.7K** | vs ~15K without compression |

### With compaction (phase 7, standard compression)

| Phase | Tokens (input) | Tokens (output) | Notes |
|-------|----------------|-----------------|-------|
| Context-load | ~2K | ~500 (snapshot) | Full snapshot |
| Compaction | ~2K (full snapshot) | ~800 (compacted) | Kimi-inspired |
| Stack-audit | ~500 | ~300 | Uses compacted snapshot |
| Issue-craft | ~800 | ~400 | Uses compacted snapshot |
| PR-context | ~600 | ~400 | Uses compacted snapshot |
| **Total** | **~5.9K** | **~2.4K** | More input, less per-phase |

Note: compaction costs ~2K input + ~800 output, but saves ~1.2K per subsequent
phase. It pays off when 3+ phases consume the snapshot.

### With caveman (phase 8, extreme compression)

| Phase | Tokens (input) | Tokens (output) | Notes |
|-------|----------------|-----------------|-------|
| Context-load | ~2K | ~500 (snapshot) | Full snapshot |
| Compaction | ~2K | ~800 (compacted) | Phase 7 |
| Caveman | ~800 (compacted) | ~400 (caveman) | Phase 8 |
| Stack-audit | ~300 | ~200 | Uses caveman snapshot |
| Issue-craft | ~500 | ~300 | Uses caveman snapshot |
| PR-context | ~400 | ~300 | Uses caveman snapshot |
| **Total** | **~6K** | **~2.5K** | Best for small context windows |

### Bare caveman (last resort, ~100 tokens)

| Phase | Tokens (input) | Tokens (output) | Notes |
|-------|----------------|-----------------|-------|
| All phases | ~100 (bare caveman) | ~300 (issue/PR body) | Only NOW+NEXT+TESTS+CI |
| **Total** | **~100** | **~300** | Loses all stack context |

## Compression Degradation Path

```
Full snapshot (~2000 tokens, ~70% savings vs traditional)
    │
    ▼  [trigger: token_count >= max * 0.75]
Compacted snapshot (~800 tokens, ~88% savings)
    │
    ▼  [still too large or caveman requested]
Caveman snapshot (<500 tokens, ~93% savings)
    │
    ▼  [still too large]
Bare caveman (~100 tokens, ~97% savings)
```

## Success Criteria

An ACF run is successful when:
1. The issue has all required labels (type + priority + area)
2. The issue AC reference real test commands and CI checks
3. The PR body has `Closes #N` and AC checkboxes
4. The PR passes CI on the first run (no back-and-forth)
5. No orphan PRs or escaped issues remain in the stack
6. If compaction/caveman was used, the issue/PR quality did not degrade
   (AC still reference real test commands and CI checks)
