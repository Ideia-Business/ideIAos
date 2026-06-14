# Pitfalls Research

**Domain:** Cross-IDE memory sync — IdeiaOS v5
**Researched:** 2026-06-14
**Confidence:** HIGH (grounded in real incidents from this repo + real leaked file confirmed on nfideia main)

---

## Critical Pitfalls

### Pitfall 1: Memory churn reaches `main` and triggers Lovable Update

**What goes wrong:**
A memory file (export artifact, temp sync file, shared memory `.md`) is committed to a branch that eventually merges to `main`. Lovable Cloud watches `main` continuously and will auto-pull/trigger on any commit there. The leaked `.lovable_mem_tmp.md` on `nfideia:main` (commit `604c0a19`, tracked, confirmed live as of 2026-06-14) proves this path is real: a temp file was committed to a feature branch and promoted to main via PR merge. Once on main, Lovable ingests it as project content — at best, harmless noise; at worst, triggers an unintended Update cycle or pollutes Lovable's understanding of the project.

**Why it happens:**
Three distinct paths lead here:
- (a) `git add -A` on a working branch before PR → temp/export files staged alongside intended files → merge to main carries them.
- (b) Autosync (launchd, 15-min timer) runs on a machine where the current branch is `main` or where the sync script doesn't guard the branch — any memory export file in the working tree gets committed to main directly (the same mode of failure as the `versions.lock` revert via commit `c7fc184`).
- (c) A `planning`→`main` merge or `work`→`main` PR accidentally includes a memory file that was committed on the feature branch during development.

**How to avoid:**
- Add `*.lovable_mem_tmp.md`, `.planning/memory/`, and any designated memory export path to `.gitignore` at the repo root for every Lovable project. This is the only reliable barrier — gitignore is checked before `git add -A` and before autosync.
- In IdeiaOS's `setup.sh`, inject these patterns into `.gitignore` for Lovable-flagged projects (same mechanism as the AIOX gitignore step that added `.aiox-core/` to prevent 58M repo bloat).
- In `lovable-handoff/SKILL.md` pre-commit gate: `git diff --cached --name-only | grep -q 'memory\|mem_tmp'` → BLOCK with direction message.
- Never run autosync on `main` branch. The `git-autosync` LaunchAgent must check `git symbolic-ref --short HEAD` and refuse to commit if branch is `main`. This guard does not currently exist.

**Warning signs:**
- `git log --oneline origin/main -- '*.md'` returns memory-shaped files (frontmatter, `name:`, `description:` fields without being a skill/agent definition).
- `git ls-files -- '.lovable_mem_tmp*' '*.mem.md'` returns non-empty in a Lovable project.
- Lovable dashboard shows an unexpected Update available after a memory-only commit.
- `git-autosync` commit messages include memory file paths in the diff summary.

**Phase to address:** Phase 1 (foundation) — gitignore patterns and autosync branch guard must be in place BEFORE any memory file is ever created, not retrofitted after the fact.

---

### Pitfall 2: Autosync commits memory to the wrong branch (the `versions.lock` analogy)

**What goes wrong:**
The autosync LaunchAgent (15-min timer, `git add -A && git commit && git push`) commits all changes in the working tree — including memory export files — to whatever branch is currently checked out. If an agent or developer was on `main` (checking deployment state, reviewing Lovable output) and didn't switch back, the next autosync timer fires and commits memory files directly to `main`. This is exactly how commit `c7fc184` reverted `versions.lock` to the legacy `1.36.0` value: autosync committed a stale working tree.

**Why it happens:**
`git add -A` is branch-blind. Autosync has no awareness of what it is committing. Memory files with `.md` extensions look identical to other tracked `.md` files to `git add -A`. The 15-minute timer means a developer who switches to `main` for 20 minutes (to inspect a Lovable issue) will have autosync fire on `main` before they switch back.

**How to avoid:**
Apply the same 6-barrier pattern that protected `versions.lock`:
1. Exclude memory export paths from `git add -A` in the autosync script (by path pattern, same as `versions.lock` exclusion in `setup-dev-machine.sh`).
2. Add a branch guard to the autosync script: if current branch is `main`, do nothing and log a warning.
3. Add a pre-commit hook that blocks memory files from being committed to `main` (exits 1 with a directional message, not a generic "check this").
4. The directional message must say which side is wrong (same lesson as `ambiguous-drift-warning-induces-agent-revert.md` — generic warnings get "fixed" in the wrong direction by AI agents).

