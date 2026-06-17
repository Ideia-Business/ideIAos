---
name: autosync-pushes-feature-branches
description: "git-autosync do IdeiaOS PROTEGE main (só pull, nunca auto-push) mas AUTO-PUSHA qualquer branch não-main — então 'local-only' num repo sob autosync exige estar em main, não numa branch"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**O quê:** `~/.local/bin/git-autosync --all` (LaunchAgent `com.ideiaos.gitautosync`, 900s) lê `~/.local/state/git-autosync-repos.txt`. Regra do script: **main/master = só pull, nunca escreve** (suja → pula; à frente → notifica "push MANUAL", não pusha). **work/feature = auto-commit (`git add -A`) + pull --rebase + push** a cada tick, agindo só na **branch atual** (`git branch --show-current`).

**O erro (2026-06-16):** ao deployar rules v8 nos projetos, commitei em branches `chore/ideiaos-v8-rules` e deixei os repos NELAS, achando que "branch = mais seguro que main, fica local". Errado: o autosync **pushou** as branches chore de cfoai e ideiapartner sem aprovação, e o `git add -A` **varreu WIP não-relacionado** (AGENTS.md, package-lock.json) pra dentro dos commits wip. Inverteu a intenção: a `main` é que era o lugar seguro (push-protegido).

**How to apply:**
- Num repo sob autosync, "local até eu mandar" = **deixar em main** (push-protegida), não numa feature branch.
- Para parar a churn de uma feature branch sob autosync, **basta voltar o repo pra main** (o autosync só age na branch atual) — não precisa deletar a branch.
- Antes de mergear/deletar uma branch que ficou sob autosync, **inspecione** `git diff --name-only main..branch | grep -v <esperado>`: o `git add -A` do autosync pode ter varrido arquivos seus. Deletar cego = perda de dados; mergear cego = poluir main.
- Lovable: deploy é por `main`. Push de feature branch NÃO dispara deploy — mas ainda assim respeite "local". Pareia com [[feedback_lovable_projects_branch_commit]] e [[declarative-manifest-vs-imperative-list-drift]].
