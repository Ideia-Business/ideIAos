#!/bin/bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6
#
# spec-validate.sh <dir-da-change>
#
# Gate binario para validar delta antes do merge.
# Exit 0 = valido; Exit 1 = delta invalido; Exit 2 = erro de invocacao.
#
# Validacoes:
#   (a) Todo cenario usa exatamente #### (4 hashtags) — rejeita ### Cenario: (3 hashtags)
#   (b) Cada ### Requisito: em secoes ADDED/MODIFIED tem >= 1 #### Cenario:
#   (c) Headers de requisito nao duplicados no mesmo arquivo de delta
#   (d) Bloco ## MODIFICADO exige requisito completo (>= 1 cenario no bloco)
#   (e) ## REMOVIDO exige **Motivo** e **Migracao** por requisito

set -euo pipefail

CHANGE_DIR="${1:-}"

if [ -z "$CHANGE_DIR" ]; then
  echo "ERRO: uso: spec-validate.sh <dir-da-change>" >&2
  exit 2
fi

if [ ! -d "$CHANGE_DIR" ]; then
  echo "ERRO: diretorio nao encontrado: $CHANGE_DIR" >&2
  exit 2
fi

DELTA_DIR="$CHANGE_DIR/delta"
if [ ! -d "$DELTA_DIR" ]; then
  echo "ERRO: subdirectorio delta/ ausente em: $CHANGE_DIR" >&2
  exit 2
fi

ERRORS=0
FOUND_ANY=0

