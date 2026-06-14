# Feature Research — Cross-IDE Memory Sync (IdeiaOS v5)

**Domain:** Shared/synchronized agent memory across IDEs (Claude Code + Cursor + others), team-scoped, Lovable-safe
**Researched:** 2026-06-14
**Confidence:** HIGH (grounded in existing IdeiaOS learning loop + verified against claude-git-sessions, claude-mem-sync, and Anthropic issue tracker)

---

## Context: The Existing Learning Loop (DO NOT Duplicate)

IdeiaOS already has a 4-layer promotion pipeline. v5 memory sync must extend it, not replace it.

```
observations.jsonl (raw, ~/.ideiaos/observations/<proj>/)
    └──/instinct-analyze──> instincts (~/.ideiaos/instincts/)
           └──/learn (manual capture mid-session)
           └──/evolve (confidence ≥0.7) ──> vault Obsidian (Learnings/) OR source/rules/
    └──/extract-learnings──> docs/learnings/YYYY-MM-DD-<slug>.md
           └──/recall-learnings (import at session start)
           └──Passo 4b: vault Obsidian
           └──Passo 4c: docs/decisions/ → vault Decisions/
```

**Key existing primitives v5 must hook into, not replace:**
- `~/.ideiaos/instincts/` — per-scope (project/global) instinct bank with confidence scores
- `~/.claude/projects/<slug>/memory/` — Claude Code's native fact store (md + frontmatter, one-file-per-fact, types: user/feedback/project/reference)
- `MEMORY.md` index in each project memory dir
- `docs/learnings/` — formal curated learnings in repo
- `docs/decisions/` — ADRs (mirrored to vault Passo 4c)
- Obsidian vault `~/Library/Mobile Documents/iCloud~md~obsidian/...` — cross-project curated library, fed by `/evolve` and `/extract-learnings`
- `planning` branch — `.planning/` artifacts, STATE.md, autosync

**Hard constraint (non-negotiable):** Memory sync rides the `planning` branch only. `main` is Lovable's sync branch — Update reads `main` automatically. Nothing in v5 may write to `main`. `/lovable-handoff` is the only gate to main.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that must exist for v5 to function. Missing any = the cross-IDE sync doesn't work.

| Feature | Why Expected | Complexity | Dependencies on Existing IdeiaOS |
|---------|--------------|------------|----------------------------------|
| **Import-on-SessionStart** — load shared memory from `planning` branch at session open | Without this, each IDE still starts blind; the whole value prop is session continuity | S | SessionStart hook (already in overlay, patch 11); `git show planning:.planning/memory/shared/` or fetch+read; piggybacks on existing `git-sync-check.sh` trigger |
| **Export-on-close (manual gate)** — `/memory-sync export` writes curated facts to `planning:.planning/memory/shared/` | Writers control what leaves their session; no accidental leakage | S | Session-close protocol in CLAUDE.md (step 3); existing `extract-learnings` gate discipline (replicable+non-obvious+stable) transplanted here |
| **shared/ vs local/ split** — `shared/` committed to `planning` (team-visible), `local/` gitignored (per-developer) | Without this split, personal facts (user preferences, feedback) leak to teammates, and IDE-private state bleeds across contexts | S | Maps directly to Claude Code's existing memory types: `project`/`reference` → shared; `user`/`feedback` → local (same split as claude-git-sessions) |
| **Project scoping** — memory namespaced by repo slug; no fact from project A surfaces in project B | Fundamental isolation requirement; cross-project leakage is the primary failure mode teams report | S | Existing slug pattern: `basename $PWD | tr ...` (already used in instinct paths `${PROJ}--*.md`); `.planning/memory/shared/<proj-slug>/` directory per project |
| **Member scoping** — within a project, personal-pending items namespaced by member ID | One developer's WIP notes must not appear in another's import | S | Subdirectory: `.planning/memory/members/<member-slug>/`; gitignored except when explicitly promoted to shared/ |
| **Readable index** — `MEMORY.md` (or equivalent) listing what's in shared/ with titles and dates | Without index, no agent can know what to load; importing raw files is O(N) reads | S | Already exists as pattern in `~/.claude/projects/<slug>/memory/MEMORY.md`; just needs a shared/ variant in planning branch |
| **Secret/credential strip gate** — no secret, credential, path, or env var survives into shared/ | Memory hygiene non-negotiable; IDE tools ingest entire project context and have no built-in instinct to filter credentials | S | Gate already exists in `/evolve` Passo 2 (Privacidade / Regra 1) and instinct abstraction rules in `/learn`; same rule applied at export step |
| **Conflict resolution (newer-wins)** — when two devs write the same fact key, the newer timestamp wins | Simple, predictable, no arbiter needed | S | No existing primitive; new logic in export script; consistent with "newer-wins" used by claude-git-sessions and memory consolidation literature |

