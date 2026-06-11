# Phase 01: quality-memory-hooks — Research

**Researched:** 2026-06-11
**Domain:** Claude Code hooks — PostToolUse, PreToolUse, Stop, PreCompact events; bash scripting; session state persistence
**Confidence:** HIGH (hook protocol verified against official docs + existing codebase patterns)

---

<user_constraints>
## User Constraints (from PROJECT.md)

### Locked Decisions
- setup.sh permanece para bootstrap; novos hooks devem ser adicionados nele
- Não quebrar os 4 projetos-produto: ideiapartner, nfideia, cfoai-grupori, lapidai
- Branch `work` para desenvolvimento; `main` para releases
- README sync hook continua valendo — todo componente novo precisa estar no README

### Claude's Discretion
- Formato exato dos arquivos de sessão ~/.claude/sessions/ (padrão ECC não está documentado formalmente)
- Estratégia de escape para JSON multiline em bash (printf vs jq)
- Se typecheck deve usar `async: true` ou `asyncRewake: true` para não bloquear

### Deferred Ideas (OUT OF SCOPE)
- Pipeline de quarentena (Fase 02)
- Observations.jsonl / instincts (Fase 05)
- Multi-harness / source/ directory (Fase 03)
</user_constraints>

---

## Summary

A Fase 01 entrega 5 hooks de qualidade e memória que completam a infraestrutura de sessão do IdeiaOS. Todos os hooks seguem o mesmo protocolo JSON que os 7 hooks já existentes em `~/.claude/hooks/` — a base de código fornece padrões concretos e funcionais para cada evento-alvo.

O protocolo de hooks do Claude Code está totalmente documentado e verificado: cada evento recebe um JSON via stdin com campos comuns (`session_id`, `transcript_path`, `cwd`, `hook_event_name`) mais campos específicos do evento. A saída de cada hook é JSON via stdout com campos `hookSpecificOutput.additionalContext` para injeção de contexto, ou `decision: "block"` para bloqueio.

O ponto mais delicado da fase é o `typecheck-on-edit.sh`: `tsc --noEmit` pode ser lento (5–30s em projetos grandes) e bloquearia o PostToolUse. A solução é usar `"async": true` com `"asyncRewake": true` para executar em background e acordar o Claude apenas quando encontrar erros. O contador de tool calls do `strategic-compact.sh` deve usar `/tmp/claude-compact-counter-{session_id}.json` — o mesmo padrão já em uso no `gsd-context-monitor.js`.

**Primary recommendation:** Implementar os 5 hooks em ordem de risco crescente: (1) console-log-guard (mais simples), (2) strategic-compact (contador /tmp), (3) precompact-state-save (escrita em arquivo), (4) session-summary (mais complexo), (5) typecheck-on-edit (async com asyncRewake).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Typecheck TypeScript | Global hook (~/.claude/hooks/) | Per-project (opcional) | Deve rodar em qualquer projeto TS, não só IdeiaOS |
| Console.log guard | Global hook | — | Todos os projetos Lovable são afetados |
| Snapshot de estado PreCompact | Global hook | — | Funciona em qualquer projeto com STATE.md ou .planning/ |
| Session summary (Stop) | Global hook | — | ECC pattern: global, injeta em ~/.claude/sessions/ |
| Strategic compact counter | Global hook | — | Contador de tool calls é global por session_id |
| setup.sh deployment | IdeiaOS/setup.sh | — | Pattern já estabelecido para todos os hooks globais |

---

## Standard Stack

### Core
| Componente | Versão/Evento | Propósito | Por que padrão |
|------------|--------------|-----------|----------------|
| PostToolUse + matcher "Edit\|Write" | CC 2.1.x | Executar após edição de arquivo | Único evento que recebe `tool_input.file_path` + `tool_result` |
| PreToolUse + matcher ".*" | CC 2.1.x | Contador de tool calls (strategic-compact) | Único evento que roda ANTES da tool — não bloqueia o fluxo |
| Stop event | CC 2.1.x | Session summary ao fim de cada turno | Recebe `transcript_path` — acesso à conversa completa |
| PreCompact event | CC 2.1.x | Snapshot antes do /compact | Recebe `trigger: "manual"\|"auto"`, pode bloquear ou adicionar contexto |
| `/tmp/claude-{tipo}-{session_id}.json` | — | Estado de sessão persistente entre chamadas de hook | Padrão já usado por gsd-context-monitor.js |
| `python3 -c "import json..."` | macOS built-in | Parse JSON sem dependência de jq | Padrão já usado em todos os hooks IdeiaOS existentes |

