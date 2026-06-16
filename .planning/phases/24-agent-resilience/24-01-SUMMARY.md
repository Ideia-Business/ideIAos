---
phase: 24-agent-resilience
plan: 24-01
subsystem: hooks/instinct-resilience
tags: [resilience, breadcrumb, recovery, anti-runaway, bash, hooks]
dependency_graph:
  requires: [23-01]
  provides: [instinct-recover-hook, breadcrumb-lifecycle]
  affects: [source/hooks/observe-session-end.sh, source/hooks/instinct-recover.sh]
tech_stack:
  added: []
  patterns: [breadcrumb-state-file, atomic-mv-claim, exactly-once-recovery]
key_files:
  created:
    - source/hooks/instinct-recover.sh
    - tests/v5-memory/test-instinct-recovery.sh
  modified:
    - source/hooks/observe-session-end.sh
decisions:
  - "time.mktime em vez de calendar.timegm para cooldown correto em timezone local (bug pre-existente em observe-session-end.sh, corrigido em ambos os arquivos)"
  - "wait em vez de disown: breadcrumb limpo no retorno do filho sem romper o fail-silent da subshell"
  - "mv atomico (.claimed-$$) como mecanismo de exactly-once, analogo ao claimNext do AIOX Agent Immortality Protocol, sem locks expliciticos"
metrics:
  duration_minutes: 6
  completed_at: "2026-06-16T14:13:58Z"
  tasks_completed: 3
  files_modified: 3
requirements_marked: [R6-02]
---

# Phase 24 Plan 01: Agent Resilience — Instinct Breadcrumb + Recovery Summary

Breadcrumb writer/cleaner em `observe-session-end.sh` + hook `instinct-recover.sh` (SessionStart) que detecta e trata orfaos idempotentemente — com claim atomico por rename, respeito a todos os 5 gates anti-runaway, e teste de 6 cenarios isolando HOME/PATH.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| RED | Test suite (6 cenarios, failing) | e333341 | tests/v5-memory/test-instinct-recovery.sh |
| 1+2 GREEN | breadcrumb observe-session-end + instinct-recover.sh | cb738b6 | source/hooks/observe-session-end.sh, source/hooks/instinct-recover.sh |

## What Was Built

### `source/hooks/observe-session-end.sh` (modificado)

Bloco de auto-trigger expandido para resiliencia R6-02:

1. Apos escrever a sentinela (gate R4-02) e antes do `nohup`, define `STATE_FILE="$HOME/.ideiaos/instincts/.spawn-${PROJ}.state"`.
2. Spawna com `nohup ... &`, captura `CHILD_PID=$!`, grava breadcrumb imediatamente (pid, started_at ISO, project, status=running, log path) via python3 — sem-jq.
3. Em vez de `disown`, faz `wait "$CHILD_PID"` + `rm -f "$STATE_FILE"` dentro da subshell ja em background — breadcrumb e removido no retorno normal, falha OU timeout de 120s.
4. Os 5 gates originais (IDEIAOS_INSTINCT_SPAWN, command -v claude, TS_OBS > TS_LAST, cooldown 1800s, timeout 120) e o gate R6-01 da fase 23 (`test -s observations.jsonl`) permanecem byte-equivalentes em ordem e semantica.

### `source/hooks/instinct-recover.sh` (novo)

Hook SessionStart, fail-silent exit 0, bash 3.2, sem-jq:

- **Barreira #1 primeiro**: `[ -n "${IDEIAOS_INSTINCT_SPAWN:-}" ] && exit 0` — sessoes de analise nao executam recovery.
- **Barreira #5**: `command -v claude` — sai silenciosamente se claude ausente.
- Itera `~/.ideiaos/instincts/.spawn-*.state`; para cada:
  - **Gate liveness**: `kill -0 "$BC_PID"` — pid vivo? pula (sem spawn duplo).
  - **Gate idade**: `started_at + 120s` (time.mktime, local) — breadcrumb jovem? pula.
  - **Claim atomico**: `mv "$STATE_FILE" "$CLAIM"` — se mv falha, outro recovery ja reivindicou, pula.
  - **Gate #2**: TS_OBS > TS_LAST (obs mais recente que sentinela).
  - **Gate #3**: cooldown 1800s (time.mktime, consistente com date +%s).
  - Se todos passam: reescreve sentinela, re-spawna com `IDEIAOS_INSTINCT_SPAWN=1 timeout 120 claude --model claude-haiku-4-5 -p /instinct-analyze`, regrava breadcrumb fresco, wait + rm-f. Se algum falha: `rm -f "$CLAIM"` (apenas limpa).

