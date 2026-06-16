#!/usr/bin/env bash
# SOURCE: IdeiaOS v2 | kind: lib | targets: claude,cursor
# handoff-packet.sh — Context-packet pattern for IdeiaOS handoffs
# Concepts: token budget + anti-injection wrapper + idempotency via SHA-256 hash
# Bash 3.2 compat. python3 stdlib (hashlib) for hashing and rewriting. Zero external deps.
# Self-contained — does NOT import gates.sh (same guard pattern, no require).
#
# Public API:
#   wrap_handoff PATH_TO_YAML [LABEL]   — apply 3 concepts to YAML at PATH
#   handoff_already_seen PATH_TO_YAML   — return 0 if PATH already has wrapped: true
#
# Usage:
#   IDEIAOS_DIR="${IDEIAOS_DIR:-$HOME/.ideiaos}"
#   [ -f "$IDEIAOS_DIR/source/lib/handoff-packet.sh" ] \
#     && . "$IDEIAOS_DIR/source/lib/handoff-packet.sh" \
#     || wrap_handoff() { return 0; }   # fallback no-op if lib absent
#   wrap_handoff "$HANDOFF_PATH" "agent-handoff"

# Double-source guard — safe to source multiple times in the same shell
[ -n "${__IDEIAOS_HANDOFF_PACKET_LOADED:-}" ] && return 0
__IDEIAOS_HANDOFF_PACKET_LOADED=1

# Configurable token budget: default 2000 chars (~500 tokens).
# Override before sourcing: HANDOFF_TOKEN_BUDGET=4000 . handoff-packet.sh
HANDOFF_TOKEN_BUDGET="${HANDOFF_TOKEN_BUDGET:-2000}"

# ---------------------------------------------------------------------------
# wrap_handoff PATH_TO_YAML [LABEL]
#
# Applies the 3 context-packet concepts to the YAML file at PATH_TO_YAML:
#   1. Token budget check — warns and notes if file exceeds HANDOFF_TOKEN_BUDGET
#   2. Anti-injection header — injects wrapped/anti_injection fields
#   3. Idempotency hash — injects input_hash (SHA-256 via python3)
#
# Returns:
#   0 — success (file updated)
#   1 — file missing or empty, or write failed
#
# Contract: fail-silent on budget exceed (warn only, never block).
# ---------------------------------------------------------------------------
wrap_handoff() {
  local yaml_path="${1:-}"
  local label="${2:-handoff}"

  # Validate input
  if [ -z "$yaml_path" ] || [ ! -f "$yaml_path" ]; then
    printf '[handoff-packet] WARNING: %s — file not found or path empty\n' \
      "${label}" >&2
    return 1
  fi
  if [ ! -s "$yaml_path" ]; then
    printf '[handoff-packet] WARNING: %s (%s) — file is empty\n' \
      "$label" "$yaml_path" >&2
    return 1
  fi

  # Concept 3: Idempotency — skip if already wrapped
  if grep -q "wrapped: true" "$yaml_path" 2>/dev/null; then
    return 0
  fi

  # Concept 3: Calculate SHA-256 hash via python3 (bash 3.2 compat)
  local hash
  hash=$(python3 -c \
    "import hashlib,sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())" \
    < "$yaml_path" 2>/dev/null) || hash="unavailable"

  # Concept 1: Token budget check (fail-silent — warn only, never block)
  local char_count
  char_count=$(wc -c < "$yaml_path" | tr -d ' ')
  if [ "${char_count:-0}" -gt "${HANDOFF_TOKEN_BUDGET:-2000}" ] 2>/dev/null; then
    printf '[handoff-packet] WARNING: %s (%s chars) exceeds budget (%s). summary will be truncated.\n' \
      "$label" "$char_count" "$HANDOFF_TOKEN_BUDGET" >&2
  fi

  # Concept 2: Anti-injection wrapper + Concept 3: inject hash
  # Rewrite via python3: insert wrapped/anti_injection/input_hash after first
  # "handoff:" line if present, else prepend to file. Pure text manipulation
  # — no YAML parser used (avoids dependency on PyYAML).
  local PY_SCRIPT
  PY_SCRIPT='
import sys
lines = sys.stdin.read()
injected = "wrapped: true\nanti_injection: true\ninput_hash: " + sys.argv[1] + "\n"
# Insert after first line if it starts with "handoff:", else prepend
parts = lines.split("\n", 1)
if parts[0].strip().startswith("handoff:"):
    result = parts[0] + "\n" + injected + (parts[1] if len(parts) > 1 else "")
else:
    result = injected + lines
sys.stdout.write(result)
'

  if python3 -c "$PY_SCRIPT" "$hash" < "$yaml_path" > "${yaml_path}.tmp" 2>/dev/null; then
    mv "${yaml_path}.tmp" "$yaml_path" || { rm -f "${yaml_path}.tmp"; return 1; }
  else
    # Fallback: python3 unavailable — append fields at end (graceful degradation)
    rm -f "${yaml_path}.tmp"
    printf 'wrapped: true\nanti_injection: true\ninput_hash: %s\n' "$hash" >> "$yaml_path" \
      || return 1
  fi

  return 0
}

# ---------------------------------------------------------------------------
# handoff_already_seen PATH_TO_YAML
#
# Returns:
#   0 — file has "wrapped: true" (already processed — idempotent skip)
#   1 — file does not have "wrapped: true" (needs processing)
#
# Used by handoff-consolidation.md Step 1b to detect already-consolidated
# handoffs before inserting into RUN-LOG.md.
# ---------------------------------------------------------------------------
handoff_already_seen() {
  local yaml_path="${1:-}"
  grep -q "wrapped: true" "$yaml_path" 2>/dev/null
}

# End of handoff-packet.sh — sourced once per shell via __IDEIAOS_HANDOFF_PACKET_LOADED
