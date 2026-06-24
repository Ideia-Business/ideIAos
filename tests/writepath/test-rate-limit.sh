#!/bin/bash
# test-rate-limit.sh — gate STANDALONE do throttle determinístico por (ref+subject) (v14.4 · B8 · R-WP12).
#
# Prova por EXIT-CODE (antifragile-gates) que rate-limit.sh:
#   • deixa passar os MAX primeiros checks da MESMA janela (exit 0);
#   • RECUSA o (MAX+1)-ésimo da MESMA janela (exit 3 REASON=rate-limited);
#   • RESETA ao avançar `now` p/ a janela seguinte (bucket muda → contador zera);
#   • mantém contadores INDEPENDENTES por (ref) e por (subject) — não compartilham limite;
#   • FAIL-CLOSED quando o store é não-gravável (exit 4) — sem contar, não deixa passar o flood.
#
# INVARIANTE CRÍTICA provada: rate-limit é defesa SECUNDÁRIA — `check` exit 0 NÃO autoriza nada (a
#   autorização é verify-payload, R-WP1/R-WP2). Caso `secondary-not-authorizer` asserta isso.
#
# ANTI-TEATRO ESTRUTURAL (espelha o harness agregado):
#   (a) MANIFESTO EXPECTED_CASES — reprova se cases_run != EXPECTED_CASES;
#   (b) cada caso-veneno casa um EXIT-CODE específico + REASON= — um !=0 genérico (127) REPROVA;
#   (c) CANÁRIO — prova que o comparador detecta mecanismo QUEBRADO (não só ausente);
#   (d) MUTAÇÃO — sabota a lib (zera a janela), prova vermelho, restaura, prova verde.
#
# Determinismo de tempo: SEM sleep — `now` por IDEIAOS_RL_NOW. Stores efêmeros em /tmp, descartados.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"   # tests/writepath/ → repo root (dois níveis)
AGENTD="$ROOT/source/agentd"
LIB="$AGENTD/rate-limit.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ratelimit.XXXXXX")"
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# store isolado (nunca toca o real do operador) + parâmetros fixos e pequenos p/ o teste
export IDEIAOS_RATELIMIT_STORE="$WORK/store"
export IDEIAOS_RL_MAX=3
export IDEIAOS_RL_WINDOW=60

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=12     # MANIFESTO — tem que bater com os assert_case abaixo (anti-teatro (a))
FAILED_NAMES=""

c_green(){ printf '\033[0;32m%s\033[0m\n' "$1"; }
c_red(){ printf '\033[0;31m%s\033[0m\n' "$1"; }

# comparador: rc==expect_exit E (sem REASON esperado OU stderr contém REASON). 0=match,1=miss.
_cmp() { local rc="$1" errf="$2" eexit="$3" ereason="$4"
  [ "$rc" = "$eexit" ] || return 1
  [ -z "$ereason" ] && return 0
  grep -q "$ereason" "$errf" 2>/dev/null
}

# assert_case NAME EXPECT_EXIT EXPECT_REASON -- CMD...
assert_case() {
  local name="$1" eexit="$2" ereason="$3"; shift 3; [ "$1" = "--" ] && shift
  CASES_RUN=$((CASES_RUN+1))
  local errf="$WORK/err.$CASES_RUN" rc
  "$@" >/dev/null 2>"$errf"; rc=$?
  if _cmp "$rc" "$errf" "$eexit" "$ereason"; then
    PASS=$((PASS+1)); printf '  ✓ %-44s exit=%s %s\n' "$name" "$rc" "${ereason:+REASON~$ereason}"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name"
    printf '  ✗ %-44s got exit=%s (want %s%s); stderr=%s\n' "$name" "$rc" "$eexit" "${ereason:+ REASON~$ereason}" "$(head -1 "$errf" 2>/dev/null)"
  fi
}

# rl <now> <ref> <subject> — invoca a lib com `now` fixo (determinístico, sem relógio real)
rl() { IDEIAOS_RL_NOW="$1" bash "$LIB" check "$2" "$3"; }

echo "━━━ rate-limit gate (B8 · R-WP12) ━━━"

