#!/usr/bin/env bash
# SOURCE: IdeiaOS v15 (R15-22)
# test-preop-guard.sh — prova o pre-op guard anti-autosync-race por exit-code.
#
# Dois alvos:
#   1. source/lib/surgery-lock.sh (produtor): begin/end/active + stale-guards.
#   2. source/autosync/git-autosync.sh (consumidor real): pula a cirurgia VIVA,
#      mas NUNCA trava numa sentinela stale (falha-segura).
#
# Sandbox /tmp + HOME falso (isola sentinela/log/pause-file). Sem rede.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER="$ROOT/source/lib/surgery-lock.sh"
AUTOSYNC="$ROOT/source/autosync/git-autosync.sh"
PASS=0; FAIL=0
ok()   { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad()  { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

SBX="$(mktemp -d "${TMPDIR:-/tmp}/preop-guard.XXXXXX")"
trap 'rm -rf "$SBX"' EXIT
export HOME="$SBX"   # isola: sentinela, log e pause-file vão para $SBX/.local/state
mkdir -p "$SBX/.local/state"
SENT="$SBX/.local/state/git-autosync.surgery"
ALOG="$SBX/.local/state/git-autosync.log"

# ── repo git de teste (work, 1 commit, SEM remote — fetch falhará de propósito) ──
REPO="$SBX/repo"; mkdir -p "$REPO"
git -C "$REPO" init -q -b work 2>/dev/null || { git -C "$REPO" init -q; git -C "$REPO" checkout -q -b work; }
git -C "$REPO" config user.email t@t; git -C "$REPO" config user.name t
echo a > "$REPO/a.txt"; git -C "$REPO" add -A; git -C "$REPO" commit -q -m init

run_autosync() { : > "$ALOG"; HOME="$SBX" bash "$AUTOSYNC" "$REPO" >/dev/null 2>&1 || true; }
log_has() { grep -q "$1" "$ALOG" 2>/dev/null; }

echo "── 1. helper surgery-lock.sh (produtor) ──"
# subshell: surgery_begin arma trap EXIT — não queremos que rode no shell de teste
( . "$HELPER"; surgery_begin "teste"; [ -f "$SENT" ] && grep -q "reason=teste" "$SENT"; ) \
  && ok "surgery_begin cria a sentinela com reason" || bad "surgery_begin não criou a sentinela"
# após o subshell sair, o trap EXIT do begin removeu a sentinela
[ ! -f "$SENT" ] && ok "trap EXIT removeu a sentinela ao sair (teardown garantido)" || { bad "sentinela vazou após EXIT"; rm -f "$SENT"; }

# surgery_active: fresca (pid vivo=deste shell, started=agora) → ATIVA (0)
printf 'pid=%s\nstarted=%s\nreason=x\nby=t\n' "$$" "$(date +%s)" > "$SENT"
( . "$HELPER"; surgery_active ) && ok "surgery_active=0 com sentinela fresca (pid vivo + TTL ok)" || bad "surgery_active devia ser 0 (fresca)"

# stale por PID morto → NÃO-ativa (1) — falha-segura
( exit 0 ) & DEAD=$!; wait "$DEAD" 2>/dev/null || true
printf 'pid=%s\nstarted=%s\nreason=x\nby=t\n' "$DEAD" "$(date +%s)" > "$SENT"
( . "$HELPER"; surgery_active ) && bad "surgery_active devia ser 1 (PID morto = stale)" || ok "surgery_active=1 com PID morto (stale → falha-segura)"

# stale por TTL expirado (pid vivo, started > 1800s atrás) → NÃO-ativa (1)
printf 'pid=%s\nstarted=%s\nreason=x\nby=t\n' "$$" "$(( $(date +%s) - 2000 ))" > "$SENT"
( . "$HELPER"; surgery_active ) && bad "surgery_active devia ser 1 (TTL expirado)" || ok "surgery_active=1 com TTL expirado (stale → falha-segura)"
rm -f "$SENT"

echo "── 2. autosync git-autosync.sh (consumidor real) ──"
# A) sentinela VIVA → autosync pula o repo por R15-22 e NÃO commita
printf 'pid=%s\nstarted=%s\nreason=x\nby=t\n' "$$" "$(date +%s)" > "$SENT"
BEFORE="$(git -C "$REPO" rev-parse HEAD)"
run_autosync
log_has "cirurgia git em andamento" && ok "autosync PULA com sentinela viva (loga R15-22)" || bad "autosync não pulou com sentinela viva"
[ "$(git -C "$REPO" rev-parse HEAD)" = "$BEFORE" ] && ok "autosync não tocou o repo (HEAD inalterado)" || bad "autosync mexeu no repo apesar da sentinela"
rm -f "$SENT"

# B) sentinela STALE (PID morto) → autosync NÃO pula por sentinela (falha-segura).
#    Sem remote, prossegue e cai em 'fetch falhou' — o que importa: NÃO travou por R15-22.
( exit 0 ) & DEAD=$!; wait "$DEAD" 2>/dev/null || true
printf 'pid=%s\nstarted=%s\nreason=x\nby=t\n' "$DEAD" "$(date +%s)" > "$SENT"
run_autosync
if log_has "cirurgia git em andamento"; then bad "autosync travou numa sentinela STALE (deveria ignorar)"; else ok "autosync IGNORA sentinela stale (PID morto) — falha-segura"; fi
rm -f "$SENT"

# C) índice .git/index.lock recente → autosync pula (operação git em curso)
: > "$REPO/.git/index.lock"
run_autosync
log_has "index.lock recente" && ok "autosync PULA com .git/index.lock recente" || bad "autosync não pulou com index.lock recente"
rm -f "$REPO/.git/index.lock"

echo ""
echo "── resultado: $PASS pass · $FAIL fail ──"
[ "$FAIL" -eq 0 ] || exit 1
