#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (DX) | kind: launcher | targets: claude,cursor
# =============================================================================
# cockpit-up.sh — abre o IdeiaOS Cockpit com UM comando.
#   1) (best-effort) reconstrói o read-model do ref `cockpit` (ingest)
#   2) sobe a API read.js (loopback 127.0.0.1:3073)
#   3) sobe o SPA Vite (loopback 127.0.0.1:5273, strictPort)
#   4) abre o browser na UI
#   5) Ctrl-C derruba os dois (trap garante teardown — sem processos órfãos)
#
# Local-first (ADR v14): tudo em loopback, sem login. NÃO toca produção, NÃO faz
# git push, NÃO roda --record. É só o leitor + a UI.
# Uso:  bash scripts/cockpit-up.sh            # sobe e abre
#       bash scripts/cockpit-up.sh --no-open  # sobe sem abrir o browser
# Exit: 0 ao encerrar limpo (Ctrl-C); 1 em pré-requisito ausente.
# =============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/cockpit"
READ_PORT="${READ_PORT:-3073}"
VITE_PORT="${VITE_PORT:-5273}"
OPEN=1; [ "${1:-}" = "--no-open" ] && OPEN=0

c_ok(){ printf '  \033[0;32m✓\033[0m %s\n' "$*"; }
c_info(){ printf '  \033[0;36mℹ\033[0m %s\n' "$*"; }
c_warn(){ printf '  \033[0;33m⚠\033[0m %s\n' "$*"; }
c_die(){ printf '\033[0;31m✗ %s\033[0m\n' "$*"; exit 1; }

command -v node >/dev/null 2>&1 || c_die "node ausente (Node 18+ necessário)"
[ -d "$APP" ] || c_die "apps/cockpit ausente — repo IdeiaOS incompleto"
[ -d "$APP/node_modules" ] || { c_info "instalando deps do SPA (1ª vez)…"; (cd "$APP" && npm install --silent) || c_die "npm install falhou"; }

printf '\033[1;36m▶ IdeiaOS Cockpit\033[0m\n'

# 1) read-model fresco (best-effort — se falhar, read.js responde 503 com dica).
if [ -f "$ROOT/source/console/ingest.js" ]; then
  if node "$ROOT/source/console/ingest.js" >/dev/null 2>&1; then c_ok "read-model atualizado (ingest do ref cockpit)"
  else c_warn "ingest falhou (segue com o read-model existente, se houver)"; fi
fi

PIDS=()
cleanup(){ printf '\n'; for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null || true; done; c_info "cockpit encerrado"; }
trap cleanup INT TERM EXIT

# 2) API read.js (loopback).
READ_PORT="$READ_PORT" node "$APP/server/read.js" >"$ROOT/.cockpit-read.log" 2>&1 &
PIDS+=("$!")
# espera o /health subir (≤10s).
up=0; for _ in $(seq 1 50); do
  if curl -fsS "http://127.0.0.1:$READ_PORT/health" >/dev/null 2>&1; then up=1; break; fi
  sleep 0.2
done
[ "$up" = 1 ] && c_ok "API read.js em http://127.0.0.1:$READ_PORT" || c_warn "API não respondeu /health (ver .cockpit-read.log)"

# 3) SPA Vite (loopback, strictPort).
( cd "$APP" && VITE_READ_PORT="$READ_PORT" npm run dev -- --port "$VITE_PORT" --strictPort >"$ROOT/.cockpit-spa.log" 2>&1 ) &
PIDS+=("$!")
up=0; for _ in $(seq 1 75); do
  if curl -fsS "http://127.0.0.1:$VITE_PORT/" >/dev/null 2>&1; then up=1; break; fi
  sleep 0.2
done
URL="http://127.0.0.1:$VITE_PORT"
[ "$up" = 1 ] && c_ok "SPA em $URL" || c_warn "SPA não respondeu (ver .cockpit-spa.log)"

# 4) abrir o browser.
if [ "$OPEN" = 1 ] && [ "$up" = 1 ]; then
  if command -v open >/dev/null 2>&1; then open "$URL"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1
  fi
fi

printf '\n  Cockpit no ar. \033[1mCtrl-C\033[0m para encerrar.\n\n'
# 5) segura em foreground até Ctrl-C (o trap derruba os dois).
wait
