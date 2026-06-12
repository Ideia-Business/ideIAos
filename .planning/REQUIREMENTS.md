# Requirements — IdeiaOS v4 (Produção do plano maior)

**Total de requisitos v4:** 9
**Origem:** ROADMAP v4 candidates + incidente runaway do instinct-loop (2026-06-12, 1331 spawns)

## Tema A — Instinct loop endurecido para produção (Fase 14)

### R4-01 (P1) — Anti-runaway: guard de sessão de análise
Sessões spawned de análise NÃO geram observações nem re-spawnam. Critério: spawn exporta `IDEIAOS_INSTINCT_SPAWN=1`; observe-tool-use e observe-session-end fazem exit 0 imediato quando a env está setada; teste reproduz cadeia e prova que para em 1.

### R4-02 (P1) — Sentinela no spawn + cooldown
Sentinela é escrita NO MOMENTO do spawn (não só após análise) e o gate exige ≥30min desde a última análise (rate limit). Critério: 2 session_ends consecutivos → 1 spawn só; gate com cooldown verificável por teste.

### R4-03 (P1) — Curadoria do estoque contaminado
Os ~616 instincts (maioria meta-junk de sessões de análise) são curados: dedup por trigger, remoção de instincts derivados de atividade de análise, cap de confidence inicial 0.6 re-aplicado. Critério: estoque final ≤80 instincts legítimos; nenhum com confidence >0.6 sem evidence_count ≥3.

### R4-04 (P2) — instinct-analyze com limites duros
SKILL.md ganha regras invioláveis: confidence inicial máx 0.6, máx 15 instincts novos por run, ignora observações de sessões de análise. Critério: greps no SKILL.md + run controlado respeita limites.

### R4-05 (P2) — /evolve rodado ao vivo
Com estoque curado, /evolve promove os maduros legítimos (≥0.7 pós-reforço) ao vault e faz decay dos estagnados. Critério: run real com relatório; vault Learnings/ recebe ≥0 notas (ok ser 0 se nada maduro legítimo).

## Tema B — Evals em produção (Fase 15)

### R4-06 (P1) — Job LLM validado fim-a-fim local
`run-evals.sh --ci` executa ≥3 casos reais via claude local (auth da máquina), grava results e aplica política. Critério: run real com ≥3 casos, exit code coerente com vereditos.

### R4-07 (P2) — CI remoto validado
Workflow dispatch disparado via gh; job structural verde; job llm-evals skipa limpo sem secret (sem quebrar). Critério: `gh run watch` do dispatch → conclusion success.

## Tema C — Marketplace pronto (Fase 16)

### R4-08 (P1) — Fluxo de instalação validado de fora
Instalação do plugin validada a partir de um clone limpo em /tmp (estrutura marketplace.json→plugins resolve; claude plugin marketplace add por path local se CLI suportar, senão validação estrutural documentada). Critério: relatório de instalação com evidência.

### R4-09 (P2) — Versionamento e docs de release
plugin.json 3x + versions.lock + README alinhados (3.0.0); seção de instalação revisada; decisão "repo público" documentada como PENDENTE DO USUÁRIO. Critério: greps de versão consistentes; nota no README.

## Coverage

| Req | Fase |
|-----|------|
| R4-01..05 | 14 |
| R4-06..07 | 15 |
| R4-08..09 | 16 |
