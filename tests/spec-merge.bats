#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6
#
# tests/spec-merge.bats
# Suite de testes para spec-validate.sh e spec-merge.sh
# Compativel com bats (preferido) e com bash puro (fallback).
# Quando rodado com bash diretamente, usa asserts proprios.
#
# Para rodar:
#   bats tests/spec-merge.bats       (se bats disponivel)
#   bash tests/spec-merge.bats       (fallback puro)

# --- Detectar modo de execucao ---
if [ "${BATS_VERSION:-}" != "" ] || command -v bats >/dev/null 2>&1 && [ "${BASH_SOURCE[0]}" = "$0" ] && false; then
  BATS_MODE=1
else
  BATS_MODE=0
fi

# --- Resolucao de caminhos ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATE="$REPO_ROOT/source/skills/spec/lib/spec-validate.sh"
MERGE="$REPO_ROOT/source/skills/spec/lib/spec-merge.sh"

# --- Infraestrutura de asserts (modo bash puro) ---
PASS_COUNT=0
FAIL_COUNT=0
FAIL_MSGS=()

assert_eq() {
  local DESC="$1" EXPECTED="$2" ACTUAL="$3"
  if [ "$EXPECTED" = "$ACTUAL" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: %s\n' "$DESC"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: $DESC | expected='$EXPECTED' actual='$ACTUAL'")
    printf '  FAIL: %s | expected=%s actual=%s\n' "$DESC" "$EXPECTED" "$ACTUAL"
  fi
}

assert_exit() {
  local DESC="$1" EXPECTED="$2" ACTUAL="$3"
  assert_eq "$DESC (exit code)" "$EXPECTED" "$ACTUAL"
}

assert_file_contains() {
  local DESC="$1" FILE="$2" PATTERN="$3"
  if grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: %s\n' "$DESC"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: $DESC | pattern '$PATTERN' not found in $FILE")
    printf '  FAIL: %s | pattern "%s" not in %s\n' "$DESC" "$PATTERN" "$FILE"
  fi
}

assert_file_not_contains() {
  local DESC="$1" FILE="$2" PATTERN="$3"
  if ! grep -q "$PATTERN" "$FILE" 2>/dev/null; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: %s\n' "$DESC"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: $DESC | pattern '$PATTERN' found in $FILE (should be absent)")
    printf '  FAIL: %s | pattern "%s" should be absent from %s\n' "$DESC" "$PATTERN" "$FILE"
  fi
}

assert_dir_exists() {
  local DESC="$1" DIR="$2"
  if [ -d "$DIR" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: %s\n' "$DESC"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: $DESC | dir not found: $DIR")
    printf '  FAIL: %s | dir not found: %s\n' "$DESC" "$DIR"
  fi
}

assert_dir_not_exists() {
  local DESC="$1" DIR="$2"
  if [ ! -d "$DIR" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: %s\n' "$DESC"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: $DESC | dir should not exist: $DIR")
    printf '  FAIL: %s | dir should not exist: %s\n' "$DESC" "$DIR"
  fi
}

# --- Setup de fixtures ---
setup_fixture() {
  local TMP="$1"

  # Estrutura de produto temporario
  mkdir -p "$TMP/specs/auth"
  mkdir -p "$TMP/specs/_changes/add-2fa/delta"
  mkdir -p "$TMP/specs/_archive"

  # spec.md existente com 1 requisito
  cat > "$TMP/specs/auth/spec.md" << 'SPEC_EOF'
# Spec: auth

## Propósito

Autenticacao e autorizacao de usuarios.

## Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar o usuario via email e senha. A senha DEVE ter minimo 8 caracteres.

#### Cenário: Login bem-sucedido

- **QUANDO** usuario fornece email e senha corretos
- **ENTÃO** sessao e criada e usuario e redirecionado para dashboard

#### Cenário: Senha incorreta

- **QUANDO** usuario fornece senha errada
- **ENTÃO** mensagem de erro e exibida sem revelar qual campo esta errado

SPEC_EOF

  # delta valido: ADICIONADO + MODIFICADO + REMOVIDO
  cat > "$TMP/specs/_changes/add-2fa/delta/auth.md" << 'DELTA_EOF'
# Delta: auth — add-2fa

## ADICIONADO Requisitos

### Requisito: Autenticacao em Dois Fatores (2FA)

O sistema DEVE suportar 2FA via TOTP (RFC 6238). Usuarios com 2FA ativado DEVEM informar o codigo TOTP apos a senha.

#### Cenário: Login com 2FA ativado

- **QUANDO** usuario com 2FA ativado fornece senha correta
- **ENTÃO** sistema solicita codigo TOTP antes de criar sessao

#### Cenário: Codigo TOTP invalido

- **QUANDO** usuario fornece codigo TOTP expirado ou incorreto
- **ENTÃO** login e negado com mensagem de codigo invalido

## MODIFICADO Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar o usuario via email e senha. A senha DEVE ter minimo 12 caracteres (atualizado para maior seguranca).

#### Cenário: Login bem-sucedido

- **QUANDO** usuario fornece email e senha corretos (minimo 12 caracteres)
- **ENTÃO** sessao e criada e usuario e redirecionado para dashboard

#### Cenário: Senha incorreta

- **QUANDO** usuario fornece senha errada
- **ENTÃO** mensagem de erro e exibida sem revelar qual campo esta errado

#### Cenário: Senha muito curta

- **QUANDO** usuario tenta criar conta com senha menor que 12 caracteres
- **ENTÃO** formulario rejeita com mensagem de tamanho minimo

## REMOVIDO Requisitos

DELTA_EOF

  # proposta.md
  cat > "$TMP/specs/_changes/add-2fa/proposta.md" << 'PROP_EOF'
# Proposta: add-2fa

## Por que
Aumentar seguranca da autenticacao adicionando suporte a TOTP 2FA.

## O que muda
- Novo requisito de 2FA
- Senha minima elevada de 8 para 12 caracteres
PROP_EOF
}

setup_fixture_with_removal() {
  local TMP="$1"
  setup_fixture "$TMP"

  # Atualizar delta para incluir REMOVIDO valido
  cat > "$TMP/specs/_changes/add-2fa/delta/auth.md" << 'DELTA_REM_EOF'
# Delta: auth — add-2fa

## ADICIONADO Requisitos

### Requisito: Autenticacao em Dois Fatores (2FA)

O sistema DEVE suportar 2FA via TOTP (RFC 6238).

#### Cenário: Login com 2FA ativado

- **QUANDO** usuario com 2FA ativado fornece senha correta
- **ENTÃO** sistema solicita codigo TOTP antes de criar sessao

## MODIFICADO Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar o usuario via email e senha. A senha DEVE ter minimo 12 caracteres.

#### Cenário: Login bem-sucedido

- **QUANDO** usuario fornece email e senha corretos
- **ENTÃO** sessao criada e usuario redirecionado para dashboard

## REMOVIDO Requisitos

### Requisito: Login com Senha Legado

**Motivo:** Requisito legado substituido pelo novo fluxo unificado de autenticacao.

**Migração:** Nenhuma migracao necessaria — este requisito era redundante com Login com Senha.

DELTA_REM_EOF
}

# ============================================================
# TESTE 1: spec-validate aceita delta valido
# ============================================================
run_test_1() {
  printf '\n[Teste 1] spec-validate aceita delta valido com ADDED\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)

  mkdir -p "$TMP/change/delta"
  cat > "$TMP/change/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Novo Recurso

O sistema DEVE suportar o novo recurso.

#### Cenário: Recurso ativo

- **QUANDO** recurso e solicitado
- **ENTÃO** sistema responde corretamente
EOF

  bash "$VALIDATE" "$TMP/change" > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-validate sai com 0 para delta valido" "0" "$EXIT_CODE"
  rm -rf "$TMP"
}

# ============================================================
# TESTE 2: spec-validate rejeita cenario com 3 hashtags
# ============================================================
run_test_2() {
  printf '\n[Teste 2] spec-validate rejeita cenario com ### (3 hashtags)\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/change/delta"

  cat > "$TMP/change/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Requisito Invalido

O sistema DEVE fazer algo.

### Cenário: Cenario com 3 hashtags

- **QUANDO** isso acontece
- **ENTÃO** isso ocorre
EOF

  bash "$VALIDATE" "$TMP/change" > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-validate sai com 1 para cenario com 3 hashtags" "1" "$EXIT_CODE"
  rm -rf "$TMP"
}

# ============================================================
# TESTE 3: spec-validate rejeita requisito sem cenario
# ============================================================
run_test_3() {
  printf '\n[Teste 3] spec-validate rejeita requisito sem #### Cenario:\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/change/delta"

  cat > "$TMP/change/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Sem Cenario

O sistema DEVE fazer algo, mas sem nenhum cenario definido.

EOF

  bash "$VALIDATE" "$TMP/change" > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-validate sai com 1 para requisito sem cenario" "1" "$EXIT_CODE"
  rm -rf "$TMP"
}

# ============================================================
# TESTE 4: spec-validate rejeita REMOVIDO sem Motivo
# ============================================================
run_test_4() {
  printf '\n[Teste 4] spec-validate rejeita REMOVIDO sem **Motivo**\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/change/delta"

  cat > "$TMP/change/delta/auth.md" << 'EOF'
## REMOVIDO Requisitos

### Requisito: Requisito Sem Motivo

**Migração:** Sem migração necessária.

EOF

  bash "$VALIDATE" "$TMP/change" > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-validate sai com 1 para REMOVIDO sem Motivo" "1" "$EXIT_CODE"
  rm -rf "$TMP"
}

# ============================================================
# TESTE 5: spec-merge aplica ADDED corretamente
# ============================================================
run_test_5() {
  printf '\n[Teste 5] spec-merge aplica ADDED — requisito inserido na spec\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/specs/auth" "$TMP/specs/_changes/add-2fa/delta" "$TMP/specs/_archive"

  cat > "$TMP/specs/auth/spec.md" << 'EOF'
# Spec: auth

## Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar via email e senha.

#### Cenário: Login ok

- **QUANDO** credenciais corretas
- **ENTÃO** sessao criada
EOF

  cat > "$TMP/specs/_changes/add-2fa/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Autenticacao em Dois Fatores

O sistema DEVE suportar 2FA via TOTP.

#### Cenário: Login com 2FA

- **QUANDO** 2FA esta ativo e senha esta correta
- **ENTÃO** sistema solicita codigo TOTP

EOF

  bash "$MERGE" "$TMP" "add-2fa" --yes > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-merge sai com 0 para ADDED valido" "0" "$EXIT_CODE"
  assert_file_contains "spec.md contem requisito adicionado" \
    "$TMP/specs/auth/spec.md" "Autenticacao em Dois Fatores"
  assert_dir_exists "archive criado apos merge" \
    "$TMP/specs/_archive/$(date +%F)-add-2fa"
  assert_dir_not_exists "_changes removido apos archive" \
    "$TMP/specs/_changes/add-2fa"

  rm -rf "$TMP"
}

# ============================================================
# TESTE 6: spec-merge aplica MODIFIED — substitui bloco
# ============================================================
run_test_6() {
  printf '\n[Teste 6] spec-merge aplica MODIFIED — bloco substituido na spec\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/specs/auth" "$TMP/specs/_changes/mod-senha/delta" "$TMP/specs/_archive"

  cat > "$TMP/specs/auth/spec.md" << 'EOF'
# Spec: auth

## Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar via email e senha com minimo 8 caracteres.

#### Cenário: Login ok

- **QUANDO** credenciais corretas
- **ENTÃO** sessao criada

EOF

  cat > "$TMP/specs/_changes/mod-senha/delta/auth.md" << 'EOF'
## MODIFICADO Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar via email e senha com minimo 12 caracteres.

#### Cenário: Login ok

- **QUANDO** credenciais corretas (minimo 12 chars)
- **ENTÃO** sessao criada

EOF

  bash "$MERGE" "$TMP" "mod-senha" --yes > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-merge sai com 0 para MODIFIED valido" "0" "$EXIT_CODE"
  assert_file_contains "spec.md reflete requisito modificado (12 chars)" \
    "$TMP/specs/auth/spec.md" "12 caracteres"
  assert_file_not_contains "spec.md nao tem mais texto antigo (8 chars)" \
    "$TMP/specs/auth/spec.md" "8 caracteres"

  rm -rf "$TMP"
}

# ============================================================
# TESTE 7: spec-merge aplica REMOVED — bloco removido da spec
# ============================================================
run_test_7() {
  printf '\n[Teste 7] spec-merge aplica REMOVED — requisito removido da spec\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/specs/auth" "$TMP/specs/_changes/rm-legado/delta" "$TMP/specs/_archive"

  cat > "$TMP/specs/auth/spec.md" << 'EOF'
# Spec: auth

## Requisitos

### Requisito: Login Legado

Requisito antigo a ser removido.

#### Cenário: Legado ok

- **QUANDO** fluxo legado
- **ENTÃO** funciona

### Requisito: Login Principal

Requisito que deve permanecer.

#### Cenário: Principal ok

- **QUANDO** fluxo principal
- **ENTÃO** funciona
EOF

  cat > "$TMP/specs/_changes/rm-legado/delta/auth.md" << 'EOF'
## REMOVIDO Requisitos

### Requisito: Login Legado

**Motivo:** Fluxo legado descontinuado em favor do Login Principal.

**Migração:** Usuarios devem usar o Login Principal. Sem migração de dados necessária.

EOF

  bash "$MERGE" "$TMP" "rm-legado" --yes > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-merge sai com 0 para REMOVED valido" "0" "$EXIT_CODE"
  assert_file_not_contains "spec.md nao contem mais o requisito removido" \
    "$TMP/specs/auth/spec.md" "Login Legado"
  assert_file_contains "spec.md ainda contem requisito nao removido" \
    "$TMP/specs/auth/spec.md" "Login Principal"

  rm -rf "$TMP"
}

# ============================================================
# TESTE 8: spec-merge rejeita ADDED com conflito — spec inalterada
# ============================================================
run_test_8() {
  printf '\n[Teste 8] spec-merge rejeita ADDED com header ja existente — idempotencia\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/specs/auth" "$TMP/specs/_changes/conflito/delta" "$TMP/specs/_archive"

  cat > "$TMP/specs/auth/spec.md" << 'EOF'
# Spec: auth

## Requisitos

### Requisito: Login com Senha

O sistema DEVE autenticar via email e senha.

#### Cenário: Login ok

- **QUANDO** credenciais corretas
- **ENTÃO** sessao criada
EOF

  # Delta tenta adicionar requisito que ja existe
  cat > "$TMP/specs/_changes/conflito/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Login com Senha

Tentativa de adicionar requisito que ja existe — deve conflitar.

#### Cenário: Conflito

- **QUANDO** requisito duplicado
- **ENTÃO** merge aborta
EOF

  SPEC_BEFORE=$(cat "$TMP/specs/auth/spec.md")
  bash "$MERGE" "$TMP" "conflito" --yes > /dev/null 2>&1
  local EXIT_CODE=$?
  SPEC_AFTER=$(cat "$TMP/specs/auth/spec.md")

  assert_exit "spec-merge sai com 1 para ADDED com conflito" "1" "$EXIT_CODE"
  # Spec deve estar inalterada
  if [ "$SPEC_BEFORE" = "$SPEC_AFTER" ]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok: spec.md inalterada apos conflito (idempotencia confirmada)\n'
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAIL_MSGS+=("FAIL: spec.md foi modificada mesmo com conflito — idempotencia violada")
    printf '  FAIL: spec.md foi modificada mesmo com conflito\n'
  fi

  rm -rf "$TMP"
}

# ============================================================
# TESTE 9: spec-validate exit 2 para arg faltando
# ============================================================
run_test_9() {
  printf '\n[Teste 9] spec-validate exit 2 para arg faltando\n'
  bash "$VALIDATE" > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-validate sai com 2 para invocacao sem arg" "2" "$EXIT_CODE"
}

# ============================================================
# TESTE 10: spec-merge dry-run nao escreve nem arquiva
# ============================================================
run_test_10() {
  printf '\n[Teste 10] spec-merge --dry-run nao escreve na spec nem cria archive\n'
  local TMP
  TMP=$(mktemp -d /tmp/spec-test-XXXXXX)
  mkdir -p "$TMP/specs/auth" "$TMP/specs/_changes/dry-test/delta" "$TMP/specs/_archive"

  cat > "$TMP/specs/auth/spec.md" << 'EOF'
# Spec: auth

## Requisitos

### Requisito: Base

Requisito base.

#### Cenário: Base

- **QUANDO** base ativa
- **ENTÃO** responde
EOF

  cat > "$TMP/specs/_changes/dry-test/delta/auth.md" << 'EOF'
## ADICIONADO Requisitos

### Requisito: Dry Run Feature

Feature testada em dry-run.

#### Cenário: Dry run

- **QUANDO** dry run
- **ENTÃO** nada muda
EOF

  bash "$MERGE" "$TMP" "dry-test" --dry-run > /dev/null 2>&1
  local EXIT_CODE=$?
  assert_exit "spec-merge --dry-run sai com 0" "0" "$EXIT_CODE"
  assert_file_not_contains "spec.md nao contem conteudo do dry-run" \
    "$TMP/specs/auth/spec.md" "Dry Run Feature"
  assert_dir_not_exists "archive nao criado em dry-run" \
    "$TMP/specs/_archive/$(date +%F)-dry-test"
  assert_dir_exists "_changes ainda existe apos dry-run" \
    "$TMP/specs/_changes/dry-test"

  rm -rf "$TMP"
}

# ============================================================
# Executar todos os testes
# ============================================================
printf '\n=== spec-merge test suite ===\n'
printf 'validate: %s\n' "$VALIDATE"
printf 'merge:    %s\n' "$MERGE"
printf '\n'

if [ ! -f "$VALIDATE" ]; then
  printf 'ERRO: spec-validate.sh nao encontrado em %s\n' "$VALIDATE" >&2
  exit 2
fi

if [ ! -f "$MERGE" ]; then
  printf 'ERRO: spec-merge.sh nao encontrado em %s\n' "$MERGE" >&2
  exit 2
fi

chmod +x "$VALIDATE" "$MERGE"

run_test_1
run_test_2
run_test_3
run_test_4
run_test_5
run_test_6
run_test_7
run_test_8
run_test_9
run_test_10

printf '\n=== Resultado ===\n'
printf 'Passaram: %d\n' "$PASS_COUNT"
printf 'Falharam: %d\n' "$FAIL_COUNT"

if [ "${#FAIL_MSGS[@]}" -gt 0 ]; then
  printf '\nFalhas:\n'
  for MSG in "${FAIL_MSGS[@]}"; do
    printf '  %s\n' "$MSG"
  done
fi

if [ "$FAIL_COUNT" -eq 0 ]; then
  printf '\nSuite: VERDE\n'
  exit 0
else
  printf '\nSuite: VERMELHA (%d falha(s))\n' "$FAIL_COUNT"
  exit 1
fi
