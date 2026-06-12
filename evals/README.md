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

**Ponto de extensão futuro:** o script expõe uma função `run_case_with_model()` marcada como
`TODO` — quando um harness de execução automática (API key + cliente LLM) estiver disponível,
plugar a chamada nessa função. Nenhuma outra alteração no runner será necessária.

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
