# SOURCE: IdeiaOS v2

---
id: EVAL-017
title: "Deploy Lovable: 400 em função adjacente por import quebrado"
source: "nfideia/docs/learnings/2026-05-29-deploy-400-em-funcao-adjacente-import-quebrado-por-lovable-ai.md"
mode: dev
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Projeto com Lovable AI gerando código automaticamente
- Deploy via Supabase Edge Functions
- Lovable modifica função A; deploy quebra com 400 na função B (adjacente, não modificada)

**Prompt:**
```
Fizemos um deploy após o Lovable AI modificar a função "process-payment". O deploy retornou
400 e a função "send-notification" (que não foi tocada) parou de funcionar. O log de deploy
mostra erro de import na "send-notification". Como detectar e reverter esse tipo de problema?
```

---

## Comportamento Esperado

Claude deve explicar que Lovable AI às vezes modifica imports em arquivos compartilhados
(ex: um módulo utilitário) que são usados por outras funções — quebrando funções adjacentes
que não foram o alvo da modificação. Deve recomendar: (1) checar o diff completo do Lovable
(não apenas a função alvo), (2) reverter o commit do Lovable se o import compartilhado foi
alterado indevidamente, (3) isolar imports por função para evitar dependências cruzadas frágeis.

---

## Critérios de Aprovação

- [ ] Identifica que o problema está em um import compartilhado modificado pelo Lovable
- [ ] Recomenda revisar o diff completo do Lovable, não apenas a função alvo
- [ ] Propõe reverter o commit do Lovable como primeiro passo seguro
- [ ] Sugere estratégia para evitar recorrência (imports isolados por função)

---

## Anti-comportamento

Claude sugere corrigir o import na `send-notification` manualmente e fazer um novo deploy
sem investigar por que o Lovable quebrou o import — o próximo commit do Lovable pode
introduzir o mesmo problema em outra função.

**Exemplo de falha:** Import corrigido manualmente; Lovable faz novo commit na semana seguinte
e quebra o mesmo import novamente — ciclo de correção manual sem endereçar a causa.
