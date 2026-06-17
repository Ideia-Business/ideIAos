# Requirements — v9: Camada de Alinhamento (Alignment Layer)

**Milestone:** v9
**Aberto:** (a abrir) · **Status:** 📋 PLANEJADO (esqueleto — não executado)
**Fonte:** análise de `mattpocock/skills` (MIT, ~132k ⭐) × IdeiaOS — ver `docs/research/2026-06-16-mattpocock-skills-analise.md`. Absorver o delta de **alinhamento humano↔agente ANTES de planejar** (grilling + linguagem ubíqua durável + ADR inline) e o ritual de **saúde de design contínua** (módulos profundos / Ousterhout), sem comprar a postura anti-framework do upstream e sem duplicar GSD/AIOX.
**Quarentena:** `security/quarantine/mattpocock-skills/` já estagiada (commit upstream `694fa30`, LICENSE MIT preservada, `security/scan-absorbed.sh` → exit 0: PASS 2 / WARN 2 / FAIL 0).

## GAPs que o milestone fecha (numerados conforme o relatório)

- **GAP 1** — glossário de **linguagem ubíqua durável e project-wide** (`CONTEXT.md` glossário-only). Hoje inexistente (GSD tem `{phase}-CONTEXT.md` = decisões efêmeras; `/spec` = contrato, não vocabulário).
- **GAP 2** — **grilling colaborativo pré-plano desacoplado de fase GSD** (uma pergunta por vez, galho-a-galho, serve até para não-código).
- **GAP 3** — ritual recorrente de **"deepening" arquitetural** (Ousterhout: módulos profundos) informado por glossário + ADRs.

## Requisitos

| ID | Requisito | Fecha GAP | Status |
|----|-----------|-----------|--------|
| R9-01 | Skill `/grelha` (alias `/grill`) — grilling colaborativo PRÉ-plano, 1 pergunta por vez, galho-a-galho, com resposta recomendada; lê código quando pode; modos `--docs` e `--rapido`; funciona para código e não-código | GAP 2 | ⬜ TODO |
| R9-02 | Artefato `CONTEXT.md` (glossário de linguagem ubíqua, glossário-only, durável, project-wide) — formato, local, manutenção e distinção explícita do `{phase}-CONTEXT.md` (GSD) e do `/spec` | GAP 1 | ⬜ TODO |
| R9-03 | ADR ultraleve inline gerado pelo grilling — gate dos 3 critérios, formato mínimo, mora em `docs/decisions/`, integra-se ao espelhamento ADR→Obsidian existente | GAP 1/2 (enabler) | ⬜ TODO |
| R9-04 | Gate de alinhamento OPCIONAL na Deia (`/idea`) — Passo 1.5 disparado por risco/ambiguidade, ANTES do roteamento; opt-in/escapável ("manda ver" pula); transparente | GAP 2 | ⬜ TODO |
| R9-05 | Ritual recorrente de "deepening" arquitetural (skill `/aprofundar` OU enriquecimento de `refactor-cleaner`/`code-simplifier`) informado por `CONTEXT.md` + `docs/decisions/` | GAP 3 | ⬜ TODO |
| R9-06 | Empacotamento/propagação — skill(s) nova(s) em `build-plugins.sh` (CORE_SKILLS), `build-adapters.sh` (rules se aplicável), `manifests/modules.json` + `plugin-membership.md`, `README.md`; atribuição MIT registrada; gates binários verdes | — (infra) | ⬜ TODO |
| R9-07 | ADR de postura sobre a tensão anti-framework em `docs/decisions/` — absorvemos técnica, não ideologia; `/grelha` opera SOB orquestração da Deia, não a substitui | — (governança) | ⬜ TODO |

---

## Detalhamento + critérios de aceitação

### R9-01 — Skill `/grelha` (alias `/grill`) · fecha GAP 2

Grilling colaborativo pré-planejamento, absorvendo `grill-me` (núcleo) + `grill-with-docs` (modo com docs) do upstream. Postura **colaborativa** (alinhar COM o humano), simétrica ao `/doubt` (adversarial, CONTRA o artefato).

