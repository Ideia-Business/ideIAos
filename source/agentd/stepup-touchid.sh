#!/bin/bash
# stepup-touchid.sh — ATALHO local opcional de presença via Touch ID (v14.4 · B3, HYBRID).
#
# Decisão: v14.4-step-up-without-relying-party.md — Touch ID é o ATALHO LOCAL (offline, sem rede)
# ONDE O HARDWARE EXISTIR; o email-OTP é o caminho PRIMÁRIO e UNIVERSAL. A AUSÊNCIA de Touch ID
# NUNCA bloqueia — apenas cai no email-OTP. Por isso `available` é uma sonda graciosa.
#
# O prompt biométrico real (LocalAuthentication via agentd) é fiado em F0b nos hosts capazes; aqui,
# F0a só prova a SONDA graciosa (a frota heterogênea não pode depender do sensor).
#
# Uso:
#   stepup-touchid.sh available   exit 0 = Touch ID plausivelmente disponível · exit 1 = indisponível (→ email-OTP)
# antifragile-gates: veredito = EXIT-CODE; jamais interativo aqui.
set -uo pipefail

case "${1:-}" in
  available)
    # macOS: bioutil reporta o estado da biometria. Override de teste: IDEIAOS_TOUCHID_FORCE=0|1.
    if [ -n "${IDEIAOS_TOUCHID_FORCE:-}" ]; then
      [ "$IDEIAOS_TOUCHID_FORCE" = "1" ] && { echo "OK touchid (forçado)"; exit 0; }
      echo "REASON=touchid-unavailable (forçado) — usar email-OTP" >&2; exit 1
    fi
    if command -v bioutil >/dev/null 2>&1 && bioutil -r 2>/dev/null | grep -qiE 'Touch ID|biometrics functionality: 1'; then
      echo "OK touchid disponível (atalho local)"; exit 0
    fi
    echo "REASON=touchid-unavailable — caminho universal é email-OTP" >&2; exit 1
    ;;
  *)
    echo "uso: stepup-touchid.sh available" >&2; exit 2
    ;;
esac
