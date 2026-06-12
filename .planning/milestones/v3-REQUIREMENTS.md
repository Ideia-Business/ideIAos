# Requirements Archive — IdeiaOS v3

**Milestone:** v3 — Refinamento e Automação
**Status:** SHIPPED 2026-06-12
**Origem:** docs/v3/v3-review.md (gaps G-01..G-15) derivados na Fase 08 (v2.0)
**Total de requisitos:** 19 (R3-01..R3-19)
**Cobertura de gaps:** 15/15 gaps cobertos

---

## Grupo 1 — Contratos de Agents (Fase 09)

### R3-01 — Frontmatter model+tools em agents críticos
- [x] **Entregue** | Fase 09 (commit 9bd9469) | Outcome: validated
- `claude-continuation.md` e `ideiaos-checker.md` têm `model:` e `tools:` explícitos em source/ e plugins/; `build-adapters.sh --target all` exit 0 com validação confirmada.
- Mapeia: G-01 | Prioridade: P1

### R3-02 — Nome canônico ideiaos-checker alinhado
- [x] **Entregue** | Fase 09 (commit 9bd9469) | Outcome: validated
- `ideiaos-checker.md` tem `name: ideiaos-checker`; `manifests/modules.json` referencia `"id": "ideiaos-checker"`; `git grep -l "setup-checker"` retorna apenas docs históricos/planning com nota de correção.
- Mapeia: G-02 | Prioridade: P1

### R3-03 — Validação de contrato de frontmatter em build
- [x] **Entregue** | Fase 09 (commit a81d421) | Outcome: validated
- `validate_agent_contracts()` em `scripts/build-adapters.sh` emite erro e exit 1 se qualquer agent em `source/agents/` não tiver `model:` e `tools:`; todos os 15 agents passam.
- Mapeia: G-01, G-02 | Prioridade: P1

### R3-04 — Flag --auto-apply no ideiaos-checker
- [x] **Entregue** | Fase 09 (commit 4e21c57) | Outcome: validated
- `--auto-apply` documentado no Passo 3 de `source/agents/ideiaos-checker.md` com 5 ocorrências na seção dedicada; comportamento original preservado sem a flag.
- Mapeia: G-01 | Prioridade: P2

---

## Grupo 2 — Token Economy (Fase 10)

### R3-05 — silent-failure-hunter downgrade opus→sonnet
- [x] **Entregue** | Fase 10 (commit e05c505) | Outcome: validated
- `source/agents/silent-failure-hunter.md` tem `model: sonnet`; zero ocorrências de `opus`; 3 casos reais validados (catch vazio, .then sem .catch, supabase sem .error check) confirmam que processo é inteiramente grep-based.
- Mapeia: G-05 | Prioridade: P2

### R3-06 — strategic-compact.sh bash puro sem python3
- [x] **Entregue** | Fase 10 (commit d25860f autosync) | Outcome: validated
- `source/hooks/strategic-compact.sh` sem nenhuma invocação de `python3`; parse de session_id via grep/sed; contador plain-text integer em /tmp; guards T-10-01 e T-10-03 preservados; testado com 200+ tool calls sem regressão.
- Mapeia: G-06 | Prioridade: P2

### R3-07 — typescript-lsp no manifesto com installStrategy:stack:typescript
- [x] **Entregue** | Fase 10 (commit ee6eda7) | Outcome: validated
- `manifests/modules.json` contém entry `typescript-lsp` com `"installStrategy": "stack:typescript"`; `setup.sh` inclui bloco condicional usando `detect_stack()` — primeira consumidora real do padrão stack:*. Módulo 71 do catálogo.
- Mapeia: G-07 | Prioridade: P2

---

## Grupo 3 — Instinct Loop Automático (Fase 11)

### R3-08 — Mecanismo automático dispara /instinct-analyze após session_end
- [x] **Entregue** | Fase 11 (commit cdae3f8) | Outcome: validated
- `observe-session-end.sh` spawna `nohup timeout 120 claude --model claude-haiku-4-5 -p "/instinct-analyze"` em background; fire-and-forget com disown; hook retorna imediatamente; 8/8 testes de observe-hooks passam.
- Mapeia: G-03 | Prioridade: P1

