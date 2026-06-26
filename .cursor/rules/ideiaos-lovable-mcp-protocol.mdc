<!--SOURCE: IdeiaOS v10 | kind: rule | targets: claude,cursor | stack: lovable-->
# Lovable MCP Protocol — contenção, autoridade e fronteira read-first

Esta rule governa o uso do **MCP server da Lovable** (`https://mcp.lovable.dev`, OAuth-only, escopo
de conta inteira, ~47 tools). Complementa `deployment-protocol.md` (plano-GitHub) e a skill
`/lovable-mcp` (verificação read-only). Postura formal: ADR `v10-lovable-mcp-readfirst-containment.md`.

## Princípio: aditivo, read-first

O MCP **soma** verificação programática ao plano-GitHub — **nunca o substitui**. A v1 (Fase A) é
**100% read-only**. Tudo que escreve, dirige o agente Cloud ou toca o DB é **demovido** para fases
posteriores, atrás do experimento de sandbox (Fase B), e exige `@devops`.

## Autoridade (@devops para qualquer mutação)

| Operação | Quem | Como |
|----------|------|------|
| `verify-deploy` / `detect-hotfix` (read-only) | qualquer agente | via skill `/lovable-mcp` |
| Promover um tool ID mutante de `deny` → `ask` | **@devops** (exclusivo) | edição consciente do settings; **nunca** `allow` silencioso |
| `send_message` / `deploy_project` / `set_*` | **@devops**, gated, Fase C+/D | fora da v1 |
| `query_database` (SQL de prod) | **opt-in por projeto** — denied por padrão; permitido onde o projeto habilitou DB de prod; **write é gated por aprovação humana do SQL** | ex.: ideiapartner (2026-06-19) |

`@devops` detém MCP add/remove/configure (ver `agent-authority.md`). Nenhum outro agente promove tool.

## Contenção dura (harness-deny + off-by-default)

O servidor Lovable é **High/Critical** na régua `mcp-hygiene` (write em filesystem via `send_message`,
DB via `query_database`, escopo de conta inteira). Logo:

1. **Off-by-default** — `disabledMcpServers` lista o servidor; habilite **on-demand** na janela de trabalho.
2. **Deny das 18 tools mutantes** — mesmo com o servidor ligado, o harness bloqueia mutação (crédito/deploy/estrutura).
3. **`query_database` é opt-in por projeto** — denied por padrão, mas **permitido onde o projeto habilitou
   acesso a DB de prod** (ex.: ideiapartner). Não é deny-obrigatório. Como roda SQL arbitrário (incl.
   write), o gate real do write passa a ser a **aprovação humana do SQL** (o agente monta, o humano
   aprova antes de executar), não a deny-list. Mantê-lo no deny continua válido p/ quem não usa DB de prod.

### Snippet canônico (`.claude/settings.json` do produto)

> O prefixo `mcp__6f530143-e779-405d-bf42-190cae4e231b__` é o **connector id** desta conexão
> (visível no nome das tools `mcp__6f530143-…__<tool>`). Se o seu cliente registrar o servidor sob
> outro id/nome, ajuste o prefixo para casar — leia-o da lista de tools do MCP.

```jsonc
{
  "permissions": {
    "deny": [
      // — escrita / créditos / agente Cloud —
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__send_message",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__create_project",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__deploy_project",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__remix_project",
      // — DB de produção (estrutural) —
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__enable_database",
      // NOTA: query_database NÃO está aqui — é OPT-IN por projeto. Mantenha-o no deny se
      // o projeto não usa DB de prod; OMITA-o (como aqui) p/ habilitar SQL de prod via MCP
      // (write fica gated por aprovação humana do SQL). Ex. habilitado: ideiapartner.
      // — Knowledge / Skills do agente Cloud —
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__set_project_knowledge",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__set_workspace_knowledge",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__create_workspace_skill",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__update_workspace_skill",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__delete_workspace_skill",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__enable_project_skill",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__disable_project_skill",
      // — visibilidade / organização / conectores —
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__set_project_visibility",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__set_folder_visibility",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__move_projects_to_folder",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__add_connector",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__remove_connector",
      "mcp__6f530143-e779-405d-bf42-190cae4e231b__get_file_upload_url"
    ]
  },
  "disabledMcpServers": ["6f530143-e779-405d-bf42-190cae4e231b"]
}
```

