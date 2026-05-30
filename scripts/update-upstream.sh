#!/usr/bin/env bash
# =============================================================================
# update-upstream.sh — atualiza componentes upstream (GSD plugin + AIOX-core)
#
# Detecta versões instaladas, verifica se há atualizações, e aplica.
# **Atenção:** atualizações upstream SOBRESCREVEM arquivos modificados pelos
# patches IdeiaOS. Após este script, rode `install-global-patches.sh` para
# re-aplicar overlay (ou use `sync-all.sh` que faz isso automaticamente).
#
# Componentes monitorados:
#   1. GSD plugin    (via Claude Code marketplace ou diretamente em ~/.claude/skills/)
#   2. AIOX-core CLI (via npm/npx)
#
# Uso:
#   bash scripts/update-upstream.sh
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Cores ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

UPDATED=0
UP_TO_DATE=0
SKIPPED=0

# ── Localizador AIOX-core ────────────────────────────────────────────────────
find_aiox_core() {
  local candidates=(
    "$(dirname "$SETUP_DIR")/.aiox-core"
    "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/.aiox-core"
    "$HOME/Projects/.aiox-core"
  )
  for c in "${candidates[@]}"; do
    [ -d "$c/development/agents" ] && { echo "$c"; return 0; }
  done
  return 1
}

# ── GSD plugin ───────────────────────────────────────────────────────────────
# GSD vem com Claude Code via plugins. Não há comando direto de update —
# o user habilita/atualiza pelo menu de plugins do Claude Code. Aqui apenas
# detectamos a versão instalada e alertamos.
check_gsd_plugin() {
  local skills_dir="$HOME/.claude/skills"
  local gsd_count
  gsd_count=$(ls -d "$skills_dir"/gsd-* 2>/dev/null | wc -l | tr -d ' ')

  if [ "$gsd_count" = "0" ]; then
    warn "GSD plugin não detectado em $skills_dir/gsd-*"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  info "GSD plugin: ${gsd_count} skills instaladas em $skills_dir/gsd-*"

  # Tenta extrair versão do plugin manifest se existir
  local manifest="$HOME/.claude/get-shit-done/manifest.json"
  if [ -f "$manifest" ]; then
    local version
    version=$(python3 -c "import json; print(json.load(open('$manifest')).get('version','?'))" 2>/dev/null || echo "?")
    info "Versão detectada: $version"
  fi

  info "Para atualizar: use o menu de plugins do Claude Code (não há CLI direta)"
  info "Após update, rode install-global-patches.sh para re-aplicar overlay"
  UP_TO_DATE=$((UP_TO_DATE+1))
}

# ── AIOX-core ────────────────────────────────────────────────────────────────
check_aiox_core() {
  local aiox_root
  aiox_root="$(find_aiox_core)" || {
    warn "AIOX-core não detectado nos caminhos padrão"
    SKIPPED=$((SKIPPED+1))
    return 0
  }

  info "AIOX-core encontrado em: $aiox_root"

  # Versão instalada via package.json
  local installed=""
  if [ -f "$aiox_root/package.json" ]; then
    installed=$(python3 -c "import json; print(json.load(open('$aiox_root/package.json')).get('version','?'))" 2>/dev/null || echo "?")
    info "Versão instalada: $installed"
  fi

  # Versão do CLI aiox-core
  local cli_version=""
  if command -v aiox-core >/dev/null 2>&1; then
    cli_version=$(aiox-core --version 2>/dev/null | head -1 || echo "?")
    info "CLI aiox-core: $cli_version"
  else
    warn "CLI 'aiox-core' não encontrado no PATH"
  fi

  # Checar versão remota via npm (se possível)
  if command -v npm >/dev/null 2>&1; then
    local latest
    latest=$(npm view @aiox-fullstack/core version 2>/dev/null || echo "")
    if [ -n "$latest" ] && [ "$latest" != "$installed" ]; then
      warn "Nova versão do AIOX-core disponível: $installed → $latest"
      info "Para atualizar: aiox-core update (ou: aiox-core install --version $latest)"
      info "Após update, rode install-global-patches.sh para re-aplicar overlay"
      UPDATED=$((UPDATED+1))  # marca como "tem update"; aplicação fica para o user
    elif [ -n "$latest" ]; then
      ok "AIOX-core já está na última versão ($installed)"
      UP_TO_DATE=$((UP_TO_DATE+1))
    else
      warn "Não foi possível verificar a versão remota do AIOX-core"
      SKIPPED=$((SKIPPED+1))
    fi
  else
    warn "npm não disponível — não foi possível checar versão remota"
    SKIPPED=$((SKIPPED+1))
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo    "║         IdeiaOS — update-upstream.sh                    ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"

step "1) GSD plugin (Claude Code marketplace)"
check_gsd_plugin

step "2) AIOX-core (npm: @aiox-fullstack/core)"
check_aiox_core

echo -e "\n${CYAN}${BOLD}━━━ Resumo ━━━${NC}"
echo -e "  ${YELLOW}Updates disponíveis:${NC} $UPDATED"
echo -e "  ${GREEN}Já na última versão:${NC} $UP_TO_DATE"
echo -e "  ${CYAN}Não verificados:${NC} $SKIPPED"

if [ "$UPDATED" -gt 0 ]; then
  echo -e "\n${YELLOW}⚠ Updates disponíveis — após aplicar, rode:${NC}"
  echo "    bash scripts/install-global-patches.sh"
  echo -e "  ${CYAN}Ou rode tudo de uma vez:${NC}"
  echo "    bash scripts/sync-all.sh"
fi

exit 0
