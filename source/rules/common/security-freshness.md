<!-- SOURCE: IdeiaOS v13 | kind: rule | targets: claude,cursor -->
# Security Freshness — Selo de Frescor de Segurança

## Princípio

Segurança tem que ser verificada **periodicamente e por sistema** — não só quando alguém
pede. Mas rigor fixo é veneno: trava melhoria boba e cansa o time. A regra-piso é
**proporcionalidade**:

> **rigor = (risco da superfície tocada) × (idade da última revisão de segurança).**

Mudança neutra e fresca → invisível. Superfície crítica sobre revisão velha → barulho alto.
O que decide o rigor **não** é "é melhoria nova?" — é "*essa* mudança tocou superfície
sensível, e *há quanto tempo* ninguém revisa isso?".

É o padrão **SOAK** (`check-soak.sh`) aplicado a **dívida de segurança**, e segue o mesmo eixo
do `antifragile-gates`: **gatilho determinístico → julgamento (LLM) → selo determinístico**.

## O mecanismo (`scripts/check-security-freshness.sh`)

| Etapa | O quê | Quem |
|-------|-------|------|
| **Gatilho** | `git diff <último_selo>..HEAD` + path-globs por risco + score + idade → tier | DETERMINÍSTICO (git, não LLM) |
| **Revisão** | `@security-reviewer` (STRIDE + OWASP LLM Top 10) sobre o **diff desde o último selo** — não re-auditoria total | JULGAMENTO (LLM) |
| **Re-selo** | `check-security-freshness.sh --record [veredito] [revisor]` grava no ledger e zera o contador | DETERMINÍSTICO |

**Ledger** (append-only, **commitado** — prova cross-máquina, igual `.planning/soak/`):
`.security/review-ledger.log` → `epoch|iso|commit|revisor|veredito|escopo`. É **a marcação de
que a segurança rodou**.

## Risk-weighting (determinístico, à prova de gaming)

O contador conta **superfície tocada**, não nº de commits. Peso por path-glob:

- **3 — crítica:** auth, migrations/RLS, manuseio de secret/credencial, integração externa, endpoint/SDK de LLM, hooks de enforcement, `.env*`.
- **1 — sensível:** rotas de API, deps/lockfile (CVE), middleware, `*.sql`, edge functions.
- **0 — neutra:** UI, docs, testes, refactor.

Tunável por repo sem editar o script: `.security/policy.sh` (sourced) ou env
`SECFRESH_CRITICAL_GLOBS`/`SECFRESH_SENSITIVE_GLOBS`/limiares. Defaults são product-oriented
(React/Supabase) + genéricos (`*credential*`, `*enforce*`, `*.env*`).

## A escada de escalonamento (o meio-termo — NUNCA gateia PR de feature)

| Tier | Condição (defaults) | Efeito |
|------|---------------------|--------|
| **fresco** | `score<10` e `idade<90d` | silent OK |
| **stale** | `score≥10` **OU** `idade≥90d` **OU** mudança crítica sem revisão em 30d | **WARN** no `idea-doctor §14` (todos os sistemas) |
| **egrégio** | `score≥20` **OU** `idade≥180d` | **trava o `git tag` do IdeiaOS** (`--gate`, quando ligado); **WARN forte** nos produtos Lovable (deploy automático — não há tag pra travar) |

Gatilho duplo (OR) com tempo porque **dependência apodrece sozinha** (CVE sem mudança de código).
`idea-doctor §14` **nunca dá FAIL** (FAIL bloquearia o SOAK) — só WARN/info; o bloqueio real é o `--gate`.

## Onde morde — e o 1º ciclo advisory (R13-07)

- **Nunca** bloqueia PR de feature. O único ponto que trava é o **TAG/release do IdeiaOS**, no tier egrégio, via `check-security-freshness.sh --gate`.
- **Gate LIGADO (default versionado `=1`, desde v16/2026-06-30):** após o 1º ciclo advisory observado (baseline + 4 selos PASS de `@security-reviewer`, limiares calibrados), o default do script passou a `SECFRESH_GATE_ENABLED:-1` → no tier **egrégio** o `--gate` **bloqueia** o tag. Continua tunável: `SECFRESH_GATE_ENABLED=0` (env ou `.security/policy.sh` local, gitignored) **desliga** por máquina. NB: ligar na frota é o **default do script** (versionado), não o `policy.sh` (que é local-only por convenção).

### Procedimento pré-tag (compõe com SOAK)
Antes de `git tag vN.0` no IdeiaOS, rode os dois gates irmãos:
```
bash scripts/check-soak.sh <milestone>              # durabilidade cross-máquina
bash scripts/check-security-freshness.sh --gate     # frescor de segurança (advisory no 1º ciclo)
```

## Bootstrap (evita "dia-1 vermelho")
Repo sem ledger = `unbootstrapped`. O `setup.sh --project-only` (e o rollout) rodam
`check-security-freshness.sh --bootstrap` → grava um **selo-baseline no HEAD atual** → contador
começa em **0**. Sem isso, todo repo nasceria "nunca revisado" → egrégio instantâneo.

## Quando re-selar
Rode `@security-reviewer` no diff desde o último selo; ao concluir, grave:
`bash scripts/check-security-freshness.sh --record PASS @security-reviewer`. Commite o ledger
(autosync empurra). Em produto Lovable, isso vai por **branch + PR**, nunca main automática.

## Cross-links
- `security-reviewer` (agent) — a revisão de fato (STRIDE + OWASP LLM Top 10).
- `antifragile-gates` — o eixo determinístico/exit-code que o gatilho segue.
- `credential-isolation` · `mcp-hygiene` · `agent-authority` — as doutrinas que a revisão checa.