**Warning signs:**
- `git log --oneline main | head -5` shows a commit authored by the autosync user on `main` containing only `.md` changes.
- `git diff main origin/main` diverges immediately after a session where main was checked out.
- `idea-doctor.sh` reports the working branch as `main` during a sync run.

**Phase to address:** Phase 1 — branch guard and autosync exclusion must ship before the memory export mechanism is wired.

---

### Pitfall 3: `planning`→`main` merge carries memory artifacts

**What goes wrong:**
The `planning` branch stores `.planning/` state. If memory sync uses `.planning/memory/` as its store, and a merge of `planning`→`main` is ever executed (to promote state, by accident, or via a PR that catches too much), memory content goes to `main`. Lovable reads `main` and ingests `.planning/memory/` as if it were project content. Even if Lovable ignores `.planning/`, the files are now in `main`'s history — harder to remove, and they may contain team-private context.

**Why it happens:**
Branch merge ambiguity: `planning` is treated as an isolation layer, but if any script or agent runs `git checkout main && git merge planning` (or if a PR is opened from `planning` to `main` for any reason), the full `.planning/` tree follows. The `lovable-handoff` skill has a mandatory merge-to-`main` step (Passo 3b) that works at feature-branch level — it has no awareness of `planning` branch contamination.

**How to avoid:**
- Keep memory sync on a dedicated branch (`memory-sync`) separate from both `planning` and `main`. Never merge `memory-sync` to `main`. The `lovable-handoff` skill's branch awareness must explicitly exclude `memory-sync`.
- Alternatively, use `.planning/memory/` only if `.planning/` is permanently gitignored from `main` (enforce with a pre-receive hook or protected branch rule that rejects any commit to `main` touching `.planning/`).
- Document the branch topology explicitly in `docs/decisions/`: `main` (Lovable) ← `work`/feature branches only; `planning` never merges to `main`; `memory-sync` never merges to `main`.

**Warning signs:**
- `git log origin/main --oneline -- .planning/` returns any commits.
- A PR is opened with `planning` or `memory-sync` as the source branch targeting `main`.
- `git diff main HEAD -- .planning/` is non-empty when the current branch is `main`.

**Phase to address:** Phase 1 — topology documented and enforced before any branch is used as a memory store.

---

### Pitfall 4: SessionStart imports stale memory before autosync pull completes

**What goes wrong:**
The `git-sync-check.sh` SessionStart hook performs a `git fetch` (with a 10-second timeout) and a `git pull --ff-only` to bring the working tree current before the AI reads `STATE.md`. However, if the memory sync store is on a separate branch (e.g., `memory-sync`) or the memory files are managed outside the current working tree's tracked files, the hook does not pull them. The AI session starts, reads the stale local memory, and acts on outdated facts — then exports a new memory snapshot that overwrites the fresher remote state.

A real instance of this: the nfideia session where "the Claude Code memory was at session 35 while the repo was at session 39 in Cursor/MacBook" (STATE.md `Ideias futuras` section). The AI's memory diverged from reality by 4 sessions. For cross-IDE memory sync this is the core timing hazard.

**Why it happens:**
- The freshness guard in `git-sync-check.sh` (90-second dedup) means if autosync ran 60 seconds ago, the fetch is skipped. But autosync might have been the one that pushed stale state.
- If memory is on a separate branch, `git-sync-check.sh` only warns about `planning` branch lag — it does not pull any other secondary branch.
- Export-on-close (session close hook) fires last, so fresh memory written during a session is not available to a second IDE that starts in the same time window.

**How to avoid:**
- Extend `git-sync-check.sh` to explicitly pull the memory store branch before the session begins, not just warn about it (same logic as the `planning` branch warning in lines 92-100 of the hook, but with `--ff-only` auto-merge).
- Set the freshness guard lower for memory branches (30 seconds) compared to 90 seconds for the main working tree.
- Design the memory format so stale-import is detectable: every memory file has a `last_sync` timestamp in frontmatter; SessionStart emits a directional warning if any file is older than N hours (configurable).
- Export-on-close must be fire-and-forget non-blocking and must push immediately, not rely on the next autosync cycle.

