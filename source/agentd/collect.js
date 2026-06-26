// SOURCE: IdeiaOS v14 | kind: agentd | targets: claude,cursor
// =============================================================================
// collect.js — Leitores read-only por fonte (zero valor de segredo)
//              Cada leitura é fail-silent: erro -> stderr + retorna default seguro.
//              NENHUM objeto retornado pode ter campo "value".
//              machine_id = sha256(IOPlatformUUID)[:12] — NUNCA hostname.
// =============================================================================
'use strict';

const { execSync, spawnSync } = require('child_process');
const fs   = require('fs');
const path = require('path');
const os   = require('os');
const crypto = require('crypto');

// ---------------------------------------------------------------------------
// machine_id — derivado 1x via sha256(IOPlatformUUID)[:12], cacheado
// NUNCA hostname (gotcha alias 192 <-> MacBook-Air-2, gotcha v73)
// ---------------------------------------------------------------------------
let _machineId = null;
function getMachineId() {
  if (_machineId) return _machineId;
  try {
    const uuid = execSync(
      "ioreg -rd1 -c IOPlatformExpertDevice | awk -F'\"' '/IOPlatformUUID/{print $4}'",
      { timeout: 5000, encoding: 'utf8' }
    ).trim();
    if (!uuid) throw new Error('IOPlatformUUID vazio');
    _machineId = crypto.createHash('sha256').update(uuid).digest('hex').slice(0, 12);
  } catch (e) {
    process.stderr.write('[collect] machine_id fallback: ' + e.message + '\n');
    // Fallback seguro: hash fixo de 'unknown' para nunca expor hostname bruto
    // (gotcha alias 192 <-> MacBook-Air-2 — hostname é ambíguo, nunca usar como id)
    _machineId = crypto.createHash('sha256').update('unknown-iopuuid').digest('hex').slice(0, 12);
  }
  return _machineId;
}

// ---------------------------------------------------------------------------
// Utilidade: exec silencioso — nunca lança; retorna string ou null
// ---------------------------------------------------------------------------
function safeExec(cmd, opts) {
  try {
    return execSync(cmd, { timeout: 10000, encoding: 'utf8', ...opts }).trim();
  } catch (e) {
    process.stderr.write('[collect] safeExec warn: ' + cmd.slice(0, 60) + ' — ' + e.message + '\n');
    return null;
  }
}

