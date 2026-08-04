#!/usr/bin/env bash
# =============================================================================
# ACF — Installer Test Suite
# =============================================================================
# Tests the install.sh script across all supported agents, modes, and error
# cases. Exits 0 if all tests pass, 1 if any fail.
#
# Usage:
#   bash scripts/test-install.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL="${REPO_ROOT}/install.sh"

PASS=0
FAIL=0
FAILED_TESTS=()

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

ok() {
  printf "  PASS  %s\n" "$1"
  PASS=$((PASS + 1))
}

fail() {
  printf "  FAIL  %s\n" "$1"
  if [[ -n "${2:-}" ]]; then
    printf "        %s\n" "$2"
  fi
  FAIL=$((FAIL + 1))
  FAILED_TESTS+=("$1")
}

# Create a temp dir and echo its path. Caller must clean up.
mktmp() {
  mktemp -d "/tmp/acf-test-XXXXXX"
}

# Check that a file exists inside a target dir.
assert_file_exists() {
  local dir="$1" rel="$2"
  if [[ -f "${dir}/${rel}" ]]; then
    return 0
  else
    return 1
  fi
}

# Check that a directory exists.
assert_dir_exists() {
  local dir="$1" rel="$2"
  if [[ -d "${dir}/${rel}" ]]; then
    return 0
  else
    return 1
  fi
}

