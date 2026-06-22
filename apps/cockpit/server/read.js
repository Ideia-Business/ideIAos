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
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { execFileSync, spawnSync } from 'node:child_process';

// ── Caminhos ─────────────────────────────────────────────────────────────────
const DB_PATH = path.join(os.homedir(), '.ideiaos', 'console', 'read-model.db');

// ── ROOT do repo (cwd dos verbos do /command; spawnSync roda os scripts daqui) ─
// read.js vive em apps/cockpit/server/ → ROOT = ../../../ (raiz do IdeiaOS).
const __filename = fileURLToPath(import.meta.url);
const __dirname  = path.dirname(__filename);
const ROOT       = path.resolve(__dirname, '..', '..', '..');

// ── Porta padrão (env READ_PORT override para testes) ─────────────────────
const PORT = parseInt(process.env.READ_PORT || '3073', 10);

// ── BIND LOOPBACK (M-01) — host: '127.0.0.1' explícito; bind-all proibido
const HOST = '127.0.0.1';

// =============================================================================
// CANAL POST /command — superfície de COMANDO (executa spawnSync na máquina do
// operador). É o ÚNICO endpoint de mutação; tudo abaixo é fail-closed.
// =============================================================================

// ── Token efêmero POR-BOOT (FIX S-01) — crypto.randomBytes, nunca durável,
// nunca commitado, nunca no contexto do LLM (credential-isolation). Vive só
// em memória deste processo; some no restart. O SPA o obtém via GET
// /command-token (Origin+Host-gated) e o reenvia em X-Cockpit-Token.
const COCKPIT_TOKEN = crypto.randomBytes(32).toString('hex');

// ── Origin same-origin do SPA (Vite strictPort 5273) + variante 127.0.0.1 ──
const ALLOWED_ORIGIN = 'http://127.0.0.1:5273';
// Host esperado (defeito DNS-rebinding: uma aba que resolve hostname-atacante →
// 127.0.0.1 chega com Host != esperado). Aceita a porta corrente (testes usam
// READ_PORT) em 127.0.0.1 ou localhost.
const ALLOWED_HOSTS = new Set([`127.0.0.1:${PORT}`, `localhost:${PORT}`]);

// ── Header CORS para o canal de comando (mesma origem do SPA) ──
const CMD_CORS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
};

// ── AUTENTICAÇÃO DO CANAL (FIX S-01) — Origin AND Host fail-closed.
// CORS NÃO é a defesa (uma aba local maliciosa via CSRF/DNS-rebinding ainda
// ENTREGA o POST). A defesa é validar server-side Origin AND Host; o browser
// FORÇA o header Origin real (JS não pode forjá-lo cross-origin via SOP).
// Retorna true se o request é da origem confiável (same-origin do SPA).
function isTrustedOrigin(req) {
  const origin = req.headers.origin || req.headers['origin'];
  const host   = req.headers.host   || req.headers['host'];
  if (origin !== ALLOWED_ORIGIN) return false; // Origin inválido → fail-closed
  if (!host || !ALLOWED_HOSTS.has(host)) return false; // Host inválido → anti-DNS-rebinding
  return true;
}

// ── ENUM TIPADO FECHADO de verbos (default-deny). 6 chaves EXATAS.
// args CONSTANTES — nenhum input do usuário é interpolado. spawnSync(file, argv)
// sem shell. arm:true ⇒ exige body.confirmed === true (armar-antes-de-disparar).
// FOREVER-OUT (A8): nenhum rotate/deploy/revoke/git push/gh pr aqui — gate prova.
const UID = process.getuid();
const VERBS = {
  // B1 — pausar autosync (destrutivo-mas-reversível → arm)
  pause_autosync:  { cmd: ['bash', 'scripts/autosync-pause.sh', 'on', 'via Cockpit'], arm: true },
  // B2 — retomar autosync (inverso de B1; não-destrutivo)
  resume_autosync: { cmd: ['bash', 'scripts/autosync-pause.sh', 'off'], arm: false },
  // B3 — re-selar frescor de segurança (carimba selo de integridade → arm)
  reseal_security: { cmd: ['bash', 'scripts/check-security-freshness.sh', '--record', 'PASS', '@security-reviewer'], arm: true },
  // B4 — forçar um ciclo de sync (idempotente)
  force_sync:      { cmd: ['launchctl', 'kickstart', '-k', `gui/${UID}/com.ideiaos.gitautosync`], arm: false },
  // B5 — kickstart de daemon X (cmd montado a partir de lookup-map fechado; ver handleCommand)
  kickstart_daemon: { cmd: null, arm: false },
  // B6 — rodar idea-doctor (read-only)
  run_doctor:      { cmd: ['bash', 'scripts/idea-doctor.sh'], arm: false },
};

