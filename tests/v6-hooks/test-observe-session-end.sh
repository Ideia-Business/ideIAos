#!/usr/bin/env bash
# =============================================================================
# test-observe-session-end.sh — testa o hook observe-session-end.sh (Stop)
#
# Cobre:
#   1. Anti-runaway guard: IDEIAOS_INSTINCT_SPAWN=1 bloqueia tudo
#   2. Fim de sessão normal escreve marcador "session_end" no JSONL
#   3. Cooldown gate: sentinela recente NÃO bloqueia o marcador (só o spawn)
#   4. Path traversal em session_id rejeitado
#   5. Entrada vazia/malformada → exit 0, sem crash
#   6. Slug derivado do basename do cwd (apenas [a-z0-9-])
#
# Requer /usr/bin/python3. Pula suite (exit 0) se ausente.
# Usa TMP_HOME isolado como HOME.
# Uso:  bash tests/v6-hooks/test-observe-session-end.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_DIR/source/hooks/observe-session-end.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$HOOK" ] || { echo "Hook não encontrado: $HOOK"; exit 1; }

if [ ! -x /usr/bin/python3 ]; then
  echo "SKIP: /usr/bin/python3 não disponível — pulando test-observe-session-end"
  exit 0
fi

ORIG_HOME="$HOME"
SANDBOXES=()
cleanup() {
  export HOME="$ORIG_HOME"
  unset IDEIAOS_INSTINCT_SPAWN 2>/dev/null || true
  for d in "${SANDBOXES[@]:-}"; do
    rm -rf "$d" 2>/dev/null || true
  done
}
trap cleanup EXIT

new_home() {
  local d
  d="$(mktemp -d /tmp/ideiaos-sess-end-home.XXXXXX)"
  SANDBOXES+=("$d")
  echo "$d"
}

# ── Grupo 1: Anti-runaway guard ───────────────────────────────────────────────
head "1) Anti-runaway guard — IDEIAOS_INSTINCT_SPAWN=1 bloqueia tudo"

TH="$(new_home)"
export HOME="$TH"
export IDEIAOS_INSTINCT_SPAWN=1
echo '{"session_id":"sess-x","cwd":"/home/user/myproj","transcript_path":"/tmp/transcript.json"}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
unset IDEIAOS_INSTINCT_SPAWN
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "IDEIAOS_INSTINCT_SPAWN=1 → exit 0" \
  || fail "IDEIAOS_INSTINCT_SPAWN=1 → esperava exit 0, veio $RC"

OBS="$TH/.ideiaos/observations/myproj/observations.jsonl"
[ ! -f "$OBS" ] \
  && pass "guard bloqueou: obs file NÃO criado" \
  || fail "VIOLAÇÃO: obs file criado apesar de IDEIAOS_INSTINCT_SPAWN=1"

# ── Grupo 2: Sessão normal escreve marcador session_end ──────────────────────
head "2) Sessão normal escreve marcador session_end"

TH="$(new_home)"
export HOME="$TH"
echo '{"session_id":"sess-normal","cwd":"/home/user/normalproj","transcript_path":"/tmp/t.json"}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "sessão normal → exit 0" \
  || fail "sessão normal → esperava exit 0, veio $RC"

OBS="$TH/.ideiaos/observations/normalproj/observations.jsonl"
[ -f "$OBS" ] \
  && pass "obs file criado para normalproj" \
  || fail "obs file não criado para normalproj"

if [ -f "$OBS" ]; then
  grep -q "session_end" "$OBS" \
    && pass "obs file contém 'session_end'" \
    || fail "obs file não contém 'session_end'"

  grep -q '"event"' "$OBS" \
    && pass "registro JSONL tem campo 'event'" \
    || fail "registro JSONL não tem campo 'event'"

  # Privacy: o conteúdo do transcript NUNCA deve ser logado
  grep -q "transcript_path" "$OBS" \
    && fail "VIOLAÇÃO: transcript_path encontrado no obs file" \
    || pass "transcript_path NÃO está no obs file (privacidade ok)"
fi

# ── Grupo 3: Cooldown gate não bloqueia o marcador ───────────────────────────
head "3) Cooldown gate: sentinela recente não bloqueia escrita do marcador"

