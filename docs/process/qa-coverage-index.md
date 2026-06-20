# SOURCE: índice de cobertura de QA do IdeiaOS (v12) — DADOS informativos
<!-- Taxonomia de dimensões inspirada em testzeus-hercules (AGPL-3.0) — conceito-only, zero código/prosa. -->

## Por que este índice

O IdeiaOS cobre QA por várias skills/agents distintos, sem um índice que os liste lado a lado
nem nomeie os gaps conhecidos. Este doc é esse índice — **referência, não nova maquinaria**.

## Dimensões de QA × cobertura atual

| Dimensão | Coberto por | Status |
|---|---|---|
| Funcional / UI | `frontend-visual-loop`, `e2e-testing` | ✅ |
| Acessibilidade (WCAG) | `accessibility`, `web-quality` | ✅ |
| Performance / Core Web Vitals | `web-quality`, `benchmark-optimization-loop` | ✅ |
| Segurança (web + LLM) | `security-reviewer` (+ OWASP LLM Top 10 — v12), `gsd-secure-phase`, `rls-reviewer` | ✅ |
| Lógica / regressão | `tdd`, `pr-test-analyzer`, `silent-failure-hunter`, `evals/` | ✅ |
| Revisão de código | `code-review`, `gsd-code-review`, `coderabbit`, `typescript/react-reviewer` | ✅ |
| **API-contract testing (REST/GraphQL)** | `api-design` cobre **design** do contrato, não **teste** dele | ⚠️ GAP registrado |
| **Visual-regression** | — | ⚠️ GAP registrado |
| **Mobile-emulation** | — | ⚠️ GAP registrado |

## Os 3 gaps (registro, não skill prematura)

Os gaps acima são **registrados** para alimentar `gsd-code-review` / `gsd-secure-phase` ao
revisar features que os tocam — **não viram skills até a demanda doer** (enforce-simplicity).
Quem implementar uma feature de API pública, UI visualmente crítica, ou mobile deve tratar a
dimensão correspondente como cobertura faltante e decidir **conscientemente** o trade-off
(marcar `debt:` se aceito por ora, ou abrir fase GSD se a feature exige a dimensão).

> Datado 2026-06-19 (v12). Atualizar quando uma das 3 dimensões ganhar cobertura real.
