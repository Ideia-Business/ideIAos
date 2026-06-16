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

step "Etapa 1/5: git pull da fonte IdeiaOS (branch atual)"
# Puxa a versão mais recente do repo ANTES de reinstalar — garante que skills,
# scripts e templates do global reflitam o que está no GitHub.
if git -C "$SETUP_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$SETUP_DIR" pull --rebase --autostash 2>&1 | tail -3
  pull_exit=${PIPESTATUS[0]}
else
  echo "  ⊙ IdeiaOS não é repo git aqui — pulando pull"
  pull_exit=0
fi

step "Etapa 2/5: check upstream updates (GSD plugin, AIOX-core)"
bash "$SETUP_DIR/scripts/update-upstream.sh"
upstream_exit=$?

step "Etapa 3/5: reinstalar componentes globais (setup.sh --global-only)"
# Propaga skills/MCPs/hooks atualizados do repo para ~/.claude (global). Sem isso,
# updates nas nossas próprias skills não chegam ao ambiente instalado.
bash "$SETUP_DIR/setup.sh" --global-only
setup_exit=$?

step "Etapa 4/5: re-apply IdeiaOS overlay (Caminho C — composição)"
bash "$SETUP_DIR/scripts/install-global-patches.sh"
patches_exit=$?

propagate_exit=0
step "Etapa 5/5: propagar para projetos-alvo (se paths propagáveis mudaram)"
bash "$SETUP_DIR/scripts/propagate-if-changed.sh" || propagate_exit=$?

step "Verificação final — idea-doctor (health + drift)"
bash "$SETUP_DIR/scripts/idea-doctor.sh" || true

echo -e "\n${CYAN}${BOLD}━━━ Sync completo ━━━${NC}"

if [ "$pull_exit" -eq 0 ] && [ "$upstream_exit" -eq 0 ] && [ "$setup_exit" -eq 0 ] && [ "$patches_exit" -eq 0 ]; then
  echo -e "  ${GREEN}✓ Ambiente IdeiaOS sincronizado e consistente${NC}"
  [ "$propagate_exit" -ne 0 ] && echo -e "  ${YELLOW}⚠ propagate-if-changed retornou exit=$propagate_exit (ver log)${NC}"
  exit 0
else
  echo -e "  ${YELLOW}⚠ Alguma etapa retornou erro:${NC}"
  echo -e "    git pull:               exit=$pull_exit"
  echo -e "    update-upstream:        exit=$upstream_exit"
  echo -e "    setup --global-only:    exit=$setup_exit"
  echo -e "    install-global-patches: exit=$patches_exit"
  echo -e "    propagate-if-changed:   exit=$propagate_exit"
  exit 1
fi
