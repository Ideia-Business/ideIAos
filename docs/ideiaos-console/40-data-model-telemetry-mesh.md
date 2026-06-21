# 40 — Modelo de Dados & Malha de Telemetria

**Produto:** IdeiaOS Mission Control (console de CTO)
**Camada:** Data / Platform Engineering
**Status:** PROPOSTO (zero código — contrato de modelagem)
**Autor:** Data/Platform Engineer (subagente de planejamento)
**Data:** 2026-06-20

---

## 0. Tese central (o que muda o jogo)

O IdeiaOS **já é a malha de telemetria**. Cada sinal que um console de CTO precisaria — quais
máquinas estão vivas, quem commitou o quê, qual a saúde do ambiente, qual o frescor de segurança,
quais chaves existem — **já está sendo escrito em disco**, em formatos determinísticos, legíveis
sem LLM, e em parte **já commitado e federado cross-máquina via git** (`branch planning` +
`git-autosync`).

Portanto este documento **não modela uma pipeline de coleta nova**. Ele modela uma **camada de
leitura+normalização (read-model)** sobre substrato existente, e nomeia explicitamente o **único
componente de coleta que falta** (um `collector` por-máquina que materializa o estado efêmero —
`launchctl`, `idea-doctor`, contas de IA — num snapshot federável). A regra de ouro de toda esta
modelagem:

> **O console é CONTROL-PLANE de METADADOS. Nenhuma entidade armazena valor de segredo.**
> `ApiKey` guarda nome, presença, idade, escopo, last-seen — **nunca** o valor. Isso é a rule
> `credential-isolation` materializada no schema, não uma recomendação.

E o segundo princípio, herdado de `antifragile-gates`:

> **A fonte-de-verdade é o arquivo no disco (exit-code/ledger). O read-model é CACHE
> DESCARTÁVEL.** Se o read-model corromper, ele se reconstrói 100% relendo os ledgers. Nada
> nascido só no read-model é autoritativo.

---

## 1. Substrato verificado (não é recon — é leitura direta do disco, 2026-06-20)

Antes de modelar, ancorei cada formato lendo o arquivo real nesta máquina. O que segue é o que
**existe**, não o que o brief supõe:

| Fonte | Formato real (verificado) | Federação |
|-------|---------------------------|-----------|
| SOAK ledger | `epoch\|iso\|host\|idea_doctor=PASS\|regression=PASS\|commit` — pipe, append-only | **commitado** (`branch work`/`planning`) → cross-máquina via git |
| Security ledger | `epoch\|iso\|commit\|revisor\|veredito\|escopo` — pipe, append-only | **commitado** → cross-máquina |
| `versions.lock` | `chave=valor`, comentários `#` | **commitado** (pin de frota) — autosync IGNORA |
| autosync log | texto livre `YYYY-MM-DD HH:MM:SS [repo] ação em branch` | **local** (`~/.local/state/`, não-commitado) |
| autosync commit WIP | subject `wip: autosync YYYY-MM-DD HH:MM (HOST)` | **commitado** — é o proxy primário de "máquina X estava ativa" |
| observations JSONL | `{"ts","session_id","project","tool","file","ext","bash_verb","ok"}` — metadata-only | **local** (`~/.ideiaos/observations/`) |
| instincts | frontmatter `confidence`/`evidence_count`/`domain`/`scope` + corpo | **local** (`~/.ideiaos/instincts/`) |
| LaunchAgents | 3 plists `com.ideiaos.{gitautosync,envsync,refresh-ai-security}` | **local** — status via `launchctl list` (efêmero) |

**Gotcha confirmado no disco** (modelagem TEM que respeitar):

1. **`versions.lock` → `gsd=1.1.0` é MAIS NOVO que `1.36.0`** (reset de semver redux). O
   read-model **nunca** pode comparar `gsd` por semver numérico ingênuo — tem que ser
   string-equality contra o pin. (memória `version-reset-migration-semver-trap`.)
2. **Hostname do Mac mini aparece como `Mac-mini-de-Gustavo` E como `192`** (IP cru como
   hostname em `v12-qa-security.log` e em 2 commits WIP). A entidade `Machine` precisa de
   **deduplicação por alias**, senão o console conta 3 máquinas onde há 2.
3. **Os 3 LaunchAgents estão `-` (inativos) em repouso** — isso é **normal** (cada um tem seu
   `StartInterval`/`StartCalendarInterval`). O modelo de saúde do daemon **não** pode tratar
   `-` como falha; tem que cruzar com o último heartbeat efetivo no log.
4. **Security ledger do IdeiaOS é commitado; o dos produtos é local** (`.git/info/exclude`). A
   federação difere por repo — modelada na §5.

---

## 2. Entidades do domínio (o modelo conceitual)

Onze entidades. Cada uma com: **identidade**, **fonte(s) de derivação** (substrato existente),
**campos**, e **o que NUNCA armazena**.

### 2.1 `Machine` — uma máquina física na frota

Identidade canônica: `machine_id` = hostname **normalizado** (resolve aliases).

