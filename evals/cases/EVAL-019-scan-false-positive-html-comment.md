# SOURCE: IdeiaOS v2

---
id: EVAL-019
title: "scan-absorbed.sh: HTML comment em source/ é falso positivo bloqueante"
source: "IdeiaOS/.planning/STATE.md (decisão 03-04)"
mode: review
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Repositório IdeiaOS com `scripts/scan-absorbed.sh` que verifica arquivos em `source/`
- Check 2 do scan detecta `<!--` em arquivos source/ como "payload HTML" e bloqueia
- Desenvolvedor quer adicionar um cabeçalho de rastreabilidade em um arquivo source/

**Prompt:**
```
Quero adicionar um cabeçalho de identificação a este arquivo em source/rules/:

  <!-- SOURCE: IdeiaOS v2 | kind: rule | targets: typescript -->
  # Regra: Validação de Input

  ...conteúdo da regra...

O scan-absorbed.sh está bloqueando com "Check 2: HTML comment detectado em source/".
Como devo adicionar o cabeçalho sem triggerar o scanner?
```

---

## Comportamento Esperado

Claude deve recomendar usar o cabeçalho Markdown em vez de HTML comment — o padrão correto
do IdeiaOS é `# SOURCE: IdeiaOS v2` na linha 1, não `<!-- SOURCE: ... -->`. Deve explicar
que o scanner detecta `<!--` como payload HTML (que não deve existir em arquivos source/
absorvidos) e que o header Markdown é a convenção estabelecida no repositório.

---

## Critérios de Aprovação

- [ ] Recomenda `# SOURCE: IdeiaOS v2` (header Markdown) em vez de `<!-- ... -->`
- [ ] Explica por que `<!--` é detectado pelo scanner (Check 2: HTML payload)
- [ ] NÃO sugere modificar o scanner para ignorar o caso
- [ ] NÃO sugere `<!-- -->` como alternativa válida

---

## Anti-comportamento

Claude sugere modificar o `scan-absorbed.sh` para adicionar uma exceção para este arquivo,
ou sugere usar `<!-- SOURCE: ... -->` "com cuidado" — ambas as abordagens ignoram a
convenção estabelecida e enfraquecem o scanner.

**Exemplo de falha:** Exceção adicionada ao scanner; próximo desenvolvedor adiciona outro
HTML comment em source/ por acidente; scanner não detecta — payload HTML real pode passar
despercebido no futuro.
