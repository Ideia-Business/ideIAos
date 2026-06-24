#!/bin/bash
# test-writepath-bootstrap.sh — gate AGREGADO anti-teatro do write-path v14.4 (B0–B4).
#
# Prova, por EXIT-CODE e FAIL-CLOSED (antifragile-gates), que o mecanismo O2 (assinatura por-máquina,
# lista pinada autoritativa-local) + step-up (comprovante assinado + token O2 de uso único) funciona —
# SEM nenhuma mutação de produção, comando cross-máquina real, ou chamada a API de provedor.
#
# ANTI-TEATRO ESTRUTURAL (não asserção esperançosa):
#   (a) MANIFESTO fixo: EXPECTED_CASES; reprova se cases_run != EXPECTED_CASES;
#   (b) cada caso-veneno casa um EXIT-CODE específico + REASON= esperado — um !=0 genérico (127/
#       file-not-found) REPROVA;
#   (c) CANÁRIO: prova que o comparador detecta um mecanismo QUEBRADO (não só ausente);
#   (d) GATE NEGATIVO: nenhum script do agentd chama API de provedor.
#   (e) nonce DURÁVEL provado através de FRONTEIRA DE PROCESSO.
#
# Fixtures efêmeras em /tmp, descartadas. Build script: exit 1 em qualquer falha.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AGENTD="$ROOT/source/agentd"
FAKE="$ROOT/tests/writepath/lib/fake-stepup-backend.mjs"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/writepath.XXXXXX")"
# guarda o cleanup ao PROCESSO PRINCIPAL — bash propaga o trap EXIT a subshells (de pipeline e `( )`);
# sem o guard, um subshell ao terminar apagaria $WORK no meio da corrida ($$ = PID do main; BASHPID = atual).
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# stores isolados (nunca tocam os reais do operador)
export IDEIAOS_PINNED_STORE="$WORK/pinned"
export IDEIAOS_STEPUP_PIN="$WORK/stepup-pin"
export IDEIAOS_NONCE_STORE="$WORK/nonces"
mkdir -p "$IDEIAOS_NONCE_STORE"

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=47     # MANIFESTO: tem que bater com os assert_case abaixo (anti-teatro (a))
declare -a FAILED_NAMES=()

c_green(){ printf '\033[0;32m%s\033[0m\n' "$1"; }
c_red(){ printf '\033[0;31m%s\033[0m\n' "$1"; }

# code_only <file...> — emite só linhas de CÓDIGO (descarta comentários //, #, *). Os checks estáticos
# e o gate-negativo testam MECANISMO (código), não prosa: um literal proibido citado num comentário de
# documentação NÃO é uma chamada a provedor. Anti-teatro vale nas DUAS direções (sem falso-positivo de prosa).
code_only() { grep -hEv '^[[:space:]]*(//|#|\*|/\*)' "$@" 2>/dev/null; }

# comparador: rc==expect_exit E (sem REASON esperado OU stderr contém REASON). Retorna 0=match,1=miss.
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
    PASS=$((PASS+1)); printf '  ✓ %-42s exit=%s %s\n' "$name" "$rc" "${ereason:+REASON~$ereason}"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES+=("$name")
    printf '  ✗ %-42s got exit=%s (want %s%s); stderr=%s\n' "$name" "$rc" "$eexit" "${ereason:+ REASON~$ereason}" "$(head -1 "$errf" 2>/dev/null)"
  fi
}

# ───────────────────────── setup de fixtures ─────────────────────────
mk_key() { ssh-keygen -t ed25519 -N '' -C "$1" -f "$WORK/$1" -q >/dev/null 2>&1; }
mk_key peerA; mk_key peerB; mk_key peerC; mk_key peerWrong
# pin local: peerA (role cto) é o produtor autoritativo
bash "$AGENTD/pinned-keys.sh" add peerA cto "$WORK/peerA.pub" >/dev/null 2>&1

