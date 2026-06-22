// SOURCE: IdeiaOS v14 | kind: server-local | targets: apps/cockpit
// =============================================================================
// read.js — Server local loopback lendo o read-model SQLite via node:sqlite
//
// Endpoints:
//   GET /machines  — lista máquinas com machine_id + last_doctor (derivado do
//                    snapshot mais recente: doctor.exit 0="ok"|1="fail"; warn>0="warn")
//   GET /health    — { ok: true }
//
// Segurança (M-01 / ADR v14):
//   BIND EXPLÍCITO host: '127.0.0.1' — bind-all proibido (loopback-only)
//   O treasure-map de metadata (chaves presentes/ausentes, daemons, projetos)
//   NÃO pode escapar para a LAN. Toda chamada externa é rejeitada pelo OS.
//
// Runtime: Node 18+ com node:sqlite (DatabaseSync — built-in, SEM npm install).
// ESM (package.json "type":"module"); zero deps externas — supply-chain nula.
// read-model.db lido em: ~/.ideiaos/console/read-model.db (plano 06).
// =============================================================================

import { DatabaseSync } from 'node:sqlite';
import http from 'node:http';
import os   from 'node:os';
import path from 'node:path';
import fs   from 'node:fs';
import { fileURLToPath } from 'node:url';

// ── Caminhos ─────────────────────────────────────────────────────────────────
const DB_PATH = path.join(os.homedir(), '.ideiaos', 'console', 'read-model.db');

// ── Porta padrão (env READ_PORT override para testes) ─────────────────────
const PORT = parseInt(process.env.READ_PORT || '3073', 10);

// ── BIND LOOPBACK (M-01) — host: '127.0.0.1' explícito; bind-all proibido
const HOST = '127.0.0.1';

// ── Derivar last_doctor do payload_json do snapshot mais recente ─────────────
// doctor.exit: -1=nunca rodou, 0=ok, 1=fail. Se warn>0 e fail==0 → 'warn'.
function doctorFromPayload(payloadJson) {
  if (!payloadJson) return 'unknown';
  try {
    const snap = JSON.parse(payloadJson);
    const d    = snap.doctor;
    if (!d)                         return 'unknown';
    if (d.exit === 0 && d.warn > 0) return 'warn';
    if (d.exit === 0)               return 'ok';
    if (d.exit === 1)               return 'fail';
    return 'unknown'; // exit -1 = nunca rodou
  } catch {
    return 'unknown';
  }
}

// ── Abrir DB ─────────────────────────────────────────────────────────────────
function openDb() {
  if (!fs.existsSync(DB_PATH)) {
    throw new Error(
      'read-model.db não encontrado: ' + DB_PATH +
      ' — rode: node source/console/ingest.js'
    );
  }
  return new DatabaseSync(DB_PATH);
}

// ── Handler GET /machines ─────────────────────────────────────────────────────
function handleMachines(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    // JOIN machine com snapshot mais recente para derivar last_doctor.
    // machine não tem coluna last_doctor no schema v14.0 — derivado do payload.
    const rows = db.prepare(`
      SELECT
        m.machine_id,
        ms.payload_json
      FROM machine m
      LEFT JOIN machine_snapshot ms
        ON ms.machine_id = m.machine_id
        AND ms.taken_epoch = (
          SELECT MAX(taken_epoch)
          FROM machine_snapshot
          WHERE machine_id = m.machine_id
        )
      ORDER BY m.machine_id
    `).all();

    const result = rows.map(row => ({
      machine_id:  row.machine_id,
      last_doctor: doctorFromPayload(row.payload_json ?? null),
    }));

    res.writeHead(200, {
      'Content-Type': 'application/json',
      // CORS local: permite a SPA em 127.0.0.1:5273 chamar 127.0.0.1:3073
      'Access-Control-Allow-Origin': 'http://127.0.0.1:5273',
    });
    res.end(JSON.stringify(result));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }
}

// ── HTTP server ───────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/machines') {
    return handleMachines(res);
  }
  if (req.method === 'GET' && req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, db: DB_PATH }));
    return;
  }
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'not found' }));
});

// BIND EXPLÍCITO em loopback (M-01): host: '127.0.0.1'
// bind-all proibido — contém o treasure-map ao loopback
server.listen(PORT, HOST, () => {
  process.stdout.write('[read.js] server em http://' + HOST + ':' + PORT + '/ db=' + DB_PATH + '\n');
});

server.on('error', (e) => {
  process.stderr.write('[read.js] erro: ' + e.message + '\n');
  process.exit(1);
});
