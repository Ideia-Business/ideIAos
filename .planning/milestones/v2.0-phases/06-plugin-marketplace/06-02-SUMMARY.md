---
phase: "06"
plan: "06-02"
status: complete
commits: ["5171cd9"]
subsystem: cleanup-removal
tags: [removal, git-rm, refactor, setup, check-readme-sync, destructive, wave2]
---

# Phase 06 Plan 02: Remoção dos dirs-fallback Summary

**One-liner:** Remoção definitiva de skills/agents/hooks/templates/ da raiz (comm -23 vazio em todos os 4 dirs) + 5 scripts reescritos para source/ + pre-commit hook re-instalado com pattern atualizado.

## Built

### Removido (git rm)
- `skills/` — 34 skills removidas da raiz (todas existem em source/skills/)
- `agents/` — 15 agents removidos da raiz (todos em source/agents/)
- `hooks/` — 14 hooks removidos da raiz (todos em source/hooks/)
- `templates/` — todas as templates removidas da raiz (todas em source/templates/)

**Superset check (Passo A):** `comm -23` entre cada dir-raiz e source/ retornou VAZIO para todos os 4 dirs. Nenhum arquivo root-only encontrado.

**Diffs conhecidos (Passo C):** extract-learnings, idea, recall-learnings — source/ é a versão mais nova (commits 0b16996/2197f2f de 2026-06-11 vs commits de 2026-06-02/08 no root).

### Scripts atualizados
- `scripts/check-readme-sync.sh` — reescrito para auditar source/ (excluindo test-* hooks)
- `scripts/install-git-hooks.sh` — pré-commit hook agora protege source/|scripts/|plugins/|manifests/
- `scripts/install-global-patches.sh` — PATCHES_DIR aponta source/templates/global-patches
- `scripts/update-design-suite.sh` — SKILLS_DIR e PIN_FILE apontam source/skills/
- `scripts/idea-doctor.sh` — loop drift (linha ~61) e textos apontam source/skills/
- `.git/hooks/pre-commit` — re-instalado via install-git-hooks.sh com pattern atualizado

### Docs atualizados
- `AGENTS.md` — mandato README: "source/ (hooks/skills/agents/templates/rules), scripts/, plugins/ ou manifests/"
- `adapters/_scaffold/README.md` — já estava correto (mostrava source/ como parent); sem mudanças necessárias

### Autosync
- Pausado no Passo 0 (com.ideiaos.gitautosync) antes do git rm
- Religado após o commit conjunto em 06-03

## Verification

| # | Check | Result |
|---|-------|--------|
| 1 | skills/agents/hooks/templates removidos | PASS |
| 2 | source/ intacto | PASS |
| 3 | superset (comm -23 vazio) | PASS |
| 4 | setup.sh bash -n | PASS |
| 5 | setup.sh sem refs mortas ($SETUP_DIR/skills...) | PASS |
| 6 | check-readme-sync audita source/hooks | PASS |
| 7 | check-readme-sync roda sem crash | PASS (exit 0) |
| 8 | install-git-hooks protege source/ | PASS |
| 9 | 5 scripts bash -n | PASS (todos) |
| 10 | AGENTS.md atualizado com source/ | PASS |

## Deviations from Plan

**1. [Observação] adapters/_scaffold/README.md — sem mudanças necessárias**
- O plano indicava atualizar linhas ~57-60 (árvore com skills/agents/hooks/templates). Verificação revelou que o arquivo já mostrava corretamente `source/` como diretório pai na árvore (nunca referenciou os dirs-raiz diretamente). Nenhuma edição necessária.

None significant — plan executed as written.
