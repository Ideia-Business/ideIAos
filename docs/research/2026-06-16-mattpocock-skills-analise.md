# Análise comparativa — `mattpocock/skills` × IdeiaOS + proposta de integração

> **Tipo:** pesquisa / proposta de integração (não-vinculante até virar milestone)
> **Data:** 2026-06-16 · **Autor da análise:** perito IdeiaOS (sessão Cursor)
> **Foco do pedido:** `/grill-with-docs` — sessão de *grilling* (alinhar ANTES de planejar) + linguagem compartilhada (`CONTEXT.md`) + ADRs.
> **Escopo:** somente leitura + criação deste relatório. Nenhum commit, nenhuma skill alterada.

## Fontes lidas

**Repo externo `mattpocock/skills`** (MIT, ~132k ⭐, autor Matt Pocock — "Skills For Real Engineers", skills.sh):

- `https://github.com/mattpocock/skills` (README/landing)
- `https://raw.githubusercontent.com/mattpocock/skills/main/README.md` (filosofia — 4 failure modes)
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/SKILL.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/grill-with-docs/ADR-FORMAT.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/productivity/grill-me/SKILL.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/diagnose/SKILL.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/to-prd/SKILL.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/improve-codebase-architecture/SKILL.md`
- `https://raw.githubusercontent.com/mattpocock/skills/main/skills/engineering/setup-matt-pocock-skills/SKILL.md`
- Árvore completa de skills via GitHub API (`/repos/mattpocock/skills/git/trees/main?recursive=1`)

**IdeiaOS local** (`/Users/gustavolopespaiva/dev/IdeiaOS`):

- `docs/IDEIAOS.md` (especificação canônica — 5 camadas)
- `source/skills/idea/SKILL.md` (orquestrador Deia + matriz de roteamento)
- `source/skills/spec/SKILL.md` + `source/rules/common/delta-spec.md` (delta-spec brownfield)
- `source/skills/doubt/SKILL.md` (doubt-driven, absorvido de addyosmani/agent-skills em v8)
- `source/skills/context-engineering/SKILL.md`
- `source/skills/forge-agent/SKILL.md`
- `source/rules/common/operating-discipline.md`, lista de `source/rules/common/*.md`
- `~/.claude/skills/gsd-discuss-phase/SKILL.md` (questionamento pré-plano do GSD)
- `manifests/modules.json` (catálogo + campo `plugin`), `scripts/build-plugins.sh`, `scripts/build-adapters.sh`
- `security/quarantine/` (padrão de absorção v8 — pasta `agent-skills/`)
- `STATE.md` (v2.0–v8 todos SHIPPED)

**Domínio real** (`/Users/gustavolopespaiva/dev/nfideia`, branch `spec/multi-tenancy-pilot`):

- `specs/multi-tenancy/spec.md`, `specs/cofre-digital/spec.md` (jargão real usado na seção 6)

---

## 1. Sumário executivo

- **O que é o repo:** uma coleção de ~25 skills pequenas, "componíveis e hackáveis", explicitamente posicionada como **alternativa anti-framework** a GSD/BMAD/Spec-Kit ("eles tomam conta do processo e te tiram o controle"). O valor não está na infraestrutura (não tem) — está na **destilação de fundamentos de engenharia** (Pragmatic Programmer, DDD/Evans, Kent Beck, Ousterhout) em rituais repetíveis.
- **A joia da coroa é `/grill-with-docs`:** uma entrevista implacável (uma pergunta por vez, descendo a árvore de decisão) que roda **ANTES** de planejar, e que materializa dois artefatos duráveis: um **glossário de linguagem ubíqua** (`CONTEXT.md`, só termos — zero implementação) e **ADRs ultraleves** (1–3 frases). Isso ataca os dois maiores failure modes ("o agente não fez o que eu quero" + "o agente é verboso demais").
- **3 GAPs reais que o IdeiaOS NÃO cobre hoje** (detalhe nas seções 3–4): (1) glossário de **linguagem ubíqua durável e project-wide**; (2) ritual de **grilling colaborativo pré-planejamento desacoplado de fase GSD** (serve até para não-código); (3) ritual recorrente de **"deepening" arquitetural** (módulos profundos de Ousterhout) informado por glossário + ADRs.
- **Maior parte das skills de engenharia: JÁ TEMOS equivalente igual ou melhor.** `diagnose` ≈ `/gsd-debug` (nosso é mais robusto: state-machine + estado persistente). `tdd` ≈ nossa `/tdd`. `handoff` ≈ `context-packet-handoffs` + `/cursor-continuation` + `precompact-state-save`. `zoom-out`/`prototype`/`write-a-skill` ≈ `/code-tour`+`code-explorer` / `gsd-sketch`+`gsd-spike` / `skill-creator`+`forge-agent`.
- **Recomendação de alto nível:** **ADOTAR** o delta de grilling+linguagem ubíqua numa skill nova `/grelha` (alias `/grill`), criando um artefato de projeto `CONTEXT.md` (glossário) que hoje não existe; **ADAPTAR** `improve-codebase-architecture` como ritual de saúde de design; **IGNORAR** o resto (já temos, ou é nicho dos cursos do Matt: `to-issues`/`triage`/`migrate-to-shoehorn`/`scaffold-exercises`).
- **Sobre a tensão filosófica anti-framework:** ela é real só no nível do *posicionamento*, não no das *técnicas*. Adotamos as **técnicas** (grilling, linguagem ubíqua, módulos profundos) como skills que a **Deia orquestra** — exatamente o que o IdeiaOS faz: pegar boas peças soltas e governá-las. NÃO adotamos a postura "frameworks são ruins". Onde o Matt tem razão (frameworks rodam soltos e perdem o humano de vista), nossa mitigação já existe ("comando direto é caminho válido" + gates) e o grilling a reforça como porta de entrada de alinhamento.
- **Esforço estimado:** 1 milestone pequeno (**v9 — "Camada de Alinhamento"**), ~2–3 skills + 1 rule + atualização de matriz da Deia + manifesto/README. Baixo risco (aditivo, não mexe em GSD/AIOX).
- **Precedente direto:** isso replica o padrão **v8** (absorção seletiva de `addyosmani/agent-skills` → só o "delta de disciplina" `/doubt` + `operating-discipline`, mantendo GSD/AIOX intactos). Mesmo fluxo de quarentena → análise → absorver delta → propagar.

