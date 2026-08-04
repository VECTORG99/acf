## Summary
[1-2 sentences: what is broken or missing]

## Context
- Architecture: [path to architecture doc]
- Related: #[issue numbers from stack-audit, if any]

## Affected Files (best guess)
- `path/to/likely/file1`
- `path/to/likely/file2`

## Acceptance Criteria
- [ ] [Specific, verifiable behavior — reference file:function]
- [ ] [Test added in `path/to/test_file` reproducing/verifying the change]
- [ ] [N tests pass — `exact test command from context-load`]
- [ ] [CI check name passes — e.g., "test (lune)"]
- [ ] [Convention rule from AGENTS.md — e.g., "--!strict in all new files"]

## Validation
[Exact command to verify, e.g., `bash scripts/dev.sh --test`]

## Complexity
Simple | Medium | Complex
- **Simple**: 1 file, <50 lines, obvious fix
- **Medium**: 2-3 files, <200 lines, clear scope
- **Complex**: >3 files or architectural decision — consider decomposition

<!--
Labels to apply (see skills/06-label-metadata/SKILL.md for the canonical taxonomy):
- type: bug | enhancement | documentation | refactor | chore | test | security
- priority: priority:P0 | priority:P1 | priority:P2 | priority:P3
- area: area:backend | area:frontend | area:ci | area:docs | area:security | area:devops
- status: ready-to-implement | needs-human | blocked
- enhancement: library-review | batch-delivery (>2 AC, needs decomposition)

If this issue has a library suggestion:
- Create a separate issue with label: library-review, enhancement
- Reference it here: Related: #NN (library review)
-->
