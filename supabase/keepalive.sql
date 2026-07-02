-- keepalive.sql — tabela mínima para o cron de keep-alive tocar o Postgres.
--
-- PROPÓSITO: o free-tier do Supabase pausa um projeto após 7 dias sem atividade de
-- API/banco. O workflow .github/workflows/supabase-keepalive.yml faz um SELECT nesta
-- tabela diariamente — uma query REAL ao Postgres (não só um hit no gateway), o que
-- conta inequivocamente como atividade e evita a pausa.
--
-- APLICAR EM CADA projeto IdeiaOS free-tier (Dashboard → SQL Editor → cola e roda),
-- OU: supabase link --project-ref <ref> && supabase db execute --file supabase/keepalive.sql
--
-- IDEMPOTENTE: pode rodar quantas vezes quiser. Expõe só um timestamp trivial via anon;
-- ZERO dado sensível (least-privilege). Ver docs/guides/supabase-keepalive.md.

create table if not exists public.keepalive (
  id        smallint    primary key default 1,
  last_ping timestamptz not null    default now(),
  constraint keepalive_singleton check (id = 1)
);

insert into public.keepalive (id) values (1)
  on conflict (id) do nothing;

alter table public.keepalive enable row level security;

-- SELECT público (role anon) — a única capacidade que o keep-alive precisa.
-- Sem INSERT/UPDATE/DELETE: o cron só lê. A tabela guarda um único timestamp trivial.
drop policy if exists keepalive_select_anon on public.keepalive;
create policy keepalive_select_anon on public.keepalive
  for select
  to anon
  using (true);