---

## 2. Análise do repo `mattpocock/skills`

### 2.1 Filosofia declarada (os 4 failure modes)

O README estrutura tudo em torno de 4 modos de falha de quem programa com agentes, cada um com citação de um clássico:

| # | Failure mode | Citação âncora | Fix proposto |
|---|--------------|----------------|--------------|
| 1 | "O agente não fez o que eu quero" (misalignment) | *Pragmatic Programmer* — "ninguém sabe exatamente o que quer" | **grilling** (`/grill-me`, `/grill-with-docs`) ANTES de construir |
| 2 | "O agente é verboso demais" | Eric Evans, *DDD* — linguagem ubíqua | **linguagem compartilhada** (`CONTEXT.md`) |
| 3 | "O código não funciona" | *Pragmatic Programmer* — passos pequenos, feedback é o limite de velocidade | **feedback loops** (tipos, browser, `/tdd`, `/diagnose`) |
| 4 | "Viramos uma bola de lama" | Kent Beck (investir no design todo dia) + Ousterhout (módulos profundos) | **cuidar do design diariamente** (`/zoom-out`, `/improve-codebase-architecture`) |

A tese anti-framework está na intro do README, literal: *"Approaches like GSD, BMAD, and Spec-Kit try to help by owning the process. But while doing so, they take away your control and make bugs in the process hard to resolve. These skills are designed to be small, easy to adapt, and composable."* É uma aposta deliberada em **skills à la carte** em vez de pipeline governado.

### 2.2 Mecânica de `/grill-with-docs` (a skill central)

O corpo da skill é curtíssimo (o poder está na disciplina, não no código). Mecânica real:

**Prompt-núcleo (idêntico ao `/grill-me`):**
> "Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer. **Ask the questions one at a time, waiting for feedback on each.** **If a question can be answered by exploring the codebase, explore the codebase instead.**"

Quatro propriedades que definem o comportamento:
1. **Uma pergunta por vez** (não despeja questionário) — força a árvore de decisão a se resolver galho a galho, com dependências entre decisões.
2. **Cada pergunta vem com a resposta recomendada** do agente (o humano corrige, não preenche do zero).
3. **Se dá pra responder lendo o código, leia o código** (não pergunta o que pode descobrir).
4. **Efeitos colaterais inline, durante a conversa** (não no fim).

**O que `/grill-with-docs` adiciona sobre o `/grill-me` — os "goodies":**

- **Consciência de domínio:** durante a exploração, procura `CONTEXT.md` (contexto único) ou `CONTEXT-MAP.md` (multi-contexto, tipo monorepo) na raiz, e `docs/adr/`.
- **Desafia contra o glossário:** se o usuário usa um termo que conflita com o `CONTEXT.md`, interrompe na hora — *"seu glossário define 'cancellation' como X, mas você parece querer Y — qual é?"*
- **Afia linguagem vaga:** termo sobrecarregado → propõe um termo canônico — *"você diz 'account' — é o Customer ou o User? São coisas diferentes."*
- **Cenários concretos:** inventa edge cases para forçar o usuário a precisar fronteiras entre conceitos.
- **Cruza com o código:** se o usuário afirma algo que o código contradiz, surface o conflito.

**O que vira `CONTEXT.md` (regra de ouro: glossário e NADA MAIS):**

- Formato: `# {Contexto}` + descrição de 1–2 frases + seção `## Language` com entradas `**Termo**: definição de 1–2 frases` + `_Avoid_: sinônimos a evitar`.
- **Regras duras:** (a) **opinativo** — escolhe a melhor palavra e lista as outras em `_Avoid_`; (b) definição **tight** (o que a coisa É, não o que faz); (c) **só termos específicos do domínio** — conceitos gerais de programação (timeout, error types) NÃO entram; (d) `CONTEXT.md` é **totalmente livre de detalhes de implementação** — não é spec, não é scratch pad, não é repositório de decisões. É glossário.
- Multi-contexto: `CONTEXT-MAP.md` lista contextos, onde vivem, e relações (ex: "Ordering → Fulfillment: emite `OrderPlaced`").
- **Criação preguiçosa:** o arquivo só nasce quando o **primeiro termo** é resolvido.

**O que vira ADR (`docs/adr/NNNN-slug.md`), oferecido com parcimônia:**

- Só oferece ADR quando os **três** são verdadeiros: (1) **difícil de reverter**; (2) **surpreendente sem contexto** (futuro leitor pergunta "por que fizeram assim?"); (3) **resultado de um trade-off real** (havia alternativas).
- Formato mínimo: título + 1–3 frases (contexto, decisão, porquê). Seções opcionais (Status/Options/Consequences) só quando agregam. "Um ADR pode ser um único parágrafo."
- Numeração sequencial, criação preguiçosa do diretório.

