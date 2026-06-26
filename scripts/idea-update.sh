#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-19)
# =============================================================================
# idea-update.sh — comando ÚNICO canônico de atualização da estação ("idea update").
#
# Reconcilia, numa passada e por exit-code, as três camadas que o caminho de update
# antes espalhava (e confundia com 2 estratégias de daemon coexistindo): HOOKS +
# OVERLAY + DAEMON. Usa SEMPRE o redeploy CANÔNICO do daemon (cp-da-fonte, via
# source/lib/redeploy-daemon.sh) — nunca os patchers in-place (sed/grep), agora
# deprecados em ideiaos-update.sh. O registro de hooks reusa o registrador idempotente
# (`ideiaos-update.sh --hooks-only`), preservando o consentimento visível (T-01-10).
#
# Build-contract: exit 1 se uma etapa CRÍTICA (overlay/daemon) falhar — não silencioso.
#
#   bash scripts/idea-update.sh            # update completo (pull + overlay + daemon + hooks + doctor)
#   bash scripts/idea-update.sh --no-pull  # sem git pull (offline / árvore já atualizada)
# =============================================================================
set -uo pipefail
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

NO_PULL=0
for a in "$@"; do case "$a" in --no-pull) NO_PULL=1 ;; esac; done
ERRORS=0

# Pre-op guard anti-race (R15-22): este comando edita hooks/overlay/daemon multi-arquivo.
IDEIAOS_DIR="${IDEIAOS_DIR:-$SETUP_DIR}"
[ -f "$IDEIAOS_DIR/source/lib/surgery-lock.sh" ] && . "$IDEIAOS_DIR/source/lib/surgery-lock.sh" || surgery_begin() { return 0; }
surgery_begin "idea-update"

# 1) pull da fonte
if [ "$NO_PULL" -eq 0 ]; then
  step "1/4: git pull (fonte IdeiaOS)"
  if git -C "$SETUP_DIR" pull --ff-only --quiet 2>/dev/null; then ok "pull OK (ou já atualizado)"
  else warn "pull pulado (offline, branch protegida ou non-FF) — seguindo com a árvore atual"; fi
fi

# 2) overlay + skills/hooks (arquivos) — etapas CRÍTICAS (gate)
step "2/4: overlay global (setup --global-only + install-global-patches)"
if bash "$SETUP_DIR/setup.sh" --global-only; then ok "setup --global-only concluído"; else err "setup --global-only FALHOU"; ERRORS=$((ERRORS+1)); fi
if bash "$SETUP_DIR/scripts/install-global-patches.sh"; then ok "overlay reaplicado"; else err "install-global-patches FALHOU"; ERRORS=$((ERRORS+1)); fi

# 3) daemon — redeploy CANÔNICO (cp-da-fonte), NUNCA patch in-place
step "3/4: git-autosync daemon (redeploy canônico da fonte)"
. "$SETUP_DIR/source/lib/redeploy-daemon.sh"
case "$(redeploy_autosync_daemon "$SETUP_DIR/source/autosync/git-autosync.sh" "$HOME/.local/bin/git-autosync")" in
  ALREADY) ok "daemon já na versão canônica" ;;
  HEALED)  ok "daemon curado da fonte canônica (qualquer drift corrigido)" ;;
  MISSING) warn "daemon não instalado nesta máquina (rode setup-dev-machine.sh)" ;;
  FAILED)  err "falha ao redeployar o daemon"; ERRORS=$((ERRORS+1)) ;;
esac

# 4) registro de hooks — reusa o registrador idempotente (T-01-10: consentimento visível)
step "4/4: registro de hooks (settings.json)"
if bash "$SETUP_DIR/scripts/ideiaos-update.sh" --hooks-only; then ok "hooks reconciliados"; else warn "registro de hooks terminou com avisos"; fi

# verificação final
step "verificação: idea-doctor"
bash "$SETUP_DIR/scripts/idea-doctor.sh" || warn "idea-doctor reportou itens (ver acima)"

echo ""
if [ "$ERRORS" -gt 0 ]; then err "idea update terminou com $ERRORS erro(s) crítico(s)."; exit 1; fi
ok "idea update concluído — hooks + overlay + daemon reconciliados (1 comando, cp-canônico)."
exit 0
