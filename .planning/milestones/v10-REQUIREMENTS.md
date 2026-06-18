# Requirements — v10: Camada de Integração Lovable MCP

**Milestone:** v10
**Aberto:** 2026-06-17 · **Status:** 📋 PLANEJADO (lapidado via `/grelha`; não executado)
**Fonte:** dossiê `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json` verbatim; workflow `wf_a9c61aa5-2bf` — 4 lentes de design → 4 céticos → síntese). Postura formalizada em `docs/decisions/v10-lovable-mcp-readfirst-containment.md`.
**Tese:** a Lovable lançou um MCP server (OAuth, full-account, ~47 tools, DB-prod, agente Cloud). Absorver **só o delta que o plano-GitHub não alcança** — verificação programática do que hoje é manual/cego — de forma **aditiva, read-first**, com **contenção real** (harness-deny + toggle de workspace + folder-scope) e `@devops` para mutações. Os produtos são Lovable e muito ativos (nfideia 1.709 / ideiapartner 2.616 edits) → o problema dos dois escritores é agudo; qualquer escrita começa num fork (sandbox), nunca em prod.

## Problemas que o milestone fecha (padrões de incidente do `deployment-protocol.md`)

- **Incidente nº1 — deploy-drift** ("bug persiste após fix"): hoje comparar "deployado vs main" é manual (caça-hash no bundle). 80%+ dos casos.
- **Incidente nº3 — hotfix inline**: correção feita no chat da Lovable que não passa pelo Git; o próximo redeploy de `main` a re-introduz (débito invisível). Hoje descoberto por acaso.
- **Incidente nº2 — schema-first** (parcial, v2): verificar o schema REAL de prod antes de um UPDATE/migration; hoje o IdeiaOS nunca teve acesso ao DB.
- **Dois cérebros** (v2/v3): o agente in-Cloud não obedece as regras do IdeiaOS (RLS, arquivos protegidos, ESM, PT-BR) porque não lê `.claude/rules`/`AGENTS.md` locais.

## Requisitos

| ID | Requisito | Fase | Prioridade | Status |
|----|-----------|------|-----------|--------|
| R10-01 | Skill `/lovable-mcp` (v1) com 2 verbos **read-only**: `verify-deploy` (deploy-drift via `get_project`/`get_diff`/`git rev-parse origin/main`) + `detect-hotfix` (`list_edits` × `git log origin/main`, só reporta) | A | MUST | ⬜ TODO |
| R10-02 | Escopo **dinâmico** = pasta "Grupo Ideia" (workspace "Grupo Ideia - Dev" `2NHP…`): a skill resolve via `list_projects(workspace_id, folder_id)` e **recusa** qualquer projeto fora da pasta | A | MUST | ⬜ TODO |
| R10-03 | Contenção dura: MCP **off-by-default** (`disabledMcpServers`) + **harness-deny** das ~15 tools mutantes no `.claude/settings.json` dos produtos + `query_database` em **deny PURO** na v1 + `@devops` único a promover tool ID a `ask` | A | MUST | ⬜ TODO |
| R10-04 | Empacotamento/propagação: skill em `build-plugins.sh` (CORE_SKILLS) + `manifests/modules.json` + `plugin-membership.md` + `README.md`; rule nova `source/rules/lovable/mcp-protocol.md` **adicionada explicitamente ao `build_lovable()`** (ao lado de `deployment-protocol.md`); cross-link de 1 linha no `/lovable-handoff`; gates binários verdes | A | MUST | ⬜ TODO |
| R10-05 | ADR de postura (read-first aditivo + contenção 2 níveis) em `docs/decisions/` | A | GOVERNANÇA | ✅ DONE (`v10-lovable-mcp-readfirst-containment.md`) |
| R10-06 | **Fase Sandbox** — experimento via `remix_project` que mede as suposições não-validadas: namespace/timing do mirror GitHub↔Cloud (o `commit_sha` é do mirror ou do repo Lovable interno? lag até aparecer em `origin/main`?) e se `deploy_project` publica de `main` ou do estado Cloud interno. **Gate de todo write-path.** | B | MUST-p/-escrita | ⬜ TODO |
| R10-07 | v2: `schema-check` (SQL **fixo** `information_schema`, `query_database` **ask-gated** sob @devops) + **teste manual** dos dois cérebros (`set_project_knowledge` em cfoai, com **backup** `get_*_knowledge` antes, medindo se o agente Cloud passa a recusar arquivo protegido). Gated em R10-06. | C | SHOULD | ⬜ TODO |
| R10-08 | v3: `drive-cloud-agent`/`publish` (gated, `plan_mode` primeiro, quiesce via `list_messages` + bracketing de SHA, check de saldo) + **compilador** `source/rules/lovable/*` → Project/Workspace Knowledge + Workspace Skills (`build-lovable-knowledge.sh`, gera artefato; gate de drift source→artefato por SHA). Gated no resultado de R10-07. | D | COULD | ⬜ TODO |

