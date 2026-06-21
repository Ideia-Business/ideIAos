---
name: learning-deterministic-replay-needs-structured-event-store
description: Uma feature de replay/time-travel DETERMINÍSTICO (reconstruir um estado/incidente passado como "lei", por exit-code) exige um EVENT-STORE ESTRUTURADO. Dado que vive só em mensagem de commit (prosa NL) ou memória curada NÃO é reconstruível deterministicamente — é vaporware até emitir um ledger estruturado. Agende a emissão do ledger na fase ANTES da feature de replay.
metadata:
  node_type: memory
  type: feedback
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

Ao planejar o IdeiaOS Cockpit (milestone v14), o blueprint prometia um "momento-prêmio": na
v14.3, reconstruir deterministicamente o incidente real de contenção Lovable deny-list
`5/5 → 2/5 → 5/5` "a partir do event-store". A apuração (doc 71) descobriu um pré-requisito
invisível: **esse estado NÃO vive num event-store estruturado** — está espalhado em mensagens de
commit em prosa (ex.: *"docs(closing): remedia regressão deny (2/5→5/5)"*) + memória curada.
Reconstruí-lo como **lei** (exit-code binário, sem interpretar NL) é **impossível** sem um ledger
estruturado. Contraste: o flip-flop do pin `gsd` no `versions.lock` (Flight Recorder v0) **É**
reconstruível porque `versions.lock` é estruturado — `git show <sha>:versions.lock` + parse.

**Why:** "reconstruir do event-store" só é determinístico se o event-store **for** estruturado.
Prosa em commit-message é interpretável por LLM (alucinável), nunca verificável por `grep`/parse +
exit-code. Prometer reconstrução determinística sobre dado não-estruturado é vaporware — a feature
parece pronta no roadmap e não tem como nascer.

**How to apply:**
- Ao planejar QUALQUER feature de replay/time-travel/post-mortem/auditoria-do-passado, primeiro
  pergunte: *o dado que vou reconstruir já existe ESTRUTURADO e append-only?* Se vive só em prosa
  (commit msg, log humano, memória), agende a **emissão de um ledger estruturado** (pipe-delimited
  análogo a `.planning/soak/*.log` / `.security/review-ledger.log`: `epoch|iso|chave|...|commit`)
  na fase **anterior** à da reconstrução — como subproduto natural do detector que já se ia construir.
- Atualize o critério de PRONTO da fase-emissora para "**grava no ledger** (não só detecta)".
- A fronteira é a mesma do `antifragile-gates`: reconstrução determinística = exit-code/parse (lei);
  interpretar prosa = NL (proibido como "lei", só advisory).
- Cross-link: [[project-milestone-v14-cockpit]] (deny-list ledger agendado p/ v14.2 como pré-req do
  momento-prêmio da v14.3), e a disciplina de verificação por exit-code em antifragile-gates.
