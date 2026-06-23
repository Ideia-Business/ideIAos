#!/bin/bash
# stub-transport.sh — transporte FAKE local p/ o gate de bootstrap (v14.4 · F0a, harness-only).
#
# NÃO é produção. Honra o contrato real: "stub-transport.sh <op> <out-file>", body JSON via STDIN.
# Prova credential-isolation do cliente: consome o body do stdin numa VARIÁVEL (memória), NUNCA grava
# o código em arquivo. Em `verify`, devolve um comprovante de teste pré-montado (env STUB_COMPROVANTE).
set -uo pipefail
op="${1:?op}"; out="${2:?out-file}"
body=$(cat)   # consome stdin — NÃO persiste (o body pode carregar o código OTP)
: "${body:=}" # referencia (evita unused) sem ecoar
case "$op" in
  send)   printf '{"success":true}\n' > "$out" ;;
  verify)
    if [ -n "${STUB_COMPROVANTE:-}" ] && [ -s "${STUB_COMPROVANTE:-}" ]; then
      cat "$STUB_COMPROVANTE" > "$out"
    else
      printf '{"comprovante":{},"sig":"stub"}\n' > "$out"
    fi ;;
  *) echo "REASON=bad-op" >&2; exit 2 ;;
esac
