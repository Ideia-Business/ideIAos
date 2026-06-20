#!/usr/bin/env bash
# SOURCE: IdeiaOS v13
# =============================================================================
# check-security-freshness.sh — Selo de Frescor de Segurança (v13)
#
# Princípio: segurança verificada PERIODICAMENTE e por sistema, não só sob
# demanda. Rigor PROPORCIONAL = (risco da superfície tocada) × (idade da última
# revisão). Nunca gateia PR de feature; gateia o TAG (IdeiaOS) no tier egrégio
# e AVISA (idea-doctor §14) em todos os sistemas.
#
# É o padrão SOAK (check-soak.sh) aplicado a DÍVIDA DE SEGURANÇA:
#   gatilho DETERMINÍSTICO (git diff + path-globs + score + idade → tier)
#   → revisão por @security-reviewer (JULGAMENTO, fora deste script)
#   → re-selo DETERMINÍSTICO (--record grava no ledger).
# O git decide SE ESTÁ NA HORA; o agente REVISA; o ledger PROVA.
#
# Ledger (append-only, por repo): .security/review-ledger.log
#   formato por linha:  <epoch>|<iso>|<commit>|<revisor>|<veredito>|<escopo>
#
# Política (defaults abaixo; override por env; ou .security/policy.sh sourced):
#   SECFRESH_WARN_SCORE=10   SECFRESH_EGREGIOUS_SCORE=20
#   SECFRESH_WARN_DAYS=90    SECFRESH_EGREGIOUS_DAYS=180   SECFRESH_CRIT_DAYS=30
#   SECFRESH_GATE_ENABLED=0  (1º ciclo advisory — só vira gate quando =1, R13-07)
#   SECFRESH_CRITICAL_GLOBS / SECFRESH_SENSITIVE_GLOBS (space-separated)
#
# USO:
#   check-security-freshness.sh                 # relatório legível (exit 0)
#   check-security-freshness.sh --tier          # imprime só o token: ok|warn|egregious|unbootstrapped
#   check-security-freshness.sh --status         # ledger + estado computado
#   check-security-freshness.sh --bootstrap      # grava selo-baseline no HEAD (dia-1 = score 0)
#   check-security-freshness.sh --record [verdito] [revisor]   # re-sela no HEAD após revisão
#   check-security-freshness.sh --gate           # exit 1 SE egrégio E gate ligado (tag-gate, R13-05)
#
# Exit: 0 = ok/advisory · 1 = egrégio com gate ligado (--gate) · 2 = erro de invocação
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEC_DIR="$ROOT/.security"
LEDGER="$SEC_DIR/review-ledger.log"

# ── Política (defaults) ──────────────────────────────────────────────────────
WARN_SCORE="${SECFRESH_WARN_SCORE:-10}"
EGREGIOUS_SCORE="${SECFRESH_EGREGIOUS_SCORE:-20}"
WARN_DAYS="${SECFRESH_WARN_DAYS:-90}"
EGREGIOUS_DAYS="${SECFRESH_EGREGIOUS_DAYS:-180}"
CRIT_DAYS="${SECFRESH_CRIT_DAYS:-30}"
GATE_ENABLED="${SECFRESH_GATE_ENABLED:-0}"

# Path-globs por superfície (peso). Override via env ou .security/policy.sh.
# bash [[ == glob ]] não é pathname-aware: '*/auth/*' casa 'src/x/auth/y.ts'.
CRITICAL_GLOBS="${SECFRESH_CRITICAL_GLOBS:-*/auth/* auth/* *Auth.* *migration* */migrations/* *rls* */rls/* .env .env.* */.env */.env.* *credential* *secret* */integrations/* */ai/* */llm/* */security/* security/* *enforce* */supabase/migrations/*}"
SENSITIVE_GLOBS="${SECFRESH_SENSITIVE_GLOBS:-*/api/* api/* package-lock.json */package-lock.json pnpm-lock.yaml yarn.lock */middleware/* *.sql */functions/* */server/*}"

