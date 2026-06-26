#!/usr/bin/env bash
# =============================================================================
# session-summary.sh — IdeiaOS Stop hook
#
# Ao fim de cada turno (Stop event), persiste um arquivo de sessão ECC em
# ~/.claude/sessions/YYYY-MM-DD-<slug>.tmp com as 4 seções:
#   1. O que funcionou (com evidência)
#   2. O que falhou
#   3. O que não foi tentado
#   4. Próximos passos
#
# Se o projeto (cwd) tiver docs/CONTINUATION_HANDOFF.md, atualiza/insere um
# bloco datado "## Ultima sessao automatica (DATE)" com link para o .tmp e
# placeholder de próximo passo. Idempotente (substitui bloco anterior do
# mesmo tipo se houver).
#
# Se CONTINUATION_HANDOFF.md NÃO existe no cwd, NÃO cria o arquivo (Pitfall 3).
#
# Entrada (stdin): JSON { session_id, transcript_path, cwd }
#
# Saída: NENHUMA (exit 0 puro — sem JSON, sem additionalContext, sem decision:block)
#   Razão: Stop hook não deve injetar contexto nem bloquear; objetivo é apenas
#          escrever arquivos locais.
#
# Segurança (T-01-04):
#   - slug e session_id sanitizados para [a-z0-9-] antes de usar em paths
#   - transcript lido de forma defensiva (parse falha silenciosamente)
#   - Conteúdo do transcript truncado a ~2000 chars
# =============================================================================
set -uo pipefail

# python3 por lookup (R15-01) — caminho não-hardcoded; portável fora de /usr/bin
PY3="$(command -v python3 2>/dev/null || true)"

INPUT="$(cat 2>/dev/null || echo '{}')"

# Extrai session_id, transcript_path, cwd via python3
PARSED="$("$PY3" -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('session_id', ''))
    print(d.get('transcript_path', ''))
    print(d.get('cwd', ''))
except Exception:
    print('')
    print('')
    print('')
" <<< "$INPUT" 2>/dev/null)"

SESSION_ID="$(echo "$PARSED" | sed -n '1p')"
TRANSCRIPT_PATH="$(echo "$PARSED" | sed -n '2p')"
CWD="$(echo "$PARSED" | sed -n '3p')"

[ -z "$CWD" ] && CWD="$PWD"

# Sanitizar SESSION_ID para [a-z0-9-] (T-01-04: evitar path traversal)
SESSION_SAFE="$("$PY3" -c "
import re, sys
raw = sys.argv[1]
safe = re.sub(r'[^a-z0-9-]', '-', raw.lower())[:32].strip('-') or 'session'
print(safe)
" "$SESSION_ID" 2>/dev/null || echo "session")"

# Derivar slug do cwd para nome do arquivo de sessão
CWD_SLUG="$("$PY3" -c "
import re, os, sys
cwd = sys.argv[1]
base = os.path.basename(cwd.rstrip('/'))
slug = re.sub(r'[^a-z0-9-]', '-', base.lower())[:24].strip('-') or 'project'
print(slug)
" "$CWD" 2>/dev/null || echo "project")"

DATE="$(date '+%Y-%m-%d')"
SLUG="${CWD_SLUG}-${SESSION_SAFE}"
mkdir -p "$HOME/.claude/sessions"
SESSION_FILE="$HOME/.claude/sessions/${DATE}-${SLUG}.tmp"

# Extrair último turno assistant do transcript (Pattern 4 do RESEARCH)
# Abordagem defensiva: parse JSONL por linha; fallback grep se falhar (Open Question 1)
LAST_ASSISTANT=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
  LAST_ASSISTANT="$("$PY3" -c "
import json, sys

transcript_path = sys.argv[1]
try:
    lines = open(transcript_path, errors='replace').readlines()
    # Tentar parse estruturado: buscar última linha com role assistant
    last_text = ''
    for raw_line in reversed(lines[-100:]):
        raw_line = raw_line.strip()
        if not raw_line:
            continue
        try:
            d = json.loads(raw_line)
            role = d.get('role', '')
            if role == 'assistant':
                msg = d.get('message', {})
                content = msg.get('content', [])
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get('type') == 'text':
                            last_text = block.get('text', '')[:2000]
                            break
                elif isinstance(content, str):
                    last_text = content[:2000]
                if last_text:
                    break
        except json.JSONDecodeError:
            # Fallback grep: linha com 'assistant'
            if '\"assistant\"' in raw_line or '\"role\": \"assistant\"' in raw_line:
                # Extrair texto bruto de forma simples
                try:
                    d = json.loads(raw_line)
                    last_text = str(d)[:2000]
                    break
                except:
                    pass
    print(last_text)
except Exception:
    pass
" "$TRANSCRIPT_PATH" 2>/dev/null || true)"
fi

# Se não conseguiu extrair nada significativo, usar placeholder
if [ -z "$LAST_ASSISTANT" ]; then
  LAST_ASSISTANT="(transcript não disponível ou ilegível)"
fi

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

# Escrever SESSION_FILE com 4 seções ECC
"$PY3" - "$SESSION_FILE" "$TIMESTAMP" "$CWD" "$LAST_ASSISTANT" <<'PYEOF' 2>/dev/null || true
import sys

session_file = sys.argv[1]
timestamp    = sys.argv[2]
cwd          = sys.argv[3]
last_text    = sys.argv[4]

content = f"""# Sessão ECC — {timestamp}

**Projeto (cwd):** {cwd}
**Arquivo:** {session_file}

---

## 1. O que funcionou (com evidência)

{last_text}

---

## 2. O que falhou

(a revisar — preencher manualmente ou via próxima sessão)

---

## 3. O que não foi tentado

(a revisar — itens planejados mas não executados nesta sessão)

---

## 4. Próximos passos

(a revisar — defina o próximo passo antes de fechar)
"""

open(session_file, 'w').write(content)
PYEOF

# Atualizar CONTINUATION_HANDOFF.md APENAS se existir no cwd (Pitfall 3)
HANDOFF_FILE="$CWD/docs/CONTINUATION_HANDOFF.md"
if [ -f "$HANDOFF_FILE" ]; then
  BLOCK_MARKER="## Ultima sessao automatica"

  "$PY3" - "$HANDOFF_FILE" "$DATE" "$SESSION_FILE" <<'PYEOF' 2>/dev/null || true
import sys, re

handoff_file = sys.argv[1]
date_str     = sys.argv[2]
session_file = sys.argv[3]

try:
    content = open(handoff_file).read()
except Exception:
    sys.exit(0)

new_block = (
    f"## Ultima sessao automatica ({date_str})\n\n"
    f"- Sessão salva em: `{session_file}`\n"
    f"- Próximo passo: (definir antes de retomar)\n"
)

marker = "## Ultima sessao automatica"

# Idempotente: substituir bloco anterior do mesmo tipo se existir
if marker in content:
    # Encontrar início do bloco e fim (próximo ## ou fim do arquivo)
    start = content.index(marker)
    rest = content[start:]
    # Encontrar próximo header de nível 2 após o primeiro
    next_h2 = re.search(r'\n## ', rest[2:])
    if next_h2:
        end = start + 2 + next_h2.start()
        content = content[:start] + new_block + "\n" + content[end:]
    else:
        content = content[:start] + new_block
else:
    # Anexar ao final
    content = content.rstrip() + "\n\n" + new_block

open(handoff_file, 'w').write(content)
PYEOF
fi

# Exit 0 puro — sem output, sem JSON, sem decision:block
exit 0
