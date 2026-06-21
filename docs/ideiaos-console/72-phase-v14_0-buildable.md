# 72 — Fase v14.0 (Substrato + Espinha) · NÍVEL EXECUTÁVEL

> **Documento 72 · Staff-Engineer build-out da v14.0 · pronto para `/gsd-plan-phase`**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Consome:** `00-BLUEPRINT.md` §4, `02-PHASE-1-SPEC.md`, `40-data-model-telemetry-mesh.md`, `specs/cockpit/spec.md`, `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md`
> **Convenção de nome:** o ref de federação é **`cockpit`** (canônico do BLUEPRINT D1). Onde os docs 40/02 dizem `mission-control`, leia `cockpit`. O daemon é **`ideiaos-agentd`**; o LaunchAgent é **`com.ideiaos.cockpit`**.

Este doc converte a v14.0 em **tarefas `- [ ] N.M` consumíveis pelo GSD**, cada uma com **critério de pronto por exit-code** (`antifragile-gates`: `test -s` / exit binário, nunca o Read tool). Os 5 itens da missão viram os 5 grupos abaixo (mais Preparação `0.x` e Merge `7.x`).

**Princípio transversal (vale para todas as tarefas):** dois regimes de verificação — **artefato-de-arquivo** (`test -s` / exit-code é lei) e **estado-de-runtime/UI** (render+screenshot+critério explícito, `frontend-visual-loop`). A v14.0 é quase toda artefato-de-arquivo; só o scaffold SPA (`6.x`) toca runtime. Hooks saem `exit 0` em falha; scripts de build saem `exit 1`.

---

## Ancoragem verificada no código (lida do disco 2026-06-20)

| Fato | Evidência | Consequência de design |
|------|-----------|------------------------|
| `idea-doctor.sh` tem 5 emissores: `pass/warn/fail/info/step` (linhas 27-31) e contadores `PASS/WARN/FAIL` (linha 32) | `scripts/idea-doctor.sh` | **Interceptar os 5 emissores** é a camada de emissão paralela — NÃO reescrever as 14 seções. |
| `step()` imprime `━━━ N) Título ━━━`; resumo final `OK: N WARN: N FAIL: N` (linhas 31, 583-584) | idem | O `id`/`titulo` do JSON saem do argumento de `step()`; status agregado dos contadores. |
| `--json` NÃO existe (0 parsing da flag) | grep no fonte | Feature nova; fallback ANSI tem que ser provado intocado. |
| `push_planning_ref()` empurra ref sem checkout: `rev-parse --verify` → `rev-list --count @{u}..ref` → `git push origin <ref>` (linhas 16-24) | `~/.local/bin/git-autosync` | **Espelhar exatamente** para `push_cockpit_ref()`. Mesma forma offline-safe. |
| `git add -A -- . "${MEM_EXCLUDES[@]}"` (linha 90) só pega o **working tree** | idem | Ref `cockpit` escrito por plumbing NUNCA aparece no working tree → autosync cego não captura. Invariante A4. |
| autosync pula `main`/`master` (só pull) mas auto-pusha branch (linhas 50-71 vs 73-113) | idem | `push_cockpit_ref` roda nos DOIS ramos (igual planning, linhas 70 e 112), nunca toca `main`. |
| `gates.sh` expõe `assert_nonempty`/`gate_output`/`require_file` (`test -s`) | `source/lib/gates.sh` | Todo gate desta fase usa esses 3; sem reinventar. |
| `machine_id` = sha256(hardware-uuid), ex. `9d7fbccdbb1b` | missão | Coletor deriva 1×, cacheia; NÃO usa hostname (gotcha alias `192`↔`Mac-mini`). |
| 3 daemons hoje: `envsync`, `gitautosync`, `refresh-ai-security` (StartInterval) | `launchctl list \| grep ideiaos` | `com.ideiaos.cockpit` é o **4º**, irmão deles. |

---

## 0. Preparação (sanity, sem código)

