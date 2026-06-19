#!/usr/bin/env bash
# SOURCE: IdeiaOS v11
# =============================================================================
# check-soak.sh — SOAK gate de fechamento de milestone (NASA #4)
#
# Princípio: nenhum milestone é declarado DONE/tag até "soakar" — passar
# idea-doctor (0 FAIL) + suíte de regressão estrutural em ≥2 máquinas distintas
# por ≥1 dia. Barreira ativa contra "velocidade > durabilidade": um milestone
# que parece pronto numa máquina pode quebrar noutra (drift de install global,
# diferença de SO, autosync). O soak dá tempo+diversidade antes de cravar a tag.
#
# Ledger (append-only, commitado em work): .planning/soak/<milestone>.log
#   formato por linha:  <epoch>|<iso>|<hostname>|idea_doctor=PASS|regression=PASS|<commit>
#
# Política (override por env): SOAK_MIN_MACHINES=2  SOAK_MIN_DAYS=1
#
# USO:
#   bash scripts/check-soak.sh <milestone>            # verifica (exit 0=soaked, 1=ainda não)
#   bash scripts/check-soak.sh <milestone> --record   # roda os gates; se PASS, grava heartbeat desta máquina
#   bash scripts/check-soak.sh <milestone> --status    # resumo do ledger
#
# Exit: 0 = soak satisfeito (no verify) / heartbeat gravado (no record) ·
#       1 = soak não satisfeito / gate local falhou · 2 = erro de invocação
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOAK_DIR="$ROOT/.planning/soak"
MIN_MACHINES="${SOAK_MIN_MACHINES:-2}"
MIN_DAYS="${SOAK_MIN_DAYS:-1}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

MILESTONE="${1:-}"
MODE="${2:-}"
[ -n "$MILESTONE" ] || { echo "uso: check-soak.sh <milestone> [--record|--status]" >&2; exit 2; }
# normaliza: aceita 'v11' ou 'v11-arsenal' etc — usa o token como nome de arquivo
MILESTONE="$(printf '%s' "$MILESTONE" | tr -c 'A-Za-z0-9._-' '_')"
LEDGER="$SOAK_DIR/$MILESTONE.log"

HOST="$(hostname -s 2>/dev/null || echo host)"
NOW_EPOCH="$(date +%s)"
NOW_ISO="$(date '+%Y-%m-%dT%H:%M:%S')"

# ── analisa o ledger → distinct hosts PASS, span em dias ─────────────────────
analyze() {
  [ -f "$LEDGER" ] || { echo "0 0 0"; return; }
  awk -F'|' '
    $4=="idea_doctor=PASS" && $5=="regression=PASS" {
      hosts[$3]=1
      if (min=="" || $1<min) min=$1
      if (max=="" || $1>max) max=$1
      n++
    }
    END {
      hc=0; for (h in hosts) hc++
      span = (max=="" ? 0 : max-min)
      printf "%d %d %d", hc, span, n
    }
  ' "$LEDGER"
}

# ── --status ─────────────────────────────────────────────────────────────────
if [ "$MODE" = "--status" ]; then
  echo -e "\n${CYAN}${BOLD}━━━ SOAK status: $MILESTONE ━━━${NC}"
  if [ ! -f "$LEDGER" ]; then info "sem ledger ($LEDGER) — nenhum heartbeat ainda"; exit 0; fi
  read -r HC SPAN N <<<"$(analyze)"
  DAYS=$(( SPAN / 86400 ))
  info "ledger: $LEDGER"
  awk -F'|' '{printf "    %s  %-16s  %s %s  %s\n", $2, $3, $4, $5, $6}' "$LEDGER"
  echo -e "  máquinas distintas (PASS): ${BOLD}$HC${NC}  ·  span: ${BOLD}${DAYS}d${NC}  ·  heartbeats: $N"
  exit 0
fi

# ── --record: roda os gates locais; se PASS, grava heartbeat ─────────────────
if [ "$MODE" = "--record" ]; then
  echo -e "\n${CYAN}${BOLD}━━━ SOAK record: $MILESTONE @ $HOST ━━━${NC}"

  info "rodando idea-doctor (0 FAIL exigido)…"
  if bash "$ROOT/scripts/idea-doctor.sh" >/dev/null 2>&1; then DOC=PASS; ok "idea-doctor PASS"; else DOC=FAIL; err "idea-doctor FAIL — rode: bash scripts/idea-doctor.sh"; fi

  info "rodando regressão estrutural (test suites + evals --dry-run)…"
  REG=PASS
  for suite in "$ROOT"/tests/*/test-*.sh; do
    [ -e "$suite" ] || continue
    if ! bash "$suite" >/dev/null 2>&1; then REG=FAIL; err "regressão FAIL: ${suite#$ROOT/}"; fi
  done
  if [ -f "$ROOT/evals/run-evals.sh" ]; then
    bash "$ROOT/evals/run-evals.sh" --dry-run >/dev/null 2>&1 || { REG=FAIL; err "regressão FAIL: evals/run-evals.sh --dry-run"; }
  fi
  [ "$REG" = "PASS" ] && ok "regressão estrutural PASS"

  if [ "$DOC" != "PASS" ] || [ "$REG" != "PASS" ]; then
    err "gates locais não passaram — heartbeat NÃO gravado."
    exit 1
  fi

  mkdir -p "$SOAK_DIR"
  COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?')"
  printf '%s|%s|%s|idea_doctor=PASS|regression=PASS|%s\n' "$NOW_EPOCH" "$NOW_ISO" "$HOST" "$COMMIT" >> "$LEDGER"
  ok "heartbeat gravado em $LEDGER ($HOST @ $NOW_ISO, commit $COMMIT)"
  info "commite o ledger para compartilhar o soak entre máquinas (autosync empurra)."
  # mostra o estado pós-gravação
  read -r HC SPAN N <<<"$(analyze)"
  DAYS=$(( SPAN / 86400 ))
  info "estado: $HC máquina(s) · span ${DAYS}d (alvo: ≥$MIN_MACHINES máquinas, ≥${MIN_DAYS}d)"
  exit 0
fi

# ── verify (default) ─────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}━━━ SOAK gate: $MILESTONE ━━━${NC}"
if [ ! -f "$LEDGER" ]; then
  err "sem soak ($LEDGER ausente) — rode em ≥$MIN_MACHINES máquinas: bash scripts/check-soak.sh $MILESTONE --record"
  exit 1
fi
read -r HC SPAN N <<<"$(analyze)"
DAYS=$(( SPAN / 86400 ))
info "máquinas distintas (PASS): $HC (alvo ≥$MIN_MACHINES) · span: ${DAYS}d (alvo ≥${MIN_DAYS}d) · heartbeats: $N"

FAILED=0
if [ "$HC" -lt "$MIN_MACHINES" ]; then err "faltam máquinas: $HC < $MIN_MACHINES — rode --record noutra máquina"; FAILED=1; fi
if [ "$DAYS" -lt "$MIN_DAYS" ]; then err "soak curto: ${DAYS}d < ${MIN_DAYS}d — aguarde e re-grave"; FAILED=1; fi

if [ "$FAILED" -eq 0 ]; then
  ok "SOAK satisfeito — $MILESTONE pode ser tagueado (≥$MIN_MACHINES máquinas, ≥${MIN_DAYS}d)"
  exit 0
fi
err "SOAK NÃO satisfeito — NÃO tague $MILESTONE ainda. Bypass consciente: SOAK_MIN_MACHINES=1 SOAK_MIN_DAYS=0 (só com justificativa registrada)."
exit 1
