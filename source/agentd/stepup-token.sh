#!/bin/bash
# stepup-token.sh — produz o TOKEN de capability O2 do step-up (v14.4 · B3 / F0a, parte autônoma).
#
# Decisões: v14.4-step-up-without-relying-party.md (HYBRID) + v14.4-stepup-comprovante-key-scheme.md
#           + v14.4-origin-auth-signing-mechanism.md (O2).
#
# Ordem FAIL-CLOSED (autenticidade ANTES de binding — fecha o confused-deputy do S-01):
#   1. comprovante ausente/vazio (backend/email/rede fora) → RECUSA (exit 5 = fail-closed; nunca pula);
#   2. payload_hash esperado = sha256(BYTES do command-file canônico) — o produtor do comando é
#      responsável pela canonicalização (o mesmo hash viajou client→send-otp→comprovante);
#   3. stepup-verify-comprovante.mjs: verifica a ASSINATURA Ed25519 contra a pubkey PINADA, depois
#      binding (payload_hash) e exp — propaga exit 3 (sig)/4 (não-pinada)/7 (binding)/8 (expirado);
#   4. comprovante jti single-use (store durável) — reuso → RECUSA (exit 10);
#   5. SÓ ENTÃO assina o token O2 {subject,role,action,ref,scope,nonce,expiry,otp_proof} com a chave
#      de máquina (sign-payload.sh / B0). role = papel PINADO da máquina (R-WP2), não inventado.
#
# credential-isolation: o código OTP NUNCA entra aqui — só o comprovante ASSINADO. A privada de
#   máquina é resolvida por sign-payload.sh na borda (keychain), nunca materializada.
# antifragile-gates: o veredito é o EXIT-CODE.
#
# Uso: stepup-token.sh <command-file> <comprovante-wire.json> [token-out]
#   env: IDEIAOS_SIGN_KEY (handle da chave de máquina, p/ sign-payload.sh)
#        IDEIAOS_MACHINE_ID (machine_id pinado do produtor — papel vem do pin)
#        IDEIAOS_STEPUP_PIN (store de pubkey do backend), IDEIAOS_PINNED_STORE (peers de máquina)
#        IDEIAOS_NONCE_STORE (dir durável de nonces/jti vistos)
#
# Exit-codes:
#   0  token O2 assinado (stdout: path do token)
#   2  erro de invocação
#   3  comprovante: assinatura inválida
#   4  comprovante: chave não-pinada
#   5  fail-closed (comprovante ausente/inacessível — backend/rede fora)
#   7  binding divergente (comprovante não casa o comando)
#   8  comprovante expirado
#   10 comprovante jti reusado (anti-replay durável)
set -uo pipefail
umask 077   # arquivos deste processo nunca legíveis por outros (defesa-em-profundidade)

HERE="$(cd "$(dirname "$0")" && pwd)"
PK="$HERE/pinned-keys.sh"
SIGN="$HERE/sign-payload.sh"
VERIFY_COMP="$HERE/stepup-verify-comprovante.mjs"
NONCE_STORE="${IDEIAOS_NONCE_STORE:-$HOME/.ideiaos/cockpit/seen-nonces}"

cmdfile="${1:?uso: stepup-token.sh <command-file> <comprovante-wire.json> [token-out]}"
compfile="${2:?comprovante-wire.json}"
tokenout="${3:-$cmdfile.token}"

# 1) fail-closed: sem comprovante (backend/rede/email fora) → recusa, nunca pula
if [ ! -s "$compfile" ]; then echo "REASON=fail-closed (comprovante ausente)" >&2; exit 5; fi
if [ ! -s "$cmdfile" ]; then echo "REASON=usage (command-file vazio)" >&2; exit 2; fi

# 2) hash esperado = sha256 dos BYTES canônicos do comando (bash-native, sem reimplementar canonicalize)
expected_hash=$(shasum -a 256 "$cmdfile" 2>/dev/null | awk '{print $1}')
[ -z "$expected_hash" ] && { echo "REASON=hash-failed" >&2; exit 2; }

# 3) verifica o comprovante (autenticidade → binding → exp). Propaga o exit-code específico.
jti=$(node "$VERIFY_COMP" verify "$compfile" "$expected_hash"); rc=$?
if [ "$rc" -ne 0 ]; then exit "$rc"; fi   # REASON já foi para stderr pelo verificador
[ -z "$jti" ] && { echo "REASON=no-jti" >&2; exit 2; }
# jti só charset seguro (evita injeção de control-char no JSON do token — LOW finding)
case "$jti" in *[!a-zA-Z0-9._-]*) echo "REASON=bad-jti-charset" >&2; exit 2;; esac

