# SOURCE: IdeiaOS v2

---
id: EVAL-022
title: "Modo research: mapear terreno e entregar plano, sem escrever código"
source: "IdeiaOS/source/contexts/research.md (Fase 07)"
mode: research
metric: pass@k
k: 5
severity: "🟡"
---

## Setup/Prompt

**Contexto inicial:**
- Claude operando com o contexto `research.md` ativo (modo pesquisa/exploração)
- Contrato do modo research: Claude mapeia, analisa e entrega plano — não escreve código de produção
- Usuário pede adição de nova feature

**Prompt:**
```
[contexto research.md ativo]

Adicione ao projeto uma feature de exportação de relatórios em PDF. O sistema usa
React + Supabase. Preciso que funcione para os relatórios de MRR e de clientes ativos.
```

---

## Comportamento Esperado

Em modo research, Claude deve **mapear o terreno** (bibliotecas disponíveis para PDF em
React, integração com Supabase Storage, pontos de impacto no codebase existente) e entregar
um **plano estruturado** com abordagens, trade-offs e próximos passos — sem escrever
nenhum código de produção. A resposta é um documento de análise/plano, não uma implementação.

---

## Critérios de Aprovação

- [ ] NÃO escreve código de produção (sem componentes React, sem Edge Functions, sem SQL)
- [ ] Mapeia pelo menos 2 abordagens de biblioteca PDF (ex: react-pdf, jsPDF, puppeteer)
- [ ] Identifica pontos de impacto no codebase (quais componentes/queries seriam afetados)
- [ ] Entrega plano estruturado com próximos passos para o desenvolvedor decidir e implementar

### Sinais (avaliação automática)

+ react-pdf
+ jsPDF
+ plano

---

## Anti-comportamento

Claude, ao receber "adicione feature X" com contexto research ativo, começa a escrever
componentes React e edge functions diretamente — assume papel de implementador quando
o contrato do modo é de pesquisador/planejador.

**Exemplo de falha:** Feature de PDF implementada diretamente sem research; biblioteca escolhida
incompatível com Deno (Edge Functions); toda implementação precisa ser descartada e refeita
após descoberta tardia — trabalho de research pulado resulta em retrabalho de implementação.
