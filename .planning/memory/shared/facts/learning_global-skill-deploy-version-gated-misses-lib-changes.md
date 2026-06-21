---
name: learning-global-skill-deploy-version-gated-misses-lib-changes
description: setup.sh --global-only só copia uma skill se a VERSÃO do SKILL.md mudou — adições só em lib/ (sem bump) nunca chegam ao global; a dica do idea-doctor "rode setup.sh --global-only" NÃO resolve esse drift de /spec
metadata:
  node_type: memory
  type: feedback
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

O check de drift do `idea-doctor` (`diff -rq source/skills/<s>/ ~/.claude/skills/<s>/`)
acusou `drift em /spec (global ≠ repo)`. A causa: o global estava **sem 3 libs do v11**
(`spec-analyze.sh`, `spec-converge.sh`, `spec-grammar.sh` em `source/skills/spec/lib/`).

**A pegadinha:** rodar `bash setup.sh --global-only` (a remediação que o próprio doctor
sugere) **não conserta** — o deploy de skills é **version-gated**: ele compara a versão do
`SKILL.md` e, se igual, imprime "já está na versão mais recente" e **pula a cópia inteira**.
Como as 3 libs foram adicionadas SEM bump de versão no `SKILL.md` do `/spec`, o global
nunca as recebeu, e re-rodar o setup continua pulando.

**Por quê:** o gate de versão otimiza velocidade (não re-copiar skill inalterada), mas usa
a versão do SKILL.md como proxy de "conteúdo mudou" — proxy que falha para mudanças
**só-em-subdiretório** (lib/, references/, data/).

**✅ CORRIGIDO (2026-06-20, commit 4c878b5):** o bloco do manifesto (`installStrategy: always`)
em `setup.sh` agora é **content-aware** — usa `diff -rq` (mesma semântica do idea-doctor) e
re-espelha o diretório INTEIRO (rmtree + copytree) quando difere, em vez de comparar/copiar só
o `SKILL.md`. Testado: dummy em `lib/` propaga ao global e some no mirror; doctor 0 WARN. Logo
este drift não recorre mais por essa via.

**Como aplicar (se reaparecer por outra via):**
- Drift NA HORA: espelhe o diretório — `cp -Rp source/skills/<s>/. ~/.claude/skills/<s>/` e confirme com `diff -rq` (exit 0 = idêntico).
- Lição geral: um gate que usa "versão do manifesto/SKILL.md" como proxy de "conteúdo mudou" sempre falha para mudanças só-em-subdiretório — prefira comparação de conteúdo (`diff -rq`).
- Família de "dica de remediação do doctor que engana": [[learning-design-suite-sha-pin-clone-destructive]] (essa do `update-design-suite.sh` AINDA em aberto — só mitigada pelo pin honesto).
