---
milestone: v3
audited: 2026-06-12
status: passed
phases_audited: 5 (09–13)
requirements_checked: 19 (R3-01..R3-19)
cross_phase_checks: 8/8 executed
blockers: 1
warnings: 2
---

# v3 Milestone Audit — IdeiaOS

**Milestone:** v3 — Refinamento e Automação  
**Fases:** 09 agent-contracts · 10 token-optimizations · 11 instinct-loop-automation · 12 evals-ci · 13 security-dx-manifest  
**Status:** GAPS_FOUND — 1 blocker, 2 warnings

---

## Resultado dos 8 Cross-Phase Checks

| # | Check | Comando | Resultado | Status |
|---|-------|---------|-----------|--------|
| 1 | Contrato agents (09) sobrevive a 10-13 | `bash scripts/build-adapters.sh --target all --dry-run` | exit 0 — "All agents have valid frontmatter contracts" | PASS |
| 2 | Plugins regenerados consistentes | `bash scripts/build-plugins.sh && git status --porcelain plugins/` | exit 0; git status vazio (0 mudanças) | PASS |
| 3 | modules.json válido, 72 módulos, typescript-lsp + script-apply-to-all presentes | python3 assert | 72 módulos; `typescript-lsp` presente; `script-apply-to-all-projects` presente | PASS |
| 4a | `~/.claude/skills/instinct-analyze/SKILL.md` existe | `ls ~/.claude/skills/instinct-analyze/SKILL.md` | exit 0 | PASS |
| 4b | Sentinela `~/.ideiaos/instincts/.last-analyzed-ideiaos` existe | `ls ~/.ideiaos/instincts/.last-analyzed-ideiaos` | exit 0 | PASS |
| 4c | ≥1 instinct em `~/.ideiaos/instincts/project/` | `ls \| wc -l` | 50 arquivos | PASS |
| 5a | `bash evals/run-evals.sh --ci --dry-run </dev/null` exit 0 | executado | exit 0, 22 casos listados | PASS |
| 5b | workflow yml existe | `ls .github/workflows/evals.yml` | exit 0 | PASS |
| 5c | Fix do skip presente (`grep -A2 'skip' run-evals.sh \| grep continue`) | executado | `continue` encontrado em linhas 252-254 | PASS |
| 6 | `bash scripts/idea-doctor.sh` 0 FAIL; Seções 7a+8 presentes | executado | OK:48 WARN:0 FAIL:0; Seção 7a linha 153; Seção 8 linha 199 | PASS |
| 7 | R3 coverage | cruzamento VERIFICATIONs | ver tabela abaixo | PARTIAL (1 gap) |
| 8a | `bash -n setup.sh` | executado | exit 0 | PASS |
| 8b | `check-readme-sync` exit 0 | executado | 92/92 — exit 0 | PASS |

---

## Wiring Summary

**Connected:** 18 conexões verificadas end-to-end  
**Orphaned:** 0 exports criados sem uso  
**Missing:** 1 critério de aceitação não implementado (R3-07 parcial)

## API / Script Coverage