// ── B5: lookup-map FECHADO de daemons (FIX S-04). body.daemon é usado SÓ como
// CHAVE deste objeto — NUNCA interpolado na arg launchctl. $UID vem de getuid().
// Nota: o daemon do console é 'cockpit' (o nome stale do doc 77 B5 foi corrigido).
const DAEMON_MAP = {
  envsync:                'com.ideiaos.envsync',
  'refresh-ai-security':  'com.ideiaos.refresh-ai-security',
  cockpit:                'com.ideiaos.cockpit',
};

// ── STDOUT VIA ZERO-LEAK (FIX S-03) — varre o stdout pelo detector
// (source/agentd/zeroleak-snapshot.sh) ANTES de devolver à UI. Materializa o
// stdout num tmpfile, roda o scanner (exit 0 = limpo, exit 1 = segredo
// detectado) e devolve o stdout SÓ se limpo; caso contrário, redige.
// É output-as-surface (OWASP LLM02): nunca retornar stdout cru sem o detector.
function zeroLeakScan(stdout) {
  const text = String(stdout || '');
  if (text.length === 0) return { clean: true, stdout: '' };
  let tmp;
  try {
    tmp = path.join(os.tmpdir(), `cockpit-cmd-${crypto.randomBytes(8).toString('hex')}.json`);
    // o scanner exige arquivo não-vazio; encapsula o stdout como JSON p/ a varredura S7
    fs.writeFileSync(tmp, JSON.stringify({ stdout: text }), { mode: 0o600 });
    const scan = spawnSync('bash', [path.join('source', 'agentd', 'zeroleak-snapshot.sh'), tmp], {
      cwd: ROOT, encoding: 'utf8',
    });
    // exit 0 = limpo; qualquer outro (1 = segredo, 2 = erro) → redige por segurança
    const clean = scan.status === 0;
    if (!clean) {
      return { clean: false, stdout: '[REDIGIDO: Zero-Leak detectou padrão de segredo no stdout]' };
    }
    // limpo → trunca p/ não estourar a UI (já scaneado)
    return { clean: true, stdout: text.slice(0, 4000) };
  } catch {
    // fail-closed: se o detector não rodou, NÃO vaze stdout cru
    return { clean: false, stdout: '[REDIGIDO: Zero-Leak indisponível — stdout não verificado]' };
  } finally {
    if (tmp) { try { fs.unlinkSync(tmp); } catch { /* ignore */ } }
  }
}

