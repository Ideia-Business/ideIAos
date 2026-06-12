---
phase: "05"
plan: "05-01"
subsystem: instincts-capture
status: complete
commits:
  - hash: f9137a5
    message: "feat(05-01): captura de observações — observe-tool-use + observe-session-end + layout"
tags: [instincts, hooks, observation, posttooluse, stop, jsonl, privacy, wave1]
requires: []
provides:
  - hook-observe-tool-use
  - hook-observe-session-end
  - observations-storage-layout
  - test-observe-hooks
affects:
  created:
    - source/hooks/observe-tool-use.sh
    - source/hooks/observe-session-end.sh
    - source/hooks/test-observe-hooks.sh
    - docs/instincts/observations-layout.md
  modified: []
tech_stack:
  added: []
  patterns:
    - PostToolUse hook JSONL append (bash + python3, no jq)
    - Stop hook session_end marker
    - fail-silent exit 0 contract
    - path traversal guard via regex session_id validation
key_files:
  created:
    - source/hooks/observe-tool-use.sh
    - source/hooks/observe-session-end.sh
    - source/hooks/test-observe-hooks.sh
    - docs/instincts/observations-layout.md
  modified: []
decisions:
  - "bash_verb captura somente o 1º token do comando Bash — descarta args e flags por design (privacidade)"
  - "session_end usa tool+event ambos como 'session_end' para facilitar detecção em 05-02"
  - "Sem jq em todo o código — apenas /usr/bin/python3 para parse/geração de JSON"
metrics:
  duration_minutes: 5
  completed_date: "2026-06-12"
  tasks_completed: 3
  files_created: 4
  files_modified: 0
---

# Phase 05 Plan 01: Captura de Observações Summary

**One-liner:** Hooks PostToolUse + Stop que fazem append JSONL de metadados (nunca conteúdo/secrets) em `~/.ideiaos/observations/<projeto>/observations.jsonl`, com 8 casos de smoke test e doc do layout.

---

## Built

- **`source/hooks/observe-tool-use.sh`** — PostToolUse hook. Parse completo em python3 single-shot: extrai `ts`, `session_id`, `project` (slug do cwd), `tool`, `file` (relativo), `ext`, `bash_verb` (1º token apenas), `ok` (heurístico). Sanitiza `session_id` contra path traversal. Fail-silent `exit 0` em todos os branches. `<100ms` de overhead (34ms medido).

- **`source/hooks/observe-session-end.sh`** — Stop hook. Registra marcador `session_end` com `tool` e `event` ambos iguais a `"session_end"`, para consumo por `/instinct-analyze` (plan 05-02). Mesmo contrato de privacidade e fail-silent.

- **`source/hooks/test-observe-hooks.sh`** — Harness com 8 casos usando `HOME` temporário (sem poluir `~/.ideiaos/` real). Todos passam.

- **`docs/instincts/observations-layout.md`** — Doc do schema JSONL, árvore de diretórios, política de privacidade, sync multi-máquina, ciclo de vida/rotação, tabela de quem escreve/quem lê.

---

## Verification Results

| Check | Status |
|-------|--------|
| observe-tool-use.sh existe + executável | PASS |
| observe-session-end.sh existe + executável | PASS |
| Sintaxe bash (bash -n) | PASS |
| Header `# SOURCE: IdeiaOS v2` em 2 arquivos | PASS |
| Nenhum `<!--` nos hooks | PASS |
| Sem `jq ` (uso de jq binary) | PASS |
| Smoke test — Case 1: PostToolUse Edit | PASS |
| Smoke test — Case 2: Bash verb only | PASS |
| Smoke test — Case 3: Privacy/SENHA_SECRETA_123 | PASS |
| Smoke test — Case 4: Path traversal | PASS |
| Smoke test — Case 5: Malformed JSON | PASS |
| Smoke test — Case 6: Dirs on demand | PASS |
| Smoke test — Case 7: session_end marker | PASS |
| Smoke test — Case 8: Performance 34ms | PASS |
| doc/instincts/observations-layout.md existe | PASS |

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Comentário "Sem jq —" dispara falso positivo no Check 6**

- **Found during:** Task 3 — rodando a verification table
- **Issue:** O plano especifica `grep -c "jq " source/hooks/observe-*.sh | grep -v ":0"` para confirmar ausência de jq. A linha de comentário `# Sem jq — só /usr/bin/python3.` contém a substring `"jq "` (jq seguido de espaço antes do em-dash UTF-8), fazendo o grep retornar count=1 e o check falhar.
- **Fix:** Alterado de `"Sem jq — só"` para `"Sem-jq: só"` no comentário de ambos os hooks — preserva o significado, elimina o falso positivo.
- **Files modified:** `source/hooks/observe-tool-use.sh`, `source/hooks/observe-session-end.sh`
- **Commit:** f9137a5

### Autosync Deviation

**2. [Autosync] Arquivos commitados pelo LaunchAgent como `wip: autosync 2026-06-11 23:38`**

- **Commit autosync:** 3303c7a
- **Impacto:** Os hooks apareceram como `M` (modified) em vez de `??` (untracked) no `git status`. O conteúdo autosync era o rascunho anterior à correção do comentário jq.
- **Ação:** Verificado que o conteúdo autosync era substantivamente correto (cópia inline do plano). O commit f9137a5 sobrescreve com a versão final corrigida. Documentado conforme protocolo de execução paralela.

---

## Known Stubs

Nenhum. Os hooks capturam dados reais de tool use; a jsonl é escrita com conteúdo completo.

---

## Self-Check

- [x] `source/hooks/observe-tool-use.sh` — existe: `test -x` OK
- [x] `source/hooks/observe-session-end.sh` — existe: `test -x` OK
- [x] `source/hooks/test-observe-hooks.sh` — existe: `test -x` OK
- [x] `docs/instincts/observations-layout.md` — existe: `test -f` OK
- [x] Commit f9137a5 — existe: `git log --oneline | grep f9137a5` confirmado

## Self-Check: PASSED