# Count SKILL.md files under a directory.
count_skills() {
  find "$1" -name "SKILL.md" -type f | wc -l
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

echo "ACF installer test suite"
echo "Repo: ${REPO_ROOT}"
echo ""

# --- Test 1: --all installs to all 6 agents ---
echo "Test 1: --all installs to all 6 agents"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  all_ok=1
  for agent_dir in .devin/skills .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
    if ! assert_dir_exists "$tmp" "$agent_dir"; then
      fail "agent dir missing: $agent_dir" "directory not created"
      all_ok=0
      break
    fi
    # Should have 9 SKILL.md files (acf + 8 sub-skills)
    n=$(count_skills "${tmp}/${agent_dir}")
    if [[ "$n" -ne 9 ]]; then
      fail "agent dir $agent_dir has $n skills (expected 9)"
      all_ok=0
      break
    fi
  done
  if [[ $all_ok -eq 1 ]]; then
    ok "--all created 6 agent dirs with 9 skills each"
  fi
else
  fail "--all exited non-zero"
fi
rm -rf "$tmp"

# --- Test 2: --agent devin installs only to devin ---
echo "Test 2: --agent devin installs only to devin"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent devin >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  if assert_dir_exists "$tmp" ".devin/skills" && \
     [[ $(count_skills "${tmp}/.devin/skills") -eq 9 ]]; then
    # Verify other agents were NOT created
    if [[ ! -d "${tmp}/.claude/skills" ]] && \
       [[ ! -d "${tmp}/.cursor/skills" ]] && \
       [[ ! -d "${tmp}/.codex/skills" ]]; then
      ok "--agent devin installed only to .devin/skills/"
    else
      fail "--agent devin created extra agent dirs"
    fi
  else
    fail "--agent devin did not install 9 skills to .devin/skills/"
  fi
else
  fail "--agent devin exited non-zero"
fi
rm -rf "$tmp"

# --- Test 3: --agent with invalid name fails ---
echo "Test 3: --agent with invalid name fails"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent foobar >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  ok "--agent foobar correctly failed"
else
  fail "--agent foobar should have failed but succeeded"
fi
rm -rf "$tmp"

# --- Test 4: no args prints usage and exits 1 ---
echo "Test 4: no args prints usage and exits 1"
bash "$INSTALL" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  ok "no args correctly failed"
else
  fail "no args should have failed"
fi

# --- Test 5: nonexistent target fails ---
echo "Test 5: nonexistent target fails"
bash "$INSTALL" /nonexistent/path/xyz >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  ok "nonexistent target correctly failed"
else
  fail "nonexistent target should have failed"
fi

# --- Test 6: auto-detect installs to existing dirs only ---
echo "Test 6: auto-detect installs to existing dirs only"
tmp=$(mktmp)
mkdir -p "${tmp}/.claude/skills" "${tmp}/.codex/skills"
bash "$INSTALL" "$tmp" >/dev/null 2>&1
if [[ $? -eq 0 ]]; then
  if assert_dir_exists "$tmp" ".claude/skills" && \
     assert_dir_exists "$tmp" ".codex/skills" && \
     [[ $(count_skills "${tmp}/.claude/skills") -eq 9 ]] && \
     [[ $(count_skills "${tmp}/.codex/skills") -eq 9 ]] && \
     [[ ! -d "${tmp}/.devin/skills" ]]; then
    ok "auto-detect installed to .claude and .codex only"
  else
    fail "auto-detect installed to wrong dirs"
  fi
else
  fail "auto-detect exited non-zero"
fi
rm -rf "$tmp"

# --- Test 7: auto-detect with no agent dirs fails with helpful message ---
echo "Test 7: auto-detect with no agent dirs fails"
tmp=$(mktmp)
output=$(bash "$INSTALL" "$tmp" 2>&1)
exit_code=$?
if [[ $exit_code -ne 0 ]] && echo "$output" | grep -q "No agent skill directories"; then
  ok "auto-detect with no dirs failed with helpful message"
else
  fail "auto-detect with no dirs should fail with message (exit=$exit_code)"
fi
rm -rf "$tmp"

# --- Test 8: idempotent re-run ---
echo "Test 8: idempotent re-run"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent claude >/dev/null 2>&1
n1=$(count_skills "${tmp}/.claude/skills")
bash "$INSTALL" "$tmp" --agent claude >/dev/null 2>&1
n2=$(count_skills "${tmp}/.claude/skills")
if [[ "$n1" -eq 9 ]] && [[ "$n2" -eq 9 ]]; then
  ok "idempotent: $n1 → $n2 skills after re-run"
else
  fail "idempotent failed: $n1 → $n2 skills"
fi
rm -rf "$tmp"

# --- Test 9: installed skills pass validation ---
echo "Test 9: installed skills pass validation"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
# Run validate-skills.sh against the installed dir
all_valid=1
for agent_dir in .devin/skills .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  for skill_md in "${tmp}/${agent_dir}"/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    # Check frontmatter
    if ! head -1 "$skill_md" | grep -q '^---$'; then
      fail "installed skill missing frontmatter: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    # Check name field
    fm=$(awk 'NR==1{next} /^---$/{exit} {print}' "$skill_md")
    if ! echo "$fm" | grep -qE '^name:'; then
      fail "installed skill missing name: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    if ! echo "$fm" | grep -qE '^description:'; then
      fail "installed skill missing description: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
  done
done
if [[ $all_valid -eq 1 ]]; then
  ok "all installed skills have valid frontmatter"
fi
rm -rf "$tmp"

# --- Test 10: --agent with no value fails ---
echo "Test 10: --agent with no value fails"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  ok "--agent without value correctly failed"
else
  fail "--agent without value should have failed"
fi
rm -rf "$tmp"

# --- Test 11: orchestrator (acf/) is installed alongside sub-skills ---
echo "Test 11: orchestrator acf/ is installed"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent claude >/dev/null 2>&1
if assert_file_exists "$tmp" ".claude/skills/acf/SKILL.md"; then
  ok "orchestrator acf/SKILL.md installed"
else
  fail "orchestrator acf/SKILL.md not installed"
fi
rm -rf "$tmp"

# --- Test 12: all 8 sub-skills are installed ---
echo "Test 12: all 8 sub-skills installed"
tmp=$(mktmp)
bash "$INSTALL" "$tmp" --agent claude >/dev/null 2>&1
all_subs=1
for sub in 01-context-load 02-stack-audit 03-issue-craft 04-pr-context 05-frontend-preview 06-label-metadata 07-compaction 08-caveman; do
  if ! assert_file_exists "$tmp" ".claude/skills/${sub}/SKILL.md"; then
    fail "sub-skill missing: ${sub}/SKILL.md"
    all_subs=0
    break
  fi
done
if [[ $all_subs -eq 1 ]]; then
  ok "all 8 sub-skills installed"
fi
rm -rf "$tmp"

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed (of $((PASS + FAIL)) tests)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failed tests:"
  for t in "${FAILED_TESTS[@]}"; do
    echo "  - $t"
  done
  exit 1
fi

exit 0
