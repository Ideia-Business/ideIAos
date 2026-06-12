<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor | stack: lovable-->
# Lovable Deployment Protocol

## Antes de qualquer push para Lovable

- [ ] `npm run build` local sem erros
- [ ] TypeScript: `tsc --noEmit` clean
- [ ] Sem `console.log` em código de produção (hook console-log-guard verifica)
- [ ] Variáveis de ambiente documentadas em `docs/lovable/env-vars.md`
- [ ] Sem secrets hardcoded (idea-doctor Seção 7)

## Sync Cursor ↔ Lovable

O Lovable tem seu próprio git history. Nunca fazer `git reset --hard` no branch Lovable.
Use `/lovable-handoff` skill para sincronizar mudanças locais → Lovable Cloud.

## Gotchas de Deploy

- Lovable usa Vite + React — imports devem ser ESM-only
- Tailwind classes dinâmicas (`${var}-500`) não são purgadas — usar `safelist` no tailwind.config
- Imagens: usar imports estáticos ou URLs absolutas (não paths relativos em produção)
- `import.meta.env` (não `process.env`) para variáveis de ambiente no Vite
- Supabase client: inicializar uma vez via singleton para evitar múltiplos websockets

## Lovable + Supabase

- Auth redirect URL deve incluir o domínio Lovable em Dashboard → Auth → URL Configuration
- Row-level security obrigatória em todas as tabelas expostas ao front-end Lovable
- Nunca expor `service_role` key no front-end (apenas `anon` key)