### R3-09 — Gate evita runs desnecessários sem observações novas
- [x] **Entregue** | Fase 11 (commit cdae3f8) | Outcome: validated (com bug fix)
- Gate `[[ "$TS_OBS" > "$TS_LAST" ]]` compara ISO 8601 lexicograficamente; sentinela `.last-analyzed-<proj>` tratado como epoch `1970-01-01T00:00:00` se ausente. Bug sistêmico corrigido durante a fase: `[ <= ]` não suporta strings em bash — substituído por `[[ ]]`.
- Mapeia: G-03 | Prioridade: P2

### R3-10 — instinct-analyze/SKILL.md documenta trigger automático
- [x] **Entregue** | Fase 11 (commit fe7d5fb) | Outcome: validated
- `source/skills/instinct-analyze/SKILL.md` contém seção "Trigger automático (Stop hook)" em "Quando rodar"; Passo 9 atualiza `.last-analyzed-<proj>` apenas em conclusão bem-sucedida; nenhuma referência a "gap de scheduler" ou destilação manual como pendência.
- Mapeia: G-03 | Prioridade: P2

---

## Grupo 4 — Evals Automáticas + CI (Fase 12)

### R3-11 — run_case_with_model() com execução real via API key
- [x] **Entregue** | Fase 12 (commit de91454) | Outcome: validated
- `run_case_with_model()` em `evals/run-evals.sh` invoca `timeout 90 claude -p` com `ANTHROPIC_API_KEY`; perl fallback para bash 3.2 compat; avaliação por grep com detecção de negação; 22 casos executam em dry-run sem erro; stub test com fake claude valida caminho completo.
- Mapeia: G-04 | Prioridade: P1

### R3-12 — GitHub Actions workflow com trigger push source/** e evals/**
- [x] **Entregue** | Fase 12 (commit 0ad8ca0) | Outcome: validated (trigger real pendente verificação humana)
- `.github/workflows/evals.yml` criado com triggers em push/PR para `source/**` e `evals/**` + `workflow_dispatch`; job `structural` (sempre) + job `llm-evals` (gated por secret); invariantes pass^k bloqueiam com exit 1; capacidades pass@k emitem warning sem bloquear.
- Mapeia: G-04, G-08 | Prioridade: P1

### R3-13 — Política pass^k/pass@k documentada e configurada
- [x] **Entregue** | Fase 12 (commits de91454 + 0ad8ca0) | Outcome: adjusted
- `evals/README.md` descreve as duas políticas e como configurar `ANTHROPIC_API_KEY` como secret (seção CI/CD linha 94, tabela linha 114); workflow implementa saída diferenciada. Ajuste: bug de borda identificado pelo verifier (skip sem key em --ci triggava exit 1 indevidamente) — documentado em 12-VERIFICATION.md para correção em v4.
- Mapeia: G-04, G-08 | Prioridade: P2

---

## Grupo 5 — Segurança e Diagnóstico (Fase 13)

### R3-14 — idea-doctor.sh Seção 7a: WARN para deny rules ausentes
- [x] **Entregue** | Fase 13 (commit 85c0d06 autosync) | Outcome: validated
- `idea-doctor.sh` reporta WARN quando qualquer das 6 deny rules baseline está ausente de `settings.json`; proxy de run via statusline IdeiaOS; sugere `install-global-patches.sh`; 48 OK, 0 WARN, 0 FAIL na máquina de desenvolvimento.
- Mapeia: G-10 | Prioridade: P2

### R3-15 — idea-doctor.sh Seção 8: WARN para contexts e aliases ausentes
- [x] **Entregue** | Fase 13 (commit 85c0d06 autosync) | Outcome: validated
- Seção 8 verifica presença de `~/.ideiaos/contexts/dev.md`, `review.md`, `research.md`; funções `claude-dev/review/research` no `~/.bashrc`; statusline IdeiaOS. Todos os checks como WARN (contexts opcionais-mas-recomendados).
- Mapeia: G-11 | Prioridade: P2

