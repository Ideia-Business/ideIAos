---
phase: 08-ideiaos-v3-review
plan: "01"
subsystem: agents
tags: [audit, agents, model-routing, v3-readiness]
requires: []
provides: [docs/v3/agents-audit.md]
affects: [source/agents/, manifests/modules.json]
tech_stack_added: []
tech_stack_patterns: [agent-frontmatter-schema]
key_files_created:
  - docs/v3/agents-audit.md
key_files_modified: []
decisions:
  - "7 agents OK, 6 AJUSTAR, 2 RETRABALHAR (ideiaos-checker e claude-continuation sem model:)"
  - "ideiaos-checker: filename vs name: inconsistencia — nome canonico a decidir em 08-04"
  - "Dois agents com directedness Medium (doc-updater, performance-optimizer) — ajuste de passo, nao retrabalho"
  - "security-reviewer e planner: opus justificado confirmado"
  - "react-reviewer e typescript-reviewer: sonnet com tools read-only — correto por raciocinio semantico acima de haiku"
metrics:
  duration_minutes: 18
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  completed_date: "2026-06-12"
---

# Phase 08 Plan 01: Auditoria dos 15 Agents Summary

Auditoria completa dos 15 agents em `source/agents/` para v3 readiness: role clarity, model routing, tools grant, usage boundaries e directedness do passo a passo.

## One-liner

Auditoria dos 15 agents: 7 OK / 6 AJUSTAR / 2 RETRABALHAR — gaps principais em dois agents sem `model:` declarado e inconsistencia de nome em `ideiaos-checker`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Inspect all 15 agent files | ae2dbea | source/agents/*.md (leitura) |
| 2 | Write docs/v3/agents-audit.md | ae2dbea | docs/v3/agents-audit.md |

## Verification Table

| Check | Command | Result |
|-------|---------|--------|
| Doc exists | `test -f docs/v3/agents-audit.md` | PASS |
| SOURCE header | `head -1 docs/v3/agents-audit.md` | `# SOURCE: IdeiaOS v2` |
| No HTML comment | `grep -c '<!--' docs/v3/agents-audit.md` | 0 |
| All 15 sections | `grep -c '^### ' docs/v3/agents-audit.md` | 15 |
| Tabela Final | `grep -c '## Tabela Final' docs/v3/agents-audit.md` | 1 |
| Verdicts | `grep -cE 'RETRABALHAR\|AJUSTAR' docs/v3/agents-audit.md` | 17 |
| Min lines | `wc -l docs/v3/agents-audit.md` | 414 (min: 120) |

## Decisions Made

- **Model routing confirmado:** haiku para read-only search (code-explorer, doc-updater); sonnet para code work com Edit/Bash (build-error-resolver, code-simplifier, refactor-cleaner, etc.); opus para high-stakes reasoning (planner, security-reviewer, silent-failure-hunter).
- **Dois agents RETRABALHAR:** `ideiaos-checker` (sem model:, sem tools:, inconsistencia de nome filename vs frontmatter `name:`); `claude-continuation` como AJUSTAR (sem model:, sem tools:, mas body bem estruturado).
- **Nota de auditoria:** `ideiaos-checker` foi classificado como RETRABALHAR (nao apenas AJUSTAR) porque acumula tres gaps simultaneos: model ausente + tools ausente + inconsistencia de nome.
- **react-reviewer e typescript-reviewer sonnet com tools read-only:** correto — revisao semantica de padroes exige raciocinio acima de haiku mesmo sem Edit/Bash.
- **rls-reviewer em sonnet (nao opus):** checklist de 6 items deterministicos; impacto de seguranca existe mas checklist mecanico e suficiente para sonnet.

## Deviations from Plan

### Incidental Commit: token-economy-review.md

**Found during:** Task 2 commit
**Issue:** `docs/v3/` era diretorio nao rastreado. Ao criar `docs/v3/agents-audit.md` e rodar `git add docs/v3/agents-audit.md`, o git incluiu `docs/v3/token-economy-review.md` (arquivo untracked pre-existente de executor concorrente 08-02) no mesmo commit.
**Impact:** Nao destrutivo — o arquivo ja existia no disco e precisava ser commitado. O conteudo e de outro plano (08-02) e esta integro.
**Commit:** ae2dbea (inclui ambos os arquivos)
**Acao futura:** Em v3, garantir que `docs/v3/` seja pre-criado ou rastreado antes dos planos Wave 1 para evitar agrupamento acidental de commits paralelos.

## Top-3 Achados

1. **claude-continuation e ideiaos-checker sem `model:`** — gap mais grave: custo e capacidade imprevisíveis. Ambos usam ferramentas nao declaradas no frontmatter (Bash implícito no corpo), criando contrato quebrado.

2. **ideiaos-checker: filename `ideiaos-checker.md` vs `name: setup-checker`** — inconsistência dupla que quebra rastreabilidade em `manifests/modules.json` (indexado por `name:`, instalado por filename). Decisao de nome canonico e obrigatoria antes de v3.

3. **Overlap nao documentado entre refactor-cleaner e code-simplifier** — ambos cobrem duplicacao sem linha de divisao clara. Risco de uso incorreto em producao; resolucao proposta: `code-simplifier` para complexidade semantica, `refactor-cleaner` para residuos estruturais.

## Self-Check: PASSED

- docs/v3/agents-audit.md existe: CONFIRMED
- Commit ae2dbea existe: CONFIRMED
- 15 secoes `###`: CONFIRMED (15)
- SOURCE header linha 1: CONFIRMED
- Sem HTML comments: CONFIRMED (0)
