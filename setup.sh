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

# PATH hardening — o LaunchAgent (autosync) roda via launchd, que NÃO herda o
# PATH do shell interativo; em Apple Silicon node/npx/python3 vivem em
# /opt/homebrew/bin. Sem isto, setup.sh falha sob propagate-if-changed com PATH
# pelado (mesmo padrão de build-adapters.sh:4 e build-plugins.sh:18). Idempotente.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$PWD"
PROJECT_ONLY=0
GLOBAL_ONLY=0
WITH_AIOX_PROJECT=0
LOVABLE_MODE="auto"  # auto | force | skip

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-only)
      PROJECT_ONLY=1
      shift
      ;;
    --global-only)
      GLOBAL_ONLY=1
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

# Se rodou de dentro do próprio IdeiaOS, não usa ele como projeto alvo
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
# permite refresh do padrão quando o template é atualizado no IdeiaOS.
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
    "$SETUP_DIR/source/templates/lovable/AGENTS.lovable.md.tmpl"

  # 2. Playbook em docs/
  if [ ! -f "$project_dir/docs/playbook-implantacao.md" ]; then
    mkdir -p "$project_dir/docs"
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/source/templates/lovable/playbook-implantacao.md.tmpl" \
      > "$project_dir/docs/playbook-implantacao.md"
    ok "docs/playbook-implantacao.md criado"
  else
    ok "docs/playbook-implantacao.md já existe"
  fi

  # 3. Template de handoff em docs/lovable/
  if [ ! -f "$project_dir/docs/lovable/_TEMPLATE.md" ]; then
    mkdir -p "$project_dir/docs/lovable"
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/source/templates/lovable/_TEMPLATE.md.tmpl" \
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
      "$SETUP_DIR/source/templates/lovable/conclusao-implantacao.md.tmpl" \
      > "$project_dir/docs/lovable/conclusao-implantacao.md"
    ok "docs/lovable/conclusao-implantacao.md criado (modelo de resposta final)"
  else
    ok "docs/lovable/conclusao-implantacao.md já existe"
  fi

  # 6. Marker explícito em .aiox-ai-config.yaml
  local config="$project_dir/.aiox-ai-config.yaml"
  if [ -f "$config" ] && ! grep -q "^deploy:" "$config" 2>/dev/null; then
    {
      printf "\n# Lovable Cloud (managed by IdeiaOS)\n"
      printf "deploy:\n  platform: lovable-cloud\n  sync: github-main\n  configured_at: %s\n" "$today"
    } >> "$config"
    ok ".aiox-ai-config.yaml marcado como Lovable Cloud"
  fi

  # 7. Cursor rules Lovable — doutrina ÚNICA (mandato global — sempre sincroniza do template)
  mkdir -p "$project_dir/.cursor/rules"
  cp "$SETUP_DIR/source/templates/lovable/lovable-deploy.mdc.tmpl" \
    "$project_dir/.cursor/rules/lovable-deploy.mdc"
  # Migração (2026-06-04): as 3 regras antigas foram consolidadas em lovable-deploy.mdc.
  rm -f "$project_dir/.cursor/rules/lovable-agent-delivery.mdc" \
        "$project_dir/.cursor/rules/lovable-deploy-update.mdc" \
        "$project_dir/.cursor/rules/lovable-publish.mdc"
  ok ".cursor/rules/lovable-deploy.mdc instalado (doutrina Lovable única)"
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
      "$SETUP_DIR/source/templates/learnings/README.md.tmpl" \
      > "$project_dir/docs/learnings/README.md"
    ok "docs/learnings/README.md criado"
  else
    ok "docs/learnings/README.md já existe"
  fi

  # 2. Template de learning (esqueleto referencial — não é um learning, é o modelo)
  if [ ! -f "$project_dir/docs/learnings/_TEMPLATE.md" ]; then
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/source/templates/learnings/_TEMPLATE.md.tmpl" \
      > "$project_dir/docs/learnings/_TEMPLATE.md"
    ok "docs/learnings/_TEMPLATE.md criado"
  else
    ok "docs/learnings/_TEMPLATE.md já existe"
  fi
}

# Setup da camada de Frescor de Segurança (v13 — Selo de Frescor de Segurança).
# Instala, POR PRODUTO e LOCALMENTE (nunca versionado), um hook post-commit
# ADVISORY que avisa quando a segurança do repo está defasada (tier warn/egrégio).
# Reusa UMA cópia do engine (no IdeiaOS) via SECFRESH_ROOT — o produto não versiona
# script algum → zero trigger de Lovable em `main`. Bootstrap de ledger-baseline
# LOCAL (dia-1 = score 0). Idempotente, fail-soft (NUNCA aborta o setup).
#
# post-commit é advisory por construção: roda DEPOIS do commit; o git ignora seu
# exit code → impossível travar uma feature (o "não enrijecer" do v13).
setup_security_freshness_layer() {
  local project_dir="$1"
  local project_name="$2"

  step "9) Camada de Frescor de Segurança (v13 — advisory, local-only)"

  local engine="$SETUP_DIR/scripts/check-security-freshness.sh"
  local tmpl="$SETUP_DIR/source/templates/security/post-commit-security-freshness.sh"
  if [ ! -x "$engine" ] || [ ! -f "$tmpl" ]; then
    warn "engine/template de frescor ausente — pulando (setup segue normalmente)"
    return 0
  fi
  if [ ! -d "$project_dir/.git" ]; then
    warn "projeto sem .git — frescor de segurança pulado"
    return 0
  fi

  # 1. Bootstrap do ledger-baseline LOCAL (idempotente; dia-1 = score 0)
  if SECFRESH_ROOT="$project_dir" bash "$engine" --bootstrap >/dev/null 2>&1; then
    ok "ledger-baseline de segurança garantido (.security/review-ledger.log — local)"
  else
    warn "bootstrap de ledger de segurança falhou (não-fatal)"
  fi

  # 2. .git/info/exclude — mantém ledger/marcador (e hook-husky) LOCAIS: nunca
  #    versionados, branch-agnostic. Protege contra o `git add -A` do autosync
  #    em branch `work` e contra commit acidental em `main` (trigger Lovable).
  local exclude_file="$project_dir/.git/info/exclude"
  mkdir -p "$project_dir/.git/info"; touch "$exclude_file"
  local e
  for e in ".security/review-ledger.log" ".security/.last-warn-epoch"; do
    grep -qxF "$e" "$exclude_file" 2>/dev/null || echo "$e" >> "$exclude_file"
  done

  # 3. Resolver o hooks dir (husky-aware): core.hooksPath ou .git/hooks
  local hookspath
  hookspath="$(git -C "$project_dir" config --get core.hooksPath 2>/dev/null || true)"
  local hooks_dir
  if [ -z "$hookspath" ]; then
    hooks_dir="$project_dir/.git/hooks"           # default (untracked, qualquer branch)
  elif [ "${hookspath:0:1}" = "/" ]; then
    hooks_dir="$hookspath"                          # caminho absoluto
  else
    hooks_dir="$project_dir/$hookspath"            # relativo ao repo (ex.: .husky — TRACKED)
    grep -qxF "$hookspath/post-commit" "$exclude_file" 2>/dev/null \
      || echo "$hookspath/post-commit" >> "$exclude_file"
  fi
  mkdir -p "$hooks_dir" 2>/dev/null || true
  local hook="$hooks_dir/post-commit"
  local marker="ideiaos-security-freshness-hook"

  # 4. Instalar/atualizar o hook (idempotente; backup se foreign)
  if [ -f "$hook" ] && ! grep -qF "$marker" "$hook" 2>/dev/null; then
    cp "$hook" "$hook.bak" 2>/dev/null || true
    warn "post-commit pré-existente não-nosso preservado em ${hook##*/}.bak"
  fi
  if sed "s|__ENGINE_PATH__|$engine|g" "$tmpl" > "$hook" 2>/dev/null; then
    chmod +x "$hook" 2>/dev/null || true
    ok "hook post-commit (advisory) instalado em ${hook#"$project_dir"/}"
  else
    warn "falha ao instalar hook post-commit (não-fatal)"
  fi
}