### Supporting
| Componente | Versão | Propósito | Quando usar |
|------------|--------|-----------|-------------|
| `"async": true` + `"asyncRewake": true` | CC 2.1.x | Rodar tsc em background, acordar Claude se erro | Obrigatório para typecheck — tsc é lento |
| `node_modules/.bin/tsc` | Local do projeto | TypeScript compiler | Evita depender de tsc global (não instalado no PATH do usuário) |
| `jq` (opcional) | brew/system | JSON generation para outputs complexos | Fallback: printf com escape manual |

### Alternatives Considered
| Padrão | Alternativa | Tradeoff |
|--------|-------------|----------|
| async+asyncRewake para typecheck | Síncrono com timeout curto | Síncrono bloqueia UI por 5–30s; asyncRewake garante feedback sem bloquear |
| /tmp/{session_id}.json para contador | Arquivo em .planning/ | /tmp é automaticamente limpo; .planning/ poluído com estado efêmero |
| Stop hook para session summary | UserPromptSubmit para detectar início de sessão | Stop tem acesso a transcript_path; UserPromptSubmit não tem histórico completo |

**Installation (novos hooks):**
```bash
# Não há pacotes npm — hooks são bash scripts + deployment via setup.sh
cp hooks/typecheck-on-edit.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/typecheck-on-edit.sh
# + Adicionar entrada em ~/.claude/settings.json (ver padrão abaixo)
```

---

## Architecture Patterns

### System Architecture Diagram

```
[Edição .ts/.tsx]
    │
    ▼
[PostToolUse] ── typecheck-on-edit.sh (async+asyncRewake)
                      │
                      ├─► tsc --noEmit (background, projeto/$CWD)
                      │       │ erro detectado
                      │       ▼
                      │   asyncRewake: Claude recebe additionalContext com erros
                      │
                      └─► [sem erro] → exit 0, sem ruído

[Edição qualquer arquivo .ts/.tsx/.js]
    │
    ▼
[PostToolUse] ── console-log-guard.sh
                      │
                      ├─► grep console.log no arquivo editado
                      │       │ encontrou
                      │       ▼
                      │   additionalContext: "⚠️ console.log detectado em <file>"
                      └─► [não encontrou] → exit 0

[Cada tool call]
    │
    ▼
[PreToolUse] ── strategic-compact.sh
                    │
                    ├─► lê /tmp/claude-compact-{session_id}.json
                    ├─► incrementa contador
                    │       │ contador % 50 == 0
                    │       ▼
                    │   additionalContext: "💡 ~50 tool calls — considere /compact"
                    └─► [abaixo do limiar] → exit 0, persiste counter

[/compact disparado]
    │
    ▼
[PreCompact] ── precompact-state-save.sh
                    │
                    ├─► detecta .planning/STATE.md ou STATE.md no cwd
                    ├─► extrai snapshot da conversa (transcript_path)
                    ├─► atualiza STATE.md com "## Compact Snapshot"
                    └─► exit 0, additionalContext: "STATE.md atualizado"

[Claude termina resposta]
    │
    ▼
[Stop] ── session-summary.sh
              │
              ├─► lê transcript_path (JSONL)
              ├─► extrai: o que funcionou / falhou / não tentado / próximos passos
              ├─► escreve ~/.claude/sessions/YYYY-MM-DD-<slug>.tmp
              ├─► atualiza docs/CONTINUATION_HANDOFF.md (se existe no cwd)
              └─► exit 0 (não bloqueia — não usa additionalContext)
```

### Recommended Project Structure
```
IdeiaOS/
├── hooks/
│   ├── typecheck-on-edit.sh        # PostToolUse .ts/.tsx
│   ├── console-log-guard.sh        # PostToolUse Edit|Write
│   ├── precompact-state-save.sh    # PreCompact
│   ├── session-summary.sh          # Stop
│   └── strategic-compact.sh        # PreToolUse
└── setup.sh                        # Deploy dos 5 novos hooks para ~/.claude/hooks/
```

### Pattern 1: Hook com additionalContext (PostToolUse / PreToolUse)

**What:** Output JSON com `hookSpecificOutput.additionalContext` que Claude vê como system reminder
**When to use:** Quando o hook quer alertar Claude sem bloquear a operação

