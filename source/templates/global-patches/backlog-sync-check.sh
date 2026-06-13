#!/usr/bin/env bash
# backlog-sync-check.sh — SessionStart guard do IdeiaOS (ideiapartner)
# -----------------------------------------------------------------------------
# Confronta o "Pendências Cloud" do handoff/STATE com a VERDADE de produção:
# consulta read-only o ops-db-gateway (incident_backlog_snapshot) e injeta no
# contexto a contagem REAL de incidentes abertos. Sem isto, o handoff (narrativa
# mantida à mão) drifta — uma sessão pode perseguir backlog já resolvido em prod,
# ou ignorar um incidente novo. Análogo do git-sync-check.sh, mas para o estado
# de RUNTIME (prod), não o estado de código (git).
#
# Escopo: só age em repos que têm scripts/ops-db-query.mjs (= ideiapartner).
# Qualquer outro repo, sem token, offline, ou gateway fora do ar → SILENCIOSO
# (exit 0). Nunca bloqueia o start. Nunca imprime conteúdo de incidente nem
# segredos — apenas agregados (open_count, by_status). Cache de 10 min para não
# martelar prod ao abrir várias sessões em sequência.
# -----------------------------------------------------------------------------
set -uo pipefail

# SessionStart entrega JSON no stdin (inclui "cwd"). Extraímos sem depender de jq.
INPUT="$(cat 2>/dev/null || true)"
CWD="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "${CWD:-}" ] && CWD="$PWD"
cd "$CWD" 2>/dev/null || exit 0

# Precisa ser um working tree git E ter o CLI do gateway (gate para ideiapartner).
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
CLI="$ROOT/scripts/ops-db-query.mjs"
[ -f "$CLI" ] || exit 0

REPO="$(basename "$ROOT")"
CACHE_DIR="$HOME/.local/state/backlog-sync-check"
CACHE="$CACHE_DIR/$REPO.txt"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

# Freshness: consultado há < 600s → reemite o cache e NÃO vai à rede de novo.
if [ -f "$CACHE" ]; then
  NOW="$(date +%s)"
  MT="$(stat -f %m "$CACHE" 2>/dev/null || stat -c %Y "$CACHE" 2>/dev/null || echo 0)"
  if [ $((NOW - MT)) -lt 600 ]; then
    cat "$CACHE" 2>/dev/null
    exit 0
  fi
fi

# Resolve o node (o PATH do hook pode não ter; tenta o nvm como fallback).
NODE="$(command -v node 2>/dev/null || true)"
[ -z "$NODE" ] && NODE="$(ls -1 "$HOME"/.nvm/versions/node/*/bin/node 2>/dev/null | sort -V | tail -1)"
[ -x "${NODE:-/nonexistent}" ] || exit 0

# Consulta read-only, com timeout. Falha / offline / sem token → silencioso.
if command -v timeout >/dev/null 2>&1; then
  OUT="$(timeout 12 "$NODE" "$CLI" incident_backlog_snapshot 2>/dev/null)"
else
  OUT="$("$NODE" "$CLI" incident_backlog_snapshot 2>/dev/null)"
fi
[ -z "$OUT" ] && exit 0

# open_count é o sinal. Sem ele (erro/payload inesperado) → silencioso, sem cachear.
OPEN="$(printf '%s' "$OUT" | grep -o '"open_count"[[:space:]]*:[[:space:]]*[0-9]\{1,\}' | grep -o '[0-9]\{1,\}' | head -1)"
case "${OPEN:-}" in ''|*[!0-9]*) exit 0 ;; esac

PEND="$(printf '%s' "$OUT" | grep -o '"pendente"[[:space:]]*:[[:space:]]*[0-9]\{1,\}' | grep -o '[0-9]\{1,\}' | head -1)"
CORR="$(printf '%s' "$OUT" | grep -o '"em_correcao"[[:space:]]*:[[:space:]]*[0-9]\{1,\}' | grep -o '[0-9]\{1,\}' | head -1)"
SLA="$(printf '%s'  "$OUT" | grep -o '"sla_breached_open"[[:space:]]*:[[:space:]]*[0-9]\{1,\}' | grep -o '[0-9]\{1,\}' | head -1)"

DETAIL="open=$OPEN"
[ -n "${PEND:-}" ] && DETAIL="$DETAIL pendente=$PEND"
[ -n "${CORR:-}" ] && DETAIL="$DETAIL em_correcao=$CORR"
if [ -n "${SLA:-}" ] && [ "${SLA:-0}" -gt 0 ] 2>/dev/null; then DETAIL="$DETAIL SLA_estourado=$SLA"; fi

if [ "$OPEN" -gt 0 ]; then
  MSG="$(printf '⚠️ [backlog-sync] %s: %s incidente(s) ABERTO(S) em prod (%s).\nA fonte de verdade do backlog é PROD, não o handoff. Antes de afirmar "Pendências Cloud" / "próximo passo", confronte com isto — só trate como pendente o que casar com estes incidentes. Detalhe: `npm run ops:db -- list_open_incidents`.' "$REPO" "$OPEN" "$DETAIL")"
else
  MSG="$(printf '✅ [backlog-sync] %s: 0 incidentes abertos em prod (backlog limpo). Se o handoff/STATE ainda listar "Pendências Cloud", está DESATUALIZADO — já foi resolvido/publicado. NÃO persiga backlog fantasma; reconcilie o handoff.' "$REPO")"
fi

# Imprime (vira contexto da sessão) e guarda no cache de freshness.
printf '%s\n' "$MSG" | tee "$CACHE" >/dev/null 2>&1 || true
printf '%s\n' "$MSG"
exit 0
