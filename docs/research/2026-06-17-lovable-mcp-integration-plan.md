---
title: Integração IdeiaOS ↔ Lovable MCP — dossiê de planejamento
status: formalizado-v10 (não-executado)
created: 2026-06-17
milestone: v10 — Camada de Integração Lovable MCP
decision_so_far: 4 forks fechados via /grelha; formalizado em .planning/milestones/v10-{REQUIREMENTS,ROADMAP}.md + ADR docs/decisions/v10-lovable-mcp-readfirst-containment.md (não executado)
companion: 2026-06-17-lovable-mcp-synthesis.json  # síntese estruturada verbatim
workflow_run_id: wf_a9c61aa5-2bf  # 9 agentes (4 lentes → 4 céticos → síntese), 681k tokens
tags: [lovable, mcp, integração, segurança, governança, milestone-candidato]
---

# Integração IdeiaOS ↔ Lovable MCP — dossiê completo

> **Propósito deste arquivo:** congelar TUDO que foi analisado na sessão de 2026-06-17 sobre
> aproveitar o novo **MCP server da Lovable** para melhorar a integração IdeiaOS↔Lovable, para
> retomar mais tarde sem perder nada. Estado atual: **plano vetado e em discussão — nada
> implementado.** O usuário pediu para "afiar o plano" antes de comprometer código.
>
> A síntese estruturada (verdict, pilares, modelos, rollout) está **verbatim** no companheiro
> `2026-06-17-lovable-mcp-synthesis.json`. Este `.md` é a versão legível + os fatos fundamentados +
> os forks abertos + os próximos passos.

---

## Grilling — resoluções (sessão 2026-06-17/18, via /grelha)

Lapidação em andamento. Workspace dev **renomeado para "Grupo Ideia - Dev"** (id `2NHPnABxF0jdSX3qVLCw`).

- **Fork A — contenção → FECHADO: dois níveis.** (1) **Operacional:** a skill resolve o escopo pela **pasta
  "Grupo Ideia"** dentro do workspace "Grupo Ideia - Dev" (via `list_projects(workspace_id, folder_id)`) e
  **recusa tudo fora dela** — substitui o "4 IDs hardcoded" do Pilar 5 por um **allowlist DINÂMICO** (curar a
  pasta = curar o escopo). (2) **Duro:** desligar `mcp_enabled` (toggle por-workspace — confirmado que existe)
  nos 2 workspaces sem nada in-scope ("Grupo IDeia - Projects" 1.622 + "Dev's Lovable") no painel Lovable.
  **Caveat honesto:** pasta NÃO é fronteira de segurança na Lovable (token é full-account) → folder-scope é
  camada OPERACIONAL (skill-enforced); a fronteira DURA é o toggle de workspace. Pré-condição da v1.
  _Folder obtido (2026-06-18):_ workspace `2NHPnABxF0jdSX3qVLCw`, folder `fold_01kvdc18tgf86ts7s0tdx6hges`.
  **In-scope = 6 projetos na pasta:** ideiapartner (`afce7743`), nfideia (`bf83d98a`), ideia-partner-hub
  /Painel Colaborador (`748a31c2`), lapidai (`44f5d5d2`), IDeia Client/geo-lovelace-hub (`3a451ad9`), e
  "Chatwoot Insights" (`f1fbc853`, research/throwaway, 1 edit — bom alvo p/ a Fase B sandbox). ⚠️
  **cfoai-grupori (`0e911cfd`) NÃO está na pasta** (estava assumido como produto/piloto) → fora de escopo pela
  regra "só a pasta"; decisão do usuário pendente. _Pendência:_ confirmar a semântica do toggle `mcp_enabled`.
- **Fork B — verbos da v1 → FECHADO: v1 SEM schema-check.** v1 = só `verify-deploy` + `detect-hotfix` (100%
  git-read). `query_database` fica em **deny PURO** no harness (sem promoção a `ask`) → v1 provadamente
  incapaz de tocar o DB de prod. `schema-check` (SQL fixo `information_schema`, `query_database` ask-gated) →
  **v2**.
- **Fork C — onde mora → FECHADO: skill nova `/lovable-mcp`.** `source/skills/lovable-mcp/SKILL.md` com os 2
  verbos + cross-link de 1 linha no `/lovable-handoff` (passo "checar deploy" → `/lovable-mcp verify-deploy`).
  **Achado que eliminou a opção CLI:** Lovable é OAuth-only (sem API key) → bash não chama o MCP; tem que ser
  skill rodando no client. A regra `mcp-to-cli` não se aplica.
