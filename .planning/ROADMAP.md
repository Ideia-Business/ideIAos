# Roadmap — IdeiaOS

## Milestones

- **v2.0 — Canivete Suíço Universal (absorção ECC)** ✅ SHIPPED 2026-06-12 — 8 fases, 29 planos, 33→70 módulos. Detalhes: [milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- **v3 — Refinamento pós-auditoria** ✅ SHIPPED 2026-06-12 — 5 fases (09-13), 10 planos, 19 reqs, 15/15 gaps fechados; loop de instincts provado ao vivo. Detalhes: [milestones/v3-ROADMAP.md](milestones/v3-ROADMAP.md)
- **v4 — Produção do plano maior** ✅ SHIPPED 2026-06-12 — fases 14-16: anti-runaway provado (incidente 1331 spawns → 3 barreiras), evals LLM fim-a-fim, marketplace 3.0.0 com install real validado. Detalhes: [milestones/v4-ROADMAP.md](milestones/v4-ROADMAP.md)
- **v5 — Memória compartilhada entre IDEs** ✅ SHIPPED 2026-06-14 — 5 fases (18-22), 11 reqs, memória cross-IDE via branch `planning`, Lovable-safe. Detalhes: [milestones/v5-ROADMAP.md](milestones/v5-ROADMAP.md)
- **v6 — Resiliência + Marketing + GSD/OpenSpec** ✅ SHIPPED 2026-06-16 — 9 fases (23-31), 15 reqs, auditoria 15/15, tag v6.0. Detalhes: [milestones/v6-ROADMAP.md](milestones/v6-ROADMAP.md)
- **v7 — Delta-Spec Brownfield + Robustez de Empacotamento** ✅ SHIPPED 2026-06-16 — 4 fases, auditoria PASSED, tag v7.0. Piloto `/spec` brownfield no nfideia (specs vivas `multi-tenancy` + `cofre-digital`) + 4 bugs/gaps corrigidos (engine archive/placement, empacotamento, memory-hooks plugin:null) + **drift-guard** manifesto×build-plugins. Detalhes: [milestones/v7-ROADMAP.md](milestones/v7-ROADMAP.md)
- **v8 — Camada de Disciplina (Discipline Layer)** ✅ SHIPPED 2026-06-16 — 4 waves, auditoria PASSED, tag v8.0. Absorção de `addyosmani/agent-skills` (MIT): `/doubt` (doubt-driven — revisor adversarial em-voo) + rule sempre-on `operating-discipline` (6 condutas) + `/context-engineering` + convenção de autoria anti-racionalização + opt-in `/observability`/`/deprecation-migration`. **Dogfood:** doubt-driven rodado sobre o próprio diff achou e corrigiu citação fabricada no `/doubt`. Detalhes: [milestones/v8-ROADMAP.md](milestones/v8-ROADMAP.md)


## Decisões registradas (2026-06-12)

- ~~actions/checkout v4→v5~~ ✅ Aplicado (commit 151132a)
- **Secret ANTHROPIC_API_KEY em CI: NÃO** (decisão do usuário) — evals LLM rodam localmente via `bash evals/run-evals.sh --ci` com o auth da máquina; o job de CI skipa limpo por design
- **Repo público: manter PRIVADO** (recomendação acatada) — marketplace funciona nas máquinas autenticadas do usuário; público só se houver intenção de distribuir como open source
