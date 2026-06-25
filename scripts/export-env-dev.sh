#!/usr/bin/env bash
# =============================================================================
# export-env-dev.sh — extrai o .env MÍNIMO de dev (least-privilege) por projeto
#
# Monta, a partir dos seus .env locais, os blocos prontos para entregar a um dev
# NOVO — só as chaves que um dev de frontend/app precisa. OMITE por padrão as
# chaves de alto risco (SERVICE_ROLE_KEY) e tokens de deploy/automação
# (Vercel/Railway/GitHub/N8N/ClickUp). Ver docs/guides/env-setup-dev.md.
#
# ⚠️ SEGURANÇA: o output contém SEGREDOS reais (lidos dos seus .env). Rode NA SUA
# máquina e entregue o resultado por CANAL SEGURO (1Password/Bitwarden ou
# onetimesecret.com) — NUNCA cole em chat/e-mail/IA. Este script é o único lugar
# onde os valores são tocados: o IdeiaOS (e qualquer IA) nunca lê seus .env.
#
# Uso:
#   bash scripts/export-env-dev.sh                 # todos os projetos (com valores)
#   bash scripts/export-env-dev.sh nfideia         # só um projeto
#   bash scripts/export-env-dev.sh --keys-only     # só os NOMES das chaves (sem valores)
#   bash scripts/export-env-dev.sh --list          # lista os projetos configurados
#   IDEIAOS_DEV_ROOT=/caminho bash scripts/export-env-dev.sh   # raiz dev != ~/dev
#
# Estender (novo projeto): adicione 1 linha em PROJECTS abaixo ("nome:CHAVE|CHAVE").
# Bash 3.2 compat (macOS). Read-only — nunca escreve nem commita nada.
# =============================================================================
set -euo pipefail

DEV_ROOT="${IDEIAOS_DEV_ROOT:-$HOME/dev}"

# Config "dinâmica": projeto:CHAVE|CHAVE|... — o conjunto MÍNIMO de dev por projeto.
# Estender é trivial — uma linha por projeto novo. Fonte de verdade legível:
# docs/guides/env-setup-dev.md (mantenha os dois em sincronia).
PROJECTS=(
  "lapidai:VITE_SUPABASE_URL|VITE_SUPABASE_PROJECT_ID|VITE_SUPABASE_PUBLISHABLE_KEY"
  "ideiapartner:VITE_SUPABASE_URL|VITE_SUPABASE_PROJECT_ID|VITE_SUPABASE_PUBLISHABLE_KEY|SUPABASE_URL|SUPABASE_ANON_KEY"
  "nfideia:NODE_ENV|AIOX_VERSION|SUPABASE_URL|SUPABASE_ANON_KEY|OPENROUTER_API_KEY"
)

YELLOW='\033[1;33m'; CYAN='\033[0;36m'; RED='\033[0;31m'; DIM='\033[2m'; NC='\033[0m'

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

list_projects() {
  echo "Projetos configurados (em scripts/export-env-dev.sh → PROJECTS):"
  for entry in "${PROJECTS[@]}"; do
    name="${entry%%:*}"; keys="${entry#*:}"
    printf "  %-16s %s\n" "$name" "$(echo "$keys" | tr '|' ' ')"
  done
  exit 0
}

KEYS_ONLY=0
FILTER=""
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)   usage ;;
    --list)      list_projects ;;
    --keys-only) KEYS_ONLY=1; shift ;;
    -*)          echo "flag desconhecida: $1" >&2; exit 2 ;;
    *)           FILTER="$1"; shift ;;
  esac
done

if [ "$KEYS_ONLY" -eq 0 ]; then
  printf "${RED}⚠️  Este output contém SEGREDOS reais. Entregue por canal seguro${NC}\n"
  printf "${RED}   (1Password/Bitwarden/onetimesecret) — NUNCA cole em chat/e-mail/IA.${NC}\n"
fi

found=0
for entry in "${PROJECTS[@]}"; do
  name="${entry%%:*}"; keys="${entry#*:}"
  [ -n "$FILTER" ] && [ "$FILTER" != "$name" ] && continue
  found=1
  envf="$DEV_ROOT/$name/.env"
  printf "\n${CYAN}########## %s  (%s) ##########${NC}\n" "$name" "$envf"

  if [ "$KEYS_ONLY" -eq 1 ]; then
    echo "$keys" | tr '|' '\n' | sed 's/$/=/'
    continue
  fi

  if [ ! -f "$envf" ]; then
    printf "${YELLOW}  ⚠ .env não encontrado em %s${NC}\n" "$envf"
    echo "$keys" | tr '|' '\n' | sed 's/$/=/'
    continue
  fi

  OLD_IFS="$IFS"; IFS='|'
  for k in $keys; do
    line="$(grep -E "^${k}=" "$envf" 2>/dev/null | head -1 || true)"
    if [ -n "$line" ]; then
      echo "$line"
    else
      printf "%s=   ${DIM}# ⚠ ausente no .env local — preencha à mão${NC}\n" "$k"
    fi
  done
  IFS="$OLD_IFS"
done

if [ "$found" -eq 0 ]; then
  printf "${RED}Projeto '%s' não está configurado.${NC} Rode com --list para ver os disponíveis.\n" "$FILTER" >&2
  exit 1
fi

if [ "$KEYS_ONLY" -eq 0 ]; then
  printf "\n${DIM}Omitido por least-privilege: SERVICE_ROLE_KEY + tokens de deploy/automação.${NC}\n"
  printf "${DIM}O dev cria cada bloco dentro do WSL: cd ~/dev/<projeto> && nano .env${NC}\n"
fi
