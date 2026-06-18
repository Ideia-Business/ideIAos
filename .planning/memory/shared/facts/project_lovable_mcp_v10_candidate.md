---
name: project-lovable-mcp-v10-candidate
description: "Integração Lovable MCP (milestone v10): Fase A (v1 read-only) SHIPPED 2026-06-18 — skill /lovable-mcp (verify-deploy + detect-hotfix) + helper source/lib/lovable-mcp.sh + harness-deny de 19 tools mutantes + rule mcp-protocol.md; gates verdes + verificação adversarial 4 lentes PASSED. ROLLOUT lado-agente FEITO 2026-06-18 (deny+disabledMcpServers nos 4 produtos: nfideia/ideiapartner/cfoai/lapidai, validado binário deny=19). Toggles de painel FEITOS (só 1 workspace no alcance); pendente SÓ rodar /lovable-mcp verify-deploy num produto real. **Fase B (sandbox) CONCLUÍDA 2026-06-18: veredito BLOQUEAR publish via MCP** — A1-namespace=ACOPLADO + A3=PASS (read-only), mas A1-lag + A2 INMENSURÁVEIS no INSTRUMENTO fork (fork sem gitsync; A2 É mensurável num produto real com gitsync) → indeterminado vota bloquear; Fases C/D PARQUEADAS-GATED até medir A2 fora do MCP. **v10 FECHADO em escopo PARCIAL 2026-06-18 (sem tag) — auditoria .planning/v10-MILESTONE-AUDIT.md (wf_4fec3ed7-fc0): veredito SOUND, contenção íntegra nos 5 alvos.** read-first, aditiva, contenção 2 níveis; 4 forks de decisão fechados via /grelha"
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
entre aspas; exit-codes; shallow-clone com aviso stderr; contagem README=46).

**ROLLOUT operacional — lado-AGENTE FEITO (2026-06-18):** harness-deny das 19 tools + `query_database` deny PURO +
`disabledMcpServers` aplicado e validado por checagem binária (`deny=19`, `disabled=True`) no `.claude/settings.json`
dos **4 produtos Lovable**: nfideia, ideiapartner, cfoai-grupori, lapidai (ideia-chat fora — sem `.lovable/`).
Persistência por design: ideiapartner=gitignored (local-only); lapidai(branch work)=autosync pusha; nfideia+cfoai=
tracked-on-main deixados uncommitted (autosync protege main dirty; NÃO commitei em main Lovable). Fonte-de-verdade p/
reaplicar = snippet em `source/rules/lovable/mcp-protocol.md`. Contenção auditada ÍNTEGRA nos 5 alvos (deny=19/ask=0/allow=0/disabled=true; `wf_4fec3ed7-fc0`). **Toggles de painel FEITOS** (usuário deixou só **Grupo Ideia - Dev** `2NHPnABxF0jdSX3qVLCw` no alcance; Grupo IDeia - Projects `A0gwgrenO8S5IrZtE4ig` + Dev's Lovable `pyHOQY0YDL838zK8GbR3` fora). **Resíduo = SÓ rodar `/lovable-mcp verify-deploy` num produto real.** _(ids confirmados ao vivo; conta Lovable `UYy17VvrHjhaxSUrjA7Fa5tivyD3`,
gustavolpaiva@gmail.com.)_ Trilha separada opt-in: **Fase B** (sandbox `remix_project`
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
`afce7743-…`, cfoai `0e911cfd-…`, ideia-partner-hub `748a31c2-…`. Suposição que travava a escrita — **RESOLVIDA na Fase B (2026-06-18):**
o `commit_sha` É do mirror GitHub (A1-namespace=ACOPLADO, A3=PASS, medido read-only em nfideia real). MAS o
veredito do write-path é **BLOQUEAR**: A2 (`deploy_project` lê de main vs interno) + A1-lag ficaram
**INMENSURÁVEIS num sandbox MCP** — o MCP da Lovable **não tem superfície para o gitsync GitHub** (nenhum
connector "github" em `list_connectors`; `get_project` sem URL de repo; `add_connector` no deny; fork remixado
não herda/auto-cria repo → `gh search commits` do sha do fork = vazio). Sem `origin/main` no fork, a divergência
do teste A2 é impossível **no instrumento fork** (precisão da auditoria de fechamento: A2 NÃO é "impossível via MCP" — É mensurável via MCP num PRODUTO REAL com gitsync, via push divergente + deploy_project + ler bundle). **Achado de segurança:** `permissions.deny` é relido+enforçado
**mid-session** (o remix só funcionou com a janela `deny→ask` aberta; assert pós-close passou) — contenção do
harness vale ao vivo. Pior-caso do A2 refutado (git pushes entram no Cloud via `developer_update`). Ferramenta
`lovable-window.py` (open|close|status idempotente) em `.planning/milestones/v10-phases/B-sandbox/`. **Fork
descartável (`1d0652c4-5477-49cc-bafd-70761a7f9fd6`) DELETADO pelo usuário 2026-06-18** — get_project=404 + list_projects=0; zero resíduo na conta Lovable.
**Para destravar C/D (R10-06 reabre):** medir A2 FORA do MCP (gitsync manual na UI do editor + 1 push divergente + 1 deploy); critério objetivo em `.planning/v10-MILESTONE-AUDIT.md` §9.

**Modelo de acesso (refinado via /grelha 2026-06-18, FOLD no v10 R10-02/03):** 2 tiers — `todos` (pasta
"Grupo Ideia") + `pessoal:<dono>` (`created_by`); **operacional** (escopo/foco do IdeiaOS, NÃO privacidade
dura — privacidade real = `visibility: draft` manual fora do modelo); resolução derivada `in_scope = (na
pasta) OU (created_by==get_me.id)` + `lovable-scope.yaml` só p/ exceções; identidade = conta Lovable
(gustavolpaiva@gmail.com ≠ git redeideia); **SEM** sistema de tokens (Lovable é OAuth-only); painel-UI
deferido (v11). cfoai = pessoal:gustavo (fora da pasta). Folder "Grupo Ideia" id `fold_01kvdc18tgf86ts7s0tdx6hges`.

Relaciona-se a [[project-aiox-core-pristine-overlay]] (overlay/pristine) e [[feedback-lovable-projects-branch-commit]].
