#!/usr/bin/env bash
# =============================================================================
# idea-doctor.sh — diagnóstico de saúde + drift do ambiente IdeiaOS (READ-ONLY)
#
# Audita, sem alterar nada:
#   1. Skills globais (orquestração + dev-loop + Suíte de Design) e GSD
#   2. Drift: cópia global vs fonte do repo (source/skills/) — pede setup --global-only
#   3. MCPs (chrome-devtools, context7)
#   4. Os 15 patches do overlay (markers de idempotência)
#   5. Versões instaladas vs versions.lock (aiox-core, gsd) + pin da Suíte
#   6. Autosync (LaunchAgent) ativo
#   7. Security Audit (deny rules, hooks perigosos, secrets em memória, quarentena,
#      contenção Lovable MCP nos produtos — 7e, anti-regressão deny=19)
#
# Exit: 0 se sem FAIL; 1 se houver FAIL (componente crítico ausente/quebrado).
# WARN não falha (drift, opcionais). Cada achado vem com a remediação.
#
# Uso:  bash scripts/idea-doctor.sh [--json|--fleet]
#       --json   Emite JSON ideiaos-doctor/v1 em vez de saída ANSI (sem output colorido).
#       --fleet  Agrega os snapshots do ref cockpit (frota cross-máquina): nome (alias-map),
#                idade do snapshot (anti-falso-verde) e status; "sem sinal" (>1d) ≠ FAIL.
# =============================================================================
set -uo pipefail

# ── Flag --json ──────────────────────────────────────────────────────────────
JSON_MODE=0
FLEET_MODE=0
for _arg in "$@"; do
  [ "$_arg" = "--json" ] && JSON_MODE=1
  [ "$_arg" = "--fleet" ] && FLEET_MODE=1
done

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$SETUP_DIR/versions.lock"
GSKILLS="$HOME/.claude/skills"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ── Buffers para o sink JSON (arrays bash 3.2 paralelos) ─────────────────────
# SEC_ID / SEC_TITLE acumulam uma entrada por step() numerado (não "Resumo").
# ITEM_SEC / ITEM_LEVEL / ITEM_MSG acumulam um item por pass/warn/fail/info.
SEC_ID=()
SEC_TITLE=()
ITEM_SEC=()
ITEM_LEVEL=()
ITEM_MSG=()
_CURRENT_SEC=""  # id da seção corrente (string, e.g. "1")

