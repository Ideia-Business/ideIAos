---
name: project-plano-maior-concluido
description: Plano maior ECC 100% concluído em 2026-06-12 (v2.0+v3+v4, tags); máquinas liberadas para update; pendências = decisões do usuário
metadata:
  type: project
---

O **plano maior (absorção ECC) está 100% concluído** — 3 milestones shipped em 2026-06-12: v2.0 (8 fases), v3 (5 fases), v4 (3 fases). Tags v2.0/v3.0/v4.0, `work`=`main` pushed. Máquinas LIBERADAS: `git pull && bash scripts/ideiaos-update.sh`.

**Incidente importante:** instinct-loop runaway (1331 spawns haiku, fork-bomb por auto-observação) — estancado e blindado na Fase 14 (env guard + sentinela-no-spawn + cooldown 30min). Lição: features com spawn automático precisam de guard de recursão DESDE O DESIGN, não só kill-switch por processo.

**Pendências (decisões do usuário):** repo público p/ marketplace aberto · secret ANTHROPIC_API_KEY p/ evals LLM em CI. **v5 ZERADO (2026-06-12):** eval criteria híbrido (Sinais+LLM-judge) entregue na fase 17; checkout@v5 aplicado; Novidades entregue nos 2 produtos em branches (`feature/novidades-portal` no NFideia, `feature/novidades` no Ideiapartner) — **merge/deploy em produção aguarda o usuário**.

Relacionado: [[project-milestone-v2-completo]], [[project-milestone-v3-completo]].
