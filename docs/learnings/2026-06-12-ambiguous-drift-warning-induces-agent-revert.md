---
date: 2026-06-12
session_type: infra
incident: n/a (commit 3724ee9 — agente Cursor reverteu pin ao "resolver" aviso de drift)
commit: 7a4f54b
tags: [ai-agents, diagnostics, error-messages, drift, tooling-ux]
applies_to_projects: [global]
promote_to_vault: true
---

# Aviso de diagnóstico ambíguo induz agente de IA a "corrigir" na direção errada — mensagens devem ser direcionais

## Trigger (quando reler isso)

Ao escrever mensagens de warning/erro em scripts de diagnóstico (doctor, linter, drift check) que
serão lidas por agentes de IA — ou ao investigar por que um agente "consertou" algo quebrando.

## O padrão (abstrato)

Um aviso que apenas constata divergência ("X ≠ Y — corrija se intencional") delega ao leitor a
decisão de **qual lado está errado**. Um agente de IA (ou humano apressado) resolve a ambiguidade
com a heurística mais disponível — e se houver uma armadilha semântica no domínio (ex.: versão
"maior" que é mais antiga), ele escolhe o lado errado com confiança, produzindo um commit
plausível de "fix" que é na verdade um revert. O dano é pior que não avisar: o aviso **convocou**
a ação destrutiva.

## Evidência (concreta — desta sessão)

- Aviso antigo: `DRIFT GSD: instalado 1.1.0 ≠ pin 1.36.0 — re-pin com --bump se intencional`
  (`update-upstream.sh` / `idea-doctor.sh`). Não dizia qual valor era o correto.
- Commit `3724ee9` ("fix(versions.lock): re-pin gsd doctor version", co-authored by Cursor) — o
  agente leu o aviso e re-pinou para o valor legado `1.36.0`.
- Correção: mensagens direcionais nos dois scripts — detectam a faixa legada e dizem
  explicitamente "instalado é PRÉ-REDUX, atualize a máquina, NÃO rode --bump" ou "pin LEGADO,
  o instalado é MAIS NOVO, corrija com --bump".

## Regra prática derivada

Todo aviso de divergência em ferramenta de diagnóstico deve, quando o conhecimento de domínio
permite, **diagnosticar a direção**: dizer qual lado está errado e qual é a ação correta (e qual
ação NÃO tomar). Se a direção não é decidível, dizer isso explicitamente e exigir confirmação
humana — nunca terminar com "corrija se intencional" genérico. Tratar mensagens de ferramenta
como prompts: agentes de IA vão agir literalmente sobre elas.

## Falsos positivos / armadilhas

- Nem todo drift tem direção decidível por código — não inventar certeza onde não há; o fallback
  correto é "ambíguo, exige humano", não um palpite.
- Mensagens direcionais embutem conhecimento de domínio que expira (ex.: faixa de versão legada) —
  precisam de nota de obsolescência como qualquer guarda.

## Cross-references

- `[[2026-06-12-version-reset-migration-semver-trap]]` — a armadilha de domínio que tornou a ambiguidade fatal
- `[[learning-protocol-discipline-needs-hooks-not-guidelines]]` — a mensagem direcional é necessária, mas a barreira (pre-commit) é o que garante
- `scripts/idea-doctor.sh` / `scripts/update-upstream.sh` — mensagens direcionais implementadas

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-12 — motivo: padrão se aplica a `[global]`
- [x] Promovido para Obsidian vault em 2026-06-12 — motivo: síntese cross-projeto (stack-agnóstico)
- [ ] Aplicado retroativamente em outros learnings (refinou regra)
