#!/usr/bin/env bash
# =============================================================================
# setup.sh — Ideia Business Dev Setup
#
# Configura o ambiente de IA para desenvolvimento:
#   - AIOX Core (orquestrador de agentes IA)
#   - Agente Cursor: retoma contexto do Claude Code no Cursor
#   - Skill Claude Code: retoma contexto do Cursor no Claude Code
#   - Memória persistente Claude Code para o projeto atual
#
# Uso:
#   1. Clone este repo e rode uma vez:
#      bash setup.sh
#
#   2. Para configurar um projeto específico:
#      bash setup.sh /caminho/para/o/projeto
#
# Requisitos: Node.js 18+, Cursor IDE, Claude Code CLI
# =============================================================================
set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$PWD"
PROJECT_ONLY=0
WITH_AIOX_PROJECT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-only)
      PROJECT_ONLY=1
      shift
      ;;
    --with-aiox-core-project)
      WITH_AIOX_PROJECT=1
      shift
      ;;
    *)
      PROJECT_DIR="$1"
      shift
      ;;
  esac
done

# Se rodou de dentro do próprio dev-setup, não usa ele como projeto alvo
if [ "$PROJECT_DIR" = "$SETUP_DIR" ]; then
  PROJECT_DIR="$PWD"
fi

# ── Cores ─────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'
BOLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC} $*"; }
step() { echo -e "\n${CYAN}${BOLD}==> $*${NC}"; }

encoded_path() { echo "$1" | sed 's|/|-|g' | sed 's|^-||'; }

ensure_file_from_template() {
  local template_path="$1"
  local target_path="$2"
  local project_name="$3"
  local today
  today="$(date +%Y-%m-%d)"

  if [ -f "$target_path" ]; then
    ok "$target_path já existe"
    return 0
  fi

  mkdir -p "$(dirname "$target_path")"
  sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" "$template_path" > "$target_path"
  ok "$target_path criado"
}

# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${CYAN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo    "║         Ideia Business — Dev Setup                  ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo -e "  Setup dir : ${BOLD}$SETUP_DIR${NC}"
echo -e "  Projeto   : ${BOLD}$PROJECT_DIR${NC}"

# ─────────────────────────────────────────────────────────────────────────────
step "1) Pré-requisitos"

MISSING=()
command -v node &>/dev/null || MISSING+=("Node.js 18+  →  https://nodejs.org")
command -v npx  &>/dev/null || MISSING+=("npx (vem com Node.js)")
command -v git  &>/dev/null || MISSING+=("git  →  https://git-scm.com")

