#!/bin/bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6
#
# spec-merge.sh <produto-root> <slug> [--dry-run] [--yes]
#
# Merge deterministico de delta na source-of-truth da capability.
# Invoca spec-validate.sh como gate antes de qualquer escrita.
#
# Tokens canonicos internos (mapeados a partir dos rotulos PT-BR do delta):
#   ADICIONADO  -> ADDED    : anexa requisito (abort se header ja existe)
#   MODIFICADO  -> MODIFIED : substitui bloco completo do requisito
#   REMOVIDO    -> REMOVED  : remove bloco do requisito
#   RENOMEADO   -> RENAMED  : renomeia header DE/PARA, preserva corpo
#
# Saida de sucesso: + N adicionados / ~ N modificados / - N removidos / -> N renomeados
# Falha: exit 1 com mensagem clara; nenhuma escrita parcial (atomico via tmp)

set -euo pipefail

# --- Argumentos ---
PRODUTO_ROOT="${1:-}"
SLUG="${2:-}"
DRY_RUN=0
YES=0

shift 2 2>/dev/null || true
for ARG in "$@"; do
  case "$ARG" in
    --dry-run) DRY_RUN=1 ;;
    --yes)     YES=1 ;;
  esac
done

if [ -z "$PRODUTO_ROOT" ] || [ -z "$SLUG" ]; then
  echo "ERRO: uso: spec-merge.sh <produto-root> <slug> [--dry-run] [--yes]" >&2
  exit 1
fi

if [ ! -d "$PRODUTO_ROOT" ]; then
  echo "ERRO: produto-root nao encontrado: $PRODUTO_ROOT" >&2
  exit 1
fi

CHANGE_DIR="$PRODUTO_ROOT/specs/_changes/$SLUG"
if [ ! -d "$CHANGE_DIR" ]; then
  echo "ERRO: change nao encontrada: $CHANGE_DIR" >&2
  exit 1
fi

DELTA_DIR="$CHANGE_DIR/delta"
if [ ! -d "$DELTA_DIR" ]; then
  echo "ERRO: delta/ ausente em $CHANGE_DIR" >&2
  exit 1
fi

# --- Gate: validar delta antes de qualquer escrita ---
VALIDATE_SCRIPT="$(dirname "$0")/spec-validate.sh"
if [ ! -f "$VALIDATE_SCRIPT" ]; then
  # Tentar caminho relativo ao script
  VALIDATE_SCRIPT="$(cd "$(dirname "$0")" && pwd)/spec-validate.sh"
fi

if [ -f "$VALIDATE_SCRIPT" ]; then
  if ! bash "$VALIDATE_SCRIPT" "$CHANGE_DIR"; then
    echo "ERRO: spec-validate falhou — merge abortado. Corrija o delta e tente novamente." >&2
    exit 1
  fi
else
  echo "AVISO: spec-validate.sh nao encontrado em $(dirname "$0") — pulando validacao" >&2
fi

# --- Funcoes auxiliares ---

# Mapear rotulo PT-BR -> token canonico interno
map_section_token() {
  local SECTION="$1"
  case "$SECTION" in
    *ADICIONADO*|*ADDED*)   echo "ADDED" ;;
    *MODIFICADO*|*MODIFIED*) echo "MODIFIED" ;;
    *REMOVIDO*|*REMOVED*)   echo "REMOVED" ;;
    *RENOMEADO*|*RENAMED*)  echo "RENAMED" ;;
    *) echo "UNKNOWN" ;;
  esac
}

