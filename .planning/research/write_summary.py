#!/usr/bin/env python3
"""Write SUMMARY.md for IdeiaOS v5 research."""

content = """\
# Project Research Summary

**Project:** IdeiaOS v5 - Cross-IDE Shared Memory (Lovable-safe)
**Domain:** Dev-OS tooling / meta-framework infrastructure - memory synchronization layer
**Researched:** 2026-06-14
**Confidence:** HIGH (all mechanisms verified against live files, real incidents, and official docs)

---

## Executive Summary

IdeiaOS v5 adds cross-IDE shared memory synchronization - a git-backed bridge that lets Claude Code
and Cursor share curated project facts across machines without ever touching `main`. The core
mechanism: facts live on the `planning` branch under `.planning/memory/shared/`, written via git
plumbing (no branch checkout, no working-tree contamination), imported at SessionStart and exported
at session close via a new explicit skill. This approach extends the existing IdeiaOS learning loop
(observations to instincts to vault) rather than replacing or duplicating it. No new dependencies
are required - the entire mechanism is pure bash plus git plumbing.

The non-negotiable invariant - confirmed across all four research domains - is that `main` must
never receive memory churn. Lovable Cloud watches `main` continuously and triggers Update on any
commit there. The leaked `.lovable_mem_tmp.md` on `nfideia:main` (live as of 2026-06-14, commit
604c0a19) is the canonical proof-by-failure that this risk is not theoretical. The entire v5 design
is organized around 6 barriers replicating the `versions.lock` protection pattern: gitignore,
autosync branch guard, pre-commit hook, planning-branch isolation, git-plumbing write path (no
working-tree residue), and autosync exclusion of memory paths.

The MVP is 7 small features. Cursor's native Memories feature is not bridgeable (server-side
storage, no filesystem access) - the Cursor bridge is read-only via
`.cursor/rules/memory-bridge.mdc` with `alwaysApply: true`. Claude Code is the active
producer/syncer; Cursor is the passive consumer. Export is triggered by an explicit `/memory-sync`
skill, not by the Stop hook on every turn, because no true SessionEnd event exists and per-turn
export would be too noisy. A pre-v5 prerequisite - removing the existing leaked file from
`nfideia:main` - must complete before any memory tooling is written.

---

## Key Findings

### Recommended Stack

No new dependencies are required. The entire mechanism is pure bash plus git plumbing, consistent
with IdeiaOS's existing hook infrastructure. Claude Code native memory files
(`~/.claude/projects/<slug>/memory/`) use plain markdown with YAML frontmatter - readable and
writable with standard bash. The `planning` branch is already the established state store for
IdeiaOS, already tracked by autosync, and already read without checkout by `git-sync-check.sh` via
`git show planning:<path>`.

**Core mechanisms:**

- **Git plumbing pipeline** (`hash-object`, `read-tree`, `update-index`, `write-tree`,
  `commit-tree`, `update-ref`): primary write path - operates purely in the git object/ref layer
  with zero working-tree impact. Verified live against nfideia repo.
- **`git show planning:<path>` / `git archive`**: read path - reads files from planning branch
  without checkout. Pattern already used by `git-sync-check.sh`.
- **`git worktree add`**: documented fallback write path - creates a second checkout in `/tmp/`,
  commits, removes. See reconciliation below.
- **Claude Code memory format** (YAML frontmatter, `name:` / `description:` / `metadata:` fields,
  one-file-per-fact with `type_slug.md` naming): canonical interchange format. One-file-per-fact
  prevents git line conflicts on concurrent edits.
- **`.cursor/rules/memory-bridge.mdc` with `alwaysApply: true`**: only accessible write path into
  Cursor's session context. Cursor Memories API is not filesystem-accessible (server-side or opaque
  SQLite).

**Known bug to handle (issue #30828):** Claude Code sometimes converts underscores to hyphens in
the project slug, creating a second memory directory for the same project. The import script must
check both the canonical slug (`tr '/' '-'`) and the normalized variant
(`tr '/' '-' | tr '_' '-'`) and use whichever has a MEMORY.md.

### Mechanism Reconciliation: Git Plumbing vs Git Worktree

STACK.md and ARCHITECTURE.md make different primary recommendations for the write path.

**STACK.md recommends: git plumbing pipeline as primary** (hash-object, commit-tree, update-ref).
Rationale: operates purely in the object/ref layer, no working-tree directory created, no cleanup
required, no risk of interfering with open editors or file watchers, no leftover state on crash.

**ARCHITECTURE.md recommends: `git worktree add` as primary.** Rationale: standard git mechanism
for committing to a non-checked-out branch, easier to reason about for file staging operations.

**Resolution: git plumbing is the primary recommendation. `git worktree` is the documented
fallback.**

The decisive factor is the `.lovable_mem_tmp.md` failure mode. `git worktree add` creates a real
filesystem directory under `/tmp/ideiaos-mem-wt-<pid>`. If the export hook crashes between
`worktree add` and `worktree remove`, the directory persists and git refuses to add another
worktree to the same branch on the next invocation - requires manual `git worktree remove --force`
to recover. The plumbing pipeline produces only transient objects in the git object store and a
temp index file cleaned up with `rm -f "$TMPIDX"` - no residue risk. Document `git worktree` as
`# FALLBACK:` in the hook script for repos where the plumbing pipeline encounters an edge case.

### Expected Features

**Must have - MVP v5 (7 P1 features):**

- `shared/` vs `local/` directory split on planning branch - team-visible vs per-developer
  isolation
- Project scoping by repo slug - `planning:.planning/memory/shared/<proj-slug>/` namespacing
- Import-on-SessionStart - `memory-import.sh` reads shared store and populates native IDE memory
- Export-on-close (explicit, manual gate) - `/memory-sync export` skill with secret strip gate
- `MEMORY.md` index in shared/ - auto-generated on export; lists facts with date and contributor
- Conflict resolution (newer-wins by `contributed_at` timestamp) - same-slug fact: newer wins
- Member scoping - `contributed_by` plus `contributed_at` in frontmatter; member-pending notes
  gitignored by default

**Should have - v5.x (after first sprint of real use):**

- `/memory-sync status` - visual dashboard of shared vs local vs pending export
- Dedup on import - slug-level check before overwriting local fact with older shared version
- Selective import by type - only `project`/`reference` facts auto-imported; `user`/`feedback` stay
  local
- Learning-loop bridge - `extract-learnings` auto-promotes `applies_to_projects: [global]` facts to
  shared/ after gate triplet
- Decay/curation - `expires:` flag on facts without `last_reinforced` for over 30 days

**Defer to v5 follow-on:**

- Instinct promotion to shared/ - `/evolve` global-scope mature instincts surfaced to shared/
- 3-tier model formal documentation - explicit doc of local, shared/planning, vault
- `/memory-sync import --dry-run` - preview mode for teams larger than 3 developers

**Anti-features (9 things explicitly NOT building):**

1. Any write to `main` - hard constraint; Lovable regression risk (the invariant)
2. Auto-push on every commit - conflicts with autosync, creates noisy git history
3. Live/real-time sync daemon - violates CLI-first/no-server philosophy (AIOX Article I)
4. Cross-project memory injection - the primary failure mode from the nfideia/ideiapartner drift
   incident
5. LLM-based conflict resolution - expensive, silently mutates facts; use newer-wins instead
6. Shared `user`/`feedback` type facts - personal preferences must never reach team store
7. Parallel second brain alongside instincts - PROJECT.md decision: instincts desaguam no vault,
   nao criar segundo cerebro paralelo
8. Auto-promotion of all `[global]` learnings without gate - floods shared/ with project-specific
   facts
9. Storing raw `observations.jsonl` in shared/ - raw observations may contain secrets and literal
   paths

### Architecture Approach

The system has three layers: (1) a canonical store on the `planning` branch at
`.planning/memory/shared/`; (2) bridge scripts (`memory-import.sh` on SessionStart, `/memory-sync`
skill for export) that read/write the store without branch checkout; and (3) the existing native
IDE memory directories (`~/.claude/projects/<slug>/memory/`) as the working copy. Autosync
propagates planning branch commits to the remote; the next SessionStart import on any machine picks
up the changes via `git-sync-check.sh`'s existing fetch.

**Major components:**

1. **`.planning/memory/shared/`** (on planning branch, never on main) - canonical multi-machine
   fact store; `facts/<type>_<slug>.md` format mirroring native Claude Code memory, `MEMORY.md`
   index rebuilt deterministically from directory scan
2. **`memory-import.sh`** (SessionStart hook, after `git-sync-check.sh` in hooks.json order) -
   reads planning branch via `git show`/`git archive`, merges into
   `~/.claude/projects/<slug>/memory/`, freshness-guarded by SHA compare; exit 0 on all failures
3. **`/memory-sync` skill** (`source/skills/memory-sync/SKILL.md`) - explicit export gate
   replacing missing SessionEnd hook; also handles force-import, status display, and secret strip
   gate
4. **`memory-export.sh`** (called by skill, not wired as Stop hook) - diffs native memory against
   planning branch, writes net-new/changed facts via git plumbing pipeline, commits to planning
   branch; autosync pushes on next cycle
5. **`.cursor/rules/memory-bridge.mdc`** (`alwaysApply: true`, gitignored, regenerated by import)
   - Cursor passive consumer bridge; inline snapshot of shared MEMORY.md content
6. **`idea-doctor.sh` sections 12 and 13** - verify Patches 12/13 installed, hooks registered,
   planning branch has `shared/` directory

**Data flow (one-way per trigger):**

```
Claude Code session modifies native memory (~/.claude/projects/<slug>/memory/)
  /memory-sync export (human-triggered at session close)
  git plumbing pipeline, planning branch local ref
  autosync LaunchAgent, origin/planning
  git-sync-check.sh fetches on next SessionStart
  memory-import.sh, native memory on all machines
  (manual gate) /extract-learnings Passo 4b, Obsidian vault
```

### Critical Pitfalls

1. **Memory churn reaches `main` and triggers Lovable Update** - HARD BLOCKER. The
   `.lovable_mem_tmp.md` on `nfideia:main` proves this path is real. Prevention: gitignore all
   memory paths at repo root for Lovable projects; autosync branch guard refuses to commit if
   branch is `main`; lovable-handoff pre-commit gate blocks files matching `memory|mem_tmp`. Must
   exist BEFORE the first memory file is created.

2. **Autosync commits memory to the wrong branch (the `versions.lock` analogy)** - `git add -A` is
   branch-blind. If a developer has `main` checked out and autosync fires within 15 minutes, any
   working-tree file goes to `main`. Apply the same 6-barrier pattern that protected
   `versions.lock`: autosync branch guard plus path exclusion plus directional (not generic)
   pre-commit error message.

3. **Stale and contradictory memory amplified across the team** - Git-backed shared memory has no
   natural GC. Contradictory records accumulate; an AI agent picks based on heuristics (and picks
   wrong, per the `ambiguous-drift-warning-induces-agent-revert.md` learning). All shared facts
   must carry `expires:` and `last_verified:` frontmatter fields. Pruning requires human
   confirmation, not AI auto-pruning.

4. **Ambiguous conflict message causes AI to resolve in the wrong direction** - Structurally
   identical to the `versions.lock` semver inversion failure. A conflict message saying "resolve"
   without direction is a prompt. Use fast-forward-only merges on the memory store. Conflict
   messages must be directional and must explicitly say "DO NOT auto-resolve - human must review
   conflicting facts."

5. **Personal or secret content committed to team-shared store** - Memory export is
   heuristic-driven; API tokens, client data, and CPF/CNPJ patterns can be captured. Run
   `scan-absorbed.sh`-style grep over every file before it enters shared/. Default scope is
   `personal`; `scope: team` requires explicit declaration (fail-safe default).

6. **Export-on-close not firing on crash** - Stop fires after every model response, not on process
   exit. Per-turn Stop export is too noisy; "last Stop" heuristic fails on crashes. Resolution:
   export is a skill, not a Stop hook. Stop hook only writes a session-close reminder.

---

## Implications for Roadmap

### Pre-v5 Prerequisite: nfideia Cleanup (must complete before Phase 1)

**Rationale:** The `.lovable_mem_tmp.md` file is live on `nfideia:main` (commit 604c0a19, confirmed
2026-06-14). Building memory tooling while this file exists normalizes the invariant violation.
Remove it first to establish a clean baseline.
**Delivers:** `nfideia:main` clean of memory artifacts. Verified by
`git log origin/main -- '*.lovable_mem_tmp*'` returning empty.
**Action:** `git rm --cached .lovable_mem_tmp.md` on nfideia main, commit
"chore: remove memory artifact from main", push, verify Lovable dashboard shows no unintended
Update.
**Research flag:** No research needed - this is a `git rm` operation.

---

### Phase 1: Foundation - Invariants and Branch Topology

**Rationale:** All other phases depend on the invariant holding. Barriers must exist before the
first memory file is written. This is the `versions.lock` 6-barrier pattern applied to memory.
**Delivers:**
- Autosync branch guard: refuse to commit if current branch is `main` - added to `git-autosync`
- Gitignore patterns for `.planning/memory/` added to all 4 Lovable project repos and IdeiaOS
- Branch topology documented in `docs/decisions/`: main receives from work/feature only; planning
  never merges to main; memory store lives on planning branch
- Pre-commit hook in `lovable-handoff/SKILL.md`: blocks files matching memory path patterns from
  commits targeting `main`
- `.planning/.gitignore` on planning branch ignoring `memory/local/`

**Addresses:** Anti-features 1 and 2; Pitfalls 1, 2, 3
**Research flag:** No deeper research needed - mirrors `versions.lock` 6-barrier precedent exactly.

---

### Phase 2: Canonical Store and Format Design

**Rationale:** Data format and directory layout must be locked before any bridge code is written.
Format decisions (frontmatter fields, slug naming, scope defaults, secret scan patterns) are hard to
migrate after facts are stored.
**Delivers:**
- `.planning/memory/shared/` skeleton on planning branch (MEMORY.md + `facts/` directory) committed
- Canonical memory file schema: `name`, `description`, `metadata`, `scope`, `contributed_by`,
  `contributed_at`, `last_verified`, `expires` frontmatter fields (strict superset of Claude Code
  native format)
- Project slug derivation handling issue #30828 - check both canonical and normalized slug variants
- Secret scan integration: export scanner blocks files containing API key / JWT / connection string
  / CPF/CNPJ patterns before they enter shared/
- `scope: personal` as default (fail-safe): facts without explicit `scope: team` never enter
  shared/
- Conflict resolution policy: same-slug uses newer `contributed_at`; fast-forward-only for shared/
  commits

**Addresses:** MVP features: `shared/` vs `local/` split, project scoping, MEMORY.md index, member
scoping
**Avoids:** Pitfalls 5 (secret leakage), 6 (cross-project slug mismatch), 8 (ambiguous conflict)
**Research flag:** No deeper research needed - format is a strict superset of Claude Code's
verified native format.

---

### Phase 3: Import Bridge (memory-import.sh)

**Rationale:** Import before export - reading proves the data model before writing to it. Import
is lower risk (worst case: fails to load memory, does not corrupt shared/).
**Delivers:**
- `source/hooks/memory-import.sh` registered as SessionStart hook after `git-sync-check.sh` in
  hooks.json
- Reads planning branch via `git show` / `git archive` (no checkout, no working-tree impact)
- Freshness guard: skip if planning branch SHA unchanged since last import (mirrors
  `git-sync-check.sh` 90s guard)
- Merges new/updated shared facts into `~/.claude/projects/<slug>/memory/` (preserves local-only
  facts)
- Rebuilds MEMORY.md index from directory scan (deterministic, not in-place - minimizes merge
  conflicts)
- `exit 0` on all failures (offline, no planning branch, no memory) - never blocks session start
- Directional slug validation: emits error if slug from git remote does not match memory directory
  being imported
- Patch 12 entry in `install-global-patches.sh` plus section 12 in `idea-doctor.sh`

**Uses:** git plumbing read path (`git show`, `git archive`), existing `hooks.json` registration
pattern
**Avoids:** Pitfall 4 (stale import - import runs after git-sync-check.sh which fetches); pitfall 9
(format divergence - canonical format verified in Phase 2)
**Research flag:** No deeper research needed - all integration points verified against live hooks.json
and git-sync-check.sh.

---

### Phase 4: Export Bridge and /memory-sync Skill

**Rationale:** Export only after import is proven stable. Export is the higher-risk operation
(writes to planning branch). Skill-as-gate is the correct pattern given no true SessionEnd hook
exists.
**Delivers:**
- `source/hooks/memory-export.sh` implementing git plumbing pipeline as primary, with `git
  worktree` as documented fallback
- Diff logic: native memory vs planning branch shared/ - skips empty exports, no empty commits
- Retry once on fast-forward failure (planning branch moved between read and write)
- `exit 0` always - never blocks session close
- `source/skills/memory-sync/SKILL.md` - `/memory-sync export`, `/memory-sync import` (force),
  `/memory-sync status`
- Patch 13 entry in `install-global-patches.sh` plus section 13 in `idea-doctor.sh`
- Autosync audit: verify `git push origin planning` in autosync loop; add if missing
- `.cursor/rules/memory-bridge.mdc` written by import (gitignored, regenerated locally - not
  committed to working branch) with inline MEMORY.md snapshot

**Addresses:** MVP features: Export-on-close, conflict resolution, Cursor bridge
**Avoids:** Pitfall 10 (export not firing on crash - skill is explicit); pitfall 2 (autosync race -
autosync runs after export commits, not simultaneously); anti-feature 3 (no daemon)
**Research flag:** No deeper research needed - git plumbing pipeline verified live on nfideia repo.

---

### Phase 5: Learning Loop Integration and Curation Tooling

**Rationale:** Core import/export loop must be stable before integrating with the existing learning
pipeline. Integration adds complexity and should not be attempted while the core is still being
validated.
**Delivers:**
- `/extract-learnings` Passo 4d: offer to push qualifying facts to `.planning/memory/shared/` in
  addition to vault (gate: `applies_to_projects: [global]` plus gate triplet confirmed plus
  developer confirms)
- `memory-audit.sh` (or `idea-doctor.sh` section): count expired vs live facts; warn when expired
  ratio exceeds 30% - human curates, not AI auto-prunes
- Decay enforcement: `expires:` field checked at import time; stale facts excluded from import
  payload
- `last_reinforced` field updated when a fact is confirmed in a new session
- `/memory-sync status` - visual list of shared vs local-only vs pending export vs expired

**Addresses:** Should-have features: learning-loop bridge, decay/curation, status command
**Avoids:** Pitfall 7 (stale memory amplification); anti-feature 8 (auto-promotion without gate)
**Research flag:** No deeper research needed - `/evolve` decay logic and `/extract-learnings` gate
triplet are existing patterns being extended.

---

### Phase Ordering Rationale

- Prerequisite (cleanup) must precede everything - establishing clean `nfideia:main` baseline
  before building tooling that depends on that invariant.
- Phase 1 (barriers) must precede memory file creation - gitignore is retroactively useless for
  already-tracked files; barriers only work if they exist before the first file.
- Phase 2 (format) must precede bridge code - format changes after bridge code require migration
  scripts; format-first avoids this entirely.
- Phase 3 (import) before Phase 4 (export) - read proves the data model; writing to an unproven
  model risks corrupting the store.
- Phase 5 (integration) last - depends on the stable core loop; premature integration would couple
  debugging cycles across two systems.
- The 9 anti-features are excluded at each phase boundary: Phases 1-2 establish main/branch
  isolation; Phases 3-4 establish the explicit export gate; Phase 5 establishes the learning
  promotion gate.

### Research Flags

**Phases needing deeper research during planning:** None. All mechanisms are verified against live
code and official documentation. Implementation risk is integration complexity, not unknown
territory.

**Phases with standard, well-documented patterns (skip research-phase):** All phases. The git
plumbing pipeline, hook registration via hooks.json, and Claude Code memory format are all fully
verified. The Cursor bridge is constrained to the only available mechanism (.mdc files). No API
calls, no new binaries, no MCP servers.

---

## Open Design Decisions (Requirements Step Must Resolve)

These are genuine open questions where research identified the options but did not find a definitive
constraint that picks one.

### (a) Export trigger: skill-driven vs Stop hook

Options:
- **A (recommended):** `/memory-sync` skill only - human-triggered at session close
- **B:** Stop hook that exports on "last Stop" using a session-end heuristic
- **C:** Stop hook that exports every N turns (batched)

Finding: No true SessionEnd event exists. Stop fires after every model response. STACK.md
explicitly recommends skill-driven export. ARCHITECTURE.md wires it as a Stop hook but acknowledges
the "last Stop" heuristic gap. Recommendation: start with Option A; add Option B as a v5.x
enhancement if users report forgetting to export.

### (b) Dedicated `memory-sync` branch vs reuse existing `planning` branch

Options:
- **A (recommended):** Memory lives in `.planning/memory/` on the existing `planning` branch
- **B:** Dedicated orphan branch `memory-sync`

Finding: PITFALLS.md flags planning-to-main merge risk. ARCHITECTURE.md and STACK.md both assume
the `planning` branch (simpler, already tracked by autosync). Recommendation: use `planning` branch
with two mitigations: (1) protected branch rule blocking PRs from `planning` to `main` that touch
`.planning/memory/`; (2) topology ADR documenting that planning never merges to main. Revisit to
Option B if a merge accident occurs in practice.

### (c) Cursor bridge file: committed vs gitignored

Options:
- **A (recommended):** `.cursor/rules/memory-bridge.mdc` gitignored, regenerated locally by
  `memory-import.sh`
- **B:** Committed to working branch alongside code

Finding: Option A means no memory content appears in code commits; Cursor developers must run
import before getting shared facts. Option B means Cursor gets facts from a pull, but memory
content appears in code history. Recommendation: Option A for clean separation.

### (d) Instinct-to-shared promotion path

Options:
- **A (MVP):** Only facts explicitly exported via `/memory-sync` reach shared/
- **B (v5.x):** `/extract-learnings` Passo 4d auto-promotes `[global]` facts with single
  confirmation
- **C (future):** `/evolve` global plus confidence >= 0.7 auto-creates candidate in shared/

Finding: FEATURES.md marks instinct promotion as P3. Recommendation: MVP ships with Option A only;
Phase 5 implements Option B; Option C deferred until instinct bank has meaningful depth across
projects.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All mechanisms verified against live filesystem, official docs, and GitHub issues. No inference from training data. |
| Features | HIGH | Grounded in existing IdeiaOS learning loop plus verified against real community solutions (claude-git-sessions, claude-mem-sync) and Anthropic issue tracker. |
| Architecture | HIGH | All integration points verified against live source files (hooks.json, git-sync-check.sh, observe-session-end.sh, install-global-patches.sh, idea-doctor.sh). |
| Pitfalls | HIGH | Grounded in real incidents: .lovable_mem_tmp.md on nfideia:main, versions.lock revert x3, autosync mid-session firing, session 35 vs 39 drift. |

**Overall confidence:** HIGH

### Gaps to Address

- **Autosync planning push verification:** `setup-dev-machine.sh` needs auditing during Phase 4 to
  confirm `git push origin planning` is in the sync loop. If missing, one-line fix - but must be
  confirmed, not assumed.
- **Cursor bridge file decision:** Open decision (c) requires a call during requirements. Choice
  affects whether `memory-bridge.mdc` appears in code commits.
- **Export trigger for session-end:** Open decision (a) requires a call during requirements.
  Skill-only approach is recommended but should be validated against the actual developer workflow.
- **Branch protection capability:** Whether the hosting git service supports protected branch rules
  blocking `.planning/memory/` paths from PRs to `main` needs to be confirmed per-service during
  Phase 1.

---

## Sources

### Primary (HIGH confidence - verified against live files and official docs)

- Claude Code memory official docs (code.claude.com/docs/en/memory) - format, MEMORY.md loading
  limits, autoMemoryDirectory
- Claude Code hooks official docs (code.claude.com/docs/en/hooks) - SessionStart, Stop, PreCompact
  events, stdin/stdout contract
- Claude Code issue #30828 (github.com/anthropics/claude-code/issues/30828) - underscore/hyphen
  slug non-determinism confirmed
- Cursor .mdc format - verified against live `.cursor/rules/*.mdc` files in this repo and nfideia
- Cursor Memories feature (forum.cursor.com/t/0-51-memories-feature/98509) - server-side storage
  confirmed, not filesystem-accessible
- Git plumbing pipeline - proven live against /Users/gustavolopespaiva/dev/nfideia repo
- /Users/gustavolopespaiva/dev/IdeiaOS/plugins/ideiaos-core/hooks/hooks.json - canonical hook
  registry
- /Users/gustavolopespaiva/.claude/hooks/git-sync-check.sh - fetch plus fast-forward plus planning
  drift warning
- /Users/gustavolopespaiva/.claude/hooks/backlog-sync-check.sh - freshness guard (600s cache)
  pattern
- /Users/gustavolopespaiva/dev/IdeiaOS/source/hooks/observe-session-end.sh - Stop hook contract,
  anti-runaway guard
- /Users/gustavolopespaiva/dev/IdeiaOS/source/hooks/precompact-state-save.sh - planning branch
  write pattern
- /Users/gustavolopespaiva/dev/IdeiaOS/scripts/install-global-patches.sh - Patch 8/11 registration
  pattern
- /Users/gustavolopespaiva/dev/IdeiaOS/scripts/idea-doctor.sh - section structure, patch
  verification pattern
- Real incident: nfideia .lovable_mem_tmp.md on origin/main (commit 604c0a19, confirmed 2026-06-14)
- Real incident: versions.lock pin reverted x3 - commits c7fc184 (autosync), 3724ee9 (AI agent
  ambiguous warning), fixed in 7a4f54b

### Secondary (MEDIUM confidence - community solutions, multiple sources agree)

- claude-git-sessions (github.com/ingram-technologies/claude-git-sessions) - orphan branch; filter
  by type; newer-wins; no working-tree contamination
- claude-mem-sync (github.com/lopadova/claude-mem-sync/) - composite-key dedup; scoring by access
  frequency; CI merge bot
- Anthropic claude-code issue #38536 - team memory feature request confirming community patterns
- AI Memory Security Best Practices (mem0.ai/blog/ai-memory-security-best-practices) - secret
  leakage patterns
- Cursor persistent memory patterns (memnexus.ai/blog/2026-02-20-cursor-persistent-memory) -
  .cursor/rules approach confirmed

### Tertiary (informational - confirmed patterns, no new findings)

- Cross-Agent Organizational Memory (augmentcode.com/guides/cross-agent-organizational-memory)
- Why Multi-Agent Systems Need Memory Engineering (oreilly.com/radar/why-multi-agent-systems-need-memory-engineering/)
- How AI Coding Assistants Leak Secrets (knostic.ai/blog/ai-coding-assistants-leaking-secrets)

---

*Research completed: 2026-06-14*
*Ready for roadmap: yes*
"""

path = '/Users/gustavolopespaiva/dev/IdeiaOS/.planning/research/SUMMARY.md'
with open(path, 'w') as f:
    f.write(content)
print(f'Written {len(content)} bytes to {path}')
