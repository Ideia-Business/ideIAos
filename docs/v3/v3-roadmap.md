# SOURCE: IdeiaOS v2

**Data:** 2026-06-12
**Fase:** 08-04 — Síntese v3 (Wave 2)
**Derivado de:** docs/v3/v3-review.md (gaps G-01..G-15)

---

## Objetivo

Propor fases candidatas para o IdeiaOS v3, agrupando os gaps priorizados em `v3-review.md` em unidades de entrega coerentes. Cada fase fecha um conjunto de gaps relacionados com esforço/valor compatíveis.

---

## Fase v3-01 — Contratos de Agents (G-01, G-02)

**Nome:** agent-contracts
**Goal:** Todos os agents têm `model:` e `tools:` explícitos no frontmatter; `ideiaos-checker` tem nome canônico alinhado entre filename e modules.json.

**Gaps fechados:**
- G-01: `claude-continuation` e `ideiaos-checker` sem `model:` e `tools:` declarados
- G-02: Inconsistência filename (`ideiaos-checker.md`) vs `name: setup-checker` vs modules.json

**Entregas:**
- Adicionar `model: sonnet` e `tools: Read, Grep, Glob, Bash` em `source/agents/claude-continuation.md`
- Decidir nome canônico para o checker (proposta: `ideiaos-checker`) e alinhar `name:` no frontmatter + entry em `manifests/modules.json`
- Adicionar `model: sonnet` e `tools: Read, Bash` em `source/agents/ideiaos-checker.md`
- Flag opcional `--auto-apply` no Passo 3 do `ideiaos-checker` para mode agentic sem bloqueio de confirmação

**Esforço:** Baixo (3-5 arquivos, mudanças pontuais)
**Valor:** Alto (elimina comportamento imprevisível em agents críticos de continuidade e setup)

---

## Fase v3-02 — Loop de Instincts Automático (G-03)

**Nome:** instinct-loop-automation
**Goal:** O loop de instincts fecha o ciclo automaticamente: captura automática (já existe) → destilação automática (gap) → promoção manual (já existe via `/evolve`).

**Gaps fechados:**
- G-03: `/instinct-analyze` sem scheduler — captura automática, destilação manual

**Entregas:**
- Criar hook `observe-session-end-analyze.sh` que chama `/instinct-analyze` como subagente haiku após registrar `session_end` (ou estender `observe-session-end.sh`)
- OU adicionar lógica em `session-summary.sh` para invocar `/instinct-analyze` após gravar o resumo da sessão
- Guardar em `manifests/modules.json` e documentar como gate: só roda se `observations.jsonl` tiver entradas novas desde a última análise (evitar runs desnecessários)
- Atualizar `source/skills/instinct-analyze/SKILL.md` para documentar o novo trigger automático e remover o gap mencionado

**Esforço:** Médio (novo hook ou extensão de hook existente + lógica de gate)
**Valor:** Alto (fecha a promessa da Fase A; o loop de aprendizado passa a ser realmente automático)

---

## Fase v3-03 — Evals Automáticas + CI Mínimo (G-04, G-08)

**Nome:** evals-ci
**Goal:** A suíte de 22+ casos de eval executa automaticamente em push/PR via GitHub Actions, e `run-evals.sh` pode rodar com API key de CI.

**Gaps fechados:**
- G-04: `run-evals.sh` nunca executa automaticamente — suíte é rede de papel
- G-08: Ausência de CI/CD — regressões detectadas só manualmente

**Entregas:**
- Criar `.github/workflows/evals.yml` com trigger em `push` para `source/**` e `evals/**`
- Implementar `run_case_with_model()` em `run-evals.sh` (ponto de extensão já nomeado em 07-02) para execução real via API key de CI
- Definir política de aprovação: pass^k para invariantes (falha = PR bloqueado), pass@k para capacidades (falha = warning)
- Documentar em `evals/README.md` como configurar `ANTHROPIC_API_KEY` como secret do repositório
- (Opcional) Adicionar job de linting/shellcheck para hooks e scripts bash no mesmo workflow

**Esforço:** Alto (GitHub Actions + extensão do runner + testes de integração)
**Valor:** Alto (transforma a suíte existente em rede de segurança real; qualquer regressão é detectada antes do merge)

---

## Fase v3-04 — Otimizações de Token Economy (G-05, G-06, G-07)

**Nome:** token-optimizations
**Goal:** Aplicar as três otimizações de custo decididas em 08-03: downgrade de silent-failure-hunter, bash puro em strategic-compact, e adoção de typescript-lsp.

**Gaps fechados:**
- G-05: `silent-failure-hunter` em opus sem justificativa para processo de grep fixo
- G-06: `strategic-compact` usa subprocess python3 a cada tool call
- G-07: `typescript-lsp` não instalado com `installStrategy: stack:typescript`

