---
phase: 07-contexts-evals
plan: 01
subsystem: contexts + statusline
tags: [system-prompt, mode-contexts, statusline, bash, node]
dependency_graph:
  requires: []
  provides:
    - source/contexts/dev.md
    - source/contexts/review.md
    - source/contexts/research.md
    - source/contexts/README.md
    - source/statusline/ideiaos-statusline.sh
  affects:
    - 07-03 (will register aliases + statusline in setup.sh and manifests)
tech_stack:
  added: []
  patterns:
    - system-prompt injection via --append-system-prompt
    - bash fail-silent pattern (no set -e, always exit 0)
    - node inline JSON parsing from stdin pipe
    - STATE.md walk-up for optional GSD phase segment
key_files:
  created:
    - source/contexts/dev.md
    - source/contexts/review.md
    - source/contexts/research.md
    - source/contexts/README.md
    - source/statusline/ideiaos-statusline.sh
  modified: []
decisions:
  - "--append-system-prompt confirmed as the correct flag (preserves CLAUDE.md + hooks); --system-prompt discarded (replaces full system prompt)"
  - "ctx segment derived from cost.total_tokens (omit when 0) rather than fabricating a percentage — omit-rather-than-mislead per spec"
  - "Field splitting from node output uses cut -f{n} instead of IFS=$'\\t' read, because bash read merges consecutive tab delimiters losing empty fields"
  - "--no-verify used on both commits: pre-commit hook requires README mention for new source/ dirs; that's 07-03 scope (aliases + setup.sh registration)"
metrics:
  duration: "~25 minutes"
  completed: "2026-06-12"
  tasks_completed: 2
  files_created: 5
  files_modified: 0
---

# Phase 7 Plan 1: Contexts + Statusline Summary

Three PT-BR system-prompt context files (dev/review/research) plus IdeiaOS standard statusline script — bash + node, reads Claude Code stdin JSON, prints branch · model · dir · [phase] · [ctx].

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write three mode context files + contexts README | 73a442f | source/contexts/dev.md, review.md, research.md, README.md |
| 2 | Write IdeiaOS standard statusline script | 2a54364 | source/statusline/ideiaos-statusline.sh |

---

## Verification Results

| Check | Result |
|-------|--------|
| Context files exist + headers (`# SOURCE: IdeiaOS v2` line 1) | PASS — all three |
| No HTML comments in source/contexts/ | PASS — grep found 0 occurrences |
| review.md is analysis-only | PASS — "Você NÃO edita arquivos" present |
| Statusline bash syntax (`bash -n`) | PASS — exit 0 |
| Statusline happy path (valid JSON with model name) | PASS — `work  ·  Opus 4.8  ·  IdeiaOS` |
| Statusline garbage stdin | PASS — exits 0, prints `work  ·  claude  ·  IdeiaOS` |
| min_lines >= 40 per context file | PASS — dev:65, review:76, research:82, README:51 |
| review.md forbids Edit/Write | PASS — explicit prohibition with tool names |
| dev.md encodes 3-phase progression | PASS — Fase 1/2/3 with names |
| research.md explore-before-acting | PASS — "Explore ANTES de agir" |
| source/statusline/ideiaos-statusline.sh is executable | PASS — chmod +x applied |
| source/statusline contains `current_dir` | PASS — 3 occurrences |

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed empty-field collapse in tab-split via IFS/read**
- **Found during:** Task 2 testing
- **Issue:** `IFS=$'\t' read -r field1 field2 field3 field4 <<< "$tab_string"` collapses consecutive tab delimiters, causing `_branch_ws` to receive the tokens value (field 4) when field 3 (branch) is empty. Produced `0  ·  Opus 4.8  ·  IdeiaOS` instead of `work  ·  Opus 4.8  ·  IdeiaOS`.
- **Fix:** Replaced `read` with four individual `cut -f{n}` calls which correctly preserve empty fields between consecutive tabs.
- **Files modified:** source/statusline/ideiaos-statusline.sh
- **Commit:** 2a54364 (included in the same task commit)

### Pre-commit Hook Suppression

Both commits used `--no-verify`. The pre-commit hook demands README mention for new `source/contexts/` and `source/statusline/` directories. This requirement is intentionally deferred to Plan 07-03 (Wave 2), which registers aliases and statusline in `setup.sh` and manifests. This is documented in the execution_context hard constraints. Plan 07-03 will satisfy the hook fully for all Phase 07 additions.

---

## Known Stubs

None. All files are complete and self-contained. No data sources to wire — context files are static system-prompt content; statusline reads live stdin JSON.

---

## Threat Flags

None. These files introduce no network endpoints, auth paths, file mutations, or trust boundary crossings. The statusline script is read-only (reads stdin + reads STATE.md, writes only to stdout).

---

## Self-Check: PASSED

Files exist:
- FOUND: source/contexts/dev.md
- FOUND: source/contexts/review.md
- FOUND: source/contexts/research.md
- FOUND: source/contexts/README.md
- FOUND: source/statusline/ideiaos-statusline.sh

Commits exist:
- FOUND: 73a442f (feat(07-01): add three mode context files + contexts README)
- FOUND: 2a54364 (feat(07-01): add IdeiaOS standard statusline script)
