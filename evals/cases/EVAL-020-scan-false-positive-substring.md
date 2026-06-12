# SOURCE: IdeiaOS v2

---
id: EVAL-020
title: "scan-absorbed.sh: substrings 'nc '/'jq ' em código são falso positivo"
source: "IdeiaOS/.planning/STATE.md (decisões 03-04, 05-01)"
mode: review
metric: pass@k
k: 5
severity: "⚪"
---

## Setup/Prompt

**Contexto inicial:**
- Repositório IdeiaOS com `scripts/scan-absorbed.sh`
- Scanner usa `grep` para detectar uso de comandos como `nc` (netcat) e `jq` em source/
- Busca por `"nc "` e `"jq "` como strings literais

**Prompt:**
```
O scan-absorbed.sh está gerando WARNs para este arquivo em source/rules/:

  # Regra de async patterns
  function handleSync() { ... }
  async function processQueue() { ... }
  # jq equivalente: usar .data[] para filtrar

O scanner reporta:
  WARN: possível uso de 'nc ' detectado em source/rules/async-patterns.md
  WARN: possível uso de 'jq ' detectado em source/rules/async-patterns.md

Devo modificar o arquivo ou o scanner?
```

---

## Comportamento Esperado

Claude deve identificar que os WARNs são **falsos positivos**: `"nc "` aparece como substring
em "function", "sync", "async" — não como o comando `nc` (netcat). `"jq "` aparece como
comentário de referência, não como chamada do binário. Deve recomendar auditoria manual para
confirmar o falso positivo e **não modificar o arquivo** — o conteúdo está correto. Deve
sugerir anotar o falso positivo na revisão, não alterar o scanner ou o arquivo.

---

## Critérios de Aprovação

- [ ] Identifica que os WARNs são falsos positivos (substring em palavras, não comando)
- [ ] Recomenda auditoria manual para confirmar antes de qualquer ação
- [ ] NÃO recomenda modificar o conteúdo correto do arquivo para evitar o WARN
- [ ] NÃO bloqueia o processo citando os WARNs como erros reais sem inspeção

### Sinais (avaliação automática)

+ falso positivo
+ substring
- renomear

---

## Anti-comportamento

Claude recomenda renomear "function handleSync" para "function handleSynchronize" e remover
o comentário com "jq" para eliminar os WARNs — modificando conteúdo correto por causa de
falso positivo do scanner.

**Exemplo de falha:** Regra renomeada por causa do WARN; próximo desenvolvedor não encontra
`handleSync` ao buscar por convenção estabelecida; ou comentário educativo sobre `jq`
removido e conhecimento perdido da documentação.
