#!/usr/bin/env bash
# SOURCE: IdeiaOS v14.1 | kind: gate | targets: claude,cursor
# =============================================================================
# test-recorder.sh — Gate A12 do Flight Recorder v0 (R14-05).
#
# Re-deriva a fita do git LOCAL (mesmo reader da Task 1: git log -- versions.lock
# + git show <H>:versions.lock | grep '^gsd=') num /tmp sandbox e compara
# SET-to-SET contra o render (apps/cockpit/src/flight-recorder.json):
#
#   exit 0  <=>  conjunto {hash8|gsd} idêntico  E  >=1 nó reversal (amber)
#   exit 1  <=>  a fita do render DIVERGIU da fonte git, OU nenhum nó amber
#
# LAW (git) vs INTERPRETED: o gate só compara pin/ordem (LAW). A narrativa não
# entra aqui. <absent> é tratado como string literal, igual ao render.
#
# Sandbox /tmp + autosync pausado (verify-guards-in-sandbox-not-live-repo,
# autosync-races-ai-git-surgery): a LEITURA do histórico de versions.lock é
# read-only (git log/show), mas a re-derivação grava SÓ em /tmp — nunca toca o
# working tree do repo.
#
# Override (anti-teatro): FR_JSON=<path> aponta o gate a uma cópia /tmp do JSON
# (ex.: um nó mutado) — DEVE dar exit 1 (a fita divergiu da fonte git).
#
# Build script (não hook): exit 1 em falha.
#
# USO:
#   bash scripts/test-recorder.sh                 # gate (exit 0=ok / 1=divergiu)
#   FR_JSON=/tmp/fr-mutado.json bash scripts/test-recorder.sh   # apontar a um copy
# =============================================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_SCRIPT="$ROOT/apps/cockpit/scripts/build-flight-recorder.mjs"
RENDER_JSON="${FR_JSON:-$ROOT/apps/cockpit/src/flight-recorder.json}"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
ok()  { echo -e "${GREEN}  ✓${NC} $*"; }
err() { echo -e "${RED}  ✗${NC} $*"; }
info(){ echo -e "${CYAN}  ℹ${NC} $*"; }

# ── Antifragile gate (fallback inline) ───────────────────────────────────────
type assert_nonempty >/dev/null 2>&1 \
  || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }

# ── Pré-condições ────────────────────────────────────────────────────────────
if ! assert_nonempty "$BUILD_SCRIPT"; then
  err "build script ausente: $BUILD_SCRIPT"; exit 1
fi
if ! assert_nonempty "$RENDER_JSON"; then
  err "render JSON ausente ou vazio: $RENDER_JSON"; exit 1
fi
if ! command -v node >/dev/null 2>&1; then
  err "node não encontrado no PATH"; exit 1
fi

SANDBOX="$(mktemp -d "${TMPDIR:-/tmp}/fr-gate.XXXXXX")"
trap 'rm -rf "$SANDBOX"' EXIT

# ── 1) Re-derivar a fita do git LOCAL para um /tmp file ──────────────────────
# Reusa o EXATO build script (mesma derivação do render) gravando em /tmp —
# nunca em src/. O FLIGHT_RECORDER_OUT redireciona a escrita para o sandbox.
DERIVED_JSON="$SANDBOX/derived.json"
if ! FLIGHT_RECORDER_OUT="$DERIVED_JSON" node "$BUILD_SCRIPT" 2>/dev/null; then
  err "falha ao re-derivar a fita do git"; exit 1
fi
if ! assert_nonempty "$DERIVED_JSON"; then
  err "re-derivação não produziu fita"; exit 1
fi

# ── 2) Extrair o SET {hash8|gsd} ordenado de cada lado ───────────────────────
set_of() {
  node -e '
    const fs = require("node:fs");
    const a = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const set = a.map(n => `${n.hash8}|${n.gsd}`).sort();
    process.stdout.write(set.join("\n") + "\n");
  ' "$1"
}

GIT_SET="$SANDBOX/git.set"
RENDER_SET="$SANDBOX/render.set"
set_of "$DERIVED_JSON"  > "$GIT_SET"   || { err "falha ao extrair SET do git";   exit 1; }
set_of "$RENDER_JSON"   > "$RENDER_SET" || { err "falha ao extrair SET do render"; exit 1; }

# ── 3) SET-to-SET: git == render ─────────────────────────────────────────────
if ! diff -u "$GIT_SET" "$RENDER_SET" >"$SANDBOX/diff.txt" 2>&1; then
  err "a fita do render DIVERGIU da fonte git (SET {hash8|gsd}):"
  sed 's/^/      /' "$SANDBOX/diff.txt" >&2
  exit 1
fi
ok "SET-to-SET git == render ($(wc -l < "$GIT_SET" | tr -d ' ') nós {hash8|gsd})"

# ── 4) Asserção >=1 nó reversal (amber) — o flip-flop real existe ────────────
REVERSALS=$(node -e '
  const fs = require("node:fs");
  const a = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(String(a.filter(n => n.reversal === true).length));
' "$RENDER_JSON")

if [ "${REVERSALS:-0}" -lt 1 ]; then
  err "nenhum nó reversal (amber) na fita — o flip-flop do daemon não aparece"
  exit 1
fi
ok ">=1 nó reversal (amber): $REVERSALS"

info "Flight Recorder v0: fita íntegra vs git + flip-flop presente"
exit 0