**Critérios de aceitação:**
- [ ] `source/skills/grelha/SKILL.md` existe, PT-BR, com header `# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9` e tabela de invocação (`/grelha`, `/grill`, "Deia, me entrevista antes…").
- [ ] Comportamento documentado: **1 pergunta por vez**, aguarda resposta, **cada pergunta vem com resposta recomendada**, e **lê o código em vez de perguntar** o que dá pra descobrir.
- [ ] Modo `--docs` (default em código): desafia contra glossário, afia termos vagos, inventa cenários de edge case, cruza afirmações com o código.
- [ ] Modo `--rapido` (= `grill-me` cru): grilling sem efeitos colaterais em arquivo — serve para não-código.
- [ ] Seção "O que é / O que NÃO é" com a fronteira explícita vs `gsd-discuss-phase` e `/doubt` (espelha o estilo de fronteira da skill `/spec`).
- [ ] Contém tabela anti-racionalização + Red flags + Verificação (convenção de autoria R8-04).

### R9-02 — Artefato `CONTEXT.md` (glossário de linguagem ubíqua) · fecha GAP 1

O subproduto durável de maior valor. Glossário **opinativo**, **só termos do domínio**, **zero implementação**.

**Critérios de aceitação:**
- [ ] `source/skills/grelha/CONTEXT-FORMAT.md` (resource empacotado, adaptado PT-BR) define: cabeçalho + `## Language` com `**Termo**: def 1-2 frases` + `_Avoid_: sinônimos`; regras de ouro (opinativo, tight, só domínio, nada de implementação); single vs multi-context (`CONTEXT-MAP.md`); criação preguiçosa.
- [ ] Rule nova `source/rules/common/ubiquitous-language.md` (sempre-on, leve) define que `CONTEXT.md` é glossário-only, durável e project-wide, e **documenta a distinção** dos outros dois "CONTEXT": `{phase}-CONTEXT.md` (GSD = decisões efêmeras) e `specs/<cap>/spec.md` (`/spec` = contrato de comportamento).
- [ ] A rule explicita como `/spec` e GSD **consomem** o glossário (vocabulário comum em requisitos, planos, nomes de código, mensagens de erro).
- [ ] Verificável: a rule aparece no deploy `.claude/rules/ideiaos-common-ubiquitous-language.md` + `.cursor/rules/*.mdc` (paridade R8-09).

### R9-03 — ADR ultraleve inline · fecha GAP 1/2 (enabler)

ADR mínimo gerado durante o grilling, **reusando `docs/decisions/`** (NÃO criar `docs/adr/` paralelo).

**Critérios de aceitação:**
- [ ] `source/skills/grelha/ADR-FORMAT.md` (resource, PT-BR) com o **gate dos 3 critérios** (difícil de reverter + surpreendente sem contexto + trade-off real — os três obrigatórios) e formato mínimo (título + 1-3 frases; seções opcionais só quando agregam).
- [ ] Numeração sequencial em `docs/decisions/NNNN-slug.md`; criação preguiçosa.
- [ ] Integra-se ao espelhamento ADR→Obsidian existente (`/extract-learnings` já espelha `docs/decisions/` → `Decisions/`): documentado que ADRs do grilling entram nesse fluxo, sem pipeline novo.
- [ ] `/grelha` **oferece** ADR (não impõe) e **pula** quando qualquer um dos 3 critérios falha.

### R9-04 — Gate de alinhamento OPCIONAL na Deia · fecha GAP 2

Passo 1.5 no roteamento da Deia, entre a classificação e a delegação à camada. **Opt-in, escapável, transparente** — nunca fricção obrigatória.