# Extrai a versão do bundle IdeiaOS de um arquivo IDEIAOS.md (qualquer projeto
# ou o template). Procura "Versão: X.Y" nas primeiras 10 linhas.
# Retorna a versão (ex: "1.1") ou string vazia se não encontrar.
ideiaos_version_of() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return; }
  head -10 "$file" 2>/dev/null \
    | grep -oE 'Vers[^:]+o:[[:space:]]*[0-9]+\.[0-9]+' \
    | head -1 \
    | sed -E 's/.*o:[[:space:]]*//'
}

# Extrai a data de instalação original (linha "Instalado em: YYYY-MM-DD") para
# preservar o timestamp histórico ao re-renderizar durante upgrade de versão.
# Retorna data ISO ou string vazia.
ideiaos_install_date_of() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return; }
  head -10 "$file" 2>/dev/null \
    | grep -oE 'Instalado em:[[:space:]]*[0-9]{4}-[0-9]{2}-[0-9]{2}' \
    | head -1 \
    | sed -E 's/.*Instalado em:[[:space:]]*//'
}

# Setup da camada IdeiaOS (orquestração GSD + AIOX + Lovable + Fase A).
# Cria IDEIAOS.md no projeto + estrutura .planning/ + verifica GSD readiness.
# Universal — vale pra qualquer projeto da Ideia Business.
#
# Bundle refresh: quando a versão de IDEIAOS.md no template é maior que a
# versão instalada no projeto, TODO o bundle (`IDEIAOS.md`, `docs/ideiaos/*`)
# é re-renderizado atomicamente. Caso contrário, ensure_file_from_template
# preserva os arquivos existentes (comportamento idempotente histórico).
setup_ideiaos_layer() {
  local project_dir="$1"
  local project_name="$2"
  local today
  today="$(date +%Y-%m-%d)"

  step "8) Camada IdeiaOS (orquestração unificada: GSD + AIOX + Lovable + Fase A)"

  # 1. Estrutura .planning/ (GSD workspace)
  if [ ! -d "$project_dir/.planning" ]; then
    mkdir -p "$project_dir/.planning/phases" "$project_dir/.planning/intel" "$project_dir/.planning/research"
    ok ".planning/ criado (phases + intel + research) — pronto para /gsd-new-project"
  else
    mkdir -p "$project_dir/.planning/phases" "$project_dir/.planning/intel" "$project_dir/.planning/research"
    ok ".planning/ presente (subpastas asseguradas)"
  fi

  # 2. IDEIAOS.md com detecção de versão (bundle master)
  local target_version installed_version original_install_date
  target_version="$(ideiaos_version_of "$SETUP_DIR/source/templates/ideiaos/IDEIAOS.md.tmpl")"
  local bundle_refresh=0

  if [ ! -f "$project_dir/IDEIAOS.md" ]; then
    sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
      "$SETUP_DIR/source/templates/ideiaos/IDEIAOS.md.tmpl" \
      > "$project_dir/IDEIAOS.md"
    ok "IDEIAOS.md criado (manifesto na raiz) — v${target_version:-?}"
    bundle_refresh=1  # first install → render todos os docs do bundle
  else
    installed_version="$(ideiaos_version_of "$project_dir/IDEIAOS.md")"
    if [ -n "$target_version" ] && [ "$installed_version" != "$target_version" ]; then
      # Preserva data de instalação original ao re-renderizar
      original_install_date="$(ideiaos_install_date_of "$project_dir/IDEIAOS.md")"
      [ -z "$original_install_date" ] && original_install_date="$today"

      sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$original_install_date|g" \
        "$SETUP_DIR/source/templates/ideiaos/IDEIAOS.md.tmpl" \
        > "$project_dir/IDEIAOS.md"
      ok "IDEIAOS.md atualizado: v${installed_version:-?} → v${target_version}"
      warn "Bundle IdeiaOS sendo refeito — docs/ideiaos/* serão sobrescritos (são artefatos gerados, não customizáveis localmente)"
      bundle_refresh=1
    else
      ok "IDEIAOS.md já existe (v${installed_version:-?})"
    fi
  fi

  # 3. Guias humanos + IA em docs/ideiaos/
  # Se bundle_refresh=1, força re-renderização. Senão preserva (idempotente).
  mkdir -p "$project_dir/docs/ideiaos"
  if [ "$bundle_refresh" = "1" ]; then
    for tmpl_name in GUIDE-HUMANS GUIDE-AI DECISION-MATRIX; do
      sed -e "s|__PROJECT_NAME__|$project_name|g" -e "s|__DATE__|$today|g" \
        "$SETUP_DIR/source/templates/ideiaos/${tmpl_name}.md.tmpl" \
        > "$project_dir/docs/ideiaos/${tmpl_name}.md"
      ok "docs/ideiaos/${tmpl_name}.md atualizado (bundle v${target_version})"
    done
  else
    ensure_file_from_template "$SETUP_DIR/source/templates/ideiaos/GUIDE-HUMANS.md.tmpl" "$project_dir/docs/ideiaos/GUIDE-HUMANS.md" "$project_name"
    ensure_file_from_template "$SETUP_DIR/source/templates/ideiaos/GUIDE-AI.md.tmpl" "$project_dir/docs/ideiaos/GUIDE-AI.md" "$project_name"
    ensure_file_from_template "$SETUP_DIR/source/templates/ideiaos/DECISION-MATRIX.md.tmpl" "$project_dir/docs/ideiaos/DECISION-MATRIX.md" "$project_name"
  fi

  # 4. Marker em .aiox-ai-config.yaml (registra que projeto está sob IdeiaOS)
  # Atualiza a versão se já existe a chave `ideiaos:` mas a versão divergiu.
  local config="$project_dir/.aiox-ai-config.yaml"
  if [ -f "$config" ]; then
    if ! grep -q "^ideiaos:" "$config" 2>/dev/null; then
      {
        printf "\n# IdeiaOS — Sistema Operacional unificado (managed by IdeiaOS)\n"
        printf "ideiaos:\n  version: %s\n  enabled: true\n  configured_at: %s\n  layers:\n" "${target_version:-1.0}" "$today"
        printf "    - aiox-core           # personas, stories, governance\n"
        printf "    - gsd                 # phases, goal-backward, atomic commits\n"
        printf "    - lovable             # deploy/handoff (se aplicável)\n"
        printf "    - learning-loop       # Fase A — recall + extract\n"
        printf "    - continuation        # cross-IDE session handoff\n"
      } >> "$config"
      ok ".aiox-ai-config.yaml marcado como IdeiaOS-enabled (v${target_version:-?})"
    elif [ "$bundle_refresh" = "1" ] && [ -n "$target_version" ]; then
      # Atualiza in-place a linha `  version: X.Y` no bloco ideiaos
      # macOS sed precisa de ''. GNU sed aceita -i sem arg. Usamos backup pra portabilidade.
      sed -i.bak -E "s|^([[:space:]]*version:[[:space:]]*)[0-9]+\.[0-9]+(.*)$|\1${target_version}\2|" "$config" \
        && rm -f "${config}.bak"
      ok ".aiox-ai-config.yaml: versão atualizada para v${target_version}"
    fi
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

# Detecta stacks presentes no projeto alvo e retorna lista separada por espaço.
# Uso: stacks=$(detect_stack "/caminho/do/projeto")
# Stacks possíveis: node typescript react nextjs supabase lovable python
# Base para instalação seletiva de rules por stack (Phase 04+).
detect_stack() {
  local project_dir="${1:-$PWD}"
  local stacks=()

  [[ -f "$project_dir/package.json" ]] && stacks+=("node")
  [[ -f "$project_dir/tsconfig.json" ]] && stacks+=("typescript")

  if [[ -f "$project_dir/package.json" ]]; then
    grep -q '"react"' "$project_dir/package.json" 2>/dev/null && stacks+=("react")
    grep -q '"next"' "$project_dir/package.json" 2>/dev/null && stacks+=("nextjs")
    grep -q '"@supabase/' "$project_dir/package.json" 2>/dev/null && stacks+=("supabase")
  fi

  [[ -d "$project_dir/supabase" ]] && ! grep -q "supabase" <<< "${stacks[*]:-}" && stacks+=("supabase")
  [[ -f "$project_dir/lovable.config.js" || -d "$project_dir/docs/lovable" ]] && stacks+=("lovable")
  [[ -f "$project_dir/requirements.txt" || -f "$project_dir/pyproject.toml" ]] && stacks+=("python")

  echo "${stacks[*]:-}"
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

# O instalador padrão do aiox-core é INTERATIVO (pergunta idioma via inquirer) e
# trava/crasha sem TTY (ERR_USE_AFTER_CLOSE), o que abortaria o setup sob set -e.
# Solução: `install --quiet --force` (modo CI/CD DOCUMENTADO pelo próprio aiox:
# "no prompts") + stdin /dev/null. Roda SEM TTY em máquina-nova/automação.
# Defensivo: (a) pula se já instalado; (b) nunca é fatal (|| warn).
if command -v aiox &>/dev/null || command -v aiox-core &>/dev/null; then
  AIOX_V="$( (aiox --version 2>/dev/null || aiox-core --version 2>/dev/null) | head -1 )"
  ok "AIOX Core já instalado (CLI ${AIOX_V:-presente}) — pulando instalador"
elif ! command -v npx &>/dev/null; then
  warn "npx não disponível — AIOX Core não instalado"
else
  if npx aiox-core@latest install --quiet --force </dev/null; then
    ok "AIOX Core instalado/atualizado (modo não-interativo --quiet --force)"
  else
    warn "Instalador do AIOX Core falhou — manual: npx aiox-core@latest install --quiet --force"
  fi
fi

# ─────────────────────────────────────────────────────────────────────────────
step "3) Agente Cursor — claude-continuation"
# Permite retomar no Cursor o que estava sendo feito no Claude Code

CURSOR_AGENTS_DIR="$HOME/.cursor/agents"
CURSOR_AGENT="$CURSOR_AGENTS_DIR/claude-continuation.md"
CURSOR_TEMPLATE="$SETUP_DIR/source/agents/claude-continuation.md"

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
step "3.5) Agente Cursor — ideiaos-checker"
# Espelho da skill /ideiaos-setup do Claude Code. Audita + completa setup do projeto.

SETUP_CHECKER="$CURSOR_AGENTS_DIR/ideiaos-checker.md"
SETUP_CHECKER_TEMPLATE="$SETUP_DIR/source/agents/ideiaos-checker.md"

if [ -f "$SETUP_CHECKER" ]; then
  if diff -q "$SETUP_CHECKER_TEMPLATE" "$SETUP_CHECKER" &>/dev/null; then
    ok "Agente Cursor ideiaos-checker já está na versão mais recente"
  else
    cp "$SETUP_CHECKER_TEMPLATE" "$SETUP_CHECKER"
    ok "Agente Cursor ideiaos-checker atualizado"
  fi
else
  cp "$SETUP_CHECKER_TEMPLATE" "$SETUP_CHECKER"
  ok "Agente Cursor ideiaos-checker instalado → $SETUP_CHECKER"
fi

echo "     Uso no Cursor: mencione @ideiaos-checker em projeto novo"

# ─────────────────────────────────────────────────────────────────────────────
step "3.6) Alias 'idea-setup' no shell (opcional)"
# Atalho terminal idempotente. Detecta zsh/bash; opt-in via prompt.

if ! grep -qF "alias idea-setup=" "$HOME/.zshrc" 2>/dev/null && ! grep -qF "alias idea-setup=" "$HOME/.bashrc" 2>/dev/null; then
  warn "Alias 'idea-setup' não está configurado. Para adicionar, rode:"
  echo "       bash \"$SETUP_DIR/scripts/install-alias.sh\""
  echo "       (idempotente — detecta shell automaticamente)"
else
  ok "Alias 'idea-setup' já configurado"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "4) Skill Claude Code — cursor-continuation"
# Permite retomar no Claude Code o que estava sendo feito no Cursor

CLAUDE_SKILL_DIR="$HOME/.claude/skills/cursor-continuation"
CLAUDE_SKILL="$CLAUDE_SKILL_DIR/SKILL.md"
CLAUDE_TEMPLATE="$SETUP_DIR/source/skills/cursor-continuation/SKILL.md"

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
LOVABLE_TEMPLATE="$SETUP_DIR/source/skills/lovable-handoff/SKILL.md"

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
step "5.5) Hook Claude Code — extract-learnings-reminder"
# Barreira ativa: injeta gate triplo após cada git commit em projeto Fase A.
# Específico do Claude Code (Cursor/Codex/Gemini têm enforcement via rules+AGENTS.md).

HOOK_DIR="$HOME/.claude/hooks"
HOOK_FILE="$HOOK_DIR/extract-learnings-reminder.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/extract-learnings-reminder.sh"

mkdir -p "$HOOK_DIR"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook extract-learnings-reminder já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook extract-learnings-reminder atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook extract-learnings-reminder instalado → $HOOK_FILE"
fi

# Verificar se está registrado em ~/.claude/settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ] && grep -q "extract-learnings-reminder.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook registrado em ~/.claude/settings.json"
else
  warn "Hook NÃO está registrado em ~/.claude/settings.json — adicione manualmente:"
  cat <<'SNIPPET'
       Adicione esta entrada em hooks.PostToolUse do ~/.claude/settings.json:

       {
         "matcher": "Bash",
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/extract-learnings-reminder.sh\"",
             "timeout": 5
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: após cada 'git commit' em projeto com AGENTS.md Fase A,"
echo "     injeta gate triplo no contexto da IA (lembra criar learning se replicável)."

# ─────────────────────────────────────────────────────────────────────────────
step "5.6) Hook SessionStart Claude Code — ideiaos-detector"
# Detecta projeto Lovable sem Fase A no início da sessão e sugere /ideiaos-setup.
# Idempotente: silencia se Fase A já instalada, projeto não é Lovable, ou é IdeiaOS.

DETECTOR_FILE="$HOOK_DIR/ideiaos-detector.sh"
DETECTOR_TEMPLATE="$SETUP_DIR/source/hooks/ideiaos-detector.sh"

if [ -f "$DETECTOR_FILE" ]; then
  if diff -q "$DETECTOR_TEMPLATE" "$DETECTOR_FILE" &>/dev/null; then
    ok "Hook ideiaos-detector já está na versão mais recente"
  else
    cp "$DETECTOR_TEMPLATE" "$DETECTOR_FILE"
    chmod +x "$DETECTOR_FILE"
    ok "Hook ideiaos-detector atualizado"
  fi
else
  cp "$DETECTOR_TEMPLATE" "$DETECTOR_FILE"
  chmod +x "$DETECTOR_FILE"
  ok "Hook ideiaos-detector instalado → $DETECTOR_FILE"
fi

# Verificar se registrado em settings.json (SessionStart event)
if [ -f "$SETTINGS_FILE" ] && grep -q "ideiaos-detector.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook ideiaos-detector registrado em ~/.claude/settings.json"
else
  warn "Hook ideiaos-detector NÃO está registrado — adicione em hooks.SessionStart:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/ideiaos-detector.sh\"",
             "timeout": 3
           }
         ]
       }
