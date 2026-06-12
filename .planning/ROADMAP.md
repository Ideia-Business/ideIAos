# Roadmap — IdeiaOS

## Milestones

- **v2.0 — Canivete Suíço Universal (absorção ECC)** SHIPPED 2026-06-12 — 8 fases, 29 planos, 33→70 módulos, plugin marketplace, instincts, contexts+evals. Detalhes: [.planning/milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)
- **v3 — Refinamento e Automação** ATIVO — 5 fases (09–13), 15 gaps G-01..G-15, 19 requisitos R3-01..R3-19

---

## Phases (v3)

- [x] **Fase 09: agent-contracts** — Frontmatters completos e nome canônico alinhado em todos os agents críticos
- [x] **Fase 10: token-optimizations** — Três otimizações de custo independentes aplicadas e validadas
- [x] **Fase 11: instinct-loop-automation** — Loop de instincts fecha o ciclo automaticamente após cada sessão
- [x] **Fase 12: evals-ci** — Suíte de 22 evals executa automaticamente em CI a cada push
- [ ] **Fase 13: security-dx-manifest** — Diagnóstico cobre deny rules e contexts; manifesto e skills corrigidos

---

## Phase Details

### Fase 09: agent-contracts

**Goal:** Todos os agents têm `model:` e `tools:` explícitos no frontmatter; nome canônico de `ideiaos-checker` alinhado entre filename, frontmatter e modules.json; build-adapters valida o contrato.
**Depends on:** — (independente)
**Requirements:** R3-01, R3-02, R3-03, R3-04
**Deliverables:**

- Adicionar `model: sonnet` e `tools: Read, Grep, Glob, Bash` em `source/agents/claude-continuation.md`
- Renomear `name: setup-checker` → `name: ideiaos-checker`; alinhar entry em `manifests/modules.json`
- Adicionar `model: sonnet` e `tools: Read, Bash` em `source/agents/ideiaos-checker.md`
- Adicionar verificação de frontmatter obrigatório em `scripts/build-adapters.sh` (exit não-zero se faltar)
- Flag `--auto-apply` no Passo 3 do `ideiaos-checker` para modo agentic

**Success Criteria** (o que deve ser VERDADE):

  1. `build-adapters.sh --target all` termina sem erro e valida campos `model:` e `tools:` em todos os agents
  2. Nenhuma ocorrência de `setup-checker` persiste em arquivo rastreado pelo git
  3. `claude-continuation.md` e `ideiaos-checker.md` têm frontmatters completos auditáveis por grep
  4. Invocar `ideiaos-checker --auto-apply` aplica patches sem prompt interativo

**Plans:** TBD

---

### Fase 10: token-optimizations

**Goal:** Três otimizações de custo independentes aplicadas: downgrade opus→sonnet no hunter, bash puro no compact, e typescript-lsp registrado no manifesto.
**Depends on:** Fase 09
**Requirements:** R3-05, R3-06, R3-07
**Deliverables:**

- Atualizar `source/agents/silent-failure-hunter.md`: `model: sonnet` (validar com 3 casos reais antes do commit)
- Reescrever contador em `source/hooks/strategic-compact.sh`: substituir subprocess python3 por bash puro (`echo N > /tmp/ideiaos-toolcount-$$`)
- Adicionar entry `typescript-lsp` em `manifests/modules.json` com `installStrategy: "stack:typescript"`; documentar configuração de `tsconfig.json` em `setup.sh`
- Rodar `bash scripts/build-adapters.sh --target all` após mudanças

**Success Criteria** (o que deve ser VERDADE):

  1. `silent-failure-hunter.md` tem `model: sonnet`; 3 execuções de teste produzem saída equivalente à versão opus
  2. `strategic-compact.sh` não contém nenhuma invocação de `python3`; sessão com 200 tool calls funciona sem regressão
  3. `manifests/modules.json` contém entry `typescript-lsp` com `installStrategy: "stack:typescript"`

**Plans:** TBD

---

### Fase 11: instinct-loop-automation

**Goal:** O loop de instincts fecha automaticamente: `session_end` registrado → `/instinct-analyze` roda em background (haiku) → instincts atualizados sem ação manual.
**Depends on:** Fase 09
**Requirements:** R3-08, R3-09, R3-10
**Deliverables:**

- Criar `scripts/hooks/observe-session-end-analyze.sh` (ou estender `observe-session-end.sh`) para invocar `/instinct-analyze` como subagente haiku após `session_end`
- Implementar gate: só executa se `observations.jsonl` tiver entradas mais recentes que o timestamp da última análise
- Registrar o novo hook em `manifests/modules.json`
- Atualizar `source/skills/instinct-analyze/SKILL.md`: documentar trigger automático, remover menção ao gap de scheduler

