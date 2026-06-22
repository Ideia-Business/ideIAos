#!/usr/bin/env bash
# SOURCE: IdeiaOS v14 | kind: harness | targets: claude,cursor
# =============================================================================
# ttt-median.sh — Mediana de Time-to-Truth por jornada (R14-06)
#
# Le o TSV de baseline, agrupa por jornada (J1/J4/J2), ordena os segundos
# de cada grupo e imprime a mediana em bash puro (sem dependencias externas).
#
# Algoritmo de mediana:
#   N impar  → linha do meio: index = (N+1)/2 (1-based)
#   N par    → linha inferior do par central: index = N/2 (escolha determinista)
#   N=0      → imprime "N/A" para a jornada
#
# TSV de entrada: ~/.ideiaos/console/ttt-baseline.tsv
#   formato por linha: <jornada>\t<modo>\t<segundos>\t<epoch>
#
# Saida (stdout, 3 linhas):
#   J1   <mediana>
#   J4   <mediana>
#   J2   <mediana>
#
# Modos (R14-06, A2):
#   terminal (default) — exclui linhas bridge-placeholder/bridge-dry-run; calcula
#                        sobre o baseline terminal (14.0-03 — NAO regride)
#   bridge             — SELECIONA SOMENTE linhas $2=="bridge" (medicao real v14.1);
#                        gate A2: `... --mode=bridge | awk '$2>=10{f=1} END{exit f}'`
#                        sai 0 ⇔ todas as jornadas tem mediana Bridge < 10s
#
# USO:
#   bash scripts/ttt-median.sh                          # mediana terminal (default)
#   bash scripts/ttt-median.sh --mode=bridge            # mediana Bridge (linhas bridge)
#   bash scripts/ttt-median.sh --mode=terminal          # explicito terminal
#   bash scripts/ttt-median.sh ~/.ideiaos/console/ttt-baseline.tsv  # TSV customizado
#   bash scripts/ttt-median.sh --mode=bridge /tmp/custom.tsv        # flag + TSV custom
#
# Exit: 0 = sucesso (mesmo que N/A) · 1 = erro de gate (TSV ausente/vazio)
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }

# ── args: flag --mode=bridge|terminal (default terminal) + caminho TSV opcional ─
MODE="terminal"
TSV_ARG=""
for arg in "$@"; do
  case "$arg" in
    --mode=bridge)   MODE="bridge" ;;
    --mode=terminal) MODE="terminal" ;;
    --mode=*)        echo "modo invalido: $arg (use --mode=bridge ou --mode=terminal)" >&2; exit 2 ;;
    -*)              echo "flag desconhecida: $arg" >&2; exit 2 ;;
    *)               TSV_ARG="$arg" ;;   # arg posicional = caminho do TSV custom
  esac
done
TSV="${TSV_ARG:-$HOME/.ideiaos/console/ttt-baseline.tsv}"

# ── source gates.sh (forma guardada + fallback inline — antifragile-gates.md) ─
[ -n "${IDEIAOS_DIR:-}" ] && [ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] && . "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
type assert_nonempty >/dev/null 2>&1 || assert_nonempty(){ test -s "${1:-}"; }

# gate: TSV deve existir e ser nao-vazio (build script: exit 1)
assert_nonempty "$TSV" "ttt-baseline.tsv" || { err "TSV ausente ou vazio: $TSV"; err "Execute: bash scripts/ttt-baseline.sh J1|J4|J2 (N>=5 por jornada)"; exit 1; }

# ── funcao de mediana para uma jornada ───────────────────────────────────────
# Extrai a coluna de segundos para a jornada dada, ordena, pega a linha do meio.
# Saida: <mediana> ou "N/A" se sem medicoes.
# Bash puro: sort -n (disponivel no macOS/Linux), awk para selecao de linha.
median_for_journey() {
  local journey="$1"

  # extrai segundos da jornada (campo 3, TAB-sep) com filtro dependente do MODO:
  #   bridge   → SELECIONA somente $2=="bridge" (medicao real v14.1)
  #   terminal → EXCLUI placeholders bridge (comportamento 14.0-03 — nao regride)
  local values
  if [ "$MODE" = "bridge" ]; then
    values="$(awk -F'\t' -v J="$journey" '
      $1==J && $2=="bridge" { print $3 }
    ' "$TSV" | sort -n)"
  else
    values="$(awk -F'\t' -v J="$journey" '
      $1==J && $2!="bridge-placeholder" && $2!="bridge-dry-run" && $2!="bridge" { print $3 }
    ' "$TSV" | sort -n)"
  fi

  local n
  n="$(echo "$values" | grep -c '[0-9]' 2>/dev/null || echo 0)"

  if [ "$n" -eq 0 ]; then
    echo "N/A"
    return 0
  fi

  # calcula indice da mediana (1-based)
  # N impar: (N+1)/2; N par: N/2 (linha inferior do par central — determinista)
  local mid
  if [ $(( n % 2 )) -eq 1 ]; then
    mid=$(( (n + 1) / 2 ))
  else
    mid=$(( n / 2 ))
  fi

  # seleciona a linha do meio do output ordenado
  echo "$values" | awk -v m="$mid" 'NR==m{print; exit}'
}

# ── calcula e imprime as 3 medianas ──────────────────────────────────────────
for j in J1 J4 J2; do
  med="$(median_for_journey "$j")"
  printf '%s\t%s\n' "$j" "$med"
done
