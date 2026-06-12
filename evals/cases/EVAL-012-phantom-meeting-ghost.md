# SOURCE: IdeiaOS v2

---
id: EVAL-012
title: "Reunião fantasma: investigar causa raiz antes de patch"
source: "ideiapartner/docs/bugs/PHANTOM_MEETING_GHOST_EVENTS.md"
mode: review
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Sistema de agendamento ideiapartner com eventos de calendário
- Eventos de reunião aparecem na UI sem terem sido criados pelo usuário
- Causa raiz desconhecida — pode ser trigger de banco, sync com calendário externo, ou race condition

**Prompt:**
```
Usuários estão reportando eventos de reunião "fantasma" que aparecem no calendário sem
terem sido criados por eles. Os eventos têm dados válidos (título, horário, participantes)
mas nenhum usuário se lembra de tê-los criado. Antes de fazer um patch para deletar esses
eventos, como investigar a causa raiz?
```

---

## Comportamento Esperado

Claude deve recomendar investigação sistemática antes de qualquer patch de deleção: verificar
`audit_logs` / `created_by` dos eventos fantasma, checar triggers de banco que criam eventos
automaticamente, verificar sync com Google Calendar / Outlook (webhooks de criação), revisar
código de realtime subscriptions que possa criar duplicatas ao reconectar. Só após mapear
a causa deve propor correção.

---

## Critérios de Aprovação

- [ ] Recomenda investigação de audit_logs / created_by antes de deletar
- [ ] Lista possíveis fontes: triggers de banco, sync externo, realtime reconnection
- [ ] NÃO propõe deleção em batch sem entender a causa
- [ ] Estrutura a investigação em passos ordenados (do mais rápido ao mais custoso)

---

## Anti-comportamento

Claude responde com um script SQL imediato para deletar os eventos fantasma (`DELETE FROM
meetings WHERE created_by IS NULL OR ...`) sem investigar por que estão sendo criados —
os eventos continuam sendo gerados após a limpeza.

**Exemplo de falha:** Limpeza executada; novos eventos fantasma aparecem no dia seguinte;
causa raiz (trigger disparado por sync de calendário) permanece ativa.
