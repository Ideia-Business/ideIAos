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
LOVABLE_MODE="auto"  # auto | force | skip

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
    --lovable)
      LOVABLE_MODE="force"
      shift
      ;;
    --no-lovable)
      LOVABLE_MODE="skip"
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

# Verifica se .gitignore já cobre uma entrada essencial — aceita variações
# comuns (com/sem barra final, globs equivalentes, sub-paths que sinalizam
# gestão manual) para não adicionar duplicatas. Idempotente: rodar 2x
# seguidas não adiciona nada após a primeira.
# Uso: gitignore_has_pattern <file> <entry>
gitignore_has_pattern() {
  local file="$1" entry="$2"
  [ -f "$file" ] || return 1
  case "$entry" in
    ".env")
      # Cobre: .env exato, *.env, .env*, ou * (ignora tudo)
      grep -qE '^\s*(\.env|\*\.env|\.env\*|\*)\s*(#.*)?$' "$file" 2>/dev/null
      ;;
    ".env.local")
      # Cobre: .env.local, .env*, *.local, *.env.local, ou *
      grep -qE '^\s*(\.env\.local|\.env\*|\*\.local|\*\.env\.local|\*)\s*(#.*)?$' "$file" 2>/dev/null
      ;;
    "node_modules/")
      # Cobre: node_modules ou node_modules/
      grep -qE '^\s*node_modules/?\s*(#.*)?$' "$file" 2>/dev/null
      ;;
    ".aiox/")
      # Cobre: .aiox, .aiox/, ou qualquer .aiox/sub-path (sinaliza gestão manual)
      grep -qE '^\s*\.aiox(/|/.+)?\s*(#.*)?$' "$file" 2>/dev/null
      ;;
    *)
      grep -qF "$entry" "$file" 2>/dev/null
      ;;
  esac
}

# ── Detector Lovable ──────────────────────────────────────────────────────────
# Procura sinais determinísticos no projeto: lovable.config.*, .lovable/, ou
# marker explícito no AGENTS.md. NUNCA assume — falha aberta exige confirmação.
detect_lovable_project() {
  local dir="$1"
  if compgen -G "$dir/lovable.config.*" > /dev/null 2>&1; then
    echo "marker:lovable.config"
    return 0
  fi
  if [ -d "$dir/.lovable" ]; then
    echo "marker:.lovable/"
    return 0
  fi
  if [ -f "$dir/AGENTS.md" ] && grep -q "lovable-deploy-section" "$dir/AGENTS.md" 2>/dev/null; then
    echo "marker:AGENTS.md"
    return 0
  fi
  if [ -f "$dir/AGENTS.md" ] && grep -qi "Deploy:\s*Lovable\s*Cloud" "$dir/AGENTS.md" 2>/dev/null; then
    echo "marker:AGENTS.md (declaração textual)"
    return 0
  fi
  return 1
}

# Anexa/atualiza fragmento Lovable ao AGENTS.md (idempotente via marcadores BEGIN/END).
# Se markers existem, substitui o bloco entre eles pelo conteúdo atual do fragment —
# permite refresh do padrão quando o template é atualizado no dev-setup.
append_lovable_to_agents_md() {
  local agents_md="$1"
  local fragment="$2"

  if [ ! -f "$agents_md" ]; then
    cat "$fragment" > "$agents_md"
    ok "AGENTS.md criado com seção Lovable"
    return 0
  fi

  if grep -q "BEGIN: lovable-deploy-section" "$agents_md" 2>/dev/null; then
    # Já tem markers — comparar conteúdo e atualizar se diferente
    local current new tmp
    current="$(awk '/BEGIN: lovable-deploy-section/,/END: lovable-deploy-section/' "$agents_md")"
    new="$(cat "$fragment")"
    if [ "$current" = "$new" ]; then
      ok "AGENTS.md já tem seção Lovable atualizada"
      return 0
    fi
    # Substituir bloco BEGIN..END pelo conteúdo do fragment (awk preserva resto do arquivo)
    tmp="$(mktemp)"
    awk -v frag="$fragment" '
      /BEGIN: lovable-deploy-section/ {
        while ((getline line < frag) > 0) print line
        close(frag)
        skip = 1
        next
      }
      skip && /END: lovable-deploy-section/ { skip = 0; next }
      !skip { print }
    ' "$agents_md" > "$tmp"
    mv "$tmp" "$agents_md"
    ok "AGENTS.md: seção Lovable atualizada (refresh do template)"
    return 0
  fi

  printf "\n" >> "$agents_md"
  cat "$fragment" >> "$agents_md"
  ok "AGENTS.md atualizado com seção Lovable (anexada)"
}

