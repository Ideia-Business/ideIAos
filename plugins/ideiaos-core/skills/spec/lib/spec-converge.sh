#!/usr/bin/env bash
# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v11
# =============================================================================
# spec-converge.sh <produto-root> [<capability>]
#
# Reconcilia a SPEC VIVA com a implementação SEM JAMAIS mutar a source-of-truth.
# Produz DELTA-CANDIDATO + RELATÓRIO numa QUARENTENA que reentra no fluxo normal
# /spec (humano revisa → propose → validate → merge). Nada é aplicado.
#
# APPEND-ONLY — camadas determinísticas (endurecidas após verificação wf_99173505):
#   (1) único destino = specs/_changes/_converge-<TS>-<PID>/ (dir NOVO, mkdir atômico).
#   (2) GUARD: specs/_changes NÃO pode ser symlink, e o destino RESOLVIDO (pwd -P)
#       deve ficar sob specs/_changes RESOLVIDO — bloqueia escape por symlink/..
#   (3) a fonte é aberta SÓ para leitura.
#   (4) hasher OBRIGATÓRIO (python3|shasum|sha256sum): se nenhum resolve, ABORTA
#       fail-loud ANTES de escrever (não degrada a no-op silencioso). sha256 de toda
#       spec viva antes/depois; divergência → rollback + exit 2.
#
# O candidato só emite MODIFICADO+TODO para requisitos de contrato (## Requisitos)
# sem cenário — NUNCA infere REMOVIDO/RENOMEADO.
#
# Exit: 0 = quarentena gerada · 1 = colisão de destino · 2 = erro de invocação OU
#       hasher ausente OU violação de imutabilidade
# Uso:  bash spec-converge.sh <produto-root> [<capability>]
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SCRIPT_DIR/spec-grammar.sh"
if [ -f "$SCRIPT_DIR/../../../lib/gates.sh" ]; then . "$SCRIPT_DIR/../../../lib/gates.sh"; fi
type gate_output >/dev/null 2>&1 || gate_output() { test -s "${1:-}" 2>/dev/null; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── hasher portável OBRIGATÓRIO (fail-loud se nenhum) ──────────────────────────
_HASHER=""
if command -v python3 >/dev/null 2>&1; then _HASHER="python3"
elif command -v shasum >/dev/null 2>&1; then _HASHER="shasum"
elif command -v sha256sum >/dev/null 2>&1; then _HASHER="sha256sum"
fi
_hash() {  # _hash FILE → sha256 hex (vazio se erro)
  case "$_HASHER" in
    python3)   python3 -c "import hashlib,sys; print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())" "$1" 2>/dev/null ;;
    shasum)    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}' ;;
    sha256sum) sha256sum "$1" 2>/dev/null | awk '{print $1}' ;;
  esac
}

ROOT="${1:-}"
[ -n "$ROOT" ] || { echo "ERRO: uso: spec-converge.sh <produto-root> [<capability>]" >&2; exit 2; }
[ -n "$_HASHER" ] || { echo "ERRO: nenhum hasher (python3/shasum/sha256sum) — não posso garantir append-only. Abortado." >&2; exit 2; }
CAP="${2:-}"
SPECS_DIR="$ROOT/specs"
[ -d "$SPECS_DIR" ] || { echo "ERRO: diretório de specs não encontrado: $SPECS_DIR" >&2; exit 2; }

# ── snapshot de imutabilidade (lista + sha256 de TODA spec viva) ───────────────
snapshot_specs() {
  local d base h
  for d in "$SPECS_DIR"/*/; do
    base="$(basename "$d")"; case "$base" in _*) continue ;; esac
    [ -f "$d/spec.md" ] || continue
    h="$(_hash "$d/spec.md")"
    [ -n "$h" ] || return 3   # hasher falhou num arquivo real → sinaliza
    printf '%s\t%s\n' "$base" "$h"
  done | sort
}
BEFORE="$(snapshot_specs)" || { echo "ERRO: falha ao hashear specs (hasher=$_HASHER) — abortado." >&2; exit 2; }

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

# ── GUARD: specs/_changes não pode ser symlink (escape) ────────────────────────
CHANGES_DIR="$SPECS_DIR/_changes"
if [ -L "$CHANGES_DIR" ]; then
  echo "FATAL: $CHANGES_DIR é um symlink — recuso escrever (risco de escape da quarentena)." >&2; exit 2
fi
mkdir -p "$CHANGES_DIR"

# ── (1) destino com entropia de PID; mkdir ATÔMICO (sem -p) ────────────────────
STAMP="$(date +%Y-%m-%d-%H%M%S)-$$"
OUT="$CHANGES_DIR/_converge-$STAMP"
if ! mkdir "$OUT" 2>/dev/null; then
  echo "ERRO: destino de quarentena já existe/colidiu: $OUT" >&2; exit 1
fi

# ── (2) GUARD realpath: destino RESOLVIDO deve ficar sob _changes RESOLVIDO ────
realp() { ( cd "$1" 2>/dev/null && pwd -P ); }
OUT_REAL="$(realp "$OUT")"; CHANGES_REAL="$(realp "$CHANGES_DIR")"
case "$OUT_REAL/" in
  "$CHANGES_REAL"/_converge-*/) : ;;
  *) echo "FATAL: destino resolvido fora da quarentena ($OUT_REAL) — rollback." >&2; rm -rf "$OUT"; exit 2 ;;
