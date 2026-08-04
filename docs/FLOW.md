# End-to-End Flow

## The ContextForge Pipeline

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

## Token Budget (approximate)

| Phase | Tokens (input) | Tokens (output) | Notes |
|-------|----------------|-----------------|-------|
| Context-load | ~2K (MDs are read, not pasted) | ~500 (snapshot) | Compressed |
| Stack-audit | ~500 (gh JSON output) | ~300 (findings) | Minimal |
| Issue-craft | ~800 (snapshot + findings) | ~400 (issue body) | Labels save tokens |
| PR-context | ~600 (issue + snapshot) | ~400 (PR body) | AC copied, not rewritten |
| Frontend-preview | ~200 (diff analysis) | ~100 (route list) | Screenshot is visual |
| **Total** | **~4K** | **~1.7K** | vs ~15K without compression |

## Success Criteria

A ContextForge run is successful when:
1. The issue has all required labels (type + priority + area)
2. The issue AC reference real test commands and CI checks
3. The PR body has `Closes #N` and AC checkboxes
4. The PR passes CI on the first run (no back-and-forth)
5. No orphan PRs or escaped issues remain in the stack
