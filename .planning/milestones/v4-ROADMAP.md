# Milestone v4: Produção do Plano Maior

**Status:** SHIPPED 2026-06-12
**Fases:** 14–16
**Total de Planos:** 3
**Branch:** `work`

---

## Visão geral

Produção e endurecimento das três frentes abertas no final do v3: loop de instincts resistente a runaway, evals LLM validados fim-a-fim (local + CI remoto) e marketplace de plugins validado de fora com versões alinhadas em 3.0.0.

O milestone foi marcado pelo **INCIDENTE RUNAWAY** — 1331 spawns de sessões de análise gerados em cascata em 2026-06-12, contaminando o estoque de instincts com meta-junk. A Fase 14 transformou o incidente em hardening: três camadas de defesa implementadas e provadas por teste, curadoria de 1046 → 69 instincts com backup, e 5 regras invioláveis no SKILL.md.

Origem: 9 requisitos R4-01..R4-09 derivados dos gaps do v3 + pós-mortem do incidente runaway.

---

## INCIDENTE RUNAWAY — Pós-mortem e Hardening

### O que aconteceu

Em 2026-06-12, durante a sessão da Fase 13 (v3), o hook `observe-session-end.sh` de **análise de instincts** disparou recursivamente: sessões spawned de análise executavam comandos bash que, por sua vez, acionavam novos hooks de session_end, gerando mais spawns. Resultado: **1331 spawns** em cascata, cada um gravando observações e potencialmente criando instincts.

Root causes identificados:
1. **Re-observação:** sessões spawned (haiku) rodavam bash commands — cada um dispara o hook de tool-use, gerando observações de atividade de análise, não de desenvolvimento real
2. **Re-spawn:** o hook de session_end das sessões spawned também passava pelo gate e disparava novos spawns (sentinela só era atualizada ao FINAL da análise, não antes)
3. **Sem cooldown efetivo:** spawns de projetos diferentes não compartilhavam sentinela; múltiplos projetos podiam ser spawned simultaneamente

### Estancamento e curadoria

O estoque atingiu 1046 arquivos de instincts, a maioria meta-junk (observações de atividade de análise: "spawnou claude haiku", "grep em instincts/", "leu SKILL.md"). Curadoria em 8 passes progressivos:

| Pass | Critério | Removidos |
|------|----------|-----------|
| 1 | Meta-keyword (instinct, observe, spawn, haiku) | ~200 |
| 2 | Dedup por slug | ~150 |
| 3 | Diretórios não-canônicos | ~100 |
| 4 | Top-level noise | ~150 |
| 5 | Meta-trigger patterns | ~100 |
| 6 | Trivial actions | ~80 |
| 7 | Non-actionable | ~70 |
| 8 | Per-project cap (top-N por evidence_count) | ~47 |

Resultado: **1046 → 69 instincts** legítimos; 977 arquivados em `_archive/`; backup em `~/.ideiaos/backups/instincts-pre-curation-20260612-164406.tar.gz`.

### Fixes implementados (Fase 14)

Três barreiras ortogonais, cada uma suficiente para estancar o runaway:

| Barreira | Mecanismo | Arquivo |
|----------|-----------|---------|
| **Env guard** | `IDEIAOS_INSTINCT_SPAWN=1` exportado antes do spawn; ambos os hooks fazem `exit 0` imediato quando setado | `observe-tool-use.sh`, `observe-session-end.sh` |
| **Sentinel-before-spawn** | Sentinela de cooldown escrita ANTES de lançar o spawn (não após análise) | `observe-session-end.sh` |
| **Cooldown 30min** | Gate `ELAPSED < 1800s` por projeto; 2 session_ends consecutivos → 1 spawn apenas | `observe-session-end.sh` |

Prova por teste: `test-observe-hooks.sh` cases 9 (anti-runaway) e 10 (cooldown) — 29/29 PASS.

---

## Estatísticas

| Métrica | Valor |
|---------|-------|
| Commits | 9 |
| Arquivos modificados | 23 |
| Inserções | 782 |
| Deleções | 61 |
| Período | 2026-06-12 (1 dia) |
| Fases | 3 |
| Planos | 3 |

---

## Realizações principais

