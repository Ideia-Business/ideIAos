# SOURCE: IdeiaOS v2

---
phase: 07-contexts-evals
plan: "02"
subsystem: evals
tags: [evals, regression, incidents, pass-at-k, pass-hat-k, gsd-verify-work]
dependency_graph:
  requires: []
  provides: [evals/README.md, evals/_TEMPLATE.md, evals/cases/*.md, evals/run-evals.sh]
  affects: [gsd-verify-work integration (by reference)]
tech_stack:
  added: []
  patterns: [pass@k/pass^k eval methodology, incident-to-case regression loop]
key_files:
  created:
    - evals/README.md
    - evals/_TEMPLATE.md
    - evals/run-evals.sh
    - evals/cases/index.md
    - evals/cases/EVAL-001-billing-no-blind-insert.md
    - evals/cases/EVAL-002-asaas-webhook-fallback.md
    - evals/cases/EVAL-003-rls-revoke-breaks-returning.md
    - evals/cases/EVAL-004-multitenant-cache-leak.md
    - evals/cases/EVAL-005-date-without-tz-brt.md
    - evals/cases/EVAL-006-silent-failure-missing-import.md
    - evals/cases/EVAL-007-webhook-naming-snake-camel.md
    - evals/cases/EVAL-008-cnpj-alphanumeric.md
    - evals/cases/EVAL-009-service-callback-no-jwt.md
    - evals/cases/EVAL-010-validator-throw-swallowed.md
    - evals/cases/EVAL-011-crm-card-duplication.md
    - evals/cases/EVAL-012-phantom-meeting-ghost.md
    - evals/cases/EVAL-013-meeting-cancel-not-visible.md
    - evals/cases/EVAL-014-proposal-lead-hydration.md
    - evals/cases/EVAL-015-cross-screen-metric-consistency.md
    - evals/cases/EVAL-016-cross-module-cache-invalidation.md
    - evals/cases/EVAL-017-lovable-deploy-400-adjacent.md
    - evals/cases/EVAL-018-inc368-onboarding-categories.md
    - evals/cases/EVAL-019-scan-false-positive-html-comment.md
    - evals/cases/EVAL-020-scan-false-positive-substring.md
    - evals/cases/EVAL-021-mode-routing-review-no-edit.md
    - evals/cases/EVAL-022-research-explore-before-act.md
  modified: []
decisions:
  - "pass^k for all financial/security invariants (EVAL-001,003,004,005,006,008,009,010,015,016,021) — 1 failure = incident"
  - "pass@k for productivity capabilities — reachability sufficient"
  - "runner is manual/semi-automatic by design — no API key wired; run_case_with_model() is the named extension point"
  - "awk section extraction uses index() not regex to avoid / delimiter clash in Setup/Prompt section name"
  - "mapfile replaced with bash 3.2-compatible glob+sort pattern (macOS ships bash 3.2)"
  - "EVAL-019 avoids literal HTML comment in its own body — uses descriptive placeholders per no-<!-- constraint"
metrics:
  duration_minutes: 70
  completed_date: "2026-06-12"
  tasks_completed: 2
  tasks_total: 2
  files_created: 27
  files_modified: 0
---

# Phase 7 Plan 02: Eval Suite — SUMMARY

**One-liner:** 22 regression evals from real incidents (ideiapartner INC-3xx/bugs + nfideia learnings) using pass@k/pass^k methodology with headless runner.

## What Was Built

### Task 1 — Methodology README, Template, Runner (commit 5a8517b)

- `evals/README.md`: full PT-BR methodology doc — pass@k vs pass^k with orientation table, gsd-verify-work integration point (incident → case → regression loop), incremental growth instructions.
- `evals/_TEMPLATE.md`: canonical case format with YAML frontmatter (id, title, source, mode, metric, k, severity) + four body sections (Setup/Prompt, Comportamento Esperado, Critérios de Aprovação, Anti-comportamento).
- `evals/run-evals.sh`: runner with `--dry-run`, `--case ID`, `--list`, `--help`; headless-safe via `[ -t 0 ] || DRY_RUN=1`; named extension point `run_case_with_model()`.

### Task 2 — 22 Eval Cases + Index (commits 0a5cf6a + 5cf37d4)

- `evals/cases/index.md`: full roster table (22 rows) with source incident, mode, metric, severity.
- 22 case files EVAL-001..022, each self-contained with prompt + pass criteria inline.

**Source confirmation:** All 22 cases have confirmed source files on disk (22/22 confirmed, 0 summary-only).

| Source repo | Cases |
|---|---|
| ideiapartner/docs/ | EVAL-001, 002, 011, 012, 013, 014, 015, 016, 018 (9 cases) |
| nfideia/docs/learnings/ | EVAL-003, 004, 005, 006, 007, 008, 009, 010, 017 (9 cases) |
| IdeiaOS .planning/STATE.md | EVAL-019, 020 (2 cases) |
| IdeiaOS source/contexts/ | EVAL-021, 022 (2 cases) |

**Metric distribution:** 14 pass^k (invariants) · 8 pass@k (productivity)

## Verification Table

| Check | Command | Result |
|---|---|---|
| Case count ≥ 20 | `ls evals/cases/EVAL-*.md \| wc -l` | 22 ✅ |
| All case headers | `for f in evals/cases/EVAL-*.md; do head -1 "$f"; done \| sort -u` | only `# SOURCE: IdeiaOS v2` ✅ |
| Methodology defines both metrics | `grep -c -E 'pass@k\|pass\^k' evals/README.md` | 10 ✅ |
| gsd-verify-work integration documented | `grep -c gsd-verify-work evals/README.md` | 4 ✅ |
| Runner dry-run headless | `bash evals/run-evals.sh --dry-run </dev/null` | exit 0, all 22 listed ✅ |
| Runner single case | `bash evals/run-evals.sh --case EVAL-001 --dry-run </dev/null` | shows EVAL-001 ✅ |
| No HTML comments | `grep -rl '<!--' evals/` | no matches ✅ |
| Runner syntax | `bash -n evals/run-evals.sh` | SYNTAX OK ✅ |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] mapfile not available on macOS bash 3.2**
- **Found during:** Task 2 verification (`bash evals/run-evals.sh --dry-run </dev/null`)
- **Issue:** `mapfile` is bash 4+ builtin; macOS ships bash 3.2 — command not found, CASE_FILES unbound
- **Fix:** Replaced with portable glob+sort pattern using `for _f in ...; CASE_FILES+=()` + `printf|sort|read` loop
- **Files modified:** `evals/run-evals.sh`
- **Commit:** 5cf37d4

**2. [Rule 1 - Bug] awk regex delimiter clash in Setup/Prompt section name**
- **Found during:** Task 2 verification (awk syntax error in dry-run output)
- **Issue:** `extract_section` interpolated section name into awk regex — `/` in `Setup/Prompt` broke the regex delimiter
- **Fix:** Changed to `awk -v sec="## ${section}" 'index($0,sec)==1{...}'` (string comparison, no regex)
- **Files modified:** `evals/run-evals.sh`
- **Commit:** 5cf37d4

**3. [Rule 2 - Constraint] EVAL-019 body cannot contain literal `<!--`**
- **Found during:** Task 2 no-HTML-comment check
- **Issue:** EVAL-019 discusses HTML comments as subject matter — literal `<!--` appeared in the case body
- **Fix:** Replaced literal HTML comment delimiters with descriptive placeholders (`[HTML-COMMENT-OPEN]`, `[MENOR-QUE]!--`) per no-`<!--` constraint
- **Files modified:** `evals/cases/EVAL-019-scan-false-positive-html-comment.md`
- **Commit:** 5cf37d4

## Known Stubs

None — all cases are self-contained with inline prompts and pass criteria. No data stubs or placeholders.

## Threat Flags

None — evals/ is a read-only regression asset. No new network endpoints, auth paths, or trust boundary crossings introduced.

## Self-Check: PASSED
