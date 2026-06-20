#!/usr/bin/env bash
# SOURCE: IdeiaOS v13
# =============================================================================
# test-secfresh-hook-install.sh — prova a CAMADA de surfacing por produto (C):
# o hook post-commit ADVISORY + bootstrap de ledger local + .git/info/exclude,
# incluindo o caminho husky (core.hooksPath). Tudo em repo SANDBOX em /tmp (nunca
# no repo vivo — learning verify-guards-in-sandbox-not-live-repo).
#
# Foco: (a) o hook NUNCA bloqueia (post-commit, exit ignorado); (b) avisa em
# tier warn; (c) throttle evita spam; (d) husky-aware install + exclude local.
#
# Replica os passos de setup_security_freshness_layer() (setup.sh) usando o
# engine e o template REAIS — a função em si é validada end-to-end na propagação.
#
# Exit: 0 = todos os asserts passaram · 1 = algum falhou
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENGINE="$REPO_ROOT/scripts/check-security-freshness.sh"
TMPL="$REPO_ROOT/source/templates/security/post-commit-security-freshness.sh"
PASS=0; FAIL=0
ok()  { echo "  ✓ $*"; PASS=$((PASS+1)); }
bad() { echo "  ✗ $*"; FAIL=$((FAIL+1)); }

[ -s "$ENGINE" ] || { echo "FATAL: engine ausente: $ENGINE"; exit 1; }
[ -s "$TMPL" ]   || { echo "FATAL: template ausente: $TMPL"; exit 1; }

# Espelha setup_security_freshness_layer() — install num repo dado.
install_layer() {
  local pdir="$1"
  SECFRESH_ROOT="$pdir" bash "$ENGINE" --bootstrap >/dev/null 2>&1
  local xf="$pdir/.git/info/exclude"; mkdir -p "$pdir/.git/info"; touch "$xf"
  local e
  for e in ".security/review-ledger.log" ".security/.last-warn-epoch"; do
    grep -qxF "$e" "$xf" 2>/dev/null || echo "$e" >> "$xf"
  done
  local hp; hp="$(git -C "$pdir" config --get core.hooksPath 2>/dev/null || true)"
  local hd
  if [ -z "$hp" ]; then hd="$pdir/.git/hooks"
  elif [ "${hp:0:1}" = "/" ]; then hd="$hp"
  else hd="$pdir/$hp"; grep -qxF "$hp/post-commit" "$xf" 2>/dev/null || echo "$hp/post-commit" >> "$xf"; fi
  mkdir -p "$hd"
  sed "s|__ENGINE_PATH__|$ENGINE|g" "$TMPL" > "$hd/post-commit" && chmod +x "$hd/post-commit"
}

echo "━━━ test-secfresh-hook-install ━━━"

# ── Cenário 1: repo padrão (sem husky) ───────────────────────────────────────
S1="$(mktemp -d 2>/dev/null || mktemp -d -t s1)"
trap 'rm -rf "$S1" "${S2:-}"' EXIT
git -C "$S1" init -q; git -C "$S1" config user.email t@t.t; git -C "$S1" config user.name t
mkdir -p "$S1/src/ui"; echo ui > "$S1/src/ui/a.tsx"
git -C "$S1" add -A; git -C "$S1" -c commit.gpgsign=false commit -qm base

install_layer "$S1"

[ -x "$S1/.git/hooks/post-commit" ] && ok "hook instalado em .git/hooks/post-commit (default)" \
  || bad "hook não instalado no path default"
grep -q "ideiaos-security-freshness-hook" "$S1/.git/hooks/post-commit" \
  && ok "hook tem o marker" || bad "hook sem marker"
! grep -q "__ENGINE_PATH__" "$S1/.git/hooks/post-commit" \
  && ok "placeholder __ENGINE_PATH__ substituído" || bad "placeholder não substituído"