- [ ] 0.1 Ler `specs/cockpit/spec.md` (9 requisitos) + este doc; confirmar escopo v14.0 = Substrato+Espinha (read-only quanto a produção). **Pronto:** `test -s specs/cockpit/spec.md` exit 0 e checklist dos 9 requisitos colado no PLAN.
- [ ] 0.2 Confirmar substrato local: `bash scripts/idea-doctor.sh >/dev/null; echo $?` deve sair 0 (ambiente saudável antes de mexer). **Pronto:** exit 0 registrado.
- [ ] 0.3 Derivar e fixar `machine_id` desta máquina: `ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}' | shasum -a 256 | cut -c1-12`. **Pronto:** string de 12 hex não-vazia capturada (ex. `9d7fbccdbb1b`); gate `[ -n "$MID" ]`.
- [ ] 0.4 Confirmar que NENHUM verbo de mutação de produção/cross-máquina entra nesta fase (gating v14.4). **Pronto:** grep por `rotate\|revoke\|deploy\|git push\|gh pr` no escopo planejado retorna 0 (allowlist vazio nesta fase — só coletor read-only).

---

## 1. `idea-doctor --json` — emissão paralela + fallback ANSI provado

**Abordagem (NÃO reescreve as 14 seções):** as 5 funções `pass/warn/fail/info/step` são os únicos pontos onde texto sai. Em vez de reescrevê-las, **decoramos** cada uma para, além do `echo` ANSI atual, **acumular um struct** num buffer em memória (arrays bash 3.2). Um **sink final** decide ANSI-vs-JSON pela presença da flag `--json`: sem a flag, o comportamento é byte-idêntico ao de hoje (os `echo` já aconteceram inline); com a flag, suprime-se o ANSI (redireciona para `/dev/null` quando `JSON_MODE=1`) e emite-se o JSON acumulado no final.

### Schema JSON exato (contrato `ideiaos-doctor/v1`)

```jsonc
{
  "schema": "ideiaos-doctor/v1",
  "generated_epoch": 1781988386,
  "repo": "/Users/.../IdeiaOS",
  "sections": [
    {
      "id": 1,                        // n. da seção (do prefixo "N)" em step())
      "titulo": "Skills globais",     // texto de step() sem o "N) "
      "status": "OK",                 // OK | WARN | FAIL — pior item da seção
      "counts": { "ok": 18, "warn": 0, "fail": 0, "info": 0 },
      "itens": [
        { "level": "ok",   "msg": "skill /idea" },
        { "level": "fail", "msg": "skill /motion AUSENTE — rode: bash setup.sh --global-only" }
      ]
    }
    // ... 14 seções
  ],
  "summary": { "ok": 75, "warn": 0, "fail": 0, "exit": 0 }
}
```

