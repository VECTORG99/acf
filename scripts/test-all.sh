#!/usr/bin/env bash
# =============================================================================
# ACF — Full Test Runner
# =============================================================================
# Runs all test suites in sequence and reports a combined summary.
# Exits 0 only if all suites pass.
#
# Usage:
#   bash scripts/test-all.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SUITES=(
  "Skill Validation"   "${SCRIPT_DIR}/test-validate.sh"
  "Installer"          "${SCRIPT_DIR}/test-install.sh"
  "Integration"        "${SCRIPT_DIR}/test-integration.sh"
  "Compaction Bench"   "${SCRIPT_DIR}/benchmark-compaction.sh"
)

TOTAL_PASS=0
TOTAL_FAIL=0
SUITE_RESULTS=()

echo "═══════════════════════════════════════════════════════════════"
echo " ACF — Full Test Suite"
echo "═══════════════════════════════════════════════════════════════"
echo ""

i=0
while [[ $i -lt ${#SUITES[@]} ]]; do
  name="${SUITES[$i]}"
  script="${SUITES[$((i + 1))]}"
  i=$((i + 2))

  echo "── ${name} ──────────────────────────────────────────────────"
  output=$(bash "$script" 2>&1)
  exit_code=$?
  echo "$output"
  echo ""

  if [[ $exit_code -eq 0 ]]; then
    SUITE_RESULTS+=("PASS  ${name}")
    # Extract pass count from summary line
    pass_count=$(echo "$output" | grep -oE '[0-9]+ passed' | head -1 | grep -oE '^[0-9]+' || echo 0)
    TOTAL_PASS=$((TOTAL_PASS + pass_count))
  else
    SUITE_RESULTS+=("FAIL  ${name}")
    fail_count=$(echo "$output" | grep -oE '[0-9]+ failed' | head -1 | grep -oE '^[0-9]+' || echo 0)
    TOTAL_FAIL=$((TOTAL_FAIL + fail_count))
  fi
done

echo "═══════════════════════════════════════════════════════════════"
echo " SUITE RESULTS"
echo "═══════════════════════════════════════════════════════════════"
for r in "${SUITE_RESULTS[@]}"; do
  printf "  %s\n" "$r"
done
echo ""
echo "Total: ${TOTAL_PASS} tests passed, ${TOTAL_FAIL} tests failed"
echo "═══════════════════════════════════════════════════════════════"

if [[ $TOTAL_FAIL -gt 0 ]]; then
  exit 1
fi
exit 0
