---
phase: 12-evals-ci
verified: 2026-06-12T17:10:00Z
status: human_needed
score: 5/6 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Push com mudança em source/ ou evals/ aciona o workflow no GitHub"
    expected: "Workflow aparece na aba Actions; job structural inicia automaticamente; llm-evals aparece mas skip step se sem secret"
    why_human: "Requer push real ao repositório remoto e acesso à UI do GitHub Actions para confirmar o trigger"
  - test: "Job structural falha corretamente em caso de frontmatter inválido"
    expected: "Remover campo obrigatório de um EVAL-*.md → CI falha com mensagem indicando o campo ausente"
    why_human: "Requer commit com arquivo corrompido e observação de resultado real no CI"
gaps:
  - truth: "ANTHROPIC_API_KEY ausente em CI_MODE=1 retorna skip (não fail) e nunca bloqueia com exit 1"
    status: partial
    reason: "run_case_with_model() retorna 'skip' corretamente, mas o loop principal ainda conta o caso skip em pass_hat_total sem exclui-lo — resultado: skip causa exit 1 em modo --ci, contrariando a intenção do plano (skip não deve bloquear)"
    artifacts:
      - path: "evals/run-evals.sh"
        issue: "Linhas 250-256: verdito 'skip' não exclui o caso da contagem pass_hat_total; verdito skip != pass incrementa pass_hat_total mas não pass_hat_aprovados, triggering exit 1 na linha 275"
    missing:
      - "Adicionar guard no loop: if [[ \"$verdict\" == \"skip\" ]]; then continue; fi antes das linhas 250-256"
      - "Alternativamente, incrementar pass_hat_aprovados para skip (skip conta como aprovado para fins de bloqueio)"
---

# Phase 12: evals-ci Verification Report

**Phase Goal:** A suíte de 22+ evals executa automaticamente em push via GitHub Actions; `run-evals.sh` usa API key de CI; invariantes bloqueiam merge em falha.
**Verified:** 2026-06-12T17:10:00Z
**Status:** human_needed (1 gap + 2 human items)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | Push em source/ ou evals/ dispara workflow sem intervenção manual | ? UNCERTAIN | Workflow criado com triggers corretos (push+PR em source/\*\* e evals/\*\*); trigger real não verificável sem push ao remoto |
| SC2 | Falha em invariante (pass^k) → exit 1 bloqueia PR; falha em capacidade (pass@k) → warning sem bloquear | ✓ VERIFIED (com ressalva) | Stub test confirm: fake claude fail em EVAL-001 (pass^k) → exit 1; fake claude fail em EVAL-002 (pass@k) → exit 0. Ressalva: skip em CI_MODE também dispara exit 1 (ver gap) |
| SC3 | run-evals.sh invoca API Claude e produz PASS/FAIL para 22 casos quando key disponível | ✓ VERIFIED | run_case_with_model() implementado com claude -p, timeout 90s, perl fallback; avaliação por grep; stub test com fake claude executa caminho completo e grava JSONL |
| SC4 | evals/README.md contém instruções para configurar o secret | ✓ VERIFIED | Seção "CI/CD — Execução Automática" presente (linha 94); instruções do secret em linhas 121-126; tabela pass^k/pass@k presente |

