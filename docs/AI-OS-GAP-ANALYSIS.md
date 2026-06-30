# IdeiaOS — Análise Comparativa: quão longe de um verdadeiro AI-OS / harness completo

> **Data:** 2026-06-30 · **Branch:** work · **Método:** scorecard de 9 dimensões contra um AI-OS de referência, verificado contra o código real (não o manifesto), com judge-panel adversarial de 3 abordagens de unificação.
> **Veredito global:** **3,67 / 5** — um sistema já maduro na periferia (governança, execução, observabilidade, distribuição), **gargalado no centro** (a coesão GSD↔AIOX, 2/5).
>
> **Visão norteadora (decisão do Gustavo, 2026-06-30):** o harness **central é a DEIA / IdeiaOS em si** — um **kernel-orquestrador** que *possui* o ciclo de vida (intake→plan→execute→verify→learn); **AIOX e GSD são executores plugáveis** por trás dela, não o centro. Este documento mede a distância até lá e traça o caminho.

---

## 1. Sumário executivo

O IdeiaOS **já é "OS-grade" em 6 das 9 dimensões** (todas 4/5): governança, segurança, execução/verificação, observabilidade, distribuição, tooling e memória. O que o separa de um **harness de verdade** está concentrado em dois pontos no **núcleo**:

1. **Coesão GSD↔AIOX — 2/5 (o gargalo).** Hoje o IdeiaOS **não é um harness — são dois upstreams externos colados.** AIOX (npm `.aiox-core/`) e GSD (plugin do Claude Code) são unidos por **1 roteador** (`/idea`) + **3 "contratos"** que, na verdade, são **injeção de texto em markdown de terceiros** (`install-global-patches.sh` edita in-place o `gsd-plan-phase/SKILL.md` e o `qa.md`). Há **2 vocabulários** (story×phase), **2 state-stores** (`docs/stories/`×`.planning/`) e **2 conjuntos de comando** (`@persona`×`/gsd-*`). A ponte é **frágil**: um update upstream reverte os patches **silenciosamente** (o próprio código loga *"upstream mudou?"* como WARN, não erro).

2. **Kernel/Orquestração — 3/5.** O `/idea` é um **roteador 100% LLM-driven** (`source/skills/idea/` só tem `SKILL.md`, zero código de roteamento). Não há **teste que prove a correção do roteamento** (`idea-smoke.sh` prova que está instalado, não que "pedido X → camada Y"), nem **escalonador de tarefas próprio** — o IdeiaOS terceiriza 100% da orquestração ao GSD.

**Descoberta que muda o plano:** verificado no disco — **não existe um único `.story.md` em todo o repo**; `docs/stories/` e `.aiox/handoffs` estão vazios. **O lado AIOX story-driven quase não é exercido.** Logo, perseguir uma unificação *simétrica* story↔phase seria construir parser de um formato morto. **A unificação deve ser GSD-first**, com "story" como cidadão de 2ª classe até ter uso real.

**Recomendação (caminho até a Deia-kernel, sem big-bang):** evoluir por ondas seguras — **Abordagem A** (camada de tradução + fachada, toda em `source/` que o IdeiaOS controla) como espinha; **a melhor ideia da Abordagem C** (adapter boundary: trocar os patches mutantes por consumo da interface pública `--prd`/`VERIFICATION.md`) como fase **condicional**; **Abordagem B** (event-store) **descartada por ora** (prematura — viola *enforce-simplicity* enquanto AIOX não é usado). O **destino continua sendo a Deia-kernel**; o caminho é incremental para não quebrar o que já está SHIPPED.

---

## 2. Modelo de referência — as 9 dimensões de um AI-OS de desenvolvimento

| # | Dimensão | O que mede | Nível 5 (ideal) |
|---|----------|------------|-----------------|
| 1 | **Kernel / Orquestração** | ponto de entrada único, roteamento, escalonamento | roteamento determinístico-primeiro + scheduler próprio, provado por exit-code |
| 2 | **Memória & Aprendizado** | persistência, recall, instincts, learnings | memória que molda conduta ao vivo + destilação automática que realimenta o agente |
| 3 | **Agentes & Papéis** | personas, autoridade, handoff | matriz de autoridade única enforçada; handoff compacto em uso comprovado |
| 4 | **Execução & Verificação** | plan→execute→verify, gates | toda fase verificada por evidência binária, zero teatro-verde |
| 5 | **Ferramentas & Integração** | skills, MCPs, plugins, CLI-first | catálogo coeso sem drift; descoberta sob demanda |
| 6 | **Governança & Segurança** | constituição, autoridade, credenciais, frescor | invariantes por gate determinístico, não por disciplina |
| 7 | **Observabilidade & Saúde** | diagnóstico, drift, frota | saúde em tempo real + drift auto-detectado e curado |
| 8 | **Distribuição & Multi-máquina/IDE** | install, propagação, autosync | mudança chega sozinha e consistente a toda máquina/IDE, com prova central |
| 9 | **Coesão / Unificação GSD↔AIOX** | quão *unificado* (não justaposto) | um harness único: 1 vocabulário, 1 modelo de estado, 1 fluxo |

