#!/usr/bin/env bash
# =============================================================================
# instinct-recover.sh — IdeiaOS SessionStart hook (Resiliência R6-02)
# SOURCE: IdeiaOS v2
#
# Detecta breadcrumbs órfãos do spawn de /instinct-analyze
# (~/.ideiaos/instincts/.spawn-<proj>.state) e os trata exatamente UMA vez:
# retomada (re-spawn) OU limpeza — sem duplicar trabalho.
#
# Ciclo de vida do breadcrumb:
#   WRITER: observe-session-end.sh grava .spawn-<proj>.state=running antes do spawn.
#   CLEANER: observe-session-end.sh remove o breadcrumb no wait do filho.
#   RECOVERY (este script, SessionStart): se o breadcrumb sobreviveu
#             (sessão morreu no meio), detecta e trata idempotentemente.
#
# Fail-silent: exit 0 em TODO caminho — nunca bloqueia SessionStart.
# Sem-jq: só /usr/bin/python3 e bash 3.2 builtins.
# Breadcrumbs ficam em ~/.ideiaos (FORA do repo) — mesma localização da sentinela.
# Nunca usa `<!--`. Header "# SOURCE: IdeiaOS v2" obrigatório.
# =============================================================================
set -uo pipefail

# Barreira #1 (R4-01): sessões spawned de análise NÃO executam recovery
# (o recovery iria re-spawnar sob o contexto filho, que ainda está "vivo")
[ -n "${IDEIAOS_INSTINCT_SPAWN:-}" ] && exit 0

# Lê JSON opcional do stdin (SessionStart pode trazer cwd)
INPUT="$(cat 2>/dev/null || echo '{}')"

(
  # ---------------------------------------------------------------------------
  # Derivar PROJ do cwd via SessionStart JSON (igual ao slug de observe-tool-use)
  # Usado apenas para logar e como fallback; o project real vem do breadcrumb.
  # ---------------------------------------------------------------------------
  _CWD="$(/usr/bin/python3 -c "
import json, sys, os, re
try:
    d = json.loads('''$INPUT''')
except Exception:
    d = {}
cwd = d.get('cwd', '') or os.getcwd()
proj = re.sub(r'[^a-z0-9-]', '-', os.path.basename(cwd.rstrip('/')).lower())[:40].strip('-') or 'project'
print(proj)
" 2>/dev/null || basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//')"

  INSTINCTS_DIR="$HOME/.ideiaos/instincts"
  # Nenhum breadcrumb → nada a fazer
  ls "$INSTINCTS_DIR"/.spawn-*.state >/dev/null 2>&1 || exit 0

  # Barreira #5 (R4-01): verificar se claude está disponível
  command -v claude >/dev/null 2>&1 || exit 0

  # ---------------------------------------------------------------------------
  # Iterar sobre todos os breadcrumbs deste host
  # ---------------------------------------------------------------------------
  for STATE_FILE in "$INSTINCTS_DIR"/.spawn-*.state; do
    [ -f "$STATE_FILE" ] || continue

    # Ler campos chave=valor do breadcrumb (bash 3.2, sem-jq)
    BC_PID=""
    BC_STARTED_AT=""
    BC_PROJECT=""
    BC_STATUS=""
    BC_LOG=""

    while IFS='=' read -r key val; do
      case "$key" in
        pid)         BC_PID="$val" ;;
        started_at)  BC_STARTED_AT="$val" ;;
        project)     BC_PROJECT="$val" ;;
        status)      BC_STATUS="$val" ;;
        log)         BC_LOG="$val" ;;
      esac
    done < "$STATE_FILE" 2>/dev/null

    # Ignorar breadcrumbs corrompidos/parciais (T-24-04): campos obrigatórios ausentes
    # — tratamos como órfão e limpamos defensivamente.
    if [ -z "$BC_PID" ] || [ -z "$BC_STARTED_AT" ] || [ -z "$BC_PROJECT" ]; then
      rm -f "$STATE_FILE" 2>/dev/null || true
      continue
    fi

    # ---- Gate liveness (T-24-03): pid ainda vivo? PULAR (sem spawn duplo) ----
    # Barreira nova (anti-corrida): kill -0 não envia sinal, só testa existência.
    kill -0 "$BC_PID" 2>/dev/null && continue

    # ---- Gate idade: pode ainda estar terminando? (evita corrida de término) --
    # Se started_at + 120s (mesmo timeout do spawn) ainda não passou, PULAR.
    BC_AGE_OK="$(/usr/bin/python3 -c "
import datetime, time
try:
    dt = datetime.datetime.fromisoformat('$BC_STARTED_AT')
    epoch_start = int(time.mktime(dt.timetuple()))
    now = int(time.time())
    age = now - epoch_start
    # Só trata se mais velho que o timeout do spawn (120s)
    print('old' if age > 120 else 'young')
except Exception:
    print('old')  # parse defensivo: se não sabe a idade, trata como órfão
