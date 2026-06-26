#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-21)
# test-deploy-hooks.sh — gate de IGUALDADE DE SET + deploy data-driven em sandbox.
#
# Prova que o loop data-driven (IDEIAOS_HOOKS) deploya EXATAMENTE o mesmo conjunto de
# hooks que os ~11 blocos copy-paste do setup.sh — nem a menos (esqueci um) nem a mais
# (inventei um). É o drift-guard que torna seguro remover os blocos incrementalmente.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="$ROOT/source/lib/deploy-hooks.sh"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

. "$HELPER"

echo "── igualdade de SET: IDEIAOS_HOOKS == blocos *_TEMPLATE do setup.sh ──"
A="$(printf '%s\n' "${IDEIAOS_HOOKS[@]}" | sort)"
B="$(grep -oE '_TEMPLATE="\$SETUP_DIR/source/hooks/[a-z0-9-]+\.sh"' "$ROOT/setup.sh" \
      | sed -E 's#.*source/hooks/([a-z0-9-]+)\.sh.*#\1#' | sort -u)"
if [ "$A" = "$B" ]; then
  ok "SET igual: $(printf '%s\n' "$A" | grep -c . ) hooks na lista == blocos do setup.sh"
else
  bad "DRIFT lista≠blocos:"; diff <(printf '%s\n' "$A") <(printf '%s\n' "$B") | sed 's/^/      /'
fi

echo "── cada hook da lista existe na fonte source/hooks/ ──"
miss=0
for h in "${IDEIAOS_HOOKS[@]}"; do [ -f "$ROOT/source/hooks/$h.sh" ] || { bad "fonte ausente: $h.sh"; miss=1; }; done
[ "$miss" -eq 0 ] && ok "todos os ${#IDEIAOS_HOOKS[@]} hooks da lista existem em source/hooks/"

echo "── deploy_all_hooks num sandbox limpo deploya exatamente N arquivos ──"
SBX="$(mktemp -d "${TMPDIR:-/tmp}/deploy-hooks.XXXXXX")"; trap 'rm -rf "$SBX"' EXIT
DST="$SBX/hooks"
OUT="$(deploy_all_hooks "$ROOT/source/hooks" "$DST")"
N="${#IDEIAOS_HOOKS[@]}"
n_inst="$(printf '%s\n' "$OUT" | grep -c INSTALLED || true)"
[ "$n_inst" -eq "$N" ] && ok "1ª passada: $N INSTALLED" || bad "esperava $N INSTALLED, veio $n_inst"
printf '%s\n' "$OUT" | grep -q MISSING && bad "algum hook veio MISSING (fonte incompleta?)" || ok "nenhum MISSING"
n_files="$(ls "$DST"/*.sh 2>/dev/null | grep -c . || true)"
[ "$n_files" -eq "$N" ] && ok "$N arquivos no destino (nada a mais, nada a menos)" || bad "esperava $N arquivos, há $n_files"
# todos executáveis
nonx=0; for f in "$DST"/*.sh; do [ -x "$f" ] || nonx=1; done
[ "$nonx" -eq 0 ] && ok "todos os hooks deployados são executáveis (chmod +x)" || bad "algum hook não-executável"

echo "── idempotência: 2ª passada = tudo CURRENT ──"
OUT2="$(deploy_all_hooks "$ROOT/source/hooks" "$DST")"
n_cur="$(printf '%s\n' "$OUT2" | grep -c CURRENT || true)"
[ "$n_cur" -eq "$N" ] && ok "2ª passada: $N CURRENT (idempotente, diff)" || bad "esperava $N CURRENT, veio $n_cur"

echo "── setup.sh sintaxe válida após o insert do loop ──"
bash -n "$ROOT/setup.sh" && ok "setup.sh bash -n OK" || bad "setup.sh sintaxe quebrada"

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
