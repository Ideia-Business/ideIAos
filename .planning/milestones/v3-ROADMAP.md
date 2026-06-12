# Milestone v3: Refinamento e Automação

**Status:** SHIPPED 2026-06-12
**Fases:** 09–13
**Total de Planos:** 10
**Branch:** `work`

---

## Visão geral

Refinamento e automação do IdeiaOS v2: contratos de agents validados em build, três otimizações de token aplicadas (downgrade opus→sonnet, bash puro sem python3, LSP condicional), loop de instincts fechado ao vivo com haiku real (2 bugs sistêmicos encontrados e corrigidos durante o teste), suíte de evals automatizada em CI via GitHub Actions com política pass^k/pass@k, e diagnóstico expandido (doctor Seções 7a/8, scan nc com word-boundary, script de propagação multi-repo).

Origem: 15 gaps G-01..G-15 levantados na Fase 08 (v2.0) em `docs/v3/v3-review.md`, traduzidos em 19 requisitos R3-01..R3-19.

---

## Estatísticas

| Métrica | Valor |
|---------|-------|
| Commits | 27 |
| Arquivos modificados | 70 |
| Inserções | 4.500 |
| Deleções | 182 |
| Período | 2026-06-12 (1 dia) |
| Fases | 5 |
| Planos | 10 |

---

## Realizações principais

1. **Contratos de agents validados no build** — `build-adapters.sh` agora executa `validate_agent_contracts()` antes de copiar qualquer arquivo: falha com exit não-zero se qualquer agent em `source/agents/` não tiver `model:` e `tools:` no frontmatter. Todos os 15 agents passam. Nome canônico `ideiaos-checker` alinhado em source/, plugins/ e setup.sh; nenhuma ocorrência de `setup-checker` em arquivo funcional.

2. **Três otimizações de token independentes** — (a) `silent-failure-hunter` downgrade opus→sonnet validado em 3 casos reais: processo inteiramente grep-based, ~5x economia estimada; (b) `strategic-compact.sh` reescrito em bash puro eliminando 3 invocações de python3 por tool call — parse de session_id via grep/sed, contador plain-text integer em /tmp; (c) `typescript-lsp` registrado no manifesto com `installStrategy: "stack:typescript"` e wiring condicional em setup.sh via `detect_stack()`, tornando-se a primeira consumidora real do padrão stack:*.

3. **Loop de instincts FECHADO ao vivo com haiku real** — `observe-session-end.sh` agora spawna `claude --model claude-haiku-4-5 -p "/instinct-analyze"` em background com gate por timestamp ISO. Dois bugs sistêmicos encontrados e corrigidos durante o teste: (1) comparação `[ <= ]` em bash não suporta strings — corrigido para `[[ "$TS_OBS" > "$TS_LAST" ]]`; (2) slug de projeto usado como sentinela precisava de normalização. `instinct-analyze/SKILL.md` documenta o Passo 9 de atualização do sentinela; referências ao "gap de scheduler" removidas.

4. **Evals em CI via GitHub Actions com política pass^k** — `run_case_with_model()` implementado em `run-evals.sh` com `claude -p`, timeout 90s (perl fallback para bash 3.2 compat). Workflow `.github/workflows/evals.yml`: job `structural` sempre (validação de frontmatter via python3 inline, zero dependências externas) + job `llm-evals` gated por secret. Invariantes pass^k bloqueiam merge com exit 1; capacidades pass@k emitem warning sem bloquear. Bug de borda identificado pelo verifier: `skip` sem key em `--ci` triggava exit 1 indevidamente — fix documentado na VERIFICATION.

5. **doctor Seções 7a/8 + scan nc word-boundary + apply-to-all-projects** — `idea-doctor.sh` expandido com Seção 7a (WARN para qualquer das 6 deny rules ausentes, proxy via statusline) e Seção 8 (WARN para contexts ausentes, aliases de shell, statusline). `scan-absorbed.sh` corrigido de `nc ` para `\bnc\b`: palavras TypeScript como `function`, `sync`, `async`, `truncate` não geram mais falsos positivos. `scripts/apply-to-all-projects.sh` criado com dry-run por padrão; detecta 5 repos em `~/dev/` e propaga `setup.sh --project-only`.

---

## Fases

### Fase 09: agent-contracts

**Goal:** Todos os agents têm `model:` e `tools:` explícitos no frontmatter; nome canônico `ideiaos-checker` alinhado entre filename, frontmatter e modules.json; build-adapters valida o contrato.
**Depends on:** — (independente)
**Plans:** 1

Plans:
- [x] 09-01: Frontmatter model+tools, nome canônico ideiaos-checker, validate_agent_contracts() em build-adapters.sh, flag --auto-apply