[ -s "$S1/.security/review-ledger.log" ] && ok "ledger-baseline local criado" || bad "ledger não criado"
grep -qxF ".security/review-ledger.log" "$S1/.git/info/exclude" \
  && ok "ledger em .git/info/exclude (local-only)" || bad "ledger não excluído"
grep -qxF ".security/.last-warn-epoch" "$S1/.git/info/exclude" \
  && ok "marcador de throttle excluído" || bad "marcador throttle não excluído"

# commit que vira tier=warn (forçado via env, que o git propaga ao hook)
mkdir -p "$S1/src/auth"; echo login > "$S1/src/auth/login.ts"; git -C "$S1" add -A
ERRF="$S1/.err1"
( cd "$S1" && SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=99 \
    git -c commit.gpgsign=false commit -qm "auth change" 2>"$ERRF" )
RC=$?
[ "$RC" -eq 0 ] && ok "commit com segurança defasada SUCEDE (hook não bloqueia)" \
  || bad "commit falhou (hook bloqueou — exit $RC)"
grep -q "Frescor de Segurança" "$ERRF" && ok "hook EMITIU WARN no tier warn" \
  || bad "hook não emitiu WARN (stderr: $(cat "$ERRF" 2>/dev/null | tr '\n' ' '))"
[ -f "$S1/.security/.last-warn-epoch" ] && ok "throttle marker gravado" || bad "throttle marker ausente"

# segundo commit imediato → throttled (sem segundo aviso)
echo x >> "$S1/src/ui/a.tsx"; git -C "$S1" add -A
ERRF2="$S1/.err2"
( cd "$S1" && SECFRESH_WARN_SCORE=1 SECFRESH_EGREGIOUS_SCORE=99 \
    git -c commit.gpgsign=false commit -qm "ui tweak" 2>"$ERRF2" )
! grep -q "Frescor de Segurança" "$ERRF2" && ok "2º commit imediato é THROTTLED (sem spam)" \
  || bad "throttle falhou — avisou de novo"

# fresco (sem env) → silencioso. Re-sela e commita neutro.
SECFRESH_ROOT="$S1" bash "$ENGINE" --record PASS tester >/dev/null 2>&1
rm -f "$S1/.security/.last-warn-epoch"
echo y >> "$S1/src/ui/a.tsx"; git -C "$S1" add -A
ERRF3="$S1/.err3"
( cd "$S1" && git -c commit.gpgsign=false commit -qm "neutral" 2>"$ERRF3" )
! grep -q "Frescor de Segurança" "$ERRF3" && ok "tier ok → hook silencioso" \
  || bad "hook falou estando fresco"

# ── Cenário 2: repo com husky (core.hooksPath=.husky, tracked) ───────────────
S2="$(mktemp -d 2>/dev/null || mktemp -d -t s2)"
git -C "$S2" init -q; git -C "$S2" config user.email t@t.t; git -C "$S2" config user.name t
mkdir -p "$S2/.husky"; echo "echo pre" > "$S2/.husky/pre-commit"; chmod +x "$S2/.husky/pre-commit"
git -C "$S2" config core.hooksPath .husky
echo a > "$S2/f.txt"; git -C "$S2" add -A; git -C "$S2" -c commit.gpgsign=false commit -qm base

install_layer "$S2"

[ -x "$S2/.husky/post-commit" ] && ok "husky: hook instalado em .husky/post-commit" \
  || bad "husky: hook não instalado no hooksPath"
grep -qxF ".husky/post-commit" "$S2/.git/info/exclude" \
  && ok "husky: hook tracked-dir adicionado a .git/info/exclude (não-versionado)" \
  || bad "husky: hook não excluído (vazaria p/ commit em main)"
[ -x "$S2/.husky/pre-commit" ] && grep -q "echo pre" "$S2/.husky/pre-commit" \
  && ok "husky: pre-commit pré-existente preservado" || bad "husky: clobberou pre-commit"

echo "━━━ Resultado: $PASS OK · $FAIL FAIL ━━━"
[ "$FAIL" -eq 0 ] || exit 1
