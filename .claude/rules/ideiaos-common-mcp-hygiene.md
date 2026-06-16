<!--SOURCE: IdeiaOS v2 | kind: rule | targets: claude,cursor-->
# MCP Hygiene Rules

## Active Server Limit

Configure ≤30 MCP servers total; keep ≤10 active at any time.
Target: ≤80 tools visible to Claude at once.

Use `disabledMcpServers` in project `.claude/settings.json` to disable project-irrelevant MCPs.

## MCP Risk Classification

| Risk | Pattern | Action |
|------|---------|--------|
| Critical | MCP fetches URLs from user input | Never enable in prod |
| High | MCP with write access to filesystem | Scope strictly |
| Medium | MCP with external network access | Monitor, disable when not needed |
| Low | Read-only, local-only MCP | OK always-on |

## Audit Checklist (run idea-doctor)

- [ ] No MCP server calling `curl | bash` or similar
- [ ] No unknown MCPs in `mcpServers` (check against known list)
- [ ] `ANTHROPIC_BASE_URL` not set in env (CVE-2026-21852)
- [ ] MCP servers without `disabledMcpServers` in project settings reviewed
