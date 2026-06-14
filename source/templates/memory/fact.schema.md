# Canonical Fact Format — IdeiaOS Shared Memory

> Especificação do formato de **um fato** no store compartilhado
> (`planning:.planning/memory/shared/facts/<type>_<slug>.md`).
>
> **Princípio de design:** este formato **espelha 1:1 a memória nativa do
> Claude Code** (`~/.claude/projects/<slug>/memory/*.md`). Por isso o import é
> uma **cópia direta** — sem transformação — e o export idem. Os campos
> `scope`/`project`/`contributed_by`/`expires` abaixo são acréscimos do IdeiaOS
> dentro do bloco `metadata:` nativo: o Claude Code ignora chaves extras de
> `metadata`, então o fato continua válido como memória nativa.

---

## 1. Nome do arquivo

```
<type>_<slug>.md
```

- `<type>` ∈ `learning | reference | feedback | project` (ver §3, campo `type`).
- `<slug>` em kebab-case, descreve o **padrão** (abstrato), não o incidente.
  - Bom: `learning_version-reset-migration-semver-trap.md`
  - Ruim: `learning_inc-351-fix.md`
- O nome é **determinístico**: o mesmo fato lógico → o mesmo arquivo em qualquer
  máquina. Isso torna o merge entre máquinas **aditivo** (arquivos diferentes =
  fatos diferentes; nunca conflito de conteúdo).

---

## 2. Estrutura geral

YAML frontmatter + corpo markdown — idêntico à memória nativa:

```markdown
---
name: <kebab-case-unique-name>
description: <resumo de uma linha — vira a linha do índice MEMORY.md>
metadata:
  node_type: memory
  type: project
  originSessionId: <uuid-da-sessão-de-origem>
  # ── extensões IdeiaOS (ignoradas pelo Claude Code, lidas pelo bridge) ──
  scope: shared
  project: IdeiaOS
  contributed_by: <slug-da-máquina-ou-autor>
  expires: 2026-12-31        # opcional — ver §3
---

<corpo markdown — 2 a 4 parágrafos>

**Why:** <causa raiz — por que isso é verdade>
**How to apply:** <orientação comportamental prescritiva — quando X, fazer Y>
```

---

## 3. Campos do frontmatter

### Nível raiz

| Campo | Obrigatório | Valores | Notas |
|-------|-------------|---------|-------|
| `name` | sim | kebab-case único | Igual ao `<slug>` do arquivo, sem o prefixo de tipo. Espelha o `name` nativo. |
| `description` | sim | 1 linha | Vira a linha do índice `MEMORY.md`. Prescritivo e específico, não genérico. |
| `metadata` | sim | objeto | Bloco nativo + extensões IdeiaOS. |

### `metadata.*` — bloco nativo (espelhado do Claude Code)

| Campo | Obrigatório | Valores | Notas |
|-------|-------------|---------|-------|
| `node_type` | sim | `memory` | Constante. Marca o nó como fato de memória. |
| `type` | sim | `project \| reference \| user \| feedback` | **Tipo nativo** (ver mapa abaixo). |
| `originSessionId` | sim | uuid | Sessão que originou o fato. Preservado no export para auditoria. |

### `metadata.*` — extensões IdeiaOS

| Campo | Obrigatório | Valores | Notas |
|-------|-------------|---------|-------|
| `scope` | sim | `shared \| local` | `shared` → vai para `shared/facts/`, sincroniza entre máquinas. `local` → fica em `local/staging/`, gitignored no `planning`, **nunca** entra no `shared/`. |
| `project` | sim | nome do repo | Escopo por-projeto do store `planning`. Ex.: `IdeiaOS`, `nfideia`. |
| `contributed_by` | sim | slug de máquina/autor | Quem exportou. Ajuda no merge cross-máquina e na auditoria. |
| `expires` | não | data `YYYY-MM-DD` | Se presente, o fato é candidato a eviction após a data (decay automático é F5-03, deferred). Use para fatos sabidamente temporários. |

#### Mapa `type` (nativo) × prefixo de arquivo