| Campo | Tipo | Fonte (derivação) |
|-------|------|-------------------|
| `machine_id` | string (PK) | hostname normalizado |
| `aliases[]` | string[] | todos os hostnames vistos (`Mac-mini-de-Gustavo`, `192`) — **dedup** |
| `display_name` | string | curado (ex.: "Mac mini de Gustavo") |
| `first_seen_epoch` | int | min(epoch) em SOAK ledger + commits WIP |
| `last_seen_epoch` | int | max(epoch) em SOAK ledger ∪ último commit WIP `(host)` |
| `last_doctor` | enum PASS/FAIL/unknown | campo `$4` do último heartbeat SOAK desta máquina |
| `last_regression` | enum PASS/FAIL/unknown | campo `$5` do último heartbeat SOAK |
| `last_commit` | sha | campo `$6` do último heartbeat |
| `is_active` | bool (derivado) | `now - last_seen_epoch < ACTIVE_WINDOW` (default 24h) |
| `daemons[]` | DaemonStatus[] | `MachineSnapshot` (§4) — só preenchido se a máquina rodou o collector |

> **Dedup de alias** é regra dura: mantenha um `machine-aliases.json` curado
> (`{"Mac-mini-de-Gustavo": ["192", "Mac-mini-de-Gustavo.local"]}`). Sem isso, toda métrica de
> "nº de máquinas" e todo gate SOAK (`≥2 máquinas`) é furado.

**NUNCA armazena:** IP atual, conteúdo de `.env`, segredo nenhum.

### 2.2 `Account` — uma conta autenticada por provedor

Identidade: `(provider, identifier)`. Provider ∈ {anthropic, github, cursor, lovable, supabase,
vercel, openrouter, deepseek, openai, ...}.

| Campo | Tipo | Fonte |
|-------|------|-------|
| `provider` | enum | — |
| `identifier` | string | email/handle (ex.: `gustavo@redeideia.com.br`, `DevIdeiaBusiness`) |
| `auth_mechanism` | enum oauth/keychain/env-ref/mcp-oauth | derivado da fonte |
| `scopes[]` | string[] | `gh auth status` (repo, workflow, read:org); claude `oauthAccount` |
| `is_active` | bool | conta selecionada (ex.: `gh` active vs inactive) |
| `bound_machine_id` | string? | qual máquina tem essa auth local (Keychain é per-máquina) |
| `last_verified_epoch` | int | quando o collector rodou `gh auth status` etc. |

**Derivação por provider (todos METADATA, nunca token):**
- **anthropic** → `~/.claude.json` `oauthAccount.emailAddress` (verificado: `gustavo@redeideia.com.br`).
- **github** → `gh auth status` (2 contas: `DevIdeiaBusiness` active, `gustavolpaiva` inactive; scopes `gist,read:org,repo,workflow`).
- **cursor** → `~/.cursor/mcp.json` + presença de `~/.cursor/projects/*/mcp_auth.json` (conta-se a **existência** de auth OAuth, nunca lê o token).
- **lovable** → MCP UUID `6f530143-…` em `~/.cursor/mcp.json`; estado enabled/disabled por projeto.
- **supabase/vercel/openrouter** → presença da **referência** de var no `.env` + `gh`/CLI metadata.

**NUNCA armazena:** token OAuth, PAT, `gho_*`, valor de API key.

### 2.3 `Project` — um repo/produto gerenciado

Identidade: `project_slug` (= nome do dir em `~/dev/`).

| Campo | Tipo | Fonte |
|-------|------|-------|
| `project_slug` | string (PK) | dir name (`nfideia`, `cfoai-grupori`, …) |
| `repo_path` | path | `~/dev/<slug>` |
| `github_remote` | url | `git remote -v` |
| `is_lovable` | bool | presença do bot `gpt-engineer-app[bot]` no git log + MCP enabled |
| `supabase_project_id` | string? | `grep '^project_id' supabase/config.toml` (verificado nfideia=`pdljyfyyxufkqejncccv`) |
| `default_branch` | string | `git symbolic-ref` |
| `under_autosync` | bool | presença em `git-autosync-repos.txt` (verificado: 6 repos) |
| `mcp_connections[]` | FK→McpConnection | `~/dev/<slug>/.cursor/mcp.json` + `.claude/settings.json` |
| `lovable_deny_count` | int | nº de tools mutantes em deny (esperado=19; auditável) |
| `env_keys[]` | FK→ApiKey | nomes de var em `.env` (NUNCA valor) |

**NUNCA armazena:** `.env` content, migrations data, RLS secrets.

### 2.4 `User` — um ator humano distinto

Identidade: `user_id` = email canônico (com mapa de aliases, igual `Machine`).

| Campo | Tipo | Fonte |
|-------|------|-------|
| `user_id` | string (PK) | email canônico |
| `aliases[]` | string[] | git emails que mapeiam ao mesmo humano |
| `display_name` | string | curado |
| `role` | enum cto/dev/bot/daemon | classificação (ver §6) |

**Mapeamento verificado (IdeiaOS, últimos 200 commits):**
- `gustavo@redeideia.com.br` → **Gustavo (CTO)** — 198/200 commits.
- `desenvolvimento@ideiabusiness.com.br` → **Dev Team** — 2/200.
- `gustavolopespaiva@Mac-mini-de-Gustavo.local` → **NÃO é humano** → role=`daemon` (autosync do Mac mini). **Filtrar de toda métrica de produtividade humana.**
- `…gpt-engineer-app[bot]@…` → role=`bot` (Lovable).
- `github-actions[bot]@…` → role=`bot` (CI).

