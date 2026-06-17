---
name: improve-architecture
description: "Ritual RECORRENTE de saúde de design — acha oportunidades de deepening (módulo raso → profundo) numa codebase, informado pelo glossário do domínio (CONTEXT.md) e pelas decisões já registradas (docs/decisions/). Ative quando o usuário disser: '/improve-architecture', '/aprofundar', 'melhorar arquitetura', 'achar refactor', 'oportunidades de refatoração', 'módulos profundos', 'deepening', 'consolidar acoplamento', 'esse módulo está raso', 'deixar mais testável', 'deixar mais navegável por IA', 'revisão de arquitetura', ou periodicamente ao fim de um ciclo de feature. DISTINTO de refactor-cleaner (agente single-shot que remove código morto), code-simplifier (agente single-shot que simplifica um trecho) e /doubt (audita adversarialmente UMA decisão pronta): aqui é DESIGN de arquitetura, recorrente, com fluxo próprio (explorar → relatório HTML → grilling). Reusa CONTEXT.md (/grelha) e ADR inline (ADR-FORMAT.md) no grilling loop. Absorvido de mattpocock/skills (MIT). PT-BR."
---

# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9
# Postura: ver docs/decisions/v9-mattpocock-skills-absorcao.md — absorvemos a técnica, não a ideologia anti-framework; sob orquestração da Deia.

# Skill: /improve-architecture — Ritual de Deepening (alias `/aprofundar`)

**Idioma:** Português brasileiro.

> Quase todo módulo nasce raso e fica raso por inércia: mais wrappers, mais indireção, mais saltos
> entre arquivinhos para entender um conceito só. `/improve-architecture` é o **ritual recorrente** de
> trazer à tona a **fricção arquitetural** e propor **oportunidades de deepening** — refactors que
> transformam módulos rasos em profundos (muito comportamento atrás de uma interface pequena). O alvo
> é **testabilidade** e **navegabilidade por IA**. Onde os agentes `refactor-cleaner` e
> `code-simplifier` fazem limpeza pontual single-shot, esta skill avalia o *design* — e roda de novo
> a cada poucos dias.

## Como invocar

| Gatilho | Exemplo |
|---------|---------|
| Comando slash | `/improve-architecture` · alias `/aprofundar` |
| Pela Deia | `Deia, acha oportunidades de deepening no módulo de pedidos` |
| Linguagem natural | `melhorar arquitetura` · `esse módulo está raso` · `deixar mais testável` · `revisão de arquitetura` |

**Ritual RECORRENTE.** A recomendação é rodar **a cada poucos dias** ou ao fim de um ciclo de feature —
não uma única vez. A codebase deriva para a rasura continuamente; a revisão precisa acompanhar.

---

## O que é — e o que NÃO é

### O que é
Uma **revisão de arquitetura colaborativa** em 3 fases: (1) explora a codebase notando fricção e
aplica o **deletion test**; (2) apresenta candidatos num **relatório HTML** no tmp do SO (nunca no
repo); (3) cai num **grilling loop** ao escolher um candidato, reusando a disciplina do `/grelha`
(atualiza `CONTEXT.md` inline; oferece ADR sob o gate). Toda sugestão usa o **glossário de
arquitetura** ([LANGUAGE.md](LANGUAGE.md)) para a estrutura e o vocabulário do **`CONTEXT.md`** para o
domínio.

### O que NÃO é

| Confusão comum | Camada correta |
|---------------|----------------|
| Remover código morto / imports / TODOs resolvidos no fim da feature | agente `refactor-cleaner` (single-shot, remove o que sobrou) |
| Simplificar UM trecho complexo preservando comportamento | agente `code-simplifier` (single-shot, simplifica trecho) |
| Auditar adversarialmente UMA decisão pronta antes de valer | `/doubt` (cross-exame, CONTRA o artefato) |
| Alinhar um plano pergunta-a-pergunta antes de existir código | `/grelha` (grilling colaborativo pré-plano) |
| Contrato de comportamento durável (SHALL + cenários) | `/spec` (delta-spec brownfield) |
| Glossário de linguagem ubíqua | `CONTEXT.md` (mantido pelo `/grelha`) |
| Repositório de decisões | ADR (`docs/decisions/`) |