- **Fork D — dois cérebros → FECHADO: sim, faseado e medido.** O v10 mira os dois cérebros como **fase
  posterior** (pós-v1, é escrita, gated por `@devops`): primeiro um **TESTE MANUAL** de `set_project_knowledge`
  em 1 produto (cfoai), com backup (`get_*_knowledge` salvo antes), medindo se o agente Cloud passa a
  recusar tocar arquivo protegido. **Compilador automático** (source→Knowledge) só se o teste provar valor.
  v1 segue read-only.
- **Assumições críticas** (mirror GitHub↔Cloud timing/namespace; `deploy_project` lê de main ou interno) —
  ainda travam todo write-path; validáveis só no experimento de sandbox (Fase 0). `gitsync_github: true`
  confirmado nos 3 workspaces (sync GitHub ativo).

### Escopo v10 fechado (pós-grilling) — escada de fases

- **v1 (read-only, sem suposições):** skill `/lovable-mcp` com `verify-deploy` + `detect-hotfix`; escopo =
  pasta "Grupo Ideia"; MCP off-by-default; harness-deny das ~15 tools mutantes (`query_database` em deny
  PURO); `@devops` p/ qualquer promoção. Pré-condição: desligar `mcp_enabled` nos 2 workspaces não-dev +
  pegar `folder_id`. **Buildável já — não depende da Fase 0.**
- **Fase 0 (sandbox, gate de toda escrita):** `remix_project` de 1 produto → medir mirror timing/namespace +
  `deploy_project` source. Custo = alguns créditos. Destrava (ou mata) tudo abaixo.
- **v2 (escrita read-mais-segura):** `schema-check` (SQL fixo, `query_database` ask-gated) + **teste manual
  dos dois cérebros** (`set_project_knowledge` em cfoai, com backup). Só após Fase 0.
- **v3 (write-path + automação):** `drive-cloud-agent`/`publish` (gated, quiesce + bracketing SHA) +
  compilador source→Knowledge — só se o teste manual da v2 provar valor.

### Modelo de acesso/escopo (grilling dedicado, 2026-06-18) — FOLD no v10 (refina R10-02/03)

Subsistema desencadeado pela pergunta do cfoai (privado). Lapidado via `/grelha`, 6 galhos fechados:
- **Ambição:** começou "N tiers nomeados, sem papéis/UI" mas o vocabulário fechou em **2 tiers** —
  `todos` + `pessoal:<dono>` (`grupo:<nome>` deferido até aparecer subconjunto de devs).
- **Enforcement:** **operacional** (escopo/foco do IdeiaOS, confiando no time), **NÃO privacidade dura**.
  Reframe importante: não é sistema de segurança, é registro de FOCO. Privacidade real, se precisar, é
  `visibility: draft` manual no painel — FORA deste modelo.
- **Identidade:** conta Lovable (`get_me.id`). ⚠️ a conta conectada é `gustavolpaiva@gmail.com` ≠ git
  `gustavo@redeideia.com.br`.
- **Resolução:** `in_scope = (na pasta "Grupo Ideia") OU (created_by == get_me.id)` — derivado da Lovable,
  sem arquivo a manter; `lovable-scope.yaml` (commitado no IdeiaOS) só para exceções/overrides.
- **Por que NÃO um sistema de tokens:** Lovable é OAuth-only, sem API key / sem token por-projeto. O OAuth
  por-dev JÁ é a identidade; a ACL nativa (visibility/membership/folder) já é a fronteira dura.
- **Painel-UI de curadoria:** ideia futura (v11), deferida. Hoje a curadoria = a pasta + `created_by` + override.
- **Encaixe:** FOLD no v10 (sem milestone próprio).

---

## 0. Contexto e pedido

A Lovable lançou um **MCP server** (`https://mcp.lovable.dev`, OAuth-only) que permite Claude/Cursor/
ChatGPT/VS Code se conectarem direto à plataforma Lovable. O usuário **já conectou** no Claude Desktop e
no Cursor (prints fornecidos), e o servidor está **vivo nesta sessão do Claude Code** (server id
`6f530143-…`). Hoje a integração IdeiaOS↔Lovable é só via **GitHub**; o pedido foi estudar "como um
arquiteto/engenheiro sênior da NASA" se dá para melhorar essa sincronicidade, explicando **como é hoje vs
como seria depois**.

