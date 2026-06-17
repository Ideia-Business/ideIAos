#!/usr/bin/env bash
# =============================================================================
# validate-agent-yaml.sh — valida o bloco ```yaml de arquivos de agente AIOX
#
# Usa o parser AUTORITATIVO (js-yaml do aiox-core — o MESMO que o AIOX carrega
# em runtime), com fallback ruby/psych → python3+yaml → skip gracioso. Bash 3.2.
#
# Por que existe: PyYAML não está no ambiente, mas js-yaml (aiox-core) e
# ruby/psych quase sempre estão. "Ferramenta X ausente" ≠ "não dá pra
# verificar" — faça probe por equivalentes antes de declarar gap. Validar com o
# parser do PRÓPRIO framework é mais forte que validar com qualquer outro.
#
# Consumidores: idea-doctor.sh (gate read-only sobre todos os agentes) e
# install-global-patches.sh (auto-validação pós-inserção do Patch 14).
#
# Uso:   validate-agent-yaml.sh <arquivo.md | diretório>
#
# Exit codes:
#   0 = todos os blocos válidos  (ou nada a validar / nenhum parser disponível)
#   1 = pelo menos um bloco YAML inválido
#   3 = caminho inexistente / argumento ausente
# =============================================================================
set -uo pipefail

TARGET="${1:-}"
[ -z "$TARGET" ] && { echo "uso: $(basename "$0") <arquivo.md | diretório>" >&2; exit 3; }
[ -e "$TARGET" ] || { echo "validate-agent-yaml: caminho inexistente: $TARGET" >&2; exit 3; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Resolve um parser disponível (preferência: parser do runtime AIOX) ────────
find_jsyaml() {
  local c
  for c in "$(dirname "$SELF_DIR")/.aiox-core/node_modules/js-yaml" \
           "$HOME/Projects/.aiox-core/node_modules/js-yaml"; do
    [ -d "$c" ] && { echo "$c"; return 0; }
  done
  return 1
}

VALIDATOR=""; JSYAML=""
if command -v node >/dev/null 2>&1 && JSYAML="$(find_jsyaml)"; then
  VALIDATOR="js-yaml"
elif command -v ruby >/dev/null 2>&1; then
  VALIDATOR="ruby/psych"
elif command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
  VALIDATOR="python3/pyyaml"
else
  echo "validate-agent-yaml: nenhum parser YAML disponível (node+js-yaml / ruby / python3+yaml) — pulei (graceful)" >&2
  exit 0
fi

# ── Valida UM arquivo: extrai o 1º bloco ```yaml e parseia ────────────────────
# Sem bloco yaml → válido (nada a checar). Parse falhou → stdout: "ARQ: erro".
validate_one() {
  local f="$1"
  case "$VALIDATOR" in
    js-yaml)
      node -e '
        const fs=require("fs"); const y=require(process.argv[2]);
        const s=fs.readFileSync(process.argv[1],"utf8");
        const m=s.match(/```yaml\n([\s\S]*?)\n```/);
        if(!m) process.exit(0);
        try { y.load(m[1]); } catch(e){ console.log(process.argv[1]+": "+e.message); process.exit(1); }
      ' "$f" "$JSYAML"
      ;;
    ruby/psych)
      ruby -E UTF-8 -ryaml -e '
        s=File.read(ARGV[0], encoding:"UTF-8")
        m=s[/```yaml\n(.*?)\n```/m,1]
        exit 0 if m.nil?
        begin; YAML.load(m); rescue => e; puts "#{ARGV[0]}: #{e.message}"; exit 1; end
      ' "$f"
      ;;
    python3/pyyaml)
      python3 - "$f" <<'PY'
import sys, re, yaml
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
m = re.search(r"```yaml\n(.*?)\n```", s, re.S)
if not m:
    sys.exit(0)
try:
    yaml.safe_load(m.group(1))
except Exception as e:
    print(f"{p}: {e}")
    sys.exit(1)
PY
      ;;
  esac
}

COUNT=0; BAD=0
check() {
  local out
  out="$(validate_one "$1")"
  local rc=$?
  COUNT=$((COUNT+1))
  if [ "$rc" -ne 0 ]; then
    BAD=$((BAD+1))
    echo "✗ YAML inválido — $out" >&2
  fi
}

if [ -d "$TARGET" ]; then
  for f in "$TARGET"/*.md; do [ -f "$f" ] && check "$f"; done
else
  check "$TARGET"
fi

echo "validate-agent-yaml [$VALIDATOR]: $COUNT arquivo(s) checado(s), $BAD inválido(s)"
[ "$BAD" -eq 0 ] && exit 0 || exit 1
