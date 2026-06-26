#!/bin/bash
# install-alias.sh — adiciona alias `idea-setup` ao ~/.zshrc ou ~/.bashrc
# Idempotente: se já tem, mostra mensagem e sai.

set -euo pipefail

DEV_SETUP="$HOME/dev/IdeiaOS"
ALIAS_LINE="alias idea-setup='bash \"$DEV_SETUP/setup.sh\" --lovable \"\$PWD\"'"

# Detectar shell rc
RC=""
if [ -n "${ZSH_VERSION:-}" ] || [ "${SHELL##*/}" = "zsh" ]; then
  RC="$HOME/.zshrc"
elif [ -n "${BASH_VERSION:-}" ] || [ "${SHELL##*/}" = "bash" ]; then
  RC="$HOME/.bashrc"
fi

if [ -z "$RC" ]; then
  echo "❌ Não consegui detectar shell rc (zsh/bash). Adicione manualmente:"
  echo ""
  echo "   $ALIAS_LINE"
  exit 1
fi

if [ ! -f "$RC" ]; then
  touch "$RC"
fi

# Já tem?
if grep -qF "alias idea-setup=" "$RC" 2>/dev/null; then
  echo "✅ Alias 'idea-setup' já está em $RC"
  echo "   Atual:"
  grep "alias idea-setup=" "$RC" | head -1
  exit 0
fi

# Adicionar
{
  printf "\n# Ideia Business IdeiaOS (adicionado em %s)\n" "$(date +%Y-%m-%d)"
  echo "$ALIAS_LINE"
} >> "$RC"

echo "✅ Alias 'idea-setup' adicionado a $RC"
echo ""
echo "Para ativar nesta sessão do shell, rode:"
echo "   source $RC"
echo ""
echo "Daqui pra frente, em qualquer projeto Lovable:"
echo "   cd /caminho/do/projeto"
echo "   idea-setup"
