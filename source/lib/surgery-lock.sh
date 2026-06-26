# SOURCE: IdeiaOS v15 (R15-22)
# =============================================================================
# surgery-lock.sh — sentinela AUTOMÁTICA de cirurgia git multi-arquivo.
#
# Problema: o git-autosync (daemon a cada 900s) já atropelou cirurgia git 3× em
# produção — memórias [[autosync-races-ai-git-surgery]],
# [[stale-autosync-branch-off-main]], [[claude-settings-deny-live-reload-autosync-capture]].
# O `autosync-pause.sh` (manual) resolve, mas depende de "lembrar de pausar" — que
# é exatamente o que falhou. Esta sentinela é posta AUTOMATICAMENTE por scripts de
# edição multi-arquivo (propagate-if-changed, apply-to-all-projects,
# install-global-patches) e removida por trap EXIT. O git-autosync a respeita (sai
# cedo) sem passo manual.
#
# DIFERENÇA do pause-file manual (git-autosync.pause):
#   - pause-file        → INTENCIONAL, sem expiração (operador é dono do `off`).
#   - surgery-sentinela → AUTOMÁTICA, EXPIRA (stale-guard por PID vivo + TTL). Um
#     script que crashar sem limpar NÃO trava o autosync para sempre — falha-segura.
#     Senão a cura vira a doença: um lock órfão pararia toda a sincronização da frota.
#
# Uso (em scripts de cirurgia):
#   IDEIAOS_DIR="${IDEIAOS_DIR:-$HOME/dev/IdeiaOS}"
#   [ -f "$IDEIAOS_DIR/source/lib/surgery-lock.sh" ] \
#     && . "$IDEIAOS_DIR/source/lib/surgery-lock.sh" \
#     || surgery_begin() { return 0; }   # fallback no-op se lib ausente
#   surgery_begin "propagate-if-changed"   # põe sentinela + trap EXIT p/ remover
#   ... cirurgia git multi-arquivo ...
#   # surgery_end roda automático no EXIT
#
# O git-autosync NÃO sourceia este arquivo (daemon auto-contido, distribuído por
# cópia): ele consome a sentinela por uma cópia INLINE da lógica de `surgery_active`.
# O contrato entre produtor e consumidor é o FORMATO do arquivo (pid=/started=),
# não o código. Mudou o formato aqui → atualize o consumidor inline no autosync.
# =============================================================================

# Double-source guard (bash 3.2; não setar `set` — afeta o shell caller).
[ -n "${__IDEIAOS_SURGERY_LOCK_LOADED:-}" ] && return 0
__IDEIAOS_SURGERY_LOCK_LOADED=1

SURGERY_SENTINEL="${SURGERY_SENTINEL:-$HOME/.local/state/git-autosync.surgery}"
SURGERY_TTL="${SURGERY_TTL:-1800}"   # 30 min — stale-guard de defesa-em-profundidade

# _surgery_file_epoch PATH — mtime em epoch, portável (BSD stat macOS / GNU stat).
_surgery_file_epoch() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# surgery_begin [reason] — cria a sentinela e arma o trap de remoção (teardown garantido).
surgery_begin() {
  mkdir -p "$(dirname "$SURGERY_SENTINEL")" 2>/dev/null || return 0
  printf 'pid=%s\nstarted=%s\nreason=%s\nby=%s\n' \
    "$$" "$(date +%s)" "${1:-cirurgia multi-arquivo}" \
    "$(whoami 2>/dev/null)@$(hostname -s 2>/dev/null || echo host)" \
    > "$SURGERY_SENTINEL" 2>/dev/null || return 0
  # trap garante remoção mesmo em erro/interrupção — espelha temp-privilege-window-teardown.
  trap 'surgery_end' EXIT INT TERM
}

# surgery_end — remove a sentinela SOMENTE se for desta sessão (pid casa) — evita
# que um script remova o lock de outra cirurgia concorrente na mesma máquina.
surgery_end() {
  [ -f "$SURGERY_SENTINEL" ] || return 0
  local owner; owner="$(sed -n 's/^pid=//p' "$SURGERY_SENTINEL" 2>/dev/null | head -1)"
  if [ -z "${owner:-}" ] || [ "$owner" = "$$" ]; then rm -f "$SURGERY_SENTINEL" 2>/dev/null; fi
}

# surgery_active — exit 0 se há cirurgia VIVA em andamento; 1 caso contrário.
# Stale-guard (falha-segura): sentinela é ignorada se o PID morreu OU o TTL expirou.
surgery_active() {
  [ -f "$SURGERY_SENTINEL" ] || return 1
  local pid started now
  pid="$(sed -n 's/^pid=//p' "$SURGERY_SENTINEL" 2>/dev/null | head -1)"
  started="$(sed -n 's/^started=//p' "$SURGERY_SENTINEL" 2>/dev/null | head -1)"
  now="$(date +%s)"
  # sanitiza valores corrompidos (não-numéricos) → tratados como ausentes; sob `set -u`
  # uma sentinela corrompida abortaria o subshell na aritmética. Simetria com idea-doctor.sh:902.
  case "${started:-}" in *[!0-9]*|'') started= ;; esac
  case "${pid:-}" in *[!0-9]*|'') pid= ;; esac
  [ -n "${started:-}" ] && [ $((now - started)) -ge "$SURGERY_TTL" ] && return 1   # TTL → stale
  [ -n "${pid:-}" ] && ! kill -0 "$pid" 2>/dev/null && return 1                     # PID morto → stale
  return 0
}
