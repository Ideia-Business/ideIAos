#!/usr/bin/env bash
# =============================================================================
# install-global-patches.sh — IdeiaOS overlay sobre componentes globais
#
# Aplica os patches IdeiaOS (Caminho C — Composição AIOX × GSD) sobre arquivos
# globais do Claude Code, GSD plugin e AIOX-core. **Idempotente:** detecta cada
# patch antes de aplicar — pode rodar 100x consecutivas sem alterar nada.
#
# Patches aplicados:
#   1. ~/.claude/skills/gsd-plan-phase/SKILL.md          — flag --story
#   2. ~/.claude/get-shit-done/workflows/plan-phase.md   — STORY_MODE pipeline
#   3. ~/.claude/hooks/extract-learnings-reminder.sh     — 3 gatilhos Fase A
#   4. ~/.claude/settings.json                            — matcher Bash|Write|Edit|MultiEdit
#   5. .aiox-core/.../agents/qa.md                       — *gate --verification
#   6. .aiox-core/.../tasks/qa-gate.md                   — IdeiaOS Composition
#   7. ~/.claude/skills/design-system/SKILL.md           — OKLCH (--brand-hue)
#   8. ~/.claude/hooks/git-sync-check.sh + settings.json — SessionStart fast-forward cross-máquina
#   9. ~/.config/git/ignore                               — gitignore global (settings.local.json, .DS_Store)
#
# Uso:
#   bash scripts/install-global-patches.sh
#
# Detecção de presença usa marcadores únicos (strings que só aparecem se o
# patch foi aplicado). Se um upstream sobrescreveu o arquivo, o detector
# retorna "ausente" e o patch é re-aplicado.
# =============================================================================
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES_DIR="$SETUP_DIR/templates/global-patches"