# ───────────────────────── janela: MAX passa, MAX+1 recusa ─────────────────────────
# NOW0 fixo dentro de uma janela. Os 3 (=MAX) primeiros checks do MESMO (ref+subject) → exit 0.
NOW0=1000000   # bucket = 1000000/60 = 16666
assert_case "1st-in-window→0"            0 "" -- rl "$NOW0" cockpit gustavo@x
assert_case "2nd-in-window→0"            0 "" -- rl "$NOW0" cockpit gustavo@x
assert_case "3rd(=MAX)-in-window→0"      0 "" -- rl "$NOW0" cockpit gustavo@x
# o (MAX+1)-ésimo na MESMA janela (mesmo NOW0, mesmo ref+subject) → rate-limited
assert_case "4th(MAX+1)-same-window→3"   3 "rate-limited" -- rl "$NOW0" cockpit gustavo@x

# ───────────────────────── janela reseta ao avançar `now` ─────────────────────────
# NOW1 cai na PRÓXIMA janela (bucket+1) → contador zera → volta a passar.
NOW1=$(( NOW0 + 60 ))   # bucket 16667
assert_case "next-window-resets→0"       0 "" -- rl "$NOW1" cockpit gustavo@x

# ───────────────────────── independência por subject e por ref ─────────────────────────
# subject DIFERENTE no MESMO bucket de NOW0 (onde gustavo@x já estourou) → contador próprio, passa.
assert_case "diff-subject-independent→0" 0 "" -- rl "$NOW0" cockpit outro@y
# ref DIFERENTE no MESMO bucket de NOW0 → contador próprio, passa.
assert_case "diff-ref-independent→0"     0 "" -- rl "$NOW0" planning gustavo@x

# ───────────────────────── invocação inválida ─────────────────────────
assert_case "no-subcommand→2"            2 "" -- bash "$LIB"
assert_case "missing-subject→2"          2 "" -- bash "$LIB" check cockpit

# ───────────────────────── FAIL-CLOSED: store não-gravável ─────────────────────────
# parent read-only → mkdir do store falha → não dá p/ contar → NÃO deixa passar (exit 4).
rl_store_ro() {
  local roparent="$WORK/ro"; mkdir -p "$roparent"; chmod 555 "$roparent"
  IDEIAOS_RATELIMIT_STORE="$roparent/store" IDEIAOS_RL_NOW="$NOW0" bash "$LIB" check cockpit z@z
  local rc=$?
  chmod 755 "$roparent" 2>/dev/null || true   # restaura p/ cleanup
  return "$rc"
}
assert_case "store-unwritable→fail-closed(4)" 4 "store-unwritable" -- rl_store_ro

# ───────────────────────── INVARIANTE: defesa SECUNDÁRIA, não autorizador ─────────────────────────
# Prova que `check` exit 0 NÃO concede autoridade: o pipeline real exige verify-payload ANTES.
#   (1) o stdout de um `check` que passa NÃO carrega token/role/OK-autorizador (só "não-negado");
#   (2) a lib referencia verify-payload/R-WP como a autoridade (rate-limit só nega, nunca concede).
rl_secondary_not_authorizer() {
  local fresh="$WORK/sec"; rm -rf "$fresh"
  local out; out=$(IDEIAOS_RATELIMIT_STORE="$fresh" IDEIAOS_RL_NOW="$NOW0" bash "$LIB" check cockpit sec@sec 2>/dev/null)
  # (1) passar no throttle não emite nada que pareça concessão de autoridade
  printf '%s' "$out" | grep -qiE 'authorized|granted|role=|token|OK ' && { echo "REASON=throttle-emits-authorization" >&2; return 1; }
  # (2) a própria lib documenta que a autorização é verify-payload (defesa secundária, nega-nunca-concede)
  grep -q 'verify-payload' "$LIB" || { echo "REASON=lib-omits-primary-authorizer" >&2; return 1; }
  grep -qi 'nega' "$LIB" || { echo "REASON=lib-omits-deny-only-stance" >&2; return 1; }
  return 0
}
assert_case "secondary-not-authorizer"   0 "" -- rl_secondary_not_authorizer

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o comparador DETECTA mecanismo quebrado: um veneno REAL (4º check = rate-limited, exit 3)
# avaliado contra expect=0 TEM que dar miss; e contra expect=3+REASON TEM que dar match. Se um veneno
# passasse como "esperado 0", o gate seria teatro.
canary() {
  local cdir="$WORK/can"; rm -rf "$cdir"
  local cn=7000000
  IDEIAOS_RATELIMIT_STORE="$cdir" rl "$cn" cockpit can@c >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$cdir" rl "$cn" cockpit can@c >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$cdir" rl "$cn" cockpit can@c >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$cdir" rl "$cn" cockpit can@c 2>"$WORK/canErr"; local rc=$?   # 4º = veneno (exit 3)
  if _cmp "$rc" "$WORK/canErr" 0 ""; then echo "REASON=canary-false-pass (gate aceitaria veneno como ok)" >&2; return 1; fi
  if ! _cmp "$rc" "$WORK/canErr" 3 "rate-limited"; then echo "REASON=canary-cant-detect-real (rc=$rc)" >&2; return 1; fi
  return 0
}
assert_case "CANARY detects-broken-not-just-absent" 0 "" -- canary