**Insight-chave:** `/grill-with-docs` separa explicitamente **três tipos de conhecimento durável** que o IdeiaOS hoje mistura ou não tem: glossário (`CONTEXT.md` = vocabulário), decisões (`docs/adr/` = porquês irreversíveis) e contrato de comportamento (que no IdeiaOS é o `/spec`). Essa tripartição é o que torna a técnica poderosa.

### 2.3 Demais skills relevantes (mecânica resumida)

- **`/grill-me`** — o grilling cru, sem docs. Uso não-código também. É o "MVP" do grill-with-docs.
- **`/diagnose`** — loop de 6 fases: **(1) construir um feedback loop** (o coração — teste falhando / curl / harness / bisection / fuzz / differential), (2) reproduzir, (3) **3–5 hipóteses falsificáveis ranqueadas** antes de testar, (4) instrumentar uma variável por vez com logs taggeados `[DEBUG-xxxx]`, (5) fix + regression test no seam correto (e "se não há seam correto, isso é o achado"), (6) cleanup + post-mortem ("o que teria prevenido?" → handoff pro `improve-codebase-architecture`).
- **`/to-prd`** — **NÃO entrevista**; sintetiza o que já foi discutido em PRD (Problem/Solution/User Stories longas/Implementation Decisions/Testing Decisions/Out of Scope) e publica como issue com label `ready-for-agent`. Detalhe interessante: faz o usuário **mapear os seams** onde vai testar antes de escrever.
- **`/improve-codebase-architecture`** — busca **"deepening opportunities"** (Ousterhout: módulo profundo = muito comportamento atrás de interface simples). Glossário próprio fixo (Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality) + **deletion test** ("se eu deletar isso, a complexidade some ou reaparece em N callers?"). Output: **relatório HTML** no tmp (Tailwind+Mermaid, before/after) → usuário escolhe candidato → cai num **grilling loop** com efeitos colaterais inline (atualiza `CONTEXT.md`, oferece ADR). Recomenda rodar "a cada poucos dias".
- **`/setup-matt-pocock-skills`** — scaffolding per-repo (`disable-model-invocation: true`): configura issue tracker (GitHub/GitLab/Linear/markdown local), vocabulário de 5 labels de triagem, e layout de docs de domínio (single vs multi-context). Escreve um bloco `## Agent skills` no `CLAUDE.md`/`AGENTS.md` + `docs/agents/*.md`. É o "ideiaos-setup" dele, em miniatura.
- **Produtividade:** `caveman` (modo comunicação ultracomprimida, −75% tokens), `handoff` (compacta conversa em doc pra outro agente), `teach` (ensina em múltiplas sessões), `write-a-skill`.
- **Misc (nicho):** `git-guardrails-claude-code`, `setup-pre-commit`, `migrate-to-shoehorn` (total-typescript), `scaffold-exercises` (cursos do Matt), `triage`/`to-issues` (workflow GitHub Issues).

---

## 3. Comparativo lado a lado — IdeiaOS × `mattpocock/skills`

Veredito: **JÁ TEMOS** (equivalente igual/melhor) · **ADOTAR** (gap real, absorver) · **ADAPTAR** (absorver só um delta sobre algo nosso) · **IGNORAR** (nicho / fora do escopo / conflita).

