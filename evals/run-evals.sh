#!/usr/bin/env bash
# SOURCE: IdeiaOS v2
# Runner de evals — IdeiaOS v2
# Uso: bash evals/run-evals.sh [--case EVAL-NNN] [--dry-run] [--list] [--help]
# Em ambiente não-interativo (stdin não-tty), assume --dry-run automaticamente.

set -uo pipefail

# Detecta ambiente não-interativo antes de qualquer processamento de args
[ -t 0 ] || DRY_RUN=1

# Diretório de casos relativo ao script (funciona de qualquer cwd)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CASES_DIR="${SCRIPT_DIR}/cases"

# ─── Defaults ────────────────────────────────────────────────────────────────
DRY_RUN="${DRY_RUN:-0}"
FILTER_CASE=""
LIST_ONLY=0

# ─── Ajuda ───────────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
Uso: bash run-evals.sh [opções]

Opções:
  --case ID      Roda somente o caso cujo nome começa com ID (ex: EVAL-001)
  --dry-run      Lista o que faria (id, source, métrica) sem pedir veredito
  --list         Imprime o roster de casos disponíveis e sai
  --help         Mostra esta ajuda

Comportamento padrão (sem args):
  Itera todos os casos em evals/cases/EVAL-*.md em ordem alfabética.
  Para cada caso, exibe id/title/mode/metric/k + Setup/Prompt + Critérios de Aprovação.
  Pausa pedindo veredito do operador: pass | fail | skip
  Ao final, imprime sumário m/k por métrica.

Ambiente não-interativo (stdin não-tty):
  Assume --dry-run automaticamente — nunca bloqueia em CI/pipelines.
USAGE
}

# ─── Parse de argumentos ─────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=1;              shift ;;
    --list)     LIST_ONLY=1;            shift ;;
    --case)
      if [[ $# -lt 2 ]]; then
        echo "ERRO: --case requer um ID (ex: EVAL-001)" >&2; exit 1
      fi
      FILTER_CASE="$2"; shift 2 ;;
    --help|-h)  usage; exit 0 ;;
    *)
      echo "ERRO: argumento desconhecido: $1" >&2
      usage >&2
      exit 1 ;;
  esac
done

# ─── Verificação do diretório de casos ───────────────────────────────────────
if [[ ! -d "$CASES_DIR" ]]; then
  echo "ERRO: diretório de casos não encontrado: $CASES_DIR" >&2
  exit 1
fi

# Coleta arquivos de casos (ordem determinística)
mapfile -t CASE_FILES < <(ls "${CASES_DIR}"/EVAL-*.md 2>/dev/null | sort)

if [[ ${#CASE_FILES[@]} -eq 0 ]]; then
  echo "Nenhum caso encontrado em $CASES_DIR" >&2
  exit 0
fi

# ─── Modo --list ─────────────────────────────────────────────────────────────
if [[ $LIST_ONLY -eq 1 ]]; then
  echo "Casos disponíveis em ${CASES_DIR}:"
  for f in "${CASE_FILES[@]}"; do
    basename "$f"
  done
  exit 0
fi

# ─── Funções auxiliares de parsing ───────────────────────────────────────────

# Extrai valor de campo YAML do frontmatter (entre --- delimitadores)
extract_field() {
  local file="$1" field="$2"
  awk "/^---$/{f++} f==1 && /^${field}:/{sub(/^${field}:[[:space:]]*/,\"\"); gsub(/[\"']/,\"\"); print; exit}" "$file"
}

# Extrai conteúdo de uma seção Markdown (## Título até a próxima ##)
extract_section() {
  local file="$1" section="$2"
  awk "/^## ${section}/{found=1; next} found && /^## /{exit} found{print}" "$file"
}

# ─── Ponto de extensão: execução automática com modelo ───────────────────────
# TODO: plugar execução automática (API/harness) aqui.
# Quando um harness LLM estiver disponível:
#   1. Receber o prompt da seção Setup/Prompt do caso
#   2. Chamar o modelo k vezes
#   3. Avaliar cada resposta contra os Critérios de Aprovação
#   4. Retornar "pass" ou "fail" automaticamente
# Por enquanto, retorna veredito manual coletado do operador.
run_case_with_model() {
  local _case_file="$1"
  # Modo manual: operador fornece veredito
  local verdict=""
  while true; do
    printf "  Veredito [pass/fail/skip]: "
    read -r verdict </dev/tty 2>/dev/null || verdict="skip"
    case "$verdict" in
      pass|fail|skip) echo "$verdict"; return ;;
      *) echo "  Opções: pass, fail, skip" ;;
    esac
  done
}

# ─── Loop principal ───────────────────────────────────────────────────────────
pass_k_total=0;   pass_k_aprovados=0
pass_hat_total=0; pass_hat_aprovados=0

for case_file in "${CASE_FILES[@]}"; do
  fname="$(basename "$case_file")"

  # Filtro --case: casa por prefixo EVAL-NNN no nome do arquivo
  if [[ -n "$FILTER_CASE" ]]; then
    if [[ "$fname" != "${FILTER_CASE}"* ]]; then
      continue
    fi
  fi

  # Extrai metadados do frontmatter
  id="$(extract_field "$case_file" "id")"
  title="$(extract_field "$case_file" "title")"
  source_ref="$(extract_field "$case_file" "source")"
  mode="$(extract_field "$case_file" "mode")"
  metric="$(extract_field "$case_file" "metric")"
  k_val="$(extract_field "$case_file" "k")"
  severity="$(extract_field "$case_file" "severity")"

  # Exibe cabeçalho do caso
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  ${id} — ${title}"
  echo "  Modo: ${mode}  |  Métrica: ${metric}  |  k=${k_val}  |  Severidade: ${severity}"
  echo "  Source: ${source_ref}"
  echo "════════════════════════════════════════════════════════════════"

  # Exibe Setup/Prompt e Critérios de Aprovação
  echo ""
  echo "── Setup/Prompt ─────────────────────────────────────────────────"
  extract_section "$case_file" "Setup/Prompt"
  echo ""
  echo "── Critérios de Aprovação ───────────────────────────────────────"
  extract_section "$case_file" "Critérios de Aprovação"
  echo ""

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] Pulando veredito."
    continue
  fi

  # Coleta veredito e contabiliza
  verdict="$(run_case_with_model "$case_file")"
  echo "  → ${id}: ${verdict}"

  if [[ "$metric" == "pass@k" ]]; then
    pass_k_total=$(( pass_k_total + 1 ))
    [[ "$verdict" == "pass" ]] && pass_k_aprovados=$(( pass_k_aprovados + 1 ))
  elif [[ "$metric" == "pass^k" ]]; then
    pass_hat_total=$(( pass_hat_total + 1 ))
    [[ "$verdict" == "pass" ]] && pass_hat_aprovados=$(( pass_hat_aprovados + 1 ))
  fi
done

# ─── Sumário ─────────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" -eq 0 ]]; then
  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  SUMÁRIO"
  echo "  pass@k  (produtividade): ${pass_k_aprovados}/${pass_k_total}"
  echo "  pass^k  (invariantes):   ${pass_hat_aprovados}/${pass_hat_total}"
  if [[ $pass_hat_total -gt 0 && $pass_hat_aprovados -lt $pass_hat_total ]]; then
    echo "  ATENÇÃO: $(( pass_hat_total - pass_hat_aprovados )) caso(s) pass^k REPROVADOS — invariante violada."
  fi
  echo "════════════════════════════════════════════════════════════════"
fi
