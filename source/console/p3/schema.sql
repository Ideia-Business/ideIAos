-- SOURCE: IdeiaOS v16 / Frente B (read-fan-out) | kind: p3-view-ddl | targets: claude,cursor
-- =============================================================================
-- schema.sql — Plano de View (P3) · Supabase Postgres dedicado · ref ysttvskswqsvtdftjhfn
--
-- Materializa o contrato R16-02 (specs/cockpit/spec.md L433-476):
--   RLS deny-all-por-default + mascaramento por-campo por papel + admissão por pin O2.
-- Decisão de motor: docs/decisions/v16-r16-02-motor-plano-view.md (ADR ACEITO 2026-06-30).
-- Análise das 4 lentes: .planning/milestones/v16-motor-decision-analysis.md (wf_631edb5c-e96).
--
-- ─────────────────────────────────────────────────────────────────────────────
-- INVARIANTES DE SEGURANÇA (gate de F1 — sem eles, até o Supabase vira teatro)
-- ─────────────────────────────────────────────────────────────────────────────
--   1. P3 ≠ P4 — este projeto (ysttvskswqsvtdftjhfn) é fisicamente distinto do
--      step-up/autoridade (xdikjgpkiqzgebcjgqmu). Invariante S-04 / R-WP12.
--   2. `value` NUNCA — nenhuma tabela tem coluna de valor de segredo. PROPOSITAL.
--      (credential-isolation materializada — espelha source/console/schema.sql).
--   3. SERVICE_ROLE NUNCA no browser — a UI lê SOMENTE as views public.* sob
--      anon-key + login (role `authenticated`). As tabelas-base vivem em `data`,
--      schema NÃO-exposto ao PostgREST (defesa estrutural, não só GRANT).
--   4. SEM policy de INSERT/UPDATE/DELETE para a UI — a UI estruturalmente não
--      escreve. A ingestão escreve em `data.*` por fora de `anon`/`authenticated`
--      (SERVICE_ROLE via edge / credencial de ingestão por-machine_id — ver §6).
--   5. O P3 ESPELHA — é cache read-only de metadata. NÃO é autoridade: nunca
--      assina, nunca pina, nunca verifica O2. O pin O2 é AUTORITATIVO-LOCAL no
--      agentd; station_enrollment aqui apenas reflete status (PENDING/APPROVED).
--
-- ─────────────────────────────────────────────────────────────────────────────
-- GATE OBRIGATÓRIO (não satisfeito por este arquivo — é o passo seguinte)
-- ─────────────────────────────────────────────────────────────────────────────
--   Teste NEGATIVO de RLS por-campo, por EXIT-CODE, contra o backend REAL
--   deployado: um `dev` fora do escopo NÃO recebe nome de chave risk_tier=critical
--   nem cadência. RLS-enforced é NECESSÁRIO; o teste negativo é o SUFICIENTE.
--   (prove-crypto-against-real-backend-cross-runtime — nunca fixture.)
--
-- CONFIG DE PROJETO (invariante operacional, fora do SQL):
--   Em Supabase → Settings → API → "Exposed schemas": manter SOMENTE `public`
--   (e graphql_public). NUNCA adicionar `data` nem `app`. Expor `data` quebra o
--   invariante #3 (tabelas-base ficariam legíveis via REST).
-- =============================================================================

begin;

-- ─────────────────────────────────────────────────────────────────────────────
-- §0 · Schemas
--   data   — tabelas-base (NÃO exposto ao PostgREST). RLS deny-all + FORCE.
--   app    — funções helper de autorização (SECURITY DEFINER). NÃO exposto.
--   public — views de apresentação. ÚNICO ponto de leitura da UI (authenticated).
-- ─────────────────────────────────────────────────────────────────────────────
create schema if not exists data;
create schema if not exists app;
-- `public` já existe.

-- Trava de superfície: anon/authenticated não recebem privilégio default em
-- data/app. (PostgREST só enxerga schemas expostos; isto é cinto-e-suspensório.)
revoke all on schema data from anon, authenticated;
revoke all on schema app  from anon, authenticated;
-- As views public.* leem data.* via SECURITY DEFINER (ownership), não via GRANT
-- direto a authenticated — por isso authenticated não precisa de USAGE em `data`.

