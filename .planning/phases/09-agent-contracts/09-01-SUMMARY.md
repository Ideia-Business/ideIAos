---
phase: 09
plan: 09-01
subsystem: agents
tags: [agent-contracts, frontmatter, canonical-name, validation, auto-apply]
requires: []
provides: [agent-frontmatter-contracts, ideiaos-checker-canonical-name, build-validation]
affects: [source/agents/claude-continuation.md, source/agents/ideiaos-checker.md, plugins/ideiaos-core/agents/ideiaos-checker.md, manifests/modules.json, scripts/build-adapters.sh, setup.sh]
tech-stack:
  added: []
  patterns: [frontmatter-contract, bash-validation-loop]
key-files:
  created: []
  modified:
    - source/agents/claude-continuation.md
    - source/agents/ideiaos-checker.md
    - plugins/ideiaos-core/agents/ideiaos-checker.md
    - scripts/build-adapters.sh
    - setup.sh
    - docs/v3/agents-audit.md
    - docs/v3/v3-review.md
decisions:
  - "Nome canônico ideiaos-checker (não setup-checker) — alinhado com filename"
  - "validate_agent_contracts() chamada antes do build, não como step separado"
  - "Docs históricos recebem nota (corrigido na Fase 09) sem reescrever"
metrics:
  duration: "~25 min"
  completed: "2026-06-12"
  tasks_completed: 4
  files_modified: 7
---

# Fase 09 Plan 01: Agent Contracts Summary

## One-liner

Frontmatter `model:` + `tools:` adicionados a claude-continuation e ideiaos-checker; nome canônico `ideiaos-checker` alinhado em source/plugins/setup.sh; build-adapters valida contrato de todos os 15 agents antes de copiar; `--auto-apply` documentado no spec do checker.

## Tasks Completed

| Task | Req | Description | Commit |
|------|-----|-------------|--------|
| 1 | R3-01 | model+tools frontmatter em claude-continuation.md e ideiaos-checker.md | 9bd9469 |
| 2 | R3-02 | Nome canônico ideiaos-checker: source + plugins + setup.sh + audit notes | 9bd9469 |
| 3 | R3-03 | validate_agent_contracts() em build-adapters.sh (exit 1 se faltar campo) | a81d421 |
| 4 | R3-04 | --auto-apply flag documentada no Passo 3 do ideiaos-checker spec | 4e21c57 |

## Acceptance Criteria Results

| Critério | Status | Evidência |
|----------|--------|-----------|
| R3-01: model+tools em claude-continuation e ideiaos-checker | PASS | `grep "model:\|tools:" source/agents/claude-continuation.md` → 2 campos; idem ideiaos-checker.md |
| R3-02: nome canônico; nenhum setup-checker em arquivo funcional | PASS | `git grep -l "setup-checker"` retorna apenas docs históricos/planning |
| R3-03: build-adapters exit 0 com todos agents válidos | PASS | `bash scripts/build-adapters.sh --target all --dry-run` exit 0; "✓ All agents have valid frontmatter contracts" |
| R3-04: --auto-apply documentado no spec | PASS | `grep "auto-apply" source/agents/ideiaos-checker.md` → 5 ocorrências na seção dedicada |
| bash -n clean | PASS | `bash -n scripts/build-adapters.sh` sem erros |
| README sync | PASS | `bash scripts/check-readme-sync.sh` → 91/91 ✅ |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] plugins/ideiaos-core/agents/ideiaos-checker.md também precisava atualização**
- Found during: Task 1/2
- Issue: O arquivo em plugins/ é cópia do source/ e também tinha `name: setup-checker` sem model/tools
- Fix: Aplicadas as mesmas correções (name, model, tools, --auto-apply) ao arquivo em plugins/
- Files modified: plugins/ideiaos-core/agents/ideiaos-checker.md

None other — plan executed as written for the remaining items.

## Known Stubs

None — all changes are complete specifications with no placeholder content.

## Threat Flags

None — changes are agent spec docs and a bash validation script; no new network endpoints, auth paths, or schema changes.

## Self-Check

- [x] source/agents/claude-continuation.md modified and committed (9bd9469)
- [x] source/agents/ideiaos-checker.md modified and committed (9bd9469, 4e21c57)
- [x] plugins/ideiaos-core/agents/ideiaos-checker.md modified and committed
- [x] scripts/build-adapters.sh modified and committed (a81d421)
- [x] setup.sh modified and committed (9bd9469)
- [x] build-adapters.sh --dry-run exit 0 confirmed
- [x] git grep setup-checker shows only historical docs
