#!/usr/bin/env bash
# =============================================================================
# observe-session-end.sh — IdeiaOS Stop hook (Continuous Learning v2)
# SOURCE: IdeiaOS v2
#
# Gatilho de AVALIAÇÃO de fim de sessão (lição ECC: usar Stop, não
# UserPromptSubmit — leveza). Acrescenta UM marcador "session_end" na
# observations.jsonl do projeto. NÃO dispara análise pesada aqui — apenas
# marca o fim; /instinct-analyze (skill, plan 05-02) é quem processa depois.
#
# Mesmo contrato de privacidade do observe-tool-use: só metadados.
# Sem jq — só /usr/bin/python3. set -uo pipefail. exit 0 puro.
# Entrada (stdin): JSON Stop { session_id, transcript_path, cwd }
# Saída: NENHUMA (exit 0).
# =============================================================================
set -uo pipefail

INPUT="$(cat 2>/dev/null || echo '{}')"

LINE="$(/usr/bin/python3 -c '
import json, sys, os, re, datetime
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
sid = str(d.get("session_id", ""))[:64]
if re.search(r"[/\\]|\.\.", sid):
    sys.exit(0)
cwd = d.get("cwd", "") or os.getcwd()
proj = re.sub(r"[^a-z0-9-]", "-", os.path.basename(cwd.rstrip("/")).lower())[:40].strip("-") or "project"
rec = {
    "ts": datetime.datetime.now().isoformat(timespec="seconds"),
    "session_id": sid,
    "project": proj,
    "tool": "session_end",
    "event": "session_end",
}
print(proj)
print(json.dumps(rec, ensure_ascii=False))
' <<< "$INPUT" 2>/dev/null)"

[ -z "$LINE" ] && exit 0
PROJ="$(printf '%s\n' "$LINE" | sed -n '1p')"
REC="$(printf '%s\n' "$LINE" | sed -n '2p')"
[ -z "$PROJ" ] && exit 0
[ -z "$REC" ] && exit 0

OBS_DIR="$HOME/.ideiaos/observations/$PROJ"
mkdir -p "$OBS_DIR" 2>/dev/null || exit 0
printf '%s\n' "$REC" >> "$OBS_DIR/observations.jsonl" 2>/dev/null || true

exit 0
