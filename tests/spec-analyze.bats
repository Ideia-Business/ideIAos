#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
#
# tests/spec-analyze.bats
# Fixture-regression de spec-analyze.sh e spec-converge.sh (W4).
# Dual-mode: roda com bats OU com bash puro (fallback) — igual a spec-merge.bats.
#   bats tests/spec-analyze.bats   /   bash tests/spec-analyze.bats  (CI + SOAK)
#
# Modelo de seção (pós-verificação adversarial wf_99173505): contrato testável =
# '### Requisito:' SOB '## Requisitos'. A1/A2/A3 são HARD só nessa zona; '### Requisito:'
# fora dela = A6 ADVISORY; tudo fence-aware. Os casos abaixo ENCODAM as correções dos
# defeitos achados pela verificação para que não regridam.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANALYZE="$REPO_ROOT/source/skills/spec/lib/spec-analyze.sh"
CONVERGE="$REPO_ROOT/source/skills/spec/lib/spec-converge.sh"
VALIDATE="$REPO_ROOT/source/skills/spec/lib/spec-validate.sh"
MERGE="$REPO_ROOT/source/skills/spec/lib/spec-merge.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}ok${NC}: %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}FAIL${NC}: %s\n" "$*"; FAIL=$((FAIL+1)); }
section() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }
assert_exit() { local d="$1" exp="$2" act="$3"; [ "$exp" = "$act" ] && pass "$d (exit $act)" || fail "$d (exit esperado=$exp obtido=$act)"; }
assert_grep() { local d="$1" f="$2" pat="$3"; grep -qE "$pat" "$f" 2>/dev/null && pass "$d" || fail "$d (padrão '$pat' ausente)"; }
assert_no_grep() { local d="$1" f="$2" pat="$3"; grep -qE "$pat" "$f" 2>/dev/null && fail "$d (padrão '$pat' presente, não deveria)" || pass "$d"; }
assert_eq() { local d="$1" exp="$2" act="$3"; [ "$exp" = "$act" ] && pass "$d" || fail "$d (esperado='$exp' obtido='$act')"; }

[ -f "$ANALYZE" ] || { echo "spec-analyze.sh não encontrado"; exit 1; }
[ -f "$CONVERGE" ] || { echo "spec-converge.sh não encontrado"; exit 1; }

SB="$(mktemp -d "${BATS_TMPDIR:-/tmp}/spec-analyze-test.XXXXXX")"
trap 'chmod -R u+rwX "$SB" 2>/dev/null; rm -rf "$SB"' EXIT

DRIFT="$SB/drift"
mkdir -p "$DRIFT/specs/auth" "$DRIFT/specs/billing" "$DRIFT/specs/dup" \
         "$DRIFT/specs/leaked" "$DRIFT/specs/ghost" "$DRIFT/specs/misplaced" \
         "$DRIFT/specs/fence" "$DRIFT/specs/search"

# A1: auth — req de contrato sem cenário
cat > "$DRIFT/specs/auth/spec.md" <<'EOF'
# Spec: auth
## Requisitos
### Requisito: Login com Senha
DEVE autenticar.
#### Cenário: ok
- **QUANDO** ok
- **ENTÃO** sessão
### Requisito: Logout Seguro
DEVE encerrar a sessão.
EOF

# A2: billing — cenário 3-hashtags E 6-hashtags (cada req tem #### válido → isola A2)
cat > "$DRIFT/specs/billing/spec.md" <<'EOF'
# Spec: billing
## Requisitos
### Requisito: Tres
DEVE cobrar.
#### Cenário: válido
- **QUANDO** a
- **ENTÃO** b
### Cenário: nível três errado
- **QUANDO** c
### Requisito: Seis
DEVE estornar.
#### Cenário: válido2
- **QUANDO** d
- **ENTÃO** e
###### Cenário: nível seis errado
- **QUANDO** f
EOF

# A3: dup — header duplicado em ## Requisitos, ambos com cenário
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