# 4) comprovante single-use: jti durável (1 comprovante → 1 token). FAIL-CLOSED — consome o jti
#    ATOMICAMENTE AGORA (antes de mintar); se não persistir (store RO/cheio OU já-visto via corrida),
#    RECUSA. Trade-off aceito: um mint que falhe depois "queima" o comprovante (mais seguro que replay).
mkdir -p "$NONCE_STORE" 2>/dev/null || { echo "REASON=nonce-store-unwritable" >&2; exit 10; }
jti_id=$(printf '%s' "comprovante:$jti" | shasum -a 256 | awk '{print $1}')
if [ -e "$NONCE_STORE/$jti_id" ]; then echo "REASON=nonce-reused (comprovante jti)" >&2; exit 10; fi
if ! ( set -o noclobber; : > "$NONCE_STORE/$jti_id" ) 2>/dev/null; then
  echo "REASON=nonce-reused (comprovante jti — store não-gravável/corrida)" >&2; exit 10
fi

# 5) monta + assina o token O2. role = papel PINADO da máquina produtora (R-WP2), nunca inventado.
mid="${IDEIAOS_MACHINE_ID:?defina IDEIAOS_MACHINE_ID (machine_id pinado do produtor)}"
role=$(bash "$PK" role-of "$mid" 2>/dev/null)
[ -z "$role" ] && { echo "REASON=producer-not-pinned mid=$mid" >&2; exit 4; }

# campos do comando (extração simples — o command-file é canônico do produtor)
_field() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$cmdfile" | head -1; }
action=$(_field action); ref=$(_field ref); scope=$(_field scope)
# subject AUTORITATIVO = o aprovador PROVADO pelo OTP (comprovante.sub, já verificado cripto acima),
# NUNCA o que o command-file do chamador alega (fecha o subject-confused-deputy — HIGH finding).
subject=$(sed -n 's/.*"sub"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$compfile" 2>/dev/null | head -1)
[ -z "$subject" ] && { echo "REASON=no-subject-in-comprovante" >&2; exit 2; }
# subject só charset email-ish (sem aspas/control-chars → JSON do token nunca malformado — S-N2)
case "$subject" in *[!a-zA-Z0-9._%+@-]*) echo "REASON=bad-subject-charset" >&2; exit 2;; esac

# nonce do token O2 = CSPRNG (/dev/urandom), curto-prazo
nonce=$(LC_ALL=C tr -dc 'a-f0-9' < /dev/urandom 2>/dev/null | head -c 32)
[ -z "$nonce" ] && { echo "REASON=nonce-gen-failed" >&2; exit 2; }
expiry=$(( $(date +%s) + ${IDEIAOS_TOKEN_TTL:-120} ))

# PUBLICAÇÃO ATÔMICA: escreve no .tmp, assina, e só promove p/ $tokenout se a assinatura suceder —
# nunca deixa um token NÃO-ASSINADO no caminho final (MEDIUM finding). Token assinado byte-a-byte.
tmptok="$tokenout.tmp.$$"
printf '{"subject":"%s","role":"%s","action":"%s","ref":"%s","scope":"%s","nonce":"%s","expiry":%s,"otp_proof":{"jti":"%s","payload_hash":"%s"}}\n' \
  "$subject" "$role" "$action" "$ref" "$scope" "$nonce" "$expiry" "$jti" "$expected_hash" > "$tmptok"

# assina com a chave de máquina (sign-payload.sh resolve a privada na borda; nunca a materializa)
if ! IDEIAOS_SIGN_KEY="${IDEIAOS_SIGN_KEY:?defina IDEIAOS_SIGN_KEY}" bash "$SIGN" "$tmptok" "$tmptok.sig" >/dev/null 2>&1; then
  rm -f "$tmptok" "$tmptok.sig"; echo "REASON=token-sign-failed" >&2; exit 2
fi
# promove atômico: token + sig juntos, SÓ após assinatura válida (nunca token sem sig no destino)
if ! { mv -f "$tmptok" "$tokenout" && mv -f "$tmptok.sig" "$tokenout.sig"; }; then
  rm -f "$tmptok" "$tmptok.sig"; echo "REASON=publish-failed" >&2; exit 2
fi

printf '%s\n' "$tokenout"
exit 0