# Override opcional por repo (tunagem sem editar o script)
[ -f "$SEC_DIR/policy.sh" ] && . "$SEC_DIR/policy.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

MODE="${1:-}"
HOST="$(hostname -s 2>/dev/null || echo host)"
NOW_EPOCH="$(date +%s)"
NOW_ISO="$(date '+%Y-%m-%dT%H:%M:%S')"
HEAD_SHA="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"

# ── helpers de ledger ────────────────────────────────────────────────────────
last_field() { # $1 = nº do campo
  [ -f "$LEDGER" ] || return 1
  tail -n1 "$LEDGER" 2>/dev/null | awk -F'|' -v n="$1" '{print $n}'
}
last_commit() { last_field 3; }
last_epoch()  { last_field 1; }

# peso de um path (3 crítico / 1 sensível / 0 neutro)
weight_of() {
  local f="$1" g
  for g in $CRITICAL_GLOBS;  do [[ "$f" == $g ]] && { echo 3; return; }; done
  for g in $SENSITIVE_GLOBS; do [[ "$f" == $g ]] && { echo 1; return; }; done
  echo 0
}

# score ponderado desde <base>..HEAD → imprime "total crit_flag changed_files"
score_since() {
  local base="$1" total=0 crit=0 nfiles=0 f w
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    nfiles=$((nfiles + 1))
    w="$(weight_of "$f")"
    total=$((total + w))
    [ "$w" -eq 3 ] && crit=1
  done < <(git -C "$ROOT" diff --name-only "$base"..HEAD 2>/dev/null)
  echo "$total $crit $nfiles"
}

# tier a partir de score, crit, idade(dias)
compute_tier() { # $1=score $2=crit $3=age_days
  local s="$1" c="$2" age="$3"
  if [ "$s" -ge "$EGREGIOUS_SCORE" ] || [ "$age" -ge "$EGREGIOUS_DAYS" ]; then echo egregious; return; fi
  if [ "$s" -ge "$WARN_SCORE" ] || [ "$age" -ge "$WARN_DAYS" ] || { [ "$c" -eq 1 ] && [ "$age" -ge "$CRIT_DAYS" ]; }; then echo warn; return; fi
  echo ok
}

# avalia o estado atual → exporta TIER, SCORE, CRIT, AGE_DAYS, BASE
evaluate() {
  if [ ! -f "$LEDGER" ]; then TIER="unbootstrapped"; SCORE=0; CRIT=0; AGE_DAYS=0; BASE=""; return; fi
  BASE="$(last_commit)"; [ -n "$BASE" ] || BASE="$(git -C "$ROOT" rev-list --max-parents=0 HEAD 2>/dev/null | tail -1)"
  local le; le="$(last_epoch)"; [ -n "$le" ] || le="$NOW_EPOCH"
  AGE_DAYS=$(( (NOW_EPOCH - le) / 86400 ))
  read -r SCORE CRIT _NF <<<"$(score_since "$BASE")"
  TIER="$(compute_tier "$SCORE" "$CRIT" "$AGE_DAYS")"
}

# ── --tier (machine-readable p/ idea-doctor §14) ─────────────────────────────
if [ "$MODE" = "--tier" ]; then
  evaluate; echo "$TIER"; exit 0
fi

# ── --status ─────────────────────────────────────────────────────────────────
if [ "$MODE" = "--status" ]; then
  echo -e "\n${CYAN}${BOLD}━━━ Security Freshness: status ━━━${NC}"
  if [ ! -f "$LEDGER" ]; then warn "sem ledger ($LEDGER) — rode --bootstrap"; exit 0; fi
  info "ledger: $LEDGER"
  awk -F'|' '{printf "    %s  %-14s  %-7s  %s\n", $2, $4, $5, $6}' "$LEDGER"
  evaluate
  echo -e "  desde o último selo ($BASE..HEAD): score ${BOLD}$SCORE${NC} (crit=$CRIT) · idade ${BOLD}${AGE_DAYS}d${NC} · tier ${BOLD}$TIER${NC}"
  echo -e "  limiares: WARN score≥$WARN_SCORE|idade≥${WARN_DAYS}d · EGRÉGIO score≥$EGREGIOUS_SCORE|idade≥${EGREGIOUS_DAYS}d · gate=$( [ "$GATE_ENABLED" = 1 ] && echo LIGADO || echo advisory )"
  exit 0
