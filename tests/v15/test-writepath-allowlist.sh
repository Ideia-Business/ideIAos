#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-18)
# test-writepath-allowlist.sh — allowlist /command LOCAL + ledger wired, por exit-code.
#
#   1. reseal_security NEUTRALIZADO — carimbar o selo @security-reviewer via clique de UI
#      afirmaria revisão humana inexistente = FRAUDE de gate (automate-the-reminder-not-stamp).
#   2. ledger hash-chained WIRED ao /command (antes: zero ocorrências) — aceitas E rejeitadas.
#   3. gate-negativo: input inválido → 'rejected' (nunca 'ok'); ledger rejeita append malformado.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
READ_JS="$ROOT/apps/cockpit/server/read.js"
LEDGER="$ROOT/source/agentd/ledger.sh"
PALETTE="$ROOT/apps/cockpit/src/components/CommandPalette.tsx"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

echo "── 1. allowlist corrigida + wiring presente (read.js) ──"
node --check "$READ_JS" && ok "read.js node --check OK" || bad "read.js sintaxe quebrada"
grep -qE "record.*PASS.*security-reviewer" "$READ_JS" \
  && bad "reseal_security AINDA carimba o selo (fraude de gate persiste)" \
  || ok "reseal_security NEUTRALIZADO — nenhum --record PASS @security-reviewer no /command"
grep -q "security_status" "$READ_JS" && ok "verbo read-only security_status presente (substitui o carimbo)" || bad "security_status ausente"
N="$(grep -c "recordCommandToLedger(" "$READ_JS")"
[ "$N" -ge 3 ] && ok "ledger WIRED ao /command (recordCommandToLedger ×$N: def + deny + exec)" || bad "wiring incompleto (×$N, esperado ≥3)"
grep -q "'rejected'" "$READ_JS" && ok "gate-negativo: rejeição auditada como 'rejected' (nunca 'ok')" || bad "rejeição não auditada"
grep -q "reseal_security" "$PALETTE" && bad "SPA ainda referencia reseal_security (botão chamaria verbo 403)" || ok "SPA alinhada ao backend (botão read-only)"

echo "── 2. ledger gate-negativo — a interface que o wiring usa ──"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/wp-allowlist.XXXXXX")"; trap 'rm -rf "$SBX"' EXIT
export IDEIAOS_LEDGER_STORE="$SBX/ledger"
# append exatamente como recordCommandToLedger faz: subject role action ref scope result
bash "$LEDGER" append cockpit-operator local-operator pause_autosync exit:0 command ok >/dev/null 2>&1 \
  && ok "append de comando ACEITO (6 campos do wiring) → exit 0" || bad "append válido falhou"
bash "$LEDGER" append cockpit-operator local-operator badverb denied command rejected >/dev/null 2>&1 \
  && ok "append de comando REJEITADO (caminho gate-negativo) → exit 0" || bad "append 'rejected' falhou"
bash "$LEDGER" verify >/dev/null 2>&1 && ok "verify: cadeia íntegra (exit 0)" || bad "verify falhou na cadeia válida"
# gate-negativo do próprio ledger: campos faltando → exit não-zero
if bash "$LEDGER" append soumcampo >/dev/null 2>&1; then bad "append incompleto deveria falhar (bad-field/usage)"; else ok "append malformado → exit não-zero (rejeitado)"; fi
# adulteração: append forjado direto no store sem atualizar HEAD → tail-anchor pega
echo "0000|forjado|x|x|x|x|x|x" >> "$IDEIAOS_LEDGER_STORE"
if bash "$LEDGER" verify >/dev/null 2>&1; then bad "verify CEGO à cauda (append forjado passou)"; else ok "verify pega append forjado na cauda (tail-anchor, exit≠0)"; fi

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
