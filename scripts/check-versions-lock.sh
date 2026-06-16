#!/usr/bin/env bash
# =============================================================================
# check-versions-lock.sh — guarda ativa do versions.lock contra reverts do pin GSD.
#
# CONTEXTO (incidente 2026-06-05 → 2026-06-11, pin revertido 3×):
#   O GSD migrou de `get-shit-done-cc` (versões 1.36–1.42, "pré-redux") para
#   `@opengsd/get-shit-done-redux`, cujo versionamento RECOMEÇOU em 1.x.
#   Logo, 1.1.0 (redux) é MAIS NOVO que 1.36.0 (pré-redux). Essa armadilha de
#   semver fez `--bump` em máquina com instalação desatualizada — e um agente
#   de IA "corrigindo" o drift na mão — reverterem o pin repetidamente
#   (commits c7fc184 e 3724ee9). Barreira ativa > documentação passiva.
#   LINHAGEM: @opengsd/get-shit-done-redux 1.x (org opengsd) — NAO e gsd-pi.
#
# VALIDAÇÕES:
#   1. Anti-legado pre-redux (sempre): gsd= nao pode ser versao pre-redux
#      (1.30–1.99). Versoes 1.36–1.42 = get-shit-done-cc = linha morta.
#   2. Anti-Pi-drift (sempre): gsd= nao pode ser versao gsd-pi (2.x/3.x).
#      gsd-pi e um produto DIFERENTE da org diferente — incompativel com o
#      redux que o IdeiaOS usa (@opengsd/get-shit-done-redux, linha 1.x).
#   3. Anti-edicao-manual (so --staged): se a linha gsd= mudou neste commit,
#      o novo valor deve ser igual a versao instalada
#      (~/.claude/get-shit-done/VERSION). Unico escritor sancionado:
#      scripts/update-upstream.sh --bump.
#      Bypass consciente: IDEIAOS_LOCK_OVERRIDE=1 git commit ...
#
# NOTA DE OBSOLESCÊNCIA: remover o padrão anti-legado quando o redux se
#   aproximar da versão 1.30 (anos) ou quando nenhuma máquina/árvore antiga
#   carregar mais o valor pré-redux.
#
# USO:
#   bash scripts/check-versions-lock.sh            # valida o working tree
#   bash scripts/check-versions-lock.sh --staged   # valida o index (pre-commit)
#
# Exit: 0 = ok · 1 = violação
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

get_gsd() { printf '%s\n' "$1" | grep -m1 '^gsd=' | cut -d= -f2- | tr -d ' '; }

# Versões pré-redux conhecidas: 1.36.0 … 1.42.x. Guarda: 1.30–1.99.
is_legacy_gsd() {
  case "$1" in
    1.3[0-9]|1.3[0-9].*|1.4[0-9]|1.4[0-9].*|1.[5-9][0-9]|1.[5-9][0-9].*) return 0 ;;
  esac
  return 1
}

# gsd-pi (2.x / 3.x e superiores) e um produto DIFERENTE do redux.
# @opengsd/get-shit-done-redux usa linha 1.x. Pin 2.x/3.x = Pi-drift = ERRADO aqui.
is_gsd_pi() {
  case "$1" in
    2.*|3.*|[4-9]*) return 0 ;;
  esac
  return 1
}

if [ "$MODE" = "--staged" ]; then
  CONTENT="$(git -C "$REPO_DIR" show :versions.lock 2>/dev/null)" || exit 0
  OLD_CONTENT="$(git -C "$REPO_DIR" show HEAD:versions.lock 2>/dev/null || true)"
else
  [ -f "$REPO_DIR/versions.lock" ] || exit 0
  CONTENT="$(cat "$REPO_DIR/versions.lock")"
  OLD_CONTENT=""
fi

NEW_GSD="$(get_gsd "$CONTENT")"
[ -z "$NEW_GSD" ] && exit 0

# ── 1) Anti-legado: valor pré-redux nunca pode entrar ────────────────────────
if is_legacy_gsd "$NEW_GSD"; then
  echo -e "${RED}❌ versions.lock: gsd=$NEW_GSD é versão PRÉ-REDUX (legado).${NC}"
  echo ""
  echo "   O GSD migrou para @opengsd/get-shit-done-redux e o versionamento"
  echo "   RECOMEÇOU em 1.x — 1.1.0 (redux) é MAIS NOVO que $NEW_GSD (pré-redux)."
  echo ""
  echo "   Se a SUA máquina tem GSD $NEW_GSD instalado, ela está desatualizada:"
  echo "   atualize o plugin GSD pelo Claude Code antes de mexer no pin."
  echo "   NUNCA 'corrija' o pin para um valor 1.3x/1.4x."
  exit 1
fi

# ── 2) Anti-Pi-drift: versão gsd-pi (2.x/3.x) é produto diferente ────────────
if is_gsd_pi "$NEW_GSD"; then
  echo -e "${RED}❌ versions.lock: gsd=$NEW_GSD parece ser gsd-pi (linha 2.x/3.x).${NC}"
  echo ""
  echo "   O IdeiaOS usa @opengsd/get-shit-done-redux (linha 1.x, org opengsd)."
  echo "   gsd-pi é um produto DIFERENTE de org diferente — incompatível com o redux."
  echo ""
  echo "   Verifique ~/.claude/get-shit-done/VERSION e rode --bump somente em"
  echo "   máquina com @opengsd/get-shit-done-redux instalado (linha 1.x)."
  echo "   NUNCA coloque um pin 2.x/3.x aqui — isso é Pi-drift, não redux."
  exit 1
fi

# ── 3) Anti-edição-manual: mudança no pin deve refletir a instalação ─────────
if [ "$MODE" = "--staged" ] && [ -n "$OLD_CONTENT" ]; then
  OLD_GSD="$(get_gsd "$OLD_CONTENT")"
  if [ "$NEW_GSD" != "$OLD_GSD" ] && [ "${IDEIAOS_LOCK_OVERRIDE:-0}" != "1" ]; then
    VFILE="$HOME/.claude/get-shit-done/VERSION"
    if [ -f "$VFILE" ]; then
      INSTALLED="$(tr -d ' \n' < "$VFILE")"
      if [ "$NEW_GSD" != "$INSTALLED" ]; then
        echo -e "${RED}❌ versions.lock: pin gsd mudou ($OLD_GSD → $NEW_GSD) mas a versão${NC}"
        echo -e "${RED}   instalada nesta máquina é $INSTALLED.${NC}"
        echo ""
        echo "   Único escritor sancionado do pin: scripts/update-upstream.sh --bump"
        echo "   (grava a versão instalada). Não edite a linha gsd= manualmente."
        echo ""
        echo -e "   Divergência intencional? ${YELLOW}IDEIAOS_LOCK_OVERRIDE=1 git commit ...${NC}"
        exit 1
      fi
    fi
  fi
fi

echo -e "${GREEN}✅ versions.lock: pin gsd=$NEW_GSD válido${NC}"
exit 0