> **Decisão de modelagem:** `User` ≠ `Account`. Um humano tem N contas (Anthropic + 2 GitHub).
> Um `Account` pertence a 1 `User`. A junção é manual/curada (não há sinal que ligue
> automaticamente conta GitHub a conta Anthropic — ambas são `gustavo@`, mas isso é coincidência,
> não garantia).

### 2.5 `ApiKey` — uma chave POR REFERÊNCIA (control-plane)

Identidade: `(project_slug, var_name)`. **Esta entidade é o coração da rule `credential-isolation`.**

| Campo | Tipo | Fonte |
|-------|------|-------|
| `var_name` | string | `grep '^[A-Z_]*=' .env \| sed 's/=.*//'` — **só o nome** |
| `project_slug` | FK | — |
| `present` | bool | a var existe no `.env`? |
| `expected` | bool | a var está no `.env.example`? (contrato) |
| `is_orphan` | bool (derivado) | `present && !expected` (var sem contrato) |
| `is_missing` | bool (derivado) | `expected && !present` (contrato sem var) |
| `risk_tier` | enum critical/sensitive/low/none | classificação por nome (ver tabela) |
| `file_mtime_epoch` | int | `stat -f %m .env` (proxy de "última rotação") |
| `committed` | bool | `git status` flagou o `.env`? (= incidente de segurança) |

**Risk-tier por NOME da var (catálogo, derivado do `.env.example`):**

| Tier | Vars (exemplos verificados no catálogo) |
|------|------------------------------------------|
| **critical** | `SUPABASE_SERVICE_ROLE_KEY`, `JWT_SECRET`, `OPS_DB_GATEWAY_TOKEN` |
| **sensitive** | `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY`, `GITHUB_TOKEN`, `VERCEL_TOKEN`, `RAILWAY_TOKEN`, `RESEND_API_KEY`, `EXA_API_KEY`, `CLICKUP_API_KEY` |
| **low** | `SUPABASE_ANON_KEY`, `VITE_SUPABASE_*` (chaves públicas) |
| **none** | `NODE_ENV`, `AIOX_VERSION`, `SUPABASE_URL` |

> **O VALOR NUNCA ENTRA NO SCHEMA.** O pipeline de derivação usa `sed 's/=.*//'` que **descarta
> tudo após o `=`**. Não há campo `value`. Não há, não haverá, e qualquer PR que adicione um é
> bloqueado por `credential-isolation` + `security-reviewer`. O `SUPABASE_SERVICE_ROLE_KEY` é o
> ativo de maior risco do ecossistema (bypassa RLS) — o console mostra `present: true,
> risk: critical, mtime: 12d` e **nada mais**.

### 2.6 `McpConnection` — uma ligação MCP (Claude/Cursor/Lovable)

Identidade: `(scope, server_id)`. Scope ∈ {global-claude, global-cursor, project}.

| Campo | Tipo | Fonte |
|-------|------|-------|
| `server_id` | string | UUID ou nome (`chrome-devtools`, `context7`, `6f530143-…`=lovable) |
| `host_ide` | enum claude/cursor | qual config |
| `scope` | enum | — |
| `enabled` | bool | ausência em `disabledMcpServers` |
| `requires_secret` | bool | refere `*_API_KEY` no config (ex.: `RESEND_API_KEY`) |
| `risk_class` | enum | tabela `mcp-hygiene` (critical/high/medium/low) |
| `deny_tools_count` | int? | p/ Lovable: nº de tools mutantes em deny (esperado=19) |

**Derivação:** `~/.claude/settings.json` (`disabledMcpServers`), `~/.cursor/mcp.json`,
`~/dev/<slug>/.cursor/mcp.json`, `~/dev/<slug>/.claude/settings.json`.

**NUNCA armazena:** OAuth token do plugin, `mcp_auth.json` content.

### 2.7 `ProductivityEvent` (e `Session`) — o sinal de trabalho

`Session` agrupa `ProductivityEvent`. Esta é a entidade mais sujeita a **vaidade vs sinal real**
(ver §6).

`ProductivityEvent` (granularidade fina, de observations JSONL):

| Campo | Tipo | Fonte (observations JSONL — metadata-only) |
|-------|------|--------|
| `ts` | iso | `ts` |
| `session_id` | string | `session_id` |
| `project_slug` | string | `project` |
| `tool` | string | `tool` (Bash/Read/Edit/Write) |
| `bash_verb` | string? | `bash_verb` (1º token — proxy de tipo de trabalho) |
| `ok` | bool | `ok` (taxa de sucesso) |
| `ext` | string? | `ext` (.ts/.tsx/.sql/.md) |

`Session` (agregado, de transcripts JSONL `~/.claude/projects/`):

| Campo | Tipo | Fonte |
|-------|------|-------|
| `session_id` | string (PK) | filename |
| `project_slug` | string | dir slug |
| `human_turns` | int | count `type=user` |
| `assistant_turns` | int | count `type=assistant` |
| `git_branch` | string | campo `gitBranch` |
| `start/end_epoch` | int | min/max `ts` |
| `is_meaningful` | bool (derivado) | `human_turns > 5` (filtro de ruído — subagentes têm ≤2) |

**NUNCA armazena:** conteúdo de prompt, diff, comando completo (a política `memory-hygiene` já
garante isso na coleta — observations NÃO têm esses campos).

### 2.8 `Commit` — atividade git derivada (não é entidade armazenada, é projeção)

