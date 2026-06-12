# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2
---
name: llms-txt
description: "Gera docs LLM-otimizadas (llms.txt) para uma codebase/produto: índice navegável que um agente lê para entender o projeto rápido. Use proactively para projetos que serão consumidos por IA."
---

# Skill: llms.txt — Docs LLM-Otimizadas

## Quando usar

- Projeto ou produto que será **consumido por IAs** (agents, assistants, automações).
- Codebase grande onde um agente novo precisa se orientar rápido sem ler tudo.
- API pública ou biblioteca open-source que você quer tornar acessível para agentes externos.
- Antes de expor o projeto para integração via MCP ou contexto de sistema.

## Princípio: sinal, não ruído

O `llms.txt` é um **índice navegável**, não um dump de documentação. Cada linha deve responder: "por que um agente leria este arquivo?". Se a resposta não for clara, a linha não entra.

## Processo

### Passo 1 — Mapear entrypoints e docs existentes

```bash
# Listar arquivos de documentação relevantes
find . -name "*.md" -not -path "*/node_modules/*" -not -path "*/.planning/*" | head -30
ls -la docs/ 2>/dev/null || echo "sem docs/"
cat README.md | head -50
```

Identificar:
- Arquivo principal de onboarding (README, AGENTS.md, IDEIAOS.md)
- Documentação de API (se existir)
- Decisões arquiteturais (docs/decisions/, .planning/)
- Configurações relevantes (.aiox-ai-config.yaml, CLAUDE.md)

### Passo 2 — Estrutura do llms.txt

O arquivo segue o padrão da spec [llms.txt](https://llmstxt.org):

```
# <Nome do Projeto>

> <Descrição de 1 linha — o que é, para quem, qual stack>

## Docs

- [<Titulo>](<URL ou path relativo>): <1 linha — por que ler>
- [<Titulo>](<URL ou path relativo>): <1 linha — por que ler>

## Código

- [<Titulo>](<path>): <1 linha — o que contém>
```

### Passo 3 — Gerar o arquivo

Criar `llms.txt` na raiz do projeto-alvo. Manter **enxuto**:
- Máximo 30-40 linhas.
- Cada entrada: nome + path/URL + descrição em 1 linha.
- Priorizar: AGENTS.md, CLAUDE.md, docs de decisão, principais módulos.
- Excluir: node_modules, arquivos gerados, testes unitários, configs de lint.

### Passo 4 — Validar

Pedir para um agente ler só o `llms.txt` e responder: "você consegue entender o projeto o suficiente para começar a trabalhar?" Se não conseguir, adicionar o que falta.

## Exemplo de llms.txt para projeto IdeiaOS

```
# IdeiaOS — Sistema Operacional de Desenvolvimento IA

> Framework de orquestração de agentes IA para a Ideia Business. Combina AIOX-Core, GSD, Lovable, Fase A e Continuation em um sistema unificado com entry point único (/idea).

## Docs principais

- [AGENTS.md](AGENTS.md): identidade do projeto, papéis e protocolo de sessão
- [CLAUDE.md](CLAUDE.md): instruções obrigatórias para Claude Code
- [docs/IDEIAOS.md](docs/IDEIAOS.md): especificação completa do sistema
- [STATE.md](STATE.md): estado operacional atual do projeto

## Configuração

- [manifests/modules.json](manifests/modules.json): catálogo de 60 módulos instaláveis
- [setup.sh](setup.sh): instalação idempotente do ambiente

## Skills principais

- [source/skills/idea/SKILL.md](source/skills/idea/SKILL.md): orquestrador — roteia qualquer pedido
- [source/skills/ideiaos-catalog/SKILL.md](source/skills/ideiaos-catalog/SKILL.md): lista módulos instalados vs disponíveis
```

## Output

Arquivo `llms.txt` na raiz do projeto-alvo, com índice navegável que permite a qualquer agente entender o projeto em menos de 2 minutos de leitura.
