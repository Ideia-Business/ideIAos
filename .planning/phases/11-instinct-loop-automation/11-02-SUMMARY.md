---
phase: 11-instinct-loop-automation
plan: "02"
subsystem: instinct-loop
tags: [instincts, skills, sentinel, loop-closure, documentation]
dependency_graph:
  requires: [11-01]
  provides: [instinct-analyze-sentinel-instruction, loop-closure-documented]
  affects: [source/skills/instinct-analyze/SKILL.md]
tech_stack:
  added: []
  patterns: [sentinel-file-pattern, retry-on-failure]
key_files:
  created: []
  modified:
    - source/skills/instinct-analyze/SKILL.md
decisions:
  - "Passo 9 atualiza sentinela APENAS em conclusao bem-sucedida — falha = no-op = retry automatico na proxima sessao"
  - "Secao Trigger automatico como subsecao de Quando rodar (nao secao de nivel top) — mantém estrutura coesa"
  - "Relacoes bidirecional: Aciona sentinela + Acionado por hook — documenta o loop completo"
metrics:
  duration: "~5 minutos"
  completed: "2026-06-12T16:45:00Z"
  tasks_completed: 1
  files_modified: 1
---

# Phase 11 Plan 02: instinct-analyze — Trigger Automatico + Sentinela Summary

**One-liner:** instinct-analyze/SKILL.md com secao Trigger automatico via Stop hook, Passo 9 que fecha o loop atualizando o sentinela, e remocao de referencias ao gap de scheduler.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Atualizar instinct-analyze/SKILL.md — trigger automatico + sentinela + remover gap | fe7d5fb | source/skills/instinct-analyze/SKILL.md |

---

## What Was Built

### instinct-analyze/SKILL.md — 3 mudanças cirúrgicas

**Mudança 1 — Secao "Trigger automatico (Stop hook)" em "Quando rodar":**
- Primeiro item de "Quando rodar" agora é a subsecao dedicada ao trigger via hook
- Texto descreve: observe-session-end.sh dispara haiku quando obs > sentinela
- Bullet anterior sobre "sessões não-analisadas (comparar updated)" removido — substituído pelo texto correto do hook

**Mudança 2 — Passo 9: Registrar conclusão (sentinela):**
- Após Passo 8 (Validação de privacidade), novo Passo 9
- python3 inline (sem jq) escreve timestamp ISO no arquivo `.last-analyzed-${PROJETO_SLUG}`
- Instrução explícita: NAO atualizar se análise falhar — retry automático

**Mudança 3 — Anti-padroes e Relacoes:**
- Anti-padrao adicionado: "Nao atualizar .last-analyzed apos análise bem-sucedida — causa re-análise desnecessária"
- Relacoes: adicionado "Aciona: .last-analyzed-<projeto>" e "Acionado por: observe-session-end.sh haiku"

---

## Loop Completo Documentado

```
observe-session-end.sh (Stop hook)
  → gate: ts_obs > .last-analyzed-<proj>
  → spawn: claude haiku -p /instinct-analyze (background, timeout 120)
    → instinct-analyze: Passos 1-8 (análise, dedup, privacidade)
    → Passo 9: atualiza ~/.ideiaos/instincts/.last-analyzed-<proj>
  → próxima sessão: gate verifica sentinela atualizado → skip se nenhuma obs nova
```

---

## Deviations from Plan

Nenhum. Plano executado exatamente conforme especificado.

---

## Verification Results

| Critério | Status |
|----------|--------|
| "Trigger automatico" presente | PASS (1 ocorrência) |
| "last-analyzed" presente | PASS (4 ocorrências) |
| "Passo 9" presente | PASS (1 ocorrência) |
| SOURCE: IdeiaOS v2 | PASS |
| Sem jq | PASS (0 ocorrências) |
| Sem scheduler/gap de scheduler | PASS (0 ocorrências) |
| Sem HTML comments | PASS |
| Passos 1-8 intactos | PASS |
| Relacoes atualizadas (Aciona/Acionado) | PASS |
| Anti-padrao de sentinela adicionado | PASS |

---

## Threat Surface

- T-11-05: Tampering via analise falha → Passo 9 instrui NAO atualizar em falha — mitigado
- T-11-06: sentinela contem apenas timestamp ISO — aceito

## Known Stubs

Nenhum. SKILL.md documenta o Passo 9 com instrucao de python3 inline completa.

## Self-Check: PASSED

- source/skills/instinct-analyze/SKILL.md: existe com Trigger automatico + Passo 9
- Commit fe7d5fb existe no git log
