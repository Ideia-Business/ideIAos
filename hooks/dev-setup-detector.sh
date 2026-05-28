#!/bin/bash
# Hook SessionStart — detecta projeto Lovable não-setupado e injeta lembrete
# para invocar `/dev-setup`.
#
# Filtros (silenciar para evitar ruído):
#   - cwd não é projeto Lovable
#   - Já tem AGENTS.md com "Loop de aprendizado contínuo" (Fase A já instalada)
#   - Projeto é o próprio dev-setup
#
# Disparo: 1x por sessão, apenas se for projeto Lovable sem Fase A.

set -uo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"

CWD="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)"
[ -z "$CWD" ] && CWD="$PWD"

# Skip se for o próprio dev-setup
if [ "$(basename "$CWD")" = "dev-setup" ]; then
  exit 0
fi

# Skip se não for projeto Lovable (heurística)
IS_LOVABLE=0
if compgen -G "$CWD/lovable.config.*" > /dev/null 2>&1; then
  IS_LOVABLE=1
elif [ -d "$CWD/.lovable" ]; then
  IS_LOVABLE=1
elif [ -f "$CWD/AGENTS.md" ] && grep -qi "Lovable Cloud" "$CWD/AGENTS.md" 2>/dev/null; then
  IS_LOVABLE=1
elif [ -d "$CWD/supabase" ] && [ -f "$CWD/package.json" ]; then
  # Heurística fraca: supabase + node. Vale só se git remote for Ideia-Business.
  REMOTE="$(cd "$CWD" && git config --get remote.origin.url 2>/dev/null || true)"
  if echo "$REMOTE" | grep -qE "Ideia-Business|ideia-business"; then
    IS_LOVABLE=1
  fi
fi
[ "$IS_LOVABLE" -eq 0 ] && exit 0

# Skip se Fase A já instalada
if [ -f "$CWD/AGENTS.md" ] && grep -q "Loop de aprendizado contínuo" "$CWD/AGENTS.md" 2>/dev/null; then
  exit 0
fi

# Injetar lembrete via additionalContext
cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "🔧 SETUP DETECTOR — Este projeto parece ser Lovable (heurística) mas NÃO tem o setup Fase A do dev-setup (AGENTS.md sem 'Loop de aprendizado contínuo' OU AGENTS.md ausente).\n\nConsidere rodar `/dev-setup` no chat. Isso é idempotente — pula tudo que já está instalado. Vai diagnosticar e completar:\n\n- AGENTS.md com seção Lovable + camada Fase A\n- docs/playbook-implantacao.md\n- docs/lovable/_TEMPLATE.md + conclusao-implantacao.md\n- docs/learnings/ + docs/postmortems/\n- .cursor/rules/*.mdc (agents-md-protocol, planning-branch, session-continuation)\n- Hook PostToolUse extract-learnings-reminder (se Claude Code global ainda não tem)\n\nSe este NÃO é projeto Lovable e o detector se enganou, ignore esta mensagem (heurística não é perfeita). Falsos positivos prováveis: forks de projetos Ideia-Business sem deploy Lovable."
  }
}
JSON
