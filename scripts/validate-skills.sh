#!/usr/bin/env bash
# =============================================================================
# ACF — Skill Validator
# =============================================================================
# Validates every SKILL.md file in the repository against the Agent Skills
# specification (https://agentskills.io).
#
# Checks performed on each SKILL.md:
#   1. YAML frontmatter exists (delimited by --- ... ---)
#   2. `name` field exists, is lowercase + hyphens only, max 64 chars
#   3. `description` field exists, max 1024 chars
#   4. Body (content after frontmatter) is under 500 lines
#
# Prints PASS/FAIL for each skill and a summary. Exits 0 if all pass, 1 if any
# fail.
# =============================================================================
set -euo pipefail

# Resolve the repo root (directory containing this script's parent).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Counters.
PASS=0
FAIL=0
FAILED_FILES=()

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Extract the YAML frontmatter block (including delimiters) from a SKILL.md.
# Prints the frontmatter text to stdout, or empty if none found.
extract_frontmatter() {
  local file="$1"
  awk '
    /^---[ \t]*$/ {
      if (!in_fm) { in_fm = 1; print; next }
      else        { print; exit }
    }
    in_fm { print }
  ' "$file"
}

# Extract the value of a top-level YAML key from a frontmatter block.
# Handles simple scalars and YAML block scalars (>- , |-, >, |).
# Prints the concatenated value to stdout.
extract_field() {
  local fm="$1"
  local key="$2"
  # Match "key:" possibly with a block scalar indicator, then capture the rest
  # of the line and any subsequent indented lines.
  printf '%s\n' "$fm" | awk -v k="$key" '
    $0 ~ "^" k ":" {
      # Strip the "key:" prefix and any block indicator.
      val = $0
      sub("^" k ":[ \\t]*", "", val)
      sub("^[|>][-+]?[ \\t]*", "", val)
      if (val != "") printf "%s ", val
      in_block = 1
      next
    }
    in_block {
      # Continuation lines of a block scalar are indented.
      if ($0 ~ "^[ \t]+") {
        line = $0
        sub("^[ \t]+", "", line)
        printf "%s ", line
      } else {
        in_block = 0
      }
    }
  ' | sed 's/[[:space:]]*$//'
}

# Count lines in the body (everything after the closing --- of frontmatter).
count_body_lines() {
  local file="$1"
  awk '
    BEGIN { seen_open = 0; seen_close = 0; body = 0 }
    /^---[ \t]*$/ {
      if (!seen_open)        { seen_open = 1; next }
      else if (!seen_close)  { seen_close = 1; body = 1; next }
    }
    body { count++ }
    END { print count + 0 }
  ' "$file"
}

# Validate a single SKILL.md file. Returns 0 on pass, 1 on fail.
validate_skill() {
  local file="$1"
  local rel="${file#${REPO_ROOT}/}"
  local errors=()

  # 1. Frontmatter exists.
  local fm
  fm="$(extract_frontmatter "$file")"
  if [[ -z "$fm" ]]; then
    errors+=("missing YAML frontmatter")
  fi

  # 2. name field.
  local name=""
  if [[ -n "$fm" ]]; then
    name="$(extract_field "$fm" "name")"
  fi
  if [[ -z "$name" ]]; then
    errors+=("missing 'name' field")
  else
    # lowercase + hyphens, max 64 chars
    if [[ ${#name} -gt 64 ]]; then
      errors+=("name exceeds 64 chars (${#name})")
    fi
    if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
      errors+=("name must be lowercase + hyphens (got: '${name}')")
    fi
  fi

  # 3. description field.
  local desc=""
  if [[ -n "$fm" ]]; then
    desc="$(extract_field "$fm" "description")"
  fi
  if [[ -z "$desc" ]]; then
    errors+=("missing 'description' field")
  else
    if [[ ${#desc} -gt 1024 ]]; then
      errors+=("description exceeds 1024 chars (${#desc})")
    fi
  fi

  # 4. Body under 500 lines.
  local body_lines
  body_lines="$(count_body_lines "$file")"
  if [[ $body_lines -ge 500 ]]; then
    errors+=("body is ${body_lines} lines (must be under 500)")
  fi

  # Report.
  if [[ ${#errors[@]} -eq 0 ]]; then
    printf "PASS  %s\n" "$rel"
    return 0
  else
    printf "FAIL  %s\n" "$rel"
    local e
    for e in "${errors[@]}"; do
      printf "        - %s\n" "$e"
    done
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

echo "ACF skill validator"
echo "Repo: ${REPO_ROOT}"
echo ""

# Find every SKILL.md under the repo.
mapfile -t SKILL_FILES < <(find "$REPO_ROOT" -type f -name "SKILL.md" \
  -not -path "*/.git/*" | sort)

if [[ ${#SKILL_FILES[@]} -eq 0 ]]; then
  echo "No SKILL.md files found."
  exit 1
fi

for f in "${SKILL_FILES[@]}"; do
  if validate_skill "$f"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAILED_FILES+=("$f")
  fi
done

echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed (of $((PASS + FAIL)) skills)"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failed files:"
  for f in "${FAILED_FILES[@]}"; do
    echo "  - ${f#${REPO_ROOT}/}"
  done
  exit 1
fi

exit 0
