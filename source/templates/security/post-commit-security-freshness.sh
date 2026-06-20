#!/usr/bin/env bash
# ideiaos-security-freshness-hook
# SOURCE: IdeiaOS v13 — Selo de Frescor de Segurança (surfacing por produto)
# =============================================================================
# Hook post-commit ADVISORY. Instalado LOCALMENTE por produto (nunca versionado:
# fica em .git/info/exclude). Surfacing do tier de frescor de segurança no commit.
#
# NUNCA bloqueia: post-commit roda DEPOIS do commit existir; o git ignora o exit
# code. Por construção satisfaz o "não enrijecer" — não há como travar uma feature.
#
# Emite, no máximo 1x por janela de throttle (default 6h), um WARN se a segurança
# deste repo estiver DEFASADA/EGRÉGIA. Silencioso quando fresco. Fail-soft sempre.
#
# Chama UMA cópia do engine (no IdeiaOS) via SECFRESH_ROOT=<este repo> — assim o
# produto não precisa versionar o script (zero trigger de Lovable em `main`).
# __ENGINE_PATH__ é substituído pelo setup.sh no momento da instalação.
# =============================================================================
set -uo pipefail

ENGINE="__ENGINE_PATH__"
REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
[ -x "$ENGINE" ] || exit 0   # engine ausente (IdeiaOS movido/removido) → no-op silencioso

TIER="$(SECFRESH_ROOT="$REPO" bash "$ENGINE" --tier 2>/dev/null || echo ok)"
case "$TIER" in
  warn|egregious) ;;          # só fala quando há dívida
  *) exit 0 ;;                # ok | unbootstrapped | qualquer ruído → quieto
esac

# Throttle: no máximo 1 aviso por janela — não spamma o git-autosync (que commita
# em ciclo). Marcador local, em .git/info/exclude (nunca versionado).
THROTTLE="${SECFRESH_HOOK_THROTTLE:-21600}"   # 6h
MARK="$REPO/.security/.last-warn-epoch"
NOW="$(date +%s)"
LAST=0; [ -f "$MARK" ] && LAST="$(cat "$MARK" 2>/dev/null || echo 0)"
case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
[ $((NOW - LAST)) -lt "$THROTTLE" ] && exit 0
mkdir -p "$REPO/.security" 2>/dev/null || true
echo "$NOW" > "$MARK" 2>/dev/null || true

{
  echo ""
  echo "  ⚠️  [IdeiaOS · Frescor de Segurança] DEFASADO neste repo (tier=$TIER)."
  echo "     Há quanto tempo ninguém revisa a segurança × o que mudou desde então."
  echo "     Ação: rode @security-reviewer no diff desde o último selo e registre —"
  echo "       SECFRESH_ROOT=\"$REPO\" bash \"$ENGINE\" --record PASS @security-reviewer"
  echo "     (ADVISORY — NÃO bloqueia commit nem deploy. Reaviso só após ${THROTTLE}s.)"
} >&2

exit 0
