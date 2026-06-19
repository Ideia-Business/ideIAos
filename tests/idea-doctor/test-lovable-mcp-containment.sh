#!/usr/bin/env bash
# =============================================================================
# test-lovable-mcp-containment.sh — testa o check 7e do scripts/idea-doctor.sh
#
# O check 7e detecta regressão da contenção Lovable MCP: cada produto Lovable
# deve ter as 19 tools mutantes (prefixo 6f530143) em permissions.deny, em
# .claude/settings.json (tracked) OU .claude/settings.local.json (quando .claude
# é gitignored). Ref: docs/learnings/2026-06-18-uncommitted-security-config-is-ephemeral.md
#
# Cobre (extrai o python REAL do idea-doctor.sh — testa o código vivo, não cópia):
#   1. Produto Lovable (.lovable dir) c/ deny=19 em settings.json    → OK tracked
#   2. Produto Lovable (vite.config lovable-tagger) c/ deny=0        → BAD (a regressão)
#   3. Produto Lovable (package.json) c/ deny=19 só em .local.json   → OK local-only
#   4. Produto Lovable c/ deny=18 (boundary, 1 abaixo do limite)     → BAD
#   5. Repo NÃO-Lovable                                              → pulado (ausente)
#   6. Produto Lovable SEM .git                                      → pulado (ausente)
#   7. O próprio repo (exclude)                                      → pulado
#   8. SUMMARY|<found>|<bad> com contagens corretas (4 found, 2 bad)
#
# Estratégia: extrai o bloco python do 7e (o que contém def is_lovable) para um
# arquivo temp e roda contra um dev/ sandbox em /tmp — não toca o repo real.
# Uso:  bash tests/idea-doctor/test-lovable-mcp-containment.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_DIR/scripts/idea-doctor.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$SCRIPT" ] || { echo "Script não encontrado: $SCRIPT"; exit 1; }

SANDBOX="$(mktemp -d /tmp/ideiaos-lovable-mcp-test.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

# Extrai o bloco python do 7e — o heredoc PYEOF que contém "def is_lovable".
# Robusto à ordem dos heredocs (não assume "2º PYEOF").
PY="$SANDBOX/lov_check.py"
awk '
  /<<.?PYEOF.?$/ { inblk=1; buf=""; next }
  /^PYEOF$/      { if (inblk && buf ~ /def is_lovable/) { printf "%s", buf; exit } inblk=0; next }
  inblk          { buf = buf $0 "\n" }
' "$SCRIPT" > "$PY"

head "Extração do python 7e"
if [ -s "$PY" ] && grep -q "def is_lovable" "$PY"; then
  pass "bloco python 7e extraído do idea-doctor.sh ($(wc -l < "$PY" | tr -d ' ') linhas)"
else
  fail "não consegui extrair o bloco python 7e (idea-doctor.sh mudou de estrutura?)"
  echo -e "\nResumo: $PASS pass · $FAIL fail"; exit 1
fi

# ── Monta o dev/ sandbox ──────────────────────────────────────────────────────
DEV="$SANDBOX/dev"; mkdir -p "$DEV"
deny_json() { # $1 = nº de entradas com o prefixo
  python3 -c "import json,sys; n=int(sys.argv[1]); print(json.dumps({'permissions':{'deny':['mcp__6f530143-e779-405d-bf42-190cae4e231b__t%d'%i for i in range(n)]},'language':'pt'}))" "$1"
}
# exclude (o "repo" cujo nome é passado como exclude)
mkdir -p "$DEV/IdeiaOS/.git"
# 1. prod-ok: .lovable dir + settings.json deny=19
mkdir -p "$DEV/prod-ok/.git" "$DEV/prod-ok/.claude" "$DEV/prod-ok/.lovable"; deny_json 19 > "$DEV/prod-ok/.claude/settings.json"
# 2. prod-bad: vite.config lovable-tagger + deny=0
mkdir -p "$DEV/prod-bad/.git" "$DEV/prod-bad/.claude"; echo 'import { componentTagger } from "lovable-tagger";' > "$DEV/prod-bad/vite.config.ts"; echo '{"permissions":{"deny":[]},"language":"pt"}' > "$DEV/prod-bad/.claude/settings.json"
# 3. prod-local: package.json lovable + deny=19 só em settings.local.json
mkdir -p "$DEV/prod-local/.git" "$DEV/prod-local/.claude"; echo '{"devDependencies":{"lovable-tagger":"^1.0.0"}}' > "$DEV/prod-local/package.json"; deny_json 19 > "$DEV/prod-local/.claude/settings.local.json"
# 4. prod-edge: .lovable + deny=18 (boundary)
mkdir -p "$DEV/prod-edge/.git" "$DEV/prod-edge/.claude" "$DEV/prod-edge/.lovable"; deny_json 18 > "$DEV/prod-edge/.claude/settings.json"
# 5. notlovable: repo comum
mkdir -p "$DEV/notlovable/.git"; echo '{"name":"x"}' > "$DEV/notlovable/package.json"
# 6. nogit-lovable: tem .lovable mas sem .git
mkdir -p "$DEV/nogit-lovable/.lovable"

OUT="$(/usr/bin/python3 "$PY" "$DEV" "IdeiaOS" "6f530143" "19")"

head "Detecção e veredito por produto"
line() { echo "$OUT" | grep -m1 "^PROD|$1|"; }

assert_status() { # $1=produto $2=status esperado $3=persist esperado
  local l; l="$(line "$1")"
  if echo "$l" | grep -q "|$2|$3$"; then pass "$1 → $2/$3"; else fail "$1 → esperado $2/$3, obtido: ${l:-<ausente>}"; fi
}
assert_status prod-ok    OK  tracked
assert_status prod-bad   BAD missing
assert_status prod-local OK  local-only
assert_status prod-edge  BAD missing   # 18 < 19 → regressão

head "Exclusões (não devem aparecer)"
for skip in notlovable nogit-lovable IdeiaOS; do
  if echo "$OUT" | grep -q "^PROD|$skip|"; then fail "$skip NÃO devia ser listado"; else pass "$skip corretamente pulado"; fi
done

head "Sumário de contagem"
if echo "$OUT" | grep -q "^SUMMARY|4|2$"; then pass "SUMMARY|4|2 (4 produtos, 2 regressões)"; else fail "SUMMARY errado: $(echo "$OUT" | grep '^SUMMARY')"; fi

echo -e "\n${CYAN}━━━ Resultado ━━━${NC}"
echo -e "  ${GREEN}PASS: $PASS${NC}  ${RED}FAIL: $FAIL${NC}"
[ "$FAIL" -eq 0 ] || exit 1