```bash
#!/usr/bin/env bash
# Source: https://code.claude.com/docs/en/hooks (verificado 2026-06-11)
# + padrão de extract-learnings-reminder.sh (IdeiaOS)

INPUT="$(cat 2>/dev/null || echo '{}')"

# Parse com python3 (sem dependência de jq — padrão IdeiaOS)
PARSED="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input', {}) or {}
    print(d.get('session_id', ''))
    print(ti.get('file_path', ''))
    print(d.get('cwd', ''))
except Exception:
    pass
" 2>/dev/null)"

SESSION_ID="$(echo "$PARSED" | sed -n '1p')"
FILE_PATH="$(echo "$PARSED" | sed -n '2p')"
CWD="$(echo "$PARSED" | sed -n '3p')"

[ -z "$FILE_PATH" ] && exit 0

# ... lógica de detecção ...

# Output: JSON com additionalContext
printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' \
  "⚠️ Mensagem para Claude (sem newlines literais aqui)"
exit 0
```

### Pattern 2: Hook assíncrono com asyncRewake (typecheck)

**What:** Hook roda em background sem bloquear; acorda o Claude apenas se exit code 2
**When to use:** Operações lentas (tsc, linters) no PostToolUse

```json
// Em ~/.claude/settings.json — hooks PostToolUse
{
  "matcher": "Edit|Write",
  "hooks": [
    {
      "type": "command",
      "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/typecheck-on-edit.sh\"",
      "timeout": 60,
      "async": true,
      "asyncRewake": true
    }
  ]
}
```

O script retorna `exit 2` com stderr = mensagem de erro quando tsc encontra erros; `exit 0` silencioso quando OK.

### Pattern 3: Contador de sessão em /tmp (strategic-compact)

**What:** Estado persistente entre chamadas de hook usando session_id como chave de arquivo
**When to use:** Qualquer contador ou estado efêmero de sessão

```bash
# Source: padrão verificado em gsd-context-monitor.js (IdeiaOS)
SESSION_ID="$(echo "$INPUT" | /usr/bin/python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('session_id',''))
except: pass
" 2>/dev/null)"

# Sanitize: rejeitar session_id com path traversal
if echo "$SESSION_ID" | grep -qE '[/\\\\]|\\.\\.' 2>/dev/null; then exit 0; fi

COUNTER_FILE="/tmp/claude-compact-counter-${SESSION_ID}.json"

# Lê contador atual
COUNT=0
if [ -f "$COUNTER_FILE" ]; then
  COUNT="$(python3 -c "import json; print(json.load(open('$COUNTER_FILE')).get('count',0))" 2>/dev/null || echo 0)"
fi
COUNT=$((COUNT + 1))

# Persiste
python3 -c "import json; json.dump({'count': $COUNT}, open('$COUNTER_FILE','w'))" 2>/dev/null || true

# Dispara a cada 50 tool calls
if [ $((COUNT % 50)) -eq 0 ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"..."}}\n'
fi
exit 0
```

### Pattern 4: Leitura de transcript_path (Stop hook)

**What:** O Stop hook recebe `transcript_path` apontando para um JSONL com todo o histórico da sessão
**When to use:** session-summary.sh para extrair o que foi feito na sessão

```bash
# Source: https://code.claude.com/docs/en/hooks (verificado 2026-06-11)
TRANSCRIPT="$(echo "$INPUT" | /usr/bin/python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('transcript_path',''))
except: pass
" 2>/dev/null)"

# transcript_path é JSONL — uma linha por mensagem
# Cada linha: {"role": "assistant"|"user", "message": {...}}
# Último assistant turn = o que Claude acabou de fazer
if [ -f "$TRANSCRIPT" ]; then
  LAST_ASSISTANT="$(tail -n 50 "$TRANSCRIPT" | /usr/bin/python3 -c "
import json, sys
lines = [l for l in sys.stdin if '\"role\":\"assistant\"' in l or '\"role\": \"assistant\"' in l]
if lines:
    try:
        d = json.loads(lines[-1])
        content = d.get('message', {}).get('content', [])
        for block in (content if isinstance(content, list) else []):
            if block.get('type') == 'text':
                print(block.get('text','')[:2000])
                break
    except: pass
" 2>/dev/null)"
fi
```

### Pattern 5: PreCompact — injetar contexto antes do /compact

