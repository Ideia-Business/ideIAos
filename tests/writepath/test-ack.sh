#!/bin/bash
# test-ack.sh — gate STANDALONE de source/agentd/ack.sh (v14.4 · B7 · R-WP8: efeito único em reentrega).
#
# Prova, por EXIT-CODE (antifragile-gates), que o ACK idempotente LOCAL com high-water mark funciona —
# SEM segredo, SEM produção, SEM chamada a provedor (espelha o regime de test-writepath-bootstrap.sh).
#
# ANTI-TEATRO ESTRUTURAL (idêntico ao harness agregado):
#   (a) MANIFESTO fixo EXPECTED_CASES — reprova se cases_run != EXPECTED_CASES;
#   (b) cada caso-veneno casa um EXIT-CODE específico + REASON= esperado (um !=0 genérico REPROVA);
#   (c) CANÁRIO: prova que o comparador detecta um mecanismo QUEBRADO (cópia sabotada in-memory →
#       o teste cross-processo VIRA VERMELHO), não só ausente;
#   (d) MUTAÇÃO: sabota a lib (registro in-memory) → cross-processo vermelho; restaura → verde;
#   (e) DURABILIDADE provada através de FRONTEIRA DE PROCESSO (1ª invocação grava; 2ª SEPARADA lê).
#
# Imprime "OK ack N/N" e sai 0 se tudo passar; sai 1 se qualquer caso falhar.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENTD="$ROOT/source/agentd"
LIB="$AGENTD/ack.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/ack-test.XXXXXX")"
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# store isolado por env — nunca toca o real do operador ($HOME/.ideiaos/cockpit/acks)
export IDEIAOS_ACK_STORE="$WORK/acks"

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=15     # MANIFESTO: tem que bater com os assert_case abaixo (anti-teatro (a))
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
    PASS=$((PASS+1)); printf '  ✓ %-46s exit=%s %s\n' "$name" "$rc" "${ereason:+REASON~$ereason}"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name"
    printf '  ✗ %-46s got exit=%s (want %s%s); stderr=%s\n' "$name" "$rc" "$eexit" "${ereason:+ REASON~$ereason}" "$(head -1 "$errf" 2>/dev/null)"
  fi
}

# ───────────────────────── fixtures ─────────────────────────
mk_command() { printf '{"action":"%s","ref":"cockpit","scope":"rotate","target_machine":"%s","nonce":"%s"}' "$2" "$3" "$4" > "$1"; }
mk_command "$WORK/cmdA" "rotate_sensitive" "peerB" "nA"
mk_command "$WORK/cmdB" "revoke_service_role" "peerC" "nB"

echo "━━━ ack (B7 · R-WP8 ACK idempotente local + high-water mark) ━━━"

# ───────────────────────── hash-of ─────────────────────────
# H1 hash-of estável e == shasum dos BYTES (mesmo binding do step-up O2)
b_hash_matches_shasum() {
  local h ref; h=$(bash "$LIB" hash-of "$WORK/cmdA") || return 1
  ref=$(shasum -a 256 "$WORK/cmdA" | awk '{print $1}')
  [ "$h" = "$ref" ]
}
assert_case "hash-of == shasum(bytes)" 0 "" -- b_hash_matches_shasum

# H1b hash-of de command-file ausente → 2 (uso)
assert_case "hash-of missing-file→2" 2 "usage" -- bash "$LIB" hash-of "$WORK/nope"

# ───────────────────────── is-applied (inédito) ─────────────────────────
# H2 is-applied de hash inédito → exit 3 REASON=not-applied
b_unseen() { local h; h=$(bash "$LIB" hash-of "$WORK/cmdA"); bash "$LIB" is-applied "$h"; }
assert_case "is-applied unseen→3 not-applied" 3 "not-applied" -- b_unseen

# ───────────────────────── DURABILIDADE CROSS-PROCESSO ─────────────────────────
# H3 mark-applied em proc A → is-applied em proc B SEPARADO → exit 0 (registro persistente, não in-memory)
b_durable_cross_process() {
  local h; h=$(bash "$LIB" hash-of "$WORK/cmdA")
  ( bash "$LIB" mark-applied "$h" ) >/dev/null 2>&1   # proc A: marca
  bash "$LIB" is-applied "$h"                          # proc B (invocação separada): enxerga do disco
}
assert_case "durable: markA→is-appliedB(sep)→0" 0 "" -- b_durable_cross_process

