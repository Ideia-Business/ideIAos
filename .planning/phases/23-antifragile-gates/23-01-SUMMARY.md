---
phase: 23-antifragile-gates
plan: 23-01
subsystem: lib/gates
tags: [antifragile, gates, bash, R6-01, hooks, build]
dependency_graph:
  requires: []
  provides: [source/lib/gates.sh, source/rules/common/antifragile-gates.md]
  affects: [source/hooks/memory-export.sh, source/hooks/observe-session-end.sh, scripts/build-adapters.sh]
tech_stack:
  added: []
  patterns: [antifragile-gates, binary-test-s, inline-fallback, fail-silent-hook-contract]
key_files:
  created:
    - source/lib/gates.sh
    - source/rules/common/antifragile-gates.md
  modified:
    - source/hooks/memory-export.sh
    - source/hooks/observe-session-end.sh
    - scripts/build-adapters.sh
decisions:
  - "Inline fallback gate_output defined in hooks because installed copies at ~/.claude/hooks/ have no IDEIAOS_DIR at runtime"
  - "require_file delegates to assert_nonempty (test -s) for consistency — all three functions enforce non-empty, not just existence"
  - "build-adapters.sh gate skips in DRY_RUN mode to match existing run() wrapper pattern"
  - "observe-session-end.sh gate is warn-only (stderr) — hook must exit 0 regardless of gate result"
  - "README.md update skipped per orchestrator coordination rules (centralized at end of parallel wave)"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-16"
  tasks_completed: 2
  tasks_total: 3
  files_created: 2
  files_modified: 3
---

# Phase 23 Plan 01: Antifragile Gates Summary

Bash antifragile gate helper (`source/lib/gates.sh`) with three functions — `assert_nonempty`, `gate_output`, `require_file` — applied at 3 real I/O validation points across hooks and build scripts; gate pattern documented in `source/rules/common/antifragile-gates.md`.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Create source/lib/gates.sh helper | b93fc29 | source/lib/gates.sh |
| 2 | Apply gates at 3 real points + rule doc | e3d5875 | memory-export.sh, observe-session-end.sh, build-adapters.sh, antifragile-gates.md |
| 3 | Update README.md | SKIPPED | README.md — per orchestrator coordination rules |

## What Was Built

### source/lib/gates.sh (new)

Reusable bash 3.2 compatible gate helper. Key properties:

- Double-source guard via `__IDEIAOS_GATES_LOADED` sentinel (idempotent)
- Three functions all delegate to `assert_nonempty` which does `test -s PATH` only
- No jq, no python3, no external dependencies
- Returns 0 on pass, 1 + stderr message on fail — caller decides action

### source/rules/common/antifragile-gates.md (new)

Rule document explaining the pattern: why `test -s` cannot be hallucinated, how to source the helper, hook-vs-build failure contracts, and the inline fallback pattern for installed hooks.

### Gate Point 1 — memory-export.sh

Inserted after `trap cleanup_tmp EXIT`: loads gates.sh from IDEIAOS_DIR when available, otherwise defines `gate_output() { test -s "${1:-}" 2>/dev/null; }` inline. Gate fires before the plumbing commit path: if `$CHANGED > 0` but `TMP_LIST` is missing or empty, exits 0 silently (hook contract preserved).

### Gate Point 2 — observe-session-end.sh

Inline `test -s "$OBS_DIR/observations.jsonl"` immediately after the `printf ... >> observations.jsonl` append. Warn-only: emits stderr message if file missing/empty, never exits non-zero from hook.

### Gate Point 3 — build-adapters.sh

Inside `build_claude()` hook copy loop: loads gates.sh from IDEIAOS_DIR, falls back to inline definition, then calls `gate_output "$CLAUDE_HOOKS_DIR/$fname"`. In live mode (not DRY_RUN): a missing or empty hook file after `cp` triggers `exit 1` — build scripts fail loudly.

## Deviations from Plan

None — plan executed exactly as written. Task 3 (README.md) is skipped per orchestrator coordination rule: README updates are centralized at the end of the parallel wave and committed by the orchestrator.

## Verification Results

All 11 automated checks passed:

1. gates.sh exists, sources cleanly, double-source idempotent
2. Smoke test: assert_nonempty returns 0 on real file, non-0 on missing
3. memory-export.sh has gate_output
4. observe-session-end.sh has test -s gate on observations.jsonl
5. build-adapters.sh has gate_output
6. antifragile-gates.md present with SOURCE header
7. Hooks have no bare `exit 1` (fail-silent contract preserved)
8. gates.sh uses only `[ ]` (bash 3.2 compat, no `[[ ]]`)
9. gates.sh has no jq dependency
10. gates.sh has SOURCE: IdeiaOS header
11. antifragile-gates.md body has no bare HTML comments

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or trust boundaries introduced. Threat model T-23-01 / T-23-02 / T-23-03 all mitigated or accepted as documented in the plan.

## Self-Check: PASSED

- source/lib/gates.sh: EXISTS (b93fc29)
- source/rules/common/antifragile-gates.md: EXISTS (e3d5875)
- source/hooks/memory-export.sh: MODIFIED (e3d5875)
- source/hooks/observe-session-end.sh: MODIFIED (e3d5875)
- scripts/build-adapters.sh: MODIFIED (e3d5875)
- Commits b93fc29, e3d5875: VERIFIED in git log