`/improve-architecture` **complementa** os dois agentes de limpeza: eles agem *no código que sobrou*
(remover/simplificar); esta skill age sobre a *forma do módulo* (raso vs profundo). A decisão de criar
uma skill nova em vez de enriquecer um agente está registrada em
`docs/decisions/deepening-skill-vs-agente.md`.

---

## Glossário (use exatamente)

Use estes termos **exatamente** em toda sugestão. Linguagem consistente é o ponto — não derive para
"componente", "serviço", "API" ou "fronteira". Definições completas em [LANGUAGE.md](LANGUAGE.md).

- **Module (Módulo)** — qualquer coisa com interface e implementação (função, classe, pacote, fatia).
- **Interface** — tudo que um chamador precisa saber para usar o módulo: tipos, invariantes, modos de
  erro, ordenação, config. Não só a assinatura de tipos.
- **Implementation (Implementação)** — o código de dentro.
- **Depth (Profundidade)** — leverage na interface: muito comportamento atrás de uma interface
  pequena. **Deep** = alta alavancagem. **Shallow** = interface quase tão complexa quanto a
  implementação.
- **Seam** — onde a interface vive; lugar onde o comportamento pode ser alterado sem editar ali
  mesmo. (Use isto, não "fronteira".)
- **Adapter** — coisa concreta que satisfaz uma interface num seam.
- **Leverage (Alavancagem)** — o que os chamadores ganham com profundidade.
- **Locality (Localidade)** — o que os mantenedores ganham com profundidade: mudança, bugs e
  conhecimento concentrados num lugar.

Princípios-chave (lista completa em [LANGUAGE.md](LANGUAGE.md)):

- **Deletion test:** imagine deletar o módulo. Se a complexidade some, era um pass-through. Se
  reaparece espalhada por N chamadores, estava ganhando o pão dele.
- **A interface é a superfície de teste.**
- **1 adapter = seam hipotético. 2 adapters = seam real.**

Esta skill é **informada** pelo modelo de domínio do projeto: o `CONTEXT.md` dá nomes aos bons seams; os
ADRs registram decisões que a skill **não deve re-litigar**.

---

## Processo (3 fases)

### Fase 1 — Explorar

**Leia ANTES de explorar o código** (mesma ordem do `/grelha --docs`):

1. `CONTEXT.md` (raiz) ou `CONTEXT-MAP.md` (multi-contexto) — o **glossário** do domínio.
2. `docs/decisions/*.md` — os **ADRs** da área que você vai tocar (para **não re-litigar** o decidido).
3. `specs/<cap>/spec.md` — o **contrato de comportamento**, se o produto usa `/spec`.

Depois, percorra a codebase. **Não siga heurísticas rígidas** — explore organicamente e anote onde
você sente **fricção**:

- Entender **um** conceito exige saltar entre **N** módulos pequenos?
- Módulos **shallow** — interface quase tão complexa quanto a implementação?
- **Pure functions** extraídas só por testabilidade, mas os bugs reais moram em como elas são chamadas
  (sem **locality**)?
- Módulos acoplados **vazando através dos seams**?
- Partes **sem teste**, ou difíceis de testar pela interface atual?

Aplique o **deletion test** a tudo que você suspeita ser raso: deletar concentraria a complexidade, ou
só a moveria? Um **"sim, concentra"** é o sinal que você quer.

### Fase 2 — Relatório HTML (no tmp, NÃO no repo)

Escreva **um arquivo HTML self-contained no diretório temporário do SO** — nada aterrissa no repo.
Resolva o tmp de `$TMPDIR`, caindo para `/tmp` (ou `%TEMP%` no Windows); grave em
`<tmpdir>/architecture-review-<timestamp>.html` (arquivo fresco por execução). Abra-o (`open` no macOS,
`xdg-open` no Linux, `start` no Windows) e informe o **caminho absoluto**.

O relatório usa **Tailwind via CDN** (layout) e **Mermaid via CDN** (diagramas em formato de grafo),
misturando com SVG/CSS à mão para visuais editoriais. **Um card por candidato**, com: **Files**,
**Problem** (1 frase), **Solution** (1 frase), **Benefits** (em termos de locality/leverage e melhoria
de testes), **Diagrama Antes/Depois** (lado a lado, ilustrando a rasura e o deepening) e **força da
recomendação** (`Forte` / `Vale explorar` / `Especulativo`, como badge). Termine com uma seção **"Top
recommendation"**: qual candidato encarar primeiro e por quê.

