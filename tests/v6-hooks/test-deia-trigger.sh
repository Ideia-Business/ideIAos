#!/usr/bin/env bash
# =============================================================================
# test-deia-trigger.sh — testa o hook deia-trigger.sh (UserPromptSubmit)
#
# Cobre:
#   1. Detecção de trigger para todas as variantes de Deia → additionalContext
#   2. Passagem sem modificação para prompts que NÃO começam com Deia
#   3. Edge cases: JSON malformado, prompt null, espaço à esquerda, empty
#
# Cria sandbox em /tmp — não toca o repo real.
# Uso:  bash tests/v6-hooks/test-deia-trigger.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_DIR/source/hooks/deia-trigger.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$HOOK" ] || { echo "Hook não encontrado: $HOOK"; exit 1; }

SANDBOX="$(mktemp -d /tmp/ideiaos-deia-trigger-test.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

# run_trigger <json> → captures stdout; always returns 0
run_trigger() {
  local json="$1"
  echo "$json" | bash "$HOOK" 2>/dev/null
}

# ── Grupo 1: Trigger detection — variantes Deia ──────────────────────────────
head "1) Trigger detection — variantes de Deia"

OUT="$(run_trigger '{"prompt":"Deia, faça algo"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'Deia, faça algo' → stdout contém additionalContext" \
  || fail "'Deia, faça algo' → esperava additionalContext no stdout"

OUT="$(run_trigger '{"prompt":"deia, faça algo"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'deia, faça algo' (minúsculo) → stdout contém additionalContext" \
  || fail "'deia, faça algo' → esperava additionalContext"

OUT="$(run_trigger '{"prompt":"Déia, algo"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'Déia, algo' (acento) → stdout contém additionalContext" \
  || fail "'Déia, algo' → esperava additionalContext"

OUT="$(run_trigger '{"prompt":"Deia: algo"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'Deia: algo' (dois pontos) → stdout contém additionalContext" \
  || fail "'Deia: algo' → esperava additionalContext"

OUT="$(run_trigger '{"prompt":"Deia algo"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'Deia algo' (espaço, sem pontuação) → stdout contém additionalContext" \
  || fail "'Deia algo' → esperava additionalContext"

OUT="$(run_trigger '{"prompt":"Deia, implementar OAuth"}')"
echo "$OUT" | grep -q "IdeiaOS" \
  && pass "stdout JSON contém 'IdeiaOS' (contexto de roteamento presente)" \
  || fail "stdout deveria conter 'IdeiaOS' no contexto"

# ── Grupo 2: Non-trigger passthrough — deve emitir stdout vazio ───────────────
head "2) Non-trigger passthrough — stdout deve ser vazio"

OUT="$(run_trigger '{"prompt":"Olá Deia, como vai"}')"
[ -z "$OUT" ] \
  && pass "'Olá Deia, como vai' (não começa com Deia) → stdout vazio" \
  || fail "'Olá Deia, como vai' → esperava stdout vazio, veio: $OUT"

OUT="$(run_trigger '{"prompt":"Bom dia, Deia"}')"
[ -z "$OUT" ] \
  && pass "'Bom dia, Deia' (Deia não está no início) → stdout vazio" \
  || fail "'Bom dia, Deia' → esperava stdout vazio, veio: $OUT"

OUT="$(run_trigger '{"prompt":"Ideiadeia algo"}')"
[ -z "$OUT" ] \
  && pass "'Ideiadeia algo' (Deia embutido, não na posição 0) → stdout vazio" \
  || fail "'Ideiadeia algo' → esperava stdout vazio, veio: $OUT"

OUT="$(run_trigger '{"prompt":""}')"
[ -z "$OUT" ] \
  && pass "prompt vazio → stdout vazio" \
  || fail "prompt vazio → esperava stdout vazio, veio: $OUT"

# ── Grupo 3: Edge cases ──────────────────────────────────────────────────────
head "3) Edge cases — robustez e segurança"

RC=0
OUT="$(echo '{}' | bash "$HOOK" 2>/dev/null)" || RC=$?
[ "$RC" = "0" ] \
  && pass "JSON vazio {} → exit 0 (sem crash)" \
  || fail "JSON vazio {} → esperava exit 0, veio $RC"
[ -z "$OUT" ] \
  && pass "JSON vazio {} → stdout vazio (sem chave 'prompt')" \
  || fail "JSON vazio {} → esperava stdout vazio, veio: $OUT"

RC=0
OUT="$(echo 'not json at all' | bash "$HOOK" 2>/dev/null)" || RC=$?
[ "$RC" = "0" ] \
  && pass "Entrada malformada → exit 0 (sem crash)" \
  || fail "Entrada malformada → esperava exit 0, veio $RC"
[ -z "$OUT" ] \
  && pass "Entrada malformada → stdout vazio" \
  || fail "Entrada malformada → esperava stdout vazio, veio: $OUT"

RC=0
OUT="$(echo '{"prompt":null}' | bash "$HOOK" 2>/dev/null)" || RC=$?
[ "$RC" = "0" ] \
  && pass "'prompt':null → exit 0 (sem crash)" \
  || fail "'prompt':null → esperava exit 0, veio $RC"
[ -z "$OUT" ] \
  && pass "'prompt':null → stdout vazio" \
  || fail "'prompt':null → esperava stdout vazio, veio: $OUT"

# Espaço à esquerda — o grep do hook permite leading whitespace
OUT="$(run_trigger '{"prompt":"  Deia, algo com espaço"}')"
echo "$OUT" | grep -q "additionalContext" \
  && pass "'  Deia, algo' (espaço à esquerda) → stdout contém additionalContext" \
  || fail "'  Deia, algo' → esperava additionalContext (hook usa ^[[:space:]]*(deia...))"

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ test-deia-trigger: todas as assertions OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ test-deia-trigger: há falhas${NC}\n"; exit 1; }
