---
phase: 01-quality-memory-hooks
plan: "01-03"
subsystem: hooks
tags: [bash, typescript, tsc, posttoolususe, asyncrewake, hooks]

# Dependency graph
requires: []
provides:
  - "hooks/typecheck-on-edit.sh: PostToolUse bash hook que roda tsc --noEmit incremental em background e acorda Claude com erros via exit 2 + JSON additionalContext"
affects:
  - 01-04  # wave 2 — test-hooks.sh smoke test integration + settings.json registration

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TDD bash hook: test script RED (falha antes da implementacao) -> feat GREEN (todos passam)"
    - "Serializacao JSON segura via python3 json.dumps para output dinamico (evita quebra por caracteres especiais)"
    - "Detecao tsc local: $CWD/node_modules/.bin/tsc > global tsc > exit 0 silencioso (Pitfall 1)"
    - "asyncRewake contract: exit 2 + JSON stdout acorda Claude; exit 0 = silencioso"

key-files:
  created:
    - hooks/typecheck-on-edit.sh
    - hooks/test-typecheck-on-edit.sh
  modified: []

key-decisions:
  - "cd $CWD em subshell para garantir que tsconfig.json do projeto seja usado pelo tsc"
  - "Truncar output do tsc a 30 linhas para evitar ultrapassar limite de 10k chars do additionalContext"
  - "python3 json.dumps obrigatorio para serializar saida do tsc (caracteres especiais explodem concatenacao bash)"
  - "test-typecheck-on-edit.sh incluido no repo como parte do contrato de validacao (Wave 2 o integra em test-hooks.sh)"

patterns-established:
  - "Pattern: hook bash com TDD minimo — test script executa antes do script-alvo existir para confirmar RED"
  - "Pattern: tsc hook exit 2 = asyncRewake wakeup; exit 0 = silencioso (sem poluicao de contexto)"

requirements-completed: [typecheck]

# Metrics
duration: 2min
completed: 2026-06-11
---

# Phase 01 Plan 03: typecheck-on-edit.sh Summary

**PostToolUse hook que roda tsc --noEmit incremental em background, detecta tsc local em node_modules/.bin, serializa erros via python3 json.dumps e acorda Claude via exit 2 (asyncRewake contract)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-06-11T23:28:44Z
- **Completed:** 2026-06-11T23:31:09Z
- **Tasks:** 1 (TDD: test RED + feat GREEN)
- **Files modified:** 2 created

## Accomplishments

- Hook `typecheck-on-edit.sh` implementado com 85 linhas, cobrindo todos os criterios de aceite do plano
- Deteccao de tsc local (`$CWD/node_modules/.bin/tsc`) com fallback para global e saida silenciosa se ausente
- Serializacao JSON segura via `python3 json.dumps` — mitiga T-01-08 (Tampering por output com caracteres especiais)
- Exit 2 com `additionalContext` para asyncRewake; exit 0 silencioso para .ts valido, non-ts, ou sem tsc
- Smoke test script com 10 casos validando todos os acceptance criteria e cenarios de borda

## TDD Gate Compliance

- RED gate commit: `568b3d6` — `test(01-03): add failing smoke tests for typecheck-on-edit.sh` (10 testes falham, hook inexistente)
- GREEN gate commit: `387f208` — `feat(01-03): implement typecheck-on-edit.sh PostToolUse hook` (10/10 passam)
- REFACTOR: nao necessario — implementacao direta, sem codigo duplicado

## Task Commits

1. **Task 1 RED: smoke tests (failing)** — `568b3d6` (test)
2. **Task 1 GREEN: implementacao do hook** — `387f208` (feat)

## Files Created/Modified

- `hooks/typecheck-on-edit.sh` — PostToolUse hook: filtra .ts/.tsx, detecta tsc local, roda --noEmit incremental, serializa erros JSON, exit 2 + additionalContext
- `hooks/test-typecheck-on-edit.sh` — Smoke test script: 10 casos cobrindo non-ts, no-tsc, acceptance criteria estaticos (.ts|.tsx case, noEmit, json.dumps, node_modules/.bin/tsc, exit 2) e .js/.tsx cenarios de borda

## Decisions Made

- `cd $CWD` em subshell para garantir uso do `tsconfig.json` correto do projeto (nao do diretorio do hook)
- Truncar output do tsc a 30 linhas — previne ultrapassar limite de 10.000 chars do `additionalContext` (Pitfall 6 mitigation)
- `python3 json.dumps` obrigatorio para serializar output dinamico do tsc — segue "Don't Hand-Roll" do RESEARCH
- `test-typecheck-on-edit.sh` incluido no repo (nao apenas local) — Wave 2 (plano 01-04) integra ao `test-hooks.sh`

## Deviations from Plan

None - plano executado exatamente conforme especificado. TDD RED/GREEN seguido rigorosamente. Todos os acceptance criteria atendidos sem ajustes.

## Threat Surface Scan

Nenhuma nova superficie de seguranca alem do descrito no `<threat_model>` do plano:
- T-01-07 (tsc de node_modules): aceito conforme plano — tsc local e o comportamento esperado
- T-01-08 (caracteres especiais no output): mitigado via `python3 json.dumps` (implementado)
- T-01-09 (tsc lento bloqueia UI): registro `async:true + asyncRewake:true + timeout:60` fica para plano 01-04 (settings.json)

## Known Stubs

Nenhum stub — hook implementa contrato completo. O registro em `settings.json` (async, asyncRewake, timeout:60) e responsabilidade do plano 01-04 conforme especificado no objetivo do plano.

## Next Phase Readiness

- `hooks/typecheck-on-edit.sh` pronto para deploy via `setup.sh` (plano 01-04/01-05)
- `hooks/test-typecheck-on-edit.sh` pronto para integracao no `test-hooks.sh` (plano 01-04)
- settings.json registration pendente (plano 01-04): `PostToolUse, matcher: "Edit|Write", async: true, asyncRewake: true, timeout: 60`

---
*Phase: 01-quality-memory-hooks*
*Completed: 2026-06-11*
