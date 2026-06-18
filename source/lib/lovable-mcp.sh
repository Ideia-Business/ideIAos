#!/usr/bin/env bash
# SOURCE: IdeiaOS v10 | kind: lib | targets: claude,cursor | stack: lovable
# =============================================================================
# lovable-mcp.sh — Helpers read-only da skill /lovable-mcp (Fase A, v10)
#
# Objetivo: dar à skill /lovable-mcp verdicts BINÁRIOS (exit code) sobre o
# estado do git local vs. o que a Lovable Cloud reporta — em vez de confiar no
# Read tool (que pode alucinar). Toda comparação é git-read pura: zero crédito,
# zero escrita, zero chamada de MCP daqui (o agente busca os dados via MCP e
# passa SHAs/ids como argumentos).
#
# Gateado por source/lib/gates.sh (R6-01 / antifragile-gates): os artefatos de
# relatório são validados por gate_output (test -s), nunca pelo Read tool.
#
# Bash 3.2 compat · sem jq · sem python3 · sem dependências externas.
# Sourced once per shell via o guard __IDEIAOS_LOVABLE_MCP_LOADED.
#
# Uso típico (dentro da skill):
#   IDEIAOS_DIR="${IDEIAOS_DIR:-$HOME/.ideiaos}"
#   . "$IDEIAOS_DIR/source/lib/lovable-mcp.sh" 2>/dev/null \
#     || { echo "lovable-mcp helper ausente" >&2; }
#   lovable_classify_deploy "$CLOUD_SHA"     # -> IN_SYNC|CLOUD_BEHIND|CLOUD_AHEAD|SHA_ABSENT|NO_REPO
#   lovable_sha_present "$EDIT_SHA"           # exit 0 = presente no git local
#   lovable_resolve_scope "$PID" "$BY" 1 "$ME"# -> in:todos|in:pessoal|in:override|out:override|out
# =============================================================================
[ -n "${__IDEIAOS_LOVABLE_MCP_LOADED:-}" ] && return 0
__IDEIAOS_LOVABLE_MCP_LOADED=1

# ── gate dependency (inline fallback se a lib não estiver acessível) ──────────
# Segue o padrão de antifragile-gates.md: nunca falhar por ausência da lib.
if ! type gate_output >/dev/null 2>&1; then
  __LMCP_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
  if [ -f "$__LMCP_DIR/gates.sh" ]; then
    # shellcheck source=/dev/null
    . "$__LMCP_DIR/gates.sh"
  fi
fi
type gate_output >/dev/null 2>&1 \
  || gate_output() { test -s "${1:-}" 2>/dev/null; }
type require_file >/dev/null 2>&1 \
  || require_file() { test -s "${1:-}" 2>/dev/null; }

# ── git guards ───────────────────────────────────────────────────────────────

# lovable_in_git_repo — exit 0 se o CWD está dentro de um repositório git.
lovable_in_git_repo() {
  git rev-parse --git-dir >/dev/null 2>&1
}

# lovable_is_shallow — exit 0 se o repositório é um shallow clone.
# Num shallow clone, cat-file/merge-base podem dar respostas erradas (um SHA
# real pode parecer ausente) → SHA_ABSENT vira falso positivo. Ver Limitações.
lovable_is_shallow() {
  local gd
  gd="$(git rev-parse --git-dir 2>/dev/null)" || return 1
  test -f "$gd/shallow"
}

# lovable_ref_sha REF — ecoa o SHA de uma ref (default origin/main); exit !=0 se ausente.
lovable_ref_sha() {
  local ref="${1:-origin/main}"
  git rev-parse --verify --quiet "${ref}^{commit}" 2>/dev/null
}

# lovable_sha_present SHA — exit 0 se o commit existe no objeto-store local.
# Binário, não-alucinável: base do detect-hotfix.
# Exit: 0 = presente · não-zero = ausente OU sha vazio/inválido. O caller só
# distingue 0 vs não-zero (ver lovable_classify_deploy).
lovable_sha_present() {
  local sha="${1:-}"
  [ -n "$sha" ] || return 1
  git cat-file -e "${sha}^{commit}" 2>/dev/null
}

# lovable_is_ancestor A B — exit 0 se A é ancestral de B (B default origin/main).
# Exit: 0 = ancestral · não-zero = não-ancestral OU A vazio.
lovable_is_ancestor() {
  local a="${1:-}" b="${2:-origin/main}"
  [ -n "$a" ] || return 1
  git merge-base --is-ancestor "$a" "$b" 2>/dev/null
}

