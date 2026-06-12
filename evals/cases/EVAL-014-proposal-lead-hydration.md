# SOURCE: IdeiaOS v2

---
id: EVAL-014
title: "Proposta: hidratação de lead falhando (v7.73)"
source: "ideiapartner/docs/bugs/PROPOSAL_LEAD_HYDRATION_FIX_v7.73.md"
mode: dev
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Sistema de propostas ideiapartner (v7.73+)
- Ao abrir uma proposta, os dados do lead vinculado não são carregados (campos vazios/undefined)
- A proposta tem `lead_id` válido no banco; o lead existe; RLS permite acesso

**Prompt:**
```
Bug na v7.73: ao abrir uma proposta, os campos do lead vinculado aparecem vazios (nome,
email, empresa). O banco tem o lead_id correto na tabela proposals, o lead existe em leads,
e as políticas RLS permitem acesso. O fetch da proposta retorna o objeto correto mas sem
os dados do lead. Como investigar e corrigir?
```

---

## Comportamento Esperado

Claude deve investigar a query de fetch da proposta: verificar se o join/select do lead
está presente (`select('*, lead:leads(*)')`), se a foreign key está correta, se há mismatch
entre o nome da relação no schema e o alias usado na query, e se o cache do React Query
tem um resultado stale sem o join. Deve propor fix na query de fetch antes de qualquer
solução de patch de dados.

---

## Critérios de Aprovação

- [ ] Verifica a query de fetch da proposta (join/select do lead incluído?)
- [ ] Verifica o nome da foreign key / relação no schema Supabase
- [ ] Considera cache stale como possível causa (resultado sem join cacheado)
- [ ] Propõe fix na camada de dados antes de workarounds no componente

---

## Anti-comportamento

Claude sugere buscar o lead separadamente com um segundo fetch após carregar a proposta —
N+1 query desnecessária que não resolve o problema estrutural do join ausente.

**Exemplo de falha:** Fix de N+1 aplicado; proposta carrega em 2 roundtrips em vez de 1;
problema realmente era foreign key com nome diferente do esperado — segundo fetch também
falha silenciosamente se RLS bloquear a rota direta ao lead.
