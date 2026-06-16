#!/usr/bin/env bash
# SOURCE: IdeiaOS v2
# =============================================================================
# build-plugins.sh — gera plugins/ a partir de source/ (gerador idempotente)
#
# ATENÇÃO: plugins/ é um ARTEFATO GERADO — não edite à mão.
# Edite source/ e rode este script. plugins/ é versionado para que
# '/plugin marketplace add Ideia-Business/IdeiaOS' resolva via GitHub.
#
# Uso:
#   bash scripts/build-plugins.sh                 # gera todos os 3 plugins
#   bash scripts/build-plugins.sh --plugin core   # só ideiaos-core
#   bash scripts/build-plugins.sh --dry-run       # mostra o que faria sem executar
#
# Referência de membership: manifests/plugin-membership.md
# =============================================================================
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

IDEIAOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$IDEIAOS_DIR/source"
PLUGINS_DIR="$IDEIAOS_DIR/plugins"

# ── Listas de membership ────────────────────────────────────────────────────
# Fonte legível: manifests/plugin-membership.md
# Implementação canônica: arrays abaixo (modificar nos dois em sincronia)

CORE_SKILLS=(
  accessibility
  api-design
  benchmark-optimization-loop
  code-tour
  codebase-onboarding
  context-engineering
  cost-tracking
  cursor-continuation
  database-migrations
  deep-research
  doubt
  e2e-testing
  evolve
  extract-learnings
  forge-agent
  idea
  ideiaos-catalog
  ideiaos-setup
  instinct-analyze
  instinct-status
  learn
  llms-txt
  mcp-to-cli
  memory-sync
  recall-learnings
  spec
  tdd
  two-instance-kickoff
)

DESIGN_SKILLS=(
  banner-design
  brand
  design
  design-system
  frontend-visual-loop
  motion
  slides
  ui-styling
  ui-ux-pro-max
  web-quality
)

LOVABLE_SKILLS=(
  lovable-handoff
)

MARKETING_SKILLS=(
  marketing
  marketing-research
)

MARKETING_AGENTS=(
  mkt-estrategista
  mkt-copywriter
  mkt-designer
  mkt-revisor
)

# Todos os agents vão para ideiaos-core
CORE_AGENTS=(
  build-error-resolver
  claude-continuation
  code-explorer
  code-simplifier
  doc-updater
  ideiaos-checker
  performance-optimizer
  planner
  pr-test-analyzer
  react-reviewer
  refactor-cleaner
  rls-reviewer
  security-reviewer
  silent-failure-hunter
  typescript-reviewer
)

# Hooks não-test para ideiaos-core (11 hooks)
CORE_HOOKS=(
  console-log-guard.sh
  deia-trigger.sh
  extract-learnings-reminder.sh
  ideiaos-detector.sh
  ideiaos-readme-reminder.sh
  observe-session-end.sh
  observe-tool-use.sh
  precompact-state-save.sh
  session-summary.sh
  strategic-compact.sh
  typecheck-on-edit.sh
)

# ── Opções ──────────────────────────────────────────────────────────────────
DRY_RUN=false
PLUGIN_FILTER="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --plugin)  PLUGIN_FILTER="$2"; shift 2 ;;
    --help|-h) echo "Usage: $0 [--dry-run] [--plugin core|design-suite|lovable|marketing|all]"; exit 0 ;;
    *) echo "Arg desconhecido: $1"; exit 1 ;;
  esac
done

run() {
  if $DRY_RUN; then echo "[DRY] $*"; else "$@"; fi
}

# ── Validação de membership ──────────────────────────────────────────────────
validate_exists() {
  local src="$1"
  if [ ! -e "$src" ]; then
    echo "ERRO: arquivo/dir de membership não encontrado: $src"
    echo "Verifique manifests/plugin-membership.md e atualize o array no build-plugins.sh."
    exit 1
  fi
}