SNIPPET
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.7) Skill Claude Code — /ideiaos-setup"
# Ponto de entrada único pra rodar o setup. Idempotente, audita antes de aplicar.

for SKILL_NAME in ideiaos-setup; do
  S_DIR="$HOME/.claude/skills/$SKILL_NAME"
  S_FILE="$S_DIR/SKILL.md"
  S_TEMPLATE="$SETUP_DIR/source/skills/$SKILL_NAME/SKILL.md"

  mkdir -p "$S_DIR"

  if [ -f "$S_FILE" ]; then
    if diff -q "$S_TEMPLATE" "$S_FILE" &>/dev/null; then
      ok "Skill $SKILL_NAME já está na versão mais recente"
    else
      cp "$S_TEMPLATE" "$S_FILE"
      ok "Skill $SKILL_NAME atualizada"
    fi
  else
    cp "$S_TEMPLATE" "$S_FILE"
    ok "Skill $SKILL_NAME instalada → $S_FILE"
  fi
done

echo "     Uso: /ideiaos-setup em qualquer projeto novo. Idempotente."

# ─────────────────────────────────────────────────────────────────────────────
step "5.8) Hook Claude Code — ideiaos-readme-reminder"
# Lembra a IA de atualizar o README do IdeiaOS quando modifica componentes.
# Reforço pelo lado da IA antes do pre-commit Git bloquear no commit.