# ── verify-deploy: classificação de drift ────────────────────────────────────
# lovable_classify_deploy CLOUD_SHA [BASE_REF]
# Ecoa exatamente um veredito e retorna 0 (o veredito é o dado; o exit é sucesso
# da classificação, não o estado). NO_REPO / SHA_ABSENT sinalizam incerteza.
#
#   IN_SYNC      cloud == base            → deploy bate com a main
#   CLOUD_BEHIND cloud é ancestral da base→ deploy-drift (fix na main, não no ar)  [incidente nº1]
#   CLOUD_AHEAD  base é ancestral do cloud→ cloud tem commits à frente da main
#   SHA_ABSENT   cloud não existe no git  → hotfix-in-cloud OU mismatch de namespace [Fase B]
#   NO_REPO      sem repo / base ausente  → não dá pra comparar
#
# NOTA (Fase B): SHA_ABSENT NÃO prova hotfix — pode ser namespace de SHA do
# mirror Lovable interno ≠ GitHub. A skill DEVE reportar como candidato, não
# como certeza, até a medição da Fase B (sandbox remix_project).
lovable_classify_deploy() {
  local cloud="${1:-}" base="${2:-origin/main}"
  lovable_in_git_repo || { echo "NO_REPO"; return 0; }
  local base_sha
  base_sha="$(lovable_ref_sha "$base")" || { echo "NO_REPO"; return 0; }
  [ -n "$cloud" ] || { echo "SHA_ABSENT"; return 0; }
  if ! lovable_sha_present "$cloud"; then
    lovable_is_shallow \
      && echo "lovable-mcp: repo é shallow — SHA_ABSENT pode ser falso positivo; rode 'git fetch --unshallow'." >&2
    echo "SHA_ABSENT"; return 0
  fi
  local cloud_sha
  cloud_sha="$(git rev-parse --verify --quiet "${cloud}^{commit}" 2>/dev/null)"
  if [ "$cloud_sha" = "$base_sha" ]; then echo "IN_SYNC"; return 0; fi
  if lovable_is_ancestor "$cloud_sha" "$base_sha"; then echo "CLOUD_BEHIND"; return 0; fi
  if lovable_is_ancestor "$base_sha" "$cloud_sha"; then echo "CLOUD_AHEAD"; return 0; fi
  echo "CLOUD_AHEAD"   # divergiu sem relação linear → cloud carrega commit fora da main
  return 0
}

# ── scope resolver (R10-02): identity-aware, operacional, 2 tiers ─────────────
# Foco/escopo do IdeiaOS — NÃO privacidade dura (essa é nativa da Lovable:
# visibility/membership). Privacidade real = visibility:draft manual, fora daqui.
#
# lovable_resolve_scope PROJECT_ID CREATED_BY IN_FOLDER(0|1) MY_ID
#   override (lovable-scope.yaml force_out)        → out:override
#   override (lovable-scope.yaml force_in)         → in:override
#   IN_FOLDER==1                                   → in:todos
#   CREATED_BY == MY_ID                            → in:pessoal
#   senão                                          → out
# Ecoa o veredito; exit 0. Lê exceções de $LOVABLE_SCOPE_FILE (default
# ./lovable-scope.yaml na raiz do produto) se presente — senão é 100% derivado.
lovable_resolve_scope() {
  local pid="${1:-}" by="${2:-}" in_folder="${3:-0}" me="${4:-}"
  local scope_file="${LOVABLE_SCOPE_FILE:-lovable-scope.yaml}"
  if [ -n "$pid" ] && [ -f "$scope_file" ]; then
    if lovable_scope_list "$scope_file" force_out | grep -qxF "$pid"; then
      echo "out:override"; return 0
    fi
    if lovable_scope_list "$scope_file" force_in | grep -qxF "$pid"; then
      echo "in:override"; return 0
    fi
  fi
  if [ "$in_folder" = "1" ]; then echo "in:todos"; return 0; fi
  if [ -n "$me" ] && [ -n "$by" ] && [ "$by" = "$me" ]; then echo "in:pessoal"; return 0; fi
  echo "out"; return 0
}

# lovable_scope_list FILE KEY — ecoa os itens de uma lista YAML simples sob KEY:
# Formato suportado (mínimo, bash 3.2 / sem jq):
#   force_in:
#     - proj_aaa
#     - "proj_bbb"     # comentário inline exige espaço antes do '#'
# O bloco começa na linha "KEY:" e termina na 1ª linha que NÃO é item indentado
# (item = >=1 espaço + '-'). Linhas em branco não encerram o bloco. Um '-' na
# coluna 0 encerra o bloco (não é item válido). '#' só é comentário se houver
# espaço antes — então ids com '#' entre aspas são preservados.
lovable_scope_list() {
  local file="${1:-}" key="${2:-}"
  [ -f "$file" ] && [ -n "$key" ] || return 0
  awk -v key="$key" '
    $0 ~ "^"key":[[:space:]]*$" { inb=1; next }
    inb && /^[[:space:]]+-[[:space:]]*/ {
      line=$0
      sub(/^[[:space:]]+-[[:space:]]*/,"",line)
      sub(/[[:space:]]+#.*$/,"",line)
      sub(/[[:space:]]*$/,"",line)
      gsub(/^["'"'"']|["'"'"']$/,"",line)
      if (line != "") print line
      next
    }
    inb && /^[[:space:]]*$/ { next }
    inb { inb=0 }
  ' "$file"
}

# ── relatório gateado ─────────────────────────────────────────────────────────
# lovable_gate_report PATH [LABEL] — valida que o relatório foi escrito e não é
# vazio, via test -s (gate_output). Use ao fim de verify-deploy / detect-hotfix.
lovable_gate_report() {
  gate_output "${1:-}" "${2:-lovable-mcp report}"
}

# End of lovable-mcp.sh — sourced once per shell via __IDEIAOS_LOVABLE_MCP_LOADED guard
