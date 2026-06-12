---
phase: "02"
plan: "02-03"
subsystem: setup-dev-machine+memory-hygiene
tags: [security, launchagent, timeout, memory-hygiene, agents]
dependency_graph:
  requires: []
  provides: [launchagent-killswitch, memory-hygiene-rule, agents-md-reference]
  affects: [setup-dev-machine.sh, docs/security/memory-hygiene.md, AGENTS.md]
tech_stack:
  added: []
  patterns:
    - "Plist ProgramArguments timeout wrapper: [TIMEOUT_BIN, 120, SCRIPT_PATH, --all]"
    - "AbandonProcessGroup false: kills child processes on timeout"
key_files:
  created:
    - docs/security/memory-hygiene.md
  modified:
    - setup-dev-machine.sh
    - AGENTS.md
decisions:
  - "TIMEOUT_BIN uses existing $BIN_DIR/timeout shim (already installed in step 2-3 of setup-dev-machine.sh) — no new dependency"
  - "AbandonProcessGroup false (not true) ensures child git processes are also killed on timeout"
metrics:
  duration: "~15min"
  completed: "2026-06-11"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 2
requirements: [REQ-05]
---

# Phase 02 Plan 03: LaunchAgent Kill-Switch + Memory Hygiene Summary

**One-liner:** ProgramArguments do LaunchAgent envolto em `timeout 120` (usando shim existente); `docs/security/memory-hygiene.md` criado com 3 regras; AGENTS.md referencia a regra.

---

## What Was Built

### setup-dev-machine.sh — Timeout wrapper

- `TIMEOUT_BIN="$BIN_DIR/timeout"` adicionado após `SCRIPT_PATH` (linha 23)
- ProgramArguments: `[TIMEOUT_BIN, "120", SCRIPT_PATH, "--all"]`
- `<key>AbandonProcessGroup</key><false/>` dentro do `<dict>` do plist

### docs/security/memory-hygiene.md

3 regras formalizadas:
1. **Sem secrets em memória**: nunca gravar credentials em `~/.claude/projects/`, vault ou arquivos GSD
2. **Memória de projeto ≠ global**: isolamento já é por design — explicitado
3. **Reset após runs não-confiáveis**: nova sessão após interação com conteúdo de quarentena

Inclui como verificar (`bash scripts/idea-doctor.sh` Seção 7).

### AGENTS.md

Seção "Segurança de sessão" adicionada com as 3 regras resumidas e link para `docs/security/memory-hygiene.md`.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1+2 | 1065eb7 | feat(02-03): LaunchAgent kill-switch + memory hygiene rule |

---

## Threat Model Compliance

| Threat | Status |
|--------|--------|
| T-02-11: git-autosync travado indefinidamente | ✅ timeout 120 + AbandonProcessGroup false |
| T-02-12: secrets em memória/vault | ✅ Regra 1 documentada + idea-doctor 7c |
| T-02-13: contaminação de sessão por quarentena | ✅ Regra 3 (reset pós-quarentena) documentada |
