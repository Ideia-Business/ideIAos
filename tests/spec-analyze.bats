#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
#
# tests/spec-analyze.bats
# Fixture-regression de spec-analyze.sh e spec-converge.sh (W4).
# Dual-mode: roda com bats OU com bash puro (fallback) — igual a spec-merge.bats.
#   bats tests/spec-analyze.bats   (se disponível)
#   bash tests/spec-analyze.bats   (fallback puro — usado no CI e no SOAK)
#
# DRIFT CONHECIDO injetado (1 defeito HARD por capability, p/ localizar a falha):
#   auth    → A1 (requisito sem cenário)
#   billing → A2 (cenário com 3 hashtags, além de um #### válido → só A2, não A1)
#   dup     → A3 (header de requisito duplicado, ambos com cenário)
#   leaked  → A4 (## MODIFICADO vazado na fonte, req com cenário)
#   ghost   → A5 (ADVISORY: path de código citado inexistente)
#   search  → 100% limpa DENTRO do produto-drift (prova: sem FP em cap sã)
# produto-clean → todas corretas.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANALYZE="$REPO_ROOT/source/skills/spec/lib/spec-analyze.sh"
CONVERGE="$REPO_ROOT/source/skills/spec/lib/spec-converge.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}ok${NC}: %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}FAIL${NC}: %s\n" "$*"; FAIL=$((FAIL+1)); }
section() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }
assert_exit() { local d="$1" exp="$2" act="$3"; [ "$exp" = "$act" ] && pass "$d (exit $act)" || fail "$d (exit esperado=$exp obtido=$act)"; }
assert_grep() { local d="$1" f="$2" pat="$3"; grep -qE "$pat" "$f" 2>/dev/null && pass "$d" || fail "$d (padrão '$pat' ausente)"; }
assert_no_grep() { local d="$1" f="$2" pat="$3"; grep -qE "$pat" "$f" 2>/dev/null && fail "$d (padrão '$pat' presente, não deveria)" || pass "$d"; }
assert_eq() { local d="$1" exp="$2" act="$3"; [ "$exp" = "$act" ] && pass "$d" || fail "$d (esperado='$exp' obtido='$act')"; }

[ -f "$ANALYZE" ] || { echo "spec-analyze.sh não encontrado: $ANALYZE"; exit 1; }
[ -f "$CONVERGE" ] || { echo "spec-converge.sh não encontrado: $CONVERGE"; exit 1; }

SB="$(mktemp -d "${BATS_TMPDIR:-/tmp}/spec-analyze-test.XXXXXX")"
trap 'rm -rf "$SB"' EXIT

# ── monta produto-drift (1 defeito HARD isolado por capability) ────────────────
DRIFT="$SB/drift"
mkdir -p "$DRIFT/specs/auth" "$DRIFT/specs/billing" "$DRIFT/specs/dup" \
         "$DRIFT/specs/leaked" "$DRIFT/specs/ghost" "$DRIFT/specs/search"

# A1: auth — "Logout Seguro" sem cenário (Login tem cenário)
cat > "$DRIFT/specs/auth/spec.md" <<'EOF'
# Spec: auth
## Requisitos
### Requisito: Login com Senha
DEVE autenticar.
#### Cenário: ok
- **QUANDO** credenciais válidas
- **ENTÃO** sessão criada
### Requisito: Logout Seguro
DEVE encerrar a sessão.
EOF

# A2: billing — cenário 3-hashtags ALÉM de um #### válido (isola A2, sem A1)
cat > "$DRIFT/specs/billing/spec.md" <<'EOF'
# Spec: billing
## Requisitos
### Requisito: Cobrança Mensal
DEVE cobrar mensalmente.
#### Cenário: válido
- **QUANDO** vencimento
- **ENTÃO** cobra
### Cenário: parcial em nível errado
- **QUANDO** algo
- **ENTÃO** outro
EOF

# A3: dup — header duplicado, ambos com cenário (isola A3, sem A1)
cat > "$DRIFT/specs/dup/spec.md" <<'EOF'
# Spec: dup
## Requisitos
### Requisito: Pagamento
DEVE pagar.
#### Cenário: a
- **QUANDO** x
- **ENTÃO** y
### Requisito: Pagamento
DEVE pagar de novo.
#### Cenário: b
- **QUANDO** z
- **ENTÃO** w
EOF

# A4: leaked — token de delta vazado, req com cenário (isola A4, sem A1)
cat > "$DRIFT/specs/leaked/spec.md" <<'EOF'
# Spec: leaked
## Requisitos
### Requisito: Recurso
DEVE funcionar.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
## MODIFICADO Requisitos
### Requisito: Recurso
colado à mão (não mergeado)
#### Cenário: z
- **QUANDO** a
- **ENTÃO** b
EOF

# A5 (ADVISORY): ghost — path de código citado inexistente
cat > "$DRIFT/specs/ghost/spec.md" <<'EOF'
# Spec: ghost
## Requisitos
### Requisito: Algo
DEVE algo.
#### Cenário: c
- **QUANDO** w
- **ENTÃO** v
## Notas
Implementado em `src/inexistente/ghost.ts`.
EOF

# search — 100% limpa (controle dentro do produto-drift)
cat > "$DRIFT/specs/search/spec.md" <<'EOF'
# Spec: search
## Requisitos
### Requisito: Busca
DEVE buscar.
#### Cenário: hit
- **QUANDO** termo existe
- **ENTÃO** resultados
EOF

