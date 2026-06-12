---
name: learn
description: Extração manual mid-session — invoque na hora em que você acabou de resolver algo não-trivial e quer registrar a lição como instinct imediato (confidence 0.5), sem esperar a análise automática. Escreve direto em ~/.ideiaos/instincts/.
---

# SOURCE: IdeiaOS v2

# Skill: learn

Você captura um **instinct atômico imediato** enquanto a descoberta ainda é fresca — sem esperar o ciclo automático de `/instinct-analyze`. Resultado: 1 instinct em `~/.ideiaos/instincts/` com confidence 0.5.

**Idioma:** Português brasileiro.

---

## Quando usar

- Você acabou de resolver algo não-trivial e quer registrar a lição agora.
- Descobriu um gotcha que vai repetir-se em sessões futuras.
- Quer capturar uma decisão arquitetural que ainda não virou observação estruturada.
- Explicitamente via `/learn`.

**Não usar para:**
- Soluções triviais ou óbvias
- Correções únicas que provavelmente não se repetem
- Qualquer coisa que já está nos docs do projeto

---

## Gate leve (1 pergunta obrigatória)

Antes de escrever o instinct, responder mentalmente:

> **"Isso se repete em sessões futuras?"**

- Se **não** (evento único desta sessão): abortar com 1 linha.
  ```
  📚 Nada a registrar — específico demais desta sessão.
  ```
- Se **sim** (vai se repetir): continuar.

---

## Pipeline

### Passo 1 — Formular trigger + action

Formular atomicamente:
- `trigger`: quando o padrão se aplica (condição observável)
- `action`: o que fazer quando o trigger ocorre

**Regra de abstração obrigatória:**
- Sem conteúdo de arquivo, sem secrets, sem paths sensíveis, sem nomes de tabelas/dados de cliente.
  - Bom: "ao criar migration SQL → testar rollback antes de aplicar em produção"
  - Ruim: "ao criar migration add_credit_limit_to_wallets → testar rollback"

### Passo 2 — Definir campos

- `confidence: 0.5` — manual sempre nasce em 0.5. Não inventar confidence maior.
- `domain`: área do instinct (typescript, supabase, git, testing, shell, nextjs, python...)
- `scope`: default `project`. Marcar `global` só se stack-agnóstico (mesmo critério do `extract-learnings`).
- `source: learn`
- `evidence_count: 1` (se novo) ou incrementado (se reforçando existente)

### Passo 3 — Dedup

Antes de criar, verificar se já existe instinct com o mesmo slug:

```bash
PROJETO_SLUG=$(basename "$PWD")
SLUG=$(echo "$TRIGGER" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | tr -s '-' | sed 's/^-//;s/-$//')

if [ "$SCOPE" = "project" ]; then
  FILE="$HOME/.ideiaos/instincts/project/${PROJETO_SLUG}--${SLUG}.md"
else
  FILE="$HOME/.ideiaos/instincts/global/${SLUG}.md"
fi
```

**Se o arquivo já existe** (mesmo slug):
- `evidence_count += 1`
- `confidence = min(confidence + 0.1, 0.9)` — reforçar o existente
- `updated = data de hoje`
- Não criar duplicata — reforço é sempre preferível

**Se não existe**: criar arquivo novo com schema completo.

### Passo 4 — Escrever o instinct

```bash
mkdir -p "$HOME/.ideiaos/instincts/$SCOPE/"
```

Usar o schema completo de `docs/instincts/instincts-layout.md`:

```markdown
---
trigger: "<trigger formulado>"
action: "<action formulado>"
confidence: 0.5
domain: "<domain>"
scope: "<project|global>"
project: "<projeto-slug>"   # somente se scope=project
evidence_count: 1
created: "<YYYY-MM-DD>"
updated: "<YYYY-MM-DD>"
source: "learn"
---
# SOURCE: IdeiaOS v2

## Evidência
- <bullet abstrato: o que foi observado/resolvido nesta sessão>

## Falsos positivos
- <quando NÃO aplicar — se já conhecido; caso contrário: "Nenhum identificado nesta sessão">
```

---

## Saída ao finalizar

```
🧬 Instinct registrado: "<trigger>" → "<action>" (confidence 0.5, domain <X>, scope <Y>)
```

Se reforçou um existente:
```
🧬 Instinct reforçado: "<trigger>" (confidence 0.5 → <nova>, evidências: <N>)
```

---

## Anti-padrões

- Registrar trivialidade — use o gate: "se repete em sessões futuras?"
- Criar duplicata em vez de reforçar — sempre verificar slug antes de criar.
- Inventar confidence > 0.5 no nascimento — manual nasce sempre em 0.5.
- Incluir conteúdo literal de arquivo, secrets ou dados sensíveis no instinct.
- Usar como substituto de documentação formal — instinct é para padrões operacionais repetíveis.

---

## Relações

- **Complemento automático:** `/instinct-analyze` faz o mesmo em lote; `/learn` faz na hora.
- **Mesmo layout:** ambos escrevem em `~/.ideiaos/instincts/` com o schema de `docs/instincts/instincts-layout.md`.
- **Mesma regra de dedup:** slug(trigger) — nunca divergir desta regra.
- **Visualização:** `/instinct-status` para ver todos os instincts.
- **Promoção:** `/evolve` (quando confidence ≥ 0.7 após reforços acumulados).
