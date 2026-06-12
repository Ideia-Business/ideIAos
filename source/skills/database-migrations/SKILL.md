---
name: database-migrations
description: "Workflow seguro de migrations (Supabase/SQL): diff → preview branch → aplicar → rollback plan. Use proativamente antes de qualquer mudança de schema."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: database-migrations

**Idioma:** Português brasileiro.

---

## Quando usar

- Qualquer DDL: `CREATE TABLE`, `ALTER TABLE`, nova coluna, novo índice, nova política RLS.
- Mudanças de tipo de coluna ou constraints.
- Novos relacionamentos (foreign keys).

## Quando NÃO usar

- Queries de leitura ou escrita sem mudança de schema (SELECT, INSERT, UPDATE — sem DDL).
- Migrações de dados puros sem alterar estrutura (usar script separado versionado).

---

## Processo

### 1. Diff antes de qualquer coisa

```bash
supabase db diff --schema public
```

Revisar o diff. Entender o que mudou. Nunca aplicar às cegas.

### 2. Testar em preview branch

- Criar preview branch no Supabase (ou ambiente de staging).
- Aplicar a migration no preview e validar comportamento da aplicação.
- Checar RLS: delegar ao agent `rls-reviewer` para verificar policies.

### 3. Checklist antes de aplicar em produção

- [ ] Migration é reversível? (plano de rollback documentado)
- [ ] RLS está correto? (especialmente em colunas novas)
- [ ] Índices necessários foram criados? (colunas de FK, colunas de filtro frequente)
- [ ] Testado com dump sanitizado de produção?
- [ ] Notificar equipe se houver downtime esperado.

### 4. Aplicar

```bash
supabase db push
```

Monitorar logs imediatamente após o push.

### 5. Registrar rollback

Documentar o rollback na PR ou em `docs/migrations/<timestamp>-rollback.sql`.

---

## Gotchas (do vault IdeiaOS)

- **Nunca `DROP COLUMN` sem fallback**: depreciar primeiro (deixar a coluna, parar de usar), depois dropar em migration separada após deploy estável.
- **`service_role` não respeita RLS**: código que usa `service_role` bypassa todas as políticas — revisar com cautela.
- **Testar com dump sanitizado**: dados de produção com volume real revelam problemas de performance que staging não mostra.
- **Colunas NOT NULL sem DEFAULT**: bloqueia tabelas grandes em produção (usar `DEFAULT` ou adicionar em etapas).

---

## Output

- Arquivo de migration versionado (ex.: `supabase/migrations/<timestamp>_<descricao>.sql`).
- Plano de rollback documentado.
- Checklist preenchido e aprovado antes do push em produção.

---

## Anti-patterns

- Editar schema direto no dashboard sem gerar migration (perde rastreabilidade).
- Aplicar em produção sem testar em preview.
- `DROP COLUMN` imediato em coluna que a aplicação ainda referencia.
- Migration sem índice em FK (degrada queries de join).
