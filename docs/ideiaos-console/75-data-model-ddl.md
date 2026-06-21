# 75 — Modelo de Dados COMPLETO (DDL do read-model SQLite)

**Produto:** IdeiaOS Cockpit (console web de CTO, local-first)
**Camada:** Data / Platform Engineering — **DDL executável + prova-de-isolamento**
**Status:** PROPOSTO (contrato de schema; zero código de runtime)
**Autor:** Data/Platform Engineer (subagente de planejamento)
**Data:** 2026-06-21
**Depende de / endurece:** `40-data-model-telemetry-mesh.md` (modelo conceitual), `00-BLUEPRINT.md`
(decisões `[CORRIGIDO]`), `73-substrate-validation-mac-mini.md` (**DADOS REAIS**), `specs/cockpit/spec.md`

> **Precedência aplicada (quando docs divergem):** o `00-BLUEPRINT.md` (FINAL, com `[CORRIGIDO]`)
> e o `73` (validação na máquina real) vencem o `40` (DRAFT conceitual). Três correções herdadas:
> (1) **risk-tier de 4 níveis** crítico/alto/sensível/baixo — `VERCEL_TOKEN=alto`, não "sensitive"
> (00 §9 deprecou o 40); (2) **ref de federação = `cockpit`** (órfão, git-plumbing) — não
> `.planning/console/` (00 §C7); (3) **alias `192 → MacBook-Air-2`** — não Mac-mini (73 §3).

---

## 0. As duas leis que o schema MATERIALIZA (não recomenda)

1. **Zero-Leak por construção.** Nenhuma tabela tem coluna `value`/`secret`/`token`. A ausência
   é estrutural — o pipeline de derivação descarta o RHS do `=` (`sed 's/=.*//'`) **antes** de
   qualquer escrita. Não há caminho do schema ao valor (prova formal em §3). Isto é
   `credential-isolation` + o Requisito "Isolamento absoluto" da `specs/cockpit/spec.md`.
2. **Read-model é CACHE DESCARTÁVEL.** Fonte-de-verdade = arquivos no disco/ref (ledgers
   append-only, exit-code). `rm read-model.db && rebuild` reconstrói 100%. Nada nascido só no DB
   é autoritativo. Toda derivação é **string-equality** onde o substrato é string (nunca semver
   ingênuo — `gsd 1.1.0`redux > `1.36.0`; memória `version-reset-migration-semver-trap`).

**Localização:** `~/.ideiaos/console/read-model.db` (SQLite single-file, fora de qualquer repo).

---

## 1. DDL completo — 12 tabelas (+ índices + views derivadas)

As 11 entidades do brief + `DenyListContainment` (o ledger estruturado novo da v14.2,
`epoch|iso|produto|deny_count|total|commit`). Cada `CREATE TABLE` declara colunas, tipos e chave.

