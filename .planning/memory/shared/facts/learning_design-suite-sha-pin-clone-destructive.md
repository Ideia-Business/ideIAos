---
name: learning-design-suite-sha-pin-clone-destructive
description: update-design-suite.sh não shallow-clona ref-SHA (--branch <sha> falha) e na prática re-vendoriza o HEAD do upstream — apaga o dataset se o HEAD for mais pobre; NUNCA rode p/ "alinhar" o WARN do seed; verifique proveniência por content-match e grave o hash real em versions.lock
metadata:
  node_type: memory
  type: feedback
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

O `idea-doctor` (§5) dá WARN quando `design-suite-commit` no `versions.lock` é `local-seed-*`
em vez de hash hex, e sugere `bash scripts/update-design-suite.sh` para "alinhar ao ref pinado".

**A pegadinha:** rodar o script é **destrutivo**. Ele faz `git clone --depth 1 --branch "$REF"`
com `REF` = um SHA de 40 chars; `--branch <sha>` **falha** (branch não existe) e cai no clone
full, mas na prática a suíte re-vendorizada veio **mais pobre** que o seed — `38 files, 4 ins,
9374 del` (apagou todos os `data/stacks/*.csv`, `styles.csv`, `scripts/*.py`). O seed local de
2026-06-02 é **mais rico** que o conteúdo que o script trouxe.

**Proveniência REAL (verificada por content-match 2026-06-20):** o seed deriva de **`b7e3af80`**
(que foi HEAD do upstream `nextlevelbuilder/ui-ux-pro-max-skill` de 2026-04-03 até 2026-06-02 —
os próximos commits só em 06-21). `diff -rq` por skill: **5/7 idênticas** a b7e3af80;
`design-system` e `banner-design` diferem só pelos **overlays IdeiaOS** (OKLCH/`--brand-hue` +
`references/oklch-tokens.md`; nota de deps externas claudekit-origin).

**Por quê:** o "pin" de 06-19 anotou `ref=b7e3af80` mas deixou `commit=local-seed-*` ("hash
desconhecido"). O hash NÃO era desconhecido — bastava content-match contra a história do upstream.

**Como aplicar:**
- **NÃO** rode `update-design-suite.sh` para limpar o WARN do seed — é destrutivo p/ ref-SHA.
- O doctor lê `design-suite-commit` do **`versions.lock`** (não do `.design-suite-version`).
  Para limpar o WARN honestamente: verifique a proveniência por `diff -rq` contra a história do
  upstream e grave o **hash real** em `versions.lock` (editar `design-suite-commit` é permitido —
  a guarda `check-versions-lock.sh` só protege a linha `gsd=`). Já feito: `commit=b7e3af80…`.
- Defeito latente do script: ao receber um ref-SHA, deveria pular o `--branch` e ir direto a
  full-clone + `checkout <sha>`. Mesma família de "dica de remediação do doctor que engana":
  [[learning-global-skill-deploy-version-gated-misses-lib-changes]] e
  [[learning-ambiguous-drift-warning-induces-agent-revert]].
