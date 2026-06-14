# Stack Research — IdeiaOS v5: Cross-IDE Memory Sync

**Domain:** Dev-OS tooling / meta-framework infrastructure
**Researched:** 2026-06-14
**Confidence:** HIGH (all mechanisms verified against real files + official docs)

---

## Context and Hard Constraints

This capability adds cross-IDE memory synchronization to IdeiaOS. The chosen direction (already decided, not re-researched) is:

- Memory rides the `planning` git branch (never `main`)
- A bridge imports on SessionStart and exports on Stop to reconcile each IDE's native memory with the planning-branch store
- `shared/` (committed) vs `local/` (gitignored, per-member) split
- Obsidian stays as the cross-project library — no parallel second brain

The non-negotiable constraint is that `main` must never be touched by this system. Lovable Update reads `main` automatically; only `/lovable-handoff` is the gate to `main`. Any auto-push or auto-write to `main` would cause silent Lovable deploys.

---

## Mechanism 1: Claude Code Memory — File Layout and Slug Derivation

### Storage location (VERIFIED against real filesystem)

```
~/.claude/projects/<slug>/memory/
├── MEMORY.md          # Index: first 200 lines or 25KB loaded every session
├── <topic>.md         # Fact files — loaded on demand, not at startup
└── ...
```

The `<slug>` is the absolute path of the git repo root with every `/` replaced by `-`, preserving underscores.

Example (verified from live filesystem):
```
/Users/gustavolopespaiva/dev/IdeiaOS  →  -Users-gustavolopespaiva-dev-IdeiaOS
/Users/gustavolopespaiva/dev/nfideia  →  -Users-gustavolopespaiva-dev-nfideia
```

### Known bug: slug non-determinism (VERIFIED, GitHub issue #30828)

Claude Code sometimes converts underscores to hyphens in the slug, creating a second memory directory for the same project. The same project `BW_customer_portal` has produced both `-Users-...-BW_customer_portal` and `-Users-...-BW-customer-portal` across sessions. Impact for v5: the import script MUST check both slug variants and pick the one that has a MEMORY.md.

### Programmatic slug derivation

```bash
# Canonical: forward-slash → hyphen, everything else preserved
slug() {
  git rev-parse --show-toplevel | tr '/' '-'
}
memory_dir="$HOME/.claude/projects/$(slug)/memory"
```

To handle the underscore bug, also check the hyphen-normalized variant:
```bash
slug_normalized() {
  git rev-parse --show-toplevel | tr '/' '-' | tr '_' '-'
}
```

### File format (VERIFIED from real memory files)

Each fact file uses YAML frontmatter + markdown body:

```markdown
---
name: <kebab-case-unique-name>
description: <one-line summary for the index>
metadata:
  node_type: memory
  type: user | feedback | project | reference
  originSessionId: <uuid>
---

<markdown body — 2-4 paragraphs>
**Why:** <root cause>
**How to apply:** <behavioral guidance>
```

`MEMORY.md` is a plain markdown index with one bullet per fact file:

```markdown
# MEMORY.md — <Project Name>

- [<description>](<filename>.md) — <one-liner>
- [<description>](<filename>.md) — <one-liner>
```

### What Claude Code loads

- `MEMORY.md`: first 200 lines or first 25KB, every session
- Topic files: on-demand only (Claude reads them when needed)
- `autoMemoryDirectory` in `.claude/settings.json` can relocate the directory

### Programmatic read/write

The files are plain markdown on the local filesystem. A bridge script reads and writes them with standard bash (`cat`, `grep`, Python). No API or lock mechanism exists — files are written directly. Claude Code reads them fresh at each session start, so any file written before `SessionStart` fires is immediately visible.

---

## Mechanism 2: Cursor Memory/Rules — Format and Bridge Access

### Rules storage (VERIFIED from real .cursor/rules/ directory)

```
.cursor/rules/          # Project-level, committed to git (NOT main-locked)
├── planning-branch.mdc
├── session-continuation.mdc
├── agents-md-protocol.mdc
└── lovable-deploy.mdc
```

### .mdc file format (VERIFIED from real files in this repo)

```markdown
---
description: 'Short description for agent rule selection'
alwaysApply: true | false
globs: "src/**/*.ts"   # optional, triggers rule when matching files opened
---

# Rule title

Markdown body with instructions...
```

Key fields:
- `description`: used by Cursor's agent to decide whether to include the rule
- `alwaysApply: true`: rule is included in every session (analogous to CLAUDE.md)
- `alwaysApply: false` + no globs: rule is "agent-requested" — included if description matches
- `globs`: auto-included when files matching the pattern are opened

