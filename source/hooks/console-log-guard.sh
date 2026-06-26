#!/usr/bin/env bash
# Hook: console-log-guard.sh
# Event: PostToolUse (matcher: Edit|Write)
#
# Detects console.log / console.debug / console.info in JS/TS files after
# an edit and injects an additionalContext warning reminding Claude to remove
# them before deploying to Lovable / production.
#
# Behaviour:
#   - Checks only .ts / .tsx / .js / .jsx files (others: exit 0 silently)
#   - Exits silently if file_path is empty or file does not exist
#   - Outputs JSON with hookSpecificOutput.additionalContext when console.* found
#   - NEVER exits with 2 (does not block the tool call)
#
# Security (T-01-02): file_path is passed as an argument to grep and python3,
# never via unquoted shell expansion or eval.

set -uo pipefail

# python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
PY3="$(command -v python3 2>/dev/null || true)"

# ---------------------------------------------------------------------------
# Read and parse stdin JSON
# ---------------------------------------------------------------------------

INPUT="$(cat 2>/dev/null || echo '{}')"

# python3 ausente: este hook PROTEGE contra console.* indo para produção — não
# pode silenciar cego. Mas só avisa se o arquivo for relevante (.ts/.tsx/.js/.jsx);
# senão sai 0 em silêncio (evitar warn-every-edit em .md/.json — ruído proibido por C-4).
if [ -z "$PY3" ]; then
  _FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  case "$_FP" in
    *.ts|*.tsx|*.js|*.jsx)
      printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[IdeiaOS] console-log-guard pulado: python3 não encontrado no PATH — console.* NÃO verificado neste edit. Instale/exponha python3 para reativar."}}'
      exit 0 ;;
    *) exit 0 ;;
  esac
fi

PARSED="$(echo "$INPUT" | "$PY3" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {}) or {}
    print(d.get('tool_name', ''))
    print(ti.get('file_path', ''))
    print(d.get('session_id', ''))
    print(d.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)"

TOOL_NAME="$(echo "$PARSED" | sed -n '1p')"
FILE_PATH="$(echo "$PARSED" | sed -n '2p')"
SESSION_ID="$(echo "$PARSED" | sed -n '3p')"
CWD="$(echo "$PARSED" | sed -n '4p')"
[ -z "$CWD" ] && CWD="$PWD"

# ---------------------------------------------------------------------------
# Guards
# ---------------------------------------------------------------------------

# No file path — nothing to check
[ -z "$FILE_PATH" ] && exit 0

# Only check JS/TS files
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx) ;;
  *) exit 0 ;;
esac

# File must exist and be readable
[ -f "$FILE_PATH" ] || exit 0

# ---------------------------------------------------------------------------
# Detect console.log / console.debug / console.info
# ---------------------------------------------------------------------------

# Pass FILE_PATH as a positional argument (never via unquoted expansion)
# grep -nE: print line numbers; head -10: limit output
MATCHES="$(grep -nE 'console\.(log|debug|info)\(' "$FILE_PATH" 2>/dev/null | head -10)"

[ -z "$MATCHES" ] && exit 0

# ---------------------------------------------------------------------------
# Build warning message and emit JSON safely via python3
# ---------------------------------------------------------------------------

BASENAME="$(basename "$FILE_PATH")"

# Line numbers (comma-separated) — extracted from grep output (format: N:...)
LINE_NUMS="$(echo "$MATCHES" | "$PY3" -c "
import sys
lines = []
for l in sys.stdin:
    l = l.strip()
    if ':' in l:
        lines.append(l.split(':')[0])
print(', '.join(lines))
" 2>/dev/null)"

# Compose message and emit JSON — python3 handles all escaping (RESEARCH: Don't Hand-Roll)
"$PY3" -c "
import json, sys

basename = sys.argv[1]
line_nums = sys.argv[2]
matches_count = sys.argv[3]

msg = (
    'console.log detectado em ' + basename + ' — '
    'vai para producao Lovable. '
    'Remova ou substitua por um logger antes do deploy. '
    'Linhas: ' + line_nums
)
# Truncate to ~1500 chars to stay well under the 10k additionalContext limit
msg = msg[:1500]

output = {
    'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': msg
    }
}
print(json.dumps(output))
" "$BASENAME" "$LINE_NUMS" "${#MATCHES}" 2>/dev/null

exit 0
