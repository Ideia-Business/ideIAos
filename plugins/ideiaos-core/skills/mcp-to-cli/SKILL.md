---
name: mcp-to-cli
description: "Converte uma integração MCP pesada em skill + CLI equivalente, reduzindo tokens e tools ativos. Use proactively quando um MCP consome muito contexto ou há >10 MCPs ativos. Implementa a regra mcp-hygiene."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
# Skill: MCP-to-CLI — Converter MCP em Skill + CLI

## Quando usar

Ative esta skill quando:

- Um MCP consome **muito contexto** (tool descriptions longas, muitas tools registradas).
- Há **mais de 10 MCPs ativos** na sessão — risco de context bloat.
- Um MCP tem **mais de 80 tools** registradas mas você usa apenas 3-5 delas.
- O MCP está causando lentidão perceptível ou erros de rate limit.
- Um MCP de terceiros não tem suporte ativo e você quer reduzir a dependência.

## Relação com regras IdeiaOS

Esta skill implementa:
- `source/rules/common/mcp-hygiene.md` — princípio de higiene de MCPs
- `source/rules/common/token-economy.md` — economia de tokens e tools

## Processo

### Passo 1 — Inventariar o uso real do MCP

```bash
# Ver MCPs ativos
claude mcp list

# Identificar quantas tools o MCP expõe
# (verificar na documentação do MCP ou na listagem de tools do Claude Code)
```

Listar as operações que **você realmente usa** do MCP no projeto. Normalmente são 3-5 de um total de 20-80.

### Passo 2 — Mapear para CLI equivalente

Para cada operação usada, encontrar o comando CLI equivalente:

| Operação MCP | CLI equivalente |
|-------------|-----------------|
| `supabase.query(sql)` | `supabase db execute --sql "<query>"` |
| `supabase.migration.new(name)` | `supabase migration new <name>` |
| `supabase.db.push()` | `supabase db push` |
| `github.pr.create(...)` | `gh pr create --title "..." --body "..."` |
| `github.issue.list()` | `gh issue list` |

### Passo 3 — Criar a skill CLI

Criar `source/skills/<nome-do-mcp>-cli/SKILL.md` com:
- Descrição das operações disponíveis
- Exemplos de uso para cada operação
- Bloco bash com os comandos exatos

Exemplo para Supabase MCP → skill:

```bash
# Operações mais usadas do Supabase (sem MCP)

# Ver diff de schema pendente
supabase db diff

# Aplicar migrations locais ao banco remoto
supabase db push

# Criar nova migration
supabase migration new <nome>

# Executar query SQL avulsa
supabase db execute --sql "SELECT count(*) FROM users;"

# Ver logs de funções edge
supabase functions logs <nome-da-funcao>
```

### Passo 4 — Desativar o MCP por projeto

No `.aiox-ai-config.yaml` do projeto:

```yaml
mcp:
  disabledMcpServers:
    - supabase  # substituído por skill supabase-cli
```

Ou via Claude Code settings do projeto (`.claude/settings.json`):

```json
{
  "mcpServers": {
    "supabase": { "disabled": true }
  }
}
```

### Passo 5 — Documentar a economia

Registrar no `STATE.md` do projeto:

```markdown
## MCP Economy

- **supabase MCP** desativado: ~45 tools removidas, ~2K tokens economizados por sessão
- Substituído por: skill `source/skills/supabase-cli/SKILL.md`
- Operações cobertas: db diff, db push, migration new, execute, functions logs
```

## Exemplo real: Supabase MCP → CLI

O Supabase MCP expõe ~45 tools. As 5 mais usadas em projetos Lovable:

1. `db diff` — ver mudanças de schema antes de push
2. `db push` — aplicar migrations
3. `migration new` — criar migration
4. `db execute` — query avulsa para debug
5. `functions logs` — ver logs de edge functions

Essas 5 viram 5 linhas de bash. O MCP fica desativado. Resultado: -45 tools registradas, -2K tokens de descrição por sessão.

## Output

- Skill CLI criada em `source/skills/<nome>-cli/SKILL.md`
- MCP desativado no projeto via `disabledMcpServers`
- Economia de tools/tokens documentada em `STATE.md`
- Nenhuma funcionalidade perdida — só uso mais eficiente
