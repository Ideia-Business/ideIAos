# SOURCE: IdeiaOS v2

# Evals — Suíte de Regressão IdeiaOS

## Propósito

Esta suíte converte **incidentes reais** dos produtos (ideiapartner, nfideia) e desvios do
próprio IdeiaOS em **casos de avaliação executáveis**. Toda falha vivida vira um caso. O objetivo
é garantir que o mesmo problema nunca passe despercebido novamente em revisão ou geração de código.

A suíte é um ativo de regressão do repositório IdeiaOS — não é um módulo instalável nem um plugin.
Ela cresce incrementalmente: cada novo incidente real se torna um único arquivo em `evals/cases/`,
sem nenhuma alteração de código.

---

## Metodologia: pass@k vs pass^k

### pass@k — "PRECISA FUNCIONAR"

O comportamento esperado ocorre em **pelo menos 1** de k tentativas.

Use para capacidades de produtividade onde o importante é que o resultado seja alcançável —
mesmo que não ocorra em todas as tentativas. Exemplo: "dado este prompt de debug, Claude chega
à causa raiz em pelo menos 1 de 5 tentativas".

**Reporte:** `m/k aprovados` (ex: `3/5`).

### pass^k — "CONSISTÊNCIA OBRIGATÓRIA"

O comportamento esperado ocorre em **todas** as k tentativas.

Use para **invariantes de segurança e dados financeiros** onde uma única falha já é inaceitável.
Exemplo: "Claude NUNCA sugere INSERT cego em client_subscriptions" deve ser verdade em 100% das
tentativas — um único deslize é um incidente real.

**Reporte:** `k/k ou FALHOU` (qualquer reprovação = falha do caso).

### Tabela orientadora

| Contexto | Métrica | Justificativa |
|---|---|---|
| Invariantes de segurança (RLS, JWT, RBAC) | pass^k | 1 falha = vulnerabilidade |
| Dados financeiros (INSERT billing, reconciliação) | pass^k | 1 falha = dado errado em prod |
| Cache multi-tenant (vazamento de dados) | pass^k | 1 falha = vazamento de privacidade |
| Capacidades de produtividade (debug, research) | pass@k | Alcançabilidade suficiente |
| Geração de código funcional | pass@k | Iteração aceitável |
| Routing de modo (review não edita, research não codifica) | pass^k | Contrato de modo é invariante |

**k padrão sugerido: k = 5.** Para casos críticos (financeiro/segurança), considere k = 3 com
exigência de pass^k (mais rápido de executar, igualmente rigoroso).

---

## Estrutura da Suíte

```
evals/
  README.md          — esta metodologia
  _TEMPLATE.md       — formato canônico de caso
  run-evals.sh       — runner (iteração / --case / --dry-run / --list)
  cases/
    index.md         — roster de todos os casos
    EVAL-001-*.md    — casos individuais
    EVAL-NNN-*.md
```

---

## Como Executar

A execução do modelo é **manual/semi-automática por design** — `run-evals.sh` apresenta cada
caso (prompt/setup + critérios de aprovação) e registra o **veredito do operador** (pass/fail/skip).
O runner **não chama nenhum modelo LLM** e **não requer API key**.

O fluxo de uso normal é:

1. Abrir uma sessão Claude com o contexto/modo relevante.
2. Em outro terminal, rodar `bash evals/run-evals.sh` (ou `--case EVAL-NNN`).
3. Para cada caso: ler o prompt exibido, executá-lo na sessão Claude, observar o comportamento,
   registrar o veredito (`pass` / `fail` / `skip`) quando solicitado.
4. Ao final, o runner imprime um sumário `m/k por métrica`.

**Modo não-interativo (CI/headless):** quando stdin não é um TTY, o runner assume `--dry-run`
automaticamente (lista casos sem pedir veredito). Isso garante que `bash run-evals.sh </dev/null`
nunca trave em pipelines.

**Execução automática (Fase 12):** a função `run_case_with_model()` está IMPLEMENTADA —
executa cada caso via `claude -p` headless (timeout 90s), grava resultados em `evals/results/`
e aplica a política de bloqueio (pass^k falha → exit 1; pass@k falha → aviso). Use
`bash evals/run-evals.sh --ci` (requer `claude` no PATH ou `ANTHROPIC_API_KEY` em CI;
sem key o caso vira `skip` e não conta nas métricas).

---

## CI/CD — Execução Automática