**What:** PreCompact pode adicionar informação crítica que o LLM preservará durante a compactação
**When to use:** precompact-state-save.sh para garantir que STATE.md seja atualizado antes de compactar

```bash
# Source: https://code.claude.com/docs/en/hooks (verificado 2026-06-11)
# PreCompact stdin inclui "trigger": "manual" | "auto"
TRIGGER="$(echo "$INPUT" | /usr/bin/python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('trigger',''))
except: pass
" 2>/dev/null)"

# Pode bloquear compactação (raro — só em casos críticos):
# echo '{"decision":"block","reason":"Motivo"}' && exit 2

# Ou apenas adicionar contexto preservado no resumo:
printf '{"hookSpecificOutput":{"hookEventName":"PreCompact","additionalContext":"%s"}}\n' \
  "Estado atual: $(cat STATE.md 2>/dev/null | head -20 | tr '\n' ' ')"
exit 0
```

### Anti-Patterns to Avoid

- **tsc síncrono em PostToolUse:** `tsc --noEmit` leva 5–30s em projetos Lovable — bloqueia visualmente o IDE. Sempre usar `async: true`.
- **Newlines literais em additionalContext JSON:** JSON não aceita newlines literais em strings. Usar `\n` (escaped) ou `printf` com formatação. O hook `extract-learnings-reminder.sh` usa este padrão incorretamente — verificar se a string é gerada com printf ou heredoc.
- **session_id não sanitizado em paths de arquivo:** session_id vem do harness e pode conter `/` ou `..`. Sempre validar antes de usar em `$COUNTER_FILE`. Ver padrão em gsd-context-monitor.js linha 50–53.
- **Escrever em STATE.md de qualquer diretório:** precompact-state-save.sh deve verificar se existe `.planning/STATE.md` ou `STATE.md` no `$CWD` antes de escrever — evita criar arquivos espúrios em projetos sem STATE.md.
- **Stop hook com `additionalContext` e `decision: "block"` juntos:** Para session-summary.sh, o objetivo é apenas escrever um arquivo — não bloquear, não injetar contexto. Usar `exit 0` puro sem JSON output.
- **Matcher muito amplo para typecheck:** `matcher: ".*"` no PostToolUse rodaria tsc após qualquer tool (inclusive Bash). Usar `matcher: "Edit|Write"` e verificar extensão do arquivo dentro do script.

---

## Don't Hand-Roll

| Problema | Não construir | Usar em vez disso | Por quê |
|----------|---------------|-------------------|---------|
| Parse de JSON stdin no hook | Parser custom bash com grep/sed | `python3 -c "import json,sys..."` | python3 está sempre disponível no macOS; já é o padrão em todos os hooks IdeiaOS |
| Estado de sessão persistente | Banco de dados, arquivos em .planning/ | `/tmp/claude-{tipo}-{session_id}.json` | Limpo automaticamente, sem poluir o projeto, padrão já usado por gsd-context-monitor |
| Detecção de erros tsc | Parser custom de output | `tsc --noEmit 2>&1` captura stderr+stdout; exit code indica erro | tsc retorna exit 1 se houver erros |
| Leitura de transcript | Parser custom JSONL | `python3 + json.loads()` por linha | JSONL é JSON Lines — uma linha por objeto |
| Escape de string para JSON | Concatenação manual | `jq -n --arg msg "$MSG" '{additionalContext:$msg}'` ou `python3 -c "import json; print(json.dumps({'a':msg})"` | Caracteres especiais, aspas, newlines explodem concatenação manual |

**Key insight:** O maior risco desta fase é a fragilidade do JSON output manual em bash. Qualquer caractere especial (aspa, newline, barra) na mensagem de erro do tsc ou no conteúdo do STATE.md vai quebrar o JSON. Usar python3 para serializar o JSON final é obrigatório em hooks que injetam conteúdo dinâmico.

---

## Common Pitfalls

### Pitfall 1: tsc não encontrado no PATH do hook
**What goes wrong:** O hook roda como subprocesso com PATH limitado. `tsc` global não está instalado (confirmado: `npx tsc --version` retorna erro "not the tsc you're looking for"). `node_modules/.bin/tsc` existe apenas se TypeScript foi instalado no projeto.
**Why it happens:** macOS não inclui tsc no PATH padrão; o usuário usa npx ou tsc do projeto.
**How to avoid:** No typecheck-on-edit.sh: procurar `$CWD/node_modules/.bin/tsc` primeiro; fallback para `npx --no-install tsc` (falha silenciosamente se não encontrar); se não encontrar nada, exit 0 sem erro.
**Warning signs:** Hook roda mas nunca reporta erros mesmo com TypeScript inválido.

