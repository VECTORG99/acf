# Context Compaction — Research and Design

This document captures the research behind ACF's context compaction (phase 7)
and caveman mode (phase 8), including the sources studied, the techniques
adapted, and the design decisions made.

## Research Sources

ACF's compaction system is inspired by Kimi CLI's open-source compaction
system, developed by MoonshotAI. The following sources were studied:

### 1. Kimi CLI — compaction.py
- Repository: [MoonshotAI/kimi-cli](https://github.com/MoonshotAI/kimi-cli)
- File: `src/kimi_cli/soul/compaction.py`
- Key contribution: the `Compaction` protocol, `SimpleCompaction` implementation,
  and `should_auto_compact` trigger logic

### 2. Kimi CLI — compact.md prompt
- File: `src/kimi_cli/prompts/compact.md`
- Key contribution: compression priorities (Current Task State, Errors &
  Solutions, Code Evolution, System Context, Design Decisions, TODO Items) and
  XML-tagged output structure (`<current_focus>`, `<environment>`,
  `<completed_tasks>`, `<active_issues>`, `<code_state>`, `<important_context>`)

### 3. Kimi Code — first-person handoff rework (PR #1214)
- Commit: [86e0c92](https://github.com/MoonshotAI/kimi-code/commit/86e0c9201ed58c7c1ce5543b1dfb47a4cf5117f6)
- Key contribution: rewriting the compaction summary as the agent's own
  continuing notes (first-person), not a third-party report. Preserves exact
  commands, paths, and outcomes; states the precise next action; flags
  claimed-but-unverified work.

### 4. Kimi Code — head+tail preservation (PR #1313)
- Commit: [329846c](https://github.com/MoonshotAI/kimi-code/commit/329846c569c0d1c449721958251425f59247b9e1)
- Key contribution: keeping the oldest 2k tokens and the most recent 18k tokens
  of user messages, with an elision marker between them. The original task
  statement no longer vanishes in long sessions.

### 5. Kimi CLI — custom /compact instructions (PR #1300)
- PR: [feat(compaction): support custom /compact instructions](https://github.com/MoonshotAI/kimi-cli/pull/1300)
- Key contribution: `/compact keep db discussions` — the user can tell the
  model what to prioritize when compressing. ACF adapts this as
  `"compact context — keep the stack-audit findings"`.

### 6. Kimi Code CLI Docs — Context compression
- URL: [https://moonshotai.github.io/kimi-code/en/guides/sessions.html](https://moonshotai.github.io/kimi-code/en/guides/sessions.html)
- Key contribution: user-facing documentation of auto-compaction and manual
  `/compact` command

### 7. DeepWiki — Context Compaction
- URL: [https://deepwiki.com/MoonshotAI/kimi-cli/7.3-context-compaction](https://deepwiki.com/MoonshotAI/kimi-cli/7.3-context-compaction)
- Key contribution: architectural overview of the compaction system, including
  the `Compaction` protocol, `SimpleCompaction` strategy, and token estimation
  heuristics

## Techniques Adapted for ACF

### Tail-preservation

**Kimi's approach**: `SimpleCompaction` splits messages into `to_compact`
(older, summarized) and `to_preserve` (recent, verbatim). Default
`max_preserved_messages = 2`.

**ACF's adaptation**: the most recent phase output (e.g., the last stack-audit
findings or the current issue draft) is preserved verbatim. Older phase outputs
(e.g., the full context-load snapshot) are compacted into a summary.

### Priority-based compression

**Kimi's approach**: the `compact.md` prompt defines compression priorities in
order: Current Task State, Errors & Solutions, Code Evolution, System Context,
Design Decisions, TODO Items. Rules: MUST KEEP errors/working solutions,
MERGE similar discussions, REMOVE redundant explanations, CONDENSE long code
blocks.

**ACF's adaptation**: ACF applies the same priorities to the SDLC context:
1. Current issue/PR draft — preserve verbatim
2. Stack-audit findings — preserve orphan PRs, close gaps, escaped issues
3. Test commands and CI checks — preserve exact command strings
4. Architecture facts — compress to one-line summaries
5. Conventions — compress to label names only
6. Completed phases — compress to one-line outcomes

### XML-tagged output structure

**Kimi's approach**: the compaction output uses XML-like tags:
`<current_focus>`, `<environment>`, `<completed_tasks>`, `<active_issues>`,
`<code_state>`, `<important_context>`.

**ACF's adaptation**: ACF uses SDLC-specific tags:
`<current_focus>`, `<stack>`, `<tests>`, `<ci>`, `<architecture>`,
`<conventions>`, `<completed_phases>`.

### First-person handoff

**Kimi's approach** (from PR #1214): the compaction summary is written as the
agent's own continuing notes. It preserves exact commands, paths, and outcomes;
states the precise next action; flags claimed-but-unverified work rather than
trusting it. The summary prefix uses a skeptical "your own working notes"
framing.

**ACF's adaptation**: after compaction, the progress file reads as the agent's
own working notes:

```markdown
## Compacted Handoff

I was working on [issue/PR title]. The context snapshot is compacted.

What I know:
- Stack has [N] orphan PRs, [M] stale issues
- Test command: [exact command] — [N] tests pass
- CI check: [check name] must pass

What I need to do next:
- [precise next action]

What I have NOT verified yet:
- [anything claimed but not confirmed]
```

### Auto-trigger threshold

**Kimi's approach**: `should_auto_compact` triggers when either:
- `token_count >= max_context_size * trigger_ratio` (default 0.85)
- `token_count + reserved_context_size >= max_context_size`

**ACF's adaptation**: same logic, but with ACF-specific defaults:
- `max_context_size`: 8000 tokens (ACF context is already compressed)
- `trigger_ratio`: 0.75 (compact earlier than Kimi's 0.85)
- `reserved_context_size`: 2000 tokens (space for the next phase's output)

### Manual trigger with custom instruction

**Kimi's approach**: `/compact keep db discussions` — the user provides a hint
that is appended to the compaction prompt, telling the model what to prioritize.

**ACF's adaptation**: `"compact context — keep the stack-audit findings"` —
the custom instruction is appended to the compaction prompt in the same way.

### Token estimation

**Kimi's approach**: `estimate_text_tokens()` calculates `total_chars // 4`
(approx. 4 chars per token for English).

**ACF's adaptation**: same heuristic for English content. For Spanish content,
use `chars // 3.5` (Spanish has more characters per token due to accents and
longer words).

## Caveman Mode — Original to ACF

Caveman mode (phase 8) is NOT from Kimi. It is original to ACF, taking Kimi's
compression rules to their logical extreme.

### Design rationale

Kimi's compaction targets ~800 tokens (from ~2000). But some models have very
small context windows (<8K tokens), and some users run on budget-constrained
APIs where every token costs money. Caveman mode targets <500 tokens, with a
"bare caveman" last resort at ~100 tokens.

### Caveman principles

1. **No prose** — every word must earn its place
2. **Paths, not descriptions** — `AGENTS.md` not "the agent directives file"
3. **Counts, not lists** — `26 services` not 26 service names
4. **Labels, not sentences** — `priority:P1` not "this is high priority"
5. **Commands, not explanations** — `lune run scripts/test_core.luau` not
   "run the core test suite"
6. **Symbols over words** — `→`, `|`, `#N`

### What caveman loses

- Architecture context — only a one-line stack summary
- Convention details — only label names, no rules
- Library opportunities — reduced to a count
- Stale issue titles — reduced to issue numbers
- Template structure — not included at all

If any of these are critical, use compaction (phase 7) instead.

### Bare caveman (last resort)

When even the caveman snapshot is too large:

```
NOW:<issue/PR 1line>
NEXT:<action 1line>
TEST:<cmd> → <N>pass
CI:<check>@<wf>
```

~100 tokens. Loses all stack context but preserves the ability to craft an
issue or PR with the right test command and CI check.

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
Bare caveman (~100 tokens)
```

## Design Decisions

### Why adapt Kimi instead of building from scratch?

Kimi CLI's compaction system is open-source, well-documented, and battle-tested
in production. Adapting it gives ACF a solid foundation without reinventing the
wheel. The four key techniques (tail-preservation, priority-based compression,
XML-tagged output, first-person handoff) are directly applicable to the SDLC
context that ACF manages.

### Why a separate caveman mode instead of more aggressive compaction?

Compaction is lossy but structured — it preserves the shape of the data in
XML tags. Caveman is lossy and unstructured — it reduces everything to bare
marks. They serve different needs:
- Compaction: "I have too much context but I still need structure"
- Caveman: "I have almost no context budget, give me the bare minimum"

Making caveman a separate phase (not just "more aggressive compaction") keeps
the two modes cleanly separated and lets the user choose explicitly.

### Why trigger_ratio 0.75 instead of Kimi's 0.85?

ACF's context is already compressed (paths, labels, counts). The full snapshot
starts at ~2000 tokens, not ~200K tokens like a raw conversation. Compacting
at 0.85 would leave very little headroom for the next phase. 0.75 gives more
buffer.

### Why not keep the original full snapshot after compaction?

Compaction is lossy by design. Keeping the original would double the token
cost. If the full snapshot is needed, re-run context-load (it's cheap — just
reading MDs and building a path index).

## Future Work

- **Head+tail preservation for ACF**: adapt Kimi Code's PR #1313 to keep the
  original task statement (head) and recent phase outputs (tail) verbatim,
  with an elision marker between them
- **Compaction metrics**: track token savings per phase, per project
- **Caveman auto-detection**: detect the model's context window size and
  auto-select between full, compacted, and caveman modes
- **Cross-project compaction**: compact context across multiple projects in a
  monorepo or org
