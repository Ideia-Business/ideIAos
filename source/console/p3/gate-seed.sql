-- SOURCE: IdeiaOS v16 / Frente B | kind: p3-gate-seed | targets: claude,cursor
-- =============================================================================
-- gate-seed.sql — dados de TESTE para o gate G1-G7 do Plano de View (P3).
--
-- COMO USAR: rode no SQL Editor do P3 DEPOIS que os 2 usuários de teste existirem
--   (o `gate-rls.mjs --create-users` os cria via Auth API). Este seed resolve
--   app_user.user_id POR EMAIL (não hardcoda UUID), então é estável.
--
-- Idempotente: começa apagando tudo com prefixo 'zzgate-' + os 2 app_user de teste.
-- Descartável: todos os identificadores levam o prefixo 'zzgate-' / emails @gate.invalid
--   → o teardown (gate-teardown.sql) remove sem tocar dado real.
--
-- O que o seed monta para exercitar o teste NEGATIVO (G1):
--   1 máquina · 2 projetos (in/out do escopo do dev) · 4 chaves (critical+low em cada)
--   · 1 mcp · 1 snapshot · admin (vê tudo) + dev (escopo = só zzgate-proj-in).
--   O alvo do teste negativo = OUT_CRITICAL_KEY (critical, committed) em zzgate-proj-out:
--   o dev NÃO pode vê-la (linha omitida), nem sua postura/cadência.
-- =============================================================================

begin;

-- ── teardown idempotente (ordem reversa de FK) ──
delete from data.user_project_scope where project_slug like 'zzgate-%';
delete from data.api_key            where project_slug like 'zzgate-%';
delete from data.mcp_connection     where machine_id  like 'zzgate-%';
delete from data.machine_snapshot   where machine_id  like 'zzgate-%';
delete from data.daemon_status      where machine_id  like 'zzgate-%';
delete from data.productivity_event where machine_id  like 'zzgate-%';
delete from data.project            where project_slug like 'zzgate-%';
delete from data.machine            where machine_id  like 'zzgate-%';
delete from data.app_user
  where user_id in (select id from auth.users
                    where email in ('p3-gate-admin@gate.invalid','p3-gate-dev@gate.invalid'));

-- ── máquina de teste ──
insert into data.machine (machine_id, canonical_name, os_version, agentd_version)
values ('zzgate-m1','Gate-Test-M1','macOS-test','v-test');

-- ── projetos: um DENTRO, um FORA do escopo do dev ──
insert into data.project (project_slug, machine_id, path, remote_url, supabase_project_id)
values
  ('zzgate-proj-in', 'zzgate-m1','/Users/test/in', 'git@example:in.git', 'ref-in'),
  ('zzgate-proj-out','zzgate-m1','/Users/test/out','git@example:out.git','ref-out');

-- ── chaves: critical + low em cada projeto.
--    OUT_CRITICAL_KEY (critical, committed=true) em zzgate-proj-out = alvo do teste negativo ──
insert into data.api_key (project_slug, var_name, present, expected, risk_tier, file_mtime_epoch, committed)
values
  ('zzgate-proj-in', 'IN_CRITICAL_KEY',  true, true, 'critical', 111, false),
  ('zzgate-proj-in', 'IN_LOW_KEY',       true, true, 'low',      222, false),
  ('zzgate-proj-out','OUT_CRITICAL_KEY', true, true, 'critical', 333, true),
  ('zzgate-proj-out','OUT_LOW_KEY',      true, true, 'low',      444, false);

-- ── mcp + snapshot (admin-only — G3) ──
insert into data.mcp_connection (machine_id, source_file, server_name, enabled)
values ('zzgate-m1','/Users/test/.cursor/mcp.json','zzgate-server', true);
insert into data.machine_snapshot (machine_id, taken_epoch, agentd_version, payload_json)
values ('zzgate-m1', 999, 'v-test', '{"note":"machine-wide dump — deve ser admin-only"}');

-- ── papéis: admin + dev (resolve user_id por email) ──
insert into data.app_user (user_id, role, display_name, github_login)
  select id, 'admin', 'Gate Admin', 'gate-admin'
  from auth.users where email='p3-gate-admin@gate.invalid';
insert into data.app_user (user_id, role, display_name, github_login)
  select id, 'dev', 'Gate Dev', 'gate-dev'
  from auth.users where email='p3-gate-dev@gate.invalid';

-- ── escopo do dev: SÓ zzgate-proj-in (zzgate-proj-out fica FORA) ──
insert into data.user_project_scope (user_id, project_slug)
  select id, 'zzgate-proj-in'
  from auth.users where email='p3-gate-dev@gate.invalid';

commit;

-- Conferência rápida (opcional — deve retornar 2 app_user de teste):
-- select role, github_login from data.app_user where github_login like 'gate-%';