### Pitfall 2: PostToolUse hook lento bloqueia a UI
**What goes wrong:** tsc --noEmit em projeto grande (ideiapartner, nfideia têm tsconfig com references) pode levar 15–30s. O PostToolUse é síncrono por padrão — Claude fica "travado" esperando.
**Why it happens:** Hooks são bloqueantes por default (timeout: 600s).
**How to avoid:** Usar `"async": true` + `"asyncRewake": true` nas settings.json. O hook executa em background; se encontrar erros, usa `exit 2` + stderr para acordar Claude com a mensagem.
**Warning signs:** Claude demora para responder após edição de .ts.

### Pitfall 3: session-summary.sh altera CONTINUATION_HANDOFF.md em todo projeto
**What goes wrong:** session-summary.sh roda em qualquer projeto (global hook). Se atualizar `docs/CONTINUATION_HANDOFF.md` incondicionalmente, vai criar esse arquivo em projetos que não têm a estrutura IdeiaOS.
**Why it happens:** Stop hook é global — roda em qualquer sessão Claude Code.
**How to avoid:** Verificar se `$CWD/docs/CONTINUATION_HANDOFF.md` existe antes de tentar atualizar. Para projetos sem o arquivo, apenas escrever em `~/.claude/sessions/` (padrão ECC).
**Warning signs:** Arquivo CONTINUATION_HANDOFF.md criado em projetos sem IdeiaOS.

### Pitfall 4: PreCompact escreve STATE.md corrompido
**What goes wrong:** precompact-state-save.sh precisa serializar conteúdo do transcript para STATE.md. Se o conteúdo incluir caracteres especiais Markdown ou caracteres de controle, a escrita pode corromper o arquivo.
**Why it happens:** transcript_path é JSONL com conteúdo arbitrário do usuário.
**How to avoid:** Usar um formato de snapshot minimal e estruturado (não inserir conteúdo bruto do transcript). Preferir atualizar apenas a seção `## Compact Snapshot` de STATE.md com data + sumário em bullet points.
**Warning signs:** STATE.md com caracteres estranhos ou seções duplicadas após /compact.

### Pitfall 5: Contador de strategic-compact não reseta entre sessões
**What goes wrong:** Se usar apenas um arquivo por `session_id`, o arquivo em /tmp persiste apenas enquanto o sistema não limpa /tmp. Se usar um arquivo global (sem session_id), conta acumula entre sessões — dispara /compact muito cedo na próxima sessão.
**Why it happens:** /tmp não tem garantia de limpeza imediata no macOS.
**How to avoid:** Usar `/tmp/claude-compact-counter-{session_id}.json` — cada session_id é único por sessão. Quando a sessão termina e nova começa, novo session_id, novo arquivo, contador começa em 0.
**Warning signs:** Sugestão de /compact aparece nas primeiras mensagens da sessão.

### Pitfall 6: additionalContext com conteúdo > 10,000 chars
**What goes wrong:** Claude Code salva automaticamente em arquivo e substitui pelo path quando additionalContext > 10,000 chars. Para session-summary e precompact-state-save com STATE.md grande, isso pode ser inesperado.
**Why it happens:** Limite documentado pela Anthropic.
**How to avoid:** Truncar conteúdo dinâmico a ~5,000 chars nos hooks que injetam contexto grande.
**Warning signs:** Claude vê "[context saved to /tmp/...]" em vez do conteúdo.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### Parse completo do PostToolUse stdin (padrão IdeiaOS)
```bash
# Source: extract-learnings-reminder.sh (IdeiaOS/hooks/) — pattern verificado
INPUT="$(cat 2>/dev/null || echo '{}')"
PARSED="$(echo "$INPUT" | /usr/bin/python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    tn = d.get('tool_name', '')
    ti = d.get('tool_input', {}) or {}
    fp = ti.get('file_path', '')
    session_id = d.get('session_id', '')
    cwd = d.get('cwd', '')
    print(tn)     # linha 1
    print(fp)     # linha 2
    print(session_id) # linha 3
    print(cwd)    # linha 4
except Exception:
    pass
" 2>/dev/null)"
TOOL_NAME="$(echo "$PARSED" | sed -n '1p')"
FILE_PATH="$(echo "$PARSED" | sed -n '2p')"
SESSION_ID="$(echo "$PARSED" | sed -n '3p')"
CWD="$(echo "$PARSED" | sed -n '4p')"
[ -z "$CWD" ] && CWD="$PWD"
```

