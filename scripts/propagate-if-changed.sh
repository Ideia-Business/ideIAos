#!/usr/bin/env bash
# =============================================================================
# propagate-if-changed.sh — propaga IdeiaOS para global + ~/dev/* quando
# commits novos tocam paths propagáveis (templates, setup, skills, agents…).
#
# Gatilhos:
#   - git-autosync após pull bem-sucedido no repo IdeiaOS
#   - post-merge hook (git pull manual)
#   - sync-all.sh etapa 5 (opcional)
#   - ideiaos-update.sh (patch do autosync)
#
# State:  ~/.ideiaos/state/last-propagate.hash
# Log:    ~/.local/state/propagate-projects.log
#
# Uso:
#   bash scripts/propagate-if-changed.sh              # auto (vs state file)
#   bash scripts/propagate-if-changed.sh --dry-run    # mostra plano, não executa
#   bash scripts/propagate-if-changed.sh --force       # ignora filtro de paths
#   bash scripts/propagate-if-changed.sh --since abc123  # diff explícito
#
# Exit: 0 se nada a fazer ou sucesso; 1 se alguma etapa falhou.
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${IDEIAOS_STATE_DIR:-$HOME/.ideiaos/state}"
HASH_FILE="$STATE_DIR/last-propagate.hash"
TS_FILE="$STATE_DIR/last-propagate.timestamp"
LOG="${IDEIAOS_PROPAGATE_LOG:-$HOME/.local/state/propagate-projects.log}"

DRY_RUN=0
FORCE=0
SINCE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    --since)
      SINCE="${2:-}"
      [ -n "$SINCE" ] || { echo "❌ --since requer um ref git"; exit 1; }
      shift 2
      ;;
    *) echo "❌ Opção desconhecida: $1"; exit 1 ;;
  esac
done

mkdir -p "$STATE_DIR" "$(dirname "$LOG")"

log_msg() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; log_msg "OK $*"; }
skip() { echo -e "${CYAN}  ⊙${NC} $*"; log_msg "SKIP $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; log_msg "WARN $*"; }
step() { echo -e "\n${CYAN}${BOLD}==> $*${NC}"; log_msg "==> $*"; }

# Paths cujo diff dispara setup --global-only + install-global-patches
GLOBAL_PATHS=(
  'source/skills/'
  'source/hooks/'
  'source/agents/'
  'plugins/'
  'manifests/modules.json'
  'scripts/install-global-patches.sh'
  'source/contexts/'
  'source/statusline/'
)

# Paths cujo diff dispara apply-to-all-projects --apply
PROJECT_PATHS=(
  'source/templates/'
  'setup.sh'
  'scripts/apply-to-all-projects.sh'
  'scripts/propagate-if-changed.sh'
)

if ! git -C "$SETUP_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  warn "IdeiaOS não é repo git — pulando propagação"
  exit 0
fi

HEAD="$(git -C "$SETUP_DIR" rev-parse HEAD)"
OLD_HASH=""
[ -f "$HASH_FILE" ] && OLD_HASH="$(tr -d '[:space:]' < "$HASH_FILE")"

if [ -n "$SINCE" ]; then
  OLD_HASH="$SINCE"
elif [ -z "$OLD_HASH" ]; then
  # Primeira execução: baseline no HEAD atual (não propaga histórico)
  if [ "$DRY_RUN" -eq 1 ]; then
    skip "Primeira execução — baseline em HEAD ($HEAD); nada a propagar"
  else
    echo "$HEAD" > "$HASH_FILE"
    date +%s > "$TS_FILE"
    skip "Primeira execução — baseline gravado em $HASH_FILE (HEAD=$HEAD)"
  fi
  exit 0
fi

if [ "$OLD_HASH" = "$HEAD" ] && [ "$FORCE" -eq 0 ]; then
  skip "HEAD inalterado desde última propagação ($HEAD)"
  exit 0
fi

# Validar OLD_HASH
if ! git -C "$SETUP_DIR" cat-file -e "$OLD_HASH^{commit}" 2>/dev/null; then
  warn "Hash armazenado inválido ($OLD_HASH) — resetando baseline para HEAD"
  echo "$HEAD" > "$HASH_FILE"
  exit 0
fi

CHANGED="$(git -C "$SETUP_DIR" diff --name-only "$OLD_HASH" "$HEAD" 2>/dev/null || true)"
if [ -z "$CHANGED" ]; then
  skip "Nenhum arquivo alterado entre $OLD_HASH e $HEAD"
  [ "$DRY_RUN" -eq 0 ] && { echo "$HEAD" > "$HASH_FILE"; date +%s > "$TS_FILE"; }
  exit 0
fi

matches_prefix() {
  local file="$1"
  shift
  local prefix
  for prefix in "$@"; do
    case "$file" in
      $prefix*) return 0 ;;
    esac
  done
  return 1
}

