-- schema.sql — backend dedicado de step-up `ideiaos-cockpit-stepup` (v14.4 · B3 / F0b).
--
-- RLS DENY-ALL para usuários autenticados; SÓ a SERVICE_ROLE (edge functions) escreve/lê
-- (padrão minerado-adaptado do ideiapartner). ZERO dado de produto, ZERO role de produto.
-- Rate-limit/lockout ancorados em EMAIL (S-07), nunca IP. Scaffold F0a — aplicado em F0b.

-- ───────────────────────── otp_codes ─────────────────────────
create table if not exists public.otp_codes (
  id           uuid primary key default gen_random_uuid(),
  email        text not null,
  code_hash    text not null,                 -- sha256(salt:code) — NUNCA o código em claro (credential-isolation)
  salt         text not null,                 -- por-linha, CSPRNG
  payload_hash text not null,                 -- binding (S-01): o código é amarrado ao COMANDO
  expires_at   timestamptz not null,
  used_at      timestamptz,
  created_at   timestamptz not null default now()
);
create index if not exists idx_otp_codes_lookup  on public.otp_codes (email, payload_hash);
create index if not exists idx_otp_codes_expires  on public.otp_codes (expires_at);
create index if not exists idx_otp_codes_created  on public.otp_codes (email, created_at desc);

alter table public.otp_codes enable row level security;
create policy "deny insert otp_codes" on public.otp_codes for insert to authenticated with check (false);
create policy "deny select otp_codes" on public.otp_codes for select to authenticated using (false);
create policy "deny update otp_codes" on public.otp_codes for update to authenticated using (false);
create policy "deny delete otp_codes" on public.otp_codes for delete to authenticated using (false);

-- ───────────────────────── otp_attempts ─────────────────────────
create table if not exists public.otp_attempts (
  id           uuid primary key default gen_random_uuid(),
  email        text not null,                 -- lockout/rate-limit por EMAIL (S-07), não IP
  success      boolean not null default false,
  attempted_at timestamptz not null default now()
);
create index if not exists idx_otp_attempts_email on public.otp_attempts (email, attempted_at desc);

alter table public.otp_attempts enable row level security;
create policy "deny all otp_attempts" on public.otp_attempts for all to authenticated using (false) with check (false);

-- ───────────────────────── trusted_devices (S-05, tiering) ─────────────────────────
create table if not exists public.trusted_devices (
  id         uuid primary key default gen_random_uuid(),
  subject    text not null,
  device_id  text not null unique,
  machine_id text not null,                   -- same-machine obrigatório p/ skip
  max_tier   text not null default 'sensível' check (max_tier = 'sensível'),  -- skip nunca acima de sensível
  is_active  boolean not null default true,
  expires_at timestamptz not null,            -- janela ≤7d
  created_at timestamptz not null default now()
);
create index if not exists idx_trusted_lookup on public.trusted_devices (subject, device_id, machine_id);
create index if not exists idx_trusted_expires on public.trusted_devices (expires_at) where is_active;

alter table public.trusted_devices enable row level security;
create policy "deny all trusted_devices" on public.trusted_devices for all to authenticated using (false) with check (false);

-- Limpeza periódica (opcional; agendar via pg_cron no F0b): apaga códigos/tentativas/devices vencidos.
-- delete from public.otp_codes      where expires_at < now() - interval '1 day';
-- delete from public.otp_attempts   where attempted_at < now() - interval '1 day';
-- delete from public.trusted_devices where expires_at < now();