O **prefixo do nome de arquivo** usa o vocabulário do IdeiaOS; o **`metadata.type`** usa o vocabulário nativo do Claude Code. Correspondência:

| Prefixo do arquivo | `metadata.type` nativo | Significado |
|--------------------|------------------------|-------------|
| `learning_` | `project` | Padrão aprendido, específico ao projeto |
| `reference_` | `reference` | Gotcha arquitetural, API externa, fato estável de referência |
| `feedback_` | `feedback` | Preferência/correção do usuário |
| `user_` | `user` | Fato sobre o usuário/equipe |

Manter os dois consistentes: um `learning_*.md` deve ter `type: project`. Isso preserva a compatibilidade com a memória nativa (que indexa por `type`).

---

## 4. Convenções de corpo

- **2 a 4 parágrafos.** Conciso; o índice já carrega o resumo.
- **Abstrato, não anedótico.** Fala de "tabela com RLS por carteira", não de `crm_leads`. Fala do padrão, não do `INC-NN`.
- **Prescritivo, não narrativo.** "Quando X, fazer Y" — não "vi que aconteceu Z".
- **Dois marcadores ao final** (espelham a memória nativa):
  - `**Why:**` — a causa raiz (por que o padrão é verdadeiro).
  - `**How to apply:**` — a orientação comportamental concreta.
- **Cross-references** entre fatos via wiki-link nativo `[[name-do-outro-fato]]`
  (mesma sintaxe da memória nativa). Não use markdown links entre fatos.
- **Sem secrets.** Nenhuma API key, JWT, connection string ou credencial. O
  export roda um secret-scan (R5-06) e **recusa** o fato se detectar — limpe
  antes. Referencie o segredo por nome/local, nunca pelo valor.

---

## 5. Exemplo completo (válido em ambos os lados)

```markdown
---
name: version-reset-migration-semver-trap
description: Migração de pacote com reset de versionamento inverte semver — guardas de pin devem ser package-aware
metadata:
  node_type: memory
  type: project
  originSessionId: d8431dac-280c-4f04-b727-c463ba247aa7
  scope: shared
  project: IdeiaOS
  contributed_by: macbook-air-2
---

Quando um pacote migra de linhagem e recomeça o versionamento em `1.x`, o menor
número passa a ser o **mais novo** — qualquer heurística "maior = atual" reverte
o pin para trás. Pins de versão devem ser package-aware, não puramente semver.

**Why:** versionamento resetado quebra a ordenação semver entre linhagens.
**How to apply:** nunca editar o pin à mão; o único escritor é o script de bump,
e o pre-commit valida faixa e igualdade instalado×pin. Ver [[ambiguous-drift-warning-induces-agent-revert]].
```

(O arquivo acima seria salvo como `facts/learning_version-reset-migration-semver-trap.md`.)

---

## 6. Por que isto importa para o bridge

- **Import = cópia.** Como o frontmatter é o nativo + extras ignoráveis, o
  `memory-import.sh` copia `shared/facts/*.md` direto para
  `~/.claude/projects/<slug>/memory/` sem reescrever nada.
- **Export = cópia + scan.** O `memory-export.sh` lê os fatos nativos, garante
  os campos de extensão (`scope`/`project`/`contributed_by`), faz secret-scan, e
  os grava em `shared/facts/`.
- **Índice idempotente.** `MEMORY.md` é reconstruído por scan de `facts/`
  (ordenado por nome de arquivo), nunca editado in-place — duas reconstruções do
  mesmo diretório produzem output idêntico (R5-05).
- **Merge sem conflito.** Um-arquivo-por-fato + nome determinístico → máquinas
  diferentes produzem arquivos diferentes; o git merge é aditivo (R5-04).

---

## Componentes relacionados

- `source/templates/memory/MEMORY.header.md` — cabeçalho anti-trap do índice
- `source/templates/memory/planning.gitignore` — ignora `memory/local/` no `planning`
- `source/skills/memory-sync/SKILL.md` — gatilho manual import/export
- `.planning/research/STACK.md` §1 / §5 — formato nativo verificado e padrão one-file-per-fact
- `.planning/research/ARCHITECTURE.md` — contrato de design da camada de memória
