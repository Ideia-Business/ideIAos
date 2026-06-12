# SOURCE: IdeiaOS v2

---
id: EVAL-005
title: "Data sem timezone vira mês anterior em BRT"
source: "nfideia/docs/learnings/2026-05-29-data-sem-timezone-vira-mes-anterior-em-brt.md"
mode: dev
metric: pass^k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Aplicação rodando em ambiente com timezone America/Sao_Paulo (BRT = UTC-3)
- Data de referência: `2026-06-01` (primeiro dia do mês)
- Código JavaScript/TypeScript processa a data sem timezone explícito

**Prompt:**
```
Temos um bug em produção: o relatório do mês de junho está aparecendo como maio para alguns
usuários. A data vem da API como string "2026-06-01" e usamos:

  const date = new Date("2026-06-01")
  const mes = date.getMonth() + 1  // retorna 5 (maio!) em vez de 6

Por que isso acontece e como corrigir para garantir que o mês exibido seja sempre o correto
independente do timezone do cliente?
```

---

## Comportamento Esperado

Claude deve explicar que `new Date("2026-06-01")` (sem timezone) é interpretado como UTC
midnight — em BRT (UTC-3) isso corresponde a `2026-05-31T21:00:00-03:00`, resultando em maio.
O fix correto é parsear a data como local (ex: `"2026-06-01T00:00:00"` sem `Z`, ou usar
biblioteca com suporte a timezone), ou usar UTC explicitamente para comparações de data.

---

## Critérios de Aprovação

- [ ] Explica a causa: string ISO sem timezone é tratada como UTC pelo `new Date()`
- [ ] Demonstra por que BRT (UTC-3) converte `2026-06-01T00:00:00Z` para `2026-05-31` local
- [ ] Propõe fix que preserva o mês correto (ex: adicionar `T00:00:00` sem Z, ou biblioteca tz)
- [ ] Fix não depende do timezone do ambiente de execução (robusto em prod/dev/CI)

---

## Anti-comportamento

Claude sugere usar `date.getUTCMonth() + 1` como solução — o que "resolve" o sintoma em BRT
mas quebra em outros timezones — ou não identifica o problema de timezone e sugere ajuste
ad-hoc no `+1` do mês.

**Exemplo de falha:** Correção com `getUTCMonth()` funciona em BRT mas quebra para usuários
em UTC+1 (Portugal) ou UTC-5 (horário de verão) — bug migra de ambiente, não é resolvido.
