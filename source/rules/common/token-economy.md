<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->
# Token Economy Rules

## Model Routing

Use the `model:` frontmatter in agent files to route to the right model:
- **haiku**: Search, lookup, repetitive worker tasks, file reading
- **sonnet** (default): Most tasks — implementation, review, analysis
- **opus**: Architecture decisions, security review, first-attempt failures, orchestration

Never use opus for tasks that haiku can handle. ~5x cost difference.

## MCP → CLI + Skills

Before adding an MCP server, check if the same outcome is achievable via:
1. CLI tool directly (e.g., `supabase` CLI instead of Supabase MCP)
2. An existing skill (e.g., `/deep-research` instead of Exa MCP)
3. A bash script (e.g., gh CLI instead of GitHub MCP)

MCP servers add latency, tool count, and attack surface. CLI is faster and auditable.

## Créditos de MCP pago (Lovable) — declare o custo ANTES de gastar

Alguns MCP servers cobram **créditos do usuário** por chamada porque acionam um **agente de IA
remoto** — não só uma API. No **Lovable MCP** isso é explícito:

| Tool | Custa crédito? | Por quê |
|------|----------------|---------|
| `send_message`, `create_project`, `remix_project` | **SIM** (~1 crédito/chamada) | acionam o agente de IA da Lovable a trabalhar |
| `query_database`, `deploy_project`, `get_*`/`list_*`/`read_file`/`get_diff` | **não** | operação direta (SQL/publish/leitura), sem o agente |

Regras:
1. **Default = caminho grátis.** Todo dado/diagnóstico via `query_database` (ou a CLI). Deploy de
   **frontend** via **Update/Publish da interface** (grátis) — nunca via `send_message`.
2. **Declare o custo ANTES** de qualquer `send_message` evitável: *"isso custa ~N créditos Lovable;
   quer que eu dispare ou prefere via Update?"*. Um "sim" do usuário a uma TAREFA **não** é
   consentimento ao CUSTO se o custo não foi declarado.
3. **Exceção pré-autorizada:** redeploy de **edge function** (mudança em `supabase/functions/`)
   depende do agente — o Update da interface NÃO redeploya edges. Aqui `send_message` é o caminho
   legítimo; só **avise** o custo, não precisa pedir a cada vez.
4. Consulta a API externa (Asaas etc.) via agente é **evitável** — tente o dado local/UI primeiro.

Vale para qualquer MCP que cobre por invocação de agente, não só o Lovable. Cross-link
`mcp-hygiene.md` (risco) — aqui o eixo é **custo**.

## Lean Codebase Discipline

- Modular: each agent/skill/hook does one thing
- No dead code in source/ — remove unused modules from manifests/modules.json
- No feature flags or backwards-compat shims in source/ — change it

## Strategic Compact

Before executing a long phase: `/compact` to flush exploration context.
After research subagent returns: read summary, compact, then plan.
Never compact mid-task — only at phase transitions.
