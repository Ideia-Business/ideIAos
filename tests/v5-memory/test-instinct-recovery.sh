#!/usr/bin/env bash
# =============================================================================
# test-instinct-recovery.sh — testa resiliência/retomada do spawn instinct (Fase 24).
# SOURCE: IdeiaOS v2
#
# Cobre 6 cenários:
#   1. CRASH MID-SPAWN: breadcrumb órfão (pid morto) é tratado (removido)
#   2. RETOMADA com gates ok: recovery re-spawna (stub claude chamado)
#   3. NÃO-RETOMADA em cooldown: recovery só limpa, não spawna
#   4. PID VIVO: breadcrumb com pid vivo é preservado (sem spawn duplo)
#   5. ANTI-RUNAWAY: IDEIAOS_INSTINCT_SPAWN=1 → exit 0 imediato, sem ação
#   6. NÃO RE-DISPARA EM LOOP: 2ª execução de recovery = no-op (stub chamado ≤1x)
#
# Sandbox: HOME temporário via mktemp → nunca toca ~/.ideiaos real.
# Stub: "claude" fake em $SANDBOX/bin (controlado; escreve marcador no log).
# Uso:   bash tests/v5-memory/test-instinct-recovery.sh
# Exit:  0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RECOVER_HOOK="$REPO_DIR/source/hooks/instinct-recover.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0

pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$RECOVER_HOOK" ] || { echo "hook não encontrado: $RECOVER_HOOK"; exit 1; }

# =============================================================================
# Sandbox: HOME isolado para nunca tocar ~/.ideiaos real
# =============================================================================
SANDBOX="$(mktemp -d /tmp/ideiaos-recovery-test.XXXXXX)"
trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$SANDBOX"' EXIT

export HOME="$SANDBOX"
# Diretório de breadcrumbs e sentinelas
INSTINCTS_DIR="$SANDBOX/.ideiaos/instincts"
OBS_DIR_BASE="$SANDBOX/.ideiaos/observations"
mkdir -p "$INSTINCTS_DIR" "$SANDBOX/.ideiaos/logs"

# =============================================================================
# Stub de claude: registra chamada em $SANDBOX/claude-calls.log e retorna 0
# =============================================================================
mkdir -p "$SANDBOX/bin"
cat > "$SANDBOX/bin/claude" << 'STUB'
#!/usr/bin/env bash
# Stub de claude para testes de recovery
echo "claude-stub-called: $(date +%s) args=$*" >> "$HOME/.ideiaos/claude-stub-calls.log"
exit 0
STUB
chmod +x "$SANDBOX/bin/claude"

# Colocar stub no PATH ANTES de qualquer entrada
export PATH="$SANDBOX/bin:$PATH"

# =============================================================================
# Helpers
# =============================================================================

# Gera um started_at antigo o suficiente (>120s atrás)
old_timestamp() {
  /usr/bin/python3 -c "
import datetime
dt = datetime.datetime.now() - datetime.timedelta(seconds=300)
print(dt.isoformat(timespec='seconds'))
"
}

# Gera um started_at recente (<120s atrás)
recent_timestamp() {
  /usr/bin/python3 -c "
import datetime
dt = datetime.datetime.now() - datetime.timedelta(seconds=30)
print(dt.isoformat(timespec='seconds'))
"
}

# Gera um started_at antigo para cooldown expirado (>1800s atrás)
old_sentinel_timestamp() {
  /usr/bin/python3 -c "
import datetime
dt = datetime.datetime.now() - datetime.timedelta(seconds=3600)
print(dt.isoformat(timespec='seconds'))
"
}

# Gera um started_at recente para cooldown ativo (<1800s atrás)
recent_sentinel_timestamp() {
  /usr/bin/python3 -c "
import datetime
dt = datetime.datetime.now() - datetime.timedelta(seconds=600)
print(dt.isoformat(timespec='seconds'))
"
}

# Conta quantas vezes o stub claude foi chamado
stub_call_count() {
  local log="$SANDBOX/.ideiaos/claude-stub-calls.log"
  if [ -f "$log" ]; then
    wc -l < "$log" | tr -d ' '
  else
    echo "0"
  fi
}

# Limpa o log de chamadas do stub
reset_stub_log() {
  rm -f "$SANDBOX/.ideiaos/claude-stub-calls.log"
}

# Cria breadcrumb com pid morto e started_at antigo
make_orphan_breadcrumb() {
  local proj="${1:-ideiaos}"
  local state_file="$INSTINCTS_DIR/.spawn-${proj}.state"
  local dead_pid=999999
  local started_at
  started_at="$(old_timestamp)"
  printf 'pid=%s\nstarted_at=%s\nproject=%s\nstatus=running\nlog=%s/.ideiaos/logs/spawn-test.log\n' \
    "$dead_pid" "$started_at" "$proj" "$SANDBOX" > "$state_file"
  echo "$state_file"
}

