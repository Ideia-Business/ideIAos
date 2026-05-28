#!/bin/bash
# install-git-hooks.sh — instala pre-commit hook que valida README sync.
#
# Rodar uma vez após clone:
#   bash scripts/install-git-hooks.sh
#
# Idempotente: substitui pre-commit existente se for nosso (detecta por marker).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_DIR/.git/hooks"
PRECOMMIT="$HOOKS_DIR/pre-commit"
MARKER="# dev-setup-readme-sync-hook"

if [ ! -d "$HOOKS_DIR" ]; then
  echo "❌ $HOOKS_DIR não existe. Estamos em um clone Git válido?"
  exit 1
fi

# Se já tem nosso hook, atualizar
if [ -f "$PRECOMMIT" ] && grep -qF "$MARKER" "$PRECOMMIT" 2>/dev/null; then
  echo "✅ Pre-commit já instalado — substituindo pela versão atual..."
elif [ -f "$PRECOMMIT" ]; then
  echo "⚠️  $PRECOMMIT já existe e NÃO é nosso. Backup em pre-commit.bak"
  cp "$PRECOMMIT" "$PRECOMMIT.bak"
fi

cat > "$PRECOMMIT" <<'HOOK'
#!/bin/bash
# dev-setup-readme-sync-hook
# Bloqueia commits que mexam em hooks/, skills/, agents/, scripts/ ou templates/
# se o README.md não estiver incluído (presumindo que precisa atualizar) OU
# se o check-readme-sync.sh falhar.

set -uo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
SCRIPT="$REPO_DIR/scripts/check-readme-sync.sh"

# Quais arquivos estão sendo commitados?
STAGED="$(git diff --cached --name-only --diff-filter=ACMR)"

# Algum em pasta de componente?
TOUCHES_COMPONENTS=0
if echo "$STAGED" | grep -qE '^(hooks|skills|agents|scripts|templates)/'; then
  TOUCHES_COMPONENTS=1
fi

# Se não mexeu em componente, deixa passar.
if [ "$TOUCHES_COMPONENTS" -eq 0 ]; then
  exit 0
fi

# README está no commit? Se sim, presume que dev atualizou.
if echo "$STAGED" | grep -qE '^README\.md$'; then
  # Mas mesmo assim, rodar check só pra garantir.
  if [ -x "$SCRIPT" ] && ! bash "$SCRIPT" "$REPO_DIR" > /tmp/readme-sync-check.log 2>&1; then
    echo "❌ README.md está no commit mas check-readme-sync falhou:"
    cat /tmp/readme-sync-check.log
    echo ""
    echo "Atualize as seções faltando ou rode com --no-verify (não recomendado)."
    exit 1
  fi
  exit 0
fi

# Mexeu em componente mas NÃO incluiu README. Rodar check.
if [ ! -x "$SCRIPT" ]; then
  echo "⚠️  $SCRIPT não encontrado/executável — pulando validação."
  exit 0
fi

if ! bash "$SCRIPT" "$REPO_DIR" > /tmp/readme-sync-check.log 2>&1; then
  echo ""
  echo "❌ Você modificou componentes (hooks/skills/agents/scripts/templates) mas"
  echo "   o README.md não está no commit E está dessincronizado."
  echo ""
  cat /tmp/readme-sync-check.log
  echo ""
  echo "Opções:"
  echo "  1. Atualizar README.md e incluir no commit (recomendado)"
  echo "  2. git commit --no-verify (bypassa esta validação — não recomendado)"
  exit 1
fi
HOOK

chmod +x "$PRECOMMIT"

echo "✅ Pre-commit hook instalado em $PRECOMMIT"
echo ""
echo "A partir de agora, commits que tocarem em hooks/skills/agents/scripts/templates"
echo "sem atualizar README.md serão BLOQUEADOS."
echo ""
echo "Para bypassar em casos excepcionais:"
echo "  git commit --no-verify -m \"...\""
