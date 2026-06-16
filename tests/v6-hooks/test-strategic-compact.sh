#!/usr/bin/env bash
# =============================================================================
# test-strategic-compact.sh — testa o hook strategic-compact.sh (PreToolUse)
#
# Cobre:
#   1. Counter incrementa, sem output antes do 50º call
#   2. 50º call emite JSON com additionalContext
#   3. 100º call também emite (boundary a cada 50, não só uma vez)
#   4. session_id vazio → exit 0 silencioso, sem counter file
#   5. Path traversal em session_id → exit 0, sem arquivo perigoso
#   6. Counter file corrompido → tratado como 0, incrementa para 1
#
# Puro bash, sem python3. Usa counter files em /tmp.
# Uso:  bash tests/v6-hooks/test-strategic-compact.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_DIR/source/hooks/strategic-compact.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$HOOK" ] || { echo "Hook não encontrado: $HOOK"; exit 1; }

# session_ids únicos por grupo para evitar contaminação cruzada
TS="$(date +%s)"
SID_A="test-strategic-${TS}-a"
SID_B="test-strategic-${TS}-b"
SID_C="test-strategic-${TS}-c"
SID_D="test-strategic-${TS}-d"
SID_E="test-strategic-${TS}-e"
SID_CORRUPT="test-strategic-${TS}-corrupt"

COUNTER_A="/tmp/claude-compact-counter-${SID_A}"
COUNTER_B="/tmp/claude-compact-counter-${SID_B}"
COUNTER_C="/tmp/claude-compact-counter-${SID_C}"
COUNTER_CORRUPT="/tmp/claude-compact-counter-${SID_CORRUPT}"

trap 'rm -f /tmp/claude-compact-counter-test-strategic-'"${TS}"'-* 2>/dev/null || true' EXIT

# run_hook <sid> → feeds JSON to hook, captures stdout + exit code in RC_HOOK
RC_HOOK=0
run_hook() {
  local sid="$1"
  RC_HOOK=0
  echo "{\"session_id\":\"$sid\",\"tool_name\":\"Read\"}" | bash "$HOOK" 2>/dev/null || RC_HOOK=$?
}

# ── Grupo 1: Counter incrementa, sem output antes do 50º ─────────────────────
head "1) Counter incrementa, sem output antes do 50º call"

# Fast path: pré-seed counter com 48, rodar hook (call 49) → deve ser silencioso
echo "48" > "$COUNTER_A"
OUT="$(run_hook "$SID_A")"
[ "$RC_HOOK" = "0" ] \
  && pass "call 49 → exit 0" \
  || fail "call 49 → esperava exit 0, veio $RC_HOOK"
[ -z "$OUT" ] \
  && pass "call 49 → stdout vazio (sem output antes do 50º)" \
  || fail "call 49 → esperava stdout vazio, veio: $OUT"

VAL="$(cat "$COUNTER_A" 2>/dev/null || echo 'MISSING')"
[ "$VAL" = "49" ] \
  && pass "counter file contém 49 após call 49" \
  || fail "counter file contém '$VAL' (esperava 49)"

# ── Grupo 2: 50º call emite JSON com additionalContext ───────────────────────
head "2) 50º call emite JSON com additionalContext"

echo "49" > "$COUNTER_B"
OUT="$(run_hook "$SID_B")"
[ "$RC_HOOK" = "0" ] \
  && pass "call 50 → exit 0" \
  || fail "call 50 → esperava exit 0, veio $RC_HOOK"

echo "$OUT" | grep -q "additionalContext" \
  && pass "call 50 → stdout contém 'additionalContext'" \
  || fail "call 50 → esperava 'additionalContext' no stdout: $OUT"

echo "$OUT" | grep -q "50" \
  && pass "call 50 → stdout contém '50' (contagem mencionada)" \
  || fail "call 50 → esperava '50' no stdout: $OUT"

# Valida que é JSON válido
echo "$OUT" | /usr/bin/python3 -c 'import sys,json; json.load(sys.stdin)' 2>/dev/null \
  && pass "call 50 → stdout é JSON válido" \
  || fail "call 50 → stdout não é JSON válido: $OUT"

