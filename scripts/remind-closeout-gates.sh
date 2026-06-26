#!/usr/bin/env bash
# =============================================================================
# remind-closeout-gates.sh — LEMBRA (nunca carimba) dos gates de fechamento.
#
# Os 3 gates de fechamento que se esquece de rodar — e o crítico do v15 apontou
# que o ff-merge work->main é a rotina MAIS frequente e mais frágil (mesma classe
# de risco dos selos):
#   1. ff-merge work->main pendente (commit antigo não-merjado)
#   2. selo SOAK velho de milestone ATIVO (não-tagueado)
#   3. frescor de segurança defasado (tier != ok)
#
# PRINCÍPIO (R15-11 / learning automate-the-reminder-not-the-integrity-stamp):
#   este script SÓ LÊ e NOTIFICA. NUNCA executa --record (selo SOAK/frescor) nem
#   --gate. Automatizar o carimbo faria a automação virar um ator sintético e
#   fraudaria a distinção que o gate protege. O humano roda --record/o ff-merge.
#
# Gatilho temporal DETERMINÍSTICO: idade em horas (now - epoch), não "há mais de
# uma sessão". launchd NÃO herda PATH → binários por caminho absoluto.
#
# Exit: sempre 0 (é um lembrete, não um gate — nunca bloqueia nada).
# Override de limiares: REMIND_FF_H (default 24) · REMIND_SOAK_H (default 48).
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT=/usr/bin/git
FF_THRESHOLD_H="${REMIND_FF_H:-24}"
SOAK_THRESHOLD_H="${REMIND_SOAK_H:-48}"
NOW="$(date +%s)"
MSGS=()

# refresh read-only de origin/main (não muta nada local)
"$GIT" -C "$ROOT" fetch origin main --quiet 2>/dev/null || true

# ── 1) ff-merge work->main pendente ──────────────────────────────────────────
if "$GIT" -C "$ROOT" rev-parse --verify --quiet origin/main >/dev/null 2>&1; then
  OLDEST="$("$GIT" -C "$ROOT" log origin/main..work --format=%ct 2>/dev/null | tail -1)"
  if [ -n "${OLDEST:-}" ]; then
    AGE_H=$(( (NOW - OLDEST) / 3600 ))
    if [ "$AGE_H" -ge "$FF_THRESHOLD_H" ]; then
      N="$("$GIT" -C "$ROOT" rev-list --count origin/main..work 2>/dev/null || echo '?')"
      MSGS+=("ff-merge work->main pendente: ${N} commit(s), o mais antigo ha ${AGE_H}h (git push origin work:main)")
    fi
  fi
fi

# ── 2) selo SOAK velho de milestone ATIVO (sem tag) ──────────────────────────
for log in "$ROOT"/.planning/soak/*.log; do
  [ -e "$log" ] || continue
  ms="$(basename "$log" .log)"
  prefix="$(printf '%s' "$ms" | grep -oE '^v[0-9]+' || true)"
  # milestone tagueado (qualquer tag vX.*) = fechado → não lembrar
  if [ -n "$prefix" ] && "$GIT" -C "$ROOT" tag 2>/dev/null | grep -qE "^${prefix}\."; then
    continue
  fi
  last_epoch="$(tail -1 "$log" 2>/dev/null | cut -d'|' -f1)"
  case "${last_epoch:-}" in ''|*[!0-9]*) continue ;; esac
  AGE_H=$(( (NOW - last_epoch) / 3600 ))
  if [ "$AGE_H" -ge "$SOAK_THRESHOLD_H" ]; then
    MSGS+=("SOAK '${ms}' (ativo) sem heartbeat ha ${AGE_H}h - re-grave o selo manualmente")
  fi
done

# ── 3) frescor de seguranca (tier machine-readable) ──────────────────────────
if [ -f "$ROOT/scripts/check-security-freshness.sh" ]; then
  TIER="$(bash "$ROOT/scripts/check-security-freshness.sh" --tier 2>/dev/null | tr -d '[:space:]' || true)"
  case "${TIER:-}" in
    warn|egregious)
      MSGS+=("frescor de seguranca: tier=${TIER} - re-selar (rodar @security-reviewer e gravar o selo)")
      ;;
  esac
fi

# ── Notificar (osascript nativo macOS) + stdout p/ o log do launchd ──────────
COUNT="${#MSGS[@]}"
if [ "$COUNT" -gt 0 ]; then
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${COUNT} pendencia(s) - veja o log\" with title \"IdeiaOS: gates de fechamento\"" >/dev/null 2>&1 || true
  fi
  printf 'IdeiaOS - gates de fechamento pendentes (%s):\n' "$COUNT"
  printf '  - %s\n' "${MSGS[@]}"
else
  echo "IdeiaOS: nenhum gate de fechamento pendente."
fi
exit 0