Links de referência da Lovable: `https://lovable.dev/mcp#setup` · `https://lovable.dev/mcp` ·
`https://docs.lovable.dev/integrations/lovable-mcp-server`.

---

## 1. Fatos fundamentados (verificados nesta sessão)

### 1.1 Superfície de capacidade do MCP (~47 tools)
- **Ciclo de projeto:** `create_project` (prompt NL/template/design-system), `get_project` (editor_url,
  preview_url, screenshot, `latest_commit_sha`, status), `list_projects` (busca fuzzy/filtro),
  `remix_project` (fork), `deploy_project` (publica em lovable.app), `set_project_visibility`,
  `move_projects_to_folder`, `list_template_projects`, `list_design_systems`.
- **Interação com o agente (a maior):** `send_message` — manda mensagem em linguagem natural ao agente
  **in-Cloud** da Lovable, que **escreve/edita código**, instala pacotes, configura auth, conecta
  integrações (Stripe/Supabase), corrige bugs, rebuilda o preview. Suporta `plan_mode` (discute sem
  editar) e anexos. `get_message` (poll status), `list_messages`.
- **Inspeção de código (read-only, tipo git):** `list_files(ref)`, `read_file(ref)`, `list_edits`
  (histórico de edições com `commit_sha` + o prompt que causou cada uma), `get_diff` (diff unificado por
  `message_id` ou `sha`).
- **DB na nuvem:** `get_database_status`, `enable_database` (provisiona Supabase Postgres),
  `query_database` — "Execute SQL… SELECT, INSERT, UPDATE, DELETE, e DDL. Operações de escrita modificam
  dados de PRODUÇÃO permanentemente." Roda com **permissão total** do DB.
- **Knowledge/Governança:** `get/set_project_knowledge` (instruções do agente por-projeto, máx 10k chars),
  `get/set_workspace_knowledge` (instruções cross-projeto, máx 10k chars).
- **Workspace Skills:** `list/get/create/update/delete_workspace_skill` (SKILL.md reusável no repo do
  workspace), `list_project_skills`, `enable/disable_project_skill`. → dá para **deployar skills
  estilo-IdeiaOS dentro da Lovable**.
- **Connectors:** `list_connectors` / `list_custom_connectors` / `list_available_connectors` /
  `list_connections` / `add_connector` (retorna URL do painel — não adiciona programaticamente) /
  `remove_connector`.
- **Analytics:** `get_project_analytics` (visitantes, pageviews, bounce, por página/fonte/device/país),
  `get_project_analytics_trend` (visitantes em tempo real).
- **Workspace/identidade:** `get_me`, `list_workspaces`, `get_workspace` (plano, SALDO DE CRÉDITO,
  membros). `get_file_upload_url` (upload presigned p/ anexos).

### 1.2 Modelo de segurança (citado da doc Lovable)
- "API key authentication is not currently available. **OAuth is the only supported way.**"
- **Escopo de conta inteira:** "Whatever client you connect can list, read, and edit **every project you
  have access to**."
- **Ao vivo + cobrado:** "Tool calls use real credits and edit real projects." Cada `create_project` e
  `send_message` consome créditos de build; as demais tools são grátis.
- DB: "`query_database` runs SQL with your **full database permissions**. Read, write, and schema changes."
- Workspaces Enterprise: third-party MCP **desabilitado por default** (admin habilita).
- A doc do MCP **não menciona** sync com GitHub. → **suposição não-validada** sobre como/quando um commit
  do agente Cloud (`send_message`) chega ao mirror GitHub.

### 1.3 Conta real do usuário (via `get_me`/`list_projects`)
- 3 workspaces: **"Gustavolpaiva Dev"** (owner, id `2NHPnABxF0jdSX3qVLCw`) = onde vivem os produtos reais;
  **"Grupo IDeia - Projects"** (admin, `A0gwgrenO8S5IrZtE4ig`) = workspace seed/demo com **1.622 projetos**
  auto-gerados; **"Dev's Lovable"** (admin, `pyHOQY0YDL838zK8GbR3`) = poucos (ideiab2b, Mamut).
