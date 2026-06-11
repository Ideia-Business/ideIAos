---
phase: "01"
plan: "01-04"
subsystem: hooks/deploy
tags: [hooks, setup, readme, deploy, idempotent, settings-json, test-harness]
dependency_graph:
  requires: ["01-01", "01-02", "01-03"]
  provides: [hook-deploy-setup, readme-sync-01, harness-complete]
  affects: [setup.sh, README.md, hooks/test-hooks.sh]
tech_stack:
  added: []
  patterns:
    - "Idempotent hook deploy: diff -q cp+chmod pattern (replicated from steps 5.5-5.6)"
    - "settings.json warn+heredoc snippet (never auto-modify — security rule T-01-10)"
    - "README 3-point sync: component table + file tree + settings.json troubleshooting"
    - "Harness typecheck assertions: non-TS -> assert_empty, no-tsc -> assert_empty"
key_files:
  created: []
  modified:
    - setup.sh
    - README.md
    - hooks/test-hooks.sh
decisions:
  - "Steps 5.15-5.19 chosen (after 5.14b) to avoid colliding with existing numbering; 5.10/5.11/5.12/5.13/5.14 were non-sequential in the file — new blocks inserted after 5.14b"
  - "test-hooks.sh and test-typecheck-on-edit.sh added to README file tree (required by check-readme-sync pre-commit hook)"
  - "Checkpoint task 3 auto-approved per user authorization; settings.json snippet documented in SUMMARY for manual application"
metrics:
  duration: "482s (~8 min)"
  completed: "2026-06-11"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 3
requirements: [typecheck, console-log, precompact, session-summary, strategic-compact]
---

# Phase 01 Plan 04: Hook Deploy (setup.sh) + README Sync + Harness Completion Summary

**One-liner:** setup.sh gets 5 idempotent deploy blocks (steps 5.15-5.19) with settings.json warn+snippet; README synced at 3 points; test harness typecheck assertions replace SKIPs — full suite passes.

---

## What Was Built

### setup.sh — Steps 5.15 to 5.19

Five new hook deploy blocks added after step 5.14b, following the exact pattern of steps 5.5/5.6:

| Step | Hook | Event | Key config |
|------|------|-------|------------|
| 5.15 | typecheck-on-edit.sh | PostToolUse Edit\|Write | async:true, asyncRewake:true, timeout:60 |
| 5.16 | console-log-guard.sh | PostToolUse Edit\|Write | timeout:5 |
| 5.17 | strategic-compact.sh | PreToolUse (no matcher) | timeout:3 |
| 5.18 | precompact-state-save.sh | PreCompact | timeout:10 |
| 5.19 | session-summary.sh | Stop | timeout:30 |

Each block:
- Defines `HOOK_FILE` / `HOOK_TEMPLATE` using existing `HOOK_DIR` / `SETUP_DIR` vars
- `diff -q` idempotent check: skips copy if already at latest version, otherwise `cp + chmod +x`
- `grep -q "<name>.sh" "$SETTINGS_FILE"` (read-only) — never writes to settings.json (T-01-10)
- `warn` + heredoc `SNIPPET` with correct JSON event config if not registered
- Descriptive `echo` of hook behavior (matches pattern of existing steps)

### README.md — 3 Sync Points

1. **Component table** (~line 208): 5 new rows added after `deia-trigger.sh` row
2. **File tree** (~line 585): 5 new `.sh` entries under `hooks/`; also added `test-hooks.sh` and `test-typecheck-on-edit.sh` (required by `check-readme-sync` pre-commit hook)
3. **Troubleshooting settings.json** (~line 648): Full block with all 5 new hooks added: PostToolUse (typecheck async+asyncRewake + console-log-guard), PreToolUse (strategic-compact), PreCompact (precompact-state-save), Stop (session-summary); A5 note about `"Compact"` fallback key added

### hooks/test-hooks.sh — Harness Completion

- **Section 3 (new):** `typecheck-on-edit.sh` assertions replacing SKIPs:
  - Test 3a: non-TS file (`.md`) → `assert_empty`
  - Test 3b: `.ts` file in tmpdir without `node_modules` (no tsc) → `assert_empty` + cleanup
