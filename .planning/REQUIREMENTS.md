# Requirements — IdeiaOS v3

**Milestone:** v3 — Refinamento e Automação
**Derivado de:** docs/v3/v3-review.md (gaps G-01..G-15) + docs/v3/v3-roadmap.md
**Data:** 2026-06-12
**Total de requisitos v3:** 18

---

## Grupo 1 — Contratos de Agents (Fase 09)

### R3-01

**Descrição:** `claude-continuation.md` e `ideiaos-checker.md` devem ter `model:` e `tools:` explícitos no frontmatter.
**Mapeia:** G-01
**Prioridade:** P1
**Critério de aceitação:** Ambos os frontmatters contêm campos `model:` e `tools:` não vazios; `build-adapters.sh --target all` executa sem erro.

### R3-02

**Descrição:** O agent `ideiaos-checker` deve ter nome canônico alinhado entre filename, campo `name:` no frontmatter e entry em `manifests/modules.json`.
**Mapeia:** G-02
**Prioridade:** P1
**Critério de aceitação:** `ideiaos-checker.md` tem `name: ideiaos-checker`; `manifests/modules.json` referencia `"id": "ideiaos-checker"`; nenhuma ocorrência de `setup-checker` persiste em nenhum arquivo rastreado.

### R3-03

**Descrição:** O contrato de frontmatter dos agents (campos `model:` e `tools:` obrigatórios) deve ser verificado por script/CI a cada build de adapters.
**Mapeia:** G-01, G-02
**Prioridade:** P1
**Critério de aceitação:** `scripts/build-adapters.sh` (ou script auxiliar dedicado) emite erro e termina com exit não-zero se qualquer agent em `source/agents/` não tiver `model:` e `tools:` presentes no frontmatter.

### R3-04

**Descrição:** O `ideiaos-checker` deve suportar flag `--auto-apply` para executar o Passo 3 sem solicitar confirmação do usuário.
**Mapeia:** G-01
**Prioridade:** P2
**Critério de aceitação:** Invocando o checker com `--auto-apply` o Passo 3 aplica patches sem prompt interativo; sem a flag o comportamento original é preservado.

---

## Grupo 2 — Token Economy (Fase 10)

### R3-05

**Descrição:** `silent-failure-hunter` deve usar `model: sonnet` em vez de opus.
**Mapeia:** G-05
**Prioridade:** P2
**Critério de aceitação:** Frontmatter de `source/agents/silent-failure-hunter.md` contém `model: sonnet`; 3 casos reais de uso validados manualmente produzem saída equivalente ao opus.

### R3-06

**Descrição:** `strategic-compact.sh` deve substituir o contador baseado em subprocess python3 por bash puro.
**Mapeia:** G-06
**Prioridade:** P2
**Critério de aceitação:** `strategic-compact.sh` não contém invocação de `python3` para contagem de tool calls; o contador funciona corretamente em sessão com 200+ tool calls sem regressão.

### R3-07

**Descrição:** `typescript-lsp` deve ser registrado em `manifests/modules.json` com `installStrategy: stack:typescript` e ter a configuração documentada no `setup.sh`.
**Mapeia:** G-07
**Prioridade:** P2
**Critério de aceitação:** `manifests/modules.json` contém entry `typescript-lsp` com `installStrategy: "stack:typescript"`; `setup.sh` inclui passo de configuração de `tsconfig.json` path; `idea-doctor.sh` verifica presença do LSP em projetos TypeScript.

---

## Grupo 3 — Instinct Loop Automático (Fase 11)

### R3-08

**Descrição:** Deve existir um mecanismo automático que dispara `/instinct-analyze` após `session_end` ser registrado em `observations.jsonl`.
**Mapeia:** G-03
**Prioridade:** P1
**Critério de aceitação:** Após o encerramento de uma sessão com observações novas, `/instinct-analyze` roda automaticamente como subagente haiku sem intervenção manual; `instincts/` é atualizado sem ação do usuário.

### R3-09

**Descrição:** O mecanismo de disparo automático deve incluir um gate que evite rodar `/instinct-analyze` quando não há observações novas desde a última análise.
**Mapeia:** G-03
**Prioridade:** P2
**Critério de aceitação:** O hook/script verifica timestamp da última análise vs timestamp das entradas mais recentes em `observations.jsonl`; runs desnecessários não ocorrem.

### R3-10

**Descrição:** `source/skills/instinct-analyze/SKILL.md` deve documentar o trigger automático e não mencionar mais o gap de scheduler como pendência.
**Mapeia:** G-03
**Prioridade:** P2
**Critério de aceitação:** SKILL.md contém seção "Trigger automático" descrevendo o hook; não contém texto indicando que destilação é manual.

---

## Grupo 4 — Evals Automáticas + CI (Fase 12)

### R3-11

**Descrição:** `run-evals.sh` deve ter `run_case_with_model()` implementado para execução real via API key de CI.
**Mapeia:** G-04
**Prioridade:** P1
**Critério de aceitação:** `run_case_with_model()` invoca a API Claude com a API key de ambiente (`ANTHROPIC_API_KEY`); os 22 casos executam e produzem resultado PASS/FAIL sem erro de execução.

### R3-12

**Descrição:** Deve existir um workflow GitHub Actions (`.github/workflows/evals.yml`) que execute a suíte de evals automaticamente em push para `source/**` e `evals/**`.
**Mapeia:** G-04, G-08
**Prioridade:** P1
**Critério de aceitação:** Push para branch `work` com mudança em `source/` ou `evals/` dispara o workflow; invariantes (pass^k) bloqueiam merge em falha; capacidades (pass@k) emitem warning sem bloquear.

