#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 | kind: gate | targets: claude,cursor
# =============================================================================
# test-cockpit-alerts.sh — gate do endpoint /alerts (Atalaia, doc 77).
# Seeda um read-model TEMPORÁRIO (COCKPIT_DB) com estado conhecido, sobe o read.js
# nesse DB + porta de teste, curla /alerts e assere os gatilhos determinísticos
# A1–A11. NÃO toca o read-model real nem a porta de produção. Exit 0 = pass.
# =============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${TEST_READ_PORT:-13073}"
TMP="$(mktemp -d)"; DB="$TMP/read-model.db"; PID=""
cleanup(){ [ -n "$PID" ] && kill "$PID" 2>/dev/null || true; rm -rf "$TMP"; }
trap cleanup EXIT
fail(){ echo "✗ $*"; exit 1; }
command -v node >/dev/null 2>&1 || fail "node ausente"
command -v curl >/dev/null 2>&1 || fail "curl ausente"

# 1) seed determinístico (schema + linhas que disparam A5/A7/A9/A10/A11).
cat > "$TMP/seed.mjs" <<'MJS'
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
const [DB, ROOT] = process.argv.slice(2);
const db = new DatabaseSync(DB);
db.exec(fs.readFileSync(ROOT + '/source/console/schema.sql', 'utf8'));
const now = Math.floor(Date.now() / 1000), old = now - 4000; // >15min, <3h → A11/A3 âmbar
db.exec(`INSERT INTO machine(machine_id,canonical_name,agentd_version,last_seen_epoch) VALUES ('mac1','Mac-mini','1.0.0',${old}),('mac2','MacBook','1.1.0',${old})`);
const pay = JSON.stringify({ security_freshness: { tier: 'egregious' } }).replace(/'/g, "''"); // A5
db.exec(`INSERT INTO machine_snapshot(machine_id,taken_epoch,agentd_version,payload_json) VALUES ('mac1',${old},'1.0.0','${pay}'),('mac2',${old},'1.1.0','{}')`);
db.exec(`INSERT INTO project(project_slug,machine_id) VALUES ('nf','mac1')`);
db.exec(`INSERT INTO api_key(project_slug,var_name,present,expected,risk_tier,committed) VALUES ('nf','SERVICE_ROLE',1,1,'critical',1)`); // A7 crítico
db.exec(`INSERT INTO soak_heartbeat(milestone,epoch,iso,host) VALUES ('v9',${now - 90000},'x','h1'),('v9',${now},'y','h2')`); // A9: 2 hosts, span≥1d
db.close();
MJS
node "$TMP/seed.mjs" "$DB" "$ROOT" || fail "seed falhou"

# 2) sobe o read.js apontando p/ o DB temp (env override COCKPIT_DB).
COCKPIT_DB="$DB" READ_PORT="$PORT" node "$ROOT/apps/cockpit/server/read.js" >"$TMP/read.log" 2>&1 &
PID=$!
up=0; for _ in $(seq 1 50); do curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1 && { up=1; break; }; sleep 0.2; done
[ "$up" = 1 ] || { cat "$TMP/read.log"; fail "read.js não subiu na porta $PORT"; }

# 3) curl /alerts.
curl -fsS "http://127.0.0.1:$PORT/alerts" -o "$TMP/alerts.json" 2>/dev/null || fail "GET /alerts falhou"

# 4) asserts (parse JSON via node — exit-code binário).
cat > "$TMP/assert.mjs" <<'MJS'
import fs from 'node:fs';
const j = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const a = j.alerts || [];
const find = (id) => a.find((x) => x.id === id);
const want = [
  ['A5', 'active', 'crítico'], ['A7', 'active', 'crítico'], ['A9', 'active', null],
  ['A10', 'active', null], ['A11', 'active', null],
  ['A1', 'no-data', null], ['A2', 'no-data', null], ['A6', 'no-data', null], ['A8', 'no-data', null],
];
let ok = true;
const ids = new Set(a.map((x) => x.id));
for (const id of ['A1','A2','A3','A4','A5','A6','A7','A8','A9','A10','A11']) {
  if (!ids.has(id)) { console.error('catálogo incompleto: faltou ' + id); ok = false; }
}
for (const [id, st, sv] of want) {
  const it = find(id);
  if (!it) { console.error('faltou ' + id); ok = false; continue; }
  if (st && it.status !== st) { console.error(id + ' status=' + it.status + ' esperado ' + st); ok = false; }
  if (sv && it.severity !== sv) { console.error(id + ' sev=' + it.severity + ' esperado ' + sv); ok = false; }
}
process.exit(ok ? 0 : 1);
MJS
node "$TMP/assert.mjs" "$TMP/alerts.json" || fail "asserts do /alerts falharam"
echo "✓ /alerts (Atalaia): 11 ids do catálogo; A5/A7/A9/A10/A11 ativos; A1/A2/A6/A8 no-data honesto"
