---
phase: "05"
plan: "05-02"
status: complete
subsystem: instincts-engine
commits:
  - hash: "3303c7a"
    message: "wip: autosync — docs/instincts/instincts-layout.md committed by autosync before feat commit"
  - hash: "24f1e92"
    message: "feat(05-02): motor de instincts — /instinct-analyze + /instinct-status + /learn + layout"
tags: [instincts, skills, haiku, background-agent, confidence, learn, status, wave1]
requires: []
provides:
  - skill-instinct-analyze
  - skill-instinct-status
  - skill-learn
  - instincts-storage-layout
affects:
  created:
    - source/skills/instinct-analyze/SKILL.md
    - source/skills/instinct-status/SKILL.md
    - source/skills/learn/SKILL.md
    - docs/instincts/instincts-layout.md
  modified: []
tech_stack:
  added: []
  patterns:
    - "frontmatter YAML first (--- line 1), then # SOURCE: IdeiaOS v2, then PT-BR body"
    - "confidence scale 0.3-0.9, dedup by slug(trigger), scope project|global"
    - "haiku background agent for batch analysis, 0.5 for manual /learn"
key_files:
  created:
    - source/skills/instinct-analyze/SKILL.md
    - source/skills/instinct-status/SKILL.md
    - source/skills/learn/SKILL.md
    - docs/instincts/instincts-layout.md
  modified: []
decisions:
  - "Schema do instinct definido como contrato central: trigger, action, confidence 0.3-0.9, domain, scope, evidence_count, created, updated, source"
  - "Dedup por slug(trigger) compartilhado entre /instinct-analyze e /learn — mesma regra nos dois"
  - "Confidence manual (/learn) nasce em 0.5; análise automática começa em 0.3-0.6 conforme evidências"
  - "docs/instincts/instincts-layout.md já entrou no repo via autosync (commit 3303c7a) antes do feat commit — conteúdo correto, documentado como desvio esperado"
metrics:
  duration: "~25min"
  completed: "2026-06-11"
  tasks_completed: 3
  files_created: 4
---

# Phase 05 Plan 02: Motor de Instincts (Wave 1) Summary

**One-liner:** Skills /instinct-analyze (haiku background), /instinct-status (barras de confidence) e /learn (manual 0.5) com schema centralizado de instincts atômicos em `~/.ideiaos/instincts/`.

---

## O que foi construído

### Task 1 — Schema do instinct + doc do layout

`docs/instincts/instincts-layout.md` — contrato central do sistema de instincts:
- Árvore `~/.ideiaos/instincts/{project,global}/` com convenção de nomenclatura (prefixo projeto para scope=project)
- Schema completo de frontmatter: trigger, action, confidence, domain, scope, project, evidence_count, created, updated, source
- Tabela de regras de confidence (0.3 análise 2 evidências → 0.6 análise 5+, 0.5 manual, reforço +0.1 cap 0.9)
- Algoritmo de dedup por `slug(trigger)` com incremento de evidence_count e recálculo de confidence
- Seção de decay (campo `updated` documentado; aplicação efetiva fica em `/evolve` 05-03)
- Sync multi-máquina: 1 arquivo por instinct para merges não-conflitantes

### Task 2 — Skill /instinct-analyze + /instinct-status

**`source/skills/instinct-analyze/SKILL.md`** (~130 linhas):
- Pipeline de 8 passos: localizar jsonl → parse defensivo → agrupar padrões → formular instincts atômicos → calcular confidence → inferir domain/scope → dedup e escrever → validação de privacidade
- Instrução explícita de invocação como agente haiku background (Task tool, `model: claude-haiku`)
- Tabela de mapeamento `ext/bash_verb → domain`
- Privacidade: sem conteúdo literal, sem secrets, abstrair sempre
- Saída compacta: `🧬 Instincts atualizados: N novos, M reforçados`

**`source/skills/instinct-status/SKILL.md`** (~90 linhas):
- Varredura de `~/.ideiaos/instincts/{project,global}/` com filtro por projeto atual
- Parse de frontmatter via `python3` inline (sem jq)
- Barra de confidence visual: `[██████░░░░] 0.6`
- Marcador `★ elegível /evolve` para confidence ≥ 0.7
- Saída agrupada: scope → domain, ordenada por confidence DESC

### Task 3 — Skill /learn (extração manual mid-session)

**`source/skills/learn/SKILL.md`** (~100 linhas):
- Gate leve: 1 pergunta "isso se repete em sessões futuras?"
- confidence: 0.5 fixo no nascimento (manual sempre)
- Dedup idêntico ao /instinct-analyze: mesma regra de slug(trigger) e reforço
- Saída: `🧬 Instinct registrado: "<trigger>" → "<action>" (confidence 0.5, domain X, scope Y)`

---

## Verificação (10 checks)

| # | Check | Resultado |
|---|-------|-----------|
| 1 | 3 skills existem | PASS |
| 2 | frontmatter YAML 1ª linha (`---`) | PASS — todos os 3 |
| 3 | `name:` correto no frontmatter | PASS — instinct-analyze, instinct-status, learn |
| 4 | `# SOURCE: IdeiaOS v2` presente | PASS — 3/3 arquivos |
| 5 | Sem `<!--` (HTML comment) | PASS — vazio |
| 6 | doc do layout existe | PASS |
| 7 | schema documenta confidence 0.3-0.9 | PASS |
| 8 | instinct-analyze cita haiku | PASS |
| 9 | /learn usa confidence 0.5 | PASS |
| 10 | PT-BR (sanidade) | PASS — todo texto de usuário em português |

---

## Deviations from Plan

### Auto-handled: docs/instincts/instincts-layout.md committed by autosync

- **Found during:** Task 1, após criar o arquivo
- **Situação:** O LaunchAgent de autosync do Mac-mini commitou `docs/instincts/instincts-layout.md` como `wip: autosync` (commit `3303c7a`) antes do commit `feat(05-02)`. O conteúdo estava correto — era exatamente o arquivo que havia sido criado.
- **Ação:** Verificado conteúdo, confirmado correto. O commit `feat(05-02)` cobre os 3 SKILL.md; a presença do layout no commit anterior foi documentada na mensagem de commit.
- **Impacto:** Nenhum. Plano menciona explicitamente este cenário como esperado no contexto de execução paralela.

---

## Known Stubs

Nenhum — todos os arquivos são documentação de skill (não contêm dados dinâmicos ou placeholders de runtime).

---

## Threat Flags

Nenhum — apenas arquivos de documentação/skill em `source/skills/` e `docs/`. Nenhuma nova superfície de rede, auth ou acesso a dados introduzida.

---

## Self-Check: PASSED

| Item | Result |
|------|--------|
| source/skills/instinct-analyze/SKILL.md | FOUND |
| source/skills/instinct-status/SKILL.md | FOUND |
| source/skills/learn/SKILL.md | FOUND |
| docs/instincts/instincts-layout.md | FOUND |
| commit 24f1e92 | FOUND |
| commit 3303c7a (autosync, layout) | FOUND |
