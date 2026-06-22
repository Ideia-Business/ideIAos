// SOURCE: IdeiaOS v14 | kind: console-ingest | targets: claude,cursor
// =============================================================================
// ingest.js — ETL: ref cockpit + ledgers disco -> read-model SQLite descartável
//
// Invariante A5 (reconstrutibilidade): rm read-model.db && node ingest.js
//   reconstrói integralmente dos refs — o DB é CACHE, nunca source-of-truth.
//
// Credential-isolation (DoD #1):
//   api_key SEM coluna `value` — ingest nunca escreve o campo value.
//   Nenhum objeto transitado por aqui contém valor de segredo.
//
// Runtime: Node 24 com node:sqlite (DatabaseSync nativo — sem npm install).
// Ledgers lidos: .planning/soak/*.log (-> soak_heartbeat).
//   security-ledger NÃO ingerido aqui: tabela security_seal é v14.2+.
//
// Dedup/Classificação (Task 3):
//   - Machine dedup via machine-aliases.json (192 -> Mac-mini-de-Gustavo)
//   - gsd por string-equality (nunca semver — version-reset-migration-semver-trap)
//   - ator classificado deterministicamente antes do UPSERT:
//       subject ^wip: autosync | autor .local$ -> actor_class='autosync'
//       autor [bot]@                            -> actor_class='bot'
//       senão                                   -> actor_class='human'
// =============================================================================
'use strict';

const { DatabaseSync } = require('node:sqlite');
const { execSync }     = require('child_process');
const fs               = require('fs');
const path             = require('path');
const os               = require('os');

// ---------------------------------------------------------------------------
// Constantes e caminhos
// ---------------------------------------------------------------------------
const REPO_ROOT   = path.join(__dirname, '..', '..');
const SCHEMA_PATH = path.join(__dirname, 'schema.sql');
const ALIASES_PATH = path.join(__dirname, 'machine-aliases.json');
const DB_DIR      = path.join(os.homedir(), '.ideiaos', 'console');
const DB_PATH     = path.join(DB_DIR, 'read-model.db');
const SOAK_DIR    = path.join(REPO_ROOT, '.planning', 'soak');

// ---------------------------------------------------------------------------
// Carrega machine-aliases.json (dedup de host por alias curado)
// Ex: { "192": "Mac-mini-de-Gustavo" }
// ---------------------------------------------------------------------------
function loadAliases() {
  try {
    return JSON.parse(fs.readFileSync(ALIASES_PATH, 'utf8'));
  } catch (e) {
    process.stderr.write('[ingest] aliases: ' + e.message + '\n');
    return {};
  }
}

// ---------------------------------------------------------------------------
// Resolve alias de host (dedup de Machine)
// "192" -> "Mac-mini-de-Gustavo" conforme machine-aliases.json curado
// Gotcha: hostname "192" é alias do Mac-mini (substrato real v73)
// ---------------------------------------------------------------------------
function resolveAlias(host, aliases) {
  return aliases[host] || host;
}

// ---------------------------------------------------------------------------
// Classifica ator de commit deterministicamente (Task 3 — FIX-06D)
// Regra (precedência explícita, nunca ambígua):
//   1. subject começa com "wip: autosync"  -> 'autosync'
//   2. autor termina com ".local"           -> 'autosync'
//   3. autor contém "[bot]@"                -> 'bot'
//   4. senão                                -> 'human'
// ---------------------------------------------------------------------------
function classifyActor(subject, author) {
  const subj = (subject || '').toLowerCase();
  const auth = (author  || '').toLowerCase();
  if (subj.startsWith('wip: autosync')) return 'autosync';
  if (auth.endsWith('.local'))          return 'autosync';
  if (auth.includes('[bot]@'))          return 'bot';
  return 'human';
}

// ---------------------------------------------------------------------------
// Executa git no REPO_ROOT (cockpit ref vive neste repo)
// ---------------------------------------------------------------------------
function git(args, opts) {
  return execSync('git ' + args, {
    cwd:      REPO_ROOT,
    timeout:  15000,
    encoding: 'utf8',
    ...opts
  }).trim();
}

