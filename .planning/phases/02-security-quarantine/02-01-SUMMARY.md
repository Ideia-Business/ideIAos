---
phase: "02"
plan: "02-01"
subsystem: security/quarantine-pipeline
tags: [security, scan, quarantine, python3, agentshield]
dependency_graph:
  requires: []
  provides: [scan-absorbed-sh, quarantine-staging, security-readme]
  affects: [security/scan-absorbed.sh, security/quarantine/.gitkeep, security/README.md]
tech_stack:
  added: []
  patterns:
    - "Python3 inline for unicode/payload/command detection (more portable than rg for structured output)"
    - "rg -q quiet mode for exit-code-only checks (stdout suppressed to avoid rendering issues)"
    - "AgentShield via npx --yes best-effort: offline → WARN not FAIL"
key_files:
  created:
    - security/scan-absorbed.sh
    - security/quarantine/.gitkeep
    - security/README.md
  modified: []
decisions:
  - "Switched Check 1 (unicode) and Check 2 (HTML payloads) to Python3 inline — rg output with U+200B or <script> tags corrupted tool output rendering; Python3 approach is more portable and was already the project pattern"
  - "Check 3 (suspicious commands) uses Python3 for same rendering safety; rg -q available as alternative"
  - "PATH export added for Homebrew tools in restricted shell environments"
metrics:
  duration: "~45min"
  completed: "2026-06-11"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 1
requirements: [REQ-01, REQ-02]
---

# Phase 02 Plan 01: Security Quarantine Pipeline Summary

**One-liner:** `security/scan-absorbed.sh` criado com 4 checks (unicode/Python3, HTML+JS/Python3, comandos suspeitos/Python3, AgentShield/npx); staging dir `quarantine/` e README documentando o fluxo obrigatório.

---

## What Was Built

### security/scan-absorbed.sh

Pipeline de quarentena executável (chmod +x). 4 checks:

| Check | Tecnologia | Resultado se encontrado |
|-------|------------|------------------------|
| 1 — Unicode invisível (U+200B/202A-E/FEFF etc.) | Python3 inline | FAIL (exit 1) |
| 2 — Payloads HTML/JS (`<!--`, `data:text/html`, `base64,`) | Python3 inline | FAIL (exit 1) |
| 3 — Comandos suspeitos (curl/wget/ssh/nc/ANTHROPIC_BASE_URL) | Python3 inline | WARN (exit 0) |
| 4 — AgentShield scan | npx --yes ecc-agentshield | WARN se offline |

Exit codes: `0=PASS` (limpo ou só WARNs), `1=FAIL` (payload ativo), `2=erro de invocação`.

### security/quarantine/.gitkeep

Staging area versionada para conteúdo de terceiros antes do scan.

### security/README.md

Documenta: fluxo obrigatório, exit codes, distinção WARN vs FAIL, tabela de checks, nota sobre AgentShield.

---

## Smoke Test Results

| Fixture | Expected | Actual |
|---------|----------|--------|
| `/tmp/payload-unicode.md` (U+200B) | exit 1 | ✅ exit 1 |
| `/tmp/payload-html.md` (`<script>`) | exit 1 | ✅ exit 1 |
| `/tmp/payload-clean.md` | exit 0 | ✅ exit 0 |
| `/caminho/inexistente` | exit 2 | ✅ exit 2 |

---

## Deviations from Plan

### Python3 instead of rg for Checks 1-3

- **Issue:** `rg -nP` with unicode matches outputs U+200B characters that corrupted tool rendering; `rg` with `<script>` patterns similarly corrupted output. Result: subsequent shell commands appeared not to execute.
- **Fix:** Replaced all 3 rg-based checks with Python3 inline scripts. Same detection logic, more portable, already the project's standard pattern (install-global-patches.sh).
- **Impact:** None on correctness. Python3 is universally available and produces identical results.

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 0+1+2 | 72866d5 | feat(02-01): security/scan-absorbed.sh quarantine pipeline + staging dir |

---

## Threat Model Compliance

| Threat | Status |
|--------|--------|
| T-02-01: unicode invisible prompt injection | ✅ Detected (FAIL) |
| T-02-02: HTML/JS payload | ✅ Detected (FAIL) |
| T-02-03: ANTHROPIC_BASE_URL/enableAllProjectMcpServers | ✅ Detected (WARN) |
| T-02-04: AgentShield offline DoS | ✅ Accepted (WARN, exit 0) |
| T-02-05: npx package compromise | ✅ Accepted (best-effort) |