esac
mkdir -p "$OUT/delta"

# ── RELATÓRIO.md ───────────────────────────────────────────────────────────────
REL="$OUT/RELATORIO.md"
{
  echo "# CONVERGE — ARTEFATO ADITIVO / NÃO-AUTORITATIVO"
  echo ""
  echo "> ⚠️ **ESTA PROPOSTA NÃO FOI APLICADA.** Rascunho gerado por \`spec-converge.sh\`."
  echo "> Revise, edite e só então promova pelo fluxo normal /spec (propose → validate → merge)."
  echo "> A source-of-truth NÃO foi tocada (sha256 antes/depois conferido)."
  echo ""
  echo "- Produto: \`$ROOT\` · Capabilities: ${TARGETS[*]:-nenhuma} · Gerado: $STAMP"
  echo ""
  echo "## Achados de \`spec-analyze --advisory-only\`"
  echo ""
  echo '```'
  bash "$SCRIPT_DIR/spec-analyze.sh" "$ROOT" ${CAP:+"$CAP"} --advisory-only 2>&1 | sed 's/\x1b\[[0-9;]*m//g' || true
  echo '```'
  echo ""
  echo "## Delta-candidato"
  echo ""
  echo "Para cada requisito de contrato (## Requisitos) SEM cenário, \`delta/<cap>.md\` traz"
  echo "um \`## MODIFICADO\` com o requisito + \`#### Cenário: <PREENCHER>\`. Nunca REMOVIDO/RENOMEADO."
  echo ""
  echo "> Nota: o candidato valida no \`spec-validate.sh\`. Antes de promover, rode também"
  echo "> \`spec-merge.sh --dry-run\` — nomes de requisito com metacaracteres de regex"
  echo "> (\`[ ] . *\`) podem precisar de ajuste no merge (limitação conhecida do grep do merge)."
} > "$REL"

# ── delta-candidato: MODIFICADO + TODO p/ requisitos de contrato sem cenário ───
CANDIDATES=0
for cap in "${TARGETS[@]}"; do
  SPEC="$SPECS_DIR/$cap/spec.md"
  DELTA="$OUT/delta/$cap.md"
  CAP_HAS=0
  while IFS=$'\t' read -r name line hs mis sec; do
    [ -z "${name:-}" ] && continue
    [ "$sec" = "REQUISITOS" ] || continue   # só requisitos de contrato
    [ "$hs" = "0" ] || continue
    if [ "$CAP_HAS" -eq 0 ]; then { echo "## MODIFICADO Requisitos"; echo ""; } > "$DELTA"; CAP_HAS=1; fi
    {
      awk -v hdr="### Requisito: $name" '
        $0 == hdr { cap=1; print; next }
        cap && (/^## / || /^### Requisito:/) { cap=0 }
        cap { print }
      ' "$SPEC"
      echo ""
      echo "#### Cenário: <PREENCHER — TODO converge: comportamento testável>"
      echo "- **QUANDO** <condição observável>"
      echo "- **ENTÃO** <resultado observável>"
      echo ""
    } >> "$DELTA"
    CANDIDATES=$((CANDIDATES + 1))
  done < <(gram_scan_reqs "$SPEC")
done

# ── proposta.md stub ───────────────────────────────────────────────────────────
PROP="$OUT/proposta.md"
TEMPLATE="$SCRIPT_DIR/../templates/proposal.md"
if [ -f "$TEMPLATE" ]; then cp "$TEMPLATE" "$PROP"
else printf '# Proposta (rascunho converge)\n\n## Por quê\n<PREENCHER>\n\n## O que muda\n<PREENCHER>\n' > "$PROP"; fi

# ── (4) AUTO-TESTE de imutabilidade ────────────────────────────────────────────
AFTER="$(snapshot_specs)" || { echo "FATAL: hasher falhou no snapshot pós-run — rollback." >&2; rm -rf "$OUT"; exit 2; }
if [ "$BEFORE" != "$AFTER" ]; then
  echo "FATAL: converge alterou a source-of-truth (violação append-only) — rollback" >&2
  echo "--- antes ---" >&2; printf '%s\n' "$BEFORE" >&2
  echo "--- depois ---" >&2; printf '%s\n' "$AFTER" >&2
  rm -rf "$OUT"; exit 2
fi
gate_output "$REL" "RELATORIO.md" || { echo "FATAL: RELATORIO.md vazio/ausente" >&2; rm -rf "$OUT"; exit 2; }

echo -e "\n${CYAN}${BOLD}━━━ spec-converge: quarentena gerada (append-only) ━━━${NC}"
echo -e "  ${GREEN}✓${NC} source-of-truth INTACTA (sha256 idêntico antes/depois · hasher=$_HASHER)"
echo -e "  ${GREEN}✓${NC} relatório: ${OUT#$ROOT/}/RELATORIO.md"
echo -e "  ${GREEN}✓${NC} delta-candidato(s): $CANDIDATES requisito(s) de contrato sem cenário → MODIFICADO/TODO"
echo -e "  ${CYAN}ℹ${NC} revise e promova pelo fluxo /spec (propose → validate → merge). Nada foi aplicado."
exit 0
