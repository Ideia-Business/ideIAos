# SOURCE: IdeiaOS v15 (R15-19)
# =============================================================================
# redeploy-daemon.sh — redeploy CANÔNICO do git-autosync a partir da fonte versionada.
#
# Substitui os patchers in-place (sed/grep/python do ideiaos-update.sh steps 2/2b/2c/2d)
# por uma cópia atômica idempotente: o binário deployado vira BYTE-A-BYTE igual à fonte
# canônica `source/autosync/git-autosync.sh`, curando QUALQUER drift (guard faltando,
# forma antiga) numa só operação. Estritamente superior ao patch in-place — que aplica
# um delta e deixa o binário HÍBRIDO; o cp substitui o arquivo inteiro, então o estado
# anterior do daemon é irrelevante. Idempotente via `cmp`.
#
# Por que isto unifica as "2 estratégias" (R15-19): o cp-canônico já existia (2e do
# ideiaos-update + propagate), rodando DEPOIS dos patchers in-place — e os anulava. Esta
# lib torna a lógica de redeploy 1 função reutilizável; o caller in-place vira redundante.
# =============================================================================

[ -n "${__IDEIAOS_REDEPLOY_DAEMON_LOADED:-}" ] && return 0
__IDEIAOS_REDEPLOY_DAEMON_LOADED=1

# redeploy_autosync_daemon SRC DST
#   stdout: ALREADY | HEALED | MISSING | FAILED   (token machine-readable)
#   exit:   0 (ALREADY/HEALED) · 1 (FAILED) · 2 (MISSING)
# Cópia atômica (.tmp + mv): o tick em execução mantém o inode antigo; o novo vale no
# próximo tick. chmod ANTES do mv — nunca expõe um destino não-executável.
redeploy_autosync_daemon() {
  local src="$1" dst="$2"
  [ -f "$src" ] || { echo MISSING; return 2; }
  [ -d "$(dirname "$dst")" ] || { echo MISSING; return 2; }
  if cmp -s "$src" "$dst" 2>/dev/null; then echo ALREADY; return 0; fi
  if cp "$src" "$dst.tmp" 2>/dev/null && chmod 0755 "$dst.tmp" 2>/dev/null && mv -f "$dst.tmp" "$dst" 2>/dev/null; then
    echo HEALED; return 0
  fi
  rm -f "$dst.tmp" 2>/dev/null
  echo FAILED; return 1
}
