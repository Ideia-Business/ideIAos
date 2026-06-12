---
phase: "03"
plan: "03-03"
subsystem: rules-layer
tags: [rules, supabase, lovable, token-economy, mcp-hygiene, orchestration, wave1]
dependency_graph:
  requires: [source-migration, manifests-stack-detection]
  provides: [rules-common, rules-supabase, rules-lovable]
  affects: [build-adapters]
tech_stack:
  added: []
  patterns: [SOURCE-header-tracing, rule-injection-via-build-adapters]
key_files:
  created:
    - source/rules/common/token-economy.md
    - source/rules/common/mcp-hygiene.md
    - source/rules/common/orchestration.md
    - source/rules/supabase/rls-patterns.md
    - source/rules/lovable/deployment-protocol.md
    - source/rules/ecc/.gitkeep
  modified: []
decisions:
  - "source/rules/ecc/ permanece como placeholder vazio — será populado no 03-04 após absorção via quarentena ECC"
  - "Header <!--SOURCE: IdeiaOS v2 | kind: rule | targets: ...--> em todos os arquivos para rastreabilidade pelo build-adapters.sh"
metrics:
  duration: "3 min"
  completed_date: "2026-06-12"
  tasks_completed: 7
  files_created: 6
---

# Phase 03 Plan 03: Rules Layer (Supabase, Lovable, Common) Summary

**One-liner:** 5 rule files + 1 placeholder criados em `source/rules/` com headers SOURCE para injeção via `build-adapters.sh` — common (token-economy, mcp-hygiene, orchestration), supabase/rls-patterns, lovable/deployment-protocol.

## What Was Built

Camada `source/rules/` criada com 4 subdirs e 5 arquivos de regras operacionais:

### source/rules/common/ (3 arquivos)

| Arquivo | Origem | Conteúdo |
|---------|--------|----------|
| `token-economy.md` | Guias Shorthand CC + Longform CC | Model routing (haiku/sonnet/opus), MCP→CLI, lean codebase, strategic compact |
| `mcp-hygiene.md` | Guia Agentic Security + Shorthand CC | Limite ≤30 MCPs, tabela de risco, checklist audit |
| `orchestration.md` | Guia Longform CC | Iterative retrieval, sequential phases, parallelization, wave-based execution |

### source/rules/supabase/ (1 arquivo)

`rls-patterns.md` — checklist RLS completo + padrões SQL de auth (uid, custom claim) + gotchas (push sem preview, realtime, storage.objects, Edge Functions).

### source/rules/lovable/ (1 arquivo)

`deployment-protocol.md` — checklist pré-push, sync Cursor↔Lovable via `/lovable-handoff`, gotchas Vite/ESM, Tailwind purge, Supabase client singleton.

### source/rules/ecc/ (placeholder)

`.gitkeep` vazio — será populado em 03-04 após quarentena das rules ECC.

## Deviations from Plan

### Deviation: Commit feito via autosync em vez de commit manual

- **Found during:** Task 7 (commit)
- **Issue:** O LaunchAgent autosync fez commit automático dos arquivos `source/rules/` com mensagem `wip: autosync 2026-06-11 22:23` antes da execução do commit manual planejado
- **Resolution:** Conteúdo está commitado corretamente em `ebcfc06`. Nenhuma ação adicional necessária — os arquivos estão no estado correto.
- **Commit:** ebcfc06

## Verification Results

| Check | Status |
|-------|--------|
| `ls source/rules/` → common/ supabase/ lovable/ ecc/ | PASS |
| `ls source/rules/common/` → 3 arquivos .md | PASS |
| `grep "SOURCE: IdeiaOS" token-economy.md` | PASS |
| `grep "RLS" supabase/rls-patterns.md` | PASS |
| `grep "lovable-handoff" lovable/deployment-protocol.md` | PASS |
| `ls source/rules/ecc/.gitkeep` | PASS |

## Self-Check: PASSED

- source/rules/common/token-economy.md: FOUND
- source/rules/common/mcp-hygiene.md: FOUND
- source/rules/common/orchestration.md: FOUND
- source/rules/supabase/rls-patterns.md: FOUND
- source/rules/lovable/deployment-protocol.md: FOUND
- source/rules/ecc/.gitkeep: FOUND
- Commit ebcfc06: FOUND (autosync)

## Known Stubs

Nenhum — todas as regras têm conteúdo operacional completo. `source/rules/ecc/` é um placeholder intencional documentado para 03-04.

## Threat Flags

Nenhuma nova superfície de rede, auth path ou schema introduzida — apenas arquivos Markdown de regras.