# ── Helper de escape JSON (sem jq/python no runtime) ─────────────────────────
json_escape() {
  # Escapa apenas \ e " — suficiente para metadata (paths, mensagens curtas).
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# ── 5 emitters DECORADOS (echo ANSI inalterado + push em arrays) ─────────────
# Em modo JSON_MODE=1 os echo ANSI vão para /dev/null (saída limpa p/ o sink).
if [ "$JSON_MODE" -eq 1 ]; then
  pass() {
    echo -e "${GREEN}  ✓${NC} $*" >/dev/null
    PASS=$((PASS+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("pass")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  warn() {
    echo -e "${YELLOW}  ⚠${NC}  $*" >/dev/null
    WARN=$((WARN+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("warn")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  fail() {
    echo -e "${RED}  ✗${NC} $*" >/dev/null
    FAIL=$((FAIL+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("fail")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  info() {
    echo -e "${CYAN}  ℹ${NC} $*" >/dev/null
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("info")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  step() {
    echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}" >/dev/null
    # Parse: ^([0-9]+)\)[[:space:]]*(.*)$ — "Resumo" (sem número) não empilha.
    if [[ "$*" =~ ^([0-9]+)\)[[:space:]]*(.*) ]]; then
      local sid="${BASH_REMATCH[1]}"
      local stitle="${BASH_REMATCH[2]}"
      SEC_ID+=("$sid")
      SEC_TITLE+=("$(json_escape "$stitle")")
      _CURRENT_SEC="$sid"
    fi
  }
else
  pass() {
    echo -e "${GREEN}  ✓${NC} $*"
    PASS=$((PASS+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("pass")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  warn() {
    echo -e "${YELLOW}  ⚠${NC}  $*"
    WARN=$((WARN+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("warn")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  fail() {
    echo -e "${RED}  ✗${NC} $*"
    FAIL=$((FAIL+1))
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("fail")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  info() {
    echo -e "${CYAN}  ℹ${NC} $*"
    ITEM_SEC+=("$_CURRENT_SEC")
    ITEM_LEVEL+=("info")
    ITEM_MSG+=("$(json_escape "$*")")
  }
  step() {
    echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"
    if [[ "$*" =~ ^([0-9]+)\)[[:space:]]*(.*) ]]; then
      local sid="${BASH_REMATCH[1]}"
      local stitle="${BASH_REMATCH[2]}"
      SEC_ID+=("$sid")
      SEC_TITLE+=("$(json_escape "$stitle")")
      _CURRENT_SEC="$sid"
    fi
  }
fi
PASS=0; WARN=0; FAIL=0

read_lock() { [ -f "$LOCK" ] && grep -m1 "^$1=" "$LOCK" 2>/dev/null | cut -d= -f2- || true; }
find_aiox_core() {
  for c in "$(dirname "$SETUP_DIR")/.aiox-core" \
           "$HOME/Projects/.aiox-core"; do
    [ -d "$c/development/agents" ] && { echo "$c"; return 0; }
  done
  return 1
}

# ── Modo --fleet (R15-09): agrega snapshots do ref cockpit ───────────────────
# Read-only sobre o ref `cockpit`. O snapshot já carrega doctor:{ok,warn,fail} e
# taken_epoch (idade) — zero coleta nova. SEMPRE renderiza a idade (anti-falso-verde);
# distingue "sem sinal" (DORMANT, >1d sem reportar — NÃO é falha) de FAIL. Sem declare -A.
run_fleet() {
  local repo="$SETUP_DIR"
  echo -e "\n${CYAN}${BOLD}━━━ Frota IdeiaOS (--fleet) ━━━${NC}"
  if ! git -C "$repo" rev-parse --verify --quiet refs/heads/cockpit >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠${NC}  ref cockpit ausente neste repo — nenhuma frota para agregar."
    echo -e "  ${CYAN}ℹ${NC}  publique snapshots com o Cockpit (source/lib/cockpit.sh) primeiro."
    return 0
  fi
  local snaps
  snaps="$(git -C "$repo" ls-tree --name-only cockpit snapshots/ 2>/dev/null | grep '\.json$' || true)"
  if [ -z "$snaps" ]; then
    echo -e "  ${YELLOW}⚠${NC}  ref cockpit existe, mas sem snapshots ainda."
    return 0
  fi
  local now af count dormant failc vazio
  now="$(date +%s)"
  af="$repo/source/console/machine-aliases.json"
  count=0; dormant=0; failc=0; vazio=0
  printf "  ${BOLD}%-22s %-11s %-8s %s${NC}\n" "MÁQUINA" "IDADE" "STATUS" "DETALHE"
  local snap mid line st name age det color
  while IFS= read -r snap; do
    [ -z "$snap" ] && continue
    mid="$(basename "$snap" .json)"
    line="$(git -C "$repo" show "cockpit:$snap" 2>/dev/null | node -e '
      const fs=require("fs");
      const mid=process.argv[1], now=parseInt(process.argv[2],10), af=process.argv[3];
      let j={}; try { j=JSON.parse(fs.readFileSync(0,"utf8")); } catch(e) {}
      let al={}; try { al=JSON.parse(fs.readFileSync(af,"utf8")); } catch(e) {}
      const name=al[mid]||mid.slice(0,12);
      const d=j.doctor||{};
      const ep=j.taken_epoch;
      const DORMANT=86400;
      function fmtAge(s){ s=Math.max(0,s); if(s<60)return s+"s"; const m=Math.floor(s/60); if(m<60)return m+"m"; const h=Math.floor(m/60); if(h<24)return h+"h "+(m%60)+"m"; const dd=Math.floor(h/24); return dd+"d "+(h%24)+"h"; }
      const ex=(typeof d.exit==="number")?d.exit:null;
      const tot=(d.ok||0)+(d.warn||0)+(d.fail||0);
      let st, age;
      if(typeof ep!=="number"||!isFinite(ep)){ st="DORMANT"; age="?"; }
      else { const a=now-ep; age=fmtAge(a);
        if(a>DORMANT) st="DORMANT";
        else if(ex===null||ex<0||tot===0) st="VAZIO";
        else if((d.fail||0)>0||ex===1) st="FAIL";
        else if((d.warn||0)>0) st="WARN";
        else st="OK"; }
      const det="exit="+(ex===null?"?":ex)+" ok="+(d.ok||0)+" warn="+(d.warn||0)+" fail="+(d.fail||0)+" · agentd "+(j.agentd_version||"?")+" · "+(j.os_version||"?");
      process.stdout.write(st+"\t"+name+"\t"+age+"\t"+det+"\n");
    ' "$mid" "$now" "$af" || true)"
    [ -z "$line" ] && continue
    IFS=$'\t' read -r st name age det <<<"$line"
    case "$st" in
      OK)      color="$GREEN" ;;
      WARN)    color="$YELLOW" ;;
      FAIL)    color="$RED";    failc=$((failc+1)) ;;
      DORMANT) color="$CYAN";   dormant=$((dormant+1)) ;;
      VAZIO)   color="$YELLOW"; vazio=$((vazio+1)) ;;
      *)       color="$NC" ;;
    esac
    printf "  ${BOLD}%-22s${NC} %-11s ${color}%-8s${NC} %s\n" "$name" "$age" "$st" "$det"
    count=$((count+1))
  done <<EOF
$snaps
EOF
  echo ""
  echo -e "  ${BOLD}${count} máquina(s)${NC} · ${CYAN}${dormant} sem sinal${NC} · ${YELLOW}${vazio} sem veredito${NC} · ${RED}${failc} com falha${NC}"
  echo -e "  ${CYAN}ℹ${NC}  idade = tempo desde o snapshot (anti-falso-verde); \"sem sinal\" = >1d sem reportar;"
  echo -e "      \"VAZIO\" = snapshot sem veredito do doctor (coleta incompleta, exit=-1) — nenhum é falha."
}
if [ "$FLEET_MODE" -eq 1 ]; then
  run_fleet
  exit 0
fi

if [ "$JSON_MODE" -eq 0 ]; then
  echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
  echo    "║          IdeiaOS — idea-doctor (health + drift)         ║"
  echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
  echo -e "  Repo: ${BOLD}$SETUP_DIR${NC}   Global: ${BOLD}$GSKILLS${NC}"
fi

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

# ── 4) Overlay (15 patches) ───────────────────────────────────────────────────
step "4) Overlay — 15 patches"
chk() { # nome, arquivo, marcador
  if [ ! -f "$2" ]; then warn "$1: alvo ausente ($2)"; return; fi
  if grep -qF -- "$3" "$2" 2>/dev/null; then pass "$1"; else warn "$1 NÃO aplicado — rode: bash scripts/install-global-patches.sh"; fi
}
# Ordem 1→9 + 11→13 (Patch 10 deny-rules conferido na Seção 7). Patch 3 (hook) não tem marcador — checa presença.
chk "Patch 1 (gsd-plan-phase --story)"   "$GSKILLS/gsd-plan-phase/SKILL.md"                 "--story <file>"
chk "Patch 2 (plan-phase STORY_MODE)"    "$HOME/.claude/get-shit-done/workflows/plan-phase.md" "STORY_MODE"
if [ -f "$HOME/.claude/hooks/extract-learnings-reminder.sh" ]; then pass "Patch 3 (hook Fase A presente)"; else warn "Patch 3 ausente — install-global-patches.sh"; fi
chk "Patch 4 (settings.json matcher)"    "$HOME/.claude/settings.json"                     "extract-learnings-reminder.sh"
# Patches 5,6: AIOX-core (pode não estar instalado)
if AIOX="$(find_aiox_core)"; then
  chk "Patch 5 (AIOX qa.md --verification)" "$AIOX/development/agents/qa.md"     "--verification <path>"
  chk "Patch 6 (AIOX qa-gate Composition)"  "$AIOX/development/tasks/qa-gate.md" "Optional Input — IdeiaOS Composition"
  chk "Patch 14 (AIOX pm.md to-prd)"        "$AIOX/development/agents/pm.md"     "Síntese sobre entrevista (delta to-prd)"
  # YAML dos agentes AIOX parseável? (parser AUTORITATIVO js-yaml → ruby → python; skip gracioso se nenhum)
  if bash "$SETUP_DIR/scripts/validate-agent-yaml.sh" "$AIOX/development/agents" >/dev/null 2>&1; then
    pass "YAML dos agentes AIOX válido (parser do runtime)"
  else
    fail "YAML inválido em agente AIOX — rode: bash scripts/validate-agent-yaml.sh $AIOX/development/agents"
  fi
else
  info "Patches 5/6 (AIOX): AIOX-core não localizado — instale via npm + install-global-patches"
fi
chk "Patch 7 (design-system OKLCH)"      "$GSKILLS/design-system/SKILL.md"                 "oklch-tokens.md"
# Patch 8 (hook git-sync) — presença do script + registro no settings.json
if [ -f "$HOME/.claude/hooks/git-sync-check.sh" ]; then pass "Patch 8 (hook git-sync presente)"; else warn "Patch 8 ausente — install-global-patches.sh"; fi
chk "Patch 8 (git-sync no SessionStart)" "$HOME/.claude/settings.json"                     "git-sync-check.sh"
# Patch 9 (gitignore global) — settings.local.json não pode sujar o tree
if grep -qxF ".claude/settings.local.json" "$HOME/.config/git/ignore" 2>/dev/null; then pass "Patch 9 (gitignore global)"; else warn "Patch 9 ausente — install-global-patches.sh"; fi
# Patch 11 (hook backlog-sync) — presença do script + registro no settings.json (gated p/ ideiapartner)
if [ -f "$HOME/.claude/hooks/backlog-sync-check.sh" ]; then pass "Patch 11 (hook backlog-sync presente)"; else warn "Patch 11 ausente — install-global-patches.sh"; fi
chk "Patch 11 (backlog-sync no SessionStart)" "$HOME/.claude/settings.json"                "backlog-sync-check.sh"
# Patch 12 (hook memory-import) — presença do script + registro no SessionStart (memória v5)
if [ -f "$HOME/.claude/hooks/memory-import.sh" ]; then pass "Patch 12 (hook memory-import presente)"; else warn "Patch 12 ausente — install-global-patches.sh"; fi
chk "Patch 12 (memory-import no SessionStart)" "$HOME/.claude/settings.json"               "memory-import.sh"
# Patch 13 (hook memory-export) — presença do script + registro no Stop (memória v5)
if [ -f "$HOME/.claude/hooks/memory-export.sh" ]; then pass "Patch 13 (hook memory-export presente)"; else warn "Patch 13 ausente — install-global-patches.sh"; fi
chk "Patch 13 (memory-export no Stop)" "$HOME/.claude/settings.json"                       "memory-export.sh"
# Patch 15 (gsd-debug seam note) — delta diagnose (v9 Fase G)
chk "Patch 15 (gsd-debug seam note)" "$GSKILLS/gsd-debug/SKILL.md"                          "Achado de seam (delta IdeiaOS"

# ── 5) Versões vs lock ────────────────────────────────────────────────────────
step "5) Versões vs versions.lock"
if [ -f "$LOCK" ]; then
  AIOX_PIN="$(read_lock aiox-core)"; GSD_PIN="$(read_lock gsd)"
  GVF="$HOME/.claude/get-shit-done/VERSION"
  if [ -f "$GVF" ]; then
    GI="$(tr -d ' \n' < "$GVF")"
    # Pré-redux (1.30–1.99) vs redux (recomeçou em 1.x): 1.1.0 > 1.36.0.
    # Mensagem direcional — o aviso genérico já induziu reverts do pin (2026-06).
    is_legacy_gsd() { case "$1" in 1.3[0-9]|1.3[0-9].*|1.4[0-9]|1.4[0-9].*|1.[5-9][0-9]|1.[5-9][0-9].*) return 0;; esac; return 1; }
    # gsd-pi (2.x/3.x) é produto DIFERENTE do redux (@opengsd/get-shit-done-redux, 1.x).
    is_gsd_pi() { case "$1" in 2.*|3.*|[4-9]*) return 0;; esac; return 1; }
    if [ "$GI" = "$GSD_PIN" ]; then
      pass "GSD $GI = pin"
    elif is_legacy_gsd "$GI"; then
      warn "GSD INSTALADO é pré-redux ($GI) — atualize o plugin GSD nesta máquina; NÃO rode --bump aqui (@opengsd/get-shit-done-redux, nao gsd-pi)"
    elif is_gsd_pi "$GI"; then
      warn "GSD INSTALADO parece ser gsd-PI ($GI) — produto diferente do redux."
      warn "O IdeiaOS usa @opengsd/get-shit-done-redux (1.x, org opengsd)."
      warn "Remova o gsd-pi e instale o redux pelo marketplace do Claude Code."
    elif is_legacy_gsd "$GSD_PIN"; then
      warn "GSD pin LEGADO pré-redux ($GSD_PIN); instalado $GI (redux) é MAIS NOVO — corrija: update-upstream.sh --bump + commit"
    else
      warn "GSD drift: instalado $GI ≠ pin $GSD_PIN (update-upstream.sh --bump se intencional; nunca edite o pin na mão)"
    fi
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
  DS_REF="$(read_lock design-suite-ref)"; DS_COMMIT="$(read_lock design-suite-commit)"
  if printf '%s' "$DS_COMMIT" | grep -qiE '^[0-9a-f]{7,40}$'; then
    pass "Suíte de Design pin: ref=$DS_REF commit=$DS_COMMIT (hash real)"
  else
    warn "Suíte de Design commit='$DS_COMMIT' não é hash real (seed local) — alinhe ao ref pinado: bash scripts/update-design-suite.sh"
  fi
else
  warn "versions.lock ausente — esperado em $LOCK"
fi

# ── 6) Autosync ───────────────────────────────────────────────────────────────
step "6) Autosync (LaunchAgent)"
if launchctl list 2>/dev/null | grep -qi gitautosync; then pass "git-autosync ativo (launchd)"; else warn "git-autosync não carregado — rode setup-dev-machine.sh"; fi
# Drift de CONTEÚDO do daemon vs fonte canônica (antes o doctor só via "carregado",
# nunca a lógica — máquina rodando daemon velho passava verde). cmp = determinístico.
_AS_SRC="$SETUP_DIR/source/autosync/git-autosync.sh"
_AS_DST="$HOME/.local/bin/git-autosync"
if [ -f "$_AS_SRC" ] && [ -f "$_AS_DST" ]; then
  if cmp -s "$_AS_SRC" "$_AS_DST"; then
    pass "git-autosync na versão canônica (sem drift de conteúdo)"
  else
    warn "git-autosync DEFASADO vs source/autosync/git-autosync.sh — rode: bash \"$SETUP_DIR/scripts/propagate-if-changed.sh\" --force"
  fi
fi
# Label antigo (com.gustavo) → migre para o genérico com.ideiaos (este check some sozinho após migrar)
if launchctl list 2>/dev/null | grep -q "com.gustavo.gitautosync" || [ -f "$HOME/Library/LaunchAgents/com.gustavo.gitautosync.plist" ]; then
  warn "Autosync com label ANTIGO 'com.gustavo' — migre p/ 'com.ideiaos':"
  if [ "$JSON_MODE" -eq 0 ]; then
    echo "       launchctl bootout gui/\$(id -u)/com.gustavo.gitautosync 2>/dev/null"
    echo "       rm -f ~/Library/LaunchAgents/com.gustavo.gitautosync.plist"
    echo "       bash \"$SETUP_DIR/setup-dev-machine.sh\"   # recria com o label novo"
  fi
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
      warn "deny rule ausente: $rule — rode: bash scripts/install-global-patches.sh OU bash scripts/ideiaos-update.sh"
    fi
  done
  # Proxy de run marker: statusline IdeiaOS = ideiaos-update.sh já rodou ao menos uma vez
  if python3 -c "import json,sys; d=json.load(open('$SETTINGS')); sys.exit(0 if 'ideiaos-statusline' in str(d.get('statusLine',{}).get('command','')) else 1)" 2>/dev/null; then
    pass "ideiaos-update.sh já rodou nesta máquina (statusline presente)"
  else
    warn "ideiaos-update.sh nunca rodou nesta máquina (statusline ausente) — rode: bash scripts/ideiaos-update.sh"
  fi
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

# 7c) Secrets em texto plano na memória de projeto (padrões alta confiança)
# Não alerta sobre nomes de env var ("ANTHROPIC_API_KEY") nem prosa ("service_role isolado").
MEM_DIR="$HOME/.claude/projects"
if [ -d "$MEM_DIR" ]; then
  SECRET_HITS="$(
    /usr/bin/python3 - "$MEM_DIR" <<'PYEOF'
import re, sys
from pathlib import Path

mem = Path(sys.argv[1])

def plausible_sk(val: str) -> bool:
    if len(val) < 24 or "..." in val or "…" in val:
        return False
    low = val.lower()
    junk = ("###", "***", "redact", "placeholder", "example", "your_", "<", "changeme", "\\n", "\\t")
    # Dummies sequenciais/dicionário (fixtures de teste tipo sk-abcdEFGH1234567890...)
    # não são chaves reais: uma chave de alta entropia praticamente nunca contém
    # uma corrida sequencial longa. Check conservador — não pula chaves genuínas.
    seq = ("abcdefgh", "0123456789", "1234567890", "qwerty")
    if any(s in low for s in seq):
        return False
    return not any(j in val or j in low for j in junk)

# Valores sk-* reais ou JWT em contexto service_role — não nomes de env var nem anon keys soltas.
PATTERNS = [
    (r"sk-ant-api[a-zA-Z0-9\-_]{20,}", "anthropic_sk", None),
    (r"sk-proj-[a-zA-Z0-9\-_]{20,}", "openai_sk", None),
    (r"sk-or-v1-[a-zA-Z0-9\-_]{20,}", "openrouter_sk", None),
    (
        r"(?:ANTHROPIC|OPENAI|OPENROUTER|SUPABASE_SERVICE_ROLE)(?:_API_KEY)?\s*[=:]\s*['\"]?(sk-[a-zA-Z0-9\-_]{20,})",
        "env_sk",
        1,
    ),
    (
        r"""['\"]service_role['\"]\s*:\s*['\"](eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,})""",
        "supabase_service_role",
        1,
    ),
]
compiled = [(re.compile(p), label, grp) for p, label, grp in PATTERNS]
hits: dict[str, list[tuple[str, str]]] = {}

for fp in mem.rglob("*"):
    if not fp.is_file() or fp.suffix not in {".jsonl", ".md", ".json", ".txt"}:
        continue
    try:
        text = fp.read_text(errors="replace")[:1_000_000]
    except OSError:
        continue
    rel = fp.relative_to(mem)
    slug = rel.parts[0] if rel.parts else "?"
    for rx, label, grp in compiled:
        m = rx.search(text)
        if not m:
            continue
        val = m.group(grp) if grp else m.group(0)
        if label in ("anthropic_sk", "openai_sk", "openrouter_sk", "env_sk") and not plausible_sk(val):
            continue
        hits.setdefault(slug, []).append((str(rel), label))
        break

if hits:
    for slug, items in sorted(hits.items(), key=lambda x: -len(x[1])):
        f, label = items[0]
        print(f"HIT|{slug}|{f}|{label}|{len(items)}")
    sys.exit(1)
sys.exit(0)
PYEOF
  )"
  secret_exit=$?
  if [ "$secret_exit" -ne 0 ]; then
    while IFS='|' read -r tag slug file label count; do
      [ "$tag" = "HIT" ] || continue
      fail "secret provável em memória — slug=$slug arquivo=$file ($label; $count arquivo(s) neste projeto)"
    done <<< "$SECRET_HITS"
    warn "Remediação: inspecione ~/.claude/projects/ e remova/redija sessões com valores reais (nunca commitar secrets)"
  else
    pass "Memória de projeto sem secrets aparentes (scan alta confiança)"
  fi
fi

# 7d) scan-absorbed.sh presente (pipeline de quarentena)
if [ -x "$SETUP_DIR/security/scan-absorbed.sh" ]; then
  pass "pipeline de quarentena (security/scan-absorbed.sh) presente"
else
  warn "security/scan-absorbed.sh ausente — quarentena obrigatória não disponível"
fi

# 7e) Contenção Lovable MCP nos produtos (anti-regressão)
# O server MCP da Lovable expõe tools mutantes (deploy/publish/structural/...). O §7e EXIGE o deny das
# 18 tools MUTANTES (crédito/deploy/estrutura) no prefixo do server ATIVO (claude_ai_Lovable) — NÃO
# conta o connector-id MORTO 6f530143 (contar o server morto era o verde-falso que R15-06 matou: o
# PROBE provou deny do prefixo ativo=0 nos 4 produtos enquanto o §7e dava PASS pelo velho). v15-A-08:
# falha-fechada — produto sem deny no server ATIVO dá BAD honesto, não verde-falso. A lista aceita
# múltiplos prefixos (split "|") p/ múltiplos servers ativos; o connector morto NÃO entra.
# debt: derivar prefixo do server ativo via `claude mcp list` em vez de lista hardcoded (fora R15-06).
#
# NOTA (query_database é OPT-IN por projeto, NÃO deny-obrigatório): query_database roda SQL arbitrário
# de prod e era "deny PURO" na v1. Reclassificado: é opt-in por projeto — denied por padrão, mas
# PERMITIDO onde o projeto habilitou acesso a DB de prod (ex.: ideiapartner, 2026-06-19; o gate real
# vira a aprovação humana do SQL, não a deny-list). Por isso o threshold é 18 (as mutantes), NÃO 19:
# query_database NÃO conta como deny obrigatório. Um produto que o mantém no deny (19) também passa.
# Cada produto Lovable DEVE ter essas 18 mutantes em permissions.deny — em .claude/settings.json
# (tracked) OU .claude/settings.local.json (quando .claude é gitignored, ex.: ideiapartner). Em
# 2026-06-18 a contenção regrediu p/ 2/5 (deny uncommitted-on-main se perdeu) e ninguém notou até
# auditoria manual. Este check é a prevenção. Ref: docs/learnings/2026-06-18-uncommitted-security-config-is-ephemeral.md
DEV_DIR="$(dirname "$SETUP_DIR")"
if [ -d "$DEV_DIR" ]; then
  LOVABLE_OUT="$(
    /usr/bin/python3 - "$DEV_DIR" "$(basename "$SETUP_DIR")" "claude_ai_Lovable" "18" <<'PYEOF'
import json, sys
from pathlib import Path

dev = Path(sys.argv[1]); exclude = sys.argv[2]; prefixes = sys.argv[3].split("|"); threshold = int(sys.argv[4])  # v15-A-08: prefix-aware

def deny_count(p):
    try:
        d = json.loads(p.read_text())
    except (OSError, ValueError):
        return 0
    deny = (d.get("permissions") or {}).get("deny") or []
    return sum(1 for x in deny if isinstance(x, str) and any(p in x for p in prefixes))  # v15-A-08: conta qualquer prefixo aceito

def is_lovable(repo):
    if (repo / ".lovable").is_dir():
        return True
    for vc in repo.glob("vite.config.*"):
        try:
            t = vc.read_text(errors="replace")
        except OSError:
            continue
        if "lovable-tagger" in t or "componentTagger" in t:
            return True
    pj = repo / "package.json"
    if pj.is_file():
        try:
            if "lovable" in pj.read_text(errors="replace").lower():
                return True
        except OSError:
            pass
    return False

found = bad = 0
try:
    entries = sorted(dev.iterdir())
except OSError:
    entries = []
for repo in entries:
    if not repo.is_dir() or repo.name == exclude or not (repo / ".git").exists():
        continue
    if not is_lovable(repo):
        continue
    found += 1
    sj = deny_count(repo / ".claude" / "settings.json")
    sl = deny_count(repo / ".claude" / "settings.local.json")
    count = max(sj, sl)
    if sj >= threshold:
        src, persist = "settings.json", "tracked"
    elif sl >= threshold:
        src, persist = "settings.local.json", "local-only"
    else:
        src, persist = ("settings.json" if sj >= sl else "settings.local.json"), "missing"
    status = "OK" if count >= threshold else "BAD"
    bad += 1 if status == "BAD" else 0
    print("PROD|%s|%d|%s|%s|%s" % (repo.name, count, src, status, persist))
print("SUMMARY|%d|%d" % (found, bad))
sys.exit(0)
PYEOF
  )"
  if echo "$LOVABLE_OUT" | grep -q '^PROD'; then
    while IFS='|' read -r tag name count src status persist; do
      [ "$tag" = "PROD" ] || continue
      if [ "$status" = "OK" ]; then
        if [ "$persist" = "local-only" ]; then
          pass "Lovable MCP contido: $name (deny=$count via $src) — local-only, re-materializar após reclone"
        else
          pass "Lovable MCP contido: $name (deny=$count)"
        fi
      else
        fail "Lovable MCP SEM contenção: $name (deny=$count, esperado >=18 — as 18 tools MUTANTES; query_database é opt-in, NÃO conta) — copie as 18 mutantes de ../lapidai/.claude/settings.json p/ $name/.claude/settings.json SEM query_database (commit na branch work, NUNCA main) ou settings.local.json se .claude for gitignored"
      fi
    done <<< "$LOVABLE_OUT"
  else
    info "Nenhum produto Lovable em $DEV_DIR (check de contenção MCP n/a)"
  fi
fi

# ── 8) Contexts e shell aliases ──────────────────────────────────────────────
step "8) Contexts e funções de shell"
CONTEXTS_DIR="$HOME/.ideiaos/contexts"

# a) Presença dos 3 arquivos de context
for ctx in dev.md review.md research.md; do
  if [ -f "$CONTEXTS_DIR/$ctx" ]; then
    pass "context $ctx"
  else
    warn "context ~/.ideiaos/contexts/$ctx ausente — rode: bash scripts/ideiaos-update.sh"
  fi
done

# b) Funções de shell presentes no profile
case "${SHELL:-/bin/bash}" in */zsh) PROFILE="$HOME/.zshrc" ;; *) PROFILE="$HOME/.bashrc" ;; esac
if grep -q "claude-review()" "$PROFILE" 2>/dev/null; then
  pass "funções claude-dev/review/research no $PROFILE"
else
  warn "funções claude-dev/review/research ausentes em $PROFILE — rode: bash scripts/ideiaos-update.sh"
fi

# c) Statusline IdeiaOS no settings.json (proxy ideiaos-update.sh)
if [ -f "$SETTINGS" ]; then
  if python3 -c "import json,sys; d=json.load(open('$SETTINGS')); sys.exit(0 if 'ideiaos-statusline' in str(d.get('statusLine',{}).get('command','')) else 1)" 2>/dev/null; then
    pass "statusline IdeiaOS configurada"
  else
    warn "statusline IdeiaOS ausente em settings.json — rode: bash scripts/ideiaos-update.sh"
  fi
fi

# d) TypeScript LSP em projetos TypeScript (R3-07 — módulo typescript-lsp)
#    Só relevante quando o cwd é um projeto TS (tsconfig.json presente).
if [ -f "tsconfig.json" ] || [ -f "$(pwd)/tsconfig.json" ]; then
  if grep -q '"id": "typescript-lsp"' "$SETUP_DIR/manifests/modules.json" 2>/dev/null || grep -q '"id": "typescript-lsp"' manifests/modules.json 2>/dev/null; then
    if command -v typescript-language-server >/dev/null 2>&1 || ls "$HOME/.claude/plugins" 2>/dev/null | grep -qi "typescript-lsp\|ts-lsp"; then
      pass "typescript-lsp disponível para projeto TS"
    else
      warn "projeto TypeScript sem typescript-lsp instalado — rode: bash setup.sh --project-only . (stack:typescript ativa o LSP)"
    fi
  fi
else
  pass "typescript-lsp: n/a (projeto atual não é TypeScript)"
fi

# ── 9) Memória (v5) ───────────────────────────────────────────────────────────
# Sistema de memória compartilhada entre IDEs/máquinas via branch `planning`
# (v5). Tudo READ-ONLY: usa `git rev-parse`/`git cat-file` contra os refs já
# existentes — nunca faz checkout do planning (invariante Lovable). Checa:
#   a) branch planning alcançável (ref local OU origin/planning)
#   b) store canônico planning:.planning/memory/shared/ existe (WARN se ausente —
#      o primeiro export pode ainda não ter rodado; não é FAIL)
#   c) patches 12 (import) e 13 (export) registrados no settings.json
step "9) Memória compartilhada (v5)"
if git -C "$(pwd)" rev-parse --git-dir >/dev/null 2>&1; then
  # a) planning alcançável (local ou remoto)
  PLANNING_REF=""
  if git rev-parse --verify --quiet planning >/dev/null 2>&1; then
    PLANNING_REF="planning"
  elif git rev-parse --verify --quiet origin/planning >/dev/null 2>&1; then
    PLANNING_REF="origin/planning"
  fi
  if [ -n "$PLANNING_REF" ]; then
    pass "branch planning alcançável ($PLANNING_REF)"
    # b) store shared/ existe no planning (read-only via ls-tree; sem checkout)
    if git ls-tree --name-only "$PLANNING_REF" .planning/memory/shared/ 2>/dev/null | grep -q .; then
      MEM_N=$(git ls-tree --name-only -r "$PLANNING_REF" .planning/memory/shared/facts/ 2>/dev/null | grep -c '\.md$' || true)
      pass "store canônico $PLANNING_REF:.planning/memory/shared/ existe (${MEM_N:-0} fato(s))"
    else
      warn "$PLANNING_REF:.planning/memory/shared/ ausente — primeiro /memory-sync export ainda não rodou (não-crítico)"
    fi
  else
    warn "branch planning não alcançável (sem ref local nem origin/planning) — memória v5 inativa neste repo"
  fi
else
  info "Memória v5: cwd não é um repositório git — checagem de store n/a"
fi
# c) patches 12/13 registrados (reusa o mesmo settings.json da Seção 4)
chk "memory-import registrado (Patch 12)" "$HOME/.claude/settings.json" "memory-import.sh"
chk "memory-export registrado (Patch 13)" "$HOME/.claude/settings.json" "memory-export.sh"

# d) guard de git instalado (pre-commit/pre-merge barram memória no main) + e) varredura de vazamento no main
if git -C "$(pwd)" rev-parse --git-dir >/dev/null 2>&1; then
  GITDIR="$(git rev-parse --git-dir 2>/dev/null)"
  if [ -f "$GITDIR/hooks/pre-commit" ] && grep -q "check-memory-not-on-main" "$GITDIR/hooks/pre-commit" 2>/dev/null; then
    pass "guard git instalado (pre-commit barra memória no main)"
  else
    warn "guard git ausente — rode: bash scripts/install-git-hooks.sh (barreira anti-churn no main)"
  fi
  # e) varredura: memória vazada no main (Lovable lê main — não pode conter memória)
  MAIN_REF=""
  git rev-parse --verify --quiet main >/dev/null 2>&1 && MAIN_REF="main"
  [ -z "$MAIN_REF" ] && git rev-parse --verify --quiet origin/main >/dev/null 2>&1 && MAIN_REF="origin/main"
  if [ -n "$MAIN_REF" ]; then
    LEAK=$(git ls-tree -r --name-only "$MAIN_REF" 2>/dev/null | grep -E '\.lovable_mem_tmp\.md$|^\.planning/memory/|/memory-bridge\.mdc$' | head -3 || true)
    if [ -n "$LEAK" ]; then
      fail "VAZAMENTO de memória em $MAIN_REF (Lovable lê main): ${LEAK//$'\n'/ } — remova: git rm --cached <arquivo> + .gitignore"
    else
      pass "main limpo: sem memória vazada em $MAIN_REF"
    fi
  fi
fi

# ── 10) Membership de plugins (anti-deriva v7) ────────────────────────────────
step "10) Membership de plugins (manifesto × build-plugins.sh)"
PMCHECK="$SETUP_DIR/scripts/check-plugin-membership.sh"
if [ -f "$PMCHECK" ]; then
  if PM_OUT=$(bash "$PMCHECK" 2>&1); then
    pass "sem deriva — ${PM_OUT##*— }"
  else
    fail "deriva manifesto×build-plugins.sh: ${PM_OUT//$'\n'/ } — corrija o array + plugin-membership.md"
  fi
else
  info "check-plugin-membership.sh ausente (pulando)"
fi

# ── 11) Proveniência & superfície de skills (v11) ─────────────────────────────
step "11) Proveniência & superfície de skills"
SHCHECK="$SETUP_DIR/scripts/check-source-headers.sh"
if [ -f "$SHCHECK" ]; then
  if bash "$SHCHECK" --strict >/dev/null 2>&1; then
    pass "toda skill declara # SOURCE (ou é vendorizada via pin)"
  else
    warn "skill(s) sem # SOURCE — rode: bash scripts/check-source-headers.sh"
  fi
else
  info "check-source-headers.sh ausente (pulando)"
fi
# Orçamento de superfície: perfil default (installStrategy: always) ~15-25 skills.
# Guarda contra reinchar a superfície numa máquina fresca (cf. mcp-hygiene ≤80 tools).
SURFACE_BUDGET="${IDEIAOS_SURFACE_BUDGET:-28}"
ALWAYS_N="$(python3 -c "import json; m=json.load(open('$SETUP_DIR/manifests/modules.json')); mods=m if isinstance(m,list) else m.get('modules',[]); print(sum(1 for e in mods if e.get('kind')=='skill' and e.get('installStrategy')=='always'))" 2>/dev/null || echo '?')"
if [ "$ALWAYS_N" = "?" ]; then
  info "superfície de skills: manifesto não lido"
elif [ "$ALWAYS_N" -le "$SURFACE_BUDGET" ]; then
  pass "superfície default: $ALWAYS_N skill(s) always-on (teto $SURFACE_BUDGET; resto stack-gated/manual)"
else
  warn "superfície default INCHADA: $ALWAYS_N > $SURFACE_BUDGET always-on — stack-gate/manual em manifests/modules.json"
fi

# ── 12) Dívida técnica marcada (// debt: — v11) ──────────────────────────────
step "12) Dívida técnica marcada (debt:)"
# Marcador comment-agnóstico (// # --) para dívida CONHECIDA e aceita (operating-discipline #5).
# Escopo: código em source/ + scripts/ (não .md — evita os exemplos em prosa da própria rule).
# Exclui idea-doctor.sh (contém o próprio padrão → observer-effect; cf. secret-scanner learning).
DEBT_HITS="$(grep -rnE '(//|#|--)[[:space:]]*debt:' "$SETUP_DIR/source" "$SETUP_DIR/scripts" \
  --include='*.sh' --include='*.js' --include='*.ts' --include='*.tsx' --include='*.py' \
  2>/dev/null | grep -v '/idea-doctor.sh:' || true)"
DEBT_N="$(printf '%s' "$DEBT_HITS" | grep -c . || true)"
if [ "${DEBT_N:-0}" -eq 0 ]; then
  pass "nenhum marcador debt: pendente em source/+scripts/"
else
  warn "$DEBT_N marcador(es) debt: em source/+scripts/ — dívida conhecida (visibilidade, não bloqueia):"
  # Guard JSON_MODE: no modo --json o detalhe NÃO pode vazar p/ stdout (quebraria o JSON que o
  # collect.js parseia → snapshot com doctor.exit=-1; sintoma exposto pelo --fleet/R15-09).
  if [ "$JSON_MODE" -eq 0 ]; then
    printf '%s\n' "$DEBT_HITS" | sed "s#$SETUP_DIR/#       #" | head -10
  fi
fi

# ── 13) AI-security intel refresh (v12) ──────────────────────────────────────
step "13) AI-security intel refresh (v12)"
REFRESH_SH="$SETUP_DIR/scripts/refresh-ai-security.sh"
AISEC_SNAP="$SETUP_DIR/security/intel/awesome-ai-security.snapshot.md"
if [ ! -f "$REFRESH_SH" ]; then
  info "refresh-ai-security.sh ausente (mecanismo de intel mensal não instalado)"
elif [ ! -s "$AISEC_SNAP" ]; then
  warn "snapshot de AI-security ausente — rode: bash scripts/refresh-ai-security.sh"
else
  SNAP_EPOCH="$(stat -f %m "$AISEC_SNAP" 2>/dev/null || stat -c %Y "$AISEC_SNAP" 2>/dev/null || echo 0)"
  AGE_D=$(( ( $(date +%s) - SNAP_EPOCH ) / 86400 ))
  if [ "$AGE_D" -le 40 ]; then
    pass "snapshot AI-security fresco (${AGE_D}d ≤ 40d)"
  else
    warn "snapshot AI-security velho (${AGE_D}d > 40d) — rode: bash scripts/refresh-ai-security.sh"
  fi
  if launchctl list 2>/dev/null | grep -q "com.ideiaos.refresh-ai-security"; then
    info "LaunchAgent mensal de refresh ativo"
  else
    info "LaunchAgent mensal não carregado (opcional, per-máquina — ative na always-on; ver MONTHLY-REFRESH-SPEC.md)"
  fi
fi

# ── 14) Security freshness (selo de segurança, v13) ──────────────────────────
step "14) Security freshness (v13)"
SECFRESH_SH="$SETUP_DIR/scripts/check-security-freshness.sh"
if [ ! -f "$SECFRESH_SH" ]; then
  info "check-security-freshness.sh ausente (gate de frescor não instalado)"
else
  SF_TIER="$(bash "$SECFRESH_SH" --tier 2>/dev/null || echo erro)"
  case "$SF_TIER" in
    ok)             pass "frescor de segurança ok (revisão recente / pouca superfície tocada)" ;;
    warn)           warn "segurança DEFASADA — rode @security-reviewer no diff + bash scripts/check-security-freshness.sh --record" ;;
    egregious)      warn "segurança EGRÉGIA (atraso grande) — revise já; o tag será bloqueado quando o gate maturar (1º ciclo = advisory)" ;;
    unbootstrapped) warn "selo de segurança não-bootstrapado — rode: bash scripts/check-security-freshness.sh --bootstrap" ;;
    *)              info "frescor de segurança indeterminado (sem git ou erro)" ;;
  esac
