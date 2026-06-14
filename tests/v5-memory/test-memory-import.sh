#!/usr/bin/env bash
# =============================================================================
# test-memory-import.sh — Smoke test harness for memory-import.sh
#                         (IdeiaOS v5 — Phase 20 / R5-07, import bridge)
#
# Cria repos git de teste (scratch) com um branch `planning` contendo fatos
# shared de exemplo, e verifica:
#   - import popula a memória nativa (~/.claude/projects/<slug>/memory/)
#   - emite systemMessage com a contagem importada
#   - regenera o índice MEMORY.md e a ponte Cursor (.mdc gitignored)
#   - é idempotente (2ª execução com mesmo SHA → no-op, freshness guard)
#   - tolera branch planning ausente (exit 0, sem escrita)
#   - tolera repo sem nada/offline (exit 0)
#   - resiste ao bug #30828 de slug (variante com underscore e com hífen)
#
# Usa um HOME temporário para não poluir o ~/.claude e ~/.local/state reais.
# O store canônico só vive no branch `planning` (NUNCA `main`) — invariante
# Lovable: o working tree do branch corrente nunca recebe arquivo de memória.
#
# Sem-jq: só /usr/bin/python3 para asserts de JSON. set -uo pipefail.
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed
# =============================================================================
set -uo pipefail

FAILS=0
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_ROOT/source/hooks/memory-import.sh"

# ---------------------------------------------------------------------------
# HOME temporário isolado (não toca o real ~/.claude / ~/.local/state).
# Mantemos um cofre fora do HOME para colocar os repos scratch — assim o slug
# (derivado do path absoluto) é estável e independente do HOME.
# ---------------------------------------------------------------------------
ORIG_HOME="$HOME"
TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/ideiaos-test-home.XXXXXX")"
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/ideiaos-test-scratch.XXXXXX")"
export HOME="$TMP_HOME"
trap 'rm -rf "$TMP_HOME" "$SCRATCH" 2>/dev/null || true; export HOME="$ORIG_HOME"' EXIT

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
assert_file_exists() {
  local path="$1"; local name="$2"
  if [ -f "$path" ]; then echo "PASS: $name"
  else echo "FAIL: $name — expected file '$path' to exist"; FAILS=$((FAILS + 1)); fi
}
assert_file_not_exists() {
  local path="$1"; local name="$2"
  if [ ! -f "$path" ]; then echo "PASS: $name"
  else echo "FAIL: $name — '$path' should NOT exist"; FAILS=$((FAILS + 1)); fi
}
assert_contains_file() {
  local file="$1"; local pat="$2"; local name="$3"
  if grep -qF "$pat" "$file" 2>/dev/null; then echo "PASS: $name"
  else echo "FAIL: $name — expected '$pat' in $file"; FAILS=$((FAILS + 1)); fi
}
assert_contains_str() {
  local hay="$1"; local pat="$2"; local name="$3"
  if printf '%s' "$hay" | grep -qF "$pat"; then echo "PASS: $name"
  else echo "FAIL: $name — expected output to contain '$pat'"; echo "      got: $(printf '%s' "$hay" | head -3)"; FAILS=$((FAILS + 1)); fi
}
assert_empty() {
  local hay="$1"; local name="$2"
  if [ -z "$hay" ]; then echo "PASS: $name"
  else echo "FAIL: $name — expected empty output, got: $(printf '%s' "$hay" | head -3)"; FAILS=$((FAILS + 1)); fi
}
assert_exit_zero() {
  local code="$1"; local name="$2"
  if [ "$code" -eq 0 ]; then echo "PASS: $name"
  else echo "FAIL: $name — expected exit 0, got $code"; FAILS=$((FAILS + 1)); fi
}
assert_eq() {
  local got="$1"; local want="$2"; local name="$3"
  if [ "$got" = "$want" ]; then echo "PASS: $name"
  else echo "FAIL: $name — expected '$want', got '$got'"; FAILS=$((FAILS + 1)); fi
}

