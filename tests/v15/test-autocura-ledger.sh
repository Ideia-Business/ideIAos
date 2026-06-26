#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-20)
# test-autocura-ledger.sh — prova o ledger de auto-cura/propagação por exit-code.
#
#   A) propagate-if-changed apende ao ledger no caminho NOOP (sandbox real, sem
#      tocar o sistema — diff só-docs → NEED_GLOBAL/PROJECT=0 → NOOP).
#   B) idea-doctor §16 LÊ a última linha e classifica FAIL → WARN (torna visível
#      o drift silencioso — o coração do R15-20). Run real do doctor.
#   C) o §16 mapeia também OK e NOOP (estático — anti-teatro de branch faltante).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROP="$ROOT/scripts/propagate-if-changed.sh"
DOCTOR="$ROOT/scripts/idea-doctor.sh"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

SBX="$(mktemp -d "${TMPDIR:-/tmp}/autocura.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT

echo "── A. append real no caminho NOOP (sandbox, sem tocar o sistema) ──"
# IdeiaOS-falso mínimo: só o propagate copiado. SETUP_DIR=dirname/.. = $SBX.
mkdir -p "$SBX/scripts"
cp "$PROP" "$SBX/scripts/propagate-if-changed.sh"
git -C "$SBX" init -q; git -C "$SBX" config user.email t@t; git -C "$SBX" config user.name t
echo base > "$SBX/base.txt"; git -C "$SBX" add -A; git -C "$SBX" commit -q -m c1
C1="$(git -C "$SBX" rev-parse HEAD)"
# commit 2: só um .md na raiz — NÃO casa nenhum path propagável → NOOP determinístico.
echo "doc" > "$SBX/meu-doc.md"; git -C "$SBX" add -A; git -C "$SBX" commit -q -m c2
STATE="$SBX/state"; mkdir -p "$STATE"; echo "$C1" > "$STATE/last-propagate.hash"
LEDGER="$SBX/propagate-ledger.log"
IDEIAOS_STATE_DIR="$STATE" IDEIAOS_PROPAGATE_LEDGER="$LEDGER" IDEIAOS_PROPAGATE_LOG="$SBX/prop.log" \
  bash "$SBX/scripts/propagate-if-changed.sh" >/dev/null 2>&1 || true
if [ -s "$LEDGER" ] && grep -q '|NOOP|' "$LEDGER"; then
  ok "ledger apendido com verdict NOOP no caminho sem-paths-propagáveis"
else
  bad "ledger NÃO recebeu linha NOOP (conteúdo: $(cat "$LEDGER" 2>/dev/null | tr '\n' ';'))"
fi
# formato: 7 campos pipe-delimited (epoch|iso|host|verdict|range|errors|note)
NF="$(tail -1 "$LEDGER" 2>/dev/null | awk -F'|' '{print NF}')"
[ "${NF:-0}" -eq 7 ] && ok "linha do ledger tem 7 campos (epoch|iso|host|verdict|range|errors|note)" \
  || bad "formato inesperado do ledger (NF=$NF, esperado 7)"

echo "── B. idea-doctor §16 classifica FAIL → WARN (run real, ~14s) ──"
FIX="$SBX/ledger-fail.log"
{
  printf '%s|2026-06-26T10:00:00|machA|OK|aaaaaaaa..bbbbbbbb|0|global=1 project=0\n' "$(( $(date +%s) - 172800 ))"
  printf '%s|2026-06-26T11:00:00|machA|FAIL|bbbbbbbb..cccccccc|2|2 erro(s)\n' "$(( $(date +%s) - 3600 ))"
} > "$FIX"
DOUT="$(IDEIAOS_PROPAGATE_LEDGER="$FIX" bash "$DOCTOR" 2>&1 || true)"
printf '%s' "$DOUT" | grep -q "última propagação FALHOU" \
  && ok "§16 mostra 'última propagação FALHOU' lendo a ÚLTIMA linha (FAIL visível)" \
  || bad "§16 não classificou a última linha como FAIL"
# o §16 leu a ÚLTIMA linha (FAIL), não a 1ª (OK) — prova tail -1, não head
printf '%s' "$DOUT" | grep -q "última propagação OK" \
  && bad "§16 mostrou OK (leu a linha errada — deveria ser a última = FAIL)" \
  || ok "§16 ignorou a linha OK anterior (heartbeat = última linha)"

echo "── C. §16 mapeia OK e NOOP além de FAIL (anti-teatro de branch faltante) ──"
grep -q 'OK)   pass "última propagação OK' "$DOCTOR" && ok "branch OK presente" || bad "branch OK ausente no §16"
grep -q 'NOOP) pass "última propagação sem-ação' "$DOCTOR" && ok "branch NOOP presente" || bad "branch NOOP ausente no §16"

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