---

## 3. Scorecard

| Dimensão | Score | Barra | Gap principal (1 linha) |
|----------|:-----:|-------|-------------------------|
| Coesão / Unificação GSD↔AIOX | **2/5** | ██░░░ | 2 upstreams colados por text-injection; 2 vocabulários, 2 state-stores |
| Kernel / Orquestração | **3/5** | ███░░ | roteamento 100% LLM, sem teste de correção nem scheduler próprio |
| Memória & Aprendizado | **4/5** | ████░ | loop de instincts **não produz saída** (`~/.ideiaos/instincts/` vazio) e é write-only |
| Agentes & Papéis | **4/5** | ████░ | matriz de autoridade só cobre as 12 personas AIOX, não os 19 agents próprios; handoff sem uso real |
| Execução & Verificação | **4/5** | ████░ | verificação depende de disciplina (o hook só *lembra*); waves são do GSD, não do IdeiaOS |
| Ferramentas & Integração | **4/5** | ████░ | drift catálogo↔disco (manifesto subconta rules 7→42, hooks 13→17) |
| Governança & Segurança | **4/5** | ████░ | Constitution é documento (não gate); Security-Freshness em modo advisory |
| Observabilidade & Saúde | **4/5** | ████░ | drift manifesto↔disco **não é detectado por nenhum gate**; frota é pull, não push |
| Distribuição & Multi-máquina/IDE | **4/5** | ████░ | "multi-IDE" são só 2 (claude+cursor); ledger de propagação é local-only (sem prova cross-máquina) |
| **Média** | **3,67/5** | | |

---

## 4. O que já é OS-grade vs o que ainda é "script solto"

**Já é OS-grade (a periferia está forte):**
- **Gates antifragile** (exit-code é lei) — 19 gates em `scripts/`, SOAK, idea-doctor com 17 seções + `--json` + `--fleet`.
- **Governança** — agent-authority, credential-isolation, security-freshness, Constitution, deny-rules de MCP.
- **Distribuição** — autosync multi-máquina, propagate-if-changed, overlay PRISTINE, 3 regimes de instalação claros.
- **Memória nativa** — auto-injetada todo SessionStart, sync cross-IDE via branch `planning`.

**Ainda é justaposição (o centro está frouxo):**
- A **costura GSD↔AIOX** é visível assim que se sai do `/idea` — dois mundos com comandos e artefatos próprios.
- O **roteador** é prosa interpretada pelo LLM, sem contrato testável.
- O **loop de instincts** está quebrado na ponta (não gera saída).
- O **drift manifesto↔disco** existe e **nenhum gate o detecta**.

---

## 5. O cerne — unificar GSD↔AIOX num único harness (a Deia-kernel)

### 5.1 Por que está em 2/5 (diagnóstico verificado no código)

- **A ponte são 3 monkey-patches.** `install-global-patches.sh` Patches 1/2/5/6 editam **in-place** arquivos instalados pelos upstreams. A semântica do `--story` é literalmente *"trate a story como um PRD"* — **coerção, não unificação**.
- **Dois state-stores desconexos.** `docs/stories/*.story.md` (AIOX) vs `.planning/phases/*/PLAN.md` (GSD), **sem fonte-de-verdade compartilhada**. Nenhum componente cross-escreve nos dois.
- **O roteador escolhe, não unifica.** `/idea` roteia por `test -d .planning` / `test -d .aiox-core` (linhas 148-152 da SKILL) — decide **qual** mundo, mantendo ambos os vocabulários visíveis. A própria `DECISION-MATRIX` precisa de "5 critérios + 2 exceções + 1 pergunta" só para escolher o mundo: evidência de que a dualidade foi **documentada**, não **abstraída**.
- **Fragilidade estrutural reconhecida.** O `install-global-patches.sh` tem 11+ avisos *"arquivo ausente — GSD instalado?"* e *"SKILL.md sem âncoras (upstream mudou?)"* — o sistema **admite** que um refactor upstream quebra o contrato em silêncio.

### 5.2 As 3 abordagens avaliadas (judge-panel adversarial)