" 2>/dev/null || echo "old")"

    [ "$BC_AGE_OK" = "young" ] && continue

    # ---- Órfão confirmado: pid morto + idade > 120s -------------------------
    # Reivindicar atomicamente via rename (atômico no mesmo FS — T-24-02).
    # Se dois SessionStart concorrentes chegarem aqui, só um mv terá sucesso;
    # o perdedor encontra o arquivo renomeado e salta (|| continue).
    CLAIM="${STATE_FILE}.claimed-$$"
    mv "$STATE_FILE" "$CLAIM" 2>/dev/null || continue

    # ---- Decidir: retomar (re-spawn) OU apenas limpar ----------------------
    # Reusar EXATAMENTE os mesmos gates de observe-session-end.sh:
    # gate #5: command -v claude (já verificado acima)
    # gate #2: sentinela + obs mais recente
    # gate #3: cooldown 30min (1800s)

    BC_LAST_ANALYZED="$INSTINCTS_DIR/.last-analyzed-${BC_PROJECT}"
    BC_OBS_DIR="$HOME/.ideiaos/observations/${BC_PROJECT}"
    BC_OBS_FILE="$BC_OBS_DIR/observations.jsonl"

    # Gate #2a: extrair ts da última observação
    TS_OBS="$(/usr/bin/python3 -c "
import sys, json
try:
    lines = open('$BC_OBS_FILE').read().strip().splitlines()
    for l in reversed(lines):
        l = l.strip()
        if not l:
            continue
        try:
            d = json.loads(l)
            ts = d.get('ts', '')
            if ts:
                print(ts)
                break
        except Exception:
            pass
except Exception:
    pass
" 2>/dev/null || echo "")"

    if [ -z "$TS_OBS" ]; then
      # Sem observações → apenas limpa (não há o que analisar)
      rm -f "$CLAIM" 2>/dev/null || true
      continue
    fi

    # Gate #2b: sentinela da última análise
    TS_LAST="$(cat "$BC_LAST_ANALYZED" 2>/dev/null || echo "1970-01-01T00:00:00")"

    # Comparação lexicográfica ISO (strings sem tz são comparáveis)
    if [[ ! "$TS_OBS" > "$TS_LAST" ]]; then
      # Obs não são mais recentes que a última análise → apenas limpa
      rm -f "$CLAIM" 2>/dev/null || true
      continue
    fi

    # Gate #3: cooldown 30min (barreira #3 preservada)
    NOW_EPOCH=$(date +%s 2>/dev/null || echo 0)
    LAST_EPOCH="$(/usr/bin/python3 -c "
import datetime, time
try:
    ts = open('$BC_LAST_ANALYZED').read().strip()
    dt = datetime.datetime.fromisoformat(ts)
    print(int(time.mktime(dt.timetuple())))
except Exception:
    print(0)
" 2>/dev/null || echo 0)"
    ELAPSED=$(( NOW_EPOCH - LAST_EPOCH ))

    if [ "$ELAPSED" -lt 1800 ]; then
      # Cooldown ativo → apenas limpa (barreira #3 intacta)
      rm -f "$CLAIM" 2>/dev/null || true
      continue
    fi

    # ---- Todos os gates passaram: re-spawnar --------------------------------
    BC_LOG_FILE="$HOME/.ideiaos/logs/instinct-recover-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$HOME/.ideiaos/logs" 2>/dev/null || true

    # Reescrever sentinela ANTES do novo spawn (barreira #2 — R4-02)
    /usr/bin/python3 -c "
import datetime
open('$BC_LAST_ANALYZED', 'w').write(datetime.datetime.now().isoformat(timespec='seconds'))
" 2>/dev/null || true

    # Novo breadcrumb fresco para este re-spawn
    NEW_STATE="$INSTINCTS_DIR/.spawn-${BC_PROJECT}.state"

    # Spawn: mesmo comando de observe-session-end.sh
    # Barreira #1: IDEIAOS_INSTINCT_SPAWN=1 (R4-01)
    # Barreira #4: timeout 120 (R4-01)
    nohup env IDEIAOS_INSTINCT_SPAWN=1 timeout 120 claude --model claude-haiku-4-5 \
      -p "/instinct-analyze" >> "$BC_LOG_FILE" 2>&1 &
    NEW_PID=$!

    # Gravar novo breadcrumb
    /usr/bin/python3 -c "
import datetime
started = datetime.datetime.now().isoformat(timespec='seconds')
content = 'pid=$NEW_PID\nstarted_at=' + started + '\nproject=$BC_PROJECT\nstatus=running\nlog=$BC_LOG_FILE\n'
open('$NEW_STATE', 'w').write(content)
" 2>/dev/null || true

    # Remover o arquivo .claimed (o trabalho foi aceito por este processo)
    rm -f "$CLAIM" 2>/dev/null || true

    # Aguardar filho e limpar breadcrumb fresco no retorno
    wait "$NEW_PID" 2>/dev/null || true
    rm -f "$NEW_STATE" 2>/dev/null || true

  done

) 2>/dev/null || true

exit 0