1. **Anti-runaway provado por teste** — Três camadas de defesa (env guard + sentinel-before-spawn + cooldown 30min) implementadas em `observe-tool-use.sh` e `observe-session-end.sh`, sincronizadas em `plugins/`. Test harness expandido com cases 9+10 (29/29 PASS). Regras invioláveis no `instinct-analyze/SKILL.md`: confidence inicial máx 0.6, máx 15 instincts por run, ignora observações de sessões de análise.

2. **Curadoria de instincts: 1046 → 69** — Oito passes progressivos eliminaram meta-junk das sessões runaway. Estoque final: 69 instincts legítimos, 0 violações de confidence. Backup preservado. `/evolve` rodado ao vivo (exit 0; 0 promoções — esperado: nenhum instinct maduro legítimo com confidence ≥0.7 ainda).

3. **Evals LLM rodando de verdade** — `run-evals.sh` corrigido (remoção de `--no-color` inválido + `</dev/null` para stdin fechado). Três casos reais executados com `claude -p` via auth local: EVAL-001 (pass^k exit 1), EVAL-021 (pass^k exit 1), EVAL-022 (pass@k exit 0). JSONL gravado em `evals/results/`. **Achado de qualidade:** critérios grep-based falham para semântica — o produto funciona corretamente (EVAL-001 não gerou INSERT cego, EVAL-021 entregou bloco JS corrigido, EVAL-022 mapeou múltiplas bibliotecas), mas o avaliador automatizado não detecta comportamento correto descrito semanticamente. Deferred: reformular critérios como padrões literais ou migrar para LLM-as-judge.

4. **CI remoto verde com skip limpo** — Dispatch `gh workflow run evals.yml` (Run ID 27439622994): job `structural` verde em 5s; job `llm-evals` skipado limpo em 12s (sem secret configurado, sem exit 1 indevido). Conclusão: SUCCESS.

5. **Marketplace v3.0.0 com instalação real validada** — Fluxo end-to-end de clone limpo: `claude plugin validate` → `claude plugin marketplace add` → `claude plugin install` → `claude plugin uninstall`, tudo confirmado. Três plugins em 3.0.0 (`ideiaos-core`, `ideiaos-design-suite`, `ideiaos-lovable`); `versions.lock` alinhado; `marketplace.json` com `description` adicionado (corrigiu warning do validador); README corrigido de `/plugin` (slash command) para `claude plugin` (CLI real).

---

## Fases

### Fase 14: instinct-production

**Goal:** Loop de instincts endurecido pós-incidente runaway (1331 spawns) e rodando em produção com curadoria.
**Depends on:** — (independente)
**Plans:** 1

Plans:
- [x] 14-01: Anti-runaway env guard + cooldown 30min + curadoria 1046→69 + limites duros R4-04 + /evolve ao vivo

**Detalhes:**
Guard `IDEIAOS_INSTINCT_SPAWN=1` adicionado a ambos os hooks; sentinela escrita antes do spawn (decisão-chave: sem esse ajuste, a janela de 120s de análise permitia novos spawns passarem pelo gate). Cooldown de 30min com `ELAPSED < 1800s`. Curadoria em 8 passes progressivos: 1046 → 69 instincts (977 arquivados, backup `.tar.gz`). Cinco regras INVIOLÁVEIS adicionadas ao topo do `instinct-analyze/SKILL.md`. Test harness: cases 9 (anti-runaway, 5 sub-cases) e 10 (cooldown) — 29/29 PASS. `/evolve` ao vivo: exit 0, 0 promoções (esperado — estoque curado, nenhum instinct com confidence ≥0.7 ainda). Desvio auto-corrigido: design original colocava sentinela após análise — corrigido para antes do spawn. Duração: ~90 min, 8 arquivos, commits `ddac7ab` e `9cc5242`.

---

### Fase 15: evals-production

**Goal:** Evals LLM validados fim-a-fim (local + CI remoto).
**Depends on:** Fase 14
**Plans:** 1

Plans:
- [x] 15-01: Fix run-evals.sh (--no-color + stdin) + 3 casos reais locais + dispatch CI remoto