# ── Cores ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
skip() { echo -e "${CYAN}  ⊙${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
step() { echo -e "\n${CYAN}${BOLD}━━━ $* ━━━${NC}"; }

# Contadores pra resumo final
APPLIED=0
SKIPPED=0
FAILED=0

# ── Localizador AIOX-core ────────────────────────────────────────────────────
# AIOX-core é instalado via CLI npm; localização padrão é Projects/.aiox-core/
# mas pode variar. Procura no diretório-pai do IdeiaOS.
find_aiox_core() {
  local candidates=(
    "$(dirname "$SETUP_DIR")/.aiox-core"
    "$HOME/Projects/.aiox-core"
  )
  for c in "${candidates[@]}"; do
    [ -d "$c/development/agents" ] && { echo "$c"; return 0; }
  done
  return 1
}

# ── PATCH 1: gsd-plan-phase SKILL.md ─────────────────────────────────────────
# Adiciona `--story <file>` ao argument-hint e à seção de Flags.
patch_gsd_skill() {
  local target="$HOME/.claude/skills/gsd-plan-phase/SKILL.md"

  if [ ! -f "$target" ]; then
    warn "Patch 1 (gsd-plan-phase SKILL.md): arquivo ausente — GSD plugin instalado?"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  if grep -qF -- "--story <file>" "$target"; then
    skip "Patch 1: --story já presente em gsd-plan-phase/SKILL.md"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  # 1a) Adicionar [--story <file>] na linha argument-hint após [--prd <file>]
  python3 - "$target" <<'PY'
import sys, re, io
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
orig = s

# Header argument-hint
s = re.sub(
    r'(argument-hint:.*?\[--prd <file>\])(\s*\[--reviews\])',
    r'\1 [--story <file>]\2',
    s
)

# Flag list — após linha do --prd, adicionar a do --story
marker_prd = "- `--prd <file>` — Use a PRD/acceptance criteria file"
if marker_prd in s and "- `--story <file>`" not in s:
    insertion = (
        "\n- `--story <file>` — IdeiaOS composition: use an AIOX story file "
        "(`docs/stories/*.story.md`) as source. Acceptance Criteria from the "
        "story become the goal-backward verification points in PLAN.md. Header "
        "references the story. Equivalent to `--prd` but with story-aware parsing."
    )
    # Inserir após a linha completa do --prd (acha quebra de linha após o marker)
    idx = s.index(marker_prd)
    nl = s.index("\n", idx)
    s = s[:nl] + insertion + s[nl:]

if s != orig:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    sys.exit(0)
sys.exit(1)
PY

  if grep -qF -- "--story <file>" "$target"; then
    ok "Patch 1: --story aplicado em gsd-plan-phase/SKILL.md"
    APPLIED=$((APPLIED+1))
  else
    err "Patch 1: falha ao aplicar (marcadores upstream mudaram?)"
    FAILED=$((FAILED+1))
  fi
}

# ── PATCH 2: GSD workflow plan-phase.md ──────────────────────────────────────
# Adiciona STORY_MODE pipeline (3 inserções no workflow).
patch_gsd_workflow() {
  local target="$HOME/.claude/get-shit-done/workflows/plan-phase.md"

  if [ ! -f "$target" ]; then
    warn "Patch 2 (GSD workflow plan-phase.md): arquivo ausente"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  if grep -q "STORY_MODE" "$target"; then
    skip "Patch 2: STORY_MODE já presente em workflows/plan-phase.md"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  python3 - "$target" <<'PY'
import sys, re
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
orig = s

# 2a) Mention --story na lista de flags do Step 2
m = re.search(
    r"(Extract from \$ARGUMENTS: phase number \(integer or decimal like `2\.1`\), flags \()(`--research`, `--skip-research`, `--gaps`, `--skip-verify`, `--skip-ui`, `--prd <filepath>`)(, `--reviews`)",
    s
)
if m and "--story <filepath>" not in m.group(0):
    s = s.replace(m.group(2), m.group(2) + ", `--story <filepath>`")

# 2b) Após linha "Extract `--prd <filepath>` from $ARGUMENTS." adicionar bloco --story
prd_extract = "Extract `--prd <filepath>` from $ARGUMENTS. If present, set PRD_FILE to the filepath."
if prd_extract in s and "Extract `--story <filepath>`" not in s:
    block = (
        "\n\nExtract `--story <filepath>` from $ARGUMENTS. If present, set "
        "STORY_FILE to the filepath, set PRD_FILE to the same value (story "
        "is parsed via the PRD pipeline), and set STORY_MODE=true. `--story` "
        "and `--prd` are mutually exclusive — if both are passed, error and "
        "exit. This is the IdeiaOS composition entry point: an AIOX story "
        "(`docs/stories/{epicNum}.{storyNum}.story.md`) becomes the source "
        "of acceptance criteria for goal-backward verification."
    )
    idx = s.index(prd_extract) + len(prd_extract)
    s = s[:idx] + block + s[idx:]

# 2c) Marcar a seção 3.5 com STORY_MODE no header
s = s.replace(
    "## 3.5. Handle PRD Express Path\n",
    "## 3.5. Handle PRD Express Path (also handles `--story` via STORY_MODE)\n",
    1
)

# 2d) Estender skip condition do step 3.5
s = s.replace(
    "**Skip if:** No `--prd` flag in arguments.",
    "**Skip if:** No `--prd` flag AND no `--story` flag in arguments.",
    1
)

# 2e) Adicionar bullet sobre AIOX story parsing após "extracted from PRD"
ac_marker = (
    "   - Extract all requirements, user stories, acceptance criteria, "
    "and constraints from the source"
)
old_marker = (
    "   - Extract all requirements, user stories, acceptance criteria, "
    "and constraints from the PRD"
)
if old_marker in s and ac_marker not in s:
    s = s.replace(old_marker, ac_marker)

story_note = (
    "   - **If STORY_MODE=true:** prioritize parsing the `## Acceptance Criteria` "
    "section (AIOX story format). Each AC becomes a locked decision AND a "
    "goal-backward verification point in PLAN.md. Treat `## Tasks/Subtasks`, "
    "`## Dev Notes`, and `## Testing` as canonical refs. Story title becomes "
    "phase scope statement.\n"
)
if "If STORY_MODE=true:" not in s:
    s = s.replace(ac_marker + "\n", ac_marker + "\n" + story_note, 1)

if s != orig:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    sys.exit(0)
sys.exit(1)
PY

  if grep -q "STORY_MODE" "$target"; then
    ok "Patch 2: STORY_MODE pipeline aplicado em workflows/plan-phase.md"
    APPLIED=$((APPLIED+1))
  else
    err "Patch 2: falha ao aplicar (marcadores upstream mudaram?)"
    FAILED=$((FAILED+1))
  fi
}

# ── PATCH 3: hook extract-learnings-reminder.sh ──────────────────────────────
# Substitui o script inteiro pela versão com 3 gatilhos (Fase A composition).
patch_extract_hook() {
  local target="$HOME/.claude/hooks/extract-learnings-reminder.sh"
  local source="$PATCHES_DIR/extract-learnings-reminder.sh"

  if [ ! -f "$source" ]; then
    err "Patch 3: template ausente em $source"
    FAILED=$((FAILED+1))
    return 0
  fi

  mkdir -p "$(dirname "$target")"

  if [ -f "$target" ] && grep -q "qa-gate-pass" "$target"; then
    skip "Patch 3: 3-gatilhos já presente em extract-learnings-reminder.sh"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  cp "$source" "$target"
  chmod +x "$target"
  ok "Patch 3: extract-learnings-reminder.sh instalado (3 gatilhos)"
  APPLIED=$((APPLIED+1))
}

# ── PATCH 4: settings.json — matcher Bash|Write|Edit|MultiEdit ───────────────
# Garante que a entry do hook extract-learnings tem matcher expandido.
patch_settings_json() {
  local target="$HOME/.claude/settings.json"

  if [ ! -f "$target" ]; then
    warn "Patch 4: ~/.claude/settings.json não existe — pular"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  local result_str
  result_str=$(python3 - "$target" <<'PY'
import json, sys, os
path = sys.argv[1]
target_matcher = "Bash|Write|Edit|MultiEdit"
hook_marker = "extract-learnings-reminder.sh"

try:
    with open(path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)
except Exception as e:
    print(f"FAILED: {e}", file=sys.stderr)
    sys.exit(2)

hooks = cfg.get("hooks", {})
post = hooks.get("PostToolUse", [])

changed = False
found_entry = False
for entry in post:
    cmds = entry.get("hooks", [])
    for h in cmds:
        if hook_marker in h.get("command", ""):
            found_entry = True
            if entry.get("matcher") != target_matcher:
                entry["matcher"] = target_matcher
                changed = True
            break

if not found_entry:
    home = os.path.expanduser('~/.claude/hooks/extract-learnings-reminder.sh')
    post.append({
        "matcher": target_matcher,
        "hooks": [{
            "type": "command",
            "command": f'bash "{home}"',
            "timeout": 5
        }]
    })
    hooks["PostToolUse"] = post
    cfg["hooks"] = hooks
    changed = True

if changed:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print("APPLIED")
else:
    print("SKIPPED")
PY
)
  local py_exit=$?

  if [ $py_exit -ne 0 ]; then
    err "Patch 4: Python falhou ao processar settings.json"
    FAILED=$((FAILED+1))
    return 0
  fi

  case "$result_str" in
    APPLIED)
      ok "Patch 4: settings.json — matcher Bash|Write|Edit|MultiEdit aplicado"
      APPLIED=$((APPLIED+1))
      ;;
    SKIPPED)
      skip "Patch 4: settings.json — matcher já está correto"
      SKIPPED=$((SKIPPED+1))
      ;;
    *)
      err "Patch 4: resposta Python inesperada: $result_str"
      FAILED=$((FAILED+1))
      ;;
  esac
}

