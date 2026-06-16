# Roadmap — IdeiaOS

## Milestones

- **v2.0 — Canivete Suíço Universal (absorção ECC)** ✅ SHIPPED 2026-06-12 — 8 fases, 29 planos, 33→70 módulos. Detalhes: [milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- **v3 — Refinamento pós-auditoria** ✅ SHIPPED 2026-06-12 — 5 fases (09-13), 10 planos, 19 reqs, 15/15 gaps fechados; loop de instincts provado ao vivo. Detalhes: [milestones/v3-ROADMAP.md](milestones/v3-ROADMAP.md)
- **v4 — Produção do plano maior** ✅ SHIPPED 2026-06-12 — fases 14-16: anti-runaway provado (incidente 1331 spawns → 3 barreiras), evals LLM fim-a-fim, marketplace 3.0.0 com install real validado. Detalhes: [milestones/v4-ROADMAP.md](milestones/v4-ROADMAP.md)
- **v5 — Memória compartilhada entre IDEs** ✅ SHIPPED 2026-06-14 — 5 fases (18-22), 11 reqs, memória cross-IDE via branch `planning`, Lovable-safe. Detalhes: [milestones/v5-ROADMAP.md](milestones/v5-ROADMAP.md)
- **v6 — Resiliência + Camada de Marketing** 🚧 IN PROGRESS — fases 23-27. Absorve 3 indicações da análise comparativa (bash gates anti-alucinação, resiliência de spawn, geração fundamentada + paridade multi-IDE) + cria a **Camada de Marketing** acionável (absorve OpenSquad, orquestrada pela Deia) + test hardening.


## Decisões registradas (2026-06-12)

- ~~actions/checkout v4→v5~~ ✅ Aplicado (commit 151132a)
- **Secret ANTHROPIC_API_KEY em CI: NÃO** (decisão do usuário) — evals LLM rodam localmente via `bash evals/run-evals.sh --ci` com o auth da máquina; o job de CI skipa limpo por design
- **Repo público: manter PRIVADO** (recomendação acatada) — marketplace funciona nas máquinas autenticadas do usuário; público só se houver intenção de distribuir como open source
