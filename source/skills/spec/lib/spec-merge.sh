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


# --- Aplicar delta em cada arquivo ---
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
