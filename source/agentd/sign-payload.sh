#!/bin/bash
# sign-payload.sh — assina um payload de comando com a chave por-máquina (v14.4 · B0).
#
# Mecanismo ACEITO (O2): assinatura de PAYLOAD via `ssh-keygen -Y sign` (NÃO commit-signing = O3).
# credential-isolation / R-WP1: a chave privada é referenciada por PATH (deploy: keychain/ssh-agent)
# e lida DIRETO pelo ssh-keygen — este script NUNCA materializa o material da chave numa variável,
# arquivo ou log. A saída é só a ASSINATURA, jamais a chave.
set -uo pipefail

NS="ideiaos-cockpit-cmd@v14.4"
# No deploy: a chave vive no keychain/ssh-agent; aqui referenciamos o handle por path (nunca o valor).
KEY="${IDEIAOS_SIGN_KEY:?defina IDEIAOS_SIGN_KEY=<handle-da-chave> (deploy: keychain/ssh-agent)}"
payload="${1:?uso: sign-payload.sh <payload-file> [sig-out]}"
sigout="${2:-$payload.sig}"

# ssh-keygen lê o handle direto e grava a assinatura em <payload>.sig
if ! ssh-keygen -Y sign -f "$KEY" -n "$NS" "$payload" >/dev/null 2>&1; then
  echo "REASON=sign-failed" >&2
  exit 1
fi
[ "$payload.sig" != "$sigout" ] && mv -f "$payload.sig" "$sigout"
printf '%s\n' "$sigout"
