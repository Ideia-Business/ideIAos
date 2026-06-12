# Requirements — IdeiaOS v4 (Produção do Plano Maior)

**Status:** SHIPPED 2026-06-12
**Total de requisitos v4:** 9
**Fases:** 14–16
**Origem:** Gaps do v3 + pós-mortem do incidente runaway (1331 spawns, 2026-06-12)

---

## Tema A — Instinct loop endurecido para produção (Fase 14)

### R4-01 (P1) — Anti-runaway: guard de sessão de análise [x] DONE

**Critério:** Spawn exporta `IDEIAOS_INSTINCT_SPAWN=1`; `observe-tool-use` e `observe-session-end` fazem `exit 0` imediato quando a env está setada; teste reproduz cadeia e prova que para em 1.

**Outcome:** Guard implementado nos dois hooks (`source/hooks/` e `plugins/`). Cases 9a-9e adicionados ao test harness — 29/29 PASS. Spawn de sessões spawned: zero novos spawns (R4-01 verificado via logs durante teste vivo).

**Fase:** 14 | **Commits:** `ddac7ab`

---

### R4-02 (P1) — Sentinela no spawn + cooldown [x] DONE

**Critério:** Sentinela escrita NO MOMENTO do spawn (não só após análise); gate exige ≥30min desde a última análise (rate limit); 2 session_ends consecutivos → 1 spawn só.

**Outcome:** Sentinela escrita antes do spawn em `observe-session-end.sh` (decisão-chave: design original de sentinela-após-análise criava janela de 120s sem proteção). Gate `ELAPSED < 1800s` implementado. Case 10 (cooldown) PASS.

**Fase:** 14 | **Commits:** `ddac7ab`

---

### R4-03 (P1) — Curadoria do estoque contaminado [x] DONE

**Critério:** Estoque final ≤80 instincts legítimos; nenhum com confidence >0.6 sem evidence_count ≥3.

**Outcome:** 1046 → 69 instincts (8 passes progressivos: meta-keyword, dedup-slug, non-canonical, top-level, meta-trigger, trivial-action, non-actionable, per-project-cap). 0 violações de confidence. 977 arquivados em `~/.ideiaos/instincts/_archive/`; backup em `~/.ideiaos/backups/instincts-pre-curation-20260612-164406.tar.gz`. Sem commit de código — mudança de dados.

**Fase:** 14

---

### R4-04 (P2) — instinct-analyze com limites duros [x] DONE

**Critério:** SKILL.md ganha regras invioláveis: confidence inicial máx 0.6, máx 15 instincts novos por run, ignora observações de sessões de análise. Greps no SKILL.md + run controlado respeita limites.

**Outcome:** 5 regras INVIOLÁVEIS adicionadas ao topo do `source/skills/instinct-analyze/SKILL.md` (sincronizado em `plugins/`). Logs de teste vivo confirmam: "Confidence respeitou cap de 0.6 (R4-04)", máx 15 instincts por run respeitado, 2126 de 2701 observações descartadas como ruído de análise.

**Fase:** 14 | **Commits:** `9cc5242`

---

### R4-05 (P2) — /evolve rodado ao vivo [x] DONE

**Critério:** Run real com relatório; vault `Learnings/` recebe ≥0 notas (ok ser 0 se nada maduro legítimo).

**Outcome:** `/evolve` rodado ao vivo — exit 0; 0 promoções (esperado: estoque recém-curado, nenhum instinct com confidence ≥0.7 pós-curadoria ainda).

**Fase:** 14

---

## Tema B — Evals em produção (Fase 15)

### R4-06 (P1) — Job LLM validado fim-a-fim local [x] DONE

**Critério:** `run-evals.sh --ci` executa ≥3 casos reais via claude local (auth da máquina), grava results e aplica política. Run real com ≥3 casos, exit code coerente com vereditos.

**Outcome:** `run-evals.sh` corrigido (remoção de `--no-color` inválido + `</dev/null` para stdin). 3 casos executados com `claude -p` via auth local (sem `ANTHROPIC_API_KEY`):
- EVAL-001 (pass^k): fail → exit 1 (correto)
- EVAL-021 (pass^k): fail → exit 1 (correto)
- EVAL-022 (pass@k): fail → exit 0 (correto — warning não bloqueia)