| Skill (Pocock) | Equivalente no IdeiaOS | Veredito | Porquê (1 linha) |
|----------------|------------------------|----------|------------------|
| **grill-with-docs** | parcial: `gsd-discuss-phase` (questiona) + `/doubt` (adversarial) + `/spec` (contrato) | **ADOTAR** | Ninguém nosso faz grilling colaborativo *pré-plano, desacoplado de fase* + glossário ubíquo durável. É o delta principal. |
| **grill-me** | parcial: `gsd-discuss-phase` | **ADOTAR** (como modo "leve" do `/grelha`) | Versão sem-docs do grilling; serve até para não-código. Vira o modo base da skill nova. |
| **CONTEXT.md (linguagem ubíqua)** | **nada** (GSD tem `{phase}-CONTEXT.md` = decisões efêmeras; `/spec` = contrato, não glossário) | **ADOTAR** | Glossário durável project-wide é GAP real. Maior valor isolado do repo. |
| **docs/adr/ (ADR ultraleve inline)** | parcial: `docs/decisions/` (citado em `/extract-learnings`) | **ADAPTAR** | Temos ADRs, mas não a captura *inline durante grilling* com gate dos 3 critérios. Absorver o gate. |
| **diagnose** | `/gsd-debug` (state-machine + estado persistente entre resets) | **JÁ TEMOS** (melhor) | Nosso debug é mais robusto; vale absorver 1 ideia: "se não há seam correto, isso É o achado". |
| **tdd** | `/tdd` (RED→GREEN→REFACTOR, fatia vertical) | **JÁ TEMOS** | Praticamente idêntica; a nossa já cita os mesmos princípios. |
| **to-prd** | `@pm`/Morgan (PRD) + `/spec` (contrato) | **JÁ TEMOS** (adaptar 1 detalhe) | Temos PRD via persona. Absorver o "sintetiza, não entrevista" + quiz de seams/módulos. |
| **to-issues** | `@po`/Pax + `@sm`/River (stories) ; GSD usa `.planning/phases` | **IGNORAR** | IdeiaOS planeja por fases/stories, não por GitHub Issues. Fora do nosso modelo de execução. |
| **triage** | — (state-machine de labels GitHub) | **IGNORAR** | Workflow de manutenção de repo OSS; não é dor do IdeiaOS hoje. |
| **improve-codebase-architecture** | parcial: agents `code-simplifier`, `refactor-cleaner`; skill `/code-tour` | **ADAPTAR** | Temos limpeza pontual, mas não o **ritual recorrente de "deepening"** (Ousterhout) informado por glossário+ADR. GAP de saúde de design. |
| **zoom-out** | `code-explorer` (haiku) + `/codebase-onboarding` + `/code-tour` | **JÁ TEMOS** | Cobertura igual ou superior (3 ferramentas para o mesmo fim). |
| **prototype** | `gsd-sketch` (UI throwaway HTML) + `gsd-spike` (experiencial) | **JÁ TEMOS** | GSD já tem protótipo descartável e spike. |
| **handoff** | `context-packet-handoffs.md` + `/cursor-continuation` + `precompact-state-save` + `CONTINUATION_HANDOFF.md` | **JÁ TEMOS** (melhor) | Handoff cross-IDE/cross-session já é uma camada inteira (Continuation). |
| **caveman** | parcial: `token-economy.md` (routing/MCP→CLI, não estilo de comms) | **IGNORAR** (could-have) | Modo de comunicação comprimida; baixo valor governado, alto risco de perder PT-BR/clareza. |
| **teach** | — | **IGNORAR** | Caso de uso educacional (cursos), não desenvolvimento de produto. |
| **write-a-skill** | `skill-creator` + `/forge-agent` (fundamenta em pesquisa) | **JÁ TEMOS** (melhor) | `/forge-agent` exige pesquisa com fontes; mais rigoroso. |
| **setup-matt-pocock-skills** | `/ideiaos-setup` + `@ideiaos-checker` + `scripts/build-adapters.sh` | **JÁ TEMOS** | Nosso setup é idempotente e multi-harness. Absorver só o conceito de "consumer rules de docs de domínio". |
| **git-guardrails-claude-code** | hooks de git (git-autosync protege `main`; só pull, nunca auto-push em main) | **JÁ TEMOS** | Já temos guardrails de git equivalentes. |
| **setup-pre-commit** | pre-commit hooks (README-sync gate, etc.) | **JÁ TEMOS** | Já temos pre-commit ativo (barreira ativa). |
| **migrate-to-shoehorn / scaffold-exercises** | — | **IGNORAR** | Nicho dos produtos/cursos do Matt (total-typescript). Irrelevante. |

**Leitura da tabela:** das ~20 skills, **3 são gaps reais** (grill-with-docs, CONTEXT.md/linguagem ubíqua, improve-codebase-architecture), **2 são deltas finos** sobre coisas nossas (ADR inline, to-prd "sintetiza"), e o **resto já temos igual ou melhor**, ou é nicho. Isso é consistente com a v8 (de `addyosmani/agent-skills` absorvemos só `/doubt` + disciplina, e ignoramos o resto).

---

## 4. Onde `/grill-with-docs` encaixa no IdeiaOS — a análise central

### 4.1 O que cada peça nossa faz, e por que NENHUMA cobre o grilling

| Peça IdeiaOS | Quando roda | Postura | Artefato | Por que ≠ grill-with-docs |
|--------------|-------------|---------|----------|----------------------------|
| `gsd-discuss-phase` | dentro de uma **fase GSD**, antes do `plan-phase` | colaborativa, mas **em lote** ("escolha quais gray areas discutir") | `{phase}-CONTEXT.md` = **decisões** da fase (efêmero, arquivado no milestone) | Acoplado ao GSD; pergunta em lote, não galho-a-galho; o "CONTEXT.md" dele é decisões, não glossário; não serve para não-código. |
| `/doubt` | **depois** de uma decisão não-trivial, antes de valer | **adversarial** ("ache o que está ERRADO"), spawna revisor de contexto fresco | (nenhum durável — é cross-exame) | `/doubt` refuta um artefato pronto; grilling **alinha com o humano ANTES** de existir artefato. São opostos complementares. |
| `/context-engineering` | montagem de contexto da sessão | curadoria (o que carregar) | — | Decide *o que o agente vê*; não extrai o que está na cabeça do humano nem cria glossário. |
| `/spec` (delta-spec) | registrar/mudar **comportamento** durável | contrato (SHALL/DEVE + cenários) | `specs/<cap>/spec.md` | É o **contrato de comportamento**, não o **vocabulário**. Glossário é pré-requisito do `/spec`, não o `/spec`. |
| `@pm`/`@analyst`/`@architect` (AIOX) | trabalho story-driven | personas formais | PRD/epic/ADR arquitetural | Pesadas (governança/stories); grilling é leve, conversacional, à la carte, e independe de persona. |

**Conclusão:** existe um buraco claro — **alinhamento colaborativo, leve, galho-a-galho, ANTES de qualquer plano, com dois subprodutos duráveis (glossário ubíquo + ADR mínimo)**. `gsd-discuss-phase` é o mais próximo, mas é GSD-bound, em-lote, e seu "CONTEXT" é outra coisa.

### 4.2 Relação com `/doubt` — a simetria que importa

`/grelha` e `/doubt` são as **duas pontas** do mesmo eixo de qualidade de decisão:

