#!/bin/bash
# test-seal.sh — prova standalone (por EXIT-CODE) do SELO do canal de comando v14.4
#   (docs/decisions/v14.4-command-ref-origin-exposure.md, ACEITO — sealed-box X25519 nativo,
#    ordem cripto `assina(P) → sela(P‖sig)`, destinatário SÓ dentro do ciphertext).
#
# ANTI-TEATRO (antifragile-gates — o veredito é o exit-code, nunca o Read tool):
#   • cada caso casa um EXIT-CODE específico (e REASON= nomeado quando aplicável);
#   • MANIFESTO fixo (EXPECTED_CASES) — reprova se cases_run != EXPECTED_CASES;
#   • CANÁRIO: prova que o comparador detecta um mecanismo QUEBRADO (não só ausente) —
#     um caso-veneno (tamper → unseal exit 3) avaliado contra "expect 0" TEM que dar FAIL, contra "expect 3" PASS;
#   • MUTAÇÃO: sabota a verificação AEAD numa CÓPIA do unseal → o caso (e) tamper VIRA FALSO-VERDE
#     (unseal aceita ciphertext adulterado); restaura → vermelho. Prova que (e) detecta a QUEBRA.
#
# credential-isolation: store/keys isolados em mktemp /tmp — NUNCA tocam ~/.ideiaos nem o repo vivo.
#   ZERO dep externa (X25519/HKDF/AES-GCM nativos de node:crypto). ZERO provedor.
#
# Imprime "OK seal N/N" e sai 0 se tudo passar; sai 1 se qualquer caso falhar.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
AGENTD="$ROOT/source/agentd"
SEAL="$AGENTD/seal.mjs"
UNSEAL="$AGENTD/unseal.mjs"
PK="$AGENTD/pinned-keys.sh"
SIGN="$AGENTD/sign-payload.sh"
VERIFY="$AGENTD/verify-payload.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/test-seal.XXXXXX")"
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# store de pin ISOLADO (nunca toca o real do operador, nunca o working tree)
export IDEIAOS_PINNED_STORE="$WORK/pinned"

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=7    # MANIFESTO — TEM que bater com os assert_case abaixo (a–f + retrocompat; canário/mutação reportados à parte)
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
    PASS=$((PASS+1)); printf '  ✓ %-46s exit=%s %s\n' "$name" "$rc" "${ereason:+REASON~$ereason}"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name"
    printf '  ✗ %-46s got exit=%s (want %s%s); stderr=%s\n' "$name" "$rc" "$eexit" "${ereason:+ REASON~$ereason}" "$(head -1 "$errf" 2>/dev/null)"
  fi
}

# gen_enckey <name> — gera um par X25519 via node (NATIVO, zero dep): grava <name>.encpub (raw b64,
#   1 linha) e <name>.encpriv (pkcs8 b64, 1 linha). Espelha o estilo gen-keypair do fake backend.
gen_enckey() {
  node -e '
    const c = require("node:crypto");
    const kp = c.generateKeyPairSync("x25519");
    const pubRaw = Buffer.from(kp.publicKey.export({format:"jwk"}).x, "base64url");
    const pkcs8 = kp.privateKey.export({format:"der", type:"pkcs8"});
    const fs = require("node:fs");
    fs.writeFileSync(process.argv[1], pubRaw.toString("base64") + "\n");
    fs.writeFileSync(process.argv[2], Buffer.from(pkcs8).toString("base64") + "\n");
  ' "$WORK/$1.encpub" "$WORK/$1.encpriv"
}

# ───────────────────────── setup de fixtures ─────────────────────────
# signing-key (Ed25519, igual ao B0 do bootstrap) p/ a máquina-origem peerA
ssh-keygen -t ed25519 -N '' -C peerA -f "$WORK/peerA" -q >/dev/null 2>&1
# enc-keypairs X25519 (separação de chave): targetT = destinatário pinado; otherO = privkey diferente
gen_enckey targetT
gen_enckey otherO
# pin LOCAL: peerA (role cto) com signing-pubkey (campo 4) E enc_pubkey (campo 5, B0-bis 4º arg)
bash "$PK" add peerA cto "$WORK/peerA.pub" "$WORK/targetT.encpub" >/dev/null 2>&1

