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
LOCK="$SETUP_DIR/versions.lock"

# --bump: grava as versões INSTALADAS no versions.lock (re-pin após aceitar update)
BUMP=0
[ "${1:-}" = "--bump" ] && BUMP=1

# Lê um valor do versions.lock (chave=valor)
read_lock() { [ -f "$LOCK" ] && grep -m1 "^$1=" "$LOCK" 2>/dev/null | cut -d= -f2- || true; }

# GSD pré-redux (get-shit-done-cc, 1.36–1.42) vs redux (@opengsd/…, recomeçou em 1.x):
# 1.1.0 (redux) é MAIS NOVO que 1.36.0 (pré-redux). Guarda: 1.30–1.99 = legado.
# Ver scripts/check-versions-lock.sh (mesma regra, enforçada no pre-commit).
is_legacy_gsd() {
  case "$1" in
    1.3[0-9]|1.3[0-9].*|1.4[0-9]|1.4[0-9].*|1.[5-9][0-9]|1.[5-9][0-9].*) return 0 ;;
  esac
  return 1
}
AIOX_PIN="$(read_lock aiox-core)"
GSD_PIN="$(read_lock gsd)"
GSD_INSTALLED=""
AIOX_INSTALLED=""

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

  # Versão do GSD: arquivo VERSION em ~/.claude/get-shit-done/
  local gsd_version_file="$HOME/.claude/get-shit-done/VERSION"
  if [ -f "$gsd_version_file" ]; then
    GSD_INSTALLED="$(tr -d ' \n' < "$gsd_version_file")"
    info "Versão GSD: $GSD_INSTALLED (pin: ${GSD_PIN:-—})"
    if [ -n "${GSD_PIN:-}" ] && [ "$GSD_INSTALLED" != "$GSD_PIN" ]; then
      # Mensagem direcional: dizer QUAL lado está errado (a ambiguidade do aviso
      # genérico causou reverts do pin em 2026-06 — ver check-versions-lock.sh).
      if is_legacy_gsd "$GSD_INSTALLED"; then
        warn "GSD INSTALADO é PRÉ-REDUX ($GSD_INSTALLED) — esta máquina está desatualizada."
        warn "Atualize o plugin GSD pelo Claude Code. NÃO rode --bump nesta máquina."
      elif is_legacy_gsd "$GSD_PIN"; then
        warn "PIN LEGADO pré-redux ($GSD_PIN) no versions.lock — o instalado $GSD_INSTALLED (redux) é MAIS NOVO."
        warn "Corrija com: bash scripts/update-upstream.sh --bump (e commit). Nunca edite o pin na mão."
      else
        warn "DRIFT GSD: instalado $GSD_INSTALLED ≠ pin $GSD_PIN (versions.lock) — re-pin com --bump se intencional"
      fi
    fi
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
    info "Versão (package.json .aiox-core): $installed"
  fi
  # Fonte de verdade do pin = INSTALAÇÃO (.aiox-core/package.json), pois é ela que
  # define o comportamento. O CLI global pode ficar defasado (exige sudo para
  # atualizar) e não deve mascarar a versão real. Fallback: CLI.
  if [ -n "$installed" ] && [ "$installed" != "?" ]; then
    AIOX_INSTALLED="$installed"
  else
    AIOX_INSTALLED="$( (aiox --version 2>/dev/null || aiox-core --version 2>/dev/null) | head -1 )"
  fi
  if [ -n "$AIOX_INSTALLED" ]; then
    info "Versão (.aiox-core): $AIOX_INSTALLED (pin: ${AIOX_PIN:-—})"
    if [ -n "${AIOX_PIN:-}" ] && [ "$AIOX_INSTALLED" != "$AIOX_PIN" ]; then
      warn "DRIFT AIOX: instalação $AIOX_INSTALLED ≠ pin $AIOX_PIN (versions.lock) — re-pin com --bump se intencional"
    fi
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
    latest=$(npm view aiox-core version 2>/dev/null || echo "")
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

# ── --bump: re-pin versions.lock com as versões INSTALADAS ────────────────────
if [ "$BUMP" = 1 ] && [ -f "$LOCK" ]; then
  step "--bump: gravando versões instaladas em versions.lock"
  [ -n "$AIOX_INSTALLED" ] && sed -i.bak "s/^aiox-core=.*/aiox-core=$AIOX_INSTALLED/" "$LOCK"
  # Guarda anti-revert: nunca gravar versão GSD pré-redux no pin. Foi exatamente
  # isso (--bump em máquina com instalação stale) que reverteu o pin 2× em 2026-06.
  if [ -n "$GSD_INSTALLED" ]; then
    if is_legacy_gsd "$GSD_INSTALLED"; then
      err "RECUSADO: gsd=$GSD_INSTALLED é PRÉ-REDUX (legado) — pin não alterado."
      echo "    Atualize o plugin GSD desta máquina (redux, 1.x) e rode --bump de novo."
    else
      sed -i.bak "s/^gsd=.*/gsd=$GSD_INSTALLED/" "$LOCK"
    fi
  fi
  sed -i.bak "s/^updated=.*/updated=$(date +%F)/" "$LOCK"
  rm -f "$LOCK.bak"
  ok "versions.lock re-pinado: aiox-core=${AIOX_INSTALLED:-?} gsd=$(read_lock gsd)"
  echo "    Commit o versions.lock para propagar o pin às outras máquinas."
fi

exit 0
