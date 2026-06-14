---
name: learning-version-reset-migration-semver-trap
description: Migração de pacote com reset de versionamento inverte semver (1.1.0 redux > 1.36.0 pré-redux) — guardas de pin devem ser package-aware
metadata: 
  node_type: memory
  type: project
  originSessionId: d8431dac-280c-4f04-b727-c463ba247aa7
---

No IdeiaOS, o GSD migrou de `get-shit-done-cc` (1.36–1.42) para `@opengsd/get-shit-done-redux` (versionamento recomeçou em 1.x): **`gsd=1.1.0` é o valor CORRETO e mais novo; 1.3x/1.4x é legado errado**. O pin em `versions.lock` foi revertido 3× por comparação ingênua (autosync com árvore stale + agente "corrigindo" drift).

**Why:** versionamento resetado quebra a ordenação semver entre linhagens — o menor é o mais novo, e qualquer heurística "maior = atual" corrige para trás.

**How to apply:** nunca editar `gsd=` na mão — único escritor é `scripts/update-upstream.sh --bump`; o pre-commit roda `scripts/check-versions-lock.sh` (bloqueia 1.30–1.99 e edição ≠ instalado; bypass `IDEIAOS_LOCK_OVERRIDE=1`). Se o doctor acusar drift, ler a mensagem direcional — ela diz qual lado está errado. Ver [[learning-ambiguous-drift-warning-induces-agent-revert]].
