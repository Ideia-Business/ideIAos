# SOURCE: IdeiaOS v2 | derivado da avaliação de chopratejas/headroom (Apache-2.0) — padrão minerado, dependência NÃO adotada

# Proposta de Mudança: tool-output-compressor

**Data:** 2026-06-21
**Autor:** Deia (sessão de análise headroom)
**Status:** rascunho

---

## Por quê

Saídas de ferramenta volumosas (logs de build/CI, JSON tabular de APIs/DB, resultados de
busca de código, dumps de teste) entram **verbatim** no contexto do agente e consomem
tokens de forma desproporcional ao sinal que carregam. A avaliação do `headroom`
(2026-06-21, memória [[headroom-eval-2026-06]]) confirmou empiricamente o tamanho do
desperdício e a viabilidade da cura:

- log repetitivo → template: **99,7%** de redução medida (11.199 → 39 tokens);
- JSON tabular baixa-cardinalidade → schema-header + linhas CSV: **57,9%**;
- JSON tool-output alta-cardinalidade: **38,4%**.

O `headroom` **não** foi adotado como dependência/proxy/MCP por três razões verificadas:
colisão com a letra do `mcp-hygiene` (`ANTHROPIC_BASE_URL`), economia ~$0 em sessão de
subscription, e inaplicabilidade às superfícies reais (Lovable-hosted e Supabase Edge/Deno).
A **ideia**, porém, é de alto valor e **stack-agnóstica**. Esta proposta a nativiza no
IdeiaOS como capability **CLI-First, determinística e sem dependência externa** — o oposto
arquitetural do proxy: nada de rede, nada de egress, nada de base_url.

O problema que isto resolve não existe hoje: as skills `/context-engineering`,
`/cost-tracking` e a rule `token-economy` são **disciplina advisory** (orientam o humano/agente);
**nenhuma** delas é um **compressor determinístico de artefato**. Este é o delta net-new.

---

## O que muda

Depois desta mudança, o IdeiaOS passa a oferecer um comportamento observável novo:

- Um agente (ou um hook/skill) pode submeter um **artefato de saída de ferramenta** a um
  compressor local que devolve uma versão **menor em tokens** e **semanticamente equivalente
  para o consumo do modelo**, escolhendo o tratamento pelo **tipo de conteúdo** detectado.
- A compressão é **reversível por padrão (CCR)**: o conteúdo derrubado é substituído por uma
  **sentinela com hash**, e o original fica recuperável sob demanda enquanto válido.
- A compressão **nunca toca a mensagem do usuário** — só atua sobre saída de ferramenta ou
  conteúdo explicitamente marcado como compressível.
- A operação **reporta economia real medida por tokenizer** (nunca número inventado) e
  sinaliza sucesso/falha por **exit-code binário** (não corrompe em silêncio).
- Tudo roda **localmente, sem rede**: se o compressor não estiver disponível ou não
  reconhecer o conteúdo, o original passa intacto (**fail-open**).

Esta proposta registra **apenas o contrato de comportamento** (propose → delta → tasks).
Nenhuma implementação é feita agora; o `tasks.md` alimenta um ciclo GSD futuro.

---

## Capabilities afetadas

### Novas

- **tool-output-compressor** — compressor local, determinístico e reversível de saídas de
  ferramenta (log/JSON/search), CLI-First, que reduz tokens antes do conteúdo entrar no
  contexto, sem rede e sem tocar a intenção do usuário.

### Modificadas

- _(nenhuma)_

### Removidas

- _(nenhuma)_

---

## Impacto

| Dimensão | Descrição |
|----------|-----------|
| Usuários afetados | Todo agente IdeiaOS (Claude Code/Cursor) que ingere saída de ferramenta volumosa; opt-in por chamada/hook. |
| Compatibilidade | Aditivo puro. Sem breaking change. Sem dependência nova (Constituição art. VI / `token-economy`: feature nativa antes de dep). |
| Risco | Baixo — fail-open e reversível por design; o modo lossless garante round-trip verificável por sha256. O risco residual (perda em modo lossy sem retrieve) é controlado por contrato (R4/R3). |
| Dependências | `antifragile-gates` (verificação por exit-code), `token-economy` (economia medida), `context-packet-handoffs` (padrão de budget/hash — primo do CCR). Não depende de `headroom`. |
