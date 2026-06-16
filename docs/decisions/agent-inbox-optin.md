# SOURCE: IdeiaOS v2

# agent-inbox: Guia de Uso Opt-in para Testes de Auth-Email

**Data:** 2026-06-16
**Status:** Referência opt-in — não instalado by default
**Escopo:** testes de auth-email em projetos-filho (nfideia, ideiapartner, cfoai-grupori); nunca em produção

---

## O que é o agent-inbox

MCP server que cria endereços de e-mail temporários reais sob demanda. Projetado para testes de fluxo de autenticação por e-mail sem exigir contas reais ou API keys.

**Características principais:**

| Propriedade | Valor |
|-------------|-------|
| API keys | Nenhuma |
| Contas externas | Nenhuma |
| Provider primário | mail.tm |
| Provider fallback | 1secmail |
| Persistência | Memória apenas — não sobrevive a restart do servidor |
| Auto-cleanup | Inboxes deletados no SIGINT/SIGTERM do servidor |
| Instalação | `npx -y gsd-agent-inbox` |

**6 ferramentas disponíveis:**

| Ferramenta | Descrição |
|------------|-----------|
| `create_inbox` | Cria inbox temporária com prefixo e nome descritivo |
| `check_inbox` | Verifica mensagens na inbox |
| `wait_for_email` | Aguarda chegada de e-mail com timeout configurável |
| `verify_email` | One-shot: aguarda e-mail, extrai link, acessa via HTTP |
| `list_inboxes` | Lista inboxes ativas na sessão |
| `delete_inbox` | Deleta inbox imediatamente |

**Inboxes nomeadas:** `create_inbox` com `name: "main"` → referenciável por nome em chamadas subsequentes, sem precisar armazenar o endereço gerado.

---

## Quando usar (opt-in)

Ativar o agent-inbox somente para os cenários abaixo:

- Testes de fluxo de sign-up com verificação de e-mail (Supabase Auth, Resend, SendGrid, AWS SES)
- Testes de convite por e-mail ou magic link
- Qualquer cenário de teste em que um agente precisa receber e-mail sem conta real

**Projetos-alvo:** nfideia, ideiapartner, cfoai-grupori.

---

## Quando NÃO usar (proibições absolutas)

- NUNCA em ambiente de produção
- NUNCA com dados sensíveis reais (e-mails não são criptografados end-to-end nos providers descartáveis)
- NUNCA tentando persistir inboxes além da sessão MCP (por design não sobrevivem a restart)
- NUNCA para serviços que bloqueiam domínios descartáveis sem alertar o usuário primeiro — se o sign-up for rejeitado, reportar ao usuário, não tentar contornar
- NUNCA instalar como MCP global sem consentimento explícito de `@devops`

---

## Higiene de MCP

Referência: [`source/rules/common/mcp-hygiene.md`](../../source/rules/common/mcp-hygiene.md)

**Classificação de risco:** Médio — acesso a rede externa (mail.tm e 1secmail).

**Regras aplicáveis:**

| Regra | Detalhe |
|-------|---------|
| Limite de MCPs ativos | O agent-inbox NÃO conta como um dos ≤10 MCPs ativos permanentes |
| Escopo temporal | Ativar somente durante a sessão de teste; desativar imediatamente após |
| Configuração global proibida | NÃO deve aparecer em `~/.claude/settings.json` como MCP permanente |
| Configuração de projeto | Usar `.claude/settings.json` do projeto-filho com `disabledMcpServers` quando não em uso ativo |

**Risco de supply chain (T-31-SC):** O pacote `gsd-agent-inbox` no npm deve ser verificado por `@devops` antes de qualquer uso real. Confirmar que o pacote é legítimo em [npmjs.com/package/gsd-agent-inbox](https://npmjs.com/package/gsd-agent-inbox) antes da primeira ativação.

---

## Como ativar (por sessão — exclusivo @devops)

Ativação manual por projeto-filho. `@devops` é o único agente autorizado a executar ativação de MCPs.

**Opção A — Claude Code (temporária, por sessão):**

```bash
claude mcp add agent-inbox -- npx -y gsd-agent-inbox
```

A configuração persiste apenas enquanto a sessão do Claude Code estiver ativa. Não modifica arquivos de configuração permanentes.

**Opção B — Configuração de projeto (`.claude/settings.json` do projeto-filho):**

```json
{
  "mcpServers": {
    "agent-inbox": {
      "command": "npx",
      "args": ["-y", "gsd-agent-inbox"]
    }
  }
}
```

Após o teste: mover a entrada para `disabledMcpServers` ou remover o bloco.

**Proibido — auto-installer interativo:**

```bash
npx gsd-agent-inbox   # NÃO usar em TTY interativo
```

O auto-installer detecta o Claude Code instalado e modifica `~/.claude/settings.json` globalmente, violando a regra de opt-in e o limite de MCPs ativos permanentes.

---

## Como usar (padrão de chamada)

Sequência típica para teste de verificação de e-mail:

```
1. create_inbox
   prefix: "signup-test"
   name: "test-main"
   → retorna: { address: "signup-test-abc@mail.tm", name: "test-main" }

2. [executar fluxo de sign-up no produto usando o endereço retornado]

3. verify_email
   address: "test-main"
   subject_contains: "confirm"
   → aguarda e-mail, extrai link de confirmação, acessa via HTTP

4. [verificar estado esperado no produto]

5. delete_inbox
   address: "test-main"
   → limpar imediatamente após o teste
```

**Regra:** sempre deletar a inbox ao final do teste. Não deixar inboxes abertas desnecessariamente.

---

## Como desativar após uso

**Opção A (sessão temporária):**

```bash
claude mcp remove agent-inbox
```

**Opção B (configuração de projeto):**

Remover ou mover o bloco `agent-inbox` de `mcpServers` para `disabledMcpServers` no `.claude/settings.json` do projeto-filho, e reiniciar a sessão do Claude Code.

---

## Limitações conhecidas

| Limitação | Detalhe |
|-----------|---------|
| Bloqueio por serviço | Alguns serviços rejeitam domínios descartáveis (mail.tm, 1secmail) — se rejeitado, reportar ao usuário; não tentar contornar |
| Sem persistência | Inboxes não sobrevivem restart do MCP server — projetar testes como stateless |
| Sem suporte a anexos | text/HTML apenas; sem anexos binários |
| Controle de provider | Fallback automático mail.tm → 1secmail sem controle sobre qual domínio será usado |
| Domínio variável | O endereço gerado inclui o domínio do provider — pode diferir entre sessões |

---

## Skill do agent-inbox (instalação opcional)

O agent-inbox distribui uma `SKILL.md` que instrui o agente a usar inboxes automaticamente em fluxos de auth. Instalação é operação de `@devops` e requer revisão do conteúdo antes de executar:

```bash
mkdir -p ~/.claude/skills/agent-inbox
curl -fsSL https://raw.githubusercontent.com/gsd-build/agent-inbox/main/skill/SKILL.md \
  -o ~/.claude/skills/agent-inbox/SKILL.md
```

Revisar o conteúdo do arquivo baixado antes de qualquer uso. A skill instrui o agente a usar as ferramentas do MCP — verificar que não contém instruções de persistência de credenciais ou acesso a recursos fora do escopo de testes.

---

## Referências

- Regras de higiene de MCP: [`source/rules/common/mcp-hygiene.md`](../../source/rules/common/mcp-hygiene.md)
- Autoridade de ativação de MCP: [`.claude/rules/agent-authority.md`](../../.claude/rules/agent-authority.md)
- Limite de MCPs ativos: ≤10 permanentes conforme `mcp-hygiene.md`