### Workflow: `.github/workflows/evals.yml`

A suíte executa automaticamente em push/PR para `source/**` ou `evals/**` via dois jobs:

#### Job `structural` (sempre ativo, sem custo de API)

Valida sem chamar LLM:
- Syntax bash em todos os scripts (`bash -n`)
- Contagem de casos >= 22
- Frontmatter completo em todos os `EVAL-*.md` (campos obrigatórios: id, title, source, mode, metric, k, severity)
- `run-evals.sh --dry-run` exit 0

**Bloqueia PR em falha.** Configurar como required check em Settings → Branches.

#### Job `llm-evals` (requer secret ou workflow_dispatch)

Roda `run-evals.sh --ci` com API key real. Política de saída:

| Tipo | Métrica | Comportamento em falha |
|------|---------|------------------------|
| Invariante de segurança/dados | pass^k | **exit 1 — bloqueia merge** |
| Capacidade de produtividade | pass@k | warning no log — não bloqueia |

Resultados salvos em `evals/results/YYYYMMDD-HHMM.jsonl` e disponíveis como artifact no run.

### Configurar ANTHROPIC_API_KEY como secret

1. No GitHub: **Settings → Secrets and variables → Actions → New repository secret**
2. Nome: `ANTHROPIC_API_KEY`
3. Valor: chave de API Anthropic (obtida em https://console.anthropic.com/settings/keys)

Sem o secret, o job `llm-evals` é pulado automaticamente (não falha o build). Para forçar execução manual: **Actions → Run workflow → `run_llm: true`**.

### Custo estimado por run

- Job `structural`: grátis (sem chamadas LLM), ~30s
- Job `llm-evals`: 22 casos × k=1 × ~2k tokens/caso ≈ 44k tokens input. Com Claude Sonnet: ~$0.13 por run. Considerar rodar apenas em PR para `main` (não em todo push para `work`).

### Política de bloqueio (R3-13)

- `pass^k` falhou → `run-evals.sh --ci` retorna exit 1 → job falha → PR bloqueado (se configurado como required check)
- `pass@k` falhou → mensagem `AVISO` no log → job retorna exit 0 → PR não bloqueado
- Sem API key → job `llm-evals` pulado → apenas `structural` bloqueia

---

## Integração com gsd-verify-work

`gsd-verify-work` é uma skill do framework GSD localizada em `~/.claude/skills/gsd-verify-work/`.
Ela conduz UAT conversacional por fase e gera `{phase}-UAT.md` ao fechar uma fase.

**Ponto de integração (loop fechado: incidente → caso → regressão):**

1. Ao fechar uma fase com `gsd-verify-work`, identificar quais casos de eval são relevantes
   àquela fase.
2. Executar esses casos como parte do UAT (`bash evals/run-evals.sh --case EVAL-NNN`).
3. Qualquer **novo incidente descoberto durante o UAT** deve virar um caso novo em `evals/cases/`
   (copiar `_TEMPLATE.md` → `EVAL-NNN-slug.md` + uma linha no `index.md`).

Como `gsd-verify-work` é uma skill do framework GSD (não um componente `source/` do IdeiaOS),
a integração é **por referência documentada aqui** — não editamos a skill.

**Snippet de referência ao fechar uma fase:**

```markdown
## Eval Cases Executados

| Caso | Resultado | Observação |
|------|-----------|------------|
| EVAL-021 (mode-routing-review) | pass 5/5 | contexto review.md ativo |
| EVAL-004 (multitenant-cache) | pass 5/5 | — |

Novos incidentes descobertos no UAT: nenhum / [listar se houver → criar EVAL-NNN]
```

---

## Convenção de IDs

- IDs sequenciais: `EVAL-001`, `EVAL-002`, …, `EVAL-NNN`.
- Nome do arquivo: `EVAL-NNN-slug-curto.md` (slug em kebab-case, sem acentos).
- Cada caso aponta a um `source` real (repo + path do documento de incidente).

---

## Crescimento Incremental

Adicionar um novo incidente = três passos, **sem alterar código**:

1. Copiar `evals/_TEMPLATE.md` → `evals/cases/EVAL-NNN-slug.md`.
2. Preencher todos os campos (id, title, source, mode, metric, k, severity, prompt, critérios).
3. Adicionar uma linha na tabela de `evals/cases/index.md`.

O runner detecta automaticamente o novo arquivo na próxima execução.
