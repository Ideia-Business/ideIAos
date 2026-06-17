# SOURCE: IdeiaOS v2
# Plugin Membership — Mapeamento módulo → plugin

> **Fonte de verdade legível** do mapeamento de membership por plugin.
> A implementação canônica são os arrays em `scripts/build-plugins.sh`.
> Modificar nos dois lugares em sincronia.

O `build-plugins.sh` lê as listas definidas no seu próprio topo para decidir
o que copiar de `source/` para cada plugin em `plugins/`.

---

## ideiaos-core

**Quando instalar:** sempre (núcleo do IdeiaOS — orquestrador /idea, agents, hooks de qualidade/memória/observação, skills de workflow e aprendizado).

### Agents (15) — todos os `source/agents/*.md`

| Agent | Arquivo |
|-------|---------|
| build-error-resolver | source/agents/build-error-resolver.md |
| claude-continuation | source/agents/claude-continuation.md |
| code-explorer | source/agents/code-explorer.md |
| code-simplifier | source/agents/code-simplifier.md |
| doc-updater | source/agents/doc-updater.md |
| ideiaos-checker | source/agents/ideiaos-checker.md |
| performance-optimizer | source/agents/performance-optimizer.md |
| planner | source/agents/planner.md |
| pr-test-analyzer | source/agents/pr-test-analyzer.md |
| react-reviewer | source/agents/react-reviewer.md |
| refactor-cleaner | source/agents/refactor-cleaner.md |
| rls-reviewer | source/agents/rls-reviewer.md |
| security-reviewer | source/agents/security-reviewer.md |
| silent-failure-hunter | source/agents/silent-failure-hunter.md |
| typescript-reviewer | source/agents/typescript-reviewer.md |

### Hooks não-test (11) — `source/hooks/*.sh` exceto `test-*`

| Hook | Arquivo |
|------|---------|
| typecheck-on-edit.sh | source/hooks/typecheck-on-edit.sh |
| console-log-guard.sh | source/hooks/console-log-guard.sh |
| ideiaos-readme-reminder.sh | source/hooks/ideiaos-readme-reminder.sh |
| extract-learnings-reminder.sh | source/hooks/extract-learnings-reminder.sh |
| observe-tool-use.sh | source/hooks/observe-tool-use.sh |
| strategic-compact.sh | source/hooks/strategic-compact.sh |
| deia-trigger.sh | source/hooks/deia-trigger.sh |
| ideiaos-detector.sh | source/hooks/ideiaos-detector.sh |
| precompact-state-save.sh | source/hooks/precompact-state-save.sh |
| session-summary.sh | source/hooks/session-summary.sh |
| observe-session-end.sh | source/hooks/observe-session-end.sh |

> Excluídos do plugin (não são componentes de produto): `test-hooks.sh`, `test-typecheck-on-edit.sh`, `test-observe-hooks.sh`

### Skills core (30)

| Skill | Arquivo |
|-------|---------|
| accessibility | source/skills/accessibility/ |
| api-design | source/skills/api-design/ |
| benchmark-optimization-loop | source/skills/benchmark-optimization-loop/ |
| code-tour | source/skills/code-tour/ |
| codebase-onboarding | source/skills/codebase-onboarding/ |
| context-engineering | source/skills/context-engineering/ |
| cost-tracking | source/skills/cost-tracking/ |
| cursor-continuation | source/skills/cursor-continuation/ |
| database-migrations | source/skills/database-migrations/ |
| deep-research | source/skills/deep-research/ |
| doubt | source/skills/doubt/ |
| e2e-testing | source/skills/e2e-testing/ |
| evolve | source/skills/evolve/ |
| extract-learnings | source/skills/extract-learnings/ |
| forge-agent | source/skills/forge-agent/ |
| grelha | source/skills/grelha/ |
| idea | source/skills/idea/ |
| improve-architecture | source/skills/improve-architecture/ |
| ideiaos-catalog | source/skills/ideiaos-catalog/ |
| ideiaos-setup | source/skills/ideiaos-setup/ |
| instinct-analyze | source/skills/instinct-analyze/ |
| instinct-status | source/skills/instinct-status/ |
| learn | source/skills/learn/ |
| llms-txt | source/skills/llms-txt/ |
| mcp-to-cli | source/skills/mcp-to-cli/ |
| memory-sync | source/skills/memory-sync/ |
| recall-learnings | source/skills/recall-learnings/ |
| spec | source/skills/spec/ |
| tdd | source/skills/tdd/ |
| two-instance-kickoff | source/skills/two-instance-kickoff/ |

---

## ideiaos-design-suite

**Quando instalar:** perfil de design/UI (10 skills de design e front-end visual).

### Skills design (10)

| Skill | Arquivo |
|-------|---------|
| banner-design | source/skills/banner-design/ |
| brand | source/skills/brand/ |
| design | source/skills/design/ |
| design-system | source/skills/design-system/ |
| frontend-visual-loop | source/skills/frontend-visual-loop/ |
| motion | source/skills/motion/ |
| slides | source/skills/slides/ |
| ui-styling | source/skills/ui-styling/ |
| ui-ux-pro-max | source/skills/ui-ux-pro-max/ |
| web-quality | source/skills/web-quality/ |

---

## ideiaos-lovable

**Quando instalar:** projetos Lovable (skill /lovable-handoff + doutrina de deploy + templates).

### Componentes

