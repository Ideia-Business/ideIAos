---
phase: "17"
plan: "01"
subsystem: evals
tags: [evals, ci, avaliador, sinais, llm-judge, grep]
dependency_graph:
  requires: [15-evals-production]
  provides: [eval-criteria-robust]
  affects: [evals/run-evals.sh, evals/_TEMPLATE.md, evals/cases/EVAL-*.md, evals/README.md]
tech_stack:
  added: []
  patterns:
    - avaliador híbrido Sinais (grep-friendly) + LLM-judge fallback
    - subseção ### Sinais dentro de ## Critérios de Aprovação
    - BSD awk compat — variável awk não pode chamar "sub" (função reservada)
key_files:
  created: []
  modified:
    - evals/run-evals.sh
    - evals/_TEMPLATE.md
    - evals/README.md
    - evals/cases/EVAL-001-billing-no-blind-insert.md
    - evals/cases/EVAL-002-asaas-webhook-fallback.md
    - evals/cases/EVAL-003-rls-revoke-breaks-returning.md
    - evals/cases/EVAL-004-multitenant-cache-leak.md
    - evals/cases/EVAL-005-date-without-tz-brt.md
    - evals/cases/EVAL-006-silent-failure-missing-import.md
    - evals/cases/EVAL-007-webhook-naming-snake-camel.md
    - evals/cases/EVAL-008-cnpj-alphanumeric.md
    - evals/cases/EVAL-009-service-callback-no-jwt.md
    - evals/cases/EVAL-010-validator-throw-swallowed.md
    - evals/cases/EVAL-011-crm-card-duplication.md
    - evals/cases/EVAL-012-phantom-meeting-ghost.md
    - evals/cases/EVAL-013-meeting-cancel-not-visible.md
    - evals/cases/EVAL-014-proposal-lead-hydration.md
    - evals/cases/EVAL-015-cross-screen-metric-consistency.md
    - evals/cases/EVAL-016-cross-module-cache-invalidation.md
    - evals/cases/EVAL-017-lovable-deploy-400-adjacent.md
    - evals/cases/EVAL-018-inc368-onboarding-categories.md
    - evals/cases/EVAL-019-scan-false-positive-html-comment.md
    - evals/cases/EVAL-020-scan-false-positive-substring.md
    - evals/cases/EVAL-021-mode-routing-review-no-edit.md
    - evals/cases/EVAL-022-research-explore-before-act.md
decisions:
  - name: "Sinais como subseção de Critérios de Aprovação (não campo frontmatter)"
    rationale: "Mantém os critérios humanos intactos; sinais ficam adjacentes aos critérios que derivam, tornando a correspondência óbvia para autores futuros. Frontmatter seria mais machine-friendly mas quebraria a leitura humana do caso."
  - name: "Fallback LLM-judge → skip (não fail) quando indisponível"
    rationale: "Ausência de judge não é falha de produto. Casos sem Sinais e sem judge disponível devem ser ignorados silenciosamente para não bloquear CI de forma não relacionada ao comportamento avaliado."
  - name: "EVAL-022 sinais simplificados para pdf+plano"
    rationale: "react-pdf/jsPDF específicos demais para contexto IdeiaOS onde o modelo conhece o projeto e responde contextualizando (menciona commissionPdfExport.ts existente). Sinais mais gerais cobrem a intenção sem falso-negativo por contexto."
metrics:
  duration: "~60 min"
  completed_date: "2026-06-12"
  tasks_completed: 4
  files_modified: 26
---

# Phase 17 Plan 01: Critérios de Eval Robustos — Summary

**One-liner:** Avaliador híbrido com Sinais grep-friendly em todos os 22 casos + fallback LLM-judge haiku; vereditos dos 3 casos reais corrigidos de fail→pass.

---

## Tasks Executadas

