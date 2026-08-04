#!/usr/bin/env bash
# =============================================================================
# ACF — Universal Multi-Agent Skill Installer
# =============================================================================
# Installs the ACF orchestrator (acf/SKILL.md) and all 8 sub-skills
# (01-context-load/ through 08-caveman/) into a target project, for one or
# more AI coding agents.
#
# Usage:
#   ./install.sh /target/project              # auto-detect existing agent dirs
#   ./install.sh /target/project --all        # install to ALL supported agents
#   ./install.sh /target/project --agent devin
#
# Supported agents and their skill directory paths:
#   devin     → .devin/skills/
#   claude    → .claude/skills/
#   cursor    → .cursor/skills/
#   codex     → .codex/skills/
#   agents    → .agents/skills/
#   opencode  → .opencode/skills/
#
# The script is idempotent: re-running it overwrites in place safely.
# =============================================================================
set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Resolve the directory where this script lives (the ACF repo root).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source skill locations inside the ACF repo.
#   - Orchestrator lives at .devin/skills/acf/
#   - The 8 sub-skills live at skills/01-context-load/ ... skills/08-caveman/
ORCHESTRATOR_SRC="${SCRIPT_DIR}/.devin/skills/acf"
SUBSKILLS_SRC="${SCRIPT_DIR}/skills"

# Associative mapping: agent name → relative skill directory path.
declare -A AGENT_PATHS=(
  ["devin"]=".devin/skills"
  ["claude"]=".claude/skills"
  ["cursor"]=".cursor/skills"
  ["codex"]=".codex/skills"
  ["agents"]=".agents/skills"
  ["opencode"]=".opencode/skills"
)

# Ordered list of agent names (for deterministic output).
AGENT_ORDER=(devin claude cursor codex agents opencode)

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Print a usage message to stderr.
usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") <target-project> [--all | --agent <name>]

Arguments:
  <target-project>   Path to the project where ACF skills will be installed.

Flags:
  --all              Install to ALL supported agent directories (creating them
                     if they do not exist).
  --agent <name>     Install only to the specified agent's directory.
                     <name> must be one of: ${AGENT_ORDER[*]}

If no flag is given, the script auto-detects which agent directories already
exist in the target project and installs to all of them.
EOF
}

# Print an error and exit 1.
die() {
  echo "ERROR: $*" >&2
  exit 1
}

# Install the orchestrator + sub-skills into one agent's skill directory.
#   $1 = target project root (absolute)
#   $2 = agent name
install_for_agent() {
  local target_root="$1"
  local agent="$2"
  local rel_path="${AGENT_PATHS[$agent]:-}"
  [[ -n "$rel_path" ]] || die "Unknown agent: ${agent}"

  local dest="${target_root}/${rel_path}"

  # Create the destination directory if it does not exist.
  mkdir -p "$dest"

  # Copy the orchestrator (acf/).
  if [[ -d "$ORCHESTRATOR_SRC" ]]; then
    cp -R "$ORCHESTRATOR_SRC" "$dest/"
  else
    die "Orchestrator source not found: $ORCHESTRATOR_SRC"
  fi

  # Copy all 8 sub-skills (01-context-load/ through 08-caveman/).
  if [[ -d "$SUBSKILLS_SRC" ]]; then
    local sub
    for sub in "$SUBSKILLS_SRC"/*/; do
      [[ -d "$sub" ]] || continue
      cp -R "$sub" "$dest/"
    done
  else
    die "Sub-skills source not found: $SUBSKILLS_SRC"
  fi

  echo "  ✓ Installed to ${agent} → ${rel_path}/"
}

# -----------------------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------------------

# Need at least one argument (the target path).
if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

# First positional argument is the target project path.
TARGET="$1"
shift

# Parse optional flags.
MODE="auto"        # auto | all | single
SINGLE_AGENT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      MODE="all"
      shift
      ;;
    --agent)
      [[ $# -ge 2 ]] || { usage; die "--agent requires a value"; }
      MODE="single"
      SINGLE_AGENT="$2"
      shift 2
      # Validate the agent name.
      valid=0
      for a in "${AGENT_ORDER[@]}"; do
        [[ "$a" == "$SINGLE_AGENT" ]] && valid=1
      done
      [[ $valid -eq 1 ]] || die "Unknown agent '${SINGLE_AGENT}'. Valid: ${AGENT_ORDER[*]}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      die "Unknown argument: $1"
      ;;
  esac
done

# Save the original target for error messages before resolving.
TARGET_RAW="$TARGET"

# Validate the target path exists before resolving to an absolute path.
[[ -d "$TARGET_RAW" ]] || die "Target path does not exist or is not a directory: ${TARGET_RAW}"

# Resolve to an absolute path.
TARGET="$(cd "$TARGET_RAW" && pwd)"

# -----------------------------------------------------------------------------
# Determine which agents to install for
# -----------------------------------------------------------------------------

SELECTED_AGENTS=()

case "$MODE" in
  all)
    # Install to every supported agent.
    SELECTED_AGENTS=("${AGENT_ORDER[@]}")
    ;;
  single)
    SELECTED_AGENTS=("$SINGLE_AGENT")
    ;;
  auto)
    # Auto-detect: check which agent directories already exist in the target.
    for agent in "${AGENT_ORDER[@]}"; do
      rel="${AGENT_PATHS[$agent]}"
      if [[ -d "${TARGET}/${rel}" ]]; then
        SELECTED_AGENTS+=("$agent")
      fi
    done
    if [[ ${#SELECTED_AGENTS[@]} -eq 0 ]]; then
      echo "No agent skill directories detected in ${TARGET}."
      echo "Use --all to install to all supported agents, or --agent <name>."
      exit 1
    fi
    ;;
esac

# -----------------------------------------------------------------------------
# Install
# -----------------------------------------------------------------------------

echo "ACF skill installer"
echo "Target: ${TARGET}"
echo "Source: ${SCRIPT_DIR}"
echo "Agents: ${SELECTED_AGENTS[*]}"
echo ""

for agent in "${SELECTED_AGENTS[@]}"; do
  install_for_agent "$TARGET" "$agent"
done

echo ""
echo "Done. Installed ACF orchestrator + 8 sub-skills to ${#SELECTED_AGENTS[@]} agent(s)."
exit 0