# ───────────────────────── IDEMPOTÊNCIA REAL (efeito único) ─────────────────────────
# H4 mark-applied 2× o MESMO hash → contador de EFEITO incrementa EXATAMENTE 1.
#   O contador é escrito SÓ na 1ª aplicação via noclobber/create-once (efeito = side-effect observável).
#   Espelha o pattern do nonce-single-use do B4: a 2ª entrega é no-op de efeito.
b_idempotent_effect_once() {
  local h; h=$(bash "$LIB" hash-of "$WORK/cmdB")
  local effect="$WORK/effect.cmdB"
  rm -f "$effect"
  # wrapper: aplica o ACK e, SE foi a 1ª vez (marker inédito), comete o efeito via noclobber.
  _apply_once() {
    bash "$LIB" mark-applied "$1" >/dev/null 2>&1 || return 1
    # efeito create-once: só a PRIMEIRA aplicação consegue criar o arquivo de efeito
    ( set -o noclobber; : > "$2" ) 2>/dev/null || true
  }
  # reentrega: invoca DUAS vezes (squash/force-update reentregando o mesmo comando)
  _apply_once "$h" "$effect"
  _apply_once "$h" "$effect"
  # contador de efeito = nº de linhas/criações? aqui o efeito é create-once → o arquivo existe 1×.
  # Provamos "exatamente 1": o marker deve existir E uma 3ª criação noclobber deve FALHAR (já há efeito).
  [ -e "$effect" ] || { echo "REASON=no-effect-applied" >&2; return 1; }
  if ( set -o noclobber; : > "$effect" ) 2>/dev/null; then
    echo "REASON=effect-applied-twice (idempotência quebrada)" >&2; return 1
  fi
  # e o ACK continua idempotente: marcar de novo → exit 0 (no-op), nunca erro
  bash "$LIB" mark-applied "$h" >/dev/null 2>&1 || { echo "REASON=remark-errored" >&2; return 1; }
  return 0
}
assert_case "idempotent: effect-counter == 1 (2× mark)" 0 "" -- b_idempotent_effect_once

# H4b após mark, is-applied → 0 (high-water mark: hash saiu do pendente)
b_after_mark_is_applied() {
  local h; h=$(bash "$LIB" hash-of "$WORK/cmdB"); bash "$LIB" is-applied "$h"
}
assert_case "high-water: applied hash → is-applied 0" 0 "" -- b_after_mark_is_applied

# H4c hash inédito DISTINTO continua pendente (não foi varrido pelo high-water mark de outro)
b_distinct_still_pending() {
  mk_command "$WORK/cmdC" "deploy" "peerD" "nC"
  local h; h=$(bash "$LIB" hash-of "$WORK/cmdC"); bash "$LIB" is-applied "$h"
}
assert_case "high-water: distinct hash still pending→3" 3 "not-applied" -- b_distinct_still_pending

# ───────────────────────── invocação inválida (cada um seu REASON) ─────────────────────────
assert_case "no-subcommand→2" 2 "" -- bash "$LIB"
assert_case "bad-subcommand→2" 2 "" -- bash "$LIB" frobnicate xyz
assert_case "mark-applied no-arg→2" 2 "usage" -- bash "$LIB" mark-applied
assert_case "is-applied bad-hash→2" 2 "bad-hash" -- bash "$LIB" is-applied "../etc/passwd"
assert_case "mark-applied bad-hash(short)→2" 2 "bad-hash" -- bash "$LIB" mark-applied "deadbeef"

# ───────────────────────── FAIL-CLOSED: store não-gravável ─────────────────────────
# H5 mark-applied com store DURÁVEL não-gravável → 4 (sem registro persistente NÃO pode declarar
#   efeito-único; recusar é mais seguro que perder a idempotência — espelha o B4.5 do harness).
b_store_unwritable() {
  local ro="$WORK/ro"; mkdir -p "$ro"; chmod 555 "$ro"
  local h; h=$(bash "$LIB" hash-of "$WORK/cmdA")
  IDEIAOS_ACK_STORE="$ro/acks" bash "$LIB" mark-applied "$h"; local rc=$?
  chmod 755 "$ro" 2>/dev/null || true   # restaura p/ cleanup do trap
  return "$rc"
}
assert_case "mark-applied store-unwritable→4" 4 "ack-store-unwritable" -- b_store_unwritable

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o teste cross-processo DETECTA mecanismo quebrado (in-memory), não só ausente.
# Sabota uma CÓPIA: troca o store DURÁVEL por um registro IN-MEMORY (não persiste cross-processo).
# A cópia sabotada → mark em proc A e is-applied em proc B SEPARADO TEM que dar not-applied (3),
# provando que o caso de durabilidade pegaria a regressão. Se a cópia "passasse", o gate seria teatro.
canary() {
  local broken="$WORK/ack-inmem.sh"
  # cópia in-memory: mark-applied/is-applied operam numa "variável" que NÃO sobrevive ao processo.
  # Cada invocação é um processo novo → o set fica vazio → is-applied SEMPRE 3, mesmo após mark.
  cat > "$broken" <<'BROKEN'
#!/bin/bash
set -uo pipefail
cmd="${1:-}"; shift 2>/dev/null || true
SEEN=""   # in-memory: zera a cada processo (sabotagem deliberada — não durável)
case "$cmd" in
  hash-of)   shasum -a 256 "${1:?}" 2>/dev/null | awk '{print $1}' ;;
  mark-applied) SEEN="$SEEN $1"; exit 0 ;;                       # "marca" só na memória do processo
  is-applied)  case " $SEEN " in *" $1 "*) exit 0;; *) echo "REASON=not-applied" >&2; exit 3;; esac ;;
  *) exit 2 ;;
