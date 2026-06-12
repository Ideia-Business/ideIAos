#!/usr/bin/env bash
# =============================================================================
# apply-to-all-projects.sh — propaga setup.sh --project-only a todos os repos ~/dev/
#
# Detecta repositórios git em ~/dev/* (1 nível de profundidade — não recursivo).
# Exclui o próprio IdeiaOS e diretórios sem .git.
# Dry-run por padrão: lista sem executar. Sem a flag: executa em cada repo.
#
# Uso:
#   bash scripts/apply-to-all-projects.sh                 # dry-run (seguro)
#   bash scripts/apply-to-all-projects.sh --apply         # executa em todos
#   bash scripts/apply-to-all-projects.sh --apply --only nfideia,lapidai  # filtro
#
# Exit: 0 se tudo OK; 1 se qualquer repo falhou (modo --apply).
# SOURCE: IdeiaOS v2
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_DIR="${DEV_DIR:-$HOME/dev}"
DRY_RUN=1
ONLY_FILTER=""

i=1
while [ "$i" -le "$#" ]; do
  eval "arg=\${$i}"
  case "$arg" in
    --apply) DRY_RUN=0 ;;
    --dry-run) DRY_RUN=1 ;;
    --only)
      i=$((i+1))
      eval "ONLY_FILTER=\${$i:-}"
      ;;
  esac
  i=$((i+1))
done

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
skip() { echo -e "${CYAN}  ⊙${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }

# Coletar repos elegíveis
REPOS=()
for d in "$DEV_DIR"/*/; do
  [ -d "$d/.git" ] || continue
  real_d="$(realpath "$d" 2>/dev/null || echo "$d")"
  real_setup="$(realpath "$SETUP_DIR" 2>/dev/null || echo "$SETUP_DIR")"
  [ "$real_d" = "$real_setup" ] && continue
  name="$(basename "$d")"
  if [ -n "$ONLY_FILTER" ]; then
    [[ ",$ONLY_FILTER," == *",$name,"* ]] || continue
  fi
  REPOS+=("$d")
done

COUNT="${#REPOS[@]}"

if [ "$DRY_RUN" -eq 1 ]; then
  echo -e "\n${CYAN}${BOLD}Projetos detectados em $DEV_DIR (dry-run — use --apply para executar):${NC}"
  for d in "${REPOS[@]}"; do
    skip "$(basename "$d")  →  $d"
  done
  echo ""
  echo "$COUNT projeto(s) detectado(s). Rode com --apply para executar."
  exit 0
fi

# Modo --apply
ERRORS=0
echo -e "\n${CYAN}${BOLD}Aplicando setup.sh --project-only em $COUNT projeto(s):${NC}"
for d in "${REPOS[@]}"; do
  name="$(basename "$d")"
  ok "Aplicando setup.sh --project-only em $name..."
  if bash "$SETUP_DIR/setup.sh" --project-only "$d"; then
    ok "$name OK"
  else
    warn "$name terminou com erro (ver acima)"
    ERRORS=$((ERRORS+1))
  fi
done
echo ""
echo "$COUNT projeto(s) processado(s). Erros: $ERRORS."
[ "$ERRORS" -gt 0 ] && exit 1 || exit 0
