# ADR — Topologia de memória v5 (Lovable-safe)

**Data:** 2026-06-14
**Milestone:** v5 — Memória compartilhada entre IDEs (Fases 18–22)
**Requisitos:** R5-01, R5-02, R5-03
**Status:** Aceito

---

## Contexto

IdeiaOS v5 adiciona sincronização de memória entre IDEs (Claude Code, Cursor) e
entre máquinas. A memória precisa de um transporte versionado e multi-máquina,
mas existe uma restrição **inegociável**:

> A Lovable Cloud lê o branch `main` continuamente. Qualquer commit em `main` —
> inclusive arquivos de memória — dispara um **Lovable Update indevido**.

Isso não é teórico: o arquivo `.lovable_mem_tmp.md` vazou para `nfideia:main`
(commit `604c0a19`) porque um staging de memória foi escrito na working tree do
branch corrente e o `git-autosync` o commitou. Esse incidente é a razão de R5-01
ser o primeiro item do milestone.

---

## Decisão

### 1. Memória vive APENAS no branch `planning`

O store canônico de memória é `planning:.planning/memory/`:

```
.planning/memory/
├── shared/   ← committed no planning; store multi-máquina canônico
│   ├── MEMORY.md
│   └── facts/<type>_<slug>.md
└── local/    ← gitignored no planning; staging por máquina
    └── staging/
```

Leitura sem checkout: `git show planning:.planning/memory/shared/MEMORY.md` /
`git archive planning .planning/memory/shared/`. Escrita sem checkout: git
plumbing (`hash-object` → `commit-tree` → `update-ref`) ou `git worktree`
(fallback documentado). A working tree do branch corrente nunca recebe um
arquivo de memória — esse é exatamente o bug `.lovable_mem_tmp.md` que estamos
corrigindo.

### 2. Topologia de branches

```
            /lovable-handoff (gate único e deliberado)
   work / feature  ───────────────────────────────────►  main  ──► Lovable Cloud
        │                                                  ▲ (read-only p/ memória)
        │ memory-export / /memory-sync (git plumbing)      │
        ▼                                                  ✗ BLOQUEADO
     planning  ──────────────────────────────────────────/
   (store de memória; autosync empurra para origin/planning)
```

- **`main` recebe apenas de `work`/feature**, e somente via `/lovable-handoff`.
- **`planning` NUNCA faz merge para `main`.** O `planning` carrega a memória por
  design; deixá-lo aterrissar no `main` reintroduziria o leak.
- **`main` é read-only para memória.** Nenhum caminho automático (autosync,
  export, worktree) escreve memória no `main`.

### 3. As 6 barreiras anti-churn (espelham o precedente do `versions.lock`)

| # | Barreira | Onde | O que faz |
|---|----------|------|-----------|
| 1 | **Guard de pre-commit** | `scripts/check-memory-not-on-main.sh` (`--staged`), via `.git/hooks/pre-commit` | Bloqueia memória staged quando o branch é `main` — mensagem direcional (diz que o branch está errado, não os arquivos) |
| 2 | **Guard de pre-merge-commit** | mesmo script (`--merge`), via `.git/hooks/pre-merge-commit` | Bloqueia merge `planning`→`main` (e memória entrando no main por merge) |
| 3 | **Exclusão no autosync** | `setup-dev-machine.sh` (git-autosync) | `git add -A` exclui `.planning/memory/local` e `.cursor/rules/memory-bridge.mdc` (e, em main, todo `.planning/memory` + `.lovable_mem_tmp.md`) |
| 4 | **Branch-guard do autosync** | `setup-dev-machine.sh` (git-autosync) | `main`/`master` nunca escrevem (só puxam); exclusões extras de memória reforçam isso |
| 5 | **`.gitignore`** | `.gitignore` (raiz) | Ignora `.cursor/rules/memory-bridge.mdc`, `.planning/memory/local/` e `.lovable_mem_tmp.md`; preserva `.planning/memory/shared` |
| 6 | **Override consciente** | `IDEIAOS_MEM_OVERRIDE=1` | Bypass explícito e auditável (espelha `IDEIAOS_LOCK_OVERRIDE`) — força a intenção, não acidente |

Mensagens **direcionais** são deliberadas: um aviso ambíguo de drift já induziu
agente de IA a reverter o pin do `versions.lock` 3×. Cada barreira diz qual lado
está errado e como corrigir.

### 4. Lovable lê `main` — racional do read-only

A Lovable Cloud faz polling/deploy a partir do `main`. O contrato do IdeiaOS é
que o `main` só muda por ato deliberado humano (`/lovable-handoff`). Memória é
churn de alta frequência (cada sessão pode gerar fatos) — se ela tocasse o
`main`, cada sessão viraria um deploy. Por isso a memória é confinada ao
`planning`, que a Lovable ignora, e o `main` permanece read-only para memória.

---

## Consequências

- **Positivo:** o `main` fica imune a churn de memória; deploys Lovable só
  acontecem por handoff deliberado; o store é multi-máquina via `origin/planning`.
- **Positivo:** as barreiras são ativas (hooks + guard), não passivas (doc) —
  uma tentativa errada falha com mensagem que ensina a corrigir.
- **Custo:** escrita de memória exige git plumbing (sem checkout do planning),
  mais complexo que escrever na working tree — mas é exatamente o que evita o leak.
- **Override existe** para casos legítimos raros (`IDEIAOS_MEM_OVERRIDE=1`), com
  trilha de auditoria, em vez de desabilitar a guarda.

---

## Referências

- `.planning/research/ARCHITECTURE.md` — contrato de paths, padrões git, anti-patterns
- `.planning/research/STACK.md` — git plumbing, slug bug #30828, formato `.mdc`
- `.planning/milestones/v5-ROADMAP.md` — Fase 18, critérios de sucesso
- `scripts/check-versions-lock.sh` — precedente das 6 barreiras (pin GSD)
- Incidente: `nfideia:main` commit `604c0a19` (`.lovable_mem_tmp.md` vazado)
