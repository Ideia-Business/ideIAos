# R15-21 — Refactor gerador de hooks do setup.sh (data-driven) · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 3 — "por último") · **Veredito:** pass (8/8).

## Problema (dívida estrutural)

O `setup.sh` deployava 11 hooks Claude Code com **~11 blocos copy-paste** de `if/diff/cp/chmod`
(~13 linhas cada). Cada um é um ponto de erro independente — o que tornava R15-01/02 (que mexem em
hooks em massa) mais arriscados. Não havia **fonte-de-verdade única** da lista de hooks.

## O que foi feito (estende o padrão, não cria — só a metade "deploy")

### 1. `source/lib/deploy-hooks.sh` (NOVO) — fonte-de-verdade única
- `IDEIAOS_HOOKS=(…)` — **a lista** dos 11 hooks com deploy idêntico. Adicionar/alterar um hook =
  **1 linha** (antes: 1 bloco de ~13). Estende o padrão data-driven que já existe (step 5.21b itera
  `modules.json`).
- `deploy_hook_file` (idempotente via diff; **sempre retorna 0** — seguro sob `set -e`, onde
  `tok=$(func)` abortaria) + `deploy_all_hooks` (loop). Tokens `INSTALLED|UPDATED|CURRENT|MISSING`.

### 2. `setup.sh` — 1 loop ativo (1 edit, baixo risco no instalador crítico)
Inserido `step 5.4b` que sourceia o helper e roda `deploy_all_hooks` ANTES dos blocos antigos. A
metade "registro" (settings.json) permanece por-hook (heterogênea — T-01-10).

### 3. Decisão de escopo: blocos antigos marcados `debt:` (não removidos agora)
Os 11 blocos de DEPLOY ficaram **redundantes idempotentes** (o loop já deployou → diff→skip). Removê-los
agora seriam 11 edições num arquivo de 1775 linhas crítico — alto risco, baixo valor incremental. Marcados
`debt:` para remoção incremental (respeita "fazer por último" + o gate de igualdade protege a remoção).
A **fonte-de-verdade única já existe** (objetivo do requisito: reduzir o risco de R15-01/02) ✅.

## Verificação (`tests/v15/test-deploy-hooks.sh` — 8/8, exit 0)

| Caso | Resultado |
|------|-----------|
| **IGUALDADE DE SET: `IDEIAOS_HOOKS` == blocos `*_TEMPLATE` do setup.sh** (11==11; drift-guard) | ✅ |
| cada hook da lista existe em `source/hooks/` | ✅ |
| `deploy_all_hooks` em sandbox: 11 INSTALLED · 0 MISSING · 11 arquivos · todos +x | ✅ |
| idempotência: 2ª passada = 11 CURRENT | ✅ |
| `setup.sh` `bash -n` válido + smoke do `while…<<EOF $(…)` sob `set -e` (não aborta) | ✅ |

O gate de igualdade de SET é o drift-guard durável: se alguém adicionar um bloco sem a lista (ou
vice-versa), o teste FALHA — o que torna seguro remover os blocos depois.

## Arquivos
- `source/lib/deploy-hooks.sh` (novo) · `setup.sh` (loop 5.4b + debt: nos blocos)
- `tests/v15/test-deploy-hooks.sh` (novo, 8 asserts)
