# E-01-SUMMARY — Fase E: ritual de deepening `/improve-architecture` (`/aprofundar`)

**Milestone:** v9 · **Fase:** E (SHOULD) · **Status:** ✅ DONE · **Cobre:** R9-05 (GAP 3) · **Data:** 2026-06-17
**Modo:** workflow (1 builder + painel 3-lentes)

## Decisão registrada (ADR)

`docs/decisions/deepening-skill-vs-agente.md` — **skill nova** `/improve-architecture` (alias `/aprofundar`), NÃO enriquecer `refactor-cleaner`/`code-simplifier`. Racional: ritual recorrente com fluxo próprio em 3 fases (explorar→HTML→grilling) + glossário de arquitetura + integração CONTEXT.md/ADR não cabe num agente single-shot de limpeza. Gate dos 3 critérios avaliado e passa (reverter=médio, surpreendente=sim, trade-off=sim). Status: Aceito. (Decisão pré-tomada pelo orquestrador conforme recomendação do relatório §8; o ADR a documenta.)

## Entregue

| Arquivo | Linhas | O quê |
|---------|--------|-------|
| `docs/decisions/deepening-skill-vs-agente.md` | 70 | ADR da decisão skill-vs-agente (slug descritivo, convenção do repo) |
| `source/skills/improve-architecture/SKILL.md` | 207 | Skill `/aprofundar`: 3 fases (Explorar [lê CONTEXT.md + docs/decisions/ antes; deletion test] → Relatório HTML em `$TMPDIR` → Grilling loop reusando disciplina do `/grelha`); ritual recorrente; fronteira vs refactor-cleaner/code-simplifier/doubt; R8-04 |
| `source/skills/improve-architecture/LANGUAGE.md` | 87 | Glossário de arquitetura PT-BR (Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality); atribuições fiéis (Feathers→Seam; Ousterhout só no enquadramento rejeitado depth-as-ratio) |
| `source/skills/improve-architecture/HTML-REPORT.md` | 158 | Scaffold do relatório em `<tmpdir>/architecture-review-<ts>.html` (não suja o repo); Tailwind+Mermaid CDN; card por candidato; ZERO `<!--` |
| `README.md` | +2 | `/improve-architecture` na tabela de skills + árvore (44 skills) |

## Verificação

- **Painel 3-lentes: PASS / PASS / PASS.** goal-backward (R9-05 entregue, 5 must_haves verificados por gate binário); **adversarial = zero fabricação** (todas as atribuições — Ousterhout, Feathers, deletion test, "interface é a superfície de teste" — verificadas fiéis à fonte); convenção = zero não-conformidades.
- **Gates binários:** `name: improve-architecture` ✓; SOURCE ✓; deletion test ✓; alias `/aprofundar` ✓; LANGUAGE + HTML-REPORT não-vazios ✓; ZERO `<!--` em toda a pasta (gate `! grep -rq '<!--'` passa) ✓; ADR ≥12l ✓; SKILL ≥70l ✓.

## Decisões / desvios
- INTERFACE-DESIGN.md do upstream (4º resource) NÃO foi criado (fora do escopo do plano) — o desenho de interface foi dobrado em guidance inline no grilling loop, com nota de divergência.
- Paths do upstream (`docs/adr/`, `../grill-with-docs/`) adaptados aos reais do IdeiaOS (`docs/decisions/`, `source/skills/grelha/`).

## Carry-forward (Fase F)
- Registrar `improve-architecture` em `CORE_SKILLS` (build-plugins.sh) + `plugin-membership.md` + `manifests/modules.json` (drift-guard R7-07).
- `/aprofundar` é alias — confirmar matching no loader (como `/grill`).
- v9.0 vs v9.1: E foi incluída no v9.0 (entregue sem incidente).
