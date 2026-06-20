---
name: memory-sync
description: Gatilho manual da memória compartilhada entre IDEs/máquinas do IdeiaOS. `/memory-sync export` força a exportação da memória nativa da IDE para o store canônico no branch `planning` (via git plumbing, sem resíduo no working tree, NUNCA tocando `main`); `/memory-sync import` força a importação dos fatos `shared/` do `planning` para a memória nativa. `/memory-sync status` é diferido (v5.x). Use quando quiser sincronizar memória sem esperar os hooks de SessionStart/Stop, ou ao fechar uma sessão com aprendizado novo.
---

# SOURCE: IdeiaOS v5

# Skill: memory-sync

Você é responsável pelo **gatilho manual explícito** da memória compartilhada do IdeiaOS — a camada que sincroniza a memória nativa de cada IDE (Claude Code, Cursor) com um store canônico que vive no branch `planning`, atravessando máquinas via git, **sem nunca tocar o `main`**.

O `export` é **skill-driven, não um hook automático por turno**. Claude Code não tem evento "SessionEnd"; o `Stop` dispara após cada resposta — exportar a cada turno seria ruidoso e lento. Por isso a escrita no store é deliberada: você (ou o usuário) invoca `/memory-sync export` quando há aprendizado a propagar. O `import` é automático no SessionStart via hook, mas esta skill também permite forçá-lo fora de hora.

**Idioma:** Português brasileiro.

---

## Modelo Lovable-safe (leia antes de qualquer coisa)

A invariante inegociável: **nenhum churn de memória pode tocar o `main`**. O `main` é lido continuamente pela Lovable Cloud; qualquer commit de memória ali dispara um Lovable Update indevido. O arquivo `.lovable_mem_tmp.md` que vazou em `nfideia:main` é a prova real desse risco — esta skill existe para que ele nunca se repita.

Como a segurança é garantida:

1. **A memória vive SÓ no branch `planning`**, dentro de `.planning/memory/`. O working tree do `main` e de qualquer feature branch nunca é tocado.
2. **Leitura** é via `git show planning:...` / `git archive planning ...` — sem checkout, sem poluir o working tree.
3. **Escrita** é via git plumbing (`hash-object` → `commit-tree` → `update-ref`), que opera apenas na camada de objetos/refs — sem diretório de trabalho, sem resíduo. `git worktree add` é o **fallback documentado**, nunca um arquivo temporário no working tree corrente.
4. **NUNCA** escrever um arquivo de staging no working tree da branch atual. O staging vive em `planning:.planning/memory/local/staging/`, que é gitignored no próprio `planning`. Escrever `.lovable_mem_tmp.md` (ou similar) na árvore corrente é o bug anti-padrão que esta camada corrige.
5. O `update-ref` aponta **exclusivamente** para `refs/heads/planning`. Antes de escrever, assegure-se de que o alvo é `planning` — nunca `main`.

---

## Topologia (3 camadas)

```
camada 1: memória nativa da IDE  (machine-local, gitignored)
          ~/.claude/projects/<slug>/memory/   (Claude Code)
          .cursor/rules/memory-bridge.mdc      (Cursor, gerado no import, gitignored)
                 ▲ import (SessionStart hook / `/memory-sync import`)
                 │ export (`/memory-sync export`)
                 ▼
camada 2: store canônico compartilhado  (committed no branch `planning`)
          planning:.planning/memory/shared/MEMORY.md  + facts/
          planning:.planning/memory/local/staging/    (gitignored no planning)
                 │ autosync empurra `planning` → origin (NÃO `main`)
                 ▼
camada 3: vault Obsidian  (síntese curada cross-projeto, iCloud)
          promovido manualmente via /extract-learnings (Passo 4b) — gate humano
```

Esta skill opera entre as **camadas 1 e 2**. A promoção para a camada 3 (Obsidian) é um gate humano separado em `/extract-learnings`; `memory-sync` alimenta esse fluxo, não o substitui.

---

## Comandos

### `/memory-sync export` — força a exportação (camada 1 → camada 2)

Roda a lógica do bridge de export fora dos hooks. Equivale a invocar manualmente:

```bash
bash ~/.claude/hooks/memory-export.sh
```

Comportamento (definido em `memory-export.sh`):

1. Deriva o `<slug>` do cwd, do mesmo jeito que `observe-session-end.sh` (path do repo root → `/` vira `-`). Trata o bug #30828: checa a variante com underscore e com hífen, usa a que tem `MEMORY.md`.
2. Lê os fatos da memória nativa: `~/.claude/projects/<slug>/memory/*.md`.
3. Para cada fato, faz diff contra `git show planning:.planning/memory/shared/facts/<arquivo>` (ou detecta ausência).
4. Para cada fato novo/alterado: escreve em `planning:.planning/memory/local/staging/` (buffer no `planning`, não na árvore corrente) e o promove a `shared/facts/`.
5. Commita via git plumbing: `hash-object -w` → índice temporário (`GIT_INDEX_FILE`, nunca o índice real) → `write-tree` → `commit-tree -p planning` → `update-ref refs/heads/planning`. (`git worktree add` é o fallback documentado no script.)
6. Regenera `shared/MEMORY.md` deterministicamente a partir do diretório (idempotente).
7. Se **nenhum fato mudou**, termina silenciosamente — sem commit vazio, sem erro.
8. **Não faz push.** O autosync empurra `planning` → origin no próximo ciclo. Nunca empurra `main`.

Quando usar: ao fechar uma sessão com aprendizado novo, ou logo após `/extract-learnings` ter criado um `learning_*.md` na memória nativa.

### `/memory-sync import` — força a importação (camada 2 → camada 1)