fi

# ── 15) Cockpit (v14.1) ──────────────────────────────────────────────────────
step "15) Cockpit (v14.1)"
# Quatro checks por exit-code — mesma lógica do check-cockpit.sh + frescor do read-model:
#   (a) agentd com.ideiaos.cockpit ativo no launchctl
#   (b) refs/heads/cockpit existe neste repo
#   (c) snapshot local fresco no ref cockpit (<2 ciclos de 900s)
#   (d) frescor do read-model real (~/.ideiaos/console/read-model.db taken_epoch <2 ciclos)
#       — o estado REAL que a Bridge serve, não só o ref de origem (v14.1).
_CC_SH="$SETUP_DIR/scripts/check-cockpit.sh"
if [ ! -f "$_CC_SH" ]; then
  info "check-cockpit.sh ausente (Cockpit v14 não instalado)"
else
  # (a) agentd
  if launchctl list 2>/dev/null | grep -q 'com.ideiaos.cockpit'; then
    pass "agentd com.ideiaos.cockpit ativo"
  else
    warn "agentd não listado — LaunchAgent não carregado ou contexto sem launchd"
  fi
  # (b) ref cockpit
  if git -C "$SETUP_DIR" rev-parse --verify --quiet refs/heads/cockpit >/dev/null 2>&1; then
    _CC_TIP=$(git -C "$SETUP_DIR" rev-parse --short refs/heads/cockpit 2>/dev/null || echo "?")
    pass "ref cockpit existe (tip=$_CC_TIP)"
  else
    fail "refs/heads/cockpit ausente — rode: cockpit_write_snapshot (source/lib/cockpit.sh)"
  fi
  # (c) snapshot local fresco (<2 ciclos)
  # machine_id DEVE casar a derivação canônica do collect.js: sha256(IOPlatformUUID)[:12]
  # sobre o UUID SEM newline. Pipar `awk | shasum` direto hasheia o '\n' do `awk print`
  # → MID divergente (131fd55c… vs c706ac77…). Captura o UUID ($() trima o \n) e usa
  # `printf '%s'` p/ não reintroduzir newline. Guarda o caso UUID-vazio (não-macOS) p/
  # manter _CC_MID="" (senão printf '' | shasum daria o hash da string vazia).
  _CC_UUID=$(ioreg -rd1 -c IOPlatformExpertDevice 2>/dev/null \
    | awk -F'"' '/IOPlatformUUID/{print $4}')
  if [ -n "$_CC_UUID" ]; then
    _CC_MID=$(printf '%s' "$_CC_UUID" | shasum -a 256 | cut -c1-12 2>/dev/null || true)
  else
    _CC_MID=""
  fi
  if [ -z "$_CC_MID" ]; then
    warn "machine_id indisponível — IOPlatformUUID ausente (não-macOS?)"
  else
    _CC_SNAP=$(git -C "$SETUP_DIR" show "cockpit:snapshots/${_CC_MID}.json" 2>/dev/null || true)
    if [ -z "$_CC_SNAP" ]; then
      warn "snapshot de ${_CC_MID} ausente no ref cockpit"
    else
      _CC_EPOCH=$(printf '%s' "$_CC_SNAP" \
        | python3 -c 'import json,sys;print(json.load(sys.stdin).get("taken_epoch",""))' \
        2>/dev/null || echo "")
      if [ -z "$_CC_EPOCH" ]; then
        warn "taken_epoch ausente no snapshot de ${_CC_MID}"
      else
        _CC_NOW="$(date +%s)"
        _CC_AGE=$(( _CC_NOW - _CC_EPOCH ))
        _CC_MAX=1800   # 2 ciclos × 900s
        if [ "$_CC_AGE" -le "$_CC_MAX" ]; then
          pass "snapshot de ${_CC_MID} fresco (age=${_CC_AGE}s ≤ ${_CC_MAX}s)"
        else
          warn "snapshot defasado (age=${_CC_AGE}s > ${_CC_MAX}s) — aguardar próximo ciclo agentd"
        fi
      fi
    fi
  fi
  # (d) frescor do READ-MODEL real (v14.1): o estado que a Bridge serve.
  #     ~/.ideiaos/console/read-model.db é um CACHE reconstrutível (invariante A5);
  #     aqui checamos só o taken_epoch do machine_snapshot desta máquina (<2 ciclos).
  #     Sem sqlite3 / sem DB / sem linha desta máquina → warn (degradação graciosa,
  #     nunca fail: o read-model é descartável e pode não ter rodado nesta máquina).
  _CC_RM_DB="$HOME/.ideiaos/console/read-model.db"
  if ! command -v sqlite3 >/dev/null 2>&1; then
    info "sqlite3 ausente — frescor do read-model não verificável (cache descartável)"
  elif [ ! -s "$_CC_RM_DB" ]; then
    warn "read-model.db ausente — rode: node source/console/ingest.js (cache reconstrutível, A5)"
  elif [ -z "$_CC_MID" ]; then
    info "machine_id indisponível — frescor do read-model não verificável nesta máquina"
  else
    _CC_RM_EPOCH=$(sqlite3 "$_CC_RM_DB" \
      "SELECT MAX(taken_epoch) FROM machine_snapshot WHERE machine_id='${_CC_MID}';" \
      2>/dev/null || echo "")
    if [ -z "$_CC_RM_EPOCH" ] || [ "$_CC_RM_EPOCH" = "" ]; then
      warn "read-model sem snapshot de ${_CC_MID} — rode ingest após o próximo ciclo agentd"
    else
      _CC_RM_NOW="$(date +%s)"
      _CC_RM_AGE=$(( _CC_RM_NOW - _CC_RM_EPOCH ))
      _CC_RM_MAX=1800   # 2 ciclos × 900s
      if [ "$_CC_RM_AGE" -le "$_CC_RM_MAX" ]; then
        pass "read-model fresco (${_CC_MID}: age=${_CC_RM_AGE}s ≤ ${_CC_RM_MAX}s)"
      else
        warn "read-model defasado (${_CC_MID}: age=${_CC_RM_AGE}s > ${_CC_RM_MAX}s) — re-ingest"
      fi
    fi
  fi