**Warning signs:**
- `git log --oneline memory-sync | head -3` shows a timestamp more than 30 minutes old during an active multi-machine session.
- SessionStart prints memory files with `last_sync` timestamps from a different machine's session.
- AI asserts a fact that contradicts the current `STATE.md` — the memory file is winning over the live state.

**Phase to address:** Phase 2 (import/export mechanism) — the freshness guarantee must be part of the SessionStart hook before memory files are trusted as inputs.

---

### Pitfall 5: Personal or secret content committed to team-shared memory store

**What goes wrong:**
Memory files may contain: (a) user-specific feedback patterns ("Gustavo prefers X"), (b) session-internal deliberation ("I made this mistake earlier this session"), (c) Supabase service role keys or API tokens that appeared in a tool output and were captured by a broad memory export, (d) client-specific business context (NFS-e workflow details) that should not cross-pollinate to another project's memory. If the team-shared store is a git branch, all of this becomes readable by every team member and every machine permanently (git history is forever).

**Why it happens:**
Memory extraction is heuristic-driven: the AI identifies "important context" and writes it. Without an explicit boundary for what is personal vs. shared, the exporter captures whatever it deems noteworthy. A tool output that includes a bearer token, a connection string, or client tax data is contextually important — and will be extracted.

**How to avoid:**
- Enforce a two-tier memory taxonomy at write time: `scope: personal` files go to `~/.claude/projects/<hash>/memory/` only (never committed anywhere); `scope: team` files go to the shared store. The export hook must require an explicit `scope:` declaration and default to `personal` if absent (fail-safe).
- Run `security/scan-absorbed.sh`-style grep patterns over any file before it enters the shared store: block anything matching patterns for API keys, connection strings, JWT tokens, CPF/CNPJ patterns (PII relevant to this client base).
- Tag-based project isolation: every shared memory file must carry `project: <slug>` frontmatter; the shared store is namespaced by project slug at the directory level so cross-project reads require an explicit opt-in.

**Warning signs:**
- A memory file contains a string matching `[A-Z0-9]{20,}` (likely a key/token) in any value field.
- A memory file's content references a client name, tax ID, or billing amount from a specific project.
- The `scope:` field is absent from a file in the shared store.
- `git log --all --oneline -- .planning/memory/` shows commits from a session that was working on `nfideia` tasks while in the `ideiapartner` directory.

**Phase to address:** Phase 2 (export mechanism) — scope declaration and secret scanning must be in the writer, not a post-hoc review step.

---

### Pitfall 6: Cross-project memory leakage via wrong project-slug mapping

**What goes wrong:**
The system serves 4 active Lovable projects (ideiapartner, nfideia, cfoai-grupori, lapidai). Claude's project memory is keyed by the file path hash of the working directory (`~/.claude/projects/<hash>/memory/`). If memory sync writes to a shared store using the project slug derived from the git remote URL or working directory name, and that derivation produces the wrong slug (e.g., a symlink, a cloned path, or a workspace alias), memory for `nfideia` lands in `ideiapartner`'s namespace. An agent in `ideiapartner` then picks up NFS-e workflow memory and applies it to a completely different product context.

**Why it happens:**
Path-based project identification is fragile: the same repo can be at `~/dev/nfideia`, `~/projects/nfideia`, or `/Volumes/data/nfideia`. Each path hashes to a different Claude project ID. A sync system that derives the slug from `basename $(git rev-parse --show-toplevel)` gets the right name but if two repos share a folder name (unlikely but possible) or if the repo root differs across machines (likely with iCloud Drive vs local paths), the namespacing breaks.

**How to avoid:**
- Define canonical project slugs in `versions.lock` or a new `memory-scope.json` manifest, not derived from filesystem paths. The slug is a stable identifier: `ideiapartner`, `nfideia`, `cfoai-grupori`, `lapidai`, `ideiaos`.
- At import time, the SessionStart hook validates the slug against the current repo's `git remote get-url origin` and emits a directional error (not a generic warning) if they mismatch — block the import, do not silently continue.
- Namespace the shared store as `<branch>/<project-slug>/` so accidental cross-project reads are visually obvious and auditable.

**Warning signs:**
- SessionStart shows memory files from a project slug that differs from the current repo name.
- An AI session references facts (feature names, table names, client-specific terminology) that belong to a different project.
- `git log memory-sync --oneline -- ideiapartner/` returns commits from sessions run in `~/dev/nfideia/`.

**Phase to address:** Phase 2 (import mechanism) — slug validation must run before any memory file is loaded.

