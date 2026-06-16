#!/usr/bin/env bash
# =============================================================================
# test-memory-export.sh — Smoke test for memory-export.sh (IdeiaOS v5, R5-08)
# SOURCE: IdeiaOS v5 — Phase 21
#
# Cria um repo git scratch (main + planning) e um diretório de memória nativa
# falso (apontado por IDEIAOS_MEM_MEMDIR). Roda o hook de export e verifica:
#
#   1. Um fato nativo NOVO aterrissa no branch `planning` (não em `main`, não no
#      working tree).
#   2. Re-rodar sem mudança é no-op SILENCIOSO (sem novo commit em planning).
#   3. Um fato contendo um SEGREDO é RECUSADO (não chega ao planning); um fato
#      limpo no mesmo lote passa.
#   4. O working tree e o branch `main` permanecem INTACTOS após o export.
#
# Determinismo: IDEIAOS_MEM_DATE fixa a data da mensagem de commit.
# Tudo em diretórios temporários — nada toca o repo real nem ~/.claude.
#
# Exit: 0 = todos os testes passaram · 1 = alguma falha.
# =============================================================================
set -uo pipefail

FAILS=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_ROOT/source/hooks/memory-export.sh"

[ -f "$HOOK" ] || { echo "FAIL: hook ausente em $HOOK"; exit 1; }

# ── Helpers ──────────────────────────────────────────────────────────────────
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; FAILS=$((FAILS + 1)); }

planning_has() {  # $1 = path relativo dentro do tree do planning
  git -C "$SCRATCH" show "planning:$1" >/dev/null 2>&1
}
planning_count() { git -C "$SCRATCH" rev-list --count planning 2>/dev/null || echo 0; }
main_count()     { git -C "$SCRATCH" rev-list --count main 2>/dev/null || echo 0; }

run_hook() {  # roda o hook com cwd = SCRATCH, env determinístico
  IDEIAOS_MEM_DATE="2026-06-14" \
  IDEIAOS_MEM_MEMDIR="$MEMDIR" \
    bash "$HOOK" <<EOF 2>/dev/null
{"session_id":"test","cwd":"$SCRATCH"}
EOF
}

# ── Scratch git repo: main + planning ────────────────────────────────────────
SCRATCH="$(mktemp -d /tmp/ideiaos-mem-export-test-XXXXXX)"
MEMDIR="$(mktemp -d /tmp/ideiaos-mem-nativemem-XXXXXX)"
trap 'rm -rf "$SCRATCH" "$MEMDIR" 2>/dev/null || true' EXIT

git -C "$SCRATCH" init -q
git -C "$SCRATCH" config user.email "test@local"
git -C "$SCRATCH" config user.name "test"
echo "app source" > "$SCRATCH/app.txt"
git -C "$SCRATCH" add app.txt
git -C "$SCRATCH" commit -qm "init main"
git -C "$SCRATCH" branch planning

MAIN_HEAD_BEFORE="$(git -C "$SCRATCH" rev-parse main)"
PLANNING_BEFORE="$(planning_count)"

# Native MEMORY.md index (não é fato; deve ser ignorado pelo export).
cat > "$MEMDIR/MEMORY.md" <<'EOF'
# MEMORY.md — scratch
- [a clean fact](facts/learning_clean.md) — learning-clean
EOF

# ─────────────────────────────────────────────────────────────────────────────
# TEST 1 — fato nativo novo aterrissa no planning (não em main, não no tree)
# ─────────────────────────────────────────────────────────────────────────────
cat > "$MEMDIR/learning_clean.md" <<'EOF'
---
name: learning-clean
description: "Um fato limpo e exportável"
metadata:
  node_type: memory
  type: project
---

Este é um aprendizado normal, sem segredos. Deve ser exportado.
**Why:** validar o caminho feliz.
EOF

run_hook

if planning_has ".planning/memory/shared/facts/learning_clean.md"; then
  pass "T1: fato novo presente em planning:.planning/memory/shared/facts/"
else
  fail "T1: fato novo NÃO chegou ao planning"
fi

# Não pode estar em main.
if git -C "$SCRATCH" show "main:.planning/memory/shared/facts/learning_clean.md" >/dev/null 2>&1; then
  fail "T1: VAZAMENTO — fato apareceu em main"
else
  pass "T1: fato ausente em main (sem vazamento)"
fi

# Não pode estar no working tree (disco do branch corrente).
if [ -e "$SCRATCH/.planning" ]; then
  fail "T1: RESÍDUO — .planning apareceu no working tree do branch corrente"
else
  pass "T1: working tree sem resíduo .planning"
fi

# planning avançou exatamente 1 commit.
PLANNING_AFTER_T1="$(planning_count)"
if [ "$PLANNING_AFTER_T1" -eq "$((PLANNING_BEFORE + 1))" ]; then
  pass "T1: planning avançou 1 commit ($PLANNING_BEFORE → $PLANNING_AFTER_T1)"
else
  fail "T1: planning deveria ter +1 commit (antes=$PLANNING_BEFORE depois=$PLANNING_AFTER_T1)"
fi

# Mensagem de commit determinística.
LAST_MSG="$(git -C "$SCRATCH" log -1 --format=%s planning 2>/dev/null)"
if printf '%s' "$LAST_MSG" | grep -q "mem: sync from .* 2026-06-14"; then
  pass "T1: mensagem de commit determinística ('$LAST_MSG')"
else
  fail "T1: mensagem inesperada ('$LAST_MSG')"
fi

# O índice MEMORY.md shared foi regenerado.
if planning_has ".planning/memory/shared/MEMORY.md"; then
  pass "T1: índice shared MEMORY.md regenerado no planning"
else
  fail "T1: índice shared MEMORY.md ausente no planning"
