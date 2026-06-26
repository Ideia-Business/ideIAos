# R15-20 — Auto-cura visível (ledger de propagação + heartbeat no doctor) · SUMMARY

**Status:** ✅ DONE 2026-06-26 (Fase C / Onda 3, Wave 1) · **Veredito:** pass (6/6 por exit-code).

## Problema

A auto-cura (`propagate-if-changed` re-deploya o daemon/overlay quando a fonte muda) **funciona mas é
caixa-preta**: quando o daemon driftou atrás da fonte, a falha foi silenciosa (incidente que motivou
o endurecimento de durabilidade do autosync, 2026-06-24).

## O que foi feito (dimensionado à necessidade — telemetria, não não-repúdio)

### 1. Ledger de propagação (`scripts/propagate-if-changed.sh`)
- `propagate_ledger_append VERDICT NOTE` → `~/.local/state/propagate-ledger.log` (**LOCAL-ONLY**, fora
  do git: não polui a frota). Append atômico de 1 linha curta via `>>` (< PIPE_BUF). **SEM
  hash-chain/tail-anchor** (molde `check-soak.sh`, não `ledger.sh` — é telemetria).
- Formato: `epoch|iso|host|verdict|old..new|errors|note` (7 campos).
- Chamado nos 3 pontos de saída materiais: **OK** (propagou), **FAIL** (drift do daemon/overlay),
  **NOOP** (diff sem paths propagáveis). Dry-run não registra (não é ciclo).

### 2. Heartbeat no `idea-doctor §16` ("Auto-cura / propagação")
- Lê a **última** linha (heartbeat, não audita a cadeia) e classifica: OK/NOOP → `pass`; **FAIL →
  `warn`** (torna visível o drift). **WARN, nunca FAIL** — igual §14: um FAIL bloquearia o SOAK por
  um drift possivelmente transitório. Sem ledger → `info` (máquina nova / sem mudança propagável).
- Sanitiza o epoch (`case … *[!0-9]*`) — ledger malformado não aborta o `$(( ))` sob `set -u`.

## Verificação (`tests/v15/test-autocura-ledger.sh` — 6/6, exit 0)

| Caso | Resultado |
|------|-----------|
| **append real** no caminho NOOP (sandbox IdeiaOS-falso, diff só-docs, sem tocar o sistema) | ✅ `|NOOP|` |
| linha do ledger tem 7 campos (formato estável) | ✅ |
| **§16 classifica FAIL → WARN** (run real do doctor, ledger fixture) — falha VISÍVEL | ✅ |
| §16 lê a ÚLTIMA linha (FAIL), ignora a OK anterior (heartbeat = `tail -1`, não `head`) | ✅ |
| §16 mapeia OK e NOOP (anti-teatro de branch faltante) | ✅ |
| `bash -n` · source-headers · readme-sync | ✅ |

O teste exercitou o caminho com **FAIL real** (não só happy-path) — o caso que mais importa em
telemetria de saúde (cf. `antitheater-gate-blind-spot-happy-path`). Achou e corrigiu uma confusão
minha de contagem de campos (eu esperava 8; são 7) antes de fechar.

## Arquivos
- `scripts/propagate-if-changed.sh` (função `propagate_ledger_append` + 3 chamadas OK/FAIL/NOOP)
- `scripts/idea-doctor.sh` (§16 — heartbeat do ledger)
- `tests/v15/test-autocura-ledger.sh` (novo, 6 asserts)
