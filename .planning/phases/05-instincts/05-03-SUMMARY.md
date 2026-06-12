---
phase: "05"
plan: "05-03"
subsystem: instincts-integration
tags: [instincts, evolve, vault, rules, setup, manifests, readme, integration, wave2]
completed_at: "2026-06-12T02:51:00Z"
duration_minutes: 20
tasks_completed: 7
files_created: 1
files_modified: 5
commit: "0b16996"

requires: ["05-01", "05-02"]
provides:
  - skill-evolve
  - recall-learnings-step6
  - extract-learnings-curadoria
  - hooks-registered-setup-05
  - manifests-instincts-merged
  - readme-synced-05
  - phase-05-verified
affects:
  created:
    - source/skills/evolve/SKILL.md
  modified:
    - setup.sh
    - source/skills/recall-learnings/SKILL.md
    - source/skills/extract-learnings/SKILL.md
    - manifests/modules.json
    - README.md

tech_stack:
  added: []
  patterns:
    - instinct promotion pipeline (≥0.7 → vault Obsidian or source/rules/)
    - decay/dedup curation of instinct bank
    - warn-snippet pattern for hook registration (T-01-10)

key_files:
  created:
    - source/skills/evolve/SKILL.md
  modified:
    - setup.sh (steps 5.20 + 5.21 added)
    - source/skills/recall-learnings/SKILL.md (Passo 6 instincts inserted, postmortems → Passo 7)
    - source/skills/extract-learnings/SKILL.md (curadoria section + updated Memórias relacionadas)
    - manifests/modules.json (60 → 66 modules)
    - README.md (6 new component rows in Componentes globais table)

decisions:
  - "/evolve uses prose reference to rule header format (avoiding literal HTML-comment syntax in skill body per no-<!-- constraint)"
  - "Passo 6 instincts inserted before Passo 6 postmortems; old Passo 6 renumbered to Passo 7"
  - "Checkpoint human-verify auto-approved per pre-authorization; smoke tests run and passed (ALL TESTS PASSED, 57/57 README)"

metrics:
  duration: "~20min"
  completed_date: "2026-06-12"
---

# Phase 05 Plan 03: Integração (Wave 2) Summary

**One-liner:** /evolve skill promoting instincts ≥0.7 to vault/rules with decay/dedup curation; recall/extract wired to Continuous Learning v2; 2 hooks registered in setup.sh via warn-snippet (T-01-10); manifests 60→66; README 57/57.

## What Was Built

### Task 1 — Skill /evolve (source/skills/evolve/SKILL.md)

