#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-converge.sh <produto-root> [<capability>]
#
# Reconcilia a SPEC VIVA com a implementação SEM JAMAIS mutar a source-of-truth.
# Produz um DELTA-CANDIDATO + RELATÓRIO numa QUARENTENA, que reentram no fluxo
# normal /spec (humano revisa → propose/validate/merge). É a ponte append-only
# spec↔código: nunca aplica nada, nunca deleta, nunca roda git.
#
# APPEND-ONLY — quatro camadas determinísticas e sobrepostas:
#   (1) único destino de escrita = specs/_changes/_converge-<TIMESTAMP>/ (dir NOVO;
#       aborta se já existir, em vez de reabrir).
#   (2) GUARD RUNTIME antes de escrever: destino fora da quarentena → mata o processo.
#   (3) a spec viva é aberta SÓ para leitura (nunca >, >>, sed -i, cp/mv mirando a fonte).
#   (4) AUTO-TESTE de imutabilidade: sha256 de TODA specs/<cap>/spec.md antes/depois;
#       qualquer divergência (ou criação/deleção de spec) → rollback + exit 2.
#
# O delta-candidato só emite MODIFICADO com TODO-skeleton para requisitos SEM
# cenário (A1) — NUNCA infere REMOVIDO/RENOMEADO (decisões irreversíveis = humano).
#
# Exit: 0 = quarentena gerada · 2 = erro de invocação OU violação de imutabilidade
# Uso:  bash spec-converge.sh <produto-root> [<capability>]
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/spec-grammar.sh"
# gates.sh (opcional — fallback no-op se ausente)
if [ -f "$SCRIPT_DIR/../../../lib/gates.sh" ]; then
  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/../../../lib/gates.sh"
fi
type gate_output >/dev/null 2>&1 || gate_output() { test -s "${1:-}" 2>/dev/null; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ROOT="${1:-}"
[ -n "$ROOT" ] || { echo "ERRO: uso: spec-converge.sh <produto-root> [<capability>]" >&2; exit 2; }
CAP="${2:-}"
SPECS_DIR="$ROOT/specs"
[ -d "$SPECS_DIR" ] || { echo "ERRO: diretório de specs não encontrado: $SPECS_DIR" >&2; exit 2; }

# ── snapshot de imutabilidade (lista + sha256 de TODA spec viva) ───────────────
# Emite 'path<TAB>sha256' por spec.md de capability (exclui _changes/_archive).
snapshot_specs() {
  local d base
  for d in "$SPECS_DIR"/*/; do
    base="$(basename "$d")"
    case "$base" in _*) continue ;; esac
    [ -f "$d/spec.md" ] || continue
    printf '%s\t%s\n' "$base" "$(/usr/bin/python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$d/spec.md" 2>/dev/null || echo '?')"
  done | sort
}
BEFORE="$(snapshot_specs)"

# ── alvos ──────────────────────────────────────────────────────────────────────
TARGETS=()
if [ -n "$CAP" ]; then
  [ -f "$SPECS_DIR/$CAP/spec.md" ] || { echo "ERRO: capability '$CAP' sem spec.md" >&2; exit 2; }
  TARGETS+=("$CAP")
else
  for d in "$SPECS_DIR"/*/; do
    base="$(basename "$d")"; case "$base" in _*) continue ;; esac
    [ -f "$d/spec.md" ] && TARGETS+=("$base")
  done
fi

# ── (1) destino fixo na quarentena; aborta se já existe ────────────────────────
STAMP="$(date +%Y-%m-%d-%H%M%S)"
OUT="$SPECS_DIR/_changes/_converge-$STAMP"
# (2) GUARD RUNTIME — destino DEVE estar dentro da quarentena
case "$OUT" in
  */specs/_changes/_converge-*) : ;;
  *) echo "FATAL: converge tentou escrever fora da quarentena: $OUT" >&2; exit 2 ;;
esac
[ -e "$OUT" ] && { echo "ERRO: destino de quarentena já existe: $OUT (rode de novo)" >&2; exit 1; }
mkdir -p "$OUT/delta"

