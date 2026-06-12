<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor | stack: supabase-->
# Supabase RLS Patterns

## RLS Checklist (antes de qualquer migration)

- [ ] Toda tabela nova tem RLS habilitada: `ALTER TABLE x ENABLE ROW LEVEL SECURITY;`
- [ ] Policy de leitura usa `auth.uid()` ou `auth.role()` — nunca `true` em prod
- [ ] Policy de escrita verifica ownership: `auth.uid() = user_id`
- [ ] Service role bypass documentado e justificado (só para Edge Functions server-side)
- [ ] Migration testada em preview branch antes de aplicar em prod

## Padrões de Auth

```sql
-- Policy padrão de leitura para dados do usuário
CREATE POLICY "users_own_data" ON table_name
  FOR SELECT USING (auth.uid() = user_id);

-- Policy para admins via custom claim
CREATE POLICY "admin_access" ON table_name
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');
```

## Gotchas

- `supabase db push` em prod sem preview branch = perigo; sempre usar migrations versionadas
- `realtime` em tabela com RLS: publicar só colunas seguras no `replication` config
- `storage.objects` RLS é separado de `public.` tables — verificar ambos
- Edge Functions com `service_role` não respeitam RLS — auditar toda chamada server-side

## Migrations

- Sempre rodar `supabase db diff` antes de `db push`
- Testar em `supabase start` local com dados reais (dump do prod sanitizado)
- Nunca usar `DROP COLUMN` sem migration de fallback na semana anterior
