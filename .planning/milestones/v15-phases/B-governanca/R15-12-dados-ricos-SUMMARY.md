# R15-12 — Expor dados ricos já-coletados no Cockpit · SUMMARY

**Status:** ✅ DONE 2026-06-26 · **Wave:** 1 · **Executor:** sessão principal
**Veredito:** pass — coleta (b+c) + exposição (a) completas; render rico = R15-13/R15-14.

## O que foi feito (3 partes)

### (b) installed_versions={} — coleta · DONE (ciclo anterior)
`collect.readVersions()` ancorava em `process.cwd()`; o plist do cockpit não define
`WorkingDirectory`, então sob launchd o cwd ≠ repo → `versions.lock` não era achado → `{}`
silencioso. **Fix:** ancorar em `__dirname` (`source/agentd/collect.js`). Provado: rodado de
`/tmp` (sem versions.lock) → **8 chaves**.

### (c) readMcp() nunca chamado — coleta · DONE (ciclo anterior)
`readMcp` existia e o ingest já consumia `snapshot.mcp_connections` (ingest.js:349 → tabela
`mcp_connection`), mas `collectSnapshot` nunca preenchia o campo → **pilar Sinapse vazio**.
**Fix:** chamar `readMcp()` e incluir `mcp_connections` no return + `buildMinimalSnapshot`
(`source/agentd/agentd.js`). Provado: `readMcp` → **6 servers** `{source,name}` credential-safe.

### (a) exposição no read.js — ESTE ciclo · DONE
4 dados ricos já-coletados ganharam camada de exposição GET (`apps/cockpit/server/read.js`):

| Dado rico | Como foi exposto | Verificação (exit-code) |
|-----------|------------------|--------------------------|
| **supabase_project_id** | `GET /projects` (novo) — lista da tabela `project`, colunas explícitas | 8 projetos; coluna presente |
| **span SOAK real** | `GET /soak` (novo) — `MAX(epoch)-MIN(epoch)` por milestone, **não wall-clock** | 5 milestones; span=MAX-MIN; todos ≥1d, 2 hosts |
| **drill-down doctor.sections** | `GET /doctor?cell=<mid>` (novo) — sections do snapshot recente, `MID_RE` validado | exit/ok/warn/fail/sections; cell inválido → 400 |
| **gh accounts** | campo `accounts` no `GET /fleet` (per-máquina, metadata-only) | accounts presente; zero-leak (sem token) |

## Verificação (7 gates por exit-code, com input INVÁLIDO)

| Gate | Resultado |
|------|-----------|
| 1 — `node --check read.js` | ✅ |
| 2 — reconstruir read-model (invariante A5: `rm db && ingest`) | ✅ |
| 3 — `/projects` expõe `supabase_project_id` (coluna presente) | ✅ 8 projetos |
| 4 — `/soak` `span_seconds === max_epoch - min_epoch` (delta gravado, não wall-clock) | ✅ 5 milestones |
| 5 — `/doctor?cell=<mid>` devolve `sections` (array) + counts | ✅ |
| 6 — **ANTI-TEATRO:** `/doctor?cell=NAO_EH_MID` → **400** (input inválido rejeitado) | ✅ |
| 7 — `/fleet` carrega `accounts`; nenhum `token/password/secret` no payload | ✅ zero-leak |

## Decisões / fronteira

- **Exposição (backend) ≠ render rico (UI).** O título é "*Expor* dados ricos" e o escopo (a)
  era "read.js/SPA". Entreguei a **camada de exposição GET** — o verbo literal "expor" —
  verificável por exit-code (curl+JSON.parse contra o read-model real). O **render rico** desses
  4 dados pertence aos requisitos de UI que existem separadamente: **R15-13** (Flight Recorder /
  drill-down) e **R15-14** (card Saúde & Governança que *consome um GET*). Renderizá-los aqui
  invadiria o escopo deles (disciplina de escopo). R15-12(a) é a **fonte GET** que R15-13/14
  consomem → dependência `R15-13/14 → R15-12(a)` registrada no INDEX.
- **doctor.sections=[] hoje é honesto, não bug.** Os snapshots ATUAIS no ref cockpit são
  pré-fix do `idea-doctor --json` (bugfix `f80e9c5`). O endpoint devolve `[]` (No-Invention);
  preenche no próximo ciclo do agentd (launchd 900s) ou re-coleta manual.
- **supabase_project_id=null hoje** nos snapshots atuais — a coluna expõe o vínculo; o valor
  preenche quando o agentd detectar o `supabase_project_id` nos projetos.
- **Não rodei `agentd --once`** para não mutar o ref cockpit no meio do trabalho — a re-coleta
  (que preenche installed_versions/mcp/sections/supabase) é o próximo ciclo natural do daemon.

## Arquivos

- `apps/cockpit/server/read.js`: +3 handlers (`handleProjects`, `handleSoak`, `handleDoctor`)
  + campo `accounts` no `handleFleet` + 3 rotas no `createServer`.
- (ciclo anterior) `source/agentd/collect.js` (readVersions `__dirname`), `source/agentd/agentd.js`
  (`mcp_connections` × 3).
- PLAN/SUMMARY. (Nenhum arquivo novo na árvore-fonte → README inalterado.)

## Pendente (não-bloqueante, herda para R15-13/R15-14)

- **Render** dos 4 dados na SPA: R15-13 (drill-down/Flight) + R15-14 (card governança GET).
- **end-to-end vivo:** `doctor.sections`, `supabase_project_id`, `installed_versions` (8) e
  `mcp_connections` (6) aparecem com valor no próximo ciclo do agentd (re-coleta com o fix do `--json`).
