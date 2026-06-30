#!/usr/bin/env node
'use strict';
// SOURCE: IdeiaOS v16 / Frente B | kind: p3-gate-rls | targets: claude,cursor
// =============================================================================
// gate-rls.mjs — gate de RLS do Plano de View (P3) por EXIT-CODE contra o backend
//   REAL. Cobre G1 (teste NEGATIVO), G2 (admin completo), G3 (admin-only),
//   G5 (tabelas-base não expostas), G7 (anon vazio). Sem dependências (fetch nativo).
//
// CREDENTIAL-ISOLATION: lê as chaves do ENV por NOME — nunca hardcoded, nunca
//   logadas. Carregue o .env antes de rodar:
//       set -a; . ~/.ideiaos/p3.env; set +a
//
// Variáveis esperadas (restritas ao P3 — nunca um PAT cross-projeto):
//   P3_URL          ex. https://ysttvskswqsvtdftjhfn.supabase.co
//   P3_ANON_KEY     a "Publishable key" (sb_publishable_…) — equivale à anon
//   P3_SERVICE_ROLE a "Secret key"      (sb_secret_…)      — equivale à service_role
//   P3_GATE_PW      (opcional) senha dos usuários de teste @gate.invalid descartáveis
//
// Fluxo:
//   node gate-rls.mjs --create-users   # 1) cria admin+dev de teste (via Auth API)
//   (cole gate-seed.sql no SQL Editor)  # 2) popula data.* + app_user (resolve por email)
//   node gate-rls.mjs --test            # 3) roda os checks → exit 0 (PASS) / 1 (FAIL)
//   node gate-rls.mjs --delete-users    # 4) limpeza (opcional)
// =============================================================================

const URL  = (process.env.P3_URL || '').replace(/\/+$/, '');
const ANON = process.env.P3_ANON_KEY || '';
const SVC  = process.env.P3_SERVICE_ROLE || '';
const PW   = process.env.P3_GATE_PW || 'zzGate-Test-2026-disposable-xQ7';

const ADMIN = 'p3-gate-admin@gate.invalid';
const DEV   = 'p3-gate-dev@gate.invalid';

function need(name, v) {
  if (!v) { console.error(`[gate] FALTA env ${name} — rode: set -a; . ~/.ideiaos/p3.env; set +a`); process.exit(2); }
}
need('P3_URL', URL); need('P3_ANON_KEY', ANON); need('P3_SERVICE_ROLE', SVC);

async function authReq(path, method = 'POST', body) {
  return fetch(`${URL}/auth/v1/${path}`, {
    method,
    headers: { apikey: SVC, Authorization: `Bearer ${SVC}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
}
async function login(email) {
  const r = await fetch(`${URL}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: { apikey: ANON, 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: PW }),
  });
  if (!r.ok) { console.error(`[gate] login falhou p/ ${email}: HTTP ${r.status} (rodou --create-users + o seed?)`); process.exit(3); }
  return (await r.json()).access_token;
}
async function rest(pathAndQuery, jwt, extraHeaders = {}) {
  const headers = { apikey: ANON, ...extraHeaders };
  if (jwt) headers.Authorization = `Bearer ${jwt}`;
  return fetch(`${URL}/rest/v1/${pathAndQuery}`, { headers });
}
async function jsonOrEmpty(resp) { try { return await resp.json(); } catch { return null; } }

async function createUsers() {
  for (const email of [ADMIN, DEV]) {
    const r = await authReq('admin/users', 'POST', { email, password: PW, email_confirm: true });
    if (r.ok) console.log(`[gate] criado: ${email}`);
    else if (r.status === 422 || r.status === 409) console.log(`[gate] já existe: ${email}`);
    else { console.error(`[gate] erro criando ${email}: HTTP ${r.status}`); process.exit(3); }
  }
  console.log('[gate] usuários prontos. Agora rode gate-seed.sql no SQL Editor e depois: node gate-rls.mjs --test');
}

async function deleteUsers() {
  const r = await authReq('admin/users?per_page=200', 'GET');
  const j = await jsonOrEmpty(r);
  const users = ((j && (j.users || j)) || []).filter(u => [ADMIN, DEV].includes(u.email));
  for (const u of users) { await authReq(`admin/users/${u.id}`, 'DELETE'); console.log(`[gate] deletado: ${u.email}`); }
  if (!users.length) console.log('[gate] nenhum usuário de teste para remover');
}

let fails = 0;
function check(name, cond, detail = '') {
  if (cond) console.log(`  ✅ ${name}`);
  else { console.log(`  ❌ ${name}${detail ? '  — ' + detail : ''}`); fails++; }
}
const isGate = (x) => typeof x?.project_slug === 'string' && x.project_slug.startsWith('zzgate-');