fi

# ─────────────────────────────────────────────────────────────────────────────
# TEST 2 — re-rodar sem mudança = no-op silencioso (sem novo commit)
# ─────────────────────────────────────────────────────────────────────────────
OUT_NOOP="$(run_hook)"
PLANNING_AFTER_T2="$(planning_count)"
if [ "$PLANNING_AFTER_T2" -eq "$PLANNING_AFTER_T1" ]; then
  pass "T2: no-op — planning NÃO avançou (sem commit vazio)"
else
  fail "T2: re-run criou commit indevido (antes=$PLANNING_AFTER_T1 depois=$PLANNING_AFTER_T2)"
fi
if [ -z "$OUT_NOOP" ]; then
  pass "T2: no-op silencioso (sem saída)"
else
  fail "T2: no-op deveria ser silencioso, mas imprimiu: '$OUT_NOOP'"
fi

# ─────────────────────────────────────────────────────────────────────────────
# TEST 3 — fato com segredo é RECUSADO; fato limpo no mesmo lote passa
# ─────────────────────────────────────────────────────────────────────────────
# Fato com segredo (connection string com credencial + chave estilo OpenAI).
cat > "$MEMDIR/learning_secret.md" <<'EOF'
---
name: learning-secret
description: "Fato que acidentalmente contém um segredo"
metadata:
  node_type: memory
  type: project
---

Conectamos ao banco com postgres://admin:SuperSecret123@db.internal:5432/prod
e usamos a chave sk-abcdEFGH1234567890ijklMNOP para a API.
EOF

# Fato limpo novo no mesmo lote.
cat > "$MEMDIR/learning_second.md" <<'EOF'
---
name: learning-second
description: "Segundo fato limpo"
metadata:
  node_type: memory
  type: project
---

Outro aprendizado normal, sem credenciais. Deve passar no secret-scan.
EOF

OUT_SECRET="$(run_hook)"

if planning_has ".planning/memory/shared/facts/learning_secret.md"; then
  fail "T3: VAZAMENTO DE SEGREDO — fato com credencial chegou ao planning"
else
  pass "T3: fato com segredo RECUSADO (ausente do planning)"
fi
if planning_has ".planning/memory/shared/facts/learning_second.md"; then
  pass "T3: fato limpo do mesmo lote foi exportado"
else
  fail "T3: fato limpo NÃO foi exportado (gate cego demais?)"
fi
if printf '%s' "$OUT_SECRET" | grep -qi "RECUSADO"; then
  pass "T3: mensagem clara de recusa emitida"
else
  fail "T3: nenhuma mensagem de recusa (esperado aviso 'RECUSADO')"
fi
# E o segredo nunca pode estar em main tampouco.
if git -C "$SCRATCH" show "main:.planning/memory/shared/facts/learning_secret.md" >/dev/null 2>&1; then
  fail "T3: VAZAMENTO — segredo apareceu em main"
else
  pass "T3: segredo ausente de main"
fi

# ─────────────────────────────────────────────────────────────────────────────
# TEST 4 — working tree + main intactos após todos os exports
# ─────────────────────────────────────────────────────────────────────────────
MAIN_HEAD_AFTER="$(git -C "$SCRATCH" rev-parse main)"
if [ "$MAIN_HEAD_AFTER" = "$MAIN_HEAD_BEFORE" ]; then
  pass "T4: main HEAD inalterado ($MAIN_HEAD_BEFORE)"
else
  fail "T4: main HEAD MUDOU ($MAIN_HEAD_BEFORE → $MAIN_HEAD_AFTER)"
fi

# Branch corrente ainda é main e o working tree está limpo.
CUR_BRANCH="$(git -C "$SCRATCH" symbolic-ref --short HEAD 2>/dev/null)"
if [ "$CUR_BRANCH" = "main" ]; then
  pass "T4: branch corrente ainda é main (sem checkout)"
else
  fail "T4: branch corrente mudou para '$CUR_BRANCH'"
fi
if [ -z "$(git -C "$SCRATCH" status --porcelain 2>/dev/null)" ]; then
  pass "T4: working tree limpo (sem arquivos não rastreados/modificados)"
else
  fail "T4: working tree SUJO após export:"
  git -C "$SCRATCH" status --porcelain | sed 's/^/      /'
fi
# Sanidade: o app.txt original intacto.
if [ "$(cat "$SCRATCH/app.txt" 2>/dev/null)" = "app source" ]; then
  pass "T4: conteúdo do working tree (app.txt) intacto"
else
  fail "T4: app.txt foi alterado"
fi

# ─────────────────────────────────────────────────────────────────────────────
# TEST 5 — REGRESSÃO (bug dogfood 2026-06-14): local/staging NUNCA é commitado
# no planning. update-index ignora .gitignore, então a barreira é não adicionar
# staging à árvore. Buffer per-máquina não pode vazar pro remoto (Phase 19 SC#4).
# ─────────────────────────────────────────────────────────────────────────────
if git -C "$SCRATCH" ls-tree -r --name-only planning 2>/dev/null | grep -q 'memory/local'; then
  fail "T5: local/staging foi commitado no planning (regressão do bug dogfood)"
  git -C "$SCRATCH" ls-tree -r --name-only planning | grep 'memory/local' | sed 's/^/      /'
else
  pass "T5: local/staging NÃO commitado no planning (buffer per-máquina isolado)"
fi

# ── Resumo ───────────────────────────────────────────────────────────────────
echo ""
if [ "$FAILS" -eq 0 ]; then
  echo "ALL TESTS PASSED (memory-export.sh)"
  exit 0
else
  echo "$FAILS TEST(S) FAILED (memory-export.sh)"
  exit 1
fi