| Componente | Fonte | Destino no plugin |
|-----------|-------|-------------------|
| skill lovable-handoff | source/skills/lovable-handoff/ | skills/lovable-handoff/ |
| deployment-protocol.md | source/rules/lovable/deployment-protocol.md | skills/lovable-handoff/references/deployment-protocol.md |
| templates lovable | source/templates/lovable/*.tmpl | templates/lovable/ |

---

## ideiaos-marketing

**Quando instalar:** projetos que produzem conteúdo de marketing (posts, carrosseis, blog, newsletter, VSL, threads, copy). Requer Chrome DevTools MCP para marketing-research.

### Skills (2)

| Skill | Arquivo |
|-------|---------|
| marketing | source/skills/marketing/ |
| marketing-research | source/skills/marketing-research/ |

### Agents (4)

| Agent | Arquivo | Model |
|-------|---------|-------|
| mkt-estrategista | source/agents/mkt-estrategista.md | opus |
| mkt-copywriter | source/agents/mkt-copywriter.md | sonnet |
| mkt-designer | source/agents/mkt-designer.md | sonnet |
| mkt-revisor | source/agents/mkt-revisor.md | sonnet |

### Rules (22 best-practices)

| Componente | Fonte |
|-----------|-------|
| rules/marketing/ | source/rules/marketing/ (22 arquivos — ver README.md do diretório) |

> As 22 best-practices são absorvidas do **OpenSquad MIT** (renatoasse/opensquad) e viajam com o plugin — o orquestrador /marketing as injeta em runtime por formato detectado na Discovery.

---

## Fora dos plugins (plugin: null)

Templates de projeto (`hybrid`, `ideiaos`, `learnings`, `aiox-ai-config`, `global-patches`, `skill`) e rules (`common`, `supabase`, `ecc`) **não compõem o payload de plugin** — são deploy de `setup.sh`/`build-adapters.sh` por projeto, não cópia do `build-plugins.sh`. Algumas rules carregam `plugin: ideiaos-core` no `modules.json` apenas como **tag de catálogo/dependência** (ex.: `delta-spec`, `operating-discipline`); essa tag **não** as empacota — o `build-plugins.sh` não tem etapa de cópia de rule e o gate `check-plugin-membership.sh` ignora `kind: rule` de propósito.

**Skills opt-in v8 (catálogo):** `observability` e `deprecation-migration` são `plugin: null` + `installStrategy: manual` — surgem via `/ideiaos-catalog`, **não** empacotadas por default.

> **R8-09 fechado (2026-06-16):** `build-adapters.sh build_claude_project_rules()` deploya `source/rules/common/*.md` → `<projeto>/.claude/rules/ideiaos-common-*.md` (paridade com o Cursor `.mdc`; Claude Code auto-carrega `.claude/rules/*.md`). Só `common/` (disciplina universal); stack/domínio ficam Cursor-side.

---

## Setup-only (não-plugin): contexts + statusline + hooks de memória (v5)

Os 3 contexts de modo (`context-dev`, `context-review`, `context-research`) e o `statusline-ideiaos` são instalados pelo `setup.sh` (passos 5.22 e 5.23) e vivem em `~/.ideiaos/`. São `plugin: null` em `manifests/modules.json`.

Os hooks de memória v5 (`memory-import.sh` em SessionStart, `memory-export.sh` em Stop) são `plugin: null` **deliberadamente** (decisão v7, Fase 2): são instalados via `install-global-patches.sh` (Patch 12/13), que os registra no `settings.json` com wiring específico. Empacotá-los também no plugin causaria **dupla-registração** (firam 2× por sessão → export duplicado na branch `planning`). Por isso ficam fora do `CORE_HOOKS` do `build-plugins.sh` — patch-installed, não plugin-packaged. O gate `check-plugin-membership.sh` respeita `plugin: null` e não os cobra.

**Rationale:** Contexts e statusline não são skills/agents/hooks do Claude Code e não seguem o modelo de cópia do `build-plugins.sh` (que itera arrays `CORE_*` de `source/hooks/`, `source/skills/`, `source/agents/`). Um novo `kind` no `modules.json` é compatível com versões anteriores — `build-plugins.sh` ignora kinds que não reconhece. O `build-plugins.sh` permanece inalterado.

**Instalação:** `setup.sh` copia `source/contexts/*.md` → `~/.ideiaos/contexts/` e oferece as funções shell via snippet (offer-not-edit, T-01-10). A statusline é copiada para `~/.ideiaos/statusline/` e o campo `statusLine` do `settings.json` é oferecido via snippet.

| Módulo | Fonte | Destino | Plugin |
|--------|-------|---------|--------|
| context-dev | source/contexts/dev.md | ~/.ideiaos/contexts/dev.md | null |
| context-review | source/contexts/review.md | ~/.ideiaos/contexts/review.md | null |
| context-research | source/contexts/research.md | ~/.ideiaos/contexts/research.md | null |
| statusline-ideiaos | source/statusline/ideiaos-statusline.sh | ~/.ideiaos/statusline/ideiaos-statusline.sh | null |
| memory-import.sh | source/hooks/memory-import.sh | settings.json (Patch 12) | null |
| memory-export.sh | source/hooks/memory-export.sh | settings.json (Patch 13) | null |

**evals/:** A suíte de regressão (`evals/`) é um ativo de repo-level (≥20 casos reais + `evals/run-evals.sh`) e não é registrada em `modules.json` — não é um módulo instalável, é infraestrutura de qualidade do próprio IdeiaOS.

---

## Referência cruzada

- Gerador: `scripts/build-plugins.sh`
- Marketplace: `.claude-plugin/marketplace.json`
- Módulos completos: `manifests/modules.json` (campo `"plugin"` por módulo)
