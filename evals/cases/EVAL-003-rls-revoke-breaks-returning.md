# SOURCE: IdeiaOS v2

---
id: EVAL-003
title: "RLS: REVOKE SELECT quebra INSERT … RETURNING *"
source: "nfideia/docs/learnings/2026-06-05-revoke-select-quebra-insert-returning-star.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Banco PostgreSQL com RLS habilitado
- Migration de segurança revoga SELECT de uma tabela para um role específico
- Código da aplicação usa `INSERT INTO tabela (...) VALUES (...) RETURNING *`

**Prompt:**
```
Aqui está uma migration de segurança que estou revisando:

  REVOKE SELECT ON tabela_pedidos FROM role_api;
  GRANT INSERT ON tabela_pedidos TO role_api;

E o código da aplicação:
  const { data } = await supabase.from('tabela_pedidos').insert(payload).select()

Isso parece correto do ponto de vista de segurança?
```

---

## Comportamento Esperado

Claude deve **detectar** que `REVOKE SELECT` combinado com `.select()` (equivalente a
`RETURNING *`) vai causar erro de permissão em tempo de execução — mesmo que o INSERT seja
permitido, o PostgreSQL requer SELECT para retornar as colunas. Deve recomendar substituir
por `RETURNING id` (colunas explicitamente permitidas) ou ajustar a policy RLS para
permitir SELECT nas colunas necessárias.

---

## Critérios de Aprovação

- [ ] Identifica o conflito entre REVOKE SELECT e RETURNING * / .select()
- [ ] Explica que PostgreSQL requer permissão SELECT para executar RETURNING em qualquer coluna
- [ ] Propõe solução concreta: RETURNING id (coluna específica) ou política RLS adequada
- [ ] Não aprova a migration como-está sem mencionar o problema

---

## Anti-comportamento

Claude aprova a migration como correta ("parece seguro — INSERT está permitido e SELECT
revogado conforme necessário") sem detectar que `.select()` / `RETURNING *` vai falhar em
tempo de execução com erro de permissão.

**Exemplo de falha:** Feature vai para produção; primeiro INSERT com `.select()` lança
`permission denied for table tabela_pedidos`, quebrando o fluxo silenciosamente em staging
ou causando 500 em prod.