- **Um único token OAuth alcança TODOS** → blast-radius ~1.640+ projetos, incluindo os produtos de prod.
- **Produtos reais** (workspace "Gustavolpaiva Dev"), todos Lovable + publicados + Supabase + muito ativos:

  | Produto | Lovable project id | Edits | Atividade |
  |---|---|---|---|
  | NFIdeia (`nfideia`) | `bf83d98a-398b-4fba-937a-fe7fedd5ee74` | 1.709 | 39 edits/24h, 213 visit/30d |
  | Ideia Partner (`ideiapartner`) | `afce7743-be51-4fd2-af2b-1e05730732d4` | 2.616 | 108 edits/7d, 758 visit/30d |
  | Ideia Finance / cfoai (`cfoai-grupori`) | `0e911cfd-3cfd-46aa-8fab-cc2d1b242291` | 175 | ativo |
  | Painel Colaborador (`ideia-partner-hub`) | `748a31c2-8b0d-48d6-aa92-5a33561cc421` | 559 | ativo |

  **Implicação decisiva:** o agente Cloud da Lovable já edita esses repos de produção **dezenas de
  vezes/dia**, em paralelo a qualquer trabalho do plano-GitHub do IdeiaOS. O problema dos **dois
  escritores é AGUDO, não teórico.**

### 1.4 Como o IdeiaOS integra com Lovable HOJE (só plano-GitHub)
- Skill `source/skills/lovable-handoff/SKILL.md`: gate de segurança duplo → playbook (typecheck → commit →
  push → merge `main` + verificar `origin/main` → handoff doc condicional quando muda migration/edge/secret
  → postmortem condicional → comunicação canônica em 6 blocos com "Ação necessária ⚠️" SIM/NÃO →
  extract-learnings). Limites: "não aplica migrations na Cloud"; arquivos protegidos
  `src/integrations/supabase/{client,types}.ts`, `.env`, `supabase/config.toml`.
- Rule `source/rules/lovable/deployment-protocol.md`: checagens pré-push (build, `tsc --noEmit`, sem
  console.log, env-vars doc, sem secrets); "Lovable tem seu próprio git history; nunca `git reset --hard`";
  gotchas Vite/ESM/Tailwind/import.meta.env/Supabase singleton; RLS obrigatória; nunca `service_role` no
  front.
- Template `source/templates/lovable/AGENTS.lovable.md.tmpl` (bloco `lovable-deploy-section`): "Update só lê
  `main`"; "PR aberto ≠ deployável"; migrations/edges/secrets aplicados **pela Lovable Cloud**;
  `.lovable/SYNC_TRIGGER.json`. **Três padrões de debugging em produção** (de incidentes recorrentes):
  1. "Bug persiste após fix" → **checar deploy ANTES** de mexer no código (80%+ é deploy-drift). Manual hoje.
  2. **Schema-first** antes de qualquer UPDATE/INSERT em prod (SELECT as colunas; schema real > intuição). Manual.
  3. **Hotfix inline** no chat Lovable que não passa pelo Git → sincronizar de volta, senão o próximo redeploy
     re-introduz o bug (débito invisível). Manual.
  + "Coordenação multi-IA: nunca editar o mesmo arquivo simultaneamente com Lovable aberto na mesma área."

### 1.5 Restrições do IdeiaOS que o plano DEVE respeitar
- **mcp-hygiene:** ≤30 servers, ≤10 ativos, ≤80 tools; classes de risco. Lovable MCP (escrita full-account
  + DB-prod + rede) = **High/Critical → não pode ser always-on**.
- **token-economy:** "MCP → CLI + Skills" (preferir CLI/script). Contraponto: `send_message`, ler o ref
  **deployado**, e introspecção do DB de prod **não** dá pra fazer via gh CLI — o MCP se justifica, mas
  embrulhado/disciplinado.
- **agent-authority:** `@devops` (Gage) é EXCLUSIVO p/ `git push`, `gh pr`, **MCP add/remove/configure**,
  CI/CD, release → as tools **mutantes** do MCP mapeiam p/ `@devops`; read-only fica aberto.
