# IdeiaOS Cockpit — Validação do Substrato Real (Mac mini)

> **Doc 73 · Apuração eixo 1 (verify, don't assume).** Fecha o gap que a crítica adversarial
> apontou: "todo o recon foi numa máquina só (MacBook); o Mac mini só foi visto via ledger".
> Esta validação rodou **na própria Mac-mini** (2026-06-20), read-only e **metadata-only** (nenhum
> valor de segredo lido). Onde a realidade divergiu do blueprint, há **`[CORREÇÃO]`**.

## 0. Resumo executivo

A maioria das suposições do blueprint **se confirmou na máquina que nunca tinha sido inspecionada**.
Três achados mudam o plano: (1) o alias `192` é a **MacBook-Air-2**, não a Mac-mini; (2) a
Constelação tem **7 projetos reais** (não 5) — Jarvis e ideia-chat existem; (3) **nenhum segredo
crítico está git-tracked** — a `credential-isolation` segura na prática.

## 1. Identidade da máquina `[verificado]`

- Host: `Mac-mini-de-Gustavo.local` · macOS `26.6` · `machine_id = sha256(hardware-uuid)` → amostra `9d7fbccdbb1b`.
- **Confirma a estratégia de `machine_id`** do doc 40 (sha do hardware-uuid é estável e não-PII).
- Daemons IdeiaOS (`launchctl | ideiaos`): `envsync`, `gitautosync`, `refresh-ai-security` — **os mesmos 3** do MacBook (simetria neste eixo). PID `-` em repouso = **normal** (gotcha confirmado). Não há 4º daemon → o `com.ideiaos.cockpit` é adição limpa.

## 2. `idea-doctor --json` — CONFIRMADO AUSENTE `[verificado — crítico estava certo]`

40 ocorrências de `json` no fonte, **zero** manejo de flag `--json`/`--format`. R14-01 é **feature nova real**, pré-requisito de v14.0, não "já dá". O doc 72 detalha o risco (não-regressão da saída ANSI num script vivo de ~593 linhas que É o gate de saúde do OS).

## 3. Frota / SOAK ledgers `[verificado + CORREÇÃO]`

| Ledger | Hosts gravados | Linhas |
|--------|----------------|--------|
| `v11-arsenal.log` | Mac-mini-de-Gustavo, MacBook-Air-2 | 3 |
| `v12-qa-security.log` | **192**, Mac-mini-de-Gustavo | 2 |
| `v13-security-freshness.log` | Mac-mini-de-Gustavo, MacBook-Air-2 | 2 |

**`[CORREÇÃO]`** O blueprint (doc 40 §9 / doc 00 §9) dizia "dedup `192`↔`Mac-mini`". **Errado** —
estamos NA Mac-mini e ela se reporta com hostname completo; o `192` aparece ao lado de
`Mac-mini-de-Gustavo` no v12, logo `192` é a **MacBook-Air-2** (hostname caiu para fragmento de IP
naquela gravação). **Alias-map correto: `192 → MacBook-Air-2`.**

## 4. Constelação — descoberta dinâmica `[verificado + EXPANSÃO]`

`~/dev` real: `IdeiaOS`, **`Jarvis`**, `cfoai-grupori`, **`ideia-chat`**, `ideiapartner`, `lapidai`,
`nfideia` (+ dirs de teste `ollama-m3-test`, `teste-mega-cérebro`).

**`[EXPANSÃO]`** O plano assumia **5 produtos**; há **7+** reais. **Jarvis tem 469 sessões de
transcript** (mais que IdeiaOS, 353!) e não estava na lista. **Decisão:** a Constelação DEVE
**descobrir** os projetos (`~/dev/*` com `.git`), **classificar** (produto vs dir-de-teste vs
tooling) e **não hardcodar 5**. Sinal de atividade real (transcripts): Jarvis 469 · ideiapartner
361 · IdeiaOS 353 · evals 22 · cfoai 4 (confirma a hipótese "IDE primário = Cursor/Lovable" em cfoai).

## 5. Superfície de credenciais real `[verificado — metadata-only]`

Nomes de variáveis (NUNCA valores), com tier do catálogo de risco (doc 00 §9):

| Var | Tier | Onde aparece (produto/arquivo) |
|-----|------|-------------------------------|
| `SUPABASE_SERVICE_ROLE_KEY` | **crítico** | cfoai `.env`, ideiapartner `.env.local`, lapidai `.env` |
| `IDEIA_CHAT_SYSADMIN_PASSWORD` | **crítico** (mas **aceito · teste** — não re-flagar, ver memória) | ideiapartner `.env.local` |
| `NOTAGATEWAY_PASSWORD` / `OPS_DB_GATEWAY_TOKEN` | **crítico** | cfoai `.env` / ideiapartner `.env.local` |
| `VERCEL_TOKEN`, `GITHUB_TOKEN`, `RAILWAY_TOKEN` | **alto** | cfoai, lapidai (`.env`); ideiapartner (`.env.local`) |
| `N8N_API_KEY`, `SENTRY_DSN` | alto/sensível | cfoai, lapidai, ideiapartner |
| `ANTHROPIC/OPENAI/OPENROUTER/DEEPSEEK/EXA/CONTEXT7/CLICKUP` | sensível | cfoai, lapidai, ideiapartner |
| `SUPABASE_ANON_KEY`, `*_PUBLISHABLE_KEY`, `VITE_*`, `NODE_ENV`, `AIOX_VERSION` | baixo/público | todos |

### 5.1 Checagem "EXPOSTO NO GIT" `[verificado — boa notícia]`

| Arquivo | Estado git | Veredito |
|---------|-----------|----------|
| cfoai `.env` (tem SERVICE_ROLE) | 🟢 gitignored | ok |
| lapidai `.env` (tem SERVICE_ROLE) | 🟢 gitignored | ok |
| ideiapartner `.env.local` (tem SERVICE_ROLE) | 🟢 gitignored | ok |
| ideiapartner `.env` | 🔴 **tracked** | mas **só públicos** (3 `VITE_*`) → 🟡 aceitável |
| nfideia `.env` | 🔴 **tracked** | mas **só públicos** (publishable/url/project_id) → 🟡 aceitável |

**Conclusão:** **nenhum segredo crítico está git-tracked.** Todo arquivo com `SERVICE_ROLE`/token
está gitignored; os dois `.env` rastreados contêm só valores públicos (publishable/anon/url são
client-side por design). A `credential-isolation` **segura na prática**. O Cofre-Espelho mostraria
esses dois como 🟡 (público-tracked), não 🔴. Nota de higiene (não-bloqueante): nfideia/ideiapartner
são Lovable-em-main → qualquer ajuste só via branch+PR; não há urgência (sem segredo exposto).

## 6. Sinapse, Contas, Supabase `[verificado]`

- **MCP:** Claude = `[chrome-devtools, context7]`; Cursor = `[chrome-devtools, context7, lovable, resend]`. (O `resend` no Cursor não estava destacado no plano — adicionar à Sinapse.)
- **GitHub (gh):** 2 contas no keyring — `DevIdeiaBusiness` (ativa) + `gustavolpaiva` (inativa); scopes `[gist, read:org, repo, workflow]`; token no keyring (fora do contexto) ✓.
- **Supabase project_id (público):** cfoai `ajvlqsdmjczkenzejznn` · ideiapartner `jtsevyeoymefkcrydhcg` · lapidai `suzztzorxqurzqgquptc` · nfideia `pdljyfyyxufkqejncccv`.
- **Observations:** ~35 escopos (`~/.ideiaos/observations/`), incl. jarvis, ideia-chat, nfideia-* — sinal de produtividade mais rico que o assumido.

## 7. Correções aplicadas ao plano (rastreabilidade)

1. **`192 → MacBook-Air-2`** (não Mac-mini) — corrigido no blueprint 00 §9; o alias-map do data-model deve refletir.
2. **Constelação descobre, não hardcoda** — 7 projetos reais; classificar produto vs teste; Jarvis é 1ª-classe.
3. **Assimetria entre máquinas FECHADA** — a Mac-mini foi inspecionada diretamente; os 3 daemons + `idea-doctor` ausente conferem. O collector ainda declara `agentd_version`/`os_version` por robustez, mas a suposição de simetria não é mais cega.
4. **Cofre com dados reais** — a matriz var×produto da §5 é a fixture real para o mockup/MVP; a checagem §5.1 valida o alert "EXPOSTO NO GIT".
5. **`resend` MCP (Cursor)** entra na Sinapse.