**Detalhes:**
`model:` e `tools:` adicionados a `claude-continuation.md` e `ideiaos-checker.md` (source/ e plugins/). Função `validate_agent_contracts()` inserida em `build-adapters.sh` antes do build; exit 1 em caso de campo ausente; `bash scripts/build-adapters.sh --target all --dry-run` exit 0 com "✓ All agents have valid frontmatter contracts". Desvio auto-corrigido: `plugins/ideiaos-core/agents/ideiaos-checker.md` também precisava de atualização (encontrado durante a tarefa 1/2). Duração: ~25 min, 7 arquivos modificados.

---

### Fase 10: token-optimizations

**Goal:** Três otimizações de custo independentes aplicadas: downgrade opus→sonnet no hunter, bash puro no compact, e typescript-lsp registrado no manifesto.
**Depends on:** Fase 09
**Plans:** 1

Plans:
- [x] 10-01: opus→sonnet em silent-failure-hunter, bash puro em strategic-compact.sh, typescript-lsp no manifesto

**Detalhes:**
Downgrade opus→sonnet em `silent-failure-hunter.md` + cópia sincronizada em plugins/ (padrão Fase 09). `strategic-compact.sh` reescrito: zero invocações python3, parse de session_id via grep/sed, contador plain-text em /tmp. `manifests/modules.json` com entry `typescript-lsp` (kind:lsp, source:null, config-only). `setup.sh` com bloco condicional TypeScript LSP usando `detect_stack()` — primeira consumidora real do padrão installStrategy:stack:*. Desvio: autosync do Mac-mini capturou strategic-compact.sh como wip antes do commit feat() — sem impacto funcional. Duração: ~25 min, 5 arquivos.

---

### Fase 11: instinct-loop-automation

**Goal:** O loop de instincts fecha automaticamente: `session_end` registrado → `/instinct-analyze` roda em background (haiku) → instincts atualizados sem ação manual.
**Depends on:** Fase 09
**Plans:** 2

Plans:
- [x] 11-01: observe-session-end.sh — gate por timestamp ISO + spawn haiku background + indicador de pendência em instinct-status
- [x] 11-02: instinct-analyze/SKILL.md — seção Trigger automático + Passo 9 sentinela + remoção de gap de scheduler

**Detalhes:**
Bloco `INSTINCT-ANALYZE AUTO-TRIGGER (R3-08/R3-09)` adicionado ao hook: guard `command -v claude`, extração de ts via python3 inline (sem jq), gate `[[ "$TS_OBS" > "$TS_LAST" ]]` (comparação lexicográfica ISO 8601), spawn `nohup timeout 120 claude --model claude-haiku-4-5 -p "/instinct-analyze" ... & disown`, fail-silent em subshell. Bug sistêmico encontrado e corrigido: `[ <= ]` não suporta strings em bash — corrigido para `[[ ]]`. Plano 11-02: Passo 9 em instinct-analyze que atualiza sentinela `.last-analyzed-<proj>` apenas em conclusão bem-sucedida. Duração: ~27 min total, 4 arquivos.

---

### Fase 12: evals-ci

**Goal:** A suíte de 22+ evals executa automaticamente em push via GitHub Actions; `run-evals.sh` usa API key de CI; invariantes bloqueiam merge em falha.
**Depends on:** Fase 09
**Plans:** 2

Plans:
- [x] 12-01: run_case_with_model() em run-evals.sh + flag --ci + política pass^k/pass@k + results/.gitignore
- [x] 12-02: .github/workflows/evals.yml (2 jobs) + seção CI/CD no evals/README.md

**Detalhes:**
`run_case_with_model()` implementado com `timeout 90 claude -p`, fallback perl para bash 3.2 compat (macOS), avaliação por grep com detecção de negação, flag `--ci` com política exit 1/0 diferenciada. Workflow com job `structural` (sempre, python3 inline frontmatter validation, zero dependências) + job `llm-evals` (gated por `check_key.outputs.skip` — mais confiável que `if: secret` em branches não-default). Desvio bug: Python comment com indentação errada no inline YAML script quebrava lógica — corrigido antes do commit. Verifier identificou gap de borda: skip sem key em `--ci` triggava exit 1 indevidamente (linhas 250-256 de run-evals.sh, fix documentado). Duração: ~18 min total, 4 arquivos criados.

---

### Fase 13: security-dx-manifest

**Goal:** `idea-doctor.sh` cobre deny rules e contexts; falso positivo de `nc` em TypeScript eliminado; manifesto e skills com dependências externas corrigidos ou marcados.
**Depends on:** — (independente; pode executar em paralelo com 11 e 12)
**Plans:** 3

