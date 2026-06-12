---
name: cost-tracking
description: "Rastreia e reduz custo de tokens/modelo por ação: model routing (haiku/sonnet/opus), MCP→CLI, contexto enxuto, strategic compact. Use proativamente em sessões longas ou ao escolher modelo de um agent."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: cost-tracking

**Idioma:** Português brasileiro.

---

## Quando usar

- Sessão longa (>30 tool calls) onde custo acumulado começa a pesar.
- Ao definir o campo `model:` de um novo agent.
- Ao identificar gargalo de custo em pipeline de agentes.
- Revisão periódica de arquitetura multi-agent para reduzir desperdício.

---

## Processo

### 1. Classificar a ação pelo tipo cognitivo

| Tipo de ação | Modelo recomendado | Motivo |
|-------------|-------------------|--------|
| Busca, recuperação, listagem, grep, leitura simples | haiku | Repetitivo, baixa complexidade |
| Classificação, filtragem, formatação, tradução | haiku | Padrão, não requer raciocínio profundo |
| Implementação, code review, debugging, análise | sonnet | Equilíbrio custo/capacidade |
| Arquitetura, segurança, decisão crítica, planejamento | opus | Alta complexidade, baixa frequência |

Haiku é ~5× mais barato que sonnet e ~20× mais barato que opus.

### 2. Preferir CLI + skill a MCP pesado

MCP tools com contexto persistente consomem tokens em cada chamada.
Quando possível, usar Bash direto (grep, jq, find) em vez de MCP de filesystem.
Reservar MCP para operações que não têm equivalente CLI eficiente.

### 3. Manter contexto enxuto

- Não carregar arquivos completos quando um `grep` resolve.
- Usar `head -N` para arquivos grandes quando só o início importa.
- Remover do contexto ativo arquivos que já foram processados.
- Preferir resumos a dumps completos (ex.: resultado de `ls` em vez de conteúdo de cada arquivo).

### 4. `/compact` estratégico

Em sessões longas, compactar contexto proativamente:
- Trigger recomendado: ~50 tool calls ou quando contexto > 60%.
- O hook `precompact-state-save` salva STATE.md automaticamente antes do compact.
- Após compact: recarregar apenas o que for necessário para a próxima tarefa.

### 5. Estimar economia

Ao propor mudança de modelo para um agent, calcular:
- Frequência de uso (chamadas/dia estimado).
- Custo médio por chamada (tokens × preço/token).
- Delta mensal estimado.

Documentar no SUMMARY da task.

---

## Output

- Recomendação de modelo por ação ou por agent (tabela).
- Estimativa de economia mensal quando relevante.
- Ajuste no campo `model:` do AGENT.md do agent em questão.

---

## Anti-patterns

- Usar opus para busca simples ("é mais preciso") — desperdício.
- MCP filesystem para leitura de arquivo único (Bash é mais barato).
- Nunca compactar em sessões longas (contexto inflado degrada qualidade e custo).
- Não documentar escolha de modelo no AGENT.md (decisão se perde).

---

## Relações

- Complementa `source/rules/common/token-economy.md` (regra de economia de tokens).
- Pareia com `benchmark-optimization-loop` para otimização orientada a dados.
- Informa escolha de `model:` em todos os AGENTs do IdeiaOS.
