#!/usr/bin/env bash
# =============================================================================
# idea-doctor.sh — diagnóstico de saúde + drift do ambiente IdeiaOS (READ-ONLY)
#
# Audita, sem alterar nada:
#   1. Skills globais (orquestração + dev-loop + Suíte de Design) e GSD
#   2. Drift: cópia global vs fonte do repo (source/skills/) — pede setup --global-only
#   3. MCPs (chrome-devtools, context7)
#   4. Os 10 patches do overlay (markers de idempotência)
#   5. Versões instaladas vs versions.lock (aiox-core, gsd) + pin da Suíte
#   6. Autosync (LaunchAgent) ativo
#   7. Security Audit (deny rules, hooks perigosos, secrets em memória, quarentena)
#
# Exit: 0 se sem FAIL; 1 se houver FAIL (componente crítico ausente/quebrado).
# WARN não falha (drift, opcionais). Cada achado vem com a remediação.
#
# Uso:  bash scripts/idea-doctor.sh
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$SETUP_DIR/versions.lock"
GSKILLS="$HOME/.claude/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
pass() { echo -e "${GREEN}  ✓${NC} $*"; PASS=$((PASS+1)); }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; WARN=$((WARN+1)); }
fail() { echo -e "${RED}  ✗${NC} $*"; FAIL=$((FAIL+1)); }
info() { echo -e "${CYAN}  ℹ${NC} $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }
PASS=0; WARN=0; FAIL=0

read_lock() { [ -f "$LOCK" ] && grep -m1 "^$1=" "$LOCK" 2>/dev/null | cut -d= -f2- || true; }
find_aiox_core() {
  for c in "$(dirname "$SETUP_DIR")/.aiox-core" \
           "$HOME/Projects/.aiox-core"; do
    [ -d "$c/development/agents" ] && { echo "$c"; return 0; }
  done
  return 1
}

echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo    "║          IdeiaOS — idea-doctor (health + drift)         ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "  Repo: ${BOLD}$SETUP_DIR${NC}   Global: ${BOLD}$GSKILLS${NC}"

# ── 1) Skills globais ─────────────────────────────────────────────────────────
step "1) Skills globais"
ORCH="idea ideiaos-setup cursor-continuation lovable-handoff recall-learnings extract-learnings"
DEVLOOP="frontend-visual-loop motion web-quality"
SUITE="ui-ux-pro-max design design-system ui-styling brand banner-design slides"
for s in $ORCH $DEVLOOP $SUITE; do
  if [ -f "$GSKILLS/$s/SKILL.md" ]; then pass "skill /$s"; else fail "skill /$s AUSENTE — rode: bash setup.sh --global-only"; fi
done
GSD_COUNT=$(ls -d "$GSKILLS"/gsd-* 2>/dev/null | wc -l | tr -d ' ')
if [ "$GSD_COUNT" -gt 0 ]; then pass "GSD: $GSD_COUNT skills /gsd-*"; else fail "GSD ausente — adicione o plugin GSD no menu do Claude Code"; fi

# ── 2) Drift: global vs fonte do repo ─────────────────────────────────────────
step "2) Drift (cópia global vs fonte do repo)"
DRIFT=0
for d in "$SETUP_DIR"/source/skills/*/; do
  s="$(basename "$d")"
  [ -d "$GSKILLS/$s" ] || continue
  if ! diff -rq "$d" "$GSKILLS/$s" &>/dev/null; then warn "drift em /$s (global ≠ repo)"; DRIFT=$((DRIFT+1)); fi
done
[ "$DRIFT" -eq 0 ] && pass "sem drift — global idêntico à fonte (source/skills/)" || info "→ sincronize: bash scripts/sync-all.sh (ou setup.sh --global-only)"

# ── 3) MCPs ───────────────────────────────────────────────────────────────────
step "3) MCPs (user scope)"
if command -v claude >/dev/null 2>&1; then
  for m in chrome-devtools context7; do
    if claude mcp get "$m" 2>/dev/null | grep -q "$m"; then pass "MCP $m configurado"; else warn "MCP $m ausente — rode: bash setup.sh --global-only"; fi
  done
else
  warn "Claude Code CLI não encontrado — não checou MCPs"
fi

# ── 4) Overlay (7 patches) ────────────────────────────────────────────────────
step "4) Overlay — 7 patches"
chk() { # nome, arquivo, marcador
  if [ ! -f "$2" ]; then warn "$1: alvo ausente ($2)"; return; fi
  if grep -qF -- "$3" "$2" 2>/dev/null; then pass "$1"; else warn "$1 NÃO aplicado — rode: bash scripts/install-global-patches.sh"; fi
}
# Ordem sequencial 1→7. Patch 3 (hook) não tem marcador de string — checa presença.
chk "Patch 1 (gsd-plan-phase --story)"   "$GSKILLS/gsd-plan-phase/SKILL.md"                 "--story <file>"
chk "Patch 2 (plan-phase STORY_MODE)"    "$HOME/.claude/get-shit-done/workflows/plan-phase.md" "STORY_MODE"
if [ -f "$HOME/.claude/hooks/extract-learnings-reminder.sh" ]; then pass "Patch 3 (hook Fase A presente)"; else warn "Patch 3 ausente — install-global-patches.sh"; fi
chk "Patch 4 (settings.json matcher)"    "$HOME/.claude/settings.json"                     "extract-learnings-reminder.sh"
# Patches 5,6: AIOX-core (pode não estar instalado)
if AIOX="$(find_aiox_core)"; then
  chk "Patch 5 (AIOX qa.md --verification)" "$AIOX/development/agents/qa.md"     "--verification <path>"
  chk "Patch 6 (AIOX qa-gate Composition)"  "$AIOX/development/tasks/qa-gate.md" "Optional Input — IdeiaOS Composition"
else
  info "Patches 5/6 (AIOX): AIOX-core não localizado — instale via npm + install-global-patches"
fi
chk "Patch 7 (design-system OKLCH)"      "$GSKILLS/design-system/SKILL.md"                 "oklch-tokens.md"
# Patch 8 (hook git-sync) — presença do script + registro no settings.json
if [ -f "$HOME/.claude/hooks/git-sync-check.sh" ]; then pass "Patch 8 (hook git-sync presente)"; else warn "Patch 8 ausente — install-global-patches.sh"; fi
chk "Patch 8 (git-sync no SessionStart)" "$HOME/.claude/settings.json"                     "git-sync-check.sh"
# Patch 9 (gitignore global) — settings.local.json não pode sujar o tree
if grep -qxF ".claude/settings.local.json" "$HOME/.config/git/ignore" 2>/dev/null; then pass "Patch 9 (gitignore global)"; else warn "Patch 9 ausente — install-global-patches.sh"; fi

# ── 5) Versões vs lock ────────────────────────────────────────────────────────
step "5) Versões vs versions.lock"
if [ -f "$LOCK" ]; then
  AIOX_PIN="$(read_lock aiox-core)"; GSD_PIN="$(read_lock gsd)"
  GVF="$HOME/.claude/get-shit-done/VERSION"
  if [ -f "$GVF" ]; then
    GI="$(tr -d ' \n' < "$GVF")"
    [ "$GI" = "$GSD_PIN" ] && pass "GSD $GI = pin" || warn "GSD drift: instalado $GI ≠ pin $GSD_PIN (update-upstream.sh --bump se intencional)"
  fi
  # Fonte de verdade = INSTALAÇÃO (.aiox-core/package.json), não o CLI global,
  # que pode ficar defasado e exige sudo p/ atualizar. Fallback: CLI.
  AIOX_ROOT="$(find_aiox_core 2>/dev/null || true)"
  AV=""
  [ -n "$AIOX_ROOT" ] && [ -f "$AIOX_ROOT/package.json" ] && \
    AV="$(python3 -c "import json,sys; print(json.load(open('$AIOX_ROOT/package.json')).get('version',''))" 2>/dev/null)"
  [ -z "$AV" ] && AV="$( (aiox --version 2>/dev/null || aiox-core --version 2>/dev/null) | head -1 )"
  if [ -n "$AV" ]; then
    [ "$AV" = "$AIOX_PIN" ] && pass "aiox-core $AV = pin" || warn "AIOX drift: instalado $AV ≠ pin $AIOX_PIN (update-upstream.sh --bump se intencional)"
  fi
  info "Suíte de Design pin: $(read_lock design-suite-ref) ($(read_lock design-suite-commit))"
else
  warn "versions.lock ausente — esperado em $LOCK"
fi

# ── 6) Autosync ───────────────────────────────────────────────────────────────
step "6) Autosync (LaunchAgent)"
if launchctl list 2>/dev/null | grep -qi gitautosync; then pass "git-autosync ativo (launchd)"; else warn "git-autosync não carregado — rode setup-dev-machine.sh"; fi
# Label antigo (com.gustavo) → migre para o genérico com.ideiaos (este check some sozinho após migrar)
if launchctl list 2>/dev/null | grep -q "com.gustavo.gitautosync" || [ -f "$HOME/Library/LaunchAgents/com.gustavo.gitautosync.plist" ]; then
  warn "Autosync com label ANTIGO 'com.gustavo' — migre p/ 'com.ideiaos':"
  echo "       launchctl bootout gui/\$(id -u)/com.gustavo.gitautosync 2>/dev/null"
  echo "       rm -f ~/Library/LaunchAgents/com.gustavo.gitautosync.plist"
  echo "       bash \"$SETUP_DIR/setup-dev-machine.sh\"   # recria com o label novo"
fi

# ── 7) Security Audit ─────────────────────────────────────────────────────────
step "7) Security Audit"
SETTINGS="$HOME/.claude/settings.json"

# 7a) Deny rules baseline presentes?
REQUIRED_DENY=("Read(~/.ssh/**)" "Read(~/.aws/**)" "Read(**/.env*)" "Write(~/.ssh/**)" "Bash(curl * | bash)" "Bash(nc *)")
if [ -f "$SETTINGS" ]; then
  for rule in "${REQUIRED_DENY[@]}"; do
    if python3 -c "import json,sys; d=json.load(open('$SETTINGS')).get('permissions',{}).get('deny',[]); sys.exit(0 if '$rule' in d else 1)" 2>/dev/null; then
      pass "deny: $rule"
    else
      fail "deny rule ausente: $rule — rode: bash scripts/install-global-patches.sh"
    fi
  done
else
  fail "settings.json não encontrado em $SETTINGS"
fi

# 7b) Hooks com curl|bash pipe (comando perigoso)
if [ -d "$HOME/.claude/hooks" ]; then
  if rg -ln 'curl.*\|.*bash|bash.*<.*curl' "$HOME/.claude/hooks/" 2>/dev/null | grep -q .; then
    fail "Hooks contêm curl|bash pipe — inspeção manual necessária"
  else
    pass "Hooks sem curl|bash pipe"
  fi
fi

# 7c) Secrets em texto plano na memória de projeto
MEM_DIR="$HOME/.claude/projects"
if [ -d "$MEM_DIR" ]; then
  if rg -l 'sk-[a-zA-Z0-9]{40,}|ANTHROPIC_API_KEY|service_role.*[a-zA-Z0-9]{30,}' "$MEM_DIR" 2>/dev/null | grep -q .; then
    fail "POSSÍVEL secret em memória de projeto — checar $MEM_DIR"
  else
    pass "Memória de projeto sem secrets aparentes"
  fi
fi

# 7d) scan-absorbed.sh presente (pipeline de quarentena)
if [ -x "$SETUP_DIR/security/scan-absorbed.sh" ]; then
  pass "pipeline de quarentena (security/scan-absorbed.sh) presente"
else
  warn "security/scan-absorbed.sh ausente — quarentena obrigatória não disponível"
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}━━━ Resumo ━━━${NC}"
echo -e "  ${GREEN}OK:${NC} $PASS   ${YELLOW}WARN:${NC} $WARN   ${RED}FAIL:${NC} $FAIL"
if [ "$FAIL" -gt 0 ]; then
  echo -e "\n  ${RED}${BOLD}Ambiente incompleto.${NC} Remediação rápida:"
  echo "    bash $SETUP_DIR/setup.sh --global-only   # instala skills/MCPs faltando"
  echo "    bash $SETUP_DIR/scripts/sync-all.sh      # + overlay + drift"
  exit 1
fi
[ "$WARN" -gt 0 ] && echo -e "\n  ${YELLOW}Avisos acima são não-críticos. sync-all.sh resolve a maioria.${NC}"
echo -e "  ${GREEN}${BOLD}Ambiente IdeiaOS saudável.${NC}"
exit 0