# payload de comando (command-file producer-canonical; inclui target_machine p/ binding cross-máquina)
MID_TARGET="machineT-7f3a"   # mid conhecido do destinatário (usado no caso (c) grep)
printf '{"action":"rotate_sensitive","ref":"cockpit","scope":"rotate","target_machine":"%s","nonce":"nSEAL"}' "$MID_TARGET" > "$WORK/payload"

export IDEIAOS_SIGN_KEY="$WORK/peerA"

# enc_pubkey raw b64 do destinatário, resolvida SÓ do pin local (B0-bis)
ENCPUB_FROM_PIN="$WORK/encpub_from_pin"
bash "$PK" enc-pubkey-of peerA > "$ENCPUB_FROM_PIN" 2>/dev/null

echo "━━━ SEAL gate (canal de comando v14.4 — sealed-box X25519, assina→sela) ━━━"

# ───────────────────────── (a) round-trip assina→sela ─────────────────────────
# assina(payload) → sela(payload‖sig) à enc_pubkey pinada → deslacra → payload'==payload BYTE-A-BYTE
# E verify-payload.sh(payload', sig') exit 0. É a ÚNICA ordem que passa.
a_roundtrip() {
  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1 || { echo "REASON=sign-failed" >&2; return 1; }
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob" || { echo "REASON=seal-failed" >&2; return 1; }
  node "$UNSEAL" "$WORK/blob" "$WORK/targetT.encpriv" "$WORK/payload.out" "$WORK/sig.out" || { echo "REASON=unseal-failed" >&2; return 1; }
  cmp -s "$WORK/payload" "$WORK/payload.out" || { echo "REASON=payload-not-byte-identical" >&2; return 1; }
  cmp -s "$WORK/payload.sig" "$WORK/sig.out" || { echo "REASON=sig-not-byte-identical" >&2; return 1; }
  bash "$VERIFY" "$WORK/payload.out" "$WORK/sig.out" peerA || { echo "REASON=verify-payload-failed" >&2; return 1; }
  return 0
}
assert_case "(a) round-trip assina→sela + verify-payload" 0 "" -- a_roundtrip

# ───────────────────────── (b) seal-then-sign RECUSADO ─────────────────────────
# Ordem ERRADA: sela o payload SEM sig (placeholder vazio), depois assina o CIPHERTEXT (o blob).
# Monta o bundle com essa sig-sobre-ciphertext e prova que o pipeline RECUSA: deslacra → separa →
# verify-payload(payload', sig-sobre-ciphertext) → exit != 0 (a sig não casa os bytes do payload).
# Só (a) — assina→sela — passa.
b_seal_then_sign_refused() {
  : > "$WORK/empty.sig"
  # sela payload‖(sig vazio) — o bundle não carrega assinatura de origem do conteúdo
  node "$SEAL" "$WORK/payload" "$WORK/empty.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_stsign" 2>/dev/null
  # seal.mjs RECUSA selar sem assinatura (empty-sig) → a ordem errada nem produz blob; fail-closed.
  if [ -s "$WORK/blob_stsign" ]; then echo "REASON=seal-accepted-empty-sig (sela sem prova de origem)" >&2; return 1; fi
  # variante: assina o CIPHERTEXT de um blob válido e tenta passá-lo como sig do payload.
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_ok" >/dev/null 2>&1 || { echo "REASON=setup-seal-failed" >&2; return 1; }
  IDEIAOS_SIGN_KEY="$WORK/peerA" bash "$SIGN" "$WORK/blob_ok" "$WORK/ct.sig" >/dev/null 2>&1   # sig SOBRE o ciphertext
  # pipeline: usa o payload em claro mas a sig-sobre-ciphertext → verify-payload DEVE recusar (exit 3).
  bash "$VERIFY" "$WORK/payload" "$WORK/ct.sig" peerA 2>/dev/null && { echo "REASON=ciphertext-sig-accepted (seal-then-sign passou)" >&2; return 1; }
  return 0
}
assert_case "(b) seal-then-sign RECUSADO (só assina→sela passa)" 0 "" -- b_seal_then_sign_refused