Roda a lógica do bridge de import fora dos hooks. Equivale a:

```bash
bash ~/.claude/hooks/memory-import.sh
```

Comportamento (definido em `memory-import.sh`):

1. Lê `git show planning:.planning/memory/shared/MEMORY.md` (offline-safe: `exit 0` se falhar).
2. Extrai os fatos via `git archive planning .planning/memory/shared/ | tar -x -C <tmp>`.
3. Copia fatos novos/atualizados para `~/.claude/projects/<slug>/memory/` (preserva fatos local-only que não estão no `shared/`).
4. Regenera o índice nativo `MEMORY.md` a partir dos fatos importados + local-only.
5. Gera `.cursor/rules/memory-bridge.mdc` (`alwaysApply: true`, gitignored) com o snapshot shared inline — a ponte Cursor.
6. Freshness guard: pula se o SHA do `planning` não mudou desde o último import (sem `git archive` redundante).
7. Resiliente: sem origin / sem branch `planning` / sem memória → `exit 0`, nunca bloqueia o SessionStart.

Quando usar: ao retomar trabalho de outra máquina, ou se suspeitar que o SessionStart não rodou o import (sessão resumida, drift de `planning`).

### `/memory-sync status` — **diferido (v5.x)**

Dashboard de shared vs local vs pending (fatos no `shared/` não importados, fatos nativos não exportados, último SHA sincronizado). **Não implementado no MVP** — está na dívida técnica do milestone v5 (F5-…). Se o usuário pedir, explique que é deferred e ofereça `import`/`export` no lugar.

---

## Hooks canônicos invocados

| Comando | Hook (source) | Hook (instalado) | Evento automático |
|---------|---------------|------------------|-------------------|
| `import` | `source/hooks/memory-import.sh` | `~/.claude/hooks/memory-import.sh` | SessionStart (após `git-sync-check.sh`) |
| `export` | `source/hooks/memory-export.sh` | `~/.claude/hooks/memory-export.sh` | Stop (registrado, mas escrita é skill-driven) |

Os hooks são instalados em `~/.claude/hooks/` pelos patches 12/13 (`install-global-patches.sh`) e registrados no `settings.json` via `ideiaos-update.sh` (step 3, lendo `plugins/ideiaos-core/hooks/hooks.json`). Não edite o `settings.json` à mão. Se um hook não existir no caminho instalado, avise o usuário para rodar a atualização do IdeiaOS — não tente recriá-lo aqui.

---

## O que NÃO fazer

- ❌ **Commitar ou empurrar memória para o `main`.** Jamais. O `update-ref`/`worktree` alvo é sempre `planning`.
- ❌ **Escrever staging no working tree da branch corrente** (o bug `.lovable_mem_tmp.md`). Staging vive em `planning:.planning/memory/local/staging/`.
- ❌ **Fazer checkout do `planning`** para ler/escrever — destrói trabalho não-commitado. Use `git show`/`git archive` (ler) e git plumbing (escrever).
- ❌ **Fazer push direto** no export — o autosync propaga `planning`. Esta skill não empurra.
- ❌ **Criar commit vazio** quando nada mudou. Export sem diff termina em silêncio.
- ❌ **Invocar um modelo (`claude -p`) no import/export.** O bridge é determinístico em bash/git; LLM-in-the-loop adiciona latência e dispara o anti-runaway guard.
- ❌ **Criar um segundo cérebro paralelo.** O store `shared/` é por-projeto; o cross-projeto continua sendo o vault Obsidian via `/extract-learnings`.

---

## Saída esperada

Após `export`:

```
🧠 memory-sync export: <N> fato(s) novo(s)/alterado(s) → planning:.planning/memory/shared/
   Commit local no branch planning; autosync empurra para origin. main intacto.
```

Ou, se nada mudou:

```
🧠 memory-sync export: nenhum fato alterado — nada a sincronizar.
```

Após `import`:

```
🧠 memory-sync import: <N> fato(s) shared importado(s) para a memória nativa (+ memory-bridge.mdc para o Cursor).
```

Ou, se offline / sem store:

```
🧠 memory-sync import: store compartilhado indisponível (sem origin / sem branch planning) — seguindo sem importar.
```

---

## Quando esta skill é invocada

- `/memory-sync export` (explícito) — ao fechar sessão com aprendizado, ou após `/extract-learnings` criar fato novo
- `/memory-sync import` (explícito) — ao retomar trabalho de outra máquina, ou se o SessionStart não importou
- Não há auto-invocação por turno (export é deliberado por design)

## Limitações

- Export é manual por design (Claude Code não tem evento de fim de sessão). O hook de Stop existe registrado, mas a escrita real é skill-driven.
- Cursor é consumidor passivo: recebe o `shared/` via `.mdc` regenerado no import; não exporta (Cursor não expõe hooks nem memória em filesystem).
- Não promove para o vault Obsidian — isso é o gate humano de `/extract-learnings` (Passo 4b).
- Não decide o que é cross-projeto; o `shared/` é por-repo.

## Memórias e componentes relacionados

- `source/hooks/memory-import.sh` — bridge SessionStart (planning → memória nativa)
- `source/hooks/memory-export.sh` — bridge Stop/skill (memória nativa → planning)
- `source/templates/memory/MEMORY.header.md` — cabeçalho anti-trap do índice `shared/`
- `source/templates/memory/fact.schema.md` — formato canônico de fato (espelha a memória nativa)
- Skill `extract-learnings` — gate de promoção ao vault (camada 3); `memory-sync` a alimenta
- Skill `recall-learnings` — lê `~/.claude/projects/<slug>/memory/` que o import popula
- `.planning/research/ARCHITECTURE.md` — contrato de design completo da camada de memória
