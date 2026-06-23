#!/bin/bash
# verify-payload.sh — verifica a assinatura de um payload contra a lista pinada AUTORITATIVA-LOCAL (v14.4 · B1).
#
# Fail-closed (R-WP1/R-WP2). Exit-codes específicos (consumidos pelo gate agregado anti-teatro · B4):
#   0  válido & autorizado
#   3  assinatura inválida (inclui downgrade: sha256 correto NÃO salva assinatura ruim)
#   4  chave não-pinada
#   5  papel forjado (role do payload diverge do PIN)
#   6  sem assinatura (sha256 sozinho NUNCA autoriza)
#   2  erro de invocação
set -uo pipefail

NS="ideiaos-cockpit-cmd@v14.4"
HERE="$(cd "$(dirname "$0")" && pwd)"
PK="$HERE/pinned-keys.sh"

payload="${1:?uso: verify-payload.sh <payload> <sig> <claimed_machine_id>}"
sig="${2:?sig-file}"
claimed="${3:?claimed_machine_id}"

# (R-WP1) sem assinatura → recusa. sha256 sozinho nunca autoriza.
if [ ! -s "$sig" ]; then echo "REASON=no-signature" >&2; exit 6; fi

# chave pinada localmente?
if ! bash "$PK" is-pinned "$claimed"; then echo "REASON=not-pinned" >&2; exit 4; fi

# allowed_signers a partir do PIN (autoridade local, nunca do ref/payload)
as=$(mktemp)
if ! bash "$PK" allowed-signers-for "$claimed" > "$as" 2>/dev/null; then
  rm -f "$as"; echo "REASON=not-pinned" >&2; exit 4
fi

# verifica a assinatura sobre os BYTES do payload (sha256 nunca é trusted aqui)
if ! ssh-keygen -Y verify -f "$as" -I "$claimed" -n "$NS" -s "$sig" < "$payload" >/dev/null 2>&1; then
  rm -f "$as"; echo "REASON=invalid-signature" >&2; exit 3
fi
rm -f "$as"

# (R-WP2) o papel autorizador vem do PIN; role declarado no payload que DIVIRJA do pin → recusa
pinrole=$(bash "$PK" role-of "$claimed")
payrole=$(sed -n 's/.*"role"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$payload" | head -1)
if [ -n "$payrole" ] && [ "$payrole" != "$pinrole" ]; then
  echo "REASON=role-forged pin=$pinrole payload=$payrole" >&2; exit 5
fi

echo "OK role=$pinrole machine=$claimed"
exit 0
