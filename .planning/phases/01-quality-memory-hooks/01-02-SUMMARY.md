---
phase: "01"
plan: "01-02"
subsystem: "hooks/memory"
tags: [hooks, precompact, stop, session-summary, state-persistence, ecc]
dependency_graph:
  requires: []
  provides: [precompact-state-save, session-summary]
  affects: [~/.claude/sessions/, .planning/STATE.md, docs/CONTINUATION_HANDOFF.md]
tech_stack:
  added: []
  patterns: [bash-hook-precompact, bash-hook-stop, python3-json-parse, idempotent-section-replace]
key_files:
  created:
    - hooks/precompact-state-save.sh
    - hooks/session-summary.sh
  modified: []
decisions:
  - "Snapshot PreCompact usa conteudo minimo estruturado (nao bruto do transcript) para evitar corrupcao do STATE.md (Pitfall 4)"
  - "session-summary emite exit 0 puro sem JSON output — Stop hook nao deve injetar contexto, apenas escrever arquivos"
  - "Idempotencia de CONTINUATION_HANDOFF.md via regex de ## Ultima sessao automatica — substitui bloco anterior, nao acumula"
  - "python3 via sys.argv para todos os writes criticos — evita interpolacao insegura de variaveis shell em codigo python3"
metrics:
  duration_seconds: 300
  completed_date: "2026-06-11"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 01 Plan 02: Session Memory Hooks (PreCompact + Stop) Summary

**One-liner:** PreCompact snapshot idempotente em STATE.md + Stop hook ECC 4-seções em ~/.claude/sessions/ com atualização condicional de CONTINUATION_HANDOFF.md.

---

## Objective

Entregar dois hooks de memória de sessão para o IdeiaOS:
1. `precompact-state-save.sh` — garante snapshot no STATE.md antes de /compact
2. `session-summary.sh` — persiste sessão ECC em ~/.claude/sessions/ e atualiza CONTINUATION_HANDOFF.md condicionalmente

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Implementar precompact-state-save.sh | e157c7c | hooks/precompact-state-save.sh (100 lines) |
| 2 | Implementar session-summary.sh | ac1baa9 | hooks/session-summary.sh (218 lines) |

---

## Implementation Details

### hooks/precompact-state-save.sh (PreCompact)

- Detecta `.planning/STATE.md` ou `STATE.md` no `cwd` (saída silenciosa se ausente)
- Reescreve/insere seção `## Compact Snapshot` de forma idempotente via python3
- Snapshot mínimo: timestamp + trigger + bullet point de referência para ~/.claude/sessions/
- Emite `additionalContext` JSON via python3 serialização (sem risco de quebra por caracteres especiais)
- Nunca usa `decision: block` — o /compact nunca é bloqueado
- Usa `sys.argv` para passar variáveis ao python3 (segurança contra interpolação de conteúdo arbitrário)

### hooks/session-summary.sh (Stop)

- Sanitiza `session_id` e `cwd` para `[a-z0-9-]` antes de montar path de arquivo (T-01-04)
- Extrai último turno assistant do transcript via parse JSONL defensivo (json.loads por linha)
- Fallback: placeholder `(transcript não disponível ou ilegível)` se parse falhar
- Escreve `~/.claude/sessions/YYYY-MM-DD-<cwd-slug>-<session-id-safe>.tmp` com 4 seções ECC
- Atualiza `docs/CONTINUATION_HANDOFF.md` APENAS se existir no cwd (Pitfall 3)
- Idempotente: substitui bloco `## Ultima sessao automatica` anterior via regex
- Exit 0 puro — sem output JSON, sem additionalContext, sem decision:block

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Threat Model Compliance

| Threat | Status |
|--------|--------|
| T-01-04: path traversal via session_id | Mitigated — slug e session_id sanitizados via regex [a-z0-9-] |
| T-01-05: STATE.md corrompido por conteudo bruto | Mitigated — snapshot minimal, sem conteudo do transcript |
| T-01-06: transcript com segredos em .tmp | Accepted — ~/.claude/sessions/ local ao usuario; mesmo risco do transcript original |

---

## Verification Results

| Check | Result |
|-------|--------|
| precompact idempotente (2 runs = 1 secao) | PASS |
| precompact silencioso em projeto sem STATE.md | PASS |
| precompact exit 0 sempre | PASS |
| STATE.md markdown valido apos escrita | PASS |
| session-summary cria .tmp em ~/.claude/sessions/ | PASS |
| CONTINUATION_HANDOFF.md NAO criado em /tmp | PASS |
| session-summary exit 0 puro | PASS |
| Idempotencia CONTINUATION_HANDOFF.md | PASS |
| Nenhum decision:block em codigo nao-comentado | PASS |

---

## Known Stubs

None — both hooks are fully wired and functional. The "a revisar" placeholders in session
files are by design (ECC sections 2-4 require human review; only section 1 is auto-populated
from transcript).

---

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

- hooks/precompact-state-save.sh exists: FOUND
- hooks/session-summary.sh exists: FOUND
- Commit e157c7c exists: FOUND
- Commit ac1baa9 exists: FOUND