# A4: leaked — token de delta em CAIXA-BAIXA (regressão finding 10), req antes com cenário
cat > "$DRIFT/specs/leaked/spec.md" <<'EOF'
# Spec: leaked
## Requisitos
### Requisito: Recurso
DEVE funcionar.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
## modificado Requisitos
EOF

# A5 (ADVISORY): ghost — path de código inexistente; req de contrato válido
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

# A6 (ADVISORY, regressão finding 8): '### Requisito:' sem cenário SOB ## Notas
# (não-silencioso; antes escapava o gate). Os reqs de contrato são válidos.
cat > "$DRIFT/specs/misplaced/spec.md" <<'EOF'
# Spec: misplaced
## Requisitos
### Requisito: Valido
DEVE valer.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
## Notas
### Requisito: Colado À Mão Sem Cenário
DEVE algo que ninguém testou.
EOF

# fence (regressão finding 1/5): '### Cenário' e '## ADICIONADO' DENTRO de ``` → NÃO disparam
cat > "$DRIFT/specs/fence/spec.md" <<'EOF'
# Spec: fence
## Requisitos
### Requisito: Documentado
DEVE funcionar.
#### Cenário: real
- **QUANDO** x
- **ENTÃO** y
## Notas
Exemplo de como um delta se parece (em prosa, não é contrato):
```
## ADICIONADO Requisitos
### Cenário: exemplo em nível errado dentro de fence
```
EOF

# search — limpa
cat > "$DRIFT/specs/search/spec.md" <<'EOF'
# Spec: search
## Requisitos
### Requisito: Busca
DEVE buscar.
#### Cenário: hit
- **QUANDO** termo
- **ENTÃO** resultados
EOF

# ── template-clean: segue o TEMPLATE OFICIAL (regressão do BLOQUEADOR finding 1) ──
TPL="$SB/template"
mkdir -p "$TPL/specs/auth"
cat > "$TPL/specs/auth/spec.md" <<'EOF'
# Spec: auth

## Propósito
Contrato de autenticação.

## Requisitos
### Requisito: Login
DEVE logar.
#### Cenário: ok
- **QUANDO** credenciais válidas
- **ENTÃO** sessão

## Notas
### Cenários futuros considerados mas fora de escopo
- SSO corporativo (adiado)
- Biometria

## Historial
| Data | Mudança |
|------|---------|
| 2026-06-19 | spec inicial |
EOF

# produto-clean
CLEAN="$SB/clean"
mkdir -p "$CLEAN/specs/auth"
cat > "$CLEAN/specs/auth/spec.md" <<'EOF'
# Spec: auth
## Requisitos
### Requisito: Login
DEVE logar.
#### Cenário: ok
- **QUANDO** x
- **ENTÃO** y
EOF

# ════════════════════════════════════════════════════════════════════════════
section "spec-analyze — exit codes"
OUT="$SB/analyze.out"
bash "$ANALYZE" "$DRIFT" > "$OUT" 2>&1; assert_exit "produto-drift falha (HARD)" 1 "$?"
bash "$ANALYZE" "$CLEAN" > /dev/null 2>&1; assert_exit "produto-clean passa" 0 "$?"
bash "$ANALYZE" "$DRIFT" --advisory-only > /dev/null 2>&1; assert_exit "--advisory-only nunca falha (HARD)" 0 "$?"
bash "$ANALYZE" "$SB/inexistente" > /dev/null 2>&1; assert_exit "sem specs/ = invocação" 2 "$?"
bash "$ANALYZE" > /dev/null 2>&1; assert_exit "sem argumento = invocação" 2 "$?"

section "BLOQUEADOR (finding 1): spec que segue o TEMPLATE OFICIAL passa"
TPL_OUT="$SB/tpl.out"
bash "$ANALYZE" "$TPL" > "$TPL_OUT" 2>&1; RC=$?
assert_exit "template oficial (## Notas com '### Cenários futuros' + ## Historial) → exit 0" 0 "$RC"
assert_no_grep "nenhum A2 espúrio no template" "$TPL_OUT" '✗ A2'