README_HOOK="$HOOK_DIR/ideiaos-readme-reminder.sh"
README_HOOK_TEMPLATE="$SETUP_DIR/source/hooks/ideiaos-readme-reminder.sh"

if [ -f "$README_HOOK" ]; then
  if diff -q "$README_HOOK_TEMPLATE" "$README_HOOK" &>/dev/null; then
    ok "Hook ideiaos-readme-reminder já está na versão mais recente"
  else
    cp "$README_HOOK_TEMPLATE" "$README_HOOK"
    chmod +x "$README_HOOK"
    ok "Hook ideiaos-readme-reminder atualizado"
  fi
else
  cp "$README_HOOK_TEMPLATE" "$README_HOOK"
  chmod +x "$README_HOOK"
  ok "Hook ideiaos-readme-reminder instalado → $README_HOOK"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "ideiaos-readme-reminder.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook ideiaos-readme-reminder registrado em ~/.claude/settings.json"
else
  warn "Hook ideiaos-readme-reminder NÃO registrado — adicione em hooks.PostToolUse:"
  cat <<'SNIPPET'

       {
         "matcher": "Edit|Write|MultiEdit",
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/ideiaos-readme-reminder.sh\"",
             "timeout": 3
           }
         ]
       }
SNIPPET
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.9) Pre-commit Git no clone do IdeiaOS (se aplicável)"
# Só dispara se estamos rodando dentro de um clone do IdeiaOS.

if [ "$SETUP_DIR" = "$PWD" ] || git -C "$SETUP_DIR" rev-parse --git-dir &>/dev/null; then
  PRECOMMIT_FILE="$SETUP_DIR/.git/hooks/pre-commit"
  if [ -f "$PRECOMMIT_FILE" ] && grep -qF "ideiaos-readme-sync-hook" "$PRECOMMIT_FILE" 2>/dev/null; then
    ok "Pre-commit hook do IdeiaOS já instalado"
  else
    warn "Pre-commit hook do IdeiaOS NÃO instalado. Para ativar:"
    echo "       bash \"$SETUP_DIR/scripts/install-git-hooks.sh\""
    echo "       (Bloqueia commits ao IdeiaOS que mexem em componentes sem atualizar README)"
  fi
else
  ok "Não estamos em clone do IdeiaOS — pulando pre-commit hook"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.12) Hook Claude Code — deia-trigger (UserPromptSubmit)"
# Detecta "Deia, …" no início de mensagens e injeta orientação para ativar
# /idea. Permite que o usuário chame o orquestrador IdeiaOS por nome
# ("Deia, faz X") em vez do comando /idea.

DEIA_HOOK="$HOOK_DIR/deia-trigger.sh"
DEIA_HOOK_TEMPLATE="$SETUP_DIR/source/hooks/deia-trigger.sh"

if [ -f "$DEIA_HOOK" ]; then
  if diff -q "$DEIA_HOOK_TEMPLATE" "$DEIA_HOOK" &>/dev/null; then
    ok "Hook deia-trigger já está na versão mais recente"
  else
    cp "$DEIA_HOOK_TEMPLATE" "$DEIA_HOOK"
    chmod +x "$DEIA_HOOK"
    ok "Hook deia-trigger atualizado"
  fi
else
  cp "$DEIA_HOOK_TEMPLATE" "$DEIA_HOOK"
  chmod +x "$DEIA_HOOK"
  ok "Hook deia-trigger instalado → $DEIA_HOOK"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "deia-trigger.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook deia-trigger registrado em ~/.claude/settings.json"
else
  warn "Hook deia-trigger NÃO registrado — adicione em hooks.UserPromptSubmit:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/deia-trigger.sh\"",
             "timeout": 2
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: prefixo 'Deia,' ou 'Deia ' no início da mensagem"
echo "     ativa automaticamente a skill /idea (orquestrador IdeiaOS)."

# ─────────────────────────────────────────────────────────────────────────────
step "5.13) MCP Claude Code — chrome-devtools (auditoria de browser)"
# Chrome DevTools MCP — audita console, rede e erros do browser diretamente
# no Claude Code via ferramentas mcp__chrome-devtools__*.
# Escopo: user (disponível em todos os projetos desta máquina).
# Repo: https://github.com/ChromeDevTools/chrome-devtools-mcp

if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI não encontrado — MCP chrome-devtools não configurado"
  warn "Após instalar o Claude Code CLI, rode:"
  echo "       claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest"
elif claude mcp get chrome-devtools 2>/dev/null | grep -q "chrome-devtools"; then
  ok "MCP chrome-devtools já configurado (user scope)"
else
  if claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest 2>/dev/null; then
    ok "MCP chrome-devtools instalado (user scope) — disponível em todos os projetos"
  else
    warn "Falha ao instalar MCP chrome-devtools — instale manualmente:"
    echo "       claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp@latest"
  fi
fi

echo "     Uso: abra o Chrome com Remote Debugging ativo, então use"
echo "          list_pages → select_page → list_console_messages / list_network_requests"
echo "          get_network_request(reqid) para ver body real de erros 400/403."

# ─────────────────────────────────────────────────────────────────────────────
step "5.14) MCP Claude Code — context7 (docs de libs ao vivo)"
# Context7 MCP — docs versionadas de 1000+ libs (React 19 vs 18, Tailwind v4 vs v3).
# Referenciado pelas regras de tool-usage e pela suíte de design. Escopo: user.
# Repo: https://github.com/upstash/context7