// ---------------------------------------------------------------------------
// readSoakHeartbeats — parse pipe-delimited de .planning/soak/*.log
// Formato: epoch|iso|host|idea_doctor=PASS|regression=PASS|commit_hash
// Retorna array de objetos SEM value (apenas metadados)
// ---------------------------------------------------------------------------
function readSoakHeartbeats() {
  try {
    const soakDir = path.join(process.cwd(), '.planning', 'soak');
    if (!fs.existsSync(soakDir)) return [];
    const files = fs.readdirSync(soakDir).filter(f => f.endsWith('.log'));
    const heartbeats = [];
    for (const file of files) {
      const milestone = file.replace('.log', '');
      const lines = fs.readFileSync(path.join(soakDir, file), 'utf8').split('\n');
      for (const line of lines) {
        if (!line.trim() || line.startsWith('#')) continue;
        const parts = line.split('|');
        if (parts.length < 6) continue;
        heartbeats.push({
          milestone,
          epoch: parseInt(parts[0], 10) || 0,
          iso:   parts[1] || '',
          host:  parts[2] || '',
          idea_doctor:  parts[3] || '',
          regression:   parts[4] || '',
          commit_hash:  parts[5] || ''
        });
      }
    }
    return heartbeats;
  } catch (e) {
    process.stderr.write('[collect] readSoakHeartbeats: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// readDaemons — launchctl list | grep ideiaos
// Retorna array de { label, pid, status }
// ---------------------------------------------------------------------------
function readDaemons() {
  try {
    const raw = safeExec('launchctl list 2>/dev/null | grep ideiaos || true');
    if (!raw) return [];
    return raw.split('\n')
      .filter(l => l.trim())
      .map(line => {
        const parts = line.trim().split(/\s+/);
        return {
          pid:    parts[0] !== '-' ? parseInt(parts[0], 10) || null : null,
          status: parts[1] || '0',
          label:  parts[2] || ''
        };
      });
  } catch (e) {
    process.stderr.write('[collect] readDaemons: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// readDoctor — consome `idea-doctor --json` -> summary + sections
// Retorna { ok, warn, fail, exit, sections[] } sem nenhum valor de segredo
// ---------------------------------------------------------------------------
function readDoctor() {
  try {
    const raw = safeExec('bash scripts/idea-doctor.sh --json 2>/dev/null');
    if (!raw) return { ok: 0, warn: 0, fail: 0, exit: -1, sections: [] };
    const d = JSON.parse(raw);
    // Extrair apenas summary (metadata, sem value)
    const summary = d.summary || { ok: 0, warn: 0, fail: 0, exit: -1 };
    const sections = (d.sections || []).map(s => ({
      id:     s.id     || '',
      titulo: s.titulo || '',
      status: s.status || '',
      counts: s.counts || { ok: 0, warn: 0, fail: 0 }
    }));
    return { ...summary, sections };
  } catch (e) {
    process.stderr.write('[collect] readDoctor: ' + e.message + '\n');
    return { ok: 0, warn: 0, fail: 0, exit: -1, sections: [] };
  }
}

// ---------------------------------------------------------------------------
// readCommits — git log --oneline -5 por repo de cada produto descoberto
// Retorna array de { repo, commits: [{ hash, subject }] } sem value
// ---------------------------------------------------------------------------
function readCommits(repoPath) {
  try {
    const raw = safeExec(`git -C "${repoPath}" log --oneline -5 2>/dev/null`);
    if (!raw) return [];
    return raw.split('\n').filter(l => l.trim()).map(line => {
      const sp = line.indexOf(' ');
      return {
        hash:    line.slice(0, sp).trim(),
        subject: line.slice(sp + 1).trim()
      };
    });
  } catch (e) {
    process.stderr.write('[collect] readCommits: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// readEnvKeys — le SO os nomes: equivalente de grep '^[A-Z_]*=' | sed 's/=.*//'
// RHS de = DESCARTADO. NENHUM objeto pode ter campo "value".
// ---------------------------------------------------------------------------
function readEnvKeys(envFilePath) {
  try {
    if (!fs.existsSync(envFilePath)) return [];
    const lines = fs.readFileSync(envFilePath, 'utf8').split('\n');
    const keys = [];
    for (const line of lines) {
      const trimmed = line.trim();
      // Ignorar comentários e linhas sem sinal de igual
      if (trimmed.startsWith('#') || !trimmed.includes('=')) continue;
      // Extrair apenas o nome (antes do =), equivalente de sed 's/=.*//'
      const match = trimmed.match(/^([A-Z_][A-Z0-9_]*)=/);
      if (!match) continue;
      const varName = match[1];
      // Metadata sobre a chave: presença e mtime — SEM o valor (RHS descartado)
      const mtime = (() => {
        try { return Math.floor(fs.statSync(envFilePath).mtimeMs / 1000); }
        catch { return null; }
      })();
      keys.push({ var_name: varName, present: true, mtime_epoch: mtime });
      // INVARIANTE: nenhum campo "value" — o push acima confirma
    }
    return keys;
  } catch (e) {
    process.stderr.write('[collect] readEnvKeys: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// readMcp — nomes dos MCP servers de ~/.claude.json e ~/.cursor/mcp.json
// Retorna array de { source, name } sem value (nenhuma chave de API)
// ---------------------------------------------------------------------------
function readMcp() {
  const results = [];
  const sources = [
    { file: path.join(os.homedir(), '.claude.json'), key: 'mcpServers' },
    { file: path.join(os.homedir(), '.cursor', 'mcp.json'), key: 'mcpServers' }
  ];
  for (const { file, key } of sources) {
    try {
      if (!fs.existsSync(file)) continue;
      const d = JSON.parse(fs.readFileSync(file, 'utf8'));
      const servers = d[key] || {};
      for (const name of Object.keys(servers)) {
        results.push({ source: path.basename(file), name });
      }
    } catch (e) {
      process.stderr.write('[collect] readMcp ' + file + ': ' + e.message + '\n');
    }
  }
  return results;
}

// ---------------------------------------------------------------------------
// readAccounts — gh auth status (metadata: logged_in, user, protocol)
// Retorna array de { host, user, protocol, active } sem tokens/values
// ---------------------------------------------------------------------------
function readAccounts() {
  try {
    const raw = safeExec('gh auth status 2>&1 || true');
    if (!raw) return [];
    const accounts = [];
    let current = null;
    for (const line of raw.split('\n')) {
      const hostMatch = line.match(/^(\S+)$/);
      if (hostMatch && !line.includes(' ')) { current = { host: line.trim(), user: '', protocol: '', active: false }; accounts.push(current); continue; }
      if (!current) continue;
      const userM  = line.match(/Logged in to .* account (\S+)/);
      const protoM = line.match(/Git operations protocol: (\S+)/);
      const activeM = line.match(/Active account: (true|false)/);
      if (userM)  current.user     = userM[1];
      if (protoM) current.protocol = protoM[1];
      if (activeM) current.active  = activeM[1] === 'true';
    }
    return accounts;
  } catch (e) {
    process.stderr.write('[collect] readAccounts: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// readSupabase — extrai project_id de supabase/config.toml (sem secrets)
// Retorna { project_id } ou null
// ---------------------------------------------------------------------------
function readSupabase(repoPath) {
  try {
    const configPath = path.join(repoPath, 'supabase', 'config.toml');
    if (!fs.existsSync(configPath)) return null;
    const content = fs.readFileSync(configPath, 'utf8');
    const m = content.match(/project_id\s*=\s*"([^"]+)"/);
    return m ? { project_id: m[1] } : null;
  } catch (e) {
    process.stderr.write('[collect] readSupabase: ' + e.message + '\n');
    return null;
  }
}

// ---------------------------------------------------------------------------
// readVersions — lê versions.lock como string-equality (nunca semver)
// Retorna objeto { [key]: version_string } sem value
// ---------------------------------------------------------------------------
function readVersions() {
  try {
    // R15-12: ancorado em __dirname (collect.js vive em <repo>/source/agentd/), NÃO
    // process.cwd() — sob launchd o cwd NÃO é o repo (plist do cockpit sem
    // WorkingDirectory), então versions.lock não era achado e installed_versions
    // ficava {} silenciosamente. Anti-padrão: depender de cwd num daemon.
    const lockPath = path.join(__dirname, '..', '..', 'versions.lock');
    if (!fs.existsSync(lockPath)) return {};
    const lines = fs.readFileSync(lockPath, 'utf8').split('\n');
    const versions = {};
    for (const line of lines) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;
      const eqIdx = trimmed.indexOf('=');
      if (eqIdx < 0) continue;
      const k = trimmed.slice(0, eqIdx).trim();
      const v = trimmed.slice(eqIdx + 1).trim();
      // String-equality: nunca parsear como semver (version-reset-migration-semver-trap)
      versions[k] = v;
    }
    return versions;
  } catch (e) {
    process.stderr.write('[collect] readVersions: ' + e.message + '\n');
    return {};
  }
}

// ---------------------------------------------------------------------------
// classifyRepo — heurística determinista: produto vs test-dir
// produto = remote origin + (em git-autosync-repos.txt OU tem .env.example/supabase/package.json)
// test-dir = sem remote OR nome casando ^(test|tmp|sandbox|fixture|ollama|ideia-chat)
// ---------------------------------------------------------------------------
function classifyRepo(dirPath) {
  const name = path.basename(dirPath);
  // Se o nome casa padrão de test-dir
  if (/^(test|tmp|sandbox|fixture|ollama|ideia-chat|teste)/i.test(name)) {
    return { is_test_dir: true, reason: 'name-pattern' };
  }
  // Verificar se tem remote origin
  const remote = safeExec(`git -C "${dirPath}" remote get-url origin 2>/dev/null || true`);
  if (!remote) return { is_test_dir: true, reason: 'no-remote' };

  // Verificar marcadores de produto real
  const hasEnvExample = fs.existsSync(path.join(dirPath, '.env.example'));
  const hasSupabase   = fs.existsSync(path.join(dirPath, 'supabase'));
  const hasPkgJson    = fs.existsSync(path.join(dirPath, 'package.json'));
  const hasDocsSrc    = fs.existsSync(path.join(dirPath, 'src')) || fs.existsSync(path.join(dirPath, 'docs'));

  // Verificar autosync-repos.txt
  let inAutoSync = false;
  try {
    const autosyncPath = path.join(os.homedir(), '.local', 'share', 'ideiaos', 'git-autosync-repos.txt');
    if (fs.existsSync(autosyncPath)) {
      const content = fs.readFileSync(autosyncPath, 'utf8');
      inAutoSync = content.includes(dirPath) || content.includes(name);
    }
  } catch {}

  const isProduct = hasEnvExample || hasSupabase || hasPkgJson || hasDocsSrc || inAutoSync;
  return { is_test_dir: !isProduct, reason: isProduct ? 'has-product-markers' : 'no-product-markers' };
}

// ---------------------------------------------------------------------------
// discoverProducts — iteração dinâmica ~/dev/*/.git
// Nunca assume N=5 (substrato real = 7 produtos, Jarvis 469 sessões)
// ---------------------------------------------------------------------------
function discoverProducts() {
  try {
    const devDir = path.join(os.homedir(), 'dev');
    if (!fs.existsSync(devDir)) return [];
    const dirs = fs.readdirSync(devDir);
    const products = [];
    for (const d of dirs) {
      const full = path.join(devDir, d);
      const gitDir = path.join(full, '.git');
      try {
        if (!fs.statSync(full).isDirectory()) continue;
        if (!fs.existsSync(gitDir)) continue;
      } catch { continue; }

      const classification = classifyRepo(full);
      const supabase = readSupabase(full);

      // api_keys: ler .env e .env.example SEM os valores (apenas nomes)
      const apiKeys = [];
      for (const envFile of ['.env', '.env.example', '.env.local']) {
        const envPath = path.join(full, envFile);
        if (fs.existsSync(envPath)) {
          const keys = readEnvKeys(envPath);
          for (const k of keys) {
            // Dedup por var_name
            if (!apiKeys.find(x => x.var_name === k.var_name)) {
              // Classificação de risk_tier por nome (heurística)
              let risk_tier = 'none';
              const vn = k.var_name.toLowerCase();
              if (vn.includes('service_role') || vn.includes('secret') || vn.includes('private')) {
                risk_tier = 'critical';
              } else if (vn.includes('anon') || vn.includes('key') || vn.includes('token') || vn.includes('api')) {
                risk_tier = 'sensitive';
              } else if (vn.includes('url') || vn.includes('id') || vn.includes('project')) {
                risk_tier = 'low';
              }
              apiKeys.push({
                var_name:    k.var_name,
                present:     k.present,
                expected:    true,  // toda chave listada no .env.example é esperada
                risk_tier,
                mtime_epoch: k.mtime_epoch
                // INVARIANTE: sem campo "value" — RHS de = foi descartado em readEnvKeys
              });
            }
          }
        }
      }

      products.push({
        slug:        d,
        path:        full,
        is_test_dir: classification.is_test_dir,
        class_reason: classification.reason,
        remote:      safeExec(`git -C "${full}" remote get-url origin 2>/dev/null || true`) || null,
        supabase_project_id: supabase ? supabase.project_id : null,
        api_keys:    apiKeys
      });
    }
    return products;
  } catch (e) {
    process.stderr.write('[collect] discoverProducts: ' + e.message + '\n');
    return [];
  }
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------
module.exports = {
  getMachineId,
  readSoakHeartbeats,
  readDaemons,
  readDoctor,
  readCommits,
  readEnvKeys,
  readMcp,
  readAccounts,
  readSupabase,
  readVersions,
  discoverProducts
};

// ---------------------------------------------------------------------------
// CLI: node collect.js --discover (tarefa 3.2: JSON válido com IdeiaOS)
// ---------------------------------------------------------------------------
if (require.main === module) {
  const arg = process.argv[2] || '';
  if (arg === '--discover') {
    const products = discoverProducts();
    process.stdout.write(JSON.stringify(products, null, 2) + '\n');
    process.exit(0);
  }
  // Sem args: imprime machine_id para verificação
  process.stdout.write(JSON.stringify({ machine_id: getMachineId() }) + '\n');
  process.exit(0);
}
