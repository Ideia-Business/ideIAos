---
name: evolve
description: Promove instincts maduros (confidence ≥0.7) de ~/.ideiaos/instincts/ para a camada permanente — scope=project vira nota em Learnings/ do vault Obsidian; regra de comportamento stack-agnóstica vira arquivo em source/rules/. Também faz curadoria: deduplica e aplica decay em instincts estagnados. Use quando /instinct-status mostrar instincts maduros, ou periodicamente para consolidar aprendizado.
---

# SOURCE: IdeiaOS v2

# Skill: evolve

Você é responsável por **promover instincts maduros** de `~/.ideiaos/instincts/` para a camada
permanente de aprendizado, e por **curar** o banco de instincts (dedup + decay).

**Idioma:** Português brasileiro.

---

## Quando usar

- `/instinct-status` exibe instincts com confidence ≥ 0.7 (maduros).
- Consolidação periódica da sessão (fim de ciclo de trabalho).
- Antes de arquivar um projeto: promover o que for reaproveitável.

---

## Pipeline de promoção

### Passo 1 — Varrer e selecionar

```bash
# instincts do projeto atual + globais
PROJ="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-')"
ls ~/.ideiaos/instincts/global/*.md 2>/dev/null
ls ~/.ideiaos/instincts/project/${PROJ}--*.md 2>/dev/null
```

Para cada arquivo, ler o frontmatter e selecionar os que tenham `confidence >= 0.7`
e ainda **não** tenham `promoted: true`.

### Passo 2 — Decidir destino de cada instinct maduro

Para cada instinct selecionado, classificar em uma de duas categorias:

#### Regra de comportamento

Critérios: prescritiva ("sempre X antes de Y"), stack-agnóstica, aplicável em qualquer projeto.

Destino: `source/rules/common/` ou `source/rules/<stack>/` (dependendo da especificidade).

O arquivo de rule usa o **header das rules existentes** — confirmar o formato antes de criar:
```bash
head -1 source/rules/common/*.mdc 2>/dev/null | head -5
```
O padrão atual usa um header HTML-comment com campos SOURCE, kind e targets (veja
`source/rules/common/*.mdc` para o formato exato), processado pelo `build-adapters.sh`
para gerar `.cursor/rules/*.mdc`. Skills usam `# SOURCE: IdeiaOS v2` (header Markdown) —
formatos diferentes por design (decisão 03-03/03-04).

#### Learning de projeto

Critérios: síntese curada de padrão cross-projeto, não puramente prescritivo, ou específico ao projeto.

Destino: vault Obsidian.

```bash
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideia Business - Second Brain"
```

Se o vault não existir no path (máquina sem iCloud) → pular promoção ao vault, deixar o
instinct marcado `promoted: pending` e avisar. Não falhar silenciosamente sem mensagem.

Criação da nota no vault:
1. Usar `$VAULT/_Templates/Learning.md` como base se existir.
2. Criar `$VAULT/Learnings/<Título humano>.md` — **nome legível**, não slug (graph view).
3. Frontmatter: `applies_to` (project ou global), tags `#stack/...` `#category/...`.
4. Cross-refs como wiki-links `[[...]]`, incluindo `[[00 Index]]`.
5. Refinar o padrão: mais abstrato que o do instinct bruto; nenhum secret/credencial.

**Privacidade (memory-hygiene, Regra 1):** ao promover ao vault, nenhum secret, credencial
ou conteúdo literal de arquivo deve constar na nota — apenas o padrão abstraído.

### Passo 3 — Marcar o instinct de origem

Após promover, atualizar o frontmatter do instinct original:

```yaml
promoted: true
promoted_to: <path relativo ou vault path>
promoted_at: <YYYY-MM-DD>
```

**Não deletar o instinct** — rastreabilidade. Opcionalmente mover para
`~/.ideiaos/instincts/_promoted/` para manter o banco ativo enxuto (documentar a escolha
se fizer isso).

---

## Curadoria — decay + dedup

Executar após (ou durante) a promoção, sobre o universo completo de instincts não-promovidos.

### Deduplicação

Identificar instincts com `slug(trigger)` equivalente ou ações redundantes:

- Fundir: somar `evidence_count`, manter a maior `confidence`, atualizar `updated`.
- Registrar a fusão no instinct sobrevivente (campo `merged_from: [<slug1>, <slug2>]`).
- Arquivar o(s) duplicado(s) em `~/.ideiaos/instincts/_archive/` — nunca deletar sem rastro.

### Decay

Instinct não reforçado (sem `updated` recente — heurística: várias sessões novas sem
que o instinct tenha sido reativado/observado):

- Reduzir `confidence` em ~0.1.
- Se `confidence` cair abaixo de ~0.2 → arquivar em `~/.ideiaos/instincts/_archive/`.
- **Nunca deletar silenciosamente** — sempre registrar no `_archive/`.

---

## Saída

```
🧬 Evolve: N instincts promovidos (X→vault, Y→rules), M deduplicados, K decay/arquivados.
```

Se nenhum instinct maduro encontrado:
```
🧬 Evolve: nenhum instinct ≥0.7 pendente. Banco atual: N total, M promovidos anteriormente.
```

---

## Anti-padrões

- Não promover instinct com confidence < 0.7 — aguardar mais evidências.
- Não despejar tudo no vault — curadoria, não dump (mesma disciplina do `extract-learnings`).
- Não duplicar Learning já existente no vault — buscar antes de criar.
- Não deletar instinct sem rastro em `_archive/`.
- Não incluir secrets ou conteúdo literal de arquivos na nota do vault.

---

## Quando esta skill é invocada

- `/evolve` (explícito) — força promoção + curadoria.
- Após `/instinct-status` mostrar maduros (confidence ≥ 0.7).
- No fechamento de sessão, após `extract-learnings` para instincts que já passaram pelo gate.

## Limitações

- Não cria instincts — use `/learn` (manual) ou `/instinct-analyze` (automático).
- Não decide pelo usuário qual é "regra de comportamento" vs "learning de projeto" quando ambíguo — perguntar.
- Se o vault Obsidian estiver indisponível, marca `promoted: pending` e segue.

## Memórias relacionadas

- Skill `/instinct-analyze` — destila observações em instincts
- Skill `/instinct-status` — lista instincts com barras de confidence
- Skill `/learn` — extração manual mid-session
- Skill `extract-learnings` — curadoria humana final → `docs/learnings/`