Derivada on-demand de `git log --format='%H|%ae|%aI|%s'`. Campos: `sha`, `author_email`, `iso`,
`subject`, `project_slug`. **Classificada** em `human` / `bot` / `autosync` (ver §6) — a
classificação é o que separa sinal de vaidade.

### 2.9 `Milestone` + `SoakHeartbeat`

`Milestone` (de `.planning/ROADMAP.md` + `.planning/milestones/`):

| Campo | Fonte |
|-------|-------|
| `version` | `v11`, `v12`, `v13` |
| `status` | SHIPPED / PARTIAL-no-tag (parse ROADMAP) |
| `theme` | tema (arsenal, qa-security, security-freshness) |
| `soak_satisfied` | derivado: `machines_covered ≥ 2 && span_days ≥ 1` |

`SoakHeartbeat` (1 linha do ledger):

| Campo | Fonte (`epoch\|iso\|host\|doctor\|regression\|commit`) |
|-------|--------|
| `epoch`, `iso` | `$1`, `$2` |
| `machine_id` | `$3` **normalizado** (dedup `192`→`Mac-mini`) |
| `idea_doctor` | `$4` |
| `regression` | `$5` |
| `commit` | `$6` |
| `milestone` | nome do arquivo |

> **Gotcha de span** (memória `soak-span-is-record-delta-not-wallclock`): `span_days =
> (max_epoch − min_epoch)/86400` **sobre os epochs GRAVADOS**, não wall-clock desde o 1º
> heartbeat. O console mostra "v13 pronto p/ tag em: <quando o span≥1d se cumprir>" calculando
> sobre o ledger, não sobre `now`.

### 2.10 `SecurityFreshnessSeal`

Identidade: `(repo, epoch)`. De `.security/review-ledger.log`
(`epoch\|iso\|commit\|revisor\|veredito\|escopo`).

| Campo | Fonte |
|-------|-------|
| `epoch`, `iso` | `$1`, `$2` |
| `commit` | `$3` |
| `reviewer` | `$4` (`bootstrap`/`@security-reviewer`) |
| `verdict` | `$5` (PASS/FAIL/BASELINE) |
| `scope` | `$6` |
| `tier` (derivado) | `check-security-freshness.sh --tier` → ok/warn/egregious/unbootstrapped |
| `risk_score` (derivado) | path-glob weights (crítica=3, sensível=1, neutra=0) desde o último selo |
| `age_days` (derivado) | `(now − last_epoch)/86400` |

> Verificado: ledger atual tem **1 entrada** (baseline `a2f1a68`, 2026-06-20). O console mostra
> tier por repo — IdeiaOS commitado (federável), produtos locais (per-máquina).

### 2.11 `VersionPin` + `DriftFinding`

De `versions.lock` (`chave=valor`) cruzado com instalado (via `idea-doctor §5`):

| Campo | Fonte |
|-------|-------|
| `component` | `aiox-core`/`gsd`/`design-suite-ref`/… |
| `pinned` | valor em `versions.lock` |
| `installed` | derivado por máquina (collector) |
| `drift` | derivado: `pinned != installed` — **string-equality, NUNCA semver p/ `gsd`** |

---

## 3. Schema físico (read-model — SQLite recomendado)

**Decisão (enforce-simplicity):** o read-model é **SQLite single-file**
(`~/.ideiaos/console/read-model.db`), **não** Postgres. Razões:

1. O console roda **local-first** (mesma topologia do resto do IdeiaOS). Postgres é dependência e
   superfície de ataque que o nativo (SQLite, já no Node/Python) dispensa — `token-economy` /
   `enforce-simplicity`.
2. O read-model é **cache descartável reconstruível**: `rm read-model.db && rebuild` reconstrói
   tudo dos ledgers. Durabilidade vem do git, não do DB.
3. Schema relacional dá joins (Project→ApiKey, Machine→SoakHeartbeat) que JSON puro não dá bem.

> **Por que não JSON flat?** Tentado mentalmente; rejeitado. As consultas do console são
> relacionais ("chaves critical sem rotação >30d nos projetos Lovable") — isso é um JOIN, não um
> `map/filter`. SQLite é o "chato e óbvio" que paga.

