#!/usr/bin/env bash
# git-sync-check.sh — SessionStart guard do IdeiaOS
# -----------------------------------------------------------------------------
# Mantém o working tree alinhado com o origin ANTES de a IA ler
# STATE.md / CONTINUATION_HANDOFF.md (que são arquivos do working tree e podem
# estar velhos se a outra máquina avançou o remoto).
#
# Comportamento: fetch + FAST-FORWARD automático quando o tree está limpo e
# estritamente atrás do upstream (--ff-only). Se houver trabalho local
# (commits à frente ou alterações não commitadas), NÃO mexe — apenas avisa.
# Nunca destrói nada. Offline / sem git / sem upstream → silencioso (exit 0).
#
# Idempotente e seguro pra rodar em qualquer repo. Instalado por
# IdeiaOS/setup.sh (--global-only) e registrado como SessionStart hook.
# -----------------------------------------------------------------------------
set -uo pipefail

# SessionStart entrega JSON no stdin (inclui "cwd"). Extraímos sem depender de jq.
INPUT="$(cat 2>/dev/null || true)"
CWD="$(printf '%s' "$INPUT" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -z "${CWD:-}" ] && CWD="$PWD"
cd "$CWD" 2>/dev/null || exit 0

# Precisa ser um working tree git.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Não interferir durante merge/rebase/cherry-pick em andamento.
GITDIR="$(git rev-parse --git-dir 2>/dev/null)" || exit 0
{ [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ] \
  || [ -f "$GITDIR/MERGE_HEAD" ] || [ -f "$GITDIR/CHERRY_PICK_HEAD" ]; } && exit 0

# Branch + upstream (detached HEAD ou sem tracking → nada a fazer).
BRANCH="$(git symbolic-ref --short -q HEAD)" || exit 0
git rev-parse '@{u}' >/dev/null 2>&1 || exit 0
UPSTREAM="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || exit 0

# Freshness guard: se já houve fetch há < 90s, evita ir à rede de novo
# (abrir várias sessões em sequência não martela o remoto).
FRESH=0
if [ -f "$GITDIR/FETCH_HEAD" ]; then
  NOW="$(date +%s)"
  MT="$(stat -f %m "$GITDIR/FETCH_HEAD" 2>/dev/null || stat -c %Y "$GITDIR/FETCH_HEAD" 2>/dev/null || echo 0)"
  [ $((NOW - MT)) -lt 90 ] && FRESH=1
fi

if [ "$FRESH" -eq 0 ]; then
  if command -v timeout >/dev/null 2>&1; then
    timeout 10 git fetch --quiet 2>/dev/null || true   # offline → segue silencioso
  else
    git fetch --quiet 2>/dev/null || true
  fi
fi

# ahead / behind vs upstream.
set -- $(git rev-list --left-right --count "HEAD...$UPSTREAM" 2>/dev/null)
AHEAD="${1:-0}"; BEHIND="${2:-0}"
[ "$BEHIND" -eq 0 ] 2>/dev/null && exit 0   # já atualizado (ou só à frente)

REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo repo)")"
CLEAN=1; [ -n "$(git status --porcelain 2>/dev/null)" ] && CLEAN=0

if [ "$CLEAN" -eq 1 ] && [ "$AHEAD" -eq 0 ]; then
  if git pull --ff-only --quiet 2>/dev/null; then
    echo "🔄 [git-sync] $REPO ($BRANCH): auto-atualizado +$BEHIND commit(s) de $UPSTREAM. Releia STATE.md/handoff se já tiver lido."
  else
    echo "⚠️ [git-sync] $REPO ($BRANCH): $BEHIND commit(s) atrás de $UPSTREAM; o fast-forward falhou — rode 'git pull --ff-only' e verifique."
  fi
else
  DIRTY="não"; [ "$CLEAN" -eq 0 ] && DIRTY="sim"
  echo "⚠️ [git-sync] $REPO ($BRANCH): $BEHIND commit(s) ATRÁS de $UPSTREAM, mas há trabalho local (ahead=$AHEAD, alterações não commitadas=$DIRTY). NÃO puxei — resolva antes de confiar nos arquivos de estado."
fi
exit 0
