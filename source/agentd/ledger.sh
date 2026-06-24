#!/bin/bash
# ledger.sh — ledger de auditoria hash-chained append-only LOCAL (v14.4 · B6 / R-WP9).
#
# Decisão ACEITA (docs/decisions/v14.4-command-ref-origin-exposure.md, Q5):
#   • a auditoria autoritativa do "quem-o-quê-quando(-para-quem)" vive SÓ no ledger LOCAL —
#     NUNCA no `origin`/GitHub (o ref é espelho efêmero de transporte, não registro de auditoria);
#   • não-repúdio com DETECÇÃO DE REESCRITA: cada entrada carrega prev_hash = sha256 da
#     LINHA-ENTRADA anterior INTEIRA (incluindo o prev_hash dela) → editar/remover/reordenar
#     QUALQUER entrada, ou adulterar um prev_hash gravado, quebra a cadeia em `verify`.
#   • a genesis usa prev_hash = 64 zeros (âncora determinística da cadeia).
#
# Formato de LINHA (determinístico, campos separados por '|', sem newline interno):
#   prev_hash|subject|role|action|ref|scope|result|signature
# '|' e control-chars nos campos são REJEITADOS (exit 2 REASON=bad-field) — senão um campo
# com '|' embutido redesenharia as fronteiras de coluna e forjaria/ocultaria entradas.
#
# antifragile-gates: o veredito de integridade é o EXIT-CODE de `verify`, nunca a leitura humana.
# credential-isolation: NENHUM valor de segredo entra aqui — a `signature` é uma assinatura
#   destacada (artefato público, não a chave); NENHUMA chamada a provedor externo.
#
# Store local override por env (para testes): IDEIAOS_LEDGER_STORE
#
# Uso:
#   ledger.sh append <subject> <role> <action> <ref> <scope> <result> [signature]
#   ledger.sh verify
#   ledger.sh print
#
# Exit-codes:
#   0  sucesso (append gravado / cadeia íntegra / print)
#   2  erro de invocação OU campo inválido ('|'/control-char) — REASON=usage | REASON=bad-field
#   3  cadeia quebrada (entrada editada/removida/reordenada ou prev_hash adulterado) — REASON=chain-broken
set -uo pipefail
umask 077   # entradas de auditoria nunca legíveis por outros (defesa-em-profundidade)

GENESIS="0000000000000000000000000000000000000000000000000000000000000000"
STORE="${IDEIAOS_LEDGER_STORE:-$HOME/.ideiaos/cockpit/ledger}"

_ensure_store() { mkdir -p "$(dirname "$STORE")" 2>/dev/null || true; [ -f "$STORE" ] || : > "$STORE"; chmod 600 "$STORE" 2>/dev/null || true; }

# sha256 dos BYTES exatos passados em $1 (sem newline final — printf '%s'). Determinístico.
_sha() { printf '%s' "$1" | shasum -a 256 | awk '{print $1}'; }

# _reject_bad_field <valor> — exit 2 REASON=bad-field se contém '|' ou QUALQUER control-char
# (newline, tab, CR, etc.). Mantém o invariante "1 entrada = 1 linha, N colunas".
_reject_bad_field() {
  case "$1" in
    *'|'*) echo "REASON=bad-field (separador '|' embutido)" >&2; exit 2 ;;
  esac
  # control-chars: remove tudo que NÃO seja printável; se sobrou diferença, havia control-char.
  local stripped; stripped=$(printf '%s' "$1" | LC_ALL=C tr -d '[:cntrl:]')
  if [ "$stripped" != "$1" ]; then
    echo "REASON=bad-field (control-char embutido)" >&2; exit 2
  fi
}

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  append) # append <subject> <role> <action> <ref> <scope> <result> [signature]
    subject="${1:?}"; role="${2:?}"; action="${3:?}"; ref="${4:?}"; scope="${5:?}"; result="${6:?}"
    signature="${7:-}"
    _reject_bad_field "$subject"; _reject_bad_field "$role"; _reject_bad_field "$action"
    _reject_bad_field "$ref";     _reject_bad_field "$scope"; _reject_bad_field "$result"
    _reject_bad_field "$signature"
    _ensure_store
    # prev_hash = sha256 da ÚLTIMA linha-entrada INTEIRA; genesis (store vazio) → 64 zeros.
    last=$(tail -n 1 "$STORE" 2>/dev/null)
    if [ -z "$last" ]; then prev="$GENESIS"; else prev=$(_sha "$last"); fi
    line="$prev|$subject|$role|$action|$ref|$scope|$result|$signature"
    # escrita atômica: monta o novo conteúdo em .tmp e promove com mv -f (append durável).
    tmp="$STORE.tmp.$$"
    { cat "$STORE" 2>/dev/null; printf '%s\n' "$line"; } > "$tmp" || { rm -f "$tmp"; echo "REASON=write-failed" >&2; exit 2; }
    mv -f "$tmp" "$STORE" || { rm -f "$tmp"; echo "REASON=write-failed" >&2; exit 2; }
    chmod 600 "$STORE" 2>/dev/null || true
    exit 0
    ;;

  verify) # re-encadeia do início: o prev_hash gravado em cada linha DEVE casar o sha256 da anterior.
    _ensure_store
    expected="$GENESIS"
    n=0
    # lê linha-a-linha PRESERVANDO bytes (IFS vazio + read -r); não pula linha final sem \n.
    while IFS= read -r line || [ -n "$line" ]; do
      n=$((n+1))
      got=$(printf '%s' "$line" | cut -d'|' -f1)
      if [ "$got" != "$expected" ]; then
        echo "REASON=chain-broken (entrada #$n: prev_hash gravado != sha256 da anterior)" >&2; exit 3
      fi
      # próximo elo esperado = sha256 desta linha-entrada INTEIRA
      expected=$(_sha "$line")
    done < "$STORE"
    exit 0
    ;;

  print) # ecoa as entradas SEM expor a signature por inteiro (só um prefixo curto — artefato sensível).
    _ensure_store
    while IFS='|' read -r prev subject role action ref scope result signature || [ -n "$prev" ]; do
      [ -z "$prev" ] && continue
      sigshort=""
      [ -n "$signature" ] && sigshort="$(printf '%s' "$signature" | cut -c1-8)…"
      printf 'subject=%s role=%s action=%s ref=%s scope=%s result=%s sig=%s\n' \
        "$subject" "$role" "$action" "$ref" "$scope" "$result" "$sigshort"
    done < "$STORE"
    exit 0
    ;;

  *)
    echo "uso: ledger.sh {append <subject> <role> <action> <ref> <scope> <result> [signature]|verify|print}" >&2
    exit 2
    ;;
esac