NEED_GLOBAL=0
NEED_PROJECT=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  if matches_prefix "$f" "${GLOBAL_PATHS[@]}"; then NEED_GLOBAL=1; fi
  if matches_prefix "$f" "${PROJECT_PATHS[@]}"; then NEED_PROJECT=1; fi
done <<< "$CHANGED"

if [ "$FORCE" -eq 1 ]; then
  NEED_GLOBAL=1
  NEED_PROJECT=1
fi

if [ "$NEED_GLOBAL" -eq 0 ] && [ "$NEED_PROJECT" -eq 0 ]; then
  skip "Diff sem paths propagáveis ($(echo "$CHANGED" | wc -l | tr -d ' ') arquivo(s) — docs/planning/etc.)"
  log_msg "SKIP paths: $(echo "$CHANGED" | tr '\n' ' ')"
  if [ "$DRY_RUN" -eq 0 ]; then
    echo "$HEAD" > "$HASH_FILE"
    date +%s > "$TS_FILE"
  fi
  exit 0
fi

echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo    "║     IdeiaOS — propagate-if-changed                    ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo "  Repo:   $SETUP_DIR"
echo "  Diff:   ${OLD_HASH:0:8}..${HEAD:0:8}"
echo "  Global: $([ "$NEED_GLOBAL" -eq 1 ] && echo sim || echo não)"
echo "  Projetos: $([ "$NEED_PROJECT" -eq 1 ] && echo sim || echo não)"
log_msg "START diff=${OLD_HASH:0:8}..${HEAD:0:8} global=$NEED_GLOBAL project=$NEED_PROJECT dry=$DRY_RUN"

if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "  Arquivos no diff:"
  echo "$CHANGED" | sed 's/^/    /'
  skip "Dry-run — nenhuma ação executada"
  exit 0
fi

ERRORS=0

if [ "$NEED_GLOBAL" -eq 1 ]; then
  step "Global: setup.sh --global-only"
  if bash "$SETUP_DIR/setup.sh" --global-only; then
    ok "setup --global-only concluído"
  else
    warn "setup --global-only falhou"
    ERRORS=$((ERRORS + 1))
  fi
  step "Global: install-global-patches.sh"
  if bash "$SETUP_DIR/scripts/install-global-patches.sh"; then
    ok "overlay global reaplicado"
  else
    warn "install-global-patches falhou"
    ERRORS=$((ERRORS + 1))
  fi
fi

if [ "$NEED_PROJECT" -eq 1 ]; then
  step "Projetos: apply-to-all-projects.sh --apply"
  if bash "$SETUP_DIR/scripts/apply-to-all-projects.sh" --apply; then
    ok "apply-to-all-projects concluído"
  else
    warn "apply-to-all-projects falhou"
    ERRORS=$((ERRORS + 1))
  fi
fi

if [ "$ERRORS" -gt 0 ]; then
  warn "Propagação terminou com $ERRORS erro(s) — baseline mantido em ${OLD_HASH:0:8}"
  exit 1
fi

echo "$HEAD" > "$HASH_FILE"
date +%s > "$TS_FILE"
ok "Propagação concluída — baseline ${HEAD:0:8}"
exit 0
