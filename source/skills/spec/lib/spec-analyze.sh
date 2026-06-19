#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-analyze.sh <produto-root> [<capability>] [--advisory-only]
#
# Analisador da SPEC VIVA (source-of-truth specs/<cap>/spec.md, JÁ mergeada).
# Complementa — NÃO duplica — spec-validate.sh:
#   • spec-validate.sh gateia o DELTA  (pré-merge, no _changes/<slug>/delta/)
#   • spec-analyze.sh   gateia a FONTE  (pós-merge, specs/<cap>/spec.md)
# Pega defeitos que entraram antes do gate existir, ou por edição manual da fonte.
#
# Núcleo DETERMINÍSTICO (HARD — falha o exit):
#   A1  requisito sem nenhum #### Cenário (não-testável)         [reusa gram_scan_reqs]
#   A2  cenário em nível de heading errado (### ou #####)         [invisível ao parser]
#   A3  header de requisito duplicado no mesmo spec.md            [quebra a chave única do merge]
#   A4  token de seção de delta vazado na fonte (## ADICIONADO…)  [delta colado à mão, não mergeado]
#
# ADVISORY (NUNCA falha o exit — só aconselha; guard-rail NASA "LLM/heurística = advisory"):
#   A5  cross-ref spec→código: path citado entre backticks que não existe no produto
#   + passes LLM (clareza de cenário, cobertura cenário↔código, caminho-de-erro,
#     vocabulário ubíquo) — feitos pela skill /spec, fora deste gate determinístico.
#
# Exit: 0 = limpo (ou --advisory-only) · 1 = ≥1 defeito HARD · 2 = erro de invocação
# Uso:  bash spec-analyze.sh <produto-root> [<capability>] [--advisory-only]
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/spec-grammar.sh"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── args ──────────────────────────────────────────────────────────────────────
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

# ── coletar specs alvo ─────────────────────────────────────────────────────────
SPEC_FILES=()
if [ -n "$CAP" ]; then
  F="$SPECS_DIR/$CAP/spec.md"
  [ -f "$F" ] || { echo "ERRO: capability '$CAP' sem spec.md em $F" >&2; exit 2; }
  SPEC_FILES+=("$F")
else
  for d in "$SPECS_DIR"/*/; do
    base="$(basename "$d")"
    case "$base" in _*) continue ;; esac   # pular _changes / _archive
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

  # ── A1: requisito sem cenário (pula SECTION=PROSE) ──
  while IFS=$'\t' read -r name line hs sec; do
    [ -z "${name:-}" ] && continue
    [ "$sec" = "PROSE" ] && continue
    if [ "$hs" = "0" ]; then
      echo -e "  ${RED}✗ A1${NC} $CAPNAME/spec.md:$line — requisito '$name' sem nenhum #### Cenário (não-testável)"
      ERRORS=$((ERRORS + 1))
    fi
  done < <(gram_scan_reqs "$SPEC")

  # ── A2: cenário em nível de heading errado (### ou #####) ──
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo -e "  ${RED}✗ A2${NC} $CAPNAME/spec.md:$hit — cenário em nível errado (use #### com 4 hashtags)"
    ERRORS=$((ERRORS + 1))
  done < <(grep -nE '^(###|#####) ([Cc]en|[Ss]cen)' "$SPEC" 2>/dev/null || true)

  # ── A3: header de requisito duplicado no mesmo arquivo ──
  while IFS= read -r dup; do
    [ -n "$dup" ] || continue
    echo -e "  ${RED}✗ A3${NC} $CAPNAME/spec.md — header de requisito DUPLICADO: '$dup' (quebra a chave única do merge)"
    ERRORS=$((ERRORS + 1))
  done < <(grep -h '^### Requisito:' "$SPEC" 2>/dev/null | sed 's/^### Requisito: *//' | sort | uniq -d || true)

  # ── A4: token de seção de delta vazado na fonte ──
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    echo -e "  ${RED}✗ A4${NC} $CAPNAME/spec.md:$hit — token de seção de DELTA vazado na fonte (cole-mão? rode o merge, não edite a fonte)"
    ERRORS=$((ERRORS + 1))
  done < <(grep -nE '^## (ADICIONADO|ADDED|MODIFICADO|MODIFIED|REMOVIDO|REMOVED|RENOMEADO|RENAMED)' "$SPEC" 2>/dev/null || true)

  # ── A5 (ADVISORY): cross-ref spec→código — path citado que não existe ──
  while IFS= read -r missing; do
    [ -n "$missing" ] || continue
    ADVISORY_BUF="${ADVISORY_BUF}  ${YELLOW}⚠ A5${NC} $CAPNAME/spec.md — path citado não existe no produto: \`$missing\`"$'\n'
  done < <(
    /usr/bin/python3 - "$SPEC" "$ROOT" <<'PYEOF' 2>/dev/null || true
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
done

# ── bloco ADVISORY (separado; nunca afeta o exit) ──
if [ -n "$ADVISORY_BUF" ]; then
  echo ""
  echo -e "${YELLOW}${BOLD}## Advisory (não-gated; não afeta o exit code)${NC}"
  printf '%b' "$ADVISORY_BUF"
fi

# ── resumo + exit ──────────────────────────────────────────────────────────────
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
