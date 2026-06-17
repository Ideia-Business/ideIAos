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
- Pós-ship: `work` ficou ahead 8 (autosync empurra); **tag `v9.0` é local** (autosync não empurra tags → precisa `git push origin v9.0` por @devops).

**NÃO adotado** (decisão consciente, ver ADR `docs/decisions/v9-mattpocock-skills-absorcao.md`): postura anti-framework do upstream; `to-issues`/`triage`/`caveman`/`diagnose`/`tdd` (já temos equivalente). Fase G could-haves (`to-prd` delta, nota `/gsd-debug`) opcional.
