#!/usr/bin/env bash
# SOURCE: IdeiaOS v13
# =============================================================================
# test-security-freshness.sh — prova o motor do Selo de Frescor de Segurança
# num repo git SANDBOX em /tmp (nunca no repo vivo — ver learning
# verify-guards-in-sandbox-not-live-repo). Foco no CAMINHO DE FALHA: egrégio +
# gate ligado → exit 1 (o bloqueio de tag que importa).
#
# Exit: 0 = todos os asserts passaram · 1 = algum falhou
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_SRC="$REPO_ROOT/scripts/check-security-freshness.sh"
PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

[ -s "$SCRIPT_SRC" ] || { echo "FATAL: $SCRIPT_SRC ausente"; exit 1; }

# ── sandbox git repo ─────────────────────────────────────────────────────────
SBX="$(mktemp -d 2>/dev/null || mktemp -d -t secfresh)"
trap 'rm -rf "$SBX"' EXIT
mkdir -p "$SBX/scripts" "$SBX/src/ui"
cp "$SCRIPT_SRC" "$SBX/scripts/"
S="$SBX/scripts/check-security-freshness.sh"

git -C "$SBX" init -q
git -C "$SBX" config user.email t@t.t; git -C "$SBX" config user.name t
echo "ui" > "$SBX/src/ui/app.tsx"
git -C "$SBX" add -A; git -C "$SBX" commit -qm "base"

run() { ( cd "$SBX" && "$@" ); }   # roda com cwd no sandbox (ROOT do script = sandbox)

echo "━━━ test-security-freshness (sandbox: $SBX) ━━━"

# 1) sem ledger → unbootstrapped
T="$(run bash "$S" --tier)"
[ "$T" = "unbootstrapped" ] && ok "sem ledger → unbootstrapped" || bad "esperava unbootstrapped, veio '$T'"

# 2) bootstrap → ledger criado, tier ok (score 0)
run bash "$S" --bootstrap >/dev/null
[ -s "$SBX/.security/review-ledger.log" ] && ok "bootstrap criou ledger" || bad "ledger não criado"
T="$(run bash "$S" --tier)"
[ "$T" = "ok" ] && ok "pós-bootstrap → ok (score 0)" || bad "esperava ok, veio '$T'"

# 3) bootstrap idempotente (não duplica)
LINES_BEFORE="$(wc -l < "$SBX/.security/review-ledger.log")"
run bash "$S" --bootstrap >/dev/null
LINES_AFTER="$(wc -l < "$SBX/.security/review-ledger.log")"
[ "$LINES_BEFORE" = "$LINES_AFTER" ] && ok "bootstrap idempotente (não duplica)" || bad "bootstrap duplicou ($LINES_BEFORE→$LINES_AFTER)"

# 4) muda arquivo NEUTRO (UI) → continua ok (não move o ponteiro)
echo "x" >> "$SBX/src/ui/app.tsx"; git -C "$SBX" commit -qam "ui tweak"
T="$(run bash "$S" --tier)"
[ "$T" = "ok" ] && ok "mudança neutra (UI) não dispara (tier ok)" || bad "UI moveu o ponteiro indevidamente (veio '$T')"

# 5) mudança CRÍTICA (auth) com idade>CRIT_DAYS forçada → warn
mkdir -p "$SBX/src/auth"; echo "login" > "$SBX/src/auth/login.ts"
git -C "$SBX" add -A; git -C "$SBX" commit -qm "auth"
T="$(run env SECFRESH_CRIT_DAYS=0 bash "$S" --tier)"   # CRIT_DAYS=0 → crítico recente já conta
[ "$T" = "warn" ] && ok "1 mudança crítica + crit-grace → warn" || bad "esperava warn, veio '$T'"

# 6) score alto → egrégio (limiar baixo p/ determinismo)
T="$(run env SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=3 bash "$S" --tier)"
[ "$T" = "egregious" ] && ok "score ≥ limiar egrégio → egregious" || bad "esperava egregious, veio '$T'"

# 7) CAMINHO DE FALHA — egrégio + gate LIGADO → exit 1
run env SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=3 SECFRESH_GATE_ENABLED=1 bash "$S" --gate >/dev/null 2>&1
[ "$?" -eq 1 ] && ok "egrégio + gate LIGADO → exit 1 (tag bloqueada)" || bad "gate ligado não bloqueou (exit $?)"

# 8) egrégio + gate ADVISORY (default) → exit 0 (1º ciclo não bloqueia)
run env SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=3 SECFRESH_GATE_ENABLED=0 bash "$S" --gate >/dev/null 2>&1
[ "$?" -eq 0 ] && ok "egrégio + gate ADVISORY → exit 0 (não bloqueia no 1º ciclo)" || bad "gate advisory bloqueou indevidamente (exit $?)"

# 9) --record re-sela no HEAD → contador zera → tier volta a ok
run bash "$S" --record PASS tester >/dev/null
T="$(run env SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=3 bash "$S" --tier)"
[ "$T" = "ok" ] && ok "--record zerou o contador (tier volta a ok)" || bad "re-selo não zerou (veio '$T')"

echo "━━━ Resultado: $PASS OK · $FAIL FAIL ━━━"
[ "$FAIL" -eq 0 ] || exit 1
