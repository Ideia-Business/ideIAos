#!/usr/bin/env bash
# git-autosync — sincroniza repositórios git em segundo plano.
# Uso: git-autosync --all   (lê ~/.local/state/git-autosync-repos.txt)
#      git-autosync <repo>
# work/feature: auto-commit + pull --rebase + push.  main/master: só puxa, nunca escreve.
#
# SOURCE-OF-TRUTH: este arquivo (source/autosync/git-autosync.sh) é o daemon canônico.
# setup-dev-machine.sh o instala em ~/.local/bin/git-autosync por cópia; propagate-if-changed.sh
# o re-deploya (atômico) quando muda. NÃO edite a cópia em ~/.local/bin — edite aqui.
set -uo pipefail
LIST="${HOME}/.local/state/git-autosync-repos.txt"
LOG="${HOME}/.local/state/git-autosync.log"
mkdir -p "$(dirname "$LOG")"
log()    { echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] ${*:2}" >> "$LOG"; }
notify() { /usr/bin/osascript -e "display notification \"$2\" with title \"$1\"" >/dev/null 2>&1 || true; }
# _push_state_ref — empurra um branch de transporte (planning=memória v5,
# cockpit=telemetria v14) com AUTO-CURA de divergência. Nunca faz checkout nem
# toca a árvore desses branches; NUNCA usa --force (falha-segura). Casos:
#   - local ATRÁS    → FF-local p/ origin via update-ref (auto-cura; sem checkout)
#   - local À FRENTE → push (fast-forward real)
#   - DIVERGÊNCIA real (ambos andaram) → notify UMA vez (flag) + aponta /memory-sync;
#     para o loop de 900s até reconciliação manual. A flag some ao re-alinhar.
# Bootstrap: se o ref local existe mas sem upstream e origin tem, seta o tracking
# (clone novo) — sem isto o push viraria no-op silencioso e o ref forkaria depois.
_push_state_ref() {
  local REF="$1" NAME="$2"
  git rev-parse --verify --quiet "$REF" >/dev/null 2>&1 || return 0
  if ! git rev-parse --verify --quiet "$REF@{u}" >/dev/null 2>&1; then
    git rev-parse --verify --quiet "refs/remotes/origin/$REF" >/dev/null 2>&1 \
      && git branch --quiet --set-upstream-to="origin/$REF" "$REF" >/dev/null 2>&1 \
      || return 0
  fi
  git fetch --quiet origin "$REF" 2>>"$LOG" || return 0
  local L U B FLAG; FLAG="${HOME}/.local/state/${REF}-diverged.flag"
  L="$(git rev-parse "$REF" 2>/dev/null)"
  U="$(git rev-parse FETCH_HEAD 2>/dev/null)"
  [ -n "$L" ] && [ -n "$U" ] || return 0
  if [ "$L" = "$U" ]; then rm -f "$FLAG"; return 0; fi
  B="$(git merge-base "$L" "$U" 2>/dev/null)"
  if [ "$U" = "$B" ]; then
    git push --quiet origin "$REF" 2>>"$LOG" \
      && { log "$NAME" "push $REF OK"; rm -f "$FLAG"; } \
      || log "$NAME" "push $REF FALHOU"
  elif [ "$L" = "$B" ]; then
    git update-ref "refs/heads/$REF" "$U" "$L" 2>>"$LOG" \
      && { log "$NAME" "$REF FF-local->origin (auto-cura)"; rm -f "$FLAG"; } \
      || log "$NAME" "$REF FF-local FALHOU"
  else
    if [ ! -f "$FLAG" ]; then
      log "$NAME" "$REF DIVERGIU (local e origin a frente) — rode /memory-sync p/ reconciliar"
      notify "Git sync — $REF divergiu" "$NAME: rode /memory-sync (nao auto-curavel)."
      : > "$FLAG"
    fi
  fi
}
push_planning_ref() { _push_state_ref planning "$1"; }
push_cockpit_ref()  { _push_state_ref cockpit  "$1"; }
# maybe_propagate_ideiaos — após pull com commits novos no IdeiaOS, propaga
# setup global + projetos-alvo em ~/dev/ (scripts/propagate-if-changed.sh).
maybe_propagate_ideiaos() {
  local NAME="$1" OLD_HEAD="$2"
  case "$NAME" in IdeiaOS|ideIAos) ;; *) return 0 ;; esac
  [ -n "$OLD_HEAD" ] || return 0
  local NEW_HEAD; NEW_HEAD="$(git rev-parse HEAD 2>/dev/null || true)"
  [ -n "$NEW_HEAD" ] && [ "$OLD_HEAD" != "$NEW_HEAD" ] || return 0
  local PROP; PROP="$(pwd)/scripts/propagate-if-changed.sh"
  [ -f "$PROP" ] || { log "$NAME" "propagate-if-changed: script ausente"; return 0; }
  if bash "$PROP" >>"$LOG" 2>&1; then
    log "$NAME" "propagate-if-changed OK (${OLD_HEAD:0:8}→${NEW_HEAD:0:8})"
  else
    log "$NAME" "propagate-if-changed FALHOU"
    notify "IdeiaOS propagate" "Falha ao propagar setup para ~/dev/*"
  fi
}
sync_one() {
  local REPO="$1"; local NAME; NAME="$(basename "$REPO")"
  cd "$REPO" 2>/dev/null || { log "$NAME" "ERRO: repo não encontrado em $REPO"; exit 1; }
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { log "$NAME" "ERRO: não é repo git"; exit 1; }
  local BRANCH; BRANCH="$(git branch --show-current)"
  [ -z "$BRANCH" ] && { log "$NAME" "detached HEAD — pulado"; exit 0; }
  local DIRTY=0; [ -n "$(git status --porcelain)" ] && DIRTY=1
  # Guard de pause (cirurgia git/infra de IA): pause-file global ou por-repo faz
  # este repo ser pulado por inteiro. Codifica o bootout manual — quem pausa é
  # responsavel por remover (ver scripts/autosync-pause.sh). Restauracao garantida.
  if [ -f "${HOME}/.local/state/git-autosync.pause" ] || [ -f "$REPO/.git/autosync-pause" ]; then
    log "$NAME" "pausado (pause-file) — pulado"; exit 0
  fi
  case "$BRANCH" in
    main|master)
      if [ "$DIRTY" -eq 1 ]; then log "$NAME" "$BRANCH (protegida) com alterações — pulado"; exit 0; fi
      git fetch --quiet origin 2>>"$LOG" || { log "$NAME" "fetch falhou — pulado"; exit 0; }
      if git rev-parse "@{u}" >/dev/null 2>&1; then
        if [ "$(git rev-parse @)" != "$(git rev-parse '@{u}')" ]; then
          local PRE_PULL; PRE_PULL="$(git rev-parse HEAD 2>/dev/null || true)"
          if git pull --rebase --quiet 2>>"$LOG"; then
            log "$NAME" "pull OK em $BRANCH"
            maybe_propagate_ideiaos "$NAME" "$PRE_PULL"
          else
            git rebase --abort 2>/dev/null
            log "$NAME" "CONFLITO pull $BRANCH"
            notify "Git sync — conflito" "$NAME (main): conflito."
          fi
        fi
        local AHEAD; AHEAD="$(git rev-list --count '@{u}..@' 2>/dev/null || echo 0)"
        [ "$AHEAD" -gt 0 ] && { log "$NAME" "$AHEAD commit(s) no $BRANCH — push MANUAL"; notify "Git sync — main protegido" "$NAME: $AHEAD commit(s) aguardando push manual."; }
      fi
      # Mesmo em main (protegido), propaga os refs `planning` (memória v5) e
      # `cockpit` (telemetria v14) se à frente/atrás do upstream (auto-cura).
      push_planning_ref "$NAME"
      push_cockpit_ref "$NAME"
      exit 0 ;;
  esac
  if [ "$DIRTY" -eq 1 ]; then
    local HOST; HOST="$(hostname -s 2>/dev/null || echo mac)"
    # versions.lock fora do autosync: pin de frota só muda em commit deliberado
    # (update-upstream.sh --bump). Evita que árvore stale reverta o pin (2026-06).
    #
    # Memória fora do autosync (v5): .planning/memory/local e a ponte Cursor
    # .cursor/rules/memory-bridge.mdc nunca entram no auto-commit. O store
    # canônico é escrito no branch `planning` via git plumbing (memory-export /
    # /memory-sync), não pela árvore do branch corrente. Guard de branch extra:
    # se por algum motivo o branch corrente for `main`, NUNCA stage memória —
    # main é lido pela Lovable Cloud (incidente .lovable_mem_tmp.md em nfideia).
    local MEM_EXCLUDES=(":(exclude)versions.lock" ":(exclude).planning/memory/local" ":(exclude).cursor/rules/memory-bridge.mdc")
    if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
      # Defesa em profundidade: além de versions.lock e memória local, o store
      # shared também jamais pode ser staged no main.
      MEM_EXCLUDES+=(":(exclude).planning/memory" ":(exclude).lovable_mem_tmp.md")
    fi
    # Guard anti-contaminacao: nunca auto-commitar arvore com conflict markers
    # (incidente 2026-06: autosync varreu <<<<<<< /======= />>>>>>> p/ uma branch
    # e pushou). git diff --check reporta "leftover conflict marker" — deterministico.
    if git diff --check 2>>"$LOG" | grep -q 'leftover conflict marker'; then
      log "$NAME" "CONFLICT MARKERS — auto-commit ABORTADO em $BRANCH"
      notify "Git sync — conflict markers" "$NAME ($BRANCH): marcadores de conflito; auto-commit pulado."
      exit 0
    fi
    git add -A -- . "${MEM_EXCLUDES[@]}" 2>>"$LOG"
    git commit -q -m "wip: autosync $(date '+%Y-%m-%d %H:%M') ($HOST)" 2>>"$LOG" && log "$NAME" "auto-commit em $BRANCH" || log "$NAME" "nada para commitar em $BRANCH"
  fi
  git fetch --quiet origin 2>>"$LOG" || { log "$NAME" "fetch falhou — push adiado"; exit 0; }
  if git rev-parse "@{u}" >/dev/null 2>&1; then
    if [ "$(git rev-parse @)" != "$(git rev-parse '@{u}')" ]; then
      local PRE_PULL; PRE_PULL="$(git rev-parse HEAD 2>/dev/null || true)"
      if git pull --rebase --autostash --quiet 2>>"$LOG"; then
        log "$NAME" "pull/rebase OK em $BRANCH"
        maybe_propagate_ideiaos "$NAME" "$PRE_PULL"
      else
        git rebase --abort 2>/dev/null
        log "$NAME" "CONFLITO pull $BRANCH — push pulado"
        notify "Git sync — conflito" "$NAME ($BRANCH): conflito."
        exit 1
      fi
    fi
    local AHEAD; AHEAD="$(git rev-list --count '@{u}..@' 2>/dev/null || echo 0)"
    [ "$AHEAD" -gt 0 ] && { git push --quiet 2>>"$LOG" && log "$NAME" "push OK ($AHEAD) em $BRANCH" || { log "$NAME" "push FALHOU $BRANCH"; notify "Git sync — push falhou" "$NAME ($BRANCH)."; }; }
  else
    git push --quiet -u origin "$BRANCH" 2>>"$LOG" && log "$NAME" "push inicial OK em $BRANCH" || { log "$NAME" "push inicial FALHOU $BRANCH"; notify "Git sync — push falhou" "$NAME ($BRANCH)."; }
  fi
  push_planning_ref "$NAME"
  push_cockpit_ref "$NAME"
  exit 0
}
if [ "${1:-}" = "--all" ] || [ "$#" -eq 0 ]; then
  [ -f "$LIST" ] || { log "*" "lista $LIST não encontrada"; exit 0; }
  while IFS= read -r repo; do
    repo="${repo%%#*}"; repo="$(echo "$repo" | xargs)"
    [ -z "$repo" ] && continue
    ( sync_one "$repo" )
  done < "$LIST"
else
  ( sync_one "$1" )
fi
