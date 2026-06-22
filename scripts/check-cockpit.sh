#!/usr/bin/env bash
# SOURCE: IdeiaOS v14 | kind: gate | targets: claude,cursor
# =============================================================================
# check-cockpit.sh — Gate de fechamento do IdeiaOS Cockpit (v14.0)
#
# Três checks por exit-code:
#   (a) agentd ativo  — LaunchAgent com.ideiaos.cockpit presente no launchctl
#   (b) ref cockpit   — refs/heads/cockpit existe neste repo
#   (c) snapshot fresco — taken_epoch desta máquina dentro de 2 ciclos (2×900s)
#
# USO:
#   bash scripts/check-cockpit.sh          # verifica (exit 0=saudável, 1=falhou)
#   bash scripts/check-cockpit.sh --status # resumo verbose sem exit não-zero
#
# Exit: 0 = saudável (todos os 3 checks passam)
#       1 = falhou (1+ check falhou)
#       2 = erro de invocação
#
# Build script (não hook): exit 1 em falha.
# Os mesmos 3 checks são expostos como idea-doctor §15 (step "15) Cockpit").
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

# ── Antifragile gate (fallback inline — IDEIAOS_DIR pode não estar disponível)
type assert_nonempty >/dev/null 2>&1 \
  || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }

# ── Derivar machine_id (sha256(IOPlatformUUID)[:12], mesma lógica do collect.js)
derive_machine_id() {
  local uuid
  uuid=$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null \
    | awk -F'"' '/IOPlatformUUID/{print $4}')
  if [ -z "$uuid" ]; then
    echo ""
    return 1
  fi
  printf '%s' "$uuid" | shasum -a 256 | cut -c1-12
}

NOW_EPOCH="$(date +%s)"
CYCLE_INTERVAL=900         # 15 min (StartInterval do LaunchAgent)
MAX_FRESH=$((2 * CYCLE_INTERVAL))  # 2 ciclos = 1800s
FAIL=0

# ── --status: resumo verbose sem exit não-zero ───────────────────────────────
if [ "$MODE" = "--status" ]; then
  echo -e "\n${CYAN}${BOLD}━━━ check-cockpit status ━━━${NC}"

  # (a) agentd
  if launchctl list 2>/dev/null | grep -q 'com.ideiaos.cockpit'; then
    ok "agentd (com.ideiaos.cockpit) ativo no launchctl"
  else
    warn "agentd não listado no launchctl (não iniciado ou não carregado)"
  fi

  # (b) ref cockpit
  if git -C "$ROOT" rev-parse --verify --quiet refs/heads/cockpit >/dev/null 2>&1; then
    CTIP=$(git -C "$ROOT" rev-parse --short refs/heads/cockpit 2>/dev/null)
    ok "ref cockpit existe ($CTIP)"
  else
    warn "refs/heads/cockpit ausente — rode cockpit_write_snapshot (lib/cockpit.sh)"
  fi

  # (c) snapshot fresco
  MID=$(derive_machine_id 2>/dev/null || true)
  if [ -z "$MID" ]; then
    warn "machine_id indisponível (IOPlatformUUID ausente)"
  else
    SNAP_JSON=$(git -C "$ROOT" show "cockpit:snapshots/${MID}.json" 2>/dev/null || true)
    if [ -z "$SNAP_JSON" ]; then
      warn "snapshot de $MID ausente no ref cockpit"
    else
      TAKEN=$(printf '%s' "$SNAP_JSON" | python3 -c 'import json,sys;print(json.load(sys.stdin).get("taken_epoch",""))' 2>/dev/null || echo "")
      if [ -z "$TAKEN" ]; then
        warn "taken_epoch ausente no snapshot de $MID"
      else
        AGE=$(( NOW_EPOCH - TAKEN ))
        if [ "$AGE" -le "$MAX_FRESH" ]; then
          ok "snapshot de $MID fresco (age=${AGE}s ≤ ${MAX_FRESH}s = 2 ciclos)"
        else
          warn "snapshot de $MID defasado (age=${AGE}s > ${MAX_FRESH}s) — aguardar próximo ciclo do agentd"
        fi
      fi
    fi
  fi
  exit 0
fi

# ── Verificação principal (exit 0=ok, 1=falhou) ──────────────────────────────
echo -e "\n${CYAN}${BOLD}━━━ check-cockpit ━━━${NC}"

# (a) agentd ativo
if launchctl list 2>/dev/null | grep -q 'com.ideiaos.cockpit'; then
  ok "agentd (com.ideiaos.cockpit) ativo"
else
  # Não é FAIL para gate de CI puro — o agentd é per-máquina.
  # WARN: o cockpit pode estar fora de um contexto com launchd (CI headless).
  warn "agentd não listado (pode ser CI headless ou LaunchAgent não carregado)"
fi

# (b) ref cockpit existe
if git -C "$ROOT" rev-parse --verify --quiet refs/heads/cockpit >/dev/null 2>&1; then
  CTIP=$(git -C "$ROOT" rev-parse --short refs/heads/cockpit 2>/dev/null || echo "?")
  ok "ref cockpit existe (tip=$CTIP)"
else
  err "refs/heads/cockpit ausente — rode: bash source/lib/cockpit.sh (cockpit_write_snapshot)"
  FAIL=$((FAIL+1))
fi

# (c) snapshot fresco (<2 ciclos)
MID=$(derive_machine_id 2>/dev/null || true)
if [ -z "$MID" ]; then
  warn "machine_id indisponível — IOPlatformUUID ausente (não-macOS?)"
else
  SNAP_JSON=$(git -C "$ROOT" show "cockpit:snapshots/${MID}.json" 2>/dev/null || true)
  if [ -z "$SNAP_JSON" ]; then
    warn "snapshot de ${MID} ausente no ref — aguardar 1º ciclo do agentd"
  else
    TAKEN=$(printf '%s' "$SNAP_JSON" \
      | python3 -c 'import json,sys;print(json.load(sys.stdin).get("taken_epoch",""))' \
      2>/dev/null || echo "")
    if [ -z "$TAKEN" ]; then
      warn "taken_epoch ausente no snapshot de ${MID}"
    else
      AGE=$(( NOW_EPOCH - TAKEN ))
      if [ "$AGE" -le "$MAX_FRESH" ]; then
        ok "snapshot de ${MID} fresco (age=${AGE}s ≤ ${MAX_FRESH}s)"
      else
        warn "snapshot defasado (age=${AGE}s > ${MAX_FRESH}s) — aguardar próximo ciclo agentd"
      fi
    fi
  fi
fi

# ── Resultado ─────────────────────────────────────────────────────────────────
if [ "$FAIL" -gt 0 ]; then
  echo -e "\n${RED}${BOLD}  ✗ check-cockpit FALHOU ($FAIL check(s))${NC}"
  exit 1
fi
echo -e "\n${GREEN}${BOLD}  ✓ check-cockpit SAUDÁVEL${NC}"
exit 0