**Must-haves verificados (contexto de verificação):**

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | run_case_with_model() com claude -p, timeout 90s, sem jq, sem mapfile, bash 3.2, flag --ci | ✓ VERIFIED | bash -n exit 0; timeout 90 + perl fallback presentes; sem mapfile/declare -A/jq; CI_MODE default; --ci seta DRY_RUN=0 |
| 2 | `bash evals/run-evals.sh --dry-run </dev/null` exit 0 com 22 casos; --list ok; --ci --dry-run ok | ✓ VERIFIED | dry-run conta 22; list conta 22 EVAL-; --ci --dry-run exit 0; nenhum "desconhecido" |
| 3 | R3-13: pass^k fail → exit 1; pass@k fail → warn exit 0 — no código + documentado em README | ⚠ PARTIAL | Código OK para fail real; FALHA para skip (no key + CI_MODE=1 → exit 1 indevido). README documenta corretamente a política |
| 4 | .github/workflows/evals.yml: 2 jobs (structural sempre; llm-evals com skip silencioso); YAML parseável | ✓ VERIFIED | 2 jobs confirmados; structural sem if top-level; llm-evals com skip via check_key output; YAML estruturalmente válido (PyYAML indisponível em macOS, validação manual completa) |
| 5 | Stub test: fake claude → 1 caso roda pelo caminho CI e gera resultado; evals/results/*.jsonl gitignored | ✓ VERIFIED | Fake claude EVAL-001 → verdict=fail → JSONL gravado; EVAL-002 → exit 0; git ls-files --others --ignored confirma .jsonl ignorado |
| 6 | Frontmatter dos 22 casos valida via python3 inline do workflow, reproduzível localmente | ✓ VERIFIED | python3 inline do workflow executado localmente: "Frontmatter OK em 22 casos" |

**Score:** 5/6 must-haves (must-have 3 está PARTIAL; o skip-trigger-exit1 é um bug de comportamento de borda)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `evals/run-evals.sh` | run_case_with_model() implementada com execução real | ✓ VERIFIED | 282 linhas; função presente linhas 119-192; not a stub |
| `evals/results/.gitignore` | Ignora *.jsonl e *.md | ✓ VERIFIED | Existe; *.jsonl confirmado ignorado via git ls-files |
| `.github/workflows/evals.yml` | 2 jobs + triggers corretos | ✓ VERIFIED | 152 linhas; structural + llm-evals; push/PR/workflow_dispatch |
| `evals/README.md` | Seção CI/CD com política pass^k/pass@k + setup do secret | ✓ VERIFIED | 190 linhas; seção "CI/CD" em linha 94; tabela de política em linha 114 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| run-evals.sh | claude CLI | `timeout 90 claude -p "$prompt_text" --no-color` | ✓ WIRED | Linha 156; perl fallback linha 158 |
| run-evals.sh | evals/results/*.jsonl | `RESULTS_FILE` + printf + >> | ✓ WIRED | Linhas 113-116 (init), 244-248 (write) |
| evals.yml structural | run-evals.sh | `bash evals/run-evals.sh --dry-run` (step) | ✓ WIRED | Linha 98 do workflow |
| evals.yml llm-evals | run-evals.sh --ci | `bash evals/run-evals.sh --ci` condicional | ✓ WIRED | Linha 141; condicionado a check_key.outputs.skip != 'true' |
| evals.yml llm-evals | secrets.ANTHROPIC_API_KEY | env: ANTHROPIC_API_KEY | ✓ WIRED | Linha 143 |
| evals.yml structural | python3 inline | frontmatter validation script | ✓ WIRED | Linhas 56-95; testado localmente |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| bash -n syntax check | `bash -n evals/run-evals.sh` | exit 0 | ✓ PASS |
| --dry-run 22 casos | `bash evals/run-evals.sh --dry-run </dev/null \| grep -c "[dry-run]"` | 22 | ✓ PASS |
| --list 22 casos | `bash evals/run-evals.sh --list \| grep -c "EVAL-"` | 22 | ✓ PASS |
| --ci --dry-run exit 0 | `bash evals/run-evals.sh --ci --dry-run </dev/null` | exit 0 | ✓ PASS |
| --ci sem key → skip | `ANTHROPIC_API_KEY="" CI_MODE=1 ... --case EVAL-001` | verdict=skip, mas exit 1 | ✗ BUG (ver gap) |
| pass^k fail → exit 1 | Fake claude + EVAL-001 (pass^k) | exit 1 | ✓ PASS |
| pass@k fail → exit 0 | Fake claude + EVAL-002 (pass@k) | exit 0 | ✓ PASS |
| JSONL gravado | Execução com fake claude + key | arquivo .jsonl criado | ✓ PASS |
| JSONL ignorado | `git ls-files --others --ignored --exclude-standard evals/results/` | 3 arquivos listados | ✓ PASS |
| frontmatter 22 casos | python3 inline do workflow executado localmente | "Frontmatter OK em 22 casos" | ✓ PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| R3-11 | 12-01 | run_case_with_model() com execução real via API | ✓ SATISFIED | Implementado em run-evals.sh linhas 119-192 |
| R3-12 | 12-02 | GitHub Actions workflow com job structural e llm-evals | ✓ SATISFIED | .github/workflows/evals.yml completo |
| R3-13 | 12-01 e 12-02 | Política pass^k/pass@k + documentação | ⚠ PARTIAL | Código correto para fail real; skip sem key em --ci dispara exit 1 indevidamente. Documentação correta no README |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| evals/README.md | 72-90 | Seção "Como Executar" diz "não chama modelo LLM" e descreve run_case_with_model() como "TODO / ponto de extensão futuro" — informação desatualizada após Plan 01 | ⚠ Warning | Documentação inconsistente com comportamento real; plano explicitamente não alterou seções existentes — intencionalmente desatualizada |

Nenhum marcador TBD/FIXME/XXX encontrado em arquivos modificados pela fase.

---

### Human Verification Required

#### 1. Push trigger ativa o workflow no GitHub

**Test:** Fazer push de uma mudança em `evals/` para o branch `work` ou `main` e observar a aba Actions no GitHub
**Expected:** Workflow "Evals — IdeiaOS" aparece; job `structural` inicia e completa (pass ou fail); job `llm-evals` inicia mas pula o step "Executar evals --ci" se `ANTHROPIC_API_KEY` não configurado como secret
**Why human:** Requer push ao repositório remoto e acesso à UI do GitHub Actions; não verificável via grep/bash local

#### 2. Frontmatter inválido falha o job structural

**Test:** Editar um EVAL-*.md temporariamente removendo um campo obrigatório (ex: `metric:`), fazer push, observar CI
**Expected:** Job `structural` falha com mensagem indicando o arquivo e campo ausente; job `llm-evals` não é iniciado (pois depende de structural via `needs: structural`)
**Why human:** Requer commit com arquivo corrompido e observação do resultado real no CI

---

### Gaps Summary

**1 gap bloqueante identificado (comportamento de borda):**

O método `run_case_with_model()` retorna corretamente `"skip"` quando `ANTHROPIC_API_KEY` está ausente em CI_MODE. Porém, o loop principal (linhas 250-256) não trata o veredito `"skip"` de forma especial: o caso é contabilizado em `pass_hat_total` mas não em `pass_hat_aprovados`, fazendo com que o sumário CI dispare `exit 1` com "BLOQUEIO" mesmo para casos meramente pulados por ausência de key.

Na prática, o fluxo real de CI do workflow nunca chama `run-evals.sh --ci` sem key (o step "Executar evals --ci" é condicionado ao check_key.outputs.skip != 'true'). O bug é portanto de borda: afeta apenas quem invoca o script manualmente sem chave, mas contradiz a especificação do PLAN ("retornar skip (não fail) — nunca trava").

**Fix necessário:** No loop, adicionar `[[ "$verdict" == "skip" ]] && continue` antes das linhas de contagem (250-256).

---

_Verified: 2026-06-12T17:10:00Z_
_Verifier: Claude (gsd-verifier)_
