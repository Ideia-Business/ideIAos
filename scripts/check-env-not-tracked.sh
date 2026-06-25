#!/usr/bin/env bash
# =============================================================================
# check-env-not-tracked.sh — detecta .env VERSIONADO em repos (anti-segredo-no-git)
#
# Variáveis de ambiente nunca devem ser commitadas. Este gate varre os repos e
# reporta qualquer `.env` real (não `.example`/`.sample`) que esteja TRACKED no
# git — agora OU no histórico. Read-only e seguro: NUNCA lê valores, só metadados
# do git (ls-files / log). Origem: incidente 2026-06-25 (.env versionado em
# ideiapartner/nfideia/lapidai, achado no onboarding de dev novo).
#
# Uso:
#   bash scripts/check-env-not-tracked.sh                 # varre ~/dev/* (exceto IdeiaOS)
#   bash scripts/check-env-not-tracked.sh ~/dev/nfideia   # repos específicos
#   IDEIAOS_DEV_ROOT=/caminho bash scripts/check-env-not-tracked.sh
#
# Exit: 0 = nenhum .env tracked agora · 1 = .env tracked AGORA (gate falha).
# Histórico é reportado como WARN (não falha — remediação é rotação/decisão).
# =============================================================================
set -uo pipefail

DEV_ROOT="${IDEIAOS_DEV_ROOT:-$HOME/dev}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# Alvos: args explícitos, ou todo git repo em $DEV_ROOT exceto o próprio IdeiaOS.
TARGETS=()
if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  for d in "$DEV_ROOT"/*/; do
    [ -d "$d/.git" ] || continue
    case "$(basename "$d")" in IdeiaOS|ideIAos) continue ;; esac
    TARGETS+=("${d%/}")
  done
fi

ENV_GLOB='(^|/)\.env'
ENV_NOT='\.(example|sample|template|e2e)$'

fail=0
echo -e "${CYAN}== .env versionado? (read-only — nunca lê valores) ==${NC}"
for d in "${TARGETS[@]}"; do
  [ -d "$d/.git" ] || { echo -e "  ${YELLOW}skip${NC} $d (sem .git)"; continue; }
  name="$(basename "$d")"

  tracked="$(git -C "$d" ls-files 2>/dev/null | grep -E "$ENV_GLOB" | grep -vE "$ENV_NOT" || true)"
  hist="$(git -C "$d" log --all --oneline -- '.env' '.env.local' '.env.production' 2>/dev/null | wc -l | tr -d ' ')"

  if [ -n "$tracked" ]; then
    echo -e "  ${RED}🔴 $name${NC}: .env VERSIONADO agora → $(echo "$tracked" | tr '\n' ' ')"
    echo -e "     fix: branch + PR \`git rm --cached <arquivo>\` (Lovable: nunca direto na main); garanta o .gitignore."
    fail=1
  elif [ "$hist" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ $name${NC}: .env já fora do tracking, mas em ${hist} commit(s) do histórico (avalie rotação)"
  else
    echo -e "  ${GREEN}✓ $name${NC}: nenhum .env versionado"
  fi
done

if [ "$fail" -eq 0 ]; then
  echo -e "${GREEN}OK — nenhum .env versionado no estado atual.${NC}"
  exit 0
else
  echo -e "${RED}FALHA — há .env versionado. Remova do tracking (via PR em repos Lovable).${NC}"
  exit 1
fi
