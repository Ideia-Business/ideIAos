#!/usr/bin/env bash
# =============================================================================
# observe-tool-use.sh — IdeiaOS PostToolUse hook (Continuous Learning v2)
# SOURCE: IdeiaOS v2
#
# Acrescenta UMA linha JSON (JSONL) por evento relevante a
#   ~/.ideiaos/observations/<projeto-slug>/observations.jsonl
#
# Coleta APENAS metadados (memory-hygiene.md Regra 1):
#   ts, session_id, project, tool, file (path relativo, sem conteúdo),
#   ext, ok (sucesso/erro), bash_verb (1º token do comando, ex "npm", NUNCA args)
# NUNCA loga: conteúdo de arquivo, diff, comando bash completo, env, secrets.
#
# Requisitos: <100ms overhead, fail-silent (exit 0 sempre), cria dirs sob demanda,
#             não bloqueia o tool use. Sem-jq: só /usr/bin/python3. set -uo pipefail.
# Entrada (stdin): JSON PostToolUse { session_id, cwd, tool_name, tool_input, tool_response }
# Saída: NENHUMA (exit 0 puro).
# =============================================================================
set -uo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"

# Parse e montagem da linha JSONL inteiramente em python3 (rápido, 1 processo).
LINE="$(/usr/bin/python3 -c '
import json, sys, os, re, datetime

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

sid = str(d.get("session_id", ""))[:64]
# Sanitiza session_id contra path traversal (mesma regra do strategic-compact)
if re.search(r"[/\\]|\.\.", sid):
    sys.exit(0)

cwd = d.get("cwd", "") or os.getcwd()
proj = re.sub(r"[^a-z0-9-]", "-", os.path.basename(cwd.rstrip("/")).lower())[:40].strip("-") or "project"

tool = str(d.get("tool_name", ""))[:32]
ti   = d.get("tool_input", {}) or {}
tr   = d.get("tool_response", {}) or {}

# file path: SÓ o path, relativo ao cwd se possível. NUNCA conteúdo.
fpath = ti.get("file_path") or ti.get("path") or ""
fpath = str(fpath)[:300]
rel = fpath
try:
    if fpath and cwd and fpath.startswith(cwd):
        rel = os.path.relpath(fpath, cwd)
except Exception:
    rel = fpath
ext = os.path.splitext(rel)[1].lstrip(".")[:12] if rel else ""

# bash_verb: APENAS o 1º token do comando (ex "npm", "git"), nunca os argumentos.
bash_verb = ""
if tool == "Bash":
    cmd = str(ti.get("command", "")).strip()
    bash_verb = re.split(r"\s+", cmd)[0][:24] if cmd else ""
    # descarta se parecer um path/secret embutido
    if "/" in bash_verb or "=" in bash_verb:
        bash_verb = os.path.basename(bash_verb).split("=")[0][:24]

# ok: sinal de sucesso (defensivo — formato de tool_response varia)
ok = True
try:
    if isinstance(tr, dict):
        if tr.get("is_error") or tr.get("error") or tr.get("interrupted"):
            ok = False
        st = tr.get("stderr") or ""
        if isinstance(st, str) and "error" in st.lower()[:200]:
            ok = False
except Exception:
    pass

rec = {
    "ts": datetime.datetime.now().isoformat(timespec="seconds"),
    "session_id": sid,
    "project": proj,
    "tool": tool,
    "file": rel,
    "ext": ext,
    "bash_verb": bash_verb,
    "ok": ok,
}
print(proj)                       # linha 1: slug do projeto (p/ o bash montar o path)
print(json.dumps(rec, ensure_ascii=False))   # linha 2: o registro JSONL
' <<< "$INPUT" 2>/dev/null)"

# Sem saída do python → nada a fazer (input malformado, session inválida, etc.)
[ -z "$LINE" ] && exit 0

PROJ="$(printf '%s\n' "$LINE" | sed -n '1p')"
REC="$(printf '%s\n' "$LINE" | sed -n '2p')"
[ -z "$PROJ" ] && exit 0
[ -z "$REC" ] && exit 0

OBS_DIR="$HOME/.ideiaos/observations/$PROJ"
mkdir -p "$OBS_DIR" 2>/dev/null || exit 0
printf '%s\n' "$REC" >> "$OBS_DIR/observations.jsonl" 2>/dev/null || true

exit 0
