# Requirements — v8: Camada de Disciplina (Discipline Layer)

**Milestone:** v8
**Aberto/Shipped:** 2026-06-16
**Fonte:** análise de `addyosmani/agent-skills` (MIT) × IdeiaOS — absorver a camada de disciplina comportamental que protege vibe coders da falha "confiante e errado", sem duplicar o que o ECC já trouxe.

## Requisitos

| ID | Requisito | Status |
|----|-----------|--------|
| R8-01 | Skill `/doubt` (Doubt-Driven Development) — revisor adversarial de contexto-fresco EM-VOO, 5 passos (CLAIM→EXTRACT→DOUBT→RECONCILE→STOP), spawn de subagente, oferta cross-model, roda só da sessão principal | ✅ DONE |
| R8-02 | Rule sempre-on `operating-discipline` — 6 condutas de base (surface assumptions, manage confusion, push back, enforce simplicity, scope discipline, verify-don't-assume); deploy Claude (`.claude/rules/`) + Cursor (`.mdc`) | ✅ DONE |
| R8-03 | Skill `/context-engineering` — hierarquia de 5 níveis, brain dump, selective include (<2k linhas/tarefa); operacionaliza token-economy/orchestration/handoffs sem duplicar | ✅ DONE |
| R8-04 | Convenção de autoria anti-racionalização em `CONTRIBUTING.md` + template `source/templates/skill/SKILL.md.tmpl` (tabela Racionalização×Realidade + Red flags + Verificação obrigatórias) | ✅ DONE |
| R8-05 | Skills opt-in de catálogo `observability` + `deprecation-migration` (`plugin: null`, surgem via `/ideiaos-catalog`) | ✅ DONE |
| R8-06 | Absorção via pipeline de quarentena (`security/scan-absorbed.sh`, exit 0) + atribuição MIT `# SOURCE: agent-skills MIT addyosmani/agent-skills` | ✅ DONE |
| R8-07 | Dogfood: rodar `/doubt` (revisor adversarial) sobre o próprio diff do milestone antes do ship; reconciliar achados | ✅ DONE |
| R8-08 | Wiring consistente (Deia matrix, CORE_SKILLS, modules.json, plugin-membership, README) + gates binários verdes (membership 71/0, readme 111/111, build, doctor 0 FAIL, bats 27/27) | ✅ DONE |
| R8-09 | **Carry-forward (herdado de v7):** deploy de `source/rules/common/*.md` para projetos-alvo Claude Code (hoje só `.cursor/` + `.claude/rules/` do próprio repo) | ⬜ DEFERIDO |

## Fora de escopo (decisão consciente)
- Lifecycle skills do Osmani que duplicam GSD (planning-and-task-breakdown, incremental-implementation) — GSD é superior.
- Skills já cobertas pelo ECC/IdeiaOS (tdd, e2e, api-design, code-review, security, performance, frontend) — mantidas as nossas.
- Scaffolding multi-harness do Osmani (.gemini/.toml, Windsurf, Kiro) e marketplace dele — temos os nossos.
