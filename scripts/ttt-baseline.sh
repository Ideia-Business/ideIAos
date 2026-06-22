#!/usr/bin/env bash
# SOURCE: IdeiaOS v14 | kind: harness | targets: claude,cursor
# =============================================================================
# ttt-baseline.sh — Time-to-Truth baseline harness (R14-06)
#
# Cronometra uma jornada (J1/J4/J2) via terminal e anexa ao TSV de baseline.
# Satisfaz A1 da spec: baseline terminal N>=5 por jornada, mediana calculada
# por ttt-median.sh. A v14.1 vai bater este numero pos-Bridge.
#
# Jornadas:
#   J1 — "Frota saudavel?" (checar status de daemons + idea-doctor)
#   J4 — "Chave X existe + idade, NUNCA valor" (metadata de api_key)
#   J2 — "Pronto p/ tag?" (soak >=2 maquinas, span>=1d sobre epochs gravados)
#          Learning: soak-span-is-record-delta-not-wallclock
#
# USO:
#   bash scripts/ttt-baseline.sh J1|J4|J2          # cronometrar jornada (modo terminal)
#   bash scripts/ttt-baseline.sh J1 --mode=bridge --dry-run  # estrutura v14.1 (exit 0)
#
# Modo interativo (stdin = tty):
#   Aguarda ENTER do operador antes e apos a jornada para cronometrar.
# Modo nao-interativo (stdin != tty, e.g. pipe/script):
#   Registra imediatamente com duracao zero (util para popular o TSV em testes).
#
# TSV: ~/.ideiaos/console/ttt-baseline.tsv
#   formato por linha: <jornada>\t<modo>\t<segundos>\t<epoch>
#
# Exit: 0 = registrado com sucesso · 1 = erro de gate/invocacao · 2 = erro de arg
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

# ── args ──────────────────────────────────────────────────────────────────────
JORNADA="${1:-}"
MODE="terminal"
DRY_RUN=0

# parse flags (posicionais apos o 1o arg)
shift || true
for arg in "$@"; do
  case "$arg" in
    --mode=bridge)   MODE="bridge" ;;
    --mode=terminal) MODE="terminal" ;;
    --dry-run)       DRY_RUN=1 ;;
  esac
done

[ -n "$JORNADA" ] || { echo "uso: ttt-baseline.sh J1|J4|J2 [--mode=bridge] [--dry-run]" >&2; exit 2; }
case "$JORNADA" in
  J1|J4|J2) ;;
  *) echo "jornada invalida: $JORNADA (use J1, J4 ou J2)" >&2; exit 2 ;;
esac