# backend de comprovante: par dedicado de teste + pin da pubkey
GEN="$(node "$FAKE" gen-keypair)"
KID=$(printf '%s' "$GEN" | sed -n 's/.*"kid":"\([^"]*\)".*/\1/p')
SPKI=$(printf '%s' "$GEN" | sed -n 's/.*"spki_b64":"\([^"]*\)".*/\1/p')
PKCS8=$(printf '%s' "$GEN" | sed -n 's/.*"pkcs8_b64":"\([^"]*\)".*/\1/p')
bash "$AGENTD/stepup-pin-backend.sh" add "$KID" "$SPKI" >/dev/null 2>&1
# 2º backend NÃO-pinado (p/ o caso not-pinned)
GEN2="$(node "$FAKE" gen-keypair)"
KID2=$(printf '%s' "$GEN2" | sed -n 's/.*"kid":"\([^"]*\)".*/\1/p')
PKCS82=$(printf '%s' "$GEN2" | sed -n 's/.*"pkcs8_b64":"\([^"]*\)".*/\1/p')

# command-file canônico A + comprovante válido bound a A
mk_command() { printf '{"action":"%s","ref":"%s","scope":"%s","sub":"%s","nonce":"%s"}' "$2" "cockpit" "rotate" "gustavo@redeideia.com.br" "$3" > "$1"; }
SUBJ="gustavo@redeideia.com.br"
mk_command "$WORK/cmdA" "rotate_sensitive" "nA"
mk_command "$WORK/cmdB" "revoke_service_role" "nB"
HASH_A=$(shasum -a 256 "$WORK/cmdA" | awk '{print $1}')
HASH_B=$(shasum -a 256 "$WORK/cmdB" | awk '{print $1}')

# helper: monta comprovante {payload_hash,sub,iat,exp,jti,kid} e assina com <pkcs8>
mk_comp() { # mk_comp <out> <payload_hash> <pkcs8> <kid> <exp_offset_sec> [jti]
  local out="$1" ph="$2" pk="$3" kid="$4" off="$5" jti="${6:-$(uuidgen 2>/dev/null || echo jti-$RANDOM$RANDOM)}"
  local now exp; now=$(date +%s); exp=$((now+off))
  printf '{"payload_hash":"%s","sub":"%s","iat":%s,"exp":%s,"jti":"%s","kid":"%s"}' "$ph" "$SUBJ" "$now" "$exp" "$jti" "$kid" > "$WORK/_comp.json"
  node "$FAKE" sign "$pk" "$WORK/_comp.json" > "$out"
}

export IDEIAOS_SIGN_KEY="$WORK/peerA"
export IDEIAOS_MACHINE_ID="peerA"

# paths das edge functions (usados por checks estáticos B3) — definidos ANTES de qualquer caso
SEND="$AGENTD/stepup/supabase/functions/send-otp/index.ts"
VER="$AGENTD/stepup/supabase/functions/verify-otp/index.ts"
REG="$AGENTD/stepup/supabase/functions/register-trusted-device/index.ts"
CHK="$AGENTD/stepup/supabase/functions/check-trusted-device/index.ts"

echo "━━━ writepath bootstrap gate (B0–B4) ━━━"

# ───────────────────────── B0 ─────────────────────────
# B0.1 privada NUNCA na saída de sign-payload (value-compare contra o material real)
b0_private_absent() {
  local payload="$WORK/b0p"; printf '{"x":1}' > "$payload"
  local out; out=$(IDEIAOS_SIGN_KEY="$WORK/peerA" bash "$AGENTD/sign-payload.sh" "$payload" "$WORK/b0p.sig" 2>"$WORK/b0e"; cat "$WORK/b0e")
  # corpo real da privada (linhas internas do PEM) não pode aparecer em stdout/stderr/sig
  local body; body=$(sed -n '2,$p' "$WORK/peerA" | grep -v 'PRIVATE KEY' | head -1)
  if printf '%s' "$out" | grep -qF "$body" 2>/dev/null; then echo "REASON=private-leaked" >&2; return 1; fi
  grep -qF "$body" "$WORK/b0p.sig" 2>/dev/null && { echo "REASON=private-in-sig" >&2; return 1; }
  return 0
}
assert_case "B0 private-never-in-output" 0 "" -- b0_private_absent

# B0.2 estrutura da entrada do pin: 3 campos não-vazios
b0_pin_structure() { bash "$AGENTD/pinned-keys.sh" list | awk -F'|' 'NF<3||$1==""||$2==""||$3==""{exit 1}'; }
assert_case "B0 pin-entry-structure" 0 "" -- b0_pin_structure

