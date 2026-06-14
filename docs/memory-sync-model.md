# Modelo de memória do IdeiaOS — 3 camadas (Lovable-safe)

**Milestone:** v5 — Memória compartilhada entre IDEs (Fases 18–22)
**Requisito:** R5-11 (modelo de 3 camadas documentado)
**Status:** Aceito
**Última atualização:** 2026-06-14

> Este documento descreve o modelo de memória de 3 camadas do IdeiaOS e — de
> forma explícita — por que ele **não cria um segundo cérebro paralelo**. O vault
> Obsidian continua sendo a biblioteca curada; o branch `planning` é apenas o
> **transporte** que faz a memória nativa de cada IDE convergir entre máquinas.

---

## TL;DR

| Camada | Onde vive | Escopo | Quem escreve | Quem lê |
|--------|-----------|--------|--------------|---------|
| **1. Local (nativo)** | `~/.claude/projects/<slug>/memory/` (Claude Code) · `.cursor/rules/memory-bridge.mdc` (Cursor, gerado, gitignored) | por-máquina, por-projeto | a IDE (Claude Code) e o `memory-import.sh` | `recall-learnings` (Passo 4), a própria IDE |
| **2. Shared (planning)** | `planning:.planning/memory/shared/` (committed) · `planning:.planning/memory/local/staging/` (gitignored no planning) | por-projeto, multi-máquina | `memory-export.sh` / `/memory-sync export` (via git plumbing) | `memory-import.sh` / `/memory-sync import` |
| **3. Vault Obsidian** | `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideia Business - Second Brain/` (`Learnings/`, `Decisions/`, `References/`, `Stack Gotchas/`) | **cross-projeto**, curado | `extract-learnings` (Passo 4b) e `/evolve` — **gate humano** | `recall-learnings` (Passo 5), `extract-learnings` |

O fluxo é **uma direção por gatilho**:

```
camada 1  ──export (Stop / /memory-sync export)──►  camada 2
camada 2  ──import (SessionStart / /memory-sync import)──►  camada 1
camada 1  ──/extract-learnings Passo 4b (curadoria humana)──►  camada 3
```

---

## Camada 1 — Local (memória nativa da IDE, per-machine)

A memória nativa é o working set de cada sessão de IDE, **por máquina**:

- **Claude Code:** `~/.claude/projects/<slug>/memory/` — um `MEMORY.md` (índice) +
  um `.md` por fato (`learning_<slug>.md`, `reference_<slug>.md`, etc.). O `<slug>`
  é o path absoluto do repo com `/` → `-` (ver bug #30828 abaixo). É carregada
  pelo Claude Code a cada sessão (primeiras ~200 linhas do `MEMORY.md`).
- **Cursor:** `.cursor/rules/memory-bridge.mdc` (`alwaysApply: true`, **gitignored**),
  regenerado a cada import. Cursor é consumidor passivo — não exporta (não expõe
  hooks nem memória em filesystem).

**Per-machine por natureza.** Esses paths são locais à máquina (fora do repo, ou
gitignored). Duas máquinas têm memória nativa independente — é a camada 2 que as
reconcilia. A memória nativa nunca é commitada no working tree do branch corrente.

> **Bug #30828 (slug não-determinístico):** o Claude Code às vezes troca `_` por
> `-` no slug, criando um 2º diretório para o mesmo projeto. As pontes
> (`memory-import.sh` / `memory-export.sh`) checam **ambas** as variantes e usam a
> que tiver `MEMORY.md`. Detalhe em `.planning/research/STACK.md`.

---

## Camada 2 — Shared (store canônico no branch `planning`, transporte git)

O store canônico multi-máquina vive **exclusivamente** no branch `planning`:

```
planning:.planning/memory/
├── shared/                    ← committed no planning; store multi-máquina canônico
│   ├── MEMORY.md              ← índice (regenerado deterministicamente, idempotente)
│   └── facts/
│       └── <type>_<slug>.md   ← um arquivo por fato (mesmo formato da memória nativa)
└── local/                     ← gitignored no planning; staging por máquina
    └── staging/
        └── <date>-<slug>.md
```

- **Leitura sem checkout:** `git show planning:.planning/memory/shared/MEMORY.md` /
  `git archive planning .planning/memory/shared/ | tar -x -C <tmp>`. Não troca
  branch, não suja o working tree (mesmo padrão de `git-sync-check.sh`).
- **Escrita sem checkout:** git plumbing (`hash-object -w` → índice temporário →
  `write-tree` → `commit-tree -p planning` → `update-ref refs/heads/planning`).
  `git worktree add` é o **fallback documentado** em `memory-export.sh` — nunca um
  arquivo temporário no working tree corrente.
- **Propagação:** o autosync empurra `planning` → `origin/planning` (NUNCA `main`).
  Próxima máquina importa via SessionStart.
- **Um arquivo por fato** ⇒ merges entre máquinas são **aditivos**, sem conflito de
  conteúdo. O `MEMORY.md` é regenerado por varredura do diretório (determinístico).

**Por que `planning` e não `main`:** a Lovable Cloud lê `main` continuamente;
qualquer commit de memória ali dispara um Lovable Update indevido. O `planning` é
ignorado pela Lovable, então é o transporte seguro. Topologia completa e as 6
barreiras anti-churn em [`docs/decisions/v5-memory-topology.md`](decisions/v5-memory-topology.md).

> **Invariante Lovable (inegociável):** nada nesta camada pode fazer memória chegar
> ao `main`. Guarda ativa: `scripts/check-memory-not-on-main.sh` (pre-commit /
> pre-merge-commit). O incidente real `.lovable_mem_tmp.md` em `nfideia:main`
> (commit `604c0a19`) é exatamente o que esta arquitetura previne.

---

## Camada 3 — Vault Obsidian (biblioteca curada cross-projeto)

O vault **"Ideia Business — Second Brain"** (iCloud) é a **síntese curada
cross-projeto** — o segundo cérebro. Pastas: `Learnings/`, `Decisions/`,
`References/`, `Stack Gotchas/`.

- **Promoção é um gate humano**, não automático: `extract-learnings` **Passo 4b**
  decide o que promover (só o que é **cross-projeto, estável e não-óbvio** — o
  vault é curadoria, não despejo). `/evolve` promove instincts maduros (≥0.7).
- **Acesso direto via filesystem** — sem MCP, sem Obsidian aberto; o Obsidian Sync
  propaga entre máquinas. Se o vault não existir no caminho, os passos são pulados
  silenciosamente.
- **Leitura:** `recall-learnings` **Passo 5** lê o vault com peso de "referência
  curada" (acima do learning bruto do repo).

---

## Isto NÃO cria um segundo cérebro paralelo

Esta é a regra que `PROJECT.md` proíbe e que este modelo respeita literalmente:

> **O vault Obsidian continua sendo a biblioteca. O `planning` é só o transporte.**

A camada 2 (`shared/planning`) **não é uma segunda biblioteca cross-projeto**:

- É **por-projeto** (cada repo tem seu próprio `planning:.planning/memory/`), não
  cross-projeto. O cross-projeto continua sendo **só** o vault Obsidian.
- É **transporte**, não curadoria: ela apenas faz a memória nativa de uma máquina
  chegar à memória nativa de outra. Não decide o que é importante — só sincroniza.
- A promoção ao vault permanece um **gate humano** em `extract-learnings` Passo 4b.
  A camada 2 **alimenta** esse fluxo (popula a memória nativa que o
  `extract-learnings` lê), nunca o substitui nem o duplica.
- **Nenhum diretório novo de "segundo cérebro"** é criado em lugar nenhum. Os
  paths usados já existiam ou são transporte interno: memória nativa do Claude
  Code (camada 1), branch `planning` (camada 2), vault Obsidian (camada 3).

Em uma frase: **camada 2 é o cabo entre as camadas 1 de máquinas diferentes; a
camada 3 (vault) continua sendo a única biblioteca cross-projeto, curada à mão.**

---

## Como as skills existentes se encaixam (sem mudança)

As skills de aprendizado **já apontam para a memória nativa e o vault** — o modelo
de 3 camadas se integra sem reescrevê-las:

| Skill | Onde lê/escreve | Papel no modelo |
|-------|------------------|-----------------|
| `recall-learnings` | lê `~/.claude/projects/<slug>/memory/MEMORY.md` (Passo 4) e o vault (Passo 5) | consome a **camada 1** (que o `memory-import.sh` acabou de popular da camada 2) e a **camada 3** |
| `extract-learnings` | escreve `~/.claude/projects/.../memory/learning_<slug>.md` (Passo 4); promove ao vault (Passo 4b) | cria fato na **camada 1** (que o `memory-export.sh` propaga à camada 2) e é o **gate humano** para a camada 3 |
| `/memory-sync` | aciona `memory-import.sh` / `memory-export.sh` | gatilho manual explícito entre **camada 1 ↔ camada 2** |
| `/evolve` | promove instincts maduros (≥0.7) ao vault/`source/rules/` | gate alternativo para a **camada 3** |

> O pipeline completo: `extract-learnings` cria fato na memória nativa →
> `memory-export.sh` / `/memory-sync export` propaga ao `planning` → próximo
> SessionStart em qualquer máquina importa via `memory-import.sh` →
> `recall-learnings` o lê → curadoria humana o promove ao vault (Passo 4b).

---

## Componentes (v5)

| Componente | Path | Camada |
|------------|------|--------|
| `memory-import.sh` (hook SessionStart) | `source/hooks/memory-import.sh` | 2 → 1 |
| `memory-export.sh` (hook Stop / skill) | `source/hooks/memory-export.sh` | 1 → 2 |
| `/memory-sync` (skill) | `source/skills/memory-sync/SKILL.md` | 1 ↔ 2 (gatilho manual) |
| `check-memory-not-on-main.sh` (guarda) | `scripts/check-memory-not-on-main.sh` | barreira: memória nunca no `main` |
| Cabeçalho anti-trap do índice shared | `source/templates/memory/MEMORY.header.md` | 2 |
| Schema canônico de fato | `source/templates/memory/fact.schema.md` | 1 e 2 (mesmo formato) |
| `.gitignore` do planning (ignora `memory/local/`) | `source/templates/memory/planning.gitignore` | 2 |

---

## Referências

- [`docs/decisions/v5-memory-topology.md`](decisions/v5-memory-topology.md) — ADR: topologia de branches + 6 barreiras anti-churn
- `.planning/research/ARCHITECTURE.md` — contrato de paths, padrões git, anti-patterns
- `.planning/research/STACK.md` — git plumbing, slug bug #30828, formato `.mdc`
- `.planning/milestones/v5-ROADMAP.md` — Fases 18–22, critérios de sucesso
- `source/skills/memory-sync/SKILL.md` — gatilho manual `/memory-sync`
- `source/skills/extract-learnings/SKILL.md` — Passo 4b (gate de promoção ao vault)
- `source/skills/recall-learnings/SKILL.md` — Passo 4 (memória nativa) + Passo 5 (vault)
