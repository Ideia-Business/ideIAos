---
name: learning-design-suite-sha-pin-clone-destructive
description: update-design-suite.sh era destrutivo NÃO pelo clone-por-sha (esse funciona) e sim pelo `cp -R` puro copiando os symlinks data//scripts/ do upstream como DANGLING (o src/ apontado não é vendorizado) → dataset some. CORRIGIDO 2026-06-20 (cp -RL + salvaguarda). Pin real = b7e3af80 (verificado por diff -rq, que resolve symlinks)
metadata:
  node_type: memory
  type: feedback
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

O `idea-doctor` (§5) dá WARN quando `design-suite-commit` no `versions.lock` é `local-seed-*`
em vez de hash hex, e sugere `bash scripts/update-design-suite.sh` para "alinhar". Rodar o script
ANTES da correção era **destrutivo** — `38 files, 4 ins, 9374 del` (sumiam `data/stacks/*.csv`,
`scripts/*.py`).

**CAUSA REAL (não óbvia):** NÃO era o clone-por-sha. O upstream
`nextlevelbuilder/ui-ux-pro-max-skill` publica `.claude/skills/<s>/data` e `scripts` como
**symlinks** p/ `../../../src/<s>/...`. O script fazia `cp -R` (BSD/macOS NÃO desreferencia
symlinks por default) → copiava os symlinks VERBATIM; como o `src/` não é vendorizado, viravam
**dangling** → o git lia o dataset inteiro como apagado. Fix: **`cp -RL`** (desreferencia) +
salvaguarda que aborta+restaura se a deleção líquida passar de um limiar.

**META-LIÇÃO (a parte importante):** minha 1ª diagnose culpou o clone-por-sha e eu cheguei a
COMMITAR um pin com base num content-match em que o `git checkout b7e3af80` do forensic **não
tinha surtido efeito** (eu diferi sem querer contra o HEAD). Só **reproduzir o comportamento
EXATO do script** (clone + checkout + ver o que `cp` produz) revelou os symlinks e a causa real.
`diff -rq` dava "match" porque **resolve symlinks**; `find -name '*.csv'` dava 0 porque **não os
segue** — os dois discordando era o sinal. Pin `b7e3af80` no fim ESTAVA certo (o conteúdo casa via
resolução de symlink), mas por sorte, não por boa verificação.

**Como aplicar:**
- Ao "fixar" um script de vendorização/cópia, **reproduza o passo exato** (clone→checkout→cp) e
  inspecione o ARTEFATO antes de concluir a causa. `cp -R` vs `cp -RL` muda tudo quando o upstream
  usa symlinks.
- `diff -rq` (segue symlinks) e `find` (não segue) discordando = pista de symlink. Cheque
  `ls -ld <dir>` p/ ver se é dir real ou link.
- update-design-suite.sh agora é **SEGURO** de rodar (2026-06-20): `cp -RL` + clone direto p/
  ref-sha + salvaguarda. O doctor lê `design-suite-commit` do **`versions.lock`** (editar é
  permitido; `check-versions-lock.sh` só protege `gsd=`).
- Família "verifique, não suponha" / "reproduza antes de consertar":
  [[learning-global-skill-deploy-version-gated-misses-lib-changes]],
  [[learning-ambiguous-drift-warning-induces-agent-revert]],
  [[learning-verify-guards-in-sandbox-not-live-repo]].
