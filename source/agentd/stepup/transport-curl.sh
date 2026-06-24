#!/bin/bash
# transport-curl.sh — transporte REAL do step-up (v14.4 · F0b). Vive FORA de source/agentd/*.sh
# (o gate-negativo do bootstrap grep esse glob non-recursive) — aqui é o único ponto que faz egress.
#
# Contrato (igual ao stub): "transport-curl.sh <op> <out-file>", BODY JSON via STDIN, exit 0 + resposta
# em <out-file>. Faz POST loopback→backend Supabase dedicado. Referencia tudo por ENV (nada hardcoded):
#   STEPUP_BACKEND_URL  = https://<ref>.supabase.co/functions/v1   (obrigatório)
#   STEPUP_ORIGIN       = http://127.0.0.1:<porta-do-cockpit>      (default 127.0.0.1:5273; o CORS da
#                         function exige loopback — curl não tem Origin natural, então mandamos um)
#   STEPUP_ANON_KEY     = anon key (PÚBLICA; opcional — só necessária se as functions exigirem JWT)
#
# credential-isolation: o body (com o código OTP) vem do STDIN e nunca toca o disco aqui.
set -uo pipefail
op="${1:?uso: transport-curl.sh <send|verify> <out-file>}"; out="${2:?out-file}"
url="${STEPUP_BACKEND_URL:?defina STEPUP_BACKEND_URL=https://<ref>.supabase.co/functions/v1}"
origin="${STEPUP_ORIGIN:-http://127.0.0.1:5273}"

case "$op" in
  send)   ep="send-otp" ;;
  verify) ep="verify-otp" ;;
  *) echo "REASON=bad-op ($op)" >&2; exit 2 ;;
esac

body=$(cat)   # body via STDIN (pode carregar o código OTP) — nunca persistido
code=$(curl -s -o "$out" -w '%{http_code}' --max-time 20 -X POST "$url/$ep" \
  -H "Content-Type: application/json" \
  -H "Origin: $origin" \
  ${STEPUP_ANON_KEY:+-H "Authorization: Bearer $STEPUP_ANON_KEY"} \
  ${STEPUP_ANON_KEY:+-H "apikey: $STEPUP_ANON_KEY"} \
  --data-binary "$body" 2>/dev/null) || { echo "REASON=curl-failed" >&2; exit 5; }

if [ "$code" != "200" ]; then echo "REASON=http-$code" >&2; exit 5; fi
exit 0
