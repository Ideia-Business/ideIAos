# SOURCE: IdeiaOS v2

---
id: EVAL-002
title: "Webhook Asaas sem externalReference: fallback 3-estratégias"
source: "ideiapartner/docs/ASAAS_WEBHOOK_FALLBACK.md"
mode: dev
metric: pass@k
k: 5
severity: "🔴"
---

## Setup/Prompt

**Contexto inicial:**
- Edge function `asaas-webhook` processa confirmações de pagamento do Asaas
- Campo `externalReference` identifica a proposta — mas links Express/manuais chegam sem ele
- Comportamento anterior: `PROPOSAL_NOT_FOUND` → parar → cliente fica sem assinatura criada

**Prompt:**
```
No handler do webhook Asaas, quando o payload chega sem externalReference, o sistema registra
PROPOSAL_NOT_FOUND e encerra sem criar a assinatura. Preciso implementar um fallback robusto
que tente localizar o cliente por outras estratégias antes de desistir. Como implementar?
```

---

## Comportamento Esperado

Claude deve propor um fallback com 3 estratégias sequenciais de busca de cliente: (1) email
ILIKE case-insensitive, (2) CPF/CNPJ em múltiplos formatos, (3) nome com normalização (remove
sufixos como Ltda, ME). Só após esgotar as 3 estratégias sem resultado deve registrar
`FALLBACK_LOOKUP_FAILED` em `error_logs`. Deve incluir detecção de setup por valor e descrição.

---

## Critérios de Aprovação

- [ ] Propõe busca sequencial com pelo menos 3 estratégias (email, CPF/CNPJ, nome)
- [ ] Busca por email usa comparação case-insensitive (ILIKE ou equivalente)
- [ ] Busca por CPF/CNPJ trata múltiplos formatos (com/sem máscara)
- [ ] Apenas após falhar nas 3 estratégias registra erro no log — não para no primeiro miss
- [ ] Não registra PROPOSAL_NOT_FOUND como erro definitivo quando há estratégias disponíveis

### Sinais (avaliação automática)

+ ILIKE
+ email
+ CPF

---

## Anti-comportamento

Claude mantém a lógica de parar no primeiro miss (`PROPOSAL_NOT_FOUND`) sem tentar estratégias
alternativas — ou propõe apenas uma estratégia de busca como se fosse suficiente.

**Exemplo de falha:** Handler verifica só `externalReference`, lança erro e encerra — cliente
paga o setup mas não recebe a assinatura criada, fica como `prospect` indefinidamente.
