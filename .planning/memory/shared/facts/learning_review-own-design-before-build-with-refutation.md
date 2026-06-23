---
name: learning-review-own-design-before-build-with-refutation
description: "Antes de construir a partir de um design que VOCÊ escreveu, rode um review adversarial multi-lente independente COM passe de refutação — self-review perde contradições que você mesmo introduziu, e achados não-refutados causam re-escopo errado"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4ccbd936-70a0-46eb-ba25-4466087d60d1
---

Quando o design a ser construído foi **escrito por você** (mesma sessão/autor), o self-review é o tipo mais fraco: você lê por cima das próprias contradições. Antes do primeiro tijolo, rode um **review adversarial multi-lente com agentes independentes** (coerência cruzada, segurança residual, simplicidade, prontidão-de-build, contrato) — e **sempre com um passe de REFUTAÇÃO**: cada achado HIGH passa por um cético independente que tenta derrubá-lo antes de virar item de ação.

Dois retornos comprovados: (1) **pega contradições que o autor introduziu** — aqui o review achou uma mitigação **asserida no ADR mas não desenhada** no design-irmão (e que o design ainda contradizia), e um "pilar" **invertido** entre dois docs (autoritativo num, cosmético no outro); ambos eu havia lido sem ver. (2) **a refutação evita re-escopo errado** — ~3 dos achados HIGH eram plausíveis-mas-refutáveis (o design já tratava: "F0 está bloqueado" foi refutado 2×; "camada de coordenação super-construída" foi refutada porque já estava gated). Agir nos não-refutados teria me feito "consertar" o que não estava quebrado.

**Why:** na revisão pré-build do v15 ([[project-milestone-v15-team-platform]]) o workflow `wf_8432e800-818` (5 lentes + refutação) confirmou F0=GO mas pegou 1 bloqueador REAL de build (esquema de chave do comprovante não-especificado) + 2 contradições nos docs que EU escrevi + o `[MITIGADO]` prematuro ([[learning-mitigated-label-must-not-outrun-precondition]]). Generaliza [[dogfood-review-tool-catches-own-defect]] (rodar a ferramenta sobre o próprio milestone pega defeito nela mesma) para o eixo design→build, e adiciona o **passe de refutação** como peça que separa achado-real de achado-plausível.

**How to apply:** design seu + prestes a construir → NÃO vá direto ao código. Spawne um review adversarial de N lentes independentes lendo os docs reais; faça cada HIGH ser refutado por um cético independente (default: na dúvida, refutado); só os sobreviventes viram ação. Separe explicitamente o que gateia o PRÓXIMO tijolo do que gateia fases posteriores — nem todo achado real bloqueia agora.