**Regras de derivação (determinísticas):**
- `id`/`titulo`: parse do argumento de `step()` via `=~ ^([0-9]+)\)[[:space:]]*(.*)$`. Seções sem número (ex.: "Resumo") não viram seção JSON — são o `summary`.
- `status` da seção: `FAIL` se algum item `fail`; senão `WARN` se algum `warn`; senão `OK`.
- `summary.exit`: 0 se `summary.fail==0`, 1 caso contrário — **idêntico** ao exit-code do modo ANSI (linha 589).
- JSON montado por concatenação de strings com **escape mínimo** (`\` e `"` nas `msg`) — sem `jq`/`python` (bash 3.2, `token-economy`). Helper `json_escape()` local.

### Tarefas

- [ ] 1.1 Adicionar buffer de acumulação (arrays paralelos `SEC_ID[] SEC_TITLE[] ITEM_SEC[] ITEM_LEVEL[] ITEM_MSG[]`) e fazer `pass/warn/fail/info/step` empilharem além de imprimir. **Pronto:** `bash scripts/idea-doctor.sh` (sem flag) produz output ANSI byte-idêntico ao baseline — ver 1.4.
- [ ] 1.2 Adicionar parsing de `--json` (set `JSON_MODE=1`) e o **sink final** que, se `JSON_MODE=1`, suprime ANSI e emite o JSON do schema acima. **Pronto:** `bash scripts/idea-doctor.sh --json | head -c1` == `{`.
- [ ] 1.3 Garantir JSON parseável: `bash scripts/idea-doctor.sh --json | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["schema"]=="ideiaos-doctor/v1"; assert len(d["sections"])>=14; sys.exit(0)'`. **Pronto:** exit 0 (python3 só como validador de teste, não dependência de runtime).
- [ ] 1.4 **Teste do FALLBACK ANSI (gate central da C3).** Capturar baseline ANTES das mudanças (`git stash` ou cópia) e comparar depois: `bash scripts/idea-doctor.sh > /tmp/ansi_after.txt; diff <(sed 's/\x1b\[[0-9;]*m//g' /tmp/ansi_baseline.txt) <(sed 's/\x1b\[[0-9;]*m//g' /tmp/ansi_after.txt)`. **Pronto:** `diff` exit 0 (texto sem ANSI-codes idêntico) **E** exit-code do modo sem-flag preservado (`bash scripts/idea-doctor.sh; echo $?` == baseline). Liga o `--json` sem quebrar a saída humana — critério C3 do BLUEPRINT.
- [ ] 1.5 Concordância JSON↔ANSI: o `summary` do JSON bate com a linha `OK: N WARN: N FAIL: N` do ANSI. **Pronto:** `test "$(./idea-doctor.sh --json | python3 -c 'import json,sys;print(json.load(sys.stdin)["summary"]["ok"])')" = "$(./idea-doctor.sh | grep -oE 'OK:[^ ]* [0-9]+' | grep -oE '[0-9]+')"` exit 0.

---

## 2. Protocolo do ref `cockpit` — git-plumbing sem tocar working tree

**Sequência EXATA** (grava `snapshots/<machine_id>.json` dentro de `refs/heads/cockpit`, órfão se não existir, append sobre a árvore anterior se existir):

```bash
# Dado: SNAP_JSON gravado em $snapshot_json (arquivo), MID (machine_id), REPO (IdeiaOS hub)
cd "$REPO"

# 1) blob para o json do snapshot
blob=$(git hash-object -w "$snapshot_json")                            # blob no object store

# 2) subárvore FLAT snapshots/ — o nome da entrada é SÓ "<mid>.json", SEM prefixo "snapshots/".
#    Caso APPEND: lê as entradas existentes da subárvore snapshots do cockpit atual,
#    descarta qualquer cujo nome == "<mid>.json", adiciona a nova, e mktree do conjunto mesclado.
#    Caso ÓRFÃO (ref não existe): `existing` fica vazio → mktree só da entrada nova.
existing=$(git ls-tree refs/heads/cockpit:snapshots 2>/dev/null | grep -v $'\t'"$MID.json"'$' || true)
sub=$(printf '%s\n100644 blob %s\t%s.json\n' "$existing" "$blob" "$MID" | grep -v '^$' | git mktree)

# 3) árvore TOPO referenciando a subárvore sob o nome "snapshots"
top=$(printf '040000 tree %s\tsnapshots\n' "$sub" | git mktree)

# 4) commit (parent = tip atual do cockpit se existir, senão órfão) e move o ref — working tree intocado
parent=$(git rev-parse -q --verify refs/heads/cockpit || true)
commit=$(git commit-tree "$top" ${parent:+-p "$parent"} -m "cockpit: snapshot $MID")
git update-ref refs/heads/cockpit "$commit"
```

> **Por que árvore de DOIS níveis e não `update-index`:** `git mktree` é **um-nível-só** — passar um path com barra (`snapshots/<mid>.json`) numa única chamada falha (`fatal: path ... contains slash`, exit 128). A correção constrói a subárvore FLAT `snapshots/` primeiro (entrada `<mid>.json`, sem prefixo) e depois a árvore-topo que a referencia sob o nome `snapshots`. `update-index` exigiria um índice temporário (`GIT_INDEX_FILE`) e cuidado para não vazar no índice real; o pipeline `ls-tree | grep -v | append | mktree` em dois níveis é puramente in-memory sobre objetos — zero `git add`/`update-index`, zero toque no índice/working tree. A lista de entradas vem da **subárvore-alvo** (`cockpit:snapshots`), não do índice (espelha o learning `git-plumbing-partial-branch-overlay-sync`).

**Como o autosync passa a empurrá-lo** — espelho EXATO de `push_planning_ref` (linhas 16-24):

```bash
push_cockpit_ref() {
  local NAME="$1"
  git rev-parse --verify --quiet cockpit >/dev/null 2>&1 || return 0
  git rev-parse --verify --quiet cockpit@{u} >/dev/null 2>&1 || return 0
  local AHEAD; AHEAD="$(git rev-list --count 'cockpit@{u}..cockpit' 2>/dev/null || echo 0)"
  [ "$AHEAD" -gt 0 ] || return 0
  git push --quiet origin cockpit 2>>"$LOG" && log "$NAME" "push cockpit OK ($AHEAD)" \
    || log "$NAME" "push cockpit FALHOU"
}
```

Chamado nos dois pontos onde `push_planning_ref` já é (linha 70 = ramo main; linha 112 = ramo feature) — **apenas no repo IdeiaOS** (hub). O `cockpit@{u}` exige um push inicial manual com `-u` (`@devops`, uma vez) para criar o upstream; sem upstream, `push_cockpit_ref` é no-op (offline-safe).

**Como o console lê N snapshots do ref:**
```bash
git show cockpit:snapshots/<machine_id>.json     # 1 máquina
git ls-tree --name-only cockpit snapshots/       # lista todas as máquinas federadas
```
O `console-ingest` itera `ls-tree` e `git show` cada blob — lê do **object store**, nunca de arquivo no disco.

### Tarefas

- [ ] 2.1 `source/lib/cockpit.sh` — função `cockpit_write_snapshot MID JSON` implementando a sequência hash-object→mktree→commit-tree→update-ref acima. Sourca `gates.sh`. **Pronto:** após chamar com um JSON de teste num repo /tmp, `git rev-parse --verify cockpit` exit 0 **E** `git status --porcelain` vazio (A4).
- [ ] 2.2 Cenário "working tree limpo" como teste: gravar snapshot e assertar `[ -z "$(git status --porcelain)" ]`. **Pronto:** exit 0; **falha** se qualquer arquivo aparecer untracked.
- [ ] 2.3 Cenário "preserva outras máquinas": gravar snapshot de `MID_A`, depois `MID_B`; `git ls-tree --name-only cockpit snapshots/ | wc -l` == 2. **Pronto:** exit 0 (segunda gravação não apaga a primeira).
- [ ] 2.4 Re-gravar `MID_A` e confirmar que a entrada é **substituída** (não duplicada): `git ls-tree cockpit snapshots/ | grep -c "${MID_A}.json"` == 1. **Pronto:** exit 0.
- [ ] 2.5 Adicionar `push_cockpit_ref()` ao `~/.local/bin/git-autosync` e chamá-la nas linhas 70 e 112. **Pronto:** `grep -c 'push_cockpit_ref' ~/.local/bin/git-autosync` == 3 (1 def + 2 chamadas) **E** `bash -n ~/.local/bin/git-autosync` exit 0 (sintaxe). **NOTA @devops:** editar `~/.local/bin/git-autosync` é mudança de daemon; o push inicial `git push -u origin cockpit` é operação `@devops` (prefixo `AIOX_ACTIVE_AGENT=devops`, learning `devops-push-gate-command-scoped-agent`).
- [ ] 2.6 Leitor: `cockpit_read_snapshot MID` (`git show cockpit:snapshots/$MID.json`) e `cockpit_list_machines` (`git ls-tree --name-only cockpit snapshots/`). **Pronto:** após 2.3, `cockpit_list_machines | wc -l` == 2 exit 0.

---

## 3. `ideiaos-agentd` — coletor read-only

**O que lê → entidade** (todas as fontes confirmadas na missão; tudo metadata, ZERO valor de segredo):

| Fonte (comando/arquivo) | Derivação | Entidade-alvo (doc 40) |
|-------------------------|-----------|------------------------|
| `.planning/soak/*.log` (`awk -F'\|'`) | epoch/iso/host/doctor/regression/commit | `SoakHeartbeat`, `Machine`, `Milestone` |
| `launchctl list \| grep ideiaos` | label→loaded(PID vs `-`) | `DaemonStatus` |
| `idea-doctor --json` (grupo 1) | `summary.{ok,warn,fail}` | `MachineSnapshot.doctor` |
| `git log/remote` por repo em `~/dev/*` | %ae/%aI/%s, remote url | `Commit`, `Project.github_remote` |
| `.env` NOMES (`grep '^[A-Z_]*=' \| sed 's/=.*//'`) | só var_name (RHS descartado) | `ApiKey` (sem `value`) |
| `~/.claude.json` + `~/.cursor/mcp.json` (keys de `mcpServers`) | server ids, enabled | `McpConnection`, `Account` |
| `gh auth status` | contas, scopes, active | `Account(github)` |
| `supabase/config.toml` (`project_id`) | supabase_project_id | `Project` |
| `~/.ideiaos/observations/*/` | agregado (count, ext, ok) | `ProductivityEvent` |
| `versions.lock` (`chave=valor`) + instalado | pinned vs installed (string-eq) | `VersionPin` |

**Descoberta dinâmica de produtos (NÃO hardcodar):** iterar `~/dev/*/` que sejam repos git (`test -d "$d/.git"`); classificar **produto** vs **test-dir** por heurística determinística — produto = tem remote `origin` configurado **E** está em `git-autosync-repos.txt` OU tem `.env.example`/`supabase/`/`package.json`; test-dir = sem remote ou nome casando `^(test|tmp|sandbox|fixture)` → flag `is_test_dir: true` no snapshot, contado à parte. Nunca assumir N=5.

### SHAPE do snapshot por máquina (`snapshots/<machine_id>.json`, schema `ideiaos-cockpit-snapshot/v1`)

```jsonc
{
  "schema": "ideiaos-cockpit-snapshot/v1",
  "machine_id": "9d7fbccdbb1b",
  "agentd_version": "0.1.0",          // declarado → Frota mostra drift de collector (assimetria assumida)
  "os_version": "Darwin 25.6.0",
  "taken_epoch": 1781988386,
  "daemons": [
    {"label":"com.ideiaos.gitautosync","loaded":false,"last_run_epoch":1781988159,"healthy":true},
    {"label":"com.ideiaos.envsync","loaded":false,"last_run_epoch":1781987000,"healthy":true},
    {"label":"com.ideiaos.refresh-ai-security","loaded":false,"last_run_epoch":1780531200,"healthy":true},
    {"label":"com.ideiaos.cockpit","loaded":true,"last_run_epoch":1781988386,"healthy":true}
  ],
  "doctor": {"ok":75,"warn":0,"fail":0,"exit":0},
  "installed_versions": {"aiox-core":"5.2.9","gsd":"1.1.0"},
  "accounts": [
    {"provider":"anthropic","identifier":"gustavo@redeideia.com.br","mechanism":"oauth"},
    {"provider":"github","identifier":"DevIdeiaBusiness","active":true,"scopes":["gist","read:org","repo","workflow"]}
  ],
  "projects": [
    {"slug":"nfideia","is_test_dir":false,"is_lovable":true,"supabase_project_id":"pdljyfyyxufkqejncccv",
     "under_autosync":true,"github_remote":"git@github.com:...",
     "api_keys":[{"var_name":"SUPABASE_SERVICE_ROLE_KEY","present":true,"expected":true,"risk_tier":"critical","mtime_epoch":1780000000}],
     "mcp_connections":[{"server_id":"6f530143-...","enabled":true,"deny_tools_count":19}],
     "security_tier":"ok"}                 // string --tier, NÃO o ledger (ledger de produto é local)
  ]
}
```

**Cadência (dois ritmos):** (a) **file-watch local** do próprio snapshot (~1–5s) para o System Pulse vivo — fora do escopo coletor, é a SPA que observa o arquivo; o agentd só **regrava** quando há mudança material. (b) **`StartInterval 900`** no plist (15min) para a coleta agendada cross-máquina. O agentd é **fail-silent** (hook-contract: erro → log stderr + `exit 0`; daemon não pode derrubar nada).

### Tarefas

- [ ] 3.1 `source/agentd/collect.js` (Node 18) — funções de leitura por fonte (tabela acima), cada uma retornando objeto puro; **nenhuma** lê o RHS de `=`. **Pronto:** teste unit `node -e 'const c=require("./collect");const k=c.readEnvKeys("/tmp/fix.env");process.exit(k.every(x=>!("value" in x))?0:1)'` exit 0 (nenhum objeto tem campo `value`).
- [ ] 3.2 Descoberta dinâmica de produtos com classificação produto/test-dir. **Pronto:** rodar contra `~/dev` real e assertar que pelo menos 1 produto conhecido (`IdeiaOS`) é `is_test_dir:false` e o output é JSON válido — `node collect.js --discover | python3 -m json.tool >/dev/null` exit 0.
- [ ] 3.3 Montagem do snapshot completo no SHAPE `ideiaos-cockpit-snapshot/v1`, gravado via `cockpit_write_snapshot` (grupo 2). **Pronto:** `node agentd.js --once && git show cockpit:snapshots/$MID.json | python3 -c 'import json,sys;d=json.load(sys.stdin);assert d["schema"]=="ideiaos-cockpit-snapshot/v1";assert "machine_id" in d'` exit 0.
- [ ] 3.4 **Zero-Leak no snapshot (gate crítico):** varrer o snapshot gerado contra padrões de segredo conhecidos (`sk-`, `gho_`, `eyJ` JWT, `service_role` value-shaped, hex>40). **Pronto:** `bash source/agentd/zeroleak-snapshot.sh <(git show cockpit:snapshots/$MID.json)` exit 0 (0 matches). Falha = release bloqueado.
- [ ] 3.5 `infra/launchd/com.ideiaos.cockpit.plist` — `StartInterval 900`, `ProgramArguments` apontando para o agentd, irmão dos 3 existentes. **Pronto:** `plutil -lint infra/launchd/com.ideiaos.cockpit.plist` exit 0 **E** `grep -q '<integer>900</integer>' ...plist`.
- [ ] 3.6 Fail-silent: simular erro (fonte ausente) e confirmar `node agentd.js --once; echo $?` == 0 com warning no stderr. **Pronto:** exit 0 mesmo com fonte faltando.

---

## 4. `console-ingest` → read-model SQLite

**Schema** (subconjunto v14.0 do doc 40 §3 — só o que a Espinha precisa; entidades de Wave 2 ficam para v14.2+). Tabelas mínimas: `machine`, `project`, `api_key` (**SEM coluna `value`**), `mcp_connection`, `productivity_event`, `soak_heartbeat`, `daemon_status`, `machine_snapshot`. DDL canônico já está no doc 40 §3 (linhas 332-487) — reusar verbatim. Destaque do invariante:

```sql
CREATE TABLE api_key (              -- credential-isolation materializada no schema
  project_slug TEXT NOT NULL, var_name TEXT NOT NULL,
  present INTEGER, expected INTEGER,
  risk_tier TEXT CHECK(risk_tier IN ('critical','sensitive','low','none')) NOT NULL,
  file_mtime_epoch INTEGER, committed INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (project_slug, var_name)
  -- NÃO HÁ coluna `value`. Proposital. Qualquer ALTER que a adicione = bloqueado.
);
```

**Regra "`rm db && rebuild` reconstrói dos refs":** o read-model é **cache 100% descartável**. O ingest:
1. lê `cockpit_list_machines` (grupo 2) → para cada `<machine_id>`, `git show cockpit:snapshots/<id>.json`;
2. lê ledgers commitados (`.planning/soak/*.log`, `.security/review-ledger.log`) direto do disco;
3. **UPSERT idempotente por PK** (re-rodar sobre os mesmos refs → mesmo DB);
4. dedup de `Machine` por `machine-aliases.json` curado (`192`↔`Mac-mini`); `gsd` por **string-equality** (nunca semver — `version-reset-migration-semver-trap`); classificação de ator determinística (`.local$`/`^wip: autosync`→autosync, `[bot]@`→bot, senão human).

### Tarefas

- [ ] 4.1 `source/console/schema.sql` — DDL das 8 tabelas v14.0 (do doc 40 §3). **Pronto:** `sqlite3 /tmp/t.db < source/console/schema.sql && sqlite3 /tmp/t.db '.tables' | grep -q api_key` exit 0.
- [ ] 4.2 **Guard estrutural anti-`value` (gate DISCRIMINANTE — exit 0 = coluna `value` EXISTE = FAIL):** isola a 2ª coluna do `PRAGMA` e busca exatamente `value`:
  ```bash
  if sqlite3 "$DB" 'PRAGMA table_info(api_key)' | cut -d'|' -f2 | grep -qiw value; then
    echo "FAIL: api_key table has a 'value' column — credential-isolation violated"; exit 1
  fi
  # pass = a coluna está ausente. Assert equivalente em uma linha:
  #   ! sqlite3 "$DB" 'PRAGMA table_info(api_key)' | cut -d'|' -f2 | grep -qiw value
  ```
  **Pronto:** o assert `! sqlite3 "$DB" 'PRAGMA table_info(api_key)' | cut -d'|' -f2 | grep -qiw value` sai exit 0 quando NÃO existe coluna `value`; qualquer `ALTER` que a adicione faz o `grep -qiw value` casar → exit 1 (FAIL). O `grep -qiv '|value|'` antigo era oco: `grep -v` casava qualquer linha sem o literal e sempre saía 0 (a tabela tem outras colunas), nunca enforçava nada.
- [ ] 4.3 `source/console/ingest.js` — lê refs+ledgers → UPSERT idempotente. **Pronto:** rodar 2× sobre os mesmos snapshots e `sqlite3 read-model.db 'SELECT COUNT(*) FROM machine'` retorna o mesmo número (idempotência) exit 0.
- [ ] 4.4 **Reconstrutibilidade (cenário A5 da spec):** `rm -f ~/.ideiaos/console/read-model.db && node ingest.js && test -s ~/.ideiaos/console/read-model.db`. **Pronto:** exit 0 — DB reconstruído integralmente dos refs.
- [ ] 4.5 Dedup + classificação de ator: fixture com `192` e `Mac-mini-de-Gustavo` → 1 só `Machine`; commit `wip: autosync`→`actor_class='autosync'`. **Pronto:** `sqlite3 ... "SELECT COUNT(DISTINCT machine_id) FROM machine"`==N esperado **E** `SELECT COUNT(*) FROM commit_log WHERE actor_class='human' AND subject LIKE 'wip: autosync%'`==0, ambos exit 0.

---

## 5. Protocolo de medição de Time-to-Truth (baseline + harness)

**As 3 jornadas concretas:**
- **J1 — "a frota está saudável?"** Resposta: cada máquina, último heartbeat, doctor PASS/FAIL, daemons vivos.
- **J4 — "a chave X existe e qual a idade?"** Resposta: para um `var_name` (ex. `SUPABASE_SERVICE_ROLE_KEY`), `present`, `risk_tier`, `age_days` (de `file_mtime_epoch`) — **nunca o valor**.
- **J2 — "está pronto para tag?"** Resposta: milestone-alvo tem `soak_satisfied` (≥2 máquinas, span≥1d **sobre epochs gravados**, não wall-clock — `soak-span-is-record-delta-not-wallclock`) + idea-doctor verde + security re-selado.

**Método de baseline (antes da Bridge existir):** cronômetro via terminal, mesma pergunta respondida abrindo terminais/greps/awk manualmente. **N≥5 medições por jornada, registra-se a mediana.** É esse número que vira a linha de base (não "2–15min assumido").

**Como medir o pós (na Bridge, v14.1):** mesmas 3 jornadas na UI, mesmo cronômetro, N≥5, mediana. Meta `<10s`. **Trust Rate:** a resposta da Bridge é comparada contra o **disco-agora** (`--verify` recomputa de `git show cockpit:...`/ledger no instante), não contra o cache.

> **Escopo v14.0 vs v14.1:** a v14.0 entrega **só o baseline terminal + o harness de cronometragem** (a Bridge ainda não existe). A medição pós-Bridge é critério da v14.1. Isto satisfaz A1 da spec ("baseline medido antes da Bridge").

### Tarefas

- [ ] 5.1 `scripts/ttt-baseline.sh J1|J4|J2` — wrapper que cronometra (`date +%s.%N` antes/depois) UMA execução manual da jornada via terminal e anexa a `~/.ideiaos/console/ttt-baseline.tsv` (`jornada\tmodo=terminal\tsegundos\tepoch`). **Pronto:** `bash scripts/ttt-baseline.sh J1 && test -s ~/.ideiaos/console/ttt-baseline.tsv` exit 0.
- [ ] 5.2 Coletar N≥5 por jornada (J1/J4/J2) e computar mediana. **Pronto:** `awk -F'\t' '$1=="J1"' ttt-baseline.tsv | wc -l` ≥ 5 para cada jornada (3 asserts, exit 0 cada).
- [ ] 5.3 `scripts/ttt-median.sh` — lê o TSV, imprime mediana por jornada (sort + linha do meio, bash puro). **Pronto:** `bash scripts/ttt-median.sh | grep -E '^J[124]\s+[0-9.]+'` retorna 3 linhas, exit 0. Registra a baseline que a v14.1 vai bater.
- [ ] 5.4 Harness reaproveitável para o pós (mesma cronometragem, modo `bridge`) — só a estrutura; a execução é v14.1. **Pronto:** `bash scripts/ttt-baseline.sh J1 --mode=bridge --dry-run; echo $?` exit 0 (aceita o modo, não exige Bridge ainda).

---

## 6. SPA scaffold (espinha visual mínima)

- [ ] 6.1 Scaffold Vite 7 + React 18 + TS + Tailwind + shadcn/ui em `apps/cockpit/`, tema black-gold OKLCH (`--brand-hue:75`). **Pronto:** `cd apps/cockpit && npm run build` exit 0 **E** `test -s dist/index.html`.
- [ ] 6.2 Servir em `http://127.0.0.1` (loopback), sem login. **Pronto:** `npm run dev &` + `curl -sf http://127.0.0.1:<port>/ | grep -qi '<div id="root"'` exit 0; processo encerrado após o gate.
- [ ] 6.3 Página única lendo o read-model SQLite (via `better-sqlite3` num pequeno server local ou pré-render no build) e exibindo a contagem de máquinas/projetos — prova de que a Espinha conecta substrato→UI. **Pronto:** `frontend-visual-loop` (regime runtime/UI): screenshot mostra ≥1 card de máquina com critério explícito "card renderiza machine_id e last_doctor".

---

## 7. Gates de fechamento, merge & archive

- [ ] 7.1 `scripts/check-cockpit.sh` + `idea-doctor §15` (dogfooding): agentd ativo? ref `cockpit` existe? snapshot local fresco (<2 ciclos)? **Pronto:** `bash scripts/check-cockpit.sh; echo $?` exit 0 quando saudável; `idea-doctor --json | python3 -c '...section id==15...'` mostra a seção 15.
- [ ] 7.2 Rodar suíte completa e garantir verde por **exit-code** (não Read tool). **Pronto:** todos os gates `2.x`–`6.x` exit 0; `idea-doctor` verde (exit 0).
- [ ] 7.3 Validar delta: `bash source/skills/spec/lib/spec-validate.sh specs/_changes/v14-cockpit-foundation` (já mergeado — confirmar archive). **Pronto:** archive `specs/_archive/2026-06-20-v14-cockpit-foundation/` existe (`test -d`).
- [ ] 7.4 SOAK: re-gravar heartbeat em ≥2 máquinas com span≥1d **sobre epochs gravados**; security re-selo (`check-security-freshness.sh --record PASS @security-reviewer`); atualizar README do GitHub (todos os recursos novos) + vault Obsidian (Changelog + extract-learnings). **Pronto:** `bash scripts/check-soak.sh v14.0; echo $?` exit 0 quando o span maturar.

---

## Ordem de execução para o `/gsd-plan-phase` (ondas)

- **Wave 1 (independentes, paralelo):** Grupo 1 (`idea-doctor --json`) · Grupo 2 (`cockpit.sh` plumbing) · Grupo 5 (baseline TtT — independe de tudo) · Grupo 6.1 (scaffold).
- **Wave 2 (depende de W1):** Grupo 3 (agentd usa `--json` do G1 + `cockpit_write_snapshot` do G2) · Grupo 4 (ingest consome o ref do G2/G3).
- **Wave 3 (integração):** Grupo 6.3 (UI lê o DB do G4) · Grupo 7 (gates de fechamento sobre tudo).

Nunca misturar independente e dependente na mesma wave (`orchestration` GSD).

---

*Documento 72 — PROPOSTO. Zero código. Próximo passo: `/gsd-plan-phase` consome estas tarefas `N.M` (Wave 1 primeiro). Verificação por exit-code em cada `Pronto:` — `antifragile-gates`.*