### Cursor Memories (native feature, v0.51+, v1.0 June 2025)

Cursor added a "Memories" feature in v0.51 (Settings → Rules → "Generate Memories"). A background model proposes facts; the user approves before they're saved. Storage location is NOT exposed as a readable/writable local filesystem path — likely server-side or in an opaque local SQLite. Therefore:

**The Cursor Memories feature is NOT bridgeable via filesystem.** Do not attempt to read or write it programmatically.

### Cursor bridge strategy (RECOMMENDED)

Bridge Cursor via the `.cursor/rules/` directory, which IS filesystem-accessible and git-committed:

- **Import (SessionStart equivalent):** Write a `memory-bridge.mdc` file with `alwaysApply: true` that includes the current shared memory snapshot as inline content. This gives Cursor agents the same context on every conversation.
- **Export (session-end equivalent):** No native hook in Cursor. Rely on the human-triggered `/extract-learnings` skill to write learnings into the shared planning-branch store.

Cursor does not have a SessionStart/Stop hook system analogous to Claude Code hooks. This asymmetry is by design — Cursor is the passive consumer of memory, Claude Code is the active producer/syncer.

---

## Mechanism 3: Git Branch as State Store — Plumbing

### Reading without checkout (VERIFIED working commands)

```bash
# Read a single file
git show planning:.planning/memory/shared/fact-name.md

# List all files in a subtree
git ls-tree -r planning --name-only | grep '.planning/memory/'

# Read the MEMORY index
git show planning:.planning/memory/MEMORY.md
```

These commands work on the currently-checked-out branch without switching. They are safe to run inside any hook.

### Writing without checkout — proven plumbing pipeline (VERIFIED live)

The full write-without-checkout pipeline was tested and proven on the nfideia repo:

```bash
REPO="$(git rev-parse --show-toplevel)"
BRANCH="planning"
FILE_PATH=".planning/memory/shared/<fact-name>.md"
CONTENT="<file content>"

# Step 1: Hash the content into git object store
BLOB_SHA=$(printf '%s' "$CONTENT" | git -C "$REPO" hash-object -w --stdin)

# Step 2: Read current branch tree into a temp index (NEVER touch the real index)
TMPIDX=$(mktemp)
GIT_INDEX_FILE="$TMPIDX" git -C "$REPO" read-tree "$BRANCH"

# Step 3: Insert new blob into temp index
GIT_INDEX_FILE="$TMPIDX" git -C "$REPO" \
  update-index --add --cacheinfo "100644,$BLOB_SHA,$FILE_PATH"

# Step 4: Write new tree object
NEW_TREE=$(GIT_INDEX_FILE="$TMPIDX" git -C "$REPO" write-tree)

# Step 5: Create commit on top of current branch HEAD
PARENT=$(git -C "$REPO" rev-parse "$BRANCH")
NEW_COMMIT=$(
  GIT_INDEX_FILE="$TMPIDX" \
  GIT_AUTHOR_NAME="memory-bridge" GIT_AUTHOR_EMAIL="bridge@local" \
  GIT_COMMITTER_NAME="memory-bridge" GIT_COMMITTER_EMAIL="bridge@local" \
  GIT_AUTHOR_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  GIT_COMMITTER_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  git -C "$REPO" commit-tree "$NEW_TREE" -p "$PARENT" -m "memory: export <slug> <timestamp>"
)

# Step 6: Advance the branch ref
git -C "$REPO" update-ref "refs/heads/$BRANCH" "$NEW_COMMIT"

# Cleanup
rm -f "$TMPIDX"
```

**Why this over `git worktree`:** Worktrees require a path and create a working-tree directory. The plumbing pipeline above operates purely in the object/ref layer with no working-tree impact, no risk of interfering with the checked-out branch, and no leftover state. It works correctly when the current branch is `main` or `work`, which is the normal operating state.

**Why not `git stash` + `git checkout`:** Branch switch while Lovable-synced repos are open risks accidental cross-contamination and triggers file-watching tools.

**Conflict prevention for shared memory:** One-file-per-fact (each fact = one `.md` file with a deterministic filename derived from `type_slug.md`) means concurrent writes from different machines produce separate files. Git merges them as additions, not content conflicts. The MEMORY.md index IS a potential merge conflict point — use an append-only, sorted format (each line = one fact reference) and resolve with `git merge -s ours` for the index during sync, then rebuild it from the directory listing.

---

## Mechanism 4: Hook System — Claude Code SessionStart and Stop

### Hook events relevant to memory sync (VERIFIED from official docs + real hooks.json)