**Detalhes:**
Dois bugs corrigidos em `run-evals.sh`: (1) `--no-color` inválido no Claude CLI v2 causava exit 1 imediato — removido; (2) stdin não fechado em subshell dupla causava potencial bloqueio — `</dev/null` adicionado, timeout aumentado para 120s. Três casos reais com `claude -p` via auth local (sem `ANTHROPIC_API_KEY`): EVAL-001/021 como pass^k (exit 1 correto), EVAL-022 como pass@k (exit 0 correto). Achado de qualidade registrado (critérios semânticos vs. grep-based) — não é bug de produto. Dispatch CI Run 27439622994: structural 5s green + llm-evals 12s skip clean. Deferred: `actions/checkout@v4` deprecação Node.js 20 (deadline 2026-06-16, atualizar para `@v5`). Duração: ~40 min, 1 arquivo modificado, commits `90517d1` e `896a741`.

---

### Fase 16: marketplace-ready

**Goal:** Marketplace validado de fora, versões 3.0.0 alinhadas, decisão de visibilidade documentada.
**Depends on:** — (independente)
**Plans:** 1

Plans:
- [x] 16-01: Clone limpo + fluxo CLI real + versões 3.0.0 + README revisado

**Detalhes:**
Clone limpo em `/tmp/ideiaos-market-test` via `git clone --depth 1 file://...`. Validações estruturais: marketplace.json parse OK, 3 sources resolvem, 3 plugin.json válidos, hooks.json 11 `.sh` presentes, 23 skills e 15 agents com frontmatter OK. Fluxo CLI real confirmado: `claude plugin validate` (OK com warnings) → `claude plugin marketplace add --scope local` → `claude plugin install ideiaos-core@ideiaos` → `claude plugin uninstall`. Dois bugs auto-corrigidos: `marketplace.json` sem `description` (warning do validador — adicionado) e README com `/plugin` (slash command) em vez de `claude plugin` (CLI real — corrigido). Versões bumped de 2.0.0 → 3.0.0 via `build-plugins.sh` (fonte única); `versions.lock` alinhado. Decisão de repo público documentada como PENDENTE DO USUÁRIO no README. Duração: ~4 min, 7 arquivos, commit `6a93a39`.

---

## Resumo do milestone

**Desvios notáveis:**

- **Sentinela before-spawn (Fase 14):** Design original colocava sentinela apenas ao final da análise (Passo 9 do SKILL.md, herdado do v3). Corrigido para antes do spawn — janela de 120s de análise sem sentinela ativa permitia que session_ends adicionais passassem o gate.
- **Curadoria em 8 passes (Fase 14):** Planejado como script one-off único; cada pass revelou nova camada de meta-junk. Processo iterativo necessário para atingir ≤80.
- **--no-color inválido no CLI v2 (Fase 15):** Flag adicionada no v3 (Fase 12) sem validação real de execução local. Detectada na primeira run com `--local`.
- **Stdin dupla subshell (Fase 15):** Captura de stdout em subshell cria segunda subshell para claude; stdin herdado podia travar em modo interativo. Fix: `</dev/null`.
- **marketplace.json sem description (Fase 16):** Warning do `claude plugin validate` — campo não documentado como obrigatório, mas necessário para validação limpa.
- **README com /plugin vs claude plugin (Fase 16):** Documentação usava sintaxe de slash command interativo; corrigida para CLI real.

**Decisões-chave:**

- Sentinela escrita ANTES do spawn: garante cooldown imediato independentemente da duração da análise (Fase 14)
- Cap por-projeto (top-N por evidence_count) como estratégia de curadoria: preserva os instincts com mais evidência por projeto em vez de aplicar threshold de confidence puro (Fase 14)
- Critérios semânticos dos evals = deferred (não reescrita dos casos para passar): registrado como achado de qualidade; comportamento do produto está correto — o problema é o avaliador grep-based (Fase 15)
- `llm-evals` job usa `steps.check_key.outputs.skip` (herdado do v3, confirmado correto): mais confiável que `if: secret` em branches não-default (Fase 15)
- `marketplace.json` com `description` adicionado para validação limpa (Fase 16)
- Decisão de repo público documentada como PENDENTE DO USUÁRIO (não tomada pelo agente) (Fase 16)

**Dívida técnica incorrida:**

- Critérios semânticos dos eval cases falham no avaliador grep-based: produto correto, avaliador incorreto — reescrita de critérios ou migração para LLM-as-judge pendente para v5
- `actions/checkout@v4` deprecação Node.js 20: deadline 2026-06-16 para atualizar para `@v5` ou adicionar `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`
- Visibilidade pública do repo: PENDENTE DO USUÁRIO (documentado no README)

---

_Para status atual do projeto, ver .planning/ROADMAP.md_
