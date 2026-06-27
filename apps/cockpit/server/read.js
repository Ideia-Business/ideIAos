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
const DB_PATH = process.env.COCKPIT_DB || path.join(os.homedir(), '.ideiaos', 'console', 'read-model.db');

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
  // B3 — frescor de segurança: SÓ leitura do tier (R15-18). NUNCA carimba via UI.
  // Carimbar o selo @security-reviewer por clique afirmaria uma revisão humana que não
  // ocorreu = FRAUDE de gate de integridade (automate-the-reminder-not-the-integrity-stamp).
  // O re-selar REAL é exceção declarada: exige @security-reviewer no diff + --record no CLI,
  // FORA do canal /command. Aqui o operador só VÊ o estado (read-only, não-mutante).
  security_status: { cmd: ['bash', 'scripts/check-security-freshness.sh', '--tier'], arm: false },
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

// ── Auditoria do write-path (R15-18) — registra TODA tentativa de comando no ledger
// hash-chained local (source/agentd/ledger.sh): aceitas (com exit) E rejeitadas. Wiring
// NOVO (antes: zero ocorrências). Metadata-only (sem stdout/segredo — credential-isolation).
// best-effort: uma falha de ledger NUNCA quebra a resposta do canal.
function recordCommandToLedger(verb, refField, result) {
  try {
    spawnSync('bash', [path.join('source', 'agentd', 'ledger.sh'), 'append',
      'cockpit-operator', 'local-operator', String(verb || 'unknown'),
      String(refField || '-'), 'command', String(result)],
      { cwd: ROOT, encoding: 'utf8', timeout: 10000 });
  } catch { /* auditoria é best-effort — nunca derruba o canal /command */ }
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
      // gate-negativo (R15-18): verbo inválido é REJEITADO e auditado como 'rejected'
      // (nunca 'ok') — input inválido jamais vira sucesso no ledger.
      recordCommandToLedger(typeof body.verb === 'string' ? body.verb : 'non-string', 'denied', 'rejected');
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

    // auditoria (R15-18): comando aceito → registra exit-code e ok|fail (metadata-only).
    recordCommandToLedger(body.verb, 'exit:' + exitCode, exitCode === 0 ? 'ok' : 'fail');

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
    // Frescor de segurança (R15-14): PIOR tier entre os snapshots (egregious>warn>ok).
    // Lido do payload (security_freshness.tier); 'unknown' honesto se nenhum reportou.
    const TIER_RANK = { ok: 1, warn: 2, egregious: 3 };
    let worstTier = null;
    for (const row of rows) {
      const d = doctorFromPayload(row.payload_json ?? null);
      if (d === 'ok')        checks.ok++;
      else if (d === 'warn') checks.warn++;
      else if (d === 'fail') checks.fail++;
      else                   checks.unknown++; // 'unknown' = sub-sinal n/a, não falha

      if (row.payload_json) {
        try {
          const t = JSON.parse(row.payload_json)?.security_freshness?.tier;
          if (t && TIER_RANK[t] && (!worstTier || TIER_RANK[t] > TIER_RANK[worstTier])) {
            worstTier = t;
          }
        } catch { /* payload inválido → ignora, nunca inventa tier */ }
      }
    }
    const security_freshness = worstTier || 'unknown';

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify({ machines, projects, checks, security_freshness }));
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
      // installed_versions + accounts (gh) vêm do payload do snapshot.
      // installed_versions: { [key]: version_string }; accounts: [{host,user,protocol,active}]
      // — accounts é METADATA-ONLY (sem token; credential-isolation). Vazios se payload
      // inválido — nunca inventados.
      let installed_versions = {};
      let accounts = [];
      if (row.payload_json) {
        try {
          const snap = JSON.parse(row.payload_json);
          if (snap.installed_versions && typeof snap.installed_versions === 'object') {
            installed_versions = snap.installed_versions;
          }
          if (Array.isArray(snap.accounts)) {
            accounts = snap.accounts;
          }
        } catch { /* payload inválido → vazios, nunca inventados */ }
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
        accounts,
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

// ── Handler GET /projects ──────────────────────────────────────────────────────
// Lista projetos descobertos por máquina (iteração ~/dev/*/.git no agentd).
// Expõe supabase_project_id (CKF-07): o vínculo produto↔backend Supabase. METADATA
// pura — supabase_project_id é o ref PÚBLICO do projeto, não chave (credential-isolation).
function handleProjects(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    // Colunas explícitas — nenhuma carrega segredo; supabase_project_id é ref público.
    const rows = db.prepare(`
      SELECT
        project_slug,
        machine_id,
        path,
        remote_url,
        supabase_project_id,
        is_test_dir,
        class_reason,
        last_seen_epoch
      FROM project
      ORDER BY project_slug
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

// ── Handler GET /soak ──────────────────────────────────────────────────────────
// Span REAL de cada milestone em SOAK, agregado do ledger soak_heartbeat.
// span_seconds = MAX(epoch) - MIN(epoch): o span é o DELTA dos epochs GRAVADOS,
// NUNCA wall-clock desde o 1º heartbeat (soak-span-is-record-delta-not-wallclock).
// span_ge_1d materializa o gate real do SOAK (≥1d de span gravado). Expõe também o
// último veredito idea_doctor/regression por milestone (heartbeat de maior epoch).
function handleSoak(res) {
  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    const rows = db.prepare(`
      SELECT
        milestone,
        COUNT(*)                AS heartbeats,
        COUNT(DISTINCT host)    AS hosts,
        MIN(epoch)              AS min_epoch,
        MAX(epoch)              AS max_epoch,
        MAX(epoch) - MIN(epoch) AS span_seconds
      FROM soak_heartbeat
      GROUP BY milestone
      ORDER BY milestone
    `).all();

    // Último veredito por milestone (heartbeat de maior epoch).
    const lastStmt = db.prepare(`
      SELECT idea_doctor, regression, commit_hash, host, epoch
      FROM soak_heartbeat
      WHERE milestone = ?
      ORDER BY epoch DESC
      LIMIT 1
    `);

    const result = rows.map(r => {
      const last = lastStmt.get(r.milestone) || {};
      return {
        milestone:        r.milestone,
        heartbeats:       r.heartbeats,
        hosts:            r.hosts,
        min_epoch:        r.min_epoch,
        max_epoch:        r.max_epoch,
        span_seconds:     r.span_seconds,
        span_ge_1d:       r.span_seconds >= 86400, // gate real do SOAK (span gravado, não wall-clock)
        last_idea_doctor: last.idea_doctor || '',
        last_regression:  last.regression  || '',
        last_commit:      last.commit_hash || '',
        last_host:        last.host        || '',
        last_epoch:       last.epoch       ?? null,
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

// ── Handler GET /doctor?cell=<machine_id> ─────────────────────────────────────
// Drill-down do idea-doctor da máquina: as sections do snapshot mais recente.
// section emitida por `idea-doctor --json` (preenche após o fix do --json, bugfix
// f80e9c5; snapshots pré-fix devolvem sections=[] — HONESTO, nunca inventado).
// SEGURANÇA (Excessive Agency): machine_id validado contra MID_RE (mesmo allowlist
// do /verify) ANTES de virar parâmetro do SELECT preparado.
function handleDoctor(req, res) {
  const q = new URL(req.url, 'http://127.0.0.1').searchParams;
  const cell = q.get('cell') || '';

  if (!MID_RE.test(cell)) {
    res.writeHead(400, JSON_CORS);
    res.end(JSON.stringify({ error: 'cell inválido (esperado machine_id [0-9a-f]{12})' }));
    return;
  }

  let db;
  try {
    db = openDb();
  } catch (e) {
    res.writeHead(503, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
    return;
  }

  try {
    const row = db.prepare(`
      SELECT payload_json
      FROM machine_snapshot
      WHERE machine_id = ?
      ORDER BY taken_epoch DESC
      LIMIT 1
    `).get(cell);

    if (!row) {
      res.writeHead(404, JSON_CORS);
      res.end(JSON.stringify({ error: 'máquina sem snapshot', cell }));
      return;
    }

    // doctor default = "nunca rodou" (exit -1, sections []). Nunca inventado.
    let doctor = { ok: 0, warn: 0, fail: 0, exit: -1, sections: [] };
    try {
      const snap = JSON.parse(row.payload_json);
      if (snap.doctor && typeof snap.doctor === 'object') {
        doctor = {
          ok:       snap.doctor.ok   ?? 0,
          warn:     snap.doctor.warn ?? 0,
          fail:     snap.doctor.fail ?? 0,
          exit:     snap.doctor.exit ?? -1,
          sections: Array.isArray(snap.doctor.sections) ? snap.doctor.sections : [],
        };
      }
    } catch { /* payload inválido → doctor default, nunca inventado */ }

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify({ cell, ...doctor }));
  } catch (e) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: e.message }));
  } finally {
    if (db) try { db.close(); } catch { /* ignore */ }
  }
}

// ── Handler GET /alerts (Atalaia — catálogo doc 77, A1–A11) ───────────────────
// Gatilhos DETERMINÍSTICOS sobre o read-model + payload do snapshot. Cada alerta:
// {id, title, severity('crítico'|'atenção'|'info'), status, detail}. status:
//   'active' (disparado) · 'clear' (saudável) · 'no-data' (insumo não coletado —
//   HONESTO, nunca fabrica; doc 77 §A.1 "n/a honesto"). NUNCA lê valor de segredo
//   (só present/risk_tier/committed). READ-only: zero mutação, zero spawn, zero rede.
function handleAlerts(res) {
  let db;
  try { db = openDb(); }
  catch (e) { res.writeHead(503, JSON_CORS); res.end(JSON.stringify({ error: e.message })); return; }
  const now = Math.floor(Date.now() / 1000);
  const alerts = [];
  const add = (id, title, severity, status, detail) => alerts.push({ id, title, severity, status, detail });
  try {
    // Snapshot mais recente por máquina (payload + idade + versão).
    const snaps = db.prepare(`
      SELECT m.machine_id, m.canonical_name, m.agentd_version, ms.taken_epoch, ms.payload_json
      FROM machine m
      LEFT JOIN machine_snapshot ms ON ms.machine_id = m.machine_id
        AND ms.taken_epoch = (SELECT MAX(taken_epoch) FROM machine_snapshot WHERE machine_id = m.machine_id)
    `).all();
    const nameOf = (s) => s.canonical_name || s.machine_id;
    const stale = snaps.filter((s) => s.taken_epoch && (now - s.taken_epoch) > 900);

    // A11 — snapshot stale por máquina (>15min âmbar, >3h crítico).
    if (snaps.length === 0) add('A11', 'Snapshot por máquina', 'atenção', 'no-data', 'sem snapshots no read-model');
    else if (stale.length === 0) add('A11', 'Snapshot por máquina', 'info', 'clear', `${snaps.length} máquina(s) com sinal fresco (≤15min)`);
    else { const worst = stale.reduce((a, s) => Math.max(a, now - s.taken_epoch), 0);
      add('A11', 'Snapshot stale por máquina', worst > 10800 ? 'crítico' : 'atenção', 'active',
        stale.map((s) => `${nameOf(s)}: há ${Math.round((now - s.taken_epoch) / 60)}min`).join(' · ')); }

    // A3 — autosync/daemon parado (proxy honesto: snapshot não avança → ref parado nessa máquina).
    if (stale.length > 0) add('A3', 'Autosync/daemon possivelmente parado',
      stale.some((s) => (now - s.taken_epoch) > 10800) ? 'crítico' : 'atenção', 'active',
      `ref não avança em: ${stale.map(nameOf).join(', ')}`);
    else add('A3', 'Autosync/daemon', 'info', 'clear', 'refs avançando');

    // A10 — agentd_version drift entre máquinas (string-equality, NUNCA semver).
    const versions = [...new Set(snaps.map((s) => s.agentd_version).filter(Boolean))];
    if (versions.length === 0) add('A10', 'agentd_version drift', 'atenção', 'no-data', 'versão do agentd não reportada');
    else if (versions.length === 1) add('A10', 'agentd_version', 'info', 'clear', `frota na versão ${versions[0]}`);
    else add('A10', 'agentd_version drift', 'atenção', 'active', `versões divergentes: ${versions.join(' vs ')}`);

    // A4/A5 — security tier (pior entre os payloads). warn→A4 (âmbar); egregious→A5 (crítico).
    const TIER = { ok: 1, warn: 2, egregious: 3 };
    let worstTier = null;
    for (const s of snaps) { try { const t = JSON.parse(s.payload_json || '{}')?.security_freshness?.tier;
      if (t && TIER[t] && (!worstTier || TIER[t] > TIER[worstTier])) worstTier = t; } catch { /* payload ilegível */ } }
    if (!worstTier) {
      add('A4', 'Security tier → stale', 'atenção', 'no-data', 'tier não coletado (próximo ciclo do agentd)');
      add('A5', 'Security tier → egrégio', 'crítico', 'no-data', 'tier não coletado (próximo ciclo do agentd)');
    } else {
      add('A4', 'Security tier → stale', 'atenção', worstTier === 'warn' ? 'active' : 'clear',
        worstTier === 'warn' ? 'rode @security-reviewer + --record' : 'tier não-stale');
      add('A5', 'Security tier → egrégio', 'crítico', worstTier === 'egregious' ? 'active' : 'clear',
        worstTier === 'egregious' ? 'rode @security-reviewer + --record (trava tag quando --gate ligado)' : 'tier não-egrégio');
    }

    // A7 — .env exposto no git (api_key committed). crítico se risk crítico/sensível; âmbar se público.
    const exposed = db.prepare(`SELECT project_slug, var_name, risk_tier FROM api_key WHERE committed = 1`).all();
    const crit = exposed.filter((r) => r.risk_tier === 'critical' || r.risk_tier === 'sensitive');
    if (exposed.length === 0) add('A7', '.env exposto no git', 'info', 'clear', 'nenhum segredo tracked');
    else if (crit.length > 0) add('A7', '.env exposto no git (segredo crítico)', 'crítico', 'active', `${crit.length} var(es) crítica(s) tracked — git rm --cached via PR @devops`);
    else add('A7', '.env público tracked', 'atenção', 'active', `${exposed.length} var(es) pública(s) tracked (VITE_/anon) — aceitável`);

    // A9 — SOAK pronto-p/-tag (máquinas≥2 E span gravado≥1d por milestone — não wall-clock).
    const soakRows = db.prepare(`SELECT milestone, COUNT(DISTINCT host) AS hosts, MAX(epoch) - MIN(epoch) AS span FROM soak_heartbeat GROUP BY milestone`).all();
    const ready = soakRows.filter((r) => r.hosts >= 2 && r.span >= 86400);
    if (soakRows.length === 0) add('A9', 'SOAK pronto-p/-tag', 'info', 'no-data', 'sem heartbeats de SOAK');
    else if (ready.length > 0) add('A9', 'SOAK pronto-p/-tag', 'info', 'active', `PRONTO: ${ready.map((r) => r.milestone).join(', ')} (2+ máquinas, span≥1d) — @devops tagueia`);
    else add('A9', 'SOAK pronto-p/-tag', 'info', 'clear', 'nenhum milestone fechou span≥1d ainda');

    // A1/A2/A6/A8 — insumos que o collector v14 ainda NÃO emite → 'no-data' honesto (doc 77 §A.1).
    add('A1', 'Drift versions.lock', 'atenção', 'no-data', 'collector não coleta versions.lock×instalado (deferido)');
    add('A2', 'Regressão deny-list', 'crítico', 'no-data', 'ledger estruturado de contenção (doc 01) não emitido ainda');
    add('A6', '.env órfão (vs .env.example)', 'atenção', 'no-data', 'diff .env×.env.example não coletado (deferido)');
    add('A8', '.env.local em iCloud', 'atenção', 'no-data', 'resolução de path iCloud não coletada (deferido)');

    res.writeHead(200, JSON_CORS);
    res.end(JSON.stringify({ generated_epoch: now, count_active: alerts.filter((a) => a.status === 'active').length, alerts }));
  } catch (e) {
    res.writeHead(500, JSON_CORS); res.end(JSON.stringify({ error: e.message }));
  } finally { if (db) try { db.close(); } catch { /* ignore */ } }
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
  if (req.method === 'GET' && req.url === '/projects') {
    return handleProjects(res);
  }
  if (req.method === 'GET' && req.url === '/soak') {
    return handleSoak(res);
  }
  if (req.method === 'GET' && req.url === '/alerts') {
    return handleAlerts(res);
  }
  if (req.method === 'GET' && req.url.startsWith('/doctor')) {
    return handleDoctor(req, res);
  }
  // Canal de COMANDO (FIX S-01..S-04) — token efêmero + POST /command autenticado.
  if (req.method === 'GET' && req.url === '/command-token') {
    return handleCommandToken(req, res);
  }
  // ── Preflight CORS do canal (FIX S-05) — o POST /command é "non-simple"
  // (Content-Type JSON + header X-Cockpit-Token) ⇒ o browser dispara um OPTIONS
  // preflight ANTES do POST. Sem este handler o preflight cai no 404 e o browser
  // BLOQUEIA o POST (net::ERR_FAILED): o ⌘K não funciona via SPA. (curl não faz
  // preflight, por isso o canal passava só no curl/exit-code e quebrava no browser.)
  // SEGURANÇA: o preflight só AUTORIZA o browser a enviar; a auth real
  // (Origin+Host+token, fail-closed) permanece intacta em handleCommand. Echo de
  // Allow-Origin SÓ p/ origem confiável (nunca '*'); origem não-confiável recebe
  // 403 sem Allow-* ⇒ o browser bloqueia mesmo assim.
  if (req.method === 'OPTIONS' && req.url === '/command') {
    if (!isTrustedOrigin(req)) {
      res.writeHead(403, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'origin/host não confiável (preflight)' }));
      return;
    }
    res.writeHead(204, {
      'Access-Control-Allow-Origin':  ALLOWED_ORIGIN,
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, X-Cockpit-Token',
      'Access-Control-Max-Age':       '600',
      'Vary':                         'Origin',
    });
    res.end();
    return;
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
