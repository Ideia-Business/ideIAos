---
name: project-milestone-v8-completo
description: v8 (Camada de Disciplina) SHIPPED 2026-06-16 — absorveu de addyosmani/agent-skills (MIT) só o delta de disciplina; agent-skills NÃO substitui GSD/AIOX
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Milestone **v8 — Camada de Disciplina** shipped em 2026-06-16 (mesmo dia do v6 e v7), tag `v8.0`, auditoria PASSED. Absorveu de `addyosmani/agent-skills` (MIT) **só o que é novo/melhor que o ECC já trouxe** (a análise concluiu ~70% de overlap com o que já tínhamos):

- **`/doubt`** (doubt-driven — revisor adversarial de contexto-fresco EM-VOO; maior ROL, não tínhamos nada in-flight)
- **rule `operating-discipline`** (6 condutas sempre-on: surface assumptions, manage confusion, push back, enforce simplicity, scope discipline, verify-don't-assume)
- **`/context-engineering`** (curadoria de contexto em camadas)
- **convenção de autoria anti-racionalização** (`CONTRIBUTING.md` + `source/templates/skill/SKILL.md.tmpl`)
- **opt-in catálogo:** `/observability`, `/deprecation-migration` (`plugin:null`)

**Veredito estratégico (importante p/ futuras decisões):** `agent-skills` **não substitui** GSD (motor de execução) nem AIOX-Core (org story-driven) — é camada de disciplina/lifecycle que senta **em cima** deles. NÃO absorver os lifecycle skills dele que duplicam GSD (planning/incremental), nem o que o ECC já deu (tdd/e2e/api-design/code-review/security/performance/frontend), nem o scaffolding multi-harness/marketplace dele.

**Carry-forward R8-09** (herdado de v7): rules `source/rules/common/*` com `plugin:ideiaos-core` (`delta-spec`, `operating-discipline`) ainda não têm deploy para projetos-alvo Claude Code via `setup.sh` — só `.cursor/` + `.claude/rules/` do próprio repo. Ver [[dogfood-review-tool-catches-own-defect]].
