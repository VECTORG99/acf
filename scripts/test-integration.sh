#!/usr/bin/env bash
# =============================================================================
# ACF — Integration Test Suite
# =============================================================================
# End-to-end tests: install ACF into a temp project, then validate that every
# installed skill passes the spec validator. Also tests that the installed
# skills are byte-identical to the source (no corruption during copy).
#
# Usage:
#   bash scripts/test-integration.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INSTALL="${REPO_ROOT}/install.sh"
VALIDATE="${REPO_ROOT}/scripts/validate-skills.sh"

PASS=0
FAIL=0
FAILED_TESTS=()

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

echo "ACF integration test suite"
echo "Repo: ${REPO_ROOT}"
echo ""

# --- Test 1: install --all, then validate installed skills ---
echo "Test 1: install --all → validate installed skills"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
  fail "install --all failed"
  rm -rf "$tmp"
  exit 1
fi

# Validate each installed skill has proper frontmatter
all_valid=1
for agent_dir in .devin/skills .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  for skill_md in "${tmp}/${agent_dir}"/*/SKILL.md; do
    [[ -f "$skill_md" ]] || continue
    # Check opening ---
    if ! head -1 "$skill_md" | grep -q '^---[[:space:]]*$'; then
      fail "missing opening ---: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    # Check closing ---
    if ! awk 'NR>1 && /^---[[:space:]]*$/ {found=1; exit} END {exit !found}' "$skill_md"; then
      fail "missing closing ---: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    # Check name field
    fm=$(awk 'NR==1{next} /^---[[:space:]]*$/{exit} {print}' "$skill_md")
    if ! echo "$fm" | grep -qE '^name:'; then
      fail "missing name: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    # Check description field
    if ! echo "$fm" | grep -qE '^description:'; then
      fail "missing description: ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
    # Check body under 500 lines
    body_lines=$(awk '
      BEGIN { seen_open=0; seen_close=0; body=0 }
      /^---[[:space:]]*$/ {
        if (!seen_open) { seen_open=1; next }
        else if (!seen_close) { seen_close=1; body=1; next }
      }
      body { count++ }
      END { print count + 0 }
    ' "$skill_md")
    if [[ $body_lines -ge 500 ]]; then
      fail "body too long (${body_lines}): ${skill_md#${tmp}/}"
      all_valid=0
      break 2
    fi
  done
done
if [[ $all_valid -eq 1 ]]; then
  ok "all installed skills across 6 agents pass spec validation"
fi
rm -rf "$tmp"

# --- Test 2: installed skills are byte-identical to source ---
echo "Test 2: installed skills are byte-identical to source"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
bash "$INSTALL" "$tmp" --agent devin >/dev/null 2>&1
all_identical=1
# Check orchestrator
if ! diff -q "${REPO_ROOT}/.devin/skills/acf/SKILL.md" "${tmp}/.devin/skills/acf/SKILL.md" >/dev/null 2>&1; then
  fail "orchestrator acf/SKILL.md differs after install"
  all_identical=0
fi
# Check sub-skills
for sub in 01-context-load 02-stack-audit 03-issue-craft 04-pr-context 05-frontend-preview 06-label-metadata 07-compaction 08-caveman; do
  if ! diff -q "${REPO_ROOT}/skills/${sub}/SKILL.md" "${tmp}/.devin/skills/${sub}/SKILL.md" >/dev/null 2>&1; then
    fail "sub-skill ${sub}/SKILL.md differs after install"
    all_identical=0
    break
  fi
done
if [[ $all_identical -eq 1 ]]; then
  ok "all installed skills are byte-identical to source"
fi
rm -rf "$tmp"

# --- Test 3: install into a project with existing skills preserves them ---
echo "Test 3: install preserves existing skills in target"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
mkdir -p "${tmp}/.claude/skills/existing-skill"
cat > "${tmp}/.claude/skills/existing-skill/SKILL.md" <<'EXISTING'
---
name: existing-skill
description: A pre-existing skill that should not be deleted.
---
# Existing Skill
This should survive the ACF install.
EXISTING
bash "$INSTALL" "$tmp" --agent claude >/dev/null 2>&1
if [[ -f "${tmp}/.claude/skills/existing-skill/SKILL.md" ]]; then
  # Also verify ACF skills were added
  if [[ -f "${tmp}/.claude/skills/acf/SKILL.md" ]]; then
    ok "existing skill preserved, ACF skills added"
  else
    fail "ACF skills not added but existing preserved"
  fi
else
  fail "existing skill was deleted by install"
fi
rm -rf "$tmp"

# --- Test 4: all 6 agents get the same content ---
echo "Test 4: all 6 agents get identical content"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
all_same=1
# Compare acf/SKILL.md across all agents
ref="${tmp}/.devin/skills/acf/SKILL.md"
for agent_dir in .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  if ! diff -q "$ref" "${tmp}/${agent_dir}/acf/SKILL.md" >/dev/null 2>&1; then
    fail "acf/SKILL.md differs in ${agent_dir}"
    all_same=0
    break
  fi
done
# Compare a sub-skill across all agents
ref_sub="${tmp}/.devin/skills/07-compaction/SKILL.md"
for agent_dir in .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  if ! diff -q "$ref_sub" "${tmp}/${agent_dir}/07-compaction/SKILL.md" >/dev/null 2>&1; then
    fail "07-compaction/SKILL.md differs in ${agent_dir}"
    all_same=0
    break
  fi
done
if [[ $all_same -eq 1 ]]; then
  ok "all 6 agents received identical skill content"
fi
rm -rf "$tmp"

# --- Test 5: skill count is consistent (9 per agent) ---
echo "Test 5: skill count is 9 per agent (1 orchestrator + 8 sub-skills)"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
all_count_ok=1
for agent_dir in .devin/skills .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  n=$(find "${tmp}/${agent_dir}" -name "SKILL.md" -type f | wc -l)
  if [[ "$n" -ne 9 ]]; then
    fail "${agent_dir} has ${n} skills (expected 9)"
    all_count_ok=0
    break
  fi
done
if [[ $all_count_ok -eq 1 ]]; then
  ok "all 6 agents have exactly 9 SKILL.md files"
fi
rm -rf "$tmp"

# --- Test 6: no .git or .slim dirs leaked into target ---
echo "Test 6: no .git or .slim leaked into target"
tmp=$(mktemp -d "/tmp/acf-integ-XXXXXX")
bash "$INSTALL" "$tmp" --all >/dev/null 2>&1
leaked=0
if [[ -d "${tmp}/.git" ]]; then leaked=1; fi
if [[ -d "${tmp}/.slim" ]]; then leaked=1; fi
# Check no .git inside agent dirs
for agent_dir in .devin/skills .claude/skills .cursor/skills .codex/skills .agents/skills .opencode/skills; do
  if find "${tmp}/${agent_dir}" -name ".git" -type d 2>/dev/null | grep -q .; then
    leaked=1
    break
  fi
done
if [[ $leaked -eq 0 ]]; then
  ok "no .git or .slim dirs leaked into target"
else
  fail ".git or .slim dirs leaked into target"
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