**Use o vocabulário do `CONTEXT.md` para o domínio e o de [LANGUAGE.md](LANGUAGE.md) para a
arquitetura.** Se `CONTEXT.md` define "Pedido", fale do "módulo de recebimento de Pedido" — não do
"FooBarHandler", nem do "serviço de Pedido".

**Conflitos com ADR:** se um candidato contradiz um ADR existente, **só** o traga à tona quando a
fricção for real o bastante para justificar reabrir o ADR; marque claro no card (callout amber:
_"contradiz o ADR `<slug>` — mas vale reabrir porque…"_). Não liste todo refactor que um ADR proíbe.

O scaffold completo, padrões de diagrama e estilo estão em [HTML-REPORT.md](HTML-REPORT.md).

**Não proponha interfaces ainda.** Depois de gravar o arquivo, pergunte ao usuário: *"Qual destes você
quer explorar?"*

### Fase 3 — Grilling loop

Quando o usuário escolhe um candidato, caia numa **conversa de grilling** (reusa a disciplina do
`/grelha`). Percorra a árvore de design com ele — restrições, dependências, a forma do módulo
aprofundado, o que fica atrás do seam, quais testes sobrevivem. **1 pergunta por vez, sempre com a
resposta recomendada**, esperando a resposta antes de seguir.

Efeitos colaterais acontecem **inline** conforme as decisões cristalizam:

- **Nomeando um módulo aprofundado com um conceito que NÃO está no `CONTEXT.md`?** Adicione o termo ao
  `CONTEXT.md` na hora — mesma disciplina do `/grelha` (formato em
  `source/skills/grelha/CONTEXT-FORMAT.md`). Crie o arquivo **preguiçosamente** se não existir.
- **Afiando um termo vago durante a conversa?** Atualize o `CONTEXT.md` ali mesmo.
- **Usuário rejeita o candidato com uma razão load-bearing?** Ofereça um ADR, enquadrado como: *"Quer
  que eu registre isto como ADR para futuras revisões de arquitetura não re-sugerirem?"* — **só** quando
  a razão seria realmente necessária a um explorador futuro para evitar a re-sugestão. Pule razões
  efêmeras ("não vale a pena agora") e auto-evidentes. O gate dos 3 critérios e o formato estão em
  `source/skills/grelha/ADR-FORMAT.md`.
- **Não re-litigue ADRs existentes.** Só sinalize conflito quando a fricção justificar reabrir o ADR.

> **Sobre interfaces:** o upstream tinha um `INTERFACE-DESIGN.md` separado. Aqui o desenho da interface
> do módulo aprofundado acontece **dentro do próprio grilling loop**: explore alternativas de interface
> uma a uma na conversa, sempre nomeando depth/seam/adapter pelo glossário, antes de cristalizar.

---

## Reuso, não reinvenção

- **`CONTEXT.md`** (R9-02) — o glossário do domínio é lido na Fase 1 e atualizado inline na Fase 3,
  pela mesma disciplina do `/grelha`. A skill **não cria pipeline próprio** de glossário.
- **ADR inline** (R9-03) — os ADRs vivem em `docs/decisions/` e seguem `ADR-FORMAT.md` (gate dos 3
  critérios, formato mínimo, slug descritivo). O espelhamento ao Obsidian fica a cargo do
  `/extract-learnings` (Passo 4c) — sem pipeline novo aqui.
- **`/grelha`** — a Fase 3 é a disciplina de grilling do `/grelha` aplicada a um candidato de
  arquitetura. A diferença: o `/grelha` alinha **antes do plano existir**; aqui o grilling parte de um
  **candidato de deepening** concreto.

---

## Fronteira (vs agentes de limpeza vs /doubt)

| Eixo | /improve-architecture | refactor-cleaner | code-simplifier | /doubt |
|------|----------------------|------------------|-----------------|--------|
| **Natureza** | ritual recorrente | agente single-shot | agente single-shot | postura adversarial em-voo |
| **Alvo** | forma do módulo (raso→profundo) | código morto / imports / TODOs | um trecho complexo | uma decisão pronta |
| **Fluxo** | explorar → HTML → grilling | varre e remove | simplifica e re-testa | cross-exame de contexto fresco |
| **Saída** | relatório HTML + (grilling) CONTEXT.md/ADR | lista de remoções | diff simplificado | veredito |
| **Quando** | a cada poucos dias | fim de feature, antes do merge | função ficou difícil de ler | antes de a decisão valer |

