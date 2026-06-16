#!/bin/bash
# SOURCE: IdeiaOS v7
# check-plugin-membership.sh
#
# Gate binário: detecta deriva entre as atribuições "plugin" do
# manifests/modules.json e os arrays de membership em scripts/build-plugins.sh.
#
# Motivação (v7, Fase 2): no piloto /spec descobrimos que `spec`, `forge-agent`
# e `memory-sync` estavam declaradas plugin:ideiaos-core no manifesto mas
# ausentes do array CORE_SKILLS → nunca eram empacotadas (o fix do /spec não
# chegava às máquinas via marketplace). O validate_exists do build-plugins.sh
# só checa existência de arquivo, não membership. Este gate fecha esse buraco.
#
# Exit 0 = consistente; Exit 1 = deriva; Exit 2 = erro de invocação.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST="$ROOT/manifests/modules.json"
BUILD="$ROOT/scripts/build-plugins.sh"

[ -f "$MANIFEST" ] || { echo "ERRO: manifesto não encontrado: $MANIFEST" >&2; exit 2; }
[ -f "$BUILD" ]    || { echo "ERRO: build-plugins.sh não encontrado: $BUILD" >&2; exit 2; }

# Mapa (kind:plugin) -> nome do array em build-plugins.sh.
# Combinações fora deste mapa (plugin null, rules/templates/contexts) são ignoradas.
array_for() {
  case "$1:$2" in
    skill:ideiaos-core)         echo "CORE_SKILLS" ;;
    skill:ideiaos-design-suite) echo "DESIGN_SKILLS" ;;
    skill:ideiaos-lovable)      echo "LOVABLE_SKILLS" ;;
    skill:ideiaos-marketing)    echo "MARKETING_SKILLS" ;;
    agent:ideiaos-core)         echo "CORE_AGENTS" ;;
    agent:ideiaos-marketing)    echo "MARKETING_AGENTS" ;;
    hook:ideiaos-core)          echo "CORE_HOOKS" ;;
    *) echo "" ;;
  esac
}

# Extrai os membros de um array NAME=( ... ) do build-plugins.sh.
array_members() {
  awk -v a="$1" '
    $0 ~ "^"a"=\\(" { inb=1; next }
    inb && /^\)/    { inb=0 }
    inb { gsub(/[[:space:]]/,""); sub(/#.*/,""); if ($0!="") print $0 }
  ' "$BUILD"
}

DRIFT=0
CHECKED=0

while IFS=$'\t' read -r kind name plugin; do
  [ -n "$plugin" ] && [ "$plugin" != "null" ] || continue
  arr="$(array_for "$kind" "$plugin")"
  [ -n "$arr" ] || continue
  CHECKED=$((CHECKED + 1))
  if ! array_members "$arr" | grep -qxF "$name"; then
    echo "  DERIVA: $kind '$name' é plugin:$plugin no manifesto mas NÃO está em $arr" >&2
    DRIFT=$((DRIFT + 1))
  fi
done < <(awk '
  /^[[:space:]]*\{[[:space:]]*$/                 { kind=""; name=""; plugin="" }
  /"kind":/                                      { k=$0; sub(/.*"kind": *"/,"",k); sub(/".*/,"",k); kind=k }
  /"source": "source\/skills\//                  { s=$0; sub(/.*source\/skills\//,"",s); sub(/\/SKILL.md.*/,"",s); name=s }
  /"source": "source\/agents\//                  { s=$0; sub(/.*source\/agents\//,"",s); sub(/\.md.*/,"",s); name=s }
  /"source": "source\/hooks\//                   { s=$0; sub(/.*source\/hooks\//,"",s); sub(/".*/,"",s); name=s }
  /"plugin":/ {
    p=$0; sub(/.*"plugin": *"?/,"",p); sub(/"?,?[[:space:]]*$/,"",p)
    if (kind!="" && name!="") print kind "\t" name "\t" p
  }
' "$MANIFEST")

if [ "$DRIFT" -gt 0 ]; then
  echo "check-plugin-membership: FALHOU — $DRIFT deriva(s) manifesto×build-plugins.sh." >&2
  echo "Corrija: adicione o módulo ao array correto em scripts/build-plugins.sh + manifests/plugin-membership.md." >&2
  exit 1
fi

echo "check-plugin-membership: OK — $CHECKED módulo(s) com plugin verificados, sem deriva."
exit 0