# Cria sentinela (.last-analyzed) com timestamp antigo (cooldown expirado)
make_old_sentinel() {
  local proj="${1:-ideiaos}"
  local sentinel="$INSTINCTS_DIR/.last-analyzed-${proj}"
  old_sentinel_timestamp > "$sentinel"
}

# Cria sentinela com timestamp recente (cooldown ativo)
make_recent_sentinel() {
  local proj="${1:-ideiaos}"
  local sentinel="$INSTINCTS_DIR/.last-analyzed-${proj}"
  recent_sentinel_timestamp > "$sentinel"
}

# Cria observations.jsonl com uma obs mais recente que a sentinela
make_obs_newer_than_sentinel() {
  local proj="${1:-ideiaos}"
  local obs_dir="$OBS_DIR_BASE/${proj}"
  mkdir -p "$obs_dir"
  /usr/bin/python3 -c "
import json, datetime
rec = {
  'ts': datetime.datetime.now().isoformat(timespec='seconds'),
  'session_id': 'test-session',
  'project': '$proj',
  'tool': 'Write',
  'file': 'test.sh',
  'ext': 'sh',
  'bash_verb': '',
  'ok': True,
}
print(json.dumps(rec))
" >> "$obs_dir/observations.jsonl"
}

# Roda o hook de recovery (em subshell isolada)
run_recovery() {
  local extra_env=""
  if [ "${1:-}" = "with-spawn-guard" ]; then
    extra_env="IDEIAOS_INSTINCT_SPAWN=1"
  fi
  if [ -n "$extra_env" ]; then
    ( env "$extra_env" bash "$RECOVER_HOOK" <<< '{}' ) 2>/dev/null
  else
    ( bash "$RECOVER_HOOK" <<< '{}' ) 2>/dev/null
  fi
}

# =============================================================================
# Teste 1: CRASH MID-SPAWN — órfão é tratado (não fica pendurado)
# =============================================================================
head "1) CRASH MID-SPAWN: breadcrumb órfão (pid morto) é tratado"

PROJ1="ideiaos-t1"
STATE_FILE1="$(make_orphan_breadcrumb "$PROJ1")"

run_recovery

# O breadcrumb principal não deve existir mais
if [ ! -f "$STATE_FILE1" ]; then
  pass "breadcrumb órfão foi removido (não ficou preso em running)"
else
  fail "breadcrumb órfão ainda existe: $STATE_FILE1"
fi

# Não pode ter sobrado arquivo .claimed pendurado
CLAIMED_COUNT="$(ls "$INSTINCTS_DIR/.spawn-${PROJ1}.state.claimed-"* 2>/dev/null | wc -l | tr -d ' ')"
if [ "$CLAIMED_COUNT" = "0" ]; then
  pass "nenhum .claimed pendurado após tratamento"
else
  fail "sobrou $CLAIMED_COUNT arquivo(s) .claimed"
fi

# =============================================================================
# Teste 2: RETOMADA com gates passando — claude stub é chamado
# =============================================================================
head "2) RETOMADA: gates ok → recovery re-spawna (stub claude chamado)"

PROJ2="ideiaos-t2"
STATE_FILE2="$(make_orphan_breadcrumb "$PROJ2")"
make_old_sentinel "$PROJ2"
make_obs_newer_than_sentinel "$PROJ2"
reset_stub_log

run_recovery

# claude stub deve ter sido chamado
CALLS_AFTER="$(stub_call_count)"
if [ "$CALLS_AFTER" -ge 1 ]; then
  pass "claude stub chamado $CALLS_AFTER vez(es) (retomada confirmada)"
else
  fail "claude stub NÃO foi chamado — retomada não ocorreu"
fi

# breadcrumb deve ter sido limpo
if [ ! -f "$STATE_FILE2" ]; then
  pass "breadcrumb de retomada foi limpo após spawn"
else
  fail "breadcrumb ainda existe após retomada: $STATE_FILE2"
fi

# =============================================================================
# Teste 3: NÃO-RETOMADA em cooldown — orphan limpo, claude NÃO chamado
# =============================================================================
head "3) NÃO-RETOMADA em cooldown: limpa orphan, não spawna"

PROJ3="ideiaos-t3"
STATE_FILE3="$(make_orphan_breadcrumb "$PROJ3")"
make_recent_sentinel "$PROJ3"  # cooldown ativo (<30min)
make_obs_newer_than_sentinel "$PROJ3"
reset_stub_log

run_recovery

# breadcrumb deve ter sido removido
if [ ! -f "$STATE_FILE3" ]; then
  pass "breadcrumb órfão removido (cooldown ativo, correto)"
else
  fail "breadcrumb ainda existe após cooldown-block: $STATE_FILE3"
