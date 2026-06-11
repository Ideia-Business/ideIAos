# Roadmap — IdeiaOS v2: Canivete Suíço Universal

**Milestone:** v2.0 — Absorção ECC + transformação multi-harness
**Criado:** 2026-06-11 (importado do plano aprovado)

## Fases

### Fase 01 — Hooks de Qualidade + Memória `01-quality-memory-hooks`

**Goal:** Erros aparecem em segundos (não no commit) e o estado de sessão sobrevive a /compact automaticamente.

- `typecheck-on-edit.sh` (PostToolUse .ts/.tsx): tsc --noEmit incremental
- `console-log-guard.sh` (PostToolUse): alerta console.log
- `precompact-state-save.sh` (PreCompact): snapshot automático em STATE.md
- `session-summary.sh` (Stop): sessão em ~/.claude/sessions/YYYY-MM-DD-<topico>.tmp (padrão ECC) + CONTINUATION_HANDOFF.md
- `strategic-compact.sh` (PreToolUse contador): sugere /compact a cada ~50 tool calls

**Depends on:** —
**Success:** editar .ts com erro → aviso em segundos; /compact → snapshot no STATE.md; 50 tool calls → sugestão.

**Plans:** 4 plans (3 em paralelo na Wave 1, integração + checkpoint na Wave 2)

Plans:
- [ ] 01-PLAN-01.md — Harness de smoke test + console-log-guard + strategic-compact (Wave 1)
- [ ] 01-PLAN-02.md — precompact-state-save + session-summary (Wave 1)
- [ ] 01-PLAN-03.md — typecheck-on-edit (async + asyncRewake) (Wave 1)
- [ ] 01-PLAN-04.md — setup.sh deploy + README sync + harness final + checkpoint de validação (Wave 2)

### Fase 02 — Security Baseline + Pipeline de Quarentena `02-security-quarantine`

**Goal:** Nenhum conteúdo de terceiros entra sem scan; config do próprio IdeiaOS auditada. PRÉ-REQUISITO das fases 04-06.

- Deny rules baseline nos templates settings.json (~/.ssh, ~/.aws, .env, curl|bash, nc)
- `security/scan-absorbed.sh`: greps unicode invisível + payloads + comandos suspeitos + AgentShield
- Guardrail anti-injection padrão para links externos em skills
- Memory hygiene como regra formal
- idea-doctor += auditoria de config (secrets, permissions, injection, MCP risk, agent config)
- Kill-switch/heartbeat no autosync LaunchAgent

**Depends on:** —
**Success:** scan-absorbed.sh detecta payload de teste; idea-doctor reporta config insegura.

**Plans:** 4 plans (3 em paralelo na Wave 1, README sync + checkpoint na Wave 2)

Plans:
- [ ] 02-01-PLAN.md — Pipeline de quarentena scan-absorbed.sh + staging dir (Wave 1)
- [ ] 02-02-PLAN.md — Deny rules baseline (Patch 10) + idea-doctor Seção 7 Security Audit (Wave 1)
- [ ] 02-03-PLAN.md — Kill-switch LaunchAgent (timeout) + memory-hygiene doc (Wave 1)
- [ ] 02-04-PLAN.md — README sync + smoke test integrado + checkpoint (Wave 2)

### Fase 03 — Arquitetura Multi-Harness + Rules Layer `03-multiharness-rules`

**Goal:** Fonte única (`source/`) compila para Claude e Cursor; rules de 18 stacks + nossas regras Supabase/Lovable; fim do drift entre IDEs.

- Migrar skills/agents/hooks/templates → `source/` (compat com setup.sh)
- `manifests/modules.json` (formato ECC: id, kind, targets, deps, installStrategy)
- Absorver `rules/` do ECC (via quarentena): common/ + 18 stacks
- Regras próprias: rules/supabase/, rules/lovable/, token-economy.md, mcp-hygiene.md, orchestration.md
- `scripts/build-adapters.sh` + `adapters/_scaffold/`
- Detecção de stack por projeto no setup

**Depends on:** 02
**Success:** build-adapters.sh → mesma regra no CLAUDE.md e .mdc; projeto Python ganha rules Python, Lovable não.

### Fase 04 — Catálogo ECC: Skills + Agents com Model Routing `04-ecc-catalog`

**Goal:** ~15 agents e ~20 skills do ECC adaptados ao IdeiaOS, todos com model routing e atribuição MIT; /idea roteia para eles.

- Agents: build-error-resolver, silent-failure-hunter, code-simplifier, refactor-cleaner, planner, code-explorer, doc-updater, pr-test-analyzer, performance-optimizer, security-reviewer, typescript-reviewer, react-reviewer, rls-reviewer (database-reviewer + checklist do vault)
- Model routing (`model:` frontmatter): haiku/sonnet/opus
- Skills: tdd, e2e-testing, deep-research, codebase-onboarding, code-tour, database-migrations, api-design, accessibility, benchmark-optimization-loop, cost-tracking
- Receitas dos guias: two-instance-kickoff, llms-txt, conversão MCP→CLI
- Matriz /idea atualizada + skill /ideiaos-catalog
- Avaliar mgrep + LSP plugins