-- =============================================================================
-- §1 · TABELAS DE DADOS (8 portadas do read-model SQLite → Postgres)
--   Tipos: epoch → bigint (fidelidade 1:1 com o payload do agentd; o read-model
--   canônico usa epoch unix — o P3 espelha sem transformação, menos bug de
--   ingestão). flags 0/1 → boolean. payload_json → jsonb. (Ver DECISÃO-D4 no §7.)
-- =============================================================================

-- ── data.machine — máquina física única; machine_id = sha256(IOPlatformUUID)[:12]
create table if not exists data.machine (
  machine_id        text primary key,
  canonical_name    text,
  os_version        text,
  agentd_version    text,
  first_seen_epoch  bigint not null default extract(epoch from now())::bigint,
  last_seen_epoch   bigint not null default extract(epoch from now())::bigint
);

-- ── data.project — produto descoberto por iteração ~/dev/*/.git
create table if not exists data.project (
  project_slug        text primary key,
  machine_id          text not null references data.machine(machine_id) on delete cascade,
  path                text,                 -- topologia de disco — recon sensível
  remote_url          text,
  supabase_project_id text,                 -- infra — recon sensível
  is_test_dir         boolean not null default false,
  class_reason        text,
  first_seen_epoch    bigint not null default extract(epoch from now())::bigint,
  last_seen_epoch     bigint not null default extract(epoch from now())::bigint
);
create index if not exists idx_project_machine on data.project (machine_id);

-- ── data.api_key — SEMPRE por-referência. SEM coluna `value`. PROPOSITAL.
--    GUARD ESTRUTURAL (DoD #1): qualquer ALTER que adicione `value` viola
--    credential-isolation e DEVE reprovar o gate de release.
create table if not exists data.api_key (
  project_slug      text not null references data.project(project_slug) on delete cascade,
  var_name          text not null,          -- nome da chave (ex STRIPE_SECRET_KEY)
  present           boolean not null default false,
  expected          boolean not null default false,
  risk_tier         text not null check (risk_tier in ('critical','sensitive','low','none')),
  file_mtime_epoch  bigint,                 -- proxy de cadência de rotação — recon sensível
  committed         boolean not null default false,
  primary key (project_slug, var_name)
);

-- ── data.mcp_connection — servidores MCP configurados na máquina
create table if not exists data.mcp_connection (
  machine_id        text not null references data.machine(machine_id) on delete cascade,
  source_file       text not null,
  server_name       text not null,
  enabled           boolean not null default true,
  last_seen_epoch   bigint not null default extract(epoch from now())::bigint,
  primary key (machine_id, source_file, server_name)
);

-- ── data.productivity_event — evento de produtividade capturado pelo agentd
create table if not exists data.productivity_event (
  id                bigint generated always as identity primary key,
  machine_id        text not null references data.machine(machine_id) on delete cascade,
  event_type        text not null,
  project_slug      text,                   -- nullable: evento machine-level
  epoch             bigint not null default extract(epoch from now())::bigint,
  payload_json      jsonb                   -- sem secrets (garantido na ingestão)
);
create index if not exists idx_prodevent_machine on data.productivity_event (machine_id);
create index if not exists idx_prodevent_project on data.productivity_event (project_slug);

-- ── data.soak_heartbeat — linha do ledger .planning/soak/<milestone>.log
create table if not exists data.soak_heartbeat (
  milestone         text not null,
  epoch             bigint not null,
  iso               text not null,
  host              text not null,
  idea_doctor       text not null default '',
  regression        text not null default '',
  commit_hash       text not null default '',
  primary key (milestone, epoch, host)
);

-- ── data.daemon_status — estado de cada LaunchAgent ideiaos na máquina
create table if not exists data.daemon_status (
  machine_id        text not null references data.machine(machine_id) on delete cascade,
  label             text not null,
  pid               integer,
  status_code       text,
  last_seen_epoch   bigint not null default extract(epoch from now())::bigint,
  primary key (machine_id, label)
);

-- ── data.machine_snapshot — snapshot completo gravado pelo agentd (sem value)
create table if not exists data.machine_snapshot (
  machine_id        text not null references data.machine(machine_id) on delete cascade,
  taken_epoch       bigint not null,
  agentd_version    text,
  payload_json      jsonb not null,         -- ideiaos-cockpit-snapshot/v1 (sem value)
  primary key (machine_id, taken_epoch)
);

-- =============================================================================
-- §2 · TABELAS RBAC (novas na Frente B)
--   app_user (papel) · user_project_scope (escopo de leitura dev→projetos) ·
--   station_enrollment (espelho do pin O2 — NUNCA autoridade).
-- =============================================================================

-- ── data.app_user — mapeia o usuário autenticado (auth.uid) → papel
create table if not exists data.app_user (
  user_id        uuid primary key references auth.users(id) on delete cascade,
  role           text not null check (role in ('admin','dev')),
  display_name   text,
  github_login   text,                      -- conta pessoal (gustavolpaiva, lucas-abreu56)
  created_at     timestamptz not null default now()
);

-- ── data.user_project_scope — quais projetos um `dev` pode VER por completo
--    (admin não precisa de linhas: vê tudo). Default-deny (linha ausente = negado).
create table if not exists data.user_project_scope (
  user_id        uuid not null references data.app_user(user_id) on delete cascade,
  project_slug   text not null references data.project(project_slug) on delete cascade,
  granted_by     uuid references data.app_user(user_id),
  granted_at     timestamptz not null default now(),
  primary key (user_id, project_slug)
);

-- ── data.station_enrollment — ESPELHO do enrollment O2 (TOFU). NÃO é autoridade.
--    A estação publica {machine_id, signing_fingerprint, enc_pubkey} como PENDING;
--    o admin aprova comparando o fingerprint out-of-band → status APPROVED aqui.
--    O re-pin AUTORITATIVO acontece na lista pinada LOCAL de cada agentd; este
--    registro só REFLETE status (R16-02 / cenário spec L468-471).
create table if not exists data.station_enrollment (
  machine_id           text primary key,
  signing_fingerprint  text not null,
  enc_pubkey           text not null,
  status               text not null default 'pending'
                         check (status in ('pending','approved','revoked')),
  role                 text check (role in ('admin','dev')),
  requested_at         timestamptz not null default now(),
  decided_at           timestamptz,
  decided_by           uuid references data.app_user(user_id)
);
-- NB (S-09): sem FK machine_id → data.machine PROPOSITAL — o enrollment O2 pode
-- preceder o 1º snapshot (admissão é local-first; este registro é só o espelho).

-- ── data.scope_audit — trilha append-only de concessão/revogação de escopo (S-07)
--    Para um recon-plane de chaves critical, "quem deu/removeu acesso a quê, quando"
--    é exatamente o que um incidente exige. Escrita SÓ pela edge de mutação (D3);
--    nunca UPDATE/DELETE (append-only enforçado pela ausência de policy + por ser
--    admin-only-read). DELETE físico de user_project_scope perderia o rastro — aqui
--    o evento fica imutável.
create table if not exists data.scope_audit (
  id            bigint generated always as identity primary key,
  action        text not null check (action in ('grant','revoke')),
  user_id       uuid not null,                -- alvo (sem FK: sobrevive a delete do app_user)
  project_slug  text not null,
  actor_id      uuid,                          -- quem executou (admin)
  at_epoch      bigint not null default extract(epoch from now())::bigint
);
create index if not exists idx_scope_audit_user on data.scope_audit (user_id);

-- =============================================================================
-- §3 · RLS — ENABLE + FORCE em TODAS as tabelas; deny-all por default.
--   Sob FORCE, até o owner respeita RLS (só roles com BYPASSRLS — SERVICE_ROLE —
--   ignoram). NENHUMA policy é criada para anon/authenticated nas tabelas-base:
--   ausência de policy sob RLS = deny-all. A leitura da UI passa SÓ pelas views
--   public.* (SECURITY DEFINER, §5). A escrita passa SÓ por SERVICE_ROLE (§6).
-- =============================================================================
alter table data.machine            enable row level security;
alter table data.machine            force  row level security;
alter table data.project            enable row level security;
alter table data.project            force  row level security;
alter table data.api_key            enable row level security;
alter table data.api_key            force  row level security;
alter table data.mcp_connection     enable row level security;
alter table data.mcp_connection     force  row level security;
alter table data.productivity_event enable row level security;
alter table data.productivity_event force  row level security;
alter table data.soak_heartbeat     enable row level security;
alter table data.soak_heartbeat     force  row level security;
alter table data.daemon_status      enable row level security;
alter table data.daemon_status      force  row level security;
alter table data.machine_snapshot   enable row level security;
alter table data.machine_snapshot   force  row level security;
alter table data.app_user           enable row level security;
alter table data.app_user           force  row level security;
alter table data.user_project_scope enable row level security;
alter table data.user_project_scope force  row level security;
alter table data.station_enrollment enable row level security;
alter table data.station_enrollment force  row level security;
alter table data.scope_audit        enable row level security;
alter table data.scope_audit        force  row level security;

-- =============================================================================
-- §4 · FUNÇÕES DE AUTORIZAÇÃO (schema app; SECURITY DEFINER; search_path travado)
--   SECURITY DEFINER é deliberado: estas funções LEEM data.app_user /
--   data.user_project_scope ignorando a RLS deny-all dessas tabelas, retornando
--   APENAS role/booleano do PRÓPRIO auth.uid() — nunca dados de terceiros. Isso
--   também QUEBRA a recursão de RLS (uma policy que chamasse is_admin() lendo
--   app_user sob RLS recursaria). search_path = '' previne hijack via search_path.
-- =============================================================================

-- papel do usuário corrente (null se não-enrolado)
create or replace function app.role_of()
returns text
language sql stable security definer set search_path = ''
as $$
  select role from data.app_user where user_id = auth.uid()
$$;

-- é membro enrolado? (qualquer papel)
create or replace function app.is_member()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from data.app_user where user_id = auth.uid())
$$;

-- é admin (CTO/TechLead)?
create or replace function app.is_admin()
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from data.app_user where user_id = auth.uid() and role = 'admin'
  )
$$;

-- o dev corrente pode ver POR COMPLETO este projeto? (admin = sempre)
create or replace function app.can_see_project(p_slug text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    coalesce((select role = 'admin' from data.app_user where user_id = auth.uid()), false)
    or exists (
      select 1 from data.user_project_scope
      where user_id = auth.uid() and project_slug = p_slug
    )
$$;

-- o dev corrente pode ver POR COMPLETO esta máquina? (admin = sempre; dev = se
-- tem escopo em ALGUM projeto daquela máquina)
create or replace function app.can_see_machine(p_machine text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    coalesce((select role = 'admin' from data.app_user where user_id = auth.uid()), false)
    or exists (
      select 1
      from data.project p
      join data.user_project_scope s on s.project_slug = p.project_slug
      where p.machine_id = p_machine and s.user_id = auth.uid()
    )
$$;

-- Travar execução: revogar de public, conceder só a authenticated (a UI logada).
revoke execute on function app.role_of()              from public;
revoke execute on function app.is_member()            from public;
revoke execute on function app.is_admin()             from public;
revoke execute on function app.can_see_project(text)  from public;
revoke execute on function app.can_see_machine(text)  from public;
grant  execute on function app.role_of()              to authenticated;
grant  execute on function app.is_member()            to authenticated;
grant  execute on function app.is_admin()             to authenticated;
grant  execute on function app.can_see_project(text)  to authenticated;
grant  execute on function app.can_see_machine(text)  to authenticated;

-- =============================================================================
-- §5 · VIEWS DE APRESENTAÇÃO (public; SECURITY DEFINER) — ÚNICO ponto de leitura.
--   Modelo de visibilidade (R16-02), ENDURECIDO pós-review adversarial:
--     • admin  → vê tudo, todos os campos.
--     • dev    → vê o catálogo de projetos (project_v) + chaves NÃO-critical
--                (api_key_v) + máquinas dos seus projetos (machine_v), com os
--                campos de RECONNAISSANCE (nome critical, cadência, postura, path,
--                infra) revelados SÓ dentro do seu user_project_scope. Fora do
--                escopo: chave critical OMITIDA; postura/cadência mascaradas.
--     • por-máquina sensível (snapshot bruto, mcp source_file, eventos
--                machine-level) → ADMIN-ONLY: o agrupador "máquina" é mais frouxo
--                que o escopo-por-projeto e o payload cru furava o mascaramento
--                (F1/F2/F3/S-04). Reabrir a dev exige ingestão POR-PROJETO (D6).
--     • não-membro (authenticated sem app_user) → não vê nada.
--
--   SECURITY DEFINER é deliberado: a view É o ponto de controle de acesso (lê
--   data.* bypassando a RLS deny-all e aplica escopo+mascaramento na própria
--   query). O aviso "security definer view" do linter Supabase é INTENCIONAL.
--   GRANT só a `authenticated` (não `anon`: exige login).
--
--   ⚠ OWNER DAS VIEWS (S-06) — INVARIANTE DE DEPLOY: o bypass de RLS de `data.*`
--   funciona porque a view roda como seu OWNER. O controle de acesso inteiro
--   reside então na cláusula `where app.*()`/`case` de cada view — uma view sem
--   filtro vaza tudo. Por isso: (1) este schema DEVE ser aplicado por um role com
--   GRANT SELECT em `data.*` (não depender de superuser-magic); (2) o gate de
--   release DEVE verificar `pg_views.viewowner` esperado e que toda view em
--   `public` tem app.is_member()/is_admin()/can_see_* no corpo (ver §7-gate).
-- =============================================================================

-- ── public.machine_v — frota visível só onde o dev tem escopo (F6/S-05).
--    canonical_name+last_seen = cadência de atividade; os/agentd_version = vetor de
--    fingerprint/exploit → mascarados p/ não-admin. Dev vê só máquinas dos seus
--    projetos (can_see_machine); admin vê toda a frota com versões.
create or replace view public.machine_v
with (security_invoker = off) as
  select
    machine_id,
    canonical_name,
    case when app.is_admin() then os_version     else null end as os_version,
    case when app.is_admin() then agentd_version else null end as agentd_version,
    first_seen_epoch,
    last_seen_epoch
  from data.machine m
  where app.can_see_machine(m.machine_id);

-- ── public.project_v — catálogo de projetos com campos sensíveis mascarados
create or replace view public.project_v
with (security_invoker = off) as
  select
    p.project_slug,
    p.machine_id,
    p.is_test_dir,
    p.first_seen_epoch,
    p.last_seen_epoch,
    case when app.can_see_project(p.project_slug) then p.path                else null end as path,
    case when app.can_see_project(p.project_slug) then p.remote_url          else null end as remote_url,
    case when app.can_see_project(p.project_slug) then p.supabase_project_id else null end as supabase_project_id,
    case when app.can_see_project(p.project_slug) then p.class_reason        else null end as class_reason,
    app.can_see_project(p.project_slug) as in_scope
  from data.project p
  where app.is_member();

-- ── public.api_key_v — o coração do mascaramento por-campo (R16-02)
--    Corrigido pós-review adversarial (S-01/S-02/F5): mascarar o NOME não bastava —
--    present/expected/committed/file_mtime de uma chave `critical` fora do escopo
--    são recon de POSTURA (quantas critical existem, se foram committadas = sinal de
--    incidente). Política endurecida:
--      • risk_tier='critical' FORA do escopo → LINHA OMITIDA por completo (nem a
--        existência/contagem vaza). Resolve o cenário negativo L445/446 fortemente.
--      • não-critical FORA do escopo → var_name+risk_tier visíveis (catálogo), mas
--        a POSTURA (present/expected/committed/file_mtime) é MASCARADA (NULL).
--      • DENTRO do escopo / admin → tudo.
--    (Mantém "mascaramento por-campo via view", não deny-all binário total — ver D1.)
create or replace view public.api_key_v
with (security_invoker = off) as
  select
    k.project_slug,
    k.var_name,                                                       -- só chega aqui se in-scope OU não-critical
    case when app.can_see_project(k.project_slug) then k.present          else null end as present,
    case when app.can_see_project(k.project_slug) then k.expected         else null end as expected,
    k.risk_tier,
    case when app.can_see_project(k.project_slug) then k.file_mtime_epoch  else null end as file_mtime_epoch,
    case when app.can_see_project(k.project_slug) then k.committed         else null end as committed,
    app.can_see_project(k.project_slug) as in_scope
  from data.api_key k
  where app.is_member()
    and (app.can_see_project(k.project_slug) or k.risk_tier <> 'critical');  -- critical fora do escopo: OMITIDA

-- ── public.mcp_connection_v — ADMIN-ONLY (F3): source_file é path completo de
--    config (ex /Users/lucas/.cursor/mcp.json) de TODOS os usuários da máquina —
--    recon de topologia cross-usuário que can_see_machine não conseguia conter.
create or replace view public.mcp_connection_v
with (security_invoker = off) as
  select machine_id, source_file, server_name, enabled, last_seen_epoch
  from data.mcp_connection
  where app.is_admin();

-- ── public.daemon_status_v — por-máquina; visível a quem vê a máquina
create or replace view public.daemon_status_v
with (security_invoker = off) as
  select machine_id, label, pid, status_code, last_seen_epoch
  from data.daemon_status d
  where app.can_see_machine(d.machine_id);

-- ── public.machine_snapshot_v — ADMIN-ONLY (F1 CRITICAL / S-04): payload_json é
--    dump da máquina INTEIRA (todos os projetos dela). can_see_machine (escopo em
--    1 projeto) deixaria o dump cru furar o escopo-por-projeto — o api_key_v/
--    project_v mascarariam, mas o snapshot bruto entregaria tudo. Fechado a admin.
--    (Reabrir a dev exige snapshot POR-PROJETO na ingestão — ver D6.)
create or replace view public.machine_snapshot_v
with (security_invoker = off) as
  select machine_id, taken_epoch, agentd_version, payload_json
  from data.machine_snapshot
  where app.is_admin();

-- ── public.productivity_event_v — dev vê SÓ eventos de projeto no seu escopo.
--    Eventos machine-level (project_slug null) → admin-only (F2): o payload_json
--    machine-level pode referenciar projetos fora do escopo (ex {"projects":[...]}),
--    e can_see_machine não os filtra. Removida a cláusula machine-level para dev.
create or replace view public.productivity_event_v
with (security_invoker = off) as
  select id, machine_id, event_type, project_slug, epoch, payload_json
  from data.productivity_event e
  where app.is_member()
    and (
      app.is_admin()
      or (e.project_slug is not null and app.can_see_project(e.project_slug))
    );

-- ── public.soak_heartbeat_v — telemetria de OS/milestone: ADMIN-ONLY
create or replace view public.soak_heartbeat_v
with (security_invoker = off) as
  select milestone, epoch, iso, host, idea_doctor, regression, commit_hash
  from data.soak_heartbeat
  where app.is_admin();

-- ── public.app_user_v — o membro vê a PRÓPRIA linha; admin vê todas
create or replace view public.app_user_v
with (security_invoker = off) as
  select user_id, role, display_name, github_login, created_at
  from data.app_user u
  where app.is_admin() or u.user_id = auth.uid();

-- ── public.user_project_scope_v — o dev vê os PRÓPRIOS escopos; admin vê todos.
--    granted_by (UUID do admin grantor) mascarado p/ não-admin (F8).
create or replace view public.user_project_scope_v
with (security_invoker = off) as
  select
    user_id,
    project_slug,
    case when app.is_admin() then granted_by else null end as granted_by,
    granted_at
  from data.user_project_scope s
  where app.is_admin() or s.user_id = auth.uid();

-- ── public.scope_audit_v — trilha de concessão/revogação de escopo: ADMIN-ONLY (S-07)
create or replace view public.scope_audit_v
with (security_invoker = off) as
  select id, action, user_id, project_slug, actor_id, at_epoch
  from data.scope_audit
  where app.is_admin();

-- ── public.station_enrollment_v — admissão de estação: ADMIN-ONLY
--    (dado sensível de pin; o re-pin real é local, este é só o espelho de status)
create or replace view public.station_enrollment_v
with (security_invoker = off) as
  select machine_id, signing_fingerprint, enc_pubkey, status, role,
         requested_at, decided_at, decided_by
  from data.station_enrollment
  where app.is_admin();

-- GRANTs de leitura: SOMENTE as views, SOMENTE a authenticated. Nunca anon,
-- nunca as tabelas-base. (anon não tem app_user → não veria nada de qualquer modo.)
grant usage on schema public to authenticated;
grant select on
  public.machine_v, public.project_v, public.api_key_v, public.mcp_connection_v,
  public.daemon_status_v, public.machine_snapshot_v, public.productivity_event_v,
  public.soak_heartbeat_v, public.app_user_v, public.user_project_scope_v,
  public.station_enrollment_v, public.scope_audit_v
  to authenticated;

-- Defesa contra enumeração e views futuras vazando a `anon` (F4/S-08):
--   • anon não loga nesta UI — remove a superfície de introspection de public.
--   • default privilege: qualquer view CRIADA NO FUTURO em public nasce SEM select
--     para anon/authenticated (força GRANT explícito + filtro app.* consciente).
revoke usage on schema public from anon;
alter default privileges in schema public revoke select on tables from anon, authenticated;

-- =============================================================================
-- §6 · ESCRITA (ingestão) — fora de anon/authenticated, por design.
--   A UI NUNCA escreve (invariante #4). A ingestão por-machine_id escreve em
--   data.* por um caminho privilegiado. DUAS opções (DECISÃO-D2 no §7):
--
--   (D2-a, RECOMENDADO) Edge function de ingestão com SERVICE_ROLE server-side:
--     o agentd POSTa o snapshot a uma edge function autenticada por um TOKEN DE
--     INGESTÃO de menor-privilégio (NÃO o SERVICE_ROLE); a função valida o
--     binding machine_id e faz UPSERT via SERVICE_ROLE que NUNCA sai do servidor.
--     → SERVICE_ROLE jamais reside numa estação; blast de uma estação = só o seu
--       próprio machine_id. Materializa "credencial de ingestão de menor-privilégio"
--       (ADR §7.7). É o caminho do step-up (edge + SERVICE_ROLE server-side).
--
--   (D2-b) Role Postgres dedicada `ingestor` + JWT com claim machine_id e policies
--     INSERT/UPDATE `with check (machine_id = auth.jwt()->>'machine_id')`.
--     → Sem edge function, mas exige emitir/gerir JWTs por máquina.
--
--   Este schema NÃO grava SERVICE_ROLE em lugar nenhum (credential-isolation). A
--   credencial de ingestão é emitida/configurada pelo dono FORA do contexto do
--   agente, no .env local. O passo "re-apontar ingest" (próximo) consome a opção
--   escolhida. Até lá, NENHUMA policy de escrita existe → deny-all de escrita.
-- =============================================================================

commit;

-- =============================================================================
-- §7 · DECISÕES DE DESIGN MARCADAS (só o dono fecha — refinar via /spec)
--   D1 (mascaramento — ÚNICA que muda comportamento de recon; ambos os reviewers
--       marcaram como decisão de SEGURANÇA, não UX): pós-endurecimento, chave
--       `critical` fora do escopo já é OMITIDA. Resta decidir o catálogo do RESTO:
--       (D1-A, atual) dev vê existência de projetos + chaves non-critical fora do
--       escopo (postura mascarada); (D1-B, mais fechado) deny-all binário total —
--       dev só vê projetos do seu user_project_scope, nada fora. Tensão literal no
--       contrato: L445 pressupõe "ver a linha"; L446 diz "não-listado = negado".
--   D2 (ingestão): D2-a (edge + SERVICE_ROLE server-side) RECOMENDADO vs D2-b
--       (role `ingestor` + JWT machine_id). Decide o passo "re-apontar ingest".
--   D3 (gestão RBAC): mutação de app_user/user_project_scope/station_enrollment +
--       escrita em scope_audit pelo admin via edge function SERVICE_ROLE (recomendado
--       — mantém zero policy de escrita na UI) vs policy admin-only. Hoje: deny-all.
--   D4 (tipos): epoch como `bigint` (fidelidade 1:1 com o payload do agentd) vs
--       `timestamptz` idiomático. Mantido bigint p/ minimizar transformação na ingestão.
--   D5 (campos mascarados em project_v): path/remote_url/supabase_project_id/
--       class_reason mascarados fora do escopo (conservador). Confirmar se afrouxa.
--   D6 (snapshot/eventos por-projeto): hoje machine_snapshot_v e eventos machine-level
--       são ADMIN-ONLY (payload cru fura escopo). Para reabrir a DEV, a ingestão
--       precisa emitir snapshots/eventos POR-PROJETO (com project_slug), trocando o
--       filtro can_see_machine → can_see_project. Escopo de evolução, não bloqueante.
--
-- §7-GATE · CHECKLIST DE RELEASE (por exit-code contra ysttvskswqsvtdftjhfn REAL —
--   nunca fixture; prove-crypto-against-real-backend-cross-runtime):
--   [ ] G1 teste NEGATIVO: dev fora do escopo em api_key_v NÃO recebe nome critical,
--       cadência, postura, nem a LINHA critical (0 rows). (cenário spec L445/446)
--   [ ] G2 admin em api_key_v/project_v recebe visão completa (cenário L448-451).
--   [ ] G3 dev em machine_snapshot_v/mcp_connection_v → 0 rows (admin-only).
--   [ ] G4 auth.uid() resolve o usuário correto sob search_path='' (S-03).
--   [ ] G5 "Exposed schemas" = só public/graphql_public — `data`/`app` NÃO expostos
--       (verificar via API; o DDL não consegue garantir — F7).
--   [ ] G6 pg_views.viewowner = role esperado (não superuser ad-hoc) e toda view em
--       public tem app.is_member()/is_admin()/can_see_* no corpo (S-06).
--   [ ] G7 anon (sem login) → 0 rows / 0 introspection em todas as views.
-- =============================================================================
