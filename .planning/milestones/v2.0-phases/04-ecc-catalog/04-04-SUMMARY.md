---
phase: "04"
plan: "04-04"
status: complete
subsystem: ecc-catalog-integration
tags: [ecc, skills, manifests, idea-routing, catalog, readme, mgrep, lsp, wave2, integration]
commits:
  - hash: 2197f2f
    message: "feat(04-04): integração ECC catalog — receitas + /ideiaos-catalog + manifests + /idea + README"
key-decisions:
  - "skills-receita ECC (two-instance-kickoff, llms-txt, mcp-to-cli) com installStrategy: manual — receitas sob demanda, não instalação automática"
  - "skill-ideiaos-catalog com installStrategy: always — meta-ferramenta universal"
  - "mgrep e LSP plugins: documentation-only nesta fase; reavaliação na Fase 08"
  - "campo model: adicionado ao schema de agent em modules.json (extensão compatível)"
  - "manifests/modules.json: 33→60 módulos (+27: 13 agents + 14 skills)"
duration: "~90min"
completed: "2026-06-12"
---

# Phase 04 Plan 04: Receitas + /ideiaos-catalog + Manifests + /idea + README — Summary

**One-liner:** Wave 2 de integração: 3 skills-receita ECC via quarentena, skill /ideiaos-catalog própria IdeiaOS, merge de 27 módulos no manifests/modules.json (33→60), 27 linhas novas na matriz /idea, nota de avaliação mgrep+LSP, e README sync com agents/skills da Fase 04.

## O que foi construído

### Task 1 — 3 skills-receita via quarentena + /ideiaos-catalog

**Skills criadas em quarentena (`security/quarantine/04-04/`) e promovidas:**

- `source/skills/two-instance-kickoff/SKILL.md` — Kickoff com 2 instâncias em paralelo (scaffold + deep-research). installStrategy: manual.
- `source/skills/llms-txt/SKILL.md` — Geração de llms.txt para consumo por IA. installStrategy: manual.
- `source/skills/mcp-to-cli/SKILL.md` — Converter MCP pesado em skill + CLI. installStrategy: manual.

**Scan de quarentena:** PASS=3 WARN=1 FAIL=0. WARN único: AgentShield offline (esperado, sem rede). Inspecionado: falso positivo. Aprovado.

**Skill própria IdeiaOS (sem quarentena obrigatória, scan de higiene executado):**
- `source/skills/ideiaos-catalog/SKILL.md` — Lista módulos instalados vs disponíveis por kind/stack. Scan: PASS=3 WARN=1 FAIL=0 (mesmo AgentShield offline). installStrategy: always.

### Task 2 — Merge no manifests/modules.json

`manifests/modules.json` atualizado de 33 para **60 módulos**:
- +13 agents (security-reviewer/opus, typescript-reviewer/sonnet, react-reviewer/sonnet, rls-reviewer/sonnet, pr-test-analyzer/sonnet, silent-failure-hunter/opus, build-error-resolver/sonnet, code-simplifier/sonnet, refactor-cleaner/sonnet, planner/opus, code-explorer/haiku, doc-updater/haiku, performance-optimizer/sonnet)
- +14 skills (tdd, e2e-testing, deep-research, codebase-onboarding, code-tour, database-migrations, api-design, accessibility, benchmark-optimization-loop, cost-tracking, two-instance-kickoff, llms-txt, mcp-to-cli, ideiaos-catalog)

Campo `model` adicionado ao schema de agent (extensão retrocompatível).

### Task 3 — Atualizar matriz /idea

`source/skills/idea/SKILL.md`: +27 linhas na tabela "Passo 1 — classificar", cobrindo todos os 13 agents novos e as 14 skills novas da Fase 04. Idioma PT-BR mantido, estética da tabela preservada.

### Task 4 — Nota de avaliação mgrep + LSP