# ── Geração de hooks.json via node (OBRIGATÓRIO — não usar heredoc bash) ────
generate_hooks_json() {
  local out="$1"
  # Usar node para serializar — ${CLAUDE_PLUGIN_ROOT} DEVE chegar como string literal
  node - <<'NODE_EOF' > "$out"
const R = "${CLAUDE_PLUGIN_ROOT}";

const hooks = {
  description: "Hooks de qualidade, memória e observação do IdeiaOS (gerado — não editar)",
  hooks: {
    PostToolUse: [
      {
        matcher: "Edit|Write",
        hooks: [
          { type: "command", command: `"${R}"/hooks/typecheck-on-edit.sh`, timeout: 60, async: true, asyncRewake: true }
        ]
      },
      {
        matcher: "Edit|Write",
        hooks: [
          { type: "command", command: `"${R}"/hooks/console-log-guard.sh`, timeout: 5 }
        ]
      },
      {
        matcher: "Edit|Write|MultiEdit",
        hooks: [
          { type: "command", command: `"${R}"/hooks/ideiaos-readme-reminder.sh`, timeout: 3 }
        ]
      },
      {
        matcher: "Bash",
        hooks: [
          { type: "command", command: `"${R}"/hooks/extract-learnings-reminder.sh`, timeout: 5 }
        ]
      },
      {
        matcher: "Edit|Write|MultiEdit|Bash",
        hooks: [
          { type: "command", command: `"${R}"/hooks/observe-tool-use.sh`, timeout: 5 }
        ]
      }
    ],
    PreToolUse: [
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/strategic-compact.sh`, timeout: 3 }
        ]
      }
    ],
    UserPromptSubmit: [
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/deia-trigger.sh`, timeout: 2 }
        ]
      }
    ],
    SessionStart: [
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/ideiaos-detector.sh`, timeout: 3 }
        ]
      }
    ],
    PreCompact: [
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/precompact-state-save.sh`, timeout: 10 }
        ]
      }
    ],
    Stop: [
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/session-summary.sh`, timeout: 30 }
        ]
      },
      {
        hooks: [
          { type: "command", command: `"${R}"/hooks/observe-session-end.sh`, timeout: 10 }
        ]
      }
    ]
  }
};

process.stdout.write(JSON.stringify(hooks, null, 2) + "\n");
NODE_EOF
}

# ── Geração de plugin.json via node ─────────────────────────────────────────
generate_plugin_json() {
  local plugin_name="$1"
  local description="$2"
  local out="$3"
  node -e "
const obj = {
  name: '${plugin_name}',
  version: '3.0.0',
  description: '${description}',
  author: { name: 'Ideia Business', email: 'gustavo@redeideia.com.br' },
  homepage: 'https://github.com/Ideia-Business/IdeiaOS',
  license: 'MIT'
};
process.stdout.write(JSON.stringify(obj, null, 2) + '\n');
" > "$out"
}

# ── Builder ideiaos-core ─────────────────────────────────────────────────────
build_core() {
  echo "→ Building ideiaos-core..."
  local PLUGIN_DIR="$PLUGINS_DIR/ideiaos-core"

  run mkdir -p "$PLUGIN_DIR/.claude-plugin"
  run mkdir -p "$PLUGIN_DIR/agents"
  run mkdir -p "$PLUGIN_DIR/skills"
  run mkdir -p "$PLUGIN_DIR/hooks"

  # Agents
  for agent in "${CORE_AGENTS[@]}"; do
    local src="$SOURCE_DIR/agents/${agent}.md"
    validate_exists "$src"
    run cp "$src" "$PLUGIN_DIR/agents/${agent}.md"
    echo "  agent: ${agent}.md"
  done

  # Skills (cp -R para preservar subpastas)
  for skill in "${CORE_SKILLS[@]}"; do
    local src="$SOURCE_DIR/skills/${skill}"
    validate_exists "$src"
    run rm -rf "$PLUGIN_DIR/skills/${skill}"
    run cp -R "$src" "$PLUGIN_DIR/skills/${skill}"
    echo "  skill: ${skill}"
  done

  # Hooks
  for hook in "${CORE_HOOKS[@]}"; do
    local src="$SOURCE_DIR/hooks/${hook}"
    validate_exists "$src"
    run cp "$src" "$PLUGIN_DIR/hooks/${hook}"
    run chmod +x "$PLUGIN_DIR/hooks/${hook}"
    echo "  hook: ${hook}"
  done

  # hooks.json (gerado via node — ${CLAUDE_PLUGIN_ROOT} deve ser literal)
  if $DRY_RUN; then
    echo "[DRY] gerar plugins/ideiaos-core/hooks/hooks.json (node)"
  else
    generate_hooks_json "$PLUGIN_DIR/hooks/hooks.json"
    echo "  hooks.json (gerado via node)"
  fi

  # plugin.json
  if $DRY_RUN; then
    echo "[DRY] gerar plugins/ideiaos-core/.claude-plugin/plugin.json"
  else
    generate_plugin_json \
      "ideiaos-core" \
      "Núcleo IdeiaOS — orquestração, agents, hooks e skills." \
      "$PLUGIN_DIR/.claude-plugin/plugin.json"
    echo "  plugin.json"
  fi

  echo "✓ ideiaos-core pronto"
}

# ── Builder ideiaos-design-suite ────────────────────────────────────────────
build_design_suite() {
  echo "→ Building ideiaos-design-suite..."
  local PLUGIN_DIR="$PLUGINS_DIR/ideiaos-design-suite"

  run mkdir -p "$PLUGIN_DIR/.claude-plugin"
  run mkdir -p "$PLUGIN_DIR/skills"

  # Skills (cp -R)
  for skill in "${DESIGN_SKILLS[@]}"; do
    local src="$SOURCE_DIR/skills/${skill}"
    validate_exists "$src"
    run rm -rf "$PLUGIN_DIR/skills/${skill}"
    run cp -R "$src" "$PLUGIN_DIR/skills/${skill}"
    echo "  skill: ${skill}"
  done

  # plugin.json
  if $DRY_RUN; then
    echo "[DRY] gerar plugins/ideiaos-design-suite/.claude-plugin/plugin.json"
  else
    generate_plugin_json \
      "ideiaos-design-suite" \
      "Suíte de Design IdeiaOS — ui-ux-pro-max, design, design-system, ui-styling, brand, banner-design, slides, motion, frontend-visual-loop, web-quality." \
      "$PLUGIN_DIR/.claude-plugin/plugin.json"
    echo "  plugin.json"
  fi

  echo "✓ ideiaos-design-suite pronto"
}

# ── Builder ideiaos-lovable ──────────────────────────────────────────────────
build_lovable() {
  echo "→ Building ideiaos-lovable..."
  local PLUGIN_DIR="$PLUGINS_DIR/ideiaos-lovable"

  run mkdir -p "$PLUGIN_DIR/.claude-plugin"
  run mkdir -p "$PLUGIN_DIR/skills"
  run mkdir -p "$PLUGIN_DIR/templates/lovable"

  # Skill lovable-handoff (cp -R)
  for skill in "${LOVABLE_SKILLS[@]}"; do
    local src="$SOURCE_DIR/skills/${skill}"
    validate_exists "$src"
    run rm -rf "$PLUGIN_DIR/skills/${skill}"
    run cp -R "$src" "$PLUGIN_DIR/skills/${skill}"
    echo "  skill: ${skill}"
  done

  # deployment-protocol.md como referência dentro da skill
  local DEPLOY_PROTO="$SOURCE_DIR/rules/lovable/deployment-protocol.md"
  validate_exists "$DEPLOY_PROTO"
  run mkdir -p "$PLUGIN_DIR/skills/lovable-handoff/references"
  run cp "$DEPLOY_PROTO" "$PLUGIN_DIR/skills/lovable-handoff/references/deployment-protocol.md"
  echo "  reference: deployment-protocol.md"

  # Templates lovable
  local LOVABLE_TMPL_DIR="$SOURCE_DIR/templates/lovable"
  validate_exists "$LOVABLE_TMPL_DIR"
  if $DRY_RUN; then
    echo "[DRY] cp source/templates/lovable/*.tmpl → plugins/ideiaos-lovable/templates/lovable/"
  else
    for tmpl in "$LOVABLE_TMPL_DIR"/*.tmpl; do
      [ -e "$tmpl" ] || continue
      run cp "$tmpl" "$PLUGIN_DIR/templates/lovable/$(basename "$tmpl")"
      echo "  template: $(basename "$tmpl")"
    done
  fi

  # plugin.json
  if $DRY_RUN; then
    echo "[DRY] gerar plugins/ideiaos-lovable/.claude-plugin/plugin.json"
  else
    generate_plugin_json \
      "ideiaos-lovable" \
      "Camada Lovable IdeiaOS — skill /lovable-handoff + doutrina de deploy e templates de handoff." \
      "$PLUGIN_DIR/.claude-plugin/plugin.json"
    echo "  plugin.json"
  fi

  echo "✓ ideiaos-lovable pronto"
}

# ── Builder ideiaos-marketing ───────────────────────────────────────────────
build_marketing() {
  echo "→ Building ideiaos-marketing..."
  local PLUGIN_DIR="$PLUGINS_DIR/ideiaos-marketing"

  run mkdir -p "$PLUGIN_DIR/.claude-plugin"
  run mkdir -p "$PLUGIN_DIR/skills"
  run mkdir -p "$PLUGIN_DIR/agents"
  run mkdir -p "$PLUGIN_DIR/rules/marketing"

  # Skills (cp -R para preservar subpastas)
  for skill in "${MARKETING_SKILLS[@]}"; do
    local src="$SOURCE_DIR/skills/${skill}"
    validate_exists "$src"
    run rm -rf "$PLUGIN_DIR/skills/${skill}"
    run cp -R "$src" "$PLUGIN_DIR/skills/${skill}"
    echo "  skill: ${skill}"
  done

  # Agents
  for agent in "${MARKETING_AGENTS[@]}"; do
    local src="$SOURCE_DIR/agents/${agent}.md"
    validate_exists "$src"
    run cp "$src" "$PLUGIN_DIR/agents/${agent}.md"
    echo "  agent: ${agent}.md"
  done

  # Rules de marketing (22 best-practices — a base de conhecimento viaja com o plugin)
  local RULES_SRC="$SOURCE_DIR/rules/marketing"
  validate_exists "$RULES_SRC"
  if $DRY_RUN; then
    echo "[DRY] cp -R source/rules/marketing → plugins/ideiaos-marketing/rules/marketing"
  else
    run cp -R "$RULES_SRC/." "$PLUGIN_DIR/rules/marketing/"
  fi
  echo "  rules/marketing (22 best-practices)"

  # plugin.json
  if $DRY_RUN; then
    echo "[DRY] gerar plugins/ideiaos-marketing/.claude-plugin/plugin.json"
  else
    generate_plugin_json \
      "ideiaos-marketing" \
      "Camada de Marketing IdeiaOS — orquestrador /marketing, 4 content agents, skill marketing-research (Sherlock via Chrome DevTools MCP), 22 best-practices absorvidas do OpenSquad MIT." \
      "$PLUGIN_DIR/.claude-plugin/plugin.json"
    echo "  plugin.json"
  fi

  echo "✓ ideiaos-marketing pronto"
}

# ── Main ─────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║          IdeiaOS — build-plugins.sh                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "  Source : $SOURCE_DIR"
echo "  Output : $PLUGINS_DIR"
$DRY_RUN && echo "  Modo   : DRY-RUN (nenhum arquivo será criado)"
echo ""

case "$PLUGIN_FILTER" in
  core|ideiaos-core)
    build_core
    ;;
  design-suite|ideiaos-design-suite)
    build_design_suite
    ;;
  lovable|ideiaos-lovable)
    build_lovable
    ;;
  marketing|ideiaos-marketing)
    build_marketing
    ;;
  all)
    build_core
    build_design_suite
    build_lovable
    build_marketing
    ;;
  *)
    echo "Plugin desconhecido: $PLUGIN_FILTER"
    echo "Opções: core | design-suite | lovable | marketing | all"
    exit 1
    ;;
esac

echo ""
echo "✓ build-plugins.sh completo (plugin=$PLUGIN_FILTER, dry-run=$DRY_RUN)"
