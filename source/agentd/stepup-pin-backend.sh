#!/bin/bash
# stepup-pin-backend.sh — pin LOCAL da pubkey de COMPROVANTE do backend de step-up (v14.4 · B3/F0a).
#
# Decisão: docs/decisions/v14.4-stepup-comprovante-key-scheme.md.
#   • A pubkey Ed25519 do backend dedicado `ideiaos-cockpit-stepup` é PINADA aqui, LOCAL e out-of-band
#     (mesma cerimônia do pin O2). Pin POR BACKEND (um por backend), NÃO por máquina.
#   • Store autoritativo-LOCAL (0600). O ref/cloud NUNCA adiciona/altera/remove este pin
#     (espelha a FRONTEIRA-DE-PIN do O2 — nada do ref muta a confiança).
#   • DISTINTO de pinned-keys.sh (peers de máquina, ssh-keygen): cadeia de assinatura SEPARADA
#     (comprovante = Ed25519/WebCrypto, verificado por stepup-verify-comprovante.mjs).
#
# Store override por env (testes): IDEIAOS_STEPUP_PIN
# Formato: linhas "kid <spki-base64>" (kid = sha256(spki)[:16]; a pubkey é a âncora de confiança).
set -uo pipefail

STORE="${IDEIAOS_STEPUP_PIN:-$HOME/.ideiaos/cockpit/stepup-backend-pubkey}"

_ensure_store() { mkdir -p "$(dirname "$STORE")" 2>/dev/null || true; [ -f "$STORE" ] || : > "$STORE"; chmod 600 "$STORE" 2>/dev/null || true; }

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  add) # add <kid> <spki_b64> — enrollment LOCAL out-of-band (idempotente por kid)
    _ensure_store
    kid="${1:?kid}"; spki="${2:?spki_b64}"
    case "$kid" in *' '*|'') echo "REASON=bad-kid" >&2; exit 2;; esac
    grep -v "^$kid " "$STORE" > "$STORE.tmp" 2>/dev/null || true; mv -f "$STORE.tmp" "$STORE"
    printf '%s %s\n' "$kid" "$spki" >> "$STORE"; chmod 600 "$STORE" 2>/dev/null || true
    ;;
  list) # kid (NÃO expõe a pubkey inteira — só o rótulo)
    _ensure_store
    awk '{print $1}' "$STORE"
    ;;
  is-pinned) # exit 0 se <kid> está pinado localmente
    _ensure_store
    awk -v k="${1:?}" '$1==k{f=1} END{exit f?0:1}' "$STORE"
    ;;
  revoke-local) # remoção AUTORITATIVA local (re-pin out-of-band)
    _ensure_store
    grep -v "^${1:?} " "$STORE" > "$STORE.tmp" 2>/dev/null || true; mv -f "$STORE.tmp" "$STORE"; chmod 600 "$STORE" 2>/dev/null || true
    ;;
  path) printf '%s\n' "$STORE" ;;
  *)
    echo "uso: stepup-pin-backend.sh {add <kid> <spki_b64>|list|is-pinned <kid>|revoke-local <kid>|path}" >&2
    exit 2
    ;;
esac
