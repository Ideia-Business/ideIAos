# R15-12 — Expor dados ricos já-coletados · SUMMARY

**Status:** 🟡 PARCIAL 2026-06-26 — **coleta (b+c) DONE**; exposição read.js (a) = continuação.
**Wave:** 1 · **Executor:** sessão principal

## O que foi feito (a COLETA — destrava os dados na fonte)

- **(b) `installed_versions={}` corrigido** (`source/agentd/collect.js`): `readVersions()` ancorava em
  `process.cwd()`; o plist do cockpit não define `WorkingDirectory`, então sob launchd o cwd não é o
  repo → `versions.lock` não era achado → `{}` silencioso. Agora ancora em `__dirname` (collect.js
  vive em `<repo>/source/agentd/`). Provado: rodado de `/tmp` (sem versions.lock) retorna **8 chaves**.
- **(c) `mcp_connections` coletado** (`source/agentd/agentd.js`): `collectSnapshot` agora chama
  `collect.readMcp()` e inclui `mcp_connections` no shape (e no `buildMinimalSnapshot`). A infra de
  consumo JÁ existia (ingest.js:349 itera `snapshot.mcp_connections` → tabela `mcp_connection`); só o
  snapshot não preenchia → **pilar Sinapse vazio**. Provado: `readMcp` → **6 servers** `{source,name}`
  credential-safe (sem `value`/`token`).

## Verificação (exit-code)

| Gate | Resultado |
|------|-----------|
| `node --check` collect.js + agentd.js | ✅ |
| **(b) anti-teatro:** `readVersions` de `/tmp` (cwd errado, sem versions.lock) → 8 chaves | ✅ |
| **(c)** `readMcp` → 6 servers `{source,name}` sem value/token | ✅ |
| **(c) wiring:** `mcp_connections` no return + minimal; ingest já consome | ✅ |

## Pendente — continuação R15-12 (parte a)

- **Exposição no `read.js`** (`apps/cockpit/server/read.js`, 654 linhas — já tem `doctorFromPayload`
  + JOINs como padrão): JOIN `supabase_project_id` (tabela `project`), span SOAK (max-min dos epochs
  gravados), drill-down de `doctor.sections`, gh accounts. + render no SPA (toca frontend → exige
  verificação de render, não só exit-code).
- **end-to-end:** os snapshots ATUAIS no ref cockpit ainda vêm da coleta antiga; `installed_versions`
  (8) e `mcp_connections` (6) só aparecem no próximo ciclo do agentd (launchd 900s) ou re-coleta.
  Não rodei `agentd --once` para não mutar o ref cockpit no meio do trabalho.

## Arquivos

- `source/agentd/collect.js` (readVersions __dirname), `source/agentd/agentd.js` (mcp_connections × 3).
- PLAN/SUMMARY. (Nenhum script novo → README inalterado.)
