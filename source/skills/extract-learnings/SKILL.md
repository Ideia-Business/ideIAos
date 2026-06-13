---
name: extract-learnings
description: Ao final de uma implantação não-trivial, extrai aprendizado em formato estruturado (padrão > evidência > regra prática > falsos positivos) e grava em `docs/learnings/YYYY-MM-DD-<slug>.md`. Promove para memória global quando o padrão for replicável. Também espelha ADRs novos (`docs/decisions/`) ao vault Obsidian (`Decisions/`). Integra-se ao final da skill lovable-handoff e roda standalone em projetos não-Lovable.
---

# Skill: extract-learnings

Você é responsável por **destilar a sessão atual em aprendizado reaproveitável**. Esta skill é invocada **ao final** de uma implantação, após:

- Bug fix com causa raiz não-óbvia ou recorrência
- Feature que envolveu decisão arquitetural significativa
- Refactor que revelou padrão antes não-explícito
- Descoberta de gotcha de stack/vendor
- Pós-mortem de incidente em produção

Não é invocada para:

- Sessões puramente operacionais (dep bump, doc typo, rename trivial)
- Tarefas conversacionais sem código
- Pedidos do tipo "explique" sem mudança real

**Idioma:** Português brasileiro.

---

## Gate inicial — vale a pena registrar?

Antes de criar arquivo, responder 3 perguntas mentalmente:

1. **Replicabilidade** — outro agente, em outra sessão, ganharia tempo se lesse isso? Se **não**, abortar.
2. **Não-obviedade** — a regra derivada seria adivinhada por alguém lendo só o código? Se **sim** (óbvia), abortar.
3. **Estabilidade** — o aprendizado vai sobreviver às próximas 5 mudanças da feature? Se **não** (efêmero), abortar.

Se passou nas 3, prosseguir. Se não passou, **dizer ao usuário** numa linha:
`📚 Sessão sem aprendizado registrável (operacional / óbvio / efêmero).`

---

## Pipeline de extração

### Passo 1 — Identificar o padrão

Releia mentalmente a sessão. Pergunte: "qual é o **único padrão central** que aprendi?" Se houver
mais de um, **gerar um arquivo por padrão** (cada um é compacto).

Padrão é **abstrato**: não fala de `crm_leads`, fala de "tabela com RLS por carteira".
Não fala de `INC-351`, fala de "campos visíveis a um usuário mas não a outro".

### Passo 2 — Slug do nome do arquivo

`YYYY-MM-DD-<slug-do-padrão>.md`

- `<slug>` em kebab-case, descreve o **padrão**, não o incidente.
- Bom: `2026-05-28-cache-rls-vs-rpc-override-divergence.md`
- Ruim: `2026-05-28-inc-351-fix.md`

### Passo 3 — Preencher o template

Copiar `docs/learnings/_TEMPLATE.md` (estrutura padrão) e preencher cada seção. **Não pular seções**:

- Frontmatter completo (date, session_type, incident, commit, tags, applies_to_projects)
- Trigger em 1 frase
- O padrão (abstrato)
- Evidência (links `arquivo:linha`, commits, queries)
- Regra prática derivada (prescritiva)
- Falsos positivos (mesmo que "Nenhum identificado nesta sessão")
- Cross-references

### Passo 4 — Decidir promoção

No frontmatter:

- `applies_to_projects: [<este-projeto>]` — específico (padrão)
- `applies_to_projects: [global]` — replicável em outros projetos da equipe

Critério para `[global]`: a regra prática funcionaria igual em outro projeto com **stack diferente**?
Se sim, é global.

Se global:
1. Criar entrada na memória Claude: `~/.claude/projects/.../memory/learning_<slug>.md`
2. Atualizar `MEMORY.md` (índice) com link
3. Marcar `promote_to_vault: true` no frontmatter do arquivo no repo
4. **Promover ao vault Obsidian** — ver Passo 4b

### Passo 4b — Promover ao Obsidian vault (quando global)

O vault **"Ideia Business — Second Brain"** é a síntese curada cross-projeto (segundo cérebro).
Acesso é **direto via filesystem** — sem MCP, sem Obsidian aberto; o Sync propaga entre máquinas.

```bash
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideia Business - Second Brain"
```

1. Usar `$VAULT/_Templates/Learning.md` como base.
2. Criar `$VAULT/Learnings/<Título legível>.md` — **nome humano**, não slug (graph view fica útil).
3. Refinar o padrão (mais abstrato que o do repo); frontmatter `applies_to: global`, `source_repo`, tags `#stack/...` `#category/...`.
4. Cross-references viram **wiki-links** `[[Nota]]`, nunca markdown links — incluir `[[00 Index]]`.
5. Marcar no learning do repo: `- [x] Promovido para Obsidian vault em <data>`.

Só promover o que é **cross-projeto e estável** — o vault é curadoria, não despejo.
Se o vault não existir no caminho, pular e deixar `promote_to_vault: true` como sinal pendente.

### Passo 4c — Espelhar ADRs novos ao vault (Decisions/)

