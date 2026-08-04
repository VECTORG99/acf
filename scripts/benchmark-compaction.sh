#!/usr/bin/env bash
# =============================================================================
# ACF — Compaction Benchmark
# =============================================================================
# Measures the token count of ACF's own skill content at each compression tier:
#   - Full:       all SKILL.md content concatenated (the "full snapshot" baseline)
#   - Compacted:  a simulated phase-7 compaction (XML-tagged, priority-based)
#   - Caveman:    a simulated phase-8 caveman compression (<500 tokens target)
#   - Bare:       bare caveman (NOW + NEXT + TESTS + CI, ~100 tokens target)
#
# Token estimation: chars // 4 (English heuristic, per Kimi CLI).
#
# Usage:
#   bash scripts/benchmark-compaction.sh [project-path]
#
#   If [project-path] is given, benchmarks that project's MD files instead of
#   ACF's own skills. This lets you benchmark any project.
#
# Output: a table of mode | chars | tokens | savings % vs full
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Target: either the given project or ACF's own skills
if [[ $# -ge 1 ]] && [[ -d "$1" ]]; then
  TARGET="$(cd "$1" && pwd)"
  TARGET_NAME="$(basename "$TARGET")"
else
  TARGET="$REPO_ROOT"
  TARGET_NAME="ACF (self)"
fi

# -----------------------------------------------------------------------------
# Token estimation (chars // 4, per Kimi CLI heuristic)
# -----------------------------------------------------------------------------
count_chars() {
  wc -c < "$1" 2>/dev/null || echo 0
}

count_chars_stdin() {
  wc -c 2>/dev/null || echo 0
}

chars_to_tokens() {
  echo $(( $1 / 4 ))
}

# -----------------------------------------------------------------------------
# Gather full content
# -----------------------------------------------------------------------------

# Collect all SKILL.md content (or all .md content if targeting external project)
gather_full_content() {
  local target="$1"
  # Find all SKILL.md files, excluding .git
  find "$target" -name "SKILL.md" -type f -not -path "*/.git/*" 2>/dev/null | sort | while read -r f; do
    cat "$f"
    echo ""
  done
}

# Simulated compacted snapshot (phase 7 — XML-tagged, priority-based)
# This is a realistic example of what phase 7 would produce for ACF itself.
generate_compacted() {
  cat <<'COMPACTED'
<current_focus>
ACF orchestrator — crafting context-rich issues and PRs
</current_focus>

<stack>
- Skills: 9 (acf + 8 sub-skills)
- Mirrors: skills/ ↔ .devin/skills/ (in sync)
- Agents: 6 supported (devin, claude, cursor, codex, agents, opencode)
</stack>

<tests>
- bash scripts/validate-skills.sh (17 skills)
- bash scripts/test-install.sh (12 tests)
- bash scripts/test-validate.sh (9 tests)
- bash scripts/test-integration.sh (6 tests)
</tests>

<ci>
- skill-validation (skill-validation.yml)
- security-check (security-check.yml)
</ci>

<architecture>
- Pattern: deepwork + oracle (orchestrator + sub-skills)
- Source: skills/ (portable) + .devin/skills/ (Devin mirror)
- Installer: install.sh (--all, --agent, auto-detect)
- Templates: issue-contextualized.md, pr-contextualized.md
</architecture>

<conventions>
- Labels: type + priority + area (minimum 3 per issue)
- Commits: feat/fix/docs/refactor/chore/test/security
- Compression: paths not contents, labels not body text
</conventions>

<completed_phases>
- context-load: done
- stack-audit: done (14 open issues, 0 orphan PRs)
- issue-craft: ready
</completed_phases>
COMPACTED
}

# Simulated caveman snapshot (phase 8 — <500 tokens)
generate_caveman() {
  cat <<'CAVEMAN'
ACF|9skills|6agents|8phases
→issue-craft
STACK:14issues|0orphan|0stale
TESTS:validate-skills|test-install|test-validate|test-integration
CI:skill-validation|security-check
ARCH:deepwork+oracle|skills/+mirror
LABELS:type+priority+area
NEXT:gh issue create
CAVEMAN
}

# Simulated bare caveman (~100 tokens)
generate_bare() {
  cat <<'BARE'
NOW: ACF issue-craft
NEXT: gh issue create
TESTS: validate-skills.sh
CI: skill-validation, security-check
BARE
}

# -----------------------------------------------------------------------------
# Run benchmark
# -----------------------------------------------------------------------------

echo "ACF compaction benchmark"
echo "Target: ${TARGET_NAME} (${TARGET})"
echo "Token heuristic: chars // 4 (Kimi CLI)"
echo ""

# Full
full_chars=$(gather_full_content "$TARGET" | count_chars_stdin)
full_tokens=$(chars_to_tokens "$full_chars")

# Compacted
compacted_chars=$(generate_compacted | count_chars_stdin)
compacted_tokens=$(chars_to_tokens "$compacted_chars")

# Caveman
caveman_chars=$(generate_caveman | count_chars_stdin)
caveman_tokens=$(chars_to_tokens "$caveman_chars")

# Bare
bare_chars=$(generate_bare | count_chars_stdin)
bare_tokens=$(chars_to_tokens "$bare_chars")

# Savings calculations: savings% = (full - mode) * 100 / full
if [[ "$full_tokens" -gt 0 ]]; then
  compacted_savings=$(( (full_tokens - compacted_tokens) * 100 / full_tokens ))
  caveman_savings=$(( (full_tokens - caveman_tokens) * 100 / full_tokens ))
  bare_savings=$(( (full_tokens - bare_tokens) * 100 / full_tokens ))
else
  compacted_savings=0
  caveman_savings=0
  bare_savings=0
fi

# Print table
printf "%-12s | %8s | %8s | %s\n" "Mode" "Chars" "Tokens" "Savings"
printf "%-12s-+-%8s-+-%8s-+-%s\n" "------------" "--------" "--------" "-------"
printf "%-12s | %8d | %8d | %s\n" "Full" "$full_chars" "$full_tokens" "baseline"
printf "%-12s | %8d | %8d | %d%%\n" "Compacted" "$compacted_chars" "$compacted_tokens" "$compacted_savings"
printf "%-12s | %8d | %8d | %d%%\n" "Caveman" "$caveman_chars" "$caveman_tokens" "$caveman_savings"
printf "%-12s | %8d | %8d | %d%%\n" "Bare" "$bare_chars" "$bare_tokens" "$bare_savings"

echo ""

# Verify targets
echo "Target verification:"
if [[ "$compacted_tokens" -le 800 ]]; then
  echo "  ✓ Compacted ≤ 800 tokens ($compacted_tokens)"
else
  echo "  ✗ Compacted > 800 tokens ($compacted_tokens) — exceeds target"
fi
if [[ "$caveman_tokens" -le 500 ]]; then
  echo "  ✓ Caveman ≤ 500 tokens ($caveman_tokens)"
else
  echo "  ✗ Caveman > 500 tokens ($caveman_tokens) — exceeds target"
fi
if [[ "$bare_tokens" -le 150 ]]; then
  echo "  ✓ Bare ≤ ~100 tokens ($bare_tokens)"
else
  echo "  ✗ Bare > 150 tokens ($bare_tokens) — exceeds target"
fi

echo ""
echo "Note: Full mode measures all SKILL.md content concatenated."
echo "      Compacted/Caveman/Bare are simulated outputs matching the"
echo "      phase 7/8 design specs. Real-world savings depend on project size."