# Extrair bloco de um requisito (de "### Requisito: <nome>" ate o proximo ### ou ##)
# Saida: linhas do bloco inclusive o header
extract_req_block() {
  local FILE="$1"
  local REQ_NAME="$2"
  local IN_REQ=0
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -q "^### Requisito:.*$REQ_NAME"; then
      IN_REQ=1
      printf '%s\n' "$LINE"
      continue
    fi
    if [ "$IN_REQ" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^(##|### Requisito:)'; then
        break
      fi
      printf '%s\n' "$LINE"
    fi
  done < "$FILE"
}

# Contar entradas em uma secao do delta
count_section_entries() {
  local FILE="$1"
  local TOKEN="$2"
  local IN_SECTION=0
  local COUNT=0
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -qE "^## .*(${TOKEN}|$(echo "$TOKEN" | sed 's/ADDED/ADICIONADO/;s/MODIFIED/MODIFICADO/;s/REMOVED/REMOVIDO/;s/RENAMED/RENOMEADO/'))"; then
      IN_SECTION=1
      continue
    fi
    if [ "$IN_SECTION" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^## [A-Z]'; then
        break
      fi
      if echo "$LINE" | grep -q '^### Requisito:'; then
        COUNT=$((COUNT + 1))
      fi
    fi
  done < "$FILE"
  echo "$COUNT"
}

# --- Processar cada arquivo de delta ---
TOTAL_ADDED=0
TOTAL_MODIFIED=0
TOTAL_REMOVED=0
TOTAL_RENAMED=0
ERRORS=0

for DELTA_FILE in "$DELTA_DIR"/*.md; do
  if [ ! -f "$DELTA_FILE" ]; then
    continue
  fi

  CAPABILITY=$(basename "$DELTA_FILE" .md)
  SPEC_FILE="$PRODUTO_ROOT/specs/$CAPABILITY/spec.md"

  echo "--- Processando capability: $CAPABILITY"

  # Para cada operacao no delta, precisamos da spec existente (exceto ADDED em spec nova)
  CURRENT_SECTION=""
  CURRENT_TOKEN=""

  # Ler o delta e coletar operacoes por secao
  # Usar arquivo temporario para construir nova spec (atomicidade)
  TMPSPEC=$(mktemp /tmp/spec-merge-XXXXXX.md)
  trap 'rm -f "$TMPSPEC"' EXIT

  # Verificar se a spec existe para operacoes que precisam dela
  if [ ! -f "$SPEC_FILE" ]; then
    # Se nao existe, so ADDED e valido (cria spec nova do zero)
    # Verificar se ha secao MODIFICADO ou REMOVIDO no delta
    if grep -qE '^## (MODIFICADO|MODIFIED|REMOVIDO|REMOVED|RENOMEADO|RENAMED)' "$DELTA_FILE"; then
      echo "ERRO: $CAPABILITY: spec nao existe em $SPEC_FILE mas delta tem MODIFICADO/REMOVIDO/RENOMEADO — impossivel aplicar" >&2
      ERRORS=$((ERRORS + 1))
      rm -f "$TMPSPEC"
      continue
    fi
    # Criar spec nova apenas com ADICIONADOs
    mkdir -p "$(dirname "$SPEC_FILE")"
    if [ "$DRY_RUN" -eq 0 ]; then
      {
        echo "# Spec: $CAPABILITY"
        echo ""
        echo "## Propósito"
        echo ""
        echo "Spec criada via delta-spec em $(date +%F)."
        echo ""
        echo "## Requisitos"
        echo ""
      } > "$SPEC_FILE"
    fi
  fi

  # Copiar spec atual para tmp (para operacoes atomicas)
  if [ -f "$SPEC_FILE" ] && [ "$DRY_RUN" -eq 0 ]; then
    cp "$SPEC_FILE" "$TMPSPEC"
  elif [ -f "$SPEC_FILE" ]; then
    cp "$SPEC_FILE" "$TMPSPEC"
  fi

  # Processar cada secao do delta em ordem: ADDED, MODIFIED, REMOVED, RENAMED
  for TOKEN in ADDED MODIFIED REMOVED RENAMED; do
    PT_LABEL=""
    case "$TOKEN" in
      ADDED)    PT_LABEL="ADICIONADO" ;;
      MODIFIED) PT_LABEL="MODIFICADO" ;;
      REMOVED)  PT_LABEL="REMOVIDO" ;;
      RENAMED)  PT_LABEL="RENOMEADO" ;;
    esac

    # Extrair bloco da secao no delta (linhas entre "## TOKEN Requisitos" e proximo "## ")
    IN_SECTION=0
    SECTION_CONTENT=""
    while IFS= read -r LINE; do
      if echo "$LINE" | grep -qE "^## ($TOKEN|$PT_LABEL)"; then
        IN_SECTION=1
        continue
      fi
      if [ "$IN_SECTION" -eq 1 ]; then
        if echo "$LINE" | grep -qE '^## [A-Z]'; then
          break
        fi
        SECTION_CONTENT="${SECTION_CONTENT}${LINE}"$'\n'
      fi
    done < "$DELTA_FILE"

    if [ -z "$(echo "$SECTION_CONTENT" | tr -d '[:space:]')" ]; then
      continue
    fi

    # Processar cada requisito na secao
    CURRENT_REQ=""
    CURRENT_REQ_BLOCK=""
    IN_REQ=0

    while IFS= read -r LINE; do
      if echo "$LINE" | grep -q '^### Requisito:'; then
        # Processar requisito anterior se houver
        if [ "$IN_REQ" -eq 1 ] && [ -n "$CURRENT_REQ" ]; then
          _apply_req "$TOKEN" "$CAPABILITY" "$CURRENT_REQ" "$CURRENT_REQ_BLOCK" "$SPEC_FILE" "$TMPSPEC" || ERRORS=$((ERRORS + 1))
        fi
        CURRENT_REQ=$(echo "$LINE" | sed 's/^### Requisito: *//')
        CURRENT_REQ_BLOCK="$LINE"$'\n'
        IN_REQ=1
      elif [ "$IN_REQ" -eq 1 ]; then
        CURRENT_REQ_BLOCK="${CURRENT_REQ_BLOCK}${LINE}"$'\n'
      fi
    done <<< "$SECTION_CONTENT"

    # Processar ultimo requisito da secao
    if [ "$IN_REQ" -eq 1 ] && [ -n "$CURRENT_REQ" ]; then
      _apply_req "$TOKEN" "$CAPABILITY" "$CURRENT_REQ" "$CURRENT_REQ_BLOCK" "$SPEC_FILE" "$TMPSPEC" || ERRORS=$((ERRORS + 1))
    fi
  done

  # Promover tmp -> spec (atomicidade)
  if [ "$ERRORS" -eq 0 ] && [ "$DRY_RUN" -eq 0 ] && [ -f "$TMPSPEC" ]; then
    cp "$TMPSPEC" "$SPEC_FILE"
  fi
  rm -f "$TMPSPEC"
  trap - EXIT
done

# Funcao auxiliar para aplicar uma operacao em um requisito
# (Definida apos o loop pois bash nao requer forward-declaration em subshell)
# NOTA: em bash 3.2 nao podemos exportar funcoes entre subshells facilmente
# Reimplementamos inline abaixo via segunda passagem

# --- Segunda passagem: aplicacao real ---
# Resetar contadores e refazer com aplicacao real

TOTAL_ADDED=0
TOTAL_MODIFIED=0
TOTAL_REMOVED=0
TOTAL_RENAMED=0
APPLY_ERRORS=0

for DELTA_FILE in "$DELTA_DIR"/*.md; do
  if [ ! -f "$DELTA_FILE" ]; then
    continue
  fi

  CAPABILITY=$(basename "$DELTA_FILE" .md)
  SPEC_FILE="$PRODUTO_ROOT/specs/$CAPABILITY/spec.md"

  # Verificar existencia para operacoes que precisam da spec
  if [ ! -f "$SPEC_FILE" ]; then
    # Spec nova: cria o arquivo base
    mkdir -p "$(dirname "$SPEC_FILE")"
    if [ "$DRY_RUN" -eq 0 ]; then
      printf '# Spec: %s\n\n## Propósito\n\nSpec criada via delta-spec em %s.\n\n## Requisitos\n\n' \
        "$CAPABILITY" "$(date +%F)" > "$SPEC_FILE"
    fi
  fi

  TMPSPEC=$(mktemp /tmp/spec-merge-XXXXXX.md)

  if [ -f "$SPEC_FILE" ]; then
    cp "$SPEC_FILE" "$TMPSPEC"
  else
    printf '# Spec: %s\n\n## Propósito\n\nSpec criada via delta-spec em %s.\n\n## Requisitos\n\n' \
      "$CAPABILITY" "$(date +%F)" > "$TMPSPEC"
  fi

  # Processar ADDED
  IN_SECTION=0
  IN_REQ=0
  CURRENT_REQ=""
  CURRENT_REQ_BLOCK=""
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -qE '^## (ADICIONADO|ADDED)'; then
      IN_SECTION=1; IN_REQ=0; CURRENT_REQ=""; CURRENT_REQ_BLOCK=""
      continue
    fi
    if [ "$IN_SECTION" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^## [A-Z]'; then
        # Fechar ultimo req
        if [ -n "$CURRENT_REQ" ]; then
          # Checar conflito: header ja existe na spec
          if grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: ADICIONADO conflito — requisito '$CURRENT_REQ' ja existe na spec" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] ADICIONADO: $CAPABILITY / $CURRENT_REQ"
            else
              printf '\n%s' "$CURRENT_REQ_BLOCK" >> "$TMPSPEC"
            fi
            TOTAL_ADDED=$((TOTAL_ADDED + 1))
          fi
        fi
        IN_SECTION=0; break
      fi
      if echo "$LINE" | grep -q '^### Requisito:'; then
        if [ -n "$CURRENT_REQ" ]; then
          if grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: ADICIONADO conflito — '$CURRENT_REQ' ja existe" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] ADICIONADO: $CAPABILITY / $CURRENT_REQ"
            else
              printf '\n%s' "$CURRENT_REQ_BLOCK" >> "$TMPSPEC"
            fi
            TOTAL_ADDED=$((TOTAL_ADDED + 1))
          fi
        fi
        CURRENT_REQ=$(echo "$LINE" | sed 's/^### Requisito: *//')
        CURRENT_REQ_BLOCK="$LINE"$'\n'
      elif [ -n "$CURRENT_REQ" ]; then
        CURRENT_REQ_BLOCK="${CURRENT_REQ_BLOCK}${LINE}"$'\n'
      fi
    fi
  done < "$DELTA_FILE"
  # Ultimo req da secao ADDED (se arquivo terminar dentro da secao)
  if [ "$IN_SECTION" -eq 1 ] && [ -n "$CURRENT_REQ" ]; then
    if grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
      echo "ERRO: $CAPABILITY: ADICIONADO conflito — '$CURRENT_REQ' ja existe" >&2
      APPLY_ERRORS=$((APPLY_ERRORS + 1))
    else
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] ADICIONADO: $CAPABILITY / $CURRENT_REQ"
      else
        printf '\n%s' "$CURRENT_REQ_BLOCK" >> "$TMPSPEC"
      fi
      TOTAL_ADDED=$((TOTAL_ADDED + 1))
    fi
  fi

  # Processar MODIFIED — substituir bloco completo do requisito na spec
  IN_SECTION=0
  IN_REQ=0
  CURRENT_REQ=""
  CURRENT_REQ_BLOCK=""
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -qE '^## (MODIFICADO|MODIFIED)'; then
      IN_SECTION=1; IN_REQ=0; CURRENT_REQ=""; CURRENT_REQ_BLOCK=""
      continue
    fi
    if [ "$IN_SECTION" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^## [A-Z]'; then
        if [ -n "$CURRENT_REQ" ]; then
          if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: MODIFICADO — requisito '$CURRENT_REQ' nao encontrado na spec" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] MODIFICADO: $CAPABILITY / $CURRENT_REQ"
            else
              # Substituir bloco: extrair tudo antes do req, o novo bloco, tudo depois
              NEWTMP=$(mktemp /tmp/spec-mod-XXXXXX.md)
              AFTER_TMP=$(mktemp /tmp/spec-after-XXXXXX.md)
              FOUND_REQ=0
              SKIP=0
              while IFS= read -r SLINE; do
                if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
                  FOUND_REQ=1; SKIP=1
                  printf '%s\n' "$CURRENT_REQ_BLOCK" >> "$NEWTMP"
                  continue
                fi
                if [ "$SKIP" -eq 1 ]; then
                  if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
                    SKIP=0
                    printf '%s\n' "$SLINE" >> "$NEWTMP"
                  fi
                  # else: pular linha do bloco antigo
                else
                  printf '%s\n' "$SLINE" >> "$NEWTMP"
                fi
              done < "$TMPSPEC"
              cp "$NEWTMP" "$TMPSPEC"
              rm -f "$NEWTMP" "$AFTER_TMP"
            fi
            TOTAL_MODIFIED=$((TOTAL_MODIFIED + 1))
          fi
        fi
        IN_SECTION=0; break
      fi
      if echo "$LINE" | grep -q '^### Requisito:'; then
        if [ -n "$CURRENT_REQ" ]; then
          if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: MODIFICADO — '$CURRENT_REQ' nao encontrado" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] MODIFICADO: $CAPABILITY / $CURRENT_REQ"
            else
              NEWTMP=$(mktemp /tmp/spec-mod-XXXXXX.md)
              SKIP=0
              while IFS= read -r SLINE; do
                if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
                  SKIP=1
                  printf '%s\n' "$CURRENT_REQ_BLOCK" >> "$NEWTMP"
                  continue
                fi
                if [ "$SKIP" -eq 1 ]; then
                  if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
                    SKIP=0; printf '%s\n' "$SLINE" >> "$NEWTMP"
                  fi
                else
                  printf '%s\n' "$SLINE" >> "$NEWTMP"
                fi
              done < "$TMPSPEC"
              cp "$NEWTMP" "$TMPSPEC"
              rm -f "$NEWTMP"
            fi
            TOTAL_MODIFIED=$((TOTAL_MODIFIED + 1))
          fi
        fi
        CURRENT_REQ=$(echo "$LINE" | sed 's/^### Requisito: *//')
        CURRENT_REQ_BLOCK="$LINE"$'\n'
      elif [ -n "$CURRENT_REQ" ]; then
        CURRENT_REQ_BLOCK="${CURRENT_REQ_BLOCK}${LINE}"$'\n'
      fi
    fi
  done < "$DELTA_FILE"
  # Ultimo req da secao MODIFIED
  if [ "$IN_SECTION" -eq 1 ] && [ -n "$CURRENT_REQ" ]; then
    if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
      echo "ERRO: $CAPABILITY: MODIFICADO — '$CURRENT_REQ' nao encontrado na spec" >&2
      APPLY_ERRORS=$((APPLY_ERRORS + 1))
    else
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] MODIFICADO: $CAPABILITY / $CURRENT_REQ"
      else
        NEWTMP=$(mktemp /tmp/spec-mod-XXXXXX.md)
        SKIP=0
        while IFS= read -r SLINE; do
          if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
            SKIP=1
            printf '%s\n' "$CURRENT_REQ_BLOCK" >> "$NEWTMP"
            continue
          fi
          if [ "$SKIP" -eq 1 ]; then
            if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
              SKIP=0; printf '%s\n' "$SLINE" >> "$NEWTMP"
            fi
          else
            printf '%s\n' "$SLINE" >> "$NEWTMP"
          fi
        done < "$TMPSPEC"
        cp "$NEWTMP" "$TMPSPEC"
        rm -f "$NEWTMP"
      fi
      TOTAL_MODIFIED=$((TOTAL_MODIFIED + 1))
    fi
  fi

  # Processar REMOVED — remover bloco do requisito
  IN_SECTION=0
  CURRENT_REQ=""
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -qE '^## (REMOVIDO|REMOVED)'; then
      IN_SECTION=1; CURRENT_REQ=""
      continue
    fi
    if [ "$IN_SECTION" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^## [A-Z]'; then
        if [ -n "$CURRENT_REQ" ]; then
          if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: REMOVIDO — '$CURRENT_REQ' nao encontrado na spec" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] REMOVIDO: $CAPABILITY / $CURRENT_REQ"
            else
              NEWTMP=$(mktemp /tmp/spec-rem-XXXXXX.md)
              SKIP=0
              while IFS= read -r SLINE; do
                if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
                  SKIP=1; continue
                fi
                if [ "$SKIP" -eq 1 ]; then
                  if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
                    SKIP=0; printf '%s\n' "$SLINE" >> "$NEWTMP"
                  fi
                else
                  printf '%s\n' "$SLINE" >> "$NEWTMP"
                fi
              done < "$TMPSPEC"
              cp "$NEWTMP" "$TMPSPEC"; rm -f "$NEWTMP"
            fi
            TOTAL_REMOVED=$((TOTAL_REMOVED + 1))
          fi
          CURRENT_REQ=""
        fi
        IN_SECTION=0; break
      fi
      if echo "$LINE" | grep -q '^### Requisito:'; then
        if [ -n "$CURRENT_REQ" ]; then
          # Processar anterior
          if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
            echo "ERRO: $CAPABILITY: REMOVIDO — '$CURRENT_REQ' nao encontrado" >&2
            APPLY_ERRORS=$((APPLY_ERRORS + 1))
          else
            if [ "$DRY_RUN" -eq 1 ]; then
              echo "[DRY-RUN] REMOVIDO: $CAPABILITY / $CURRENT_REQ"
            else
              NEWTMP=$(mktemp /tmp/spec-rem-XXXXXX.md)
              SKIP=0
              while IFS= read -r SLINE; do
                if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
                  SKIP=1; continue
                fi
                if [ "$SKIP" -eq 1 ]; then
                  if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
                    SKIP=0; printf '%s\n' "$SLINE" >> "$NEWTMP"
                  fi
                else
                  printf '%s\n' "$SLINE" >> "$NEWTMP"
                fi
              done < "$TMPSPEC"
              cp "$NEWTMP" "$TMPSPEC"; rm -f "$NEWTMP"
            fi
            TOTAL_REMOVED=$((TOTAL_REMOVED + 1))
          fi
        fi
        CURRENT_REQ=$(echo "$LINE" | sed 's/^### Requisito: *//')
      fi
    fi
  done < "$DELTA_FILE"
  # Ultimo req da secao REMOVED
  if [ "$IN_SECTION" -eq 1 ] && [ -n "$CURRENT_REQ" ]; then
    if ! grep -q "^### Requisito: $CURRENT_REQ$" "$TMPSPEC" 2>/dev/null; then
      echo "ERRO: $CAPABILITY: REMOVIDO — '$CURRENT_REQ' nao encontrado" >&2
      APPLY_ERRORS=$((APPLY_ERRORS + 1))
    else
      if [ "$DRY_RUN" -eq 1 ]; then
        echo "[DRY-RUN] REMOVIDO: $CAPABILITY / $CURRENT_REQ"
      else
        NEWTMP=$(mktemp /tmp/spec-rem-XXXXXX.md)
        SKIP=0
        while IFS= read -r SLINE; do
          if echo "$SLINE" | grep -q "^### Requisito: $CURRENT_REQ$"; then
            SKIP=1; continue
          fi
          if [ "$SKIP" -eq 1 ]; then
            if echo "$SLINE" | grep -qE '^(## |### Requisito:)'; then
              SKIP=0; printf '%s\n' "$SLINE" >> "$NEWTMP"
            fi
          else
            printf '%s\n' "$SLINE" >> "$NEWTMP"
          fi
        done < "$TMPSPEC"
        cp "$NEWTMP" "$TMPSPEC"; rm -f "$NEWTMP"
      fi
      TOTAL_REMOVED=$((TOTAL_REMOVED + 1))
    fi
  fi

  # Processar RENAMED — renomear header DE/PARA
  IN_SECTION=0
  REQ_DE=""
  REQ_PARA=""
  while IFS= read -r LINE; do
    if echo "$LINE" | grep -qE '^## (RENOMEADO|RENAMED)'; then
      IN_SECTION=1; REQ_DE=""; REQ_PARA=""
      continue
    fi
    if [ "$IN_SECTION" -eq 1 ]; then
      if echo "$LINE" | grep -qE '^## [A-Z]'; then
        IN_SECTION=0
        break
      fi
      if echo "$LINE" | grep -qE '^\*\*DE:\*\*|^- \*\*DE:\*\*'; then
        REQ_DE=$(echo "$LINE" | sed 's/.*\*\*DE:\*\* *//')
      fi
      if echo "$LINE" | grep -qE '^\*\*PARA:\*\*|^- \*\*PARA:\*\*'; then
        REQ_PARA=$(echo "$LINE" | sed 's/.*\*\*PARA:\*\* *//')
      fi
      # Quando temos os dois, aplicar
      if [ -n "$REQ_DE" ] && [ -n "$REQ_PARA" ]; then
        if ! grep -q "^### Requisito: $REQ_DE$" "$TMPSPEC" 2>/dev/null; then
          echo "ERRO: $CAPABILITY: RENOMEADO — '$REQ_DE' nao encontrado na spec" >&2
          APPLY_ERRORS=$((APPLY_ERRORS + 1))
        elif grep -q "^### Requisito: $REQ_PARA$" "$TMPSPEC" 2>/dev/null; then
          echo "ERRO: $CAPABILITY: RENOMEADO — '$REQ_PARA' ja existe na spec (conflito)" >&2
          APPLY_ERRORS=$((APPLY_ERRORS + 1))
        else
          if [ "$DRY_RUN" -eq 1 ]; then
            echo "[DRY-RUN] RENOMEADO: $CAPABILITY / $REQ_DE -> $REQ_PARA"
          else
            sed -i.bak "s/^### Requisito: $REQ_DE$/### Requisito: $REQ_PARA/" "$TMPSPEC"
            rm -f "$TMPSPEC.bak"
          fi
          TOTAL_RENAMED=$((TOTAL_RENAMED + 1))
        fi
        REQ_DE=""; REQ_PARA=""
      fi
    fi
  done < "$DELTA_FILE"

  # Promover tmp -> spec (so se sem erros e nao dry-run)
  if [ "$APPLY_ERRORS" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
    cp "$TMPSPEC" "$SPEC_FILE"
  fi
  rm -f "$TMPSPEC"

done

# --- Checar confirmacao (se nao --yes e nao dry-run e ha algo a fazer) ---
TOTAL_OPS=$((TOTAL_ADDED + TOTAL_MODIFIED + TOTAL_REMOVED + TOTAL_RENAMED))

if [ "$APPLY_ERRORS" -gt 0 ]; then
  echo "" >&2
  echo "spec-merge: ABORTADO — $APPLY_ERRORS erro(s) encontrado(s). Nenhuma escrita foi promovida." >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then
  echo ""
  echo "spec-merge: DRY-RUN concluido"
  echo "+ $TOTAL_ADDED adicionados / ~ $TOTAL_MODIFIED modificados / - $TOTAL_REMOVED removidos / -> $TOTAL_RENAMED renomeados"
  exit 0
fi

if [ "$YES" -eq 0 ] && [ "$TOTAL_OPS" -gt 0 ]; then
  echo ""
  echo "Operacoes a aplicar: + $TOTAL_ADDED adicionados / ~ $TOTAL_MODIFIED modificados / - $TOTAL_REMOVED removidos / -> $TOTAL_RENAMED renomeados"
  printf "Confirmar? [s/N] "
  read -r CONFIRM
  case "$CONFIRM" in
    [sSyY]) ;;
    *) echo "Abortado pelo usuario."; exit 1 ;;
  esac
fi

# --- Archive: mover change para _archive/AAAA-MM-DD-<slug>/ ---
ARCHIVE_DATE=$(date +%F)
ARCHIVE_DIR="$PRODUTO_ROOT/specs/_archive/${ARCHIVE_DATE}-${SLUG}"

if [ -d "$ARCHIVE_DIR" ]; then
  echo "ERRO: destino de archive ja existe: $ARCHIVE_DIR — nao sobrescrever historico" >&2
  exit 1
fi

mv "$CHANGE_DIR" "$ARCHIVE_DIR"

echo ""
echo "spec-merge: OK"
echo "+ $TOTAL_ADDED adicionados / ~ $TOTAL_MODIFIED modificados / - $TOTAL_REMOVED removidos / -> $TOTAL_RENAMED renomeados"
echo "Arquivado em: $ARCHIVE_DIR"
exit 0