TH="$(new_home)"
# Seed sentinel com timestamp atual (simula análise recente < 1800s atrás)
mkdir -p "$TH/.ideiaos/instincts"
NOW_TS="$(/usr/bin/python3 -c "import datetime; print(datetime.datetime.now().isoformat(timespec='seconds'))")"
echo "$NOW_TS" > "$TH/.ideiaos/instincts/.last-analyzed-coolproj"

export HOME="$TH"
echo '{"session_id":"sess-cool","cwd":"/home/user/coolproj","transcript_path":"/tmp/t.json"}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "cooldown ativo → exit 0" \
  || fail "cooldown ativo → esperava exit 0, veio $RC"

OBS="$TH/.ideiaos/observations/coolproj/observations.jsonl"
[ -f "$OBS" ] \
  && pass "obs file criado (cooldown só bloqueia spawn, não o marcador)" \
  || fail "obs file não criado — cooldown não devia bloquear o marcador"

if [ -f "$OBS" ]; then
  grep -q "session_end" "$OBS" \
    && pass "marcador session_end presente mesmo com cooldown ativo" \
    || fail "marcador session_end ausente com cooldown ativo"
fi

# ── Grupo 4: Path traversal em session_id rejeitado ──────────────────────────
head "4) Path traversal em session_id rejeitado"

TH="$(new_home)"
export HOME="$TH"
echo '{"session_id":"../../../evil","cwd":"/home/user/proj"}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "session_id '../../../evil' → exit 0 (sem crash)" \
  || fail "session_id com traversal → esperava exit 0, veio $RC"

# Não deve ter criado nenhum arquivo
OBS_EVIL="$TH/.ideiaos/observations"
if [ -d "$OBS_EVIL" ]; then
  STRAY="$(find "$OBS_EVIL" -name "*.jsonl" 2>/dev/null | grep '\.\.' || true)"
  [ -z "$STRAY" ] \
    && pass "nenhum arquivo perigoso criado (traversal bloqueado)" \
    || fail "VIOLAÇÃO: arquivo criado com '..' no caminho: $STRAY"
else
  pass "nenhum obs dir criado (traversal bloqueado)"
fi

# ── Grupo 5: Fail-silent — entrada vazia/malformada ──────────────────────────
head "5) Fail-silent — entrada vazia e malformada"

TH="$(new_home)"
export HOME="$TH"

RC=0
echo '' | bash "$HOOK" 2>/dev/null || RC=$?
[ "$RC" = "0" ] \
  && pass "stdin vazio → exit 0" \
  || fail "stdin vazio → esperava exit 0, veio $RC"

RC=0
echo 'not json' | bash "$HOOK" 2>/dev/null || RC=$?
[ "$RC" = "0" ] \
  && pass "stdin malformado ('not json') → exit 0" \
  || fail "stdin malformado → esperava exit 0, veio $RC"

export HOME="$ORIG_HOME"

# ── Grupo 6: Slug derivado do cwd basename (apenas [a-z0-9-]) ────────────────
head "6) Slug do projeto derivado do basename do cwd (lowercase alfanumérico)"

TH="$(new_home)"
export HOME="$TH"
# cwd com espaços e maiúsculas — slug deve ser sanitizado
echo '{"session_id":"s1","cwd":"/home/user/My Project With Spaces"}' \
  | bash "$HOOK" 2>/dev/null
RC=$?
export HOME="$ORIG_HOME"

[ "$RC" = "0" ] \
  && pass "cwd com espaços → exit 0" \
  || fail "cwd com espaços → esperava exit 0, veio $RC"

OBS_DIR="$TH/.ideiaos/observations"
if [ -d "$OBS_DIR" ]; then
  # Pegar nome do diretório criado sob observations/
  SLUG_DIR="$(ls "$OBS_DIR" 2>/dev/null | head -1)"
  if [ -n "$SLUG_DIR" ]; then
    # Verificar que slug é apenas [a-z0-9-]
    INVALID="$(echo "$SLUG_DIR" | grep -v '^[a-z0-9-]*$' || true)"
    [ -z "$INVALID" ] \
      && pass "slug '$SLUG_DIR' é apenas [a-z0-9-] (sanitizado corretamente)" \
      || fail "slug '$SLUG_DIR' contém caracteres inválidos: $INVALID"
  else
    fail "nenhum diretório criado em $OBS_DIR"
  fi
else
  fail "diretório de observações não criado"
fi

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ test-observe-session-end: todas as assertions OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ test-observe-session-end: há falhas${NC}\n"; exit 1; }