// ---------------------------------------------------------------------------
// cockpit_list_machines — lista machine_ids no ref cockpit
// Espelha cockpit.sh:cockpit_list_machines (git ls-tree --name-only cockpit snapshots/)
// ---------------------------------------------------------------------------
function cockpitListMachines() {
  try {
    const out = git('ls-tree --name-only cockpit snapshots/');
    if (!out) return [];
    return out.split('\n')
      .filter(l => l.trim().endsWith('.json'))
      .map(l => path.basename(l, '.json'));
  } catch (e) {
    process.stderr.write('[ingest] cockpit_list_machines: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// cockpit_read_snapshot — lê snapshot do object store (NUNCA arquivo no disco)
// Espelha cockpit.sh:cockpit_read_snapshot (git show cockpit:snapshots/<id>.json)
// ---------------------------------------------------------------------------
function cockpitReadSnapshot(mid) {
  // INVARIANTE: lemos do object store via "cockpit:snapshots/<mid>.json"
  // Nunca de arquivo no filesystem — a invariante A5 exige isso
  const raw = git(`show cockpit:snapshots/${mid}.json`);
  return JSON.parse(raw);
}

// ---------------------------------------------------------------------------
// parseSoakLedger — le ledgers pipe-delimited do disco
// Formato: epoch|iso|host|idea_doctor=PASS|regression=PASS|commit_hash
// Retorna array de heartbeat objects
// ---------------------------------------------------------------------------
function parseSoakLedger(aliases) {
  const heartbeats = [];
  if (!fs.existsSync(SOAK_DIR)) return heartbeats;
  const files = fs.readdirSync(SOAK_DIR).filter(f => f.endsWith('.log'));
  for (const file of files) {
    const milestone = file.replace('.log', '');
    const content = fs.readFileSync(path.join(SOAK_DIR, file), 'utf8');
    for (const line of content.split('\n')) {
      const l = line.trim();
      if (!l || l.startsWith('#')) continue;
      const parts = l.split('|');
      if (parts.length < 6) continue;
      heartbeats.push({
        milestone,
        epoch:        parseInt(parts[0], 10) || 0,
        iso:          parts[1] || '',
        host:         resolveAlias(parts[2] || '', aliases), // dedup alias
        idea_doctor:  parts[3] || '',
        regression:   parts[4] || '',
        commit_hash:  parts[5] || ''
      });
    }
  }
  return heartbeats;
}

// ---------------------------------------------------------------------------
// openDb — abre ou cria o DB, aplica schema.sql se necessário
// ---------------------------------------------------------------------------
function openDb() {
  fs.mkdirSync(DB_DIR, { recursive: true });
  const db = new DatabaseSync(DB_PATH);
  // Aplicar schema (CREATE TABLE IF NOT EXISTS — idempotente)
  const ddl = fs.readFileSync(SCHEMA_PATH, 'utf8');
  db.exec(ddl);
  return db;
}

// ---------------------------------------------------------------------------
// UPSERT helpers — INSERT ... ON CONFLICT DO UPDATE (idempotente por PK)
// Regra: NUNCA escrever campo value (api_key nao tem a coluna — DoD #1)
// ---------------------------------------------------------------------------
function upsertMachine(db, row) {
  db.prepare(`
    INSERT INTO machine (machine_id, canonical_name, os_version, agentd_version, last_seen_epoch)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(machine_id) DO UPDATE SET
      canonical_name   = excluded.canonical_name,
      os_version       = excluded.os_version,
      agentd_version   = excluded.agentd_version,
      last_seen_epoch  = excluded.last_seen_epoch
  `).run(
    row.machine_id,
    row.canonical_name  || null,
    row.os_version      || null,
    row.agentd_version  || null,
    row.last_seen_epoch || Math.floor(Date.now() / 1000)
  );
}

function upsertProject(db, row) {
  db.prepare(`
    INSERT INTO project
      (project_slug, machine_id, path, remote_url, supabase_project_id, is_test_dir, class_reason, last_seen_epoch)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(project_slug) DO UPDATE SET
      machine_id           = excluded.machine_id,
      path                 = excluded.path,
      remote_url           = excluded.remote_url,
      supabase_project_id  = excluded.supabase_project_id,
      is_test_dir          = excluded.is_test_dir,
      class_reason         = excluded.class_reason,
      last_seen_epoch      = excluded.last_seen_epoch
  `).run(
    row.project_slug,
    row.machine_id,
    row.path                 || null,
    row.remote_url           || null,
    row.supabase_project_id  || null,
    row.is_test_dir ? 1 : 0,
    row.class_reason         || null,
    row.last_seen_epoch      || Math.floor(Date.now() / 1000)
  );
}

function upsertApiKey(db, row) {
  // INVARIANTE: nenhum campo value escrito (DoD #1)
  // api_key DDL: PK (project_slug, var_name), risk_tier CHECK, SEM value
  db.prepare(`
    INSERT INTO api_key
      (project_slug, var_name, present, expected, risk_tier, file_mtime_epoch, committed)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(project_slug, var_name) DO UPDATE SET
      present          = excluded.present,
      expected         = excluded.expected,
      risk_tier        = excluded.risk_tier,
      file_mtime_epoch = excluded.file_mtime_epoch,
      committed        = excluded.committed
  `).run(
    row.project_slug,
    row.var_name,
    row.present    ? 1 : 0,
    row.expected   ? 1 : 0,
    row.risk_tier  || 'none',
    row.file_mtime_epoch || null,
    row.committed  ? 1 : 0
  );
}

function upsertMcpConnection(db, row) {
  db.prepare(`
    INSERT INTO mcp_connection (machine_id, source_file, server_name, enabled, last_seen_epoch)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(machine_id, source_file, server_name) DO UPDATE SET
      enabled         = excluded.enabled,
      last_seen_epoch = excluded.last_seen_epoch
  `).run(
    row.machine_id,
    row.source_file,
    row.server_name,
    row.enabled !== false ? 1 : 0,
    row.last_seen_epoch || Math.floor(Date.now() / 1000)
  );
}

function upsertDaemonStatus(db, row) {
  db.prepare(`
    INSERT INTO daemon_status (machine_id, label, pid, status_code, last_seen_epoch)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(machine_id, label) DO UPDATE SET
      pid             = excluded.pid,
      status_code     = excluded.status_code,
      last_seen_epoch = excluded.last_seen_epoch
  `).run(
    row.machine_id,
    row.label,
    row.pid         || null,
    row.status_code || null,
    row.last_seen_epoch || Math.floor(Date.now() / 1000)
  );
}

function upsertMachineSnapshot(db, row) {
  db.prepare(`
    INSERT INTO machine_snapshot (machine_id, taken_epoch, agentd_version, payload_json)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(machine_id, taken_epoch) DO UPDATE SET
      agentd_version = excluded.agentd_version,
      payload_json   = excluded.payload_json
  `).run(
    row.machine_id,
    row.taken_epoch,
    row.agentd_version || null,
    row.payload_json
  );
}

function upsertSoakHeartbeat(db, row) {
  db.prepare(`
    INSERT INTO soak_heartbeat
      (milestone, epoch, iso, host, idea_doctor, regression, commit_hash)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(milestone, epoch, host) DO UPDATE SET
      iso          = excluded.iso,
      idea_doctor  = excluded.idea_doctor,
      regression   = excluded.regression,
      commit_hash  = excluded.commit_hash
  `).run(
    row.milestone,
    row.epoch,
    row.iso,
    row.host,
    row.idea_doctor  || '',
    row.regression   || '',
    row.commit_hash  || ''
  );
}

// ---------------------------------------------------------------------------
// enrichSnapshotWithActorClass — classifica ator nos commits do snapshot
// Como commit_log é v14.2+, materializa actor_class em payload_json -> $.commits[]
// Task 3 / FIX-06D: gate valida via json_extract contra machine_snapshot.payload_json
// ---------------------------------------------------------------------------
function enrichSnapshotWithActorClass(snapshot) {
  // Clonar para não mutar o original
  const enriched = JSON.parse(JSON.stringify(snapshot));
  if (!enriched.commits) enriched.commits = [];
  enriched.commits = enriched.commits.map(c => ({
    ...c,
    actor_class: classifyActor(c.subject || '', c.author || '')
  }));
  return enriched;
}

// ---------------------------------------------------------------------------
// ingestSnapshot — processa um snapshot completo da máquina no DB
// ---------------------------------------------------------------------------
function ingestSnapshot(db, snapshot, aliases) {
  const mid = snapshot.machine_id;
  const canonicalName = resolveAlias(mid, aliases);
  const takenEpoch = snapshot.taken_epoch || Math.floor(Date.now() / 1000);

  // 1) Machine
  upsertMachine(db, {
    machine_id:     mid,
    canonical_name: canonicalName,
    os_version:     snapshot.os_version     || null,
    agentd_version: snapshot.agentd_version || null,
    last_seen_epoch: takenEpoch
  });

  // 2) Daemons
  for (const d of (snapshot.daemons || [])) {
    upsertDaemonStatus(db, {
      machine_id:     mid,
      label:          d.label       || '',
      pid:            d.pid         || null,
      status_code:    d.status      || null,
      last_seen_epoch: takenEpoch
    });
  }

  // 3) MCP connections (se presentes no snapshot)
  for (const m of (snapshot.mcp_connections || [])) {
    upsertMcpConnection(db, {
      machine_id:   mid,
      source_file:  m.source_file || m.source || 'unknown',
      server_name:  m.name        || m.server_name || '',
      enabled:      m.enabled !== false,
      last_seen_epoch: takenEpoch
    });
  }

  // 4) Projects + api_keys (project_slug = slug do projeto)
  for (const proj of (snapshot.projects || [])) {
    const slug = proj.slug || proj.project_slug || '';
    if (!slug) continue;

    upsertProject(db, {
      project_slug:       slug,
      machine_id:         mid,
      path:               proj.path || null,
      remote_url:         proj.remote || proj.remote_url || null,
      supabase_project_id: proj.supabase_project_id || null,
      is_test_dir:        proj.is_test_dir || false,
      class_reason:       proj.class_reason || null,
      last_seen_epoch:    takenEpoch
    });

    // api_keys: NUNCA escrever value (DoD #1)
    for (const k of (proj.api_keys || [])) {
      upsertApiKey(db, {
        project_slug:     slug,
        var_name:         k.var_name     || '',
        present:          k.present      || false,
        expected:         k.expected     || false,
        risk_tier:        k.risk_tier    || 'none',
        file_mtime_epoch: k.mtime_epoch  || null,
        committed:        k.committed    || false
        // INVARIANTE: sem campo value — DoD #1
      });
    }
  }

  // 5) Machine snapshot (payload completo com actor_class materializado)
  const enriched = enrichSnapshotWithActorClass(snapshot);
  upsertMachineSnapshot(db, {
    machine_id:     mid,
    taken_epoch:    takenEpoch,
    agentd_version: snapshot.agentd_version || null,
    payload_json:   JSON.stringify(enriched)  // sem value (DoD #1)
  });
}

// ---------------------------------------------------------------------------
// main — ponto de entrada do ingest
// ---------------------------------------------------------------------------
function main() {
  const aliases = loadAliases();
  const db = openDb();
  const now = Math.floor(Date.now() / 1000);

  // Ler todos os machine_ids do ref cockpit via object store
  const machines = cockpitListMachines();
  process.stdout.write('[ingest] machines no ref cockpit: ' + machines.join(', ') + '\n');

  for (const mid of machines) {
    try {
      // INVARIANTE: lemos de "cockpit:snapshots/<mid>.json" (object store)
      const snapshot = cockpitReadSnapshot(mid);
      ingestSnapshot(db, snapshot, aliases);
      process.stdout.write('[ingest] ok: ' + mid + '\n');
    } catch (e) {
      process.stderr.write('[ingest] erro snapshot ' + mid + ': ' + e.message + '\n');
    }
  }

  // Ingerir soak heartbeats do disco (SOMENTE soak — security_seal é v14.2+)
  const heartbeats = parseSoakLedger(aliases);
  process.stdout.write('[ingest] soak heartbeats: ' + heartbeats.length + '\n');
  for (const hb of heartbeats) {
    upsertSoakHeartbeat(db, hb);
  }

  // Resumo
  const machineCount = db.prepare('SELECT COUNT(*) AS n FROM machine').get().n;
  const projectCount = db.prepare('SELECT COUNT(*) AS n FROM project').get().n;
  const apiKeyCount  = db.prepare('SELECT COUNT(*) AS n FROM api_key').get().n;
  const soakCount    = db.prepare('SELECT COUNT(*) AS n FROM soak_heartbeat').get().n;

  process.stdout.write(
    '[ingest] done — machines:' + machineCount +
    ' projects:' + projectCount +
    ' api_keys:' + apiKeyCount +
    ' soak_heartbeats:' + soakCount +
    ' db:' + DB_PATH + '\n'
  );

  db.close();
}

main();
