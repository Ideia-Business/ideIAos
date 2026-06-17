# v9 — Milestone Audit: Camada de Alinhamento (Alignment Layer)

**Milestone:** v9 · **Auditado:** 2026-06-17 · **Veredito:** ✅ **PASSED → ship tag v9.0**
**Fonte:** absorção de `mattpocock/skills` (MIT, commit upstream `694fa30`) — quarentena em `security/quarantine/mattpocock-skills/`.
**Execução:** autônoma multi-agente (1 orquestrador + builders/revisores por fase via workflows); 6 fases A–F; estado canônico promovido v8→v9 no início.

## Requisitos R9-01..R9-07

| ID | Requisito | Fecha GAP | Fase | Status |
|----|-----------|-----------|------|--------|
| R9-01 | Skill `/grelha` (alias `/grill`) — grilling colaborativo pré-plano, 1 pergunta/vez c/ resposta recomendada, lê código, modos `--docs`/`--rapido` | GAP 2 | B | ✅ DONE |
| R9-02 | `CONTEXT.md` glossário-only durável + rule `ubiquitous-language` (distinção dos 3 CONTEXT) | GAP 1 | B | ✅ DONE |
| R9-03 | ADR ultraleve inline (gate dos 3 critérios) em `docs/decisions/`; espelhado ao Obsidian via `/extract-learnings` | GAP 1/2 | C | ✅ DONE |
| R9-04 | Gate de alinhamento OPCIONAL na Deia (Passo 1.5) — disparo por risco/ambiguidade, escapável, transparente | GAP 2 | D | ✅ DONE |
| R9-05 | Ritual de deepening `/improve-architecture` (`/aprofundar`) — glossário de arquitetura + deletion test + relatório HTML + grilling loop | GAP 3 | E | ✅ DONE |
| R9-06 | Empacotamento/propagação (CORE_SKILLS + membership + modules.json + README + adapters); atribuição MIT; gates verdes | infra | F | ✅ DONE |
| R9-07 | ADR de postura anti-framework (`docs/decisions/v9-mattpocock-skills-absorcao.md`) — referenciado + espelhado | governança | F | ✅ DONE (já existia) |

## Gates binários (exit code — não Read tool)

| Gate | Comando | Resultado |
|------|---------|-----------|
| Scan de quarentena | `scan-absorbed.sh security/quarantine/mattpocock-skills` | ✅ exit 0 — PASS 2 / WARN 2 / FAIL 0 (após Check-2 fence-aware) |
| modules.json válido | `node JSON.parse` | ✅ OK — 96 módulos |
| Drift-guard membership | `check-plugin-membership.sh` | ✅ exit 0 — 0 deriva (73 módulos c/ plugin; 30 skills core) |
| README sync | `check-readme-sync.sh` | ✅ exit 0 — README sincronizado (44 skills) |
| Build de plugins | `build-plugins.sh` | ✅ exit 0 — `grelha` + `improve-architecture` empacotadas em `plugins/ideiaos-core/skills/` |
| Build de adapters | `build-adapters.sh --target all` | ✅ exit 0 — rule deployada em `.claude/rules/ideiaos-common-ubiquitous-language.md` + `.cursor/rules/*.mdc` (paridade R8-09) |
| Doctor | `idea-doctor.sh` | ✅ exit 0 — 61 OK / 1 WARN / 0 FAIL |
| Suíte bats | `bats tests/` | ⚠️ `bats` ausente no ambiente — pulado (não-bloqueante: v9 não tocou a lógica de `spec-merge`/`v5-memory`/`v6-hooks`) |

## Revisão adversarial por fase + dogfood

- **Por fase (painéis 3-lentes):** B verifier PASS + `/doubt` pegou e corrigiu **citação embelezada** do Pragmatic Programmer (eco do dogfood do v8); C PASS (3-em-1); D PASS goal + **não-regressão PASS** (diff 52/0, 5 rotas canônicas idênticas); E PASS/PASS/PASS (adversarial confirmou zero fabricação).
- **Dogfood `/doubt` final (diff completo do v9):** **VEREDITO SHIP.** Fabricação zero (4 atribuições — Pragmatic Programmer, Feathers, Ousterhout, Evans — verificadas contra a quarentena); escopo fechado em R9-01..R9-07 (nada inventado); Deia sem regressão (Passo 1.5 aditivo/escapável); scanner fence-aware sem buraco real (payload fora de fence ainda FALHA, provado por fixture); empacotamento consistente (CORE_SKILLS=membership=modules.json).
- **1 achado LOW (não-bloqueante, pré-existente ao v9):** redação do `README` sobre o escopo do `scan-absorbed.sh` (alvo é a quarentena, não `source/`) — diferido como item separado.

## Segurança / proveniência

- Quarentena auditada (`security/scan-absorbed.sh` exit 0); WARNs benignos (curl/ssh em docs não-absorvidas; AgentShield offline).
- Atribuição MIT (`# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9`) presente em todas as skills/resources/rule novos; postura registrada em `docs/decisions/v9-mattpocock-skills-absorcao.md` (técnica, não ideologia; sob orquestração da Deia).
- Correção de precisão do scanner (`scan-absorbed.sh` Check-2 fence-aware) com control test: matches dentro de fenced code block (documentação) ignorados; matches fora de fence continuam FAIL.

## Veredito

**PASSED.** Os 7 requisitos entregues, todos os gates binários verdes (bats pulado por ausência de ambiente, não-bloqueante), dogfood adversarial = SHIP. A Fase E (SHOULD) foi incluída no v9.0 sem incidente — **sem fatiamento v9.1**. Pronto para tag `v9.0`.

## Addendum — Fase G (could-haves) entregue pós-v9.0 (2026-06-17)

Os dois deltas finos da `v9-IMPLEMENTATION-PLAN.md §G` foram absorvidos via overlay idempotente: **Patch 14** (`to-prd` → core_principle "síntese > entrevista" + quiz seams/módulos no @pm/Morgan) e **Patch 15** (`diagnose` → nota de seam no `/gsd-debug`). Aplicados na cópia instalada (`.aiox-core` do repo mantido pristine, mesmo padrão dos Patches 1/5). Contagem do overlay "13→15 patches" sincronizada em `install-global-patches.sh`/`README.md`/`idea-doctor.sh`. Gates: `bash -n` OK, run exit 0 (2 aplicados/0 falhas), idea-doctor Patch 14✓/15✓ (0 FAIL), readme-sync 114/114. Detalhe em `v9-phases/G-could-haves/G-01-SUMMARY.md`. `caveman`/`to-issues`/`triage` permanecem WON'T.