```
        ANTES de existir artefato                DEPOIS de decidir, antes de valer
   ┌──────────────────────────────┐        ┌──────────────────────────────────┐
   │  /grelha  (grill-with-docs)   │        │  /doubt (doubt-driven)            │
   │  colaborativo · COM o humano  │  ───►  │  adversarial · CONTRA o artefato  │
   │  "o que você realmente quer?" │        │  "o que está errado nisto?"       │
   │  saída: alinhamento+glossário │        │  saída: achados classificados     │
   └──────────────────────────────┘        └──────────────────────────────────┘
```

Eles não competem: `/grelha` produz o entendimento e o vocabulário; `/doubt` audita as decisões não-triviais que saem dali. Juntos fecham o ciclo "entender certo → decidir certo".

### 4.3 Decisão: skill NOVA `/grelha` (alias `/grill`) — e por quê (não enriquecer existente)

**Proposta: criar `source/skills/grelha/` (alias `/grill`).** Justificativa (segue `operating-discipline` §3 — discordar com número):

- **Por que não enriquecer `gsd-discuss-phase`?** Isso amarraria o grilling ao GSD (upstream `@opengsd`, que nem é nosso código-fonte — é dependência fixada em `versions.lock`). Perderíamos o uso não-código e o uso "antes de escolher a camada". Acoplamento errado.
- **Por que não enriquecer `/spec`?** `/spec` é contrato de comportamento; grilling é descoberta + vocabulário. Misturar viola a tripartição (seção 2.2) que é justamente o que dá poder à técnica.
- **Por que não enriquecer `/doubt`?** Postura oposta (colaborativa × adversarial). Fundir borraria os dois.
- **Por que skill nova é barato:** segue o molde da v8 (`/doubt`, `/context-engineering` viraram skills novas em `source/skills/`, propagadas por `build-plugins`/`build-adapters`). Risco mínimo, aditivo.

**O `/grelha` absorve:**
1. O **prompt-núcleo de grilling** (`grill-me`): uma pergunta por vez, com resposta recomendada, lê código quando pode, desce a árvore de decisão.
2. O **modo "with-docs"** (`grill-with-docs`): desafia contra glossário, afia termos, cenários concretos, cruza com código.
3. Os **dois artefatos duráveis**: `CONTEXT.md` (glossário ubíquo, regras de ouro do CONTEXT-FORMAT) e ADR mínimo em `docs/decisions/` (nosso diretório existente; **não** criamos `docs/adr/` novo — reusamos o que `/extract-learnings` já espelha pro Obsidian) com o **gate dos 3 critérios**.
4. Um **modo leve** (`/grelha --rapido` ou linguagem natural "me entrevista rápido") = só o `grill-me`, sem docs, para não-código.

---

## 5. Como a Deia (`/idea`) orquestraria

Hoje a matriz da Deia (`source/skills/idea/SKILL.md`) tem um **gap de etapa**: ela classifica e roteia direto para a camada de execução (GSD/AIOX/Lovable). Não há um **portão de alinhamento** antes do roteamento. O `/grelha` entra exatamente aí, como **pré-passo opcional e disparável por risco**.

### 5.1 Fluxo proposto (passo a passo)

```
Usuário: "Deia, quero implementar <X>"
   │
   ▼
[Passo 1] Deia classifica intenção (matriz atual)
   │
   ▼
[Passo 1.5 — NOVO: gate de alinhamento]
   Deia avalia "preciso grelhar antes?" com heurística de ambiguidade/risco:
     • pedido vago ("melhorar", "deixar melhor", "resolver o problema do X")?
     • toca conceito de domínio sem termo claro / termo sobrecarregado?
     • blast-radius alto (multi-tenancy, migration, API pública, RLS)?
     • feature nova grande (não fix mecânico)?
   → Se 1+ verdadeiro: PROPÕE /grelha ANTES de planejar (não força — oferece).
   → Se pedido é mecânico/claro: pula direto pro Passo 2.
   │
   ▼ (se grelha aceito)
[/grelha]  entrevista galho-a-galho · lê CONTEXT.md e specs/ existentes
   │        → atualiza CONTEXT.md (glossário) inline
   │        → oferece ADR em docs/decisions/ quando passa o gate dos 3 critérios
   │        → (opcional) /doubt nas decisões não-triviais que saíram
   ▼
[Passo 2] Roteamento para a camada certa (JÁ com vocabulário alinhado):
   ├── GSD     → /gsd-do | /gsd-plan-phase   (o plano nasce usando o glossário)
   ├── /spec   → contrato de comportamento    (consome os termos do CONTEXT.md)
   ├── AIOX    → @pm/@architect/@dev
   └── Lovable → /lovable-handoff
   │
   ▼
[Pós] Fase A (/extract-learnings) · STATE.md · CONTINUATION_HANDOFF.md
```

**Princípio preservado:** "comando direto é caminho válido" + "orquestrador é transparente". A Deia **mostra** que vai grelhar e por quê, e o usuário pode dizer "manda ver" (pula). Isso responde a tensão anti-framework: o humano nunca perde o controle.

### 5.2 Onde isso entra na matriz de roteamento atual

Duas linhas novas na tabela "Sinal no pedido → Camada → Comando" de `source/skills/idea/SKILL.md`:

