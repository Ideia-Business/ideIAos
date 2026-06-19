#!/usr/bin/env bash
# SOURCE: IdeiaOS v11
# =============================================================================
# check-source-headers.sh — guarda de PROVENIÊNCIA das skills (ADVISORY/WARN)
#
# Toda skill em source/skills/*/SKILL.md DEVE declarar sua origem com uma linha
# `# SOURCE:` (após o frontmatter). Convenção:
#   • absorvida:  `# SOURCE: <upstream> <licença> | adapted: IdeiaOS vN`
#   • nativa:     `# SOURCE: IdeiaOS [vN]`
#   • vendorizada (Suíte de Design): proveniência vive no pin
#     source/skills/.design-suite-version — NÃO inline (cp -R do
#     update-design-suite.sh sobrescreveria qualquer header inline).
#
# Por isso as skills da Suíte são tratadas como OK-via-pin: o guard deriva a
# lista de skills vendorizadas do PRÓPRIO update-design-suite.sh (linha SUITE=),
# evitando duplicar a lista (anti-deriva declarativo×imperativo).
#
# Severidade: ADVISORY. Exit 0 por padrão (não bloqueia push/commit/CI).
#   --strict → exit 1 se alguma skill NÃO-vendorizada estiver sem `# SOURCE:`.
#
# Uso:
#   bash scripts/check-source-headers.sh            # WARN, exit 0
#   bash scripts/check-source-headers.sh --strict   # WARN, exit 1 se faltar
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/source/skills"
DESIGN_SCRIPT="$ROOT/scripts/update-design-suite.sh"
PIN_FILE="$ROOT/source/skills/.design-suite-version"
MODE="${1:-}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

[ -d "$SKILLS_DIR" ] || { echo "ERRO: $SKILLS_DIR não existe" >&2; exit 2; }

# Lista vendorizada = única fonte de verdade: a linha SUITE= do update-design-suite.sh.
VENDORED=""
if [ -f "$DESIGN_SCRIPT" ]; then
  VENDORED="$(grep -m1 '^SUITE=' "$DESIGN_SCRIPT" 2>/dev/null | sed -E 's/^SUITE=//; s/"//g')"
fi
is_vendored() {
  case " $VENDORED " in *" $1 "*) return 0 ;; esac
  return 1
}

echo -e "\n${CYAN}${BOLD}━━━ Proveniência de skills (# SOURCE:) ━━━${NC}"
[ -n "$VENDORED" ] && info "vendorizadas (proveniência via pin): $VENDORED" \
                   || warn "não consegui derivar SUITE= de update-design-suite.sh — todas tratadas como autorais"

OK=0; PIN=0; MISS=0; MISSING_LIST=""
for d in "$SKILLS_DIR"/*/; do
  s="$(basename "$d")"
  f="$d/SKILL.md"
  [ -f "$f" ] || continue
  if grep -q '# SOURCE:' "$f" 2>/dev/null; then
    OK=$((OK+1))
  elif is_vendored "$s"; then
    PIN=$((PIN+1))   # proveniência via .design-suite-version — header inline seria apagado no re-vendor
  else
    MISS=$((MISS+1)); MISSING_LIST="$MISSING_LIST $s"
    warn "skill SEM '# SOURCE:': /$s — adicione após o frontmatter (ex.: '# SOURCE: IdeiaOS vN')"
  fi
done

[ "$PIN" -gt 0 ] && info "$PIN skill(s) vendorizada(s) sem header inline — OK (pin: $(basename "$PIN_FILE"))"
echo -e "  ${GREEN}com SOURCE:${NC} $OK   ${CYAN}vendorizadas-via-pin:${NC} $PIN   ${YELLOW}sem SOURCE:${NC} $MISS"

if [ "$MISS" -gt 0 ]; then
  if [ "$MODE" = "--strict" ]; then
    echo -e "  ${YELLOW}--strict: falhando por$MISSING_LIST${NC}" >&2
    exit 1
  fi
  echo -e "  ${YELLOW}(advisory — não bloqueia. Use --strict p/ gate)${NC}"
fi
exit 0
