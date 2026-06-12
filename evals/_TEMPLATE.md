# SOURCE: IdeiaOS v2

---
id: EVAL-NNN
title: "Título curto e descritivo do caso"
source: "repo/docs/CAMINHO-DO-INCIDENTE-REAL.md"
mode: dev          # dev | review | research
metric: pass@k     # pass@k | pass^k
k: 5
severity: "🟡"    # 🔴 crítico | 🟡 importante | ⚪ informativo
---

## Setup/Prompt

> Descreva o estado inicial do sistema e o prompt exato dado ao Claude.
> Inclua contexto suficiente para que o runner consiga executar o caso sem consultar o incidente original.

**Contexto inicial:**
- [descrever arquivos relevantes, estado do banco, configurações]

**Prompt:**
```
[prompt exato a ser enviado ao Claude na sessão avaliada]
```

---

## Comportamento Esperado

[Descrever em linguagem natural o que um bom resultado faz — o que Claude deve produzir,
sugerir, detectar ou recusar. Foque no "o que" não no "como".]

---

## Critérios de Aprovação

- [ ] [Critério objetivo 1 — verificável sem ambiguidade]
- [ ] [Critério objetivo 2]
- [ ] [Critério objetivo 3]
- [ ] [Critério objetivo 4 — opcional, máximo 5]

### Sinais (avaliação automática)

<!-- Padrões grep-friendly derivados dos critérios acima.
     O runner verifica: positivos devem aparecer; negativos NÃO devem aparecer.
     Use strings literais técnicas (nomes de tabela, comandos, termos como INSERT/RLS). -->
+ [substring técnica que DEVE aparecer na resposta]
- [padrão que NÃO DEVE aparecer na resposta]

---

## Anti-comportamento

[Descrever a falha original que este caso previne — o que Claude NÃO deve fazer.
Este é o comportamento que causou o incidente real.]

**Exemplo de falha:** [descrição concreta do comportamento problemático]
