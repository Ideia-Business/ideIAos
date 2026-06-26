#!/bin/bash
# Hook PostToolUse Edit|Write — lembra de atualizar README do IdeiaOS
# quando o agente modifica componentes (hooks, skills, agents, scripts, templates).
#
# Específico do Claude Code. Reforço para devs usando Claude — barreira
# adicional ao pre-commit hook do Git (este avisa ANTES; pre-commit BLOQUEIA).

set -uo pipefail

# python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
PY3="$(command -v python3 2>/dev/null || true)"

INPUT="$(cat 2>/dev/null || echo '{}')"

# Path do arquivo modificado (Edit usa file_path; Write usa file_path)
FILE_PATH="$(echo "$INPUT" | "$PY3" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    inp = d.get('tool_input', {})
    print(inp.get('file_path', ''))
except Exception:
    pass
" 2>/dev/null)"

[ -z "$FILE_PATH" ] && exit 0

# Só dispara se path contém IdeiaOS/{hooks,skills,agents,scripts,templates}
if ! echo "$FILE_PATH" | grep -qE 'IdeiaOS/(hooks|skills|agents|scripts|templates)/'; then
  exit 0
fi

# Skip se o próprio README está sendo modificado (presume atualização em andamento)
if echo "$FILE_PATH" | grep -qE 'IdeiaOS/README\.md$'; then
  exit 0
fi

# Skip se é o próprio script de auditoria ou install-hooks (não muda nada visível)
if echo "$FILE_PATH" | grep -qE 'IdeiaOS/scripts/(check-readme-sync|install-git-hooks)\.sh$'; then
  exit 0
fi

# Identificar tipo de componente
COMPONENT=""
case "$FILE_PATH" in
  *IdeiaOS/hooks/*)       COMPONENT="hook" ;;
  *IdeiaOS/skills/*)      COMPONENT="skill" ;;
  *IdeiaOS/agents/*)      COMPONENT="agent" ;;
  *IdeiaOS/scripts/*)     COMPONENT="script" ;;
  *IdeiaOS/templates/*)   COMPONENT="template" ;;
  *)                        COMPONENT="componente" ;;
esac

NAME="$(basename "$FILE_PATH")"

# Injetar additionalContext
cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "📝 README SYNC REMINDER — Você acabou de modificar um $COMPONENT ($NAME) no repo IdeiaOS.\n\nAntes de commitar, confirme que README.md ainda reflete o estado:\n\n1. Seção \"O que este setup instala\" (tabelas de componentes globais e do projeto) — esse $COMPONENT está listado?\n2. Seção \"Estrutura do repositório\" (árvore) — esse arquivo aparece?\n3. Se for skill/agent novo, seção \"Como usar no dia a dia\" precisa mencionar?\n\nVocê pode rodar agora pra validar:\n  bash scripts/check-readme-sync.sh\n\nO pre-commit hook vai BLOQUEAR o commit se README estiver dessincronizado E você não incluir README.md no commit. Isso existe porque hoje (28/05/2026) o README ficou desatualizado por 1 sessão inteira sem ninguém notar — barreira ativa > documentação passiva."
  }
}
JSON