```sql
-- =====================================================================
-- read-model.db · IdeiaOS Cockpit · CACHE DESCARTÁVEL
-- Fonte-de-verdade = ledgers/refs no disco. NENHUMA coluna de valor de segredo.
-- Convenção: epoch = INTEGER unix-seconds; iso = TEXT ISO-8601; bool = INTEGER 0/1.
-- =====================================================================

PRAGMA foreign_keys = ON;

-- 1) Machine — máquina física da frota. PK = hostname normalizado (resolve aliases).
CREATE TABLE machine (
  machine_id        TEXT PRIMARY KEY,                 -- hostname normalizado OU sha256(hw-uuid)
  display_name      TEXT,                             -- curado ("Mac mini de Gustavo")
  aliases_json      TEXT NOT NULL DEFAULT '[]',       -- ["192","Mac-mini-de-Gustavo.local"] — DEDUP
  os_version        TEXT,                             -- "26.6" (collector; robustez p/ assimetria)
  agentd_version    TEXT,                             -- divergência = drift âmbar na Frota
  first_seen_epoch  INTEGER,                          -- min(epoch) SOAK ∪ commits WIP
  last_seen_epoch   INTEGER,                          -- max(epoch) SOAK ∪ último WIP "(host)"
  last_doctor       TEXT CHECK(last_doctor    IN ('PASS','FAIL','unknown')) DEFAULT 'unknown',
  last_regression   TEXT CHECK(last_regression IN ('PASS','FAIL','unknown')) DEFAULT 'unknown',
  last_commit       TEXT,                             -- $6 do último heartbeat SOAK
  is_active         INTEGER NOT NULL DEFAULT 0        -- now - last_seen_epoch < ACTIVE_WINDOW (24h)
);

-- 2) Project — repo/produto gerenciado. PK = slug (= nome do dir em ~/dev).
--    CLASSE produto/teste/tool é DESCOBERTA (não hardcodada) — ver §5 e enum project_class.
CREATE TABLE project (
  project_slug        TEXT PRIMARY KEY,               -- "nfideia","Jarvis","ideia-chat","cfoai-grupori"
  repo_path           TEXT NOT NULL,                  -- ~/dev/<slug>
  project_class       TEXT NOT NULL                   -- DESCOBERTO, não fixo (73 §4)
                        CHECK(project_class IN ('product','test','tool','unknown')) DEFAULT 'unknown',
  github_remote       TEXT,                           -- git remote -v
  is_lovable          INTEGER NOT NULL DEFAULT 0,     -- bot gpt-engineer-app[bot] + MCP enabled
  supabase_project_id TEXT,                           -- público (grep config.toml). nfideia=pdljyfyy...
  default_branch      TEXT,                           -- git symbolic-ref
  under_autosync      INTEGER NOT NULL DEFAULT 0,     -- presença em git-autosync-repos.txt
  health_overall      INTEGER,                        -- 0-100, NULLABLE (NULL = insuficiente p/ nota)
  health_doctor_state TEXT                            -- 'ok'|'warn'|'fail'|'n/a' (Lovable = n/a HONESTO)
                        CHECK(health_doctor_state IN ('ok','warn','fail','n/a')) DEFAULT 'n/a'
);

-- 3) User — ator HUMANO distinto. PK = email canônico. role separa humano de daemon/bot.
CREATE TABLE app_user (                               -- "user" é reservado em SQL → app_user
  user_id      TEXT PRIMARY KEY,                      -- email canônico
  display_name TEXT,
  role         TEXT NOT NULL                          -- ver classificação determinística §5
                 CHECK(role IN ('cto','dev','bot','daemon')),
  aliases_json TEXT NOT NULL DEFAULT '[]'             -- git emails do mesmo humano
);

-- 4) ApiKey — chave POR REFERÊNCIA. PK = (project_slug, var_name). **SEM coluna value.**
--    Coração da rule credential-isolation. Prova de isolamento em §3.
CREATE TABLE api_key (
  project_slug      TEXT NOT NULL REFERENCES project(project_slug),
  var_name          TEXT NOT NULL,                    -- SÓ o nome (sed 's/=.*//' descarta o valor)
  present           INTEGER NOT NULL DEFAULT 0,       -- a var existe no .env?
  expected          INTEGER NOT NULL DEFAULT 0,       -- está no .env.example? (contrato)
  risk_tier         TEXT NOT NULL                     -- catálogo ÚNICO do 00 §9 (4 níveis)
                      CHECK(risk_tier IN ('critical','high','sensitive','low','none')),
  file_mtime_epoch  INTEGER,                          -- stat -f %m .env (proxy de última rotação)
  committed         INTEGER NOT NULL DEFAULT 0,       -- .env vazou pro git-tracking? = incidente
  in_icloud         INTEGER NOT NULL DEFAULT 0,       -- .env.local trafega por iCloud? (achado Atalaia)
  PRIMARY KEY (project_slug, var_name)
  -- NÃO HÁ coluna value/secret/masked. is_orphan/is_missing são VIEWS (abaixo).
);

-- 5) McpConnection — ligação MCP (Claude/Cursor/Lovable). PK = (scope, server_id).
CREATE TABLE mcp_connection (
  scope            TEXT NOT NULL,                      -- 'global-claude'|'global-cursor'|'project:<slug>'
  server_id        TEXT NOT NULL,                      -- 'chrome-devtools'|'context7'|'lovable'|'resend'
  host_ide         TEXT CHECK(host_ide IN ('claude','cursor')),
  enabled          INTEGER NOT NULL DEFAULT 1,         -- ausência em disabledMcpServers
  requires_secret  INTEGER NOT NULL DEFAULT 0,         -- refere *_API_KEY no config (ex.: resend)
  risk_class       TEXT CHECK(risk_class IN ('critical','high','medium','low')),
  deny_tools_count INTEGER,                            -- Lovable: nº tools mutantes em deny (esperado 19)
  PRIMARY KEY (scope, server_id)
);

-- 6) ProductivityEvent — sinal de trabalho FINO (observations JSONL, metadata-only).
CREATE TABLE productivity_event (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  ts_epoch     INTEGER NOT NULL,
  session_id   TEXT,
  project_slug TEXT REFERENCES project(project_slug),
  tool         TEXT,                                   -- Bash|Read|Edit|Write
  bash_verb    TEXT,                                   -- 1º token (proxy de tipo de trabalho)
  ext          TEXT,                                   -- .ts|.tsx|.sql|.md
  ok           INTEGER NOT NULL DEFAULT 1              -- taxa de sucesso (atrito do ambiente)
);  -- SEM conteúdo de arquivo/prompt/comando. metadata-only by construction.

-- 6b) Session — agregado de transcripts (filtra subagente-ruído de sinal real).
CREATE TABLE session (
  session_id      TEXT PRIMARY KEY,
  project_slug    TEXT REFERENCES project(project_slug),
  machine_id      TEXT REFERENCES machine(machine_id),
  human_turns     INTEGER NOT NULL DEFAULT 0,
  assistant_turns INTEGER NOT NULL DEFAULT 0,
  git_branch      TEXT,
  start_epoch     INTEGER,
  end_epoch       INTEGER,
  is_meaningful   INTEGER NOT NULL DEFAULT 0           -- human_turns > 5 (subagentes têm <=2)
);

-- 7) Commit — projeção de git log. PK = (sha, project_slug). actor_class separa sinal de vaidade.
CREATE TABLE commit_log (
  sha          TEXT NOT NULL,
  project_slug TEXT NOT NULL REFERENCES project(project_slug),
  author_email TEXT NOT NULL,
  ts_epoch     INTEGER NOT NULL,
  subject      TEXT,
  actor_class  TEXT NOT NULL                           -- DETERMINÍSTICO §5
                 CHECK(actor_class IN ('human','bot','autosync')),
  commit_type  TEXT,                                   -- feat|fix|docs|chore|wip|refactor
  PRIMARY KEY (sha, project_slug)
);

-- 8) SoakHeartbeat — 1 linha do SOAK ledger (epoch|iso|host|doctor|regression|commit).
CREATE TABLE soak_heartbeat (
  milestone   TEXT NOT NULL,                           -- "v11"|"v12"|"v13" (nome do arquivo)
  epoch       INTEGER NOT NULL,                        -- $1
  iso         TEXT NOT NULL,                           -- $2
  machine_id  TEXT NOT NULL REFERENCES machine(machine_id),  -- $3 NORMALIZADO (192->MacBook-Air-2)
  idea_doctor TEXT,                                    -- $4 ("idea_doctor=PASS" → PASS)
  regression  TEXT,                                    -- $5
  commit      TEXT,                                    -- $6
  PRIMARY KEY (milestone, epoch, machine_id)
);

-- 9) SecurityFreshnessSeal — 1 linha do security ledger (epoch|iso|commit|revisor|veredito|escopo).
--    repo='IdeiaOS' federa via ref; repo=<produto> chega como string --tier no snapshot.
CREATE TABLE security_seal (
  repo        TEXT NOT NULL,                           -- 'IdeiaOS' | '<produto>'
  epoch       INTEGER NOT NULL,                        -- $1
  iso         TEXT,                                    -- $2
  commit      TEXT,                                    -- $3
  reviewer    TEXT,                                    -- $4 (bootstrap|@security-reviewer)
  verdict     TEXT,                                    -- $5 (PASS|FAIL|BASELINE)
  scope       TEXT,                                    -- $6
  tier        TEXT CHECK(tier IN ('ok','warn','egregious','unbootstrapped')),  -- derivado --tier
  PRIMARY KEY (repo, epoch)
);

-- 10) VersionPin — pin de frota (versions.lock) × instalado (collector por máquina).
CREATE TABLE version_pin (
  component   TEXT NOT NULL,                           -- 'aiox-core'|'gsd'|'design-suite-ref'
  machine_id  TEXT NOT NULL REFERENCES machine(machine_id),
  pinned      TEXT NOT NULL,                           -- valor em versions.lock
  installed   TEXT,                                    -- collector
  drift       INTEGER NOT NULL DEFAULT 0,              -- STRING-EQUALITY pinned!=installed; NUNCA semver
  PRIMARY KEY (component, machine_id)
);

-- 11) DriftFinding — achado de divergência (frota/versão/deny/tier) p/ a Atalaia.
CREATE TABLE drift_finding (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  detected_epoch INTEGER NOT NULL,
  kind          TEXT NOT NULL                          -- categoria do achado
                  CHECK(kind IN ('version_pin','deny_list','autosync_stalled',
                                 'security_stale','env_orphan','env_committed',
                                 'env_in_icloud','soak_ready_tag')),
  subject_ref   TEXT NOT NULL,                         -- a quem o achado se refere (slug|machine|component)
  severity      TEXT NOT NULL CHECK(severity IN ('info','warn','critical')),
  detail        TEXT,                                  -- texto humano (NUNCA valor de segredo)
  resolved_epoch INTEGER                               -- NULL = aberto
);

-- 12) DenyListContainment — LEDGER ESTRUTURADO novo da v14.2. 1 linha por amostra do watch.
--     Formato espelha SOAK/security: epoch|iso|produto|deny_count|total|commit.
--     Pré-requisito do Time-Travel (v14.3): reconstruir 5/5->2/5->5/5 deterministicamente.
CREATE TABLE deny_list_containment (
  epoch        INTEGER NOT NULL,                        -- $1
  iso          TEXT NOT NULL,                           -- $2
  produto      TEXT NOT NULL REFERENCES project(project_slug),  -- $3 (coluna "produto" ~ "host" do SOAK)
  deny_count   INTEGER NOT NULL,                        -- $4 (quantas das mutantes estão em deny)
  total        INTEGER NOT NULL,                        -- $5 (esperado 19)
  commit       TEXT,                                    -- $6
  PRIMARY KEY (epoch, produto)                          -- append-only; dedup natural por amostra
);

-- ---------------------------------------------------------------------
-- ÍNDICES (consultas quentes do console)
-- ---------------------------------------------------------------------
CREATE INDEX ix_commit_actor   ON commit_log(project_slug, actor_class, commit_type, ts_epoch);
CREATE INDEX ix_event_project  ON productivity_event(project_slug, ts_epoch);
CREATE INDEX ix_soak_mstone    ON soak_heartbeat(milestone, machine_id);
CREATE INDEX ix_apikey_risk    ON api_key(risk_tier, present);
CREATE INDEX ix_drift_open     ON drift_finding(kind, resolved_epoch);
CREATE INDEX ix_deny_produto   ON deny_list_containment(produto, epoch);

-- ---------------------------------------------------------------------
-- VIEWS derivadas (drift/orphan/stale CALCULADOS, nunca persistidos como verdade)
-- ---------------------------------------------------------------------
CREATE VIEW v_api_key_orphan  AS SELECT * FROM api_key WHERE present=1 AND expected=0;
CREATE VIEW v_api_key_missing AS SELECT * FROM api_key WHERE present=0 AND expected=1;

-- chaves críticas/altas sem rotação além do stale-warn do catálogo (00 §9: crítico 60d, alto 90d)
CREATE VIEW v_stale_sensitive_keys AS
  SELECT *, (strftime('%s','now') - file_mtime_epoch)/86400 AS age_days FROM api_key
  WHERE present=1 AND (
        (risk_tier='critical'  AND (strftime('%s','now') - file_mtime_epoch) > 60*86400)
     OR (risk_tier IN ('high','sensitive') AND (strftime('%s','now') - file_mtime_epoch) > 90*86400));

-- regressão de contenção: a amostra MAIS RECENTE por produto abaixo do total esperado
CREATE VIEW v_deny_regression AS
  SELECT d.* FROM deny_list_containment d
  JOIN (SELECT produto, MAX(epoch) mx FROM deny_list_containment GROUP BY produto) last
    ON d.produto=last.produto AND d.epoch=last.mx
  WHERE d.deny_count < d.total;

-- span do SOAK por milestone (delta dos epochs GRAVADOS, não wall-clock — memória soak-span-is-record-delta)
CREATE VIEW v_soak_status AS
  SELECT milestone,
         COUNT(DISTINCT machine_id) AS machines_covered,
         (MAX(epoch)-MIN(epoch))/86400.0 AS span_days,
         (COUNT(DISTINCT machine_id) >= 2 AND (MAX(epoch)-MIN(epoch)) >= 86400) AS soak_satisfied
  FROM soak_heartbeat GROUP BY milestone;
```