// ── Handler POST /command — fail-closed, NESTA ordem (auth → body → enum → arm → exec → zero-leak).
function handleCommand(req, res) {
  // (1) AUTENTICAÇÃO DO CANAL (FIX S-01) — ANTES de qualquer parse/exec.
  if (!isTrustedOrigin(req)) {
    res.writeHead(403, CMD_CORS);
    res.end(JSON.stringify({ error: 'origin/host não confiável (Origin+Host fail-closed)' }));
    return;
  }
  // Token efêmero por-boot exigido em X-Cockpit-Token. Ausente/inválido → 403.
  // Comparação em tempo-constante (timingSafeEqual) p/ não vazar por timing.
  const provided = req.headers['x-cockpit-token'] || '';
  const a = Buffer.from(String(provided));
  const b = Buffer.from(COCKPIT_TOKEN);
  const tokenOk = a.length === b.length && crypto.timingSafeEqual(a, b);
  if (!tokenOk) {
    res.writeHead(403, CMD_CORS);
    res.end(JSON.stringify({ error: 'X-Cockpit-Token ausente ou inválido' }));
    return;
  }

  // (2) BODY-PARSING HARDENED (FIX S-02) — Content-Type + cap 4KB + JSON.parse try/catch.
  const ctype = (req.headers['content-type'] || '').split(';')[0].trim();
  if (ctype !== 'application/json') {
    res.writeHead(415, CMD_CORS);
    res.end(JSON.stringify({ error: 'Content-Type deve ser application/json' }));
    return;
  }
  const MAX_BODY = 4096; // 4KB = 4 * 1024
  let raw = '';
  let aborted = false;
  req.on('data', (chunk) => {
    if (aborted) return;
    raw += chunk;
    if (raw.length > MAX_BODY) {
      aborted = true;
      res.writeHead(413, CMD_CORS);
      res.end(JSON.stringify({ error: 'body > 4KB (413)' }));
      req.destroy();
    }
  });
  req.on('end', () => {
    if (aborted) return;
    let body;
    try {
      body = JSON.parse(raw);
    } catch {
      res.writeHead(400, CMD_CORS);
      res.end(JSON.stringify({ error: 'JSON malformado (400)' }));
      return;
    }
    if (!body || typeof body !== 'object') {
      res.writeHead(400, CMD_CORS);
      res.end(JSON.stringify({ error: 'body deve ser objeto JSON' }));
      return;
    }

    // (3) ENUM FECHADO — default-deny. Verbo fora do enum → 403 (gate v14.4).
    const v = VERBS[body.verb];
    if (!v) {
      res.writeHead(403, CMD_CORS);
      res.end(JSON.stringify({
        error: 'verbo fora do allowlist (default-deny) — capacidade exige o gate de v14.4',
        verb: typeof body.verb === 'string' ? body.verb : null,
      }));
      return;
    }

    // (4) ARMAR-ANTES-DE-DISPARAR server-side (Open Q4) — arm:true exige confirmed:true.
    if (v.arm && body.confirmed !== true) {
      res.writeHead(412, CMD_CORS);
      res.end(JSON.stringify({
        error: 'verbo destrutivo-mas-reversível exige confirmed:true (armar-antes-de-disparar)',
        verb: body.verb,
      }));
      return;
    }

    // (5) B5: monta o cmd a partir do lookup-map FECHADO (FIX S-04). body.daemon
    //     é SÓ chave; nunca interpolado. $UID de getuid(), nunca do body.
    let cmd = v.cmd;
    if (body.verb === 'kickstart_daemon') {
      const label = DAEMON_MAP[body.daemon];
      if (!label) {
        res.writeHead(403, CMD_CORS);
        res.end(JSON.stringify({ error: 'daemon fora do lookup-map fechado', daemon: null }));
        return;
      }
      cmd = ['launchctl', 'kickstart', '-k', `gui/${UID}/${label}`];
    }

    // (6) EXECUÇÃO — spawnSync(file, argsArray), SEM shell, args constantes.
    const proc = spawnSync(cmd[0], cmd.slice(1), {
      cwd: ROOT, encoding: 'utf8', timeout: 60000, maxBuffer: 4 * 1024 * 1024,
    });
    const exitCode = (typeof proc.status === 'number') ? proc.status : -1;

    // (7) STDOUT VIA ZERO-LEAK (FIX S-03) — varre ANTES do res.end. Nunca cru.
    const combined = (proc.stdout || '') + (proc.stderr ? ('\n' + proc.stderr) : '');
    const scanned = zeroLeakScan(combined);

    res.writeHead(200, CMD_CORS);
    res.end(JSON.stringify({
      verb: body.verb,
      exitCode,
      stdout: scanned.stdout,        // já varrido pelo Zero-Leak (S7)
      zeroleak: scanned.clean ? 'clean' : 'redacted',
    }));
  });
  req.on('error', () => {
    if (aborted) return;
    res.writeHead(400, CMD_CORS);
    res.end(JSON.stringify({ error: 'erro de leitura do body' }));
  });
}

