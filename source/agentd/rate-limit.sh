#!/bin/bash
# rate-limit.sh — throttle determinístico por (ref+subject) do write-path do Cockpit (v14.4 · B8 · R-WP12).
#
# Decisão (docs/decisions/v14.4-command-ref-origin-exposure.md — Q5, "substrato LOCAL: ... rate-limit"):
#   rate-limit é defesa SECUNDÁRIA contra FLOOD. NUNCA autoriza nada sozinho — a autorização é a
#   assinatura por-máquina (verify-payload, R-WP1/R-WP2), verificada ANTES no pipeline. Este gate só
#   NEGA (recusa o excesso); jamais CONCEDE. Passar no `check` é condição necessária, nunca suficiente.
#
# DETERMINISMO (testável sem sleep/relógio real):
#   • "agora" = IDEIAOS_RL_NOW (epoch) se setado, senão `date +%s`.
#   • janela fixa de W segundos (IDEIAOS_RL_WINDOW, default 60); bucket = floor(now / W).
#   • contador durável por chave = sha256(ref \x1f subject \x1f bucket). Avançar `now` p/ o bucket
#     seguinte gera OUTRA chave → contador zera (janela reseta) sem mexer no store.
#   • threshold = IDEIAOS_RL_MAX (default 5): o (MAX+1)-ésimo check da MESMA janela é recusado.
#
# Store durável LOCAL com override por env (p/ teste): IDEIAOS_RATELIMIT_STORE
#   (default $HOME/.ideiaos/cockpit/ratelimit). NUNCA no working tree. chmod 600.
#
# credential-isolation: NENHUM segredo entra/sai; o subject é metadado (email), não credencial.
#   ZERO chamada a provedor externo (sem curl/supabase/api) — defesa local, determinística.
# antifragile-gates: o veredito é o EXIT-CODE.
#
# Uso:
#   rate-limit.sh check <ref> <subject>
#       exit 0 = dentro do threshold (NÃO autoriza — só não-nega)
#       exit 3 REASON=rate-limited = excedeu o threshold na janela atual
#
# Exit-codes:
#   0  dentro do threshold (passa o throttle; a autorização segue sendo verify-payload)
#   2  erro de invocação (subcomando/args inválidos)
#   3  rate-limited (flood: excedeu MAX na janela corrente)
#   4  store não-gravável (FAIL-CLOSED: sem poder contar, não deixa passar o flood)
set -uo pipefail

STORE="${IDEIAOS_RATELIMIT_STORE:-$HOME/.ideiaos/cockpit/ratelimit}"
RL_MAX="${IDEIAOS_RL_MAX:-5}"
RL_WINDOW="${IDEIAOS_RL_WINDOW:-60}"

_ensure_store() { mkdir -p "$STORE" 2>/dev/null || { echo "REASON=store-unwritable" >&2; return 1; }; chmod 700 "$STORE" 2>/dev/null || true; }

# _now — epoch determinístico (override por env p/ teste), senão relógio real.
_now() {
  if [ -n "${IDEIAOS_RL_NOW:-}" ]; then printf '%s\n' "$IDEIAOS_RL_NOW"; else date +%s; fi
}

# _key <ref> <subject> <bucket> — chave durável opaca = sha256(ref \x1f subject \x1f bucket).
#   \x1f (US) como delimitador: evita colisão ref="a"+subject="bc" vs ref="ab"+subject="c".
_key() {
  printf '%s\037%s\037%s' "$1" "$2" "$3" | shasum -a 256 | awk '{print $1}'
}

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  check) # check <ref> <subject> — incrementa o contador da janela atual; recusa se exceder MAX.
    ref="${1:-}"; subject="${2:-}"
    # args obrigatórios → exit 2 (invocação), nunca o exit 1 default de ${VAR:?} (mantém o contrato)
    [ -n "$ref" ] || { echo "REASON=usage (ref ausente) — uso: rate-limit.sh check <ref> <subject>" >&2; exit 2; }
    [ -n "$subject" ] || { echo "REASON=usage (subject ausente) — uso: rate-limit.sh check <ref> <subject>" >&2; exit 2; }

    # MAX/WINDOW têm que ser inteiros positivos (env malformado não deve abrir o portão silenciosamente)
    case "$RL_MAX" in (*[!0-9]*|'') echo "REASON=bad-max ($RL_MAX)" >&2; exit 2;; esac
    case "$RL_WINDOW" in (*[!0-9]*|''|0) echo "REASON=bad-window ($RL_WINDOW)" >&2; exit 2;; esac

    _ensure_store || exit 4

    now=$(_now)
    case "$now" in (*[!0-9]*|'') echo "REASON=bad-now ($now)" >&2; exit 2;; esac
    bucket=$(( now / RL_WINDOW ))

    key=$(_key "$ref" "$subject" "$bucket")
    [ -n "$key" ] || { echo "REASON=key-failed" >&2; exit 4; }
    counter="$STORE/$key"

    # leitura do count atual (ausente=0; corrompido=0 p/ não travar por ruído — defesa SECUNDÁRIA)
    cur=0
    if [ -f "$counter" ]; then
      cur=$(head -1 "$counter" 2>/dev/null)
      case "$cur" in (*[!0-9]*|'') cur=0;; esac
    fi
    new=$(( cur + 1 ))

    # persiste o novo count ATOMICAMENTE (.tmp.$$ + mv -f). FAIL-CLOSED: se não persistir, não deixa
    # passar o flood (sem o registro, o próximo check não veria este → bypass do throttle).
    tmp="$counter.tmp.$$"
    if ! printf '%s\n' "$new" > "$tmp" 2>/dev/null; then
      rm -f "$tmp" 2>/dev/null || true; echo "REASON=store-unwritable" >&2; exit 4
    fi
    if ! mv -f "$tmp" "$counter" 2>/dev/null; then
      rm -f "$tmp" 2>/dev/null || true; echo "REASON=store-unwritable" >&2; exit 4
    fi
    chmod 600 "$counter" 2>/dev/null || true

    # veredito: o (MAX+1)-ésimo (new > MAX) é o flood → recusa. Os MAX primeiros passam.
    if [ "$new" -gt "$RL_MAX" ]; then
      echo "REASON=rate-limited (ref=$ref subject=$subject count=$new>max=$RL_MAX window=${RL_WINDOW}s)" >&2
      exit 3
    fi
    # NÃO imprime nada autorizador — passar aqui é só "não-negado". A autorização é verify-payload.
    exit 0
    ;;
  *)
    echo "uso: rate-limit.sh check <ref> <subject>" >&2
    exit 2
    ;;
esac
