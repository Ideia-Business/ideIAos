---
name: project-lovable-mcp-v10-candidate
description: "Integração Lovable MCP (milestone v10): Fase A (v1 read-only) SHIPPED 2026-06-18 — skill /lovable-mcp (verify-deploy + detect-hotfix) + helper source/lib/lovable-mcp.sh + harness-deny de 19 tools mutantes + rule mcp-protocol.md; gates verdes + verificação adversarial 4 lentes PASSED. Pendente: rollout operacional (deny nos produtos + toggle workspace) + Fase B (sandbox, gate de escrita). read-first, aditiva, contenção 2 níveis; 4 forks fechados via /grelha"
metadata:
  node_type: memory
  type: project
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

A Lovable lançou um **MCP server** (`https://mcp.lovable.dev`, **OAuth-only**, escopo de **conta inteira**,
~47 tools): dirigir o **agente Cloud** (`send_message`), ler código em qualquer ref (`get_diff`/`list_edits`),
rodar SQL no **DB de produção** (`query_database`), publicar (`deploy_project`), gerir Knowledge/Skills do
agente Cloud. Já conectado no Claude Desktop, Cursor e nesta sessão (server id `6f530143-…`).

**Status: Fase A (v1 read-only) SHIPPED 2026-06-18** (commit `409066a`; R10-01..05 = DONE, 25% do v10).
Entregue: skill `source/skills/lovable-mcp/SKILL.md` (`verify-deploy` cruza commit da Cloud × `origin/main`;
`detect-hotfix` cruza `list_edits` × git local — só reporta, candidato ≠ certeza por causa do namespace
não-medido da Fase B); helper `source/lib/lovable-mcp.sh` (gateado por `gates.sh`, verdicts binários
IN_SYNC/CLOUD_BEHIND/CLOUD_AHEAD/SHA_ABSENT/NO_REPO + resolver de escopo + parser YAML de `lovable-scope.yaml`;
testado em sandbox git); harness-deny de **19 tools mutantes** + `query_database` deny PURO + `disabledMcpServers`
no `.claude/settings.json`; rule `source/rules/lovable/mcp-protocol.md`; empacotamento completo + cross-link no
`/lovable-handoff`. **Verificação adversarial (workflow `wf_e0d15139-74a`, 4 lentes): deny-completeness CLEAN,
read-only-integrity CLEAN; helper/packaging com achados — TODOS corrigidos** (parser awk dash-coluna-0 + `#`
entre aspas; exit-codes; shallow-clone com aviso stderr; contagem README=46). **Pendente:** rollout operacional
(aplicar deny nos produtos + desligar `mcp_enabled` nos 2 workspaces não-dev) + **Fase B** (sandbox `remix_project`
= gate de TODA escrita). Lapidado via `/grelha` (4 forks). Artefatos de planejamento:
`.planning/milestones/v10-{REQUIREMENTS,ROADMAP}.md`, ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md`,
dossiê `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json`; workflow `wf_a9c61aa5-2bf`).

**Decisões dos 4 forks (o que mudou vs a síntese original):**
- **A — contenção em DOIS níveis:** operacional = escopo é a **pasta "Grupo Ideia"** no workspace
  **"Grupo Ideia - Dev"** (`2NHPnABxF0jdSX3qVLCw`, renomeado de "Gustavolpaiva Dev"), resolvido dinamicamente
  via `list_projects(folder_id)` (substitui "4 IDs hardcoded"); duro = desligar o toggle `mcp_enabled` (existe
  por-workspace) nos 2 workspaces não-dev ("Grupo IDeia - Projects" 1.622 + "Dev's Lovable") + harness-deny.
  Caveat: pasta NÃO é fronteira de segurança na Lovable (token full-account) → folder-scope é skill-enforced.
- **B — v1 SEM schema-check:** v1 = só `verify-deploy` + `detect-hotfix` (100% git-read). `query_database` em
  **deny PURO** → v1 incapaz de tocar o DB. `schema-check` (SQL fixo) → v2.
- **C — skill nova `/lovable-mcp`** (não estender `/lovable-handoff`). CLI descartado: Lovable é OAuth-only,
  sem API key → tem que ser skill no client MCP (regra `mcp-to-cli` não se aplica).
- **D — dois cérebros: sim, faseado/medido** — teste MANUAL de `set_project_knowledge` em 1 produto (v2, com
  backup) antes de construir o compilador (v3).

**Escada de fases:** A (v1 read-only, buildável já, não depende de nada) ; B (sandbox `remix_project` = gate
de TODA escrita, mede o timing/namespace do mirror GitHub↔Cloud) → C (v2: schema-check + teste dos dois
cérebros) → D (v3: write-path + compilador source→Knowledge).

**Cuidados não-óbvios:** dois escritores no mesmo repo (agente Cloud edita nfideia/ideiapartner dezenas/dia)
→ qualquer escrita começa num fork; produtos reais em "Grupo Ideia - Dev": nfideia `bf83d98a-…`, ideiapartner
`afce7743-…`, cfoai `0e911cfd-…`, ideia-partner-hub `748a31c2-…`. Suposição que trava a escrita (não-medida):
o `commit_sha` é do mirror GitHub ou do repo Lovable interno? `deploy_project` lê de main? (`gitsync_github:
true` confirmado nos 3 workspaces). **Próximo concreto:** construir a Fase A; pré-condições do usuário no
painel = desligar `mcp_enabled` nos 2 workspaces não-dev + passar o `folder_id` da pasta.

**Modelo de acesso (refinado via /grelha 2026-06-18, FOLD no v10 R10-02/03):** 2 tiers — `todos` (pasta
"Grupo Ideia") + `pessoal:<dono>` (`created_by`); **operacional** (escopo/foco do IdeiaOS, NÃO privacidade
dura — privacidade real = `visibility: draft` manual fora do modelo); resolução derivada `in_scope = (na
pasta) OU (created_by==get_me.id)` + `lovable-scope.yaml` só p/ exceções; identidade = conta Lovable
(gustavolpaiva@gmail.com ≠ git redeideia); **SEM** sistema de tokens (Lovable é OAuth-only); painel-UI
deferido (v11). cfoai = pessoal:gustavo (fora da pasta). Folder "Grupo Ideia" id `fold_01kvdc18tgf86ts7s0tdx6hges`.

Relaciona-se a [[project-aiox-core-pristine-overlay]] (overlay/pristine) e [[feedback-lovable-projects-branch-commit]].
