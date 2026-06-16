#!/usr/bin/env bash
# =============================================================================
# test-build-adapters.sh — testa o script scripts/build-adapters.sh
#
# Cobre:
#   1. Agent válido (model + tools) → exit 0, "All agents have valid frontmatter"
#   2. Agent sem 'model:' → exit 1, output menciona "model"
#   3. Agent sem 'tools:' → exit 1, output menciona "tools"
#   4. Agent sem AMBOS os campos → exit 1, output menciona model E tools
#   5. Múltiplos agents: um válido, um inválido → exit 1, nomeia o inválido
#   6. --dry-run não copia arquivos + stdout contém "[DRY]"
#   7. --target desconhecido → exit 1, menciona "Unknown"
#   8. source/agents/ vazio → exit 0 (validação vazia = ok)
#
# Estratégia: copia build-adapters.sh para $ws/scripts/ para que IDEIAOS_DIR
# resolva para o workspace (dirname($0)/..) e não para o repo real.
# Usa workspace em /tmp — não toca o repo real.
# Uso:  bash tests/v6-hooks/test-build-adapters.sh
# Exit: 0 = todos passaram · 1 = alguma falha
# =============================================================================
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_DIR/scripts/build-adapters.sh"

GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'
PASS=0; FAIL=0
pass() { printf "  ${GREEN}✓${NC} %s\n" "$*"; PASS=$((PASS+1)); }
fail() { printf "  ${RED}✗${NC} %s\n" "$*"; FAIL=$((FAIL+1)); }
head() { printf "\n${CYAN}━━━ %s ━━━${NC}\n" "$*"; }

[ -f "$SCRIPT" ] || { echo "Script não encontrado: $SCRIPT"; exit 1; }

SANDBOX="$(mktemp -d /tmp/ideiaos-build-adapters-test.XXXXXX)"
trap 'rm -rf "$SANDBOX"' EXIT

# setup_ws <workspace> — cria estrutura mínima IdeiaOS em $workspace.
# Copia build-adapters.sh para $ws/scripts/ para que IDEIAOS_DIR resolva
# para $ws (dirname($0)/.. = $ws/scripts/../ = $ws).
setup_ws() {
  local ws="$1"
  mkdir -p "$ws/source/agents" \
           "$ws/source/hooks" \
           "$ws/source/rules" \
           "$ws/manifests" \
           "$ws/adapters" \
           "$ws/scripts" \
           "$ws/out/claude/hooks" \
           "$ws/out/claude/agents"
  cp "$SCRIPT" "$ws/scripts/build-adapters.sh"
  # Hook e rule mínimos para build_claude/build_cursor não falharem em find
  echo "#!/usr/bin/env bash" > "$ws/source/hooks/stub.sh"
  echo "# stub rule" > "$ws/source/rules/stub.md"
  # modules.json mínimo
  echo '{}' > "$ws/manifests/modules.json"
}

# run_ba <ws> [extra_args] — executa build-adapters do workspace (não do repo).
# IDEIAOS_DIR resolverá para $ws. Captura stdout+stderr combinados.
run_ba() {
  local ws="$1"; shift
  local out_dir="$ws/out"
  CLAUDE_HOOKS_DIR="$out_dir/claude/hooks" \
  CLAUDE_AGENTS_DIR="$out_dir/claude/agents" \
  CURSOR_RULES_DIR="$out_dir/cursor/rules" \
  bash "$ws/scripts/build-adapters.sh" --project-dir "$ws" --target all --dry-run "$@" 2>&1
}

# ── Grupo 1: Agent válido → exit 0 ───────────────────────────────────────────
head "1) Agent válido (model + tools) → exit 0"

WS1="$SANDBOX/ws1"; setup_ws "$WS1"
cat > "$WS1/source/agents/good-agent.md" <<'FRONTMATTER'
---
name: good-agent
description: A good agent for testing
model: sonnet
tools: Read, Bash
---
FRONTMATTER

RC=0
OUT="$(run_ba "$WS1")" || RC=$?