async function test() {
  const jwtAdmin = await login(ADMIN);
  const jwtDev   = await login(DEV);

  // ── G2 — admin vê tudo ──
  console.log('G2 — admin: visão completa');
  const adminKeys = (await jsonOrEmpty(await rest('api_key_v?select=*', jwtAdmin))) || [];
  const ga = Array.isArray(adminKeys) ? adminKeys.filter(isGate) : [];
  const outCritAdmin = ga.find(x => x.var_name === 'OUT_CRITICAL_KEY');
  check('admin vê OUT_CRITICAL_KEY (projeto fora do escopo do dev)', !!outCritAdmin);
  check('admin vê a postura completa (committed=true)', outCritAdmin?.committed === true);
  check('admin enxerga as 4 chaves de teste', ga.length === 4, `len=${ga.length}`);

  // ── G1 — teste NEGATIVO (dev fora do escopo) ──
  console.log('G1 — dev: teste NEGATIVO (o cenário spec L445/446)');
  const devKeys = (await jsonOrEmpty(await rest('api_key_v?select=*', jwtDev))) || [];
  const gd = Array.isArray(devKeys) ? devKeys.filter(isGate) : [];
  check('dev NÃO vê o NOME da chave critical fora do escopo', !gd.some(x => x.var_name === 'OUT_CRITICAL_KEY'));
  check('dev NÃO vê NENHUMA linha critical fora do escopo (omitida)',
        !gd.some(x => x.project_slug === 'zzgate-proj-out' && x.risk_tier === 'critical'));
  const outRows = gd.filter(x => x.project_slug === 'zzgate-proj-out');
  check('dev: postura/cadência MASCARADA fora do escopo (present/committed/file_mtime = null)',
        outRows.length > 0 && outRows.every(x => x.present === null && x.committed === null && x.file_mtime_epoch === null),
        `outRows=${JSON.stringify(outRows)}`);
  const inCrit = gd.find(x => x.var_name === 'IN_CRITICAL_KEY');
  check('dev VÊ a chave critical do PRÓPRIO escopo, com postura', !!inCrit && inCrit.committed !== null);

  // ── G3 — views admin-only (snapshot bruto / mcp paths) ──
  console.log('G3 — snapshot/mcp são admin-only');
  const snapDev   = (await jsonOrEmpty(await rest('machine_snapshot_v?select=*', jwtDev)))   || [];
  const snapAdmin = (await jsonOrEmpty(await rest('machine_snapshot_v?select=*', jwtAdmin))) || [];
  check('dev NÃO vê machine_snapshot', !(Array.isArray(snapDev) && snapDev.some(x => x.machine_id === 'zzgate-m1')));
  check('admin VÊ machine_snapshot',     Array.isArray(snapAdmin) && snapAdmin.some(x => x.machine_id === 'zzgate-m1'));
  const mcpDev = (await jsonOrEmpty(await rest('mcp_connection_v?select=*', jwtDev))) || [];
  check('dev NÃO vê mcp_connection (paths)', !(Array.isArray(mcpDev) && mcpDev.some(x => x.machine_id === 'zzgate-m1')));

  // ── G7 — anon (sem login) não recebe nada ──
  console.log('G7 — anon (sem JWT)');
  const anonResp = await rest('api_key_v?select=*', null);
  const anonRows = await jsonOrEmpty(anonResp);
  check('anon NÃO recebe linhas (0 ou erro)', !Array.isArray(anonRows) || anonRows.length === 0, `status=${anonResp.status}`);

  // ── G5 — tabelas-base (schema data) não expostas ao PostgREST ──
  console.log('G5 — tabelas-base data.* não expostas');
  const dataResp = await rest('api_key?select=*', jwtAdmin, { 'Accept-Profile': 'data' });
  check('data.api_key NÃO acessível via REST', dataResp.status !== 200, `status=${dataResp.status}`);

  console.log('');
  if (fails === 0) { console.log('✅ GATE PASS — G1/G2/G3/G5/G7 verdes contra o backend real'); process.exit(0); }
  console.log(`❌ GATE FAIL — ${fails} check(s) falharam`); process.exit(1);
}

const cmd = process.argv[2];
if (cmd === '--create-users') await createUsers();
else if (cmd === '--delete-users') await deleteUsers();
else if (cmd === '--test') await test();
else { console.error('uso: node gate-rls.mjs --create-users | --test | --delete-users'); process.exit(2); }