| Sinal no pedido | Camada → Comando |
|----------------|-----------------|
| "me entrevista antes", "grelha esse plano", "alinha comigo antes de codar", "antes de planejar quero pensar junto", pedido vago/alto risco detectado | **Alinhamento** → `/grelha` (grilling pré-plano + glossário/ADR; complementa `gsd-discuss-phase`) |
| "qual o vocabulário do domínio", "monta o glossário", "linguagem ubíqua", "padroniza os termos do projeto" | **Alinhamento** → `/grelha --docs` (foco em `CONTEXT.md`) |

E uma nota de fronteira (espelhando a nota `/spec x GSD` que já existe na skill):

> **Fronteira `/grelha` × `gsd-discuss-phase` × `/doubt`:** `/grelha` alinha COM o humano ANTES de existir plano (à la carte, serve até não-código) e produz glossário durável. `gsd-discuss-phase` faz o mesmo DENTRO de uma fase GSD já aberta (decisões da fase). `/doubt` audita CONTRA decisões já tomadas. Em dúvida, `/grelha` primeiro, GSD depois, `/doubt` nas decisões críticas.

---

## 6. Exemplo real — nfideia (multi-tenancy / cofre digital)

> Jargão extraído de `nfideia` (`spec/multi-tenancy-pilot`): `escritorio_id` (o tenant = escritório contábil), `empresas_clientes`, **cofre digital**, **certificado A1 (`.pfx`)** (A3 rejeitado), **token público efêmero** (15 min, uso único), `platform_admin`, cargos **`admin`/`operador`**, RLS, NFS-e, funções `get_user_escritorio_id()` / `get_empresa_escritorio_id()` / `has_role()`, `logs_auditoria`. **Tudo abaixo é baseado no que foi lido nas specs reais.**

**Cenário plausível:** o usuário quer permitir que um **contador externo** (não-membro do escritório) acesse temporariamente o cofre de um cliente para baixar um certificado vencido e substituir. Pedido inicial (vago):

> "Deia, quero deixar um contador de fora acessar o cofre de um cliente por um tempo."

### (a) A sessão de grilling que a Deia faria (uma pergunta por vez)

1. **Termo "contador de fora".** *Recomendo chamar isso de "convidado externo" — distinto de `operador` (membro do escritório com cargo) e de `platform_admin`. Seu glossário ainda não tem esse conceito. Confere que é um terceiro SEM membership no `escritorio_id`?* → (usuário confirma)
2. **"acessar o cofre" — ler, escrever, ou os dois?** *O cofre hoje tem dois caminhos: o token público de upload (15 min, uso único, escrita) e o acesso autenticado de membro (leitura/gestão). Você quer dar **leitura** (download do `.pfx`) a um externo — que hoje NENHUM fluxo permite. Recomendo: novo token de **leitura** efêmero, espelhando o de upload. Concorda?* → (usuário: "sim, mas precisa logar download")
3. **Cruzando com o código.** *A spec `cofre-digital` diz que toda tentativa de acesso cruzado entre tenants é **negada e auditada em `logs_auditoria`**, e o token público "concede acesso apenas ao path do escritório que o emitiu". Seu pedido respeita isso: o token de leitura nasceria preso ao `escritorio_id` emissor. Confirmo que o externo NUNCA escolhe o escritório — ele herda do token?* → (sim)
4. **Janela e uso.** *O padrão do cofre é 15 min / uso único. Mantemos para leitura, ou download justifica janela maior (ex.: 1 download em até 60 min)?* → (usuário: "uso único, 30 min")
5. **Edge case.** *E se o certificado estiver **expirado** (estado vermelho) no momento do download? Bloqueia, ou permite (já que o motivo é justamente substituir)? Recomendo permitir leitura mesmo expirado, mas marcar no log.* → (usuário: "permite, e loga o motivo")
6. **Cargo que pode emitir.** *Quem emite esse token de leitura externo: só `admin`, ou `operador` também? A spec dá auditoria só pra `admin`. Recomendo restringir emissão a `admin`.* → (sim)

### (b) `CONTEXT.md` resultante (glossário — zero implementação)

```md
# Cofre Digital

Gestão e compartilhamento seguro de certificados digitais A1 dos clientes do escritório.

## Language

**Escritório**:
O tenant do NFIdeia — escritório contábil identificado por `escritorio_id`. Toda linha de dado pertence a um.
_Avoid_: empresa, conta, organização, tenant (em superfície PT-BR)

**Convidado externo**:
Terceiro SEM ownership nem membership de um escritório, que recebe acesso temporário e escopado por token. Distinto de operador e de platform_admin.
_Avoid_: usuário externo, visitante, contador (ambíguo)

**Token de leitura de cofre**:
Concessão efêmera (uso único, 30 min) que permite a um convidado externo baixar UM certificado, presa ao escritório emissor. Espelha o token de upload.
_Avoid_: link de download, acesso temporário

**Certificado A1**:
Certificado digital em arquivo `.pfx` usado para assinar NFS-e. A3 (mídia criptográfica) é incompatível.
_Avoid_: certificado digital (genérico), pfx (use "certificado A1")
```

### (c) ADR gerado (passa o gate dos 3 critérios: difícil reverter? sim, é superfície de segurança · surpreendente? sim · trade-off real? sim)

