# F-01-SUMMARY — Fase F: empacotamento + propagação + postura + auditoria

**Milestone:** v9 · **Fase:** F (saída/ship) · **Status:** ✅ DONE · **Cobre:** R9-06, R9-07 · **Data:** 2026-06-17

## Entregue

- **Empacotamento em sincronia (drift-guard R7-07):** `grelha` + `improve-architecture` em `CORE_SKILLS` (build-plugins.sh) **e** na tabela "Skills core (30)" do `plugin-membership.md` — nomes idênticos, 0 deriva. `manifests/modules.json` (+3 entradas: `skill-grelha`, `skill-improve-architecture`, `rule-ubiquitous-language`; 93→96 módulos; JSON válido).
- **README "Como usar no dia a dia":** subseção sobre `/grelha` (alinhar antes de planejar; Deia oferece no Passo 1.5) e `/improve-architecture` (`/aprofundar`). Tabela de skills + árvore já adicionadas em B/E.
- **Postura (R9-07):** ADR `docs/decisions/v9-mattpocock-skills-absorcao.md` já existia (Aceito); referenciado por 1 linha nos headers de `grelha/SKILL.md` e `improve-architecture/SKILL.md` (absorvemos técnica, não ideologia; sob orquestração da Deia). Sem reescrita.
- **Artefatos gerados (commitados):** `plugins/ideiaos-core/skills/{grelha,improve-architecture}/` (build-plugins) + `.claude/rules/ideiaos-common-ubiquitous-language.md` + `.cursor/rules/ideiaos-common-ubiquitous-language.mdc` (build-adapters, paridade R8-09).

## Gates binários (exit code)

| Gate | Resultado |
|------|-----------|
| `check-plugin-membership.sh` | ✅ exit 0 — 0 deriva (30 skills core) |
| `node JSON.parse modules.json` | ✅ OK (96 módulos) |
| `build-plugins.sh` | ✅ exit 0 — 2 skills empacotadas |
| `check-readme-sync.sh` | ✅ exit 0 — README sincronizado (44 skills) |
| `build-adapters.sh --target all` | ✅ exit 0 — rule nos 2 harnesses |
| `idea-doctor.sh` | ✅ exit 0 — 61 OK / 1 WARN / 0 FAIL |
| `bats tests/` | ⚠️ `bats` ausente no ambiente — pulado (v9 não tocou lógica testada) |

## Dogfood `/doubt` (revisor adversarial, contexto fresco, diff completo do v9)

**Veredito: SHIP.** Fabricação zero (4 atribuições verificadas contra a quarentena), escopo fechado em R9-01..R9-07, Deia sem regressão (Passo 1.5 aditivo/escapável), scanner fence-aware sem buraco real (payload fora de fence ainda FALHA — provado por fixture), empacotamento consistente. **1 LOW pré-existente** (redação do README sobre escopo do `scan-absorbed.sh`) — diferido como item separado.

## Auditoria

`.planning/v9-MILESTONE-AUDIT.md` — **PASSED**. Tag `v9.0` (Fase E incluída no v9.0, sem fatiamento v9.1).

## Follow-ups (não-bloqueantes)
- Clarificar no README que o `scan-absorbed.sh` mira a quarentena, não `source/` (LOW do dogfood; pré-existente).
- Fase G could-haves (opcional): `to-prd` delta no @pm + nota no `/gsd-debug`.
