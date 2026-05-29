#!/bin/bash
# check-readme-sync.sh — audita se o README menciona todos os componentes do repo.
#
# Componentes auditados:
#   - hooks/*.sh
#   - skills/*/SKILL.md (verifica nome da skill, não o path do SKILL.md)
#   - agents/*.md
#   - scripts/*.sh
#   - templates/**/*.tmpl (verifica nome lógico, sem .tmpl)
#
# Output:
#   ✅ por componente mencionado
#   ❌ por componente ausente
#   Exit code: 0 se sincronizado, 1 se faltar algo.
#
# Uso:
#   bash scripts/check-readme-sync.sh          # rodar na raiz do IdeiaOS
#   bash scripts/check-readme-sync.sh /caminho # explicitar dir do IdeiaOS

set -uo pipefail

REPO_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
README="$REPO_DIR/README.md"

if [ ! -f "$README" ]; then
  echo "❌ README.md não encontrado em $REPO_DIR"
  exit 1
fi

MISSING=0
TOTAL=0
MENTIONED=0

check_mentioned() {
  local label="$1" pattern="$2"
  TOTAL=$((TOTAL + 1))
  if grep -qF "$pattern" "$README" 2>/dev/null; then
    echo "  ✅ $label"
    MENTIONED=$((MENTIONED + 1))
  else
    echo "  ❌ $label — NÃO mencionado no README (busca: \"$pattern\")"
    MISSING=$((MISSING + 1))
  fi
}

echo "🔍 Auditoria de sincronização README ↔ componentes do repo"
echo "   Repo: $REPO_DIR"
echo ""

echo "📁 Hooks (hooks/*.sh)"
for f in "$REPO_DIR"/hooks/*.sh; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  check_mentioned "$name" "$name"
done

echo ""
echo "📁 Skills (skills/*/SKILL.md)"
for d in "$REPO_DIR"/skills/*/; do
  [ -e "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  check_mentioned "/$name (skill)" "/$name"
done

echo ""
echo "📁 Agents (agents/*.md)"
for f in "$REPO_DIR"/agents/*.md; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .md)"
  check_mentioned "@$name (agent)" "$name"
done

echo ""
echo "📁 Scripts (scripts/*.sh)"
for f in "$REPO_DIR"/scripts/*.sh; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  check_mentioned "$name" "$name"
done

echo ""
echo "📁 Templates de projeto (templates/**/*.tmpl)"
while IFS= read -r f; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .tmpl)"
  check_mentioned "$name (template)" "$name"
done < <(find "$REPO_DIR/templates" -name "*.tmpl" 2>/dev/null)

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Resumo: $MENTIONED/$TOTAL mencionados · $MISSING faltando"
echo "═══════════════════════════════════════════════════════════"

if [ "$MISSING" -gt 0 ]; then
  echo ""
  echo "❌ README desatualizado. Atualize as seções:"
  echo "   - \"O que este setup instala\" (tabela de componentes globais)"
  echo "   - \"Estrutura do repositório\" (árvore)"
  exit 1
fi

echo ""
echo "✅ README sincronizado."
exit 0