---

## 2. Matriz Fonte → Entidade → Tela

Cada tabela: de qual arquivo/comando REAL deriva (fontes verificadas no doc 73), o modo de
federação, e em qual tela do Cockpit aparece (pilares do 00 §3).

| Tabela | Fonte (arquivo/comando — verificado no 73) | Federação | Tela / Pilar |
|--------|--------------------------------------------|-----------|--------------|
| `machine` | SOAK `.planning/soak/*.log` ($3 host); commits WIP `(host)`; `machine_id=sha256(hw-uuid)` (73 §1, amostra `9d7fbccdbb1b`); `launchctl` para daemons | commitado + snapshot | **Frota** (Overview + tela Frota) |
| `project` | `~/dev/*` com `.git` — **descoberta** dos 7 reais (73 §4); `git remote`; `supabase/config.toml`; bot Lovable no `git log` | local→snapshot | **Constelação** + Overview |
| `app_user` | `git log --format=%ae` (73: 198/200 = `gustavo@`); `~/.claude.json` oauth; curadoria de aliases | commitado (repo) | **Pulso** (atribuição), **Sinapse** |
| `api_key` | `grep '^[A-Z_]*=' .env \| sed 's/=.*//'` (NOME); `.env.example` (`expected`); `stat` (`mtime`); `git status` (`committed`); §5 do 73 = fixture real | local→snapshot | **Cofre-Espelho** + Atalaia |
| `mcp_connection` | `~/.claude.json`, `~/.cursor/mcp.json` (73 §6: claude=2, cursor=4 c/ `resend`), `.claude/settings.json` deny-list | commitado (repo) + snapshot | **Sinapse** |
| `productivity_event` | `~/.ideiaos/observations/<proj>/observations.jsonl` (73 §6: ~35 escopos) | local→snapshot/agg | **Pulso** |
| `session` | transcripts `~/.claude/projects/*.jsonl` (73 §4: Jarvis 469, ideiapartner 361, IdeiaOS 353, cfoai 4) | local→snapshot/agg | **Pulso** |
| `commit_log` | `git log --format='%H\|%ae\|%aI\|%s'` por repo; classificação de ator §5 | commitado (repo) | **Pulso** + **Constelação** |
| `soak_heartbeat` | `.planning/soak/*.log` (formato pipe verificado: `1781902304\|...\|MacBook-Air-2\|idea_doctor=PASS\|regression=PASS\|4011186`) | **commitado** → cross-máquina | **Releases/SOAK** (Overview) |
| `security_seal` | IdeiaOS: `.security/review-ledger.log` (verificado: 1 entrada baseline `a2f1a68` 2026-06-20); produto: string `--tier` no snapshot | IdeiaOS commitado · produto via snapshot | **Segurança** (Overview) + Atalaia |
| `version_pin` | `versions.lock` (`chave=valor`) × `idea-doctor §5` instalado | commitado (pin) + snapshot (instalado) | **Frota** (drift âmbar) |
| `drift_finding` | derivado: diff `versions.lock`, `v_deny_regression`, autosync log parado, tier→stale, `v_api_key_orphan`, iCloud | derivado no ingest | **Atalaia** (transversal) |
| `deny_list_containment` | **NOVO (v14.2):** `lovable-mcp.sh` deny-watch grava `epoch\|iso\|produto\|deny_count\|total\|commit`; hoje o estado vive só em prosa de commit + memória (00 §10) | commitado (novo ledger) | **Sinapse** (watch) + **Time-Travel** (v14.3) |