### `tests/v5-memory/test-instinct-recovery.sh` (novo)

6 cenarios, sandbox HOME isolado, stub claude em `$SANDBOX/bin`:

| # | Cenario | Assert |
|---|---------|--------|
| 1 | CRASH MID-SPAWN | breadcrumb orfao removido, sem .claimed pendurado |
| 2 | RETOMADA com gates ok | stub claude chamado >= 1x, breadcrumb limpo |
| 3 | NAO-RETOMADA em cooldown | breadcrumb limpo, stub NAO chamado |
| 4 | PID VIVO | breadcrumb preservado, stub NAO chamado |
| 5 | ANTI-RUNAWAY (IDEIAOS_INSTINCT_SPAWN=1) | breadcrumb intocado, stub NAO chamado |
| 6 | NAO RE-DISPARA EM LOOP | 2a execucao = no-op, stub chamado <= 1x total |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Timezone bug no cooldown gate: calendar.timegm vs time.mktime**

- **Found during:** Task 1 + 2 implementacao, revelado por falha do Teste 3 (cooldown)
- **Issue:** `calendar.timegm(dt.timetuple())` interpreta datetime naive como UTC, enquanto `date +%s` da epoch local. Em UTC-3 (Brasil), um timestamp "10 minutos atras" parece "170 minutos no futuro" para o gate, desativando o cooldown incorretamente.
- **Fix:** Substituido por `time.mktime(dt.timetuple())` (interpreta como local) em ambos `observe-session-end.sh` e `instinct-recover.sh`. Consistente com `date +%s`.
- **Files modified:** `source/hooks/observe-session-end.sh` (linha 108-117), `source/hooks/instinct-recover.sh` (gate idade + gate cooldown).
- **Commits:** cb738b6

### Design Adaptations

**Disown -> Wait**: O plano descrevia `disown + sair` com nota de que "a subshell ja esta em background". Implementado como `wait + rm -f` dentro da mesma subshell, que e exatamente o comportamento correto — a subshell ja roda em background do hook pelo bloco `( ... ) 2>/dev/null || true`.

## 5 Barreiras Anti-Runaway — Status Pos-Fase 24

| Barreira | Mecanismo | Status |
|----------|-----------|--------|
| #1 IDEIAOS_INSTINCT_SPAWN | exit 0 cedo em observe-session-end + recover | PRESERVADO; recover.sh tambem verifica |
| #2 Sentinela .last-analyzed | escrita ANTES do spawn; gate TS_OBS > TS_LAST | PRESERVADO; recovery reescreve antes de re-spawnar |
| #3 Cooldown 30min | ELAPSED < 1800 -> exit; fix de timezone aplicado | PRESERVADO; fix melhora confiabilidade |
| #4 timeout 120s | mesmo `timeout 120 claude ...` no re-spawn | PRESERVADO identico |
| #5 command -v claude | gate em observe-session-end E recover.sh | PRESERVADO; recover.sh adiciona o mesmo gate |
| NOVA: anti-corrida | claim por mv atomico + kill -0 liveness | ADICIONADO sem enfraquecer as 5 anteriores |

## Verification Results

| Gate | Result |
|------|--------|
| bash tests/v5-memory/test-instinct-recovery.sh | 12/12 PASS, exit 0 |
| bash tests/v5-memory/test-guardrails.sh | 10/10 PASS, exit 0 (sem regressao) |
| bash -n instinct-recover.sh | syntax OK |
| bash -n observe-session-end.sh | syntax OK |
| SOURCE: IdeiaOS v2 header | presente em instinct-recover.sh |
| zero <!-- | confirmado em instinct-recover.sh |
| sem jq | confirmado (python3 stdlib only) |
| spawn- em observe-session-end | confirmado |
| IDEIAOS_INSTINCT_SPAWN em recover | confirmado |
| running em test | confirmado |

## Known Stubs

Nenhum. Toda a logica de breadcrumb esta completamente implementada e testada.

## Self-Check: PASSED

- [x] `source/hooks/instinct-recover.sh` existe
- [x] `source/hooks/observe-session-end.sh` modificado
- [x] `tests/v5-memory/test-instinct-recovery.sh` existe
- [x] Commit e333341 existe (RED)
- [x] Commit cb738b6 existe (GREEN)
- [x] test-instinct-recovery.sh sai 0
- [x] test-guardrails.sh sai 0 (sem regressao)
