#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-analyze.sh <produto-root> [<capability>] [--advisory-only]
#
# Analisador da SPEC VIVA (source-of-truth specs/<cap>/spec.md, JÁ mergeada).
# Complementa — NÃO duplica — spec-validate.sh:
#   • spec-validate.sh gateia o DELTA  (pré-merge, no _changes/<slug>/delta/)
#   • spec-analyze.sh   gateia a FONTE  (pós-merge, specs/<cap>/spec.md)
#
# Modelo de seção (corrigido após verificação adversarial wf_99173505): a ZONA DE
# CONTRATO é `## Requisitos`. Só requisitos AÍ são contrato testável (A1/A2/A3 HARD).
# `### Requisito:` fora dela = misplaced (A6 ADVISORY, não-silencioso). Tudo é
# fence-aware (exemplos em ``` não disparam). Todas as detecções vêm do motor
# compartilhado spec-grammar.sh (sem regex duplicada inline).
#
# DETERMINÍSTICO (HARD — falha o exit):
#   A1  requisito (em ## Requisitos) sem nenhum #### Cenário (não-testável)
#   A2  cenário em nível errado (###/#####/######) dentro de um requisito de contrato
#   A3  header de requisito duplicado dentro de ## Requisitos
#   A4  token de seção de delta vazado na fonte (## ADICIONADO…, qualquer caixa, fora de fence)
#   (spec ilegível também é HARD — gate determinístico não pode falhar em silêncio)
#
# ADVISORY (NUNCA falha o exit):
#   A5  cross-ref spec→código: path citado entre backticks que não existe no produto
#   A6  '### Requisito:' fora de ## Requisitos (misplaced — contrato vive em ## Requisitos)
#   + passes LLM (clareza, cobertura, caminho-de-erro, vocabulário) — feitos pela skill /spec
#
# Exit: 0 = limpo (ou --advisory-only) · 1 = ≥1 defeito HARD · 2 = erro de invocação
# Uso:  bash spec-analyze.sh <produto-root> [<capability>] [--advisory-only]
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/spec-grammar.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ROOT="${1:-}"
[ -n "$ROOT" ] || { echo "ERRO: uso: spec-analyze.sh <produto-root> [<capability>] [--advisory-only]" >&2; exit 2; }
shift
ADVISORY_ONLY=0
CAP=""
for a in "$@"; do
  case "$a" in
    --advisory-only) ADVISORY_ONLY=1 ;;
    --*) echo "ERRO: flag desconhecida: $a" >&2; exit 2 ;;
    *) CAP="$a" ;;
  esac
done

SPECS_DIR="$ROOT/specs"
[ -d "$SPECS_DIR" ] || { echo "ERRO: diretório de specs não encontrado: $SPECS_DIR" >&2; exit 2; }

SPEC_FILES=()
if [ -n "$CAP" ]; then
  F="$SPECS_DIR/$CAP/spec.md"
  [ -f "$F" ] || { echo "ERRO: capability '$CAP' sem spec.md em $F" >&2; exit 2; }
  SPEC_FILES+=("$F")
