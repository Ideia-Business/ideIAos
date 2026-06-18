# ADR — Integração Lovable MCP: postura read-first aditiva + contenção em dois níveis

**Status:** Aceito · **Data:** 2026-06-17 · **Milestone:** v10 (Camada de Integração Lovable MCP)
**Decisores:** Gustavo (owner) + Deia (orquestrador), via `/grelha` (lapidação por grilling).
**Fonte:** `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json` verbatim; workflow `wf_a9c61aa5-2bf`).

## Contexto

A Lovable lançou um **MCP server** (`https://mcp.lovable.dev`, **OAuth-only**, escopo de **conta inteira**)
com ~47 tools que vão muito além do que o IdeiaOS faz hoje (só plano-GitHub): dirigir o **agente in-Cloud**
(`send_message`), rodar SQL no **DB de produção** (`query_database`, escrita+DDL total), publicar
(`deploy_project`), ler o código deployado, gerir Knowledge/Skills do agente Cloud. Um único token alcança
**~1.640 projetos** (incl. os 4 produtos reais e um workspace de 1.622). Os produtos são editados pelo agente
Cloud **dezenas de vezes/dia** → o problema dos **dois escritores** (GitHub-plane × MCP-plane) no mesmo repo é
**agudo**. A doc do MCP **não descreve** o comportamento do sync GitHub↔Cloud (timing/namespace de commits;
fonte de leitura do `deploy_project`) — suposições que travam qualquer escrita segura.

## Decisão

**Adotar o MCP de forma ADITIVA (nunca substituir o `/lovable-handoff`), "read-first", com contenção em dois
níveis e autoridade `@devops` para qualquer mutação.** Concretamente:

1. **Read-first** — a v1 expõe só verbos **somente-leitura** (`verify-deploy`, `detect-hotfix`), 100%
   git-read. Tudo que escreve (`send_message`, `deploy_project`, `query_database`-write, `set_*_knowledge`)
   é **demovido** para fases posteriores, atrás de um **experimento de validação em sandbox** (`remix_project`)
   que mede as suposições não-verificadas do mirror antes de qualquer escrita em prod.
2. **Contenção em dois níveis:**
   - **Operacional** — o escopo é a **pasta "Grupo Ideia"** (workspace "Grupo Ideia - Dev"); a skill resolve
     a associação via `list_projects(workspace_id, folder_id)` e **recusa** qualquer projeto fora dela
     (allowlist **dinâmico** — curar a pasta = curar o escopo).
   - **Dura** — desligar o toggle `mcp_enabled` (por-workspace) nos workspaces **sem nada in-scope**
     ("Grupo IDeia - Projects" 1.622 + "Dev's Lovable"), removendo-os do alcance do token; e **harness-deny**
     das ~15 tools mutantes no `.claude/settings.json` de cada produto. `query_database` fica em **deny PURO**
     na v1 (sem promoção). `@devops` é o único fluxo que promove um tool ID a `ask` (prompt humano sempre,
     nunca `allow` silencioso).
3. **MCP off-by-default** (`disabledMcpServers`), habilitado **on-demand** na janela de trabalho (régua
   `mcp-hygiene`: o servidor é High/Critical).

## Consequências

- **Positivas:** o maior valor (matar os incidentes de deploy-drift e hotfix-inline) chega **sem créditos,
  sem superfície de escrita e sem depender de nenhuma suposição não-medida**. A contenção real (não teatro)
  vive na camada que o modelo não pode pular (harness-deny) + na fronteira de plataforma (toggle de
  workspace). O escopo por-pasta acompanha a curadoria do usuário sem mudar código.
- **Negativas / custos:** a verificação `schema-first` (incidente nº2) e a unificação de governança ("dois
  cérebros") ficam para fases posteriores; o write-path depende de um experimento de sandbox que custa
  alguns créditos. O folder-scope é **client-side** (skill-enforced) — não é fronteira de segurança da
  Lovable; a fronteira dura é o toggle de workspace.
- **Operacional:** a Lovable é **OAuth-only** (sem API key) → não dá para envelopar como CLI puro
  (regra `mcp-to-cli` não se aplica); tem que ser **skill** rodando no client MCP.

## Alternativas consideradas (e por que não)

- **Capacidade total já (write + Cloud-agent + DB):** rejeitada — blast-radius + créditos + dois-escritores
  agudos + suposições não-medidas. Risco desproporcional ao valor incremental.
- **Substituir o `/lovable-handoff`:** rejeitada — o handoff (plano-GitHub) é maduro e ortogonal; o MCP
  **soma** verificação read-only, não troca o playbook de deploy.
- **Allowlist de 4 IDs hardcoded:** rejeitada em favor do **folder-scope dinâmico** (escolha do owner) —
  acompanha novos produtos sem mudança de código.
- **Pasta como fronteira dura:** inviável — na Lovable a pasta é organização, não segurança; o equivalente
  duro seria um workspace dedicado (overkill agora).
- **CLI wrapper (mcp-to-cli):** inviável — Lovable é OAuth-only, sem API key para um script chamar.

## Notas

- Espelhamento ao Obsidian (`Decisions/`) fica a cargo do `/extract-learnings` (Passo 4c), sem pipeline novo.
- Suposições que ainda gateiam a escrita estão listadas no dossiê (§2.5) e são o objeto da Fase B (sandbox).