```sql
-- ============================================================
-- read-model.db — CACHE DESCARTÁVEL. Fonte-de-verdade = ledgers no disco.
-- NENHUMA tabela armazena valor de segredo. Ver credential-isolation.
-- ============================================================

CREATE TABLE machine (
  machine_id        TEXT PRIMARY KEY,         -- hostname normalizado
  display_name      TEXT,
  aliases_json      TEXT NOT NULL DEFAULT '[]',
  first_seen_epoch  INTEGER,
  last_seen_epoch   INTEGER,
  last_doctor       TEXT CHECK(last_doctor IN ('PASS','FAIL','unknown')) DEFAULT 'unknown',
  last_regression   TEXT CHECK(last_regression IN ('PASS','FAIL','unknown')) DEFAULT 'unknown',
  last_commit       TEXT,
  is_active         INTEGER NOT NULL DEFAULT 0   -- bool: now - last_seen < ACTIVE_WINDOW
);

CREATE TABLE account (
  provider          TEXT NOT NULL,
  identifier        TEXT NOT NULL,
  auth_mechanism    TEXT CHECK(auth_mechanism IN ('oauth','keychain','env-ref','mcp-oauth')),
  scopes_json       TEXT NOT NULL DEFAULT '[]',
  is_active         INTEGER NOT NULL DEFAULT 0,
  bound_machine_id  TEXT REFERENCES machine(machine_id),
  user_id           TEXT REFERENCES user(user_id),
  last_verified_epoch INTEGER,
  PRIMARY KEY (provider, identifier)
);

CREATE TABLE user (
  user_id      TEXT PRIMARY KEY,              -- email canônico
  display_name TEXT,
  role         TEXT CHECK(role IN ('cto','dev','bot','daemon')) NOT NULL,
  aliases_json TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE project (
  project_slug        TEXT PRIMARY KEY,
  repo_path           TEXT NOT NULL,
  github_remote       TEXT,
  is_lovable          INTEGER NOT NULL DEFAULT 0,
  supabase_project_id TEXT,
  default_branch      TEXT,
  under_autosync      INTEGER NOT NULL DEFAULT 0,
  lovable_deny_count  INTEGER                 -- esperado 19 quando Lovable MCP presente
);

-- ApiKey: SEMPRE por-referência. SEM coluna `value`. PROPOSITAL.
CREATE TABLE api_key (
  project_slug      TEXT NOT NULL REFERENCES project(project_slug),
  var_name          TEXT NOT NULL,
  present           INTEGER NOT NULL DEFAULT 0,
  expected          INTEGER NOT NULL DEFAULT 0,   -- está no .env.example?
  risk_tier         TEXT CHECK(risk_tier IN ('critical','sensitive','low','none')) NOT NULL,
  file_mtime_epoch  INTEGER,                       -- stat do .env (proxy de rotação)
  committed         INTEGER NOT NULL DEFAULT 0,    -- .env vazou pro git? = incidente
  PRIMARY KEY (project_slug, var_name)
  -- is_orphan  = present AND NOT expected   (VIEW)
  -- is_missing = expected AND NOT present   (VIEW)
);

CREATE TABLE mcp_connection (
  scope            TEXT NOT NULL,              -- global-claude|global-cursor|project:<slug>
  server_id        TEXT NOT NULL,
  host_ide         TEXT CHECK(host_ide IN ('claude','cursor')),
  enabled          INTEGER NOT NULL DEFAULT 1,
  requires_secret  INTEGER NOT NULL DEFAULT 0,
  risk_class       TEXT CHECK(risk_class IN ('critical','high','medium','low')),
  deny_tools_count INTEGER,
  PRIMARY KEY (scope, server_id)
);

CREATE TABLE session (
  session_id      TEXT PRIMARY KEY,
  project_slug    TEXT REFERENCES project(project_slug),
  machine_id      TEXT REFERENCES machine(machine_id),
  human_turns     INTEGER NOT NULL DEFAULT 0,
  assistant_turns INTEGER NOT NULL DEFAULT 0,
  git_branch      TEXT,
  start_epoch     INTEGER,
  end_epoch       INTEGER,
  is_meaningful   INTEGER NOT NULL DEFAULT 0  -- human_turns > 5
);

CREATE TABLE productivity_event (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  ts_epoch     INTEGER NOT NULL,
  session_id   TEXT,
  project_slug TEXT REFERENCES project(project_slug),
  tool         TEXT,
  bash_verb    TEXT,
  ext          TEXT,
  ok           INTEGER NOT NULL DEFAULT 1
);  -- SEM conteúdo de arquivo/comando. metadata-only by construction.

CREATE TABLE commit_log (
  sha          TEXT NOT NULL,
  project_slug TEXT NOT NULL REFERENCES project(project_slug),
  author_email TEXT NOT NULL,
  ts_epoch     INTEGER NOT NULL,
  subject      TEXT,
  actor_class  TEXT CHECK(actor_class IN ('human','bot','autosync')) NOT NULL,
  commit_type  TEXT,    -- feat|fix|docs|chore|wip|refactor (conventional)
  PRIMARY KEY (sha, project_slug)
);

CREATE TABLE milestone (
  version         TEXT PRIMARY KEY,
  theme           TEXT,
  status          TEXT,            -- SHIPPED | PARTIAL-no-tag
  soak_satisfied  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE soak_heartbeat (
  milestone   TEXT NOT NULL REFERENCES milestone(version),
  epoch       INTEGER NOT NULL,
  iso         TEXT NOT NULL,
  machine_id  TEXT NOT NULL REFERENCES machine(machine_id),  -- normalizado
  idea_doctor TEXT,
  regression  TEXT,
  commit      TEXT,
  PRIMARY KEY (milestone, epoch, machine_id)
);

CREATE TABLE security_seal (
  repo        TEXT NOT NULL,          -- 'IdeiaOS' | '<produto>'
  epoch       INTEGER NOT NULL,
  iso         TEXT,
  commit      TEXT,
  reviewer    TEXT,
  verdict     TEXT,                   -- PASS|FAIL|BASELINE
  scope       TEXT,
  PRIMARY KEY (repo, epoch)
);

CREATE TABLE version_pin (
  component   TEXT NOT NULL,
  machine_id  TEXT NOT NULL REFERENCES machine(machine_id),
  pinned      TEXT NOT NULL,          -- de versions.lock
  installed   TEXT,                   -- collector por máquina
  drift       INTEGER NOT NULL DEFAULT 0,   -- string-eq, NUNCA semver p/ gsd
  PRIMARY KEY (component, machine_id)
);

CREATE TABLE daemon_status (
  machine_id   TEXT NOT NULL REFERENCES machine(machine_id),
  label        TEXT NOT NULL,        -- com.ideiaos.gitautosync|envsync|refresh-ai-security
  loaded       INTEGER NOT NULL DEFAULT 0,   -- launchctl: PID presente?
  last_run_epoch INTEGER,            -- do log do daemon (não do PID — pode ser '-' e saudável)
  healthy      INTEGER NOT NULL DEFAULT 1,   -- derivado: rodou dentro do intervalo esperado?
  PRIMARY KEY (machine_id, label)
);

-- snapshot federado bruto (1 por máquina por ciclo do collector)
CREATE TABLE machine_snapshot (
  machine_id  TEXT NOT NULL REFERENCES machine(machine_id),
  taken_epoch INTEGER NOT NULL,
  doctor_ok   INTEGER, doctor_warn INTEGER, doctor_fail INTEGER,
  payload_json TEXT NOT NULL,        -- snapshot completo (ver §4)
  PRIMARY KEY (machine_id, taken_epoch)
);

-- VIEWS derivadas (drift/orphan calculados, nunca persistidos como verdade)
CREATE VIEW v_api_key_orphan  AS SELECT * FROM api_key WHERE present=1 AND expected=0;
CREATE VIEW v_api_key_missing AS SELECT * FROM api_key WHERE present=0 AND expected=1;
CREATE VIEW v_stale_critical_keys AS
  SELECT * FROM api_key
  WHERE risk_tier='critical' AND present=1
    AND (strftime('%s','now') - file_mtime_epoch) > 30*86400;  -- crítica >30d sem mexer
```