# ── modo bridge (medicao REAL v14.1 — R14-06, A2) ─────────────────────────────
# Cronometra a jornada RESPONDIDA VIA A BRIDGE: o read-model SQLite que a Bridge
# (read.js loopback /fleet /vault) serve — nao o terminal. node:sqlite (built-in,
# zero dep) le ~/.ideiaos/console/read-model.db, a MESMA fonte dos endpoints 14.1-01.
#
# As 3 jornadas (NUNCA expoem valor de chave — credential-isolation):
#   J1 frota-saudavel  → COUNT machine + daemon_status (fonte de /fleet)
#   J4 chave-existe+idade → api_key METADATA-ONLY (present, risk_tier, file_mtime_epoch
#                            → idade = now - mtime); NUNCA o valor (schema sem coluna value)
#   J2 pronto-pra-tag  → soak_satisfied: >=2 hosts distintos com PASS E span>=86400s
#                         entre EPOCHS GRAVADOS no ledger (delta, nao wall-clock —
#                         learning soak-span-is-record-delta-not-wallclock)
if [ "$MODE" = "bridge" ]; then
  if [ "$DRY_RUN" = "1" ]; then
    info "bridge --dry-run: valida estrutura, NAO grava medicao bridge"
    ok "bridge --dry-run: exit 0 sem gravar linha bridge"
    exit 0
  fi

  TSV_DIR="$HOME/.ideiaos/console"
  mkdir -p "$TSV_DIR"
  TSV="$TSV_DIR/ttt-baseline.tsv"
  DB_PATH="$TSV_DIR/read-model.db"

  if [ ! -s "$DB_PATH" ]; then
    err "read-model.db ausente/vazio: $DB_PATH"
    err "rode: node source/console/ingest.js (reconstroi do ref cockpit)"
    exit 1
  fi

  # query da jornada via node:sqlite (a Bridge data-path). Cronometra do disco no
  # instante da pergunta — a mesma SELECT que /fleet e /vault servem.
  case "$JORNADA" in
    J1) BRIDGE_QUERY="SELECT (SELECT COUNT(*) FROM machine) AS machines, (SELECT COUNT(*) FROM daemon_status) AS daemons;" ;;
    J4) BRIDGE_QUERY="SELECT COUNT(*) AS keys, SUM(present) AS present, MAX(file_mtime_epoch) AS newest_mtime FROM api_key;" ;;
    J2) BRIDGE_QUERY="SELECT milestone, COUNT(DISTINCT host) AS pass_hosts, (MAX(epoch)-MIN(epoch)) AS span_s, (CASE WHEN COUNT(DISTINCT host)>=2 AND (MAX(epoch)-MIN(epoch))>=86400 THEN 1 ELSE 0 END) AS soak_satisfied FROM soak_heartbeat WHERE idea_doctor LIKE '%PASS%' AND regression LIKE '%PASS%' GROUP BY milestone;" ;;
  esac

  T_START="$(date +%s%N)"
  # node:sqlite read-only — a Bridge responde a jornada a partir do read-model.
  # J4: seleciona SO metadata (count/present/mtime); o valor NUNCA e lido (schema sem value).
  BRIDGE_OUT="$(IDEIA_Q="$BRIDGE_QUERY" node --input-type=module -e '
    import { DatabaseSync } from "node:sqlite";
    import os from "node:os";
    import path from "node:path";
    const db = new DatabaseSync(path.join(os.homedir(), ".ideiaos", "console", "read-model.db"), { readOnly: true });
    const rows = db.prepare(process.env.IDEIA_Q).all();
    db.close();
    // imprime so contagens/flags derivadas — NUNCA um valor de chave (J4 e metadata-only)
    process.stdout.write(JSON.stringify(rows));
  ' 2>/dev/null)"
  RC=$?
  T_END="$(date +%s%N)"

  if [ "$RC" -ne 0 ] || [ -z "$BRIDGE_OUT" ]; then
    err "jornada $JORNADA via Bridge falhou (node:sqlite rc=$RC)"
    exit 1
  fi

  NANOSEC_ELAPSED=$(( T_END - T_START ))
  SECONDS_ELAPSED="$(awk "BEGIN {printf \"%.3f\", $NANOSEC_ELAPSED / 1000000000}")"
  NOW_EPOCH="$(date +%s)"

  # append ao TSV com modo LITERAL `bridge` (nao placeholder); mesmo formato 4-col
  printf '%s\t%s\t%s\t%s\n' "$JORNADA" "bridge" "$SECONDS_ELAPSED" "$NOW_EPOCH" >> "$TSV"

  # feedback so em tty (stdout limpo em pipe/script — o gate le o TSV, nao o stdout)
  if [ -t 1 ]; then
    ok "bridge $JORNADA respondida em ${SECONDS_ELAPSED}s (via read-model)"
    info "jornada=$JORNADA  modo=bridge  segundos=$SECONDS_ELAPSED  epoch=$NOW_EPOCH"
  fi
  exit 0
fi

# ── descricao de cada jornada ─────────────────────────────────────────────────
descricao_jornada() {
  case "$1" in
    J1) echo "Frota saudavel? (daemons + idea-doctor + status geral)" ;;
    J4) echo "Chave X existe + idade, NUNCA valor (metadata de api_key)" ;;
    J2) echo "Pronto p/ tag? (soak >=2 maquinas, span>=1d sobre epochs gravados)" ;;
  esac
}

# ── detecta modo interativo ───────────────────────────────────────────────────
# stdin = tty → modo interativo (operador real); senao → modo nao-interativo
INTERACTIVE=0
if [ -t 0 ]; then
  INTERACTIVE=1
fi

# ── cronometragem ─────────────────────────────────────────────────────────────
TSV_DIR="$HOME/.ideiaos/console"
mkdir -p "$TSV_DIR"
TSV="$TSV_DIR/ttt-baseline.tsv"

