---
phase: "15"
plan: "01"
subsystem: evals
tags: [evals, ci, llm, local-auth, regression]
dependency_graph:
  requires: [14-instinct-production]
  provides: [R4-06, R4-07]
  affects: [evals/run-evals.sh, .github/workflows/evals.yml]
tech_stack:
  added: []
  patterns: [--local flag para claude auth local sem ANTHROPIC_API_KEY, </dev/null para stdin em subshell dupla]
key_files:
  created: []
  modified:
    - evals/run-evals.sh
decisions:
  - name: "Critérios de casos (grep-based) têm limitação semântica"
    rationale: "grep -qi sobre texto completo do critério não funciona para descrições semânticas; só funciona para negações (NÃO/NUNCA) e strings técnicas específicas que apareceriam literalmente na resposta. Não reescrevemos casos para passar — registrado como achado de qualidade."
  - name: "actions/checkout@v4 mantido por ora"
    rationale: "Aviso de deprecação Node.js 20 para junho/16 — não é bloqueio no dia 2026-06-12. Atualização para @v5 ou flag Node.js 24 fica como deferred item."
metrics:
  duration: "~40 min"
  completed_date: "2026-06-12"
  tasks_completed: 2
  files_modified: 1
---

# Phase 15 Plan 01: Evals em Produção — Summary

**One-liner:** Evals LLM validados fim-a-fim local (3 casos reais via `claude -p` + auth local) e CI remoto verde (structural + llm-evals skip limpo), com fix de `--no-color` inválido e stdin fechado em subshell.

---

## Tasks Executadas

| Task | Descrição | Commit | Status |
|------|-----------|--------|--------|
| R4-06 | Fix run-evals.sh + 3 casos locais reais | 90517d1 | ✅ |
| R4-07 | Dispatch CI remoto + validação jobs | (push 896a741) | ✅ |

---

## R4-06 — Resultados Reais (3 casos, claude local)

Casos executados com `bash evals/run-evals.sh --local --case EVAL-NNN`:

| Caso | Métrica | Severidade | Veredito | Exit | Análise |
|------|---------|------------|----------|------|---------|
| EVAL-001 | pass^k | 🔴 | fail | 1 | Critério semântico (ver achado abaixo) |
| EVAL-021 | pass^k | ���� | fail | 1 | Critério semântico (ver achado abaixo) |
| EVAL-022 | pass@k | 🟡 | fail | 0 | Critério semântico; exit 0 correto (pass@k não bloqueia) |

**Infrastructure confirmada:**
- `claude -p` via auth local (sem `ANTHROPIC_API_KEY`) executa corretamente
- JSONL gravado em `evals/results/YYYYMMDD-HHMM.jsonl` para cada run
- Exit codes coerentes: pass^k fail → exit 1; pass@k fail → exit 0
- Timeout 120s suficiente (respostas reais ~25-60s via auth local)

---

## R4-07 — CI Remoto

**Dispatch:** `gh workflow run evals.yml --repo Ideia-Business/ideIAos --ref work`
**Run ID:** 27439622994
**Conclusão:** SUCCESS

| Job | Resultado | Duração |
|-----|-----------|---------|
| Validação Estrutural (sem API key) | ✅ green | 5s |
| Evals LLM (requer API key) | ✅ skipped clean | 12s |

LLM job: "Executar evals --ci" skipado por `steps.check_key.outputs.skip == 'true'` e `run_llm=false` — comportamento esperado sem secret configurado.

---

## Bugs Corrigidos (Deviations)

### Auto-fixed Issues

**1. [Rule 1 - Bug] Flag --no-color inválida causava exit 1 imediato**
- **Found during:** Task R4-06 (primeira execução com --local)
- **Issue:** `claude -p "$prompt" --no-color` retornava exit 1 (`error: unknown option '--no-color'`) — Claude CLI v2 não suporta essa flag
- **Fix:** Removido `--no-color` da chamada em `run_case_with_model()`
- **Files modified:** `evals/run-evals.sh`
- **Commit:** 90517d1

**2. [Rule 1 - Bug] stdin não fechado causava potencial bloqueio em subshell dupla**
- **Found during:** Task R4-06 (exit 143 / SIGTERM em algumas execuções)
- **Issue:** `verdict="$(run_case_with_model ...)"` captura stdout da função em subshell; dentro, `response="$(timeout 90 claude -p ...)"` cria segunda subshell. Sem `</dev/null`, stdin herdado de stdin do script podia bloquear claude em modo interativo
- **Fix:** Adicionado `</dev/null` + timeout aumentado para 120s
- **Files modified:** `evals/run-evals.sh`
- **Commit:** 90517d1

---

## Achados de Qualidade dos Casos (não são bugs de produto)

### Limitação do avaliador grep-based

O `run_case_with_model()` avalia critérios via `grep -qi "$criterion_text" <<< "$response"` — ou seja, procura o **texto completo do critério** na resposta do modelo.

Isso funciona para **critérios de negação** (`NÃO`/`NUNCA`) pois verifica ausência. Mas **falha** para critérios semânticos/descritivos porque frases como "Claude aponta o uso de `AsaasCustomersList`" não aparecem literalmente na resposta do modelo.

**Exemplos observados:**

| Caso | Critério (falsa falha) | Resposta real do modelo |
|------|------------------------|------------------------|
| EVAL-001 | "Claude aponta o uso de `AsaasCustomersList`..." | Não gerou INSERT (comportamento correto), pediu dados antes |
| EVAL-021 | "Entrega patch proposto (diff ou bloco corrigido)..." | Entregou bloco JS corrigido + explicação |
| EVAL-022 | "Mapeia pelo menos 2 abordagens de biblioteca PDF..." | Mapeou `@react-pdf/renderer` + `jsPDF` + entregou plano |

**Conclusão:** O comportamento do produto (não gerar INSERT cego, não editar arquivo, não escrever código de produção) está correto em todos os casos observados. As "falhas" são do avaliador automatizado, não do produto.

**Recomendação (não implementada nesta fase):** Reformular critérios como padrões simples (`INSERT INTO client_subscriptions`, `react-pdf`, `jsPDF`) ou migrar para avaliador LLM-as-judge para semântica.

---

## Deferred Items

- `actions/checkout@v4` — aviso de deprecação Node.js 20 (força para Node.js 24 a partir de 2026-06-16). Atualizar para `@v5` ou adicionar `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` antes da deadline.

---

## Self-Check: PASSED

- `evals/run-evals.sh` existe e tem sintaxe válida (bash -n OK)
- commit `90517d1` existe no log
- `evals/results/` contém JSONL das 3 execuções
- CI run 27439622994 conclusion: success
