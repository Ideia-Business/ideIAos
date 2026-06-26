#!/usr/bin/env node
// SOURCE: IdeiaOS v14 | kind: agentd | targets: claude,cursor
// =============================================================================
// agentd.js — Entry do ideiaos-agentd: coleta read-only, monta snapshot v1
//             e grava em refs/heads/cockpit via cockpit_write_snapshot (plan 02).
//
// Uso:
//   node source/agentd/agentd.js --once     # uma coleta (daemon ou manual)
//
// Fail-silent (hook-contract de daemon): qualquer erro -> stderr + process.exit(0)
// NENHUM campo "value" em nenhum lugar do snapshot.
// A4: git status --porcelain vazio após gravar (plumbing puro, não toca working tree).
// =============================================================================
'use strict';

const { execSync } = require('child_process');
const path         = require('path');
const os           = require('os');
const fs           = require('fs');

const AGENTD_VERSION = '1.0.0';

// Resolver o root do IdeiaOS a partir do caminho deste arquivo
const IDEIAOS_ROOT = path.resolve(__dirname, '..', '..');

// ---------------------------------------------------------------------------
// Utilitário: exec silencioso
// ---------------------------------------------------------------------------
function safeExec(cmd, opts) {
  try {
    return execSync(cmd, { timeout: 15000, encoding: 'utf8', cwd: IDEIAOS_ROOT, ...opts }).trim();
  } catch (e) {
    process.stderr.write('[agentd] safeExec warn: ' + cmd.slice(0, 80) + ' — ' + e.message + '\n');
    return null;
  }
}

// ---------------------------------------------------------------------------
// collectSnapshot — monta o objeto SHAPE ideiaos-cockpit-snapshot/v1
// ---------------------------------------------------------------------------
async function collectSnapshot() {
  // Importar collect.js (fail-silent: qualquer erro retorna valores padrão)
  let collect;
  try {
    collect = require('./collect');
  } catch (e) {
    process.stderr.write('[agentd] collect.js ausente ou com erro: ' + e.message + '\n');
    // Fail-silent: retornar snapshot mínimo mas válido
    return buildMinimalSnapshot();
  }

  // machine_id = sha256(IOPlatformUUID)[:12] — NUNCA hostname
  let machine_id;
  try { machine_id = collect.getMachineId(); }
  catch (e) { process.stderr.write('[agentd] machine_id: ' + e.message + '\n'); machine_id = 'unknown000000'; }

  // os_version
  let os_version;
  try {
    os_version = (safeExec('sw_vers -productVersion') || os.release()).trim();
  } catch { os_version = os.release(); }

  // daemons[]
  let daemons = [];
  try { daemons = collect.readDaemons(); } catch (e) { process.stderr.write('[agentd] daemons: ' + e.message + '\n'); }

  // doctor{}
  let doctor = { ok: 0, warn: 0, fail: 0, exit: -1, sections: [] };
  try { doctor = collect.readDoctor(); } catch (e) { process.stderr.write('[agentd] doctor: ' + e.message + '\n'); }

  // installed_versions{}
  let installed_versions = {};
  try { installed_versions = collect.readVersions(); } catch (e) { process.stderr.write('[agentd] versions: ' + e.message + '\n'); }

  // mcp_connections[] — R15-12: readMcp() existe e o ingest já consome
  // snapshot.mcp_connections (tabela mcp_connection), mas collectSnapshot nunca
  // a chamava → pilar Sinapse vazio. Credential-safe ({source,name}, sem value).
  let mcp_connections = [];
  try { mcp_connections = collect.readMcp(); } catch (e) { process.stderr.write('[agentd] mcp: ' + e.message + '\n'); }

  // accounts[]
  let accounts = [];
  try { accounts = collect.readAccounts(); } catch (e) { process.stderr.write('[agentd] accounts: ' + e.message + '\n'); }

  // projects[] — descoberta dinâmica, NUNCA N=5 hardcoded
  let projects = [];
  try {
    const allProducts = collect.discoverProducts();
    // Filtrar para produtos não-test (mas incluir todos para visibilidade total)
    projects = allProducts.map(p => ({
      slug:                p.slug,
      path:                p.path,
      is_test_dir:         p.is_test_dir,
      remote:              p.remote || null,
      supabase_project_id: p.supabase_project_id || null,
      // api_keys SEM campo "value" — credential-isolation estrutural
      api_keys: (p.api_keys || []).map(k => ({
        var_name:    k.var_name,
        present:     k.present    !== undefined ? k.present    : false,
        expected:    k.expected   !== undefined ? k.expected   : true,
        risk_tier:   k.risk_tier  || 'none',
        mtime_epoch: k.mtime_epoch || null
        // INVARIANTE: sem campo "value" — RHS de = descartado em collect.readEnvKeys
      }))
    }));
  } catch (e) {
    process.stderr.write('[agentd] projects: ' + e.message + '\n');
  }

  // Snapshot SHAPE ideiaos-cockpit-snapshot/v1 (doc 72 §3)
  return {
    schema:             'ideiaos-cockpit-snapshot/v1',
    machine_id,
    agentd_version:     AGENTD_VERSION,
    os_version,
    taken_epoch:        Math.floor(Date.now() / 1000),
    daemons,
    doctor,
    installed_versions,
    mcp_connections,
    accounts,
    projects
    // INVARIANTE: sem campo "value" em nenhum ponto do snapshot
  };
}