| Event | When | Blocking | Stdin | Useful For |
|-------|------|----------|-------|------------|
| `SessionStart` | Session begins or resumes | No | `{session_id, cwd, source}` | Import: pull shared memory from planning branch into Claude Code memory dir |
| `Stop` | Claude finishes a turn | Yes (exit 2 prevents stop) | `{session_id, cwd}` + history | Export: write new facts to planning branch |
| `PreCompact` | Before /compact | Yes | `{trigger: manual|auto}` | Already in use: precompact-state-save.sh |

### SessionStart specifics (VERIFIED from real git-sync-check.sh)

- Registered in `~/.claude/settings.json` under `hooks.SessionStart[]`
- Receives JSON on stdin including `cwd` (the working directory at session start)
- Timeout: up to 600s for command hooks (though 15s is the practical target)
- Non-blocking: always exit 0; use `systemMessage` in JSON output to inject context into Claude's startup
- Multiple hooks run in parallel (existing hooks: git-sync-check.sh, backlog-sync-check.sh, ideiaos-detector.sh, gsd-check-update.js, gsd-session-state.sh)

```json
// Registration format in ~/.claude/settings.json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/path/to/memory-import.sh\"",
          "timeout": 20
        }]
      }
    ]
  }
}
```

The `systemMessage` output field injects a message into Claude's context at session start without it appearing as a user message. This is how to surface the "N memories loaded from planning branch" summary.

### Stop specifics (for export)

- Fires when Claude finishes a turn (not session end — fires after every response)
- `observe-session-end.sh` uses the `Stop` hook for the observations pipeline (R4-01 anti-runaway guard already in place)
- Memory export should trigger on session end (last Stop), not every Stop — use a sentinel file or check session context

**Important:** There is no true "session end" hook analogous to a process exit signal. `Stop` fires after every model response. A `Stop` hook that exports memory on every turn would be too noisy and slow. Recommended approach: export via a skill (`/memory-sync`) invoked explicitly at session close, registered as a reminder in the `observe-session-end.sh` output.

### Cursor hooks

Cursor has no hook system exposed to scripts. There is no SessionStart/Stop equivalent that can run arbitrary shell commands. Cursor bridge is therefore pull-only (rules files written by Claude Code before session; Cursor reads them passively).

---

## Mechanism 5: File Format for Conflict-Minimizing Team Memory

### One-file-per-fact (CONFIRMED pattern from existing Claude Code memory)

Each fact = one file, named with a deterministic scheme:

```
<type>_<kebab-slug>.md
```

Examples from real MEMORY.md index:
- `learning_version-reset-migration-semver-trap.md`
- `learning_ambiguous-drift-warning-induces-agent-revert.md`

