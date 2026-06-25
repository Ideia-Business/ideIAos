#!/usr/bin/env bash
# =============================================================================
# check-env-not-tracked.sh — detecta SEGREDO em .env VERSIONADO (anti-segredo-no-git)
#
# Variáveis de ambiente sensíveis nunca devem ser commitadas. Este gate varre os
# repos e FALHA (exit 1) só quando um `.env` versionado contém um nome de chave
# claramente SECRETO (service_role / api_key / token / password / secret). Um
# `.env` com só config/chaves públicas (HOST_NAME, MONGO_URL, VITE_*, anon/
# publishable) vira WARN (higiene), não falha. Read-only e seguro: NUNCA lê
# valores — só NOMES de chave (o pipe filtra antes de qualquer saída).
#
# Exclui por convenção: *.example/.sample/.template e fixtures de teste
# (.env.test/.env.e2e). Pule repos (forks de terceiros, ex. Rocket.Chat) via
# IDEIAOS_ENV_GATE_SKIP="repo1 repo2".
#
# Origem: incidente 2026-06-25 (.env versionado em ideiapartner/nfideia; o gate
# v1 falsava em fork Rocket.Chat e fixture E2E — refinado para nome-de-chave).
#
# Uso:
#   bash scripts/check-env-not-tracked.sh                 # varre ~/dev/* (exceto IdeiaOS)
#   bash scripts/check-env-not-tracked.sh ~/dev/nfideia   # repos específicos
#   IDEIAOS_DEV_ROOT=/caminho  IDEIAOS_ENV_GATE_SKIP="grupori-chat" bash ...
#
# Exit: 0 = nenhum segredo versionado · 1 = segredo versionado AGORA.
# =============================================================================
set -uo pipefail

DEV_ROOT="${IDEIAOS_DEV_ROOT:-$HOME/dev}"
SKIP="${IDEIAOS_ENV_GATE_SKIP:-}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; DIM='\033[2m'; NC='\033[0m'

ENV_GLOB='(^|/)\.env'
ENV_NOT='\.(example|sample|template|e2e|test)$'   # exemplos + fixtures de teste
# Nome de chave SECRETO (FAIL) … menos chaves comprovadamente públicas (config/anon).
SENS_INC='secret|token|password|passwd|service_role|credential|api[_-]?key|_key$|_pat$|private'
SENS_EXC='publishable|anon|public|^vite_|_url$|project_id|host_name'

# nomes de chave secretos de um blob .env (lista, 1 por linha; vazio se nenhum). NUNCA valores.
secret_keys() {  # $1=repo dir, $2=path no HEAD
  git -C "$1" show "HEAD:$2" 2>/dev/null \
    | grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' | sed 's/=$//' \
    | grep -iE "$SENS_INC" | grep -viE "$SENS_EXC" || true
}

TARGETS=()
if [ "$#" -gt 0 ]; then TARGETS=("$@"); else
  for d in "$DEV_ROOT"/*/; do
    [ -d "$d/.git" ] || continue
    case "$(basename "$d")" in IdeiaOS|ideIAos) continue ;; esac
    TARGETS+=("${d%/}")   # allowlist (IDEIAOS_ENV_GATE_SKIP) é aplicada no loop principal
  done
fi

fail=0
echo -e "${CYAN}== Segredo em .env versionado? (read-only — nunca lê valores) ==${NC}"
for d in "${TARGETS[@]}"; do
  [ -d "$d/.git" ] || { echo -e "  ${YELLOW}skip${NC} $d (sem .git)"; continue; }
  name="$(basename "$d")"
  case " $SKIP " in *" $name "*) echo -e "  ${DIM}skip $name (allowlist)${NC}"; continue ;; esac

  # .env reais tracked (exclui exemplos/fixtures)
  tracked="$(git -C "$d" ls-files 2>/dev/null | grep -E "$ENV_GLOB" | grep -vE "$ENV_NOT" || true)"
  worst=""   # "" ok | "warn" | "fail"
  detail=""
  if [ -n "$tracked" ]; then
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      sk="$(secret_keys "$d" "$f")"
      if [ -n "$sk" ]; then
        worst="fail"; detail+="    🔴 $f → chave(s) secreta(s): $(echo "$sk" | tr '\n' ' ')\n"
      else
        [ "$worst" = "fail" ] || worst="warn"; detail+="    ⚠ $f → versionado (só config/público — higiene)\n"
      fi
    done <<< "$tracked"
  fi

  # histórico com segredo (mesmo que já removido)
  histsens=""
  for c in $(git -C "$d" log --all --format='%H' -- '.env' '.env.local' '.env.production' 2>/dev/null); do
    s="$(secret_keys "$d" '.env' 2>/dev/null)"; [ -z "$s" ] && s="$(git -C "$d" show "$c:.env" 2>/dev/null | grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' | sed 's/=$//' | grep -iE "$SENS_INC" | grep -viE "$SENS_EXC" || true)"
    [ -n "$s" ] && { histsens="yes"; break; }
  done

  if [ "$worst" = "fail" ]; then
    echo -e "  ${RED}🔴 $name${NC}: SEGREDO em .env versionado"
    printf "%b" "$detail"
    echo -e "     fix: branch + PR \`git rm --cached <arquivo>\` (Lovable: nunca direto na main) + rotacionar."
    fail=1
  elif [ "$worst" = "warn" ]; then
    echo -e "  ${YELLOW}⚠ $name${NC}: .env versionado (só config/público)"; printf "%b" "$detail"
  elif [ -n "$histsens" ]; then
    echo -e "  ${YELLOW}⚠ $name${NC}: .env já fora do tracking, mas o histórico teve segredo (avalie rotação)"
  else
    echo -e "  ${GREEN}✓ $name${NC}: nenhum segredo versionado"
  fi
done

if [ "$fail" -eq 0 ]; then
  echo -e "${GREEN}OK — nenhum segredo versionado no estado atual.${NC}"; exit 0
else
  echo -e "${RED}FALHA — há segredo em .env versionado. Untrack (PR em repos Lovable) + rotacione.${NC}"; exit 1
fi