fi

# ── Resumo ────────────────────────────────────────────────────────────────────
if [ "$JSON_MODE" -eq 0 ]; then
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
fi

# >>> JSON_SINK_BEGIN
# Assembler JSON ideiaos-doctor/v1 — sem jq/python no runtime; bash 3.2; set -uo pipefail.
# Montado por concatenação de strings dos arrays SEC_* / ITEM_* acumulados durante a execução.
# summary.exit é idêntico ao exit-code ANSI: 0 se FAIL==0, senão 1.

_json_summary_exit=0
[ "$FAIL" -gt 0 ] && _json_summary_exit=1

# Constrói sections[] — iterar arrays com guard bash 3.2 (set -u: array vazio aborta sem guard)
_sections_json=""
_sec_count="${#SEC_ID[@]}"
_i=0
while [ "$_i" -lt "$_sec_count" ]; do
  _sid="${SEC_ID[$_i]}"
  _stitle="${SEC_TITLE[$_i]}"

  # Coleta itens desta seção e determina status (pior item: fail > warn > pass/info = ok)
  _sec_ok=0; _sec_warn=0; _sec_fail=0
  _items_json=""
  _item_count="${#ITEM_SEC[@]}"
  _j=0
  while [ "$_j" -lt "$_item_count" ]; do
    if [ "${ITEM_SEC[$_j]}" = "$_sid" ]; then
      _lvl="${ITEM_LEVEL[$_j]}"
      _msg="${ITEM_MSG[$_j]}"
      [ -n "$_items_json" ] && _items_json="${_items_json},"
      _items_json="${_items_json}{\"level\":\"${_lvl}\",\"msg\":\"${_msg}\"}"
      case "$_lvl" in
        pass) _sec_ok=$((_sec_ok+1)) ;;
        warn) _sec_warn=$((_sec_warn+1)) ;;
        fail) _sec_fail=$((_sec_fail+1)) ;;
      esac
    fi
    _j=$((_j+1))
  done

  # Status da seção: FAIL se qualquer fail, WARN se qualquer warn, OK caso contrário
  _sec_status="OK"
  [ "$_sec_warn" -gt 0 ] && _sec_status="WARN"
  [ "$_sec_fail" -gt 0 ] && _sec_status="FAIL"

  [ -n "$_sections_json" ] && _sections_json="${_sections_json},"
  _sections_json="${_sections_json}{\"id\":\"${_sid}\",\"titulo\":\"${_stitle}\",\"status\":\"${_sec_status}\",\"counts\":{\"ok\":${_sec_ok},\"warn\":${_sec_warn},\"fail\":${_sec_fail}},\"itens\":[${_items_json}]}"
  _i=$((_i+1))
done

_generated_epoch="$(date +%s)"
_repo_escaped="$(json_escape "$SETUP_DIR")"

printf '{"schema":"ideiaos-doctor/v1","generated_epoch":%s,"repo":"%s","sections":[%s],"summary":{"ok":%d,"warn":%d,"fail":%d,"exit":%d}}\n' \
  "$_generated_epoch" "$_repo_escaped" "$_sections_json" \
  "$PASS" "$WARN" "$FAIL" "$_json_summary_exit"

exit "$_json_summary_exit"
# <<< JSON_SINK_END