- **Section 4 (renamed):** `precompact-state-save.sh` + `session-summary.sh` moved to PRESENT/SKIP block with updated message referencing plan 01-02
- Full suite result: `ALL TESTS PASSED` (exit 0)

---

## Checkpoint Task 3 — Auto-Approved

**Status:** Auto-approved per user authorization ("execute completamente tudo").

**What requires manual action:** The 5 hooks are now deployed to `~/.claude/hooks/` via `setup.sh`, but they must be registered in `~/.claude/settings.json` to fire. `setup.sh` never auto-modifies `settings.json` (security rule T-01-10).

### settings.json snippet to apply manually

Add the following to `~/.claude/settings.json` under each event key. Replace `<você>` with your username:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/typecheck-on-edit.sh\"",
          "timeout": 60,
          "async": true,
          "asyncRewake": true
        }]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/console-log-guard.sh\"",
          "timeout": 5
        }]
      }
    ],
    "PreToolUse": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/strategic-compact.sh\"",
          "timeout": 3
        }]
      }
    ],
    "PreCompact": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/precompact-state-save.sh\"",
          "timeout": 10
        }]
      }
    ],
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/session-summary.sh\"",
          "timeout": 30
        }]
      }
    ]
  }
}
```

> **Note (A5):** If `PreCompact` does not fire, try `"Compact"` as the key name instead of `"PreCompact"`.

### Validation steps after registering

1. Run `bash setup.sh --global-only` — confirm 5 "instalado" or "já na versão" messages + 5 "NÃO registrado" warnings (until registered)
2. After applying snippet and restarting Claude Code session:
   - **typecheck:** In an ideiapartner/nfideia project, introduce a TS type error → expect warning within seconds
   - **console-log:** Add `console.log("x")` to a `.ts` file → expect Lovable prod warning
   - **precompact:** Run `/compact` → open `.planning/STATE.md` → confirm `## Compact Snapshot` section with timestamp
   - **strategic-compact:** After ~50 tool calls → confirm `/compact` suggestion
   - **session-summary:** End a turn → confirm new file in `~/.claude/sessions/YYYY-MM-DD-*.tmp`; if in IdeiaOS, confirm `docs/CONTINUATION_HANDOFF.md` updated

---

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 — setup.sh deploy blocks | 835d2c9 | feat(01-04): 5 idempotent hook deploy blocks (steps 5.15-5.19) |
| 2 — README + harness | 03e6260 | feat(01-04): sync README + close test harness for 5 phase-01 hooks |

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] test-hooks.sh and test-typecheck-on-edit.sh missing from README**

- **Found during:** Task 2 commit (pre-commit hook blocked)
- **Issue:** `check-readme-sync.sh` requires all `hooks/*.sh` files to appear in README.md. The plan specified adding only the 5 new hook scripts, but the two test scripts (`test-hooks.sh`, `test-typecheck-on-edit.sh`) created in plans 01-01/01-03 were also missing.
- **Fix:** Added `test-hooks.sh` and `test-typecheck-on-edit.sh` to the file tree section of README.md
- **Files modified:** README.md
- **Commit:** 03e6260

---

## Threat Model Compliance

| Threat | Status |
|--------|--------|
| T-01-10: Tampering — setup.sh auto-modifying settings.json | Enforced — new blocks use only `grep -q` (read) + `warn` + snippet |
| T-01-11: Repudiation — hooks installed without README trail | Enforced — 3-point README sync complete; pre-commit hook validated |

---

## Known Stubs

None. All hooks are fully implemented. settings.json registration is intentionally manual (security rule).

---

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes.

---

## Self-Check: PASSED

Files modified:
- setup.sh: FOUND (contains 5.15-5.19 blocks)
- README.md: FOUND (5 hooks in 3 sync points)
- hooks/test-hooks.sh: FOUND (typecheck assertions, no SKIP)

Commits:
- 835d2c9: FOUND
- 03e6260: FOUND

Harness: ALL TESTS PASSED (exit 0)
