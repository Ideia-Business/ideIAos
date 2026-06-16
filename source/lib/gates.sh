#!/usr/bin/env bash
# SOURCE: IdeiaOS v2 | kind: lib | targets: claude,cursor
# =============================================================================
# gates.sh — Antifragile I/O gate helpers (R6-01)
#
# Validates step outputs via binary test -s / exit codes ONLY.
# Never trusts Read-tool output — that path can be hallucinated.
# Sourced once per shell session via the __IDEIAOS_GATES_LOADED guard.
#
# Usage:
#   . "$IDEIAOS_DIR/source/lib/gates.sh"
#   gate_output "$MY_FILE" "step-label" || { echo "bail" >&2; exit 1; }
#
# Caller decides failure action:
#   Hooks    → warn + exit 0  (never block IDE session)
#   Scripts  → exit 1         (fail loudly on bad build)
# =============================================================================
[ -n "${__IDEIAOS_GATES_LOADED:-}" ] && return 0
__IDEIAOS_GATES_LOADED=1

# assert_nonempty PATH [LABEL]
# Returns 0 if PATH exists and is non-empty (test -s passes).
# Returns 1 and prints to stderr if missing or zero bytes.
assert_nonempty() {
  local path="${1:-}"
  local label="${2:-$path}"
  if test -s "$path" 2>/dev/null; then
    return 0
  fi
  printf 'gates: %s not found or empty: %s\n' "$label" "$path" >&2
  return 1
}

# gate_output PATH [LABEL]
# Synonym for assert_nonempty — intended for "validate a step's output file".
gate_output() {
  assert_nonempty "$@"
}

# require_file PATH [LABEL]
# Synonym for assert_nonempty — intended for "dependency must exist before use".
require_file() {
  assert_nonempty "$@"
}

# End of gates.sh — sourced once per shell session via __IDEIAOS_GATES_LOADED guard