---

### Pitfall 7: Stale and contradictory memory amplified across the team

**What goes wrong:**
Memory files become stale. This was confirmed during this session: the audit identified 3 obsolete memory records in the IdeiaOS MEMORY.md that needed pruning. In a team-shared, git-backed memory store, a stale record written 3 weeks ago by Machine A is pulled and acted on by Machine B today. Unlike a single-user memory, team shared memory has no natural GC: nobody owns it, so nobody prunes it. Over time, contradictory records accumulate: one file says "the GSD pin is 1.1.0 (correct)" and a later file says "drift detected: GSD at 1.36.0" (the ambiguous warning that triggered commit `3724ee9`). An AI agent reads both, picks the one with higher apparent confidence, and acts on it.

**Why it happens:**
Memory files are append-friendly and deletion-averse (deleting a file from a git branch requires an explicit commit and the intent to prune). Without a decay policy and a curation step, the shared store grows monotonically with outdated facts. The ambiguous-drift-warning learning is especially relevant: a stale memory file that describes a state that no longer exists is structurally identical to the ambiguous drift warning — it does not say which version of reality is current.

**How to avoid:**
- Every memory file in the shared store must carry `last_verified:` and `expires:` fields in frontmatter. A pre-import hook in SessionStart skips files where `expires:` is past.
- The export mechanism must, when writing a new fact, check for conflicting existing facts and either update the existing file (same key/slug) or explicitly retire the old one (add `status: retired` to the old frontmatter and commit the retirement before committing the new fact).
- Periodic curation: `idea-doctor.sh` (or a new `memory-audit.sh`) counts expired and retired files and emits a non-blocking warning when the ratio of expired:live exceeds 30%. The action is: human curates, not AI auto-prunes (AI auto-pruning stale memory is itself a hazard — it may prune still-valid records based on incorrect freshness heuristics).

**Warning signs:**
- Two memory files in the shared store make contradictory claims about the same key (GSD version, branch topology, Lovable project status).
- `expires:` dates are more than 30 days past on more than 2 files.
- An AI session references a feature or behavior that was deprecated in a past milestone.

**Phase to address:** Phase 2 (memory format) and Phase 3 (curation tooling) — format design must include decay metadata; curation tooling ships before the system is used by multiple team members.

---

### Pitfall 8: Ambiguous memory conflict message causes AI to "fix" in the wrong direction