| Abordagem | Tese | Esforço | Risco | Veredito |
|-----------|------|:-------:|:-----:|----------|
| **A — Camada de tradução / fachada** | glossário canônico + lib de tradução story↔phase + fachada, **tudo em `source/`** (IdeiaOS controla 100%), upstreams intactos | médio | baixo | ✅ **espinha** |
| **C — Kernel-orquestrador nativo** | `source/kernel/` possui o ciclo de vida; AIOX/GSD viram executores plugáveis | muito alto | alto | 🔶 **1 ideia aproveitada** (adapter boundary, fase condicional) |
| **B — Estado unificado (work-item + event-store)** | um schema canônico do qual story/phase são projeções | muito alto | alto | ❌ **descartada por ora** (prematura — `docs/stories/` vazio) |

**Por que A vence e não C (apesar de C ser a sua visão de destino):** C **é** o destino certo (Deia dona do meta-ciclo), mas empacotado como um kernel monolítico que **reescreve o coração SHIPPED** de uma vez — risco enorme e **conflito de dois donos de lifecycle** (GSD já tem discuss→plan→execute→verify; a Constitution AIOX é NON-NEGOTIABLE). A forma **segura** de chegar à Deia-kernel é **evoluir até ela**: a camada de tradução (A) já entrega coesão real hoje com risco baixo, e o "adapter boundary" de C — trocar os patches mutantes por consumo da interface pública `--prd` — entra quando o uso justificar. **C não é abandonado; é faseado.**

### 5.3 Roadmap faseado — o caminho seguro até a Deia-kernel

> Princípio: cada fase entrega valor isolado, é reversível, e é gateada por exit-code. **Nada de big-bang.**

- **Fase 0 — Corrigir a premissa (1 sessão).** Registrar num ADR (`docs/decisions/`) que a unificação começa **GSD-cêntrica**: "story" é projeção futura, não par simétrico de "phase". Evita construir parser de formato que não é exercido.
- **Fase 1 — Vocabulário canônico.** `source/translation/glossary.md` (formato `CONTEXT.md`, reusa a rule *ubiquitous-language*): mapa canônico phase↔story↔requirement↔AC↔goal↔status. `source/translation/translate.sh` (bash 3.2, gateado por `gates.sh`). Registrar em `manifests/modules.json` + `check-plugin-membership.sh` para **não criar novo drift**.
- **Fase 2 — Endurecer o gate que JÁ existe.** O `idea-doctor §4` já audita a presença dos patches (grep `-qF`, WARN). Elevar **WARN→FAIL** quando AIOX está instalado **e** um patch foi revertido por update; e mover a lógica de tradução dos blocos python dos patches para `translate.sh` (patches viram cascas finas — menos superfície a quebrar).
- **Fase 3 — Fachada de leitura (GSD-first).** `scripts/idea-index.sh` read-only varre `.planning/` e emite `.ideiaos-index.json` (gitignored). Sub-rotas `/idea status` (fase atual + progresso real do `STATE.md`, não `test -d`) e `/idea next`. Sem novo entrypoint.
- **Fase 4 — Adapter boundary (CONDICIONAL, gated por ≥3 usos reais do fluxo story→fase).** Substituir o Patch 2 por um adapter que lê a story, extrai os AC e **gera um `--prd`** que o GSD já aceita publicamente — **eliminando a mutação in-place**. Manter os patches como no-op idempotente por 1 SOAK antes de deprecar (rollback seguro).
- **Fase 5 — Fechamento.** `idea-doctor` + gates de fechamento (SOAK, security-freshness `--gate`). `extract-learnings`. Atualizar `IDEIAOS.md` apontando o glossário como fonte do vocabulário.

**Onde isto chega:** ao fim das fases 1-4, o `/idea` deixa de ser um roteador-que-escolhe e passa a ser uma **fachada com estado** que fala **um vocabulário** e mostra **um índice** — a Deia começa a *possuir o meta-ciclo entre fases*, enquanto GSD/AIOX executam *dentro* das fases. É a Deia-kernel chegando por evolução, não por reescrita.

---

## 6. Quick wins transversais (alto ROI, baixo esforço — fora do eixo GSD↔AIOX)

| Quick win | Dimensão | Por quê |
|-----------|----------|---------|
| **Consertar o loop de instincts** (investigar logs 0-byte; gate `assert_nonempty` no spawn) | Memória | hoje produz **zero** instincts apesar de rodar — aprendizado automático está quebrado na ponta |
| **Gate de drift manifesto↔disco** (`check-manifest-drift.sh`: conta `kind=rule/hook/...` vs arquivos reais) | Observabilidade | o drift 7→42 rules / 13→17 hooks **não é detectado por ninguém** |
| **Ligar `SECFRESH_GATE_ENABLED=1`** (já há 4 selos PASS no ledger) | Governança | converte Security-Freshness de advisory para gate real de tag |
| **Fixture de roteamento** em `idea-smoke.sh` (N pedidos → camada esperada, por exit-code) | Kernel | prova a **correção** do roteamento, não só o bootstrap |
| **`build-plugins.sh` + commit** (zera drift `ideiaos-checker.md` source↔plugin) | Tooling | 1 comando elimina cópia desatualizada já identificada |
| **Commitar ledger de propagação** (estilo SOAK) | Distribuição | dá **prova cross-máquina** de que a mudança chegou |
| **Matriz de autoridade para os 19 agents próprios** | Agentes | hoje só as 12 personas AIOX têm autoridade formal |