Regra prática: *forma do módulo, recorrente* → `/improve-architecture`. *Remover o que sobrou* →
`refactor-cleaner`. *Simplificar um trecho* → `code-simplifier`. *Refutar uma decisão* → `/doubt`.

---

## Tabela anti-racionalização

| Racionalização | Realidade |
|---|---|
| "Já limpei o código morto, a arquitetura está boa" | Remover morto não aprofunda módulo raso. `refactor-cleaner` é limpeza pontual; deepening é design — eixos diferentes. |
| "Rodo uma vez e está resolvido" | É **ritual recorrente**. A codebase deriva para a rasura continuamente; rode a cada poucos dias. |
| "Gravo o relatório HTML no repo pra versionar" | NÃO. O relatório vai no **tmp do SO** — é efêmero, por execução. Sujar o repo com HTML de revisão é ruído. |
| "Proponho a interface nova já no relatório" | Não na Fase 2. Interfaces se desenham no **grilling loop** (Fase 3), com o humano, uma alternativa por vez. |
| "Esse candidato contradiz um ADR, mas vou sugerir mesmo assim" | Só reabra um ADR quando a fricção for real. Re-litigar o decidido queima atenção e desrespeita a decisão registrada. |
| "Anoto o módulo novo no relatório e sigo" | Nomeou um módulo com conceito fora do `CONTEXT.md`? Atualize o `CONTEXT.md` **inline**, na hora — não em lote. |
| "Chamo de componente/serviço, dá no mesmo" | Não dá. O glossário é o ponto: module/interface/seam/depth, exatamente. Derivar de vocabulário esvazia a análise. |
| "Extraí pure functions, logo está testável" | Testabilidade sem **locality** é ilusão: se os bugs moram em como são chamadas, a interface está na forma errada. |
| "Esse módulo é deep porque a implementação é grande" | Profundidade é **leverage na interface**, não tamanho da implementação. Implementação inflada não é profundidade. |

## Red flags

- Gravar o relatório HTML **no repo** em vez do tmp do SO
- Explorar o código **antes** de ler `CONTEXT.md` e os ADRs da área
- Propor interfaces **na Fase 2** em vez de no grilling loop
- Derivar do glossário ("componente", "serviço", "fronteira") em vez de module/seam/depth
- Sugerir um candidato que **contradiz um ADR** sem fricção real que justifique reabri-lo
- Acumular atualizações de `CONTEXT.md` **em lote** em vez de inline ao nomear o módulo
- Oferecer ADR sem que os **3 critérios** (reverter/surpreendente/trade-off) estejam satisfeitos
- Tratar como limpeza single-shot (isso é `refactor-cleaner`/`code-simplifier`)
- Rodar **uma vez** e considerar encerrado (é ritual recorrente)
- Despejar um questionário no grilling em vez de **1 pergunta por vez** com resposta recomendada

## Verificação (R8-04 — gates binários, não confie no Read)

- [ ] Fase 1 leu na ordem: `CONTEXT.md`/`CONTEXT-MAP.md` → `docs/decisions/` → `specs/` → código
- [ ] O **deletion test** foi aplicado a cada candidato suspeito de ser raso
- [ ] O relatório HTML foi gravado no **tmp do SO** (não no repo) e verificado com `test -s <path>`
- [ ] O relatório tem **≥1 candidato** com Files/Problem/Solution/Benefits/Antes-Depois/força + "Top recommendation"
- [ ] O domínio usou o vocabulário do `CONTEXT.md`; a estrutura usou o de [LANGUAGE.md](LANGUAGE.md)
- [ ] Nenhum ADR de `docs/decisions/` foi **re-litigado** (conflito só sinalizado com fricção real)
- [ ] No grilling: módulo novo nomeado → `CONTEXT.md` atualizado **inline** (formato `CONTEXT-FORMAT.md`)
- [ ] ADR só **oferecido** quando os 3 critérios de `ADR-FORMAT.md` passam, com slug descritivo
- [ ] Grilling conduzido **1 pergunta por vez**, cada uma com a **resposta recomendada**
