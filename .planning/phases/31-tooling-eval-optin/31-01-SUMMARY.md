---
phase: 31-tooling-eval-optin
plan: "01"
subsystem: docs/decisions
tags: [adr, tooling, evaluation, gsd-browser, agent-inbox, opt-in]
dependency_graph:
  requires: []
  provides:
    - docs/decisions/gsd-browser-pilot-evaluation.md
    - docs/decisions/agent-inbox-optin.md
  affects:
    - source/skills/frontend-visual-loop/SKILL.md (referenciada, nao modificada)
    - source/rules/common/mcp-hygiene.md (referenciada, nao modificada)
tech_stack:
  added: []
  patterns:
    - ADR (Architecture Decision Record) para avaliacao de ferramenta
    - Guia opt-in com higiene de MCP documentada
key_files:
  created:
    - docs/decisions/gsd-browser-pilot-evaluation.md
    - docs/decisions/agent-inbox-optin.md
  modified: []
decisions:
  - "R6-14: gsd-browser decisao Adiar ate npm/crates.io publicados E caso real de regressao visual"
  - "R6-15: agent-inbox documentado como MCP opt-in por sessao, nunca global, exclusivo @devops"
metrics:
  completed_date: "2026-06-16"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
  deviations: 0
requirements_closed:
  - R6-14
  - R6-15
---

# Phase 31 Plan 01: Tooling Eval Opt-in Summary

**One-liner:** ADR de avaliacao do gsd-browser (decisao Adiar com condicao objetiva) + guia opt-in do agent-inbox para testes de auth-email.

---

## Arquivos Criados

### 1. `docs/decisions/gsd-browser-pilot-evaluation.md`

ADR estruturado que avalia o gsd-browser como substituto hipotetico do chrome-devtools MCP nas skills `frontend-visual-loop` e `web-quality`.

Cobre os 4 criterios mandatorios:
- **Custo de token:** vantagem estrutural (CLI vs MCP overhead), nao medida empiricamente
- **Determinismo:** vantagem clara via versioned refs (`@v1:e1`) e assertions JSON
- **Instalacao Rust:** binario pre-compilado, mas curl/bash sem hash e npm/crates.io ausentes
- **Churn de org:** `gsd-build` e `open-gsd` sao orgs distintas; sem historico verificavel

Referencia direta: `source/skills/frontend-visual-loop/SKILL.md` (motor atual, papel hipotetico do gsd-browser).

### 2. `docs/decisions/agent-inbox-optin.md`

Guia de uso opt-in do agent-inbox (MCP para e-mails temporarios) em testes de auth-email nos projetos nfideia, ideiapartner e cfoai-grupori.

Cobre:
- 6 ferramentas disponíveis (create_inbox, check_inbox, wait_for_email, verify_email, list_inboxes, delete_inbox)
- Proibicoes absolutas (NUNCA prod, NUNCA global)
- Protocolo de ativacao por sessao (opcoes A e B) — exclusivo @devops
- Higiene de MCP: referencia `source/rules/common/mcp-hygiene.md`; nao conta nos ≤10 MCPs ativos permanentes
- Padrao de chamada para verificacao de e-mail (sequencia de 5 passos)
- Limitacoes conhecidas (bloqueio por servico, sem persistencia, sem anexos)

---

## Decisao Registrada no ADR do gsd-browser

**Opcao escolhida: Adiar**

**Condicao objetiva dupla (ambas simultaneamente):**
1. Pacotes publicados em npm ou crates.io — permitindo pino de versao via gerenciador de pacotes
2. Caso real de regressao visual nao detectada pelo chrome-devtools MCP no IdeiaOS

**Fundamentacao:**
- Risco de supply chain: curl/bash sem verificacao de hash e npm/crates.io ausentes
- Churn de org desconhecida (`gsd-build`) sem historico de manutencao verificavel
- Zero medicao de ganho de token no contexto IdeiaOS
- Motor atual (chrome-devtools MCP) e suficiente para o loop de 3 iteracoes

---

## Confirmacao: Nada Foi Instalado

- Nenhum binario baixado ou executado
- Nenhum arquivo `settings.json` modificado
- Nenhuma skill alterada
- Nenhum MCP adicionado ou removido
- Documentacao-only, conforme o objetivo do plano

---

## Requirements Fechados

- **R6-14:** ADR do gsd-browser com decisao formal (Adiar) e 4 criterios documentados — FECHADO
- **R6-15:** Doc opt-in do agent-inbox com protocolo de higiene e proibicao de prod — FECHADO

---

## Deviations from Plan

None - plano executado exatamente conforme especificado. Os arquivos temporarios `/tmp/_cmp_gsd-browser` e `/tmp/_cmp_agent-inbox` nao existiam, mas o plano contem todo o conteudo inline necessario.

---

## Threat Flags

Nenhum novo superficie de seguranca introduzido — documentacao-only.

Os threats T-31-01 (curl/bash sem hash), T-31-02 (info disclosure via mail.tm), T-31-03 (auto-installer global) e T-31-SC (supply chain npx) foram documentados nos ADRs conforme o threat model do plano.

---

## Self-Check

| Artifact | Status |
|----------|--------|
| `docs/decisions/gsd-browser-pilot-evaluation.md` | FOUND |
| `docs/decisions/agent-inbox-optin.md` | FOUND |
| Header `# SOURCE: IdeiaOS v2` em ambos | PASS |
| Secao `## Decisao` no ADR do gsd-browser | PASS |
| Decisao "Adiar" com condicao objetiva | PASS |
| Referencia a `frontend-visual-loop/SKILL.md` | PASS |
| Proibicao `NUNCA em ambiente de producao` | PASS |
| Referencia a `mcp-hygiene.md` | PASS |
| Sem `<!--` em ambos os arquivos | PASS |
| Nenhum binario instalado | PASS |
| Nenhum settings.json modificado | PASS |

**Self-Check: PASSED**