# ── PATCH 5: AIOX-core agents/qa.md ──────────────────────────────────────────
patch_aiox_qa_agent() {
  local aiox_root
  aiox_root="$(find_aiox_core)" || {
    warn "Patch 5: AIOX-core não localizado — pular"
    SKIPPED=$((SKIPPED+1))
    return 0
  }
  local target="$aiox_root/development/agents/qa.md"

  if [ ! -f "$target" ]; then
    warn "Patch 5: $target ausente"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  if grep -qF -- "--verification <path>" "$target"; then
    skip "Patch 5: --verification já presente em AIOX-core qa.md"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  python3 - "$target" <<'PY'
import sys, re
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
orig = s

# Substituir definição do command gate
old = (
    "  - name: gate\n"
    "    visibility: [full, quick]\n"
    "    args: '{story}'\n"
    "    description: 'Create quality gate decision'\n"
)
new = (
    "  - name: gate\n"
    "    visibility: [full, quick]\n"
    "    args: '{story} [--verification <path>]'\n"
    "    description: 'Create quality gate decision. With --verification <path> "
    "(IdeiaOS composition), AC already marked ✅ in the GSD VERIFICATION.md are "
    "assumed verified and qa-gate complements (does not duplicate) with "
    "stakeholder/format checks.'\n"
)
if old in s:
    s = s.replace(old, new)

if s != orig:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    sys.exit(0)
sys.exit(1)
PY

  if grep -qF -- "--verification <path>" "$target"; then
    ok "Patch 5: --verification aplicado em AIOX-core qa.md"
    APPLIED=$((APPLIED+1))
  else
    err "Patch 5: falha ao aplicar (marcadores upstream mudaram?)"
    FAILED=$((FAILED+1))
  fi
}