# ───────────────────────── B1 ─────────────────────────
# B1.1 válido cross-identity: peerA assina, verifica como peerA pinado
b1_valid() {
  printf '{"action":"x","role":"cto"}' > "$WORK/b1p"
  IDEIAOS_SIGN_KEY="$WORK/peerA" bash "$AGENTD/sign-payload.sh" "$WORK/b1p" "$WORK/b1p.sig" >/dev/null 2>&1
  bash "$AGENTD/verify-payload.sh" "$WORK/b1p" "$WORK/b1p.sig" peerA
}
assert_case "B1 valid-cross-identity" 0 "" -- b1_valid

# B1.2 payload-tamper → exit 3
b1_tamper() {
  printf '{"action":"x"}' > "$WORK/b1t"
  IDEIAOS_SIGN_KEY="$WORK/peerA" bash "$AGENTD/sign-payload.sh" "$WORK/b1t" "$WORK/b1t.sig" >/dev/null 2>&1
  printf '{"action":"y"}' > "$WORK/b1t"   # vira o payload após assinar
  bash "$AGENTD/verify-payload.sh" "$WORK/b1t" "$WORK/b1t.sig" peerA
}
assert_case "B1 payload-tamper→3" 3 "invalid-signature" -- b1_tamper

# B1.3 chave não-pinada → exit 4 (peerC não pinado)
b1_unpinned() {
  printf '{"action":"x"}' > "$WORK/b1u"
  IDEIAOS_SIGN_KEY="$WORK/peerC" bash "$AGENTD/sign-payload.sh" "$WORK/b1u" "$WORK/b1u.sig" >/dev/null 2>&1
  bash "$AGENTD/verify-payload.sh" "$WORK/b1u" "$WORK/b1u.sig" peerC
}
assert_case "B1 not-pinned→4" 4 "not-pinned" -- b1_unpinned

# B1.4 papel forjado → exit 5 (payload role=admin, peerA pinado cto)
b1_roleforge() {
  printf '{"action":"x","role":"admin"}' > "$WORK/b1r"
  IDEIAOS_SIGN_KEY="$WORK/peerA" bash "$AGENTD/sign-payload.sh" "$WORK/b1r" "$WORK/b1r.sig" >/dev/null 2>&1
  bash "$AGENTD/verify-payload.sh" "$WORK/b1r" "$WORK/b1r.sig" peerA
}
assert_case "B1 role-forged→5" 5 "role-forged" -- b1_roleforge

# B1.5 sem assinatura (só-sha256) → exit 6
b1_nosig() { printf '{"action":"x"}' > "$WORK/b1n"; : > "$WORK/b1n.sig"; bash "$AGENTD/verify-payload.sh" "$WORK/b1n" "$WORK/b1n.sig" peerA; }
assert_case "B1 only-sha256→6" 6 "no-signature" -- b1_nosig

# B1.6 downgrade: sig de chave errada (peerWrong) p/ id peerA → exit 3
b1_downgrade() {
  printf '{"action":"x"}' > "$WORK/b1d"
  IDEIAOS_SIGN_KEY="$WORK/peerWrong" bash "$AGENTD/sign-payload.sh" "$WORK/b1d" "$WORK/b1d.sig" >/dev/null 2>&1
  bash "$AGENTD/verify-payload.sh" "$WORK/b1d" "$WORK/b1d.sig" peerA
}
assert_case "B1 downgrade→3" 3 "invalid-signature" -- b1_downgrade

# ───────────────────────── B2 ─────────────────────────
# B2.1 revogação-via-ref recusada (alerta) E pin de peerA PERMANECE
b2_forged_revoke() {
  bash "$AGENTD/pinned-keys.sh" process-ref-revocation "$WORK/anything" 2>"$WORK/b2e"; local rc=$?
  [ "$rc" = "9" ] || { echo "REASON=ref-revoke-not-alerted rc=$rc" >&2; return 1; }
  grep -q "ref-revocation-ignored" "$WORK/b2e" || { echo "REASON=no-alert" >&2; return 1; }
  bash "$AGENTD/pinned-keys.sh" is-pinned peerA || { echo "REASON=pin-removed" >&2; return 1; }
  return 0
}
assert_case "B2 forged-revoke-refused" 0 "" -- b2_forged_revoke

