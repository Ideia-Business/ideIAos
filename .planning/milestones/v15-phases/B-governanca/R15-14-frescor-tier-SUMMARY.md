# R15-14 (completion) — Frescor-tier coletado + re-coleta do agentd · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase 1 do "faça tudo até 100%") · **Executor:** sessão principal
**Veredito:** pass — fecha o **net-new diferido** do R15-14 (3º pilar do card "Saúde & Governança")
+ destrava 2 bugs de coleta que mantinham o snapshot pobre.

## O que foi feito

### 1. Frescor-tier de segurança (o net-new que R15-14 deixou diferido)
- `collect.js`: nova `readSecurityFreshness()` — roda `check-security-freshness.sh --tier` (token
  machine-readable no stdout: `ok|warn|egregious|unbootstrapped`), retorna `{ tier }` sem segredo.
- `agentd.js`: `security_freshness` incluído no snapshot (`collectSnapshot` + `buildMinimalSnapshot`).
- `read.js handleOverview`: agrega o **pior tier** entre os snapshots (`egregious>warn>ok`), lido do
  payload; `unknown` honesto se nenhum reportou. Retorna `security_freshness` no `/overview`.
- `Overview.tsx`: o 3º pilar do card troca `aguardando coleta` pelo **tier real** (mapa ok→fresco
  verde / warn→defasado / egregious→egrégio; `unknown`/`unbootstrapped` → mantém "aguardando coleta").

### 2. Bug de coleta do doctor consertado (mascarava TODA a saúde da frota)
`readDoctor` nunca capturava o doctor — **dois motivos** sobrepostos:
- **timeout:** `idea-doctor --json` leva ~16s; o `safeExec` default era **10s** → ETIMEDOUT.
- **exit-code:** `idea-doctor --json` sai **exit 1 quando há FAIL** (estado normal!); o `execSync`
  trata non-zero como exceção e **descartava o JSON válido do stdout**.
- **Fix:** `safeExec('… --json 2>/dev/null || true', { timeout: 60000 })` — `|| true` preserva o
  stdout (o exit real vem em `JSON.summary.exit`); 60s cobre os 16s com folga.

### 3. Re-coleta do agentd (`agentd --once`)
Preencheu os campos que estavam vazios nos snapshots pré-fix: `installed_versions` **8 chaves**,
`mcp_connections` **6**, `supabase_project_id` **4/8 projetos**, `security_freshness` **ok**, e o
`doctor` agora real (**exit 1 · ok 75 · warn 3 · fail 3 · 15 sections**).

## Verificação

| Gate | Resultado |
|------|-----------|
| `node --check` collect.js / agentd.js / read.js | ✅ |
| smoke `collect.readSecurityFreshness()` | ✅ `{tier:"ok"}` |
| `agentd --once` (coleta+grava ref cockpit+re-ingere) | ✅ exit 0 |
| snapshot pós-recoleta: security_freshness/versions/mcp/supabase/doctor | ✅ todos preenchidos |
| curl `/overview` → `security_freshness:"ok"` + checks reais | ✅ |
| `tsc -b` + `vite build` | ✅ exit 0 (235 kB) |
| **Render (regime-R):** pilar Frescor verde "fresco"; Saúde "fail" honesto | ✅ |

## Achado que entra na Fase 3 (resíduo de segurança)

A re-coleta destravou o doctor → os **3 FAILs reais** ficaram visíveis (§7e Lovable-MCP):
- **cfoai-grupori** (deny=0) + **nfideia** (deny=0) → esperam o PR `sec→main` (cfoai é particular).
- **ideiapartner** (deny=**16**, esperado ≥19) — **NOVO**: o handoff o dava como "nada a fazer"
  (settings.local.json). Faltam 3 deny. Fix é local (gitignored, não dispara deploy Lovable).

O DoD do v15 (`idea_doctor=PASS` p/ SOAK) exige os 3 fechados.

## Arquivos
- `source/agentd/collect.js` (readSecurityFreshness + fix readDoctor)
- `source/agentd/agentd.js` (security_freshness no snapshot ×2)
- `apps/cockpit/server/read.js` (agrega tier no /overview)
- `apps/cockpit/src/pages/Overview.tsx` (pilar 3 consome o tier real)
