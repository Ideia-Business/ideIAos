---
phase: 12
plan: 12-01
subsystem: evals
tags: [evals, ci, runner, llm, bash]
dependency_graph:
  requires: []
  provides: [run_case_with_model, CI_MODE_flag, evals_results_dir]
  affects: [evals/run-evals.sh, evals/results/.gitignore]
tech_stack:
  added: []
  patterns: [bash 3.2 compat, perl alarm timeout fallback, JSONL output]
key_files:
  created: [evals/results/.gitignore]
  modified: [evals/run-evals.sh]
decisions:
  - Negation criterion grep uses full criterion text as pattern (not keyword extraction) — simpler and sufficient for current cases
  - RESULTS_FILE initialized only when DRY_RUN=0 to avoid creating results/ in dry-run mode
  - Stub test with fake claude binary documents CI behavior without real API cost
metrics:
  duration: ~10min
  completed: 2026-06-12
---

# Phase 12 Plan 01: Runner LLM + Política de Saída Summary

**One-liner:** `run_case_with_model()` implementado com `claude -p` headless, timeout 90s (perl fallback), avaliação de critérios por grep com detecção de negação, flag `--ci` com política exit 1/0 diferenciada por métrica pass^k/pass@k, resultados em JSONL.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | run_case_with_model() + --ci flag | de91454 | evals/run-evals.sh |
| 2 | evals/results/.gitignore | de91454 | evals/results/.gitignore |

## Verification Results

| Critério | Resultado |
|----------|-----------|
| `bash -n evals/run-evals.sh` exit 0 | PASS |
| `--dry-run` conta 22 casos | PASS (22) |
| `--list` conta 22 casos EVAL- | PASS (22) |
| `--ci` reconhecido sem "desconhecido" | PASS |
| `evals/results/.gitignore` existe | PASS |
| `git check-ignore *.jsonl` ignora arquivo | PASS |
| Stub test 1 caso CI mode (fake claude) | PASS — exit 1 correto em pass^k fail |

## Deviations from Plan

None - plan executed exactly as written.

**Stub test note:** Tested `--ci` with fake `claude` binary returning pass-like text on EVAL-001. The negation criterion (`Claude NÃO gera INSERT`) matched the stub output (which contained the criterion text), correctly triggering `fail` and exit 1. This validates CI policy without real API cost.

## Known Stubs

None — `run_case_with_model()` is fully implemented. The old "TODO" stub is replaced.

## Self-Check: PASSED

- [x] `evals/run-evals.sh` exists and passes `bash -n`
- [x] `evals/results/.gitignore` exists
- [x] Commit de91454 exists
