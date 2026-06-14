#!/usr/bin/env bash
# =============================================================================
# test-guardrails.sh — testa as 6 barreiras anti-churn de memória (Fase 18).
#
# Cobre:
#   1. check-memory-not-on-main.sh BLOQUEIA memória staged no branch `main`
#   2. ...e PASSA quando o branch é `planning` ou `work`
#   3. A lógica de exclusão do autosync NÃO faz stage de caminhos de memória
#   4. Um merge simulado `planning`→`main` com memória é BLOQUEADO
#   5. IDEIAOS_MEM_OVERRIDE=1 libera o bloqueio (bypass consciente)
#
# Cria repos descartáveis em /tmp — não toca refs/estado do repo real.
# Uso:  bash tests/v5-memory/test-guardrails.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GUARD="$REPO_DIR/scripts/check-memory-not-on-main.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$GUARD" ] || { echo "guard não encontrado: $GUARD"; exit 1; }

# Sandbox isolada — sem config/hooks da máquina influenciando o teste.
SANDBOX="$(mktemp -d /tmp/ideiaos-mem-test.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=t@t

# mk_repo <dir> — repo git com main + planning + work; o guard é copiado para
# scripts/ dentro do repo (o guard resolve REPO_DIR via BASH_SOURCE/..).
mk_repo() {
  local d="$1"
  mkdir -p "$d/scripts"
  cp "$GUARD" "$d/scripts/check-memory-not-on-main.sh"
  git -C "$d" init -q -b main
  echo "# project" > "$d/README.md"
  git -C "$d" add README.md scripts/check-memory-not-on-main.sh
  git -C "$d" commit -q -m "init"
  git -C "$d" branch planning
  git -C "$d" branch work
}

run_guard() {  # run_guard <repo> <mode> ; ecoa exit code
  local d="$1" mode="$2"
  ( cd "$d" && bash scripts/check-memory-not-on-main.sh "$mode" >/dev/null 2>&1 )
  echo $?
}

# ── Teste 1: memória staged em `main` é bloqueada ────────────────────────────
head "1) Guard bloqueia memória staged em main"
R="$SANDBOX/r1"; mk_repo "$R"
git -C "$R" checkout -q main
mkdir -p "$R/.planning/memory/shared/facts"
echo "secret-free fact" > "$R/.planning/memory/shared/facts/learning_x.md"
git -C "$R" add .planning/memory/shared/facts/learning_x.md
rc="$(run_guard "$R" --staged)"
[ "$rc" = "1" ] && pass "fato de memória staged em main → exit 1 (bloqueado)" \
                || fail "esperava exit 1, veio $rc"

# leak histórico untracked no working tree de main também é pego (sem --staged)
echo "leak" > "$R/.lovable_mem_tmp.md"
rc="$(run_guard "$R" "")"
[ "$rc" = "1" ] && pass ".lovable_mem_tmp.md no working tree de main → bloqueado" \
                || fail "esperava exit 1 (working tree), veio $rc"

# ── Teste 2: memória em planning / work passa ────────────────────────────────
head "2) Guard passa em planning e work"
R="$SANDBOX/r2"; mk_repo "$R"
git -C "$R" checkout -q planning
mkdir -p "$R/.planning/memory/shared/facts"
echo "fact" > "$R/.planning/memory/shared/facts/learning_y.md"
git -C "$R" add .planning/memory/shared/facts/learning_y.md
rc="$(run_guard "$R" --staged)"
[ "$rc" = "0" ] && pass "memória staged em planning → exit 0 (permitido)" \
                || fail "esperava exit 0 em planning, veio $rc"

git -C "$R" reset -q
git -C "$R" checkout -q work
echo "fact" > "$R/.planning/memory/shared/facts/learning_z.md"
git -C "$R" add .planning/memory/shared/facts/learning_z.md
rc="$(run_guard "$R" --staged)"
[ "$rc" = "0" ] && pass "memória staged em work → exit 0 (trânsito interno ok)" \
                || fail "esperava exit 0 em work, veio $rc"

# ── Teste 3: exclusão de autosync pula caminhos de memória ───────────────────
# Replica a lógica do git-autosync: em work, exclui memory/local + bridge mdc;
# em main, exclui também todo .planning/memory + .lovable_mem_tmp.md.
head "3) Exclusão do autosync pula memória"
R="$SANDBOX/r3"; mk_repo "$R"

