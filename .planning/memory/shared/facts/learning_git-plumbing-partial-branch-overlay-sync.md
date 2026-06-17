---
name: learning-git-plumbing-partial-branch-overlay-sync
description: "Para sincronizar um SUBCONJUNTO de arquivos a uma branch que tem conteúdo exclusivo a preservar, faça overlay via git plumbing (base=árvore-alvo, blobs da origem, commit-tree+update-ref) — e compute a lista da ORIGEM antes do índice temp"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Sincronizar um subconjunto de arquivos para uma branch que tem arquivos exclusivos
(que a origem não tem e não pode perder) NÃO se faz com merge/checkout — é destrutivo
nos dois sentidos. Faça **overlay cirúrgico com git plumbing**:

1. `FILES` da branch-ORIGEM **antes** de setar `GIT_INDEX_FILE` (senão `git ls-files` lê o
   índice temporário = árvore-alvo, e a lista vem errada — faltam os arquivos só-da-origem).
2. `GIT_INDEX_FILE=tmp git read-tree <alvo>` → base preserva o exclusivo do alvo.
3. Para cada arquivo: `blob=$(git rev-parse --verify --quiet "<origem>:<path>")`; pular vazio;
   `git update-index --add --cacheinfo "100644,$blob,$path"`.
4. `write-tree` → `commit-tree -p <alvo>` → `update-ref refs/heads/<alvo>`. Sem checkout, sem
   working tree, sem hooks.
5. **Verificar por diff:** `git diff <alvo> <origem> -- <subárvore>` deve sobrar SÓ o exclusivo do alvo.

**Why:** foi como sincronizei `.planning/*` (exceto `memory/`) de `work`→`planning` preservando o
memory store cross-IDE. A 1ª tentativa rodou `ls-files` sob `GIT_INDEX_FILE` já setado → omitiu os
docs novos → `--cacheinfo` com blob vazio. Reset + recompute antes resolveu.

**How to apply:** overlay só ADICIONA/ATUALIZA (não deleta stale do alvo). `commit-tree` pula hooks
E checagem de FF — releia o tip do alvo imediatamente antes do `-p` (autosync concorrente vira non-FF
no push). Cross-link: [[autosync-pushes-feature-branches]] (tip do planning avança sozinho via hook de
memória), [[learning-missing-tool-not-cant-verify]] (mesma sessão).
