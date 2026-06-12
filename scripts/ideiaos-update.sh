#!/usr/bin/env bash
# =============================================================================
# ideiaos-update.sh — Atualização completa de máquina em 1 comando
#
# Camada fina sobre o sync-all.sh que adiciona a configuração de usuário
# que o setup.sh (por decisão T-01-10) só imprime como snippet:
#
#   1. scripts/sync-all.sh             (pull → upstream → setup --global-only
#                                        → patches globais → idea-doctor)
#   2. Funções claude-dev/review/research no profile do shell (idempotente)
#   3. Statusline IdeiaOS no ~/.claude/settings.json (backup + idempotente)
#
# DIFERENÇA do setup.sh (decisão T-01-10): o setup.sh NUNCA edita dotfiles ou
# settings.json do usuário — só imprime snippets. ESTE script edita, porque
# rodá-lo é o consentimento explícito ("atualizar tudo sem copiar/colar").
#
# Uso:
#   bash scripts/ideiaos-update.sh                  # tudo
#   bash scripts/ideiaos-update.sh --no-shell       # não toca no profile do shell
#   bash scripts/ideiaos-update.sh --no-statusline  # não toca no settings.json
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Cores ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
skip() { echo -e "${CYAN}  ⊙${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

NO_SHELL=0; NO_STATUSLINE=0
for arg in "$@"; do
  case "$arg" in
    --no-shell)      NO_SHELL=1 ;;
    --no-statusline) NO_STATUSLINE=1 ;;
  esac
done

# ── 1. sync-all (pull + upstream + setup global + patches + doctor) ──────────
# Self-update: se o pull do sync-all trouxer versão nova DESTE script, a
# execução atual continua com a versão antiga — aceitável (as etapas 2-3 são
# estáveis); a próxima execução já usa a nova.
step "1/3: sync-all.sh (pull → upstream → setup --global-only → patches → doctor)"
bash "$SETUP_DIR/scripts/sync-all.sh" || warn "sync-all terminou com avisos (ver acima)"

# ── 2. Funções de shell (claude-dev/review/research) ─────────────────────────
step "2/3: funções de contexto no shell"
if [ "$NO_SHELL" -eq 1 ]; then
  skip "profile do shell não tocado (--no-shell)"
else
  # Detecta o profile certo: zsh → ~/.zshrc; bash → ~/.bashrc
  case "${SHELL:-/bin/bash}" in
    */zsh)  PROFILE="$HOME/.zshrc" ;;
    *)      PROFILE="$HOME/.bashrc" ;;
  esac
  touch "$PROFILE"
  if grep -q "claude-review()" "$PROFILE" 2>/dev/null; then
    skip "Funções já presentes em $PROFILE"
  else
    {
      printf '\n# IdeiaOS — modos de contexto (Fase 07: contexts-evals)\n'
      printf 'claude-dev()      { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/dev.md")" "$@"; }\n'
      printf 'claude-review()   { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/review.md")" "$@"; }\n'
      printf 'claude-research() { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/research.md")" "$@"; }\n'
    } >> "$PROFILE"
    ok "Funções claude-dev/review/research adicionadas a $PROFILE"
  fi
fi

# ── 3. Statusline IdeiaOS no settings.json ───────────────────────────────────
step "3/3: statusline IdeiaOS"
SETTINGS="$HOME/.claude/settings.json"
SL_CMD="bash $HOME/.ideiaos/statusline/ideiaos-statusline.sh"
if [ "$NO_STATUSLINE" -eq 1 ]; then
  skip "settings.json não tocado (--no-statusline)"
elif [ ! -f "$SETTINGS" ]; then
  warn "~/.claude/settings.json não existe — rode o Claude Code uma vez e re-execute"
elif /usr/bin/python3 -c "
import json, sys
d = json.load(open('$SETTINGS'))
sl = d.get('statusLine', {})
sys.exit(0 if 'ideiaos-statusline' in str(sl.get('command', '')) else 1)
" 2>/dev/null; then
  skip "Statusline IdeiaOS já configurada"
else
  cp "$SETTINGS" "$SETTINGS.bak-statusline"
  /usr/bin/python3 - "$SETTINGS" "$SL_CMD" <<'PYEOF'
import json, sys
p, cmd = sys.argv[1], sys.argv[2]
d = json.load(open(p))
d["statusLine"] = {"type": "command", "command": cmd}
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PYEOF
  ok "Statusline IdeiaOS configurada (backup em settings.json.bak-statusline)"
fi

echo ""
echo -e "${GREEN}${BOLD}━━━ Atualização concluída ━━━${NC}"
echo -e "${YELLOW}⚠ Reinicie o Claude Code (e abra um terminal novo) para tudo surtir efeito.${NC}"