# ── RELATÓRIO.md (banner não-autoritativo + saída do analyze advisory) ─────────
REL="$OUT/RELATORIO.md"
{
  echo "# CONVERGE — ARTEFATO ADITIVO / NÃO-AUTORITATIVO"
  echo ""
  echo "> ⚠️ **ESTA PROPOSTA NÃO FOI APLICADA.** É um rascunho gerado por \`spec-converge.sh\`"
  echo "> a partir da análise da spec viva. Revise, edite e só então promova pelo fluxo"
  echo "> normal /spec (propose → validate → merge). A source-of-truth NÃO foi tocada."
  echo ""
  echo "- Produto: \`$ROOT\`"
  echo "- Capabilities analisadas: ${TARGETS[*]:-nenhuma}"
  echo "- Gerado em: $STAMP"
  echo ""
  echo "## Achados de \`spec-analyze --advisory-only\`"
  echo ""
  echo '```'
  bash "$SCRIPT_DIR/spec-analyze.sh" "$ROOT" ${CAP:+"$CAP"} --advisory-only 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
  echo '```'
  echo ""
  echo "## Delta-candidato"
  echo ""
  echo "Para cada requisito SEM cenário (A1), \`delta/<capability>.md\` traz um bloco"
  echo "\`## MODIFICADO\` com o requisito atual + um \`#### Cenário: <PREENCHER>\` a completar."
  echo "**Nunca** inferimos REMOVIDO/RENOMEADO automaticamente — isso é decisão humana."
} > "$REL"

# ── delta-candidato: MODIFICADO + TODO para requisitos sem cenário (A1) ────────
CANDIDATES=0
for cap in "${TARGETS[@]}"; do
  SPEC="$SPECS_DIR/$cap/spec.md"
  DELTA="$OUT/delta/$cap.md"
  CAP_HAS=0
  while IFS=$'\t' read -r name line hs sec; do
    [ -z "${name:-}" ] && continue
    [ "$sec" = "PROSE" ] && continue
    [ "$hs" = "0" ] || continue
    if [ "$CAP_HAS" -eq 0 ]; then
      { echo "## MODIFICADO Requisitos"; echo ""; } > "$DELTA"
      CAP_HAS=1
    fi
    # extrai o bloco atual do requisito (header + corpo até a próxima fronteira)
    {
      awk -v hdr="### Requisito: $name" '
        $0 == hdr { cap=1; print; next }
        cap && (/^## / || /^### Requisito:/) { cap=0 }
        cap { print }
      ' "$SPEC"
      echo ""
      echo "#### Cenário: <PREENCHER — TODO converge: descreva o comportamento testável>"
      echo "- **QUANDO** <condição observável>"
      echo "- **ENTÃO** <resultado observável>"
      echo ""
    } >> "$DELTA"
    CANDIDATES=$((CANDIDATES + 1))
  done < <(gram_scan_reqs "$SPEC")
done

# ── proposta.md stub (a partir do template, se existir) ────────────────────────
PROP="$OUT/proposta.md"
TEMPLATE="$SCRIPT_DIR/../templates/proposal.md"
if [ -f "$TEMPLATE" ]; then
  cp "$TEMPLATE" "$PROP"
else
  printf '# Proposta (rascunho converge)\n\n## Por quê\n<PREENCHER>\n\n## O que muda\n<PREENCHER>\n' > "$PROP"
fi

# ── (4) AUTO-TESTE de imutabilidade: a fonte mudou? → rollback ─────────────────
AFTER="$(snapshot_specs)"
if [ "$BEFORE" != "$AFTER" ]; then
  echo "FATAL: converge alterou a source-of-truth (violação append-only) — fazendo rollback" >&2
  echo "--- antes ---" >&2; printf '%s\n' "$BEFORE" >&2
  echo "--- depois ---" >&2; printf '%s\n' "$AFTER" >&2
  rm -rf "$OUT"
  exit 2
fi

gate_output "$REL" "RELATORIO.md" || { echo "FATAL: RELATORIO.md vazio/ausente" >&2; rm -rf "$OUT"; exit 2; }

echo -e "\n${CYAN}${BOLD}━━━ spec-converge: quarentena gerada (append-only) ━━━${NC}"
echo -e "  ${GREEN}✓${NC} source-of-truth INTACTA (sha256 idêntico antes/depois)"
echo -e "  ${GREEN}✓${NC} relatório: ${OUT#$ROOT/}/RELATORIO.md"
echo -e "  ${GREEN}✓${NC} delta-candidato(s): $CANDIDATES requisito(s) sem cenário → MODIFICADO/TODO"
echo -e "  ${CYAN}ℹ${NC} revise e promova pelo fluxo /spec (propose → validate → merge). Nada foi aplicado."
exit 0
