-- SOURCE: IdeiaOS v16 / Frente B | kind: p3-gate-teardown | targets: claude,cursor
-- =============================================================================
-- gate-teardown.sql — remove TODO o cenário de teste do gate (prefixo 'zzgate-').
--
-- Rode no SQL Editor quando quiser deixar o P3 limpo para os dados reais.
-- Complemento: os 2 usuários de teste do Auth (@gate.invalid) saem com
--   `node gate-rls.mjs --delete-users` (deletar o auth.user cascateia app_user /
--   user_project_scope; os demais zzgate-* saem por estes DELETEs).
--
-- Idempotente e seguro: só toca identificadores 'zzgate-%' e os 2 emails de teste.
-- =============================================================================

begin;
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
commit;