- **Packaging (crítico):** `.aiox-core` PRISTINE; deltas em `source/` propagados por
  `build-adapters.sh`/`build-plugins.sh` (paridade Claude×Cursor) + gates `idea-doctor.sh`,
  `check-readme-sync`, `check-plugin-membership`, `manifests/modules.json`. Skills globais e `.aiox-core`
  instalado só via `scripts/install-global-patches.sh` (overlay idempotente). Lovable: commit da IA vai p/
  **branch, nunca main automática**; IdeiaOS (não-Lovable) pode ir direto na main.
- **Os dois cérebros:** regras do IdeiaOS vivem no repo LOCAL (`.cursor/rules`, `.claude/rules`, `AGENTS.md`);
  o agente **in-Cloud** da Lovable **não lê** esses arquivos — só obedece Project/Workspace **Knowledge** +
  Workspace **Skills**. Hoje, edição via chat Lovable ignora todas as regras do IdeiaOS.

---

## 2. A síntese — plano vetado (4 lentes → 4 céticos → síntese)

> Versão estruturada verbatim em `2026-06-17-lovable-mcp-synthesis.json`. Resumo legível abaixo.

### 2.1 Veredito
**Adotar de forma ADITIVA, "read-first", com contenção REAL no harness (`permissions.deny`/`ask` no
`settings.json`, não em prosa de skill) e autoridade `@devops` p/ mutações; piloto read-only em 1 produto
(cfoai); todo write-path DEMOVIDO até um experimento de validação em sandbox (`remix_project`) passar.**
Nunca substitui o `/lovable-handoff` atual — soma a ele.

### 2.2 Os 8 pilares (hoje → depois)

**v1 — read-only (≈80% do valor, ≈5% do risco, 0 crédito):**

1. **`verify-deploy` — gate de deploy-drift** · `must` · risco baixo. Hoje: comparar "deployado vs main" no
   olho (caça-hash no bundle). Depois: `get_project().latest_commit_sha` vs `git rev-parse origin/main`;
   `get_diff` mostra o quê. Resolve incidente nº1. Tools: `get_project`, `get_diff`, `read_file`. Mora:
   `source/skills/lovable-mcp/SKILL.md` + helper gateado por `source/lib/gates.sh`.

2. **`detect-hotfix` — reconciliação de hotfix inline** · `must` · risco baixo. Hoje: descobre por acaso;
   "pede o trecho ao operador". Depois: `list_edits` (commit_sha + prompt) cruza com `git log origin/main`
   → SHA na Cloud ausente no main = hotfix não-sincronizado; `get_diff(message_id)` recupera. Só REPORTA,
   nunca reconcilia sozinho. Resolve incidente nº3. Tools: `list_edits`, `get_diff`.

3. **`schema-check` — verificação schema-first (SQL hardcoded)** · `must` · risco médio. Hoje: SELECT vira
   handoff p/ humano, ou confia em `types` velho. Depois: `query_database` no Postgres real, mas com
   **templates fixos** (`information_schema.columns`), **sem SQL arbitrário** = zero superfície de escrita
   por construção (sem parser anti-DML teatral). Tools: `query_database`, `get_database_status`.

4. **Contenção no HARNESS — `deny`/`ask` no `settings.json`** · `must` · risco baixo · **a peça
   inegociável**. Hoje: inexistente. Depois: as ~15 tools mutantes em `permissions.deny` no
   `.claude/settings.json` de todo produto; `@devops` é o único fluxo que promove um tool ID p/ `ask`
   (prompt humano sempre, nunca `allow` silencioso). Anti-injeção vira determinística (nega capability na
   camada que o modelo não pode pular). Mora: `.claude/settings.json` dos produtos + nota em
   `agent-authority.md`.

5. **Allowlist de 4 IDs hardcoded + MCP off-por-default** · `must` · risco médio. Hoje: 1 OAuth alcança
   ~1.640 projetos; always-on estoura o teto de 80 tools. Depois: 4 project IDs hardcoded no helper (não um
   `lovable-allowlist.json` — generality especulativa); MCP em `disabledMcpServers` por default, on-demand.
   ⚠️ **Honestidade:** allowlist client-side é camada SECUNDÁRIA — contenção real só vem de ação no painel
   Lovable. Tools: `get_workspace`, `list_projects`, `get_me`.

**Demovidos — escrita, atrás de gates (v2/v3):**