fi

# ── --bootstrap (selo-baseline no HEAD; dia-1 = score 0) ─────────────────────
if [ "$MODE" = "--bootstrap" ]; then
  if [ -s "$LEDGER" ]; then info "ledger já existe ($LEDGER) — bootstrap idempotente, nada a fazer."; exit 0; fi
  mkdir -p "$SEC_DIR"
  printf '%s|%s|%s|bootstrap|BASELINE|baseline @ %s (sem revisão — marca o ponto de partida)\n' \
    "$NOW_EPOCH" "$NOW_ISO" "$HEAD_SHA" "$HEAD_SHA" >> "$LEDGER"
  ok "selo-baseline gravado em $LEDGER (HEAD $HEAD_SHA) — contador começa em 0"
  exit 0
fi

# ── --record (re-selo após revisão por @security-reviewer) ───────────────────
if [ "$MODE" = "--record" ]; then
  VERDICT="${2:-PASS}"; REVIEWER="${3:-${USER:-manual}}"
  mkdir -p "$SEC_DIR"
  BASE="$(last_commit)"; [ -n "$BASE" ] || BASE="(início)"
  printf '%s|%s|%s|%s|%s|revisão %s..HEAD\n' \
    "$NOW_EPOCH" "$NOW_ISO" "$HEAD_SHA" "$REVIEWER" "$VERDICT" "$BASE" >> "$LEDGER"
  ok "selo gravado: HEAD $HEAD_SHA · revisor=$REVIEWER · veredito=$VERDICT (zera o contador)"
  info "commite o ledger para compartilhar o frescor entre máquinas (autosync empurra)."
  exit 0
fi

# ── --gate (tag-gate, R13-05/R13-07) ─────────────────────────────────────────
if [ "$MODE" = "--gate" ]; then
  evaluate
  echo -e "\n${CYAN}${BOLD}━━━ Security Freshness gate ━━━${NC}"
  info "tier=$TIER · score=$SCORE (crit=$CRIT) · idade=${AGE_DAYS}d · gate=$( [ "$GATE_ENABLED" = 1 ] && echo LIGADO || echo advisory )"
  if [ "$TIER" = "egregious" ]; then
    if [ "$GATE_ENABLED" = 1 ]; then
      err "segurança DEFASADA (egrégio) — NÃO tague. Rode @security-reviewer no diff e: check-security-freshness.sh --record"
      exit 1
    fi
    warn "egrégio, mas gate em modo ADVISORY (1º ciclo). NÃO bloqueia ainda — revise assim que puder."
    exit 0
  fi
  ok "frescor de segurança aceitável (tier=$TIER) — sem bloqueio."
  exit 0
fi

# ── default: relatório legível ───────────────────────────────────────────────
if [ -n "$MODE" ]; then echo "uso: check-security-freshness.sh [--tier|--status|--bootstrap|--record|--gate]" >&2; exit 2; fi
evaluate
echo -e "\n${CYAN}${BOLD}━━━ Security Freshness ━━━${NC}"
case "$TIER" in
  unbootstrapped) warn "não-bootstrapado — rode: bash scripts/check-security-freshness.sh --bootstrap" ;;
  ok)        ok   "fresco — score $SCORE (crit=$CRIT) · idade ${AGE_DAYS}d desde o último selo" ;;
  warn)      warn "DEFASADO — score $SCORE (crit=$CRIT) · idade ${AGE_DAYS}d. Rode @security-reviewer no diff e --record." ;;
  egregious) err  "EGRÉGIO — score $SCORE (crit=$CRIT) · idade ${AGE_DAYS}d. Revisão de segurança em atraso." ;;
esac
exit 0
