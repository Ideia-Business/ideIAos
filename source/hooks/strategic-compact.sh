#!/usr/bin/env bash
# Hook: strategic-compact.sh
# Event: PreToolUse (no matcher — runs before every tool call)
#
# Counts tool calls per session_id using a counter file in /tmp.
# Every 50 calls, injects an additionalContext suggesting the user run /compact.
#
# Behaviour:
#   - Each session_id gets its own counter file: /tmp/claude-compact-counter-{session_id}
#   - Calls 1-49 are silent (exit 0, no output)
#   - Every 50th call (50, 100, 150, ...) emits hookSpecificOutput.additionalContext
#   - Empty session_id → exit 0 silently (no global counter file)
#   - session_id with /, \ or .. → exit 0 silently (path traversal protection, T-10-01)
#   - NEVER exits with code other than 0 (does not block any tool call)
#
# Security (T-10-01): session_id is validated before being used in a file path.
# Pattern: /tmp/claude-compact-counter-{session_id}  (plain-text integer, no JSON)

set -uo pipefail

# ---------------------------------------------------------------------------
# Read and parse stdin JSON
# ---------------------------------------------------------------------------

INPUT="$(cat 2>/dev/null || echo '{}')"

# Parse session_id using bash-native grep/sed — bash puro, sem subprocesso externo (R3-06)
SESSION_ID="$(echo "$INPUT" | \
  grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' 2>/dev/null | \
  sed 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/' 2>/dev/null || \
  echo "")"

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

# Empty session_id — no counter without a session-scoped key (Pitfall 5: no global counter)
[ -z "$SESSION_ID" ] && exit 0

# Sanitize: reject session_id containing path traversal characters (T-10-01)
if echo "$SESSION_ID" | grep -qE '[/\\]|\.\.' 2>/dev/null; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Counter file — scoped to session_id (plain-text integer, no JSON)
# ---------------------------------------------------------------------------

COUNTER_FILE="/tmp/claude-compact-counter-${SESSION_ID}"

# Read current count (default 0)
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
    COUNT="$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)"
    COUNT="${COUNT:-0}"
    # Guarantee it is a non-negative integer (guard against corrupted file)
    [[ "$COUNT" =~ ^[0-9]+$ ]] || COUNT=0
fi

# Increment
COUNT=$((COUNT + 1))

# Persist new count (plain integer — simpler and faster than JSON for a single number)
echo "$COUNT" > "$COUNTER_FILE" || true

# ---------------------------------------------------------------------------
# Emit suggestion every 50 calls
# ---------------------------------------------------------------------------

if [ $((COUNT % 50)) -eq 0 ]; then
    MSG="~${COUNT} tool calls nesta sessao — considere rodar /compact para preservar qualidade. O hook precompact-state-save salvara o STATE.md automaticamente."
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"%s"}}\n' "$MSG"
fi

exit 0