fi

# claude NÃO deve ter sido chamado
CALLS_COOLDOWN="$(stub_call_count)"
if [ "$CALLS_COOLDOWN" = "0" ]; then
  pass "claude stub NÃO chamado em cooldown (correto)"
else
  fail "claude stub chamado $CALLS_COOLDOWN vez(es) apesar do cooldown"
fi

# =============================================================================
# Teste 4: PID VIVO — breadcrumb preservado (sem spawn duplo)
# =============================================================================
head "4) PID VIVO: breadcrumb intocado (sem spawn duplo)"

PROJ4="ideiaos-t4"

# Processo vivo real
sleep 30 &
LIVE_PID=$!

STATE_FILE4="$INSTINCTS_DIR/.spawn-${PROJ4}.state"
STARTED4="$(recent_timestamp)"
printf 'pid=%s\nstarted_at=%s\nproject=%s\nstatus=running\nlog=%s/.ideiaos/logs/spawn-live.log\n' \
  "$LIVE_PID" "$STARTED4" "$PROJ4" "$SANDBOX" > "$STATE_FILE4"
reset_stub_log

run_recovery

# breadcrumb deve continuar existindo (pid vivo)
if [ -f "$STATE_FILE4" ]; then
  pass "breadcrumb com pid vivo foi preservado (sem spawn duplo)"
else
  fail "breadcrumb com pid vivo foi removido — possível spawn duplo"
fi

# claude NÃO deve ter sido chamado
CALLS_LIVE="$(stub_call_count)"
if [ "$CALLS_LIVE" = "0" ]; then
  pass "claude stub NÃO chamado para pid vivo (correto)"
else
  fail "claude stub chamado $CALLS_LIVE vez(es) para pid vivo — spawn duplo!"
fi

# Limpar processo vivo
kill "$LIVE_PID" 2>/dev/null || true
wait "$LIVE_PID" 2>/dev/null || true
# Limpar breadcrumb manual (pid morto agora, mas teste já passou)
rm -f "$STATE_FILE4"

# =============================================================================
# Teste 5: ANTI-RUNAWAY — IDEIAOS_INSTINCT_SPAWN=1 → exit 0, nada tocado
# =============================================================================
head "5) ANTI-RUNAWAY: IDEIAOS_INSTINCT_SPAWN=1 → exit 0 imediato"

PROJ5="ideiaos-t5"
STATE_FILE5="$(make_orphan_breadcrumb "$PROJ5")"
reset_stub_log

run_recovery "with-spawn-guard"

# breadcrumb deve estar intocado
if [ -f "$STATE_FILE5" ]; then
  pass "breadcrumb intocado sob IDEIAOS_INSTINCT_SPAWN=1 (correto)"
else
  fail "breadcrumb foi tratado mesmo com IDEIAOS_INSTINCT_SPAWN=1 — anti-runaway falhou"
fi

# claude NÃO deve ter sido chamado
CALLS_GUARD="$(stub_call_count)"
if [ "$CALLS_GUARD" = "0" ]; then
  pass "claude stub NÃO chamado sob IDEIAOS_INSTINCT_SPAWN=1 (correto)"
else
  fail "claude stub chamado $CALLS_GUARD vez(es) — anti-runaway falhou"
fi

# Limpar breadcrumb do teste 5
rm -f "$STATE_FILE5"

# =============================================================================
# Teste 6: NÃO RE-DISPARA EM LOOP — 2ª execução é no-op
# =============================================================================
head "6) NÃO RE-DISPARA EM LOOP: 2ª execução = no-op (stub chamado ≤1x)"

PROJ6="ideiaos-t6"
STATE_FILE6="$(make_orphan_breadcrumb "$PROJ6")"
make_old_sentinel "$PROJ6"
make_obs_newer_than_sentinel "$PROJ6"
reset_stub_log

# 1ª execução — deve processar o órfão
run_recovery

CALLS_FIRST="$(stub_call_count)"

# 2ª execução — breadcrumb não existe mais; deve ser no-op
run_recovery

CALLS_SECOND="$(stub_call_count)"

if [ "$CALLS_FIRST" -ge 1 ]; then
  pass "1ª execução: stub chamado $CALLS_FIRST vez(es) (retomada ok)"
else
  fail "1ª execução: stub não chamado — retomada não ocorreu"
fi

if [ "$CALLS_SECOND" = "$CALLS_FIRST" ]; then
  pass "2ª execução: no-op (stub count não aumentou: $CALLS_SECOND total)"
else
  fail "2ª execução: stub chamado de novo ($CALLS_SECOND total) — loop detectado!"
fi

# =============================================================================
# Resumo
# =============================================================================
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ todos os cenários de recovery OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ há cenários falhando${NC}\n"; exit 1; }
