---
phase: "13-security-dx-manifest"
plan: "03"
subsystem: "dx-tooling"
tags: ["apply-to-all-projects", "multi-repo", "setup-propagation", "modules-json"]
dependency_graph:
  requires: []
  provides: ["script-apply-to-all-projects", "modules-json-72"]
  affects: ["scripts/apply-to-all-projects.sh", "manifests/modules.json", "README.md"]
tech_stack:
  added: []
  patterns: ["dry-run-default", "realpath-exclusion", "no-jq"]
key_files:
  created: ["scripts/apply-to-all-projects.sh"]
  modified: ["manifests/modules.json", "README.md"]
decisions:
  - "Dry-run DEFAULT por segurança — --apply requer intenção explícita"
  - "Exclui IdeiaOS via realpath comparison — não toca o próprio repo"
  - "Itera ~/dev/* 1 nível de profundidade apenas (não recursivo)"
  - "Script NÃO adicionado como módulo plugin-buildable — é wrapper manual (installStrategy: manual)"
metrics:
  completed_date: "2026-06-12"
---

# Phase 13 Plan 03: apply-to-all-projects.sh Summary

Novo script `scripts/apply-to-all-projects.sh` que propaga `setup.sh --project-only` a todos os repositórios git em `~/dev/`, fechando G-09/R3-19. Dry-run por padrão; `--apply` executa; `--only` filtra por nome.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Criar apply-to-all-projects.sh | 6e31fcc | scripts/apply-to-all-projects.sh |
| 2 | Registrar em modules.json e README.md | 6e31fcc | manifests/modules.json, README.md |

## Verification Results

```
bash -n scripts/apply-to-all-projects.sh  # syntax OK
bash scripts/apply-to-all-projects.sh --dry-run:
  Projetos detectados em ~/dev (dry-run):
  ⊙ Jarvis, cfoai-grupori, ideiapartner, lapidai, nfideia
  5 projeto(s) detectado(s).

modules.json: OK (72 módulos, entry script-apply-to-all-projects presente)
README.md: 2 menções a apply-to-all-projects
check-readme-sync: 92/92 — README sincronizado
```

## Deviations from Plan

**[Rule 3 - Arg Parsing Fix]** O template do plano usava `for arg in "$@"; do ... shift` que não é compatível com `shift` dentro de `for`. Implementado com loop `while [ "$i" -le "$#" ]` + eval, mantendo a mesma semântica de flags. Sem impacto no comportamento externo.

## Self-Check: PASSED

- `scripts/apply-to-all-projects.sh` — FOUND (criado)
- `manifests/modules.json` — FOUND com "script-apply-to-all-projects" (72 módulos)
- `README.md` — FOUND com 2 menções a "apply-to-all-projects"
- Commit 6e31fcc — FOUND in git log