# Processar cada arquivo .md em delta/
for DELTA_FILE in "$DELTA_DIR"/*.md; do
  if [ ! -f "$DELTA_FILE" ]; then
    continue
  fi

  FOUND_ANY=1
  FNAME=$(basename "$DELTA_FILE")

  # (a) Rejeitar cenarios com ### (3 hashtags exatos seguidos de "Cenario:" ou "Scenario:")
  while IFS= read -r BADLINE; do
    if [ -n "$BADLINE" ]; then
      echo "ERRO: $FNAME: cenario com 3 hashtags (###) — use #### (4 hashtags): $BADLINE" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < <(grep '^### [Cc]en' "$DELTA_FILE" 2>/dev/null || true)

  # Determinar secoes presentes
  # Processar o arquivo em modo de secao para validacoes (b), (c), (d), (e)

  CURRENT_SECTION="NONE"
  IN_REQ=0
  REQ_NAME=""
  REQ_LINE=0
  HAS_SCENARIO=0
  LINE_NUM=0
  SEEN_REQS=""

  # (e) variaveis de REMOVIDO
  REM_REQ_NAME=""
  REM_REQ_LINE=0
  REM_HAS_MOTIVO=0
  REM_HAS_MIGRACAO=0

  while IFS= read -r LINE; do
    LINE_NUM=$((LINE_NUM + 1))

    # Detectar inicio de secao principal
    if echo "$LINE" | grep -qE '^## (ADICIONADO|ADDED|MODIFICADO|MODIFIED|REMOVIDO|REMOVED|RENOMEADO|RENAMED)'; then
      # Fechar requisito anterior da secao anterior
      if [ "$IN_REQ" -eq 1 ] && [ -n "$REQ_NAME" ]; then
        if [ "$CURRENT_SECTION" = "ADDED" ] || [ "$CURRENT_SECTION" = "MODIFIED" ]; then
          if [ "$HAS_SCENARIO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REQ_LINE: requisito '$REQ_NAME' sem nenhum #### Cenario:" >&2
            ERRORS=$((ERRORS + 1))
          fi
        fi
        if [ "$CURRENT_SECTION" = "REMOVED" ]; then
          if [ "$REM_HAS_MOTIVO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Motivo**" >&2
            ERRORS=$((ERRORS + 1))
          fi
          if [ "$REM_HAS_MIGRACAO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Migracao**/**Migracao**" >&2
            ERRORS=$((ERRORS + 1))
          fi
        fi
      fi
      IN_REQ=0
      REQ_NAME=""
      HAS_SCENARIO=0
      REM_REQ_NAME=""
      REM_HAS_MOTIVO=0
      REM_HAS_MIGRACAO=0

      # Classificar secao atual
      if echo "$LINE" | grep -qE '^## (ADICIONADO|ADDED)'; then
        CURRENT_SECTION="ADDED"
      elif echo "$LINE" | grep -qE '^## (MODIFICADO|MODIFIED)'; then
        CURRENT_SECTION="MODIFIED"
      elif echo "$LINE" | grep -qE '^## (REMOVIDO|REMOVED)'; then
        CURRENT_SECTION="REMOVED"
      elif echo "$LINE" | grep -qE '^## (RENOMEADO|RENAMED)'; then
        CURRENT_SECTION="RENAMED"
      else
        CURRENT_SECTION="OTHER"
      fi
      continue
    fi

    # Detectar inicio de requisito
    if echo "$LINE" | grep -q '^### Requisito:'; then
      # Fechar requisito anterior
      if [ "$IN_REQ" -eq 1 ] && [ -n "$REQ_NAME" ]; then
        if [ "$CURRENT_SECTION" = "ADDED" ] || [ "$CURRENT_SECTION" = "MODIFIED" ]; then
          if [ "$HAS_SCENARIO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REQ_LINE: requisito '$REQ_NAME' sem nenhum #### Cenario:" >&2
            ERRORS=$((ERRORS + 1))
          fi
        fi
        if [ "$CURRENT_SECTION" = "REMOVED" ]; then
          if [ "$REM_HAS_MOTIVO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Motivo**" >&2
            ERRORS=$((ERRORS + 1))
          fi
          if [ "$REM_HAS_MIGRACAO" -eq 0 ]; then
            echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Migracao**" >&2
            ERRORS=$((ERRORS + 1))
          fi
        fi
      fi

      CURRENT_REQ_RAW=$(echo "$LINE" | sed 's/^### Requisito: *//')

      # (c) Verificar duplicatas de header no arquivo
      if echo "$SEEN_REQS" | grep -qF "|${CURRENT_REQ_RAW}|"; then
        echo "ERRO: $FNAME:$LINE_NUM: header de requisito duplicado: '$CURRENT_REQ_RAW'" >&2
        ERRORS=$((ERRORS + 1))
      fi
      SEEN_REQS="${SEEN_REQS}|${CURRENT_REQ_RAW}|"

      REQ_NAME="$CURRENT_REQ_RAW"
      REQ_LINE=$LINE_NUM
      HAS_SCENARIO=0
      IN_REQ=1

      if [ "$CURRENT_SECTION" = "REMOVED" ]; then
        REM_REQ_NAME="$REQ_NAME"
        REM_REQ_LINE=$LINE_NUM
        REM_HAS_MOTIVO=0
        REM_HAS_MIGRACAO=0
      fi
      continue
    fi

    # Dentro de um requisito
    if [ "$IN_REQ" -eq 1 ]; then
      # Detectar cenario (4 hashtags)
      if echo "$LINE" | grep -q '^#### '; then
        HAS_SCENARIO=1
      fi

      # (e) Detectar Motivo e Migracao em REMOVED
      if [ "$CURRENT_SECTION" = "REMOVED" ]; then
        # Aceitar **Motivo**, **Motivo:** sem acento
        if echo "$LINE" | grep -qi 'Motivo'; then
          REM_HAS_MOTIVO=1
        fi
        # Aceitar Migracao, Migração, migration (variantes de encoding)
        if echo "$LINE" | grep -qi 'migra'; then
          REM_HAS_MIGRACAO=1
        fi
      fi
    fi

  done < "$DELTA_FILE"

  # Fechar ultimo requisito do arquivo
  if [ "$IN_REQ" -eq 1 ] && [ -n "$REQ_NAME" ]; then
    if [ "$CURRENT_SECTION" = "ADDED" ] || [ "$CURRENT_SECTION" = "MODIFIED" ]; then
      if [ "$HAS_SCENARIO" -eq 0 ]; then
        echo "ERRO: $FNAME:$REQ_LINE: requisito '$REQ_NAME' sem nenhum #### Cenario:" >&2
        ERRORS=$((ERRORS + 1))
      fi
    fi
    if [ "$CURRENT_SECTION" = "REMOVED" ]; then
      if [ "$REM_HAS_MOTIVO" -eq 0 ]; then
        echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Motivo**" >&2
        ERRORS=$((ERRORS + 1))
      fi
      if [ "$REM_HAS_MIGRACAO" -eq 0 ]; then
        echo "ERRO: $FNAME:$REM_REQ_LINE: REMOVIDO '$REM_REQ_NAME' sem **Migracao**" >&2
        ERRORS=$((ERRORS + 1))
      fi
    fi
  fi

  # (d) Bloco MODIFICADO: cada requisito deve ter >= 1 cenario (ja coberto acima)
  # — validado no loop acima por CURRENT_SECTION=MODIFIED + HAS_SCENARIO

done

if [ "$FOUND_ANY" -eq 0 ]; then
  echo "AVISO: nenhum arquivo .md encontrado em $DELTA_DIR" >&2
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "spec-validate: FALHOU com $ERRORS erro(s). Corrija o delta antes de aplicar o merge." >&2
  exit 1
fi

echo "spec-validate: OK — delta valido em $CHANGE_DIR"
exit 0
