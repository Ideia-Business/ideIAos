# SOURCE: IdeiaOS v15 (R15-21)
# =============================================================================
# deploy-hooks.sh — deploy DATA-DRIVEN dos hooks Claude Code (metade "deploy-do-arquivo").
#
# Substitui ~11 blocos copy-paste de `if/diff/cp/chmod` no setup.sh por 1 LISTA +
# 1 loop. Estende o padrão data-driven que já existe (setup.sh step 5.21b itera o
# manifests/modules.json). A metade "registro" (settings.json) permanece por-hook
# (heterogênea — T-01-10) e está marcada debt: no setup.sh.
#
# Objetivo (R15-21): a lista abaixo é a FONTE-DE-VERDADE ÚNICA dos hooks com deploy
# idêntico — adicionar/alterar um hook = 1 linha aqui (antes: 1 bloco de ~13 linhas).
# Isso reduz o risco de R15-01/02 (que mexem em hooks em massa).
# =============================================================================

[ -n "${__IDEIAOS_DEPLOY_HOOKS_LOADED:-}" ] && return 0
__IDEIAOS_DEPLOY_HOOKS_LOADED=1

# Hooks com deploy idêntico (cp+chmod). NÃO inclui: memory-export/import e
# instinct-recover (deploy próprio, v5/v6), nem test-*.sh (não são hooks de runtime).
IDEIAOS_HOOKS=(
  extract-learnings-reminder
  ideiaos-detector
  ideiaos-readme-reminder
  deia-trigger
  typecheck-on-edit
  console-log-guard
  strategic-compact
  precompact-state-save
  session-summary
  observe-tool-use
  observe-session-end
)

# deploy_hook_file NAME SRC_DIR DST_DIR → stdout token: CURRENT|UPDATED|INSTALLED|MISSING
# Idempotente (diff): só copia quando difere. chmod +x sempre que copia.
# SEMPRE retorna 0 (o token carrega o status) — seguro sob `set -e` no caller, onde
# `tok=$(deploy_hook_file …)` abortaria se a função retornasse não-zero.
deploy_hook_file() {
  local name="$1" src_dir="$2" dst_dir="$3"
  local src="$src_dir/$name.sh" dst="$dst_dir/$name.sh"
  [ -f "$src" ] || { echo MISSING; return 0; }
  mkdir -p "$dst_dir" 2>/dev/null
  if [ -f "$dst" ] && diff -q "$src" "$dst" >/dev/null 2>&1; then echo CURRENT; return 0; fi
  local existed=0; [ -f "$dst" ] && existed=1
  if cp "$src" "$dst" 2>/dev/null && chmod +x "$dst" 2>/dev/null; then
    [ "$existed" -eq 1 ] && echo UPDATED || echo INSTALLED
  else
    echo MISSING
  fi
  return 0
}

# deploy_all_hooks SRC_DIR DST_DIR → deploya todos; stdout: "NAME TOKEN" por linha.
deploy_all_hooks() {
  local src_dir="$1" dst_dir="$2" name tok
  for name in "${IDEIAOS_HOOKS[@]}"; do
    tok="$(deploy_hook_file "$name" "$src_dir" "$dst_dir")"
    echo "$name $tok"
  done
}