### R3-16 — scan-absorbed.sh usa word boundary \bnc\b
- [x] **Entregue** | Fase 13 (commit 6428bb8) | Outcome: validated
- `security/scan-absorbed.sh` com `\bnc\b`: palavras TypeScript como `function`, `sync`, `async`, `truncate` não geram WARN; `nc localhost 4444` e `nc -lvp 9001` ainda detectados corretamente.
- Mapeia: G-15 | Prioridade: P3

---

## Grupo 6 — Manifesto e Skills (Fase 13)

### R3-17 — modules.json e ideiaos-catalog/SKILL.md refletem contagem real (70+)
- [x] **Entregue** | Fase 13 (commit 6428bb8) | Outcome: adjusted
- `source/skills/ideiaos-catalog/SKILL.md`: contagem hardcoded removida do texto narrativo; contagem dinâmica via python3 inline no bloco de código. `manifests/modules.json` com 72 entries (71 após Fase 10, +1 apply-to-all-projects na Fase 13-03).
- Mapeia: G-14 | Prioridade: P3

### R3-18 — Skills com deps externas marcadas explicitamente
- [x] **Entregue** | Fase 13 (commit 6428bb8) | Outcome: validated
- `source/skills/banner-design/SKILL.md` com nota "claudekit-origin — requer setup separado" em 2 ocorrências para deps `ai-artist`, `ai-multimodal`, `chrome-devtools`, `frontend-design`; `source/skills/frontend-visual-loop/SKILL.md` com `gsd-ui-review` marcado como "externo/planejado v3" em 2 ocorrências.
- Mapeia: G-12, G-13 | Prioridade: P3

### R3-19 — scripts/apply-to-all-projects.sh com dry-run por padrão
- [x] **Entregue** | Fase 13 (commit 6e31fcc) | Outcome: validated
- `scripts/apply-to-all-projects.sh --dry-run` lista 5 projetos (Jarvis, cfoai-grupori, ideiapartner, lapidai, nfideia) sem executar; `--apply` executa; `--only <nome>` filtra; script registrado em `manifests/modules.json` como entry 72 (`installStrategy: "manual"`).
- Mapeia: G-09 | Prioridade: P2

---

## Traceability final

| Requisito | Fase | Status final |
|-----------|------|-------------|
| R3-01 | 09 | Completo |
| R3-02 | 09 | Completo |
| R3-03 | 09 | Completo |
| R3-04 | 09 | Completo |
| R3-05 | 10 | Completo |
| R3-06 | 10 | Completo |
| R3-07 | 10 | Completo |
| R3-08 | 11 | Completo |
| R3-09 | 11 | Completo (bug fix sistêmico durante teste) |
| R3-10 | 11 | Completo |
| R3-11 | 12 | Completo |
| R3-12 | 12 | Completo (trigger real pendente verificação humana) |
| R3-13 | 12 | Completo (bug de borda documentado para v4) |
| R3-14 | 13 | Completo |
| R3-15 | 13 | Completo |
| R3-16 | 13 | Completo |
| R3-17 | 13 | Completo (adjusted: contagem dinâmica em vez de valor fixo) |
| R3-18 | 13 | Completo |
| R3-19 | 13 | Completo |

**19/19 requisitos entregues. 15/15 gaps cobertos.**

---

## Cobertura de gaps

| Gap | Requisito(s) | Status |
|-----|-------------|--------|
| G-01 | R3-01, R3-03, R3-04 | Coberto |
| G-02 | R3-02, R3-03 | Coberto |
| G-03 | R3-08, R3-09, R3-10 | Coberto |
| G-04 | R3-11, R3-12, R3-13 | Coberto |
| G-05 | R3-05 | Coberto |
| G-06 | R3-06 | Coberto |
| G-07 | R3-07 | Coberto |
| G-08 | R3-12, R3-13 | Coberto |
| G-09 | R3-19 | Coberto |
| G-10 | R3-14 | Coberto |
| G-11 | R3-15 | Coberto |
| G-12 | R3-18 | Coberto |
| G-13 | R3-18 | Coberto |
| G-14 | R3-17 | Coberto |
| G-15 | R3-16 | Coberto |