6. **`drive-cloud-agent` (`send_message`)** · `should` · risco alto. Instruir o agente Cloud em NL
   (`plan_mode:true` primeiro). Melhor só p/ o que só a Cloud faz (provisionar Supabase, migrations,
   conector Stripe, arquivos protegidos); pior p/ qualquer coisa testável local e durante os 39–108
   edits/dia (two-writers agudo). Demovido: queima crédito + depende do timing do mirror não-medido.

7. **`publish` (`deploy_project`)** · `could` · risco alto. Publicar + confirmar com `get_project` status +
   screenshot real. **Bloqueado** até medir se `deploy_project` lê de `main` ou do estado Cloud interno (se
   interno, é rota de deploy paralela que ignora todos os gates IdeiaOS).

8. **Compilador de Knowledge/Skills (os dois cérebros)** · `could` · risco alto. Compilar
   `source/rules/lovable/*` em Project/Workspace Knowledge + Workspace Skills p/ o agente Cloud obedecer as
   regras do IdeiaOS. Demovido: efeito do `set_knowledge` no agente Cloud é **não-medido** → v1 escreve à
   mão em 1 produto e mede antes de construir o pipeline. Backup obrigatório (`get_*_knowledge` →
   `knowledge/_backup/`) antes do 1º `set_*` (escrita na Cloud não tem rollback automático). Tools:
   `set_project_knowledge`, `set_workspace_knowledge`, `create_workspace_skill`.

### 2.3 Os três modelos
- **Concorrência (dois escritores):** v1 é read-only → não tem o problema. "Lease/lock" **cortado** (falsa
  segurança: o plano Cloud nunca lê o arquivo de lock). Na escrita (Fase 3): **detecção+reconciliação, não
  exclusão** — `list_messages` (zero `in_progress`) antes/depois + **bracketing de SHA** contra TOCTOU
  (snapshot `latest_commit_sha` antes do trabalho e antes do push; mudou → aborta). Prevenção total é
  impossível sem cooperação da plataforma (humano no browser fura qualquer convenção).
- **Segurança:** contenção no harness (`deny`/`ask`), não em skill. `query_database` em `deny`, só promovido
  a `ask` na janela de `schema-check` (SQL fixo). `create_project` = `@devops` + aprovação humana (cria
  asset + queima crédito). Ler `get_workspace` (saldo) e abortar abaixo de um piso antes de qualquer
  escrita. Vazamento de OAuth é existencial (sem rotação, scope = conta) → reduzir superfície ANTES (off por
  default; backup do DB antes de janela de escrita) + playbook reativo (revogar no painel, auditar
  `list_edits`/`list_messages`).
- **Governança (dois cérebros):** fonte única = `source/rules/lovable/*` (`deployment-protocol.md` dono dos
  3 padrões — template/skill/Cloud REFERENCIAM, não duplicam). Push one-way local→Cloud; Knowledge é espelho
  derivado. Budget: Workspace Knowledge = invariantes cross-produto (RLS, anon-only, ESM, PT-BR, deploy
  condensada) ~3-4k chars; Project Knowledge = específico (arquivos protegidos literais) ~2-3k/produto. O
  drift artefato↔Cloud **não** é gate do `idea-doctor` (seria I/O de rede mutável — viola antifrágil); vira
  verbo on-demand `knowledge-status` sob `@devops`. Só o drift source→artefato (SHA binário) é gate de CI.

### 2.4 Rollout faseado
- **Fase 0 — Sandbox (pré-requisito de toda escrita):** medir as 3 suposições que travam a escrita (timing/
  namespace do mirror; `deploy_project` lê de main ou interno; `commit_sha` do `list_edits` bate com
  `git log`). Tudo num **fork via `remix_project`** — zero risco em prod, custo = alguns créditos.
- **Fase 1 — Read-only:** os 3 verbos. Piloto on-demand no **cfoai** (menos ativo). Read-only roda nos 4 no
  dia 1.
- **Fase 2 — Knowledge manual:** `set_project_knowledge` à mão no cfoai (com backup); testar se o agente
  passa a recusar tocar arquivo protegido. Se não mudar → o compilador inteiro morre aqui.
- **Fase 3 — Write-path:** `drive-cloud-agent` (`plan_mode` primeiro) + `publish`, com quiesce + bracketing
  SHA + check de crédito. Edit trivial reversível no cfoai.
