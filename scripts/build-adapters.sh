#!/usr/bin/env bash
# build-adapters.sh — compila source/ → harness targets
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

IDEIAOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$IDEIAOS_DIR/source"
MANIFESTS="$IDEIAOS_DIR/manifests/modules.json"
ADAPTERS_DIR="$IDEIAOS_DIR/adapters"

# Harness-specific destinations (defaults, override via env)
CLAUDE_HOOKS_DIR="${CLAUDE_HOOKS_DIR:-$HOME/.claude/hooks}"
CLAUDE_AGENTS_DIR="${CLAUDE_AGENTS_DIR:-$HOME/.claude/agents}"
CURSOR_RULES_DIR="${CURSOR_RULES_DIR:-${PWD}/.cursor/rules}"

usage() {
  echo "Usage: $0 [--target claude|cursor|all] [--project-dir PATH] [--dry-run]"
  echo "  --target: which harness to build for (default: all)"
  echo "  --project-dir: project to install cursor rules into (default: cwd)"
  echo "  --dry-run: show what would be done without doing it"
}

TARGET="all"
DRY_RUN=false
PROJECT_DIR="$PWD"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; CURSOR_RULES_DIR="$2/.cursor/rules"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then echo "[DRY] $*"; else "$@"; fi
}

# Validate agent frontmatter contracts: all source/agents/*.md must have model: and tools:
validate_agent_contracts() {
  echo "→ Validating agent frontmatter contracts..."
  local offenders=()
  while IFS= read -r agent_file; do
    local in_frontmatter=0
    local has_model=0
    local has_tools=0
    while IFS= read -r line; do
      if [[ "$line" == "---" ]]; then
        if [[ $in_frontmatter -eq 0 ]]; then
          in_frontmatter=1
        else
          break
        fi
      elif [[ $in_frontmatter -eq 1 ]]; then
        [[ "$line" =~ ^model:[[:space:]] ]] && has_model=1
        [[ "$line" =~ ^tools:[[:space:]] ]] && has_tools=1
      fi
    done < "$agent_file"
    if [[ $has_model -eq 0 || $has_tools -eq 0 ]]; then
      offenders+=("$(basename "$agent_file") (missing:$([ $has_model -eq 0 ] && echo ' model')$([ $has_tools -eq 0 ] && echo ' tools'))")
    fi
  done < <(find "$SOURCE_DIR/agents" -name "*.md")

  if [[ ${#offenders[@]} -gt 0 ]]; then
    echo "ERROR: The following agents are missing required frontmatter fields (model: and/or tools:):" >&2
    for o in "${offenders[@]}"; do
      echo "  - $o" >&2
    done
    echo "Fix the frontmatter before building adapters." >&2
    exit 1
  fi
  echo "✓ All agents have valid frontmatter contracts (model + tools)"
}

build_claude() {
  echo "→ Building Claude target..."
  run mkdir -p "$CLAUDE_HOOKS_DIR" "$CLAUDE_AGENTS_DIR"

  # Hooks: copy from source/hooks/ to ~/.claude/hooks/
  while IFS= read -r hook_file; do
    fname="$(basename "$hook_file")"
    run cp "$hook_file" "$CLAUDE_HOOKS_DIR/$fname"
    run chmod +x "$CLAUDE_HOOKS_DIR/$fname"
    echo "  hook: $fname → $CLAUDE_HOOKS_DIR/"
    # Gate R6-01: verify the copied hook file landed and is non-empty.
    if [ -z "${DRY_RUN:-}" ] || [ "$DRY_RUN" = "false" ]; then
      # shellcheck source=/dev/null
      [ -n "${IDEIAOS_DIR:-}" ] && [ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] \
        && . "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
      type gate_output >/dev/null 2>&1 || gate_output() { test -s "${1:-}" 2>/dev/null; }
      gate_output "$CLAUDE_HOOKS_DIR/$fname" "build-claude/hook/$fname" \
        || { echo "ERROR: hook copy failed or produced empty file: $fname" >&2; exit 1; }
    fi
  done < <(find "$SOURCE_DIR/hooks" -name "*.sh" -not -name "test-*")

  # Agents: copy from source/agents/ to ~/.claude/agents/
  while IFS= read -r agent_file; do
    fname="$(basename "$agent_file")"
    run cp "$agent_file" "$CLAUDE_AGENTS_DIR/$fname"
    echo "  agent: $fname → $CLAUDE_AGENTS_DIR/"
  done < <(find "$SOURCE_DIR/agents" -name "*.md")

  echo "✓ Claude target built"
}

build_cursor() {
  echo "→ Building Cursor target for: $PROJECT_DIR"
  run mkdir -p "$CURSOR_RULES_DIR"

  # Rules: copy source/rules/ → .cursor/rules/ as .mdc files
  # NOTE: installStrategy filtering (stack:STACK from manifests/modules.json) is Phase 04 scope.
  # build-adapters.sh installs ALL rules here; detect_stack() + selective install wire in Phase 04
  # when /ideiaos-catalog skill is built. This is intentional — not dead code.
  while IFS= read -r rule_file; do
    rel="${rule_file#$SOURCE_DIR/rules/}"
    # Flatten path: common/token-economy.md → ideiaos-token-economy.mdc
    slug="ideiaos-$(echo "$rel" | tr '/' '-' | sed 's/\.md$/.mdc/')"
    run cp "$rule_file" "$CURSOR_RULES_DIR/$slug"
    echo "  rule: $rel → .cursor/rules/$slug"
  done < <(find "$SOURCE_DIR/rules" -name "*.md" -not -path "*/ecc/*" 2>/dev/null || true)

  echo "✓ Cursor target built"
}

validate_agent_contracts

case "$TARGET" in
  claude) build_claude ;;
  cursor) build_cursor ;;
  all)    build_claude; build_cursor ;;
  *) echo "Unknown target: $TARGET"; usage; exit 1 ;;
esac

echo ""
echo "✓ build-adapters.sh complete (target=$TARGET, dry-run=$DRY_RUN)"
