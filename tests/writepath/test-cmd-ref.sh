#!/bin/bash
# test-cmd-ref.sh — prova standalone por EXIT-CODE do transporte de ref OPACO `refs/ideiaos/cmd` (v14.4 · B5).
#
# Prova, FAIL-CLOSED (antifragile-gates), a propriedade load-bearing do ADR Q5:
#   o ref de comando vive SÓ via plumbing (update-ref), ISOLADO do working tree → o `git add -A` cego
#   do git-autosync NÃO o captura. E o round-trip put→get é byte-a-byte do blob OPACO.
#
# ANTI-TEATRO (mesmo regime do harness agregado):
#   (a) MANIFESTO fixo EXPECTED_CASES; reprova se cases_run != EXPECTED_CASES;
#   (b) cada caso-veneno casa EXIT-CODE específico + REASON= — um !=0 genérico (127/file-not-found) REPROVA;
#   (c) CANÁRIO: prova que o comparador detecta um mecanismo QUEBRADO (lib sabotada que grava no working
#       tree → o check "status --porcelain vazio" VIRA VERMELHO), não só ausente;
#   (d) MUTAÇÃO: sabota a lib REAL (troca update-ref por escrita no working tree), prova vermelho, restaura, verde.
#
# SEGURANÇA DE TESTE (CRÍTICO): TODA operação git roda num repo DESCARTÁVEL (`git init` em mktemp -d) via
#   IDEIAOS_CMD_REPO; `rm -rf` no fim. NUNCA cria refs/ideiaos/cmd no repo VIVO do IdeiaOS.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$ROOT/source/agentd/cmd-ref.sh"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/cmdref.XXXXXX")"
# guarda o cleanup ao PROCESSO PRINCIPAL (bash propaga trap EXIT a subshells; sem o guard um subshell apagaria $WORK no meio)
trap '[ "${BASHPID:-$$}" = "$$" ] && rm -rf "$WORK"' EXIT

# ───── repo git DESCARTÁVEL (nunca o repo vivo) ─────
REPO="$WORK/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q 2>/dev/null
git -C "$REPO" config user.email t@t >/dev/null 2>&1
git -C "$REPO" config user.name t >/dev/null 2>&1
# um commit-base para o repo ter HEAD/working tree real (torna o teste de isolamento significativo)
printf 'baseline\n' > "$REPO/README.md"
git -C "$REPO" add README.md >/dev/null 2>&1
git -C "$REPO" commit -qm base >/dev/null 2>&1
export IDEIAOS_CMD_REPO="$REPO"

# blob OPACO (simula ciphertext já-selado pela borda — o conteúdo é irrelevante p/ o transporte)
BLOB="$WORK/blob.opaque"
printf '\x00OPAQUE-SEALED-CIPHERTEXT-%s\x00\xff\n' "$(date +%s)" > "$BLOB"

PASS=0; FAIL=0; CASES_RUN=0
EXPECTED_CASES=12     # MANIFESTO: tem que bater com os assert_case abaixo (anti-teatro (a))
FAILED_NAMES=""

c_green(){ printf '\033[0;32m%s\033[0m\n' "$1"; }
c_red(){ printf '\033[0;31m%s\033[0m\n' "$1"; }

# comparador: rc==expect_exit E (sem REASON OU stderr contém REASON). 0=match,1=miss.
_cmp() { local rc="$1" errf="$2" eexit="$3" ereason="$4"
  [ "$rc" = "$eexit" ] || return 1
  [ -z "$ereason" ] && return 0
  grep -q "$ereason" "$errf" 2>/dev/null
}

# assert_case NAME EXPECT_EXIT EXPECT_REASON -- CMD...
assert_case() {
  local name="$1" eexit="$2" ereason="$3"; shift 3; [ "$1" = "--" ] && shift
  CASES_RUN=$((CASES_RUN+1))
  local errf="$WORK/err.$CASES_RUN" rc
  "$@" >/dev/null 2>"$errf"; rc=$?
  if _cmp "$rc" "$errf" "$eexit" "$ereason"; then
    PASS=$((PASS+1)); printf '  + %-44s exit=%s %s\n' "$name" "$rc" "${ereason:+REASON~$ereason}"
  else
    FAIL=$((FAIL+1)); FAILED_NAMES="$FAILED_NAMES $name"
    printf '  x %-44s got exit=%s (want %s%s); stderr=%s\n' "$name" "$rc" "$eexit" "${ereason:+ REASON~$ereason}" "$(head -1 "$errf" 2>/dev/null)"
  fi
}