**Wired:** build-adapters.sh → source/agents/*.md (validate_agent_contracts); observe-session-end.sh → ~/.ideiaos/instincts/.last-analyzed-{proj}; run-evals.sh → claude CLI; apply-to-all-projects.sh → setup.sh --project-only; idea-doctor.sh → ~/.claude/settings.json + ~/.ideiaos/contexts/  
**Orphaned:** nenhum

## E2E Flows

**Complete:** 5/6  
**Broken:** 1 (parcial — ver BLOCKER abaixo)

---

## Detailed Findings

### BLOCKER

**B-01 — R3-07: `idea-doctor.sh` não verifica typescript-lsp em projetos TypeScript**

- **Requirement:** R3-07 — critério de aceitação 3: "`idea-doctor.sh` verifica presença do LSP em projetos TypeScript"
- **Expected connection:** Fase 10 (typescript-lsp em modules.json + setup.sh) → Fase 13 (idea-doctor.sh deve incluir check de LSP)
- **Actual state:** `grep -n "typescript\|lsp\|LSP\|typescript-lsp" scripts/idea-doctor.sh` retorna vazio. O doctor tem 8 seções; nenhuma cobre LSP.
- **Phase 10 VERIFICATION status:** Marcou R3-07 como SATISFIED cobrindo apenas 2 dos 3 critérios (modules.json entry + setup.sh install). O terceiro critério (idea-doctor check) foi omitido silenciosamente da verificação.
- **Impact:** R3-07 está PARTIAL. Ambientes TypeScript com typescript-lsp ausente passam pela triagem do doctor sem WARN.
- **Fix:** Adicionar seção ao `scripts/idea-doctor.sh` que, quando `detect_stack` detecta typescript no projeto-alvo, verifica se o LSP está configurado (tsconfig path acessível, entry em modules.json presente).

### WARNINGS

**W-01 — REQUIREMENTS.md: header declara 18 requisitos, mas o documento lista 19 (R3-01..R3-19)**

- **File:** `/Users/gustavolopespaiva/dev/IdeiaOS/.planning/REQUIREMENTS.md` linha 7: `Total de requisitos v3: 18`
- **Actual count:** `grep -c "^### R3-" .planning/REQUIREMENTS.md` → 19
- **Impact:** Inconsistência de contagem no cabeçalho. Não afeta funcionalidade, mas confunde auditores futuros.
- **Fix:** Corrigir linha 7 de `18` para `19`.

**W-02 — Phase 12 VERIFICATION: `evals/README.md` Seção "Como Executar" desatualizada**

- **File:** `evals/README.md` linhas 72-90
- **Issue:** Descreve `run_case_with_model()` como "TODO / ponto de extensão futuro", mas a função foi implementada na Fase 12. Documentação contradiz o comportamento real.
- **Acknowledged in VERIFICATION:** Sim — 12-VERIFICATION.md linha 116 classifica como Warning intencional ("plano explicitamente não alterou seções existentes"). Registrado para visibilidade.
- **Fix:** Atualizar seção "Como Executar" do README para refletir que `run_case_with_model()` está implementado e invoca a API via `ANTHROPIC_API_KEY`.

### Anti-Patterns / Observações

- **Phase 11 status `human_needed`:** O adendo no final do 11-VERIFICATION.md registra execução end-to-end real com 574 observações, 9+ instincts gerados, sentinela atualizada. Status efetivo: passed. Loop completo provado em produção.
- **Phase 12 skip-bug (resolvido):** O gap apontado na 12-VERIFICATION (skip causa exit 1 indevido) está **corrigido** no código atual — `evals/run-evals.sh` linhas 252-254 contêm o guard `if [[ "$verdict" == "skip" ]]; then continue; fi`. O bug foi resolvido após a VERIFICATION ser escrita.
- **modules.json count drift entre fases:** Fase 10 VERIFICATION diz 71 módulos; Fase 13 diz 72; contagem real atual é 72. Drift esperado e explicado pela adição de `script-apply-to-all-projects` na Fase 13.

---

## Requirements Integration Map

| Requirement | Fase | Caminho de integração | Status | Issue |
|-------------|------|-----------------------|--------|-------|
| R3-01 | 09 | `source/agents/{claude-continuation,ideiaos-checker}.md` → `validate_agent_contracts()` em build-adapters.sh | WIRED | — |
| R3-02 | 09 | `ideiaos-checker.md` (name: ideiaos-checker) → modules.json (id: agent-ideiaos-checker) → plugins/ideiaos-core (diff vazio) | WIRED | — |
| R3-03 | 09 | `build-adapters.sh` `validate_agent_contracts()` → loop source/agents/*.md → exit 1 se campo ausente | WIRED | — |
| R3-04 | 09 | `ideiaos-checker.md` seção `--auto-apply` → plugins/ideiaos-core/agents/ideiaos-checker.md (idêntico) | WIRED | — |
| R3-05 | 10 | `source/agents/silent-failure-hunter.md` (model: sonnet) → build-adapters validate → plugins copy | WIRED | — |
| R3-06 | 10 | `source/hooks/strategic-compact.sh` (bash puro) → ~/.claude/hooks/strategic-compact.sh (diff vazio) | WIRED | — |
| R3-07 | 10 | modules.json (typescript-lsp) + setup.sh (detect_stack) — **idea-doctor.sh LSP check ausente** | PARTIAL | BLOCKER B-01: critério 3 do acceptance não implementado |
| R3-08 | 11 | `observe-session-end.sh` gate+spawn → `claude -p /instinct-analyze` haiku → `~/.ideiaos/instincts/` | WIRED | End-to-end provado em produção (adendo 11-VERIFICATION) |
| R3-09 | 11 | `observe-session-end.sh` TS_OBS vs TS_LAST compare → no-op se sentinela futuro | WIRED | — |
| R3-10 | 11 | `instinct-analyze/SKILL.md` seção "Trigger automático" + Passo 9 (sentinela) | WIRED | — |
| R3-11 | 12 | `run-evals.sh` `run_case_with_model()` linhas 119-192 → `claude -p` + timeout 90 + JSONL output | WIRED | — |
| R3-12 | 12 | `.github/workflows/evals.yml` (push source/** + evals/**) → 2 jobs (structural + llm-evals) | WIRED | Trigger real não verificável sem push ao remoto (human item pendente) |
| R3-13 | 12 | pass^k → exit 1; pass@k → exit 0+warn; skip → continue (guard presente) | WIRED | W-02: README seção desatualizada (cosmético) |
| R3-14 | 13 | `idea-doctor.sh` linha 160 WARN deny rules ausentes → sugere install-global-patches.sh | WIRED | — |
| R3-15 | 13 | `idea-doctor.sh` linhas 199-227 Seção 8 → ~/.ideiaos/contexts/{dev,review,research}.md | WIRED | — |
| R3-16 | 13 | `security/scan-absorbed.sh` linha 71 `\bnc\b` word-boundary | WIRED | — |
| R3-17 | 13 | `ideiaos-catalog/SKILL.md` "70+ módulos" + len() dinâmico; modules.json 72 entradas | WIRED | — |
| R3-18 | 13 | `banner-design/SKILL.md` (claudekit-origin ×2); `frontend-visual-loop/SKILL.md` (externo: gsd-ui-review) | WIRED | — |
| R3-19 | 13 | `apply-to-all-projects.sh` dry-run → setup.sh --project-only; modules.json id: script-apply-to-all-projects; README 2 menções | WIRED | — |

**Requirements com integração cross-phase:**
- R3-07: Fase 10 (modules.json + setup.sh) DEVERIA conectar à Fase 13 (idea-doctor.sh) — conexão ausente (B-01)
- R3-03 + R3-05 + R3-08: todas dependem do contrato de Fase 09 — validado via build-adapters dry-run (PASS)

**Requirements sem touchpoint cross-phase (auto-contidos):**
- R3-04 (--auto-apply em ideiaos-checker: contido em source+plugin, sem consumer externo)
- R3-09 (gate de timestamp: contido em observe-session-end.sh)
- R3-16 (regex fix: contido em scan-absorbed.sh)

---

## Sumário Executivo

18 de 19 requisitos estão WIRED end-to-end. **1 blocker:** R3-07 tem critério de aceitação não implementado — `idea-doctor.sh` não verifica typescript-lsp em projetos TypeScript (os outros dois critérios do R3-07 estão completos). O milestone não pode ser declarado PASSED sem corrigir esse gap.

Todos os 8 cross-phase checks executaram com exit 0. O skip-bug da Fase 12 foi corrigido após a VERIFICATION. O loop de instincts (Fase 11) foi validado em produção com tokens reais. A suíte de builds (plugins, adapters) está limpa e consistente.

**Ação bloqueante:** Adicionar check de typescript-lsp em `scripts/idea-doctor.sh` e re-verificar R3-07.

---

_Auditado: 2026-06-12_  
_Auditor: Claude (cross-phase integration audit)_


## Adendo — correções aplicadas (2026-06-12, orquestrador)

- **B-01 corrigido:** idea-doctor.sh ganhou check 8d (typescript-lsp em projetos TS); doctor 49 OK / 0 FAIL.
- **W-01 corrigido:** REQUIREMENTS.md total 18→19.
- **W-02 corrigido:** evals/README.md agora documenta run_case_with_model() como implementada (Fase 12) com instruções de uso de --ci.

**Status final: PASSED — 19/19 requirements wired.**
