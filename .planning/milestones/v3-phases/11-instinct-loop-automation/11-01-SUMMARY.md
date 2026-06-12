---
phase: 11-instinct-loop-automation
plan: "01"
subsystem: instinct-loop
tags: [hooks, instincts, automation, stop-hook, gate, haiku]
dependency_graph:
  requires: []
  provides: [observe-session-end-gate, instinct-status-pending-indicator]
  affects: [source/hooks/observe-session-end.sh, source/skills/instinct-status/SKILL.md, plugins/ideiaos-core/hooks/observe-session-end.sh]
tech_stack:
  added: []
  patterns: [fire-and-forget-spawn, timestamp-gate, fail-silent-subshell]
key_files:
  created: []
  modified:
    - source/hooks/observe-session-end.sh
    - source/skills/instinct-status/SKILL.md
    - plugins/ideiaos-core/hooks/observe-session-end.sh
decisions:
  - "Comparação ISO lexicográfica via [[ TS_OBS > TS_LAST ]] (não [ \<= ]) — bash [ ] não suporta <= para strings"
  - "Sentinela atualizado apenas pelo instinct-analyze (Passo 9, plano 11-02) — não pelo hook — retry automático em caso de falha do spawn"
  - "command -v claude guard antes do spawn — hook fail-silent quando claude ausente do PATH"
metrics:
  duration: "~22 minutos"
  completed: "2026-06-12T16:40:50Z"
  tasks_completed: 2
  files_modified: 3
---

# Phase 11 Plan 01: Instinct Loop — Stop Hook Gate + Status Indicator Summary

**One-liner:** Stop hook com gate por timestamp ISO + spawn haiku background para /instinct-analyze, e indicador de pendência em instinct-status.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Estender observe-session-end.sh com gate + spawn haiku | cdae3f8 | source/hooks/observe-session-end.sh, plugins/ideiaos-core/hooks/observe-session-end.sh |
| 2 | Adicionar indicador de pendência em instinct-status/SKILL.md | 241cbc5 | source/skills/instinct-status/SKILL.md |

---

## What Was Built

### observe-session-end.sh — Gate + Spawn

Adicionado bloco `INSTINCT-ANALYZE AUTO-TRIGGER (R3-08 / R3-09)` ao final do hook, antes do `exit 0`:

1. **Guard claude**: `command -v claude >/dev/null 2>&1 || exit 0` — skip silencioso se claude ausente.
2. **Extrai ts da última obs**: python3 lê última linha não-vazia do `observations.jsonl`, extrai campo `"ts"`.
3. **Lê sentinela**: `~/.ideiaos/instincts/.last-analyzed-<proj>` — trata como epoch `1970-01-01T00:00:00` se ausente.
4. **Gate**: `[[ "$TS_OBS" > "$TS_LAST" ]] || exit 0` — comparação lexicográfica ISO 8601 correta.
5. **Spawn**: `nohup timeout 120 claude --model claude-haiku-4-5 -p "/instinct-analyze" >> "$LOG_FILE" 2>&1 & disown $! 2>/dev/null || true`
6. **Fail-silent**: todo o bloco em subshell `( ) 2>/dev/null || true`.
7. **Hook retorna imediatamente** após spawn (fire-and-forget, sem `wait`).

### instinct-status/SKILL.md — Passo 0

Inserido Passo 0 antes do Passo 1 existente:
- Varre todos os projetos em `~/.ideiaos/observations/`
- Compara ts da última observação vs sentinela `.last-analyzed-<proj>`
- Exibe "pendente de analise: N observações" se gate passa
- Aviso adicional se última análise > 7 dias
- Passos 1-5 originais intactos

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comparação de strings ISO com [ \<= ] não funciona em bash**
- **Found during:** Task 1, teste comportamental Test B
- **Issue:** `[ "$TS_OBS" \<= "$TS_LAST" ]` causa erro "binary operator expected" em bash — o builtin `[` não suporta operador `<=` para strings. Gate não bloqueava quando sentinela era futuro.
- **Fix:** Substituído por `[[ "$TS_OBS" > "$TS_LAST" ]] || exit 0` — `[[ ]]` suporta comparações de string com `>` e é correto para ISO 8601 lexicográfico.
- **Files modified:** source/hooks/observe-session-end.sh
- **Commit:** cdae3f8

---

## Verification Results

| Critério | Status |
|----------|--------|
| bash -n passa | PASS |
| Contém "last-analyzed" (2x) | PASS |
| Contém "timeout 120" (2x) | PASS |
| Contém "disown" | PASS |
| Sem jq (apenas em comentário "Sem-jq:") | PASS |
| Bloco comentado com R3-08/R3-09 | PASS |
| Comportamento original (session_end append) preservado | PASS |
| TEST A: gate passa sem sentinela | PASS |
| TEST B: gate bloqueia com sentinela futuro | PASS |
| TEST C: exit 0 quando claude ausente do PATH | PASS |
| 8/8 casos do test-observe-hooks.sh | PASS |
| instinct-status: "pendente de analise" | PASS |
| instinct-status: "last-analyzed" (3x) | PASS |
| instinct-status: SOURCE IdeiaOS v2 | PASS |
| instinct-status: sem HTML comments | PASS |
| instinct-status: pipeline original intacto | PASS |

---

## Threat Surface

Nenhuma nova surface além do mapeado no threat_model do plano:
- T-11-01 (DoS): mitigado via timeout 120
- T-11-02 (Tampering sentinela): aceito — arquivo local do usuário
- T-11-03 (Elevation): aceito — claude -p herda contexto do usuário sem elevação
- T-11-04 (Info Disclosure no log): aceito — log local do usuário

---

## Known Stubs

Nenhum. O hook spawna claude -p com prompt `/instinct-analyze` diretamente. O sentinela será atualizado pelo Passo 9 do instinct-analyze (implementado no plano 11-02).

## Self-Check: PASSED

- source/hooks/observe-session-end.sh: existe e contém gate + spawn
- source/skills/instinct-status/SKILL.md: existe e contém Passo 0
- plugins/ideiaos-core/hooks/observe-session-end.sh: sincronizado
- ~/.claude/hooks/observe-session-end.sh: instalado
- Commits cdae3f8 e 241cbc5 existem no git log
