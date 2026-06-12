#!/usr/bin/env bash
# SOURCE: IdeiaOS v2
# IdeiaOS standard statusline for Claude Code's statusLine.command setting.
#
# Reads ONE JSON object from stdin (Claude Code injects model/workspace/cost).
# Prints ONE line to stdout. Exits 0 always — a statusline must never crash.
#
# Output format (segments separated by "  ·  "):
#   <branch>  ·  <model>  ·  <basename cwd>  ·  [P{n}/{m}]  ·  [ctx ~Nk]
#
# Usage in ~/.claude/settings.json:
#   "statusLine": { "type": "command", "command": "/path/to/ideiaos-statusline.sh" }

set -uo pipefail

# --- read stdin ---------------------------------------------------------------
STDIN_DATA="$(cat 2>/dev/null || true)"

# --- parse JSON via node (safe dep: node is required by IdeiaOS setup.sh) -----
# On ANY parse error, fall back to empty strings so the script still prints.
# Output is tab-separated: MODEL<TAB>CURRENT_DIR<TAB>BRANCH_WS<TAB>TOKENS
_parsed="$(printf '%s' "$STDIN_DATA" | node -e "
process.stdin.setEncoding('utf8');
var buf = '';
process.stdin.on('data', function(c) { buf += c; });
process.stdin.on('end', function() {
  try {
    var d = JSON.parse(buf);
    var m   = (d && d.model   && d.model.display_name)                       ? d.model.display_name              : '';
    var dir = (d && d.workspace && d.workspace.current_dir)                  ? d.workspace.current_dir           : '';
    var br  = (d && d.workspace && d.workspace.git_worktree
                 && d.workspace.git_worktree.branch)                         ? d.workspace.git_worktree.branch   : '';
    var tok = (d && d.cost && d.cost.total_tokens > 0)                       ? String(d.cost.total_tokens)       : '0';
    process.stdout.write([m, dir, br, tok].join('\t'));
  } catch (e) {
    process.stdout.write('\t\t\t0');
  }
});
" 2>/dev/null || printf '\t\t\t0')"

# --- split tab-separated fields -----------------------------------------------
# Use cut rather than read/IFS so empty fields between consecutive tabs are preserved.
_model="$(      printf '%s' "$_parsed" | cut -f1)"
_current_dir="$(printf '%s' "$_parsed" | cut -f2)"
_branch_ws="$(  printf '%s' "$_parsed" | cut -f3)"
_tokens="$(     printf '%s' "$_parsed" | cut -f4)"

MODEL="${_model:-claude}"
CURRENT_DIR="${_current_dir:-$PWD}"
TOKENS="${_tokens:-0}"

# --- resolve branch -----------------------------------------------------------
# workspace.git_worktree.branch is set only inside a linked worktree.
# Fall back to git rev-parse for normal repos.
if [ -z "${_branch_ws:-}" ]; then
  BRANCH="$(git -C "$CURRENT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '—')"
else
  BRANCH="$_branch_ws"
fi
BRANCH="${BRANCH:-—}"

# --- context tokens -----------------------------------------------------------
# Claude Code does not pass a context-usage percentage reliably on stdin.
# We derive a best-effort token count from cost.total_tokens when > 0 and
# render it as "ctx ~Nk". We do NOT fabricate a percentage we cannot compute —
# omit rather than mislead (per plan spec).
CTX_SEG=""
if printf '%s' "$TOKENS" | grep -qE '^[0-9]+$' && [ "$TOKENS" -gt 0 ] 2>/dev/null; then
  CTX_K="$(node -e "process.stdout.write('~' + Math.round(${TOKENS}/1000) + 'k')" 2>/dev/null || true)"
  [ -n "${CTX_K:-}" ] && CTX_SEG="ctx ${CTX_K}"
fi

# --- GSD phase (optional) -----------------------------------------------------
# Walk up from CURRENT_DIR (max 10 levels, stop at HOME) looking for
# .planning/STATE.md. Mirror the walk-up logic from gsd-statusline.js.
PHASE_SEG=""
_dir="$CURRENT_DIR"
for _i in 1 2 3 4 5 6 7 8 9 10; do
  _candidate="${_dir}/.planning/STATE.md"
  if [ -f "$_candidate" ]; then
    # Extract "Phase: N of M" line from body
    _phase_line="$(grep -m1 '^Phase:[[:space:]]*[0-9]' "$_candidate" 2>/dev/null || true)"
    if [ -n "$_phase_line" ]; then
      _n="$(printf '%s' "$_phase_line" | sed 's/Phase:[[:space:]]*\([0-9]*\).*/\1/' 2>/dev/null || true)"
      _m="$(printf '%s' "$_phase_line" | sed 's/.*of[[:space:]]*\([0-9]*\).*/\1/' 2>/dev/null || true)"
      if [ -n "${_n:-}" ] && [ -n "${_m:-}" ]; then
        PHASE_SEG="P${_n}/${_m}"
      fi
    fi
    break
  fi
  _parent="$(dirname "$_dir")"
  # Stop at home directory or filesystem root
  if [ "$_parent" = "$_dir" ] || [ "$_dir" = "${HOME:-/}" ]; then
    break
  fi
  _dir="$_parent"
done

# --- compose output line ------------------------------------------------------
BASENAME_DIR="$(basename "$CURRENT_DIR" 2>/dev/null || echo '.')"

_line="$BRANCH  ·  $MODEL  ·  $BASENAME_DIR"
[ -n "${PHASE_SEG:-}" ] && _line="${_line}  ·  ${PHASE_SEG}"
[ -n "${CTX_SEG:-}"   ] && _line="${_line}  ·  ${CTX_SEG}"

printf '%s\n' "${_line:-ideiaos}"

exit 0