**What goes wrong:**
When two machines sync and find conflicting memory content, the conflict message says "conflict: file X differs between local and remote — resolve." An AI agent or even a developer reads this as "one of these is wrong" and resolves it using the most available heuristic. For memory files, the heuristic is usually recency — but the remote file may be more recent without being more correct (it may carry a stale fact from a session on Machine B that ran before Machine A's session that produced the correct fact). This is the exact failure mode documented in `2026-06-12-ambiguous-drift-warning-induces-agent-revert.md`, applied to memory instead of `versions.lock`.

**Why it happens:**
Git merge conflicts on memory `.md` files produce standard `<<<<<<< HEAD / >>>>>>> remote` markers. These are resolved by humans or AI agents. An AI agent cannot know which fact is correct — it picks one. If it picks wrong, it commits the wrong fact with a plausible-looking "fix(memory): resolve conflict" commit message, which autosync or a push will propagate to all machines.

**How to avoid:**
- Use only fast-forward merges for the memory store branch — no merge commits. If fast-forward fails (diverged histories), block the import and require human resolution. Memory conflicts are correctness issues, not merge issues.
- Memory files should use append-only semantics where possible: instead of editing a fact file, write a new revision file with a monotonically increasing revision suffix and let the reader use the highest revision. This avoids git-level conflicts entirely at the cost of slightly more storage.
- If a conflict must be resolved by an AI agent, the conflict message must be directional: include the session timestamps and machine IDs of both sides, and state explicitly "DO NOT auto-resolve — human must review conflicting facts."

**Warning signs:**
- `git log memory-sync --oneline | grep -i "resolve conflict\|fix.*memory\|merge"` returns commits.
- A memory file that was correct last session now shows a fact that was previously identified as wrong (the `versions.lock` semver inversion pattern in memory form).
- Two AI sessions on different machines reach contradictory conclusions about the same project state.

**Phase to address:** Phase 2 (sync mechanism) — fast-forward-only policy and conflict block must be the default, not an option.

---

### Pitfall 9: Claude vs Cursor memory format divergence breaking the bridge

**What goes wrong:**
Claude Code memory uses `.md` files with YAML frontmatter (`name:`, `description:`, `metadata:`) stored at `~/.claude/projects/<hash>/memory/`. Cursor memory format is different (separate file structure, different keys, no standard frontmatter schema). A bridge layer that converts between formats may translate fields incorrectly, drop unknown fields silently, or produce files that are syntactically valid but semantically wrong (a `description:` that was a one-liner in Cursor becomes the full body in Claude format, corrupting the intent). Additionally, Claude reads memory files at the project level keyed by the working-directory hash — if the bridge writes to the wrong hash, the memory is invisible to Claude.

**Why it happens:**
No shared memory schema exists across IDEs today. Each IDE defines its own format. A sync bridge either commits to one format as canonical (losing IDE-specific metadata) or maintains a translation layer that must be updated each time either IDE changes its format.

**How to avoid:**
- Define a canonical interchange format (e.g., IdeiaOS Memory Format v1) that is a strict subset of both Claude and Cursor formats — only fields both support. The bridge converts from canonical to each IDE's native format, not from IDE to IDE directly.
- Pin the Claude memory schema version. If Claude releases a format change, the bridge breaks loudly (startup check fails) rather than silently producing malformed files. Use the same versioning philosophy as `versions.lock` — the schema version is a pinned value, not inferred.
- Test the round-trip: canonical → Claude format → canonical must be lossless. canonical → Cursor format → canonical must be lossless. Failures are CI gates, not post-hoc discoveries.

**Warning signs:**
- A memory file loaded by Claude shows empty or garbled content that was correctly authored in Cursor.
- The `metadata:` field in a Claude memory file contains Cursor-specific keys that Claude ignores (silent data loss).
- A session claims no memory for a project that has extensive Cursor memory — bridge produced files in the wrong project hash directory.

**Phase to address:** Phase 2 (format design) — canonical format must be defined and tested before any bridge implementation is written.

---

### Pitfall 10: Export-on-close not firing on crash, force-quit, or autosync race

**What goes wrong:**
The session-close export hook (writes session memory back to the shared store) is registered as a PostToolUse or similar session lifecycle event. If a session ends by: (a) terminal killed, (b) machine sleeps mid-session, (c) Claude Code crashes, (d) the user closes the IDE window without going through a graceful `/exit` — the hook never fires. The session's insights are lost. More dangerous: the session started, imported memory, modified the working memory in-session, and now the shared store reflects the import-time state while the in-session state is gone. The next session on another machine imports the pre-session state, potentially missing hours of corrections.

Additionally, if autosync fires (15-min timer) while the export hook is also running (session close), both attempt to commit to the shared store branch simultaneously — push race condition, one of them will fail and the other will produce a partial commit.

**Why it happens:**
Shell-level hooks are not guaranteed to execute on abnormal termination. The `setup.sh` hook installation uses git hooks and Claude Code's `hooks.json`, but these only execute in graceful flows. A push race between two git processes on the same branch is a classic concurrent-write hazard.

**How to avoid:**
- Implement a heartbeat file (`~/.local/state/ideiaos-memory/<project-slug>/session.lock` with PID and machine ID) that is updated every N minutes during the session. On next session start, if a lock file exists from the same machine (PID gone) or from a different machine (possible concurrent session), the import step reads the partial export if available, or falls back to the shared store state and logs a warning.
- Autosync must check for an active session lock before committing to the memory store branch — if a session is live, skip the memory store files and let the export hook handle them.
- Make the export idempotent: exporting the same memory twice produces the same git commit hash (or is a no-op if nothing changed). This means a retry after a crash is safe.

**Warning signs:**
- Session heartbeat file from a previous session still exists with a dead PID (`kill -0 <PID>` returns non-zero).
- `git log memory-sync --oneline` shows two commits within 5 seconds from the same session ID.
- A session starts and the shared store state is more than 2 autosync cycles (30 minutes) behind what the developer remembers from the previous session.

**Phase to address:** Phase 2 (export mechanism) and Phase 3 (autosync coordination) — heartbeat and push coordination must be designed before the export hook is wired.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Store memory on `planning` branch (already exists) | No new branch infrastructure | `planning`→`main` merge path exists; one merge mistake contaminates Lovable | Never — use a dedicated `memory-sync` branch |
| Use `git add -A` in memory export commit | Simple implementation | Captures working-tree noise, secrets, temp files | Never — always explicit file list |
| Derive project slug from directory basename | Zero config | Breaks across machines with different checkout paths | Never in production; OK only for local-only dev |
| Infer memory scope (personal vs team) from content | No user burden | AI will guess wrong; secrets will reach shared store | Never — require explicit `scope:` declaration |
| Trust `expires:` date for auto-pruning | GC without human effort | AI prunes valid memory that looks stale | Never — pruning requires human confirmation |
| One shared memory branch for all projects | Simple topology | Cross-project leakage when slug mapping fails | Only if slug is machine-verified against git remote |
| Sync on next autosync cycle instead of immediately on close | No extra hook | Sessions that crash export nothing; stale state propagates | Never for close export; OK for non-critical supplementary facts |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Lovable Cloud + memory files | Memory `.md` file with valid frontmatter committed to `main` — Lovable ingests as project context | `.gitignore` all memory paths at repo root; enforce with pre-commit hook in Lovable projects |
| Claude Code memory + project hash | Assuming the hash is stable across machines — it is not (path-derived) | Use canonical slug → hash lookup table per machine; never hardcode paths |
| Autosync + memory export | Both fire at session close → push race on memory-sync branch | Autosync must check session lock before touching memory files; mutual exclusion |
| git-sync-check.sh + memory branch | Hook only pulls the main working branch and warns about `planning` — does not pull `memory-sync` | Extend hook to pull `memory-sync` with `--ff-only` before session reads any memory |
| Obsidian vault + memory sync | Vault is iCloud/Obsidian Sync (non-git) — attempting git-based sync to vault path will conflict with Obsidian Sync | Keep vault and git memory store entirely separate; vault is human-curated second brain, not AI memory export target |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Memory export includes tool output verbatim | API keys, connection strings, Supabase service role keys in git history forever | Scan every export file with `scan-absorbed.sh`-style grep before commit; block on match |
| Personal feedback facts (user preferences, critique of user's decisions) in team store | Team-readable critique of individual team member's choices | Default `scope: personal`; team scope requires explicit override |
| Client PII (CPF/CNPJ, company names, billing amounts) captured in memory | LGPD compliance risk if shared store is on a semi-public repo | PII pattern blocklist in export scanner; memory files flagged with `pii: true` must never reach shared store |
| Memory branch is not protected (force-push allowed) | Attacker or misguided agent rewrites history, poisoning all team members' memory imports | Protected branch rule on `memory-sync`: no force-push, require signed commits or at minimum commit author validation |
| Temp memory file committed before gitignore is set up | Permanent git history entry even after gitignore added (gitignore does not retroactively remove tracked files) | `git rm --cached` the file + add to `.gitignore` + commit the removal before any push to shared branches. The nfideia `.lovable_mem_tmp.md` case: requires `git rm --cached .lovable_mem_tmp.md` on main |

---

## "Looks Done But Isn't" Checklist

- [ ] **gitignore coverage:** Memory export paths added to `.gitignore` — verify with `git check-ignore -v <memory-file-path>` returning a match
- [ ] **Autosync branch guard:** Autosync script refuses to commit if branch is `main` — verify with `git checkout main && (trigger autosync)` and confirm no commit is created
- [ ] **Memory on main:** `git log origin/main --oneline -- '*.lovable_mem_tmp*' '**memory**'` returns empty for all Lovable projects
- [ ] **Scope declaration enforced:** Memory export hook returns exit 1 when `scope:` is absent from frontmatter
- [ ] **Secret scan coverage:** `scan-absorbed.sh` patterns include API key, JWT, connection string patterns — verify by inserting a dummy `sk-proj-test` and confirming scan blocks it
- [ ] **Slug validation active:** SessionStart hook emits a directional error (not a generic warning) when slug derived from git remote does not match the memory directory being imported
- [ ] **Fast-forward-only enforced:** `git config --get branch.memory-sync.mergeOptions` shows `--ff-only` or equivalent branch protection is active
- [ ] **nfideia cleanup:** `.lovable_mem_tmp.md` removed from `nfideia:main` with `git rm --cached` + commit + push before v5 ships (this file is live today)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Memory file on `main` (Lovable ingested it) | MEDIUM | `git rm --cached <file>` → commit "chore: remove memory artifact from main" → push → check Lovable dashboard for triggered Update → if triggered, ensure Update is benign before Publish |
| Autosync committed stale memory to wrong branch | LOW | `git revert <commit>` on the offending commit → push → no --force needed since revert is a new commit |
| Export-on-close missed (crash) | LOW | Re-run export manually from memory in next session; note the gap in memory history — do not attempt to reconstruct |
| Cross-project memory leakage detected | MEDIUM | `git log memory-sync --all -- <wrong-project-slug>/` → identify contaminating commits → `git filter-repo` or surgical `git revert` to remove → force-push allowed only on `memory-sync` (never `main`) |
| Secret committed to shared store | HIGH | Rotate the secret immediately (treat as compromised) → `git filter-repo --path <file> --invert-paths` to rewrite history → force-push `memory-sync` → notify all team members to re-clone or `git fetch && git reset --hard origin/memory-sync` |
| Conflicting memory resolved in wrong direction by AI agent | MEDIUM | Identify the correct version from session logs → `git revert <bad-commit>` → write correct memory file explicitly → add directional warning to the conflicting facts |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Memory reaches `main` (Lovable regression) | Phase 1: Foundation | `git log origin/main -- memory paths` returns empty for all Lovable projects |
| Autosync commits to wrong branch | Phase 1: Foundation | `git checkout main && trigger autosync → no new commits` |
| `planning`→`main` merge carries memory | Phase 1: Foundation | Protected branch rule blocks `.planning/memory/` paths from appearing in PRs to `main` |
| SessionStart imports stale memory | Phase 2: Import/export mechanism | `git-sync-check.sh` pulls `memory-sync` branch; session shows current `last_sync` timestamps |
| Personal/secret content in shared store | Phase 2: Export mechanism | `scan-absorbed.sh` blocks export; `scope: personal` is default |
| Cross-project slug mismatch | Phase 2: Import mechanism | SessionStart emits directional error on slug mismatch; confirmed with test slug collision |
| Stale/contradictory memory amplification | Phase 2: Memory format + Phase 3: Curation tooling | `expires:` present in all files; `memory-audit.sh` reports expired ratio |
| AI resolves conflict in wrong direction | Phase 2: Sync mechanism | Fast-forward-only enforced; conflict block confirmed with artificial diverge test |
| Claude vs Cursor format drift | Phase 2: Format design | Round-trip test canonical→Claude→canonical is lossless (CI gate) |
| Export-on-close not firing | Phase 2: Export mechanism + Phase 3: Autosync coordination | Session lock heartbeat present; crash simulation shows safe fallback |

---

## Sources

- Real incident: `nfideia` `.lovable_mem_tmp.md` on `origin/main` (commit `604c0a19`, confirmed 2026-06-14)
- Real incident: `versions.lock` pin reverted 3× — commits `c7fc184` (autosync stale tree) and `3724ee9` (AI agent ambiguous warning), fixed in `7a4f54b`
- `docs/learnings/2026-06-12-version-reset-migration-semver-trap.md` — the autosync + semver inversion failure modes and 6-barrier solution
- `docs/learnings/2026-06-12-ambiguous-drift-warning-induces-agent-revert.md` — messages of tools are prompts; ambiguity is dangerous
- `docs/learnings/2026-06-02-interactive-installer-breaks-set-e.md` — non-interactive environment hazards
- `nfideia/docs/learnings/2026-06-08-autosync-commita-no-meio-da-sessao-verificar-antes-de-flagar.md` — autosync fires mid-session; working tree is not a reliable snapshot
- `~/.claude/projects/.../memory/multi-ide-trabalho-concorrente.md` — concurrent IDE sessions on same repo; foreign changes in working tree
- `source/templates/global-patches/git-sync-check.sh` — SessionStart hook current behavior (pulls working branch, warns about `planning`, does not pull any memory branch)
- `source/skills/lovable-handoff/SKILL.md` — Lovable merge-to-main mandate (Passo 3b) and its scope limits
- `STATE.md` "Roadmap / Ideias futuras" — origin of the memory sync feature; real drift incident documented (session 35 vs session 39)
- `scripts/check-versions-lock.sh` — precedent for file-specific pre-commit guard with directional messages and bypass escape hatch

---
*Pitfalls research for: IdeiaOS v5 — cross-IDE memory sync*
*Researched: 2026-06-14*
