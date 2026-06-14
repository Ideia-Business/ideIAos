# Architecture Research

**Domain:** Branch-isolated shared memory + per-IDE bridge for IdeiaOS v5
**Researched:** 2026-06-14
**Confidence:** HIGH (based on real source files; all integration points verified against code)

---

## System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        planning branch (git)                             │
│                                                                          │
│  .planning/memory/                                                       │
│  ├── shared/          ← committed, multi-machine canonical store         │
│  │   ├── MEMORY.md    ← index (frontmatter slug → file map)              │
│  │   └── facts/       ← one file per fact (same format as native mem)   │
│  └── local/           ← gitignored, machine-local draft/staging          │
│      └── staging/     ← in-progress exports before commit                │
└──────────────────────────────────────────────────────────────────────────┘
            ▲ git show planning:.planning/memory/shared/MEMORY.md          
            │ (read-only, no checkout needed)                              
            │                                                              
            │  import (SessionStart)          export (Stop / Close)       
            ▼                                 ▲                           
┌───────────────────────┐         ┌───────────────────────────────────────┐
│  Claude Code          │         │  Close bridge                         │
│  ~/.claude/projects/  │         │  (memory-export.sh Stop hook)         │
│  <slug>/memory/       │         │  git show planning:... → diff →       │
│  MEMORY.md + facts    │◄────────│  git add planning:.planning/memory/   │
│  (native format)      │         │  shared/ → commit on planning →       │
└───────────────────────┘         │  push (autosync, NOT main)            │
                                  └───────────────────────────────────────┘
            │ (future: Cursor adapter)                                     
            ▼                                                              
┌──────────────────────────────────────────────────────────────────────────┐
│  Obsidian Vault (iCloud)  — curated cross-project library                │
│  ~/Library/Mobile Documents/iCloud~md~obsidian/...                      │
│  Learnings/  Decisions/  Stack Gotchas/  References/                    │
│  Populated via /extract-learnings Passo 4b (manual curation gate)       │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## Canonical Memory Store: path layout on `planning` branch

All memory churn lives on the `planning` branch inside `.planning/memory/`. The working tree of `main` and every feature branch is never touched.

```
.planning/
└── memory/
    ├── shared/                         ← committed on planning; multi-machine
    │   ├── MEMORY.md                   ← index: "- [slug](facts/slug.md) — summary"
    │   └── facts/
    │       ├── learning_<slug>.md      ← one file per fact (mirrors native format)
    │       ├── reference_<slug>.md
    │       └── feedback_<slug>.md
    └── local/                          ← gitignored on planning branch
        └── staging/
            └── <date>-<slug>.md        ← draft facts before export commit
```

**Why this layout:**

- `shared/` is the multi-machine canonical store. Any IDE on any machine reads it the same way via `git show planning:.planning/memory/shared/...` — no checkout required, no working-tree pollution.
- `local/staging/` is the write buffer: the close bridge writes here first, diffs against shared/, then commits only net-new or changed facts to `planning`. This prevents noise commits.
- `local/` is gitignored via an entry in `.planning/.gitignore` (create this file), not the global `.config/git/ignore`, so only the planning branch is affected.
- The `facts/` filenames and frontmatter format are identical to the native Claude Code memory format (`~/.claude/projects/<slug>/memory/*.md`). This lets the import bridge do a straight copy with no transformation.

**Reading without checking out `planning`:**

```bash
# Read the index
git show planning:.planning/memory/shared/MEMORY.md

# Read a specific fact
git show planning:.planning/memory/shared/facts/learning_some-slug.md

# List all facts
git ls-tree --name-only planning .planning/memory/shared/facts/

# Export entire shared tree into a temp dir (import bridge pattern)
git archive planning .planning/memory/shared/ | tar -x -C /tmp/mem-import/
```

The `git show` + `git archive` pattern is the same technique already used by `git-sync-check.sh` to read `planning:.planning/STATE.md` — it requires no branch switch and leaves the working tree clean.

