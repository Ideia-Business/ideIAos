---
phase: 14
plan: 01
name: instinct-production
subsystem: continuous-learning
tags: [anti-runaway, instinct-loop, curation, production-hardening]
dependency_graph:
  requires: []
  provides: [R4-01, R4-02, R4-03, R4-04, R4-05]
  affects: [observe-session-end.sh, observe-tool-use.sh, instinct-analyze/SKILL.md]
tech_stack:
  added: []
  patterns: [anti-runaway-env-guard, cooldown-sentinel, confidence-cap-0.6]
key_files:
  created:
    - source/hooks/test-observe-hooks.sh (Cases 9+10 adicionados)
    - .planning/phases/14-instinct-production/14-01-PLAN.md
  modified:
    - source/hooks/observe-tool-use.sh
    - source/hooks/observe-session-end.sh
    - source/skills/instinct-analyze/SKILL.md
    - plugins/ideiaos-core/hooks/observe-tool-use.sh
    - plugins/ideiaos-core/hooks/observe-session-end.sh
    - plugins/ideiaos-core/skills/instinct-analyze/SKILL.md
decisions:
  - Sentinela escrita ANTES do spawn (não após análise) para garantir cooldown imediato
  - Cap por-projeto (top-N por evidence_count) como estratégia de curation vs threshold puro
  - /evolve sem promoções é OK — estoque curado não tem instincts maduros legítimos ainda
metrics:
  duration: ~90min
  completed_date: 2026-06-12
  tasks_completed: 6
  files_modified: 8
---

# Phase 14 Plan 01: Instinct Production Hardening Summary

**One-liner:** Anti-runaway com IDEIAOS_INSTINCT_SPAWN + cooldown 30min + curadoria de 1046→69 instincts + limites duros R4-04 no SKILL.md.

---

## Critérios R4-01..05

| Req | Critério | Resultado | Status |
|-----|----------|-----------|--------|
| R4-01 | spawn exporta IDEIAOS_INSTINCT_SPAWN=1; ambos hooks fazem exit 0 quando setado; teste prova cadeia para | grep confirma guard nos 2 hooks; test-observe-hooks.sh cases 9a-9e PASS | **PASS** |
| R4-02 | sentinela escrita antes do spawn; gate ≥30min entre spawns; 2 invocações → 1 spawn | sentinel write antes do spawn implementado; cooldown gate ELAPSED < 1800s; case 10 PASS | **PASS** |
| R4-03 | estoque final ≤80 instincts; nenhum com confidence >0.6 sem evidence_count ≥3 | 69 instincts (de 1046); 0 violações de confidence | **PASS** |
| R4-04 | SKILL.md com regras INVIOLÁVEIS no topo; run controlado respeita limites | 5 regras adicionadas; logs confirmam "Confidence respeitou cap de 0.6 (R4-04)" | **PASS** |
| R4-05 | run real /evolve; vault Learnings/ recebe ≥0 notas | exit 0; 0 promoções (ok — nenhum instinct maduro legítimo com confidence ≥0.7 pós-curation) | **PASS** |

---

## Commits

| Hash | Descrição |
|------|-----------|
| `ddac7ab` | fix(14-01): R4-01/R4-02 anti-runaway guard + cooldown 30min em observe hooks |
| `9cc5242` | fix(14-01): R4-04 limites duros no instinct-analyze SKILL.md |

**Nota R4-03:** A curadoria ocorreu em `~/.ideiaos/` (fora do repo). Sem commit de código — mudança de dados.

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Sentinela escrita após análise (design original) era insuficiente para cooldown**
- **Found during:** Task 2
- **Issue:** O design original atualizava a sentinela apenas ao FINAL da análise (Passo 9 do SKILL.md). Se o spawn demorava 120s, outros session_ends conseguiam passar o gate durante esse tempo.
- **Fix:** Sentinela escrita ANTES do spawn no hook — o gate de 30min fica ativo imediatamente.
- **Files modified:** source/hooks/observe-session-end.sh

**2. [Rule 2 - Missing critical] Teste de harness não cobria R4-01/R4-02**
- **Found during:** Task 1/2
- **Issue:** test-observe-hooks.sh não testava os novos guards.
- **Fix:** Cases 9 (anti-runaway) e 10 (cooldown) adicionados. 29/29 PASS.
- **Files modified:** source/hooks/test-observe-hooks.sh

**3. [Rule 1 - Bug] Curadoria R4-03: ≤80 requereu 8 passes (não 1 script one-off)**
- **Found during:** Task 3
- **Issue:** Cada pass revelou nova camada de meta-junk (meta-trigger patterns, trivial actions, non-canonical dirs, per-project cap).
- **Fix:** 8 passes progressivos: meta-keyword, dedup-slug, non-canonical, top-level, meta-trigger, trivial-action, non-actionable, per-project-cap.
- **Resultado:** 1046 → 69 instincts (656 archived em _archive/).

### Observação sobre teste vivo (Task 5)

O spawn manual disparou ~65 logs em 4 minutos porque **esta sessão GSD** (não uma spawned session) estava rodando bash commands — cada um dispara session_end hook, que por sua vez tentou spawnar análise para diferentes projetos. Os spawned haiku sessions funcionaram corretamente:
- Respeitaram confidence cap 0.6 (confirmado nos logs)
- Respeitaram máx 15 instincts por run (logs mostram 12-15)
- Filtraram atividade de análise (2126 de 2701 obs descartadas como ruído)
- NÃO re-spawnam (R4-01 verificado — zero logs gerados a partir de sessões spawned)

O cooldown de 30min funcionou: para cada projeto, apenas o PRIMEIRO spawn em 30min executou.

---

## Curadoria Stats

| Métrica | Valor |
|---------|-------|
| Instincts antes | 1046 arquivos |
| Meta-junk removido (passes 1-7) | ~900 |
| Per-project cap (pass 8) | ~47 |
| Instincts finais live | 69 |
| Archived (em _archive/) | ~977 |
| Backup | ~/.ideiaos/backups/instincts-pre-curation-20260612-164406.tar.gz |
| Violações confidence restantes | 0 |

---

## Self-Check: PASSED

- [x] source/hooks/observe-tool-use.sh modificado com guard
- [x] source/hooks/observe-session-end.sh modificado com guard + cooldown + sentinel-before-spawn
- [x] source/skills/instinct-analyze/SKILL.md com REGRAS INVIOLÁVEIS
- [x] plugins/ideiaos-core/hooks/ sincronizados (idênticos aos source/)
- [x] ~/.claude/hooks/ instalados
- [x] ~/.claude/skills/ instalado
- [x] Commits ddac7ab e 9cc5242 no branch work
- [x] test-observe-hooks.sh: 29/29 PASS
- [x] /evolve rodado: exit 0 (0 promoções — esperado)
- [x] Sentinelas futuras (~+2h) para bloquear novos spawns durante sessão