```md
# docs/decisions/0007-token-leitura-externo-do-cofre.md

# Token de leitura efêmero para convidado externo do cofre

Para permitir que um contador externo baixe um certificado A1 sem criar conta nem
membership, introduzimos um "token de leitura de cofre" — uso único, 30 min, preso ao
`escritorio_id` emissor — espelhando o token de upload existente (15 min). Escolhemos
esse caminho em vez de (a) criar um cargo de membership temporário (acoplaria o externo
ao tenant, difícil de revogar) ou (b) link permanente assinado (viola o contrato de
acesso efêmero + auditado da spec cofre-digital). Download é permitido mesmo com
certificado expirado (o motivo de uso é a substituição), e toda tentativa — sucesso ou
falha — é registrada em `logs_auditoria`.
```

### (d) Como flui pro resto do pipeline

```
/grelha  (acima)
   │  → CONTEXT.md atualizado · ADR 0007 criado
   ▼
/spec    → delta em specs/cofre-digital/spec.md:
   │      "## ADICIONADO Requisitos" → Requisito: Acesso de leitura externo por token efêmero
   │      + cenários (#### QUANDO token válido → ENTÃO 1 download; QUANDO expirado → nega; etc.)
   │      gera tasks.md
   ▼
/doubt   → audita a decisão não-trivial (authz cross-tenant): spawna rls-reviewer
   │      "encontre como esse token pode vazar entre tenants"
   ▼
GSD /gsd-plan-phase → consome tasks.md (já usando "convidado externo", "token de leitura")
   ▼
GSD /gsd-execute-phase → implementa (nova função SECURITY DEFINER + policy + log)
   ▼
/lovable-handoff → deploy (migration + edge), resposta 8 blocos
   ▼
/spec merge+archive → consolida o contrato · Fase A /extract-learnings
```

O ganho concreto: do `/spec` em diante **todo mundo fala "convidado externo" e "token de leitura"** — o plano GSD, a policy RLS, a mensagem de erro e o ADR usam o mesmo vocabulário. É o failure mode #2 (verbosidade/jargão divergente) resolvido na raiz.

---

## 7. Plano de absorção (padrão v8 / quarentena)

Mesmo fluxo que absorveu `addyosmani/agent-skills` no v8: **quarentena → análise → absorver só o delta que não temos → propagar → atualizar manifesto/README**. Licença MIT (compatível; exige preservar atribuição — usamos o header `# SOURCE:` que já é convenção nossa, ex.: `/doubt`, `/spec`).

### Passo 1 — Quarentena (igual ao v8)

Copiar as skills-fonte cruas para `security/quarantine/mattpocock-skills/`:

```
security/quarantine/mattpocock-skills/
  skills/grill-with-docs.md          (+ CONTEXT-FORMAT.md, ADR-FORMAT.md)
  skills/grill-me.md
  skills/improve-codebase-architecture.md   (+ LANGUAGE.md)
  references/philosophy-4-failure-modes.md   (recorte do README)
  _PROVENANCE.md   (URLs, commit/data de captura, licença MIT, o que entra/o que NÃO entra)
```

Razão da quarentena: conteúdo de terceiro é **não-confiável** até auditado (alinha com `context-engineering` §"níveis de confiança" e `memory-hygiene`). Após absorver/testar, **resetar sessão** antes de voltar a trabalho confiável (regra de segurança do `AGENTS.md`).

### Passo 2 — O que absorver, e onde

| Delta a absorver | Destino IdeiaOS | Forma |
|------------------|-----------------|-------|
| Grilling (grill-me + grill-with-docs) | `source/skills/grelha/SKILL.md` | Skill nova PT-BR, header `# SOURCE: mattpocock/skills MIT \| adapted: IdeiaOS v9` |
| Formato do glossário | `source/skills/grelha/CONTEXT-FORMAT.md` | Bundled resource (adaptado PT-BR; regras de ouro preservadas) |
| Gate de ADR (3 critérios) | `source/skills/grelha/ADR-FORMAT.md` + nota em `source/rules/common/` | Reusa `docs/decisions/` existente (NÃO cria `docs/adr/`) |
| Conceito de glossário ubíquo como artefato de projeto | `source/rules/common/ubiquitous-language.md` (rule nova, leve) | Define que `CONTEXT.md` é glossário-only, durável, e como `/spec`+GSD o consomem |
| Ritual de deepening (Ousterhout) | `source/skills/improve-architecture/SKILL.md` (nome PT-BR a definir) | Skill nova; absorve glossário Module/Interface/Depth/Seam + deletion test + relatório HTML |
| Delta de `to-prd` ("sintetiza, não entrevista" + quiz de seams) | enriquecer a doc do `@pm`/Morgan (1 parágrafo) | Ajuste pequeno, não skill nova |
| Achado de `diagnose` ("sem seam correto = o achado") | enriquecer `/gsd-debug`/`source/agents` (1 nota) | Ajuste pequeno |

### Passo 3 — Wiring na Deia + matriz

- Adicionar as 2 linhas + nota de fronteira da seção 5.2 em `source/skills/idea/SKILL.md`.
- Adicionar o **Passo 1.5 (gate de alinhamento)** na lógica de roteamento.

### Passo 4 — Propagação (pipeline existente)

```bash
# membership: incluir grelha + improve-architecture em CORE_SKILLS
#   (editar scripts/build-plugins.sh E manifests/plugin-membership.md — em sincronia,
#    como avisa o próprio script)
bash scripts/build-plugins.sh            # source/ → plugins/ (artefato versionado)
bash scripts/build-adapters.sh --target all   # source/ → ~/.claude/skills + .cursor/rules
# registrar os módulos novos em manifests/modules.json (kind: skill, plugin: ideiaos-core)
bash scripts/check-plugin-membership.sh  # gate de paridade manifesto×build
```

