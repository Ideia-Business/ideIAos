#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-19)
# test-idea-update.sh — prova o redeploy CANÔNICO do daemon por exit-code.
#
# Foco do R15-19: equivalência do redeploy canônico (cp-da-fonte) contra um daemon
# LEGADO real — o "caso de CURA" que um sandbox /tmp LIMPO (sem binário) não exercita.
# Aqui o destino existe e está DRIFTADO (binário antigo, sem guards); provamos que o
# cp-canônico o cura byte-a-byte e entrega TODOS os guards que os patchers in-place
# (steps 2/2b/2c/2d, agora deprecados) aplicariam — logo são redundantes.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/source/autosync/git-autosync.sh"
HELPER="$ROOT/source/lib/redeploy-daemon.sh"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

SBX="$(mktemp -d "${TMPDIR:-/tmp}/idea-update.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT
DST="$SBX/bin/git-autosync"; mkdir -p "$SBX/bin"
. "$HELPER"

echo "── caso de CURA: daemon deployado LEGADO/driftado (não limpo) ──"
# pior caso: conteúdo antigo SEM guards, e nem executável (0644)
printf '#!/usr/bin/env bash\n# git-autosync LEGADO (sem guards novos)\necho old\n' > "$DST"
chmod 0644 "$DST"
if cmp -s "$SRC" "$DST"; then bad "pré-condição inválida (deployado já == fonte)"; else ok "pré-condição: daemon deployado DIFERE da fonte (drift real)"; fi
TOK="$(redeploy_autosync_daemon "$SRC" "$DST")"
[ "$TOK" = "HEALED" ] && ok "redeploy → HEALED no daemon driftado" || bad "esperava HEALED, veio '$TOK'"
cmp -s "$SRC" "$DST" && ok "daemon curado é BYTE-A-BYTE igual à fonte (drift eliminado)" || bad "daemon não ficou == fonte"
[ -x "$DST" ] && ok "daemon curado é executável (chmod 0755 — corrige o 0644 legado)" || bad "daemon não-executável após cura"

echo "── equivalência: o cp entrega os guards que os patchers in-place aplicariam ──"
# Estes 3 guards são exatamente o que os steps 2/2d patcheavam in-place; vindo da
# fonte canônica, o cp os entrega todos → os patchers in-place são redundantes.
for g in "git-autosync.pause" "leftover conflict marker" "_autosync_surgery_active" "(exclude)versions.lock"; do
  grep -qF "$g" "$DST" && ok "guard presente no curado: $g" || bad "guard FALTANDO no curado: $g"
done

echo "── idempotência + casos de borda ──"
TOK2="$(redeploy_autosync_daemon "$SRC" "$DST")"
[ "$TOK2" = "ALREADY" ] && ok "2ª chamada = ALREADY (idempotente, cmp)" || bad "esperava ALREADY, veio '$TOK2'"
TOK3="$(redeploy_autosync_daemon "$SBX/nao-existe.sh" "$DST")"; r3=$?
[ "$TOK3" = "MISSING" ] && ok "fonte ausente → MISSING (não corrompe o destino)" || bad "esperava MISSING, veio '$TOK3'"
cmp -s "$SRC" "$DST" && ok "destino intacto após MISSING (nenhuma escrita parcial)" || bad "destino mexido no caminho MISSING"

echo "── sintaxe dos artefatos novos ──"
bash -n "$ROOT/scripts/idea-update.sh"          && ok "idea-update.sh sintaxe OK"     || bad "idea-update.sh sintaxe"
bash -n "$HELPER"                                && ok "redeploy-daemon.sh sintaxe OK" || bad "redeploy-daemon.sh sintaxe"

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