**Critérios de aceitação:**
- [ ] `source/skills/idea/SKILL.md` ganha o **Passo 1.5 (gate de alinhamento)** com heurística de disparo (pedido vago; termo de domínio sobrecarregado/ausente; blast-radius alto — multi-tenancy/migration/API pública/RLS; feature nova grande) e regra "se mecânico/claro → pula".
- [ ] A Deia **propõe** `/grelha` (não força); "manda ver" / pedido explícito de velocidade pula direto pro roteamento.
- [ ] +2 linhas na matriz de roteamento ("me entrevista antes", "grelha esse plano", "monta o glossário", "linguagem ubíqua") → `/grelha`.
- [ ] Nota de fronteira `/grelha × gsd-discuss-phase × /doubt` adicionada (espelha a nota `/spec × GSD` já existente).
- [ ] Verificável: roteamento permanece **transparente** (mostra o comando antes de executar — princípio #2 do IDEIAOS.md).

### R9-05 — Ritual de "deepening" arquitetural · fecha GAP 3

Absorve `improve-codebase-architecture`: busca de oportunidades de aprofundamento (módulo raso → profundo), com **deletion test**, informado por `CONTEXT.md` + `docs/decisions/`.

**Critérios de aceitação:**
- [ ] **Decisão registrada** (ADR ou nota no roadmap): skill nova `/aprofundar` (`source/skills/improve-architecture/`) **vs** enriquecer `refactor-cleaner`/`code-simplifier`. Recomendação do relatório: skill nova (o ritual recorrente + relatório HTML + glossário Module/Interface/Depth/Seam não cabe num agente de limpeza pontual).
- [ ] Se skill: absorve o glossário de arquitetura (Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality), o **deletion test**, o relatório HTML em tmp (sem sujar o repo) e o grilling loop com efeitos colaterais inline (atualiza `CONTEXT.md`, oferece ADR — reusa R9-02/R9-03).
- [ ] Usa o vocabulário do `CONTEXT.md` do projeto para o domínio e o glossário de arquitetura para a estrutura; não re-litiga ADRs existentes (só sinaliza conflito quando a fricção justifica reabrir).
- [ ] Header `# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9`.

### R9-06 — Empacotamento / propagação · infra

**Critérios de aceitação:**
- [ ] `/grelha` (e `/aprofundar`, se skill) adicionadas a `CORE_SKILLS` em `scripts/build-plugins.sh` **e** a `manifests/plugin-membership.md` (em sincronia — o drift-guard R7-07 exige).
- [ ] Entradas novas em `manifests/modules.json` (`kind: skill`, `plugin: ideiaos-core`); rule `ubiquitous-language` registrada como `kind: rule`.
- [ ] `bash scripts/build-plugins.sh` + `bash scripts/build-adapters.sh --target all` rodam sem erro; `scripts/check-plugin-membership.sh` → 0 deriva.
- [ ] `README.md` atualizado (seções "O que este setup instala", "Estrutura do repositório", "Como usar no dia a dia"); `scripts/check-readme-sync.sh` verde (paridade N/N).
- [ ] Atribuição MIT preservada (header `# SOURCE:` nas skills + `_PROVENANCE`/LICENSE já na quarentena).
- [ ] `idea-doctor` 0 FAIL; suíte bats verde.

### R9-07 — ADR de postura anti-framework · governança

**Critérios de aceitação:**
- [ ] `docs/decisions/NNNN-postura-anti-framework-mattpocock.md` registra: absorvemos **técnica** (grilling, linguagem ubíqua, módulos profundos), **não a ideologia** ("frameworks tiram o controle"); `/grelha` e `/aprofundar` operam **sob** orquestração da Deia; o que NÃO adotamos (`to-issues`/`triage`/`caveman`/substituir `gsd-debug` por `diagnose` ou `/tdd` pela do Matt) e por quê.
- [ ] ADR referenciado no header das skills novas e no relatório de pesquisa.
- [ ] Espelhado no Obsidian via fluxo `/extract-learnings` existente (R9-03).

---

## Fora de escopo (decisão consciente)

- **`to-issues` / `triage`** — acoplam a GitHub/GitLab Issues; o IdeiaOS planeja por fases GSD (`.planning/`) e stories AIOX, não por issue tracker externo.
- **`diagnose`, `tdd`, `handoff`, `zoom-out`, `prototype`, `write-a-skill`, `setup-pre-commit`, `git-guardrails`** — JÁ TEMOS equivalente igual ou melhor (`/gsd-debug`, `/tdd`, Continuation, `code-explorer`/`code-tour`, `gsd-sketch`/`gsd-spike`, `skill-creator`/`forge-agent`, pre-commit hooks, git-autosync).
- **`migrate-to-shoehorn`, `scaffold-exercises`, `teach`, `setup-matt-pocock-skills`** — nicho dos produtos/cursos do autor; irrelevantes ao IdeiaOS.
- **`caveman`** — could-have de baixa prioridade; conflita com clareza + PT-BR. Reavaliar fora do v9, se houver demanda.
- **Postura anti-framework do upstream** — explicitamente NÃO adotada (ver R9-07).
