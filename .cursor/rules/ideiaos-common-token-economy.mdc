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

## Lean Codebase Discipline

- Modular: each agent/skill/hook does one thing
- No dead code in source/ — remove unused modules from manifests/modules.json
- No feature flags or backwards-compat shims in source/ — change it

## Strategic Compact

Before executing a long phase: `/compact` to flush exploration context.
After research subagent returns: read summary, compact, then plan.
Never compact mid-task — only at phase transitions.