if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI não encontrado — MCP context7 não configurado"
  warn "Após instalar o Claude Code CLI, rode:"
  echo "       claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest"
elif claude mcp get context7 2>/dev/null | grep -q "context7"; then
  ok "MCP context7 já configurado (user scope)"
else
  if claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest 2>/dev/null; then
    ok "MCP context7 instalado (user scope) — disponível em todos os projetos"
  else
    warn "Falha ao instalar MCP context7 — instale manualmente:"
    echo "       claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp@latest"
  fi
fi

echo "     Uso: resolve-library-id(\"react\") → get-library-docs(topic) para docs atuais."

# ─────────────────────────────────────────────────────────────────────────────
step "5.14b) MCPs no Cursor — chrome-devtools + context7 (~/.cursor/mcp.json)"
# O Cursor usa config PRÓPRIA de MCP (não o 'claude mcp add'). Mescla os mesmos
# servidores no ~/.cursor/mcp.json, preservando os já existentes (idempotente).
if command -v python3 &>/dev/null; then
  CURSOR_MCP_RESULT="$(python3 - <<'PYEOF'
import json, os
p = os.path.expanduser('~/.cursor/mcp.json')
data = {}
if os.path.exists(p):
    try:
        with open(p) as f: data = json.load(f)
    except Exception:
        data = {}
servers = data.setdefault('mcpServers', {})
want = {
    'chrome-devtools': {'command': 'npx', 'args': ['-y', 'chrome-devtools-mcp@latest']},
    'context7':        {'command': 'npx', 'args': ['-y', '@upstash/context7-mcp@latest']},
}
added = [n for n, spec in want.items() if n not in servers and not servers.update({n: spec})]
if added:
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print('instalados: ' + ', '.join(added))
else:
    print('já presentes')
PYEOF
)"
  ok "MCPs no Cursor: ${CURSOR_MCP_RESULT}"
else
  warn "python3 ausente — configure MCP do Cursor manualmente em ~/.cursor/mcp.json"
fi
echo "     (Cursor lê ~/.cursor/mcp.json — reinicie o Cursor para carregar.)"

# ─────────────────────────────────────────────────────────────────────────────
step "5.15) Hook Claude Code — typecheck-on-edit (PostToolUse .ts/.tsx async)"
# Roda tsc --noEmit incremental em background após edição de .ts/.tsx.
# asyncRewake: acorda Claude com erros detectados; silencioso quando OK.
# Não bloqueia — async:true + asyncRewake:true obrigatórios no settings.json.