### Typecheck assíncrono com resultado injetado no Claude
```bash
# Source: padrão derivado de docs + gsd-context-monitor pattern
#!/usr/bin/env bash
set -uo pipefail
INPUT="$(cat 2>/dev/null || echo '{}')"
# (parse session_id, file_path, cwd conforme padrão acima)

# Filtrar apenas .ts/.tsx
case "$FILE_PATH" in
  *.ts|*.tsx) ;;
  *) exit 0 ;;
esac

# Encontrar tsc local
TSC=""
if [ -f "$CWD/node_modules/.bin/tsc" ]; then
  TSC="$CWD/node_modules/.bin/tsc"
elif command -v tsc &>/dev/null 2>&1; then
  TSC="tsc"
fi
[ -z "$TSC" ] && exit 0  # tsc não disponível — silencioso

# Rodar typecheck incremental
# asyncRewake=true: este script roda em background; exit 2 acorda Claude
TSC_OUTPUT="$("$TSC" --noEmit --incremental 2>&1)" || {
  # Erros encontrados — formatar e acordar Claude
  ERRORS_TRIMMED="$(echo "$TSC_OUTPUT" | head -30)"
  # JSON-safe via python3
  MSG="$(/usr/bin/python3 -c "
import json, sys
msg = sys.argv[1]
print(json.dumps({'hookSpecificOutput':{'hookEventName':'PostToolUse','additionalContext':msg}}))
" "TypeScript errors detected:\n$ERRORS_TRIMMED")"
  echo "$MSG"
  exit 2
}
exit 0
```

### PreCompact com snapshot de STATE.md
```bash
# Source: https://code.claude.com/docs/en/hooks (verificado 2026-06-11) + padrão IdeiaOS
#!/usr/bin/env bash
set -uo pipefail
INPUT="$(cat 2>/dev/null || echo '{}')"
CWD="$(echo "$INPUT" | /usr/bin/python3 -c "
import json,sys
try: print(json.load(sys.stdin).get('cwd',''))
except: pass
" 2>/dev/null)"
[ -z "$CWD" ] && CWD="$PWD"

# Detectar STATE.md
STATE_FILE=""
if [ -f "$CWD/.planning/STATE.md" ]; then
  STATE_FILE="$CWD/.planning/STATE.md"
elif [ -f "$CWD/STATE.md" ]; then
  STATE_FILE="$CWD/STATE.md"
fi
[ -z "$STATE_FILE" ] && exit 0  # Projeto sem STATE.md — silencioso

# Atualizar seção Compact Snapshot
TIMESTAMP="$(date '+%Y-%m-%d %H:%M')"
# Remove seção antiga se existir, adiciona nova no final
/usr/bin/python3 -c "
import sys
content = open('$STATE_FILE').read()
marker = '## Compact Snapshot'
if marker in content:
    content = content[:content.index(marker)].rstrip()
new_section = '''

## Compact Snapshot

**Auto-saved:** $TIMESTAMP (PreCompact hook)
'''
open('$STATE_FILE', 'w').write(content + new_section)
print('ok')
" 2>/dev/null

exit 0
```