---

## 3. ApiKey — PROVA de isolamento (não há caminho do schema até o value)

**Afirmação:** é **estruturalmente impossível** o valor de um segredo alcançar o read-model,
qualquer superfície da UI, ou o snapshot federado. Prova em quatro elos, cada um verificável.

**Elo 1 — o schema não tem onde guardar.** A tabela `api_key` (§1) tem exatamente 8 colunas:
`project_slug, var_name, present, expected, risk_tier, file_mtime_epoch, committed, in_icloud`.
Nenhuma é `value`, `secret`, `token`, `masked` ou `hash_do_valor`. Um `INSERT` com o valor não
tem coluna-destino → erro de schema. A ausência é o gate, não uma política.

**Elo 2 — o pipeline de derivação descarta o RHS ANTES de qualquer escrita.** A única leitura do
`.env` é:
```
grep '^[A-Z_]*=' .env | sed 's/=.*//'
```
`sed 's/=.*//'` apaga tudo a partir do primeiro `=`. O valor **nunca entra na memória do
processo coletor** como dado roteável — só o nome (LHS) sobrevive ao pipe. `file_mtime_epoch` vem
de `stat` (metadado do arquivo, não do conteúdo); `committed` de `git status` (estado do índice);
`expected` de comparar nomes do `.env.example`. **Nenhuma derivação abre o RHS.**