# ───────────────────────── (c) destinatário-no-ciphertext / sem-alvo-em-claro ─────────────────────────
# O blob NÃO contém o machine_id/role/enc_pubkey do destinatário EM CLARO. grep do mid conhecido
# (e do role, e da enc_pubkey b64) no blob → ausente (exit 1). O alvo viaja DENTRO do ciphertext.
c_no_target_in_clear() {
  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_c" >/dev/null 2>&1 || { echo "REASON=seal-failed" >&2; return 1; }
  # o mid do destinatário NÃO pode aparecer no blob (nem em base64-decodificado)
  if grep -qF "$MID_TARGET" "$WORK/blob_c"; then echo "REASON=mid-in-blob-clear" >&2; return 1; fi
  base64 -d "$WORK/blob_c" 2>/dev/null | grep -qF "$MID_TARGET" && { echo "REASON=mid-in-blob-decoded" >&2; return 1; }
  # a enc_pubkey b64 do destinatário tampouco aparece em claro no blob
  local enc; enc=$(cat "$ENCPUB_FROM_PIN")
  grep -qF "$enc" "$WORK/blob_c" && { echo "REASON=enc-pubkey-in-blob" >&2; return 1; }
  return 0
}
assert_case "(c) sem alvo/role/enc-pubkey em claro no blob" 0 "" -- c_no_target_in_clear

# ───────────────────────── (d) só-o-destinatário-pinado-deslacra ─────────────────────────
# unseal com uma enc-privkey DIFERENTE (otherO) → AEAD falha → exit 3.
d_wrong_recipient() {
  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_d" >/dev/null 2>&1
  node "$UNSEAL" "$WORK/blob_d" "$WORK/otherO.encpriv" "$WORK/p_d" "$WORK/s_d"
}
assert_case "(d) só destinatário-pinado deslacra→3" 3 "auth-failed" -- d_wrong_recipient

# ───────────────────────── (e) tamper ─────────────────────────
# flipa 1 byte do ciphertext (na cauda do blob, fora do cabeçalho 60B) → unseal exit 3 (GCM falha).
make_tampered_blob() { # make_tampered_blob <src-blob> <out-blob>
  node -e '
    const fs = require("node:fs");
    const b64 = fs.readFileSync(process.argv[1], "utf8").trim();
    const buf = Buffer.from(b64, "base64");
    // flipa 1 byte no ciphertext (offset >= 60 = após eph(32)+iv(12)+tag(16))
    const off = buf.length - 1;
    buf[off] = buf[off] ^ 0xff;
    fs.writeFileSync(process.argv[2], buf.toString("base64") + "\n");
  ' "$1" "$2"
}
e_tamper() {
  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_e" >/dev/null 2>&1
  make_tampered_blob "$WORK/blob_e" "$WORK/blob_e_tampered"
  node "$UNSEAL" "$WORK/blob_e_tampered" "$WORK/targetT.encpriv" "$WORK/p_e" "$WORK/s_e"
}
assert_case "(e) tamper-ciphertext→3 (GCM auth-fail)" 3 "auth-failed" -- e_tamper

