#!/bin/bash
# test-ledger.sh — prova standalone (por EXIT-CODE) do ledger hash-chained append-only LOCAL
#   (v14.4 · B6 / R-WP9: não-repúdio com detecção de reescrita).
#
# ANTI-TEATRO (antifragile-gates — o veredito é o exit-code, nunca o Read tool):
#   • cada caso casa um EXIT-CODE específico + REASON= nomeado (um !=0 genérico NÃO conta);
#   • MANIFESTO fixo (EXPECTED_CASES) — reprova se cases_run != EXPECTED_CASES;
#   • CANÁRIO: prova que o comparador detecta um mecanismo QUEBRADO (não só ausente) —
#     um caso-veneno avaliado contra "expect 0" TEM que dar FAIL, contra "expect 3" PASS;
#   • MUTAÇÃO: sabota a checagem de prev_hash numa CÓPIA da lib → o caso "editar entrada do
#     meio" VIRA VERMELHO (verify passa onde não devia) → prova que o teste detecta a QUEBRA;
#     restaura a lib íntegra → verde.
#
# credential-isolation: store isolado por env (IDEIAOS_LEDGER_STORE) — NUNCA toca o real do
#   operador, NUNCA no working tree. Fixtures efêmeras em /tmp, descartadas. ZERO provedor.
#
# Imprime "OK ledger N/N" e sai 0 se tudo passar; sai 1 se qualquer caso falhar.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LEDGER="$ROOT/source/agentd/ledger.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-ledger.XXXXXX")"
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# store isolado por env (nunca toca o real do operador, nunca o working tree)
export IDEIAOS_LEDGER_STORE="$WORK/ledger"

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=9     # MANIFESTO — TEM que bater com os assert_case abaixo
FAILED_NAMES=""

c_green(){ printf '\033[0;32m%s\033[0m\n' "$1"; }
c_red(){ printf '\033[0;31m%s\033[0m\n' "$1"; }