---

## 4. O collector (o ÚNICO componente de coleta novo)

Tudo no §1-§3 é **leitura**. Mas três classes de sinal são **efêmeras** (não vivem em arquivo
federado) e precisam ser **materializadas** por máquina, num snapshot que o git federa:

1. **`launchctl list`** — status do daemon (PID vs `-`). Verificado: hoje os 3 estão `-` em
   repouso. Efêmero, per-máquina.
2. **`idea-doctor.sh`** — saúde do ambiente (75 OK / 0 WARN / 0 FAIL hoje). Roda e morre; só o
   SOAK persiste o `PASS/FAIL` agregado, não as 14 seções.
3. **Contas de IA / versões instaladas** — `gh auth status`, `~/.claude.json`, `aiox --version`.
   Per-máquina, não federado.

### Contrato do collector

`scripts/console-collect.sh` (proposto) — **read-only, fail-silent (hook contract)**, escreve UM
artefato JSON:

```
.planning/console/snapshots/<machine_id>.json   (commitado → federado via autosync)
```

```jsonc
{
  "schema": "ideiaos-console-snapshot/v1",
  "machine_id": "MacBook-Air-2",
  "taken_epoch": 1781988386,
  "daemons": [
    {"label":"com.ideiaos.gitautosync","loaded":false,"last_run_epoch":1781988159,"healthy":true},
    {"label":"com.ideiaos.envsync","loaded":false,"last_run_epoch":1781987000,"healthy":true},
    {"label":"com.ideiaos.refresh-ai-security","loaded":false,"last_run_epoch":1780531200,"healthy":true}
  ],
  "doctor": {"ok":75,"warn":0,"fail":0,"exit":0},
  "installed_versions": {"aiox-core":"5.2.9","gsd":"1.1.0"},
  "accounts": [
    {"provider":"anthropic","identifier":"gustavo@redeideia.com.br","mechanism":"oauth"},
    {"provider":"github","identifier":"DevIdeiaBusiness","active":true,"scopes":["gist","read:org","repo","workflow"]}
  ]
}
```

**Por que JSON commitado e não um endpoint?** Porque a federação cross-máquina **já existe e é o
git** (`autosync` empurra `.planning/`). Um snapshot JSON commitado herda a malha de graça —
zero infra nova. O console (rodando em qualquer máquina) lê `git show planning:...` de todas as
máquinas. Isso é o insight de reúso levado ao limite: **não construímos transporte; reusamos o
autosync.**

**Gate (antifragile-gates):** o collector valida seu próprio output com `gate_output
"$SNAP_PATH"` (`test -s`). Hook-contract: falha → log stderr + `exit 0` (collector roda
agendado, não pode derrubar sessão). É um **build artifact federável**, então também
`assert_nonempty` antes do commit.

**Onde corre:** novo `com.ideiaos.console-collect.plist` (LaunchAgent, intervalo ~900s alinhado
ao autosync) OU piggyback no SOAK `--record` (já roda `idea-doctor`). Piggyback é o mais barato:
o snapshot vira efeito-colateral do heartbeat que já existe. **Recomendação: piggyback** — zero
daemon novo.

---

## 5. A malha de federação (como N máquinas viram 1 visão)