else
  for d in "$SPECS_DIR"/*/; do
    base="$(basename "$d")"
    case "$base" in _*) continue ;; esac
    [ -f "$d/spec.md" ] && SPEC_FILES+=("$d/spec.md")
  done
fi

echo -e "\n${CYAN}${BOLD}━━━ spec-analyze: ${#SPEC_FILES[@]} spec(s) em $SPECS_DIR ━━━${NC}"
if [ "${#SPEC_FILES[@]}" -eq 0 ]; then
  echo -e "  ${CYAN}ℹ${NC} nenhuma spec viva encontrada — nada a analisar"
  exit 0
fi

ERRORS=0
ADVISORY_BUF=""

for SPEC in "${SPEC_FILES[@]}"; do
  CAPNAME="$(basename "$(dirname "$SPEC")")"

  # spec ilegível = defeito HARD (gate determinístico não falha em silêncio)
  if [ ! -r "$SPEC" ]; then
    echo -e "  ${RED}✗ IO${NC} $CAPNAME/spec.md — ilegível (sem permissão de leitura)"
    ERRORS=$((ERRORS + 1)); continue
  fi

  SCAN="$(gram_scan_reqs "$SPEC")"

  # ── A1: requisito de contrato (## Requisitos) sem cenário ──
  while IFS=$'\t' read -r line name; do
    [ -n "${name:-}" ] || continue
    echo -e "  ${RED}✗ A1${NC} $CAPNAME/spec.md:$line — requisito '$name' sem nenhum #### Cenário (não-testável)"
    ERRORS=$((ERRORS + 1))
  done < <(printf '%s\n' "$SCAN" | awk -F'\t' '$5=="REQUISITOS" && $3=="0" {print $2"\t"$1}')

  # ── A2: cenário em nível errado dentro de um requisito de contrato ──
  while IFS=$'\t' read -r line name; do
    [ -n "${name:-}" ] || continue
    echo -e "  ${RED}✗ A2${NC} $CAPNAME/spec.md:$line — requisito '$name' tem cenário em nível errado (use #### com 4 hashtags)"
    ERRORS=$((ERRORS + 1))
  done < <(printf '%s\n' "$SCAN" | awk -F'\t' '$5=="REQUISITOS" && $4=="1" {print $2"\t"$1}')

  # ── A3: header de requisito duplicado dentro de ## Requisitos ──
  while IFS= read -r dup; do
    [ -n "$dup" ] || continue
    echo -e "  ${RED}✗ A3${NC} $CAPNAME/spec.md — header de requisito DUPLICADO em ## Requisitos: '$dup' (quebra a chave única do merge)"
    ERRORS=$((ERRORS + 1))
  done < <(printf '%s\n' "$SCAN" | awk -F'\t' '$5=="REQUISITOS"{print $1}' | sort | uniq -d)

  # ── A4: token de seção de delta vazado (qualquer caixa, fora de fence) ──
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo -e "  ${RED}✗ A4${NC} $CAPNAME/spec.md:$hit — token de seção de DELTA vazado na fonte (rode o merge, não edite a fonte)"
    ERRORS=$((ERRORS + 1))
  done < <(gram_grep_delta_tokens "$SPEC")

  # ── A6 (ADVISORY): '### Requisito:' fora de ## Requisitos (misplaced) ──
  while IFS=$'\t' read -r line name sec; do
    [ -n "${name:-}" ] || continue
    ADVISORY_BUF="${ADVISORY_BUF}  ${YELLOW}⚠ A6${NC} $CAPNAME/spec.md:$line — requisito '$name' FORA de ## Requisitos (seção '$sec'; contrato vive em ## Requisitos)"$'\n'
  done < <(printf '%s\n' "$SCAN" | awk -F'\t' '$5!="REQUISITOS" {print $2"\t"$1"\t"$5}')

  # ── A5 (ADVISORY): cross-ref spec→código — path citado que não existe ──
  if command -v python3 >/dev/null 2>&1; then
    while IFS= read -r missing; do
      [ -n "$missing" ] || continue
      ADVISORY_BUF="${ADVISORY_BUF}  ${YELLOW}⚠ A5${NC} $CAPNAME/spec.md — path citado não existe no produto: \`$missing\`"$'\n'
    done < <(
      python3 - "$SPEC" "$ROOT" <<'PYEOF' 2>/dev/null || true
import re, sys, os
spec, root = sys.argv[1], sys.argv[2]
try:
    text = open(spec, errors="replace").read()
except OSError:
    sys.exit(0)
seen = set()
codepath = re.compile(r'^(src|source|lib|app|packages|scripts|tests)/[\w./-]+\.(ts|tsx|js|jsx|py|sh|go|rs)$')
for tok in re.findall(r'`([^`\s]+)`', text):
    if '://' in tok or tok in seen:
        continue
    if codepath.match(tok):
        seen.add(tok)
        if not os.path.exists(os.path.join(root, tok)):
            print(tok)
PYEOF
    )
  fi
done

if [ -n "$ADVISORY_BUF" ]; then
  echo ""
  echo -e "${YELLOW}${BOLD}## Advisory (não-gated; não afeta o exit code)${NC}"
  printf '%b' "$ADVISORY_BUF"
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}spec-analyze: OK${NC} — 0 defeitos determinísticos (HARD) nas ${#SPEC_FILES[@]} spec(s)"
else
  echo -e "  ${RED}${BOLD}spec-analyze: $ERRORS defeito(s) HARD${NC} — corrija a fonte (ou via /spec --converge → delta → merge)"
fi

if [ "$ADVISORY_ONLY" -eq 1 ]; then
  echo -e "  ${CYAN}ℹ${NC} --advisory-only: exit 0 (HARD rebaixado a aviso)"
  exit 0
fi
[ "$ERRORS" -gt 0 ] && exit 1
exit 0