**Entregas:**
- Atualizar `source/agents/silent-failure-hunter.md`: `model: sonnet` (testar com 3 casos reais antes de commitar)
- Reescrever contador em `source/hooks/strategic-compact.sh`: substituir subprocess python3 por `echo N > /tmp/ideiaos-toolcount-$$` + leitura bash pura
- Adicionar entry `typescript-lsp` em `manifests/modules.json` com `installStrategy: stack:typescript`; documentar configuração (`tsconfig.json` path) em `setup.sh` passo correspondente
- Rodar `bash scripts/build-adapters.sh --target all` após mudanças em agents/hooks

**Esforço:** Médio (3 mudanças independentes, cada uma com critério de validação)
**Valor:** Alto (economia estimada: ~5x por invocação do hunter + ~900ms por sessão no compact + find-refs semântico)

---

## Fase v3-05 — Segurança e Diagnóstico (G-10, G-11, G-15)

**Nome:** security-dx
**Goal:** Deny rules são verificadas e reportadas pelo idea-doctor; contexts de modo são verificados; falso positivo de `nc ` no scan-absorbed é eliminado.

**Gaps fechados:**
- G-10: Deny rules baseline dependem de ação manual em máquinas existentes
- G-11: Contexts (`claude-dev/review/research`) não verificados pelo `idea-doctor.sh`
- G-15: `nc ` em scan-absorbed.sh gera falsos positivos em código TypeScript

**Entregas:**
- Adicionar verificação de deny rules na Seção 7 do `idea-doctor.sh` (já existe Seção 7 de Security Audit — adicionar check das 6 deny rules específicas em `settings.json`)
- Adicionar verificação de `~/.ideiaos/contexts/` e presença do snippet de shell na Seção de Skills do `idea-doctor.sh`
- Corrigir pattern em `security/scan-absorbed.sh`: `r'nc '` → `r'\bnc\b'` (word boundary) para evitar match em `function`, `sync`, `async`, `truncate`
- Opcional: adicionar auto-fix sugerido no idea-doctor para deny rules ausentes (`install-global-patches.sh`)

**Esforço:** Baixo-Médio (scripts bash existentes, mudanças pontuais)
**Valor:** Médio-Alto (reduz fricção de DX e melhora postura de segurança sem custo operacional)

---

## Fase v3-06 — Manifesto e Skills (G-09, G-12, G-13, G-14)

**Nome:** manifest-cleanup
**Goal:** manifests/modules.json reflete o estado real do sistema; skills com dependências quebradas são corrigidas ou marcadas; mecanismo de propagação multi-repo é prototipado.

**Gaps fechados:**
- G-09: Sem mecanismo para propagar setup a múltiplos projetos-alvo de uma vez
- G-12: `banner-design` referencia skills inexistentes fora do modules.json
- G-13: `frontend-visual-loop` referencia `gsd-ui-review` ausente do manifesto
- G-14: `ideiaos-catalog` desatualizado — menciona 60 módulos, real é 66+

**Entregas:**
- Atualizar `manifests/modules.json` para contagem real pós-Fase 07 (66+ módulos); atualizar `source/skills/ideiaos-catalog/SKILL.md` para refletir contagem correta
- Em `source/skills/banner-design/SKILL.md`: marcar `ai-artist`, `ai-multimodal`, `chrome-devtools`, `frontend-design` como "claudekit-origin — requer setup separado" ou remover a dependência se não usada
- Em `source/skills/frontend-visual-loop/SKILL.md`: marcar `gsd-ui-review` como "planejado v3" ou adicionar ao modules.json com status `planned`
- Adicionar script `scripts/apply-to-all-projects.sh` (ou função em `sync-all.sh`) que itera sobre os repos em `~/dev/` detectados e roda `setup.sh --project-only` em cada um — com dry-run por padrão

**Esforço:** Médio (manifesto + script multi-repo)
**Valor:** Médio (qualidade operacional e escalabilidade de manutenção)

---

## Visão Geral das Fases

| Fase | Nome | Gaps | Esforço | Valor | Dependências |
|------|------|------|---------|-------|--------------|
| v3-01 | agent-contracts | G-01, G-02 | Baixo | Alto | — |
| v3-02 | instinct-loop-automation | G-03 | Médio | Alto | v3-01 (opcional) |
| v3-03 | evals-ci | G-04, G-08 | Alto | Alto | — |
| v3-04 | token-optimizations | G-05, G-06, G-07 | Médio | Alto | v3-01 |
| v3-05 | security-dx | G-10, G-11, G-15 | Médio | Médio-Alto | — |
| v3-06 | manifest-cleanup | G-09, G-12, G-13, G-14 | Médio | Médio | v3-04 (lsp entry) |

**Ordem recomendada:** v3-01 primeiro (custo zero, elimina risco) → v3-04 (otimizações de custo, alimentadas por v3-01) → v3-02 (automação do loop) → v3-03 (CI, mais complexo mas alto valor) → v3-05 e v3-06 em paralelo.