- **Fase 4 — Rollout + compilador:** cfoai → ideia-partner-hub → nfideia → ideiapartner (semanal, só
  escrita); `scripts/build-lovable-knowledge.sh` (gera artefato, não chama MCP) + gate SHA source→artefato;
  +2 entradas em `modules.json`, build-plugins, README counts; `build_lovable()` ganha `mcp-protocol.md`.

### 2.5 Suposições críticas a validar (antes de qualquer escrita)
- **Trava tudo:** namespace/timing do mirror GitHub↔Cloud — `commit_sha` é do mirror GitHub ou do repo
  Lovable interno? Qual o lag `get_message:completed` → commit em `origin/main`?
- `deploy_project` publica de `main` ou do estado Cloud interno? (se interno, ignora os gates IdeiaOS).
- `send_message` concorrentes no mesmo projeto são serializados pela Lovable ou colidem?
- Efeito real de `set_project_knowledge`/`create_workspace_skill` no agente in-Cloud (não-medido).
- Workspace Enterprise desabilita third-party MCP por default — confirmar se "Gustavolpaiva Dev" permite
  restringir o OAuth a 1 workspace / tokens por-workspace (única contenção REAL do blast-radius).
- `query_database` aceita múltiplos statements por `;`? (confirmar no fork, mesmo com SQL fixo).
- **Correção factual:** `propagate-if-changed.sh` JÁ propaga `source/rules/` — a memória
  `propagate-rules-gap` está parcialmente errada. Gap real: uma rule `source/rules/lovable/mcp-protocol.md`
  precisa ser adicionada explicitamente ao `build_lovable()`, ao lado de `deployment-protocol.md`.

### 2.5b RESULTADOS da Fase B (2026-06-18 — COMPLETA · veredito: 🔴 BLOQUEAR `publish` via MCP)

Medido **read-only** (`list_edits`/`get_project` não estão no deny) em produto REAL (nfideia `bf83d98a-…`) × `git log origin/main` local — zero crédito, zero risco, sem deny-lift. Detalhe em `.planning/milestones/v10-phases/B-sandbox/B-01-SUMMARY.md`.

- **A1-namespace = ACOPLADO ✅** — todo `commit_sha` do `list_edits` casa 1:1 (SHA-cheio) com `git log origin/main`. O `commit_sha` da Cloud É o SHA do mirror GitHub, não um namespace interno.
- **A3 = PASS ✅** — 100% dos SHAs `completed` ∈ `git log origin/main`; `detect-hotfix` opera no namespace certo.
- **Bônus** — commits `type: ai_update` do agente Cloud (ex.: `76e9cee5` "Rescan security concluído") aparecem em `origin/main`: mirror **bidirecional** confirmado; "dois escritores" visível no histórico. `status` do `list_edits` = build da Lovable, não do git (`c35b5207` é `failed` no build mas existe em `origin/main`).
**Metade de escrita (ao vivo, fork descartável `1d0652c4`, janela `deny→ask` aberta+fechada):**
- **MURO DE VIABILIDADE** — o MCP **não expõe nem gerencia o gitsync GitHub**: nenhum connector "github" (`list_connectors`), zero conexão GitHub (`list_connections`), `get_project` sem URL de repo; o `sha_0` do fork (`cac6c856…`) não existe em repo nenhum (`gh search commits`=`[]`), nenhum repo auto-criado, a própria fonte sem repo. gitsync é manual-por-projeto na UI do editor, só nos 5 produtos. `add_connector` está no `deny`.
- **A1-lag = INDETERMINADO** e **A2 = INDETERMINADO** — sem `origin/main` no fork, divergência e propagação são **estruturalmente impossíveis de medir via MCP**.
- **A2 pior-caso REFUTADO** pelo read-only: `developer_update` (git pushes) entram no `list_edits` da Cloud → `publish` não ignora o Git por completo; risco residual = **lag de ingestão**, não bypass total.
- **VEREDITO (tabela-verdade):** A1-lag + A2 indeterminados → **BLOQUEAR `publish`**. Fases C/D gateadas; a contenção `deny=19` (relida e enforçada mid-session — comprovado) é a postura correta. Para destravar: medir A2 **fora do MCP** (gitsync manual na UI + 1 push divergente + 1 deploy). Fase A não depende disto. Detalhe + fork a deletar em `B-01-SUMMARY.md`.

