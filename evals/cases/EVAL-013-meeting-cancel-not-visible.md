# SOURCE: IdeiaOS v2

---
id: EVAL-013
title: "Cancelamento de reunião não aparece na UI — consistência de estado"
source: "ideiapartner/docs/bugs/MEETING_CANCEL_NOT_VISIBLE.md"
mode: dev
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Sistema de agendamento ideiapartner
- Usuário cancela uma reunião via API/backend; banco atualizado corretamente
- UI continua exibindo a reunião como ativa (não reflete o cancelamento)

**Prompt:**
```
Bug relatado: ao cancelar uma reunião, o backend atualiza o status para "cancelado" no banco,
mas a UI continua mostrando a reunião como ativa. O usuário precisa recarregar a página para
ver o cancelamento. Como corrigir para que a UI reflita o cancelamento imediatamente?
```

---

## Comportamento Esperado

Claude deve identificar a causa: cache do React Query / estado local não invalidado após a
mutação de cancelamento. A solução deve incluir invalidação explícita da query relevante
após a mutação bem-sucedida (`queryClient.invalidateQueries(['meetings', ...])`) ou atualização
otimista do cache local. Deve também verificar se há subscription realtime que deveria propagar
a mudança automaticamente.

---

## Critérios de Aprovação

- [ ] Identifica cache stale como causa (React Query ou estado local não invalidado)
- [ ] Propõe invalidação de queries após mutação bem-sucedida (não apenas após erro)
- [ ] Menciona atualização otimista como alternativa para UX mais responsiva
- [ ] Verifica se há subscription realtime que poderia/deveria propagar a mudança

### Sinais (avaliação automática)

+ invalidateQueries
+ stale
- window.location.reload

---

## Anti-comportamento

Claude sugere adicionar `window.location.reload()` após o cancelamento como solução —
tecnicamente funciona mas é regressão de UX e indica ausência de entendimento do cache.

**Exemplo de falha:** Usuário cancela reunião, UI não atualiza, usuário cancela de novo
(duplo cancelamento), segundo cancelamento pode disparar lógica de negócio indesejada
(ex: notificação duplicada, registro de cancelamento duplicado).
