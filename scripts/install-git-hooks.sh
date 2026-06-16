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
PREMERGE="$HOOKS_DIR/pre-merge-commit"
MARKER="# ideiaos-readme-sync-hook"
MERGE_MARKER="# ideiaos-memory-merge-guard"

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

# ── Guarda de memória (Lovable-safe) ─────────────────────────────────────────
# Bloqueia memória (.planning/memory/, .lovable_mem_tmp.md, .cursor/rules/
# memory-bridge.mdc) staged quando o branch corrente é `main` — a Lovable Cloud
# lê `main` e um commit de memória dispara Update indevido. Mensagem direcional.
# Bypass consciente: IDEIAOS_MEM_OVERRIDE=1 git commit ...
MCHECK="$REPO_DIR/scripts/check-memory-not-on-main.sh"
if [ -f "$MCHECK" ] && ! bash "$MCHECK" --staged; then
  echo ""
  echo "❌ Commit bloqueado: guarda de memória falhou (acima)."
  exit 1
fi

# ── Guarda de membership de plugins (anti-deriva v7, Fase 2) ─────────────────
# Bloqueia commit que toque o manifesto ou os arrays de build se houver deriva
# entre as atribuições plugin: do modules.json e os arrays de build-plugins.sh
# (o bug que deixou spec/forge-agent/memory-sync de fora do empacotamento).
if echo "$STAGED" | grep -qE '^(manifests/modules\.json|manifests/plugin-membership\.md|scripts/build-plugins\.sh)$'; then
  PMCHECK="$REPO_DIR/scripts/check-plugin-membership.sh"
  if [ -f "$PMCHECK" ] && ! bash "$PMCHECK" > /tmp/plugin-membership-check.log 2>&1; then
    echo ""
    echo "❌ Commit bloqueado: deriva de membership de plugins (manifesto×build-plugins.sh):"
    cat /tmp/plugin-membership-check.log
    echo ""
    echo "Corrija o array em scripts/build-plugins.sh + manifests/plugin-membership.md (ou --no-verify)."
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

# ── pre-merge-commit: barra merge planning→main de memória ────────────────────
# Roda ANTES do commit de merge ser criado. Bloqueia um merge `planning`→`main`
# (a memória vive no planning e nunca pode aterrissar no main). Idempotente.
if [ -f "$PREMERGE" ] && ! grep -qF "$MERGE_MARKER" "$PREMERGE" 2>/dev/null; then
  echo "⚠️  $PREMERGE já existe e NÃO é nosso. Backup em pre-merge-commit.bak"
  cp "$PREMERGE" "$PREMERGE.bak"
fi

cat > "$PREMERGE" <<'MERGEHOOK'
#!/bin/bash
# ideiaos-memory-merge-guard
# Bloqueia merge planning→main (e qualquer memória entrando no main via merge).
# A Lovable Cloud lê `main`; memória ali dispara Update indevido. Direcional.
# Bypass consciente: IDEIAOS_MEM_OVERRIDE=1 git merge ...

set -uo pipefail

REPO_DIR="$(git rev-parse --show-toplevel)"
MCHECK="$REPO_DIR/scripts/check-memory-not-on-main.sh"

if [ -f "$MCHECK" ] && ! bash "$MCHECK" --merge; then
  echo ""
  echo "❌ Merge bloqueado: guarda de memória falhou (acima)."
  exit 1
fi
MERGEHOOK

chmod +x "$PREMERGE"

echo "✅ Pre-merge-commit hook instalado em $PREMERGE"
echo "✅ Pre-commit hook instalado em $PRECOMMIT"
echo ""
echo "A partir de agora, commits que tocarem em source/scripts/plugins/manifests"
echo "sem atualizar README.md serão BLOQUEADOS."
echo ""
echo "Para bypassar em casos excepcionais:"
echo "  git commit --no-verify -m \"...\""
