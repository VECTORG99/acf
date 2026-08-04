---
name: graph-scope
description: >-
  Cross-cutting skill for ACF. Decomposes a project into a dependency graph so
  the agent loads context only for the affected subgraph, not the entire
  project. Builds the graph using grep/find (no external dependencies), stores
  it as a markdown file under .slim/acf/, and provides query patterns for
  blast-radius (forward) and context-tracing (backward). Use before
  context-load to narrow scope, when the user asks "what's affected by
  changing X", "map the dependencies", "scope this change", or when ACF
  detects the project is large enough that full context-load would waste
  tokens.
---

# Graph-Scope

Decomposes a project into a **dependency graph** so the agent navigates only
the relevant subgraph for each change. Instead of reading the entire project
(default context-load behavior), graph-scope identifies which files matter
for the current change and limits context-load to those files.

This is the difference between a **flashlight** (context-load: read all MDs)
and a **laser** (graph-scope: read only what the change touches).

## When to Trigger

- Before context-load, when the project has more than ~20 source files
- When the user asks "what's affected by changing X?"
- When the user asks to "map the dependencies" or "build the graph"
- When the user asks to "scope this change" or "narrow the context"
- When ACF detects a large project where full context-load would waste tokens
- When the user explicitly requests "full scope" (skip graph-scope, load
  everything)

## What It Produces

Two files under `.slim/acf/`:

1. **`graph.md`** — human/agent-readable graph summary (hubs, leaves, layers)
2. **`graph.json`** — machine-readable adjacency list (for programmatic
   traversal by the agent)

The graph is rebuilt when:
- The project is scanned for the first time
- The user asks to "rebuild the graph"
- Files have been added/removed since the last build (check with `git status`)

## Build Phase: Constructing the Graph

### Step 1: Detect language(s)

Identify the project's primary language(s) by file extension frequency:

```bash
find . -type f -not -path './.git/*' -not -path './node_modules/*' \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10
```

Map extensions to import patterns:

| Language | Extension(s) | Import pattern (regex) |
|----------|-------------|------------------------|
| Luau | `.luau` | `require\(.*\)` |
| Lua | `.lua` | `require\(.*\)` |
| Python | `.py` | `^import \|^from .+ import` |
| JavaScript | `.js`, `.jsx` | `require\(|^import .+ from` |
| TypeScript | `.ts`, `.tsx` | `^import .+ from|require\(` |
| Go | `.go` | `^import \(` |
| Rust | `.rs` | `^use ` |
| Java | `.java` | `^import ` |
| C# | `.cs` | `^using ` |
| C/C++ | `.c`, `.cpp`, `.h` | `^#include` |

### Step 2: Extract imports per file

For each source file, extract its imports using grep:

```bash
# Example: Luau
grep -rEn "require\(" --include="*.luau" . \
  | sed 's/:\s*require(\(.*\))/\1/' \
  | sort -u
```

The agent should adapt the pattern to the detected language(s). For
multi-language projects, run each pattern and merge results.

### Step 3: Resolve import paths

Map import strings to actual file paths. This is language-specific:

- **Luau/Lua**: `require(game:GetService("ReplicatedStorage").Packages.Knit)`
  → `src/shared/` + module name + `.luau`
- **Python**: `from src.shared.constants import X` → `src/shared/constants.py`
- **JS/TS**: `import X from './utils'` → `./utils.ts` or `./utils/index.ts`
- **Go**: `import "github.com/user/repo/pkg"` → `pkg/` directory

The agent resolves paths using `find` and `grep` — no external parser needed.

### Step 4: Build adjacency list

For each file, record:
- `id`: the file path (relative to project root)
- `imports`: list of file paths this file imports (resolved in step 3)
- `imported_by`: list of file paths that import this file (reverse edges)

Write to `.slim/acf/graph.json`:

```json
{
  "version": 1,
  "project": "project-name",
  "languages": ["luau"],
  "built_at": "2026-08-04T12:00:00Z",
  "node_count": 53,
  "edge_count": 127,
  "nodes": {
    "src/shared/Constants.luau": {
      "imports": [],
      "imported_by": [
        "src/server/Services/CycleManager.luau",
        "src/server/Services/EconomyService.luau"
      ]
    }
  }
}
```

### Step 5: Build human-readable summary

Write to `.slim/acf/graph.md`:

```markdown
# Dependency Graph

## Stats
- Nodes: 53
- Edges: 127
- Languages: luau
- Built: 2026-08-04

## Hub nodes (most depended-on, top 10)
1. src/shared/Constants.luau (26 dependents)
2. src/shared/Types.luau (22 dependents)
3. src/shared/Utils.luau (18 dependents)
...

## Leaf nodes (no dependents — safe to change without blast radius)
- src/client/Controllers/UIController.luau
...

## Isolated nodes (no imports, no dependents)
- scripts/test_core.luau
...

## Layers (by dependency depth)
- Layer 0 (no imports): Constants, Types, Utils
- Layer 1 (imports Layer 0): Services, SignalRefs
- Layer 2 (imports Layer 1): Controllers
```

## Query Phase: Scoping a Change

