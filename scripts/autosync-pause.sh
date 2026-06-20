#!/usr/bin/env bash
# autosync-pause.sh — pausa/retoma o git-autosync de forma codificada.
#
# Substitui o `launchctl bootout`/`bootstrap` manual (frágil, fácil de esquecer
# de restaurar) por um pause-file que o próprio git-autosync respeita no início
# de cada repo (guard adicionado em 2026-06 após o incidente autosync-vs-cirurgia).
#
# Uso:
#   autosync-pause.sh on [motivo]   # cria o pause-file (autosync pula todos os repos)
#   autosync-pause.sh off           # remove o pause-file (retoma)
#   autosync-pause.sh status        # mostra estado atual
#
# Escopo: pause GLOBAL (todos os repos da lista --all). Para pausar UM repo só,
# crie `<repo>/.git/autosync-pause` manualmente.
#
# IMPORTANTE: o daemon continua disparando a cada 900s, mas sai cedo (no-op) e
# loga "pausado (pause-file)". Nada de bootout/bootstrap — restauração é só `off`.
set -uo pipefail
PAUSE="${HOME}/.local/state/git-autosync.pause"
mkdir -p "$(dirname "$PAUSE")"

case "${1:-status}" in
  on)
    printf 'paused-at=%s\nreason=%s\nby=%s\n' \
      "$(date '+%Y-%m-%d %H:%M:%S')" "${2:-cirurgia git/infra}" "$(whoami)@$(hostname -s 2>/dev/null || echo host)" > "$PAUSE"
    echo "⏸  git-autosync PAUSADO (pause-file: $PAUSE)"
    echo "   retome com: $(basename "$0") off"
    ;;
  off)
    if [ -f "$PAUSE" ]; then
      rm -f "$PAUSE"
      echo "▶  git-autosync RETOMADO (pause-file removido)"
    else
      echo "▶  git-autosync já estava ativo (sem pause-file)"
    fi
    ;;
  status)
    if [ -f "$PAUSE" ]; then
      echo "⏸  PAUSADO:"; sed 's/^/   /' "$PAUSE"
    else
      echo "▶  ATIVO (sem pause-file em $PAUSE)"
    fi
    ;;
  *)
    echo "uso: $(basename "$0") {on [motivo]|off|status}" >&2; exit 2 ;;
esac
