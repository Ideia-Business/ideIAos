---
gsd_state_version: 1.0
milestone: v10
milestone_name: Camada de Integração Lovable MCP
status: partial
last_updated: "2026-06-19"
progress:
  total_phases: 4
  completed_phases: 2
  total_plans: 4
  completed_plans: 2
  percent: 50
---

# State — IdeiaOS

**Atualizado:** 2026-06-19

## Snapshot

| Item | Status |
|------|--------|
| v2.0/v3/v4 (plano maior ECC) | ✅ SHIPPED |
| v5 (memória cross-IDE) | ✅ SHIPPED |
| v6 (Resiliência + Marketing + GSD/OpenSpec) | ✅ SHIPPED 2026-06-16 — 9 fases, tag v6.0 |
| v7 (Delta-Spec Brownfield + Robustez de Empacotamento) | ✅ SHIPPED 2026-06-16 — 4 fases, tag v7.0 |
| **v8 (Camada de Disciplina)** | ✅ **SHIPPED 2026-06-16** — tag v8.0: `/doubt` + rule `operating-discipline` + `/context-engineering` + opt-in `/observability`/`/deprecation-migration`. |
| **v9 (Camada de Alinhamento)** | ✅ **SHIPPED 2026-06-17** — tag v9.0: absorção de `mattpocock/skills` (MIT) — `/grelha` (grilling pré-plano) + glossário `CONTEXT.md` + rule `ubiquitous-language` + ADR inline + Passo 1.5 na Deia + `/improve-architecture` (deepening). 6 fases, auditoria PASSED, dogfood `/doubt` = SHIP. |
| **v10 (Camada de Integração Lovable MCP)** | 🟡 **FECHADO EM ESCOPO PARCIAL (2026-06-18/19)** — read-only SHIPPED+validado; write-path BLOQUEADO por evidência; C/D PARQUEADAS-GATED (sem tag). **Fase A** SHIPPED + **validada e2e** (`verify-deploy` → `IN_SYNC` contra nfideia real, 2026-06-19); deny=19 PERSISTIDO em 5/5 alvos. **Fase B** EXECUTADA — veredito 🔴 **bloquear `publish` via MCP** (MCP não expõe gitsync → A1-lag/A2 inmensuráveis; indeterminado-vota-bloquear). **C/D** parqueadas atrás de R10-06 até medir A2 fora do MCP. Ver `.planning/v10-MILESTONE-AUDIT.md`. |

## Milestone atual — v10: Camada de Integração Lovable MCP

**Goal:** Somar ao plano-GitHub maduro (`/lovable-handoff`) uma camada de **verificação programática** via o MCP server da Lovable, de forma **ADITIVA e read-first**, com **contenção real** (harness-deny + toggle de workspace + folder-scope dinâmico) e `@devops` para mutações. Lapidado via `/grelha` (4 forks fechados). Postura em `docs/decisions/v10-lovable-mcp-readfirst-containment.md`.

**Fases (grafo: A independente, buildável já; B → C → D, onde B é o gate de toda escrita):**

| Fase | Objetivo | Cobre | Status |
|------|----------|-------|--------|
| A — v1 read-only (skill `/lovable-mcp`: verify-deploy + detect-hotfix) | mata incidentes nº1 (deploy-drift) e nº3 (hotfix inline); 0 crédito, 0 escrita | R10-01..05 | ✅ SHIPPED 2026-06-18 + validado e2e (`IN_SYNC`) 2026-06-19 |
| B — Sandbox (gate de toda escrita) | mede suposições do mirror GitHub↔Cloud via `remix_project` | R10-06 | ✅ EXECUTADA 2026-06-18 — veredito 🔴 BLOQUEAR publish (A2 inmensurável no MCP) |
| C — v2: schema-check + teste manual dos dois cérebros | schema-first seguro (SQL fixo) + mede efeito do `set_knowledge` | R10-07 | ⏸️ PARQUEADA-GATED (atrás de R10-06) |
| D — v3: write-path + compilador de governança | drive-cloud-agent/publish (gated) + compilador source→Knowledge | R10-08 | ⏸️ PARQUEADA-GATED (atrás de R10-06) |

**Escopo (refinado via `/grelha`):** resolver identity-aware **operacional** — 2 tiers `todos` (pasta "Grupo Ideia", `folder_id fold_01kvdc18tgf86ts7s0tdx6hges`, workspace `2NHP…`) + `pessoal:<dono>` (`created_by`); `in_scope = na-pasta OU created_by==get_me.id`; override `lovable-scope.yaml`; é foco do IdeiaOS, não privacidade. **Pré-condição do usuário (painel, ~1 min):** desligar `mcp_enabled` nos 2 workspaces não-dev (o `folder_id` já foi obtido).