Plans:
- [x] 13-01: idea-doctor.sh — Seção 7a deny rules WARN + Seção 8 contexts/aliases/statusline (R3-14, R3-15)
- [x] 13-02: scan-absorbed.sh nc word-boundary + ideiaos-catalog contagem dinâmica + banner-design/fvl deps externas (R3-16, R3-17, R3-18)
- [x] 13-03: scripts/apply-to-all-projects.sh + modules.json entry + README.md (R3-19)

**Detalhes:**
`idea-doctor.sh` OK: 48 OK, 0 WARN, 0 FAIL após Seções 7a+8 (linhas 156-227). Seção 7a: proxy de run via statusline em settings.json (mais robusto que verificar arquivo de script). Seção 8: todos os checks como WARN (contexts opcionais-mas-recomendados). `scan-absorbed.sh`: `\bnc\b` — `function`, `sync`, `async`, `truncate` não geram WARN; `nc localhost 4444` e `nc -lvp 9001` ainda detectados. `ideiaos-catalog/SKILL.md`: contagem hardcoded removida, contagem dinâmica via python3 no bloco de código. `apply-to-all-projects.sh`: dry-run DEFAULT; detecta 5 repos (Jarvis, cfoai-grupori, ideiapartner, lapidai, nfideia); exclui IdeiaOS via realpath. Executor da Fase 13 interrompido e retomado (Plan 01 via autosync commit 85c0d06 no Mac-mini; Plans 02+03 em sessão de retomada). Módulos: 71→72 entries. Duração: ~3 sessões, 8 arquivos.

---

## Resumo do milestone

**Desvios notáveis:**

- **Bug sistêmico no gate de instincts (Fase 11):** `[ "$TS_OBS" \<= "$TS_LAST" ]` causa "binary operator expected" em bash — o builtin `[` não suporta `<=` para strings. Corrigido inline para `[[ "$TS_OBS" > "$TS_LAST" ]]`. Descoberto durante o teste comportamental TEST B.
- **Bug no loop de skip/CI (Fase 12 — encontrado pelo verifier):** Veredito `skip` (key ausente em CI_MODE) incrementava `pass_hat_total` sem `pass_hat_aprovados`, triggando exit 1 indevidamente. Fix identificado: `[[ "$verdict" == "skip" ]] && continue` antes das linhas de contagem. Bug de borda (workflow real nunca chama `--ci` sem key), mas contradiz spec.
- **Executor da Fase 13 interrompido e retomado:** Plan 13-01 foi executado e commitado pelo autosync do Mac-mini (85c0d06) antes da sessão principal. Plans 02+03 foram executados em sessão de retomada. Nenhum impacto funcional.
- **Autosync races (Fase 10 e 13):** autosync capturou arquivos intermediários como commits wip antes de commits feat() explícitos. Kill-switch timeout 120s (Fase 02 v2.0) mitiga travamentos; conteúdo correto commitado em ambos os casos.
- **Plugin copy obrigatória (Fases 09+10):** A Fase 09 estabeleceu que `plugins/ideiaos-core/agents/` deve sempre ser sincronizada com `source/agents/` — aplicado também na Fase 10 sem estar no plano explícito (desvio auto-corrigido).

**Decisões-chave:**

- `validate_agent_contracts()` chamada antes do build (não como step separado) — falha rápida antes de qualquer cópia (Fase 09)
- Docs históricos com `setup-checker` receberam nota "(corrigido na Fase 09)" sem reescrita — preserva rastreabilidade (Fase 09)
- Counter plain-text integer vs JSON em strategic-compact — scalar único não justifica overhead de JSON; zero jq (Fase 10)
- `typescript-lsp` como `source:null` (config-only) — não instala pacote npm, apenas referência para `detect_stack()` (Fase 10)
- Sentinela de instincts atualizado **apenas em conclusão bem-sucedida** — falha = no-op = retry automático na próxima sessão (Fase 11)
- `llm-evals` job usa `steps.check_key.outputs.skip` em vez de `if: secret` — mais confiável em branches não-default do GitHub Actions (Fase 12)
- Seção 7a do doctor como WARN (não FAIL) para deny rules — FAIL apenas para `settings.json` ausente (Fase 13)
- `apply-to-all-projects.sh` dry-run por padrão — `--apply` requer intenção explícita; exclui IdeiaOS via `realpath` comparison (Fase 13)

**Dívida técnica incorrida:**

- Bug de skip/exit 1 em `run-evals.sh` não corrigido no milestone (comportamento de borda; workaround é o workflow real que nunca executa sem key) — fix documentado no 12-VERIFICATION.md para v4
- Verificação de trigger real do GitHub Actions (push → workflow) requer acesso humano ao repositório remoto — não verificável localmente

---

_Para status atual do projeto, ver .planning/ROADMAP.md_