---

### Differentiators (Competitive Advantage)

Features that go beyond basic sync and leverage IdeiaOS's existing learning loop to create meaningful value not found in generic solutions (claude-mem-sync, claude-git-sessions, etc.).

| Feature | Value Proposition | Complexity | Dependencies on Existing IdeiaOS |
|---------|-------------------|------------|----------------------------------|
| **Learning-loop bridge** — `/extract-learnings` auto-promotes qualifying facts from `docs/learnings/` into `shared/` on export | Existing curated, gated learnings become shared memory automatically; no double-work; the gate triplet (replicable+non-obvious+stable) already does quality control | S | `extract-learnings` SKILL.md Passos 3-4; `applies_to_projects: [global]` flag becomes the promotion signal to shared/ |
| **Instinct promotion to shared/** — instincts at confidence ≥0.7 with `scope: global` surfaced to shared/ as candidate facts | Validated behavioral patterns from automatic observation become team knowledge without manual curation overhead | M | `/evolve` SKILL.md already decides scope=global vs project; new step: if `scope=global AND confidence≥0.7` and not yet in shared/, offer to promote during export |
| **Decay/curation — stale eviction** — facts in shared/ older than N days without reinforcement are flagged for review or archived | Prevents the "stale facts museum" failure mode where old decisions corrupt new sessions; library stays signal-rich | M | `/evolve` already implements decay logic for instincts (confidence -0.1 per stale cycle, archive below 0.2); same mechanic applied to shared/ facts via `last_reinforced` frontmatter field |
| **Obsidian vault as cross-project tier** — `/recall-learnings` Passo 5 already reads vault; vault already receives `[global]` learnings; v5 formalizes this as the tier above shared/ | Shared/ = project-scoped team memory; vault = cross-project curated library; two-tier architecture with clear promotion paths and no ambiguity about where to look | M | Existing vault path + Passo 4b/4c in extract-learnings; new: explicit documentation of the 3-tier model (local → shared/planning → vault) so agents understand where each fact lives and why |
| **Dedup on import** — before writing imported shared facts into local memory, diff against existing local facts; skip if semantically equivalent slug already present | Prevents import from overwriting newer local versions with older shared copies; avoids duplicate fact entries | M | Existing slug dedup pattern in `/learn` Passo 3 (`evidence_count += 1`, never create duplicate); import script adopts same slug-based dedup check |
| **Member-contributed attribution** — shared/ facts carry `contributed_by: <member>` and `contributed_at: <date>` in frontmatter | Audit trail: team can see who introduced a fact, enabling trust weighting and dispute resolution without an arbiter agent | S | Frontmatter pattern already established in learning files; new: add two fields to the shared memory file schema |
| **`/memory-sync status`** — show what's in shared/, what's local-only, what's pending export, last sync timestamp | Observability; without it teams can't tell what the shared state actually is | S | Mirrors `/instinct-status` pattern (visual, grouped, scannable); new shell/script |
| **Selective import by type** — import only `project`/`reference` facts from shared/, never auto-import `user`/`feedback` | Preserves personal IDE preferences while getting team knowledge; same principle as claude-git-sessions' filter-by-type | S | Claude Code memory type system already defines these 4 types; filter is a one-liner in the import script |

---

### Anti-Features (Deliberately NOT Build)

Features that seem useful but violate constraints, create failure modes, or duplicate existing better solutions.

| Feature | Why It Seems Good | Why It Is Problematic | Correct Alternative | Constraint Violated |
|---------|-------------------|-----------------------|---------------------|---------------------|
| **Write anything to `main`** | "Simpler to keep one branch" | Lovable's Update auto-pulls `main`; any memory file there becomes production content in the Lovable sync | All memory-sync lives on `planning` branch only; `/lovable-handoff` is the sole gate | **HARD: Lovable/main constraint** |
| **Auto-push shared/ on every commit** | "Always up to date" | Autosync already excludes `versions.lock` to prevent drift; memory sync on every commit creates noisy git history, conflicts with autosync, and risks committing incomplete exports mid-session | Export is an explicit action at session close or on demand via `/memory-sync export` | autosync design; git history hygiene |
| **Live/real-time sync (WebSocket, polling daemon)** | "Always fresh context" | Requires persistent background process, infrastructure beyond git, introduces latency and connectivity dependencies, and conflicts with the filesystem-first, no-server philosophy of IdeiaOS | Eventual consistency via SessionStart import + session-close export is sufficient for async developer teams; live sync solves a problem the team doesn't have | IdeiaOS CLI-first / no-server philosophy; Article I of AIOX Constitution |
| **Cross-project memory injection** — importing facts from project A into a session working on project B | "Global learnings should flow everywhere" | This IS the primary failure mode from the real incident (nfideia memory drifting into ideiapartner context); one project's pending items must never appear in another's context | Project scoping is non-negotiable; cross-project promotion happens only via Obsidian vault as explicit curation step (`applies_to_projects: [global]`) | **Cross-project leakage** — stated hard constraint |
| **Auto-merge conflicting facts via LLM arbiter** | "Smart resolution" | LLM-based semantic merge (73% of resolutions in literature) requires API call at import time, costs tokens, and can silently change the meaning of a fact; for a dev team's memory, simpler is safer | Newer-wins for same-slug conflicts; surface conflicts to the developer via `/memory-sync status` for human resolution | cost, complexity, implicit mutation |
| **Shared `user`/`feedback` type facts** — pushing personal preferences and feedback to team memory | "Team could benefit from my style preferences" | Personal feedback facts (e.g., "user prefers shorter responses") are developer-specific; sharing them causes one developer's preferences to alter another's IDE behavior | Only `project` and `reference` typed facts go to shared/; `user` and `feedback` stay in local/ always | **Cross-member leakage** — stated hard constraint |
| **Separate memory system parallel to instincts** — building a new `~/.ideiaos/shared-memory/` store independent of existing pipeline | "Clean separation" | Creates a second brain parallel to the vault (already flagged as anti-pattern in PROJECT.md: "Instincts desaguam no vault Obsidian — não criar um segundo cérebro paralelo"); doubles maintenance burden and confuses agents about which store to consult | v5 shared memory is a layer on top of existing stores: Claude Code's `memory/` dir and the planning branch; it does not introduce a new canonical store | PROJECT.md decision: no parallel second brain |
| **Automatic promotion of all `[global]` learnings** without gate | "More sharing = more value" | The vault curation discipline exists precisely because "maioria é project-specific" (extract-learnings anti-patterns); auto-promotion floods shared/ with project-specific facts that happen to be marked global incorrectly | Promotion remains gated: `applies_to_projects: [global]` + passes the extract-learnings gate triplet + developer confirms at export | extract-learnings gate discipline |
| **Storing raw observations.jsonl in shared/** | "Raw data for teammates to analyze" | Raw observations contain literal file paths, table names, code snippets, and potentially secrets; abstraction gate (instinct formulation step) exists for this reason | Only promoted instincts (confidence ≥0.7, scope=global, abstracted) surface to shared/; raw observations stay local | secret leakage; extract-learnings anti-patterns |

---

## Feature Dependencies

```
[Import-on-SessionStart]
    └──requires──> [MEMORY.md index in shared/]
    └──requires──> [Project scoping (slug-namespaced dirs)]
    └──requires──> [shared/ vs local/ split]
    └──requires──> [planning branch readable from session]

[Export-on-close]
    └──requires──> [Secret strip gate]
    └──requires──> [Conflict resolution (newer-wins)]
    └──requires──> [Member scoping (contributed_by)]
    └──enhances──> [Learning-loop bridge] (extract-learnings output feeds export)
    └──enhances──> [Instinct promotion to shared/] (evolve output feeds export)

[Decay/curation — stale eviction]
    └──requires──> [MEMORY.md index] (to know last_reinforced per fact)
    └──enhances──> [Import-on-SessionStart] (stale facts excluded from import)

[/memory-sync status]
    └──requires──> [Import-on-SessionStart] (to know what was last synced)
    └──requires──> [Export-on-close] (to know what's pending)

[Obsidian vault as cross-project tier]
    └──requires──> [existing extract-learnings Passo 4b/4c] (already implemented)
    └──enhances──> [shared/ tier] (vault is the promotion destination above shared/)

[Dedup on import]
    └──requires──> [MEMORY.md index] (to know existing slugs)
    └──requires──> [Project scoping] (scope the dedup check correctly)

[Selective import by type]
    └──requires──> [shared/ vs local/ split]
    └──conflicts──> [Shared user/feedback facts] (explicitly excluded)
```

### Dependency Notes

- **Import requires index:** the `MEMORY.md` index in `shared/` is the cheapest entry point; without it, importing means scanning all files.
- **Export requires gate:** the secret strip gate must run before any fact exits local scope; it is a pre-condition, not an optional step.
- **Vault tier is already built:** `/recall-learnings` Passo 5 already reads the vault; `/evolve` Passo 2 already writes to it. v5 just formalizes the 3-tier model in documentation and the import script's precedence.
- **Decay enhances import:** stale eviction from shared/ ensures that SessionStart import does not load outdated facts that contradict current reality.

---

## MVP Definition

### Launch With (v5 milestone)

Minimum viable: a developer can close a session, export relevant facts, and the next developer (or themselves on another machine/IDE) can open the next session with those facts available.

- [ ] **shared/ vs local/ split** — directory convention on planning branch; gitignore for local/
- [ ] **Project scoping by slug** — `planning:.planning/memory/shared/<proj-slug>/`
- [ ] **Import-on-SessionStart** — hook reads shared/<proj-slug>/ and injects into local memory context; warns on DRIFT if shared/ has newer facts than last import timestamp
- [ ] **Export-on-close (manual)** — `/memory-sync export` with secret strip gate; writes only `project`/`reference` typed facts
- [ ] **MEMORY.md index in shared/** — auto-generated on export; lists facts with date and contributor
- [ ] **Conflict resolution (newer-wins)** — timestamp comparison on same-slug export
- [ ] **Member scoping** — `contributed_by` + `contributed_at` in frontmatter; member-specific pending notes go to `members/<slug>/` (gitignored by default)

### Add After Validation (v5.x)

- [ ] **`/memory-sync status`** — visual dashboard of shared state vs local vs pending; add when first developer reports confusion about what's synced
- [ ] **Dedup on import** — add when import collisions are observed in practice (slug-level check)
- [ ] **Selective import by type** — add when a developer reports personal preferences being altered by teammate's imports
- [ ] **Learning-loop bridge** — auto-signal from `extract-learnings` when `applies_to_projects: [global]` is set; add once core import/export is stable
- [ ] **Decay/curation** — stale flag on facts older than 30 days without `last_reinforced`; add once shared/ has been in use for a sprint

### Future Consideration (v5 follow-on)

- [ ] **Instinct promotion to shared/** — `/evolve` output surfaced to shared/ for global-scoped mature instincts; defer until the instinct bank has meaningful depth across projects
- [ ] **Obsidian vault tier formal documentation** — write the 3-tier model (local → shared/planning → vault) as a rule/doc; vault integration already works, just needs to be named and explained to new team members
- [ ] **`/memory-sync import --dry-run`** — preview what would change before accepting; add if team grows beyond 3 developers

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| shared/ vs local/ split + project scoping | HIGH | LOW | P1 |
| Import-on-SessionStart | HIGH | LOW | P1 |
| MEMORY.md index in shared/ | HIGH | LOW | P1 |
| Export-on-close with secret gate | HIGH | LOW | P1 |
| Conflict resolution (newer-wins) | HIGH | LOW | P1 |
| Member scoping (contributed_by) | MEDIUM | LOW | P1 |
| `/memory-sync status` | MEDIUM | LOW | P2 |
| Dedup on import | MEDIUM | LOW | P2 |
| Selective import by type | MEDIUM | LOW | P2 |
| Learning-loop bridge (extract-learnings → shared/) | HIGH | LOW | P2 |
| Decay/curation — stale eviction | MEDIUM | MEDIUM | P2 |
| Instinct promotion to shared/ | MEDIUM | MEDIUM | P3 |
| 3-tier model documentation | LOW | LOW | P3 |
| `/memory-sync import --dry-run` | LOW | LOW | P3 |

**Priority key:**
- P1: Must have for v5 launch (the core sync loop)
- P2: Add after first sprint of real use
- P3: Future milestone

---

## Analog Systems Referenced

| System | Key Pattern Borrowed | Pattern Discarded |
|--------|----------------------|-------------------|
| **claude-git-sessions** (ingram-technologies) | Orphan branch; filter by type (project/reference shared, user/feedback private); newer-wins; no working tree contamination | Orphan branch separate from planning — IdeiaOS already has planning branch; session UUID keying (overkill for our team size) |
| **claude-mem-sync** (lopadova) | Composite-key dedup; scoring by access frequency; CI merge bot; `#keep` tag for permanent facts | SQLite store (IdeiaOS is filesystem/markdown-native); developer name privacy (small known team; attribution is a feature not a risk) |
| **IdeiaOS `/evolve`** (existing) | Decay logic (confidence -0.1 per stale cycle, archive below threshold); dedup by slug; promoted: true marker; vault as promotion target | N/A — this is the source |
| **IdeiaOS `/learn`** (existing) | Slug-based dedup before creating (evidence_count++, never duplicate); abstraction rules (no secrets, no literal paths) | N/A — this is the source |

---

## Sources

- [claude-git-sessions — orphan branch memory sharing for teams](https://github.com/ingram-technologies/claude-git-sessions)
- [claude-mem-sync — filtered, scored, deduplicated team memory via git](https://github.com/lopadova/claude-mem-sync/)
- [Anthropic claude-code issue #38536 — Shared Team Memory feature request](https://github.com/anthropics/claude-code/issues/38536)
- [Inside Claude Code's Team Memory Sync Engine — Jake Goldsborough](https://jakegoldsborough.com/blog/2026/inside-claude-codes-team-memory-sync/)
- [Cross-Agent Organizational Memory — Augment Code](https://www.augmentcode.com/guides/cross-agent-organizational-memory)
- [Why Multi-Agent Systems Need Memory Engineering — O'Reilly](https://www.oreilly.com/radar/why-multi-agent-systems-need-memory-engineering/)
- [AI Memory Security Best Practices — mem0.ai](https://mem0.ai/blog/ai-memory-security-best-practices)
- [How AI Coding Assistants Leak Secrets — Knostic](https://www.knostic.ai/blog/ai-coding-assistants-leaking-secrets)
- [Cursor persistent memory patterns — MemNexus](https://memnexus.ai/blog/2026-02-20-cursor-persistent-memory)
- IdeiaOS source: `source/skills/extract-learnings/SKILL.md`, `source/skills/recall-learnings/SKILL.md`, `source/skills/evolve/SKILL.md`, `source/skills/learn/SKILL.md`, `source/skills/instinct-status/SKILL.md`
- IdeiaOS STATE.md section "Roadmap / Ideias futuras" — real incident: nfideia session 35 vs session 39 drift across Cursor/Claude

---

*Feature research for: IdeiaOS v5 — cross-IDE memory sync*
*Researched: 2026-06-14*
