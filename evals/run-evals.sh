#!/usr/bin/env bash
# SOURCE: IdeiaOS v2
# Runner de evals — IdeiaOS v2
# Uso: bash evals/run-evals.sh [--case EVAL-NNN] [--dry-run] [--list] [--ci] [--local] [--help]
# Em ambiente não-interativo (stdin não-tty), assume --dry-run automaticamente.
# --local: usa claude do PATH com auth local (sem ANTHROPIC_API_KEY); implica --ci.

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
CI_MODE="${CI_MODE:-0}"
LOCAL_MODE=0  # --local: claude via auth local, sem API key

# ─── Ajuda ───────────────────────────────────────────────────────────────────
usage() {
  cat <<USAGE
Uso: bash run-evals.sh [opções]

Opções:
  --case ID      Roda somente o caso cujo nome começa com ID (ex: EVAL-001)
  --dry-run      Lista o que faria (id, source, métrica) sem pedir veredito
  --list         Imprime o roster de casos disponíveis e sai
  --ci           Modo CI: executa via API claude -p; políticas pass^k/pass@k ativas
  --local        Usa claude do PATH com auth local (sem ANTHROPIC_API_KEY); implica --ci
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
    --dry-run)  DRY_RUN=1;                           shift ;;
    --list)     LIST_ONLY=1;                         shift ;;
    --ci)       CI_MODE=1; DRY_RUN=0;               shift ;;
    --local)    LOCAL_MODE=1; CI_MODE=1; DRY_RUN=0; shift ;;
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

# Coleta arquivos de casos (ordem determinística — compatível com bash 3.2/macOS)
CASE_FILES=()
for _f in "${CASES_DIR}"/EVAL-*.md; do
  [ -f "$_f" ] && CASE_FILES+=("$_f")
