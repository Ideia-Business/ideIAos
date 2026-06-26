#!/usr/bin/env bash
# =============================================================================
# typecheck-on-edit.sh — IdeiaOS PostToolUse hook
#
# Roda tsc --noEmit incremental em background apos editar um .ts/.tsx.
# Se houver erros de tipo, acorda o Claude via exit 2 + JSON additionalContext
# (asyncRewake contract). Exit 0 silencioso para arquivos validos ou sem tsc.
#
# Registro em settings.json (plano 04):
#   PostToolUse, matcher: "Edit|Write", async: true, asyncRewake: true, timeout: 60
#
# Entrada (stdin): JSON PostToolUse
#   { "tool_name": "Edit", "tool_input": { "file_path": "..." }, "cwd": "...", "session_id": "..." }
#
# Saida (stdout):
#   exit 0   — silencioso (arquivo nao-TS, tsc OK, ou tsc ausente)
#   exit 2   — JSON com additionalContext contendo erros TypeScript (acorda Claude via asyncRewake)
# =============================================================================
set -uo pipefail

# python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
PY3="$(command -v python3 2>/dev/null || true)"

# Lê stdin — formato JSON do Claude Code
INPUT="$(cat 2>/dev/null || echo '{}')"

# python3 ausente: este hook PROTEGE contra erro de tipo — não pode silenciar cego.
# Mas só avisa se o arquivo for relevante (.ts/.tsx); senão sai 0 em silêncio
# (evitar warn-every-edit em .md/.json/.png — ruído proibido por C-4).
if [ -z "$PY3" ]; then
  _FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  case "$_FP" in
    *.ts|*.tsx)
      printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[IdeiaOS] typecheck-on-edit pulado: python3 não encontrado no PATH — verificação de tipos NÃO executada neste edit. Instale/exponha python3 para reativar."}}'
      exit 0 ;;
    *) exit 0 ;;
  esac
fi

# Extrai file_path e cwd via python3 (sem dependencia de jq — padrao IdeiaOS)
PARSED="$(echo "$INPUT" | "$PY3" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {}) or {}
    print(ti.get('file_path', ''))
    print(d.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)"

FILE_PATH="$(echo "$PARSED" | sed -n '1p')"
CWD="$(echo "$PARSED" | sed -n '2p')"

# Fallback: usa PWD se cwd nao veio no JSON
[ -z "$CWD" ] && CWD="$PWD"

# Filtrar extensao: so processar .ts e .tsx
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Detectar tsc local (Pitfall 1: tsc global nao disponivel no PATH do hook)
# Procurar node_modules/.bin/tsc no cwd do projeto; fallback para tsc global
TSC=""
if [ -f "$CWD/node_modules/.bin/tsc" ]; then
  TSC="$CWD/node_modules/.bin/tsc"
elif command -v tsc >/dev/null 2>&1; then
  TSC="tsc"
fi

# tsc indisponivel — sair silencioso (sem ruido)
[ -z "$TSC" ] && exit 0

# Rodar typecheck incremental no contexto do projeto
# cd "$CWD" garante que o tsconfig.json do projeto seja usado
# tsc retorna exit != 0 quando ha erros de tipo
TSC_OUTPUT="$(cd "$CWD" && "$TSC" --noEmit --incremental 2>&1)" || {
  # Erros encontrados — truncar a 30 linhas e acordar Claude via asyncRewake
  ERRORS_TRIMMED="$(echo "$TSC_OUTPUT" | head -30)"

  # Serializar JSON de forma segura via python3 json.dumps
  # Evita quebra por aspas, newlines, barras ou caracteres especiais no output do tsc
  MSG="$("$PY3" -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PostToolUse',
        'additionalContext': msg
    }
}))
" "TypeScript errors detected:\n$ERRORS_TRIMMED" 2>/dev/null)"

  echo "$MSG"
  exit 2
}

# tsc saiu 0 — sem erros, silencioso
exit 0