echo "=== cmd-ref (refs/ideiaos/cmd) transporte OPACO + isolamento do working tree ==="

# ───────────────── casos NEGATIVOS antes do put (ref ausente) ─────────────────
# get sem ref → fail-closed exit 3
assert_case "get-without-ref->3"  3 "no-cmd-ref" -- bash "$LIB" get
# list sem ref → fail-closed exit 3
assert_case "list-without-ref->3" 3 "no-cmd-ref" -- bash "$LIB" list

# ───────────────── invocação inválida ─────────────────
assert_case "bad-subcommand->2"   2 "" -- bash "$LIB" frobnicate
# put sem arg → uso (2)
assert_case "put-no-arg->2"       2 "" -- bash "$LIB" put
# put com blob ausente/vazio → 5
: > "$WORK/empty.blob"
assert_case "put-empty-blob->5"   5 "blob-missing" -- bash "$LIB" put "$WORK/empty.blob"
assert_case "put-missing-blob->5" 5 "blob-missing" -- bash "$LIB" put "$WORK/nope.blob"

# repo-alvo inválido → 4 (aponta IDEIAOS_CMD_REPO p/ um dir SEM git)
not_a_repo() { local d="$WORK/notrepo"; mkdir -p "$d"; IDEIAOS_CMD_REPO="$d" bash "$LIB" list; }
assert_case "not-a-git-repo->4"   4 "not-a-git-repo" -- not_a_repo

# ───────────────── PUT válido + provas de ISOLAMENTO (o coração do B5) ─────────────────
# put → exit 0 e imprime um sha de 40 hex
put_ok() { local sha; sha=$(bash "$LIB" put "$BLOB" 2>/dev/null) || return 1; printf '%s' "$sha" | grep -qE '^[0-9a-f]{40}$'; }
assert_case "put-opaque-blob->0+sha" 0 "" -- put_ok

# ISOLAMENTO #1: após put, o working tree fica INTOCADO (status --porcelain ZERO linhas) E nem `add -A`
#   captura nada de comando (o ref por update-ref não entra no index). Esta é a prova load-bearing do ADR Q5.
isolation_status_clean() {
  bash "$LIB" put "$BLOB" >/dev/null 2>&1 || return 1
  # working tree intocado pelo transporte do ref
  [ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ] || { echo "REASON=working-tree-dirty" >&2; return 1; }
  # add -A do autosync NÃO captura nenhum arquivo de comando para o index
  git -C "$REPO" add -A >/dev/null 2>&1
  [ -z "$(git -C "$REPO" diff --cached --name-only 2>/dev/null)" ] || { echo "REASON=add-A-captured-cmd" >&2; return 1; }
  # e o ref RESOLVE (objeto existe) embora NÃO esteja rastreado no índice (ls-files não o vê)
  git -C "$REPO" rev-parse --verify --quiet refs/ideiaos/cmd >/dev/null 2>&1 || { echo "REASON=ref-unresolved" >&2; return 1; }
  git -C "$REPO" ls-files | grep -q 'cmd' && { echo "REASON=cmd-tracked-in-index" >&2; return 1; }
  return 0
}
assert_case "put-isolated-from-worktree+index" 0 "" -- isolation_status_clean

# ROUND-TRIP: get devolve byte-a-byte o blob posto
roundtrip() {
  bash "$LIB" put "$BLOB" >/dev/null 2>&1 || return 1
  bash "$LIB" get > "$WORK/got.blob" 2>/dev/null || return 1
  cmp -s "$BLOB" "$WORK/got.blob" || { echo "REASON=roundtrip-mismatch" >&2; return 1; }
  return 0
}
assert_case "get-roundtrip-byte-for-byte" 0 "" -- roundtrip

# list após put → sha que casa o do put
list_matches() {
  local p l; p=$(bash "$LIB" put "$BLOB" 2>/dev/null) || return 1
  l=$(bash "$LIB" list 2>/dev/null) || return 1
  [ "$p" = "$l" ] || { echo "REASON=list-sha-mismatch put=$p list=$l" >&2; return 1; }
  return 0
}
assert_case "list-sha-matches-put" 0 "" -- list_matches

