#!/bin/bash
# ack.sh — ACK idempotente LOCAL com high-water mark (v14.4 · B7 · R-WP8: efeito único em reentrega).
#
# Decisão-fonte: docs/decisions/v14.4-command-ref-origin-exposure.md (Q5, ACEITO 2026-06-24) —
#   "o bundle mantém um HIGH-WATER MARK de ACKs recebidos: só entradas com ACK saem do bundle; um
#    alvo offline por >1 janela ainda encontra sua entrada selada pendente. Sem isso, force-update
#    poderia sobrescrever um comando antes da coleta." A origem NUNCA mostra FEITO sem ACK idempotente
#    (R-WP8) — comando reentregue (squash/force-update repetido) tem EFEITO ÚNICO no alvo.
#
# Idempotência por INPUT_HASH = sha256 dos BYTES do command-file (MESMO binding do step-up O2 —
#   stepup-token.sh:54). O registro de aplicados é DURÁVEL cross-processo (store local 0600, NÃO
#   in-memory): uma 2ª invocação em processo SEPARADO enxerga o que a 1ª gravou. Marcar 2× o mesmo
#   hash NÃO duplica o efeito — a 2ª detecta já-aplicado (noclobber/create-once) e é no-op de efeito.
#
# Store local override por env (para testes): IDEIAOS_ACK_STORE (default $HOME/.ideiaos/cockpit/acks).
#   NUNCA no working tree (fora do alcance do git add -A do autosync, igual aos demais stores B0–B4).
#
# credential-isolation: NENHUM segredo/valor entra aqui — só o input_hash (sha256, metadado opaco).
#   ZERO chamada a provedor externo (curl/supabase/api) — só FS local + shasum.
# antifragile-gates: o veredito é o EXIT-CODE.
#
# Uso:
#   ack.sh hash-of <command-file>   — emite sha256 dos BYTES do command-file (stdout)
#   ack.sh mark-applied <input_hash> — registra como aplicado (atômico/create-once); high-water mark
#   ack.sh is-applied  <input_hash> — exit 0 se já aplicado; exit 3 se inédito
#
# Exit-codes:
#   0  sucesso (hash emitido / marcado / já-aplicado)
#   2  erro de invocação (subcomando/arg inválido, command-file ausente, hash malformado)
#   3  is-applied: hash inédito (REASON=not-applied)
#   4  mark-applied: store durável não-gravável (REASON=ack-store-unwritable — fail-closed: sem
#      registro persistente, NÃO pode declarar efeito-único; melhor recusar que perder a idempotência)
set -uo pipefail
umask 077   # arquivos deste processo nunca legíveis por outros (defesa-em-profundidade)

STORE="${IDEIAOS_ACK_STORE:-$HOME/.ideiaos/cockpit/acks}"

# _ensure_store — store é um DIRETÓRIO: 1 arquivo-marca por input_hash (granular, sem reescrever
# linha — evita corrida de write-the-whole-file que um store mono-arquivo teria sob concorrência).
_ensure_store() {
  mkdir -p "$STORE" 2>/dev/null || return 1
  chmod 700 "$STORE" 2>/dev/null || true
  [ -d "$STORE" ] && [ -w "$STORE" ]
}

# _valid_hash — input_hash DEVE ser sha256 hex (64 chars [0-9a-f]); rejeita path-traversal/control-char
# que poluiria o nome de arquivo da marca (defesa contra ../, espaço, etc.).
_valid_hash() {
  case "$1" in
    *[!0-9a-f]*) return 1 ;;
    ????????????????????????????????????????????????????????????????) return 0 ;;  # exatamente 64
    *) return 1 ;;
  esac
}

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  hash-of) # hash-of <command-file> — sha256 dos BYTES (mesmo padrão do stepup-token.sh:54)
    cf="${1:-}"
    [ -n "$cf" ] || { echo "REASON=usage (hash-of: command-file ausente)" >&2; exit 2; }
    [ -s "$cf" ] || { echo "REASON=usage (command-file vazio/inexistente)" >&2; exit 2; }
    h=$(shasum -a 256 "$cf" 2>/dev/null | awk '{print $1}')
    [ -n "$h" ] || { echo "REASON=hash-failed" >&2; exit 2; }
    printf '%s\n' "$h"
    ;;

  mark-applied) # mark-applied <input_hash> — registra atômico/create-once; idempotente; high-water mark
    h="${1:-}"
    [ -n "$h" ] || { echo "REASON=usage (mark-applied: input_hash ausente)" >&2; exit 2; }
    _valid_hash "$h" || { echo "REASON=bad-hash (sha256 hex de 64 chars esperado)" >&2; exit 2; }
    _ensure_store || { echo "REASON=ack-store-unwritable" >&2; exit 4; }

    marker="$STORE/$h"
    if [ -e "$marker" ]; then
      # JÁ aplicado: 2ª (ou n-ésima) entrega do MESMO comando → NO-OP de efeito (idempotência real).
      # high-water mark: este hash já saiu do conjunto pendente; não duplica nada.
      exit 0
    fi
    # 1ª aplicação: create-once ATÔMICO (noclobber) — fecha a corrida de duas invocações simultâneas
    # do mesmo hash (só uma cria o marker; a outra cai no já-aplicado acima ou no fallback abaixo).
    if ! ( set -o noclobber; : > "$marker" ) 2>/dev/null; then
      # noclobber falhou: ou corrida (outro processo criou agora — idempotente OK) ou store RO.
      if [ -e "$marker" ]; then exit 0; fi   # corrida benigna: o marker EXISTE → efeito já contado
      echo "REASON=ack-store-unwritable" >&2; exit 4
    fi
    chmod 600 "$marker" 2>/dev/null || true

    # soft-dependency OPCIONAL com B6 (ledger hash-chained, R-WP9): best-effort APENAS na 1ª aplicação.
    # A idempotência NÃO depende disto — falha de ledger NUNCA quebra o ACK (já registrado acima).
    # debt: quando source/agentd/ledger.sh existir (B6), trocar o no-op pelo append real
    #   `bash "$HERE/ledger.sh" append ...`. Hoje a lib não existe → guarda de existência + silêncio.
    if [ -n "${IDEIAOS_LEDGER_STORE:-}" ]; then
      HERE="$(cd "$(dirname "$0")" && pwd)"
      if [ -x "$HERE/ledger.sh" ] || [ -f "$HERE/ledger.sh" ]; then
        bash "$HERE/ledger.sh" append "ack-applied:$h" >/dev/null 2>&1 || true   # best-effort, nunca bloqueia
      fi
    fi
    exit 0
    ;;

  is-applied) # is-applied <input_hash> — exit 0 se já aplicado; exit 3 REASON=not-applied se inédito
    h="${1:-}"
    [ -n "$h" ] || { echo "REASON=usage (is-applied: input_hash ausente)" >&2; exit 2; }
    _valid_hash "$h" || { echo "REASON=bad-hash (sha256 hex de 64 chars esperado)" >&2; exit 2; }
    _ensure_store || { echo "REASON=ack-store-unwritable" >&2; exit 4; }
    if [ -e "$STORE/$h" ]; then exit 0; fi
    echo "REASON=not-applied" >&2; exit 3
    ;;

  *)
    echo "uso: ack.sh {hash-of <command-file>|mark-applied <input_hash>|is-applied <input_hash>}" >&2
    exit 2
    ;;
esac
