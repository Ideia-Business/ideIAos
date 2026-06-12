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

build_claude() {
  echo "→ Building Claude target..."
  run mkdir -p "$CLAUDE_HOOKS_DIR" "$CLAUDE_AGENTS_DIR"

  # Hooks: copy from source/hooks/ to ~/.claude/hooks/
  while IFS= read -r hook_file; do
    fname="$(basename "$hook_file")"
    run cp "$hook_file" "$CLAUDE_HOOKS_DIR/$fname"
    run chmod +x "$CLAUDE_HOOKS_DIR/$fname"
    echo "  hook: $fname → $CLAUDE_HOOKS_DIR/"
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

case "$TARGET" in
  claude) build_claude ;;
  cursor) build_cursor ;;
  all)    build_claude; build_cursor ;;
  *) echo "Unknown target: $TARGET"; usage; exit 1 ;;
esac

echo ""
echo "✓ build-adapters.sh complete (target=$TARGET, dry-run=$DRY_RUN)"