---

## 7. Próximos projetos de melhoria (eixos estratégicos do Gustavo — execução posterior)

> Registrados aqui a pedido; **não** fazem parte do roadmap GSD↔AIOX acima. Tratar como projetos de melhoria próprios.

### 7.1 Lifecycle de documentação de planejamento — da concepção (greenfield) ao legado (brownfield)

**Estado hoje:** as peças existem, **dispersas e sem lifecycle unificado**:
- *Greenfield:* `/gsd-new-project`, `/gsd-new-milestone`, `/grelha` (alinhamento + glossário), `/spec` (contrato de comportamento).
- *Brownfield:* `/gsd-map-codebase`, `/gsd-ingest-docs`, Brownfield Discovery do AIOX (10 fases), `/spec` delta-spec, `/codebase-onboarding`.

**Gap:** não há **um pipeline padronizado** que cubra os **dois pontos de entrada** (app do zero × legado assumido) convergindo num **mesmo conjunto de artefatos de planejamento**. Hoje a IA escolhe peças ad-hoc.

**Direção proposta (futuro):** um fluxo único de "documentação de planejamento" com **dois on-ramps** (novo vs legado) que produzem o **mesmo formato canônico** (visão → glossário `CONTEXT.md` → spec de capabilities → roadmap GSD), de modo que assumir um legado e conceber um novo terminem no **mesmo estado documental**.

### 7.2 Documentação viva e permanente, padronizada por projeto

**Estado hoje:** o registro vivo está **fragmentado** em `STATE.md`, `docs/CONTINUATION_HANDOFF.md`, `docs/learnings/`, `CONTEXT.md` — cada um com regra própria, sem um artefato-âncora único por projeto.

**Gap:** não há um padrão de **"living doc"** — um documento permanente, **auto-atualizado por gate/hook** a cada fechamento de sessão, que seja o retrato sempre-atual de cada projeto assumido dentro do IdeiaOS.

**Direção proposta (futuro):** um artefato-âncora padrão por projeto (ex.: `PROJECT.md` vivo) com seções fixas (estado, decisões, capabilities, dívidas, próximos passos) cuja atualização seja **enforçada** no protocolo de fechamento (o IdeiaOS já tem o gancho: o passo "atualizar STATE.md/HANDOFF" do CLAUDE.md vira um **gate** em vez de disciplina).

---

## 8. Riscos e mitigações (do roadmap de unificação)

| Risco | Mitigação |
|-------|-----------|
| Construir índice sobre `docs/stories/` que **não existe** | Fase 3 GSD-first: índice lê só `.planning/` até AIOX ter uso real |
| Os 3 patches continuam mutando markdown upstream (update reverte em silêncio) | Curto prazo: endurecer o gate de presença (WARN→FAIL). Durável: fase 4 (adapter boundary) |
| Novos módulos viram **mais drift** manifesto↔disco | Registrar em `modules.json` + `check-plugin-membership.sh` na **mesma onda** que cria o módulo |
| Adotar o kernel (C) cedo demais → "kernel meia-boca pior que 3 patches que funcionam" + 2 donos de lifecycle | Gate de necessidade (≥3 usos); rule explícita: **GSD dono DENTRO da fase; IdeiaOS dono do meta-ciclo ENTRE fases** |
| `.ideiaos-index.json` driftar do estado real | Regenerar on-demand a cada `/idea status`; nunca tratar como fonte-de-verdade |

---

## 9. Conclusão

O IdeiaOS está **a ~1,3 ponto** (3,67→5) de um AI-OS de referência, e a distância **não está espalhada** — está concentrada no **núcleo** (coesão 2/5, kernel 3/5). A boa notícia: a periferia madura (gates, governança, distribuição, observabilidade) é exatamente a fundação sobre a qual um kernel se apoia. A **Deia-kernel é alcançável por evolução** — camada de tradução → fachada com estado → adapter boundary — sem reescrever o que já funciona, e sem quebrar os upstreams que o IdeiaOS não controla. Os dois eixos de documentação (§7) são projetos de melhoria paralelos que tornam o harness completo também **no plano do conhecimento**, não só no da execução.

---

*Gerado por análise multi-agente (scorecard 9 dimensões + judge-panel adversarial de 3 abordagens), verificado contra o código real em 2026-06-30. Visão norteadora: [`project_deia-kernel-vision`] — a Deia/IdeiaOS é o harness central.*
