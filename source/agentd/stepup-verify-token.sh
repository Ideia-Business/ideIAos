#!/bin/bash
# stepup-verify-token.sh — verifica o TOKEN de capability O2 no ALVO (v14.4 · B4 / R-WP3).
#
# Compõe verify-payload.sh (B1: assinatura de máquina + papel-do-PIN) e adiciona a semântica do
# TOKEN de step-up, FAIL-CLOSED:
#   1. assinatura de máquina inválida / chave não-pinada / papel forjado → propaga 3/4/5/6 (verify-payload.sh);
#   2. expiry no passado → exit 8 (REASON=expired);
#   3. binding: token.action != ação pretendida no alvo → exit 7 (REASON=binding);
#   4. nonce já visto (registro DURÁVEL, sobrevive a restart de processo) → exit 10 (REASON=nonce-reused);
#      inédito → registra e segue. (anti-replay R-WP3 + Q4)
#
# NÃO modifica verify-payload.sh (preserva os 19/19 já provados) — compõe por cima (enforce-simplicity).
# antifragile-gates: veredito = EXIT-CODE.
#
# Uso: stepup-verify-token.sh <token-file> <token-sig> <claimed_machine_id> <intended_action>
#   env: IDEIAOS_PINNED_STORE (peers de máquina), IDEIAOS_NONCE_STORE (dir durável de nonces)
#
# Exit-codes:
#   0  token válido & inédito
#   2  erro de invocação
#   3/4/5/6  propagados de verify-payload.sh (sig inválida / não-pinada / papel forjado / sem-assinatura)
#   7  binding divergente            (REASON=binding)
#   8  token expirado                (REASON=expired)
#   10 nonce reusado (replay durável) (REASON=nonce-reused)
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
VERIFY_PAYLOAD="$HERE/verify-payload.sh"
NONCE_STORE="${IDEIAOS_NONCE_STORE:-$HOME/.ideiaos/cockpit/seen-nonces}"

token="${1:?uso: stepup-verify-token.sh <token> <sig> <claimed_machine_id> <intended_action>}"
sig="${2:?sig}"
claimed="${3:?claimed_machine_id}"
intended="${4:?intended_action}"

# 1) assinatura de máquina + papel-do-PIN (B1). Propaga o exit-code específico (3/4/5/6).
# ⚠️ NÃO usar `if ! cmd; then rc=$?` — após um `!`-negado, $? é SEMPRE 0 (aceitaria token forjado).
# Capturar o rc REAL primeiro, depois ramificar (mesmo padrão correto de stepup-token.sh).
bash "$VERIFY_PAYLOAD" "$token" "$sig" "$claimed" >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ]; then echo "REASON=machine-sig (verify-payload rc=$rc)" >&2; exit "$rc"; fi

_field() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$token" | head -1; }
action=$(_field action)
nonce=$(_field nonce)
expiry=$(sed -n 's/.*"expiry"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' "$token" | head -1)

# 2) expiry
now=$(date +%s)
[ -z "$expiry" ] && { echo "REASON=expired (sem expiry)" >&2; exit 8; }
if [ "$expiry" -le "$now" ]; then echo "REASON=expired exp=$expiry now=$now" >&2; exit 8; fi

# 3) binding: a ação do token tem que ser a ação pretendida no alvo
if [ "$action" != "$intended" ]; then
  echo "REASON=binding token-action=$action intended=$intended" >&2; exit 7
fi

# 4) anti-replay durável (cross-processo): nonce visto?  FAIL-CLOSED — se o store não persiste, RECUSA
#    (S-N1: store não-gravável NÃO pode degradar a anti-replay PRIMÁRIA do R-WP3 para fail-open).
[ -z "$nonce" ] && { echo "REASON=nonce-reused (sem nonce)" >&2; exit 10; }
mkdir -p "$NONCE_STORE" 2>/dev/null || { echo "REASON=nonce-store-unwritable" >&2; exit 10; }
nid=$(printf '%s' "token:$nonce" | shasum -a 256 | awk '{print $1}')
if [ -e "$NONCE_STORE/$nid" ]; then echo "REASON=nonce-reused nonce=$nonce" >&2; exit 10; fi
# registra (durável, atômico) — consome o nonce; se NÃO conseguir persistir (store RO/cheio OU corrida
# que criou o $nid entre o teste e agora), RECUSA — nunca aceita sem registrar (fail-closed).
if ! ( set -o noclobber; : > "$NONCE_STORE/$nid" ) 2>/dev/null; then
  echo "REASON=nonce-store-unwritable (anti-replay fail-closed)" >&2; exit 10
fi

echo "OK action=$action machine=$claimed"
exit 0
