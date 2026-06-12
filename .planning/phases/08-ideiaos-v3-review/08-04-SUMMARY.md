---
phase: 08-ideiaos-v3-review
plan: 04
subsystem: docs/v3
tags: [synthesis, v3-roadmap, gap-analysis, orchestration]
dependency_graph:
  requires: [08-01-agents-audit, 08-02-skills-guide, 08-03-token-economy-review]
  provides: [v3-review, v3-roadmap, prioritized-gaps]
  affects: [README.md, docs/v3/]
tech_stack:
  added: []
  patterns: [gap-prioritization, roadmap-derivation, audit-synthesis]
key_files:
  created:
    - docs/v3/v3-review.md
    - docs/v3/v3-roadmap.md
  modified:
    - README.md
decisions:
  - "15 gaps totais: 4 P1 (agents sem model/tools, instinct-loop, evals-sem-CI), 7 P2, 4 P3"
  - "v3 order: agent-contracts primeiro (custo zero), depois token-optimizations, instinct-loop, evals-ci"
  - "slides standalone candidata a aposentadoria em favor do subsistema design-system (mapeado G-12 área)"
metrics:
  duration: "~35 min"
  completed_date: "2026-06-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 1
---

# Phase 08 Plan 04: v3-synthesis Summary

**One-liner:** Síntese das 3 auditorias Wave 1 em 15 gaps priorizados P1/P2/P3 com 6 fases candidatas v3 derivadas dos gaps.

---

## O que foi feito

### Task 1: Consolidar auditorias + gaps de orquestração

Todos os três docs Wave 1 (`agents-audit.md`, `skills-guide.md`, `token-economy-review.md`) foram lidos e seus gaps extraídos. Os 6 candidatos de gaps de orquestração do plano foram avaliados contra o sistema real:

- CI/CD: confirmado ausente (sem `.github/`)
- Multi-repo: autosync existe mas sem propagação em lote para projetos-alvo
- Evals automáticas: `run-evals.sh` manual por design (decisão 07-02), `run_case_with_model()` como ponto de extensão nomeado
- Instinct loop: captura automática, destilação manual — gap confirmado pelo próprio `skills-guide.md`
- Deny rules: enforcement manual em máquinas existentes
- Contexts (Fase 07): não verificados por `idea-doctor.sh`
- Falso positivo `nc `: confirmado ainda ativo em `scan-absorbed.sh`

Total: 15 gaps deduplicated e priorizados em tabela `G-01..G-15`.

### Task 2: Escrever v3-review.md, v3-roadmap.md e sincronizar README

**docs/v3/v3-review.md** (109 linhas): primeira linha `# SOURCE: IdeiaOS v2`, sem `<!--`, 5 seções (Resumo, Síntese das Auditorias, Gaps de Orquestração, Gaps Priorizados, Recomendação v3), tabela com 15 gaps G-01..G-15 com ID/Gap/Origem/Prioridade/Esforço/Valor.

**docs/v3/v3-roadmap.md** (150 linhas): primeira linha `# SOURCE: IdeiaOS v2`, 6 fases candidatas v3 agrupando os gaps por coerência (agent-contracts, instinct-loop-automation, evals-ci, token-optimizations, security-dx, manifest-cleanup), cada fase com goal, gaps fechados, entregas, esforço/valor, dependências.

**README.md**: nova subseção "Revisão v3 (Fase 08)" na seção "Documentação canônica do ideIAos" apontando para `docs/v3/v3-review.md`, `docs/v3/v3-roadmap.md` e os três docs Wave 1.

`check-readme-sync.sh` passou: 89/89 componentes mencionados, exit 0. Commit sem `--no-verify`.

---

## Gaps Priorizados (G-01..G-15)

| ID | Gap | Prioridade |
|----|-----|------------|
| G-01 | `claude-continuation` e `ideiaos-checker` sem `model:` e `tools:` no frontmatter | P1 |
| G-02 | `ideiaos-checker.md` com `name: setup-checker` — inconsistência filename vs modules.json | P1 |
| G-03 | `/instinct-analyze` sem scheduler automático — captura automática, destilação manual | P1 |
| G-04 | `run-evals.sh` nunca executa automaticamente — suíte de 22+ casos é rede de papel | P1 |
| G-05 | `silent-failure-hunter` em opus, mas processo é grep patterns fixos — candidato a sonnet | P2 |
| G-06 | `strategic-compact` usa subprocess python3 a cada tool call | P2 |
| G-07 | `typescript-lsp` não adotado com `installStrategy: stack:typescript` | P2 |
| G-08 | Ausência de CI/CD — regressões detectadas só manualmente | P2 |
| G-09 | Multi-repo em lote: sem propagação automática de setup para projetos-alvo | P2 |
| G-10 | Deny rules baseline dependem de ação manual em máquinas existentes | P2 |
| G-11 | Contexts (`claude-dev/review/research`) não verificados pelo `idea-doctor.sh` | P2 |
| G-12 | `banner-design` referencia skills inexistentes fora do modules.json | P3 |
| G-13 | `frontend-visual-loop` referencia `gsd-ui-review` ausente do manifesto | P3 |
| G-14 | `ideiaos-catalog` desatualizado — menciona 60 módulos, real é 66+ | P3 |
| G-15 | `nc ` em scan-absorbed.sh gera falsos positivos em TypeScript | P3 |

---

## Deviations from Plan

None — plan executed exactly as written. The `v3-review.md` was already partially present in the working tree (from a prior autosync commit at 08:38 that captured it before this session ran). The file content was complete and met all criteria; no rewrite was needed.

---

## Self-Check: PASSED

- `docs/v3/v3-review.md` exists: FOUND
- `docs/v3/v3-roadmap.md` exists: FOUND
- `README.md` references `docs/v3`: FOUND (5 occurrences)
- `v3-review.md` first line: `# SOURCE: IdeiaOS v2`
- `v3-roadmap.md` first line: `# SOURCE: IdeiaOS v2`
- No `<!--` in either file: CONFIRMED (grep returns 0)
- Gap rows in v3-review.md: 15 (>=10)
- `## Gaps de Orquestração` section: FOUND
- `check-readme-sync.sh` exit: 0 (89/89 mencionados)
- Commits containing the files: `1e4a2c5` (v3-review.md), `2f6d66f` (v3-roadmap.md + README)
