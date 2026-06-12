# SOURCE: IdeiaOS v2

---
id: EVAL-015
title: "Mesma métrica deve bater entre telas diferentes"
source: "ideiapartner/docs/CROSS_SCREEN_METRIC_CONSISTENCY.md"
mode: review
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Aplicação ideiapartner com painel admin e painel de cliente
- Métrica "MRR ativo" calculada em duas telas diferentes
- Painel admin mostra R$ 42.500; painel de cliente mostra R$ 41.800 para o mesmo período

**Prompt:**
```
Temos uma inconsistência: o painel admin mostra MRR = R$ 42.500 e a tela de assinatura do
cliente mostra MRR = R$ 41.800 para o mesmo mês. Ambas parecem corretas isoladamente.
Como revisar o código para garantir que as duas telas usem exatamente a mesma fonte de dados
e lógica de cálculo?
```

---

## Comportamento Esperado

Claude deve identificar que as duas telas provavelmente têm queries/lógicas de cálculo
independentes (duplicação de lógica de negócio) em vez de consumir uma única fonte de verdade.
Deve recomendar extrair o cálculo de MRR para uma função/view/RPC compartilhada e que ambas
as telas consumam essa única fonte. Deve também identificar possíveis causas da diferença
(filtros diferentes, status incluídos/excluídos, arredondamento).

---

## Critérios de Aprovação

- [ ] Identifica duplicação de lógica de cálculo como causa estrutural
- [ ] Propõe fonte única de verdade (função compartilhada, DB view, ou RPC)
- [ ] Lista possíveis causas da divergência (filtros, status, arredondamento)
- [ ] Não propõe apenas "checar qual das duas está correta" sem endereçar a duplicação

---

## Anti-comportamento

Claude revisa cada cálculo isoladamente, encontra "a correta", e sugere copiar a lógica da
correta para a errada — duas cópias continuam existindo, divergência vai acontecer novamente.

**Exemplo de falha:** Lógica copiada; três meses depois uma nova regra de negócio é aplicada
em uma tela mas não na outra; inconsistência retorna — mesma raiz, novo sintoma.