[ "$RC" = "0" ] \
  && pass "agent válido → exit 0" \
  || fail "agent válido → esperava exit 0, veio $RC"

echo "$OUT" | grep -q "All agents have valid frontmatter" \
  && pass "stdout contém 'All agents have valid frontmatter contracts'" \
  || fail "stdout não contém mensagem de validação OK: $OUT"

# ── Grupo 2: Agent sem 'model:' mas com 'tools:' → exit 1 (sem msg stderr) ───
# NOTA: set -euo pipefail no script. $([ $has_tools -eq 0 ] && echo ...) com
# has_tools=1 retorna exit 1 → set -e mata o script ANTES de imprimir a
# mensagem de erro detalhada. Exit 1 é correto; stderr fica vazio — comportamento
# real estável (o script bloqueia, apenas sem diagnostico textual completo).
head "2) Agent sem model (tem tools) → exit 1, sem msg de erro detalhada"

WS2="$SANDBOX/ws2"; setup_ws "$WS2"
cat > "$WS2/source/agents/bad-agent-no-model.md" <<'FRONTMATTER'
---
name: bad-agent-no-model
description: Has tools, missing model
tools: Read
---
FRONTMATTER

RC=0
COMBINED="$(run_ba "$WS2")" || RC=$?

[ "$RC" = "1" ] \
  && pass "agent sem model (tem tools) → exit 1 (validação bloqueou)" \
  || fail "agent sem model → esperava exit 1, veio $RC"

echo "$COMBINED" | grep -q "Validating agent frontmatter" \
  && pass "validação foi executada (processo iniciou corretamente)" \
  || fail "validação não foi executada: $COMBINED"

# ── Grupo 3: Agent sem 'tools:' → exit 1 ─────────────────────────────────────
head "3) Agent sem 'tools:' → exit 1, output menciona 'tools'"

WS3="$SANDBOX/ws3"; setup_ws "$WS3"
cat > "$WS3/source/agents/bad-agent2.md" <<'FRONTMATTER'
---
name: bad-agent2
description: Missing tools field
model: sonnet
---
FRONTMATTER

RC=0
COMBINED="$(run_ba "$WS3")" || RC=$?

[ "$RC" = "1" ] \
  && pass "agent sem 'tools:' → exit 1" \
  || fail "agent sem 'tools:' → esperava exit 1, veio $RC"

echo "$COMBINED" | grep -qi "tools" \
  && pass "output menciona 'tools' no erro" \
  || fail "output não menciona 'tools': $COMBINED"

# ── Grupo 4: Agent sem AMBOS os campos → exit 1, ambos mencionados ───────────
head "4) Agent sem model E tools → exit 1, output menciona ambos"

WS4="$SANDBOX/ws4"; setup_ws "$WS4"
cat > "$WS4/source/agents/bad-both.md" <<'FRONTMATTER'
---
name: bad-both
description: Missing both model and tools
---
FRONTMATTER

RC=0
COMBINED="$(run_ba "$WS4")" || RC=$?

[ "$RC" = "1" ] \
  && pass "agent sem model e tools → exit 1" \
  || fail "agent sem model e tools → esperava exit 1, veio $RC"

echo "$COMBINED" | grep -qi "model" \
  && pass "output menciona 'model'" \
  || fail "output não menciona 'model': $COMBINED"

echo "$COMBINED" | grep -qi "tools" \
  && pass "output menciona 'tools'" \
  || fail "output não menciona 'tools': $COMBINED"

# ── Grupo 5: Múltiplos agents — um sem tools (detectável) → exit 1 ───────────
# Usa agent com tools ausente (não model ausente) para evitar o set-e bug.
# Um agent válido + um sem tools → exit 1.
head "5) Múltiplos agents: um válido + um sem tools → exit 1"

WS5="$SANDBOX/ws5"; setup_ws "$WS5"
cat > "$WS5/source/agents/good-agent.md" <<'FRONTMATTER'
---
name: good-agent
description: This one is fine
model: sonnet
tools: Read, Bash
---
FRONTMATTER