if [ "$INTERACTIVE" = "1" ]; then
  echo -e "\n${CYAN}${BOLD}━━━ TTT Baseline: $JORNADA ━━━${NC}"
  info "Jornada: $(descricao_jornada "$JORNADA")"
  echo ""
  case "$JORNADA" in
    J1)
      info "Passos da jornada J1 — Frota saudavel?:"
      info "  1. Verifique os daemons LaunchAgent (launchctl list | grep com.ideiaos)"
      info "  2. Execute: bash scripts/idea-doctor.sh (aguarde o resultado)"
      info "  3. Confirme o status de cada maquina no snapshot mais recente"
      ;;
    J4)
      info "Passos da jornada J4 — Chave X existe + idade, NUNCA valor:"
      info "  1. Identifique a chave alvo (nome da variavel, ex: SUPABASE_KEY)"
      info "  2. Verifique: present=1/0, risk_tier, mtime_epoch (sem ver o valor)"
      info "  3. Calcule a idade: \$(( \$(date +%s) - mtime_epoch )) segundos"
      info "  AVISO: apenas metadados — NUNCA o valor da chave (credential-isolation)"
      ;;
    J2)
      info "Passos da jornada J2 — Pronto p/ tag?:"
      info "  1. Verifique soak: bash scripts/check-soak.sh <milestone> --status"
      info "  2. Confirme >=2 maquinas distintas com PASS no ledger"
      info "  3. Confirme span>=1d entre os EPOCHS GRAVADOS (nao wall-clock)"
      info "     Learning: soak-span-is-record-delta-not-wallclock"
      info "  4. Confirme idea-doctor = 0 FAIL e security re-selado"
      ;;
  esac
  echo ""
  info "(Pressione ENTER para iniciar o cronometro)"
  read -r _

  T_START="$(date +%s%N)"
  info "CRONOMETRO INICIADO — execute a jornada $JORNADA agora"
  echo ""
  info "(Pressione ENTER quando terminar)"
  read -r _
  T_END="$(date +%s%N)"

  NANOSEC_ELAPSED=$(( T_END - T_START ))
  SECONDS_ELAPSED="$(awk "BEGIN {printf \"%.3f\", $NANOSEC_ELAPSED / 1000000000}")"
  NOW_EPOCH="$(date +%s)"
  echo ""
  ok "Jornada $JORNADA concluida em ${SECONDS_ELAPSED}s"
else
  # modo nao-interativo: registra medicao com timestamp imediato (para popular o TSV)
  T_START="$(date +%s%N)"
  T_END="$(date +%s%N)"
  NANOSEC_ELAPSED=$(( T_END - T_START ))
  SECONDS_ELAPSED="$(awk "BEGIN {printf \"%.3f\", $NANOSEC_ELAPSED / 1000000000}")"
  NOW_EPOCH="$(date +%s)"
fi

# ── source gates.sh (forma guardada + fallback inline — antifragile-gates.md) ─
[ -n "${IDEIAOS_DIR:-}" ] && [ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] && . "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
type assert_nonempty >/dev/null 2>&1 || assert_nonempty(){ test -s "${1:-}"; }

# ── append ao TSV ─────────────────────────────────────────────────────────────
printf '%s\t%s\t%s\t%s\n' "$JORNADA" "$MODE" "$SECONDS_ELAPSED" "$NOW_EPOCH" >> "$TSV"

# gate o TSV (build script: exit 1 em falha)
assert_nonempty "$TSV" "ttt-baseline.tsv" || { err "TSV nao encontrado ou vazio: $TSV"; exit 1; }

[ "$INTERACTIVE" = "1" ] && ok "registrado em $TSV" || true
[ "$INTERACTIVE" = "1" ] && info "jornada=$JORNADA  modo=$MODE  segundos=$SECONDS_ELAPSED  epoch=$NOW_EPOCH" || true

# status atual do TSV (so em modo interativo)
if [ "$INTERACTIVE" = "1" ]; then
  TOTAL="$(wc -l < "$TSV" | tr -d ' ')"
  for j in J1 J4 J2; do
    N_J="$(awk -F'\t' -v J="$j" '$1==J' "$TSV" | wc -l | tr -d ' ')"
    if [ "$N_J" -ge 5 ]; then
      ok "$j: $N_J medicoes (N>=5 atingido)"
    else
      warn "$j: $N_J medicoes (meta: >=5)"
    fi
  done
  info "total de medicoes no TSV: $TOTAL"
fi

exit 0