**Elo 3 — derivações de risco/idade são sobre METADADOS, não sobre o valor.** `risk_tier` é
função-tabela **do nome** (`SUPABASE_SERVICE_ROLE_KEY → critical`), nunca do conteúdo. "Idade"
é `now - file_mtime_epoch` (relógio do FS). O Cockpit responde "a `SUPABASE_SERVICE_ROLE_KEY`
existe, é crítica, mtime 12d" sem jamais ler um caractere do segredo — exatamente o cenário
"render de uma credencial conhecida" da `spec.md` (mostra nome/presença/idade/risco, **nunca o
valor, nem mascarado a partir do real**).

**Elo 4 — federação não carrega o valor.** O snapshot JSON escrito no ref `cockpit` carrega
`{var_name, present, expected, risk_tier, mtime, committed}` — os mesmos campos sem-valor. O
`git add -A` do autosync nunca vê o `.env` (gitignored — 73 §5.1) e o snapshot vai por
git-plumbing fora do working tree. **O valor não está no DB, não está no snapshot, não está no
ref, não está na rede.**

**Invariante de release (gate Zero-Leak = 0):** um teste varre `read-model.db`, o snapshot e o
DOM/estado/rede por padrões de segredo (`gho_`, `sk-`, `eyJ`, `service_role` value-shaped). Uma
única ocorrência reprova o build (P0, bloqueia merge) — Requisito "invariante de release" da
`spec.md`. **Regra de bolso:** se o valor pode aparecer num screenshot, o design está errado.