// ── Handler GET /command-token — entrega o token efêmero ao SPA same-origin.
// Gated pelo MESMO Origin+Host (FIX S-01): só a origem confiável (o SPA em
// :5273) lê o token. Uma aba cross-origin chega com Origin != ALLOWED → 403 e
// NÃO consegue ler o token (o browser força o Origin real; SOP impede forja).
function handleCommandToken(req, res) {
  if (!isTrustedOrigin(req)) {
    res.writeHead(403, CMD_CORS);
    res.end(JSON.stringify({ error: 'origin/host não confiável' }));
    return;
  }
  res.writeHead(200, CMD_CORS);
  res.end(JSON.stringify({ token: COCKPIT_TOKEN }));
}

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

// ── Header CORS local (loopback-only) — fixo a 127.0.0.1:5273 (vite strictPort) ─
const JSON_CORS = {
  'Content-Type': 'application/json',
  'Access-Control-Allow-Origin': 'http://127.0.0.1:5273',
};

// ── Handler GET /overview ─────────────────────────────────────────────────────
// Contagens agregadas para o bento: máquinas, projetos e estado doctor derivado
// do snapshot mais recente por máquina (reusa doctorFromPayload — nunca nota fabricada).
function handleOverview(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    const machines = db.prepare('SELECT COUNT(*) AS n FROM machine').get().n;
    const projects = db.prepare('SELECT COUNT(*) AS n FROM project').get().n;

    // Estado doctor por máquina, derivado do snapshot mais recente.
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
    `).all();

    // Saúde por produto (spec): onde idea-doctor não roda (Lovable), 'n/a' — nunca fabricada.
    const checks = { ok: 0, warn: 0, fail: 0, unknown: 0 };
    for (const row of rows) {
      const d = doctorFromPayload(row.payload_json ?? null);
      if (d === 'ok')        checks.ok++;
      else if (d === 'warn') checks.warn++;
      else if (d === 'fail') checks.fail++;
      else                   checks.unknown++; // 'unknown' = sub-sinal n/a, não falha
    }

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify({ machines, projects, checks }));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }
}

// ── Handler GET /fleet ─────────────────────────────────────────────────────────
// Por-máquina: JOIN machine + snapshot mais recente (MAX(taken_epoch)) + daemon_status.
// installed_versions cru do payload (version-drift por STRING-EQUALITY na UI, nunca semver).
// last_seen_epoch cru para a UI computar "último sinal há Xh" (frescor honesto).
function handleFleet(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    const machines = db.prepare(`
      SELECT
        m.machine_id,
        m.canonical_name,
        m.os_version,
        m.agentd_version,
        m.last_seen_epoch,
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

    const daemonStmt = db.prepare(`
      SELECT label, pid, status_code, last_seen_epoch
      FROM daemon_status
      WHERE machine_id = ?
      ORDER BY label
    `);

    const result = machines.map(row => {
      // installed_versions vem do payload do snapshot (objeto { [key]: version_string }).
      let installed_versions = {};
      if (row.payload_json) {
        try {
          const snap = JSON.parse(row.payload_json);
          if (snap.installed_versions && typeof snap.installed_versions === 'object') {
            installed_versions = snap.installed_versions;
          }
        } catch { /* payload inválido → versões vazias, nunca inventadas */ }
      }

      return {
        machine_id:         row.machine_id,
        canonical_name:     row.canonical_name,
        os_version:         row.os_version,
        agentd_version:     row.agentd_version,
        last_seen_epoch:    row.last_seen_epoch,
        last_doctor:        doctorFromPayload(row.payload_json ?? null),
        daemons:            daemonStmt.all(row.machine_id),
        installed_versions,
      };
    });

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify(result));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }
}

