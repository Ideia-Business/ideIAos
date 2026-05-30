#!/bin/bash
# Hook PostToolUse — força gate triplo de extract-learnings em 3 gatilhos:
#
#   1. Bash `git commit` (gatilho original — feedback_extract_learning_under_pressure)
#   2. Write/Edit em qa-gate file com `gate: PASS` (IdeiaOS composição — Contrato 3)
#   3. Write/Edit em `*-VERIFICATION.md` do GSD com goal atingido (IdeiaOS composição — Contrato 3)
#
# Gatilhos 2 e 3 vêm da composição AIOX × GSD desenhada em
# IDEIAOS.md (Caminho C — Composição) — quando uma das pontas conclui
# o trabalho, o ciclo Fase A deve ser fechado.

set -uo pipefail

# Lê stdin JSON do harness
INPUT="$(cat 2>/dev/null || echo '{}')"

# Extrai tool_name, command, file_path e content do tool_input
PARSED="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    tn = d.get('tool_name', '')
    ti = d.get('tool_input', {}) or {}
    cmd = ti.get('command', '')
    fp = ti.get('file_path', '')
    # Para Write, content fica em 'content'; para Edit, há new_string
    content = ti.get('content', '') or ti.get('new_string', '')
    cwd = d.get('cwd', '')
    # Output: 5 linhas — tool_name | command | file_path | first 4kb of content | cwd
    print(tn)
    print(cmd)
    print(fp)
    print(content[:4096].replace(chr(10), ' '))
    print(cwd)
except Exception:
    pass
" 2>/dev/null)"

TOOL_NAME="$(echo "$PARSED" | sed -n '1p')"
COMMAND="$(echo "$PARSED" | sed -n '2p')"
FILE_PATH="$(echo "$PARSED" | sed -n '3p')"
CONTENT_SNIPPET="$(echo "$PARSED" | sed -n '4p')"
CWD="$(echo "$PARSED" | sed -n '5p')"
[ -z "$CWD" ] && CWD="$PWD"

# Determina o gatilho (TRIGGER) — sai cedo se nenhum aplicável
TRIGGER=""

case "$TOOL_NAME" in
  Bash)
    # Gatilho 1: git commit
    if echo "$COMMAND" | grep -qE 'git[[:space:]]+commit'; then
      TRIGGER="git-commit"
    fi
    ;;
  Write|Edit|MultiEdit)
    # Gatilho 2: qa-gate file com PASS
    # Path típico: docs/qa/gates/<story-slug>.yaml ou similar
    if echo "$FILE_PATH" | grep -qE '/qa/gates/.*\.ya?ml$'; then
      if echo "$CONTENT_SNIPPET" | grep -qE 'gate:[[:space:]]*PASS\b'; then
        TRIGGER="qa-gate-pass"
      fi
    fi
    # Gatilho 3: VERIFICATION.md de fase GSD
    if echo "$FILE_PATH" | grep -qE '\.planning/phases/[^/]+/[0-9]+-VERIFICATION\.md$'; then
      # Heurística: VERIFICATION.md "completo" tem "Status: SUCCESS" ou "Goal achieved: YES"
      if echo "$CONTENT_SNIPPET" | grep -qiE '(status:[[:space:]]*success|goal[[:space:]]+achieved:[[:space:]]*yes|✅[[:space:]]*goal)'; then
        TRIGGER="gsd-verify-success"
      fi
    fi
    ;;
esac

[ -z "$TRIGGER" ] && exit 0

# Só dispara em projeto com protocolo Fase A instalado
AGENTS_PATH="$CWD/AGENTS.md"
if [ ! -f "$AGENTS_PATH" ]; then
  exit 0
fi
if ! grep -qF "Loop de aprendizado contínuo" "$AGENTS_PATH" 2>/dev/null; then
  exit 0
fi

# Heurísticas de skip aplicáveis APENAS ao gatilho git-commit
if [ "$TRIGGER" = "git-commit" ]; then
  # Pula commits triviais conhecidos (heurística por padrão da mensagem)
  if echo "$COMMAND" | grep -qiE '\b(typo|formatting|whitespace|lint:[[:space:]]*fix|deps:[[:space:]]*bump|style:|chore\(deps\)|chore\(lint\)|chore\(format\))'; then
    exit 0
  fi
  # Heurística: docs-only que NÃO seja postmortem/learning/handoff também pula
  if echo "$COMMAND" | grep -qiE 'docs\(.*\):' && ! echo "$COMMAND" | grep -qiE '(postmortem|learning|handoff|playbook)'; then
    exit 0
  fi
fi

# Mensagem-base do gate triplo
GATE_MESSAGE='1. **Replicável?** Outro agente em outra sessão ganharia tempo lendo um learning desse padrão?\n2. **Não-óbvio?** A regra seria adivinhada apenas lendo o código atual?\n3. **Estável?** Vai sobreviver às próximas 5 mudanças no entorno?\n\nSe 3 SIM → criar 'docs/learnings/YYYY-MM-DD-<slug-do-padrao>.md' usando docs/learnings/_TEMPLATE.md ANTES de seguir pra próxima tarefa.\n\nSe algum NÃO → declarar explicitamente: \"📚 Sessão sem learning registrável. Motivo: <qual gate falhou e por quê>\".\n\nNÃO PULAR SILENCIOSAMENTE. Disciplina explícita > intenção implícita.'

# Cabeçalho varia por gatilho
case "$TRIGGER" in
  git-commit)
    HEADER='🧠 GATE TRIPLO EXTRACT-LEARNINGS — você acabou de commitar em projeto com protocolo Fase A.\n\nPause AGORA e aplique o gate triplo EXPLICITAMENTE (no chat, não mental):'
    ;;
  qa-gate-pass)
    HEADER='🧠 GATE TRIPLO EXTRACT-LEARNINGS — qa-gate concluído com verdict PASS (IdeiaOS Contrato 3).\n\nA story passou no gate de qualidade AIOX. Antes de seguir para deploy/push, avalie o gate triplo:'
    ;;
  gsd-verify-success)
    HEADER='🧠 GATE TRIPLO EXTRACT-LEARNINGS — VERIFICATION.md do GSD marcado como SUCCESS (IdeiaOS Contrato 3).\n\nA fase atingiu o goal-backward. Antes de seguir para qa-gate ou deploy, avalie o gate triplo:'
    ;;
esac

# Injetar additionalContext via JSON output (escape de \n via printf)
ADDITIONAL_CONTEXT="${HEADER}\n\n${GATE_MESSAGE}"

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$ADDITIONAL_CONTEXT"
