#!/usr/bin/env bash
# =============================================================================
# update-design-suite.sh — atualização CONTROLADA da Suíte de Design vendorizada
#
# Fonte ÚNICA: github.com/nextlevelbuilder/ui-ux-pro-max-skill  (.claude/skills/*)
# As 7 skills (ui-ux-pro-max + design/design-system/ui-styling/brand/banner-design/
# slides) são vendorizadas em skills/. Este script as re-vendoriza do upstream.
#
# NÃO é automático: clona o upstream no ref pedido, re-copia, mostra o diff e
# deixa VOCÊ revisar + commitar. O overlay OKLCH (Patch 7) é re-aplicado depois
# pelo sync-all.sh / install-global-patches.sh — não precisa mexer à mão.
#
# Uso:
#   bash scripts/update-design-suite.sh            # usa ref pinado (.design-suite-version) ou main
#   bash scripts/update-design-suite.sh v2.5.0     # ref específico (tag / branch / commit)
#
# Idempotente: se o upstream não mudou no ref, o diff sai vazio.
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$SETUP_DIR/source/skills"
PIN_FILE="$SETUP_DIR/source/skills/.design-suite-version"
REPO="https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git"
SUITE="ui-ux-pro-max design design-system ui-styling brand banner-design slides"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
die()  { err "$*"; exit 1; }

# Ref: arg > pin file > main
REF="${1:-}"
if [ -z "$REF" ] && [ -f "$PIN_FILE" ]; then
  REF="$(grep -m1 '^ref=' "$PIN_FILE" 2>/dev/null | cut -d= -f2)"
fi
REF="${REF:-main}"

echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo    "║   IdeiaOS — update-design-suite.sh (controlado)         ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "  Upstream : ${BOLD}$REPO${NC}"
echo -e "  Ref      : ${BOLD}$REF${NC}"

command -v git >/dev/null 2>&1 || die "git não encontrado"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo -e "\n${CYAN}${BOLD}━━━ Clonando upstream ($REF) ━━━${NC}"
# Tenta shallow no ref (tag/branch); se falhar (ex: commit sha), clona full + checkout.
if git clone --quiet --depth 1 --branch "$REF" "$REPO" "$TMP/up" 2>/dev/null; then
  ok "clone shallow @ $REF"
else
  git clone --quiet "$REPO" "$TMP/up" || die "falha ao clonar $REPO"
  git -C "$TMP/up" checkout --quiet "$REF" || die "ref inválido: $REF"
  ok "clone full + checkout $REF"
fi

SRC="$TMP/up/.claude/skills"
[ -d "$SRC" ] || die "estrutura inesperada — '$SRC' não existe (upstream mudou de layout?)"

echo -e "\n${CYAN}${BOLD}━━━ Re-vendorizando 7 skills ━━━${NC}"
MISSING=0
for s in $SUITE; do
  if [ -d "$SRC/$s" ]; then
    rm -rf "${SKILLS_DIR:?}/$s"
    cp -R "$SRC/$s" "$SKILLS_DIR/$s"
    ok "re-vendorizado: $s"
  else
    warn "ausente no upstream ($REF): $s — mantida a versão atual"
    MISSING=$((MISSING+1))
  fi
done

# Registra o pin
COMMIT="$(git -C "$TMP/up" rev-parse --short HEAD 2>/dev/null || echo '?')"
{
  echo "# Suíte de Design vendorizada — pin de origem (update-design-suite.sh)"
  echo "repo=$REPO"
  echo "ref=$REF"
  echo "commit=$COMMIT"
  echo "updated=$(date +%F)"
} > "$PIN_FILE"
ok "pin gravado: $PIN_FILE (ref=$REF commit=$COMMIT)"

echo -e "\n${CYAN}${BOLD}━━━ Diff (skills/) ━━━${NC}"
if git -C "$SETUP_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  if git -C "$SETUP_DIR" diff --quiet -- source/skills/; then
    echo -e "  ${GREEN}Nenhuma mudança — já estava na versão de $REF${NC}"
  else
    git -C "$SETUP_DIR" diff --stat -- source/skills/ | tail -25
    echo
    echo -e "  ${YELLOW}${BOLD}AÇÃO MANUAL:${NC} revise o diff acima."
    echo -e "  • O overlay OKLCH (Patch 7) será re-aplicado por: ${BOLD}bash scripts/sync-all.sh${NC}"
    echo -e "  • Quando aprovar: ${BOLD}git add source/skills/ && git commit -m 'chore(design): bump suite → $REF ($COMMIT)'${NC}"
  fi
else
  warn "IdeiaOS não é repo git aqui — pulei o diff"
fi

[ "$MISSING" -gt 0 ] && warn "$MISSING skill(s) não vieram do upstream nesse ref — confira o layout do repo"
exit 0
