# R15-10 — Governança no CI · SUMMARY

**Status:** ✅ DONE (code-complete) 2026-06-26 · **Wave:** 1 · **Executor:** sessão principal

## O que foi feito

Criado `.github/workflows/governance.yml` — workflow que roda os **2 gates repo-puros de governança
que faltavam ao CI**: `check-readme-sync` e `check-memory-not-on-main`. Repo PÚBLICO → Actions sem
billing.

## Escopo correto (descoberto na investigação)

O requisito parecia "criar workflow com os 4 gates", mas a inspeção do `evals.yml` mostrou que ele
**já cobre 2 deles** (`check-plugin-membership` linha 143, `check-source-headers` linha 147) e **já
NÃO roda** idea-doctor nem check-env-not-tracked (excluídos por design — auditam `$HOME`). Logo:

- O "REMOVER idea-doctor/check-env do CI" **já estava satisfeito** — nada a remover.
- O delta real era **adicionar os 2 faltantes**, sem duplicar (requisito: "não re-rodar o que evals
  já cobre"). Por isso um workflow SEPARADO com só os 2, e não um que repetisse os 4.

## Decisões de design

- **Checkout com branch nomeado** (`ref: ${{ github.head_ref || github.ref_name }}`): o
  `check-memory-not-on-main` usa `git symbolic-ref --short HEAD` — em detached HEAD (default) pularia
  a inspeção. Com o ref nomeado, um push p/ `main` é inspecionado de verdade.
- **Triggers `push: [main]` + `pull_request`** — NÃO em push de `work`, para não gerar um run a cada
  tick do git-autosync. O gate de memória só importa quando o destino é `main`; o readme-sync roda em
  PR (antes do merge) e em push p/ main.

## Verificação (exit-code)

| Gate | Resultado |
|------|-----------|
| YAML válido (ruby `-E UTF-8` local; PyYAML no runner como o evals.yml) | ✅ |
| comandos referenciados existem | ✅ |
| `check-readme-sync` verde com o novo workflow | ✅ |
| **anti-teatro:** `.planning/` trackado + `.planning/memory/leak.md` novo → gate exit **1** (barrou); sem memória → exit **0** | ✅ |

**Aprendizado do teste:** a 1ª tentativa de sandbox criou TODO o `.planning/` untracked → `git status
--porcelain` compactou para `?? .planning/` (dir), que o gate corretamente não classifica como memória.
Com `.planning/` TRACKADO (como no repo real), o `.planning/memory/` novo aparece e o gate barra. O
teste tem de espelhar o estado real do repo, não um sandbox vazio.

## Pendente

"CI verde em PR" (DoD) confirma-se no Actions após o próximo push p/ `main` (dispara o workflow).
Verificável via `gh run list --workflow=governance.yml`.

## Arquivos

- `.github/workflows/governance.yml` (novo).
- `.planning/milestones/v15-phases/B-governanca/R15-10-ci-gates-{PLAN,SUMMARY}.md`.
