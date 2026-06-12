---
phase: "02"
plan: "02-02"
subsystem: scripts/patches+doctor
tags: [security, deny-rules, idea-doctor, idempotent, python3]
dependency_graph:
  requires: []
  provides: [patch-10-deny-rules, idea-doctor-section-7]
  affects: [scripts/install-global-patches.sh, scripts/idea-doctor.sh]
tech_stack:
  added: []
  patterns:
    - "python3 inline idempotent JSON merge (same as Patch 4/8)"
    - "idea-doctor pass/warn/fail pattern with section step()"
key_files:
  created: []
  modified:
    - scripts/install-global-patches.sh
    - scripts/idea-doctor.sh
decisions:
  - "ssh/scp in permissions.ask not deny — avoids breaking 4 product projects"
  - "deny rules check uses python3 -c inline (single line) for portability"
metrics:
  duration: "~20min"
  completed: "2026-06-11"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
requirements: [REQ-03, REQ-04]
---

# Phase 02 Plan 02: Patch 10 + idea-doctor Section 7 Summary

**One-liner:** Patch 10 adicionado ao install-global-patches.sh (6 deny rules + 2 ask rules, idempotente via python3); Seção 7 Security Audit inserida no idea-doctor.sh antes do Resumo.

---

## What Was Built

### install-global-patches.sh — Patch 10

- `patch_deny_rules()` function added after `patch_global_gitignore()`
- 6 deny rules: `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Read(**/.env*)`, `Write(~/.ssh/**)`, `Bash(curl * | bash)`, `Bash(nc *)`
- 2 ask rules: `Bash(ssh *)`, `Bash(scp *)` — não bloqueia SSH legítimo dos 4 projetos
- Idempotente: python3 verifica presença antes de adicionar; `APPLIED/SKIPPED/FAILED` counters
- Todos os steps renumerados 1/9→1/10 .. 9/9→9/10; novo `step "Patch 10/10"` no final

### idea-doctor.sh — Section 7 Security Audit

Inserida antes do `━━━ Resumo ━━━`:

| Sub-check | Tecnologia | Resultado |
|-----------|------------|-----------|
| 7a — 6 deny rules presentes | python3 -c inline | FAIL se ausente |
| 7b — hooks com curl\|bash pipe | rg -ln | FAIL se encontrado |
| 7c — secrets em ~/.claude/projects | rg -l | FAIL se encontrado |
| 7d — scan-absorbed.sh presente | test -x | WARN se ausente |

Header atualizado: "Os 10 patches" e Seção 7 mencionada.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1+2 | 661e16d | feat(02-02): Patch 10 deny rules + idea-doctor Section 7 Security Audit |

---

## Threat Model Compliance

| Threat | Status |
|--------|--------|
| T-02-06: Read ~/.ssh, ~/.aws, .env | ✅ deny rules instaladas via Patch 10 |
| T-02-07: Bash(curl\|bash), Bash(nc *) | ✅ deny rules instaladas via Patch 10 |
| T-02-08: secrets em memória | ✅ idea-doctor 7c detecta |
| T-02-09: hooks com curl\|bash pipe | ✅ idea-doctor 7b detecta |
| T-02-10: deny Bash(ssh *) bloqueia deploy | ✅ ssh/scp em ask, não deny |