# Setup completo Lovable num projeto.
setup_lovable_project() {
  local project_dir="$1"
  local project_name="$2"
  local today
  today="$(date +%Y-%m-%d)"

  step "6) Camada Lovable (deploy via Lovable Cloud)"

  # Confirmação humana se modo == auto e nenhum marker
  if [ "$LOVABLE_MODE" = "auto" ]; then
    local detected
    if detected="$(detect_lovable_project "$project_dir")"; then
      ok "Projeto Lovable detectado ($detected)"
    else
      warn "Nenhum marker Lovable encontrado em $project_dir"
      warn "Pulando setup Lovable. Para forçar: bash setup.sh --lovable \"$project_dir\""
      return 0
    fi
  elif [ "$LOVABLE_MODE" = "skip" ]; then
    warn "Modo --no-lovable: pulando setup Lovable"
    return 0
  else
    ok "Modo --lovable forçado"
  fi

  # 1. Anexa fragmento ao AGENTS.md
  append_lovable_to_agents_md \
    "$project_dir/AGENTS.md" \
    "$SETUP_DIR/templates/lovable/AGENTS.lovable.md.tmpl"

  # 2. Playbook em docs/
  if [ ! -f "$project_dir/docs/playbook-implantacao.md" ]; then
    mkdir -p "$project_dir/docs"
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/templates/lovable/playbook-implantacao.md.tmpl" \
      > "$project_dir/docs/playbook-implantacao.md"
    ok "docs/playbook-implantacao.md criado"
  else
    ok "docs/playbook-implantacao.md já existe"
  fi

  # 3. Template de handoff em docs/lovable/
  if [ ! -f "$project_dir/docs/lovable/_TEMPLATE.md" ]; then
    mkdir -p "$project_dir/docs/lovable"
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/templates/lovable/_TEMPLATE.md.tmpl" \
      > "$project_dir/docs/lovable/_TEMPLATE.md"
    ok "docs/lovable/_TEMPLATE.md criado"
  else
    ok "docs/lovable/_TEMPLATE.md já existe"
  fi

  # 4. Estrutura mínima de postmortems
  if [ ! -d "$project_dir/docs/postmortems" ]; then
    mkdir -p "$project_dir/docs/postmortems"
    touch "$project_dir/docs/postmortems/.gitkeep"
    ok "docs/postmortems/ criado"
  fi

  # 5. Modelo de resposta de conclusão (referência canônica)
  if [ ! -f "$project_dir/docs/lovable/conclusao-implantacao.md" ]; then
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/templates/lovable/conclusao-implantacao.md.tmpl" \
      > "$project_dir/docs/lovable/conclusao-implantacao.md"
    ok "docs/lovable/conclusao-implantacao.md criado (modelo de resposta final)"
  else
    ok "docs/lovable/conclusao-implantacao.md já existe"
  fi

  # 6. Marker explícito em .aiox-ai-config.yaml
  local config="$project_dir/.aiox-ai-config.yaml"
  if [ -f "$config" ] && ! grep -q "^deploy:" "$config" 2>/dev/null; then
    {
      printf "\n# Lovable Cloud (managed by dev-setup)\n"
      printf "deploy:\n  platform: lovable-cloud\n  sync: github-main\n  configured_at: %s\n" "$today"
    } >> "$config"
    ok ".aiox-ai-config.yaml marcado como Lovable Cloud"
  fi
}

# Setup da camada de aprendizado (universal — qualquer projeto, não só Lovable).
setup_learnings_layer() {
  local project_dir="$1"
  local project_name="$2"
  local today
  today="$(date +%Y-%m-%d)"

  step "7) Camada de aprendizado contínuo (docs/learnings/)"

  # 1. Pasta + README
  if [ ! -d "$project_dir/docs/learnings" ]; then
    mkdir -p "$project_dir/docs/learnings"
    ok "docs/learnings/ criado"
  fi

  if [ ! -f "$project_dir/docs/learnings/README.md" ]; then
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/templates/learnings/README.md.tmpl" \
      > "$project_dir/docs/learnings/README.md"
    ok "docs/learnings/README.md criado"
  else
    ok "docs/learnings/README.md já existe"
  fi

  # 2. Template de learning (esqueleto referencial — não é um learning, é o modelo)
  if [ ! -f "$project_dir/docs/learnings/_TEMPLATE.md" ]; then
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/templates/learnings/_TEMPLATE.md.tmpl" \
      > "$project_dir/docs/learnings/_TEMPLATE.md"
    ok "docs/learnings/_TEMPLATE.md criado"
  else
    ok "docs/learnings/_TEMPLATE.md já existe"
  fi
}

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