# ───────────────────────── (f) separação de chave ─────────────────────────
# a enc_pubkey é DISTINTA da signing-pubkey: tipos/arquivos diferentes; o pin tem os DOIS campos
# (campo 4 = signing ssh ed25519; campo 5 = enc X25519 raw b64) e eles não coincidem.
f_key_separation() {
  # signing-pubkey ssh (campo 4) começa com "ssh-ed25519 "; a enc_pubkey é raw X25519 b64 (32 bytes).
  local signing enc
  signing=$(awk 'NF>=2{print $1" "$2; exit}' "$WORK/peerA.pub")
  enc=$(bash "$PK" enc-pubkey-of peerA 2>/dev/null)
  [ -n "$enc" ] || { echo "REASON=no-enc-pubkey-pinned" >&2; return 1; }
  # tipos diferentes: signing é ssh-ed25519; a enc decodifica p/ exatamente 32 bytes X25519
  printf '%s' "$signing" | grep -q '^ssh-ed25519 ' || { echo "REASON=signing-not-ed25519" >&2; return 1; }
  local enclen; enclen=$(printf '%s' "$enc" | base64 -d 2>/dev/null | wc -c | tr -d ' ')
  [ "$enclen" = "32" ] || { echo "REASON=enc-not-32-bytes (len=$enclen)" >&2; return 1; }
  # e os DOIS valores não coincidem (chave de encriptação independente da assinatura)
  printf '%s' "$signing" | grep -qF "$enc" && { echo "REASON=enc-equals-signing" >&2; return 1; }
  return 0
}
assert_case "(f) enc_pubkey ≠ signing-pubkey (2 campos)" 0 "" -- f_key_separation

# ───────────────────────── retrocompat do pin (3 args, sem enc) ─────────────────────────
# `add` de 3 args (sem enc_pubkey) DEVE continuar funcionando: 5º campo vazio → enc-pubkey-of exit 4;
# list/role-of/allowed-signers-for permanecem idênticos.
legacy_pin_3args() {
  ssh-keygen -t ed25519 -N '' -C peerLegacy -f "$WORK/peerL" -q >/dev/null 2>&1
  bash "$PK" add peerL dev "$WORK/peerL.pub" >/dev/null 2>&1 || { echo "REASON=add-3args-failed" >&2; return 1; }
  bash "$PK" is-pinned peerL || { echo "REASON=not-pinned-after-3arg-add" >&2; return 1; }
  [ "$(bash "$PK" role-of peerL)" = "dev" ] || { echo "REASON=role-of-broke" >&2; return 1; }
  bash "$PK" allowed-signers-for peerL | grep -q '^peerL ssh-ed25519 ' || { echo "REASON=allowed-signers-broke" >&2; return 1; }
  bash "$PK" list | grep -q '^peerL|' || { echo "REASON=list-broke" >&2; return 1; }
  # enc-pubkey-of de pin legado (sem enc) → exit 4 no-enc-pubkey
  bash "$PK" enc-pubkey-of peerL 2>"$WORK/legacy_err"; local rc=$?
  [ "$rc" = "4" ] || { echo "REASON=legacy-enc-not-4 (rc=$rc)" >&2; return 1; }
  grep -q "no-enc-pubkey" "$WORK/legacy_err" || { echo "REASON=legacy-no-reason" >&2; return 1; }
  return 0
}
assert_case "(retrocompat) add-3args + enc-pubkey-of-legacy→4" 0 "" -- legacy_pin_3args

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o COMPARADOR detecta um mecanismo quebrado: um veneno REAL (tamper → unseal exit 3)
# avaliado contra expect=0 TEM que dar FAIL; contra expect=3 PASS. Se passasse como "esperado 0", teatro.
canary() {
  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_can" >/dev/null 2>&1
  make_tampered_blob "$WORK/blob_can" "$WORK/blob_can_t"
  node "$UNSEAL" "$WORK/blob_can_t" "$WORK/targetT.encpriv" "$WORK/p_can" "$WORK/s_can" 2>"$WORK/canErr"; local rc=$?
  if _cmp "$rc" "$WORK/canErr" 0 ""; then echo "REASON=canary-false-pass (gate aceitaria veneno como ok)" >&2; return 1; fi
  if ! _cmp "$rc" "$WORK/canErr" 3 "auth-failed"; then echo "REASON=canary-cant-detect-real (rc=$rc)" >&2; return 1; fi
  return 0
}
echo "─────────────────────────────────────────────"
if canary; then c_green "✓ CANÁRIO: comparador rejeita veneno-como-esperado-0 e aceita o exit real"; \
  else c_red "✗ CANÁRIO falhou — o comparador NÃO distingue veneno de verde"; FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES CANARY"; fi