// Snapshot mínimo para falha catastrófica de collect.js
function buildMinimalSnapshot() {
  return {
    schema:             'ideiaos-cockpit-snapshot/v1',
    machine_id:         'unknown000000',
    agentd_version:     AGENTD_VERSION,
    os_version:         os.release(),
    taken_epoch:        Math.floor(Date.now() / 1000),
    daemons:            [],
    doctor:             { ok: 0, warn: 0, fail: 0, exit: -1, sections: [] },
    installed_versions: {},
    mcp_connections:    [],
    accounts:           [],
    projects:           []
  };
}

// ---------------------------------------------------------------------------
// writeSnapshot — serializa e grava via cockpit_write_snapshot (cockpit.sh plan 02)
// Invoca como: bash -c '. source/lib/cockpit.sh; cockpit_write_snapshot <MID> "$JSON"'
// ---------------------------------------------------------------------------
function writeSnapshot(snapshot) {
  const machine_id  = snapshot.machine_id;
  const jsonContent = JSON.stringify(snapshot, null, 2);

  // Gravar JSON em arquivo temporário e invocar cockpit_write_snapshot via bash
  // (cockpit_write_snapshot aceita MID + JSON_STRING conforme cockpit.sh plan 02)
  const cockpitSh  = path.join(IDEIAOS_ROOT, 'source', 'lib', 'cockpit.sh');
  const tmpFile    = '/tmp/ideiaos-agentd-snap-' + machine_id + '.json';

  // Escrever snap em /tmp para não tocar working tree (A4)
  fs.writeFileSync(tmpFile, jsonContent, 'utf8');

  // Invocar cockpit_write_snapshot via bash — a função aceita MID + JSON_STRING
  // Passamos o JSON como string via variável de ambiente para evitar quoting hell
  const cmd = `bash -c '. "${cockpitSh}"; cockpit_write_snapshot "${machine_id}" "$(cat ${tmpFile})"'`;

  try {
    execSync(cmd, {
      cwd:      IDEIAOS_ROOT,
      timeout:  30000,
      encoding: 'utf8',
      stdio:    ['ignore', 'pipe', 'pipe']
    });
  } finally {
    // Limpar arquivo /tmp (não é parte do working tree — A4 não afetada)
    try { fs.unlinkSync(tmpFile); } catch {}
  }

  return machine_id;
}

// ---------------------------------------------------------------------------
// main — entry --once (coleta única, fail-silent)
// ---------------------------------------------------------------------------
async function main() {
  const arg = process.argv[2] || '';
  if (arg !== '--once') {
    process.stderr.write('[agentd] uso: node agentd.js --once\n');
    // Fail-silent mesmo em uso incorreto
    process.exit(0);
  }

  try {
    const snapshot   = await collectSnapshot();
    const machine_id = writeSnapshot(snapshot);
    process.stdout.write('[agentd] snapshot gravado: cockpit:snapshots/' + machine_id + '.json\n');
    // Re-ingest do read-model no MESMO ciclo: coletar→snapshot→ingest. Sem isto o
    // read-model (~/.ideiaos/console/read-model.db) só atualizava por ingest manual e
    // defasava (cache descartável A5, mas o console mostraria dado velho — foi o que
    // deixou o idea-doctor §15 em WARN por ~2.8 dias). Isolado e fail-silent: erro de
    // ingest nunca derruba o snapshot já gravado. Usa process.execPath (mesmo node).
    try {
      const ingestJs = path.join(IDEIAOS_ROOT, 'source', 'console', 'ingest.js');
      execSync(`"${process.execPath}" "${ingestJs}"`, { cwd: IDEIAOS_ROOT, timeout: 30000, stdio: 'ignore' });
      process.stdout.write('[agentd] read-model re-ingerido\n');
    } catch (e2) {
      process.stderr.write('[agentd] ingest falhou (fail-silent): ' + e2.message + '\n');
    }
  } catch (e) {
    // Fail-silent: daemon nunca derruba nada (hook-contract)
    process.stderr.write('[agentd] ERRO (fail-silent): ' + e.message + '\n');
    process.exit(0);
  }
  process.exit(0);
}

main();