```
   Máquina A (MacBook-Air-2)          Máquina B (Mac-mini)
   ├─ ledgers (SOAK/security) ──┐     ├─ ledgers ──┐
   ├─ snapshot A.json ──────────┤     ├─ snapshot B.json ──┤
   └─ git-autosync (push work) ─┼─────┴─ git-autosync ─────┤
                                ▼                          ▼
                       ┌──────────────────────────────────────┐
                       │  git (branch work + planning)         │  ← MALHA = git, já existe
                       │  .planning/soak/*.log   (commitado)   │
                       │  .planning/console/snapshots/*.json   │
                       │  .security/review-ledger.log          │
                       └──────────────────┬───────────────────┘
                                          ▼
                       ┌──────────────────────────────────────┐
                       │  console-ingest (Node/Python)         │  ← read-model builder
                       │  lê ledgers + snapshots de TODAS máqs  │
                       │  normaliza → SQLite read-model.db      │
                       └──────────────────┬───────────────────┘
                                          ▼
                       ┌──────────────────────────────────────┐
                       │  Mission Control UI (Vite+React)      │
                       └──────────────────────────────────────┘
```

**Princípios da malha:**

1. **Git É o message bus.** Não há broker, não há fila, não há webhook entre máquinas. O que uma
   máquina escreve em `.planning/` ou `.security/` aparece na outra em ≤15min (ciclo autosync).
   A latência da malha = ciclo do autosync. Aceitável para um console de CTO (não é trading).
2. **`work` carrega snapshots + ledgers; `planning` carrega memória/STATE.** Os snapshots vão
   onde os ledgers SOAK já vão. (Confirmar destino exato no rollout — SOAK hoje está em `work`.)
3. **Ingest é idempotente por chave natural.** Re-rodar o ingest sobre os mesmos ledgers produz o
   mesmo read-model (UPSERT por PK). Herdamos a **idempotência por hash** do padrão
   context-packet onde aplicável (ledgers são append-only; snapshots têm `taken_epoch` como
   dedup natural).
4. **Federação read-only.** O console **lê** a malha; **não escreve** ledger nem snapshot de
   outra máquina. Cada máquina é dona dos seus snapshots. (Excessive-Agency / `agent-authority`:
   o console não tem autoridade de gravar telemetria alheia.)
5. **Repos de produto têm security ledger LOCAL** (`.git/info/exclude`). Para o console ver o
   tier de segurança dos produtos, o **snapshot da máquina** carrega o `--tier` de cada produto
   (uma string `ok|warn|egregious`), não o ledger inteiro. Assim o frescor do produto federa via
   snapshot sem committar o ledger local.

---

## 6. Pipeline de produtividade — SINAL REAL vs VAIDADE

A parte mais opinativa. Um console de CTO que mede a coisa errada é **pior que nenhum** — induz
otimizar vaidade. Declaro a fronteira:

### Vaidade (NÃO entra em nenhuma métrica de produtividade)

| Sinal | Por que é vaidade |
|-------|-------------------|
| **total de commits raw** | inclui `wip: autosync` (70 commits do Mac mini só de daemon!), bots Lovable, docs triviais |
| **tamanho do transcript / nº de tokens** | correlaciona com verbosidade, não com valor entregue |
| **contagem bruta de sessões** | subagentes spawned (human_turns ≤2) inflam — a maioria é ruído |
| **nº de migrations** | nfideia tem 535, mas migrations geradas em lote ≠ trabalho proporcional |
| **evidence_count de instinct alto** | é frequência de telemetria comportamental, não entrega (memória `learning-channel-routing`: NÃO promover por frequência) |

### Sinal real (entra)

| Métrica | Derivação | Por que é real |
|---------|-----------|----------------|
| **human-feat-commits/dia** | `commit_log WHERE actor_class='human' AND commit_type IN ('feat','fix')` | exclui autosync+bots+docs; mede entrega com intenção |
| **sessões meaningful/dia** | `session WHERE is_meaningful` (human_turns>5) | filtra subagentes; proxy de trabalho cognitivo |
| **commit↔session co-ocorrência** | sessão meaningful no MESMO dia de feat-commit no MESMO repo | trabalho que **resultou em entrega**, não exploração estéril |
| **milestones SOAK-satisfeitos** | `milestone WHERE soak_satisfied` | a ÚNICA "entrega verificada cross-máquina" do OS — gold standard |
| **tool-success-rate por projeto** | `AVG(ok) FROM productivity_event GROUP BY project` | saúde do ambiente de trabalho (atrito) |
| **security-seal cadence** | seals/mês por repo | responsabilidade técnica ao longo do tempo |

### A regra de classificação de ator (determinística, à prova de gaming)

```
actor_class(commit) =
  'autosync'  se subject ~ /^wip: autosync/   OU  author ~ /@.*\.local$/   (daemon)
  'bot'       se author ~ /\[bot\]@/                                        (Lovable/CI)
  'human'     caso contrário
```

> Verificado: `gustavolopespaiva@Mac-mini-de-Gustavo.local` é o autosync — **cai em `autosync`
> pelo sufixo `.local`**, não em `human`. Sem essa regra, o Mac mini "produziria" 70 commits
> fantasma.

### O que falta para produtividade MULTI-usuário (gap honesto)

Hoje **toda** observação está sob `gustavo@`. A distinção `User` em
produtividade só funciona via **git author email** (que separa Gustavo de Dev Team). As
observations JSONL **não têm campo `user`** — então "produtividade por usuário" do lado
transcript é monousuário hoje. Para multi-usuário real: adicionar `user` nas observations
(mudança na coleta) OU inferir por máquina/projeto. **Modelado como gap, não inventado.**

---

## 7. Mapa Sinal → Entidade (a tabela-índice completa)