section "spec-analyze — cada check HARD detecta seu defeito"
assert_grep "A1 (req sem cenário) em auth"          "$OUT" 'A1.*auth.*Logout Seguro'
assert_grep "A2 nível 3 (req Tres) em billing"      "$OUT" 'A2.*billing.*Tres'
assert_grep "A2 nível 6 (req Seis) em billing"      "$OUT" 'A2.*billing.*Seis'
assert_grep "A3 (header duplicado) em dup"          "$OUT" 'A3.*dup.*Pagamento'
assert_grep "A4 token CAIXA-BAIXA em leaked"        "$OUT" 'A4.*leaked'
assert_no_grep "search (cap sã) sem HARD"           "$OUT" '(A1|A2|A3|A4).*search'
assert_no_grep "fence (em bloco fenced) sem HARD"   "$OUT" '(A1|A2|A4).*fence'

section "ADVISORY (A5/A6 não contam no exit; sob separador)"
assert_grep "A5 ghost.ts presente"                  "$OUT" 'ghost\.ts'
assert_grep "A6 misplaced (req sob ## Notas)"       "$OUT" 'A6.*misplaced'
ADV_LINE=$(grep -n '## Advisory' "$OUT" | head -1 | cut -d: -f1)
A6_LINE=$(grep -n 'A6.*misplaced' "$OUT" | head -1 | cut -d: -f1)
if [ -n "$ADV_LINE" ] && [ -n "$A6_LINE" ] && [ "$A6_LINE" -gt "$ADV_LINE" ]; then
  pass "A6/A5 sob o separador '## Advisory' (não-gated)"
else
  fail "advisory mal posicionado (adv=$ADV_LINE a6=$A6_LINE)"
fi

section "spec-analyze — spec ilegível é HARD (não falha em silêncio)"
if [ "$(id -u)" != "0" ]; then
  IO="$SB/io"; mkdir -p "$IO/specs/x"
  printf '# Spec: x\n## Requisitos\n### Requisito: R\nDEVE.\n#### Cenário: a\n- **QUANDO** y\n' > "$IO/specs/x/spec.md"
  chmod 000 "$IO/specs/x/spec.md"
  bash "$ANALYZE" "$IO" > /dev/null 2>&1; assert_exit "spec chmod 000 → exit 1 (HARD)" 1 "$?"
  chmod u+rw "$IO/specs/x/spec.md"
else
  pass "spec ilegível: pulado (rodando como root)"
fi

# ════════════════════════════════════════════════════════════════════════════
section "spec-converge — append-only (source-of-truth INTACTA)"
hash_specs() { for f in "$DRIFT"/specs/*/spec.md; do bash -c '
  if command -v python3 >/dev/null 2>&1; then python3 -c "import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],\"rb\").read()).hexdigest())" "$1";
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk "{print \$1}";
  else sha256sum "$1" | awk "{print \$1}"; fi' _ "$f"; done | sort; }
HASH_BEFORE=$(hash_specs)
bash "$CONVERGE" "$DRIFT" > "$SB/converge.out" 2>&1; assert_exit "converge gera quarentena" 0 "$?"
assert_eq "sha256 de toda spec viva IDÊNTICO antes/depois" "$HASH_BEFORE" "$(hash_specs)"

section "spec-converge — quarentena válida, round-trip validate"
CONV_DIR=$(ls -d "$DRIFT"/specs/_changes/_converge-* 2>/dev/null | head -1)
[ -n "$CONV_DIR" ] && pass "dir de quarentena criado" || fail "dir de quarentena ausente"
if [ -n "$CONV_DIR" ]; then
  assert_grep "RELATORIO.md NÃO-AUTORITATIVO" "$CONV_DIR/RELATORIO.md" 'NÃO FOI APLICADA|NÃO-AUTORITATIVO'
  bash "$VALIDATE" "$CONV_DIR" > /dev/null 2>&1; assert_exit "candidato passa no spec-validate" 0 "$?"
fi

section "Resumo"
printf "  %d ok · %d fail\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TODOS PASSARAM"; exit 0; } || { echo "  HOUVE FALHAS"; exit 1; }