# ── PATCH 6: AIOX-core tasks/qa-gate.md ──────────────────────────────────────
patch_aiox_qa_task() {
  local aiox_root
  aiox_root="$(find_aiox_core)" || {
    SKIPPED=$((SKIPPED+1))
    return 0
  }
  local target="$aiox_root/development/tasks/qa-gate.md"

  if [ ! -f "$target" ]; then
    warn "Patch 6: $target ausente"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  if grep -qF "Optional Input — IdeiaOS Composition" "$target"; then
    skip "Patch 6: bloco IdeiaOS Composition já presente em AIOX-core qa-gate.md"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  python3 - "$target" <<'PY'
import sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    s = f.read()
orig = s

anchor = "- Understanding of story requirements and implementation"
block = """

## Optional Input — IdeiaOS Composition (`--verification <path>`)

When invoked as `*gate {story} --verification <path>`, the gate accepts a GSD-produced VERIFICATION.md as evidence of AC-level verification. This is the second contract of the IdeiaOS AIOX × GSD composition (the first being `/gsd-plan-phase --story <path>`).

**Skip-if-verified rule:**

For each AC in the story:
1. Look up the matching entry in `VERIFICATION.md` (matched by AC number or text).
2. If marked `✅ verificado` with evidence (commit hash, test name, screenshot path, or RPC result) → **assume verified**, do not re-execute the check.
3. If marked `❌ pendente` or `⚠️ partial` → **treat as a finding** in the gate report (severity inherited from VERIFICATION.md if present, else `high` by default).
4. If absent from VERIFICATION.md → **execute the standard check** (no shortcut).

**What qa-gate ADDS on top of VERIFICATION.md (does NOT duplicate):**

- Stakeholder-format checks (story is well-formed, AC traceable, Definition of Done met).
- NFR validation not covered by GSD goal-backward (security audit, performance baseline, accessibility).
- Risk profile and blast radius reasoning.
- Final PASS/CONCERNS/FAIL/WAIVED verdict and status transition (InReview → Done on PASS).

**Output augmentation when `--verification` is used:**

The generated gate YAML MUST include a `verification_source` field referencing the GSD verification:

```yaml
schema: 1
story: '4.2'
gate: PASS
verification_source: '.planning/phases/04-oauth/04-VERIFICATION.md'
verification_summary:
  ac_total: 8
  ac_verified_in_gsd: 6
  ac_re_executed: 2
  ac_with_findings: 0
reviewer: 'Quinn'
...
```

This makes the audit trail explicit: which AC were trusted from GSD verification, which were re-executed, and which produced new findings.
"""

if anchor in s and "Optional Input — IdeiaOS Composition" not in s:
    idx = s.index(anchor) + len(anchor)
    s = s[:idx] + block + s[idx:]

if s != orig:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    sys.exit(0)
sys.exit(1)
PY

  if grep -qF "Optional Input — IdeiaOS Composition" "$target"; then
    ok "Patch 6: bloco IdeiaOS Composition aplicado em AIOX-core qa-gate.md"
    APPLIED=$((APPLIED+1))
  else
    err "Patch 6: falha ao aplicar"
    FAILED=$((FAILED+1))
  fi
}