# ── produto-clean (controle verde) ─────────────────────────────────────────────
CLEAN="$SB/clean"
mkdir -p "$CLEAN/specs/auth" "$CLEAN/specs/billing"
cat > "$CLEAN/specs/auth/spec.md" <<'EOF'
# Spec: auth
## Requisitos
### Requisito: Login
DEVE logar.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
EOF
cat > "$CLEAN/specs/billing/spec.md" <<'EOF'
# Spec: billing
## Requisitos
### Requisito: Cobrança
DEVE cobrar.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
EOF

# ════════════════════════════════════════════════════════════════════════════
section "spec-analyze — exit codes"
OUT="$SB/analyze.out"
bash "$ANALYZE" "$DRIFT" > "$OUT" 2>&1; RC=$?
assert_exit "produto-drift falha (HARD)" 1 "$RC"
bash "$ANALYZE" "$CLEAN" > "$SB/clean.out" 2>&1; RC=$?
assert_exit "produto-clean passa" 0 "$RC"
bash "$ANALYZE" "$DRIFT" --advisory-only > /dev/null 2>&1; RC=$?
assert_exit "--advisory-only nunca falha" 0 "$RC"
bash "$ANALYZE" "$SB/inexistente" > /dev/null 2>&1; RC=$?
assert_exit "produto sem specs/ = erro de invocação" 2 "$RC"
bash "$ANALYZE" > /dev/null 2>&1; RC=$?
assert_exit "sem argumento = erro de invocação" 2 "$RC"

section "spec-analyze — cada check HARD detecta seu defeito"
assert_grep "A1 (req sem cenário) em auth"        "$OUT" 'A1.*auth.*Logout Seguro'
assert_grep "A2 (cenário nível errado) em billing" "$OUT" 'A2.*billing'
assert_grep "A3 (header duplicado) em dup"         "$OUT" 'A3.*dup.*Pagamento'
assert_grep "A4 (delta vazado) em leaked"          "$OUT" 'A4.*leaked'
assert_no_grep "search (cap sã) sem achado HARD"   "$OUT" '(A1|A2|A3|A4).*search'

section "spec-analyze — A5 é ADVISORY (sob separador, não conta no exit)"
assert_grep "A5 ghost.ts presente"                 "$OUT" 'ghost\.ts'
# 'ghost.ts' deve aparecer DEPOIS do separador '## Advisory'
ADV_LINE=$(grep -n '## Advisory' "$OUT" | head -1 | cut -d: -f1)
GHOST_LINE=$(grep -n 'ghost\.ts' "$OUT" | head -1 | cut -d: -f1)
if [ -n "$ADV_LINE" ] && [ -n "$GHOST_LINE" ] && [ "$GHOST_LINE" -gt "$ADV_LINE" ]; then
  pass "A5 ghost.ts está SOB o separador '## Advisory' (linha $GHOST_LINE > $ADV_LINE)"
else
  fail "A5 ghost.ts NÃO está sob o separador Advisory (adv=$ADV_LINE ghost=$GHOST_LINE)"
fi

# ════════════════════════════════════════════════════════════════════════════
section "spec-converge — append-only (source-of-truth INTACTA)"
# hash de cada spec viva ANTES
hash_specs() { for f in "$DRIFT"/specs/*/spec.md; do python3 -c "import hashlib,sys;print(sys.argv[1],hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$f"; done | sort; }
LIST_BEFORE=$(cd "$DRIFT/specs" && find . -name spec.md | sort)
HASH_BEFORE=$(hash_specs)
bash "$CONVERGE" "$DRIFT" > "$SB/converge.out" 2>&1; RC=$?
assert_exit "converge gera quarentena (exit 0)" 0 "$RC"
HASH_AFTER=$(hash_specs)
LIST_AFTER=$(cd "$DRIFT/specs" && find . -name spec.md | sort)
assert_eq "sha256 de toda spec viva IDÊNTICO antes/depois" "$HASH_BEFORE" "$HASH_AFTER"
assert_eq "nenhuma spec.md de capability criada/deletada"  "$LIST_BEFORE" "$LIST_AFTER"

section "spec-converge — quarentena válida e não-autoritativa"
CONV_DIR=$(ls -d "$DRIFT"/specs/_changes/_converge-* 2>/dev/null | head -1)
[ -n "$CONV_DIR" ] && pass "dir de quarentena criado: $(basename "$CONV_DIR")" || fail "dir de quarentena ausente"
if [ -n "$CONV_DIR" ]; then
  assert_grep "RELATORIO.md tem banner NÃO-AUTORITATIVO" "$CONV_DIR/RELATORIO.md" 'NÃO-APLICADA|NÃO-AUTORITATIVO|NÃO FOI APLICADA'
  # o delta-candidato (auth tem A1) deve validar pelo gate real
  bash "$REPO_ROOT/source/skills/spec/lib/spec-validate.sh" "$CONV_DIR" > /dev/null 2>&1; RC=$?
  assert_exit "delta-candidato passa no spec-validate (reentra no fluxo)" 0 "$RC"
fi

# ════════════════════════════════════════════════════════════════════════════
section "Resumo"
printf "  %d ok · %d fail\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TODOS PASSARAM"; exit 0; } || { echo "  HOUVE FALHAS"; exit 1; }
