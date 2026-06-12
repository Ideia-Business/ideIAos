---
phase: 07-contexts-evals
plan: "03"
subsystem: setup-integration
tags: [setup, contexts, statusline, manifests, readme-sync, wave-2]
dependency_graph:
  requires: [07-01, 07-02]
  provides: [installable-contexts, installable-statusline, manifest-70-modules, readme-synced]
  affects: [setup.sh, manifests/modules.json, manifests/plugin-membership.md, README.md]
tech_stack:
  added: []
  patterns:
    - offer-not-edit (T-01-10) — setup.sh NUNCA auto-edita dotfiles ou settings.json
    - shell functions with "$@" passthrough using --append-system-prompt
    - kind extension in modules.json ("context", "statusline") — backward-compatible
key_files:
  modified:
    - setup.sh
    - manifests/modules.json
    - manifests/plugin-membership.md
    - README.md
decisions:
  - contexts e statusline são setup.sh-only (plugin null); build-plugins.sh inalterado
  - evals/ é ativo de repo-level, não módulo — intencionalmente fora de modules.json
  - --append-system-prompt (não --system-prompt) preserva CLAUDE.md/hooks/memória
metrics:
  duration: "~30min"
  completed: "2026-06-12"
  tasks_completed: 3
  files_modified: 4
---

# Phase 07 Plan 03: Wave 2 Integration — setup.sh + manifests + README Summary

**One-liner:** setup.sh steps 5.22+5.23 deploy mode contexts and statusline with offer-not-edit snippets; modules.json grows 66→70 with context/statusline kinds; README syncs 89/89.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Deploy contexts + offer aliases + offer statusline in setup.sh | 4973609 | setup.sh |
| 2 | Register contexts + statusline in manifests, sync README | 3f2be17 | manifests/modules.json, manifests/plugin-membership.md, README.md |
| 3 | Smoke test — checkpoint auto-approved | (automated) | — |

## What Was Built

**Task 1 — setup.sh steps 5.22 and 5.23:**
- Step 5.22: copies `source/contexts/{dev,review,research}.md` → `~/.ideiaos/contexts/` (idempotent, updates propagate on re-run). Probes `~/.zshrc` and `~/.bashrc` for `claude-review()`. If absent: `warn` + `cat <<'SNIPPET'` with three shell functions using `--append-system-prompt "$(cat ...)"  "$@"`. If present: `ok`.
- Step 5.23: copies `source/statusline/ideiaos-statusline.sh` → `~/.ideiaos/statusline/` (`chmod +x`). Probes `~/.claude/settings.json` for `ideiaos-statusline.sh`. If absent: `warn` + `cat <<'SNIPPET'` showing the `statusLine` JSON block with `/Users/<você>/...` path placeholder. If present: `ok`. Never auto-edits settings.json (T-01-10).

**Task 2 — Manifests and README:**
- `manifests/modules.json`: +4 entries — `context-dev`, `context-review`, `context-research` (kind "context"), `statusline-ideiaos` (kind "statusline"). All `plugin: null`, `installStrategy: "manual"`. Total: 66 → 70.
- `manifests/plugin-membership.md`: new section "Setup-only (não-plugin): contexts + statusline" with rationale table and evals note.
- `README.md`: tree populated (contexts/ entries, statusline/ line, evals/ top-level block); "O que instala" table +4 rows; Terminal section +3 subsections (mode aliases, statusline, evals runner).

## Checkpoint: Auto-Approved

Task 3 was `type="checkpoint:human-verify"` — pre-authorized as fully autonomous per execution context. All automated checks were run and passed. Operator interactive verification (paste alias in shell, run `claude-review`) is noted as pending for the operator at their discretion.

## Smoke Test Results (Automated — Task 3)

| Check | Command | Result |
|-------|---------|--------|
| setup.sh syntax | `bash -n setup.sh` | EXIT 0 — PASS |
| README sync gate | `bash scripts/check-readme-sync.sh .` | 89/89 — EXIT 0 |
| modules.json valid | `node -e "JSON.parse(...)"` | PASS |
| statusline stdin | `printf '{"model":...}' \| bash source/statusline/ideiaos-statusline.sh` | `work  ·  Opus 4.8  ·  IdeiaOS` |
| evals --list | `bash evals/run-evals.sh --list </dev/null` | 22 cases listed |
| evals case count | `ls evals/cases/EVAL-*.md \| wc -l` | 22 (>=20) |
| aliases use correct flag | `grep -c append-system-prompt setup.sh` | 5 occurrences |
| no --system-prompt misuse | grep for bare `--system-prompt` | PASS: only in comment |
| no HTML comments | `grep -c '<!--' ...` | 0 in all 3 touched files |
| dry-run pre-commit | `bash -n setup.sh && bash scripts/check-readme-sync.sh .` | both EXIT 0 |
| context file readable | `cat source/contexts/review.md >/dev/null` | PASS |

## Verification Table (from plan)

| Check | Expected | Actual |
|-------|----------|--------|
| `bash -n setup.sh` | exit 0 | PASS |
| `grep -c append-system-prompt setup.sh` | >= 1 | 5 |
| No `--system-prompt` misuse for aliases | none | PASS |
| `grep -c '.ideiaos/contexts' setup.sh` | >= 1 | 7 |
| `grep -c 'ideiaos-statusline.sh' setup.sh` | >= 1 | 5 |
| modules.json valid + 4 new IDs | OK | PASS |
| evals NOT a module | none | PASS |
| `bash scripts/check-readme-sync.sh .` | exit 0 | 89/89 PASS |
| No HTML comments added | none | 0 in all files |
| Commit-clean dry-run | both exit 0 | PASS |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All context files (dev.md, review.md, research.md) and statusline script are Wave 1 deliverables (already in `source/`). The aliases snippet is offered correctly and reads real deployed files.

## Threat Flags

None. No new network endpoints, auth paths, or trust-boundary schema changes introduced. All new files are static shell/markdown assets deployed to user's local `~/.ideiaos/`.

## Self-Check

Files verified:
- `setup.sh` — modified, `bash -n` passes
- `manifests/modules.json` — 70 modules, JSON valid
- `manifests/plugin-membership.md` — new section present, first line `# SOURCE: IdeiaOS v2`
- `README.md` — 89/89 sync, key strings present

Commits verified:
- `4973609` — feat(07-03): setup.sh steps 5.22+5.23
- `3f2be17` — feat(07-03): manifests + README sync

## Self-Check: PASSED
