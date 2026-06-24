#!/bin/bash
# cmd-ref.sh — transporte do ref de comando OPACO `refs/ideiaos/cmd`, ISOLADO do working tree (v14.4 · B5).
#
# SOURCE: nativo IdeiaOS. Decisão: docs/decisions/v14.4-command-ref-origin-exposure.md (ADR Q5) —
#   "Ref ÚNICO e OPACO" + "Isolamento do autosync (working tree)" (R-WP6 / R-WP8 / R-WP9 / R-WP12).
#
# ESCOPO desta lib (estrito): ela é SÓ o transporte-de-ref. Ela NÃO cifra, NÃO sela, NÃO assina —
#   apenas TRANSPORTA um blob OPACO já-pronto (o selo `assina(P)→sela(P‖sig)` é gated no owner, B0-bis).
#   O blob que entra aqui já deve estar cifrado/selado pela borda; aqui só vira objeto git + ref.
#
# ISOLAMENTO (a propriedade load-bearing do ADR Q5 — "Isolamento do autosync"):
#   o ref vive SÓ via plumbing (`hash-object -w` + `update-ref`), NUNCA no working tree nem no index.
#   Logo o `git add -A` cego do git-autosync NÃO o captura (add -A opera sobre o working tree do branch
#   corrente; um objeto solto referenciado por update-ref puro não toca o index). Verificável por exit-code:
#   após `put`, `git status --porcelain` produz ZERO linhas e `git diff --cached` não lista arquivo de comando.
#
# credential-isolation: NENHUM segredo/valor transita por esta lib — o blob é OPACO (ciphertext já-pronto)
#   e nunca é decifrado/ecoado aqui. NENHUMA chamada a provedor externo (curl/api/supabase) — só git local.
#
# Repo-alvo por env (para teste em repo descartável): IDEIAOS_CMD_REPO (default = root do IdeiaOS).
#   TODA operação git usa `git -C "$REPO"` — esta lib nunca opera no repo implícito do cwd.
#
# Uso:
#   cmd-ref.sh put <blob-file>   # cria objeto opaco + aponta refs/ideiaos/cmd (plumbing puro)
#   cmd-ref.sh get               # emite o blob opaco (round-trip byte-a-byte)
#   cmd-ref.sh list              # mostra o sha do ref (ou no-cmd-ref se ausente)
#
# Exit-codes (cada falha = REASON único, mutação-testável — um !=0 genérico NÃO conta como prova):
#   0  sucesso
#   2  erro de invocação (subcomando/argumento inválido)
#   3  ref de comando ausente (get/list sem put prévio) — REASON=no-cmd-ref
#   4  repo-alvo inválido (não é repositório git)        — REASON=not-a-git-repo
#   5  blob-file ausente/vazio (put)                     — REASON=blob-missing
#   6  falha ao gravar o objeto opaco / apontar o ref    — REASON=ref-write-failed
set -uo pipefail

# o ref de comando é ÚNICO e OPACO (ADR Q5): um só path, sem <recipient> nem escopo no nome
CMD_REF="refs/ideiaos/cmd"

# raiz do IdeiaOS = dois níveis acima de source/agentd/ (default quando IDEIAOS_CMD_REPO não vem do env)
HERE="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_REPO="$(cd "$HERE/../.." && pwd)"
REPO="${IDEIAOS_CMD_REPO:-$DEFAULT_REPO}"

# _ensure_repo — falha-cedo se o alvo não for um repositório git (fail-closed; nunca opera fora de um repo)
_ensure_repo() {
  git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || { echo "REASON=not-a-git-repo repo=$REPO" >&2; exit 4; }
}

cmd="${1:-}"; shift 2>/dev/null || true
case "$cmd" in
  put) # put <blob-file> — TRANSPORTA o blob OPACO já-pronto: objeto git + update-ref. NÃO toca working tree/index.
    _ensure_repo
    blob="${1:-}"
    [ -n "$blob" ] || { echo "uso: cmd-ref.sh put <blob-file>" >&2; exit 2; }
    [ -s "$blob" ] || { echo "REASON=blob-missing path=$blob" >&2; exit 5; }
    # hash-object -w grava o objeto no store SEM staging; nunca cria arquivo no working tree.
    sha=$(git -C "$REPO" hash-object -w --stdin < "$blob" 2>/dev/null) || sha=""
    [ -n "$sha" ] || { echo "REASON=ref-write-failed (hash-object)" >&2; exit 6; }
    # update-ref aponta o ref direto ao objeto — plumbing puro, fora do index/working tree.
    if ! git -C "$REPO" update-ref "$CMD_REF" "$sha" 2>/dev/null; then
      echo "REASON=ref-write-failed (update-ref)" >&2; exit 6
    fi
    printf '%s\n' "$sha"
    ;;
  get) # get — emite o blob OPACO (round-trip). Ausente → fail-closed (no-cmd-ref).
    _ensure_repo
    git -C "$REPO" rev-parse --verify --quiet "$CMD_REF" >/dev/null 2>&1 || { echo "REASON=no-cmd-ref" >&2; exit 3; }
    # cat-file -p sobre o ref emite os BYTES do blob — sem decifrar, sem ecoar valor (continua opaco).
    git -C "$REPO" cat-file -p "$CMD_REF" 2>/dev/null || { echo "REASON=ref-write-failed (cat-file)" >&2; exit 6; }
    ;;
  list) # list — sha do ref (prova que resolve). Ausente → fail-closed (no-cmd-ref).
    _ensure_repo
    sha=$(git -C "$REPO" rev-parse --verify --quiet "$CMD_REF" 2>/dev/null) || sha=""
    [ -n "$sha" ] || { echo "REASON=no-cmd-ref" >&2; exit 3; }
    printf '%s\n' "$sha"
    ;;
  *)
    echo "uso: cmd-ref.sh {put <blob-file>|get|list}" >&2
    exit 2
    ;;
esac
