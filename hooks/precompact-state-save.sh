#!/usr/bin/env bash
# =============================================================================
# precompact-state-save.sh — IdeiaOS PreCompact hook
#
# Garante que o STATE.md do projeto (.planning/STATE.md ou STATE.md) seja
# atualizado com um snapshot mínimo ANTES que o /compact compacte o histórico.
#
# Entrada (stdin): JSON { session_id, transcript_path, cwd, trigger }
#   trigger: "manual" | "auto"
#
# Saída (stdout): JSON com additionalContext informando que STATE.md foi salvo
#   (ou silencioso se projeto sem STATE.md)
#
# Exit 0: sempre — NÃO bloqueia o compact (nunca usa decision: block)
#
# Segurança:
#   - Não insere conteúdo bruto do transcript (Pitfall 4)
#   - Snapshot é mínimo e estruturado (bullets + timestamp)
#   - Escreve apenas em STATE_FILE detectado no cwd (não cria arquivo espúrio)
#   - Usa python3 para escrever STATE.md (sem risco de caracteres de controle)
# =============================================================================
set -uo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"

# Extrai cwd e trigger via python3 (sem dependência de jq — padrão IdeiaOS)
PARSED="$(/usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('cwd', ''))
    print(d.get('trigger', 'unknown'))
except Exception:
    print('')
    print('unknown')
" <<< "$INPUT" 2>/dev/null)"

CWD="$(echo "$PARSED" | sed -n '1p')"
TRIGGER="$(echo "$PARSED" | sed -n '2p')"

[ -z "$CWD" ] && CWD="$PWD"
[ -z "$TRIGGER" ] && TRIGGER="unknown"

# Detectar STATE_FILE (padrão do RESEARCH — interfaces)
STATE_FILE=""
if [ -f "$CWD/.planning/STATE.md" ]; then
  STATE_FILE="$CWD/.planning/STATE.md"
elif [ -f "$CWD/STATE.md" ]; then
  STATE_FILE="$CWD/STATE.md"
fi

# Projeto sem STATE.md — sair silenciosamente
[ -z "$STATE_FILE" ] && exit 0

TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"

# Atualizar seção "## Compact Snapshot" de forma idempotente:
#   - Se já existe, truncar tudo a partir do marcador (remove seção antiga)
#   - Reanexar nova seção no final
# Usa sys.argv para evitar interpolação de variáveis shell no código python3 (segurança)
/usr/bin/python3 - "$STATE_FILE" "$TIMESTAMP" "$TRIGGER" <<'PYEOF' 2>/dev/null || true
import sys

state_file = sys.argv[1]
timestamp  = sys.argv[2]
trigger    = sys.argv[3]

try:
    content = open(state_file).read()
except Exception:
    sys.exit(0)

marker = '## Compact Snapshot'

# Truncar seção antiga se existir
if marker in content:
    content = content[:content.index(marker)].rstrip()

new_section = (
    "\n\n"
    "## Compact Snapshot\n\n"
    f"**Auto-saved:** {timestamp} (PreCompact hook, trigger: {trigger})\n\n"
    "- Snapshot automático antes do /compact.\n"
    "- Detalhes da sessão em ~/.claude/sessions/ (session-summary hook).\n"
)

open(state_file, 'w').write(content + new_section)
PYEOF

# Emitir systemMessage informando que STATE.md foi preservado
# (PreCompact não suporta hookSpecificOutput/additionalContext — schema aceita
#  apenas campos raiz: continue, suppressOutput, stopReason, decision, reason,
#  systemMessage)
# Truncado a < 5000 chars (Pitfall 6)
MSG="STATE.md atualizado com Compact Snapshot ($TIMESTAMP). Contexto preservado no resumo do /compact. Arquivo: $STATE_FILE"

/usr/bin/python3 -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({'systemMessage': msg}))
" "$MSG" 2>/dev/null || true

exit 0