**Success Criteria** (o que deve ser VERDADE):

  1. Após encerrar uma sessão com observações novas, `~/.ideiaos/instincts/` é atualizado sem ação do usuário
  2. Encerrar uma sessão sem observações novas não dispara `/instinct-analyze` (gate funcionando)
  3. `instinct-analyze/SKILL.md` descreve o trigger automático e não menciona destilação manual como pendência

**Plans:** TBD

---

### Fase 12: evals-ci

**Goal:** A suíte de 22+ evals executa automaticamente em push via GitHub Actions; `run-evals.sh` usa API key de CI; invariantes bloqueiam merge em falha.
**Depends on:** Fase 09
**Requirements:** R3-11, R3-12, R3-13
**Deliverables:**

- Implementar `run_case_with_model()` em `run-evals.sh` para execução real via `ANTHROPIC_API_KEY`
- Criar `.github/workflows/evals.yml` com trigger em push para `source/**` e `evals/**`
- Definir política no workflow: pass^k para invariantes (exit 1 = PR bloqueado), pass@k para capacidades (warning)
- Documentar configuração de `ANTHROPIC_API_KEY` como secret em `evals/README.md`
- (Opcional) Adicionar job de shellcheck para hooks e scripts bash no mesmo workflow

**Success Criteria** (o que deve ser VERDADE):

  1. Push com mudança em `source/` ou `evals/` dispara o workflow sem intervenção manual
  2. Falha em um caso invariante retorna exit 1 e bloqueia o PR; falha em capacidade emite warning sem bloquear
  3. `run-evals.sh` invoca a API Claude e produz resultado PASS/FAIL para todos os 22 casos quando `ANTHROPIC_API_KEY` está disponível
  4. `evals/README.md` contém instruções para configurar o secret no repositório

**Plans:** TBD

---

### Fase 13: security-dx-manifest

**Goal:** `idea-doctor.sh` cobre deny rules e contexts; falso positivo de `nc` em TypeScript eliminado; manifesto e skills com dependências externas corrigidos ou marcados.
**Depends on:** — (independente; pode executar em paralelo com 11 e 12)
**Requirements:** R3-14, R3-15, R3-16, R3-17, R3-18, R3-19
**Deliverables:**

- Adicionar verificação das 6 deny rules baseline na Seção 7 do `idea-doctor.sh`; sugerir `install-global-patches.sh` em caso de ausência
- Adicionar verificação de `~/.ideiaos/contexts/` e presença do snippet de shell na Seção de Skills do `idea-doctor.sh`
- Corrigir pattern em `security/scan-absorbed.sh`: `r'nc '` → `r'\bnc\b'`
- Atualizar `manifests/modules.json` e `source/skills/ideiaos-catalog/SKILL.md` para contagem real (70+ módulos)
- Marcar dependências externas em `banner-design/SKILL.md` e `frontend-visual-loop/SKILL.md` com status explícito
- Criar `scripts/apply-to-all-projects.sh` com dry-run por padrão; registrar em `manifests/modules.json`

**Success Criteria** (o que deve ser VERDADE):

  1. `idea-doctor.sh` reporta WARN quando qualquer das 6 deny rules está ausente e sugere o comando de correção
  2. `idea-doctor.sh` reporta WARN quando `~/.ideiaos/contexts/` está incompleto
  3. Absorver código TypeScript com `function`, `sync`, `async`, `truncate` não gera nenhum WARN de `nc` em `scan-absorbed.sh`
  4. `ideiaos-catalog/SKILL.md` menciona ≥70 módulos, consistente com `modules.json`
  5. `scripts/apply-to-all-projects.sh --dry-run` lista projetos sem executar; sem flag executa em cada repo detectado

**Plans:** 3 plans
Plans:

- [ ] 13-01-PLAN.md — idea-doctor: deny rules WARN + Seção 8 contexts (R3-14, R3-15)
- [ ] 13-02-PLAN.md — scan-absorbed nc fix + skills manifest corrections (R3-16, R3-17, R3-18)
- [ ] 13-03-PLAN.md — apply-to-all-projects.sh + modules.json + README (R3-19)

**UI hint**: no

---

## Progress Table

| Fase | Planos Completos | Status | Concluída |
|------|-----------------|--------|-----------|
| 09 — agent-contracts | 1/1 | Complete    | 2026-06-12 |
| 10 — token-optimizations | 1/1 | Completa | 2026-06-12 |
| 11 — instinct-loop-automation | 2/2 | Complete | 2026-06-12 |
| 12 — evals-ci | 2/2 | Complete | 2026-06-12 |
| 13 — security-dx-manifest | 0/3 | Não iniciada | — |
