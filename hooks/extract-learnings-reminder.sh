#!/bin/bash
# Hook PostToolUse Bash matcher — força gate triplo de extract-learnings após git commit.
#
# Disparado após Bash; injeta `additionalContext` no model context quando:
#   1. O comando inclui `git commit`
#   2. O cwd tem AGENTS.md declarando "Loop de aprendizado contínuo" (projeto Fase A)
#   3. NÃO é commit trivial (chore typo, docs only, etc — heurística por mensagem)
#
# Remediação da feedback-extract-learning-under-pressure (2026-05-28).

set -uo pipefail

# Lê stdin JSON do harness
INPUT="$(cat 2>/dev/null || echo '{}')"

# Extrai comando do tool_input.command
COMMAND="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except Exception:
    pass
" 2>/dev/null)"

# Só dispara se for git commit
if [ -z "$COMMAND" ]; then
  exit 0
fi
if ! echo "$COMMAND" | grep -qE 'git[[:space:]]+commit'; then
  exit 0
fi

# Diretório do cwd reportado pelo harness (fallback: PWD)
CWD="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)"
[ -z "$CWD" ] && CWD="$PWD"

# Só dispara em projeto com protocolo Fase A instalado
AGENTS_PATH="$CWD/AGENTS.md"
if [ ! -f "$AGENTS_PATH" ]; then
  exit 0
fi
if ! grep -qF "Loop de aprendizado contínuo" "$AGENTS_PATH" 2>/dev/null; then
  exit 0
fi

# Pula commits triviais conhecidos (heurística por padrão da mensagem)
# `chore(typo)`, `docs(typo)`, `chore(deps)`, `style:` etc.
if echo "$COMMAND" | grep -qiE '\b(typo|formatting|whitespace|lint:[[:space:]]*fix|deps:[[:space:]]*bump|style:|chore\(deps\)|chore\(lint\)|chore\(format\))'; then
  exit 0
fi

# Heurística: docs-only que NÃO seja postmortem/learning/handoff também pula
# (criar postmortem/learning/handoff costuma ser parte da reflexão; já está sendo feito)
if echo "$COMMAND" | grep -qiE 'docs\(.*\):' && ! echo "$COMMAND" | grep -qiE '(postmortem|learning|handoff|playbook)'; then
  exit 0
fi

# Injetar additionalContext via JSON output
cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "🧠 GATE TRIPLO EXTRACT-LEARNINGS — você acabou de commitar em projeto com protocolo Fase A.\n\nPause AGORA e aplique o gate triplo EXPLICITAMENTE (no chat, não mental):\n\n1. **Replicável?** Outro agente em outra sessão ganharia tempo lendo um learning desse padrão?\n2. **Não-óbvio?** A regra seria adivinhada apenas lendo o código atual?\n3. **Estável?** Vai sobreviver às próximas 5 mudanças no entorno?\n\nSe 3 SIM → criar 'docs/learnings/YYYY-MM-DD-<slug-do-padrao>.md' usando docs/learnings/_TEMPLATE.md ANTES de seguir pra próxima tarefa.\n\nSe algum NÃO → declarar explicitamente no bloco 7 do modelo canônico: '📚 Sessão sem learning registrável. Motivo: <qual gate falhou e por quê>'.\n\nNÃO PULAR SILENCIOSAMENTE. Esta cobertura existe porque registrou-se tendência sua de pular o passo sob pressão (feedback_extract_learning_under_pressure.md). Disciplina explícita > intenção implícita."
  }
}
JSON