### 2.6 Cortado por simplicidade
Lease/lock (falsa segurança), o compilador de Knowledge inteiro (deferido até medir), skill `/lovable-db`
com parser anti-DML (substituída por SQL fixo), `lovable-allowlist.json` (4 IDs hardcoded), espera de 1
semana entre produtos **para verbos read-only** (leitura é idempotente/grátis → roda nos 4 no dia 1), gate
de drift artefato↔Cloud no idea-doctor (vira verbo on-demand).

### 2.7 Recomendação final (escopo v1)
Aprovar a v1 enxuta: skill `source/skills/lovable-mcp/SKILL.md` com 3 verbos read-only (`verify-deploy`,
`detect-hotfix`, `schema-check` com SQL hardcoded), 4 project IDs hardcoded, helper gateado por `gates.sh`,
MCP em `disabledMcpServers` por default + on-demand, cross-link de 1 linha no `lovable-handoff`, e — a peça
inegociável — as ~15 tools mutantes em `permissions.deny` no `.claude/settings.json` dos produtos. Ataca os
incidentes nº1, nº3 e metade do nº2, ~5% do risco, 0 crédito, sem depender de nenhuma suposição
não-verificada. Aditivo, respeita overlay/pristine, `@devops`, mcp-hygiene (off por default).

---

## 3. Forks abertos para AFIAR (decisões do usuário)

- **Fork A — contenção real do blast-radius (resolver primeiro):** o plano "Gustavolpaiva Dev" permite
  restringir o OAuth a 1 workspace, ou desabilitar "third-party MCP clients" nos 2 workspaces não usados (o
  de 1.622 + "Dev's Lovable")? Recomendação: tratar como **pré-condição da v1**. Pode exigir Business/
  Enterprise.
- **Fork B — v1 ainda mais fina?** `verify-deploy` + `detect-hotfix` são 100% git (risco baixo);
  `schema-check` toca DB de prod (read). Recomendação: **manter os 3** (SQL fixo é seguro por construção).
  Alternativa: cortar `schema-check` p/ v2 e deixar v1 git-puro.
- **Fork C — onde mora:** skill nova `/lovable-mcp` vs estender `/lovable-handoff`. Recomendação: **skill
  nova** + cross-link de 1 linha (handoff é playbook de escrita/deploy; verificação read-only é
  responsabilidade distinta).
- **Fork D — apetite pelos "dois cérebros":** maior upside (agente Cloud obedecer RLS/arquivos protegidos),
  menos comprovado. Recomendação: **vale a Fase 2 manual** (baixo risco, mede antes de construir o
  compilador).

---

## 4. Decisão até agora & próximo passo

- **Decisão (2026-06-17):** os **4 forks foram fechados** via `/grelha` e o plano foi **FORMALIZADO como
  milestone v10** — `.planning/milestones/v10-{REQUIREMENTS,ROADMAP}.md` + ADR
  `docs/decisions/v10-lovable-mcp-readfirst-containment.md`. Ainda **não executado** (nenhum código de skill).
- **Próximo passo concreto:** construir a **Fase A (v1 read-only)** — skill `/lovable-mcp`
  (`verify-deploy` + `detect-hotfix`) + harness-deny + folder-scope + empacotamento. Trabalho de framework
  IdeiaOS (direto na main); **não depende da Fase B (sandbox)**.
  - **Pré-condições suas (painel Lovable, ~1 min):** desligar `mcp_enabled` nos 2 workspaces não-dev
    ("Grupo IDeia - Projects" + "Dev's Lovable") + passar o `folder_id` da pasta "Grupo Ideia".
  - Fases B/C/D (escrita) ficam gated no experimento de sandbox (Fase B).
- **Importante (anti-cascata / two-writers):** os produtos são Lovable e muito ativos. Qualquer
  experimento de **escrita** deve começar num **fork via `remix_project`** (Fase 0), nunca direto em prod.

## 5. Referências
- Síntese estruturada verbatim: `docs/research/2026-06-17-lovable-mcp-synthesis.json`.
- Workflow run id: `wf_a9c61aa5-2bf` (9 agentes; 4 lentes de design → 4 céticos adversariais → síntese sênior).
- Doc oficial Lovable: `https://docs.lovable.dev/integrations/lovable-mcp-server`.
- Integração atual: `source/skills/lovable-handoff/SKILL.md`, `source/rules/lovable/deployment-protocol.md`,
  `source/templates/lovable/AGENTS.lovable.md.tmpl`.
