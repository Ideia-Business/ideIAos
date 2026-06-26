#!/bin/bash
# check-readme-sync.sh — audita se o README menciona todos os componentes do repo.
#
# Componentes auditados (todos em source/):
#   - source/hooks/*.sh (excluídos: test-*.sh — não são componentes de produto)
#   - source/skills/*/SKILL.md (verifica nome da skill, não o path do SKILL.md)
#   - source/agents/*.md
#   - scripts/*.sh
#   - source/templates/**/*.tmpl (verifica nome lógico, sem .tmpl)
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

echo "📁 Hooks (source/hooks/*.sh — excluídos: test-*)"
for f in "$REPO_DIR"/source/hooks/*.sh; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  # Excluir test-hooks — não são componentes de produto
  case "$name" in test-*) continue;; esac
  check_mentioned "$name" "$name"
done

echo ""
echo "📁 Skills (source/skills/*/SKILL.md)"
for d in "$REPO_DIR"/source/skills/*/; do
  [ -e "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  check_mentioned "/$name (skill)" "/$name"
done

echo ""
echo "📁 Agents (source/agents/*.md)"
for f in "$REPO_DIR"/source/agents/*.md; do
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
echo "📁 Templates de projeto (source/templates/**/*.tmpl)"
while IFS= read -r f; do
  [ -e "$f" ] || continue
  name="$(basename "$f" .tmpl)"
  check_mentioned "$name (template)" "$name"
done < <(find "$REPO_DIR/source/templates" -name "*.tmpl" 2>/dev/null)

echo ""
echo "📁 Cobertura de gotchas do runbook de instalação (R15-15)"
# Runbook único de Windows/Linux: docs/guides/windows-wsl.md. INSTALL-WINDOWS.md (raiz) é stub-ponteiro.
# Gate: (1) cada gotcha aparece >=1 no runbook; (2) o stub NÃO re-duplica o corpo do Caminho B.
RUNBOOK="$REPO_DIR/docs/guides/windows-wsl.md"
STUB="$REPO_DIR/INSTALL-WINDOWS.md"
if [ ! -f "$RUNBOOK" ]; then
  echo "  ⏭️  windows-wsl.md ausente — skip (repo sem guias de instalação)"
else
  # (1) cobertura: cada gotcha presente >=1 vez no runbook único (grep -c)
  for gotcha in "checkout work" "/mnt/c" "autocrlf"; do
    TOTAL=$((TOTAL + 1))
    n="$(grep -c -F -- "$gotcha" "$RUNBOOK" 2>/dev/null)"; n="${n:-0}"
    if [ "$n" -ge 1 ]; then
      echo "  ✅ gotcha \"$gotcha\" coberto no runbook (${n}×)"
      MENTIONED=$((MENTIONED + 1))
    else
      echo "  ❌ gotcha \"$gotcha\" AUSENTE no runbook (docs/guides/windows-wsl.md)"
      MISSING=$((MISSING + 1))
    fi
  done
  # (2) stub-ponteiro não re-duplica o corpo: âncoras de comando do Caminho B só no runbook
  if [ -f "$STUB" ]; then
    for anchor in "nvm install --lts" "githubcli-archive-keyring.gpg" "crontab -l"; do
      TOTAL=$((TOTAL + 1))
      if grep -qF -- "$anchor" "$STUB" 2>/dev/null; then
        echo "  ❌ stub INSTALL-WINDOWS.md re-duplica o corpo (\"$anchor\" deve ficar só no runbook)"
        MISSING=$((MISSING + 1))
      else
        echo "  ✅ stub não re-duplica \"$anchor\" (corpo fica só no runbook)"
        MENTIONED=$((MENTIONED + 1))
      fi
    done
  fi
fi

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
