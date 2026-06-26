# A-06 — Botão verificar na Frota (R15-08) · SUMMARY

**Status:** ✅ DONE 2026-06-25 · **Wave:** 1 · **Executor:** sessão principal (não delegado)

## Objetivo

O endpoint `/verify` (read.js:517-585) era completo e hardened (recompute-from-disk via
`git show cockpit:snapshots/<MID>.json`, MID validado `^[0-9a-f]{12}$`, argv-array sem shell,
metadata-only) — mas **nenhuma tela o consumia**. Adicionar à Frota um botão "verificar"
por máquina que distingue os **3 estados honestos**.

## O que foi feito (só `apps/cockpit/src/pages/Frota.tsx` — backend intocado)

1. **`interface VerifyResult`** com o shape REAL do endpoint (`cell, verified, served_epoch,
   disk_epoch, recomputed_at_epoch, source`) — zero campo inventado (No-Invention).
2. **`verifyState(r)`** deriva os 3 estados da DUPLA `(verified, disk_epoch)`:
   - `verified===true` → **verified**
   - `verified===false && disk_epoch!=null` → **divergence** (alarme real)
   - `verified===false && disk_epoch==null` → **unverifiable** (NEUTRO — invariante-piso)
3. **Handler `verifyCell`** dispara `GET /verify?cell=<MID>` on-demand (no clique,
   recompute-from-disk A6 — nunca cache/load inicial); erro de FETCH é estado distinto dos 3.
4. **Nova coluna "verificar"** na tabela de heartbeat: botão + render dos 3 estados com
   Badge (`ok`/`fail`/`default`) **+ label textual** (cor nunca é o único sinal — WCAG).
5. **"verificado há Xs"** derivado de `recomputed_at_epoch` (não `last_seen_epoch`).

## Verificação

| Gate | Regime | Resultado |
|------|--------|-----------|
| `test -s Frota.tsx`; grep `/verify` + `verified` + `disk_epoch` + ramo `disk_epoch != null` | artefato (exit-code) | ✅ |
| `read.js` intacto (`git diff` vazio) — read-only sobre o backend | artefato | ✅ |
| `npm run build` (tsc -b + vite) | artefato | ✅ exit 0 |
| **3 estados no browser** (Chrome DevTools MCP, a11y-tree + screenshot) | runtime | ✅ |

### Prova de runtime (regime-UI — curl não exercita o CORS preflight do fetch)

Stub loopback EFÊMERO (scratchpad, fora do repo) serviu `/fleet` com 3 máquinas sintéticas e
`/verify` com os 3 casos; Vite apontado a ele via `VITE_READ_PORT=3099`. Observado no a11y-tree
**e** no screenshot:

| Máquina | Badge | Label textual | Cor |
|---------|-------|---------------|-----|
| `aaaaaaaaaaaa` | `ok` | **verificado** + "verificado há 15s" | verde |
| `bbbbbbbbbbbb` | `fail` | **divergência** + "servido ≠ disco" | vermelho (alarme) |
| `cccccccccccc` | `default` | **não-verificável** + "sem snapshot no disco" | **dourado/neutro — NÃO vermelho** |

A invariante-piso R15-08 (disk_epoch==null = NEUTRO, nunca alarme) está provada nos dois sinais.
Stub e processos encerrados; `read.js` de produção sem resíduo.

## Arquivos

- `apps/cockpit/src/pages/Frota.tsx` (único arquivo de produto)

## Carry-forward

- Nenhum. A capacidade `/verify` (já construída) agora tem superfície de UI.
- Escopo cirúrgico respeitado: `version-drift`/`MachineCard`/`App.tsx`/`badge.tsx`/`read.js` intocados.
