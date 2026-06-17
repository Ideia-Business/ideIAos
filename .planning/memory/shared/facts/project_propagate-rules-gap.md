---
name: propagate-rules-gap
description: "PENDENTE: propagate-if-changed.sh não auto-propaga mudanças de source/rules/ aos projetos; e setup.sh --project-only não deploya as .claude/rules do R8-09"
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

**Status:** não corrigido (decisão de não hackear às pressas). Fix deve reconciliar propagate-if-changed.sh + setup.sh/build-adapters numa fase própria.
