#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 | kind: gate | targets: source/console/machine-aliases.json
# R15-07 — cruza cada machine_id real do ref cockpit contra o alias-map:
#   resolveAlias(mid) != mid  → PASS (casou num nome legível)
#   entrada presente com valor == sha256 → FAIL (rótulo inútil)
#   mid ausente do map        → WARN (máquina-nova-não-curada — NÃO falha)
#   ZERO PASS com MIDs curáveis → FAIL (o bug original ainda vivo)
#
# Build-script (antifragile-gates): exit 1 em falha. NÃO é hook.
# bash 3.2 (sem declare -A); o cruzamento determinístico roda em node (espelha ingest.js:60).
set -u

# Localizar a raiz do repo independentemente do CWD
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || { echo "FAIL: não consegui cd para a raiz do repo"; exit 1; }

ALIAS_MAP="source/console/machine-aliases.json"

# Dependência: o alias-map precisa existir e ser não-vazio
. source/lib/gates.sh 2>/dev/null || require_file() { test -s "${1:-}" 2>/dev/null; }
require_file "$ALIAS_MAP" "alias-map" || { echo "FAIL: $ALIAS_MAP ausente/vazio"; exit 1; }

# MIDs reais do ref cockpit. Clone fresco sem ref cockpit = nada a cruzar → WARN, exit 0.
if ! git rev-parse --verify cockpit >/dev/null 2>&1; then
  echo "WARN: ref cockpit ausente (clone fresco) — nenhuma frota para cruzar ainda; exit 0"
  exit 0
fi

MIDS="$(git ls-tree --name-only cockpit snapshots/ 2>/dev/null | sed 's#snapshots/##; s#\.json##' | grep -E '^[0-9a-f]{12}$' || true)"
if [ -z "$MIDS" ]; then
  echo "WARN: ref cockpit sem snapshots/<MID>.json — nada a cruzar; exit 0"
  exit 0
fi

# Cruzamento determinístico em node (espelha resolveAlias = aliases[mid] || mid).
# Recebe a lista de MIDs como argv; decide o exit-code conforme a regra do requisito.
node -e '
  const fs=require("fs");
  const a=JSON.parse(fs.readFileSync("source/console/machine-aliases.json","utf8"));
  const resolveAlias=(mid)=> a[mid] || mid;          // ESPELHA ingest.js:60
  const mids=process.argv.slice(1).filter(Boolean);
  let pass=0, warn=0, fail=0;
  for(const mid of mids){
    const r=resolveAlias(mid);
    if(r!==mid){ console.log("PASS "+mid+" -> "+r); pass++; }
    else if(Object.prototype.hasOwnProperty.call(a,mid)){ console.log("FAIL "+mid+" (valor == sha256)"); fail++; }
    else { console.log("WARN "+mid+" nao-curado"); warn++; }
  }
  console.log("--- "+pass+" PASS / "+warn+" WARN / "+fail+" FAIL ("+mids.length+" MIDs)");
  if(fail>0) process.exit(1);
  if(pass===0 && mids.length>0) process.exit(1);     // map nao resolve nenhum MID = bug vivo
  process.exit(0);
' $MIDS
EXIT=$?
if [ "$EXIT" -eq 0 ]; then
  echo "OK: alias-map resolve os MIDs do ref cockpit (chave×MID cruzado)"
fi
exit "$EXIT"