---

## The Bridge: SessionStart import and Stop export

### Component 1: `memory-import.sh` (SessionStart hook)

Reads the canonical store from the `planning` branch and syncs it into the native IDE memory directory. Registered as a SessionStart hook via the same `ideiaos-update.sh` / `hooks.json` mechanism used by `git-sync-check.sh` and `backlog-sync-check.sh`.

**Contract:**
- Reads `git show planning:.planning/memory/shared/MEMORY.md` (offline-safe: `exit 0` if fails)
- Uses `git archive planning .planning/memory/shared/` to extract facts into a temp dir
- Copies new or updated facts into `~/.claude/projects/<slug>/memory/` (slug derived from cwd, same derivation as `observe-session-end.sh`)
- Regenerates `~/.claude/projects/<slug>/memory/MEMORY.md` index from the imported facts (preserving any local-only facts not in shared/)
- Freshness guard: skips if planning branch FETCH_HEAD is < 90 s old AND no new commits since last import (mirrors git-sync-check.sh's 90 s guard)
- Idempotent: comparing file hashes means re-running on the same commit is a no-op

**Coexistence with `git-sync-check.sh`:**
- `git-sync-check.sh` already fetches the remote and warns about planning branch drift (see lines 92-100 of git-sync-check.sh). The import hook runs AFTER git-sync-check (hooks.json ordering: git-sync-check is first, memory-import is second in the SessionStart array). By the time memory-import runs, the planning refs are already fresh.
- `memory-import.sh` only uses `git show`/`git archive` against the already-fetched refs — no second fetch needed.

**Coexistence with autosync:**
- Autosync runs `git add -A -- . ':(exclude)versions.lock'` on the working tree of the CURRENT branch. It cannot touch the planning branch because the planning branch is not checked out. Memory files on planning are safe by design: autosync has no mechanism to commit to a branch that is not HEAD.

### Component 2: `memory-export.sh` (Stop hook)

Reads the current IDE's native memory, diffs against the planning branch's shared store, and commits net-new or changed facts to the planning branch without switching branches.

**Contract:**
- Triggered by the `Stop` event (same event as `session-summary.sh` and `observe-session-end.sh`)
- Reads `~/.claude/projects/<slug>/memory/*.md` (native memory of current session)
- Diffs each file against `git show planning:.planning/memory/shared/facts/<file>` (or detects absence)
- For each new/changed fact: writes to `.planning/memory/local/staging/` first (working copy), then:
  ```bash
  git worktree add /tmp/ideiaos-mem-wt planning --no-checkout 2>/dev/null || true
  # copy staging files into worktree
  git -C /tmp/ideiaos-mem-wt add .planning/memory/shared/
  git -C /tmp/ideiaos-mem-wt commit -m "mem: sync from <slug> <date>"
  git worktree remove /tmp/ideiaos-mem-wt --force
  ```
  OR (simpler, same result):
  ```bash
  git read-tree planning
  # stage changes
  NEW_TREE=$(git write-tree)
  NEW_COMMIT=$(git commit-tree "$NEW_TREE" -p planning -m "mem: sync from <slug> <date>")
  git branch -f planning "$NEW_COMMIT"
  ```
  The `git worktree` approach is recommended: it is the standard git mechanism for committing to a non-checked-out branch without polluting HEAD. The `read-tree` approach is lower-level and harder to get right in edge cases.
- After committing to the local `planning` branch, autosync will pick it up and push on its next cycle (the autosync LaunchAgent already pushes `work` and `planning` if they have upstream tracking). This is the designed propagation path — the export hook DOES NOT push directly.
- If no facts changed, exit 0 silently (no empty commits).
- Exit 0 always — never blocks session close.

**Why `git worktree` not a branch checkout:**

A checkout would replace the working tree (destroying any uncommitted work in the current branch). `git worktree add` creates a second, separate checkout in a temp directory while leaving the main working tree untouched. This is the same technique used by many CI tools to operate on multiple branches simultaneously.

**Autosync exclusion requirement:**

The autosync script's current patch excludes `versions.lock` from `git add -A`. For memory safety, the autosync MUST also NOT auto-commit to the `planning` branch during a session — and it currently cannot, because it only runs `git add -A` on the currently-checked-out branch. The memory-export hook commits directly to `planning` via worktree; autosync then pushes `planning` to origin when it runs (it already tracks the planning branch if set up). If autosync does NOT currently push `planning`, a one-line fix in `setup-dev-machine.sh` adds `git push origin planning` to the sync loop.

---

## Source / Adapter Model

Following the existing `source/ → adapters` principle (PROJECT.md decision):

| Layer | Path | Nature | Who writes it |
|-------|------|---------|---------------|
| **Source** | `source/hooks/memory-import.sh` | Versioned, compiled to global install | Human / IdeiaOS dev |
| **Source** | `source/hooks/memory-export.sh` | Versioned, compiled to global install | Human / IdeiaOS dev |
| **Source** | `source/skills/memory-sync/SKILL.md` | The `/memory-sync` skill (manual trigger) | Human / IdeiaOS dev |
| **Compiled global** | `~/.claude/hooks/memory-import.sh` | Installed by `setup.sh --global-only` | build-adapters / setup |
| **Compiled global** | `~/.claude/hooks/memory-export.sh` | Installed by `setup.sh --global-only` | build-adapters / setup |
| **Runtime canonical** | `planning:.planning/memory/shared/` | The actual synced facts | memory-export.sh (auto) |
| **Runtime local** | `planning:.planning/memory/local/` | Machine-local staging (gitignored on planning) | memory-export.sh (auto) |
| **Runtime native** | `~/.claude/projects/<slug>/memory/` | IDE-native working copy | Claude Code (IDE) |
| **Curated library** | Obsidian vault `Learnings/` | Cross-project curated synthesis | `/extract-learnings` (human gate) |

**What goes into `source/` vs stays per-machine:**
- Hook scripts (`memory-import.sh`, `memory-export.sh`) → `source/hooks/` (compiled to global `~/.claude/hooks/`)
- The skill doc (`/memory-sync`) → `source/skills/memory-sync/SKILL.md`
- The `hooks.json` registration entry → updated in `plugins/ideiaos-core/hooks/hooks.json` (adds `memory-import` to SessionStart array, `memory-export` to Stop array)
- The `.planning/memory/` directory itself → created on the `planning` branch at first export (runtime, not source)
- The `.planning/.gitignore` entry for `memory/local/` → added by install script, committed to `planning` branch

---

## Data Flow

### Fact created in IDE → planning store → Obsidian vault

```
User session in Claude Code (cwd = some project)
    │
    │  AI creates/updates a fact in native memory
    ▼
~/.claude/projects/<slug>/memory/
    ├── MEMORY.md          ← index updated by Claude Code
    └── facts/learning_x.md
    │
    │  Stop event fires
    ▼
memory-export.sh (Stop hook, runs alongside session-summary.sh)
    │  git diff: native fact vs planning:.planning/memory/shared/facts/learning_x.md
    │  net-new or changed → write to .planning/memory/local/staging/
    │  git worktree add /tmp/... planning
    │  git -C /tmp/... add + commit "mem: sync from <slug> <date>"
    │  git worktree remove /tmp/...
    ▼
planning branch (local)
    └── .planning/memory/shared/facts/learning_x.md   ← committed
    │
    │  autosync LaunchAgent (next cycle, ~60s)
    ▼
origin/planning (remote)
    └── .planning/memory/shared/facts/learning_x.md   ← pushed
    │
    │  Next SessionStart on any machine:
    │  git-sync-check.sh fetches → memory-import.sh reads git archive planning
    ▼
~/.claude/projects/<slug>/memory/facts/learning_x.md  ← imported into native memory
    │
    │  Manual curation gate: /extract-learnings Passo 4b (human decision)
    │  (only cross-project, stack-agnostic, stable learnings promoted)
    ▼
Obsidian Vault: Learnings/<Human Title>.md
    └── iCloud Sync propagates to all machines with Obsidian installed
```

### Key: what triggers each hop

| Hop | Trigger | Mechanism | Fallback |
|-----|---------|-----------|----------|
| Native memory → planning | `Stop` event | `memory-export.sh` hook | exit 0, skip if no change |
| Planning (local) → origin | autosync LaunchAgent | `git push origin planning` | next cycle retries |
| Origin → all machines | `SessionStart` | `memory-import.sh` (after git-sync-check fetch) | exit 0 if offline |
| Planning → native memory | `SessionStart` | `memory-import.sh` | exit 0 if no planning branch |
| Native memory → Obsidian | manual `/extract-learnings` | human curation, Passo 4b | explicit skip in skill |

---

## Architectural Patterns

### Pattern 1: Read-Only Branch Access via `git show` / `git archive`

**What:** Access files on another branch (planning) without checking it out, by using `git show <branch>:<path>` for single files and `git archive <branch> <prefix>` piped to tar for directory extraction.

**When to use:** Whenever the SessionStart or Stop hook needs to read canonical memory without disrupting the working tree. This is non-negotiable because the working tree may have uncommitted changes.

**Evidence in existing code:** `git-sync-check.sh` already uses `git show planning:.planning/STATE.md` (lines 75-78) and checks `origin/planning` refs without checkout. `CLAUDE.md` documents `git show planning:.planning/STATE.md` as the standard read pattern.

**Trade-offs:** Read is cheap and safe. Write requires `git worktree` (see Pattern 2). Cannot be used for writes.

### Pattern 2: Write to Non-Checked-Out Branch via `git worktree`

**What:** Use `git worktree add <tmpdir> <branch>` to get a second working tree pointing at the planning branch, make changes, commit, then `git worktree remove`. The main working tree is untouched throughout.

**When to use:** `memory-export.sh` Stop hook — the only write path from IDE native memory to the planning branch.

**Trade-offs:** Requires a temp directory (`/tmp/ideiaos-mem-wt-<pid>`). Worktrees must be removed after use or git refuses to add another worktree to the same branch. The hook must use `trap` to clean up the worktree on error. Performance: acceptable for a Stop hook (non-blocking, async if needed).

**Conflict safety:** If two machines export simultaneously (unlikely but possible: autosync pushed after this machine fetched), the commit will fail because `planning` moved forward. The hook should retry once with a fresh fetch before giving up silently. This is identical to the concurrency model already used by the instinct-analyze auto-trigger in `observe-session-end.sh`.

### Pattern 3: Freshness Guard (copy from `git-sync-check.sh`)

**What:** Record last-import timestamp in `~/.local/state/ideiaos-mem-import/<slug>.ts`. On SessionStart, skip the import if the planning branch has not moved since the last import (compare SHA). This prevents redundant `git archive` extractions when opening multiple tabs.

**When to use:** `memory-import.sh`. Mirrors the 90 s FETCH_HEAD guard in `git-sync-check.sh` and the 600 s cache in `backlog-sync-check.sh`.

### Pattern 4: Hook Registration via `hooks.json` + `ideiaos-update.sh`

**What:** New hooks are declared in `plugins/ideiaos-core/hooks/hooks.json`. `ideiaos-update.sh` step 3 reads this file and registers any missing hooks into `~/.claude/settings.json` idempotently. `idea-doctor.sh` checks for their presence.

**When to use:** Both `memory-import.sh` (SessionStart) and `memory-export.sh` (Stop) follow this exact registration path — no manual settings.json editing required.

**Ordering:** In the `SessionStart` array, `memory-import.sh` must come AFTER `git-sync-check.sh` (which fetches) and AFTER `backlog-sync-check.sh`. The import hook depends on fresh remote refs. The `hooks.json` array order is respected by Claude Code.

---

## Component Table: New vs Modified

| Component | Status | Path | Change Description |
|-----------|--------|------|--------------------|
| `memory-import.sh` | **NEW** | `source/hooks/memory-import.sh` | SessionStart bridge: planning→native IDE memory |
| `memory-export.sh` | **NEW** | `source/hooks/memory-export.sh` | Stop bridge: native IDE memory→planning |
| `memory-sync` skill | **NEW** | `source/skills/memory-sync/SKILL.md` | Manual `/memory-sync` trigger (force import/export outside hooks) |
| `.planning/memory/shared/` | **NEW** | `planning` branch only | Canonical memory store (created at first export) |
| `.planning/.gitignore` | **NEW** | `planning` branch only | Ignores `memory/local/` on planning branch |
| `hooks.json` | **MODIFIED** | `plugins/ideiaos-core/hooks/hooks.json` | Add `memory-import` to SessionStart array (after git-sync-check), `memory-export` to Stop array |
| `idea-doctor.sh` | **MODIFIED** | `scripts/idea-doctor.sh` | New section 12: check Patch 12 (memory-import present + registered), check Patch 13 (memory-export present + registered), check .planning/memory/shared/ exists on planning branch |
| `install-global-patches.sh` | **MODIFIED** | `scripts/install-global-patches.sh` | Patch 12: copy memory-import.sh to `~/.claude/hooks/`, register in settings.json; Patch 13: same for memory-export.sh |
| `ideiaos-update.sh` | **NOT MODIFIED** | `scripts/ideiaos-update.sh` | Picks up new hooks automatically via hooks.json step (step 3) — no change needed |
| `setup-dev-machine.sh` | **MAYBE MODIFIED** | `scripts/setup-dev-machine.sh` | Add `git push origin planning` to autosync loop if not already present |
| autosync LaunchAgent | **NOT MODIFIED** | `~/.local/bin/git-autosync` | Already excludes versions.lock; planning branch push is natural if tracked |
| `extract-learnings` skill | **NOT MODIFIED** | `source/skills/extract-learnings/SKILL.md` | Already handles Obsidian promotion (Passo 4b); memory-sync feeds it, does not replace it |
| `recall-learnings` skill | **NOT MODIFIED** | `source/skills/recall-learnings/SKILL.md` | Already reads `~/.claude/projects/<slug>/memory/`; import hook populates this — no change |

---

## Dependency-Ordered Build Sequence

The roadmapper can use this as phase input. Each item depends on all items above it.

```
1. Planning branch memory layout
   ├── Create .planning/memory/shared/ skeleton (MEMORY.md + facts/ dir)
   ├── Create .planning/.gitignore (ignores memory/local/)
   └── Commit to planning branch
   → No code dependency; prerequisite for all bridge work

2. memory-import.sh (source/hooks/)
   ├── git show / git archive read pattern
   ├── Freshness guard (~/.local/state/ideiaos-mem-import/)
   ├── Native memory merge logic (new facts only; preserve local-only facts)
   └── exit 0 on any failure (offline, no planning branch, no memory)
   → Depends on: (1) planning layout exists to read

3. memory-export.sh (source/hooks/)
   ├── git worktree add/remove pattern
   ├── Diff logic: native vs planning (skip empty exports)
   ├── Commit to planning branch (retry once on conflict)
   ├── Staging via .planning/memory/local/staging/
   └── exit 0 always (Stop hook must not block)
   → Depends on: (1) planning layout exists to write into

4. hooks.json update
   ├── Add memory-import to SessionStart array (after git-sync-check entry)
   └── Add memory-export to Stop array
   → Depends on: (2)(3) hook scripts exist as source

5. install-global-patches.sh patches 12 & 13
   ├── Patch 12: copy memory-import.sh → ~/.claude/hooks/, register in settings.json
   └── Patch 13: copy memory-export.sh → ~/.claude/hooks/, register in settings.json
   → Depends on: (4) hooks.json declares them

6. idea-doctor.sh section update
   ├── Section 12 check: Patch 12 marker, file presence, settings.json registration
   ├── Section 13 check: Patch 13 marker, file presence, settings.json registration
   └── Check: planning:.planning/memory/shared/ exists (warns if not — first export hasn't run yet)
   → Depends on: (5) patches exist to check

7. /memory-sync skill (source/skills/memory-sync/SKILL.md)
   ├── Manual force-import: re-runs memory-import.sh out-of-band
   ├── Manual force-export: re-runs memory-export.sh out-of-band
   └── Describes the data flow for human understanding
   → Depends on: (2)(3) hooks exist to call

8. setup-dev-machine.sh autosync push audit
   └── Verify autosync pushes planning branch; add if missing
   → Depends on: (3) export commits to planning; needs autosync to push it

9. Obsidian vault promotion (no new code)
   └── Document that /extract-learnings Passo 4b is the promotion gate;
       memory-sync feeds it; no additional code needed
   → Depends on: (7) data flowing through pipeline
```

---

## Integration Points

### Integration with `git-sync-check.sh`

`git-sync-check.sh` already:
1. Fetches remote refs on SessionStart (line 46-52)
2. Warns when the local `planning` branch is behind `origin/planning` (lines 92-100)

`memory-import.sh` slots in AFTER this hook in the SessionStart array. It reads the freshly-fetched planning refs. No duplication; the fetch is shared.

### Integration with autosync LaunchAgent

Autosync runs `git add -A -- . ':(exclude)versions.lock'` and pushes the current branch. For the planning branch:
- During normal work sessions, the working branch is `work` or a feature branch — autosync pushes THAT branch
- `memory-export.sh` commits directly to the local `planning` branch via worktree
- On its next run cycle, autosync will see that `planning` has unpushed commits and push them (if `planning` has an upstream tracking ref)
- If autosync only pushes the current branch, add: `git push origin planning 2>/dev/null || true` to the sync loop

### Integration with `observe-session-end.sh`

Both `memory-export.sh` and `observe-session-end.sh` are Stop hooks. They run concurrently (or serially per hooks.json order). They are fully independent: observe-session-end.sh writes to `~/.ideiaos/observations/`; memory-export.sh writes to the planning branch. No shared state.

### Integration with `extract-learnings` and `recall-learnings`

`recall-learnings` reads `~/.claude/projects/<slug>/memory/MEMORY.md` (Passo 4). After `memory-import.sh` runs on SessionStart, this file contains the latest synced facts from all machines. No change to `recall-learnings` needed.

`extract-learnings` creates new facts in `~/.claude/projects/<slug>/memory/` (Passo 4 global path) and promotes to Obsidian (Passo 4b). The Stop hook `memory-export.sh` then picks up these new facts and syncs them to the planning branch. The pipeline is: extract-learnings creates → Stop hook exports → planning branch stores → next SessionStart imports. No change to `extract-learnings` needed.

### Lovable safety guarantee

The canonical memory store lives exclusively on the `planning` branch (`.planning/memory/`). The `main` branch is untouched. The autosync pattern and the worktree pattern both operate against `planning`, never `main`. The leaked `.lovable_mem_tmp.md` on `nfideia/main` is exactly what this architecture prevents: there is no temporary file written to the working tree of the current branch. All staging is in `.planning/memory/local/staging/` on the planning branch, which is gitignored there.

---

## Anti-Patterns

### Anti-Pattern 1: Writing memory to the working tree before committing

**What people do:** Write a temp file like `.lovable_mem_tmp.md` to the current branch's working tree as a staging step.
**Why it's wrong:** Autosync picks it up and commits it to whatever branch is checked out — including `main`. This is what happened on `nfideia`.
**Do this instead:** Write staging files only to `.planning/memory/local/staging/` via the planning branch worktree (never to the main working tree).

### Anti-Pattern 2: Checking out `planning` to read memory

**What people do:** `git checkout planning && cat .planning/memory/shared/MEMORY.md && git checkout -`.
**Why it's wrong:** Destroys uncommitted work in the current branch; breaks if there are conflicts; not safe in a hook.
**Do this instead:** `git show planning:.planning/memory/shared/MEMORY.md` (read) or `git worktree add` (write).

### Anti-Pattern 3: Registering hooks manually in settings.json

**What people do:** Edit `~/.claude/settings.json` by hand to add hook entries.
**Why it's wrong:** Not propagated to other machines; not idempotent; not verified by `idea-doctor.sh`.
**Do this instead:** Add the hook to `plugins/ideiaos-core/hooks/hooks.json` and let `ideiaos-update.sh` step 3 register it everywhere.

### Anti-Pattern 4: Storing per-project memory on `main`

**What people do:** Commit memory index or fact files to `main` for easy access.
**Why it's wrong:** Lovable Update reads `main` automatically. Memory files get synced to Lovable's build pipeline, appear in Lovable diffs, and create merge conflicts.
**Do this instead:** All memory lives on `planning`. IDEs access it via `git show planning:...` or after SessionStart import into native memory paths (which are machine-local and gitignored).

---

## Sources

All findings derived from direct file inspection of the following real sources (HIGH confidence — no inference from training data):

- `/Users/gustavolopespaiva/dev/IdeiaOS/.planning/PROJECT.md` — decisions, source/adapter model, Lovable constraint
- `/Users/gustavolopespaiva/dev/IdeiaOS/CLAUDE.md` — planning branch read pattern (`git show planning:...`)
- `/Users/gustavolopespaiva/.claude/hooks/git-sync-check.sh` — fetch + fast-forward + planning drift warning pattern; lines 92-100 for `planning` branch check
- `/Users/gustavolopespaiva/.claude/hooks/backlog-sync-check.sh` — freshness guard (600 s cache), cwd-gated scope, exit 0 safety contract
- `/Users/gustavolopespaiva/dev/IdeiaOS/plugins/ideiaos-core/hooks/hooks.json` — canonical hook registry; SessionStart, Stop, PostToolUse event arrays
- `/Users/gustavolopespaiva/dev/IdeiaOS/scripts/ideiaos-update.sh` — step 3 hook registration; step 2 autosync patch (versions.lock exclusion precedent)
- `/Users/gustavolopespaiva/dev/IdeiaOS/scripts/idea-doctor.sh` — patch verification pattern; section structure for Patch 8/11
- `/Users/gustavolopespaiva/dev/IdeiaOS/scripts/install-global-patches.sh` — Patch 8/11 registration pattern (hook copy + settings.json entry)
- `/Users/gustavolopespaiva/dev/IdeiaOS/source/hooks/observe-session-end.sh` — Stop hook contract; anti-runaway guard; IDEIAOS_INSTINCT_SPAWN precedent
- `/Users/gustavolopespaiva/dev/IdeiaOS/source/hooks/precompact-state-save.sh` — git worktree-free branch write (read-then-write on planning via python3); STATE.md write pattern
- `/Users/gustavolopespaiva/dev/IdeiaOS/source/hooks/session-summary.sh` — Stop hook idempotent file write; slug derivation from cwd pattern
- `/Users/gustavolopespaiva/dev/IdeiaOS/source/skills/extract-learnings/SKILL.md` — Passo 4b (Obsidian promotion), global memory path `~/.claude/projects/.../memory/`
- `/Users/gustavolopespaiva/dev/IdeiaOS/source/skills/recall-learnings/SKILL.md` — Passo 4 (reads MEMORY.md index), Passo 5 (Obsidian vault), instincts path

---
*Architecture research for: IdeiaOS v5 — cross-IDE shared memory on planning branch*
*Researched: 2026-06-14*
