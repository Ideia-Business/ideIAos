# A-05 — Alias-map da Frota (R15-07) · SUMMARY

**Status:** ✅ DONE 2026-06-25 · **Wave:** 1 · **Executor:** sessão principal (não delegado)

## Objetivo

A aba Frota do Cockpit mostrava o `sha256[:12]` cru (`52ae4ab0681a`) em vez de um nome humano.
Causa-raiz: **chave do JSON**, não código — `machine-aliases.json` estava chaveado por hostname,
mas `resolveAlias(mid, aliases)` (ingest.js:325) é chamado com `mid = sha256[:12]` → nunca casava.

## O que foi feito

1. **Re-chaveado `source/console/machine-aliases.json` por sha256[:12]** (rota manual/curada).
   - `c706ac77d577` → `Mac-mini-de-Gustavo`
   - `52ae4ab0681a` → `MacBook-Air-2`
   - header `_SOURCE` de proveniência; zero chave de hostname residual.
2. **Novo gate `scripts/check-alias-map.sh`** — build-script (exit 1 em falha) que CRUZA
   chave×MID: espelha `resolveAlias` (ingest.js:60) sobre cada MID real do ref `cockpit`.
   WARN para máquina-não-curada; FAIL para valor==sha256 ou zero-resolve.
3. **Zero edição em lógica** — `resolveAlias`/`ingest.js`/`read.js`/`collect.js`/`Frota.tsx`
   intocados. O fix é 100% de DADO.

## Correção de No-Invention (vs. o plano)

O plano A-05 sugeria `52ae4ab0681a → Mac-mini-de-Gustavo`. **Provei por exit-code o contrário**:
derivei o `machine_id` desta máquina (hostname `Mac-mini-de-Gustavo.local`) pela fórmula real do
`collect.js:25-29` (`sha256(IOPlatformUUID)[:12]`) = **`c706ac77d577`**. Logo o Mac-mini é
`c706ac77d577` e o MacBook-Air-2 é `52ae4ab0681a` (por eliminação — os 2 hosts da cerimônia N=2).
Gravei o mapeamento **correto/empírico**, não o chute do plano.

## Verificação (exit-code)

| Gate | Resultado |
|------|-----------|
| JSON válido + ≥1 chave `^[0-9a-f]{12}$` + zero hostname residual | ✅ |
| `check-alias-map.sh` PASSA no map corrigido (2 PASS / 0 WARN / 0 FAIL) | ✅ |
| Anti-teatro-verde: FALHA contra map hostname-keyed; map bom restaurado | ✅ |
| Re-ingest → `machine.canonical_name != sha256` na coluna real que a Frota lê | ✅ |
| README sync (gate) verde após documentar o novo script | ✅ |

## Arquivos

- `source/console/machine-aliases.json` (re-chaveado)
- `scripts/check-alias-map.sh` (novo gate)
- `README.md` (tabela de scripts + árvore)

## Carry-forward

- A coluna `canonical_name` no read-model local já reflete os nomes. A Frota mostra nome após
  o próximo `/fleet` (A-06 wire-up do botão verificar é ortogonal a este fix).
- `resolveAlias` de soak-heartbeat (ingest.js:142) é ORTOGONAL — não tocado (marcado como fora de escopo).