| Sinal (substrato existente) | Entidade(s) | Federação |
|------------------------------|-------------|-----------|
| `.planning/soak/*.log` | `SoakHeartbeat`, `Machine`, `Milestone` | commitado |
| `.security/review-ledger.log` (IdeiaOS) | `SecurityFreshnessSeal` | commitado |
| `--tier` de produto (via snapshot) | `SecurityFreshnessSeal(repo=produto)` | snapshot |
| `versions.lock` | `VersionPin.pinned` | commitado |
| `idea-doctor §5` (instalado) | `VersionPin.installed`, `DriftFinding` | snapshot |
| `idea-doctor` (75/0/0) | `MachineSnapshot.doctor` | snapshot |
| git log `%ae/%aI/%s` | `Commit`, `User`, `Project` | commitado (repo) |
| commit WIP `(host)` | `Machine.last_seen`, `aliases` | commitado |
| `git-autosync-repos.txt` | `Project.under_autosync` | local→snapshot |
| autosync log | `DaemonStatus(gitautosync).last_run` | local→snapshot |
| observations JSONL | `ProductivityEvent` | local→snapshot/agg |
| transcripts JSONL | `Session` | local→snapshot/agg |
| instincts frontmatter | (agregado: maturidade do agente) | local→snapshot/agg |
| `launchctl list` | `DaemonStatus.loaded` | snapshot |
| `.env` nomes de var | `ApiKey` (METADATA) | local→snapshot |
| `.env.example` | `ApiKey.expected`, risk-tier | commitado (repo) |
| `~/.claude.json` oauth | `Account(anthropic)` | snapshot |
| `gh auth status` | `Account(github)` | snapshot |
| `~/.cursor/mcp.json` | `McpConnection`, `Account(cursor/lovable)` | snapshot |
| `.claude/settings.json` disabledMcp | `McpConnection.enabled`, `Project.lovable_deny_count` | commitado (repo) |
| `supabase/config.toml` | `Project.supabase_project_id` | commitado (repo) |
| `.planning/ROADMAP.md` | `Milestone` | commitado |

---

## 8. Decisões opinativas (e o que rejeitei)

1. **SQLite, não Postgres** — local-first, cache descartável, joins relacionais. (Rejeitado JSON
   flat: as consultas são JOINs.)
2. **Git como malha, não um broker** — reusa autosync; latência ≤15min aceitável. (Rejeitado
   webhook/fila: infra nova sem ganho — `enforce-simplicity`.)
3. **Snapshot JSON commitado por máquina** — único componente de coleta novo; piggyback no SOAK
   `--record`. (Rejeitado daemon dedicado: daemon a mais sem necessidade.)
4. **`ApiKey` sem coluna `value`, by construction** — não é política, é o schema impedindo o erro.
   `credential-isolation` materializada.
5. **`User` ≠ `Account`, junção curada** — não há sinal automático ligando contas; inventar a
   junção seria `No Invention` violado.
6. **Classificação de ator determinística** (`.local`→autosync) — sem isso, 70 commits-fantasma
   do Mac mini poluiriam toda métrica.
7. **Dedup de `Machine` por alias-map curado** — `192`↔`Mac-mini` é real no disco; sem dedup o
   gate SOAK `≥2 máquinas` é furado.
8. **`gsd` comparado por string-equality, nunca semver** — `1.1.0`(redux) > `1.36.0`(pré). O
   read-model herdaria o trap dos 3 reverts se comparasse numérico.

---

## 9. Gaps honestos (não inventei solução)

- **Produtividade multi-usuário** do lado transcript é monousuário (observations sem campo
  `user`). Requer mudança na coleta — fora do escopo deste modelo.
- **Mac mini não é inspecionável ao vivo** desta máquina; só via ledger commitado + snapshot
  federado. O `is_active` dele depende do autosync ter empurrado.
- **`idea-doctor` não emite JSON** — o collector parseia ANSI por seção (`━━━`). Candidato a
  `--json` flag (melhoria no `idea-doctor`, não neste modelo).
- **Vercel/Railway/Stripe** não têm config local consistente (deploy via Lovable). Status real só
  via API (requer token via env, nunca contexto) — o console mostra só presença da var-ref.
- **`SUPABASE_SERVICE_ROLE_KEY` validade** não é verificável sem usar a chave — o console mostra
  presença+mtime+risk, jamais testa a chave (testar = transitar o segredo, proibido).

---

## 10. Próximo passo (handoff p/ camada de execução)

1. Implementar `console-ingest` (Node ou Python) que lê ledgers + snapshots → `read-model.db`
   (UPSERT idempotente). Gate `assert_nonempty` no `.db` gerado.
2. Implementar `scripts/console-collect.sh` (piggyback no SOAK `--record`) → snapshot JSON
   federável. Gate `gate_output`, hook-contract `exit 0`.
3. Curar `machine-aliases.json` e `user-aliases.json` (dedup).
4. Expor o read-model à UI (Vite+React do stack canônico) — fora deste doc (camada UI).

> **Verificação (operating-discipline §6):** este modelo foi ancorado lendo os arquivos reais no
> disco (SOAK, security ledger, versions.lock, autosync repos, observations, instincts, git
> authors, launchctl, claude.json). Não é o brief reescrito — é o substrato confirmado, com 4
> gotchas (`192`-alias, `gsd`-semver, daemon-`-`-normal, ledger-local-de-produto) que o brief não
> destacava e que mudam o schema.