# ── Main ─────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════════╗"
echo    "║     IdeiaOS — install-global-patches.sh (Caminho C)     ║"
echo -e "╚══════════════════════════════════════════════════════════╝${NC}"
echo -e "  Setup dir   : ${BOLD}$SETUP_DIR${NC}"
echo -e "  Patches dir : ${BOLD}$PATCHES_DIR${NC}"

# ── PATCH 7: design-system OKLCH tokens (overlay sobre suíte de terceiros) ─────
# A Suíte de Design (ui-ux-pro-max, design-system...) vem do repo externo
# nextlevelbuilder, fora do IdeiaOS. Este patch injeta o suporte a tokens OKLCH
# (--brand-hue) no design-system global de forma idempotente, sobrevivendo a
# reinstalações/atualizações do upstream.
patch_design_system_oklch() {
  local skill="$HOME/.claude/skills/design-system"
  local target="$skill/SKILL.md"
  local refs="$skill/references"
  local tmpl="$PATCHES_DIR/oklch-tokens.md"

  if [ ! -f "$target" ]; then
    warn "Patch 7 (design-system OKLCH): Suíte de Design ausente — instale ui-ux-pro-max-skill e re-rode"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  if [ ! -f "$tmpl" ]; then
    err "Patch 7: template oklch-tokens.md não encontrado em $PATCHES_DIR"
    FAILED=$((FAILED+1))
    return 0
  fi

  # Doc de referência: cópia idempotente (sempre garante a versão mais recente)
  mkdir -p "$refs"
  cp "$tmpl" "$refs/oklch-tokens.md"

  if grep -qF "oklch-tokens.md" "$target"; then
    skip "Patch 7: design-system já referencia OKLCH"
    SKIPPED=$((SKIPPED+1))
    return 0
  fi

  python3 - "$target" <<'PYOK'
import sys
path = sys.argv[1]
with open(path, encoding='utf-8') as f:
    s = f.read()
orig = s

anchor = "| Primitive Tokens | `references/primitive-tokens.md` |"
if anchor in s and "oklch-tokens.md" not in s:
    s = s.replace(anchor, anchor + "\n| **OKLCH Tokens (`--brand-hue`)** | `references/oklch-tokens.md` |", 1)

a2 = "- Design token creation"
if a2 in s and "OKLCH color palettes" not in s:
    s = s.replace(a2, a2 + "\n- **OKLCH color palettes derived from a single `--brand-hue`** (see `references/oklch-tokens.md`)", 1)

if s != orig:
    with open(path, 'w', encoding='utf-8') as f:
        f.write(s)
    print("APPLIED")
else:
    print("NOCHANGE")
PYOK

  if grep -qF "oklch-tokens.md" "$target"; then
    ok "Patch 7: design-system OKLCH (--brand-hue) aplicado"
    APPLIED=$((APPLIED+1))
  else
    warn "Patch 7: doc OKLCH copiado, mas SKILL.md sem âncoras esperadas (upstream mudou?) — ref disponível em references/oklch-tokens.md"
    SKIPPED=$((SKIPPED+1))
  fi
}

