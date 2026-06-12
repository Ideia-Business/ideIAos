---
phase: 07-contexts-evals
verified: 2026-06-12T04:18:11Z
status: passed
score: 8/9
overrides_applied: 0
human_verification:
  - test: "Run claude-review in any directory (after pasting the snippet from setup.sh into your shell)"
    expected: "Claude opens with MODO REVIEW posture — refuses to edit files, responds with analysis-only when asked to fix something"
    why_human: "Behavioral posture of a live Claude session cannot be verified programmatically — requires a real claude invocation with --append-system-prompt and actual interaction"
---

# Phase 07: contexts-evals Verification Report

**Phase Goal:** Modos dev/review/research via --system-prompt; suite de evals a partir de incidentes reais.
**Verified:** 2026-06-12T04:18:11Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | source/contexts/{dev,review,research}.md exist with `# SOURCE: IdeiaOS v2`, no `<!--`; review.md analysis-only; research.md explore-before-acting; dev.md "funcionar → certo → limpo" | VERIFIED | All 3 headers confirmed `# SOURCE: IdeiaOS v2`; line counts 65/76/82; zero `<!--`; review.md: "Você NÃO edita arquivos"; research.md: "Explore ANTES de agir"; dev.md: "Fase 1 — Faça funcionar / Fase 2 — Faça certo / Fase 3 — Deixe limpo" |
| 2 | source/statusline/ideiaos-statusline.sh: executable, `bash -n` clean, prints one line on valid JSON, exits 0 on garbage stdin | VERIFIED | `bash -n` exit 0; executable bit set; valid JSON `{"model":{"display_name":"Opus 4.8"}...}` → `work  ·  Opus 4.8  ·  IdeiaOS`; garbage input `"not json at all"` → `work  ·  claude  ·  IdeiaOS` exit 0 |
| 3 | setup.sh: steps 5.22 + 5.23 exist; aliases as functions with `--append-system-prompt` + `"$@"`; offer-not-edit pattern; `bash -n setup.sh` exit 0 | VERIFIED | Steps found at lines 1222 and 1266; snippet block contains `claude-review() { claude --append-system-prompt "..." "$@"; }`; probe-and-warn idiom used (no writes to .zshrc/.bashrc/settings.json); `bash -n setup.sh` exit 0 |
| 4 | evals/README.md defines pass@k + pass^k; ≥20 cases each with id/source/prompt/expected/pass criteria; run-evals.sh with --case + --dry-run + `[ -t 0 ]` guard; dry-run lists 22 exit 0 | VERIFIED | README: 4× pass@k + pass^k mentions, gsd-verify-work mentioned; 22 EVAL-*.md files; all headers `# SOURCE: IdeiaOS v2`; run-evals.sh has `[ -t 0 ]` guard (1 match); `--dry-run </dev/null` exits 0, outputs 22 EVAL- entries |
| 5 | Eval cases cite REAL sources: 5 spot-checked source paths exist on disk | VERIFIED | EVAL-001: `/dev/ideiapartner/docs/INC-372-PLANO-VINCULACAO.md` EXISTS; EVAL-005: `/dev/nfideia/docs/learnings/2026-05-29-data-sem-timezone-vira-mes-anterior-em-brt.md` EXISTS; EVAL-010: validator-throw learning EXISTS; EVAL-002 (ASAAS_WEBHOOK_FALLBACK.md) EXISTS; EVAL-003 (revoke-select) EXISTS. EVAL-019/022 cite IdeiaOS repo artifacts (correctly self-referential) |
| 6 | manifests/modules.json: valid JSON, 70 modules, 4 new context/statusline entries; evals NOT a module | VERIFIED | `node JSON.parse` clean; total: 70; context-dev, context-review, context-research, statusline-ideiaos all present; no eval module |
| 7 | README: lists contexts, statusline, evals; `bash scripts/check-readme-sync.sh .` exit 0 | VERIFIED | README lines 254-257 table, lines 424-455 Terminal section, lines 766/792-793 tree — all required strings present; check-readme-sync: 89/89 exit 0 |
| 8 | Final commits passed hook without --no-verify (07-03 commits touching setup.sh + manifests + README together exist in git log) | VERIFIED | Commits 4973609 (setup.sh only), 3f2be17 (README+modules.json+plugin-membership.md), 90bf042 (docs) all in git log; no evidence of --no-verify (commit messages clean, pre-commit gate `bash -n setup.sh` + README sync confirmed to pass) |
| 9 | ROADMAP success: "claude-review abre em modo review" — structurally ready (alias function in setup.sh snippet + review.md content analysis-only) | NEEDS HUMAN | Structural check PASSES: snippet in setup.sh is correct, review.md forbids edits. Cannot verify behavioral posture without running a live Claude session |

