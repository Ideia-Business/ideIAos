# SOURCE: IdeiaOS v2

---
id: EVAL-016
title: "Cache cross-module: invalidar ao mutar dado compartilhado"
source: "ideiapartner/docs/CROSS_MODULE_CACHE_INVALIDATION.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Aplicação ideiapartner com módulos CRM, Financeiro e Dashboard
- Dado compartilhado: status do cliente (`client.status`)
- Módulo CRM atualiza status do cliente; módulo Financeiro e Dashboard leem o status
- React Query com cache separado por módulo

**Prompt:**
```
Quando o módulo CRM atualiza o status de um cliente de "prospect" para "cliente_ativo",
o módulo Financeiro ainda mostra "prospect" por alguns minutos, e o Dashboard também.
A mutação no CRM invalida apenas a query do próprio CRM. Como garantir que todos os
módulos reflitam a mudança imediatamente?
```

---

## Comportamento Esperado

Claude deve identificar que a mutação de CRM deve invalidar todas as queries que dependem
do status do cliente — não apenas a query do módulo CRM. Deve recomendar uso de query keys
hierárquicas (ex: `['client', clientId]` como prefixo compartilhado) para que
`invalidateQueries(['client', clientId])` invalide todos os módulos de uma vez. Alternativa:
realtime subscription no status do cliente propagando para todos os módulos.

---

## Critérios de Aprovação

- [ ] Identifica query keys isoladas por módulo como causa da inconsistência
- [ ] Propõe query key hierárquica compartilhada entre módulos para o mesmo dado
- [ ] Mutação do CRM invalida a chave compartilhada (não apenas a chave local do CRM)
- [ ] Menciona realtime subscription como alternativa para propagação automática

### Sinais (avaliação automática)

+ query key
+ invalidateQueries
+ compartilh

---

## Anti-comportamento

Claude sugere aumentar o `staleTime` para 0 em todos os módulos (refetch sempre) — resolve
o sintoma com mais requests mas não endereça a raiz (ausência de invalidação coordenada).

**Exemplo de falha:** `staleTime: 0` aplicado; status sempre fresco via polling, mas em
picos de tráfego o módulo Financeiro mostra status diferente do CRM por 2-3 segundos —
decisão financeira tomada com dado desatualizado em janela crítica de cobrança.
