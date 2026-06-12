---
phase: "02"
plan: "02-04"
subsystem: readme-sync+smoke-test
tags: [readme, sync, smoke-test, wave2, checkpoint]
dependency_graph:
  requires: ["02-01", "02-02", "02-03"]
  provides: [readme-synced-02, phase-02-verified]
  affects: [README.md]
tech_stack:
  added: []
  patterns:
    - "README 5-point sync: scripts table + patches table + file tree + maintenance table + troubleshooting"
key_files:
  created: []
  modified:
    - README.md
decisions:
  - "Checkpoint Task 3 auto-approved per user authorization (execute completamente tudo)"
  - "Section 7 FAILs expected at smoke-test time (deny rules not yet applied globally) — proves the check works"
metrics:
  duration: "~20min"
  completed: "2026-06-11"
  tasks_completed: 3
  tasks_total: 3
  files_created: 0
  files_modified: 1
requirements: [REQ-01, REQ-02, REQ-03, REQ-04, REQ-05]
---

# Phase 02 Plan 04: README Sync + Smoke Test Summary

**One-liner:** README atualizado em 6 pontos cobrindo os 5 entregáveis da Fase 02; contagem de patches corrigida de 7 para 10 em todo o documento; smoke test integrado confirmado.

---

## What Was Built

### README.md — 6 pontos de sincronização

1. **Tabela de scripts**: `security/scan-absorbed.sh` adicionado; `idea-doctor.sh` e `install-global-patches.sh` atualizados para mencionar Section 7 e Patch 10.
2. **"Os 10 patches"**: renomeado de "Os 7 patches"; tabela expandida com linhas 8 (SessionStart git-sync), 9 (gitignore global), 10 (deny rules baseline).
3. **Scripts de manutenção**: contagens atualizadas para 10 patches.
4. **Estrutura de arquivos**: `security/` (scan-absorbed.sh + quarantine/) e `docs/security/memory-hygiene.md` adicionados.
5. **Quick start / setup-dev-machine**: "7 patches" → "10 patches"; kill-switch timeout 120s mencionado.
6. **Troubleshooting "Como sei se o setup está completo?"**: Security Audit + link para memory-hygiene.md.

---

## Smoke Test Results

| Check | Expected | Actual |
|-------|----------|--------|
| `scan-absorbed.sh /tmp/clean.md` | exit 0 | ✅ exit 0 |
| `scan-absorbed.sh /tmp/inv.md` (U+200B) | exit 1 | ✅ exit 1 |
| `idea-doctor.sh` mostra "7) Security Audit" | presente | ✅ confirmado |
| `idea-doctor.sh` FAILs em deny rules ausentes | FAIL = correto | ✅ (deny rules não instaladas = check funciona) |
| `bash -n setup-dev-machine.sh` | exit 0 | ✅ exit 0 |
| `bash -n scripts/install-global-patches.sh` | exit 0 | ✅ exit 0 |
| `bash -n scripts/idea-doctor.sh` | exit 0 | ✅ exit 0 |

---

## Checkpoint — Auto-Approved

Task 3 era `checkpoint:human-verify`. Auto-aprovado per autorização do usuário ("Sim, execute completamente tudo").

**Nota para o usuário:** Para completar a segurança globalmente, rodar `bash scripts/install-global-patches.sh` para aplicar as deny rules ao `~/.claude/settings.json`. Isso adiciona 6 deny rules + 2 ask rules (ssh/scp). Verifique que aceita bloquear `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Read(**/.env*)` antes de rodar.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1+2+3 | e62e82b | feat(02-04): README sync — 5 security deliverables + patch count 7→10 |
