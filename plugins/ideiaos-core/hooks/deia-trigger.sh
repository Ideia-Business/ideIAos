#!/usr/bin/env bash
# =============================================================================
# deia-trigger.sh — IdeiaOS UserPromptSubmit hook
#
# Detecta quando o usuário começa a mensagem com "Deia," / "Deia " / "deia,"
# / "deia " / "Déia," / "Déia " (variantes com vírgula, espaço, acento) e
# injeta no contexto da IA um direcionamento explícito para ativar a skill
# /idea (orquestrador IdeiaOS).
#
# Atua como reforço determinístico ao description-based trigger da skill,
# garantindo que o usuário possa chamar por nome ("Deia, faça X") sem
# precisar lembrar o comando /idea.
#
# Entrada (stdin): JSON com o evento UserPromptSubmit
#   { "prompt": "Deia, preciso implementar OAuth" }
#
# Saída (stdout): JSON com contexto adicional injetado no prompt
#   { "additionalContext": "<orientação para Claude>" }
#
# Exit 0: sempre (hook não bloqueia mensagem)
# =============================================================================
set -uo pipefail

# Lê stdin — formato JSON do Claude Code
INPUT="$(cat 2>/dev/null || true)"
[ -z "$INPUT" ] && exit 0

# Extrai o prompt do usuário (resiliente — funciona com ou sem jq)
if command -v jq &>/dev/null; then
  PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || true)"
else
  # Fallback: extrai primeiro valor de "prompt" via grep+sed
  PROMPT="$(echo "$INPUT" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"prompt"[[:space:]]*:[[:space:]]*"//;s/"$//' | head -1)"
fi

[ -z "$PROMPT" ] && exit 0

# Detecta gatilho "Deia" no início da mensagem (case-insensitive, com/sem acento, com/sem pontuação)
# Padrões aceitos: "Deia", "deia", "Déia", "déia", seguidos de:
#   - vírgula (", ")
#   - dois pontos (": ")
#   - espaço (" ")
#   - ponto e espaço (". ")
if echo "$PROMPT" | grep -qiE '^[[:space:]]*(deia|déia)[[:space:]]*[,.:!?]?[[:space:]]+' 2>/dev/null; then
  # Match — injetar contexto que orienta Claude a ativar a skill /idea
  cat <<JSON
{
  "additionalContext": "🎯 IdeiaOS Trigger Detectado — O usuário invocou 'Deia' como assistente. Ative a skill /idea (orquestrador IdeiaOS) AGORA. Analise o pedido completo após 'Deia, ' e roteie para a camada correta (GSD/AIOX/Lovable/Fase A/Continuation) seguindo a matriz em ~/.claude/skills/idea/SKILL.md. Mostre transparentemente qual comando real está executando antes de delegar."
}
JSON
  exit 0
fi

# Nada a fazer — passa o prompt adiante sem modificação
exit 0
