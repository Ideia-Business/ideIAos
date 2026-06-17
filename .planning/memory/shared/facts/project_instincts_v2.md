---
name: IdeiaOS instincts v2 (June 2026)
description: Instincts destilados de 1506 observações sobre padrões de trabalho em IdeiaOS
type: project
originSessionId: c94fe2f9-e63c-4ddc-8c23-ac62a34a82dd
---
# IdeiaOS Instincts v2 — Análise de 2026-06-12

## Background
Análise de 1506 observações coletadas em 109 sessões do projeto IdeiaOS. Padrões identificados refletem o workflow típico: exploração bash → iterações → documentação.

## Instincts Criados (Project Scope)

### 1. iterative-bash-validation
- **Confidence**: 0.8 (96% das bash actions são iterativas)
- **Trigger**: Executar bash command em sessão IdeiaOS
- **Action**: Preparar para loop iterativo de bash — próxima ação muito provável é bash novamente ou write de documentação
- **Padrão**: 1145/1194 bash successes → bash; típico: bash → bash → bash → doc

### 2. bash-to-docs-feedback
- **Confidence**: 0.65 (padrão Bash→Write observado 23+ vezes)
- **Trigger**: 3+ bash commands bem-sucedidos em sequência
- **Action**: Seguir com markdown write/edit para capturar resultados ou status

### 3. markdown-iterative-polish
- **Confidence**: 0.6 (57% de edições markdown → próximas markdown edits)
- **Trigger**: Editar/criar arquivo .md
- **Action**: Esperar 2-3 passadas de refinamento antes de considerar estável
- **Nota**: Refinamento é core ao workflow de artefatos GSD

## Complementaridade com Global Instincts
- `bash_bash_edit` (global, 0.7) — reforça edit→bash pattern
- `bash_bash_write` (global, 0.7) — reforça bash→write pattern

Esses globais são generalizados; os project-scope IdeiaOS capturam especificidade: iteração vs. exploração única, documentação integrada ao pipeline.

## Aplicação Prática
- **Ao planejar**: orçamentar 3-5 iterações bash antes de estabilizar
- **Ao documentar**: não interromper ciclo de refinamento .md
- **Ao integrar**: esperar bash→docs feedback loop
