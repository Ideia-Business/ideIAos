---
name: grelha
description: "Grilling colaborativo PRÉ-plano — me entrevista implacavelmente, 1 pergunta por vez com resposta recomendada, descendo a árvore de decisão ANTES de existir plano ou código. Ative quando o usuário disser: '/grelha', '/grill', 'me entrevista antes', 'grelha esse plano', 'alinha comigo antes de codar', 'antes de planejar quero pensar junto', 'monta o glossário', 'linguagem ubíqua do projeto', ou por linguagem natural quando quiser ALINHAR/AFIAR um plano antes de executar. DISTINTO do /doubt (adversarial, CONTRA artefato pronto) e do gsd-discuss-phase (GSD-bound, em-lote DENTRO de uma fase): /grelha é COLABORATIVO, à la carte, pré-plano, código e não-código. Modo --docs afia contra o glossário (CONTEXT.md) e cruza com o código; modo --rapido serve decisões de negócio sem efeito em arquivo. Absorvido de mattpocock/skills (MIT). PT-BR."
---

# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9

# Skill: /grelha — Grilling Colaborativo Pré-Plano

**Idioma:** Português brasileiro.

> Ninguém sabe exatamente o que quer antes de ser pressionado a explicar. `/grelha` é o
> ritual de **te entrevistar implacavelmente** — descendo cada galho da árvore de decisão,
> 1 pergunta por vez, sempre com uma resposta recomendada — até chegarmos a um entendimento
> compartilhado, **enquanto ainda não existe plano nem código** e mudar de ideia é barato.
> Onde o `/doubt` é o promotor (adversarial, contra um artefato), `/grelha` é o parceiro de
> pensamento (colaborativo, a favor do alinhamento).

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/grelha` · alias `/grill` |
| Modo explícito | `/grelha --docs` (default em código) · `/grelha --rapido` (não-código) |
| Pela Deia | `Deia, me entrevista antes de eu implementar o carrinho` |
| Linguagem natural | `alinha comigo antes de codar` · `grelha esse plano` · `monta o glossário do projeto` |

---

## O que é — e o que NÃO é

### O que é
Uma **entrevista implacável colaborativa**: 1 pergunta por vez, descendo a árvore de decisão
e resolvendo as dependências entre decisões uma a uma, **ANTES de existir plano ou artefato**.
Para cada pergunta você **oferece sua resposta recomendada** e **espera a resposta do humano**
antes de seguir. Quando a pergunta pode ser respondida explorando o código, você **explora o
código em vez de perguntar**. Produz **alinhamento** e — no modo `--docs` — o **glossário**
(`CONTEXT.md`) e, quando couber, ADRs.

### O que NÃO é

| Confusão comum | Camada correta |
|---------------|----------------|
| Veredito adversarial sobre artefato/decisão pronta | `/doubt` (cross-exame em-voo, CONTRA o artefato) |
| Questionamento DENTRO de uma fase GSD já aberta, em lote | `gsd-discuss-phase` (GSD-bound) |
| Contrato de comportamento durável (SHALL + cenários) | `/spec` (delta-spec brownfield) |
| Plano técnico de fase (o que vou construir agora) | GSD → `/gsd-plan-phase` |
| Repositório de decisões/implementação | ADR (`docs/decisions/`) · `/spec` · NÃO o `CONTEXT.md` |

`/grelha` **complementa** todos os acima: é a **porta de entrada de alinhamento** humano↔agente
que roda à la carte, antes do planejamento começar. O `gsd-discuss-phase` é o sucessor natural
quando o trabalho já entrou numa fase GSD; o `/doubt` é o que audita depois as decisões que
saíram do grelha.

---

## Prompt-núcleo do grilling (verbatim de intenção)

> "Vou te entrevistar implacavelmente sobre cada aspecto deste plano até chegarmos a um
> entendimento compartilhado. Desço cada galho da árvore de decisão, resolvendo as
> dependências entre decisões uma a uma. Para **cada pergunta, ofereço minha resposta
> recomendada**. Faço **uma pergunta por vez** e espero sua resposta antes de seguir. **Se a
> pergunta pode ser respondida explorando o código, eu exploro o código em vez de perguntar.**"

Este é o coração da skill. Tudo abaixo (modos, glossário, ADR) são camadas sobre este núcleo.

---

## Modos

### `--docs` (DEFAULT quando há projeto de código)
Liga os efeitos colaterais sobre o domínio. Durante o grilling você:

- **a. Consciência de domínio** — na exploração, procura `CONTEXT.md` (raiz) ou
  `CONTEXT-MAP.md` (multi-contexto) e `docs/decisions/` (ADRs). Em produto que usa `/spec`,
  lê também o `specs/<cap>/spec.md` relevante.
- **b. Desafia contra o glossário** — termo que conflita com o `CONTEXT.md` → interrompe na
  hora: *"Seu glossário define 'cancelamento' como X, mas você parece querer dizer Y — qual é?"*
- **c. Afia linguagem vaga** — termo sobrecarregado → propõe o termo canônico: *"Você disse
  'conta' — é o Cliente ou o Usuário? São coisas diferentes."*
- **d. Cenários concretos** — inventa edge cases para forçar fronteiras entre conceitos e te
  obrigar a ser preciso sobre os limites.
- **e. Cruza com o código** — afirmação que o código contradiz → faz surface do conflito:
  *"Seu código cancela o Pedido inteiro, mas você disse que cancelamento parcial é possível
  — qual está certo?"*
- **f. Efeitos colaterais INLINE** — ao resolver um termo, atualiza o `CONTEXT.md` **na hora**
  (formato em `CONTEXT-FORMAT.md`; não acumular em lote). Ao cristalizar uma decisão
  irreversível, **oferece um ADR** — sob o gate dos 3 critérios detalhado adiante.

### `--rapido` (= grill-me cru)
Só o prompt-núcleo, **sem nenhum efeito em arquivo**. Serve para o **não-código**: decisão de
negócio, definição de escopo, nome de produto, posicionamento. Aqui o valor é o pensamento
afiado pela entrevista — não há glossário nem ADR para atualizar.

---

## Como lê artefatos existentes (criação preguiçosa)

Ordem de leitura na exploração (caminhos reais no projeto-alvo):

1. `CONTEXT.md` (raiz) ou `CONTEXT-MAP.md` (multi-contexto) — o **glossário** de linguagem ubíqua
2. `docs/decisions/*.md` — os **ADRs** já registrados (para **não re-litigar** o que já foi decidido)
3. `specs/<cap>/spec.md` — o **contrato de comportamento**, se o produto usa `/spec`
4. **código relevante** — quando a pergunta é respondível por exploração

**Criação preguiçosa:** o `CONTEXT.md` nasce **só quando o 1º termo é resolvido**. Não criar
arquivo vazio em antecipação. Idem para `docs/decisions/` (nasce com o 1º ADR). Ver
`CONTEXT-FORMAT.md` para o formato exato e single vs multi-context.

---

## Gate do ADR (oferecer com parcimônia)

Só **oferecer** registrar um ADR quando os **três** critérios forem verdadeiros:

1. **Difícil de reverter** — o custo de mudar de ideia depois é relevante;
2. **Surpreendente sem contexto** — um leitor futuro perguntaria "por que fizeram assim?";
3. **Resultado de um trade-off real** — havia alternativas genuínas e uma foi escolhida por motivos específicos.

Faltando qualquer um dos três → **pular** silenciosamente o ADR (não oferecer). Os ADRs vivem em
`docs/decisions/` (reuso do diretório existente). O formato canônico do ADR inline está em
**`ADR-FORMAT.md`** (mesma pasta desta skill): gate dos 3 critérios, formato mínimo (título +
1-3 frases), seções opcionais e numeração `NNNN-slug.md` com criação preguiçosa.

Comportamento no passo "efeitos colaterais inline" do modo `--docs`: quando os **3 critérios** de
`ADR-FORMAT.md` passam, `/grelha` **oferece** (não impõe) registrar a decisão e, ao aceitar,
escreve em `docs/decisions/NNNN-slug.md` no formato mínimo. Quando **qualquer** critério falha,
`/grelha` **pula** o ADR sem ruído. O espelhamento ao Obsidian não é feito aqui — fica a cargo do
`/extract-learnings` (Passo 4c), sem pipeline novo.

---

## Fronteira `/grelha × gsd-discuss-phase × /doubt`

Espelha a nota `/spec × GSD` de `source/rules/common/delta-spec.md`.

| Eixo | /grelha | gsd-discuss-phase | /doubt |
|------|---------|-------------------|--------|
| **Quando** | ANTES do plano (à la carte; código e não-código) | DENTRO de uma fase GSD já aberta | DEPOIS de decidir, antes de a decisão valer |
| **Postura** | colaborativa — COM o humano | colaborativa, em-lote | adversarial — CONTRA o artefato |
| **Granularidade** | pergunta-a-pergunta na árvore de decisão | bloco de perguntas da fase | por decisão não-trivial |
| **Saída durável** | alinhamento + `CONTEXT.md` + (gate) ADR | `{phase}-CONTEXT.md` (decisões da fase) | nenhuma (é cross-exame) |
| **Carrega** | mattpocock/skills (MIT) | GSD | agent-skills (MIT) |

Regra prática: alinhar antes de planejar → `/grelha`. Já estou numa fase GSD e preciso fechar
decisões dela → `gsd-discuss-phase`. Já decidi e quero refutar antes de valer → `/doubt`.

---

## Interação com outras skills/rules

- **`/doubt`** — audita adversarialmente as decisões que saem do grelha, antes de valerem.
  Sequência natural: `/grelha` (alinha) → decisão → `/doubt` (refuta) → executa.
- **`/spec`** — **consome** o vocabulário canônico do glossário: requisitos e cenários da spec
  DEVEM usar os termos do `CONTEXT.md`. O glossário é pré-requisito de um bom `/spec`, não o substitui.
- **`/extract-learnings`** — ADRs que `/grelha` grava em `docs/decisions/` são espelhados ao vault
  Obsidian (`Decisions/`) pelo **Passo 4c** do `/extract-learnings` — sem pipeline novo no `/grelha`.
- **`gsd-discuss-phase`** — sucessor natural quando o trabalho entra numa fase GSD; o `/grelha`
  alinha antes de a fase existir.
- **`/context-engineering`** — o grelha **alimenta** o que vai para o contexto (glossário, ADRs,
  alinhamento); a engenharia de contexto cura essa entrada.
- **`operating-discipline`** — *Surface Assumptions* e *Manage Confusion Actively* são o **piso**
  do grilling: cada pergunta materializa uma suposição e nomeia uma confusão antes que vire dívida.
- **`ubiquitous-language`** (rule) — ancora o `CONTEXT.md` como glossário-only e distingue os três
  "CONTEXT" (ver `source/rules/common/ubiquitous-language.md`).

---

## Tabela anti-racionalização

| Racionalização | Realidade |
|---|---|
| "Já sei exatamente o que quero, pulo o grilling" | "Ninguém sabe exatamente o que quer" (Thomas & Hunt, _The Pragmatic Programmer_) — e, na prática, raramente antes de ser pressionado a explicar. O grilling barato agora evita o retrabalho caro depois. |
| "É mais rápido só começar a codar" | Direção errada custa o plano inteiro. Alinhar 5 perguntas agora é mais barato que refazer um PR depois. |
| "Faço todas as perguntas de uma vez, ganho tempo" | Despejar questionário quebra a árvore de decisão — cada resposta muda a próxima pergunta. 1 por vez **é** o método. |
| "Pergunto pro humano como o código funciona" | Se dá pra ler no código, leia. Perguntar o que é explorável queima o orçamento de atenção do humano. |
| "Anoto a decisão no CONTEXT.md" | `CONTEXT.md` é glossário, não repositório de decisões. Decisão irreversível → ADR; comportamento contratado → `/spec`. |
| "Isso é igual ao gsd-discuss-phase" | Não: aquele é GSD-bound e em-lote, DENTRO de uma fase. `/grelha` roda antes de qualquer fase existir, à la carte, e também serve não-código. |
| "Crio o CONTEXT.md já no começo pra não esquecer" | Criação preguiçosa: o arquivo nasce com o 1º termo resolvido. Arquivo vazio em antecipação é ruído. |
| "Registro um ADR pra cada decisão" | ADR só com os 3 critérios (difícil reverter + surpreendente + trade-off real). Os demais são glossário ou nada. |

## Red flags

- Despejar um questionário inteiro em vez de **1 pergunta por vez**
- Perguntar ao humano o que dava para **ler no código**
- Fazer uma pergunta **sem oferecer a resposta recomendada**
- Tratar o `CONTEXT.md` como spec/scratch pad/repositório de decisões (viola o glossário-only)
- Acumular atualizações de glossário **em lote** em vez de inline ao resolver o termo
- Oferecer ADR sem que os **3 critérios** estejam satisfeitos
- Criar `CONTEXT.md` vazio em antecipação (quebra a criação preguiçosa)
- Re-litigar uma decisão **já registrada** em `docs/decisions/` em vez de ler o ADR
- Rodar `--docs` num contexto não-código (escreve glossário onde não cabe → use `--rapido`)
- Virar adversarial ("encontre o que está errado") — isso é `/doubt`, não `/grelha`

## Verificação

- [ ] O grilling foi conduzido **1 pergunta por vez**, esperando a resposta antes da próxima
- [ ] **Cada** pergunta veio com a **resposta recomendada**
- [ ] Perguntas respondíveis por exploração foram **respondidas lendo o código**, não perguntando
- [ ] Modo escolhido condiz com o contexto: `--docs` em código · `--rapido` em não-código
- [ ] (`--docs`) Glossário lido na ordem: `CONTEXT.md`/`CONTEXT-MAP.md` → `docs/decisions/` → `specs/` → código
- [ ] (`--docs`) Termo resolvido foi gravado **inline** no `CONTEXT.md` no formato de `CONTEXT-FORMAT.md`
- [ ] (`--docs`) `CONTEXT.md` permaneceu **glossário-only** (zero implementação/decisão/spec)
- [ ] (`--docs`) `CONTEXT.md` criado **preguiçosamente** (só ao resolver o 1º termo)
- [ ] ADR só foi **oferecido** quando os 3 critérios (reverter/surpreendente/trade-off) eram verdadeiros
- [ ] Nenhuma decisão já registrada em `docs/decisions/` foi re-litigada
