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

## Critérios de auditoria de MCP (nomeados)

<!-- # SOURCE: SlowMist MCP-Security-Checklist (MIT) + OWASP Agentic / MITRE ATLAS —
     conceito-only, zero prosa. Generaliza o caso Lovable (idea-doctor §7e). -->

A risk-table acima classifica o **servidor**; estes critérios auditam o **manifest/tool-set**
de um MCP — o que o caso Lovable (deny-list de 19 tools mutantes, enforçado por `idea-doctor`
§7e) já faz pontualmente, aqui nomeado e generalizado:

- **Tool-definitions perigosas/mutantes** — toda tool que escreve/deleta/deploya/configura
  precisa de deny explícito ou justificativa; manifest com tool mutante sem deny correspondente
  é achado (conceito `mcp-scan`, CLI-first — `idea-doctor` §7e é o enforcement do caso Lovable).
- **Escopo de permissão** — least-privilege: a tool concede só a capacidade que a tarefa exige
  (ver **Excessive Agency** abaixo)?
- **Egress não-controlado** — a tool faz fetch/post a host arbitrário? egress deve ser
  pinável/auditável (liga ao `Critical` da risk-table: fetch de URL de input do usuário).
- **Injection via tool-description** — a descrição/schema da tool é DADO que o agente lê; texto
  malicioso aí é prompt-injection (cross-link `context-engineering`, anti-injection).

### Excessive Agency (OWASP LLM06) — rótulo auditável

<!-- # SOURCE: OWASP Gen AI Top 10 2025 (genai.owasp.org) — CC BY-SA 4.0, conceito-only. -->

Um agente/tool com **mais capacidade do que a tarefa exige** é superfície de abuso (tool abuse,
goal hijacking, credential exfil). O IdeiaOS já pratica least-privilege — `agent-authority`
(delegação mínima) e o learning `temp-privilege-window-teardown-grants` (janelas de privilégio
temporário) — mas sem nome auditável. Nomear como **Excessive Agency** dá rastreabilidade: ao
revisar um agente/tool, pergunte "essa capacidade é necessária para a tarefa, ou é agência
excessiva?". Não substitui `agent-authority` (autoridade de operação) — é a lente de **capacidade
mínima**, ortogonal e complementar a `credential-isolation` (posse de segredo).
