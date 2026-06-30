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
--   Modelo de visibilidade (R16-02):
--     • admin  → vê tudo, todos os campos.
--     • dev    → vê o CATÁLOGO (existência + metadata operacional) de todos os
--                projetos/máquinas, MAS os campos de RECONNAISSANCE sensível
--                (nome de chave risk_tier=critical, cadência/file_mtime, path,
--                supabase_project_id) só são revelados DENTRO do seu escopo.
--                Fora do escopo → mascarados (NULL). É "mascaramento por-campo
--                via view", NÃO deny-all binário (contrato L435-439). O cenário
--                negativo L445 ("dev faz SELECT sobre projeto fora do escopo →
--                não retorna nome critical nem cadência") materializa-se aqui.
--     • não-membro (authenticated sem app_user) → não vê nada (where is_member()).
--
--   SECURITY DEFINER é deliberado: a view É o ponto de controle de acesso (lê
--   data.* bypassando a RLS deny-all e aplica escopo+mascaramento na própria
--   query). O aviso "security definer view" do linter Supabase é INTENCIONAL.
--   GRANT só a `authenticated` (não `anon`: exige login).
-- =============================================================================

-- ── public.machine_v — catálogo de frota (pouco sensível; visível a membros)
create or replace view public.machine_v
with (security_invoker = off) as
  select machine_id, canonical_name, os_version, agentd_version,
         first_seen_epoch, last_seen_epoch
  from data.machine
  where app.is_member();

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
--    Fora do escopo: nome de chave `critical` e a cadência (file_mtime) → NULL.
--    Mantém visível a POSTURA agregável (present/expected/risk_tier) p/ o catálogo,
--    mas nunca o NOME da chave critical nem a cadência fora do escopo.
create or replace view public.api_key_v
with (security_invoker = off) as
  select
    k.project_slug,
    case
      when app.can_see_project(k.project_slug) then k.var_name        -- no escopo: revela
      when k.risk_tier = 'critical'            then null              -- fora + critical: MASCARA o nome
      else k.var_name                                                 -- fora + não-critical: nome não-sensível
    end as var_name,
    k.present,
    k.expected,
    k.risk_tier,
    case when app.can_see_project(k.project_slug)
         then k.file_mtime_epoch else null end as file_mtime_epoch,   -- cadência: mascara fora do escopo
    k.committed,
    app.can_see_project(k.project_slug) as in_scope
  from data.api_key k
  where app.is_member();

-- ── public.mcp_connection_v — por-máquina; visível a quem vê a máquina
create or replace view public.mcp_connection_v
with (security_invoker = off) as
  select machine_id, source_file, server_name, enabled, last_seen_epoch
  from data.mcp_connection m
  where app.can_see_machine(m.machine_id);

-- ── public.daemon_status_v — por-máquina; visível a quem vê a máquina
create or replace view public.daemon_status_v
with (security_invoker = off) as
  select machine_id, label, pid, status_code, last_seen_epoch
  from data.daemon_status d
  where app.can_see_machine(d.machine_id);

-- ── public.machine_snapshot_v — payload bruto; só dentro do escopo da máquina
create or replace view public.machine_snapshot_v
with (security_invoker = off) as
  select machine_id, taken_epoch, agentd_version, payload_json
  from data.machine_snapshot s
  where app.can_see_machine(s.machine_id);

-- ── public.productivity_event_v — evento de projeto no escopo; machine-level só admin
create or replace view public.productivity_event_v
with (security_invoker = off) as
  select id, machine_id, event_type, project_slug, epoch, payload_json
  from data.productivity_event e
  where app.is_member()
    and (
      app.is_admin()
      or (e.project_slug is not null and app.can_see_project(e.project_slug))
      or (e.project_slug is null      and app.can_see_machine(e.machine_id))
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

-- ── public.user_project_scope_v — o dev vê os PRÓPRIOS escopos; admin vê todos
create or replace view public.user_project_scope_v
with (security_invoker = off) as
  select user_id, project_slug, granted_by, granted_at
  from data.user_project_scope s
  where app.is_admin() or s.user_id = auth.uid();

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
  public.station_enrollment_v
  to authenticated;

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
--   D1 (mascaramento): adotada a interpretação "catálogo + mascaramento por-campo"
--       — é a leitura que o cenário negativo L445 exige ("faz SELECT sobre projeto
--       fora do escopo" pressupõe ver a linha; o que se veda são os campos
--       critical/cadência). Alternativa mais-fechada: deny-all binário total (dev
--       nem vê que o projeto existe) — trocar 1 cláusula `where` por view. Confirmar.
--   D2 (ingestão): D2-a (edge + SERVICE_ROLE server-side) RECOMENDADO vs D2-b
--       (role `ingestor` + JWT machine_id). Decide o passo "re-apontar ingest".
--   D3 (gestão RBAC): mutação de app_user/user_project_scope/station_enrollment
--       pelo admin via edge function SERVICE_ROLE (recomendado — mantém zero policy
--       de escrita na UI) vs policy admin-only de escrita. Hoje: deny-all de escrita.
--   D4 (tipos): epoch como `bigint` (fidelidade 1:1 com o payload do agentd) vs
--       `timestamptz` idiomático. Mantido bigint p/ minimizar transformação na ingestão.
--   D5 (campos mascarados em project_v): path/remote_url/supabase_project_id/
--       class_reason mascarados fora do escopo (conservador — reduz recon de
--       topologia/infra). O contrato cita explicitamente só chave critical+cadência;
--       este fechamento extra é defensável. Confirmar se quer afrouxar.
-- =============================================================================
