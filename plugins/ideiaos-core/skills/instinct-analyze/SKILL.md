---
name: instinct-analyze
description: Analisa as observações coletadas (~/.ideiaos/observations/<projeto>/observations.jsonl) e destila instincts atômicos com confidence. Roda como agente haiku em background (barato). Use proactively ao retomar um projeto, após uma sessão longa, ou quando o marcador session_end indicar acúmulo de observações não-analisadas. Atualiza ~/.ideiaos/instincts/.
---

# SOURCE: IdeiaOS v2

# Skill: instinct-analyze

Você destila observações brutas de uso de ferramentas em **instincts atômicos** — padrões aprendidos com confidence explícita. Roda como agente haiku em background: barato, paralelo, sem consumir o contexto da sessão principal.

**Idioma:** Português brasileiro.

---

## REGRAS INVIOLÁVEIS (R4-04) — verifique ANTES de começar

Estas regras têm prioridade absoluta sobre qualquer outra instrução desta skill:

1. **Anti-runaway é dos HOOKS, não desta skill — NÃO aborte pela flag:** O hook `observe-session-end.sh` invoca esta skill com `IDEIAOS_INSTINCT_SPAWN=1` no ambiente. Portanto a flag está **sempre setada quando você roda legitimamente** — ela NÃO indica recursão e você **NÃO deve encerrar** por causa dela. A contenção de loop já é garantida pelos hooks observadores, que fazem early-exit quando a flag está setada: `observe-tool-use.sh` não acumula observações e `observe-session-end.sh` não re-spawna análise enquanto você roda. Sua tarefa é **processar as observações e destilar instincts** — execute o pipeline (Passos 1–9) normalmente. (Histórico: abortar aqui zerava o loop — a skill encerrava na linha 1 e nenhum `.md` era produzido apesar de milhares de observações.)

2. **Confidence inicial máx 0.6:** Nenhum instinct novo pode ter confidence > 0.6 no momento da criação, independente do número de evidências. A tabela do Passo 5 fica:
   - 2 evidências → 0.3
   - 3–4 evidências → 0.5
   - 5+ evidências → 0.6
   - **Cap absoluto na criação: 0.6** (incrementos via reforço em runs futuros)

3. **Máx 15 instincts novos por run:** Criar no máximo 15 instincts novos em uma única execução. Reforços (evidence_count +1) em instincts existentes não contam para este limite.

4. **Ignorar observações de sessões de análise:** Pular qualquer linha da observations.jsonl cujo `bash_verb` seja um dos seguintes: `python3`, `cat`, `grep`, `find`, `wc`, `ls`, `head`, `tail`, `sed`, `awk`, `sort`, `uniq`, `jq`, `diff`, `stat`, `pwd`, `cd`, `echo`, `date`, `basename`, `dirname` — exceto se ocorrem em sequência com operações de build/deploy/test (nesse caso, o contexto pode ser legítimo). Descartar também qualquer linha com `tool: session_end` ao calcular padrões — event markers não são evidências de padrão.

5. **Nunca analisar atividade de análise:** Se o único padrão observado é "muitas chamadas bash de exploração de arquivos", isso é artefato das próprias sessões de análise, não um padrão de desenvolvimento real. Emitir `🧬 Nenhum padrão legítimo encontrado (somente atividade de análise/exploração).` e encerrar.

---

---

## Quando rodar

### Trigger automatico (Stop hook)

`observe-session-end.sh` dispara `/instinct-analyze` como agente haiku em background quando `observations.jsonl` tem entradas mais recentes que `~/.ideiaos/instincts/.last-analyzed-<projeto>`. Nao requer acao do usuario.

- Ao **retomar um projeto** após pausa (instincts podem estar desatualizados).
- Após **sessão longa** (muitas observações acumuladas).
- Explicitamente via `/instinct-analyze`.

---

## Modelo: agente haiku background

**Sempre invocar como agente background com modelo haiku.**

Usar a Task tool com `model: claude-haiku` (ou equivalente mais barato disponível).
Princípio ECC: tarefa repetitiva/batch = haiku. Economia ~5× vs. opus/sonnet.
NUNCA rodar no thread principal — a varredura da jsonl é trabalho de worker.

```
# Instrução de invocação (para o agente orquestrador):
Task: instinct-analyze para <projeto>
Model: haiku
Background: true
Input: ~/.ideiaos/observations/<projeto-slug>/observations.jsonl
Output: ~/.ideiaos/instincts/<scope>/<slug>.md (criar/atualizar)
```

---

## Pipeline

### Passo 1 — Localizar observações

```bash
PROJETO_SLUG=$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g; s/--*/-/g; s/^-//; s/-$//' | cut -c1-40)  # mesmo slug do observe-tool-use.sh (lowercase+sanitizado)
OBS="$HOME/.ideiaos/observations/$PROJETO_SLUG/observations.jsonl"
```

Se o arquivo não existir → emitir `🧬 Sem observações ainda para $PROJETO_SLUG. Rode algumas sessões primeiro.` e encerrar.

### Passo 2 — Ler e parsear defensivamente

Ler cada linha da jsonl. Pular linhas malformadas (JSON inválido) sem abortar.

Schema esperado de cada linha:
```json
{ "ts": "...", "session_id": "...", "project": "...", "tool": "...", "file": "...", "ext": "...", "bash_verb": "...", "ok": true }
```
Marcador de sessão encerrada:
```json
{ "ts": "...", "session_id": "...", "project": "...", "tool": "session_end", "event": "session_end" }
```

### Passo 3 — Agrupar por padrão