> **`SUPABASE_SERVICE_ROLE_KEY`** (presente em cfoai/ideiapartner/lapidai — 73 §5) é o ativo de
> maior risco (bypassa RLS). O Cockpit mostra `present:true, risk:critical, mtime:Xd` e **nada
> mais** — e **não oferece botão de rotação** na v14.1 (00 §C8: mapa metadata-only, sem mutação).

---

## 4. Health-score honesto por produto (sem inventar nota)

**Problema real (73 §4 + 00 §3):** `idea-doctor` **não roda igual** nos produtos Lovable
(cfoai/nfideia/ideiapartner são Lovable-em-main). Um score que tratasse `idea-doctor` ausente
como 0 puniria o produto por uma medição que não se aplica; tratá-lo como 100 fabricaria
aprovação. Ambos mentem. O Requisito "Saúde por produto com sub-sinal honesto" da `spec.md` exige
rotular `n/a` e **não contar** o sub-sinal ausente nem como falha nem como sucesso.

**Modelo:** o health-score é **média ponderada só dos sub-sinais DISPONÍVEIS** — `n/a` sai do
numerador E do denominador (não é zero, é ausência).

| Sub-sinal | Peso | Fonte | Disponível quando |
|-----------|------|-------|-------------------|
| `idea_doctor` | 3 | `idea-doctor §por-produto` (ok/warn/fail) | repo roda idea-doctor (**`n/a` nos Lovable**) |
| `security_tier` | 3 | `security_seal.tier` (ok=100/warn=50/egregious=0) | sempre (ledger local ou `--tier` no snapshot) |
| `deny_containment` | 2 | `deny_list_containment` última amostra: `deny_count/total*100` | produto tem Lovable MCP |
| `tool_success` | 1 | `AVG(productivity_event.ok)*100` por projeto | há observations do projeto |
| `autosync_fresh` | 1 | autosync rodou < ciclo? (100/0) | projeto sob autosync |