### R3-13

**Descrição:** A política de aprovação de evals (pass^k vs pass@k) deve estar documentada e configurada no workflow de CI.
**Mapeia:** G-04, G-08
**Prioridade:** P2
**Critério de aceitação:** `evals/README.md` descreve as duas políticas e como configurar `ANTHROPIC_API_KEY` como secret; o workflow implementa saída diferenciada (exit 1 para invariantes, exit 0+warning para capacidades).

---

## Grupo 5 — Segurança e Diagnóstico (Fase 13)

### R3-14

**Descrição:** `idea-doctor.sh` deve verificar a presença das 6 deny rules baseline em `settings.json` na Seção 7 (Security Audit).
**Mapeia:** G-10
**Prioridade:** P2
**Critério de aceitação:** `idea-doctor.sh` reporta WARN ou ERROR quando qualquer das 6 deny rules (Read `~/.ssh/**`, `~/.aws/**`, `**/.env*`; Write `~/.ssh/**`; Bash `curl|bash`, `nc *`) está ausente do `settings.json`; sugere rodar `install-global-patches.sh`.

### R3-15

**Descrição:** `idea-doctor.sh` deve verificar a presença dos contexts (`~/.ideiaos/contexts/`) e do snippet de shell nos targets de diagnóstico.
**Mapeia:** G-11
**Prioridade:** P2
**Critério de aceitação:** `idea-doctor.sh` detecta ausência de `~/.ideiaos/contexts/dev.md`, `review.md` ou `research.md` e emite WARN com instrução de reexecutar `setup.sh --project-only`.

### R3-16

**Descrição:** `security/scan-absorbed.sh` deve usar word boundary (`\bnc\b`) em vez de `nc ` para eliminar falsos positivos em código TypeScript.
**Mapeia:** G-15
**Prioridade:** P3
**Critério de aceitação:** Absorver código TypeScript com palavras `function`, `sync`, `async`, `truncate` não gera nenhum WARN de `nc`; código com `nc ` literal (netcat) ainda é detectado.

---

## Grupo 6 — Manifesto e Skills (Fase 13)

### R3-17

**Descrição:** `manifests/modules.json` e `source/skills/ideiaos-catalog/SKILL.md` devem refletir a contagem real de módulos pós-Fase 07 (70+).
**Mapeia:** G-14
**Prioridade:** P3
**Critério de aceitação:** `ideiaos-catalog/SKILL.md` menciona ≥70 módulos; contagem no arquivo é consistente com o número real de entries em `modules.json`.

### R3-18

**Descrição:** Skills `banner-design` e `frontend-visual-loop` devem ter dependências externas marcadas explicitamente em seus SKILL.md como "claudekit-origin — requer setup separado" ou "planejado v3", eliminando referências implícitas a módulos ausentes do manifesto.
**Mapeia:** G-12, G-13
**Prioridade:** P3
**Critério de aceitação:** `banner-design/SKILL.md` não referencia `ai-artist`, `ai-multimodal`, `chrome-devtools`, `frontend-design` como se fossem disponíveis no IdeiaOS sem nota; `frontend-visual-loop/SKILL.md` marca `gsd-ui-review` com status explícito.

### R3-19

**Descrição:** Deve existir script `scripts/apply-to-all-projects.sh` que aplique `setup.sh --project-only` a todos os repositórios-alvo detectados em `~/dev/`, com dry-run por padrão.
**Mapeia:** G-09
**Prioridade:** P2
**Critério de aceitação:** `scripts/apply-to-all-projects.sh --dry-run` lista os projetos que receberiam o setup sem executá-lo; sem a flag executa em cada repo detectado; script está registrado em `manifests/modules.json`.

---

## Traceability

| Requisito | Fase | Status |
|-----------|------|--------|
| R3-01 | Fase 09 | Completo |
| R3-02 | Fase 09 | Completo |
| R3-03 | Fase 09 | Completo |
| R3-04 | Fase 09 | Completo |
| R3-05 | Fase 10 | Completo |
| R3-06 | Fase 10 | Completo |
| R3-07 | Fase 10 | Completo |
| R3-08 | Fase 11 | Pendente |
| R3-09 | Fase 11 | Pendente |
| R3-10 | Fase 11 | Pendente |
| R3-11 | Fase 12 | Pendente |
| R3-12 | Fase 12 | Pendente |
| R3-13 | Fase 12 | Pendente |
| R3-14 | Fase 13 | Pendente |
| R3-15 | Fase 13 | Pendente |
| R3-16 | Fase 13 | Pendente |
| R3-17 | Fase 13 | Pendente |
| R3-18 | Fase 13 | Pendente |
| R3-19 | Fase 13 | Pendente |

---

## Cobertura de gaps

| Gap | Requisito(s) |
|-----|-------------|
| G-01 | R3-01, R3-03, R3-04 |
| G-02 | R3-02, R3-03 |
| G-03 | R3-08, R3-09, R3-10 |
| G-04 | R3-11, R3-12, R3-13 |
| G-05 | R3-05 |
| G-06 | R3-06 |
| G-07 | R3-07 |
| G-08 | R3-12, R3-13 |
| G-09 | R3-19 |
| G-10 | R3-14 |
| G-11 | R3-15 |
| G-12 | R3-18 |
| G-13 | R3-18 |
| G-14 | R3-17 |
| G-15 | R3-16 |

**Todos os 15 gaps cobertos. 19 requisitos derivados.**