**Planejamento detalhado:** `.planning/milestones/v10-{REQUIREMENTS,ROADMAP}.md` + dossiê `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json` verbatim).

### v9 (Camada de Alinhamento) — ✅ SHIPPED 2026-06-17 (tag v9.0)
6 fases A–F + G could-haves; auditoria PASSED; dogfood `/doubt` = SHIP. Planejamento em `.planning/milestones/v9-*`.

## Decisões Tecnicas Canonicas

### GSD — Linhagem Definitiva
- Usamos `@opengsd/get-shit-done-redux@1.1.0` (linha VIVA/estável, org open-gsd).
- redux 1.x ≠ gsd-pi 3.x (produto diferente, NÃO migrar). open-gsd ≠ gsd-build (legado).
- versions.lock blindado (fase 28); guards anti-Pi-drift em check-versions-lock.sh + idea-doctor.sh.

## Próximo passo

**Milestone v10 — Fase A (v1 read-only) SHIPPED 2026-06-18.** Skill `/lovable-mcp` (`verify-deploy` + `detect-hotfix`), helper `source/lib/lovable-mcp.sh` (gateado por `gates.sh`, testado em sandbox), resolver de escopo identity-aware, harness-deny de 19 tools mutantes (+ `query_database` deny puro) no `.claude/settings.json`, rule `source/rules/lovable/mcp-protocol.md`, empacotamento completo (build-plugins/modules.json/plugin-membership/README) e cross-link no `/lovable-handoff`. Gates verdes; verificação adversarial de 4 lentes PASSED após fixes (parser awk, exit-codes, shallow-clone, contagem README). R10-01..05 = DONE.

**Estado atual (2026-06-19):** Fase A **rollout COMPLETO** — deny=19 em 5/5 alvos (regressão 2/5 remediada+persistida 06-18) + `verify-deploy` validado e2e contra nfideia (`IN_SYNC`) + toggles de painel feitos. Fase B **EXECUTADA** — veredito 🔴 bloquear publish via MCP. **Não há próximo passo acionável no v10:** Fases C/D estão PARQUEADAS-GATED por design (write-path bloqueado até medir A2 fora do MCP — gitsync manual na UI). Reabrir só com apetite explícito por write-path.

_v9 (Camada de Alinhamento) SHIPPED 2026-06-17, tag v9.0 — 7 requisitos, auditoria PASSED, dogfood `/doubt` = SHIP._

**Fechamento operacional (2026-06-17):** tag `v9.0` empurrada para `origin`; LOW do dogfood resolvido (README esclarece que `scan-absorbed.sh` mira a quarentena, não `source/`); branch `planning` sincronizado com os docs de milestone v9 via git plumbing (memory store preservado); **`main` reconciliada** com `work` por fast-forward (IdeiaOS vai direto na main); **validador YAML antifrágil** (`scripts/validate-agent-yaml.sh`, parser autoritativo js-yaml) wired no `idea-doctor` + Patch 14 (rollback). Aprendizado extraído (`docs/learnings/2026-06-17-git-plumbing-partial-branch-overlay-sync.md` → memória global + vault Obsidian) + Changelog do vault atualizado para v9. **Nada pendente no repo** — `main`=`work`=`origin`.

## Pendências (opt-in, decisão do usuário)
- **Lovable MCP (v10) — write-path C/D PARQUEADO-GATED:** Fase A SHIPPED+validado e rollout completo (deny 5/5 + verify-deploy `IN_SYNC`); Fase B executada (veredito 🔴 bloquear publish). C/D só reabrem com apetite por write-path E medição de A2 fora do MCP. Docs: `.planning/v10-MILESTONE-AUDIT.md` + ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md`.
- ✅ Piloto /spec (delta-spec) no nfideia — **RESOLVIDO 2026-06-19**: specs portadas p/ main via PR [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (MERGED, doc-only); branch stale `spec/multi-tenancy-pilot` não arrastada.
- gsd-browser: reavaliar quando publicar npm/crates (ADR docs/decisions/) — aguarda upstream.
- DeepSeek V4 Pro: habilitar nos PRODUTOS (cfoai/nfideia etc.), fora do escopo IdeiaOS.

## Compact Snapshot

**Auto-saved:** 2026-06-21 00:23 (PreCompact hook, trigger: manual)

- Snapshot automático antes do /compact.
- Detalhes da sessão em ~/.claude/sessions/ (session-summary hook).