# ─────────────────────────────────────────────────────────────────────────────
step "5) Skill Claude Code — lovable-handoff"
# Executa playbook de implantação Lovable (typecheck → commit → push → handoff)

LOVABLE_SKILL_DIR="$HOME/.claude/skills/lovable-handoff"
LOVABLE_SKILL="$LOVABLE_SKILL_DIR/SKILL.md"
LOVABLE_TEMPLATE="$SETUP_DIR/skills/lovable-handoff/SKILL.md"

mkdir -p "$LOVABLE_SKILL_DIR"

if [ -f "$LOVABLE_SKILL" ]; then
  if diff -q "$LOVABLE_TEMPLATE" "$LOVABLE_SKILL" &>/dev/null; then
    ok "Skill lovable-handoff já está na versão mais recente"
  else
    cp "$LOVABLE_TEMPLATE" "$LOVABLE_SKILL"
    ok "Skill lovable-handoff atualizada"
  fi
else
  cp "$LOVABLE_TEMPLATE" "$LOVABLE_SKILL"
  ok "Skill lovable-handoff instalada → $LOVABLE_SKILL"
fi

echo "     Uso no Claude Code: /lovable-handoff (em projeto Lovable)"

# ─────────────────────────────────────────────────────────────────────────────
step "6) Skills Claude Code — recall-learnings + extract-learnings"
# Loop de aprendizado contínuo (universal — qualquer projeto)

for SKILL_NAME in recall-learnings extract-learnings; do
  L_DIR="$HOME/.claude/skills/$SKILL_NAME"
  L_FILE="$L_DIR/SKILL.md"
  L_TEMPLATE="$SETUP_DIR/skills/$SKILL_NAME/SKILL.md"

  mkdir -p "$L_DIR"

  if [ -f "$L_FILE" ]; then
    if diff -q "$L_TEMPLATE" "$L_FILE" &>/dev/null; then
      ok "Skill $SKILL_NAME já está na versão mais recente"
    else
      cp "$L_TEMPLATE" "$L_FILE"
      ok "Skill $SKILL_NAME atualizada"
    fi
  else
    cp "$L_TEMPLATE" "$L_FILE"
    ok "Skill $SKILL_NAME instalada → $L_FILE"
  fi
done

echo "     Uso: /recall-learnings (auto no início) · /extract-learnings (auto no fim)"

else
  step "2-6) Setup global"
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
  added=0
  for entry in ".env" ".env.local" "node_modules/" ".aiox/"; do
    if ! gitignore_has_pattern ".gitignore" "$entry"; then
      echo "$entry" >> .gitignore
      added=$((added + 1))
    fi
  done
  if [ "$added" -gt 0 ]; then
    ok ".gitignore: $added proteção(ões) essencial(is) adicionada(s)"
  else
    ok ".gitignore: proteções essenciais já cobertas"
  fi

  # Estrutura híbrida de continuidade (main + planning)
  PROJECT_NAME="$(basename "$PROJECT_DIR")"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/AGENTS.md.tmpl" "$PROJECT_DIR/AGENTS.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/CLAUDE.md.tmpl" "$PROJECT_DIR/CLAUDE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/STATE.md.tmpl" "$PROJECT_DIR/STATE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/CONTINUATION_HANDOFF.md.tmpl" "$PROJECT_DIR/docs/CONTINUATION_HANDOFF.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/session-continuation.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/session-continuation.mdc" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/agents-md-protocol.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/agents-md-protocol.mdc" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/templates/hybrid/planning-branch.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/planning-branch.mdc" "$PROJECT_NAME"

  # Camada Lovable (detector + flags --lovable / --no-lovable)
  setup_lovable_project "$PROJECT_DIR" "$PROJECT_NAME"

  # Camada de aprendizado contínuo (universal — qualquer projeto)
  setup_learnings_layer "$PROJECT_DIR" "$PROJECT_NAME"
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
