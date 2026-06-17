# ADR — Absorver técnicas de `mattpocock/skills`, não a ideologia anti-framework

**Data:** 2026-06-16
**Milestone:** v9 — Camada de Alinhamento
**Requisitos:** R9-07
**Status:** Aceito

---

## Contexto

O repo externo `mattpocock/skills` (MIT, Matt Pocock — "Skills For Real Engineers")
posiciona-se **explicitamente contra frameworks que tomam conta do processo**. O README
cita nominalmente GSD, BMAD e Spec-Kit:

> *"Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while
> doing so, they take away your control and make bugs in the process hard to resolve."*

É uma aposta deliberada em **skills à la carte** em vez de pipeline governado.

O IdeiaOS é o **oposto estrutural**: um orquestrador de 5 camadas governadas pela Deia.
Ao avaliar a absorção de técnicas valiosas desse repo — notadamente o *grilling* do
`/grill-with-docs`, o glossário de **linguagem ubíqua** (`CONTEXT.md`) e o ritual de
*"deepening"* arquitetural de Ousterhout (`improve-codebase-architecture`) — surge a
tensão: **adotar essas técnicas significa adotar junto a postura anti-framework?**

A análise completa está em [`docs/research/2026-06-16-mattpocock-skills-analise.md`](../research/2026-06-16-mattpocock-skills-analise.md)
(ver §1 sumário executivo e §7 "Postura sobre a tensão anti-framework"). Das ~20 skills do
repo, apenas **3 são gaps reais** do IdeiaOS; o resto já temos igual ou melhor, ou é nicho.

---

## Decisão

**Absorvemos as TÉCNICAS, NÃO a POSTURA.**

- Adotamos as técnicas de Pocock — *grilling* pré-plano, linguagem ubíqua / `CONTEXT.md`,
  módulos profundos de Ousterhout — como **skills que a Deia orquestra**.
- **Não** adotamos a tese de que processo governado é ruim. Essas técnicas **não são
  frameworks — são rituais**, e ritual solto ("skill que você tem que lembrar de usar") é
  exatamente o que a Deia foi feita para disparar na hora certa.
- A entrada de alinhamento (`/grelha`) entra como **gate opcional e escapável** (Passo 1.5
  da Deia): **oferece, não obriga**.

### Por que não há contradição

A crítica do Matt — *processo opaco que esconde bugs e tira o controle do humano* — o
IdeiaOS **já mitiga por design**:

- princípio **"comando direto é caminho válido"** (o humano nunca é forçado a um pipeline);
- **roteamento transparente** (a Deia mostra o comando antes de executar);
- **gates como contratos explícitos**, não caixa-preta.

Logo, colocar as técnicas dele sob orquestração não reintroduz o problema que ele aponta —
ao contrário, as torna mais poderosas sem comprar a ideologia de que orquestração é o inimigo.

### O que explicitamente NÃO adotamos

- A tese de que **orquestração é o inimigo**.
- O acoplamento a **GitHub Issues** (`to-issues` / `triage`) — nosso modelo é fases/stories.
- O estilo **`caveman`** (comunicação ultracomprimida) — conflita com clareza + PT-BR.
- **Não** trocamos `/gsd-debug` pelo `diagnose` dele, nem nossa `/tdd` pela dele — os nossos
  são iguais ou superiores.

---

## Alternativas consideradas

- **(a) Não absorver nada** — descartada: perderíamos 3 GAPs reais (grilling colaborativo
  pré-plano, glossário ubíquo durável, ritual de *deepening*) que o IdeiaOS hoje não cobre.
- **(b) Absorver inclusive a postura — skills à la carte, sem orquestração** — descartada:
  violaria a identidade do IdeiaOS (orquestrador de camadas) e a memória institucional;
  reintroduziria "skills soltas que você esquece de usar".
- **(c) Absorção seletiva sob orquestração** — **escolhida**: pega as boas peças soltas e as
  governa pela Deia, preservando o controle do humano.

---

## Consequências

- ✅ v9 fica **aditivo**: não mexe em GSD nem em AIOX; só adiciona a Camada de Alinhamento.
- ✅ Skills absorvidas levam header de atribuição **`# SOURCE: mattpocock/skills (MIT)`**
  (mesma convenção usada em `/doubt` e `/spec`), preservando o crédito exigido pela licença.
- ✅ A **fronteira filosófica fica documentada** (relatório de pesquisa + este ADR), evitando
  ambiguidade futura sobre "por que o IdeiaOS pegou skills de um repo anti-framework".
- ⚠️ Risco de **diluição filosófica** (importar a postura junto da técnica) — mitigado por
  esta decisão explícita, pelo header `# SOURCE:` e pelo `_PROVENANCE.md` da quarentena.

---

## Referências

- [`docs/research/2026-06-16-mattpocock-skills-analise.md`](../research/2026-06-16-mattpocock-skills-analise.md) — análise comparativa completa (§1 sumário, §7 postura anti-framework)
- Precedente **v8 — Camada de Disciplina**: absorção seletiva de `addyosmani/agent-skills`
  → só o delta de disciplina (`/doubt` + `operating-discipline`), mantendo GSD/AIOX intactos.
  Mesmo fluxo: quarentena → análise → absorver só o delta → propagar.
- `docs/IDEIAOS.md` — especificação canônica das 5 camadas e do papel orquestrador da Deia.
