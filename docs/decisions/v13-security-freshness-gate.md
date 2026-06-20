# ADR — v13: Security Freshness Gate (Selo de Frescor de Segurança)

**Status:** **Aceito** (2026-06-20) · aprovado pelo usuário; build GSD em andamento (W1→W4)
**Contexto-fonte:** sessão de design 2026-06-20 (grilling + 3 decisões via AskUserQuestion)
**Sucede:** [v12 — QA & AI-Security]; reusa o padrão SOAK (`.planning/soak/` + `check-soak.sh`) e a disciplina `antifragile-gates`.
**Proveniência:** **nativo IdeiaOS** (composição de peças existentes; zero dependência/ferramenta/MCP novo).

## Contexto

Pedido do usuário: hoje a revisão de segurança (`@security-reviewer`, OWASP LLM Top 10) só roda
**sob demanda**. O usuário quer que **todo sistema tenha, em algum momento, a segurança verificada
— não só quando solicitado** — com uma **marcação** de que rodou, e uma **nova revisão após X
implantações**. Restrição explícita: **não enrijecer** (qualquer melhoria passando por rigor extremo)
**nem afrouxar** (insegurança acumulando por features novas). Meio-termo aceitável.

## Princípio (a espinha)

**Rigor = `risco da superfície tocada × quão velha está a última revisão`.** Rigor proporcional,
nunca fixo. Mudança neutra e fresca → invisível. Superfície crítica sobre revisão velha → barulho alto.
O que decide o rigor **não** é "é melhoria nova?" — é "*essa* mudança tocou superfície sensível, e
*há quanto tempo* ninguém revisa isso?".

## Decisão

Implementar um **gate de frescor de segurança** que é o **padrão SOAK aplicado a dívida de segurança**:
gatilho **determinístico**, revisão por **julgamento** (LLM), re-selo **determinístico**. Três decisões
do usuário (2026-06-20) fixam o desenho:

| Eixo | Decisão | Efeito |
|---|---|---|
| **Onde morde** | Trava **só o TAG/release** (nunca o PR) | Feature flui sem fricção; egrégio trava `git tag` no IdeiaOS; Lovable = WARN (deploy automático, sem tag pra travar) |
| **Como conta o X** | **Risk-weighted** por superfície (não flat) | Diff tocou `auth/RLS/secrets/deps/integrações/LLM` pesa; UI/docs/refactor ~não movem |
| **Rollout** | **5 sistemas de uma vez** (IdeiaOS + 4 produtos) | Cobertura imediata — **com 2 mitigações obrigatórias** (ver abaixo) |

### Mecanismo (compõe o que já existe)

| Peça | Papel | Origem |
|---|---|---|
| `.security/review-ledger.log` (por repo) | **a marcação** — `epoch\|iso\|commit\|revisor\|veredito\|escopo`, append-only | espelha `.planning/soak/*.log` |
| `scripts/check-security-freshness.sh` | gatilho determinístico (`git diff <último_selo>..HEAD` + path-globs + score + tempo → tier) **+ `--record`** | espelha `check-soak.sh` |
| pesos/limiares em `core-config.yaml` | risk-weighting tunável | config existente |
| `idea-doctor §14` | lê ledger, emite tier (OK/WARN; FAIL-soft só no contexto de tag) | padrão §7/§13 |
| `@security-reviewer` (sobre o **diff** desde o último selo) | **a revisão** (STRIDE + OWASP LLM) — escopo proporcional, não re-auditoria total | já existe |
| `source/rules/common/security-freshness.md` | a doutrina (proporcionalidade, globs, escada) | nova rule |

> **Antifragile:** o **gatilho** é binário (git+globs+contagem+tempo — não pode ser alucinado); o
> **julgamento** é o agente; o **selo** é determinístico. Nunca "o LLM decide se está seguro" — o git
> decide *se está na hora*, o agente *revisa*, o ledger *prova*. Mesma filosofia do v11/v12 (núcleo
> determinístico, LLM advisory).

### Risk-weighting (determinístico, à prova de gaming)

| Peso | Superfície | Globs (exemplos) |
|---|---|---|
| **3 — crítica** | auth, RLS/migrations, manuseio de secret, integração externa com credencial, endpoint/SDK de LLM | `**/auth/**`, `**/*migration*`, `**/rls/**`, `**/.env*`, `**/integrations/**`, `**/ai/**` |
| **1 — sensível** | rotas de API, validação de input, deps/lockfile (CVE) | `**/api/**`, `package-lock.json`, `**/middleware/**` |
| **0 — neutra** | UI, docs, testes, refactor | `**/*.css`, `docs/**`, `**/*.test.*` |

`score = Σ peso(arquivos no diff desde o último selo)`. Conta **superfície tocada**, não nº de commits.

### Escada de escalonamento (defaults — tunáveis)

- **fresco** (`score < 10` e `idade < 90d`) → **silent OK**.
- **stale** (`score ≥ 10` **OU** `idade ≥ 90d` **OU** qualquer peso-3 sem revisão em 30d) → **WARN** (todos os 5).
- **egrégio** (`score ≥ 20` **OU** `idade ≥ 180d`) → **trava o `git tag` do IdeiaOS** (compõe com `check-soak`); **WARN forte** nos produtos Lovable.
- Gatilho duplo (OR) com tempo porque **dependência apodrece sozinha** (CVE sem mudança de código).

### Mitigações obrigatórias do rollout "5 de uma vez"

1. **Bootstrap-baseline:** o `setup.sh --project-only` cria `.security/` e grava um **selo-baseline no HEAD atual** de cada repo → dia-1 com `score=0` (sem vermelho instantâneo por "nunca revisado").
2. **1º ciclo advisory-puro:** estreia com **WARN em todos + tag-gate do IdeiaOS DESLIGADO** (flag de maturação). Observa-se um ciclo real; só então liga-se o gate-no-tag. Espírito do SOAK (maturar antes de cravar).

## Consequências

- **+** Segurança verificada **periodicamente e por sistema**, sem gatear PR de feature — resolve o pedido sem enrijecer.
- **+** Proporcionalidade real: rigor escala com risco × idade; CSS fresco é invisível, auth velho é barulhento.
- **+** Zero dependência nova: git + globs + agente que já temos + padrão de ledger já provado (SOAK).
- **+** A marcação é auditável (commit + veredito + escopo no ledger) — combate "teatro de segurança".
- **−** Mais 1 rule sempre-on (`security-freshness`) + 1 check no doctor (§14) + 1 script. Pago: dívida de segurança deixa de ser invisível.
- **− Risco do rollout 5-de-uma-vez** (estreia sem dogfood-soak): mitigado por bootstrap-baseline + 1º-ciclo-advisory. Se WARN ruidoso, ajusta-se limiares no `core-config.yaml` antes de ligar o gate.
- **SOAK:** v13 fecha PARCIAL/no-tag; tag `v13.0` só após soak ≥2 máquinas + ≥1d (gate herdado do v11).

## Decisões adiadas (fora de escopo do v13)

- Promover a lente OWASP LLM Top 10 do `security-reviewer` de ADVISORY → bloqueante (decisão separada, pós-soak).
- Bloquear PR em superfície crítica (a 3ª opção da decisão "onde morde", **não** escolhida) — fica como could-have de um v13.x se o WARN se mostrar insuficiente.
- Wirar o `@security-reviewer` automaticamente no fluxo de PR (vs sob demanda).