### Passo 5 — Manifesto + README (barreira ativa)

`AGENTS.md` exige: toda mudança em `source/` atualiza `README.md` (seções "O que este setup instala", "Estrutura do repositório", "Como usar no dia a dia") **e** `manifests/modules.json`. O pre-commit hook (`check-readme-sync.sh`) **bloqueia** o commit se não fizer. Incluir `/grelha` na matriz documentada da Deia também.

### Passo 6 — Milestone

Vira **v9 — "Camada de Alinhamento"** (espelha o nome da v8 "Camada de Disciplina"):

- **v9.0:** `/grelha` (grilling + `CONTEXT.md` glossário + ADR inline) + rule `ubiquitous-language` + wiring na Deia.
- **v9.1 (could):** `/improve-architecture` (ritual de deepening) + deltas finos em `@pm`/`gsd-debug`.

### Riscos e mitigação

| Risco | Mitigação |
|-------|-----------|
| **Sobreposição confusa** com `gsd-discuss-phase` e `/doubt` (3 coisas que "perguntam") | Nota de fronteira explícita (seção 5.2) + tabela 4.1 na própria skill; mesma disciplina da fronteira `/spec × GSD` que já funciona. |
| **Colisão de `CONTEXT.md`** com o `{phase}-CONTEXT.md` do GSD | São arquivos diferentes (raiz/`src/*` vs `.planning/phases/*`); a rule `ubiquitous-language` documenta a distinção. Risco baixo, mas precisa ser dito em letras grandes. |
| **Grilling vira fricção** (usuário só quer codar) | É **opcional e disparado por risco**; "manda ver" pula. Nunca bloqueia fix mecânico. |
| **Diluição filosófica** (importar a postura anti-framework) | Absorvemos técnica, não postura (ver abaixo). Header `# SOURCE:` + este relatório registram a fronteira. |
| **Licença/atribuição** | MIT — preservar crédito no header `# SOURCE:` e no `_PROVENANCE.md` da quarentena. |

### Postura sobre a tensão anti-framework (honesta)

Pocock vende as skills como **anti-GSD/BMAD/Spec-Kit**. O IdeiaOS é o oposto: um **orquestrador de camadas**. Não há contradição em adotar as técnicas dele, porque:

- O que o Matt critica nos frameworks ("tomam o controle, escondem bugs do processo") o IdeiaOS **já mitiga** por design: princípio "comando direto é caminho válido", roteamento **transparente** (mostra o comando antes), e gates que são contratos explícitos — não caixa-preta.
- As técnicas dele (grilling, linguagem ubíqua, módulos profundos) **não são frameworks** — são rituais. Rituais soltos é exatamente o que a Deia foi feita para governar. Transformamos "skills à la carte que você tem que lembrar de usar" em "camada que a Deia dispara na hora certa".
- **O que NÃO adotamos:** a tese de que processo governado é ruim; o acoplamento a GitHub Issues (`to-issues`/`triage`); o estilo `caveman` (conflita com clareza + PT-BR). E não trocamos `/gsd-debug` por `diagnose`, nem nossa `/tdd` pela dele — os nossos são iguais ou superiores.

Em uma frase: **o Matt provou que essas três técnicas valem ouro soltas; o IdeiaOS as torna mais poderosas ao colocá-las sob orquestração — sem comprar a ideologia de que orquestração é o inimigo.**

---

## 8. Recomendação final (priorizada)

### MUST

1. **Criar `/grelha` (alias `/grill`)** absorvendo grill-me + grill-with-docs, com `CONTEXT.md` (glossário ubíquo durável) e ADR inline em `docs/decisions/` (gate dos 3 critérios). É o delta de maior valor e o foco explícito do pedido.
2. **Criar a rule `ubiquitous-language.md`** que define `CONTEXT.md` como glossário-only e sua relação com `/spec` (contrato) e GSD (`{phase}-CONTEXT.md` = decisões). Sem isso, os três "CONTEXT" se confundem.
3. **Wirar na Deia** o Passo 1.5 (gate de alinhamento opcional, disparado por ambiguidade/risco) + as 2 linhas de matriz + nota de fronteira.

### SHOULD

4. **`/improve-architecture`** — ritual recorrente de "deepening" (Ousterhout), informado por `CONTEXT.md` + `docs/decisions/`, com relatório HTML e grilling loop. Preenche o gap de **saúde de design contínua** que hoje só temos pontual (`code-simplifier`/`refactor-cleaner`).
5. **Delta de `to-prd`** no `@pm`/Morgan: "sintetiza o discutido, não re-entrevista" + quiz de seams/módulos antes do PRD.

### COULD

6. Absorver a nota do `diagnose` ("sem seam de teste correto, isso É o achado → handoff pra architecture") em `/gsd-debug`.
7. Avaliar `caveman` como modo opt-in de baixa prioridade (risco de clareza/PT-BR — provavelmente fica de fora).

### WON'T (explicitamente fora)

- `to-issues`, `triage` (acoplam a GitHub Issues; nosso modelo é fases/stories).
- `tdd`, `handoff`, `zoom-out`, `prototype`, `write-a-skill`, `setup-pre-commit`, `git-guardrails`, `migrate-to-shoehorn`, `scaffold-exercises`, `teach` (já temos igual/melhor, ou é nicho).

---

*Relatório de pesquisa. Não-vinculante até virar milestone v9 via `/gsd-new-milestone` ou decisão do mantenedor. Nenhum código foi alterado nesta sessão.*
