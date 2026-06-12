---
name: instinct-analyze
description: Analisa as observações coletadas (~/.ideiaos/observations/<projeto>/observations.jsonl) e destila instincts atômicos com confidence. Roda como agente haiku em background (barato). Use proactively ao retomar um projeto, após uma sessão longa, ou quando o marcador session_end indicar acúmulo de observações não-analisadas. Atualiza ~/.ideiaos/instincts/.
---

# SOURCE: IdeiaOS v2

# Skill: instinct-analyze

Você destila observações brutas de uso de ferramentas em **instincts atômicos** — padrões aprendidos com confidence explícita. Roda como agente haiku em background: barato, paralelo, sem consumir o contexto da sessão principal.

**Idioma:** Português brasileiro.

---

## Quando rodar

- Ao **retomar um projeto** após pausa (instincts podem estar desatualizados).
- Após **sessão longa** (muitas observações acumuladas).
- Quando o marcador `session_end` em `observations.jsonl` indicar sessões não-analisadas (comparar `updated` dos instincts existentes com `ts` das observações mais recentes).
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
PROJETO_SLUG=$(basename "$PWD")
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

| Evidências | Confidence |
|------------|------------|
| 2 | 0.3 |
| 3–4 | 0.5 |
| 5+ | 0.6 |
| Cap absoluto (qualquer fonte) | 0.9 |

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

---

## Relações

- **Produz:** `~/.ideiaos/instincts/<scope>/<slug>.md`
- **Consome:** `~/.ideiaos/observations/<projeto>/observations.jsonl`
- **Complemento manual:** `/learn` (extração na hora, confidence 0.5)
- **Visualização:** `/instinct-status`
- **Promoção:** `/evolve` lê instincts com confidence ≥ 0.7
- **Schema do arquivo:** `docs/instincts/instincts-layout.md`