# ───────────────────────── (c) CANÁRIO ─────────────────────────
# Prova que o check de ISOLAMENTO detecta um mecanismo QUEBRADO (não só ausente): uma cópia SABOTADA da lib
# que grava o blob como ARQUIVO no working tree (em vez de update-ref) DEVE sujar o status → o check de
# isolamento TEM que dar VERMELHO. Se passasse mesmo com a lib gravando no working tree, o gate seria teatro.
canary() {
  local sabo="$WORK/cmd-ref-sabo.sh"
  # lib sabotada: o `put` escreve no working tree (cmd-payload) em vez de plumbing puro
  cat > "$sabo" <<'SABO'
#!/bin/bash
set -uo pipefail
REPO="${IDEIAOS_CMD_REPO:?}"
case "${1:-}" in
  put) cp "$2" "$REPO/cmd-payload"; echo "sabotaged" ;;
  *) echo "n/a" ;;
esac
SABO
  # roda o MESMO check de isolamento, mas contra a lib sabotada
  IDEIAOS_CMD_REPO="$REPO" bash "$sabo" put "$BLOB" >/dev/null 2>&1
  # o check de status-limpo TEM que detectar sujeira (working tree agora tem cmd-payload)
  if [ -z "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
    echo "REASON=canary-false-pass (working tree limpo mesmo com lib gravando arquivo)" >&2
    git -C "$REPO" checkout -- . 2>/dev/null; rm -f "$REPO/cmd-payload"
    return 1
  fi
  # confirma que o que sujou é justamente o arquivo de comando que NÃO deveria existir
  git -C "$REPO" status --porcelain 2>/dev/null | grep -q 'cmd-payload' || { echo "REASON=canary-wrong-dirt" >&2; return 1; }
  # limpa a sujeira do canário para não contaminar casos seguintes
  rm -f "$REPO/cmd-payload"; git -C "$REPO" checkout -- . 2>/dev/null
  return 0
}
assert_case "CANARY detects-broken-isolation" 0 "" -- canary

# ───────────────── veredito + (d) MUTAÇÃO sobre a lib REAL ─────────────────
echo "---------------------------------------------"
echo "casos: run=$CASES_RUN  pass=$PASS  fail=$FAIL  (manifesto EXPECTED_CASES=$EXPECTED_CASES)"

rc=0
[ "$CASES_RUN" -ne "$EXPECTED_CASES" ] && { c_red "x MANIFESTO violado: run=$CASES_RUN != EXPECTED=$EXPECTED_CASES"; rc=1; }
[ "$FAIL" -ne 0 ] && { c_red "x falhas:$FAILED_NAMES"; rc=1; }

# (d) MUTAÇÃO sobre a lib REAL: sabota cmd-ref.sh p/ gravar no working tree em vez de update-ref → o
#     check de isolamento DEVE virar vermelho; restaura → verde. Prova que o teste pega regressão real
#     (não só ausência). Faz numa CÓPIA da lib viva, restaurada ao fim — nunca deixa a lib sabotada.
mutation_check() {
  local muta="$WORK/cmd-ref-MUTA.sh"
  cp "$LIB" "$muta"
  # troca o plumbing por escrita no working tree (a sabotagem que o isolamento DEVE pegar)
  # injeta, no ramo `put`, um cp para o working tree ANTES do hash-object; mantém o resto.
  if ! sed 's#sha=\$(git -C "\$REPO" hash-object#cp "$blob" "$REPO/cmd-payload-MUTA"; sha=$(git -C "$REPO" hash-object#' "$LIB" > "$muta"; then
    echo "  ! mutação: sed falhou"; return 1
  fi
  # roda o check de isolamento contra a lib MUTADA (deve FALHAR: working tree fica sujo)
  IDEIAOS_CMD_REPO="$REPO" bash "$muta" put "$BLOB" >/dev/null 2>&1
  local dirty; dirty=$(git -C "$REPO" status --porcelain 2>/dev/null)
  # restaura o estado do repo de teste (remove a sujeira da mutação)
  rm -f "$REPO/cmd-payload-MUTA"; git -C "$REPO" checkout -- . 2>/dev/null
  if [ -z "$dirty" ]; then
    c_red "x MUTAÇÃO não-detectada: lib gravando no working tree passou pelo check de isolamento (teatro)"
    return 1
  fi
  # e a lib REAL (intocada) DEVE produzir working tree limpo (verde após 'restore')
  bash "$LIB" put "$BLOB" >/dev/null 2>&1
  if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
    c_red "x lib REAL suja o working tree — isolamento quebrado"
    return 1
  fi
  return 0
}
if mutation_check; then
  c_green "  + MUTAÇÃO provada: lib sabotada (grava no working tree) -> VERMELHO; lib real -> VERDE"
else
  rc=1
fi

if [ "$rc" -eq 0 ]; then
  c_green "OK cmd-ref $PASS/$EXPECTED_CASES"
else
  c_red "FALHOU cmd-ref"
fi
exit "$rc"
