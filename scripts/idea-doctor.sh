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
# O server MCP da Lovable (prefixo 6f530143) expõe 19 tools mutantes (deploy/publish/db-write/...).
# Cada produto Lovable DEVE ter essas 19 em permissions.deny — em .claude/settings.json (tracked) OU
# .claude/settings.local.json (quando .claude é gitignored, ex.: ideiapartner). Em 2026-06-18 a
# contenção regrediu p/ 2/5 (deny uncommitted-on-main se perdeu) e ninguém notou até auditoria manual.
# Este check é a prevenção. Ref: docs/learnings/2026-06-18-uncommitted-security-config-is-ephemeral.md
DEV_DIR="$(dirname "$SETUP_DIR")"
if [ -d "$DEV_DIR" ]; then
  LOVABLE_OUT="$(
    /usr/bin/python3 - "$DEV_DIR" "$(basename "$SETUP_DIR")" "6f530143" "19" <<'PYEOF'
import json, sys
from pathlib import Path

dev = Path(sys.argv[1]); exclude = sys.argv[2]; prefix = sys.argv[3]; threshold = int(sys.argv[4])

def deny_count(p):
    try:
        d = json.loads(p.read_text())
    except (OSError, ValueError):
        return 0
    deny = (d.get("permissions") or {}).get("deny") or []
    return sum(1 for x in deny if isinstance(x, str) and prefix in x)

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
        fail "Lovable MCP SEM contenção: $name (deny=$count, esperado >=19) — copie .permissions.deny de ../lapidai/.claude/settings.json p/ $name/.claude/settings.json (commit na branch work, NUNCA main) ou settings.local.json se .claude for gitignored"
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
  printf '%s\n' "$DEBT_HITS" | sed "s#$SETUP_DIR/#       #" | head -10
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