# ── PATCH 8: SessionStart git-sync-check.sh ──────────────────────────────────
# Instala o guard de sincronização git e o registra como 1º SessionStart hook.
# Comportamento: fetch + fast-forward automático quando o tree está limpo e
# estritamente atrás do upstream; senão, apenas avisa. Fecha o gap cross-máquina
# (iMac ↔ MacBook) em que a IA lia STATE.md/handoff de um working tree velho.
patch_git_sync() {
  local target="$HOME/.claude/hooks/git-sync-check.sh"
  local source="$PATCHES_DIR/git-sync-check.sh"

  if [ ! -f "$source" ]; then
    err "Patch 8: template ausente em $source"
    FAILED=$((FAILED+1))
    return 0
  fi

  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ] && diff -q "$source" "$target" &>/dev/null; then
    skip "Patch 8: git-sync-check.sh já está na versão mais recente"
    SKIPPED=$((SKIPPED+1))
  else
    cp "$source" "$target"
    chmod +x "$target"
    ok "Patch 8: git-sync-check.sh instalado → $target"
    APPLIED=$((APPLIED+1))
  fi

  # Registro idempotente em settings.json (SessionStart, como 1ª entrada).
  local settings="$HOME/.claude/settings.json"
  if [ ! -f "$settings" ]; then
    warn "Patch 8: ~/.claude/settings.json não existe — registre git-sync-check manualmente em hooks.SessionStart"
    return 0
  fi

  local result_str
  result_str=$(python3 - "$settings" <<'PY'
import json, sys, os
path = sys.argv[1]
marker = "git-sync-check.sh"
home = os.path.expanduser('~/.claude/hooks/git-sync-check.sh')

try:
    with open(path, 'r', encoding='utf-8') as f:
        cfg = json.load(f)
except Exception as e:
    print(f"FAILED: {e}", file=sys.stderr)
    sys.exit(2)

hooks = cfg.setdefault("hooks", {})
ss = hooks.get("SessionStart", [])

for entry in ss:
    for h in entry.get("hooks", []):
        if marker in h.get("command", ""):
            print("SKIPPED")
            sys.exit(0)

# Insere como PRIMEIRA entrada — sincroniza antes dos demais SessionStart lerem estado.
ss.insert(0, {
    "hooks": [{
        "type": "command",
        "command": f'bash "{home}"',
        "timeout": 15
    }]
})
hooks["SessionStart"] = ss
cfg["hooks"] = hooks

with open(path, 'w', encoding='utf-8') as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
    f.write('\n')
print("APPLIED")
PY
)
  local py_exit=$?

  if [ $py_exit -ne 0 ]; then
    err "Patch 8: Python falhou ao registrar git-sync-check em settings.json"
    FAILED=$((FAILED+1))
    return 0
  fi

  case "$result_str" in
    APPLIED)
      ok "Patch 8: git-sync-check registrado em settings.json (SessionStart, 1ª entrada)"
      APPLIED=$((APPLIED+1)) ;;
    SKIPPED)
      skip "Patch 8: git-sync-check já registrado em settings.json"
      SKIPPED=$((SKIPPED+1)) ;;
    *)
      err "Patch 8: resposta Python inesperada: $result_str"
      FAILED=$((FAILED+1)) ;;
  esac
}

# ── PATCH 9: gitignore global (arquivos locais por-máquina) ──────────────────
# ~/.config/git/ignore (caminho XDG padrão do git, sem precisar de core.excludesfile).
# Sem isto, .claude/settings.local.json deixa o working tree "sujo" e o git-autosync
# (proteção dirty em main) PULA o pull — repo fica atrás em silêncio cross-máquina.
patch_global_gitignore() {
  local target="$HOME/.config/git/ignore"
  local entries=(".claude/settings.local.json" ".DS_Store")
  mkdir -p "$(dirname "$target")"
  [ -f "$target" ] || printf '# Git global ignore (IdeiaOS) — arquivos locais por-máquina, nunca versionados.\n' > "$target"
  local added=0
  local e
  for e in "${entries[@]}"; do
    grep -qxF -- "$e" "$target" 2>/dev/null || { printf '%s\n' "$e" >> "$target"; added=$((added+1)); }
  done
  if [ "$added" -gt 0 ]; then
    ok "Patch 9: gitignore global (~/.config/git/ignore) — +$added entrada(s)"
    APPLIED=$((APPLIED+1))
  else
    skip "Patch 9: gitignore global já tem as entradas"
    SKIPPED=$((SKIPPED+1))
  fi
}