if [ ${#MISSING[@]} -gt 0 ]; then
  err "Ferramentas obrigatórias ausentes:"
  for item in "${MISSING[@]}"; do echo "     • $item"; done
  exit 1
fi
ok "Node $(node --version) · git $(git --version | awk '{print $3}')"

command -v cursor &>/dev/null \
  && ok "Cursor IDE detectado" \
  || warn "Cursor IDE não encontrado na linha de comando (ok se estiver instalado como app)"

[ -d "$HOME/.claude" ] \
  && ok "Claude Code detectado" \
  || warn "Claude Code não encontrado — instale em https://claude.ai/code"

# ─────────────────────────────────────────────────────────────────────────────
if [ "$PROJECT_ONLY" -eq 0 ]; then
step "2) AIOX Core (orquestrador de agentes IA)"

if command -v npx &>/dev/null; then
  npx aiox-core@latest install
  ok "AIOX Core instalado/atualizado"
else
  warn "npx não disponível — AIOX Core não instalado"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "3) Agente Cursor — claude-continuation"
# Permite retomar no Cursor o que estava sendo feito no Claude Code

CURSOR_AGENTS_DIR="$HOME/.cursor/agents"
CURSOR_AGENT="$CURSOR_AGENTS_DIR/claude-continuation.md"
CURSOR_TEMPLATE="$SETUP_DIR/agents/claude-continuation.md"

mkdir -p "$CURSOR_AGENTS_DIR"

if [ -f "$CURSOR_AGENT" ]; then
  if diff -q "$CURSOR_TEMPLATE" "$CURSOR_AGENT" &>/dev/null; then
    ok "Agente Cursor já está na versão mais recente"
  else
    cp "$CURSOR_TEMPLATE" "$CURSOR_AGENT"
    ok "Agente Cursor atualizado"
  fi
else
  cp "$CURSOR_TEMPLATE" "$CURSOR_AGENT"
  ok "Agente Cursor instalado → $CURSOR_AGENT"
fi

echo "     Uso no Cursor: mencione @claude-continuation ou 'retoma o que estava no Claude'"

# ─────────────────────────────────────────────────────────────────────────────
step "4) Skill Claude Code — cursor-continuation"
# Permite retomar no Claude Code o que estava sendo feito no Cursor

CLAUDE_SKILL_DIR="$HOME/.claude/skills/cursor-continuation"
CLAUDE_SKILL="$CLAUDE_SKILL_DIR/SKILL.md"
CLAUDE_TEMPLATE="$SETUP_DIR/skills/cursor-continuation/SKILL.md"

mkdir -p "$CLAUDE_SKILL_DIR"

if [ -f "$CLAUDE_SKILL" ]; then
  if diff -q "$CLAUDE_TEMPLATE" "$CLAUDE_SKILL" &>/dev/null; then
    ok "Skill Claude Code já está na versão mais recente"
  else
    cp "$CLAUDE_TEMPLATE" "$CLAUDE_SKILL"
    ok "Skill Claude Code atualizado"
  fi
else
  cp "$CLAUDE_TEMPLATE" "$CLAUDE_SKILL"
  ok "Skill Claude Code instalado → $CLAUDE_SKILL"
fi

echo "     Uso no Claude Code: /cursor-continuation"
else
  step "2-4) Setup global"
  warn "Modo --project-only ativo: pulando AIOX Core + instalação global de agentes/skills"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5) Configurar projeto: $PROJECT_DIR"

if [ ! -d "$PROJECT_DIR" ]; then
  warn "Diretório de projeto não encontrado: $PROJECT_DIR"
  warn "Pulando configuração específica do projeto"
else
  cd "$PROJECT_DIR"

  # AIOX config
  if [ ! -f ".aiox-ai-config.yaml" ]; then
    cp "$SETUP_DIR/templates/aiox-ai-config.yaml" ".aiox-ai-config.yaml"
    ok ".aiox-ai-config.yaml criado no projeto"
    warn "Configure OPENROUTER_API_KEY no .env para habilitar fallback de IA"
  else
    ok ".aiox-ai-config.yaml já existe no projeto"
  fi

  # AIOX Core no projeto (opcional: pode ser interativo dependendo da versão)
  if [ -d ".aiox-core" ]; then
    ok ".aiox-core já existe no projeto"
  else
    if [ "$WITH_AIOX_PROJECT" -eq 1 ]; then
      if command -v npx &>/dev/null; then
        if npx aiox-core@latest install; then
          if [ -d ".aiox-core" ]; then
            ok "AIOX Core inicializado no projeto (.aiox-core)"
          else
            warn "AIOX Core executado, mas .aiox-core não foi criado automaticamente"
          fi
        else
          warn "Falha ao inicializar AIOX Core no projeto (setup segue normalmente)"
        fi
      else
        warn "npx não disponível — não foi possível inicializar AIOX Core no projeto"
      fi
    else
      warn ".aiox-core ausente. Para inicializar no projeto, rode: bash setup.sh --with-aiox-core-project \"$PROJECT_DIR\""
    fi
  fi

  # Memória Claude Code para este projeto
  ENCODED="$(encoded_path "$PROJECT_DIR")"
  MEMORY_DIR="$HOME/.claude/projects/$ENCODED/memory"
  MEMORY_FILE="$MEMORY_DIR/MEMORY.md"
  PROJECT_NAME="$(basename "$PROJECT_DIR")"

  if [ ! -f "$MEMORY_FILE" ]; then
    mkdir -p "$MEMORY_DIR"
    cat > "$MEMORY_FILE" << MEMMD
# Memory — $PROJECT_NAME

> Memória persistente Claude Code para este projeto.
> Atualizada automaticamente durante sessões.

- **Idioma:** Português
- **Setup:** $(date +%Y-%m-%d)
MEMMD
    ok "Memória Claude Code inicializada"
  else
    ok "Memória Claude Code já existe"
  fi

  # .planning/ para GSD
  if [ ! -d ".planning" ]; then
    mkdir -p .planning/phases
    ok ".planning/ criado — rode /gsd-new-project no Claude Code para inicializar"
  else
    ok ".planning/ já existe"
  fi

  # .gitignore — proteções mínimas
  if [ ! -f ".gitignore" ]; then touch .gitignore; fi
  for entry in ".env" ".env.local" "node_modules/" ".aiox/"; do
    grep -qF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
  done
  ok ".gitignore com proteções essenciais"

  # Estrutura híbrida de continuidade (main + planning)
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/AGENTS.md.tmpl" "$PROJECT_DIR/AGENTS.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/CLAUDE.md.tmpl" "$PROJECT_DIR/CLAUDE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/STATE.md.tmpl" "$PROJECT_DIR/STATE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/CONTINUATION_HANDOFF.md.tmpl" "$PROJECT_DIR/docs/CONTINUATION_HANDOFF.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/session-continuation.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/session-continuation.mdc" "$PROJECT_NAME"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo    "║                  Setup concluído! ✓                 ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}O que foi instalado globalmente:${NC}"
echo "  • Agente Cursor    → ~/.cursor/agents/claude-continuation.md"
echo "  • Skill Claude     → ~/.claude/skills/cursor-continuation/SKILL.md"
echo "  • AIOX Core        → disponível via npx aiox-core"
echo ""
echo -e "  ${BOLD}Como usar no dia a dia:${NC}"
echo ""
echo "  No Cursor:"
echo "  → Diga: 'retoma o que estava no Claude Code'"
echo "  → Ou mencione @claude-continuation no chat"
echo ""
echo "  No Claude Code:"
echo "  → Digite: /cursor-continuation"
echo "  → Ou diga: 'retoma o contexto do Cursor'"
echo ""
echo -e "  ${BOLD}Para um novo projeto:${NC}"
echo "  → bash $SETUP_DIR/setup.sh /caminho/do/projeto"
echo ""