JSONL gravado em `evals/results/`. Exit codes coerentes com política.

**Achado de qualidade (deferred — v5 candidato):** Os 3 "fails" são do avaliador grep-based, não do produto. Comportamento real correto: EVAL-001 não gerou INSERT cego, EVAL-021 entregou bloco JS corrigido, EVAL-022 mapeou `@react-pdf/renderer` + `jsPDF`. Critérios semânticos (frases descritivas) não aparecem literalmente na resposta do modelo.

**Fase:** 15 | **Commits:** `90517d1`

---

### R4-07 (P2) — CI remoto validado [x] DONE

**Critério:** Workflow dispatch disparado via gh; job structural verde; job llm-evals skipa limpo sem secret (sem quebrar). `gh run watch` do dispatch → conclusion success.

**Outcome:** `gh workflow run evals.yml --repo Ideia-Business/ideIAos --ref work` → Run ID 27439622994. Structural: 5s green. LLM-evals: 12s skip clean (`steps.check_key.outputs.skip == 'true'`). Conclusão: SUCCESS.

**Fase:** 15 | **Commits:** `896a741`

---

## Tema C — Marketplace pronto (Fase 16)

### R4-08 (P1) — Fluxo de instalação validado de fora [x] DONE

**Critério:** Instalação do plugin validada a partir de um clone limpo em /tmp. Critério: relatório de instalação com evidência.

**Outcome:** Clone limpo `git clone --depth 1 file:///Users/gustavolopespaiva/dev/IdeiaOS /tmp/ideiaos-market-test`. Fluxo CLI real:
1. `claude plugin validate /tmp/ideiaos-market-test` → OK com warnings (description adicionado para fix)
2. `claude plugin marketplace add /tmp/ideiaos-market-test --scope local` → Success
3. `claude plugin install ideiaos-core@ideiaos` → Successfully installed
4. `claude plugin uninstall ideiaos-core` → Successfully uninstalled

**Fase:** 16 | **Commits:** `6a93a39`

---

### R4-09 (P2) — Versionamento e docs de release [x] DONE

**Critério:** plugin.json 3x + versions.lock + README alinhados (3.0.0); seção de instalação revisada; decisão "repo público" documentada como PENDENTE DO USUÁRIO.

**Outcome:** `build-plugins.sh` bumped para 3.0.0 (fonte única); 3x `plugin.json` 3.0.0; `versions.lock` `ideiaos-plugin=3.0.0`; `marketplace.json` com `description` adicionado; README com comandos corrigidos de `/plugin` para `claude plugin` + Opções A/B documentadas + nota de visibilidade pendente.

**Fase:** 16 | **Commits:** `6a93a39`

---

## Coverage

| Req | Prioridade | Fase | Status |
|-----|-----------|------|--------|
| R4-01 | P1 | 14 | [x] DONE |
| R4-02 | P1 | 14 | [x] DONE |
| R4-03 | P1 | 14 | [x] DONE |
| R4-04 | P2 | 14 | [x] DONE |
| R4-05 | P2 | 14 | [x] DONE |
| R4-06 | P1 | 15 | [x] DONE |
| R4-07 | P2 | 15 | [x] DONE |
| R4-08 | P1 | 16 | [x] DONE |
| R4-09 | P2 | 16 | [x] DONE |

**9/9 requisitos entregues.**

---

## Dívida técnica incorrida (v5 candidatos)

| Item | Descrição | Origem |
|------|-----------|--------|
| Critérios semânticos dos eval cases | Reformular como padrões literais ou migrar para LLM-as-judge | R4-06 achado de qualidade |
| `actions/checkout@v4` | Deprecação Node.js 20 — atualizar para `@v5` antes de 2026-06-16 | R4-07 deferred |
| Visibilidade pública do repo | PENDENTE DO USUÁRIO — documentado no README | R4-08 decisão |