// ── Handler GET /vault ─────────────────────────────────────────────────────────
// Matriz var × project a partir de api_key. METADATA-ONLY (credential-isolation):
// o schema NÃO tem coluna `value` e o SELECT NUNCA introduz um campo `value`.
function handleVault(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    // Colunas explícitas — SEM `value`. Qualquer SELECT * seria proibido aqui.
    const rows = db.prepare(`
      SELECT
        project_slug,
        var_name,
        present,
        expected,
        risk_tier,
        file_mtime_epoch,
        committed
      FROM api_key
      ORDER BY project_slug, var_name
    `).all();

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify(rows));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }
}

// ── Handler GET /verify?cell=<machine_id> ─────────────────────────────────────
// TRUST-RATE (A6): recomputa do DISCO no instante da pergunta — NUNCA de cache.
// Para a célula (machine_id) consultada, executa `git show cockpit:snapshots/<MID>.json`
// e compara o taken_epoch do disco com o servido pelo read-model.
//
// SEGURANÇA (T-14.1-01-T / Excessive Agency): o machine_id é VALIDADO contra um
// allowlist estrito (^[0-9a-f]{12}$ — sha256[:12]) ANTES de virar argumento; e o
// git é invocado por execFileSync com ARGV em ARRAY (sem shell) — input do usuário
// NUNCA é interpolado numa string de shell.
const MID_RE = /^[0-9a-f]{12}$/;

function handleVerify(req, res) {
  // Parse seguro do query param (sem montar URL com host arbitrário).
  const q = new URL(req.url, 'http://127.0.0.1').searchParams;
  const cell = q.get('cell') || '';

  if (!MID_RE.test(cell)) {
    res.writeHead(400, JSON_CORS);
    res.end(JSON.stringify({ error: 'cell inválido (esperado machine_id [0-9a-f]{12})' }));
    return;
  }

  // 1) Valor servido pelo read-model (o que o Cockpit AFIRMA).
  let servedEpoch = null;
  let db;
  try {
    db = openDb();
    const row = db.prepare(`
      SELECT MAX(taken_epoch) AS taken_epoch
      FROM machine_snapshot
      WHERE machine_id = ?
    `).get(cell);
    servedEpoch = row ? row.taken_epoch : null;
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }

  // 2) RECOMPUTE-FROM-DISK: git show cockpit:snapshots/<MID>.json (argv array, sem shell).
  //    A ref + o path são CONSTANTES com o MID já validado contra o allowlist.
  let diskEpoch = null;
  try {
    const out = execFileSync(
      'git',
      ['show', 'cockpit:snapshots/' + cell + '.json'],
      { encoding: 'utf8', maxBuffer: 8 * 1024 * 1024 }
    );
    const snap = JSON.parse(out);
    diskEpoch = (typeof snap.taken_epoch === 'number') ? snap.taken_epoch : null;
  } catch {
    // sem snapshot no disco para esta célula → não verificável (nunca inventar)
    diskEpoch = null;
  }

  const verified = diskEpoch !== null && servedEpoch !== null && diskEpoch === servedEpoch;

  res.writeHead(200, JSON_CORS);
  res.end(JSON.stringify({
    cell,
    verified,
    served_epoch:       servedEpoch,
    disk_epoch:         diskEpoch,
    recomputed_at_epoch: Math.floor(Date.now() / 1000),
    source:             'git-show-cockpit',
  }));
}

// ── HTTP server ───────────────────────────────────────────────────────────────
const server = http.createServer((req, res) => {
  if (req.method === 'GET' && req.url === '/machines') {
    return handleMachines(res);
  }
  if (req.method === 'GET' && req.url === '/overview') {
    return handleOverview(res);
  }
  if (req.method === 'GET' && req.url.startsWith('/verify')) {
    return handleVerify(req, res);
  }
  if (req.method === 'GET' && req.url === '/fleet') {
    return handleFleet(res);
  }
  if (req.method === 'GET' && req.url === '/vault') {
    return handleVault(res);
  }
  // Canal de COMANDO (FIX S-01..S-04) — token efêmero + POST /command autenticado.
  if (req.method === 'GET' && req.url === '/command-token') {
    return handleCommandToken(req, res);
  }
  if (req.method === 'POST' && req.url === '/command') {
    return handleCommand(req, res);
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
