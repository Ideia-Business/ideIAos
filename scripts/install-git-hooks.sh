#!/bin/bash
# install-git-hooks.sh — instala pre-commit hook que valida README sync e
# protege o versions.lock (pin GSD) contra reverts pré-redux/edição manual.
#
# Rodar uma vez após clone:
#   bash scripts/install-git-hooks.sh
#
# Idempotente: substitui pre-commit existente se for nosso (detecta por marker).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_DIR/.git/hooks"
PRECOMMIT="$HOOKS_DIR/pre-commit"
MARKER="# ideiaos-readme-sync-hook"

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
# ideiaos-readme-sync-hook
# Bloqueia commits que mexam em source/, scripts/, plugins/ ou manifests/
# se o README.md não estiver incluído (presumindo que precisa atualizar) OU
# se o check-readme-sync.sh falhar.

set -uo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
SCRIPT="$REPO_DIR/scripts/check-readme-sync.sh"

# Quais arquivos estão sendo commitados?
STAGED="$(git diff --cached --name-only --diff-filter=ACMRD)"

# ── Guarda do versions.lock (pin GSD) ────────────────────────────────────────
# Bloqueia: (a) valor pré-redux legado (1.3x/1.4x — ver check-versions-lock.sh);
#           (b) edição manual do pin que não corresponde à versão instalada.
# Bypass consciente: IDEIAOS_LOCK_OVERRIDE=1 git commit ...
if echo "$STAGED" | grep -qx 'versions.lock'; then
  VCHECK="$REPO_DIR/scripts/check-versions-lock.sh"
  if [ -f "$VCHECK" ] && ! bash "$VCHECK" --staged; then
    echo ""
    echo "❌ Commit bloqueado: versions.lock falhou na validação do pin (acima)."
    exit 1
  fi
fi

# Algum em pasta de componente?
TOUCHES_COMPONENTS=0
if echo "$STAGED" | grep -qE '^(source|scripts|plugins|manifests)/'; then
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
  echo "❌ Você modificou componentes (source/scripts/plugins/manifests) mas"
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
echo "A partir de agora, commits que tocarem em source/scripts/plugins/manifests"
echo "sem atualizar README.md serão BLOQUEADOS."
echo ""
echo "Para bypassar em casos excepcionais:"
echo "  git commit --no-verify -m \"...\""