HOOK_FILE="$HOOK_DIR/typecheck-on-edit.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/typecheck-on-edit.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook typecheck-on-edit já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook typecheck-on-edit atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook typecheck-on-edit instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "typecheck-on-edit.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook typecheck-on-edit registrado em ~/.claude/settings.json"
else
  warn "Hook typecheck-on-edit NÃO registrado — adicione em hooks.PostToolUse:"
  cat <<'SNIPPET'

       {
         "matcher": "Edit|Write",
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/typecheck-on-edit.sh\"",
             "timeout": 60,
             "async": true,
             "asyncRewake": true
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: após editar .ts/.tsx, roda tsc --noEmit incremental em"
echo "     background; acorda Claude apenas se encontrar erros de tipo (asyncRewake)."

# ─────────────────────────────────────────────────────────────────────────────
step "5.16) Hook Claude Code — console-log-guard (PostToolUse Edit|Write)"
# Detecta console.log/debug/info em .ts/.tsx/.js/.jsx após edição.
# Avisa Claude com additionalContext — nunca bloqueia (sem decision:block).

HOOK_FILE="$HOOK_DIR/console-log-guard.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/console-log-guard.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook console-log-guard já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook console-log-guard atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook console-log-guard instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "console-log-guard.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook console-log-guard registrado em ~/.claude/settings.json"
else
  warn "Hook console-log-guard NÃO registrado — adicione em hooks.PostToolUse:"
  cat <<'SNIPPET'

       {
         "matcher": "Edit|Write",
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/console-log-guard.sh\"",
             "timeout": 5
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: detecta console.log/debug/info em .ts/.tsx/.js/.jsx;"
echo "     emite additionalContext para lembrar remover antes de prod Lovable."

# ─────────────────────────────────────────────────────────────────────────────
step "5.17) Hook Claude Code — strategic-compact (PreToolUse — contador de tool calls)"
# Conta tool calls por sessão em /tmp; sugere /compact a cada 50 calls.
# Sem matcher: roda em TODOS os PreToolUse. Silencioso abaixo do limiar.

HOOK_FILE="$HOOK_DIR/strategic-compact.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/strategic-compact.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook strategic-compact já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook strategic-compact atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook strategic-compact instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "strategic-compact.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook strategic-compact registrado em ~/.claude/settings.json"
else
  warn "Hook strategic-compact NÃO registrado — adicione em hooks.PreToolUse:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/strategic-compact.sh\"",
             "timeout": 3
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: incrementa contador por session_id em /tmp; a cada 50"
echo "     tool calls injeta sugestão de /compact para evitar context overflow."

# ─────────────────────────────────────────────────────────────────────────────
step "5.18) Hook Claude Code — precompact-state-save (PreCompact)"
# Salva snapshot de STATE.md antes de /compact — garante que o plano atual
# não seja perdido na compactação. Sem matcher (PreCompact não suporta).

HOOK_FILE="$HOOK_DIR/precompact-state-save.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/precompact-state-save.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook precompact-state-save já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook precompact-state-save atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook precompact-state-save instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "precompact-state-save.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook precompact-state-save registrado em ~/.claude/settings.json"
else
  warn "Hook precompact-state-save NÃO registrado — adicione em hooks.PreCompact:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/precompact-state-save.sh\"",
             "timeout": 10
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: detecta .planning/STATE.md ou STATE.md no cwd;"
echo "     insere seção '## Compact Snapshot' com timestamp antes de /compact."

# ─────────────────────────────────────────────────────────────────────────────
step "5.19) Hook Claude Code — session-summary (Stop)"
# Ao final de cada turno, persiste resumo ECC em ~/.claude/sessions/ e
# atualiza docs/CONTINUATION_HANDOFF.md (se existir no cwd).

HOOK_FILE="$HOOK_DIR/session-summary.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/session-summary.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook session-summary já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
    ok "Hook session-summary atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"
  chmod +x "$HOOK_FILE"
  ok "Hook session-summary instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "session-summary.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook session-summary registrado em ~/.claude/settings.json"
else
  warn "Hook session-summary NÃO registrado — adicione em hooks.Stop:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/session-summary.sh\"",
             "timeout": 30
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: ao final de cada turno, cria ~/.claude/sessions/YYYY-MM-DD-*.tmp"
echo "     com 4 seções ECC; atualiza docs/CONTINUATION_HANDOFF.md se existir no cwd."

# ─────────────────────────────────────────────────────────────────────────────
step "5.20) Hook Claude Code — observe-tool-use (PostToolUse · Continuous Learning v2)"
# Coleta leve de observações (só metadados) em ~/.ideiaos/observations/<projeto>/.
# <100ms, fail-silent, nunca bloqueia o tool use. Insumo do /instinct-analyze.

HOOK_FILE="$HOOK_DIR/observe-tool-use.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/observe-tool-use.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook observe-tool-use já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"; chmod +x "$HOOK_FILE"
    ok "Hook observe-tool-use atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"; chmod +x "$HOOK_FILE"
  ok "Hook observe-tool-use instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "observe-tool-use.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook observe-tool-use registrado em ~/.claude/settings.json"
else
  warn "Hook observe-tool-use NÃO registrado — adicione em hooks.PostToolUse:"
  cat <<'SNIPPET'

       {
         "matcher": "Edit|Write|MultiEdit|Bash",
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/observe-tool-use.sh\"",
             "timeout": 5
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: anexa 1 linha JSON (só metadados) por Edit/Write/Bash em"
echo "     ~/.ideiaos/observations/<projeto>/observations.jsonl. Nunca loga conteúdo/secrets."

# ─────────────────────────────────────────────────────────────────────────────
step "5.21) Hook Claude Code — observe-session-end (Stop · Continuous Learning v2)"
# Marca session_end na observations.jsonl como gatilho de avaliação para /instinct-analyze.
# <100ms, fail-silent.

HOOK_FILE="$HOOK_DIR/observe-session-end.sh"
HOOK_TEMPLATE="$SETUP_DIR/source/hooks/observe-session-end.sh"

if [ -f "$HOOK_FILE" ]; then
  if diff -q "$HOOK_TEMPLATE" "$HOOK_FILE" &>/dev/null; then
    ok "Hook observe-session-end já está na versão mais recente"
  else
    cp "$HOOK_TEMPLATE" "$HOOK_FILE"; chmod +x "$HOOK_FILE"
    ok "Hook observe-session-end atualizado"
  fi
else
  cp "$HOOK_TEMPLATE" "$HOOK_FILE"; chmod +x "$HOOK_FILE"
  ok "Hook observe-session-end instalado → $HOOK_FILE"
fi

if [ -f "$SETTINGS_FILE" ] && grep -q "observe-session-end.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hook observe-session-end registrado em ~/.claude/settings.json"
else
  warn "Hook observe-session-end NÃO registrado — adicione em hooks.Stop:"
  cat <<'SNIPPET'

       {
         "hooks": [
           {
             "type": "command",
             "command": "bash \"/Users/<você>/.claude/hooks/observe-session-end.sh\"",
             "timeout": 10
           }
         ]
       }
SNIPPET
fi

echo "     Comportamento: marca session_end na observations.jsonl como gatilho de"
echo "     avaliação para /instinct-analyze. Insumo do Continuous Learning v2."

# ─────────────────────────────────────────────────────────────────────────────
step "5.21b) Skills do manifesto (installStrategy: always → ~/.claude/skills)"
# Instala TODA skill do manifests/modules.json com installStrategy=always e
# target claude que ainda não esteja em ~/.claude/skills — fecha o gap em que
# skills absorvidas (ECC, instincts, catalog) existiam só em source/.
# Skills stack:*/manual NÃO são instaladas globalmente (instalação por projeto).
MANIFEST="$SETUP_DIR/manifests/modules.json"
if [ -f "$MANIFEST" ]; then
  INSTALLED_SKILLS="$(/usr/bin/python3 - "$MANIFEST" "$SETUP_DIR" "$HOME/.claude/skills" <<'PYEOF'
import json, os, shutil, sys, subprocess
manifest, setup_dir, dst_root = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    mods = json.load(open(manifest))["modules"]
except Exception:
    sys.exit(0)

def _dirs_differ(a, b):
    # content-aware, MESMA semântica do idea-doctor (`diff -rq`): detecta diferença
    # em QUALQUER subdir (lib/, references/, data/), não só no SKILL.md. Antes o
    # gate comparava só SKILL.md e copiava só SKILL.md — mudança só em lib/ (sem
    # bump de versão) ficava órfã no global = drift silencioso (ex.: libs do /spec).
    return subprocess.run(["diff", "-rq", a, b],
                          stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode != 0

count = 0
for m in mods:
    if m.get("kind") != "skill" or m.get("installStrategy") != "always":
        continue
    if "claude" not in (m.get("targets") or []):
        continue
    name = m["id"].replace("skill-", "", 1)
    src = os.path.join(setup_dir, "source", "skills", name)
    dst = os.path.join(dst_root, name)
    if not os.path.isdir(src):
        continue
    try:
        if not os.path.isdir(dst):
            shutil.copytree(src, dst)
            count += 1
        elif _dirs_differ(src, dst):
            # re-espelha o diretório INTEIRO (rmtree + copytree), não só SKILL.md.
            shutil.rmtree(dst)
            shutil.copytree(src, dst)
            count += 1
    except Exception:
        pass
print(count)
PYEOF
)"
  if [ "${INSTALLED_SKILLS:-0}" -gt 0 ] 2>/dev/null; then
    ok "Skills do manifesto instaladas/atualizadas: $INSTALLED_SKILLS"
  else
    ok "Skills do manifesto já em dia (installStrategy: always)"
  fi
else
  warn "manifests/modules.json não encontrado — instalação por manifesto pulada"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.22) Contexts de modo + aliases claude-dev/review/research (T-01-10)"
# Implanta os 3 contexts em ~/.ideiaos/contexts/ e OFERECE (via snippet) as
# funções shell que chamam claude --append-system-prompt. Nunca edita .zshrc/.bashrc.
# T-01-10: setup.sh nunca auto-edita dotfiles ou settings.json do usuário.

CONTEXTS_SRC="$SETUP_DIR/source/contexts"
CONTEXTS_DEST="$HOME/.ideiaos/contexts"
mkdir -p "$CONTEXTS_DEST"

for mode in dev review research; do
  src_file="$CONTEXTS_SRC/${mode}.md"
  if [ -f "$src_file" ]; then
    cp "$src_file" "$CONTEXTS_DEST/${mode}.md"
    ok "Context implantado: ~/.ideiaos/contexts/${mode}.md"
  else
    warn "Context não encontrado: ${src_file} — certifique-se de rodar após 07-01 (Wave 1)"
  fi
done

# Verificar se os aliases já estão nos rc do shell
if grep -qF "alias claude-review=" "$HOME/.zshrc" 2>/dev/null \
   || grep -qF "alias claude-review=" "$HOME/.bashrc" 2>/dev/null \
   || grep -qF "claude-review()" "$HOME/.zshrc" 2>/dev/null \
   || grep -qF "claude-review()" "$HOME/.bashrc" 2>/dev/null; then
  ok "Aliases de modo já configurados (~/.zshrc ou ~/.bashrc)"
else
  warn "Aliases claude-dev/review/research NÃO configurados — adicione ao seu rc de shell:"
  cat <<'SNIPPET'

       # IdeiaOS — Modos de contexto Claude (cole no ~/.zshrc ou ~/.bashrc)
       # Usa --append-system-prompt: adiciona ao prompt padrão (preserva CLAUDE.md,
       # hooks e memória automáticos). Não use --system-prompt (substitui tudo).
       claude-dev()      { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/dev.md")" "$@"; }
       claude-review()   { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/review.md")" "$@"; }
       claude-research() { claude --append-system-prompt "$(cat "$HOME/.ideiaos/contexts/research.md")" "$@"; }
SNIPPET
  echo "     Os contextos já foram implantados em ~/.ideiaos/contexts/."
  echo "     Após adicionar as funções e recarregar o shell, use:"
  echo "       claude-review  ← abre em modo review (análise, não edição)"
  echo "       claude-dev     ← abre em modo dev (implementação + qualidade)"
  echo "       claude-research← abre em modo research (deep research)"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.23) Statusline IdeiaOS — deploy + snippet settings.json (T-01-10)"
# Implanta o script em ~/.ideiaos/statusline/ e OFERECE (via snippet) o campo
# statusLine para ~/.claude/settings.json. Nunca auto-edita settings.json.
# T-01-10: setup.sh nunca auto-edita dotfiles ou settings.json do usuário.

STATUSLINE_SRC="$SETUP_DIR/source/statusline/ideiaos-statusline.sh"
STATUSLINE_DEST_DIR="$HOME/.ideiaos/statusline"
STATUSLINE_DEST="$STATUSLINE_DEST_DIR/ideiaos-statusline.sh"

mkdir -p "$STATUSLINE_DEST_DIR"

if [ -f "$STATUSLINE_SRC" ]; then
  cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"
  chmod +x "$STATUSLINE_DEST"
  ok "Statusline implantada: ~/.ideiaos/statusline/ideiaos-statusline.sh"
else
  warn "Statusline não encontrada: ${STATUSLINE_SRC} — certifique-se de rodar após 07-01 (Wave 1)"
fi

# Verificar se já está registrada em ~/.claude/settings.json
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ] && grep -q "ideiaos-statusline.sh" "$SETTINGS_FILE" 2>/dev/null; then
  ok "Statusline IdeiaOS já registrada em ~/.claude/settings.json"
