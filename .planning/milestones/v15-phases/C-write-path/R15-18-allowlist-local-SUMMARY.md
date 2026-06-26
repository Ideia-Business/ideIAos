# R15-18 — Allowlist write-path LOCAL (verbos local-reversíveis + ledger wired) · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 4 — write-path sensível) · **Veredito:** pass (11/11).
**Era a única proposta com `respects=false`** — só adotável corrigida. As 2 correções foram feitas.

## Correção 1 (segurança) — `reseal_security` era fraude de gate

O verbo `reseal_security` carimbava `check-security-freshness.sh --record PASS @security-reviewer` por
**clique de UI** (arm:true). Isso AFIRMA que @security-reviewer revisou o diff quando **ninguém revisou**
= **fraude de gate de integridade** (viola o FOREVER-OUT do canal). Liga direto a
[[automate-the-reminder-not-the-integrity-stamp]] (automatize o LEMBRETE, nunca o CARIMBO).

**Fix:** substituído por `security_status` — **read-only** (`--tier`, arm:false). O operador VÊ o tier;
o re-selar REAL é exceção declarada (exige @security-reviewer no diff + `--record` no **CLI**, fora do
/command). A SPA (`CommandPalette.tsx`) foi alinhada: botão "Ver frescor de segurança" (não-mutante).

## Correção 2 (auditoria) — ledger WIRED ao /command (era código novo)

O ledger hash-chained (`source/agentd/ledger.sh`) **não estava wired** ao `/command` (zero ocorrências).
Adicionado `recordCommandToLedger(verb, ref, result)` — registra TODA tentativa, metadata-only
(credential-isolation; sem stdout/segredo), best-effort (falha de ledger nunca derruba o canal):
- comando **aceito** → `append … exit:<code> command ok|fail` (após exec).
- comando **rejeitado** (verbo fora do enum) → `append … denied command rejected` (no gate default-deny).

## Verificação (`tests/v15/test-writepath-allowlist.sh` — 11/11, exit 0)

| Caso | Resultado |
|------|-----------|
| `reseal_security` NEUTRALIZADO (0 `--record PASS @security-reviewer` no read.js) | ✅ |
| `security_status` read-only presente; SPA alinhada (sem `reseal_security`) | ✅ |
| ledger WIRED (`recordCommandToLedger` ×3: def + deny + exec) | ✅ |
| **gate-negativo: verbo inválido auditado como 'rejected' (nunca 'ok')** | ✅ |
| ledger: append aceito/rejeitado → exit 0; **append malformado → exit≠0** | ✅ |
| **adulteração na cauda → `verify` exit≠0 (tail-anchor não-cego)** | ✅ |
| `read.js` node --check · SPA `tsc + vite build` (235 kB) | ✅ |
| regressão `tests/writepath/test-ledger.sh` (não toquei ledger.sh) | ✅ |

O gate-negativo foi provado de verdade (input inválido → 'rejected', append malformado → exit≠0,
cauda forjada → verify falha) — não só o happy-path (cf. `antitheater-gate-blind-spot-happy-path`).

## Fronteira respeitada (NÃO é R15-17)
Só verbos **LOCAL-reversíveis** + auditoria local. **Nada** de cross-máquina, push_cmd_ref, enc-keys
ou @devops. O FOREVER-OUT do canal (sem rotate/deploy/revoke/push) segue intacto — e mais forte
(o carimbo de segurança saiu do clique).

## Arquivos
- `apps/cockpit/server/read.js` (VERBS: reseal→security_status; `recordCommandToLedger` + 2 chamadas)
- `apps/cockpit/src/components/CommandPalette.tsx` (botão read-only)
- `tests/v15/test-writepath-allowlist.sh` (novo, 11 asserts)