### Settings.json entries para os 5 novos hooks
```json
// Source: padrão verificado em ~/.claude/settings.json existente
// PostToolUse — typecheck (async)
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/typecheck-on-edit.sh\"",
    "timeout": 60,
    "async": true,
    "asyncRewake": true
  }]
}

// PostToolUse — console-log-guard (síncrono, rápido)
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/console-log-guard.sh\"",
    "timeout": 5
  }]
}

// PreToolUse — strategic-compact (sem matcher específico)
{
  "hooks": [{
    "type": "command",
    "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/strategic-compact.sh\"",
    "timeout": 3
  }]
}

// PreCompact — precompact-state-save (não tem matcher no settings)
// Registrado em: settings.json → hooks.PreCompact
{
  "hooks": [{
    "type": "command",
    "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/precompact-state-save.sh\"",
    "timeout": 10
  }]
}

// Stop — session-summary
{
  "hooks": [{
    "type": "command",
    "command": "bash \"/Users/gustavolopespaiva/.claude/hooks/session-summary.sh\"",
    "timeout": 30
  }]
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Stop hook retornava apenas `decision: "block"` | Stop hook pode retornar `hookSpecificOutput.additionalContext` para continuar sem bloquear | Changelog CC recente | session-summary.sh pode injetar contexto sem bloquear se quiser |
| PreToolUse não suportava additionalContext | PreToolUse suporta `additionalContext` em `hookSpecificOutput` | Changelog CC recente | strategic-compact.sh pode injetar sugestão diretamente |
| Hooks bloqueantes por default | `"async": true` + `"asyncRewake": true` disponível | CC 2.x | typecheck não bloqueia UI |

**Deprecated/outdated:**
- Hooks com output direto para stdout sem JSON: O padrão antigo (antes do `hookSpecificOutput`) usava stdout como texto simples. O padrão atual é sempre JSON estruturado para injection de contexto.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ECC session summary usa 4 seções: "o que funcionou com evidência / o que falhou / o que não foi tentado / próximos passos" | Standard Stack | Formato errado gera sessões menos úteis, mas não quebra nada |
| A2 | `"async": true` + `"asyncRewake": true` estão disponíveis no CC 2.1.173 (versão em uso) | Architecture Patterns | Se não disponível, typecheck deve ser feito de outro modo (spawn background no script) |
| A3 | PreCompact recebe `trigger: "manual"\|"auto"` no stdin | Code Examples | Se campo ausente, script ainda funciona (não filtra por trigger) |
| A4 | `transcript_path` aponta para JSONL com objetos `{"role": ..., "message": {...}}` | Code Examples | Se formato diferente, parsing do Stop hook falha silenciosamente |
| A5 | settings.json aceita evento "PreCompact" como chave de primeiro nível (análogo a "PostToolUse") | Standard Stack | Se nome diferente, hook não registrado — pode ser "Compact" em vez de "PreCompact" |

**Verificado:** A2 e A5 têm suporte via Context7 docs confirmando PreCompact como evento e `async/asyncRewake` como campos suportados. A3 verificado via docs oficiais. A4 verificado via `gsd-context-monitor.js` que lê transcript path implicitamente. A1 é [ASSUMED] baseado na descrição do ECC-ABSORPTION-PLAN.md.

---

## Open Questions

1. **Formato exato do transcript_path JSONL**
   - What we know: É um path para JSONL; `jq '.messages | length'` é usado em exemplos
   - What's unclear: Estrutura exata de cada linha — `{"role":"assistant","message":{...}}` vs outro formato
   - Recommendation: No session-summary.sh, usar abordagem defensiva: tentar parse estruturado; fallback para `grep "assistant"` se parse falhar

2. **`async: true` exige `asyncRewake: true` para injetar feedback?**
   - What we know: São flags independentes segundo os docs
   - What's unclear: Se `async: true` sem `asyncRewake` ainda permite que exit 2 + stderr chegue ao Claude
   - Recommendation: Usar ambos `async: true` + `asyncRewake: true` para typecheck — conservador e documentado

3. **PreCompact evento disponível como chave em settings.json?**
   - What we know: Docs listam "PreCompact" como evento; Context7 confirma
   - What's unclear: Se o nome exato da chave em settings.json é "PreCompact" ou outro
   - Recommendation: Verificar em produção na primeira execução; se não funcionar, tentar "Compact"

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| python3 | Todos os hooks (parse JSON) | ✓ | /usr/bin/python3 (macOS built-in) | — (sem fallback necessário) |
| node_modules/.bin/tsc | typecheck-on-edit.sh | ✓ | Em ideiapartner, nfideia | Exit 0 silencioso se não encontrado |
| ~/.claude/sessions/ dir | session-summary.sh | ✓ | Existe com 1 arquivo | mkdir -p se não existir |
| ~/.claude/hooks/ | Deploy de todos os hooks | ✓ | Já contém 7 hooks ativos | — |
| ~/.claude/settings.json | Registro de hooks | ✓ | CC 2.1.173 | — |
| jq | JSON generation (opcional) | ? | Não verificado | python3 como alternativa (preferido) |
| tsc global | typecheck-on-edit.sh | ✗ | npx tsc retorna erro "not the tsc you're looking for" | node_modules/.bin/tsc (ok) |

**Missing dependencies with no fallback:** Nenhum — todos os hooks têm fallback silencioso (exit 0) quando dependência ausente.

**Missing dependencies with fallback:**
- `tsc` global: não disponível; usar `$CWD/node_modules/.bin/tsc` (presente nos projetos alvo)

---

## Validation Architecture

Não há framework de testes automatizados para hooks bash. Validação é manual + smoke test.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Manual smoke testing (hooks bash — sem framework de unit test aplicável) |
| Config file | none |
| Quick run command | `echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test.ts"},"session_id":"test123","cwd":"/tmp"}' \| bash hooks/typecheck-on-edit.sh` |
| Full suite command | Script de smoke test dedicado (Wave 0 gap) |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command | Exists? |
|-----|----------|-----------|-------------------|---------|
| typecheck | Editar .ts com erro → aviso em segundos | Smoke | Criar .ts com erro, verificar exit 2 | Wave 0 |
| console-log | Adicionar console.log → additionalContext | Smoke | Echo JSON com file_path .ts contendo console.log | Wave 0 |
| precompact | /compact → STATE.md atualizado | Smoke | Echo JSON PreCompact event, verificar STATE.md | Wave 0 |
| session-summary | Stop → arquivo em ~/.claude/sessions/ | Smoke | Echo JSON Stop event, verificar arquivo criado | Wave 0 |
| strategic-compact | 50 calls → sugestão | Smoke | Rodar PreToolUse hook 50x, verificar output call 50 | Wave 0 |