# ───────────────────────── (mutação) sabota a verificação AEAD do unseal → vermelho → restaura → verde ─────────────────────────
# Numa CÓPIA do unseal, neutraliza a propagação do auth-fail (o `die(3,'auth-failed')` do catch vira
# no-op de saída-0): o caso (e) tamper — que num unseal íntegro dá exit 3 — passa a NÃO recusar (falso-verde).
# Restaurada → volta a exit 3. Prova que (e) detecta a QUEBRA do AEAD, não só sua ausência.
MUT_OK=0
mutation_proof() {
  local mut="$WORK/unseal.mut.mjs"; cp "$UNSEAL" "$mut"
  # sabota: o catch do AEAD passa a IGNORAR a falha e seguir com plaintext vazio → não recusa tamper.
  #   troca `die(3, 'auth-failed');` por `pt = Buffer.alloc(8);` (8 bytes: passa o framing-too-short e
  #   produz payload/sig vazios sem ABORTAR) → unseal SABOTADO sai 0 num blob adulterado (falso-verde).
  perl -0pi -e "s/die\(3, 'auth-failed'\);/pt = Buffer.alloc(8);/" "$mut"
  grep -q "Buffer.alloc(8)" "$mut" || { echo "REASON=mutation-not-applied" >&2; return 1; }

  bash "$SIGN" "$WORK/payload" "$WORK/payload.sig" >/dev/null 2>&1
  node "$SEAL" "$WORK/payload" "$WORK/payload.sig" "$ENCPUB_FROM_PIN" "$WORK/blob_mut" >/dev/null 2>&1
  make_tampered_blob "$WORK/blob_mut" "$WORK/blob_mut_t"

  # unseal SABOTADO sobre blob adulterado: NÃO deve recusar (rc != 3) → prova red-when-broken
  node "$mut" "$WORK/blob_mut_t" "$WORK/targetT.encpriv" "$WORK/p_mut" "$WORK/s_mut" >/dev/null 2>&1; local rc_mut=$?
  if [ "$rc_mut" = "3" ]; then echo "REASON=mutation-not-effective (sabotado ainda recusou rc=3)" >&2; return 1; fi
  # unseal ÍNTEGRO sobre o MESMO blob adulterado: DEVE recusar (rc 3) → verde após restore
  node "$UNSEAL" "$WORK/blob_mut_t" "$WORK/targetT.encpriv" "$WORK/p_mut2" "$WORK/s_mut2" >/dev/null 2>&1; local rc_real=$?
  if [ "$rc_real" != "3" ]; then echo "REASON=restore-not-red (íntegro não pegou o tamper rc=$rc_real)" >&2; return 1; fi
  MUT_OK=1
  return 0
}
if mutation_proof; then c_green "✓ MUTAÇÃO: verificação AEAD sabotada → tamper falso-verde; restaurada → vermelho (rc=3)"; \
  else c_red "✗ MUTAÇÃO falhou — o teste NÃO prova que a verificação AEAD é load-bearing"; fi

# ───────────────────────── veredito ─────────────────────────
echo "─────────────────────────────────────────────"
echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)  mutação=$MUT_OK"

rc=0
if [ "$CASES_RUN" -ne "$EXPECTED_CASES" ]; then
  c_red "✗ MANIFESTO violado: cases_run ($CASES_RUN) != EXPECTED_CASES ($EXPECTED_CASES) — caso somido/extra"; rc=1
fi
if [ "$FAIL" -ne 0 ]; then
  c_red "✗ $FAIL caso(s) falharam:$FAILED_NAMES"; rc=1
fi
if [ "$MUT_OK" -ne 1 ]; then
  c_red "✗ MUTAÇÃO não provou que a verificação AEAD é load-bearing"; rc=1
fi
if [ "$rc" -eq 0 ]; then
  c_green "OK seal $PASS/$EXPECTED_CASES"
else
  c_red "✗ seal gate vermelho"
fi
exit "$rc"
