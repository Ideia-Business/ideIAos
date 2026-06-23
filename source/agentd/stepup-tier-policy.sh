#!/bin/bash
# stepup-tier-policy.sh — política tier × remember-device × O4 (v14.4 · B3 / S-05).
#
# Decisão: v14.4-step-up-without-relying-party.md (matriz tier × fator). Pura, LOCAL, sem rede —
# o veredito é o EXIT-CODE (antifragile-gates). Regras:
#   • remember-device (pular OTP) SÓ no tier `sensível`, SAME-MACHINE, janela ≤7d; token bind a
#     max_tier=sensível. `alto`/`crítico`/`deploy` → OTP TODA VEZ (nunca pula).
#   • O4 (aprovação out-of-band) SEMPRE no `crítico` e `deploy`.
#
# Uso:
#   stepup-tier-policy.sh skip-allowed <tier> <same_machine:0|1> <age_days>
#       exit 0 = OTP pode ser PULADO (remember-device válido) · exit 1 = OTP OBRIGATÓRIO
#   stepup-tier-policy.sh o4-required <tier>      exit 0 = O4 sempre exigido · exit 1 = não
#   stepup-tier-policy.sh max-tier-for-skip       imprime o tier-teto de skip (sensível)
set -uo pipefail

REMEMBER_WINDOW_DAYS="${IDEIAOS_REMEMBER_WINDOW_DAYS:-7}"
cmd="${1:-}"; shift 2>/dev/null || true

case "$cmd" in
  skip-allowed)
    tier="${1:?tier}"; same="${2:?same_machine 0|1}"; age="${3:?age_days}"
    case "$tier" in
      sensível|sensivel)
        if [ "$same" != "1" ]; then echo "REASON=skip-denied (não same-machine)" >&2; exit 1; fi
        case "$age" in (*[!0-9]*|'') echo "REASON=skip-denied (age inválido)" >&2; exit 1;; esac
        if [ "$age" -gt "$REMEMBER_WINDOW_DAYS" ]; then echo "REASON=skip-denied (janela > ${REMEMBER_WINDOW_DAYS}d)" >&2; exit 1; fi
        echo "OK skip-allowed tier=sensível same=1 age=${age}d<=${REMEMBER_WINDOW_DAYS}d"; exit 0
        ;;
      alto|crítico|critico|deploy)
        echo "REASON=skip-denied (tier=$tier exige OTP toda vez)" >&2; exit 1
        ;;
      *) echo "REASON=skip-denied (tier desconhecido=$tier)" >&2; exit 1;;
    esac
    ;;
  o4-required)
    tier="${1:?tier}"
    case "$tier" in
      crítico|critico|deploy) echo "OK o4-required tier=$tier"; exit 0;;
      *) echo "REASON=o4-not-required tier=$tier" >&2; exit 1;;
    esac
    ;;
  max-tier-for-skip) echo "sensível";;
  *)
    echo "uso: stepup-tier-policy.sh {skip-allowed <tier> <same 0|1> <age_days>|o4-required <tier>|max-tier-for-skip}" >&2
    exit 2
    ;;
esac