# ── PATCH 10: deny rules baseline em settings.json ───────────────────────────
# Fecha superfície de ataque da config (CVE-2025-59536, CVE-2026-21852).
# Decisão PROJECT.md: security como infra. ssh/scp = "ask" (não bloquear SSH legítimo).
patch_deny_rules() {
  local target="$HOME/.claude/settings.json"
  if [ ! -f "$target" ]; then
    warn "Patch 10: ~/.claude/settings.json não existe — pular"
    SKIPPED=$((SKIPPED+1)); return 0
  fi
  local result_str
  result_str=$(python3 - "$target" <<'PY'
import json, sys
path = sys.argv[1]
DENY = ["Read(~/.ssh/**)","Read(~/.aws/**)","Read(**/.env*)",
        "Write(~/.ssh/**)","Bash(curl * | bash)","Bash(nc *)"]
ASK  = ["Bash(ssh *)","Bash(scp *)"]
with open(path) as f: cfg = json.load(f)
perms = cfg.setdefault("permissions", {})
deny = perms.setdefault("deny", [])
ask  = perms.setdefault("ask", [])
added = 0
for r in DENY:
    if r not in deny: deny.append(r); added += 1
for r in ASK:
    if r not in ask and r not in deny: ask.append(r); added += 1
if added:
    with open(path, "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False); f.write("\n")
    print(f"APPLIED:{added}")
else:
    print("SKIPPED")
PY
)
  case "$result_str" in
    APPLIED:*) ok "Patch 10: deny rules baseline (${result_str#APPLIED:} regra(s))"; APPLIED=$((APPLIED+1)) ;;
    SKIPPED)   skip "Patch 10: deny rules já presentes"; SKIPPED=$((SKIPPED+1)) ;;
    *)         err "Patch 10: Python falhou ($result_str)"; FAILED=$((FAILED+1)) ;;
  esac
}

step "Patch 1/10: --story em gsd-plan-phase SKILL.md"
patch_gsd_skill

step "Patch 2/10: STORY_MODE em workflows/plan-phase.md"
patch_gsd_workflow

step "Patch 3/10: 3 gatilhos em extract-learnings-reminder.sh"
patch_extract_hook

step "Patch 4/10: matcher expandido em settings.json"
patch_settings_json

step "Patch 5/10: --verification em AIOX-core agents/qa.md"
patch_aiox_qa_agent

step "Patch 6/10: IdeiaOS Composition em AIOX-core tasks/qa-gate.md"
patch_aiox_qa_task

step "Patch 7/10: OKLCH (--brand-hue) em design-system SKILL.md"
patch_design_system_oklch

step "Patch 8/10: SessionStart git-sync-check (auto fast-forward cross-máquina)"
patch_git_sync

step "Patch 9/10: gitignore global (settings.local.json + .DS_Store)"
patch_global_gitignore

step "Patch 10/10: deny rules baseline em settings.json"
patch_deny_rules

# ── Resumo ───────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}━━━ Resumo ━━━${NC}"
echo -e "  ${GREEN}Aplicados:${NC} $APPLIED"
echo -e "  ${CYAN}Pulados (já presentes):${NC} $SKIPPED"
echo -e "  ${RED}Falhas:${NC} $FAILED"

if [ "$FAILED" -gt 0 ]; then
  echo -e "\n${YELLOW}⚠ Alguns patches falharam. Possíveis causas:${NC}"
  echo "  • Upstream renomeou marcadores que o detector procurava"
  echo "  • Arquivo está em formato inesperado"
  echo "  • Pode requerer adaptação manual do script"
  exit 1
fi

if [ "$APPLIED" -gt 0 ]; then
  echo -e "\n${YELLOW}⚠ Reinicie o Claude Code para os hooks atualizados surtirem efeito.${NC}"
fi

exit 0