else
  warn "Statusline IdeiaOS NÃO registrada em ~/.claude/settings.json — adicione manualmente:"
  cat <<'SNIPPET'

       Adicione (ou mescle) o campo statusLine no ~/.claude/settings.json:

       {
         "statusLine": {
           "type": "command",
           "command": "bash /Users/<você>/.ideiaos/statusline/ideiaos-statusline.sh"
         }
       }

       Substitua /Users/<você> pelo seu home real (ex: /Users/gustavo).
       IMPORTANTE: este arquivo NÃO foi modificado pelo setup.sh (regra T-01-10).
SNIPPET
fi

# ─────────────────────────────────────────────────────────────────────────────
step "5.10) Skill Claude Code — /idea (orquestrador IdeiaOS)"
# Comando único de entrada do IdeiaOS — roteia entre GSD/AIOX/Lovable/Fase A
# automaticamente baseado no que o usuário pediu.

IDEA_SKILL_DIR="$HOME/.claude/skills/idea"
IDEA_SKILL="$IDEA_SKILL_DIR/SKILL.md"
IDEA_TEMPLATE="$SETUP_DIR/source/skills/idea/SKILL.md"

mkdir -p "$IDEA_SKILL_DIR"

if [ -f "$IDEA_SKILL" ]; then
  if diff -q "$IDEA_TEMPLATE" "$IDEA_SKILL" &>/dev/null; then
    ok "Skill /idea já está na versão mais recente"
  else
    cp "$IDEA_TEMPLATE" "$IDEA_SKILL"
    ok "Skill /idea atualizada"
  fi
else
  cp "$IDEA_TEMPLATE" "$IDEA_SKILL"
  ok "Skill /idea instalada → $IDEA_SKILL"
fi

echo "     Uso: /idea <pedido em linguagem natural> — roteia automaticamente"
echo "          Ex: /idea quero adicionar autenticação OAuth"
echo "          Ex: /idea preciso retomar de onde parei"

# ─────────────────────────────────────────────────────────────────────────────
step "5.11) GSD readiness check (orquestração goal-backward)"
# GSD vem com o ambiente Claude Code (skills /gsd-* globais). Aqui só verificamos
# disponibilidade e avisamos se faltar — não instalamos nada (vem por padrão).

GSD_SKILLS_DIR="$HOME/.claude/skills"
GSD_DETECTED=0
if compgen -G "$GSD_SKILLS_DIR/gsd-*" > /dev/null 2>&1; then
  GSD_COUNT="$(ls -d "$GSD_SKILLS_DIR"/gsd-* 2>/dev/null | wc -l | tr -d ' ')"
  ok "GSD detectado: $GSD_COUNT skills /gsd-* disponíveis"
  GSD_DETECTED=1
else
  warn "GSD não detectado em $GSD_SKILLS_DIR"
  warn "GSD vem com Claude Code via plugins — instale via /plugins ou habilite o pacote GSD"
  echo "       Skills esperadas: /gsd-do, /gsd-quick, /gsd-plan-phase, /gsd-execute-phase, /gsd-new-project"
fi

# ─────────────────────────────────────────────────────────────────────────────
step "6) Skills Claude Code — recall-learnings + extract-learnings"
# Loop de aprendizado contínuo (universal — qualquer projeto)

for SKILL_NAME in recall-learnings extract-learnings; do
  L_DIR="$HOME/.claude/skills/$SKILL_NAME"
  L_FILE="$L_DIR/SKILL.md"
  L_TEMPLATE="$SETUP_DIR/source/skills/$SKILL_NAME/SKILL.md"

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

# ─────────────────────────────────────────────────────────────────────────────
step "6.1) Skills de design (dev-loop) — frontend-visual-loop + motion + web-quality"
# Skills próprias do IdeiaOS, com pasta references/ (cp -R, não só SKILL.md).
# Complementam a Suíte de Design externa (ui-ux-pro-max etc.). Globais — valem
# pra qualquer projeto. Loop visual, animação e auditoria CWV/WCAG/SEO sobre o
# Chrome DevTools MCP já instalado (sem Playwright).

for SKILL_NAME in frontend-visual-loop motion web-quality; do
  D_DIR="$HOME/.claude/skills/$SKILL_NAME"
  D_TEMPLATE="$SETUP_DIR/source/skills/$SKILL_NAME"

  if [ -d "$D_DIR" ] && diff -rq "$D_TEMPLATE" "$D_DIR" &>/dev/null; then
    ok "Skill $SKILL_NAME já está na versão mais recente"
  else
    rm -rf "$D_DIR"
    cp -R "$D_TEMPLATE" "$D_DIR"
    ok "Skill $SKILL_NAME instalada/atualizada → $D_DIR"
  fi
done

echo "     Uso: /frontend-visual-loop · /motion · /web-quality (globais, qualquer projeto)"

# ─────────────────────────────────────────────────────────────────────────────
step "6.2) Suíte de Design (vendorizada) — ui-ux-pro-max + 6 skills"
# Vendorizada no repo (fonte única: nextlevelbuilder/ui-ux-pro-max-skill, MIT).
# Antes vinha de clone manual; agora replica direto do repo IdeiaOS. cp -R porque
# têm data/, references/, scripts/. O OKLCH é aplicado por cima via overlay (Patch 7).

for SKILL_NAME in ui-ux-pro-max design design-system ui-styling brand banner-design slides; do
  G_DIR="$HOME/.claude/skills/$SKILL_NAME"
  G_TEMPLATE="$SETUP_DIR/source/skills/$SKILL_NAME"

  if [ ! -d "$G_TEMPLATE" ]; then
    warn "Suíte: $SKILL_NAME ausente no repo — rode scripts/update-design-suite.sh"
    continue
  fi
  if [ -d "$G_DIR" ] && diff -rq "$G_TEMPLATE" "$G_DIR" &>/dev/null; then
    ok "Skill $SKILL_NAME já está na versão mais recente"
  else
    rm -rf "$G_DIR"
    cp -R "$G_TEMPLATE" "$G_DIR"
    ok "Skill $SKILL_NAME instalada/atualizada → $G_DIR"
  fi
done

echo "     Atualizar do upstream: bash scripts/update-design-suite.sh (controlado, sob demanda)"

else
  step "2-6) Setup global"
  warn "Modo --project-only ativo: pulando AIOX Core + instalação global de agentes/skills"
fi

