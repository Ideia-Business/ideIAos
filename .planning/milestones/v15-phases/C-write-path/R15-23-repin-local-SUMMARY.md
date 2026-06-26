# R15-23 — Proof-gate de teardown (re-pin local O2) · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 4) · **Veredito:** pass (13/13 por exit-code).

## Problema (capacidade existia, mas era prosa no ADR)

`pinned-keys.sh` já tinha `add`/`revoke-local`/`process-ref-*` — mas o invariante de **revogação/re-pin
local own-fleet** não estava operacionalizado por exit-code. Sem o proof-gate, "revogar/re-pinar" é
prosa no ADR, não capacidade provada ([[mitigated-label-must-not-outrun-precondition]]). A faceta
multi-dev (revoke FG-PAT) é v16; o **re-pin local** é own-fleet e **precede R15-17/F2**.

## O que foi feito — `tests/v15/test-repin-local.sh` (proof-gate, 13/13 exit 0)

Operacionaliza o ciclo de teardown da chave O2 (a `enc_pubkey` do selo) com chaves SSH reais
(`ssh-keygen`) num store sandbox (`IDEIAOS_PINNED_STORE`):

| Fase | Invariante provado | Resultado |
|------|--------------------|-----------|
| **1. pin** | `add` pina O2 #1; `enc-pubkey-of` = O2 #1 (vem só do pin LOCAL, nunca do ref) | ✅ |
| **2. re-pin** | `add` O2 #2 ROTACIONA: `enc-pubkey-of`=O2 #2, **E2≠E1** (antiga não-autoritativa), 1 entrada (sem duplicata) | ✅ |
| **3. teardown** | `revoke-local` → `is-pinned`≠0 **e** `enc-pubkey-of` exit≠0 (chave O2 indisponível) | ✅ |
| **4. fail-closed** | `process-ref-revocation`/`-addition` → exit≠0 **e** o pin é **PRESERVADO** após revogação FORJADA via ref | ✅ |

A fase 4 é a mais importante: prova que **nada vindo do ref muta a lista** — fecha o CRÍTICO de
revogação forjada (host comprometido assinaria a revogação da chave BOA → DoS). A revogação
autoritativa é **só** re-pin local out-of-band. Espelha `temp-privilege-window-teardown-grants`:
a janela de privilégio é revogável de verdade, localmente.

## Fronteira respeitada
Re-pin **LOCAL** (own-fleet) — NÃO é a cerimônia N=2 das enc-keys (R15-17, GATED). Nenhum código
de produção alterado (proof-gate sobre capacidade existente); zero risco de regressão.

## Arquivos
- `tests/v15/test-repin-local.sh` (novo, 13 asserts) — não toca `pinned-keys.sh` (prova o que já existe)
