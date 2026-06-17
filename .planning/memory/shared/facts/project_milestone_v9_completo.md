---
name: project-milestone-v9-completo
description: "v9 (Camada de Alinhamento) SHIPPED 2026-06-17 — absorveu de mattpocock/skills (MIT) o delta de alinhamento humano↔agente: /grelha, glossário CONTEXT.md, ADR inline, gate na Deia, /aprofundar"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Milestone **v9 — Camada de Alinhamento (Alignment Layer)** SHIPPED em 2026-06-17, tag `v9.0`. Execução autônoma multi-agente (orquestrador Deia + builders/revisores via Workflow, painel 3-lentes por fase). 6 fases A–F, auditoria `.planning/v9-MILESTONE-AUDIT.md` PASSED, dogfood `/doubt` sobre o diff = SHIP.

**O que entrou (de `mattpocock/skills`, MIT, commit `694fa30`, via quarentena):**
- `/grelha` (alias `/grill`) — grilling colaborativo PRÉ-plano, 1 pergunta/vez com resposta recomendada, lê o código; modos `--docs`/`--rapido`. Simétrico ao [[project-milestone-v8-completo]] `/doubt` (adversarial). R9-01.
- Glossário `CONTEXT.md` (linguagem ubíqua durável) + rule `ubiquitous-language` que distingue os **3 CONTEXT**: glossário `CONTEXT.md` × `{phase}-CONTEXT.md` (GSD) × `specs/<cap>/spec.md` (/spec). R9-02.
- ADR ultraleve inline (`ADR-FORMAT`, gate dos 3 critérios) reusando `docs/decisions/` + espelhamento Obsidian do `/extract-learnings`. R9-03.
- Passo 1.5 (gate de alinhamento OPCIONAL/escapável) na Deia (`source/skills/idea/SKILL.md`). R9-04.
- `/improve-architecture` (`/aprofundar`) — ritual recorrente de deepening (Ousterhout), deletion test, relatório HTML em tmp. R9-05.

**Aprendizados desta execução:**
- O `/doubt` adversarial por fase pegou de novo uma **citação embelezada** (Pragmatic Programmer) na Fase B — eco do [[learning_dogfood-review-tool-catches-own-defect]]; corrigida antes do commit.
- Surfou e corrigiu uma **falha latente no `scan-absorbed.sh`**: Check-2 falhava em `<script>`/`<!--` dentro de fenced code block (documentação). Fix fence-aware com control test (payload fora de fence ainda FALHA). Padrão [[declarative-manifest-vs-imperative-list-drift]] não — é falso-positivo de detector.
- Autosync foi **pausado** (linha do IdeiaOS comentada em `~/.local/state/git-autosync-repos.txt`) durante a execução multi-agente para não varrer WIP, e restaurado ao fim — ver [[autosync-pushes-feature-branches]].
- Fechamento operacional (2026-06-17): **tag `v9.0` empurrada para origin** (commit 9b51679; autosync não empurra tags → push manual); LOW do dogfood resolvido (README esclarece que `scan-absorbed.sh` mira a quarentena, não `source/`); branch **`planning` sincronizado** com os docs de milestone v9 via git plumbing (base = árvore do planning → memory store `.planning/memory/` + `.gitignore` preservados intactos; só os `.planning/*` não-memory foram sobrepostos a partir do work). `work`=`origin/work`=122da91.

**NÃO adotado** (decisão consciente, ver ADR `docs/decisions/v9-mattpocock-skills-absorcao.md`): postura anti-framework do upstream; `to-issues`/`triage`/`caveman`/`tdd` (já temos equivalente).

**Fase G (could-haves) entregue pós-v9.0 (2026-06-17):** os 2 deltas finos viraram **Patches 14/15 do overlay** (`install-global-patches.sh`), não skills novas. P14 = `to-prd` → core_principle "síntese > entrevista" + quiz seams/módulos no @pm/Morgan (`.aiox-core/.../agents/pm.md`); P15 = `diagnose` → nota de seam no `/gsd-debug` (`~/.claude/skills/gsd-debug/SKILL.md`). Aprendizado: o `.aiox-core` vendado no repo é mantido **pristine** — deltas IdeiaOS vão SÓ na cópia instalada via overlay idempotente (precedente Patches 1/5), nunca por edição direta. Custo real MEDIUM (não XS): a contagem "13→15 patches" precisou sincronizar em 3 arquivos (script+README+doctor) — eco de [[declarative-manifest-vs-imperative-list-drift]].