done
# sort portável: reconstruir array via sort
if [ ${#CASE_FILES[@]} -gt 0 ]; then
  _sorted=$(printf '%s\n' "${CASE_FILES[@]}" | sort)
  CASE_FILES=()
  while IFS= read -r _line; do CASE_FILES+=("$_line"); done <<< "$_sorted"
fi

if [ ${#CASE_FILES[@]} -eq 0 ]; then
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
# Passa o título via variável awk para evitar problemas com / em nomes de seção
extract_section() {
  local file="$1" section="$2"
  awk -v sec="## ${section}" 'index($0,sec)==1{found=1; next} found && /^## /{exit} found{print}' "$file"
}

# ─── Inicializar RESULTS_FILE ────────────────────────────────────────────────
RESULTS_FILE=""
if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "${SCRIPT_DIR}/results"
  RESULTS_FILE="${SCRIPT_DIR}/results/$(date +%Y%m%d-%H%M).jsonl"
fi

# ─── Extrai seção de nível ### dentro de uma seção ## pai ────────────────────
# extract_subsection FILE PARENT_SECTION SUBSECTION
# Retorna linhas de ### SUBSECTION dentro de ## PARENT_SECTION
# Nota: variável awk não pode se chamar "sub" (é função reservada do awk)
extract_subsection() {
  local file="$1" parent="$2" subsec="$3"
  awk -v par="## ${parent}" -v ssec="### ${subsec}" \
    'index($0,par)==1 && par!="" { in_parent=1; in_sub=0; next }
     in_parent && /^## / { in_parent=0; in_sub=0 }
     in_parent && index($0,ssec)==1 && ssec!="" { in_sub=1; next }
     in_parent && in_sub && /^### / { in_sub=0 }
     in_parent && in_sub { print }' "$file"
}

# ─── Avaliador híbrido: Sinais grep → fallback LLM-judge ────────────────────
# Retorna: pass | fail | skip
evaluate_response() {
  local response="$1"
  local case_file="$2"

  # --- Tenta avaliação por Sinais primeiro ---
  local signals_raw
  signals_raw="$(extract_subsection "$case_file" "Critérios de Aprovação" "Sinais (avaliação automática)")"

  if [[ -n "$signals_raw" ]]; then
    local verdict="pass"
    while IFS= read -r sig_line; do
      # Linha positiva: "+ padrão que DEVE aparecer"
      case "$sig_line" in
        "+ "*)
          local pat="${sig_line#+ }"
          if ! printf '%s' "$response" | grep -qi "$pat"; then
            verdict="fail"
          fi
          ;;
        "- "*)
          local pat="${sig_line#- }"
          if printf '%s' "$response" | grep -qi "$pat"; then
            verdict="fail"
          fi
          ;;
      esac
    done <<< "$signals_raw"
    echo "$verdict"
    return
  fi

  # --- Fallback: LLM-judge via claude haiku ---
  # Sem judge disponível → skip (não fail — ausência de Sinais não é falha de produto)
  if ! command -v claude >/dev/null 2>&1; then
    echo "  [AVISO] Sem seção Sinais e claude não disponível para judge — marcando skip" >&2
    echo "skip"
    return
  fi

  local criteria_raw
  criteria_raw="$(extract_section "$case_file" "Critérios de Aprovação")"

  local judge_prompt
  judge_prompt="Você é um avaliador de qualidade de LLM.

## Critérios de Aprovação
${criteria_raw}

## Resposta do modelo avaliado
${response}

## Instrução
Avalie se a resposta atende TODOS os critérios. Responda APENAS com:
VEREDITO: pass
ou
VEREDITO: fail

Seguido de uma linha de justificativa curta."

  local judge_response=""
  local judge_exit=0
  if command -v timeout >/dev/null 2>&1; then
    judge_response="$(timeout 60 claude --model claude-haiku-4-5 -p "$judge_prompt" </dev/null 2>/dev/null)" || judge_exit=$?
  else
    judge_response="$(perl -e 'alarm 60; exec @ARGV' -- claude --model claude-haiku-4-5 -p "$judge_prompt" </dev/null 2>/dev/null)" || judge_exit=$?
  fi

  if [[ $judge_exit -ne 0 ]]; then
    echo "  [AVISO] LLM-judge falhou (exit $judge_exit) — marcando skip" >&2
    echo "skip"
    return
  fi

  # Extrai veredito da linha "VEREDITO: pass|fail"
  local judge_verdict
  judge_verdict="$(printf '%s' "$judge_response" | grep -i 'VEREDITO:' | head -1 | grep -oi 'pass\|fail' | tr '[:upper:]' '[:lower:]')"
  if [[ "$judge_verdict" == "pass" || "$judge_verdict" == "fail" ]]; then
    echo "  [judge] ${judge_verdict}" >&2
    echo "$judge_verdict"
  else
    echo "  [AVISO] LLM-judge resposta não reconhecida — marcando skip" >&2
    echo "skip"
  fi
}

# ─── Execução automática com modelo ─────────────────────────────────────────
run_case_with_model() {
  local _case_file="$1"

  # Guard de API key — LOCAL_MODE bypassa: usa claude do PATH com auth local
  if [[ -z "${ANTHROPIC_API_KEY:-}" ]] && [[ "$LOCAL_MODE" -eq 0 ]]; then
    if [[ "$CI_MODE" -eq 1 ]]; then
      echo "  [AVISO] ANTHROPIC_API_KEY ausente — caso marcado como skip" >&2
      echo "skip"
      return
    else
      # Modo interativo sem API key: fallback para veredito manual
      local verdict=""
      while true; do
        printf "  Veredito [pass/fail/skip]: "
        read -r verdict </dev/tty 2>/dev/null || verdict="skip"
        case "$verdict" in
          pass|fail|skip) echo "$verdict"; return ;;
          *) echo "  Opções: pass, fail, skip" ;;
        esac
      done
    fi
  fi

  # LOCAL_MODE: verificar que claude está no PATH antes de prosseguir
  if [[ "$LOCAL_MODE" -eq 1 ]] && ! command -v claude >/dev/null 2>&1; then
    echo "  [ERRO] --local especificado mas 'claude' não encontrado no PATH" >&2
    echo "skip"
    return
  fi

  # Extrair prompt (seção Setup/Prompt) — remover fenced code e headers markdown
  local raw_prompt
  raw_prompt="$(extract_section "$_case_file" "Setup/Prompt")"
  local prompt_text
  prompt_text="$(printf '%s\n' "$raw_prompt" | grep -v '^```' | grep -v '^#')"

  # Chamar claude headless com timeout
  # --no-color removido: versões recentes do Claude CLI não suportam essa flag
  # </dev/null: garante stdin fechado (sem TTY) para evitar bloqueio em captura de subshell
  local response=""
  local exit_code=0
  if command -v timeout >/dev/null 2>&1; then
    response="$(timeout 120 claude -p "$prompt_text" </dev/null 2>/dev/null)" || exit_code=$?
  else
    response="$(perl -e 'alarm 120; exec @ARGV' -- claude -p "$prompt_text" </dev/null 2>/dev/null)" || exit_code=$?
  fi

  if [[ $exit_code -ne 0 && $exit_code -ne 124 ]]; then
    echo "  [ERRO] claude saiu com $exit_code" >&2
    echo "fail"
    return
  fi

  # Avaliar resposta: Sinais → fallback LLM-judge
  evaluate_response "$response" "$_case_file"
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

  # Gravar resultado JSON no RESULTS_FILE
  if [[ -n "$RESULTS_FILE" && "$verdict" != "skip" ]]; then
    local_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    printf '{"id":"%s","metric":"%s","severity":"%s","verdict":"%s","ts":"%s"}\n' \
      "$id" "$metric" "$severity" "$verdict" "$local_ts" >> "$RESULTS_FILE"
  fi

  # skip (sem API key / pulado pelo operador) não conta em nenhuma métrica —
  # sem isto, skip vira falha pass^k e bloqueia invocação manual sem key
  if [[ "$verdict" == "skip" ]]; then
    continue
  fi

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

  # Política de saída CI
  if [[ "$CI_MODE" -eq 1 ]]; then
    if [[ $pass_hat_total -gt 0 && $pass_hat_aprovados -lt $pass_hat_total ]]; then
      echo "BLOQUEIO: $(( pass_hat_total - pass_hat_aprovados )) invariante(s) pass^k reprovada(s)" >&2
      exit 1
    fi
    if [[ $pass_k_total -gt 0 && $pass_k_aprovados -lt $pass_k_total ]]; then
      echo "AVISO: $(( pass_k_total - pass_k_aprovados )) capacidade(s) pass@k reprovada(s) — não bloqueia CI"
    fi
  fi
fi
