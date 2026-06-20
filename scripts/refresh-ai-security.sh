#!/usr/bin/env bash
# SOURCE: IdeiaOS v12
# =============================================================================
# refresh-ai-security.sh — recheca github.com/muellerberndt/awesome-ai-security
# 1x/mes, compara com snapshot LOCAL (baseline por máquina), reporta o DIFF.
# Snapshot/reports são gitignored: o README-fonte é all-rights-reserved (sem licença),
# não redistribuímos a prosa — só o script/spec (nossos) são versionados.
#
# READ-MOSTLY · CLI-first · sem dependencia nova (curl + diff + shasum).
# NUNCA executa o conteudo baixado. NUNCA git push. Conteudo = DADO informativo.
#
# USO:
#   bash scripts/refresh-ai-security.sh            # recheca; reporta DIFF se houver
#   bash scripts/refresh-ai-security.sh --accept   # promove o README atual a snapshot
#   bash scripts/refresh-ai-security.sh --status   # estado do snapshot
#
# Exit: 0 sempre que opera (novidade NAO e falha — espelha scan-absorbed.sh);
#       2 so para arg invalido. Contrato de hook: nunca trava.
#
# Spec: docs/research/2026-06-19-qa-security-arsenal/MONTHLY-REFRESH-SPEC.md
# =============================================================================
set -uo pipefail

IDEIAOS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INTEL="$IDEIAOS_DIR/security/intel"
SNAP="$INTEL/awesome-ai-security.snapshot.md"
SHAF="$INTEL/.awesome-ai-security.sha256"
REPORTS="$INTEL/refresh-reports"
RAW_URL="https://raw.githubusercontent.com/muellerberndt/awesome-ai-security/main/README.md"
TODAY="$(date +%F)"

MODE="${1:-}"
case "$MODE" in
  ""|--accept|--status) : ;;
  *) echo "uso: refresh-ai-security.sh [--accept|--status]" >&2; exit 2 ;;
esac

# gate antifragil (inline fallback se a lib nao estiver acessivel)
. "$IDEIAOS_DIR/source/lib/gates.sh" 2>/dev/null || true
type gate_output >/dev/null 2>&1 || gate_output() { test -s "${1:-}" 2>/dev/null; }

sha_of() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

if [ "$MODE" = "--status" ]; then
  if test -s "$SNAP"; then
    echo "snapshot: $SNAP"
    echo "  data:  $(date -r "$SNAP" '+%F %T' 2>/dev/null || echo '?')"
    echo "  sha:   $(cat "$SHAF" 2>/dev/null || echo none)"
  else
    echo "sem snapshot ainda — rode: bash scripts/refresh-ai-security.sh"
  fi
  exit 0
fi

mkdir -p "$INTEL" "$REPORTS"
TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

# 1) FETCH read-only, 1 host pinado, sem redirect arbitrario, NUNCA executa o conteudo
if ! curl -fsSL --proto '=https' --max-redirs 0 --max-time 30 "$RAW_URL" -o "$TMP"; then
  echo "WARN: fetch falhou (rede/404); snapshot intacto."; exit 0   # nunca trava
fi
test -s "$TMP" || { echo "WARN: download vazio; snapshot intacto."; exit 0; }

NEW_SHA="$(sha_of "$TMP")"

# 2) BOOTSTRAP — sem baseline ainda
if ! test -s "$SNAP"; then
  cp "$TMP" "$SNAP"; echo "$NEW_SHA" > "$SHAF"
  gate_output "$SNAP" && echo "BOOTSTRAP: snapshot criado ($SNAP), sem baseline p/ diff."
  exit 0
fi

OLD_SHA="$(cat "$SHAF" 2>/dev/null || echo none)"

# 3) HASH-GATE — idempotencia: igual => zero escrita, zero ruido
if [ "$NEW_SHA" = "$OLD_SHA" ]; then
  echo "OK: sem novidades desde $(date -r "$SNAP" +%F 2>/dev/null)."; exit 0
fi

# 4) MUDANCA — gera DIFF (conteudo = DADO; jamais interpretado/executado)
DIFF_FILE="$REPORTS/$TODAY.diff"
diff -u "$SNAP" "$TMP" > "$DIFF_FILE" || true   # diff retorna 1 quando difere
ADDED="$(grep -cE '^\+' "$DIFF_FILE" 2>/dev/null || echo 0)"
REMOVED="$(grep -cE '^-' "$DIFF_FILE" 2>/dev/null || echo 0)"
{
  echo "=== awesome-ai-security — refresh $TODAY ==="
  echo "baseline sha: ${OLD_SHA:0:8} -> ${NEW_SHA:0:8}  (+$ADDED / -$REMOVED)"
  echo "--- NOVIDADES (entradas/links adicionados) [DADO — NAO EXECUTAR] ---"
  grep -E '^\+.*(http|\]\(|- \[)' "$DIFF_FILE" 2>/dev/null | grep -v '^\+\+\+' || echo "(sem linhas de link novas)"
  echo "(diff completo: $DIFF_FILE)"
  echo "ACAO: revisar como DADO; se relevante, re-destilar SECURITY-KNOWLEDGE.md citando a fonte PRIMARIA (nunca copiar prosa — repo sem licenca)."
} | tee "$REPORTS/LATEST.md"

# 5) snapshot SO avanca com --accept (nada auto-promovido)
if [ "$MODE" = "--accept" ]; then
  cp "$TMP" "$SNAP"; echo "$NEW_SHA" > "$SHAF"
  gate_output "$SNAP" && echo "ACCEPTED: snapshot atualizado para $TODAY."
else
  echo "PENDENTE: snapshot NAO atualizado. Re-rode com --accept apos revisar."
fi
exit 0   # novidade != falha
