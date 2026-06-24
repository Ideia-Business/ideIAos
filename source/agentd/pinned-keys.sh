#!/bin/bash
# pinned-keys.sh — lista pinada AUTORITATIVA-LOCAL de peers do Cockpit write-path (v14.4 · B0/B2/B0-bis)
#
# Decisão ACEITA (docs/decisions/v14.4-origin-auth-signing-mechanism.md):
#   • a lista autoritativa vive LOCAL (store 0600), estabelecida out-of-band no enrollment;
#   • a cópia no ref `cockpit` é ESPELHO NÃO-CONFIÁVEL — NADA vindo do ref adiciona/altera/remove pin;
#   • cada entrada = {machine_id, fingerprint, role, signing_pubkey}; o `role` autorizador vem do PIN (R-WP2);
#   • revogação autoritativa = re-pin out-of-band LOCAL; revogação/adição via ref = ALERTA, nunca efetiva
#     (fecha o CRÍTICO: host comprometido, chave ainda pinada, assinaria a revogação da chave BOA → DoS).
#
# B0-bis (docs/decisions/v14.4-command-ref-origin-exposure.md, ACEITO — pré-req do SELO do canal):
#   • o selo exige uma CHAVE DE ENCRIPTAÇÃO por destinatário, INDEPENDENTE da Ed25519 de assinatura
#     (não derivada — sem reuso de chave entre primitivas). A entrada do pin vira
#     {machine_id, fingerprint, role, signing_pubkey, enc_pubkey} (5º campo = enc_pubkey X25519 raw b64).
#   • a `enc_pubkey` vem SÓ do pin local (nunca do payload/ref → sem downgrade/substituição).
#   • RETROCOMPAT: `add` de 3 args continua válido (5º campo vazio); list/role-of/allowed-signers-for
#     permanecem IDÊNTICOS (campos 1-3/3/4). Pins legados sem enc_pubkey: enc-pubkey-of → exit 4.
#
# Store local override por env (para testes): IDEIAOS_PINNED_STORE
set -uo pipefail

STORE="${IDEIAOS_PINNED_STORE:-$HOME/.ideiaos/cockpit/pinned-keys}"

_ensure_store() { mkdir -p "$(dirname "$STORE")" 2>/dev/null || true; [ -f "$STORE" ] || : > "$STORE"; chmod 600 "$STORE" 2>/dev/null || true; }

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  add) # add <machine_id> <role> <pubkey_file> [enc_pubkey_file] — enrollment LOCAL out-of-band (idempotente)
    #   4º arg OPCIONAL (B0-bis): arquivo com a enc_pubkey X25519 raw em base64 (1 linha) → 5º campo.
    #   Sem o 4º arg, o 5º campo fica VAZIO (retrocompat total com o pin O2 original).
    _ensure_store
    mid="${1:?machine_id}"; role="${2:?role}"; pub="${3:?pubkey_file}"; encf="${4:-}"
    fp=$(ssh-keygen -lf "$pub" 2>/dev/null | awk '{print $2}')
    [ -z "$fp" ] && { echo "REASON=bad-pubkey" >&2; exit 2; }
    keyline=$(awk 'NF>=2{print $1" "$2; exit}' "$pub")   # keytype keydata (sem comentário)
    enc=""
    if [ -n "$encf" ]; then
      enc=$(awk 'NF>=1{print $1; exit}' "$encf" 2>/dev/null)   # 1ª linha não-vazia = enc_pubkey b64
      [ -z "$enc" ] && { echo "REASON=bad-enc-pubkey" >&2; exit 2; }
    fi
    grep -v "^$mid|" "$STORE" > "$STORE.tmp" 2>/dev/null || true; mv -f "$STORE.tmp" "$STORE"
    printf '%s|%s|%s|%s|%s\n' "$mid" "$fp" "$role" "$keyline" "$enc" >> "$STORE"; chmod 600 "$STORE" 2>/dev/null || true
    ;;
  list) # machine_id|fingerprint|role (3 campos — NÃO expõe a pubkey)
    _ensure_store
    cut -d'|' -f1-3 "$STORE"
    ;;
  role-of) # role-of <machine_id> — papel autoritativo (do PIN)
    _ensure_store
    grep "^${1:?}|" "$STORE" | head -1 | cut -d'|' -f3
    ;;
  is-pinned) # exit 0 se <machine_id> está pinado localmente
    _ensure_store
    grep -q "^${1:?}|" "$STORE"
    ;;
  allowed-signers-for) # emite linha allowed_signers (ssh-keygen -Y verify) p/ <machine_id>
    _ensure_store
    line=$(grep "^${1:?}|" "$STORE" | head -1)
    [ -z "$line" ] && { echo "REASON=not-pinned" >&2; exit 4; }
    printf '%s %s\n' "$1" "$(printf '%s' "$line" | cut -d'|' -f4)"
    ;;
  enc-pubkey-of) # enc-pubkey-of <machine_id> — emite a enc_pubkey X25519 raw b64 (5º campo) p/ o SELO.
    #   B0-bis: a seleção da enc_pubkey vem SÓ do pin local (nunca do payload/ref). Vazia/legado → exit 4.
    _ensure_store
    line=$(grep "^${1:?}|" "$STORE" | head -1)
    [ -z "$line" ] && { echo "REASON=not-pinned" >&2; exit 4; }
    enc=$(printf '%s' "$line" | cut -d'|' -f5)
    [ -z "$enc" ] && { echo "REASON=no-enc-pubkey" >&2; exit 4; }
    printf '%s\n' "$enc"
    ;;
  revoke-local) # remoção AUTORITATIVA local (re-pin out-of-band)
    _ensure_store
    grep -v "^${1:?}|" "$STORE" > "$STORE.tmp" 2>/dev/null || true; mv -f "$STORE.tmp" "$STORE"; chmod 600 "$STORE" 2>/dev/null || true
    ;;
  process-ref-revocation) # entrada de revogação vinda do REF — ALERTA, NUNCA remove (mesmo se assinada por peer pinado)
    echo "ALERT REASON=ref-revocation-ignored: revogação-via-ref ignorada — use re-pin local out-of-band (fail-closed contra revogação forjada)" >&2
    exit 9
    ;;
  process-ref-addition) # entrada de adição vinda do REF — RECUSADA (nada do ref muta a lista)
    echo "ALERT REASON=ref-addition-refused: adição-de-pin via ref recusada — use enrollment out-of-band local" >&2
    exit 9
    ;;
  *)
    echo "uso: pinned-keys.sh {add|list|role-of|is-pinned|allowed-signers-for|enc-pubkey-of|revoke-local|process-ref-revocation|process-ref-addition}" >&2
    exit 2
    ;;
esac