Se a sessão **produziu ou alterou um ADR** (Architecture Decision Record em `docs/decisions/<slug>.md` do repo), espelhe-o no vault. A pasta `Decisions/` é o registro cross-projeto de decisões estratégicas, e a sincronização repo→vault é **manual** (não há hook) — se este passo for pulado, a pasta defasa silenciosamente (aconteceu: ficou vazia de 28/mai a 13/jun-2026 mesmo com ADRs no repo).

1. Para cada ADR novo/alterado em `docs/decisions/`, criar/atualizar `$VAULT/Decisions/<Título legível>.md` — **nome humano**, não slug.
2. Base: `$VAULT/_Templates/Decision.md`. Frontmatter: `type: decision`, `status`, `created`, `affects_projects: [...]`, `source_repo`, `source_file` (caminho do ADR canônico no repo), `tags` `#decision/...`.
3. É um **espelho condensado**, não cópia crua: callout no topo marcando "espelho de `docs/decisions/<slug>.md` (fonte canônica)"; preservar Contexto/Decisão/Consequências **sem inventar nem omitir** decisão.
4. Cross-references em **wiki-links** `[[Nota]]`: incluir `[[00 Index]]`, `[[Projects/<Projeto>]]` e `[[Changelog/<Projeto>]]`.
5. Linkar de volta: `[[ADR]]` na entrada do `Changelog/<Projeto>.md` **e** na seção "## Decisões (ADRs)" do `00 Index.md`.

O ADR no repo continua sendo a **fonte canônica**; o vault é a vista cross-projeto navegável. Se o vault não existir no caminho, pular (mesmo critério do Passo 4b).

### Passo 5 — Linkar de volta

Se o postmortem do incidente existir, adicionar linha no fim dele:

```markdown
## Learning extraído

- `docs/learnings/YYYY-MM-DD-<slug>.md` — <título curto>
```

### Passo 6 — Anunciar no bloco 7 da resposta final

No modelo de resposta de conclusão de implantação (definido em
`docs/lovable/conclusao-implantacao.md` ou `IdeiaOS/templates/lovable/conclusao-implantacao.md.tmpl`),
preencher o bloco 7:

```
📚 Learning registrado: `docs/learnings/YYYY-MM-DD-<slug>.md` — <título curto>
   Tags: [tag1, tag2]  ·  Aplica-se a: [<este-projeto> | global]
```

---

## Insumo automático — observações e instincts (Continuous Learning v2)

A extração não parte do zero: a sessão já gerou observações
(`~/.ideiaos/observations/<projeto>/observations.jsonl`) e possivelmente instincts
(`~/.ideiaos/instincts/`). Antes do Passo 1, considerar:

- Rodar (ou ter rodado) `/instinct-analyze` para destilar as observações em instincts.
- Um instinct **maduro (≥0.7)** já é forte candidato a virar learning de repo/vault — nesse
  caso, prefira `/evolve` (que promove ao vault/rules) e referencie o instinct na Evidência.
- `extract-learnings` continua sendo a **curadoria humana/IA final**: aplica o gate triplo
  e escreve o `docs/learnings/...md` quando o padrão merece registro formal de projeto.

Em suma: observações (cru) → instincts (`/instinct-analyze`, `/learn`) → learning de
projeto (`extract-learnings`) → vault/rules (`/evolve`). Cada camada é mais curada que a anterior.

---

## Anti-padrões

- ❌ Criar learning para **cada** bug. Use o gate: replicável, não-óbvio, estável.
- ❌ Copiar 50 linhas de código no campo Evidência. Use `arquivo:linha`.
- ❌ Escrever em primeira pessoa narrativa ("vi que…"). Use prescritivo ("quando X, fazer Y").
- ❌ Duplicar conteúdo do postmortem. Learning = padrão; postmortem = história.
- ❌ Tags genéricas demais (`bug`, `fix`). Use stack + categoria (`supabase rls divergence cache`).
- ❌ Marcar tudo como `[global]`. Maioria é project-specific. Critério: stack diferente, mesma regra.

---

## Saída esperada

Ao concluir, anunciar **em 2 linhas**:

```
📚 Learning extraído: `docs/learnings/2026-05-28-cache-rls-vs-rpc-override-divergence.md`
   Tags: [supabase, rls, cache, divergence-pattern]  ·  Aplica-se a: [ideiapartner]
```

Ou se promovido:

```
📚 Learning extraído + promovido a memória global: ...
   Tags: [...]  ·  Aplica-se a: [global]
```

---

## Quando esta skill é invocada

- Auto-invocação ao final de implantação significativa (parte do bloco 7 do modelo de resposta)
- Embutida na skill `lovable-handoff` (passo final)
- `/extract-learnings` (explícito) — força extração em qualquer ponto

## Limitações

- Não decide sozinha que é global se a regra é só similar — exige stack-agnóstico real.
- Não modifica código de produção, só docs e memória.
- Não substitui postmortem — complementa.

## Memórias relacionadas

- `reference_learnings_protocol.md` — protocolo completo
- Skill `recall-learnings` — par desta no início da sessão
- Skill `lovable-handoff` — invoca esta no passo 7
- Skill `/instinct-analyze` — destila observações em instincts (insumo desta)
- Skill `/learn` — extração manual mid-session de instinct
- Skill `/evolve` — promove instincts maduros ao vault/rules (camada seguinte)
