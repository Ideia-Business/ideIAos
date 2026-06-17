---
date: 2026-06-17
session_type: infra
incident: n/a
commit: cf009c3
tags: [git, plumbing, cross-branch-sync, commit-tree, temp-index]
applies_to_projects: [global]
promote_to_vault: true
---

# Sync parcial cross-branch sem clobber: overlay via índice temporário + commit-tree

> O padrão é a técnica git, não o caso do `planning`. Aplica-se a qualquer "atualizar
> um subconjunto de arquivos numa branch que tem arquivos exclusivos a preservar".

## Trigger (quando reler isso)

Quando você precisa propagar um **subconjunto** de arquivos de uma branch para outra
que **tem arquivos próprios que a origem não tem** (e não pode perder), **sem** checkout,
sem merge e sem sujar o working tree. Ex.: sincronizar docs de planejamento para uma
branch que também carrega um store de memória exclusivo.

## O padrão (abstrato)

Um `merge`/`checkout` ingênuo é destrutivo nos dois sentidos: traz o conteúdo exclusivo
da branch-alvo para a origem (poluição) ou apaga-o ao sobrescrever (perda). A operação
correta é um **overlay cirúrgico** construído com git plumbing:

1. **Base = árvore da branch-alvo** (preserva tudo que é exclusivo dela).
2. **Overlay = só os arquivos desejados, com os blobs da branch-origem.**
3. Commit sintético com a árvore resultante, pai = tip da branch-alvo, via `commit-tree`
   + `update-ref` — **sem** checkout, **sem** working tree, **sem** disparar hooks.

A footgun central: a **lista de arquivos a sobrepor tem de vir do índice da ORIGEM**,
computada **antes** de carregar o índice temporário. Se você rodar `git ls-files` depois
de `GIT_INDEX_FILE=tmp git read-tree alvo`, o `ls-files` lê o índice TEMPORÁRIO (= árvore
do alvo) e a lista vem errada — faltam exatamente os arquivos que existem só na origem
(os que mais importam sincronizar).

## Evidência (concreta — desta sessão)

- Sync de `.planning/*` (exceto `.planning/memory/`) de `work` → `planning`, preservando
  o memory store (27→28 fatos) exclusivo do `planning`. Commits `cf009c3`, `7e20483`, `f11a8bb`.
- Receita validada:
  ```bash
  FILES="$(git ls-files .planning/ | grep -v '^\.planning/memory/')"   # ANTES do índice temp
  TMPIDX="$(mktemp)"; export GIT_INDEX_FILE="$TMPIDX"
  git read-tree planning                                                # base = árvore-alvo
  while IFS= read -r f; do
    blob="$(git rev-parse --verify --quiet "work:$f")" || continue
    git update-index --add --cacheinfo "100644,$blob,$f"
  done <<< "$FILES"
  TREE="$(git write-tree)"; unset GIT_INDEX_FILE; rm -f "$TMPIDX"
  COMMIT="$(git commit-tree "$TREE" -p planning -m 'sync ...')"
  git update-ref refs/heads/planning "$COMMIT"
  ```
- Bug pego e corrigido na 1ª tentativa: `ls-files` rodou sob `GIT_INDEX_FILE` setado →
  listou os arquivos do `planning`, omitindo os 7 docs novos do `work`; resultado tinha
  `update-index` falhando em `100644,,path` (blob vazio). Reset do ref + recompute da lista
  antes do índice temp resolveu.

## Regra prática derivada

1. **Compute a lista de arquivos da branch-ORIGEM antes** de tocar `GIT_INDEX_FILE`.
2. Resolva blobs com `git rev-parse --verify --quiet "<origem>:<path>"`; pule string vazia
   (arquivo inexistente na origem) — nunca passe blob vazio para `--cacheinfo`.
3. Base sempre = árvore da branch-ALVO (`read-tree alvo`), nunca a da origem, quando o objetivo
   é preservar o exclusivo do alvo.
4. **Verifique por diff:** `git diff <alvo> <origem> -- <subárvore>` deve sobrar SÓ os arquivos
   exclusivos do alvo. Qualquer doc compartilhado divergente = sync incompleto.
5. `commit-tree` não dispara hooks nem toca o working tree — ideal para sync automatizado,
   mas isso também significa que **gates de pre-commit não te protegem**: a verificação por diff é obrigatória.

## Falsos positivos / armadilhas

- Overlay **só adiciona/atualiza**; não DELETA arquivos stale que existem só no alvo. Para
  espelho completo (com deleção), a base tem de ser a árvore da origem + re-overlay do exclusivo.
- `update-ref` direto pula a checagem de fast-forward; garanta que o pai (`-p`) é o tip ATUAL
  do alvo (re-leia o ref imediatamente antes), senão um autosync concorrente vira non-FF no push.

## Cross-references

- `[[learning-missing-tool-not-cant-verify]]` — mesma sessão (verificar com o parser certo).
- Memória: `learning_autosync-pushes-feature-branches.md` — por que o tip do `planning` avança sozinho (hook de memória).
- Memória global: `learning_git-plumbing-partial-branch-overlay-sync.md`.

## Promoção (preenchido depois)

- [x] Promovido para memória global (`~/.claude/projects/.../memory/`) em 2026-06-17 — motivo: técnica git stack-agnóstica.
- [x] Promovido para Obsidian vault em 2026-06-17.