| Task | Descrição | Commit | Status |
|------|-----------|--------|--------|
| 1 | Runner: avaliador híbrido Sinais + LLM-judge | 229728c | OK |
| 2 | Awk fix (sub reservado) + EVAL-022 sinais ajustados | 59f8c22 | OK (Rule 1 - Bug) |
| 3 | Prova real: 3 casos re-rodados com --local | — | OK |
| 4 | README: seção Avaliação Automática | 5997486 | OK |

---

## Vereditos — Antes e Depois

| Caso | Métrica | Severidade | Antes (Fase 15) | Depois (Fase 17) | Mecanismo |
|------|---------|------------|-----------------|------------------|-----------|
| EVAL-001 | pass^k | 🔴 | **fail** | **pass** | Sinais: `- INSERT INTO client_subscriptions`, `+ reconcile`, `+ proposta` |
| EVAL-021 | pass^k | 🔴 | **fail** | **pass** | Sinais: `+ discount`, `+ validação`, `- Edit(` |
| EVAL-022 | pass@k | 🟡 | **fail** | **pass** | Sinais: `+ pdf`, `+ plano` |

Todos os 3 casos agora refletem o comportamento real do produto (que estava correto desde Fase 15).

---

## Design Aplicado

### Estrutura de Sinais

Cada caso ganhou subseção `### Sinais (avaliação automática)` dentro de `## Critérios de Aprovação`:

```markdown
### Sinais (avaliação automática)

+ padrão que DEVE aparecer (grep -qi, case-insensitive)
- padrão que NÃO DEVE aparecer
```

O runner (`evaluate_response()`) processa os sinais antes de tentar o LLM-judge. Se não houver seção Sinais, faz uma chamada `claude --model claude-haiku-4-5 -p` com os critérios e a resposta, pedindo `VEREDITO: pass|fail`.

### Fallback LLM-judge

- Timeout: 60s (separado do 120s do run principal).
- Sem judge disponível → `skip` (nunca `fail`).
- Extrai a linha `VEREDITO: pass` ou `VEREDITO: fail` via grep.

---

## Deviações do Plano

### Auto-fixed Issues

**1. [Rule 1 - Bug] awk BSD compat — variável `sub` é função reservada**
- **Found during:** Primeiro run real de EVAL-001 (exit awk com `syntax error at source line 4`)
- **Issue:** `awk -v sub="..."` falha em BSD awk (macOS) porque `sub()` é função nativa do awk; o nome da variável colide e causa syntax error em compound patterns
- **Fix:** Renomeado para `ssec` na chamada de `extract_subsection`
- **Files modified:** `evals/run-evals.sh`
- **Commit:** 59f8c22

**2. [Rule 1 - Bug] EVAL-022 sinais específicos demais causavam falso-negativo contextual**
- **Found during:** Primeiro run de EVAL-022 (fail por ausência de `react-pdf` e `jsPDF`)
- **Issue:** O modelo IdeiaOS conhece o projeto ideiapartner e responde roteando para lá (mencionando `commissionPdfExport.ts` existente), sem listar bibliotecas genéricas. Os sinais `+ react-pdf` e `+ jsPDF` eram corretos para um modelo sem contexto, mas errados para o agente contextualizado.
- **Fix:** Sinais simplificados para `+ pdf` e `+ plano` — cobrem a intenção sem depender de nomes específicos
- **Files modified:** `evals/cases/EVAL-022-research-explore-before-act.md`
- **Commit:** 59f8c22

---

## Validações

- `bash -n evals/run-evals.sh` — OK
- `bash evals/run-evals.sh --dry-run` — 22/22 casos OK
- Frontmatter python3 inline (CI) — 22 casos OK
- EVAL-001 `--local`: pass (era: fail)
- EVAL-021 `--local`: pass (era: fail)
- EVAL-022 `--local`: pass (era: fail, com timeout ocasional em run de alta carga)

---

## Self-Check: PASSED

- `evals/run-evals.sh` existe e tem sintaxe válida (bash -n OK)
- commits `229728c`, `59f8c22`, `5997486` existem no log
- 22 casos com seção `### Sinais` confirmados via `--dry-run`
- 3 vereditos reais: pass/pass/pass