### Wave 0 Gaps
- [ ] `hooks/test-hooks.sh` — smoke tests para todos os 5 hooks
- [ ] Verificar formato exato do transcript_path JSONL em sessão real antes de escrever session-summary.sh

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | sim | Sanitizar session_id antes de usar em path de arquivo |
| V6 Cryptography | não | — |
| V2 Authentication | não | — |
| V4 Access Control | não | — |

### Known Threat Patterns for hooks bash

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via session_id | Tampering | Rejeitar session_id com `/`, `\`, `..` (padrão gsd-context-monitor.js linha 50) |
| Command injection via file_path | Elevation | Nunca passar file_path direto para shell expansion — sempre usar como argumento para python3/tsc |
| Conteúdo malicioso em STATE.md via precompact | Tampering | Truncar e sanitizar antes de escrever; não executar conteúdo |

---

## Sources

### Primary (HIGH confidence)
- `https://code.claude.com/docs/en/hooks` — Protocolo completo de hooks: eventos, stdin, stdout, exit codes, async, asyncRewake, additionalContext, PreCompact (verificado 2026-06-11)
- `/anthropics/claude-code` (Context7) — hookSpecificOutput structure, PreCompact, Stop, PostToolUse fields, timeout configuration
- `/Users/gustavolopespaiva/.claude/hooks/gsd-context-monitor.js` — Padrão de contador em /tmp com session_id, async stdin handling, sanitização de session_id
- `/Users/gustavolopespaiva/dev/IdeiaOS/hooks/extract-learnings-reminder.sh` — Padrão python3 para parse JSON, multi-field extraction, printf JSON output

### Secondary (MEDIUM confidence)
- `/anthropics/claude-code` (Context7) — `async: true` + `asyncRewake: true` fields confirmed; Stop hook `additionalContext` support confirmed from CHANGELOG reference
- `/Users/gustavolopespaiva/.claude/settings.json` — Formato real de registro de hooks (estrutura verificada em produção)

### Tertiary (LOW confidence — marcado como ASSUMED)
- `ECC-ABSORPTION-PLAN.md` — Formato das 4 seções do session summary ECC (não verificado no repo ECC)

---

## Metadata

**Confidence breakdown:**
- Hook protocol (events, stdin/stdout, exit codes): HIGH — verificado via docs oficiais + Context7 + codebase
- async/asyncRewake: HIGH — verificado via docs oficiais
- PreCompact trigger field: HIGH — verificado via docs
- transcript_path JSONL format: MEDIUM — inferido de exemplos nos docs + uso em gsd-context-monitor
- ECC session summary 4-section format: LOW — apenas mencionado no ECC-ABSORPTION-PLAN, não verificado no repo ECC

**Research date:** 2026-06-11
**Valid until:** 2026-09-11 (stable — Claude Code hook protocol raramente muda)