# comparador: rc==expect_exit E (sem REASON esperado OU stderr contém REASON). 0=match,1=miss.
_cmp() { local rc="$1" errf="$2" eexit="$3" ereason="$4"
  [ "$rc" = "$eexit" ] || return 1
  [ -z "$ereason" ] && return 0
  grep -qF "$ereason" "$errf" 2>/dev/null
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

SUBJ="gustavo@redeideia.com.br"

# assinaturas realistas (longas, como uma Ed25519 destacada) — exercitam o redact real do `print`.
SIG_A="MEUCIQDaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaSIG-A-FULL-VALUE-9001"
SIG_B="MEUCIQDbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbSIG-B-FULL-VALUE-9002"
SIG_C="MEUCIQDccccccccccccccccccccccccccccccccccccccccccccSIG-C-FULL-VALUE-9003"

# fresh_chain <store> — popula um store com 3 entradas íntegras encadeadas.
fresh_chain() {
  local store="$1"; : > "$store"
  IDEIAOS_LEDGER_STORE="$store" bash "$LEDGER" append "$SUBJ" cto rotate_sensitive    cockpit rotate ok "$SIG_A" >/dev/null 2>&1
  IDEIAOS_LEDGER_STORE="$store" bash "$LEDGER" append "$SUBJ" cto revoke_service_role cockpit revoke ok "$SIG_B" >/dev/null 2>&1
  IDEIAOS_LEDGER_STORE="$store" bash "$LEDGER" append "$SUBJ" cto deploy_prod         cockpit deploy ok "$SIG_C" >/dev/null 2>&1
}

echo "━━━ ledger B6 gate (R-WP9 — hash-chained append-only LOCAL) ━━━"

# ───────────────────────── casos positivos ─────────────────────────
# 1) append 3 entradas → store tem exatamente 3 linhas (prova append durável).
c_append_three() {
  fresh_chain "$IDEIAOS_LEDGER_STORE"
  local n; n=$(wc -l < "$IDEIAOS_LEDGER_STORE" | tr -d ' ')
  [ "$n" = "3" ] || { echo "REASON=append-count n=$n (want 3)" >&2; return 1; }
  # genesis (1ª entrada) usa prev_hash = 64 zeros
  head -1 "$IDEIAOS_LEDGER_STORE" | cut -d'|' -f1 | grep -qE '^0{64}$' || { echo "REASON=genesis-not-zeros" >&2; return 1; }
  return 0
}
assert_case "append-3-entries (durável + genesis)" 0 "" -- c_append_three

# 2) verify cadeia íntegra → exit 0
c_verify_intact() { fresh_chain "$IDEIAOS_LEDGER_STORE"; bash "$LEDGER" verify; }
assert_case "verify-intact-chain→0" 0 "" -- c_verify_intact

# 3) print ecoa as 3 entradas SEM expor a signature por inteiro (não vaza o valor cru).
c_print_redacts() {
  fresh_chain "$IDEIAOS_LEDGER_STORE"
  local out; out=$(bash "$LEDGER" print 2>/dev/null)
  printf '%s\n' "$out" | grep -q 'action=rotate_sensitive' || { echo "REASON=print-missing-entry" >&2; return 1; }
  # a signature crua NÃO pode aparecer por inteiro na saída de print (só um prefixo curto + …)
  printf '%s\n' "$out" | grep -qF "$SIG_B" && { echo "REASON=print-leaks-signature" >&2; return 1; }
  printf '%s\n' "$out" | grep -qF "$(printf '%s' "$SIG_B" | cut -c1-8)" || { echo "REASON=print-missing-sig-prefix" >&2; return 1; }
  return 0
}
assert_case "print-redacts-signature" 0 "" -- c_print_redacts

# ───────────────────────── casos-veneno (cadeia quebrada → 3) ─────────────────────────
# 4) editar 1 campo de uma entrada do MEIO → verify 3 chain-broken
c_edit_middle() {
  local s="$WORK/edit"; fresh_chain "$s"
  sed -i.bak '2s/revoke_service_role/TAMPERED_ACTION/' "$s"; rm -f "$s.bak"
  IDEIAOS_LEDGER_STORE="$s" bash "$LEDGER" verify
}
assert_case "edit-middle-field→3" 3 "chain-broken" -- c_edit_middle

# 5) remover a 2ª entrada → verify 3 chain-broken
c_remove_second() {
  local s="$WORK/rm2"; fresh_chain "$s"
  sed -i.bak '2d' "$s"; rm -f "$s.bak"
  IDEIAOS_LEDGER_STORE="$s" bash "$LEDGER" verify
}
assert_case "remove-2nd-entry→3" 3 "chain-broken" -- c_remove_second

# 6) adulterar um prev_hash gravado → verify 3 chain-broken
c_tamper_prevhash() {
  local s="$WORK/ph"; fresh_chain "$s"
  sed -i.bak '3s/^[0-9a-f]\{4\}/dead/' "$s"; rm -f "$s.bak"   # corrompe o prev_hash da entrada #3
  IDEIAOS_LEDGER_STORE="$s" bash "$LEDGER" verify
}
assert_case "tamper-stored-prev_hash→3" 3 "chain-broken" -- c_tamper_prevhash

# ───────────────────────── bad-field (sanitização) ─────────────────────────
# 7) append com '|' embutido num campo → exit 2 bad-field
c_bad_pipe() { bash "$LEDGER" append "ev|il" cto x cockpit y ok; }
assert_case "bad-field-pipe→2" 2 "bad-field" -- c_bad_pipe

# 8) append com control-char (newline) embutido → exit 2 bad-field
c_bad_ctrl() { bash "$LEDGER" append "$(printf 'a\nb')" cto x cockpit y ok; }
assert_case "bad-field-control-char→2" 2 "bad-field" -- c_bad_ctrl

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o COMPARADOR detecta um mecanismo quebrado: um veneno REAL (entrada do meio
# editada → verify exit 3) avaliado contra expect=0 TEM que dar FAIL; contra expect=3 PASS.
# Se um veneno passasse como "esperado 0", o gate seria teatro.
canary() {
  local s="$WORK/canary"; fresh_chain "$s"
  sed -i.bak '2s/revoke_service_role/EVIL/' "$s"; rm -f "$s.bak"
  IDEIAOS_LEDGER_STORE="$s" bash "$LEDGER" verify 2>"$WORK/canErr"; local rc=$?
  # o comparador DEVE rejeitar "expect 0" e aceitar "expect 3 + REASON"
  if _cmp "$rc" "$WORK/canErr" 0 ""; then echo "REASON=canary-false-pass (gate aceitaria veneno como ok)" >&2; return 1; fi
  if ! _cmp "$rc" "$WORK/canErr" 3 "chain-broken"; then echo "REASON=canary-cant-detect-real (rc=$rc)" >&2; return 1; fi
  return 0
}
assert_case "CANARY detects-broken-not-just-absent" 0 "" -- canary

# ───────────────────────── (mutação) sabota a lib → vermelho → restaura → verde ─────────────────────────
# Sabota a CHECAGEM de prev_hash numa CÓPIA da lib (verify vira no-op de comparação): o caso
# "editar entrada do meio" — que num verify íntegro dá exit 3 — passa a dar exit 0. Isso PROVA
# que o teste detecta a QUEBRA do mecanismo, não só sua ausência. Restaurada → volta a exit 3.
MUT_OK=0
mutation_proof() {
  local mlib="$WORK/ledger.mut.sh"
  cp "$LEDGER" "$mlib"
  # neutraliza o `exit 3` do verify (a única ramificação que aborta a cadeia quebrada) → no-op
  sed -i.bak 's/echo "REASON=chain-broken (entrada #\$n: prev_hash gravado != sha256 da anterior)" >&2; exit 3/: ignora-quebra/' "$mlib"
  rm -f "$mlib.bak"

  local s="$WORK/mut-store"; fresh_chain "$s"
  sed -i.bak '2s/revoke_service_role/EVIL/' "$s"; rm -f "$s.bak"   # entrada do meio editada

  # lib SABOTADA: verify de cadeia quebrada deve dar exit 0 (FALSO-VERDE) → prova red-when-broken
  IDEIAOS_LEDGER_STORE="$s" bash "$mlib" verify >/dev/null 2>&1; local rc_mut=$?
  if [ "$rc_mut" != "0" ]; then
    echo "REASON=mutation-not-effective (lib sabotada ainda recusou rc=$rc_mut)" >&2; return 1
  fi
  # lib ÍNTEGRA: o MESMO store quebrado deve dar exit 3 → verde após restore
  IDEIAOS_LEDGER_STORE="$s" bash "$LEDGER" verify >/dev/null 2>&1; local rc_real=$?
  if [ "$rc_real" != "3" ]; then
    echo "REASON=restore-not-green (lib íntegra não pegou a quebra rc=$rc_real)" >&2; return 1
  fi
  MUT_OK=1
  return 0
}
# (não conta como assert_case do manifesto: é meta-prova do próprio teste; reportada à parte)
echo "─────────────────────────────────────────────"
if mutation_proof; then c_green "✓ MUTAÇÃO: lib sabotada → falso-verde (rc=0); lib restaurada → vermelho (rc=3) — o teste detecta a QUEBRA"; \
  else c_red "✗ MUTAÇÃO falhou — o teste NÃO prova detecção da quebra"; fi

# ───────────────────────── veredito ─────────────────────────
echo "─────────────────────────────────────────────"
echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)  mutação_ok=$MUT_OK"

rc=0
if [ "$CASES_RUN" -ne "$EXPECTED_CASES" ]; then
  c_red "✗ MANIFESTO violado: cases_run ($CASES_RUN) != EXPECTED_CASES ($EXPECTED_CASES) — caso somido/extra"; rc=1
fi
if [ "$FAIL" -ne 0 ]; then
  c_red "✗ $FAIL caso(s) falharam:$FAILED_NAMES"; rc=1
fi
if [ "$MUT_OK" -ne 1 ]; then
  c_red "✗ MUTAÇÃO não provou detecção da quebra"; rc=1
fi
if [ "$rc" -eq 0 ]; then
  c_green "OK ledger $PASS/$EXPECTED_CASES"
else
  c_red "✗ ledger gate vermelho"
fi
exit "$rc"