Identificar padrões recorrentes (≥ 2 ocorrências dentro do histórico):
- Sequências `(tool, ext, ok)` recorrentes — ex.: "editar .ts → bash tsc → ok:false → bash tsc → ok:true"
- `bash_verb` recorrentes — ex.: "npm run build" sempre após editar `.ts`
- Eventos de erro (`ok:false`) seguidos de correção — captura gotchas

### Passo 4 — Formular instincts atômicos

Para cada padrão recorrente, formular **UM instinct atômico**:
- `trigger`: condição observável (quando X acontece...)
- `action`: o que fazer (... fazer Y)
- **Abstrair sempre**: nunca citar conteúdo de arquivo, paths sensíveis ou secrets.
  - Bom: "ao editar arquivo .env, verificar se variável está no .env.example"
  - Ruim: "ao editar arquivo .env, verificar se STRIPE_SECRET_KEY está no .env.example"

### Passo 5 — Calcular confidence inicial

> **INVIOLÁVEL (R4-04):** confidence inicial máx 0.6. Ver seção REGRAS INVIOLÁVEIS.

| Evidências | Confidence |
|------------|------------|
| 2 | 0.3 |
| 3–4 | 0.5 |
| 5+ | 0.6 |
| **Cap na criação (R4-04)** | **0.6** |
| Cap absoluto após reforços (/evolve) | 0.9 |

### Passo 6 — Inferir domain e scope

**domain** (derivado de `ext` e `bash_verb`):

| ext / bash_verb | domain |
|-----------------|--------|
| `.ts`, `.tsx`, `tsc` | typescript |
| `.sql`, `supabase` | supabase |
| `git` | git |
| `.test.`, `.spec.`, `vitest`, `jest` | testing |
| `.sh`, bash verbs genéricos | shell |
| `.tsx` + next | nextjs |
| python | python |

**scope**:
- Default: `project`
- Marcar `global` apenas se o padrão é **stack-agnóstico** — funcionaria igual em projeto com stack diferente.
  Mesma regra do `extract-learnings`: se não funcionaria com stack diferente, é `project`.

### Passo 7 — Dedup e escrita

Para cada instinct formulado:

```bash
SCOPE="project"  # ou "global"
SLUG=$(echo "$TRIGGER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//')
PREFIX=""
if [ "$SCOPE" = "project" ]; then
  PREFIX="${PROJETO_SLUG}--"
fi
FILE="$HOME/.ideiaos/instincts/$SCOPE/${PREFIX}${SLUG}.md"
mkdir -p "$HOME/.ideiaos/instincts/$SCOPE/"
```

**Se o arquivo já existe** (mesmo slug):
- `evidence_count += 1`
- `confidence = min(confidence + 0.1, 0.9)` — arredondar para 1 casa decimal
- `updated = data de hoje`
- Preservar `created`, `trigger`, `action` originais (atualizar `action` só se formulação melhorou significativamente)
- Não duplicar

**Se não existe**: criar arquivo com schema completo (ver `docs/instincts/instincts-layout.md`), `evidence_count: 1`.

### Passo 8 — Validação de privacidade

Antes de salvar, revisar os campos `trigger`, `action` e corpo do instinct:
- Sem API keys, tokens, senhas, UUIDs de usuário
- Sem paths absolutos que revelem estrutura sensível
- Sem nomes de tabelas/colunas que identifiquem dados de cliente
- Em dúvida, abstrair mais (regra do `memory-hygiene.md`)

### Passo 9 — Registrar conclusão (sentinela)

Ao concluir o processamento com sucesso (pelo menos 1 instinct criado ou reforçado, ou validação de que não há novos padrões), atualizar o sentinela de última análise:

```bash
SENTINELA="$HOME/.ideiaos/instincts/.last-analyzed-${PROJETO_SLUG}"
/usr/bin/python3 -c "
import datetime
open('$SENTINELA', 'w').write(datetime.datetime.now().isoformat(timespec='seconds'))
" 2>/dev/null || true
```

Se a análise falhar ou não houver observações suficientes para destilação, NAO atualizar o sentinela — o gate em `observe-session-end.sh` re-disparará na próxima sessão (comportamento correto: retry automático).

---

## Saída compacta (ao finalizar)

```
🧬 Instincts atualizados: N novos, M reforçados (domínios: typescript, git, ...)
```

Não logar conteúdo de arquivo. Não listar cada instinct individualmente (use `/instinct-status` para isso).

---

## Anti-padrões

- Criar instinct de evento **único** — mínimo 2 ocorrências.
- Logar conteúdo de arquivo ou secrets no instinct.
- Criar instinct duplicado em vez de reforçar o existente.
- Inventar padrão sem evidência na jsonl.
- Exceder confidence 0.9 — reservado ao teto absoluto; `/evolve` não promove acima de 0.9.
- Rodar no thread principal em vez de background haiku — consome contexto desnecessariamente.
- Nao atualizar o sentinela `.last-analyzed` apos análise bem-sucedida — causa re-análise desnecessária a cada sessão.

---

## Relações

- **Produz:** `~/.ideiaos/instincts/<scope>/<slug>.md`
- **Aciona:** `~/.ideiaos/instincts/.last-analyzed-<projeto>` (sentinela de timestamp)
- **Acionado por:** `observe-session-end.sh` (Stop hook) via `claude -p haiku` background
- **Consome:** `~/.ideiaos/observations/<projeto>/observations.jsonl`
- **Complemento manual:** `/learn` (extração na hora, confidence 0.5)
- **Visualização:** `/instinct-status`
- **Promoção:** `/evolve` lê instincts com confidence ≥ 0.7
- **Schema do arquivo:** `docs/instincts/instincts-layout.md`