# slug nativo: path absoluto → '/' vira '-', resto preservado (igual ao hook).
# IMPORTANTE: o hook deriva o slug de `git rev-parse --show-toplevel`, que no
# macOS canonicaliza symlinks (/tmp → /private/tmp). Por isso resolvemos o
# toplevel do repo (não o path cru do mktemp) para casar com o hook.
slug_of() { printf '%s' "$1" | tr '/' '-'; }
slug_of_repo() {
  local repo="$1"
  local top
  top="$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null || echo "$repo")"
  printf '%s' "$top" | tr '/' '-'
}

# Escreve um fato de exemplo no diretório de facts shared (formato nativo).
write_fact() {
  local dir="$1"; local fname="$2"; local fname_meta="$3"; local desc="$4"; local body="$5"
  mkdir -p "$dir"
  cat > "$dir/$fname" <<EOF
---
name: $fname_meta
description: $desc
metadata:
  node_type: memory
  type: project
  originSessionId: 00000000-0000-0000-0000-000000000000
---

$body
EOF
}

# Cria um repo git scratch com main + branch planning contendo o store shared.
# $1 = path do repo. Facts são passados como pares "arquivo|name|desc|body".
make_repo_with_planning() {
  local repo="$1"; shift
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@local"
  git -C "$repo" config user.name "test"
  git -C "$repo" config commit.gpgsign false
  # main: arquivo inócuo (NUNCA recebe memória)
  echo "# scratch project" > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "init main"
  # garantir nome do branch principal previsível
  git -C "$repo" branch -M main 2>/dev/null || true

  # planning branch: store shared/
  git -C "$repo" checkout -q -b planning
  local facts="$repo/.planning/memory/shared/facts"
  mkdir -p "$facts"
  echo "# MEMORY.md — shared" > "$repo/.planning/memory/shared/MEMORY.md"
  for spec in "$@"; do
    IFS='|' read -r ffile fname fdesc fbody <<< "$spec"
    write_fact "$facts" "$ffile" "$fname" "$fdesc" "$fbody"
  done
  git -C "$repo" add .planning
  git -C "$repo" commit -q -m "mem: seed shared facts"
  # voltar para main (estado normal de operação: planning não-checked-out)
  git -C "$repo" checkout -q main
}

run_hook() {
  # $1 = cwd; emite o JSON SessionStart e roda o hook, captura stdout e exit.
  local cwd="$1"
  printf '{"session_id":"smoketest","cwd":"%s","source":"startup"}' "$cwd" \
    | bash "$HOOK" 2>/dev/null
}

# ---------------------------------------------------------------------------
echo "--- Guard: hook present + executable ---"
if [ ! -x "$HOOK" ]; then
  echo "MISSING: $HOOK (not found or not executable)"
  FAILS=$((FAILS + 1))
fi
echo ""

# ===========================================================================
# Case 1 — Import populates native memory + emits systemMessage
# ===========================================================================
echo "--- Case 1: import populates native memory ---"
REPO1="$SCRATCH/projalpha"
make_repo_with_planning "$REPO1" \
  "learning_one.md|learning-one|Primeiro fato compartilhado de teste|Corpo do fato um.\n**Why:** porque sim." \
  "learning_two.md|learning-two|Segundo fato compartilhado de teste|Corpo do fato dois."

SLUG1="$(slug_of_repo "$REPO1")"
MEM1="$HOME/.claude/projects/$SLUG1/memory"

OUT1=""; EXIT1=0
OUT1="$(run_hook "$REPO1")" || EXIT1=$?
assert_exit_zero "$EXIT1" "Case 1: exit 0"
assert_file_exists "$MEM1/learning_one.md" "Case 1: learning_one.md imported"
assert_file_exists "$MEM1/learning_two.md" "Case 1: learning_two.md imported"
assert_file_exists "$MEM1/MEMORY.md" "Case 1: native MEMORY.md regenerated"
assert_contains_file "$MEM1/MEMORY.md" "learning_one.md" "Case 1: index references learning_one"
assert_contains_file "$MEM1/MEMORY.md" "Primeiro fato compartilhado de teste" "Case 1: index uses description as label"
assert_contains_str "$OUT1" "memory-import" "Case 1: systemMessage emitted"
assert_contains_str "$OUT1" "systemMessage" "Case 1: output is JSON with systemMessage key"
# count "2" in the message
assert_contains_str "$OUT1" "2 fato" "Case 1: systemMessage reports 2 imported facts"