# --global-only: instala/atualiza só os componentes globais (skills, MCPs, hooks,
# agentes Cursor) e encerra ANTES de configurar um projeto. Usado por sync-all.sh
# e pelo bootstrap setup-dev-machine.sh para refresh do ambiente global.
if [ "$GLOBAL_ONLY" = 1 ]; then
  ok "Modo --global-only: setup global concluído (config de projeto pulada)"
  exit 0
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
    cp "$SETUP_DIR/source/templates/aiox-ai-config.yaml" ".aiox-ai-config.yaml"
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
        # --quiet --merge: não-interativo + preserva configs existentes (brownfield)
        if npx aiox-core@latest install --quiet --merge </dev/null; then
          if [ -d ".aiox-core" ]; then
            ok "AIOX Core inicializado no projeto (.aiox-core)"
            echo "      ℹ️  .aiox-core é local-only (gitignored, ~58M). Em clone novo/máquina nova,"
            echo "         rode: npx aiox-core@latest install  (igual a 'npm install'). As personas"
            echo "         (@dev/@qa/@architect) e o /idea (Deia) já são globais — funcionam sem isso."
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

  # .planning/ para GSD (camada IdeiaOS — orquestração goal-backward)
  if [ ! -d ".planning" ]; then
    mkdir -p .planning/phases .planning/intel .planning/research
    ok ".planning/ criado (com phases/intel/research) — rode /gsd-new-project no Claude Code"
  else
    # Garante subpastas mínimas mesmo em projetos legados
    mkdir -p .planning/phases .planning/intel .planning/research
    ok ".planning/ já existe (subpastas asseguradas)"
  fi

  # .gitignore — proteções mínimas
  # ADR docs/decisions/aiox-gitignore-npx-vs-global.md: AIOX Core é tratado como
  # node_modules — instalado por máquina via `npx aiox-core@latest install` e NUNCA
  # versionado (.aiox-core/ ~58M + agentes multi-IDE). A camada de instrução (GSD,
  # /idea, personas AIOX) é global; só o engine/estado fica por-máquina.
  if [ ! -f ".gitignore" ]; then touch .gitignore; fi
  added=0
  for entry in ".env" ".env.local" "node_modules/" ".aiox/" \
               ".aiox-core/" ".antigravity/" ".codex/" ".gemini/" ".kimi/" \
               ".cursor/rules/agents/" ".github/agents/"; do
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
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/AGENTS.md.tmpl" "$PROJECT_DIR/AGENTS.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/CLAUDE.md.tmpl" "$PROJECT_DIR/CLAUDE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/STATE.md.tmpl" "$PROJECT_DIR/STATE.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/CONTINUATION_HANDOFF.md.tmpl" "$PROJECT_DIR/docs/CONTINUATION_HANDOFF.md" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/session-continuation.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/session-continuation.mdc" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/agents-md-protocol.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/agents-md-protocol.mdc" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/planning-branch.mdc.tmpl" "$PROJECT_DIR/.cursor/rules/planning-branch.mdc" "$PROJECT_NAME"
  ensure_file_from_template "$SETUP_DIR/source/templates/hybrid/CONTRIBUTING.md.tmpl" "$PROJECT_DIR/CONTRIBUTING.md" "$PROJECT_NAME"

  # Common rules (R8-09): source/rules/common/ → .cursor/rules/ideiaos-*.mdc +
  # .claude/rules/ideiaos-common-*.md (paridade Claude×Cursor). build-adapters é a
  # ferramenta canônica de deploy de rule; chamá-la AQUI garante que a via de
  # propagação (apply-to-all-projects → setup.sh --project-only) entregue as common
  # rules — antes ela era pulada (gap R8-09 vs propagate). Fail-soft: nunca aborta o setup.
  if [ -f "$SETUP_DIR/scripts/build-adapters.sh" ]; then
    if bash "$SETUP_DIR/scripts/build-adapters.sh" --target cursor --project-dir "$PROJECT_DIR" >/dev/null; then
      ok "Common rules (R8-09) deployadas: .cursor/rules/ideiaos-* + .claude/rules/ideiaos-common-*"
    else
      warn "build-adapters falhou ao deployar common rules (setup segue normalmente)"
    fi
  else
    warn "scripts/build-adapters.sh ausente — common rules (R8-09) não deployadas"
  fi

  # Camada Lovable (detector + flags --lovable / --no-lovable)
  setup_lovable_project "$PROJECT_DIR" "$PROJECT_NAME"

  # Camada TypeScript LSP (stack:typescript — primeira consumidora real de detect_stack)
  TARGET_PROJ="${PROJECT_DIR:-$PWD}"
  DETECTED_STACKS="$(detect_stack "$TARGET_PROJ")"
  if echo "$DETECTED_STACKS" | grep -qw "typescript"; then
    TSCONFIG_PATH="$(find "$TARGET_PROJ" -name tsconfig.json -maxdepth 2 2>/dev/null | head -1)"
    if [ -n "$TSCONFIG_PATH" ]; then
      ok "TypeScript LSP: tsconfig.json encontrado em $TSCONFIG_PATH (módulo typescript-lsp ativo)"
    else
      warn "TypeScript LSP: stack typescript detectado mas tsconfig.json não encontrado — LSP não ativado"
    fi
  fi

  # Camada de aprendizado contínuo (universal — qualquer projeto)
  setup_learnings_layer "$PROJECT_DIR" "$PROJECT_NAME"

  # Camada IdeiaOS (orquestração GSD + AIOX + Lovable + Fase A)
  setup_ideiaos_layer "$PROJECT_DIR" "$PROJECT_NAME"

  # Camada de Frescor de Segurança (v13 — hook advisory local, por produto)
  setup_security_freshness_layer "$PROJECT_DIR" "$PROJECT_NAME"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗"
echo    "║          IdeiaOS — Setup concluído! ✓               ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}IdeiaOS: Sistema Operacional unificado para dev IA${NC}"
echo "  Camadas ativas: AIOX-Core + GSD + Lovable + Fase A + Continuation"
echo ""
echo -e "  ${BOLD}Comando único de entrada (recomendado):${NC}"
echo "  → ${BOLD}/idea <pedido em linguagem natural>${NC}  (Claude Code)"
echo "       Roteia automaticamente para a camada certa:"
echo "       /gsd-* (execução), @dev/@qa/@pm (AIOX), /lovable-handoff, etc"
echo ""
echo -e "  ${BOLD}Comandos diretos por contexto:${NC}"
echo "  • Setup de projeto         → /ideiaos-setup  (Claude)  ·  @ideiaos-checker  (Cursor)"
echo "  • Continuar trabalho       → /cursor-continuation  ·  @claude-continuation"
echo "  • Implantação Lovable      → /lovable-handoff"
echo "  • Loop de aprendizado      → /recall-learnings (início) · /extract-learnings (fim)"
echo "  • Execução goal-backward   → /gsd-do, /gsd-quick, /gsd-plan-phase"
echo "  • Personas AIOX            → @dev, @qa, @pm, @architect, @po, @sm, @devops"
echo ""
echo -e "  ${BOLD}Documentação no projeto:${NC}"
echo "  • IDEIAOS.md                       (manifesto na raiz)"
echo "  • docs/ideiaos/GUIDE-HUMANS.md     (guia para devs)"
echo "  • docs/ideiaos/GUIDE-AI.md         (guia para IAs)"
echo "  • docs/ideiaos/DECISION-MATRIX.md  (qual ferramenta para qual tarefa)"
echo ""
echo -e "  ${BOLD}Para outro projeto:${NC}"
echo "  → bash $SETUP_DIR/setup.sh --project-only /caminho/do/projeto"
echo "  → ou (com alias): cd projeto && idea-setup"
echo ""
