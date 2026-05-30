#!/usr/bin/env bash
# =============================================================================
# sync-all.sh — orquestrador IdeiaOS (update upstream → re-apply overlay)
#
# Fluxo padrão de manutenção do ambiente global IdeiaOS:
#   1. Detecta/aplica atualizações de upstream (GSD plugin, AIOX-core)
#   2. Re-aplica overlay de patches IdeiaOS (Caminho C — composição AIOX × GSD)
#
# **Idempotente:** rodar 1x ou 100x consecutivas dá o mesmo resultado.
# Use este script sempre que:
#   • Atualizar Claude Code
#   • Atualizar GSD plugin manualmente
#   • Atualizar AIOX-core via CLI
#   • Trocar de máquina e quiser restaurar o ambiente
#   • Não tiver certeza se algo foi sobrescrito
#
# Uso:
#   bash scripts/sync-all.sh
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Cores ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
step() { echo -e "\n${CYAN}${BOLD}══════ $* ══════${NC}"; }

echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo    "║         IdeiaOS — sync-all.sh                            ║"
echo    "║         (update upstream + re-apply overlay)            ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"

step "Etapa 1/2: check upstream updates"
bash "$SETUP_DIR/scripts/update-upstream.sh"
upstream_exit=$?

step "Etapa 2/2: re-apply IdeiaOS overlay (Caminho C — composição)"
bash "$SETUP_DIR/scripts/install-global-patches.sh"
patches_exit=$?

echo -e "\n${CYAN}${BOLD}━━━ Sync completo ━━━${NC}"

if [ "$upstream_exit" -eq 0 ] && [ "$patches_exit" -eq 0 ]; then
  echo -e "  ${GREEN}✓ Ambiente IdeiaOS sincronizado e consistente${NC}"
  exit 0
else
  echo -e "  ${YELLOW}⚠ Alguma etapa retornou erro:${NC}"
  echo -e "    update-upstream:        exit=$upstream_exit"
  echo -e "    install-global-patches: exit=$patches_exit"
  exit 1
fi