# Cursor bridge generated + gitignored-safe (not in git status of work tree)
MDC1="$REPO1/.cursor/rules/memory-bridge.mdc"
assert_file_exists "$MDC1" "Case 1: Cursor .mdc bridge generated"
assert_contains_file "$MDC1" "alwaysApply: true" "Case 1: .mdc has alwaysApply: true"
assert_contains_file "$MDC1" "Primeiro fato compartilhado de teste" "Case 1: .mdc inlines shared facts"

# INVARIANTE LOVABLE: nada de arquivo de memória no working tree do branch main
assert_file_not_exists "$REPO1/.lovable_mem_tmp.md" "Case 1: no .lovable_mem_tmp.md leak"
WT_MEM="$(ls -1 "$REPO1"/.planning/memory 2>/dev/null || true)"
assert_empty "$WT_MEM" "Case 1: planning store NOT materialized in main working tree"
echo ""

# ===========================================================================
# Case 2 — Idempotent: 2nd run with same planning SHA is a no-op (freshness)
# ===========================================================================
echo "--- Case 2: idempotent 2nd run (freshness guard) ---"
OUT2=""; EXIT2=0
OUT2="$(run_hook "$REPO1")" || EXIT2=$?
assert_exit_zero "$EXIT2" "Case 2: exit 0"
assert_empty "$OUT2" "Case 2: 2nd run emits no systemMessage (no-op)"
# native memory unchanged (still exactly 2 facts + MEMORY.md)
N2="$(ls -1 "$MEM1"/*.md 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "$N2" "3" "Case 2: native memory unchanged (2 facts + MEMORY.md)"
echo ""

# ===========================================================================
# Case 2b — New planning commit advances SHA → import picks it up again
# ===========================================================================
echo "--- Case 2b: new shared fact after SHA bump is imported ---"
git -C "$REPO1" checkout -q planning
write_fact "$REPO1/.planning/memory/shared/facts" \
  "learning_three.md" "learning-three" "Terceiro fato adicionado depois" "Corpo do fato três."
git -C "$REPO1" add .planning
git -C "$REPO1" commit -q -m "mem: add third fact"
git -C "$REPO1" checkout -q main

OUT2B=""; EXIT2B=0
OUT2B="$(run_hook "$REPO1")" || EXIT2B=$?
assert_exit_zero "$EXIT2B" "Case 2b: exit 0"
assert_file_exists "$MEM1/learning_three.md" "Case 2b: new fact imported after SHA bump"
assert_contains_str "$OUT2B" "1 fato" "Case 2b: systemMessage reports 1 new fact"
echo ""

# ===========================================================================
# Case 3 — Missing planning branch → exit 0, no writes
# ===========================================================================
echo "--- Case 3: missing planning branch tolerated (exit 0) ---"
REPO3="$SCRATCH/projnoplan"
mkdir -p "$REPO3"
git -C "$REPO3" init -q
git -C "$REPO3" config user.email "test@local"
git -C "$REPO3" config user.name "test"
git -C "$REPO3" config commit.gpgsign false
echo "# no planning" > "$REPO3/README.md"
git -C "$REPO3" add README.md
git -C "$REPO3" commit -q -m "init"
git -C "$REPO3" branch -M main 2>/dev/null || true

SLUG3="$(slug_of_repo "$REPO3")"
MEM3="$HOME/.claude/projects/$SLUG3/memory"

OUT3=""; EXIT3=0
OUT3="$(run_hook "$REPO3")" || EXIT3=$?
assert_exit_zero "$EXIT3" "Case 3: exit 0 with no planning branch"
assert_empty "$OUT3" "Case 3: no systemMessage with no planning branch"
assert_file_not_exists "$MEM3/MEMORY.md" "Case 3: no native memory created (nothing to import)"
echo ""

# ===========================================================================
# Case 3b — Not a git repo at all → exit 0
# ===========================================================================
echo "--- Case 3b: non-git cwd tolerated (exit 0) ---"
NOGIT="$SCRATCH/notarepo"
mkdir -p "$NOGIT"
OUT3B=""; EXIT3B=0
OUT3B="$(run_hook "$NOGIT")" || EXIT3B=$?
assert_exit_zero "$EXIT3B" "Case 3b: exit 0 in non-git dir"
assert_empty "$OUT3B" "Case 3b: no output in non-git dir"
echo ""

