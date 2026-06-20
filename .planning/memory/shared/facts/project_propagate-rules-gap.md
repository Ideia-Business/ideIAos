---
name: propagate-rules-gap
description: "RESOLVIDO (2026-06-16, commit 66598c1): propagate-if-changed.sh ganhou source/rules/ em PROJECT_PATHS + setup.sh --project-only deploya .claude/rules via build-adapters. Prova viva: lapidai tem 8 rules ideiaos-common. Resíduo = housekeeping (re-rodar --project-only nos 3 produtos restantes)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Gap descoberto em 2026-06-16 ao auditar a auto-propagação do v8.

**O sintoma:** numa 2ª máquina que puxa o IdeiaOS, skills (`/doubt`, `/context-engineering`) **propagam** (v8 tocou `source/skills/` + `manifests/` → dispara `setup.sh --global-only` que inclui o sync de skills 5.21b). Mas a rule `operating-discipline` (e qualquer rule nova em `source/rules/common/`) **NÃO** chega aos projetos.

**Causa raiz (fix de 2 partes):**
1. `scripts/propagate-if-changed.sh` — `source/rules/` não está em `GLOBAL_PATHS` nem `PROJECT_PATHS`, e `scripts/build-adapters.sh` (que o R8-09 tornou a ferramenta de deploy de rule) também não. Logo mudança só-de-rule não dispara `apply-to-all-projects.sh`. **Fix:** adicionar `source/rules/` + `scripts/build-adapters.sh` a `PROJECT_PATHS`.
2. `apply-to-all-projects.sh` roda `setup.sh --project-only`, que (linha ~1475) **pula** instalação global e **não referencia** `build-adapters`/`build_claude_project_rules`. Então mesmo com o gatilho, a via de propagação provavelmente não deploya as `.claude/rules` do R8-09 (só Cursor, se tanto). **Fix:** fazer `setup.sh --project-only` (ou apply-to-all-projects) chamar `build-adapters.sh --target cursor --project-dir <repo>`, que já entrega Cursor + Claude common rules.

**Por quê importa:** é exatamente o padrão [[declarative-manifest-vs-imperative-list-drift]] — capability declarada (R8-09 deploya .claude rules) sem o gatilho/caminho que a entrega na propagação. O deploy manual desta sessão (`build-adapters --target cursor --project-dir` em cada repo) é workaround; a propagação automática ainda não cobre rules.

**Status:** ✅ CORRIGIDO (2026-06-16, commit 66598c1, landed em `work`). Fix de 2 partes +
blindagem: (1) `propagate-if-changed.sh` ganhou `source/rules/` + `scripts/build-adapters.sh`
em `PROJECT_PATHS`; (2) `setup.sh` (config de projeto, roda em `--project-only`) chama
`build-adapters.sh --target cursor --project-dir` fail-soft → entrega `.cursor/rules/ideiaos-*`
+ `.claude/rules/ideiaos-common-*`; (3) `build-adapters.sh` reordenado p/ `build_claude_project_rules`
antes de `build_cursor` (alvo load-bearing primeiro em deploy parcial). Verificado: bash -n +
sandbox (rule-only propaga, docs-only não) + end-to-end setup --project-only + revisão
adversarial 3-lentes (clean, só LOW). Cadeia completa fechada.

**Follow-up (2026-06-19 noite) — propagação v12 fechada nos 4 produtos, + 2 achados:** ao
propagar o delta de rules do v12 (nova `credential-isolation` + edits) medi que ele estava
em **0/4** produtos e a `propagate-if-changed` automática tinha **falhado numa corrida com o
autosync** (rodou às 21:41 sobre git sujo → `apply-to-all-projects falhou, 2 erros`). Re-propaguei
manualmente com segurança (autosync pausado+religado por `trap`). Resultado: 4/4 ATIVOS com 10
`ideiaos-common` + `credential-isolation` (drift 7/8/9/8 zerado). **Dois achados que valem nota:**
(1) a auto-propagação **não é robusta a corrida com autosync** — pode falhar silenciosamente; rodar
`apply-to-all-projects.sh --apply` manual (com autosync pausado) é o fallback confiável. (2) **nfideia
rastreia `.claude/rules` em `main`** (Lovable) → cada sync exige um **PR** (foi o [nfideia#41](https://github.com/Ideia-Business/nfideia/pull/41),
MERGED) — enquanto **ideiapartner gitignora** as rules (local, frictionless). Recomendação durável:
alinhar nfideia ao modelo gitignore (um `git rm --cached` + commit em main). Mecanismo do gate de push:
[[learning-devops-push-gate-command-scoped-agent]].
