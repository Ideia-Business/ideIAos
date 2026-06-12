---
phase: 08-ideiaos-v3-review
plan: 02
subsystem: documentation
tags: [skills, workflow, design-suite, learning-loop, redundancy-audit]
dependency_graph:
  requires: []
  provides: [docs/v3/skills-guide.md]
  affects: [08-04-PLAN.md, manifests/modules.json]
tech_stack:
  added: []
  patterns: [skills-guide, workflow-clusters, redundancy-map]
key_files:
  created:
    - docs/v3/skills-guide.md
  modified: []
decisions:
  - "design é orquestrador de sub-skills (brand, design-system, ui-styling, banner-design, slides) — não substituí-los; manter todas com escopo delimitado"
  - "/instinct-analyze é invocação manual deliberada sem scheduler — gap documentado para 08-04"
  - "slides (claudekit) é candidata a aposentar em favor do subsistema de slides embutido no design-system (mais robusto)"
metrics:
  duration_minutes: 45
  completed_date: "2026-06-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 0
requirements_satisfied: [F08-SKILLS-GUIDE]
---

# Phase 08 Plan 02: Skills Guide Summary

## One-liner

Guia de uso dos 34 skills em 5 clusters de workflow com sequências por cenário, anti-patterns, exemplos canônicos e mapa de 10 redundâncias identificadas por inspeção direta dos SKILL.md.

## Tasks Completadas

| Task | Nome | Commit | Arquivos |
|------|------|--------|----------|
| 1 | Inspecionar 34 skills e atribuir clusters | — | (análise, sem arquivo próprio) |
| 2 | Escrever docs/v3/skills-guide.md | 2ae329c | docs/v3/skills-guide.md |

## Deviations from Plan

None — plano executado exatamente como especificado. Os clusters sugeridos no plano foram mantidos com refinamentos menores baseados nos SKILL.md reais.

## Verification Table

| Check | Resultado |
|-------|-----------|
| Doc exists | PASS |
| SOURCE header (`# SOURCE: IdeiaOS v2` na linha 1) | PASS |
| No HTML comment (`<!--`) | PASS (0 ocorrências) |
| Workflow section presente | PASS (1 ocorrência) |
| Redundancy map presente | PASS (1 ocorrência) |
| Anti-patterns / quando NÃO usar | PASS (5 ocorrências) |
| Canonical example | PASS (5 ocorrências, 1 por cluster) |
| Min 120 linhas | PASS (282 linhas) |
| 34 skills cobertas | PASS (8+10+6+7+3 = 34) |

## Top-3 Achados

### 1. A suíte de design tem sobreposição estrutural intencional mas não documentada

`design` é um orquestrador que roteia para `brand`, `design-system`, `ui-styling`, `banner-design` e `slides` como sub-skills. Porém `banner-design`, `brand`, `slides` também existem como skills standalone. Isso não é um bug — é uma decisão de distribuição (usuário pode usar só `brand` sem a suíte completa), mas não estava explicitado em nenhum SKILL.md. O guia documenta essa hierarquia.

### 2. `slides` (claudekit standalone) é redundante com o subsistema de slides do `design-system`

O `design-system` tem um slide system completo (BM25 search, 8 CSVs de estratégia/layout/copywriting, `search-slides.py`, `slide-token-validator.py`, contextual decision flow com sparkline). O `slides` claudekit é uma versão mais simples do mesmo propósito. **Candidato a aposentar**: `slides` em favor do subsistema do `design-system`. Documentado no Mapa de Redundância.

### 3. `/instinct-analyze` sem scheduler é o gap mais impactante do Learning Loop

O loop de captura está incompleto: hooks capturam observações automaticamente em `observations.jsonl`, mas a destilação em instincts (via `/instinct-analyze`) é manual. Isso significa que observações podem acumular indefinidamente sem virar aprendizado. A skill documenta o trigger correto ("após sessão longa", "ao retomar projeto") mas não há automação. Este gap alimenta 08-04.

## Documentation Gaps (para 08-04)

1. `/instinct-analyze` sem scheduler automático — gap entre captura e destilação
2. `banner-design` referencia skills inexistentes no IdeiaOS (`ai-artist`, `ai-multimodal`, `chrome-devtools`, `frontend-design`)
3. Skills claudekit (`brand`, `design`, `design-system`, `ui-styling`, `slides`, `banner-design`) não têm `# SOURCE: IdeiaOS v2` — verificar compatibilidade com `build-adapters.sh`
4. `frontend-visual-loop` referencia `gsd-ui-review` que não existe em `source/skills/`
5. `ideiaos-catalog` menciona 60 módulos mas `modules.json` deve estar desatualizado (66+ módulos pós-Fase 07)

## Known Stubs

Nenhum stub. O guia documenta as 34 skills com base nos SKILL.md reais — nenhum campo fictício ou placeholder.

## Threat Flags

Nenhum. Arquivo de documentação (docs/v3/), sem surface de rede, auth ou schema.

## Self-Check: PASSED

- `docs/v3/skills-guide.md` existe: CONFIRMED
- Commit `2ae329c` existe: CONFIRMED
- 34 skills cobertas (8+10+6+7+3): CONFIRMED
- Nenhum `<!--` no arquivo: CONFIRMED
