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
# Sem-jq: só /usr/bin/python3. set -uo pipefail. exit 0 puro.
# Entrada (stdin): JSON Stop { session_id, transcript_path, cwd }
# Saída: NENHUMA (exit 0).
# =============================================================================
set -uo pipefail

# R4-01: Anti-runaway guard — sessões spawned de análise NÃO re-spawnam nem gravam obs
[ -n "${IDEIAOS_INSTINCT_SPAWN:-}" ] && exit 0

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

# --- INSTINCT-ANALYZE AUTO-TRIGGER (R3-08 / R3-09, endurecido R4-01/R4-02) ---
# Gate: só dispara se há observações mais recentes que a última análise.
# Fail-silent: todo o bloco em subshell, nunca bloqueia a sessão.
# Kill-switch: timeout 120s no claude -p haiku (sem timeout = risco OpenClaw).
# Sentinela ~/.ideiaos/instincts/.last-analyzed-<proj> é escrita ANTES do spawn (R4-02).
# Cooldown: gate adicional de 30min entre spawns (R4-02).
# Anti-runaway: spawn com IDEIAOS_INSTINCT_SPAWN=1 (R4-01).
# Comparação lexicográfica ISO 8601: strings de data sem tz são comparáveis.
(
  LAST_ANALYZED_FILE="$HOME/.ideiaos/instincts/.last-analyzed-${PROJ}"
  LOG_FILE="$HOME/.ideiaos/logs/instinct-analyze-$(date +%Y%m%d-%H%M%S).log"
  mkdir -p "$HOME/.ideiaos/logs" 2>/dev/null || exit 0

  # Verificar se claude está disponível no PATH; se não, pular silenciosamente
  command -v claude >/dev/null 2>&1 || exit 0

  # Extrair ts da última observação (última linha não-vazia do jsonl)
  TS_OBS="$(/usr/bin/python3 -c '
import sys, json
try:
    lines = open(sys.argv[1]).read().strip().splitlines()
    for l in reversed(lines):
        l = l.strip()
        if not l:
            continue
        try:
            d = json.loads(l)
            ts = d.get("ts", "")
            if ts:
                print(ts)
                break
        except Exception:
            pass
except Exception:
    pass
' "$OBS_DIR/observations.jsonl" 2>/dev/null || echo "")"

  [ -z "$TS_OBS" ] && exit 0

  # Ler sentinela (epoch se ausente — gate passa sempre se nunca analisou)
  TS_LAST="$(cat "$LAST_ANALYZED_FILE" 2>/dev/null || echo "1970-01-01T00:00:00")"

  # Gate: comparar strings ISO (lexicograficamente corretas para timestamps sem tz)
  # Se a obs mais recente <= última análise, nada a fazer
  [[ "$TS_OBS" > "$TS_LAST" ]] || exit 0

  # R4-02: Cooldown gate — se a sentinela tem <30min, não re-spawnar (rate limit)
  NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
  LAST_EPOCH=$(/usr/bin/python3 -c "
import datetime, sys
try:
    ts = open('$LAST_ANALYZED_FILE').read().strip()
    dt = datetime.datetime.fromisoformat(ts)
    import time, calendar
    print(int(calendar.timegm(dt.timetuple())))
except Exception:
    print(0)
" 2>/dev/null || echo 0)
  ELAPSED=$(( NOW_EPOCH - LAST_EPOCH ))
  # Se última análise foi há menos de 30min (1800s), pular
  [ "$ELAPSED" -lt 1800 ] && exit 0

  # Gate passou: escrever sentinela ANTES do spawn (R4-02)
  /usr/bin/python3 -c "
import datetime
open('$LAST_ANALYZED_FILE', 'w').write(datetime.datetime.now().isoformat(timespec='seconds'))
" 2>/dev/null || true

  # Spawn haiku background com timeout e anti-runaway env (R4-01)
  # IDEIAOS_INSTINCT_SPAWN=1 garante que os hooks NÃO acumulam obs nem re-spawnam
  nohup env IDEIAOS_INSTINCT_SPAWN=1 timeout 120 claude --model claude-haiku-4-5 -p "/instinct-analyze" \
    >> "$LOG_FILE" 2>&1 &
  disown $! 2>/dev/null || true
) 2>/dev/null || true

exit 0
