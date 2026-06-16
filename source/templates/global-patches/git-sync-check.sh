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

# Branch de FEATURE encalhado vs o branch default (main) — RODA ANTES do early-exit
# abaixo de propósito: os checks vs upstream comparam o branch com o PRÓPRIO remote, então
# um branch obsoleto "em dia com origin/<ele>" sairia silencioso (BEHIND=0) mesmo com o main
# muito à frente. Foi o que causou o drift da sessão 63 — a máquina ficou parada num branch de
# onda já mergeada. Aqui olhamos a distância explícita até o default. Só AVISA, nunca mexe.
DEFAULT_REF="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
[ -z "${DEFAULT_REF:-}" ] && { git rev-parse --verify --quiet origin/main >/dev/null 2>&1 && DEFAULT_REF="origin/main"; }
if [ -n "${DEFAULT_REF:-}" ] && [ "$BRANCH" != "${DEFAULT_REF#origin/}" ]; then
  MAIN_BEHIND="$(git rev-list --count "HEAD..$DEFAULT_REF" 2>/dev/null || echo 0)"
  MAIN_AHEAD="$(git rev-list --count "$DEFAULT_REF..HEAD" 2>/dev/null || echo 0)"
  case "$MAIN_BEHIND" in ''|*[!0-9]*) MAIN_BEHIND=0 ;; esac
  case "$MAIN_AHEAD" in ''|*[!0-9]*) MAIN_AHEAD=0 ;; esac
  # Limiar conservador p/ não ser ruidoso: muito atrás do default E pouco trabalho próprio
  # = branch abandonado, não feature ativo (o 'planning' tem muitos commits próprios → não dispara).
  if [ "$MAIN_BEHIND" -ge 30 ] && [ "$MAIN_AHEAD" -le 10 ]; then
    printf '⚠️ [git-sync] você está no branch "%s" — %s commit(s) atrás de %s e só %s à frente. O trabalho provavelmente migrou para o %s e esta máquina ficou parada num branch antigo. Confirme antes de seguir: git checkout %s && git pull.\n' \
      "$BRANCH" "$MAIN_BEHIND" "$DEFAULT_REF" "$MAIN_AHEAD" "${DEFAULT_REF#origin/}" "${DEFAULT_REF#origin/}"
  fi
fi

# ahead / behind vs upstream.
set -- $(git rev-list --left-right --count "HEAD...$UPSTREAM" 2>/dev/null)
AHEAD="${1:-0}"; BEHIND="${2:-0}"
[ "$BEHIND" -eq 0 ] 2>/dev/null && exit 0   # já atualizado (ou só à frente)

REPO="$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo repo)")"
# Só modificações RASTREADAS bloqueiam um fast-forward; arquivos untracked
# (ex.: .claude/settings.local.json) não impedem o pull --ff-only — por isso
# usamos --untracked-files=no aqui (senão repos com config local nunca puxariam).
TRACKED_DIRTY=0; [ -n "$(git status --porcelain --untracked-files=no 2>/dev/null)" ] && TRACKED_DIRTY=1

if [ "$TRACKED_DIRTY" -eq 0 ] && [ "$AHEAD" -eq 0 ]; then
  if git pull --ff-only --quiet 2>/dev/null; then
    # Drift de estado: o repo avançou em outra máquina/sessão e acabei de puxar.
    # Numa RETOMADA de sessão pausada, o contexto/summary/memória da IA reflete um
    # estado ANTIGO — então injeta um aviso FORTE + a verdade (commits + STATE),
    # para a IA descartar o contexto velho em vez de confiar nele.
    printf '⚠️⚠️ DRIFT DE ESTADO — o repositório avançou +%s commit(s) desde o seu contexto (puxei de %s).\n' "$BEHIND" "$UPSTREAM"
    printf 'Se esta é uma retomada de sessão pausada, seu summary/memória PODE ESTAR DESATUALIZADO. NÃO confie no contexto da conversa para o ESTADO do projeto (pendências, "próximo passo", "o que falta"). Use a verdade abaixo e releia STATE.md + docs/CONTINUATION_HANDOFF.md ANTES de afirmar qualquer coisa sobre o estado.\n\n'
    printf '— Últimos commits:\n'
    git log --oneline -8 2>/dev/null | sed 's/^/    /'
    if [ -f STATE.md ]; then
      printf '\n— STATE.md (topo):\n'
      sed -n '1,6p' STATE.md 2>/dev/null | sed 's/^/    /'
    fi
  else
    echo "⚠️ [git-sync] $REPO ($BRANCH): $BEHIND commit(s) atrás de $UPSTREAM; o fast-forward falhou (talvez um arquivo untracked colida com a entrada) — rode 'git pull --ff-only' e verifique."
  fi
else
  REASON="trabalho local"
  [ "$AHEAD" -gt 0 ] && REASON="$AHEAD commit(s) à frente"
  [ "$TRACKED_DIRTY" -eq 1 ] && REASON="$REASON + alterações rastreadas não commitadas"
  echo "⚠️ [git-sync] $REPO ($BRANCH): $BEHIND commit(s) ATRÁS de $UPSTREAM, mas há $REASON. NÃO puxei — resolva antes de confiar nos arquivos de estado."
fi

# Branches de ESTADO secundários (ex.: planning, onde vive .planning/): o fetch já
# atualizou as refs origin/*. Se o branch LOCAL ficou atrás, avisa — senão a IA lê
# um .planning/ velho desse branch (foi o que aconteceu na retomada da sessão 39).
for SB in planning; do
  git rev-parse --verify --quiet "$SB" >/dev/null 2>&1 || continue
  git rev-parse --verify --quiet "origin/$SB" >/dev/null 2>&1 || continue
  SB_BEHIND="$(git rev-list --count "$SB..origin/$SB" 2>/dev/null || echo 0)"
  case "$SB_BEHIND" in ''|*[!0-9]*) SB_BEHIND=0 ;; esac
  if [ "$SB_BEHIND" -gt 0 ]; then
    printf '⚠️ [git-sync] branch local "%s" está %s commit(s) atrás de origin/%s — NÃO leia .planning/ desse branch sem antes: git fetch && git branch -f %s origin/%s (ou git show origin/%s:.planning/STATE.md).\n' "$SB" "$SB_BEHIND" "$SB" "$SB" "$SB" "$SB"
  fi
done
exit 0