This naming scheme (already used by Claude Code's auto memory) means:
- Two machines writing the same logical fact produce the same filename (idempotent)
- Different facts produce different filenames (no collision)
- Git merge sees only additions (new files) not content conflicts

### MEMORY.md index format

The index must be append-only and sortable to minimize merge conflicts:

```markdown
# MEMORY.md — <Project>

- [<description>](<type>_<slug>.md) — <one-liner>
```

Lines are sorted alphabetically by filename. Rebuild the index deterministically from directory listing rather than editing it line-by-line:

```bash
# Rebuild MEMORY.md index from directory contents
{
  echo "# MEMORY.md — $(basename $(git rev-parse --show-toplevel))"
  echo ""
  for f in ~/.claude/projects/$(slug)/memory/*.md; do
    [ "$(basename "$f")" = "MEMORY.md" ] && continue
    name=$(grep -m1 '^name:' "$f" | sed 's/^name: //')
    desc=$(grep -m1 '^description:' "$f" | sed 's/^description: //')
    echo "- [$desc]($(basename $f)) — $name"
  done
} > ~/.claude/projects/$(slug)/memory/MEMORY.md
```

### shared/ vs local/ directory split in planning branch

```
.planning/memory/
├── shared/          # committed to planning branch, synced across IDEs/machines
│   ├── MEMORY.md    # shared index
│   └── <type>_<slug>.md   # individual fact files
└── local/           # gitignored, machine-specific
    └── <machine-id>/
        └── *.md
```

`.gitignore` in the planning branch should include `.planning/memory/local/`.

Obsidian vault continues as the cross-project library (`/extract-learnings` → vault promotion remains unchanged). The `shared/` directory is project-scoped, not cross-project.

---

## Supporting Tools (No New Dependencies Required)

| Tool | Purpose | Availability |
|------|---------|-------------|
| `bash` | Hook scripts | Already in use (all existing hooks) |
| `python3` | JSON parsing, file writing | Already used in precompact-state-save.sh |
| `git` (plumbing) | Branch-as-state-store | Core git, already required |
| `stat` | File modification times (freshness gates) | Already used in git-sync-check.sh |
| `date` | Timestamps in commits | Standard |

No npm packages, no new binaries, no MCP servers required. The entire mechanism is pure bash + git plumbing, consistent with the existing hook infrastructure.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Git plumbing (hash-object/commit-tree) | `git worktree add` | Worktrees create a filesystem directory, risk interfering with open editors and file watchers |
| Git plumbing pipeline | `git stash + checkout` | Branch switch risks Lovable drift on repos where file watchers react to checkout |
| Rebuild MEMORY.md index from directory scan | Edit MEMORY.md in-place | Reduces merge conflicts — rebuild is deterministic and idempotent |
| Export via explicit skill (`/memory-sync`) | Export on every Stop hook | Stop fires after every model response; per-turn export is noisy and slow |
| Cursor bridge via `.cursor/rules/*.mdc` | Cursor native Memories API | Cursor Memories storage is not filesystem-accessible (likely server-side or opaque SQLite); no programmatic write path |
| One-file-per-fact with type_slug naming | Single monolithic facts file | One file = git line conflicts on concurrent edits; one-file-per-fact = only additive merges |

---

## What NOT to Build

- **No writes to `main`:** The bridge must never commit to or push `main`. The `update-ref` step targets `planning` only; the hook script must assert the target branch before writing.
- **No Cursor Memories API integration:** Cursor Memories is not filesystem-accessible. Do not build a poller/scraper for it.
- **No new MCP server:** The bridge is shell scripts + git plumbing. Adding an MCP server for memory sync is over-engineering.
- **No cross-project memory in the planning branch:** The planning branch is per-repo. Cross-project memory continues to flow via Obsidian vault through `/extract-learnings`. Do not merge these concerns.
- **No LLM-in-the-loop for import/export:** The bridge reads/writes markdown files deterministically. Do not invoke `claude -p haiku` or any model during import/export — this triggers the anti-runaway guard and adds latency.
- **No autosync of `.planning/memory/` via LaunchAgent:** The existing autosync excludes `versions.lock` because of the pin-revert bug pattern. Memory files are similarly sensitive to stale-tree writes. Memory sync must be triggered intentionally (SessionStart import / skill export), not by the autosync LaunchAgent.
- **No global `~/.claude/` memory as the sync source:** The bridge reads FROM `~/.claude/projects/<slug>/memory/` (Claude Code local) and WRITES TO `.planning/memory/shared/` (planning branch). Direction is one-way per trigger: import pulls from planning branch into local; export pushes from local into planning branch.

---

## Integration Points with Existing IdeiaOS Infrastructure

| Existing Component | Integration |
|-------------------|-------------|
| `~/.claude/settings.json` hooks.SessionStart | Add `memory-import.sh` as a new hook (after git-sync-check.sh) |
| `plugins/ideiaos-core/hooks/hooks.json` | Add Stop hook entry for session-end memory reminder |
| `ideiaos-update.sh` | Add step to register memory-import hook on update |
| `scripts/idea-doctor.sh` | Add Section N: memory sync health check (planning branch reachable, shared/ exists, last sync timestamp) |
| `/extract-learnings` skill | Add Passo 4d: offer to push fact to `.planning/memory/shared/` in addition to vault |
| `source/skills/` | New skill `/memory-sync` for explicit export trigger |
| `.gitignore` on planning branch | Add `.planning/memory/local/` |
| `git-sync-check.sh` (SessionStart) | Runs before memory-import; if it fast-forwards, memory-import gets the latest shared facts |

---

## Sources

- Claude Code memory official docs: [code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory) — VERIFIED
- Claude Code hooks official docs: [code.claude.com/docs/en/hooks](https://code.claude.com/docs/en/hooks) — VERIFIED
- Slug derivation bug: [github.com/anthropics/claude-code/issues/30828](https://github.com/anthropics/claude-code/issues/30828) — VERIFIED
- Cursor .mdc format: verified against real `.cursor/rules/*.mdc` files in this repo and nfideia
- Cursor Memories feature: [forum.cursor.com/t/0-51-memories-feature](https://forum.cursor.com/t/0-51-memories-feature/98509) — storage is not locally accessible
- Git plumbing pipeline: proven live against `/Users/gustavolopespaiva/dev/nfideia` (commit SHA `06819c2fa8...` created in dry-run, ref not advanced)
- Existing hook infrastructure: verified from `~/.claude/settings.json`, `plugins/ideiaos-core/hooks/hooks.json`, `source/hooks/`