# ── Grupo 3: 100º call também emite (boundary a cada 50) ─────────────────────
head "3) 100º call também emite (boundary a cada 50, não só uma vez)"

echo "99" > "$COUNTER_C"
OUT="$(run_hook "$SID_C")"
[ "$RC_HOOK" = "0" ] \
  && pass "call 100 → exit 0" \
  || fail "call 100 → esperava exit 0, veio $RC_HOOK"

echo "$OUT" | grep -q "additionalContext" \
  && pass "call 100 → stdout contém 'additionalContext'" \
  || fail "call 100 → esperava 'additionalContext' no stdout: $OUT"

echo "$OUT" | grep -q "100" \
  && pass "call 100 → stdout contém '100'" \
  || fail "call 100 → esperava '100' no stdout: $OUT"

# ── Grupo 4: session_id vazio → exit 0 silencioso, sem counter file ──────────
head "4) session_id vazio → exit 0, sem counter file criado"

RC_HOOK=0
OUT="$(echo '{"session_id":"","tool_name":"Read"}' | bash "$HOOK" 2>/dev/null)" || RC_HOOK=$?
[ "$RC_HOOK" = "0" ] \
  && pass "session_id vazio → exit 0" \
  || fail "session_id vazio → esperava exit 0, veio $RC_HOOK"
[ -z "$OUT" ] \
  && pass "session_id vazio → stdout vazio" \
  || fail "session_id vazio → esperava stdout vazio, veio: $OUT"

# Verificar que nenhum counter file com nome vazio foi criado
EMPTY_COUNTER="/tmp/claude-compact-counter-"
[ ! -f "$EMPTY_COUNTER" ] \
  && pass "nenhum counter file criado para session_id vazio" \
  || fail "counter file criado para session_id vazio: $EMPTY_COUNTER"

# ── Grupo 5: Path traversal em session_id → exit 0, sem arquivo perigoso ─────
head "5) Path traversal em session_id → exit 0, sem arquivo perigoso"

RC_HOOK=0
OUT="$(echo '{"session_id":"../../etc/passwd","tool_name":"Read"}' | bash "$HOOK" 2>/dev/null)" || RC_HOOK=$?
[ "$RC_HOOK" = "0" ] \
  && pass "session_id com traversal '../../etc/passwd' → exit 0" \
  || fail "session_id com traversal → esperava exit 0, veio $RC_HOOK"
[ -z "$OUT" ] \
  && pass "session_id com traversal → stdout vazio" \
  || fail "session_id com traversal → esperava stdout vazio, veio: $OUT"

# Verificar que nenhum arquivo com '..' foi criado em /tmp
STRAY="$(find /tmp -maxdepth 1 -name 'claude-compact-counter-*' 2>/dev/null | grep '\.\.' || true)"
[ -z "$STRAY" ] \
  && pass "nenhum arquivo perigoso criado em /tmp (traversal bloqueado)" \
  || fail "VIOLAÇÃO: arquivo perigoso criado: $STRAY"

# ── Grupo 6: Counter corrompido → tratado como 0, incrementa para 1 ──────────
head "6) Counter file corrompido → resetado para 0, incrementa para 1"

echo "notanumber" > "$COUNTER_CORRUPT"
OUT="$(run_hook "$SID_CORRUPT")"
[ "$RC_HOOK" = "0" ] \
  && pass "counter corrompido → exit 0" \
  || fail "counter corrompido → esperava exit 0, veio $RC_HOOK"
[ -z "$OUT" ] \
  && pass "counter corrompido → stdout vazio (call 1, não emite)" \
  || fail "counter corrompido → esperava stdout vazio (call 1), veio: $OUT"

VAL="$(cat "$COUNTER_CORRUPT" 2>/dev/null || echo 'MISSING')"
[ "$VAL" = "1" ] \
  && pass "counter corrompido → resetado e incrementado para 1" \
  || fail "counter corrompido → esperava valor '1', veio '$VAL'"

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ test-strategic-compact: todas as assertions OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ test-strategic-compact: há falhas${NC}\n"; exit 1; }
