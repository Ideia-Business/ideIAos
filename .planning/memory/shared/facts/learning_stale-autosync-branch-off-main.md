---
name: learning-stale-autosync-branch-off-main
description: "Para um fix cirúrgico que vira PR→main em repo Lovable sob autosync, ramifique de main HEAD (não da branch work corrente, que driftou stale 57/212 commits atrás) — senão o PR arrasta o delta velho"
metadata:
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Ao criar uma branch para um fix **CIRÚRGICO** (ex.: 1 arquivo `settings.json` de segurança) em repo Lovable sob git-autosync, **NÃO ramifique da branch `work` corrente** — ela pode ter DRIFTADO muito atrás da `main` (caso real v15 2026-06-25: cfoai/nfideia com `work` **57/212 commits atrás** de main). Ramificar de `work` carregaria esse delta stale inteiro para dentro do PR, poluindo o diff e arriscando reintroduzir/reverter coisas em main.

**Why:** o autosync auto-commita (`git add -A`) e auto-pusha a branch atual a cada tick, então `work` em produto Lovable acumula WIP e fica defasada de main (que é push-protegida, só-pull). Um PR limpo precisa que a base seja **main HEAD**, não a conveniência da branch atual.

**How to apply:** para um fix cirúrgico que vai virar PR→main, faça `git fetch origin && git switch -c sec/<slug> origin/main` (branch NOVA a partir de main HEAD), commite SÓ o arquivo-alvo (`git add <path>` específico, NUNCA `-A`), e push via @devops (`AIOX_ACTIVE_AGENT=devops`). Antes de abrir o PR, confirme `git diff --stat main..sec/<slug>` mostra APENAS o arquivo pretendido. Pareia com [[autosync-pushes-feature-branches]] (autosync pusha branch não-main), [[feedback-lovable-projects-branch-commit]] (branch nunca main em Lovable) e [[learning-gate-audits-current-branch-not-other-branch]] (o gate só vê a branch em checkout).
