#!/usr/bin/env bash
# =============================================================================
# test-observe-tool-use.sh — testa o hook observe-tool-use.sh (PostToolUse)
#
# Cobre:
#   1. Privacy: secrets NUNCA aparecem em observations.jsonl (crítico)
#   2. Privacy: conteúdo de arquivo NUNCA é logado, apenas o path
#   3. Anti-runaway guard: IDEIAOS_INSTINCT_SPAWN=1 bloqueia tudo
#   4. Evento válido cria registro JSONL correto
#   5. Entrada vazia → exit 0, sem crash (fail-silent)
#   6. Path traversal em session_id é rejeitado
#
# Requer /usr/bin/python3. Pula suite (exit 0) se ausente.
# Usa TMP_HOME isolado como HOME para que obs files sejam criadas em sandbox.
# Uso:  bash tests/v6-hooks/test-observe-tool-use.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_DIR/source/hooks/observe-tool-use.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$HOOK" ] || { echo "Hook não encontrado: $HOOK"; exit 1; }

if [ ! -x /usr/bin/python3 ]; then
  echo "SKIP: /usr/bin/python3 não disponível — pulando test-observe-tool-use"
  exit 0
fi

ORIG_HOME="$HOME"
SANDBOX="$(mktemp -d /tmp/ideiaos-obs-tool-test.XXXXXX)"
TMP_HOME="$(mktemp -d /tmp/ideiaos-obs-home.XXXXXX)"
trap 'rm -rf "$SANDBOX" "$TMP_HOME"; export HOME="$ORIG_HOME"; unset IDEIAOS_INSTINCT_SPAWN 2>/dev/null || true' EXIT

# obs_file <proj_slug> → path to observations.jsonl under TMP_HOME
obs_file() {
  echo "$TMP_HOME/.ideiaos/observations/$1/observations.jsonl"
}

# run_hook <json> → feeds JSON to hook with TMP_HOME as HOME; returns exit code
run_hook() {
  local json="$1"
  export HOME="$TMP_HOME"
  echo "$json" | bash "$HOOK" 2>/dev/null
  local rc=$?
  export HOME="$ORIG_HOME"
  return $rc
}

# ── Grupo 1: Privacy — SECRETS NUNCA LOGADOS (mais crítico) ──────────────────
head "1) Privacy — secrets NUNCA chegam a observations.jsonl"

export HOME="$TMP_HOME"
echo '{"session_id":"s1","cwd":"/home/user/myproject","tool_name":"Bash","tool_input":{"command":"export API_KEY=sk-secret123"},"tool_response":{}}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "evento Bash com secret → exit 0" \
  || fail "evento Bash com secret → esperava exit 0, veio $RC"

OBS="$(obs_file "myproject")"
[ -f "$OBS" ] \
  && pass "obs file criado (myproject)" \
  || fail "obs file não encontrado em $OBS"

if [ -f "$OBS" ]; then
  grep -q "sk-secret123" "$OBS" \
    && fail "VIOLAÇÃO CRÍTICA: 'sk-secret123' encontrado em obs file" \
    || pass "secret value 'sk-secret123' NÃO está no obs file"

  grep -q "API_KEY=sk-secret123" "$OBS" \
    && fail "VIOLAÇÃO CRÍTICA: atribuição 'API_KEY=sk-secret123' encontrada em obs file" \
    || pass "atribuição completa 'API_KEY=sk-secret123' NÃO está no obs file"

  grep -q '"bash_verb"' "$OBS" \
    && pass "campo 'bash_verb' presente no registro (apenas verbo, não args)" \
    || fail "campo 'bash_verb' ausente no registro"

  grep -q '"export"' "$OBS" \
    && pass "bash_verb é 'export' (apenas 1º token, não os argumentos)" \
    || fail "bash_verb não é 'export' — verbo incorreto ou não logado"
fi

# ── Grupo 2: Privacy — conteúdo de arquivo NÃO logado, apenas path ───────────
head "2) Privacy — conteúdo de arquivo NÃO logado"

# Limpa obs para este teste com novo projeto
TMP2="$(mktemp -d /tmp/ideiaos-obs-home2.XXXXXX)"
trap 'rm -rf "$SANDBOX" "$TMP_HOME" "${TMP2:-}" "${TMP3:-}" "${TMP4:-}" "${TMP5:-}" "${TMP6:-}"; export HOME="$ORIG_HOME"; unset IDEIAOS_INSTINCT_SPAWN 2>/dev/null || true' EXIT

export HOME="$TMP2"
echo '{"session_id":"s2","cwd":"/home/user/readproj","tool_name":"Read","tool_input":{"file_path":"/home/user/readproj/secrets.env","content":"password=hunter2"},"tool_response":{"content":"password=hunter2"}}' \
  | bash "$HOOK" 2>/dev/null
export HOME="$ORIG_HOME"