---

## Detalhamento + critérios de aceitação

### R10-01 — Skill `/lovable-mcp` (v1, read-only) · Fase A
- [ ] `source/skills/lovable-mcp/SKILL.md` existe, PT-BR, header de SOURCE/atribuição, tabela de invocação.
- [ ] `verify-deploy`: compara `get_project(project_id).latest_commit_sha` com `git rev-parse origin/main`; divergência → reporta drift + `get_diff`. Read-only, 0 crédito.
- [ ] `detect-hotfix`: `list_edits(project_id)` (commit_sha + prompt) cruzado com `git log origin/main`; SHA na Cloud ausente no main → reporta candidato a hotfix não-sincronizado (NÃO reconcilia sozinho).
- [ ] Nenhum verbo chama `query_database`, `send_message`, `deploy_project` ou qualquer tool mutante.
- [ ] Helper gateado por `source/lib/gates.sh` (verificação por exit code binário).

### R10-02 — Escopo dinâmico por pasta · Fase A
- [ ] A skill obtém o `folder_id` da pasta "Grupo Ideia" (config do produto / passado pelo usuário) e resolve a lista via `list_projects(workspace_id, folder_id)`.
- [ ] Qualquer `project_id` fora da pasta é **recusado** com mensagem clara (não silenciosamente ignorado).
- [ ] Documentado que folder-scope é camada **operacional** (skill-enforced), não fronteira de segurança da Lovable.

### R10-03 — Contenção dura · Fase A
- [ ] `.claude/settings.json` dos produtos: `disabledMcpServers` inclui o Lovable MCP por default; as ~15 tools mutantes em `permissions.deny`; `query_database` em deny.
- [ ] Documentado o fluxo `@devops` para promover um tool ID a `ask` (nunca `allow`).
- [ ] Pré-condição registrada: desligar `mcp_enabled` nos 2 workspaces não-dev (painel Lovable) + obter `folder_id`.
- [ ] Entrada classificando o Lovable MCP como **High/Critical** na régua `mcp-hygiene`.

### R10-04 — Empacotamento/propagação · Fase A
- [ ] Skill em `build-plugins.sh` (CORE_SKILLS) + `manifests/modules.json` + `plugin-membership.md`; `README.md` "N components" sincronizado (gate `check-readme-sync`).
- [ ] Rule `source/rules/lovable/mcp-protocol.md` (autoridade @devops, read-only-default, modelo de concorrência detecção+reconciliação, fronteira MCP-vs-GitHub) criada e **adicionada à lista explícita de `build_lovable()`** — corrige o gap real (≠ a memória `propagate-rules-gap`, que estava parcialmente errada: `propagate-if-changed.sh` já propaga `source/rules/`).
- [ ] Cross-link de 1 linha no `/lovable-handoff` (passo "checar deploy" → `/lovable-mcp verify-deploy`).
- [ ] `idea-doctor` 0 FAIL; `check-plugin-membership` 0 deriva.

### R10-06 — Fase Sandbox (gate de escrita) · Fase B
- [ ] `remix_project` de um produto cria fork descartável (custo = créditos de build; zero risco em prod).
- [ ] Medido: namespace do `commit_sha` (mirror GitHub vs repo Lovable interno); lag `get_message:completed → origin/main`; fonte de leitura do `deploy_project` (main vs estado interno).
- [ ] Resultado registrado no dossiê; só então as Fases C/D são liberadas. Se `deploy_project` lê do estado interno → `publish` permanece bloqueado (ignora gates IdeiaOS).

### R10-07 — v2 (gated em R10-06) · Fase C
- [ ] `schema-check`: SQL **fixo** (`information_schema.columns`), sem SQL arbitrário; `query_database` promovido a `ask` só nessa janela, sob @devops.
- [ ] Teste manual dos dois cérebros: backup (`get_project_knowledge` → `knowledge/_backup/cfoai.md`) **antes** do `set_project_knowledge`; teste de aceitação = pedir edit que viola arquivo protegido e ver se o agente Cloud recusa.

### R10-08 — v3 (gated em R10-07) · Fase D
- [ ] `drive-cloud-agent`: `plan_mode:true` por default; quiesce (`list_messages` zero `in_progress`) + bracketing de SHA antes/depois; check de saldo (`get_workspace`) antes de queimar crédito.
- [ ] Compilador `build-lovable-knowledge.sh` GERA o artefato (não chama MCP); publicação = verbo @devops separado; gate de drift **source→artefato** por SHA binário no CI (o drift artefato↔Cloud é verbo on-demand, não gate — viola antifrágil).