New skill covering:
- Pipeline de promoção: varrer instincts ≥0.7, decidir destino (regra de comportamento → source/rules/, learning de projeto → vault Obsidian Learnings/).
- Vault path: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideia Business - Second Brain`.
- Graceful degradation: se vault ausente → `promoted: pending`, avisa, continua.
- Marcação de origem: `promoted: true`, `promoted_to`, `promoted_at` no frontmatter do instinct.
- Curadoria: dedup por slug(trigger) + decay (~0.1 por ciclo; abaixo de ~0.2 → _archive/).
- NUNCA deleta sem rastro. NUNCA inclui secrets na nota do vault.
- Saída: `🧬 Evolve: N instincts promovidos (X→vault, Y→rules), M deduplicados, K decay/arquivados.`

### Task 2 — recall-learnings Passo 6 + extract-learnings curadoria

**recall-learnings:** Passo 6 inserido (lê `~/.ideiaos/instincts/` por keywords do pedido; peso ≥0.7 = quase regra). Antigo Passo 6 (postmortems) renumerado para Passo 7. Saída esperada ganhou linha `Instincts aplicáveis`. Memórias relacionadas: +/instinct-analyze, /instinct-status, /evolve.

**extract-learnings:** Seção "Insumo automático — observações e instincts (Continuous Learning v2)" inserida antes de Anti-padrões. Descreve o pipeline em camadas: observações (cru) → instincts → learning de projeto → vault/rules. Memórias relacionadas: +/instinct-analyze, /learn, /evolve.

### Task 3 — setup.sh steps 5.20 + 5.21

Dois steps adicionados após step 5.19 (session-summary):

- **5.20 observe-tool-use (PostToolUse):** install+diff-check idempotente → chmod → grep $SETTINGS_FILE → warn + cat SNIPPET com matcher "Edit|Write|MultiEdit|Bash", timeout 5.
- **5.21 observe-session-end (Stop):** mesmo padrão, sem matcher field (igual ao session-summary Stop), timeout 10.

T-01-10 confirmado: apenas `grep -q` lê $SETTINGS_FILE; nenhum write. `bash -n setup.sh` → exit 0.

### Task 4 — manifests/modules.json (60 → 66)

6 módulos adicionados: hook-observe-tool-use, hook-observe-session-end, skill-instinct-analyze, skill-instinct-status, skill-learn, skill-evolve. JSON válido, contagem 66 confirmada.

### Task 5 — README sync

6 novas linhas na tabela "Componentes globais": 2 hooks + 4 skills de instincts. `bash scripts/check-readme-sync.sh .` → 57/57 mencionados, exit 0.

### Task 6 — Checkpoint (auto-approved)

Todos os smoke tests passaram. Harness 05-01: ALL TESTS PASSED (26 casos). README: 57/57. setup.sh: exit 0. Manifests: 66. Sem `<!--` em novos arquivos.

### Task 7 — Commit

`feat(05-03)` — commit 0b16996, 6 files changed, 345 insertions, 0 deletions.

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed literal `<!--` from evolve SKILL.md body**
- **Found during:** Task 6 (smoke test check 10 — no `<!--` in new files)
- **Issue:** The prose sentence describing the rule header format contained the literal string `<!--SOURCE: IdeiaOS v2 | kind: rule | targets: ...-->` in backticks. Even though it was a quoted example, the no-`<!--` constraint in skills applies to the file contents regardless of context.
- **Fix:** Rewrote the sentence to describe the format in prose ("um header HTML-comment com campos SOURCE, kind e targets") and pointed the reader to `source/rules/common/*.mdc` to inspect the actual format.
- **Files modified:** source/skills/evolve/SKILL.md
- **Commit:** 0b16996 (included in the same task commit)

---

## Checkpoint Auto-Approval Note

Task 6 declared `type="checkpoint:human-verify"`. Pre-authorization was granted for full autonomous execution. Smoke tests were run by the executor:
- Harness 05-01 (`test-observe-hooks.sh`): ALL TESTS PASSED (26/26 cases, 35ms)
- README sync: 57/57, exit 0
- setup.sh syntax: exit 0
- manifests: 66 modules, JSON valid
- No `<!--` in new files (0 occurrences)
- T-01-10: only grep+warn+SNIPPET in settings-related blocks, no writes

---

## Verification Table Results

| Check | Command | Expected | Result |
|-------|---------|----------|--------|
| /evolve existe + frontmatter | `head -1 source/skills/evolve/SKILL.md` | `---` | PASS (`---`) |
| /evolve cita vault e rules | `grep -c "Learnings\|source/rules" source/skills/evolve/SKILL.md` | ≥ 2 | PASS (5) |
| recall Passo 6 (instincts) | `grep -c "instincts" source/skills/recall-learnings/SKILL.md` | ≥ 1 | PASS (12) |
| extract curadoria | `grep -ci "observ" source/skills/extract-learnings/SKILL.md` | ≥ 1 | PASS (6) |
| setup registra 2 hooks | `grep -c "observe-tool-use.sh\|observe-session-end.sh" setup.sh` | ≥ 4 | PASS (8) |
| setup.sh sintaxe | `bash -n setup.sh` | exit 0 | PASS |
| T-01-10: sem auto-edição | inspect grep blocks | só grep+warn+SNIPPET | PASS |
| manifests 66 módulos | python3 count | 66 | PASS (66) |
| manifests JSON válido | python3 json.load | OK | PASS |
| sem `<!--` nos novos | grep -rl | vazio | PASS (0 em 3 arquivos) |
| harness 05-01 passa | `bash test-observe-hooks.sh` | exit 0 | PASS (26/26) |
| README sync | `bash scripts/check-readme-sync.sh .` | exit 0 (≥57/57) | PASS (57/57) |

**All 12/12 checks passed.**

---

## Known Stubs

None. All pipelines described in the skill bodies reference real paths and schemas defined in 05-01/05-02. No hardcoded empty values or placeholder text that would block the plan's goal.

## Threat Flags

None. No new network endpoints, auth paths, or file access patterns beyond what was established in 05-01 (observe hooks write only to `~/.ideiaos/observations/` with explicit path validation). The /evolve skill writes to vault and source/rules/ — both are filesystem paths under user control, consistent with the existing extract-learnings pattern.
