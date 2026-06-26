# R15-12 — Expor dados ricos já-coletados no Cockpit · PLAN

**Milestone:** v15 · **Fase:** B · **Wave:** 1 · **Req:** R15-12 · **Origem:** CKN-05 / CKF-07(3,4,6)

## Objetivo (goal-backward)

O Cockpit mostra o valor que já coleta: gh accounts, drill-down de `doctor.sections`,
`supabase_project_id`, span SOAK real — e a COLETA para de vir capada (`installed_versions={}`,
pilar Sinapse vazio). Metadata-only (sem `value`/segredo).

## 3 partes

- **(b) installed_versions={}** — `collect.readVersions()` ancorava em `process.cwd()`; o plist do
  cockpit (`com.ideiaos.cockpit.plist`) **não tem `WorkingDirectory`** → sob launchd o cwd não é o
  repo → `versions.lock` não era achado → `{}` silencioso. **Fix:** ancorar em `__dirname`.
- **(c) readMcp() nunca chamado** — `readMcp` existe (collect.js:192, exportado) e o ingest JÁ consome
  `snapshot.mcp_connections` (ingest.js:349 → tabela `mcp_connection`), mas `collectSnapshot` nunca
  preenchia o campo → pilar Sinapse vazio. **Fix:** chamar `readMcp()` e pôr em `mcp_connections`.
- **(a) expor no read.js** — JOIN `supabase_project_id` (tabela `project`), span SOAK (max-min dos
  epochs), drill-down `doctor.sections`, gh accounts. Dados no `payload_json` BLOB → tocar `read.js`
  (parse/JOIN), não "só render". **MAIOR parte — toca backend + provável SPA.**

## Escopo deste ciclo: (b) + (c) — a COLETA

(b) e (c) são contidos, verificáveis por exit-code, e PRÉ-REQUISITO de (a) (sem coletar, expor
mostra vazio). (a) — exposição read.js/SPA — é maior (toca frontend, exige verificação de render) e
fica como **continuação do R15-12**.

## Gates (exit-code, com input INVÁLIDO)

| Gate | Verificação | Resultado |
|------|-------------|-----------|
| 1 | `node --check` collect.js + agentd.js | ✅ |
| 2 | **(b) anti-teatro:** `readVersions` rodado de `/tmp` (cwd sem versions.lock — simula launchd) → 8 chaves (process.cwd() teria dado `{}`) | ✅ |
| 3 | **(c)** `readMcp` → 6 servers `{source,name}` sem `value`/`token` | ✅ |
| 4 | **(c) wiring:** `mcp_connections` no return + buildMinimalSnapshot; ingest já consome | ✅ |

## Pendente (continuação R15-12)

- **(a) exposição read.js** (`apps/cockpit/server/read.js`, 654 linhas): JOIN supabase_project_id,
  span SOAK, drill-down doctor.sections, gh accounts + render no SPA.
- **end-to-end:** os snapshots ATUAIS no ref cockpit ainda têm `installed_versions={}`/sem
  `mcp_connections`; os campos aparecem no próximo ciclo do agentd (launchd, 900s) ou re-coleta manual.