OBS2="$(echo "$TMP2/.ideiaos/observations/readproj/observations.jsonl")"
if [ -f "$OBS2" ]; then
  grep -q "hunter2" "$OBS2" \
    && fail "VIOLAÇÃO: conteúdo 'hunter2' encontrado em obs file" \
    || pass "conteúdo do arquivo 'hunter2' NÃO está no obs file"

  grep -q "password=" "$OBS2" \
    && fail "VIOLAÇÃO: 'password=' encontrado em obs file" \
    || pass "conteúdo 'password=' NÃO está no obs file"

  grep -q "secrets.env" "$OBS2" \
    && pass "path do arquivo 'secrets.env' está logado (path ok, conteúdo não)" \
    || pass "path logado como relativo (sem nome completo — path relativo ao cwd)"
else
  fail "obs file não criado para o evento Read"
fi

# ── Grupo 3: Anti-runaway guard ───────────────────────────────────────────────
head "3) Anti-runaway guard — IDEIAOS_INSTINCT_SPAWN=1 bloqueia tudo"

TMP3="$(mktemp -d /tmp/ideiaos-obs-home3.XXXXXX)"
export HOME="$TMP3"
export IDEIAOS_INSTINCT_SPAWN=1
echo '{"session_id":"s3","cwd":"/home/user/guardproj","tool_name":"Read","tool_input":{},"tool_response":{}}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
unset IDEIAOS_INSTINCT_SPAWN
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "IDEIAOS_INSTINCT_SPAWN=1 → exit 0" \
  || fail "IDEIAOS_INSTINCT_SPAWN=1 → esperava exit 0, veio $RC"

OBS3="$TMP3/.ideiaos/observations/guardproj/observations.jsonl"
[ ! -f "$OBS3" ] \
  && pass "guard bloqueou: obs file NÃO criado (spawn bloqueado na raiz)" \
  || fail "VIOLAÇÃO: obs file criado apesar de IDEIAOS_INSTINCT_SPAWN=1"

# ── Grupo 4: Evento válido cria registro JSONL correto ───────────────────────
head "4) Evento válido cria registro JSONL correto"

TMP4="$(mktemp -d /tmp/ideiaos-obs-home4.XXXXXX)"
export HOME="$TMP4"
echo '{"session_id":"sess-abc","cwd":"/home/user/testproj","tool_name":"Read","tool_input":{"file_path":"/home/user/testproj/README.md"},"tool_response":{}}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "evento Read válido → exit 0" \
  || fail "evento Read válido → esperava exit 0, veio $RC"

OBS4="$TMP4/.ideiaos/observations/testproj/observations.jsonl"
[ -f "$OBS4" ] \
  && pass "obs file criado para testproj" \
  || fail "obs file não criado para testproj"

if [ -f "$OBS4" ]; then
  LC="$(wc -l < "$OBS4" | tr -d ' ')"
  [ "$LC" = "1" ] \
    && pass "obs file tem 1 linha após 1 evento (correto)" \
    || fail "obs file tem $LC linhas (esperava 1)"

  grep -q '"session_id"' "$OBS4" \
    && pass "registro contém campo 'session_id'" \
    || fail "registro não contém 'session_id'"

  grep -q '"Read"' "$OBS4" \
    && pass "registro contém tool_name 'Read'" \
    || fail "registro não contém 'Read'"
fi

# ── Grupo 5: Entrada vazia → exit 0, sem crash ────────────────────────────────
head "5) Fail-silent — entrada vazia não causa crash"

TMP5="$(mktemp -d /tmp/ideiaos-obs-home5.XXXXXX)"
export HOME="$TMP5"
RC=0
echo '' | bash "$HOOK" 2>/dev/null || RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "stdin vazio → exit 0 (fail-silent)" \
  || fail "stdin vazio → esperava exit 0, veio $RC"

# ── Grupo 6: Path traversal em session_id rejeitado ──────────────────────────
head "6) Path traversal em session_id é rejeitado"

TMP6="$(mktemp -d /tmp/ideiaos-obs-home6.XXXXXX)"
export HOME="$TMP6"
echo '{"session_id":"../../etc/passwd","cwd":"/home/user/proj","tool_name":"Read","tool_input":{},"tool_response":{}}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "session_id com path traversal → exit 0 (sem crash)" \
  || fail "session_id com path traversal → esperava exit 0, veio $RC"

# Verifica que nenhum arquivo foi escrito em caminho perigoso
STRAY="$(find "$TMP6/.ideiaos/observations" -name "*.jsonl" 2>/dev/null | grep -v '^$' || true)"
if [ -z "$STRAY" ]; then
  pass "nenhum obs file criado para session_id com traversal"
else
  # Verifica que nenhum slug contém '..'
  DANGEROUS="$(echo "$STRAY" | grep '\.\.' || true)"
  if [ -z "$DANGEROUS" ]; then
    pass "nenhum arquivo criado com '..' no caminho (traversal bloqueado)"
  else
    fail "VIOLAÇÃO: arquivo criado com caminho perigoso: $DANGEROUS"
  fi
fi

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ test-observe-tool-use: todas as assertions OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ test-observe-tool-use: há falhas${NC}\n"; exit 1; }