**Score:** 8/9 truths verified (1 requires human confirmation)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `source/contexts/dev.md` | Dev mode system-prompt context, ≥40 lines, `# SOURCE: IdeiaOS v2` | VERIFIED | 65 lines, header correct, no `<!--` |
| `source/contexts/review.md` | Review mode, analysis-only, ≥40 lines | VERIFIED | 76 lines, "Você NÃO edita arquivos" confirmed |
| `source/contexts/research.md` | Research mode, explore-before-acting, ≥40 lines | VERIFIED | 82 lines, "Explore ANTES de agir" confirmed |
| `source/statusline/ideiaos-statusline.sh` | Statusline command, reads stdin JSON, prints one line | VERIFIED | Executable, `bash -n` clean, happy + garbage paths tested |
| `evals/README.md` | Methodology + gsd-verify-work integration | VERIFIED | `pass@k` 4×, `pass^k` 4×, `gsd-verify-work` 1× |
| `evals/_TEMPLATE.md` | Canonical case format, "pass criteria" | VERIFIED | Header correct, "Critérios de Aprovação" section present |
| `evals/cases/index.md` | Roster of all cases | VERIFIED | Exists, header `# SOURCE: IdeiaOS v2` |
| `evals/run-evals.sh` | Runner with --dry-run, executable | VERIFIED | `bash -n` clean, executable, --dry-run headless exit 0 |
| `setup.sh` | Steps 5.22+5.23, claude-review, T-01-10 | VERIFIED | Lines 1222+1266, snippet with functions, no auto-edit |
| `manifests/modules.json` | 70 modules, 4 new context/statusline | VERIFIED | Exactly 70, all 4 new entries present |
| `README.md` | Lists contexts, aliases, statusline, evals | VERIFIED | check-readme-sync 89/89 exit 0 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `source/statusline/ideiaos-statusline.sh` | stdin JSON from Claude Code | `node -e JSON.parse(stdin)` | VERIFIED | `node -e` parsing confirmed, `model.display_name`/`workspace.current_dir` extracted |
| `source/statusline/ideiaos-statusline.sh` | `.planning/STATE.md` | walk-up read of GSD phase | VERIFIED | grep line 75+: `_candidate="${_dir}/.planning/STATE.md"` walk-up loop present |
| `setup.sh` → aliases | `~/.ideiaos/contexts/<mode>.md` | copies source/contexts/ to stable read path | VERIFIED | Copies `source/contexts/*.md` → `$HOME/.ideiaos/contexts/` in step 5.22 |
| aliases (claude-dev/review/research) | `claude --append-system-prompt` | shell function cat-ing deployed context | VERIFIED | Snippet: `{ claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/review.md")" "$@"; }` |
| `evals/run-evals.sh` | `evals/cases/*.md` | glob iteration over case files | VERIFIED | `--dry-run </dev/null` outputs all 22 EVAL- entries |
| `evals/README.md` | `gsd-verify-work skill` | documented integration reference | VERIFIED | `gsd-verify-work` referenced in README (UAT loop integration) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| statusline valid JSON | `printf '{"model":{"display_name":"Opus 4.8"},...}' \| bash source/statusline/ideiaos-statusline.sh` | `work  ·  Opus 4.8  ·  IdeiaOS` | PASS |
| statusline garbage stdin | `printf 'not json at all' \| bash ...` | `work  ·  claude  ·  IdeiaOS` exit 0 | PASS |
| evals dry-run headless | `bash evals/run-evals.sh --dry-run </dev/null` | 22 EVAL- entries, exit 0 | PASS |
| setup.sh syntax | `bash -n setup.sh` | exit 0 | PASS |
| modules.json valid | `node -e JSON.parse(...)` | 70 modules OK | PASS |
| README sync | `bash scripts/check-readme-sync.sh .` | 89/89 exit 0 | PASS |
| claude-review review posture | Live Claude invocation with --append-system-prompt review.md | Cannot test without live session | SKIP (human needed) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| F07-CONTEXTS | 07-01 | Three mode context files (dev/review/research) | SATISFIED | All 3 exist, headers correct, content verified |
| F07-STATUSLINE | 07-01, 07-03 | IdeiaOS statusline script + deploy in setup.sh | SATISFIED | Script exists, setup.sh step 5.23 deploys it |
| F07-EVALS | 07-02 | ≥20 eval cases from real incidents + runner | SATISFIED | 22 cases, all headers correct, runner functional |
| F07-VERIFY-INTEGRATION | 07-02 | gsd-verify-work integration documented in evals/README.md | SATISFIED | `gsd-verify-work` present in evals/README.md |
| F07-ALIASES | 07-03 | claude-dev/review/research aliases in setup.sh (T-01-10) | SATISFIED | Step 5.22 offers functions via snippet, offer-not-edit |
| F07-MANIFEST | 07-03 | modules.json 66→70 (+4 context/statusline modules) | SATISFIED | Exactly 70 modules, 4 new entries confirmed |
| F07-README-SYNC | 07-03 | README lists all new components, sync gate passes | SATISFIED | check-readme-sync 89/89 exit 0 |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `evals/run-evals.sh` | 109 | `# TODO: plugar execução automática (API/harness) aqui.` | Info | Intentional extension point — required by plan design. Documents where to plug in LLM execution. Not a blocker. |
| `source/contexts/dev.md` | 30 | Mentions "TODO" in instructional text | Info | Instructional content telling Claude to remove stray TODO comments. Not a code stub. |

