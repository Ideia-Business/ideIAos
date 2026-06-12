---
name: codebase-onboarding
description: "Mapeia uma codebase desconhecida em um guia navegável: arquitetura, entrypoints, convenções, gotchas. Use proativamente ao entrar em projeto/módulo novo."
---

# SOURCE: ECC MIT affaan-m/ECC | adapted: IdeiaOS v2

# Skill: codebase-onboarding

**Idioma:** Português brasileiro.

---

## Quando usar

- Primeiro contato com um repositório ou módulo desconhecido.
- Retorno a um projeto após longo período sem mexer nele.
- Receber manutenção de código escrito por outro time/dev.

---

## Processo

### 1. Detectar stack

```bash
ls package.json pyproject.toml Cargo.toml go.mod 2>/dev/null
cat package.json | jq '.dependencies | keys' 2>/dev/null | head -20
```

Identificar: linguagem, framework principal, ORM/DB, plataforma de deploy.

### 2. Mapear entrypoints

- Web: `src/main.ts`, `app/page.tsx`, `index.html`, `server.ts`.
- CLI: `bin/`, `cmd/`, `__main__.py`.
- API: rotas registradas (Express `app.use`, Next `app/api/`, FastAPI `@router`).
- Listar os 5 entrypoints mais importantes.

### 3. Traçar 1 fluxo end-to-end

Escolher o fluxo mais representativo (ex.: login, criação de entidade principal).
Seguir: request → middleware → handler → service → DB → response.
Anotar cada salto e o que acontece nele.

> Pode delegar busca de arquivos ao agent `code-explorer` em haiku para economizar tokens.

### 4. Listar convenções e gotchas

- Convenções: estilo de nomes (camelCase vs snake_case), estrutura de diretórios, padrão de erro, autenticação.
- Gotchas: partes contraintuitivas, áreas frágeis, dependências circulares conhecidas, TODOs críticos.

---

## Output

`ONBOARDING.md` curto (30–60 linhas) com seções:

```markdown
## Stack
## Como rodar localmente
## Entrypoints principais
## Fluxo de referência: <nome>
## Convenções
## Gotchas e áreas de atenção
```

---

## Anti-patterns

- Ler todos os arquivos antes de formar hipótese (análise sem foco).
- Onboarding de 500 linhas que ninguém lê.
- Pular gotchas — são os mais valiosos para quem vem depois.

---

## Diferença de `code-tour`

- `codebase-onboarding`: visão geral do **projeto** (stack, estrutura, como rodar, gotchas).
- `code-tour`: guia de **um fluxo específico** passo a passo (arquivo:linha → arquivo:linha).

Use onboarding primeiro; use code-tour para aprofundar um fluxo específico depois.