**Depends on:** 02, 03
**Success:** /idea "revise o RLS" → rls-reviewer (sonnet); agent de busca roda em haiku; /ideiaos-catalog lista módulos.

### Fase 05 — Continuous Learning v2: Fase A Automática `05-instincts`

**Goal:** 100% das sessões geram observações; instincts com confidence; /evolve promove ao vault. Resolve memória compartilhada entre IDEs.

- Hooks de observação → ~/.ideiaos/observations/<projeto>/observations.jsonl
- /instinct-analyze (agente haiku background) → instincts atômicos
- ~/.ideiaos/instincts/ sincronizado multi-máquina
- /learn (extração manual mid-session)
- /evolve → Learnings/ no vault ou source/rules/
- recall-learnings Passo 6 + extract-learnings como curadoria

**Depends on:** 01
**Success:** sessão normal → observations.jsonl cresce; /instinct-status lista; /evolve gera Learning no vault.

### Fase 06 — Plugin + Marketplace Privado `06-plugin-marketplace`

**Goal:** Máquina nova instala IdeiaOS via /plugin marketplace add + install, versionado com update nativo.

- .claude-plugin/marketplace.json + plugin.json
- setup.sh permanece para bootstrap de máquina
- Sub-plugins por perfil: ideiaos-core, ideiaos-design-suite, ideiaos-lovable

**Depends on:** 03
**Success:** máquina limpa → /plugin marketplace add Ideia-Business/IdeiaOS + install → IdeiaOS funcional.

### Fase 07 — Contexts Dinâmicos + Eval Loops `07-contexts-evals`

**Goal:** Modos dev/review/research via --system-prompt; suite de evals a partir de incidentes reais.

- source/contexts/: dev.md, review.md, research.md
- Aliases claude-dev, claude-review, claude-research no setup
- Eval roadmap: 20-50 test cases de incidentes reais (INC-3xx ideiapartner, bugs NFideia); pass@k / pass^k; integrar ao gsd-verify-work
- Statusline padrão IdeiaOS

**Depends on:** 03
**Success:** claude-review abre em modo review; suite de evals roda contra 20+ casos reais.

### Fase 08 — Revisão IdeiaOS v3: Gaps + UX dos Agentes + Otimização de Tokens `08-ideiaos-v3-review`

**Goal:** Após completar as 7 fases, auditar o IdeiaOS v2 como um todo e identificar lacunas de melhoria para a v3 — com foco em: (a) passo a passo bem direcionado de cada subagente e skill, (b) uso correto e otimizado de tokens e modelos por ação, (c) novas gaps identificadas durante a absorção ECC.

- Auditoria de todos os agentes absorvidos: modelo correto por agente? role bem definido? quando usar vs. não usar?
- Guia de uso de cada skill: sequência recomendada, anti-patterns, exemplos canônicos
- Token economy review: quais ações consomem tokens desnecessariamente? onde trocar haiku/sonnet/opus?
- Gaps de orquestração: fluxos que o IdeiaOS ainda não cobre bem
- Documento `/ideiaos-v3-roadmap` gerado como output

**Depends on:** 04, 05, 06, 07 (todas as fases completas)
**Success:** Documento v3-review.md com ≥10 gaps priorizados + matriz modelo/ação atualizada + guia de uso dos agentes.

## Ordem de execução

01 e 02 podem rodar em paralelo → 03 → 04 (e 05 após 01; 06 e 07 após 03) → 08 (após todas).

| Fase | Esforço | Valor |
|---|---|---|
| 01 | Baixo | Alto |
| 02 | Baixo | Crítico (pré-req) |
| 03 | Alto | Estrutural |
| 04 | Médio | Alto |
| 05 | Alto | Transformacional |
| 06 | Médio | Alto |
| 07 | Baixo | Médio |
| 08 | Médio | Estratégico (v3) |

## Plans

### Fase 01 — quality-memory-hooks (4 plans, 2 waves)

| Plan | Wave | Objetivo | Tasks |
|------|------|----------|-------|
| 01-PLAN-01 | 1 | Harness smoke test + console-log-guard + strategic-compact | 3 |
| 01-PLAN-02 | 1 | precompact-state-save + session-summary | 2 |
| 01-PLAN-03 | 1 | typecheck-on-edit (async) | 1 |
| 01-PLAN-04 | 2 | setup.sh deploy + README sync + harness final + checkpoint | 3 |

Demais fases: usar /gsd-plan-phase por fase.