# B2.2 adição-via-ref recusada
b2_ref_add() { bash "$AGENTD/pinned-keys.sh" process-ref-addition "$WORK/anything"; }
assert_case "B2 ref-addition-refused→9" 9 "ref-addition-refused" -- b2_ref_add

# B2.3 revoke-local funciona
b2_revoke_local() {
  bash "$AGENTD/pinned-keys.sh" add tmpX dev "$WORK/peerB.pub" >/dev/null 2>&1
  bash "$AGENTD/pinned-keys.sh" revoke-local tmpX >/dev/null 2>&1
  bash "$AGENTD/pinned-keys.sh" is-pinned tmpX && return 1 || return 0
}
assert_case "B2 revoke-local-works" 0 "" -- b2_revoke_local

# ───────────────────────── B3 (comprovante + mint) ─────────────────────────
# B3.1 mint válido: comprovante bound a A → token; token verifica por verify-payload
b3_valid_mint() {
  mk_comp "$WORK/compA" "$HASH_A" "$PKCS8" "$KID" 60
  local tok; tok=$(bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compA" "$WORK/tokA" 2>"$WORK/b3e"); local rc=$?
  [ "$rc" = "0" ] || { cat "$WORK/b3e" >&2; return $rc; }
  bash "$AGENTD/verify-payload.sh" "$WORK/tokA" "$WORK/tokA.sig" peerA
}
assert_case "B3 valid-mint + token-signed" 0 "" -- b3_valid_mint

# B3.2 comprovante sig inválida → 3
b3_bad_sig() {
  mk_comp "$WORK/compBad" "$HASH_A" "$PKCS8" "$KID" 60
  # corrompe a assinatura no wire
  sed 's/"sig":"./"sig":"X/' "$WORK/compBad" > "$WORK/compBad2" && mv "$WORK/compBad2" "$WORK/compBad"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compBad" "$WORK/tokBad"
}
assert_case "B3 comprovante-invalid-sig→3" 3 "comprovante-invalid-sig" -- b3_bad_sig

# B3.3 comprovante chave não-pinada → 4 (assina com KID2 não-pinado)
b3_not_pinned() { mk_comp "$WORK/compNP" "$HASH_A" "$PKCS82" "$KID2" 60; bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compNP" "$WORK/tokNP"; }
assert_case "B3 comprovante-not-pinned→4" 4 "comprovante-not-pinned" -- b3_not_pinned

# B3.4 binding A≠B (o fix S-01): comprovante de A usado p/ comando B → 7
b3_binding() { mk_comp "$WORK/compBind" "$HASH_A" "$PKCS8" "$KID" 60; bash "$AGENTD/stepup-token.sh" "$WORK/cmdB" "$WORK/compBind" "$WORK/tokBind"; }
assert_case "B3 binding-A≠B→7" 7 "binding" -- b3_binding

# B3.5 comprovante expirado → 8
b3_expired() { mk_comp "$WORK/compExp" "$HASH_A" "$PKCS8" "$KID" -60; bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compExp" "$WORK/tokExp"; }
assert_case "B3 comprovante-expired→8" 8 "expired" -- b3_expired

# B3.6 booleano REPROVA: {verified:true} plano → recusa (malformed-wire, razão NOMEADA, não 127/genérico)
b3_boolean() { printf '{"verified":true}' > "$WORK/compBool"; bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compBool" "$WORK/tokBool"; }
assert_case "B3 boolean-rejected (não-booleano)" 2 "malformed-wire" -- b3_boolean

# B3.7 fail-closed: comprovante ausente/vazio → 5
b3_failclosed() { : > "$WORK/compEmpty"; bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compEmpty" "$WORK/tokFC"; }
assert_case "B3 fail-closed-no-comprovante→5" 5 "fail-closed" -- b3_failclosed

# B3.8 cliente fail-closed: STEPUP_TRANSPORT ausente → 5
b3_client_fc() { env -u STEPUP_TRANSPORT bash "$AGENTD/stepup-otp-client.sh" fetch "$SUBJ" "$HASH_A" "rotate"; }
assert_case "B3 client-fail-closed→5" 5 "fail-closed" -- b3_client_fc

# B3.9 comprovante replay durável CROSS-PROCESSO: consome num subshell separado, reusa em invocação
#   separada → 2ª recusa 10 lendo o store durável do disco (rigor simétrico ao B4 do token).
b3_replay() {
  mk_comp "$WORK/compR" "$HASH_A" "$PKCS8" "$KID" 60 "jti-fixed-replay"
  ( bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compR" "$WORK/tokR1" ) >/dev/null 2>&1   # proc A: consome
  mk_comp "$WORK/compR2" "$HASH_A" "$PKCS8" "$KID" 60 "jti-fixed-replay"                          # mesmo jti
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compR2" "$WORK/tokR2"                         # proc B (separado): replay
}
assert_case "B3 comprovante-replay-cross-process→10" 10 "nonce-reused" -- b3_replay

# B3.10 SUBJECT-BINDING (HIGH fix): comprovante aprovado por approverX + command-file alegando attackerY
#   → token.subject TEM que ser approverX (do comprovante PROVADO), nunca o que o command-file alega.
b3_subject_from_comprovante() {
  printf '{"action":"rotate_sensitive","ref":"cockpit","scope":"rotate","sub":"attacker@evil.com","nonce":"nS"}' > "$WORK/cmdEvil"
  local h; h=$(shasum -a 256 "$WORK/cmdEvil" | awk '{print $1}')
  local now exp; now=$(date +%s); exp=$((now+60))
  printf '{"payload_hash":"%s","sub":"approver@ideia.com","iat":%s,"exp":%s,"jti":"jti-subj","kid":"%s"}' "$h" "$now" "$exp" "$KID" > "$WORK/_comp.json"
  node "$FAKE" sign "$PKCS8" "$WORK/_comp.json" > "$WORK/compSubj"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdEvil" "$WORK/compSubj" "$WORK/tokSubj" >/dev/null 2>&1 || return 91
  grep -q '"subject":"approver@ideia.com"' "$WORK/tokSubj" && ! grep -q 'attacker@evil.com' "$WORK/tokSubj"
}
assert_case "B3 subject-from-comprovante-not-command" 0 "" -- b3_subject_from_comprovante

# B3.10b SUBJECT charset (S-N2): comprovante com sub contendo aspas/backslash → recusa (JSON nunca malformado)
b3_bad_subject() {
  local now exp; now=$(date +%s); exp=$((now+60))
  printf '{"payload_hash":"%s","sub":"x\\"evil","iat":%s,"exp":%s,"jti":"jti-badsubj","kid":"%s"}' "$HASH_A" "$now" "$exp" "$KID" > "$WORK/_comp.json"
  node "$FAKE" sign "$PKCS8" "$WORK/_comp.json" > "$WORK/compBadSub"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compBadSub" "$WORK/tokBadSub"
}
assert_case "B3 bad-subject-charset→rejected" 2 "bad-subject-charset" -- b3_bad_subject

# B3.11 OTP-CODE não-vazado (HIGH fix · S-03): roda o client com STEPUP_OTP_CODE + stub e value-compare
#   '123456' contra stdout/stderr/out — o código (via stdin) não pode acabar em nenhum arquivo do client.
b3_otp_not_leaked() {
  local stub="$ROOT/tests/writepath/lib/stub-transport.sh"; chmod +x "$stub" 2>/dev/null || true
  printf '{"comprovante":{},"sig":"stub"}' > "$WORK/h_resp.json"
  STEPUP_TRANSPORT="$stub" STUB_COMPROVANTE="$WORK/h_resp.json" STEPUP_OTP_CODE="123456" \
    bash "$AGENTD/stepup-otp-client.sh" fetch "$SUBJ" "$HASH_A" "rotate" "$WORK/h_out" >"$WORK/h_stdout" 2>"$WORK/h_stderr" || true
  grep -rqF "123456" "$WORK/h_stdout" "$WORK/h_stderr" "$WORK/h_out" 2>/dev/null && { echo "REASON=otp-leaked" >&2; return 1; }
  return 0
}
assert_case "B3 OTP-code-not-leaked (value-compare)" 0 "" -- b3_otp_not_leaked

# B3.12 CORS loopback-only (S-08, estático): regex loopback + reflexo EXATO + 403 p/ não-loopback
b3_cors_loopback() {
  local c="$AGENTD/stepup/supabase/functions/_shared/cors.ts"
  grep -qE '127\.0\.0\.1|localhost' "$c" && grep -q 'Access-Control-Allow-Origin"\] = origin' "$c" && grep -q '403' "$c"
}
assert_case "B3 CORS loopback-only+403 (S-08)" 0 "" -- b3_cors_loopback

# B3.13 rate-limit por EMAIL, não IP (S-07, estático)
b3_ratelimit_email() {
  code_only "$SEND" | grep -q '\.eq("email"' && ! code_only "$SEND" | grep -qiE 'x-forwarded|x-real-ip|cf-connecting|ip_address|req\.ip'
}
assert_case "B3 rate-limit by-email-not-IP (S-07)" 0 "" -- b3_ratelimit_email

# B3.14 remember-device tiering no backend (S-05, estático): max_tier=sensível, device_id, same-machine, janela
b3_remember_device() {
  code_only "$REG" | grep -q "max_tier" && code_only "$REG" | grep -qE "onConflict.*device_id" \
    && code_only "$CHK" | grep -q 'machine_id' && code_only "$CHK" | grep -q 'expires_at'
}
assert_case "B3 remember-device tiering (register/check, S-05)" 0 "" -- b3_remember_device

# B3.15 schema sem tabelas/roles de PRODUTO (S-04 mineração-adaptada, estático)
b3_schema_no_product() { ! code_only "$AGENTD/stepup/schema.sql" | grep -qiE 'user_roles|is_seller|admin_emails'; }
assert_case "B3 schema no-product-tables (S-04)" 0 "" -- b3_schema_no_product

# B3.16/17 Touch ID atalho: presente→0; AUSENTE→1 e NÃO bloqueia (cai em email-OTP, núcleo do HYBRID)
assert_case "B3 touchid present(force=1)→0" 0 "" -- env IDEIAOS_TOUCHID_FORCE=1 bash "$AGENTD/stepup-touchid.sh" available
assert_case "B3 touchid absent(force=0)→1 non-blocking" 1 "touchid-unavailable" -- env IDEIAOS_TOUCHID_FORCE=0 bash "$AGENTD/stepup-touchid.sh" available

# B3 tiering (S-05)
assert_case "B3 tier sensível/same/3d→skip" 0 "" -- bash "$AGENTD/stepup-tier-policy.sh" skip-allowed sensível 1 3
assert_case "B3 tier sensível/same/8d→deny" 1 "skip-denied" -- bash "$AGENTD/stepup-tier-policy.sh" skip-allowed sensível 1 8
assert_case "B3 tier sensível/other/3d→deny" 1 "skip-denied" -- bash "$AGENTD/stepup-tier-policy.sh" skip-allowed sensível 0 3
assert_case "B3 tier alto→always-otp" 1 "OTP toda vez" -- bash "$AGENTD/stepup-tier-policy.sh" skip-allowed alto 1 1
assert_case "B3 tier o4-required(crítico)" 0 "" -- bash "$AGENTD/stepup-tier-policy.sh" o4-required crítico

# B3 estáticos (CSPRNG / não-booleano / sem login-por-senha) — sobre CÓDIGO (code_only), não prosa.
# (SEND/VER/REG/CHK já definidos no setup, antes de qualquer caso.)
b3_csprng() { code_only "$SEND" | grep -q 'crypto.getRandomValues' && ! code_only "$SEND" | grep -Eq 'Math\.random'; }
assert_case "B3 send-otp CSPRNG (no Math.random)" 0 "" -- b3_csprng
# não-booleano: PROVA POSITIVA (assina + retorna o comprovante) + NEGATIVA (nenhum verified:true no código)
b3_not_boolean_static() { code_only "$VER" | grep -q 'signComprovante' && code_only "$VER" | grep -q 'return json(signed)' && ! code_only "$VER" | grep -Eq 'verified"?[[:space:]]*:[[:space:]]*true'; }
assert_case "B3 verify-otp signed-not-boolean" 0 "" -- b3_not_boolean_static
b3_no_signin() { ! code_only "$SEND" "$VER" "$REG" "$CHK" | grep -q 'signInWithPassword'; }
assert_case "B3 no-login-por-senha (S-09)" 0 "" -- b3_no_signin

# ───────────────────────── B4 (token verify fail-closed) ─────────────────────────
# B4.0 INVALID-MACHINE-SIG (fecha o blind-spot CRÍTICO: verify-token DEVE recusar token forjado).
#   Antes da fix do trap `! cmd; rc=$?`, estes saíam 0 (qualquer token forjado era aceito).
b4_forged_sig() {
  printf '{"action":"deploy_prod","nonce":"x","expiry":9999999999}' > "$WORK/pwn"; printf 'garbage-sig' > "$WORK/pwn.sig"
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/pwn" "$WORK/pwn.sig" peerA "deploy_prod"
}
assert_case "B4 forged-sig-token→3 (CRITICAL fix)" 3 "machine-sig" -- b4_forged_sig
b4_not_pinned_token() {
  printf '{"action":"x","nonce":"y","expiry":9999999999}' > "$WORK/pwn2"; printf 'garbage' > "$WORK/pwn2.sig"
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/pwn2" "$WORK/pwn2.sig" evilmachine "x"
}
assert_case "B4 not-pinned-machine-token→4" 4 "machine-sig" -- b4_not_pinned_token
b4_empty_sig_token() {
  printf '{"action":"x","nonce":"z","expiry":9999999999}' > "$WORK/pwn3"; : > "$WORK/pwn3.sig"
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/pwn3" "$WORK/pwn3.sig" peerA "x"
}
assert_case "B4 empty-sig-token→6" 6 "machine-sig" -- b4_empty_sig_token

# B4.1 token válido & inédito → 0  (mint fresco)
b4_valid() {
  mk_comp "$WORK/compV4" "$HASH_A" "$PKCS8" "$KID" 60 "jti-b4-valid"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compV4" "$WORK/tok4" >/dev/null 2>&1 || return 99
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/tok4" "$WORK/tok4.sig" peerA "rotate_sensitive"
}
assert_case "B4 token-valid-fresh→0" 0 "" -- b4_valid

# B4.2 token expirado → 8 (TTL 0 no mint)
b4_expired() {
  mk_comp "$WORK/compE4" "$HASH_A" "$PKCS8" "$KID" 60 "jti-b4-exp"
  IDEIAOS_TOKEN_TTL=-5 bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compE4" "$WORK/tokE4" >/dev/null 2>&1 || return 99
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/tokE4" "$WORK/tokE4.sig" peerA "rotate_sensitive"
}
assert_case "B4 token-expired→8" 8 "expired" -- b4_expired

# B4.3 binding divergente: token p/ rotate_sensitive verificado como intended=deploy_prod → 7
b4_binding() {
  mk_comp "$WORK/compB4" "$HASH_A" "$PKCS8" "$KID" 60 "jti-b4-bind"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compB4" "$WORK/tokB4" >/dev/null 2>&1 || return 99
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/tokB4" "$WORK/tokB4.sig" peerA "deploy_prod"
}
assert_case "B4 binding-divergent→7" 7 "binding" -- b4_binding

# B4.4 nonce replay CROSS-PROCESSO durável: consome em proc A, reusa em proc B separado → 10
b4_replay_cross_process() {
  mk_comp "$WORK/compN4" "$HASH_A" "$PKCS8" "$KID" 120 "jti-b4-nonce"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compN4" "$WORK/tokN4" >/dev/null 2>&1 || return 99
  # processo A (subshell separado) consome o nonce
  ( bash "$AGENTD/stepup-verify-token.sh" "$WORK/tokN4" "$WORK/tokN4.sig" peerA "rotate_sensitive" ) >/dev/null 2>&1
  # processo B (invocação separada) reusa → deve recusar 10 lendo o store DURÁVEL do disco
  bash "$AGENTD/stepup-verify-token.sh" "$WORK/tokN4" "$WORK/tokN4.sig" peerA "rotate_sensitive"
}
assert_case "B4 nonce-replay-cross-process→10" 10 "nonce-reused" -- b4_replay_cross_process

# B4.5 NONCE-STORE não-gravável → FAIL-CLOSED (S-N1): token válido NÃO pode ser aceito sem registrar o nonce
b4_nonce_store_fail_closed() {
  mk_comp "$WORK/compFC" "$HASH_A" "$PKCS8" "$KID" 120 "jti-fc-nonce"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/compFC" "$WORK/tokFC2" >/dev/null 2>&1 || return 91
  local roparent="$WORK/ro"; mkdir -p "$roparent"; chmod 555 "$roparent"
  IDEIAOS_NONCE_STORE="$roparent/nonces" bash "$AGENTD/stepup-verify-token.sh" "$WORK/tokFC2" "$WORK/tokFC2.sig" peerA "rotate_sensitive"
  local rc=$?
  chmod 755 "$roparent" 2>/dev/null || true   # restaura p/ cleanup
  return "$rc"
}
assert_case "B4 nonce-store-unwritable→fail-closed(10)" 10 "nonce-store-unwritable" -- b4_nonce_store_fail_closed

# ───────────────────────── (d) GATE NEGATIVO ─────────────────────────
# gate-negativo sobre CÓDIGO (code_only): nenhum script do agentd faz EGRESS / comando cross-máquina /
# chamada a provedor. Regex AMPLIADA (egress-gap finding) — cobre fetch/wget/deno/nc/scp/ssh user@/
# gh api|pr|push/git push além de curl + provedores. `ssh-keygen` (ssh SEM espaço-@) e `node` local não
# casam. Comentários de doc citando um provedor não são chamadas (code_only os remove) — anti-teatro.
b4_gate_negativo() {
  local hits
  # `fetch *\(` (a CHAMADA JS), não a palavra "fetch" — o cliente usa `fetch` como VERBO de subcomando.
  hits=$(code_only "$AGENTD"/*.sh | grep -En 'curl|wget|fetch *\(|vercel|railway|supabase|\bdeno\b|\bnc\b|\bscp\b|ssh +[^ ]*@|gh +(api|pr|push)|git +push|api\.' || true)
  [ -z "$hits" ] || { echo "REASON=egress-found: $hits" >&2; return 1; }
  return 0
}
assert_case "GATE-NEGATIVO no-egress/provider in agentd/*.sh" 0 "" -- b4_gate_negativo

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o comparador DETECTA mecanismo quebrado: um veneno real (sig corrompida → exit 3) avaliado
# contra expect=0 TEM que dar FAIL; e contra expect=3 TEM que dar PASS. Se um veneno passasse como
# "esperado 0", o gate seria teatro.
canary() {
  mk_comp "$WORK/canC" "$HASH_A" "$PKCS8" "$KID" 60 "jti-canary"
  sed 's/"sig":"./"sig":"X/' "$WORK/canC" > "$WORK/canC2" && mv "$WORK/canC2" "$WORK/canC"
  bash "$AGENTD/stepup-token.sh" "$WORK/cmdA" "$WORK/canC" "$WORK/tokCan" 2>"$WORK/canErr"; local rc=$?
  # o comparador DEVE rejeitar "expect 0" e aceitar "expect 3 + REASON"
  if _cmp "$rc" "$WORK/canErr" 0 ""; then echo "REASON=canary-false-pass (gate aceitaria veneno como ok)" >&2; return 1; fi
  if ! _cmp "$rc" "$WORK/canErr" 3 "comprovante-invalid-sig"; then echo "REASON=canary-cant-detect-real" >&2; return 1; fi
  return 0
}
assert_case "CANARY detects-broken-not-just-absent" 0 "" -- canary

# ───────────────────────── veredito ─────────────────────────
echo "─────────────────────────────────────────────"
echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)"

rc=0
if [ "$CASES_RUN" -ne "$EXPECTED_CASES" ]; then
  c_red "✗ MANIFESTO violado: cases_run ($CASES_RUN) != EXPECTED_CASES ($EXPECTED_CASES) — caso somido/extra"
  rc=1
fi
if [ "$FAIL" -ne 0 ]; then
  c_red "✗ $FAIL caso(s) falharam: ${FAILED_NAMES[*]}"
  rc=1
fi
if [ "$rc" -eq 0 ]; then
  c_green "✓ writepath bootstrap GATE verde — B0–B4 fail-closed provados por exit-code (anti-teatro: manifesto+REASON+canário+gate-negativo)"
else
  c_red "✗ writepath bootstrap GATE vermelho"
fi
exit "$rc"