# ───────────────────────── parcial: veredito + MUTAÇÃO ─────────────────────────
partial_verdict() {
  echo "─────────────────────────────────────────────"
  echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)"
  local rc=0
  [ "$CASES_RUN" -ne "$EXPECTED_CASES" ] && { c_red "✗ MANIFESTO violado: run=$CASES_RUN != $EXPECTED_CASES"; rc=1; }
  [ "$FAIL" -ne 0 ] && { c_red "✗ falhou:$FAILED_NAMES"; rc=1; }
  return "$rc"
}

# (d) MUTAÇÃO — prova que o gate PEGA uma lib sabotada e ACEITA a lib correta.
#   Sabotagem: zerar a janela (bucket sempre 0) faz o reset-de-janela e o limite por-janela colapsarem,
#   mas a sabotagem cirúrgica aqui ataca o CONTADOR: comentar a persistência → cada check vê cur=0 →
#   o flood NUNCA é detectado (4º check vira exit 0). O caso "4th(MAX+1)" TEM que virar vermelho.
mutation_probe() {
  local mut="$WORK/rate-limit.mut.sh"
  # cópia sabotada: neutraliza a persistência do contador (substitui o incremento por new=1 fixo).
  sed 's/    new=$(( cur + 1 ))/    new=1   # MUTATION: contador nunca acumula → flood passa/' "$LIB" > "$mut"
  # roda o cenário do flood contra a cópia MUTANTE: 4 checks na mesma janela
  local mdir="$WORK/mutdir"; rm -rf "$mdir"
  IDEIAOS_RATELIMIT_STORE="$mdir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$mut" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$mdir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$mut" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$mdir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$mut" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$mdir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$mut" check cockpit m@m >/dev/null 2>&1; local mrc=$?
  rm -f "$mut"
  # lib MUTANTE: o 4º check NÃO é mais rate-limited (mrc=0) → a mutação ESCAPOU à detecção do mecanismo
  if [ "$mrc" = "3" ]; then echo "  (mutação: sabotagem do contador foi detectada — esperado mrc!=3, got 3)"; return 1; fi
  # lib RESTAURADA (original): o 4º check VOLTA a ser rate-limited (rc=3)
  local odir="$WORK/origdir"; rm -rf "$odir"
  IDEIAOS_RATELIMIT_STORE="$odir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$LIB" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$odir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$LIB" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$odir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$LIB" check cockpit m@m >/dev/null 2>&1
  IDEIAOS_RATELIMIT_STORE="$odir" IDEIAOS_RL_NOW="$NOW0" IDEIAOS_RL_MAX=3 bash "$LIB" check cockpit m@m >/dev/null 2>&1; local orc=$?
  [ "$orc" = "3" ] || { echo "  (mutação: lib restaurada deveria recusar o flood — esperado orc=3, got $orc)"; return 1; }
  return 0
}

echo "─── mutação (sabota o contador → flood passa → vermelho; restaura → verde) ───"
if mutation_probe; then
  echo "  ✓ MUTAÇÃO: lib sabotada deixa o flood passar (gate pegaria); lib restaurada recusa o flood"
  MUT_OK=0
else
  echo "  ✗ MUTAÇÃO: o gate não distingue lib sabotada de lib correta"
  MUT_OK=1
fi

# ───────────────────────── veredito final ─────────────────────────
rc=0
partial_verdict || rc=1
[ "${MUT_OK:-1}" -ne 0 ] && rc=1

if [ "$rc" -eq 0 ]; then
  c_green "OK rate-limit $PASS/$EXPECTED_CASES"
else
  c_red "✗ rate-limit gate vermelho"
fi
exit "$rc"