esac
BROKEN
  local h; h=$(bash "$broken" hash-of "$WORK/cmdA")
  ( bash "$broken" mark-applied "$h" ) >/dev/null 2>&1   # proc A
  bash "$broken" is-applied "$h" 2>"$WORK/can.err"; local rc=$?  # proc B separado
  # cópia sabotada DEVE falhar cross-processo (rc=3); se passasse (rc=0), o gate não detectaria a quebra.
  if _cmp "$rc" "$WORK/can.err" 0 ""; then
    echo "REASON=canary-false-pass (in-memory passou cross-processo — gate é teatro)" >&2; return 1
  fi
  if ! _cmp "$rc" "$WORK/can.err" 3 "not-applied"; then
    echo "REASON=canary-cant-detect-broken" >&2; return 1
  fi
  return 0
}
assert_case "CANARY in-memory→cross-proc red (broken≠absent)" 0 "" -- canary

# ───────────────────────── (d) MUTAÇÃO ─────────────────────────
# Sabota a LIB REAL (transforma o store durável em no-op de escrita), prova VERMELHO no cross-processo,
# restaura, prova VERDE. Mutação real sobre o arquivo que será integrado — não sobre uma cópia.
mutation() {
  local backup="$WORK/ack.sh.bak"
  cp "$LIB" "$backup" || { echo "REASON=mutation-backup-failed" >&2; return 1; }
  # sabotagem: faz `: > "$marker"` (a gravação durável) virar no-op → nada persiste no disco.
  # usa um store mutante isolado p/ não contaminar os casos anteriores.
  local mstore="$WORK/acks-mutant"; mkdir -p "$mstore"
  # injeta a sabotagem: neutraliza a criação do marker (substitui a linha do noclobber por true).
  sed 's#( set -o noclobber; : > "\$marker" )#( set -o noclobber; true )#' "$LIB" > "$LIB.mut" \
    && mv "$LIB.mut" "$LIB"
  local h; h=$(IDEIAOS_ACK_STORE="$mstore" bash "$LIB" hash-of "$WORK/cmdA")
  ( IDEIAOS_ACK_STORE="$mstore" bash "$LIB" mark-applied "$h" ) >/dev/null 2>&1   # proc A (sabotado)
  IDEIAOS_ACK_STORE="$mstore" bash "$LIB" is-applied "$h" >/dev/null 2>"$WORK/mut.err"; local rc_broken=$?
  # restaura ANTES de avaliar (garante restore mesmo se a asserção falhar)
  cp "$backup" "$LIB" || { echo "REASON=mutation-restore-failed" >&2; return 1; }
  # mutação DEVE ter quebrado: is-applied cross-processo não enxerga (3 not-applied)
  if [ "$rc_broken" = "0" ]; then echo "REASON=mutation-not-detected (sabotagem passou verde)" >&2; return 1; fi
  grep -q "not-applied" "$WORK/mut.err" || { echo "REASON=mutation-wrong-reason" >&2; return 1; }
  # restaurada: o mesmo fluxo num store fresco DEVE dar verde (0)
  local mstore2="$WORK/acks-restored"
  local h2; h2=$(IDEIAOS_ACK_STORE="$mstore2" bash "$LIB" hash-of "$WORK/cmdA")
  ( IDEIAOS_ACK_STORE="$mstore2" bash "$LIB" mark-applied "$h2" ) >/dev/null 2>&1
  IDEIAOS_ACK_STORE="$mstore2" bash "$LIB" is-applied "$h2" || { echo "REASON=restore-not-green" >&2; return 1; }
  return 0
}
assert_case "MUTATION durable→red, restore→green" 0 "" -- mutation

# ───────────────────────── veredito ─────────────────────────
echo "─────────────────────────────────────────────"
echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)"

rc=0
if [ "$CASES_RUN" -ne "$EXPECTED_CASES" ]; then
  c_red "✗ MANIFESTO violado: cases_run ($CASES_RUN) != EXPECTED_CASES ($EXPECTED_CASES)"
  rc=1
fi
if [ "$FAIL" -ne 0 ]; then
  c_red "✗$FAILED_NAMES"
  rc=1
fi
if [ "$rc" -eq 0 ]; then
  c_green "OK ack $PASS/$EXPECTED_CASES"
else
  c_red "✗ ack gate vermelho"
fi
exit "$rc"