Tools **read-only liberadas** (não constam no deny): `get_me`, `get_workspace`, `get_project`,
`get_project_knowledge`, `get_workspace_knowledge`, `get_diff`, `get_message`,
`get_project_analytics*`, `get_database_status`, `list_*` e `read_file`. São o que a `/lovable-mcp`
usa — zero crédito, zero escrita.

## Pré-condições operacionais (painel Lovable — uma vez)

- Desligar o toggle `mcp_enabled` (por-workspace) nos workspaces **sem nada in-scope** — removendo-os
  do alcance do token: **"Grupo IDeia - Projects"** (~1.622 projetos) e **"Dev's Lovable"**.
- O workspace de trabalho é **"Grupo Ideia - Dev"** (`2NHPnABxF0jdSX3qVLCw`); a pasta in-scope é
  **"Grupo Ideia"** (`fold_01kvdc18tgf86ts7s0tdx6hges`).
- Aplicar o snippet de deny acima ao `.claude/settings.json` de cada produto Lovable.

## Escopo (operacional) ≠ contenção (dura) — camadas separadas

- **Escopo** (R10-02, skill `/lovable-mcp`): foco do IdeiaOS — 2 tiers `todos` (pasta "Grupo Ideia")
  + `pessoal:<dono>` (`created_by`); `in_scope = na-pasta OU created_by==get_me.id`; override
  `lovable-scope.yaml`. É **client-side**, não esconde projeto de outra conta-membro. **Não** é segurança.
- **Contenção** (esta seção): fronteira de **capability/token** — harness-deny + toggle de workspace.
  É o que o modelo **não pode pular**.

Um não substitui o outro. Privacidade dura de um projeto = `visibility: draft` manual no painel,
fora destes dois mecanismos.

## Dois escritores (GitHub-plane × MCP-plane) — modelo de concorrência

O mesmo repo é editado por **dois planos**: o GitHub (commits do IdeiaOS/Cursor) e o MCP/Cloud
(agente Lovable via chat/`send_message`). Em produtos ativos (nfideia, ideiapartner — dezenas de
edições/dia) isso é **agudo**. Regras:

- **Detecção antes de reconciliação.** A v1 só **detecta** divergência (`verify-deploy`,
  `detect-hotfix`); **nunca** reconcilia automaticamente. Reconciliar é decisão humana + `/lovable-handoff`.
- **Toda escrita começa num fork.** Qualquer write-path futuro (Fase D) parte de `remix_project`
  (sandbox), nunca direto em prod.
- **Suposição não-medida (gate da escrita):** o `commit_sha` da Cloud é do mirror GitHub ou do repo
  Lovable interno? `deploy_project` publica de `main` ou do estado Cloud? → **Fase B** mede antes de
  qualquer escrita. Até lá, `SHA_ABSENT` é **candidato**, não certeza.

## Fronteira MCP × GitHub

| Eixo | Plano-GitHub (`/lovable-handoff`) | Plano-MCP (`/lovable-mcp`) |
|------|-----------------------------------|----------------------------|
| Papel | **playbook** de deploy (escreve no Git, abre/merge PR, handoff) | **verificação** read-only do estado Cloud |
| Escrita | sim (git add/commit/push; @devops para push/PR) | **não** (v1) |
| Créditos Lovable | não | não (read-only) |
| Substituível? | é o caminho principal de deploy | aditivo — só dá olhos sobre a Cloud |
