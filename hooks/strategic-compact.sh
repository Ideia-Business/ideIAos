#!/usr/bin/env bash
# Hook: strategic-compact.sh
# Event: PreToolUse (no matcher — runs before every tool call)
#
# Counts tool calls per session_id using a counter file in /tmp.
# Every 50 calls, injects an additionalContext suggesting the user run /compact.
#
# Behaviour:
#   - Each session_id gets its own counter file: /tmp/claude-compact-counter-{session_id}.json
#   - Calls 1-49 are silent (exit 0, no output)
#   - Every 50th call (50, 100, 150, ...) emits hookSpecificOutput.additionalContext
#   - Empty session_id → exit 0 silently (no global counter file)
#   - session_id with /, \ or .. → exit 0 silently (path traversal protection, T-01-01)
#   - NEVER exits with code other than 0 (does not block any tool call)
#
# Security (T-01-01): session_id is validated before being used in a file path.
# Pattern: /tmp/claude-compact-counter-{session_id}.json

set -uo pipefail

# ---------------------------------------------------------------------------
# Read and parse stdin JSON
# ---------------------------------------------------------------------------

INPUT="$(cat 2>/dev/null || echo '{}')"

SESSION_ID="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', ''))
except Exception:
    pass
" 2>/dev/null)"

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

# Empty session_id — no counter without a session-scoped key (Pitfall 5: no global counter)
[ -z "$SESSION_ID" ] && exit 0

# Sanitize: reject session_id containing path traversal characters (T-01-01)
if echo "$SESSION_ID" | grep -qE '[/\\]|\.\.' 2>/dev/null; then
    exit 0
fi

# ---------------------------------------------------------------------------
# Counter file — scoped to session_id
# ---------------------------------------------------------------------------

COUNTER_FILE="/tmp/claude-compact-counter-${SESSION_ID}.json"

# Read current count (default 0)
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
    COUNT="$(/usr/bin/python3 -c "
import json, sys
try:
    print(json.load(open('$COUNTER_FILE')).get('count', 0))
except Exception:
    print(0)
" 2>/dev/null || echo 0)"
fi

# Increment
COUNT=$((COUNT + 1))

# Persist new count
/usr/bin/python3 -c "
import json
try:
    json.dump({'count': $COUNT}, open('$COUNTER_FILE', 'w'))
except Exception:
    pass
" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Emit suggestion every 50 calls
# ---------------------------------------------------------------------------

if [ $((COUNT % 50)) -eq 0 ]; then
    MSG="~${COUNT} tool calls nesta sessao — considere rodar /compact para preservar qualidade. O hook precompact-state-save salvara o STATE.md automaticamente."
    /usr/bin/python3 -c "
import json, sys
msg = sys.argv[1]
output = {
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'additionalContext': msg
    }
}
print(json.dumps(output))
" "$MSG" 2>/dev/null
fi

exit 0