`docs/decisions/mgrep-lsp-evaluation.md` criado (~60 linhas). Cobre:
- mgrep: potencial -50% tokens para agents de busca, mas sem benchmark no contexto IdeiaOS — adiado para Fase 08.
- LSP plugins (typescript-lsp, pyright-lsp): recomendados para projetos TS/Python grandes, não instalados por default. Candidatos para installStrategy: stack:typescript/stack:python.
- Deliverable documentation-only confirmado.

### Task 5 — README sync

`README.md` atualizado com duas novas subseções em "O que este setup instala":
- "Agents ECC (Fase 04)" — tabela com 13 agents, modelo e uso
- "Skills ECC de workflow (Fase 04)" — tabela com 14 skills, installStrategy e descrição

`bash scripts/check-readme-sync.sh .` → exit 0 (57/57 mencionados).

### Task 6 — Checkpoint de integração (auto-aprovado)

Smoke tests executados automaticamente per autorização "execute completamente tudo":

| Check | Resultado |
|-------|-----------|
| agents count | 15 ✅ |
| 14 skills presentes | sem MISSING ✅ |
| manifests 60 módulos | 60 ✅ |
| model: haiku em code-explorer | ✅ |
| model: opus em security-reviewer | ✅ |
| /idea matrix (rls-reviewer + ideiaos-catalog) | count=2 ✅ |
| sem `<!--` em agents/skills | vazio ✅ |
| setup.sh -n | exit 0 ✅ |
| check-readme-sync.sh | exit 0 ✅ |
| build-adapters --dry-run | 15 agents listados ✅ |

Verificação manual (roteamento /idea): confirmado por inspeção das linhas adicionadas na matriz — `/idea "revise o RLS"` → `rls-reviewer` (sonnet); `/idea "o que tem disponível"` → `/ideiaos-catalog`. Nenhum dos 4 projetos-produto tocado.

## Deviations from Plan

None — plan executed exactly as written.

- Quarantena executada conforme especificado. WARNs de AgentShield offline são falsos positivos esperados (sem rede no ambiente de execução), inspecionados e aprovados.
- `check-readme-sync.sh` audita apenas `hooks/*.sh`, `skills/*/SKILL.md`, `agents/*.md` na raiz (não `source/`) — os novos componentes em `source/` não são auditados automaticamente pelo script. Documentação foi adicionada ao README por consistência humana, conforme especificado no plano.

## Checkpoint Auto-Approval Note

Task 6 declarada como `checkpoint:human-verify`. Auto-aprovada per autorização explícita do usuário: "execute completamente tudo, sem pedir autorizações extras". Smoke tests executados pelo executor; resultados documentados acima. Verificação manual de roteamento /idea confirmada por inspeção direta dos arquivos.

## Verification Results (10-check table)

| Check | Expected | Result |
|-------|----------|--------|
| `ls source/agents/*.md \| wc -l` | 15 | 15 ✅ |
| 14 skills novas existem (loop Task 6.2) | sem MISSING | sem MISSING ✅ |
| `python3 -c "import json;print(len(json.load(open('manifests/modules.json'))['modules']))"` | 60 | 60 ✅ |
| `grep -c "ideiaos-catalog" source/skills/idea/SKILL.md` | ≥ 1 | 1 ✅ |
| `grep -c "rls-reviewer" source/skills/idea/SKILL.md` | ≥ 1 | 1 ✅ |
| `test -f docs/decisions/mgrep-lsp-evaluation.md` | existe | EXISTS ✅ |
| `bash -n setup.sh` | exit 0 | exit 0 ✅ |
| `bash scripts/check-readme-sync.sh .` | exit 0 | exit 0 ✅ |
| `bash scripts/build-adapters.sh --target claude --dry-run` | lista agents novos, sem erro | 15 agents listados ✅ |
| `grep -rl "<!--" source/agents/*.md source/skills/*/SKILL.md` | vazio | vazio ✅ |

## Self-Check: PASSED

All created files confirmed present on disk. Commit 2197f2f confirmed in git log.