**Fórmula de agregação (ignora ausentes):**
```
sub-score(s) ∈ [0,100]  para cada sub-sinal s DISPONÍVEL (state != 'n/a')
health_overall = round( Σ(peso_s · score_s) / Σ(peso_s) )   apenas sobre s disponíveis
se Σ(peso dos disponíveis) == 0  →  health_overall = NULL  (UI: "dados insuficientes", não nota)
```
`project.health_doctor_state` guarda `'n/a'` explicitamente quando o idea-doctor não se aplica —
o card mostra o badge `idea-doctor n/a` ao lado da nota, então o operador vê **por que** o peso 3
não entrou. A nota nunca é inflada nem deflada por uma medição inaplicável; `NULL` é a saída
honesta quando não há sub-sinal suficiente (a coluna é `NULLABLE` de propósito).

**Exemplo (cfoai-grupori, Lovable):** `idea_doctor=n/a` (sai). Disponíveis: `security_tier=ok(100,
peso3)`, `deny_containment=5/5→100(peso2)`, `tool_success=…`, `autosync_fresh=100(peso1)`.
`health = (3·100 + 2·100 + 1·… + 1·100)/(3+2+1+1)` — **nunca** dividido por um peso que não
mediu.

---

## 5. Alias-map + classificação determinística de ator (parte do ingest)

Dois mapas curados + uma função determinística — todos rodam no `console-ingest`, antes de
qualquer métrica. São a diferença entre contar 2 máquinas e 3, entre sinal humano e 70 commits
fantasma.

### 5.1 `machine-aliases.json` (dedup de `Machine`)
Verificado no 73 §3: o `192` aparece ao lado de `Mac-mini-de-Gustavo` no `v12` ledger, logo o
`192` é a **MacBook-Air-2** (hostname caiu para fragmento de IP), **não** a Mac-mini. Mapa curado:
```json
{
  "MacBook-Air-2": ["192", "MacBook-Air-2.local"],
  "Mac-mini-de-Gustavo": ["Mac-mini-de-Gustavo.local", "9d7fbccdbb1b"]
}
```
Ingest normaliza todo `host`/`machine_id` por este mapa **antes** do `UPSERT`. Sem isto, o gate
SOAK `≥2 máquinas` é furado e a Frota conta máquina inexistente.

### 5.2 `user-aliases.json` (dedup de `User`, role)
Verificado no 73 §4 / 40 §2.4 (200 commits IdeiaOS): `gustavo@redeideia.com.br → cto`;
`desenvolvimento@ideiabusiness.com.br → dev`; `…gpt-engineer-app[bot]@… → bot`;
`gustavolopespaiva@Mac-mini-de-Gustavo.local → daemon` (autosync — **filtrar de toda métrica
humana**).

### 5.3 Classificação determinística de ator (commit → actor_class)
Regra do 00 §9 / 40 §6 — pura, à prova de gaming, sem NL:
```
actor_class(commit) =
  'autosync'  se subject ~ /^wip: autosync/   OU  author_email ~ /@.*\.local$/
  'bot'       se author_email ~ /\[bot\]@/
  'human'     caso contrário
```
> O `gustavolopespaiva@Mac-mini-de-Gustavo.local` cai em `autosync` pelo sufixo `.local` — sem
> essa regra, os ~70 commits-fantasma do daemon poluiriam toda métrica de entrega (00 §10).

