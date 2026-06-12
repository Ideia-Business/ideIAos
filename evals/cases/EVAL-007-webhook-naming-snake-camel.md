# SOURCE: IdeiaOS v2

---
id: EVAL-007
title: "Webhook: handler tolera snake_case, camelCase e múltiplos tipos de payload"
source: "nfideia/docs/learnings/2026-05-29-webhook-naming-mismatch-snake-vs-camel-e-multiplos-tipos-de-payload.md"
mode: dev
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Handler de webhook que recebe eventos de terceiros
- Provedor externo pode enviar campos em snake_case (`payment_status`) ou camelCase (`paymentStatus`)
- Múltiplos tipos de evento chegam no mesmo endpoint

**Prompt:**
```
Nosso webhook handler falha quando o provedor muda o naming convention. Às vezes recebemos:
  { "payment_status": "paid", "customer_id": "123" }
E outras vezes:
  { "paymentStatus": "paid", "customerId": "123" }
E ainda outros tipos:
  { "event_type": "refund", "amount": 50.00 }

Como implementar um handler robusto que tolere os dois formatos de naming e múltiplos tipos?
```

---

## Comportamento Esperado

Claude deve propor uma estratégia de normalização no ponto de entrada do handler: converter
o payload para um formato canônico (ex: camelCase via lib como `camelcase-keys`) antes de
processar, com lookup tolerante (`payload.paymentStatus ?? payload.payment_status`). Deve
também propor roteamento por tipo de evento com discriminante explícito (`event_type` ou
`type`), e validação de schema por tipo.

---

## Critérios de Aprovação

- [ ] Propõe normalização do naming convention no ponto de entrada (não espalhada pelo código)
- [ ] Handler não falha silenciosamente se campo vier em formato inesperado
- [ ] Roteamento por tipo de evento é explícito (switch/map, não if-else aninhado ad-hoc)
- [ ] Menciona validação de schema por tipo de evento (ex: Zod, joi, ou equivalente)

---

## Anti-comportamento

Claude propõe acessar campos com verificações ad-hoc espalhadas por todo o código
(`if (payload.payment_status || payload.paymentStatus)`) sem normalização centralizada —
tornando o handler frágil para qualquer campo adicional.

**Exemplo de falha:** Terceiro muda `customer_id` → `customerId` em uma release; handler
silenciosamente ignora o campo e processa eventos com customer indefinido, corrompendo dados.