# ===========================================================================
# Case 4 — Slug bug #30828: underscore variant already has native memory
#          → hook MUST import into the EXISTING (underscore) dir, not a new one
# ===========================================================================
echo "--- Case 4: slug #30828 — underscore variant honored ---"
# Repo path with an underscore so canonical slug keeps '_' but #30828 variant
# would normalize it to '-'. We pre-seed the underscore (canonical) dir with a
# local-only fact; the hook must import INTO it and PRESERVE the local fact.
REPO4="$SCRATCH/proj_underscore"
make_repo_with_planning "$REPO4" \
  "learning_shared.md|learning-shared|Fato shared para variante underscore|Corpo shared."

SLUG4_CANON="$(slug_of_repo "$REPO4")"            # ...-proj_underscore  (com '_')
SLUG4_HYPHEN="$(printf '%s' "$SLUG4_CANON" | tr '_' '-')"  # ...-proj-underscore
MEM4_CANON="$HOME/.claude/projects/$SLUG4_CANON/memory"
MEM4_HYPHEN="$HOME/.claude/projects/$SLUG4_HYPHEN/memory"

# Pre-seed the CANONICAL (underscore) dir with a local-only fact + MEMORY.md
mkdir -p "$MEM4_CANON"
write_fact "$MEM4_CANON" "learning_localonly.md" "learning-localonly" \
  "Fato apenas local que NAO esta no shared" "Corpo local-only."
echo "# MEMORY.md — seed" > "$MEM4_CANON/MEMORY.md"

OUT4=""; EXIT4=0
OUT4="$(run_hook "$REPO4")" || EXIT4=$?
assert_exit_zero "$EXIT4" "Case 4: exit 0"
# imported into the EXISTING underscore dir
assert_file_exists "$MEM4_CANON/learning_shared.md" "Case 4: shared fact imported into existing (underscore) dir"
# local-only fact preserved (NOT clobbered/deleted)
assert_file_exists "$MEM4_CANON/learning_localonly.md" "Case 4: local-only fact preserved"
# did NOT create the hyphen-variant dir
assert_file_not_exists "$MEM4_HYPHEN/learning_shared.md" "Case 4: did NOT spawn a 2nd (hyphen) memory dir"
# index includes both
assert_contains_file "$MEM4_CANON/MEMORY.md" "learning_shared.md" "Case 4: index has shared fact"
assert_contains_file "$MEM4_CANON/MEMORY.md" "learning_localonly.md" "Case 4: index keeps local-only fact"
echo ""

# ===========================================================================
# Case 4b — Slug bug #30828: hyphen variant already has native memory
#          → repo path has NO underscore, but a pre-existing hyphen dir holds
#            memory; we assert the canonical (== hyphen here) dir is used and a
#            local-only fact survives. (Symmetric coverage of pick_memory_dir.)
# ===========================================================================
echo "--- Case 4b: slug #30828 — canonical dir reused, local fact survives ---"
REPO4B="$SCRATCH/projplain"
make_repo_with_planning "$REPO4B" \
  "learning_s.md|learning-s|Fato shared simples|Corpo."

SLUG4B="$(slug_of_repo "$REPO4B")"
MEM4B="$HOME/.claude/projects/$SLUG4B/memory"
mkdir -p "$MEM4B"
write_fact "$MEM4B" "learning_keepme.md" "learning-keepme" "Local-only que sobrevive" "Corpo."
echo "# seed" > "$MEM4B/MEMORY.md"

OUT4B=""; EXIT4B=0
OUT4B="$(run_hook "$REPO4B")" || EXIT4B=$?
assert_exit_zero "$EXIT4B" "Case 4b: exit 0"
assert_file_exists "$MEM4B/learning_s.md" "Case 4b: shared fact imported into existing dir"
assert_file_exists "$MEM4B/learning_keepme.md" "Case 4b: local-only fact preserved"
echo ""

# ===========================================================================
# Summary
# ===========================================================================
echo "--- Results ---"
if [ "$FAILS" -gt 0 ]; then
  echo "FAILED: $FAILS test(s) failed"
  exit 1
else
  echo "ALL TESTS PASSED"
  exit 0
fi