# 3a — branch work: shared deve ENTRAR; local e bridge devem ficar de FORA
git -C "$R" checkout -q work
mkdir -p "$R/.planning/memory/shared/facts" "$R/.planning/memory/local/staging" "$R/.cursor/rules"
echo "shared" > "$R/.planning/memory/shared/facts/learning_a.md"
echo "local"  > "$R/.planning/memory/local/staging/draft.md"
echo "bridge" > "$R/.cursor/rules/memory-bridge.mdc"
WORK_EXCLUDES=(":(exclude)versions.lock" ":(exclude).planning/memory/local" ":(exclude).cursor/rules/memory-bridge.mdc")
( cd "$R" && git add -A -- . "${WORK_EXCLUDES[@]}" )
STAGED="$(git -C "$R" diff --cached --name-only)"
echo "$STAGED" | grep -q '.planning/memory/local/staging/draft.md' \
  && fail "autosync(work) NÃO devia stage memory/local" \
  || pass "autosync(work) excluiu .planning/memory/local"
echo "$STAGED" | grep -q '.cursor/rules/memory-bridge.mdc' \
  && fail "autosync(work) NÃO devia stage memory-bridge.mdc" \
  || pass "autosync(work) excluiu memory-bridge.mdc"
echo "$STAGED" | grep -q '.planning/memory/shared/facts/learning_a.md' \
  && pass "autosync(work) incluiu shared/ (store em trânsito interno ok)" \
  || fail "autosync(work) devia incluir shared/"

# 3b — branch main: NENHUM caminho de memória pode ser staged
git -C "$R" reset -q
git -C "$R" checkout -q main
mkdir -p "$R/.planning/memory/shared/facts" "$R/.cursor/rules"
echo "shared" > "$R/.planning/memory/shared/facts/learning_b.md"
echo "leak"   > "$R/.lovable_mem_tmp.md"
echo "bridge" > "$R/.cursor/rules/memory-bridge.mdc"
MAIN_EXCLUDES=(":(exclude)versions.lock" ":(exclude).planning/memory/local" ":(exclude).cursor/rules/memory-bridge.mdc" ":(exclude).planning/memory" ":(exclude).lovable_mem_tmp.md")
( cd "$R" && git add -A -- . "${MAIN_EXCLUDES[@]}" )
STAGED="$(git -C "$R" diff --cached --name-only)"
if echo "$STAGED" | grep -qE '(\.planning/memory|\.lovable_mem_tmp\.md|memory-bridge\.mdc)'; then
  fail "autosync(main) deixou memória passar: $(echo "$STAGED" | tr '\n' ' ')"
else
  pass "autosync(main) não fez stage de nenhum caminho de memória"
fi

# ── Teste 4: merge planning→main com memória é bloqueado ─────────────────────
head "4) Merge planning→main com memória é bloqueado"
R="$SANDBOX/r4"; mk_repo "$R"
# Cria um fato de memória no planning
git -C "$R" checkout -q planning
mkdir -p "$R/.planning/memory/shared/facts"
echo "fact" > "$R/.planning/memory/shared/facts/learning_m.md"
git -C "$R" add .planning/memory/shared/facts/learning_m.md
git -C "$R" commit -q -m "mem: add fact on planning"
# Volta para main e tenta o merge SEM commitar (--no-commit --no-ff) para deixar
# MERGE_HEAD presente; então roda o guard em modo --merge.
git -C "$R" checkout -q main
git -C "$R" merge --no-commit --no-ff planning >/dev/null 2>&1 || true
rc="$(run_guard "$R" --merge)"
[ "$rc" = "1" ] && pass "merge planning→main → exit 1 (bloqueado, direcional)" \
                || fail "esperava exit 1 no merge planning→main, veio $rc"
git -C "$R" merge --abort 2>/dev/null || true

# ── Teste 5: override consciente libera ──────────────────────────────────────
head "5) IDEIAOS_MEM_OVERRIDE=1 libera o bloqueio"
R="$SANDBOX/r5"; mk_repo "$R"
git -C "$R" checkout -q main
mkdir -p "$R/.planning/memory/shared/facts"
echo "fact" > "$R/.planning/memory/shared/facts/learning_o.md"
git -C "$R" add .planning/memory/shared/facts/learning_o.md
rc="$( cd "$R" && IDEIAOS_MEM_OVERRIDE=1 bash scripts/check-memory-not-on-main.sh --staged >/dev/null 2>&1; echo $? )"
[ "$rc" = "0" ] && pass "override=1 em main → exit 0 (bypass consciente)" \
                || fail "esperava exit 0 com override, veio $rc"

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ todas as barreiras OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ há barreiras falhando${NC}\n"; exit 1; }
