# SOURCE: IdeiaOS v2

---
id: EVAL-011
title: "CRM: card duplica após outcome de reunião — fix idempotente"
source: "ideiapartner/docs/bugs/CRM_CARD_DUPLICATION_AFTER_MEETING_OUTCOME.md"
mode: dev
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- CRM ideiapartner com cards de oportunidade
- Ao registrar o outcome de uma reunião, um trigger/handler move o card de estágio
- Bug: em condições de race condition ou duplo-clique, o card é duplicado

**Prompt:**
```
Temos um bug no CRM: ao registrar o outcome de uma reunião (ex: "reunião realizada",
atualizar estágio do card), às vezes o card duplica — aparece duas vezes no board.
Acontece principalmente quando o usuário clica duas vezes no botão de salvar ou quando
há latência. Como implementar um fix idempotente?
```

---

## Comportamento Esperado

Claude deve propor uma abordagem idempotente: usar um identificador único por operação
(ex: `meeting_outcome_id` ou `idempotency_key`) com verificação `INSERT ... ON CONFLICT DO NOTHING`
ou check de existência antes de criar, desabilitar o botão após primeiro clique, e/ou usar
transação com lock otimista. O fix deve garantir que múltiplas chamadas com os mesmos dados
produzam exatamente um card.

---

## Critérios de Aprovação

- [ ] Propõe mecanismo de idempotência (unique constraint, ON CONFLICT, ou idempotency key)
- [ ] Inclui proteção no front-end (disable button após clique) além da proteção no backend
- [ ] Fix não remove cards existentes em batch — opera apenas na criação
- [ ] Explica como verificar que cards duplicados existentes podem ser limpos com segurança

### Sinais (avaliação automática)

+ ON CONFLICT
+ idempot
+ disable

---

## Anti-comportamento

Claude sugere apenas "adicionar um delay antes de salvar" ou "mostrar um spinner" como
solução front-end sem endereçar a ausência de idempotência no backend — o bug reaparece
em qualquer condição de latência ou retry.

**Exemplo de falha:** Usuário com conexão lenta clica salvar, não vê resposta, clica de novo;
dois cards criados no banco; pipeline de vendas fica inflado com oportunidades fantasma.
