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
  echo "Usage: $0 [--target claude|cursor|all] [--project-dir PATH] [--dry-run] [--validate-parity]"
  echo "  --target: which harness to build for (default: all)"
  echo "  --project-dir: project to install cursor (.cursor/rules) + claude common rules (.claude/rules) into (default: cwd)"
  echo "  --dry-run: show what would be done without doing it"
  echo "  --validate-parity: check semantic equivalence between claude and cursor targets"
}

TARGET="all"
DRY_RUN=false
PROJECT_DIR="$PWD"
VALIDATE_PARITY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; CURSOR_RULES_DIR="$2/.cursor/rules"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --validate-parity) VALIDATE_PARITY=true; shift ;;
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

validate_parity() {
  echo "→ Validating cross-target parity..."
  local errors=0
  local checked=0
  local report=""

  local current_id=""
  local current_kind=""
  local current_strategy=""
  local in_targets=0
  local has_claude=0
  local has_cursor=0

  while IFS= read -r line; do
    # Detect "id": "value"
    case "$line" in
      *'"id":'*)
        id_val="${line#*'"id":'}"
        id_val="${id_val#*\"}"
        id_val="${id_val%%\"*}"
        current_id="$id_val"
        current_kind=""
        current_strategy=""
        in_targets=0
        has_claude=0
        has_cursor=0
        ;;
      *'"kind":'*)
        kind_val="${line#*'"kind":'}"
        kind_val="${kind_val#*\"}"
        kind_val="${kind_val%%\"*}"
        current_kind="$kind_val"
        ;;
      *'"installStrategy":'*)
        strat_val="${line#*'"installStrategy":'}"
        strat_val="${strat_val#*\"}"
        strat_val="${strat_val%%\"*}"
        current_strategy="$strat_val"
        ;;
      *'"targets":'*)
        in_targets=1
        case "$line" in *'"claude"'*) has_claude=1 ;; esac
        case "$line" in *'"cursor"'*) has_cursor=1 ;; esac
        ;;
      *']'*)
        if [ "$in_targets" -eq 1 ]; then
          in_targets=0
        fi
        ;;
    esac

    if [ "$in_targets" -eq 1 ]; then
      case "$line" in *'"claude"'*) has_claude=1 ;; esac
      case "$line" in *'"cursor"'*) has_cursor=1 ;; esac
    fi

    # Evaluate on block close
    case "$line" in
      *'}'*)
        if [ -n "$current_id" ] && [ -n "$current_kind" ]; then
          case "$current_kind" in
            skill|agent)
              if [ "$has_claude" -eq 1 ] && [ "$has_cursor" -eq 0 ]; then
                checked=$((checked + 1))
                if [ "$current_strategy" != "manual" ]; then
                  report="${report}  DIVERGENCE: ${current_id} — in claude but NOT cursor\n"
                  errors=$((errors + 1))
                fi
              elif [ "$has_cursor" -eq 1 ] && [ "$has_claude" -eq 0 ]; then
                checked=$((checked + 1))
                if [ "$current_strategy" != "manual" ]; then
                  report="${report}  DIVERGENCE: ${current_id} — in cursor but NOT claude\n"
                  errors=$((errors + 1))
                fi
              elif [ "$has_claude" -eq 1 ] && [ "$has_cursor" -eq 1 ]; then
                checked=$((checked + 1))
              fi
              current_id=""
              current_kind=""
              current_strategy=""
              has_claude=0
              has_cursor=0
              in_targets=0
              ;;
          esac
        fi
        ;;
    esac
  done < "$MANIFESTS"

  if [ "$errors" -gt 0 ]; then
    printf "%b" "$report" >&2
    echo "ERROR: $errors parity divergence(s) found. Add to both targets or set installStrategy: manual." >&2
    exit 1
  fi
  echo "✓ Cross-target parity OK ($checked modules checked)"
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

# Claude Code auto-carrega .claude/rules/*.md como project instructions. Antes o
# build-adapters só entregava rules ao Cursor (.mdc) — esta etapa dá PARIDADE ao Claude
# (fecha R8-09). Deploy SÓ de source/rules/common/ (disciplina universal: operating-
# discipline, token-economy, orchestration, antifragile-gates, context-packet-handoffs,
# mcp-hygiene, delta-spec). Rules de stack/domínio (marketing, supabase) ficam Cursor-side
# para não inflar o contexto always-on de TODO projeto.
build_claude_project_rules() {
  local claude_rules_dir="$PROJECT_DIR/.claude/rules"
  echo "→ Deploying common rules to Claude (project): $claude_rules_dir"
  run mkdir -p "$claude_rules_dir"
  local name
  while IFS= read -r rule_file; do
    name="$(basename "$rule_file")"
    run cp "$rule_file" "$claude_rules_dir/ideiaos-common-$name"
    echo "  rule: common/$name → .claude/rules/ideiaos-common-$name"
  done < <(find "$SOURCE_DIR/rules/common" -name "*.md" 2>/dev/null || true)
  echo "✓ Claude project rules deployed"
}

validate_agent_contracts
if $VALIDATE_PARITY; then validate_parity; fi

case "$TARGET" in
  claude) build_claude ;;
  cursor) build_cursor; build_claude_project_rules ;;
  all)    build_claude; build_cursor; build_claude_project_rules ;;
  *) echo "Unknown target: $TARGET"; usage; exit 1 ;;
esac

echo ""
echo "✓ build-adapters.sh complete (target=$TARGET, dry-run=$DRY_RUN)"