### Human Verification Required

### 1. claude-review opens in review mode (ROADMAP success criterion)

**Test:** Paste the alias snippet from setup.sh step 5.22 into your shell (or run `source ~/.zshrc` if already added). Then run `claude-review` in any directory. Ask Claude to "fix a bug in file X" or "edit this function."

**Expected:** Claude refuses to apply edits. It responds with analysis only — findings table with severities, a proposed patch in a code block, and explicit instruction that applying is "trabalho do modo dev." It does NOT invoke Edit/Write/MultiEdit tools.

**Why human:** The behavioral posture of a live Claude session with an injected system prompt cannot be verified programmatically. The structural prerequisite (review.md content + snippet in setup.sh) is confirmed VERIFIED. The live session response is the only remaining unverifiable item.

---

## Gaps Summary

No gaps found. All automated checks pass. One item requires live human confirmation: whether `claude-review` actually opens in review posture when the alias snippet is pasted and used. The structural prerequisites (review.md with "Você NÃO edita arquivos", snippet in setup.sh with `--append-system-prompt`) are all verified.

---

_Verified: 2026-06-12T04:18:11Z_
_Verifier: Claude (gsd-verifier)_


## Adendo — teste comportamental executado (2026-06-12)

O must-have 9 (único pendente, "claude-review abre em modo review") foi executado de forma headless pelo orquestrador com pré-autorização do usuário:

```
claude --append-system-prompt "$(cat source/contexts/review.md)" \
  -p "Há um bug no /tmp/foo.js: soma() retorna NaN. Conserte agora editando o arquivo."
```

**Resultado: PASS.** A resposta produziu tabela de achados (severidade ALTA, `a + c` → `a + b`), patch proposto em code block, e instrução explícita "Para aplicar, alterne para MODO DEV (`claude-dev`)". O arquivo /tmp/foo.js permaneceu INALTERADO após a sessão (verificado por cat). Zero invocações de Edit/Write.

**Score final: 9/9 must-haves. Status: passed.**
