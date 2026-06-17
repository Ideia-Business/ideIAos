# Roadmap — v9: Camada de Alinhamento (Alignment Layer)

**Milestone:** v9
**Aberto:** (a abrir) · **Status:** 📋 PLANEJADO (esqueleto — não executado)
**Numeração de fases:** lettered (Fase A–F), espelhando o estilo de "waves" do v8 (v7/v8 reiniciam a contagem por milestone; não há contador global desde o v6/fase 31).

## Tese

Absorver de `mattpocock/skills` (MIT) **só o delta que não temos**: o ritual de **alinhamento humano↔agente ANTES de planejar** (grilling colaborativo), seu subproduto durável de **linguagem ubíqua** (`CONTEXT.md` glossário-only) e ADRs ultraleves, mais o ritual recorrente de **deepening** arquitetural (Ousterhout). Tudo PT-BR, **sob orquestração da Deia** (não à la carte), complementando — nunca substituindo — `gsd-discuss-phase`, `/doubt`, `/spec` e GSD/AIOX. Shippado pelas próprias práticas do IdeiaOS: quarentena antes de instalar (já feita), `/doubt` sobre o próprio entregável, verificação por exit code, gates de membership/README verdes.

---

## Fases

### Fase A — Quarentena & atribuição ✅ pré-feita (revalidar)

**Objetivo (goal-backward):** garantir que o material de terceiro está auditado e atribuído antes de qualquer absorção.
**Estado:** `security/quarantine/mattpocock-skills/` já estagiada — commit upstream `694fa30`, LICENSE MIT preservada, `_catalog.yaml` com vereditos preliminares, `security/scan-absorbed.sh` → exit 0 (PASS 2 / WARN 2 / FAIL 0; WARNs = comandos curl/ssh em docs legítimas + AgentShield offline).
**A fazer nesta fase:** capturar os resources ainda `not_captured` que vamos absorver (`grill-with-docs/{CONTEXT-FORMAT,ADR-FORMAT}.md` e `improve-codebase-architecture/{LANGUAGE,HTML-REPORT}.md`); revisão manual dos 2 WARNs; reset de sessão pós-quarentena (regra de higiene).
**Cobre:** habilita R9-01, R9-02, R9-03, R9-05.
**Done:** resources alvo capturados; WARNs inspecionados e anotados; `_catalog.yaml` com vereditos finais alinhados ao relatório.

### Fase B — Skill `/grelha` + glossário `CONTEXT.md`

**Objetivo (goal-backward):** o usuário consegue rodar `/grelha` e sair com alinhamento + um `CONTEXT.md` glossário-only no projeto.
**Entregar:** `source/skills/grelha/SKILL.md` (núcleo grill-me + modo `--docs` + modo `--rapido`) + `CONTEXT-FORMAT.md` (resource) + rule `source/rules/common/ubiquitous-language.md` (com a distinção tripla dos "CONTEXT").
**Cobre:** R9-01, R9-02.
**Done:** skill autorada com fronteira documentada vs `gsd-discuss-phase`/`/doubt`; rule deploya em `.claude/rules/` + `.cursor/rules/` (paridade R8-09); dry-run de grilling produz um `CONTEXT.md` que respeita as regras de ouro (glossário-only).

### Fase C — ADR leve + integração com espelhamento Obsidian

**Objetivo (goal-backward):** decisões irreversíveis que emergem do grilling viram ADRs mínimos rastreáveis, sem pipeline novo.
**Entregar:** `source/skills/grelha/ADR-FORMAT.md` (gate dos 3 critérios + formato mínimo), wiring com `docs/decisions/` (numeração sequencial, criação preguiçosa) e confirmação de que o `/extract-learnings` já espelha `docs/decisions/` → Obsidian `Decisions/`.
**Cobre:** R9-03.
**Done:** `/grelha` oferece ADR só quando os 3 critérios passam e pula caso contrário; um ADR de exemplo nasce em `docs/decisions/` e é espelhado pelo fluxo existente.

### Fase D — Gate de alinhamento opcional na Deia

**Objetivo (goal-backward):** a Deia oferece grilling na hora certa (risco/ambiguidade) sem virar fricção.
**Entregar:** Passo 1.5 no `source/skills/idea/SKILL.md` (heurística de disparo + regra de skip), +2 linhas na matriz de roteamento, nota de fronteira `/grelha × gsd-discuss-phase × /doubt`.
**Cobre:** R9-04.
**Done:** roteamento continua transparente; pedido mecânico/claro pula o gate; "manda ver" escapa; exemplo de roteamento ambíguo no SKILL.md atualizado.

### Fase E — Ritual de deepening arquitetural

**Objetivo (goal-backward):** o usuário tem um ritual recorrente que mantém os módulos profundos e o design navegável, falado no vocabulário do projeto.
**Entregar:** decisão skill-nova-vs-enriquecimento registrada; se skill → `source/skills/improve-architecture/SKILL.md` (glossário de arquitetura + deletion test + relatório HTML em tmp + grilling loop reusando R9-02/R9-03).
**Cobre:** R9-05.
**Done:** ritual roda contra a codebase do próprio IdeiaOS (ou um produto) e produz ≥1 candidato de deepening com before/after, sem sujar o repo; usa termos do `CONTEXT.md`.

### Fase F — Empacotamento, propagação, README + ADR de postura + auditoria

**Objetivo (goal-backward):** o delta chega às máquinas via marketplace/adapters, documentado, com a postura de design registrada e o milestone auditado.
**Entregar:** `CORE_SKILLS` + `plugin-membership.md` + `modules.json` atualizados em sincronia; `build-plugins.sh`/`build-adapters.sh` rodados; `README.md` sincronizado; ADR de postura anti-framework (R9-07); dogfood `/doubt` sobre o próprio diff; auditoria de milestone (`v9-MILESTONE-AUDIT.md`).
**Cobre:** R9-06, R9-07.
**Done:** gates binários verdes (membership 0 deriva, readme N/N, build OK, idea-doctor 0 FAIL, bats verde); ADR de postura criado e espelhado; auditoria PASSED; pronto para tag v9.0.

---

## Progresso

| Fase | Objetivo | Cobre | Status |
|------|----------|-------|--------|
| A — Quarentena & atribuição | material auditado + atribuído | (habilita R9-01/02/03/05) | ✅ pré-feita (revalidar resources) |
| B — `/grelha` + `CONTEXT.md` | grilling + glossário ubíquo | R9-01, R9-02 | ⬜ TODO |
| C — ADR leve + Obsidian | decisões irreversíveis rastreáveis | R9-03 | ⬜ TODO |
| D — Gate de alinhamento na Deia | grilling na hora certa, escapável | R9-04 | ⬜ TODO |
| E — Ritual de deepening | saúde de design contínua | R9-05 | ⬜ TODO |
| F — Empacotamento + postura + auditoria | propagação + governança + ship | R9-06, R9-07 | ⬜ TODO |

## Dependências entre fases

- B depende de A (resources `CONTEXT-FORMAT`/`ADR-FORMAT`).
- C depende de B (`/grelha` precisa existir para oferecer ADR).
- D depende de B (o gate dispara `/grelha`).
- E depende de B+C (reusa glossário + ADR inline) e pode rodar em paralelo a D.
- F fecha tudo (empacota o que B–E produziram).

## Sequência de execução recomendada

`A (revalidar) → B → C → D → E → F`. B é o caminho crítico (entrega o maior valor isolado: GAP 1 + GAP 2). D e E podem paralelizar após B/C. F é serial no fim.