When a change is requested (e.g., "fix the flashlight bug in
`EntityController.luau`"), graph-scope computes the **affected subgraph**:

### Forward traversal (blast radius — what might break)

Starting from the changed file, traverse `imported_by` edges outward:

```
Changed: src/server/Services/EntityController.luau
  → imported_by: src/server/Services/CycleManager.luau
    → imported_by: src/server/init.luau
  → imported_by: src/client/Controllers/EntityController.luau
    → imported_by: src/client/init.luau
```

Result: the blast radius is `[CycleManager, init.luau (server), EntityController (client), init.luau (client)]`.

The agent should:
1. List all files in the blast radius
2. Flag any **hub nodes** in the radius (high-risk changes)
3. Flag any **test files** in the radius (must re-run those tests)

### Backward traversal (context — what to load)

Starting from the changed file, traverse `imports` edges inward:

```
Changed: src/server/Services/EntityController.luau
  → imports: src/shared/Constants.luau
  → imports: src/shared/Types.luau
  → imports: src/shared/SignalRefs.luau
  → imports: src/shared/Utils.luau
```

Result: the context scope is `[Constants, Types, SignalRefs, Utils]`.

The agent should:
1. Load context for these files (via context-load, but scoped)
2. Read their exports/types/interfaces
3. Skip files not in this subgraph

### Output: Scoped Context Directive

After computing both traversals, graph-scope writes a directive to the
progress file:

```markdown
## Graph Scope

Change target: src/server/Services/EntityController.luau

Blast radius (forward, 3 hops):
- src/server/Services/CycleManager.luau
- src/client/Controllers/EntityController.luau
- src/server/init.luau
- src/client/init.luau

Context scope (backward, full depth):
- src/shared/Constants.luau
- src/shared/Types.luau
- src/shared/SignalRefs.luau
- src/shared/Utils.luau

Test files in scope:
- scripts/test_services.luau (covers EntityController)
- scripts/test_controllers.luau (covers EntityController client)

Hub nodes in blast radius: none (all leaves/low-degree)

Scope mode: scoped (9 files of 53 total — 83% reduction)
```

## Scope Modes

| Mode | Behavior | When to use |
|------|----------|-------------|
| `scoped` | Load context only for the affected subgraph | Default, large projects |
| `full` | Load context for the entire project | Small projects, or when user says "load everything" |
| `manual` | User specifies which files to scope to | When the user knows the exact scope |

The orchestrator selects the mode:
- **Default**: `scoped` if project has >20 source files, `full` otherwise
- **Override**: user can say "full scope" or "scope to [file list]"

## Integration with ACF Pipeline

Graph-scope runs **before context-load** when in `scoped` mode:

```
graph-scope → context-load (scoped) → stack-audit → issue-craft → ...
```

In `full` mode, graph-scope is skipped and context-load reads everything:

```
context-load (full) → stack-audit → issue-craft → ...
```

The orchestrator should:
1. Check if `.slim/acf/graph.json` exists and is fresh
2. If not, run graph-scope build phase
3. Run graph-scope query phase with the change target
4. Pass the scoped file list to context-load
5. Context-load reads only those files + all project MDs (MDs are always
   loaded — they contain conventions and AC patterns)

## What Graph-Scope Does NOT Do

- **Static type analysis** — it traces imports, not type flows. For type-level
  impact, use a language-specific tool (tsc, mypy, luau-analyze).
- **Runtime dependency detection** — it scans source code, not runtime
  behavior. Dynamic imports, reflection, or dependency injection are invisible.
- **Replace tests** — it identifies which tests to run, but doesn't run them.
  The agent should use the test list from graph-scope to run the right tests.
- **Require external tools** — no tree-sitter, no AST parser, no Python. The
  agent uses grep, find, and its own language understanding to build the graph.

## Comparison to Existing Tools

| Tool | Approach | Dependencies | ACF integration | Compaction |
|------|----------|-------------|-----------------|------------|
| change-impact-analysis-skill | AST + BFS | Python, PyYAML | None | No |
| project-understanding (evil-skills) | Tree-sitter | Node, tree-sitter | None | Token budgeting |
| codespaces (diskd-ai) | Tree-sitter, belief-map | Python, tree-sitter | None | No |
| Hawkeye | AST + graph | Python | None | Compact JSON |
| Constrictor | AST | Python | None | No |
| **ACF graph-scope** | **grep + agent reasoning** | **None** | **Yes (pipeline)** | **Yes (phase 7/8)** |

ACF graph-scope is the only one that:
1. Requires zero external dependencies (agent uses grep/find)
2. Integrates with an issue/PR crafting pipeline
3. Can be compacted by phase 7 and caveman phase 8
4. Works on any language the agent understands (not limited to Python/TS)
5. Produces agent-readable markdown (not just JSON for tools)

The trade-off: ACF graph-scope is **less precise** than AST-based tools
(it uses regex, not parsing). For projects that need type-level analysis,
use an AST tool alongside ACF. For projects that need fast scope narrowing
without dependencies, ACF graph-scope is sufficient.

## Token Budget

The graph itself is compact:
- `graph.md`: ~200-500 tokens (summary, top hubs, layers)
- `graph.json`: ~500-2000 tokens (full adjacency list)
- Scoped directive: ~50-200 tokens (just the affected subgraph)

When the token budget is tight:
- Phase 7 (compaction) compresses the graph to hub/leaf counts + the scoped
  directive only
- Phase 8 (caveman) compresses to `SCOPE: [file list] | BLAST: [count] |
  TESTS: [file list]`

## Output

After graph-scope runs, the progress file contains:
- The scoped file list (context scope)
- The blast radius (forward traversal)
- The test files in scope
- The scope mode used
- The reduction percentage (files scoped vs total)
