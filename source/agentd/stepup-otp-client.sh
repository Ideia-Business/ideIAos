#!/bin/bash
# stepup-otp-client.sh — cliente do step-up email-OTP (v14.4 · B3 / F0a, parte autônoma).
#
# Orquestra o fator de presença na ORIGEM (email-OTP universal):
#   send-otp(email, payload_hash, action_label) → operador recebe e-mail com a AÇÃO em claro +
#   código → verify-otp(email, code, payload_hash) → COMPROVANTE ASSINADO do binding.
#
# SEAM DE TRANSPORTE (escopo airtight): este script NÃO faz a chamada de rede diretamente — delega a
#   um executável injetado em $STEPUP_TRANSPORT. Em bootstrap (F0a) o gate injeta um stub local; em
#   produção (F0b) o operador aponta para o transporte real (que vive FORA de source/agentd/*.sh).
#   Assim nenhum literal de chamada-de-provedor entra nos scripts do agentd (gate negativo B4).
# FAIL-CLOSED: transporte ausente/inacessível, ou resposta vazia → RECUSA (exit 5), nunca degrada.
# credential-isolation: o CÓDIGO OTP NUNCA toca o disco no lado do cliente — o body vai por STDIN
#   ao transporte, ficando só na memória do processo. (Não há arquivo p/ "apagar": `shred` é ausente/
#   ineficaz em macOS+APFS — remoção de arquivo seria teatro. Eliminamos o arquivo, não confiamos no shred.)
#
# Contrato do transporte: "$STEPUP_TRANSPORT <op> <out-file>" (op ∈ send|verify), BODY JSON via STDIN,
#   exit 0 + grava a resposta em <out-file>.
#
# Uso: stepup-otp-client.sh fetch <email> <payload_hash> <action_label> [comprovante-out]
#   env: STEPUP_TRANSPORT (handle do transporte), STEPUP_OTP_CODE (testes não-interativos; senão lê do tty)
#
# Exit-codes:  0 comprovante obtido (stdout: path)  ·  2 invocação  ·  5 fail-closed
set -uo pipefail
umask 077

cmd="${1:-}"; shift 2>/dev/null || true
[ "$cmd" = "fetch" ] || { echo "uso: stepup-otp-client.sh fetch <email> <payload_hash> <action_label> [out]" >&2; exit 2; }

email="${1:?email}"; payload_hash="${2:?payload_hash}"; action_label="${3:?action_label}"
out="${4:-${TMPDIR:-/tmp}/stepup-comprovante.$$.json}"

# fail-closed: sem transporte resolvível → recusa (backend/rede inalcançável por construção)
transport="${STEPUP_TRANSPORT:-}"
if [ -z "$transport" ] || [ ! -x "$transport" ]; then
  echo "REASON=fail-closed (transporte de step-up ausente/inacessível)" >&2; exit 5
fi

# 1) send-otp: pede o código amarrado ao payload_hash + rótulo da ação (vai em claro no e-mail).
#    Body por STDIN — nada sensível aqui, mas mantém o contrato uniforme.
sendresp="${TMPDIR:-/tmp}/stepup-send.$$.out"
if ! printf '{"email":"%s","payload_hash":"%s","action_label":"%s"}\n' "$email" "$payload_hash" "$action_label" \
     | "$transport" send "$sendresp" >/dev/null 2>&1; then
  rm -f "$sendresp"; echo "REASON=fail-closed (send-otp inacessível)" >&2; exit 5
fi
rm -f "$sendresp"

# 2) coleta o código (não-interativo via env nos testes; senão do tty). Fica só em variável (memória).
code="${STEPUP_OTP_CODE:-}"
if [ -z "$code" ]; then
  printf 'Código do e-mail (ação: %s): ' "$action_label" > /dev/tty 2>/dev/null || true
  IFS= read -r code < /dev/tty 2>/dev/null || code=""
fi
[ -z "$code" ] && { echo "REASON=fail-closed (sem código)" >&2; exit 5; }

# 3) verify-otp: troca o código pelo COMPROVANTE ASSINADO (não booleano). O body COM o código vai por
#    STDIN — JAMAIS escrito num arquivo. Process-substitution mantém o segredo fora do disco.
if ! printf '{"email":"%s","code":"%s","payload_hash":"%s"}\n' "$email" "$code" "$payload_hash" \
     | "$transport" verify "$out" >/dev/null 2>&1; then
  echo "REASON=fail-closed (verify-otp inacessível)" >&2; exit 5
fi
code=""   # descarta da memória o quanto antes

# resposta vazia = fail-closed (nunca tratar ausência como sucesso)
if [ ! -s "$out" ]; then echo "REASON=fail-closed (comprovante vazio)" >&2; exit 5; fi

printf '%s\n' "$out"
exit 0
