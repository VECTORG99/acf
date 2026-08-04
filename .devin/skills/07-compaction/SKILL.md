---
name: compaction
description: >-
  Phase 7 of ACF. Compacts the context snapshot and progress file using
  techniques inspired by Kimi CLI's compaction system (tail-preservation,
  priority-based compression, XML-tagged output, first-person handoff).
  Use when ACF detects the context snapshot is growing too large, when the
  user asks to "compact context", "compress the snapshot", or "save tokens",
  or when the progress file exceeds a token budget threshold.
---

# Compaction

Reduces the context snapshot and progress file to a fraction of their
original size while preserving the information that matters for issue-craft
and pr-context. Inspired by Kimi CLI's open-source compaction system
([MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli)).

## When to Trigger

- The progress file (`.slim/acf/<slug>.md`) exceeds ~2000 tokens (~8000 chars)
- The context snapshot has more than 5 sections with more than 5 bullets each
- The user explicitly asks to compact or compress context
- Before passing context to a model with a small context window
- Between phases when the snapshot has accumulated stack-audit findings

## Kimi's Compaction Techniques (adapted for ACF)

ACF borrows four key techniques from Kimi's compaction system:

### 1. Tail-Preservation

Kimi's `SimpleCompaction` splits messages into two pools:
- **to_compact**: older messages, summarized into a single block
- **to_preserve**: the most recent turns, kept verbatim

ACF adapts this: the most recent phase output (e.g., the last stack-audit
findings or the current issue draft) is preserved verbatim. Older phase
outputs (e.g., the full context-load snapshot) are compacted into a summary.

### 2. Priority-Based Compression

Kimi's `compact.md` prompt defines compression priorities in order:
1. Current Task State (what is being worked on RIGHT NOW)
2. Errors and Solutions (all encountered errors and their resolutions)
3. Code Evolution (final working versions only, remove intermediate attempts)
4. System Context (project structure, dependencies, environment setup)
5. Design Decisions (architectural choices and their rationale)
6. TODO Items (unfinished tasks and known issues)

ACF applies the same priorities to the SDLC context:
1. **Current issue/PR draft** — preserve verbatim
2. **Stack-audit findings** — preserve orphan PRs, close gaps, escaped issues
3. **Test commands and CI checks** — preserve exact command strings
4. **Architecture facts** — compress to one-line summaries
5. **Conventions** — compress to label names only
6. **Completed phases** — compress to one-line outcomes

### 3. XML-Tagged Output Structure

Kimi's compaction output uses XML-like tags for structured retrieval:
`<current_focus>`, `<environment>`, `<completed_tasks>`, `<active_issues>`,
`<code_state>`, `<important_context>`.

ACF uses the same pattern for the compacted snapshot:

```xml
<current_focus>
[The issue or PR currently being crafted — 1-2 lines]
</current_focus>

<stack>
- Open PRs: [count] | Orphan: [count] | Stale issues: [count]
- Close gaps: [list PR#→Issue# or "none"]
- Escaped issues: [list or "none"]
- Library opportunities: [list or "none"]
</stack>

<tests>
- [exact test command 1] ([N] tests)
- [exact test command 2] ([N] tests)
- Coverage: [command or "none"]
</tests>

<ci>
- [check name 1] (from [workflow file])
- [check name 2] (from [workflow file])
</ci>

<architecture>
- Stack: [one line]
- Key dirs: [paths only]
- Architecture doc: [path or "none"]
</architecture>

<conventions>
- Labels: [type + priority + area required]
- Commit: [conventional commits]
- Branch: [prefix rules]
</conventions>

<completed_phases>
- context-load: [done — snapshot built]
- stack-audit: [done — N findings]
- issue-craft: [in progress — draft at /tmp/issue-body.md]
</completed_phases>
```

### 4. First-Person Handoff

Kimi-Code's compaction rework writes the summary as the agent's own
continuing notes (first-person), not a third-party report. The summary:
- Preserves exact commands, paths, and outcomes
- States the precise next action
- Flags claimed-but-unverified work rather than trusting it

ACF applies this to the progress file. After compaction, the progress file
reads as the agent's own working notes:

```markdown
## Compacted Handoff

I was working on [issue/PR title]. The context snapshot is compacted.

What I know:
- Stack has [N] orphan PRs, [M] stale issues
- Test command: [exact command] — [N] tests pass
- CI check: [check name] must pass

What I need to do next:
- [precise next action, e.g., "run gh issue create with the draft at /tmp/issue-body.md"]

What I have NOT verified yet:
- [anything claimed but not confirmed, e.g., "CI check names are guessed — verify against .github/workflows/"]
```

## Compaction Rules

1. **MUST KEEP**: exact test commands, CI check names, issue/PR numbers, label
   names, orphan PR numbers, close-gap pairs
2. **MERGE**: similar findings into single lines (e.g., "3 stale issues" not
   listing all three)
3. **REMOVE**: full file contents (replace with paths), verbose architecture
   descriptions (replace with one-line summaries), intermediate drafts
4. **CONDENSE**: long command lists into counts + the most critical command
5. **PRESERVE RECENT**: the current phase's output is never compacted
6. **FIRST-PERSON**: the handoff note is written as the agent's own notes

## Auto-Trigger Threshold

Following Kimi's `should_auto_compact` logic:

```
trigger_compaction = (
    token_count >= max_context_size * trigger_ratio  # default 0.85
    or token_count + reserved_context_size >= max_context_size
)
```

For ACF, the defaults are:
- `max_context_size`: 8000 tokens (configurable per project)
- `trigger_ratio`: 0.75 (compact earlier than Kimi's 0.85, since ACF context
  is already compressed)
- `reserved_context_size`: 2000 tokens (space for the next phase's output)

## Manual Trigger

The user can trigger compaction at any time with a custom instruction:

```
"compact context — keep the stack-audit findings"
"compress the snapshot — prioritize test commands"
```

The custom instruction is appended to the compaction prompt, telling the
model what to prioritize (same as Kimi's `/compact keep db discussions`).

## Token Estimation

Following Kimi's heuristic: `tokens ≈ chars // 4` (approx. 4 chars per token
for English). For Spanish content, use `chars // 3.5` (Spanish has more
characters per token due to accents and longer words).

## Output

The compacted snapshot replaces the full snapshot in the progress file. The
original full snapshot is NOT kept — compaction is lossy by design. If the
full snapshot is needed, re-run context-load.

## Relationship to Caveman Mode

Compaction is the standard compression mode. Caveman (phase 8) is the
extreme compression mode for when even the compacted snapshot is too large.
See `skills/08-caveman/SKILL.md`.

## Sources

- [MoonshotAI/kimi-cli — compaction.py](https://github.com/MoonshotAI/kimi-cli/blob/main/src/kimi_cli/soul/compaction.py)
- [MoonshotAI/kimi-cli — compact.md prompt](https://github.com/MoonshotAI/kimi-cli/blob/main/src/kimi_cli/prompts/compact.md)
- [MoonshotAI/kimi-code — first-person handoff rework (PR #1214)](https://github.com/MoonshotAI/kimi-code/commit/86e0c9201ed58c7c1ce5543b1dfb47a4cf5117f6)
- [MoonshotAI/kimi-code — head+tail preservation (PR #1313)](https://github.com/MoonshotAI/kimi-code/commit/329846c569c0d1c449721958251425f59247b9e1)
- [Kimi Code CLI Docs — Context compression](https://moonshotai.github.io/kimi-code/en/guides/sessions.html)
