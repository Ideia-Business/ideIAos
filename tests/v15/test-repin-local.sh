#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-23)
# test-repin-local.sh — PROOF-GATE do teardown/re-pin LOCAL da chave O2 (own-fleet).
#
# Operacionaliza por exit-code o invariante de revogação que antes era prosa no ADR
# (mitigated-label-must-not-outrun-precondition): re-pin local ROTACIONA a chave O2,
# revoke-local faz o TEARDOWN autoritativo, e o REF NUNCA muta a lista (fail-closed
# contra revogação/adição forjada). Espelha temp-privilege-window-teardown-grants — a
# janela de privilégio é revogável de verdade, localmente, sem depender do ref.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PK="$ROOT/source/agentd/pinned-keys.sh"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

command -v ssh-keygen >/dev/null 2>&1 || { echo "  ⊙ ssh-keygen ausente — proof-gate pulado (skip gracioso)"; exit 0; }

SBX="$(mktemp -d "${TMPDIR:-/tmp}/repin-local.XXXXXX")"; trap 'rm -rf "$SBX"' EXIT
export IDEIAOS_PINNED_STORE="$SBX/pinned"
MID="abc123def456"   # 12 hex (machine_id own-fleet)
ssh-keygen -t ed25519 -f "$SBX/k1" -N "" -q
ssh-keygen -t ed25519 -f "$SBX/k2" -N "" -q
printf 'ZW5jMW9uZS1iYXNlNjQtcGxhY2Vob2xkZXI=\n' > "$SBX/enc1"   # enc_pubkey O2 #1 (placeholder b64)
printf 'ZW5jMnR3by1iYXNlNjQtcGxhY2Vob2xkZXI=\n' > "$SBX/enc2"   # enc_pubkey O2 #2 (rotação)

echo "── 1. pin inicial da chave O2 ──"
bash "$PK" add "$MID" peer "$SBX/k1.pub" "$SBX/enc1" >/dev/null 2>&1 && ok "add (pin O2 #1) → exit 0" || bad "add inicial falhou"
bash "$PK" is-pinned "$MID" && ok "is-pinned=0 após pin" || bad "is-pinned devia ser 0"
E1="$(bash "$PK" enc-pubkey-of "$MID" 2>/dev/null)"
[ "$E1" = "$(cat "$SBX/enc1")" ] && ok "enc-pubkey-of = O2 #1 (vem só do pin local)" || bad "enc-pubkey-of errada ($E1)"

echo "── 2. RE-PIN local rotaciona a chave O2 (teardown da antiga) ──"
bash "$PK" add "$MID" peer "$SBX/k2.pub" "$SBX/enc2" >/dev/null 2>&1 && ok "re-pin (add O2 #2) → exit 0" || bad "re-pin falhou"
E2="$(bash "$PK" enc-pubkey-of "$MID" 2>/dev/null)"
[ "$E2" = "$(cat "$SBX/enc2")" ] && ok "enc-pubkey-of = O2 #2 (rotacionada)" || bad "re-pin não rotacionou ($E2)"
[ "$E2" != "$E1" ] && ok "chave O2 antiga não é mais autoritativa (E2≠E1)" || bad "chave antiga persiste após re-pin"
NREP="$(grep -c "^$MID|" "$IDEIAOS_PINNED_STORE" 2>/dev/null || echo 0)"
[ "$NREP" -eq 1 ] && ok "re-pin SUBSTITUIU (1 entrada — sem duplicata)" || bad "re-pin duplicou ($NREP entradas)"

echo "── 3. revoke-local = TEARDOWN autoritativo ──"
bash "$PK" revoke-local "$MID" >/dev/null 2>&1 && ok "revoke-local → exit 0" || bad "revoke-local falhou"
if bash "$PK" is-pinned "$MID"; then bad "is-pinned ainda 0 após revoke (teardown não efetivou)"; else ok "is-pinned≠0 após revoke (teardown efetivo)"; fi
if bash "$PK" enc-pubkey-of "$MID" >/dev/null 2>&1; then bad "enc-pubkey-of devia falhar (not-pinned)"; else ok "enc-pubkey-of → exit≠0 após revoke (chave O2 indisponível)"; fi

echo "── 4. invariante FAIL-CLOSED: revogação/adição via REF nunca muta a lista ──"
bash "$PK" add "$MID" peer "$SBX/k1.pub" "$SBX/enc1" >/dev/null 2>&1   # re-pin p/ testar o ref
if bash "$PK" process-ref-revocation >/dev/null 2>&1; then bad "process-ref-revocation devia sair ≠0"; else ok "process-ref-revocation → exit≠0 (ALERTA, ignorada)"; fi
bash "$PK" is-pinned "$MID" && ok "pin PRESERVADO após ref-revocation FORJADA (fecha o CRÍTICO de DoS)" || bad "ref-revocation REMOVEU o pin (vulnerável a revogação forjada)"
if bash "$PK" process-ref-addition >/dev/null 2>&1; then bad "process-ref-addition devia sair ≠0"; else ok "process-ref-addition → exit≠0 (recusada — nada do ref adiciona pin)"; fi

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
