---
name: project-lovable-mcp-v10-candidate
description: "Lovable lançou um MCP server (OAuth, full-account, ~47 tools, DB-prod, agente Cloud); existe um plano v10-candidato 'read-first' vetado em docs/research/2026-06-17-lovable-mcp-integration-plan.md; decisão atual = só discutir/afiar (nada implementado)"
metadata:
  node_type: memory
  type: project
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

A Lovable lançou um **MCP server** (`https://mcp.lovable.dev`, **OAuth-only**, escopo de **conta inteira**)
que dá a Claude/Cursor uma API com ~47 tools sobre a plataforma: dirigir o **agente Cloud** da Lovable
(`send_message`/`plan_mode`), ler código em qualquer ref (`get_diff`/`list_edits`/`read_file`), rodar SQL no
**DB de produção** (`query_database`), publicar (`deploy_project`), analytics, e gerir Project/Workspace
**Knowledge** + Workspace **Skills**. O usuário já conectou no Claude Desktop e Cursor.

**Plano completo e durável (NÃO perder):** `docs/research/2026-06-17-lovable-mcp-integration-plan.md`
(+ `…-synthesis.json` verbatim). Vetado por 9 agentes (workflow `wf_a9c61aa5-2bf`). Veredito: **adotar
ADITIVO ao `/lovable-handoff` (nunca substituir), "read-first", contenção REAL no harness
(`permissions.deny`/`ask` no `.claude/settings.json`, NÃO em prosa de skill), `@devops` p/ mutações; piloto
read-only no cfoai; todo write-path DEMOVIDO até um experimento em sandbox (`remix_project`) medir o
comportamento do sync GitHub↔Cloud.** v1 = skill `source/skills/lovable-mcp/` com 3 verbos read-only:
`verify-deploy` (deploy-drift), `detect-hotfix` (hotfix inline não-sincronizado), `schema-check` (SQL fixo no
DB-prod) — resolvem os 3 padrões de debugging em produção do `deployment-protocol.md`.

**Por que importa / cuidados não-óbvios:**
- **Dois escritores** no mesmo repo: o agente Cloud da Lovable edita os produtos **dezenas de vezes/dia**
  (nfideia 1.709 / ideiapartner 2.616 edits) em paralelo ao plano-GitHub do IdeiaOS. Colisão é aguda →
  qualquer **escrita** começa num **fork (`remix_project`)**, nunca em prod. Ver [[feedback-lovable-projects-branch-commit]].
- **Blast-radius:** 1 token OAuth alcança ~1.640 projetos (inclui workspace de 1.622). Contenção real só
  existe no **painel Lovable** (token por-workspace / desabilitar third-party MCP) — allowlist client-side é
  secundária. Pela `mcp-hygiene` o servidor é High/Critical → **off por default**, on-demand.
- **Suposição que trava a escrita (não-medida):** o `commit_sha` do MCP é do mirror GitHub ou do repo
  Lovable interno? `deploy_project` lê de `main` ou do estado Cloud? Medir num fork antes de qualquer write.
- Produtos reais (workspace "Gustavolpaiva Dev"): nfideia `bf83d98a-…`, ideiapartner `afce7743-…`,
  cfoai-grupori `0e911cfd-…`, ideia-partner-hub `748a31c2-…`.

**Decisão da sessão (2026-06-17):** usuário escolheu **"só discutir/afiar o plano"** — nada implementado.
4 forks abertos (A contenção blast-radius / B v1 fina / C skill nova vs handoff / D dois cérebros).
Relaciona-se a [[project-aiox-core-pristine-overlay]] (overlay/pristine) e ao milestone [[project-milestone-v9-completo]].