### 5.4 Classificação determinística de PROJETO (descoberta, não hardcode)
O 73 §4 manda **descobrir e classificar**, nunca assumir 5. Heurística do ingest sobre `~/dev/*`
com `.git`:
```
project_class(dir) =
  'tool'     se slug == 'IdeiaOS'  (o próprio OS)  OU  é dir de framework/CLI sem deploy
  'test'     se slug ~ /test|teste|-test$/ (ex.: ollama-m3-test, teste-mega-cérebro)
             OU  transcripts < limiar de atividade E sem remote de produto
  'product'  se tem supabase config OU remote de produto OU bot Lovable  (cfoai, nfideia, …)
  'unknown'  caso contrário → revisão curada (não vira métrica até classificado)
```
Os 7 reais do 73 §4: `IdeiaOS`(tool), `Jarvis`/`ideiapartner`/`cfoai-grupori`/`lapidai`/`nfideia`/
`ideia-chat`(product), `ollama-m3-test`/`teste-mega-cérebro`(test). **Jarvis (469 sessões) é
1ª-classe** — não estava na lista do plano, entra pela descoberta.

---

## 6. Decisões de modelagem (e o que rejeitei)

1. **`api_key` sem coluna `value`, by construction** — não é regra escrita, é o schema impedindo o
   `INSERT`. (Rejeitado: coluna `masked` — masking parte do valor real, que `spec.md` proíbe.)
2. **Health-score = média só dos disponíveis; `NULL` quando insuficiente** — `n/a` sai de
   numerador e denominador. (Rejeitado: `n/a`=0 pune; `n/a`=100 fabrica.)
3. **`project_class` DESCOBERTO** — `~/dev/*` com `.git` + heurística; nunca lista fixa de 5.
   (Rejeitado: hardcode — o 73 provou que Jarvis e ideia-chat ficariam de fora.)
4. **`deny_list_containment` como ledger pipe espelhando SOAK** — `epoch|iso|produto|deny_count|
   total|commit`; uma linha por amostra (grava, não só sinaliza). É o que tira o Time-Travel do
   vaporware (00 §10). (Rejeitado: reconstruir de prosa de commit — não é exit-code, viola "lei =
   binário".)
5. **`risk_tier` de 4 níveis do 00 §9** (`critical/high/sensitive/low`) — `VERCEL_TOKEN=high`.
   (Rejeitado: os 3 níveis do 40, que o BLUEPRINT deprecou em `[CORRIGIDO C9]`.)
6. **Alias/ator/projeto resolvidos no INGEST, não na UI** — métrica nasce já limpa; a UI não
   reclassifica. (Eixo `agent-authority`/Excessive-Agency: o console não reescreve telemetria.)
7. **`drift` e `soak span` por string-equality / delta-de-epochs-gravados** — nunca semver
   ingênuo (`gsd 1.1.0`redux), nunca wall-clock (memórias verificadas).

---

## 7. Gaps honestos (não inventei solução)

- **Produtividade multi-usuário** é monousuário (observations sem campo `user`; 73 §6 — tudo
  `gustavo@`). `Session`→`User` só separa via git author email. Multi-usuário real = mudança na
  coleta, fora deste schema. Personas P1/P2 = vaporware até `desenvolvimento@` ter volume (00 §3).
- **`deny_list_containment` nasce vazio** — o ledger é novo (v14.2); o histórico `5/5→2/5→5/5`
  vive hoje só em prosa de commit + memória. O Time-Travel reconstrói a partir do momento em que
  o watch começar a gravar; o passado pré-ledger é só narrativo (declarado, não fabricado).
- **`SERVICE_ROLE` validade** não é verificável sem usar a chave (= transitar o segredo,
  proibido). O Cockpit mostra presença+mtime+risco, jamais testa.
- **Produto Lovable `idea-doctor: n/a`** é ausência real de sub-sinal, não bug — modelado em §4.

> **Verificação (operating-discipline §6):** schema ancorado lendo os arquivos reais — formato
> SOAK confirmado (`1781902304|...|MacBook-Air-2|idea_doctor=PASS|...`), security ledger (1
> baseline `a2f1a68`), `deny_list_containment` confirmado AUSENTE no disco (é artefato novo da
> v14.2). Correções de precedência (risk-tier 4 níveis, ref `cockpit`, alias `192→MacBook-Air-2`)
> aplicadas do 00/73 sobre o 40. Não é o 40 reescrito — é o DDL executável endurecido pelos dados
> reais do 73, com as 12 tabelas pedidas e a prova-de-isolamento formal da `ApiKey`.