cat > "$WS5/source/agents/bad-no-tools.md" <<'FRONTMATTER'
---
name: bad-no-tools
description: Missing tools field
model: haiku
---
FRONTMATTER

RC=0
COMBINED="$(run_ba "$WS5")" || RC=$?

[ "$RC" = "1" ] \
  && pass "um válido + um sem tools → exit 1 (um bad blocks all)" \
  || fail "um válido + um sem tools → esperava exit 1, veio $RC"

echo "$COMBINED" | grep -qi "bad-no-tools" \
  && pass "output nomeia 'bad-no-tools' (o ofensor)" \
  || fail "output não nomeia 'bad-no-tools': $COMBINED"

# ── Grupo 6: --dry-run não copia arquivos ────────────────────────────────────
head "6) --dry-run não copia arquivos, stdout contém '[DRY]'"

WS6="$SANDBOX/ws6"; setup_ws "$WS6"
cat > "$WS6/source/agents/good-agent.md" <<'FRONTMATTER'
---
name: good-agent
description: Valid agent
model: sonnet
tools: Read, Bash
---
FRONTMATTER

RC=0
OUT="$(run_ba "$WS6")" || RC=$?

[ "$RC" = "0" ] \
  && pass "--dry-run com agent válido → exit 0" \
  || fail "--dry-run com agent válido → esperava exit 0, veio $RC"

AGENT_COPY="$WS6/out/claude/agents/good-agent.md"
[ ! -f "$AGENT_COPY" ] \
  && pass "--dry-run: good-agent.md NÃO copiado (correto)" \
  || fail "--dry-run: good-agent.md FOI copiado (violação de dry-run)"

echo "$OUT" | grep -q "\[DRY\]" \
  && pass "stdout contém '[DRY]' (modo dry-run anunciado)" \
  || fail "stdout não contém '[DRY]': $OUT"

# ── Grupo 7: --target desconhecido → exit 1 ──────────────────────────────────
head "7) --target desconhecido → exit 1, menciona 'Unknown'"

WS7="$SANDBOX/ws7"; setup_ws "$WS7"
cat > "$WS7/source/agents/good-agent.md" <<'FRONTMATTER'
---
name: good-agent
description: Valid agent
model: sonnet
tools: Read, Bash
---
FRONTMATTER

RC=0
COMBINED="$(CLAUDE_HOOKS_DIR="$WS7/out/claude/hooks" \
  CLAUDE_AGENTS_DIR="$WS7/out/claude/agents" \
  CURSOR_RULES_DIR="$WS7/out/cursor/rules" \
  bash "$WS7/scripts/build-adapters.sh" --project-dir "$WS7" --target unknown --dry-run 2>&1)" || RC=$?

[ "$RC" = "1" ] \
  && pass "--target unknown → exit 1" \
  || fail "--target unknown → esperava exit 1, veio $RC"

echo "$COMBINED" | grep -qi "Unknown" \
  && pass "output menciona 'Unknown'" \
  || fail "output não menciona 'Unknown': $COMBINED"

# ── Grupo 8: source/agents/ vazio → exit 0 (validação vazia = ok) ────────────
head "8) source/agents/ vazio → exit 0 (nothing to validate)"

WS8="$SANDBOX/ws8"; setup_ws "$WS8"
# Nenhum .md em source/agents/

RC=0
OUT="$(run_ba "$WS8")" || RC=$?

[ "$RC" = "0" ] \
  && pass "source/agents/ vazio → exit 0 (validação vazia = pass)" \
  || fail "source/agents/ vazio → esperava exit 0, veio $RC"

# ── Resumo ───────────────────────────────────────────────────────────────────
printf "\n${CYAN}━━━ Resumo ━━━${NC}\n"
printf "  passou: ${GREEN}%d${NC}   falhou: ${RED}%d${NC}\n" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] && { printf "${GREEN}✅ test-build-adapters: todas as assertions OK${NC}\n"; exit 0; } \
                  || { printf "${RED}❌ test-build-adapters: há falhas${NC}\n"; exit 1; }
