# ideIAos — Sistema Operacional Unificado de Desenvolvimento

> **Configura o ambiente de IA da equipe em um único comando.**
> O ideIAos combina 5 camadas (AIOX-Core, GSD, Lovable, Fase A, Continuation) em um sistema único, com **um comando de entrada** (`/idea`) que roteia para a camada certa.
> Implementado como `ideIAos` — instalável, idempotente, com enforcement automático para você não ter que lembrar de nada.

---

## 🚀 Quickstart (instalação em 30 segundos)

```bash
# 1. Clone
git clone git@github.com:Ideia-Business/ideIAos.git
cd ideIAos

# 2. Instale o ambiente global (uma vez na vida): skills + MCPs + hooks + Suíte de Design
bash setup.sh --global-only

# 3. Aplique o overlay (13 patches sobre GSD/AIOX/Claude) e confira a saúde
bash scripts/sync-all.sh         # já roda o idea-doctor no final

# 4. (Opcional) Atalho de terminal
bash scripts/install-alias.sh && source ~/.zshrc   # ou ~/.bashrc
```

> **Máquina nova do zero?** Use o bootstrap: `bash setup-dev-machine.sh` — clona todos os repos da Ideia, configura o autosync (LaunchAgent) **e** roda o setup global do IdeiaOS + overlay automaticamente.
>
> **Manutenção (qualquer dia):** `bash scripts/idea-doctor.sh` (diagnóstico) · `bash scripts/sync-all.sh` (atualiza tudo). Veja [Mantendo o ambiente global sincronizado](#-mantendo-o-ambiente-global-sincronizado-caminho-c--v11).

Pronto. Em qualquer projeto, você precisa decorar **um comando** — ou apenas chamar a **Deia** por nome:

| Onde | Como chamar | Função |
|------|-------------|--------|
| Claude Code | `Deia, <pedido>` ou `/idea <pedido>` | **Orquestrador ideIAos** — roteia para a camada certa |
| Cursor | `@ideiaos-checker` | Audita setup do projeto |
| Terminal | `idea-setup` | Roda setup do projeto atual |

A **Deia** é a assistente ideIAos — basta começar a mensagem com `Deia,` (ou `deia,` / `Déia,`) e ela ativa automaticamente. Reforçada por hook `UserPromptSubmit` para máxima confiabilidade.

E você não precisa decorar nem isso, porque **o sistema te avisa quando precisar**. Veja [Como usar no dia a dia](#-como-usar-no-dia-a-dia).

---

## 🧠 O que é o ideIAos

ideIAos é o **Sistema Operacional** de desenvolvimento da Ideia Business. Não é um framework — é a camada de orquestração que combina ferramentas em um sistema coerente:

| Camada | Propósito | Quando ativa |
|--------|-----------|--------------|
| **AIOX-Core** | Personas, stories, Constitution gates | Trabalho story-driven com múltiplos papéis |
| **GSD** | Phases, atomic commits, goal-backward verification | Execução técnica de qualquer escopo |
| **Lovable Handoff** | Deploy via Lovable Cloud, modelo 8 blocos | Projeto Lovable, qualquer mudança em produção |
| **Fase A (Learning)** | Recall+extract, gate triplo, memory global | Início e fim de toda sessão não-trivial |
| **Continuation** | Cross-IDE handoff (Cursor↔Claude) | Retomar trabalho entre IDEs |

Documentação canônica do design: [`docs/IDEIAOS.md`](docs/IDEIAOS.md).

Comparativo com ecossistema GitHub (60+ projetos analisados): [`../mapa-github-ai-dev-tools.md`](../mapa-github-ai-dev-tools.md).

---

## 🔀 Composição AIOX × GSD — Caminho C (v1.1)

AIOX-Core e GSD **não competem** — operam em planos diferentes e se compõem internamente. A Deia roteia para **um ponto de entrada**; a execução técnica sempre passa por GSD.

| Plano | Camada | Artefato canônico |
|-------|--------|-------------------|
| **O QUÊ** (intenção + critério de pronto) | AIOX-Core | `docs/stories/{N}.story.md` |
| **COMO** (execução técnica) | GSD | `.planning/phases/{N}/PLAN.md` + `VERIFICATION.md` |
| **ONDE** (produção) | Lovable Handoff | `docs/lovable/*` |
| **MEMÓRIA** (transversal) | Fase A | `docs/learnings/*` |
| **TRÂNSITO** (transversal) | Continuation | `STATE.md` + `HANDOFF.md` |

### A decisão única da Deia

Antes do roteamento, a Deia avalia **2 exceções + 1 decisão única**:

1. **Retomada?** ("retoma", "onde parei", "ontem...") → Continuation
2. **Bug reprodutível?** ("isso não funciona") → `/gsd-debug`
3. **Decisão única — precisa de O QUÊ formal?** Qualquer SIM dos 5 critérios → entrada AIOX. Todos NÃO → entrada GSD (default).

**Os 5 critérios:**
- Stakeholder externo no loop (cliente, compliance, legal, produto)
- Aceite formal antes de mergulhar (PRD, AC, escopo travado)
- Mudança visível ao usuário final que precisa validação de UX
- Trabalho dividido entre 2+ executores
- Palavras-chave: "story", "epic", "AC", "PRD", "validação formal"

### Os 3 contratos de integração

| Contrato | Comando | Quando |
|----------|---------|--------|
| **Plan aceita story** | `/gsd-plan-phase --story <path>` | Após AIOX validar story (AC vira goal-backward) |
| **QA-gate aceita verification** | `@qa *gate <story> --verification <path>` | Após GSD verificar (skip-if-verified) |
| **Hook lembra extract** | automático | Após qa-gate PASS, `*-VERIFICATION.md` success, ou `git commit` |

Detalhes completos: cada projeto ideIAos recebe [`docs/ideiaos/DECISION-MATRIX.md`](source/templates/ideiaos/DECISION-MATRIX.md.tmpl) e [`docs/ideiaos/GUIDE-AI.md`](source/templates/ideiaos/GUIDE-AI.md.tmpl).

---

## 📋 Pré-requisitos

> O bootstrap **aborta** se faltar `git`, `gh`, `node` ou `npm`. Instale-os antes.

- **Homebrew** (macOS) — para instalar o resto: [brew.sh](https://brew.sh)
- **Node.js 18+** (traz `npm`) — `brew install node` · [nodejs.org](https://nodejs.org)
- **Git** — `brew install git`
- **GitHub CLI (`gh`)** — `brew install gh` (necessário pra clonar os repos privados Ideia-Business)
- **Claude Code CLI** — `npm install -g @anthropic-ai/claude-code` (ou instalador oficial) · [claude.ai/code](https://claude.ai/code)
- **Cursor IDE** *(opcional)* — [cursor.sh](https://cursor.sh)
- Shell: `zsh` ou `bash` (macOS/Linux nativamente; Windows via WSL)

---

## 🔌 Instalação via Plugin (marketplace privado)

Máquina nova pode instalar os componentes ideIAos via plugin nativo do Claude Code — versionado, com `/plugin update` automático.

> **Pré-requisito de visibilidade:** O marketplace lê diretamente do repositório. Se o repo `Ideia-Business/IdeiaOS` ainda não estiver público no GitHub, use o path local em vez do slug GitHub: `claude plugin marketplace add /caminho/para/IdeiaOS`. **Decisão de tornar o repo público: pendente do usuário.**

```bash
# Adicionar o marketplace ideIAos (uma vez)
# Opção A — via GitHub (quando o repo for público):
claude plugin marketplace add Ideia-Business/IdeiaOS
# Opção B — via path local (repo privado ou clone já na máquina):
claude plugin marketplace add /caminho/para/IdeiaOS

# Instalar o núcleo (sempre — orquestrador, agents, hooks, skills de workflow)
claude plugin install ideiaos-core@ideiaos

# Instalar a Suíte de Design (perfil UI/design)
claude plugin install ideiaos-design-suite@ideiaos

# Instalar a camada Lovable (projetos Lovable)
claude plugin install ideiaos-lovable@ideiaos
```

| Plugin | Versão | Conteúdo | Quando instalar |
|--------|--------|----------|-----------------|
| `ideiaos-core` | 3.0.0 | 15 agents + 13 hooks + 24 skills (idea, tdd, evolve, instincts, memory-sync…) | Sempre — núcleo do sistema |
| `ideiaos-design-suite` | 3.0.0 | 10 skills de design (ui-ux-pro-max, design-system, brand…) | Quem faz UI/design |
| `ideiaos-lovable` | 3.0.0 | Skill `/lovable-handoff` + doutrina de deploy + templates | Projetos Lovable |

> **Plugin e setup.sh são complementares** — não excludentes. O plugin entrega skills/agents/hooks versionados com atualização nativa (`claude plugin update`). O `setup.sh` entrega o ambiente de máquina completo: working-dirs, autosync (LaunchAgent), vault Obsidian, git hooks e config de projeto. Para uma máquina nova do zero, use o setup.sh (ou o bootstrap `setup-dev-machine.sh`) — ele faz tudo em sequência.

---

## 🍎 Instalação em máquina nova (completa)

Fluxo de ponta a ponta pra um Mac do zero. O bootstrap faz o grosso; só GSD fica manual.

### 1. Pré-requisitos (uma vez — não são auto-instalados)
```bash
# Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Ferramentas base (bootstrap aborta se faltar)
brew install git gh node

# Claude Code CLI (se 'claude' não estiver no PATH)
npm install -g @anthropic-ai/claude-code
```

### 2. Pegar o bootstrap (escolha **A** ou **B**)
```bash
# A) Clonar o IdeiaOS primeiro (precisa de acesso ao GitHub Ideia-Business)
gh auth login                                   # se ainda não logado
mkdir -p ~/dev && git clone https://github.com/Ideia-Business/ideIAos.git ~/dev/IdeiaOS

# B) AirDrop deste Mac:  ~/dev/setup-dev-machine.sh  →  Mac novo
```

### 3. Rodar o bootstrap (faz quase tudo)
```bash
bash ~/dev/IdeiaOS/setup-dev-machine.sh         # ou o caminho do arquivo via AirDrop
```
Executa, em sequência:
- `gh auth login` (se preciso) + credential helper do git
- clona os 5 repos em `~/dev/` (cfoai-grupori, IdeiaOS, lapidai, nfideia, ideiapartner) + `npm install`
- instala o **autosync** (LaunchAgent, a cada 15 min, com **kill-switch timeout 120s**)
- `setup.sh --global-only` → **skills** (idea, frontend-visual-loop, motion, web-quality, Suíte de Design) + **MCPs** (chrome-devtools, context7) + hooks + agentes Cursor
- `sync-all.sh` → aplica os **13 patches** do overlay + roda `idea-doctor`

> ⚠️ No passo do **AIOX-core** aparece um prompt interativo de idioma — responda (só roda interativo porque há terminal). Sem terminal, ele é pulado e você roda depois: `npx aiox-core@latest install`.

### 4. Passo manual: plugin GSD
GSD vem por plugin do Claude Code (instalação interativa):
```
# dentro do Claude Code:
/plugin     → adicionar o plugin GSD (get-shit-done)
```

### 5. Verificar
```bash
bash ~/dev/IdeiaOS/scripts/idea-doctor.sh       # alvo: 0 FAIL
```
Se acusar algo, ele já mostra o comando de correção (quase sempre `bash ~/dev/IdeiaOS/scripts/sync-all.sh`).

### Caminhos que ficam instalados
| O quê | Onde |
|-------|------|
| Repos de trabalho | `~/dev/<projeto>/` |
| IdeiaOS (este repo) | `~/dev/IdeiaOS/` |
| Skills globais (idea, dev-loop, suíte, gsd-*) | `~/.claude/skills/` |
| MCPs (user scope) | config do Claude Code (`claude mcp list`) |
| Hooks Claude | `~/.claude/hooks/` |
| Agentes Cursor | `~/.cursor/agents/` |
| AIOX-core (framework) | `~/dev/.aiox-core/` |
| Autosync (LaunchAgent) | `~/Library/LaunchAgents/com.ideiaos.gitautosync.plist` |

> ⚠️ **Não auto-instalado:** pré-requisitos (passo 1) e o **plugin GSD** (passo 4, interativo do Claude Code).

---

## 🎯 O que este setup instala

### Componentes globais (uma vez, vale pra qualquer projeto)

| Componente | Onde | Para quê |
|------------|------|----------|
| **AIOX Core** | npm global via `npx aiox-core` | Orquestrador de agentes IA — base do AIOX |
| **GSD skills** | `~/.claude/skills/gsd-*` | Suite com 60+ comandos GSD (vem com Claude Code via plugins) |
| **Skill Claude `/idea`** | `~/.claude/skills/idea/` | **Orquestrador ideIAos** — comando único de entrada |
| **Skill Claude `/ideiaos-setup`** | `~/.claude/skills/ideiaos-setup/` | Audita + completa setup do projeto |
| **Skill Claude `/cursor-continuation`** | `~/.claude/skills/cursor-continuation/` | Retoma no Claude Code o trabalho do Cursor |
| **Skill Claude `/lovable-handoff`** | `~/.claude/skills/lovable-handoff/` | Playbook de implantação Lovable |
| **Skill Claude `/recall-learnings`** | `~/.claude/skills/recall-learnings/` | Lê aprendizados antes de propor plano |
| **Skill Claude `/extract-learnings`** | `~/.claude/skills/extract-learnings/` | Registra aprendizado pós-trabalho |
| **Skill Claude `/frontend-visual-loop`** | `~/.claude/skills/frontend-visual-loop/` | Loop visual render→screenshot→crítica→fix (Chrome DevTools MCP) |
| **Skill Claude `/motion`** | `~/.claude/skills/motion/` | Animação (Framer Motion / GSAP + princípios) |
| **Skill Claude `/web-quality`** | `~/.claude/skills/web-quality/` | Auditoria CWV / WCAG 2.1 / SEO (lighthouse via Chrome DevTools MCP) |
| **Suíte de Design `/ui-ux-pro-max`** | `~/.claude/skills/ui-ux-pro-max/` | Design intelligence: 84 estilos, 160 paletas, 73 fontes, 16 stacks (vendorizada) |
| **Skill Claude `/design`** | `~/.claude/skills/design/` | Logo, CIP, ícones, social photos (Gemini) |
| **Skill Claude `/design-system`** | `~/.claude/skills/design-system/` | Tokens (primitive→semantic→component) + **OKLCH** (via overlay Patch 7) |
| **Skill Claude `/ui-styling`** | `~/.claude/skills/ui-styling/` | shadcn/ui + Tailwind + canvas design |
| **Skill Claude `/brand`** | `~/.claude/skills/brand/` | Voz de marca, identidade visual, consistência |
| **Skill Claude `/banner-design`** | `~/.claude/skills/banner-design/` | Banners social/ads/web/print |
| **Skill Claude `/slides`** | `~/.claude/skills/slides/` | Apresentações HTML com Chart.js + design tokens |
| **Agente Cursor `@claude-continuation`** | `~/.cursor/agents/` | Retoma no Cursor o trabalho do Claude Code |
| **Agente Cursor `@ideiaos-checker`** | `~/.cursor/agents/` | Audita + completa setup do projeto no Cursor |
| **Hook Claude `extract-learnings-reminder`** | `~/.claude/hooks/` | Após `git commit`, lembra de gate triplo |
| **Hook Claude `ideiaos-detector`** | `~/.claude/hooks/` | SessionStart — detecta projeto sem ideIAos |
| **Hook Claude `ideiaos-readme-reminder.sh`** | `~/.claude/hooks/` | PostToolUse Edit/Write — lembra de sync README |
| **Hook Claude `deia-trigger.sh`** | `~/.claude/hooks/` | UserPromptSubmit — detecta "Deia," e ativa `/idea` |
| **Hook Claude `typecheck-on-edit.sh`** | `~/.claude/hooks/` | PostToolUse Edit/Write — tsc incremental async em .ts/.tsx; acorda Claude se erros |
| **Hook Claude `console-log-guard.sh`** | `~/.claude/hooks/` | PostToolUse Edit/Write — detecta console.log/debug/info em .ts/.tsx/.js/.jsx |
| **Hook Claude `strategic-compact.sh`** | `~/.claude/hooks/` | PreToolUse — conta tool calls/sessão; sugere `/compact` a cada 50 |
| **Hook Claude `precompact-state-save.sh`** | `~/.claude/hooks/` | PreCompact — snapshot de STATE.md antes do `/compact` |
| **Hook Claude `session-summary.sh`** | `~/.claude/hooks/` | Stop — persiste resumo ECC em `~/.claude/sessions/` e atualiza CONTINUATION_HANDOFF.md |
| **Hook Claude `observe-tool-use.sh`** | `~/.claude/hooks/` | PostToolUse Edit/Write/Bash — anexa observação (só metadados) em `~/.ideiaos/observations/` |
| **Hook Claude `observe-session-end.sh`** | `~/.claude/hooks/` | Stop — marca session_end como gatilho do /instinct-analyze |
| **Hook Claude `memory-import.sh`** | `~/.claude/hooks/` | SessionStart (v5) — importa os fatos `shared/` do branch `planning` para a memória nativa da IDE (`~/.claude/projects/<slug>/memory/`); roda após git-sync-check; regenera a ponte Cursor `.cursor/rules/memory-bridge.mdc` (gitignored); freshness guard por SHA; exit 0 offline-safe (nunca bloqueia SessionStart) |
| **Hook Claude `memory-export.sh`** | `~/.claude/hooks/` | Stop (v5) — exporta a memória nativa alterada para o branch `planning` via git plumbing (`hash-object`→`commit-tree`→`update-ref`); NUNCA toca `main`, sem resíduo no working tree; secret-scan gate (recusa fatos com credencial); escrita real é skill-driven (`/memory-sync export`) |
| **Skill Claude `/instinct-analyze`** | `~/.claude/skills/instinct-analyze/` | Agente haiku background — observações → instincts atômicos |
| **Skill Claude `/instinct-status`** | `~/.claude/skills/instinct-status/` | Lista instincts com barras de confidence por domínio/scope |
| **Skill Claude `/learn`** | `~/.claude/skills/learn/` | Extração manual mid-session — instinct confidence 0.5 |
| **Skill Claude `/evolve`** | `~/.claude/skills/evolve/` | Promove instincts maduros (≥0.7) → vault Obsidian ou source/rules/ |
| **Skill Claude `/memory-sync`** | `~/.claude/skills/memory-sync/` | Gatilho manual da memória compartilhada entre IDEs/máquinas (v5) — `export` (memória nativa → `planning`, git plumbing, Lovable-safe) e `import` (`planning` → memória nativa + ponte Cursor); `status` diferido (v5.x) |
| **MCP `chrome-devtools`** | user scope (via `claude mcp`) | Auditoria de console/rede do browser direto no Claude Code |
| **MCP `context7`** | user scope (via `claude mcp`) | Docs versionadas de 1000+ libs (React/Tailwind/etc) ao vivo |
| **Alias `idea-setup`** | `~/.zshrc` ou `~/.bashrc` (via `install-alias.sh`) | Atalho terminal — `cd projeto && idea-setup` |
| **Contexts de modo** | `~/.ideiaos/contexts/` (via setup.sh 5.22) | `source/contexts/` — dev.md / review.md / research.md |
| **Funções `claude-dev` / `claude-review` / `claude-research`** | snippet oferecido pelo setup.sh (opt-in no rc) | Abre Claude em modo focado via `--append-system-prompt` (preserva CLAUDE.md/hooks/memória) |
| **Statusline IdeiaOS** | `~/.ideiaos/statusline/ideiaos-statusline.sh` (via setup.sh 5.23) | Exibe branch · modelo · dir no status bar do Claude Code (snippet settings.json — opt-in) |
| **Suíte de evals** | `evals/` (repo-level — não instalável) | ≥20 casos reais + `bash evals/run-evals.sh` — regressão de qualidade do IdeiaOS |

### Agents ECC (Fase 04 — source/agents/)

13 agents absorvidos do ECC (via quarentena) — instalados por `bash scripts/build-adapters.sh --target claude`:

| Agent | Modelo | Quando usar |
|-------|--------|-------------|
| `security-reviewer` | opus | Auditar vulnerabilidades antes de deploy |
| `typescript-reviewer` | sonnet | Revisar type-safety e uso correto de TS |
| `react-reviewer` | sonnet | Revisar hooks, re-renders, padrões React |
| `rls-reviewer` | sonnet | Revisar RLS e migrations Supabase |
| `pr-test-analyzer` | sonnet | Identificar lacunas de teste em PRs |
| `silent-failure-hunter` | opus | Caçar erros engolidos e falhas silenciosas |
| `build-error-resolver` | sonnet | Resolver erros de tsc/vite/jest/lint |
| `code-simplifier` | sonnet | Simplificar código complexo |
| `refactor-cleaner` | sonnet | Limpar código morto e duplicação |
| `planner` | opus | Planejamento ad-hoc de tarefas amplas |
| `code-explorer` | haiku | Navegar codebase sem modificar nada |
| `doc-updater` | haiku | Atualizar README e comentários WHY |
| `performance-optimizer` | sonnet | Identificar gargalos de performance |

### Skills ECC de workflow (Fase 04 — source/skills/)

14 skills adicionadas na Fase 04 — acessíveis via `/idea` ou comando direto:

| Skill | installStrategy | Descrição |
|-------|-----------------|-----------|
| `/tdd` | always | Test-Driven Development RED→GREEN→REFACTOR |
| `/e2e-testing` | always | Testes end-to-end para fluxos críticos |
| `/deep-research` | always | Pesquisa profunda para decisões técnicas |
| `/codebase-onboarding` | always | Onboarding estruturado em codebase nova |
| `/code-tour` | always | Tour guiado de fluxo ou feature |
| `/api-design` | always | Design de endpoints e contrato de API |
| `/benchmark-optimization-loop` | always | Medir antes de otimizar |
| `/cost-tracking` | always | Rastrear custo de tokens e escolha de modelo |
| `/database-migrations` | stack:supabase | Migrations seguras com estratégia de rollback |
| `/accessibility` | stack:react | WCAG ao construir componentes |
| `/two-instance-kickoff` | manual | Kickoff com 2 instâncias em paralelo (scaffold + research) |
| `/llms-txt` | manual | Gerar llms.txt para consumo por IA |
| `/mcp-to-cli` | manual | Converter MCP pesado em skill + CLI |
| `/ideiaos-catalog` | always | Listar módulos instalados vs disponíveis |

### Manutenção do próprio ideIAos (rodados manualmente)

| Script | O que faz |
|--------|-----------|
| `scripts/install-alias.sh` | Adiciona alias `idea-setup` ao seu shell rc (zsh/bash) |
| `scripts/install-git-hooks.sh` | Instala pre-commit hook que BLOQUEIA commits sem README sincronizado E protege o pin GSD do `versions.lock` |
| `scripts/check-readme-sync.sh` | Audita se README menciona todos os componentes do repo |
| **`scripts/check-versions-lock.sh`** | **Guarda do pin GSD** — bloqueia valor pré-redux (1.3x/1.4x) e edição manual do `gsd=` que não corresponda à versão instalada (único escritor: `update-upstream.sh --bump`; bypass: `IDEIAOS_LOCK_OVERRIDE=1`). Roda no pre-commit. |
| **`scripts/check-memory-not-on-main.sh`** | **Guarda Lovable-safe da memória (v5)** — bloqueia qualquer caminho de memória (`.planning/memory/`, `.lovable_mem_tmp.md`, `.cursor/rules/memory-bridge.mdc`) staged no branch `main` e o merge `planning`→`main`; mensagem direcional (diz qual lado está errado); bypass consciente: `IDEIAOS_MEM_OVERRIDE=1`. Modos `--staged` (pre-commit) e `--merge` (pre-merge-commit). |
| **`scripts/idea-doctor.sh`** | Diagnóstico read-only: skills, MCPs, 13 patches, versões vs `versions.lock`, drift, autosync, **Seção 7 Security Audit** (deny rules, hooks, secrets, quarentena), **Seção 8 Contexts** (~/.ideiaos/contexts/, funções claude-dev/review/research, statusline), **Seção 9 Memória v5** (planning, store shared/, patches 12/13) |
| **`scripts/install-global-patches.sh`** | Aplica overlay ideIAos (Caminho C) sobre GSD/AIOX/Claude — idempotente, 13 patches (incl. Patch 11: backlog-sync-check, Patches 12/13: memória v5) |
| **`security/scan-absorbed.sh`** | **Pipeline de quarentena obrigatório** — scan unicode invisível/payloads/comandos + AgentShield antes de absorver conteúdo de terceiros em `source/`. Exit 1 = bloqueado. |
| **`scripts/update-upstream.sh`** | Detecta updates do GSD plugin e AIOX-core vs `versions.lock`; `--bump` re-pina |
| **`scripts/update-design-suite.sh`** | Atualização CONTROLADA da Suíte de Design (re-vendoriza do nextlevelbuilder, mostra diff, sob demanda) |
| **`scripts/sync-all.sh`** | Orquestrador — `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| **`scripts/apply-to-all-projects.sh`** | Propaga `setup.sh --project-only` a todos os repos `~/dev/*`. Dry-run por padrão; use `--apply` para executar. `--only proj1,proj2` para filtrar. |
| **`scripts/ideiaos-update.sh`** | **Atualização de máquina em 1 comando** — sync-all + guarda do git-autosync (versions.lock fora do add -A) + funções claude-dev/review/research no shell + statusline no settings.json (idempotente, com backup; edita config do usuário por consentimento explícito — diferente do setup.sh/T-01-10) |
| **`scripts/build-adapters.sh`** | **Compila `source/` → harnesses** — copia hooks/agents para Claude (`~/.claude/`) e rules para Cursor (`.cursor/rules/*.mdc`). Suporte a `--target claude\|cursor\|all` e `--dry-run`. |
| **`scripts/build-plugins.sh`** | **Gera `plugins/` a partir de `source/`** — gerador idempotente dos 3 sub-plugins do marketplace. Suporte a `--plugin core\|design-suite\|lovable\|all` e `--dry-run`. |
| **`versions.lock`** | Lockfile de versões (aiox-core, gsd, ref da Suíte, MCPs, plugins) que toda máquina deve convergir |

### Componentes do projeto (instalados quando você roda em projeto específico)

| Componente | Arquivo | Camada |
|------------|---------|--------|
| `IDEIAOS.md` | Raiz | ideIAos — manifesto |
| `docs/ideiaos/GUIDE-HUMANS.md` | docs/ideiaos/ | ideIAos — guia para humanos |
| `docs/ideiaos/GUIDE-AI.md` | docs/ideiaos/ | ideIAos — guia para IAs |
| `docs/ideiaos/DECISION-MATRIX.md` | docs/ideiaos/ | ideIAos — matriz "tarefa → comando" |
| `AGENTS.md` com seção Lovable + Fase A | Raiz | AIOX |
| `CLAUDE.md` (auto-load Claude) | Raiz | AIOX |
| `STATE.md` (snapshot operacional) | Raiz | Continuation |
| `CONTRIBUTING.md` | Raiz | AIOX |
| `docs/CONTINUATION_HANDOFF.md` | docs/ | Continuation |
| `.cursor/rules/agents-md-protocol.mdc` | .cursor/rules/ | Cursor |
| `.cursor/rules/session-continuation.mdc` | .cursor/rules/ | Cursor |
| `.cursor/rules/planning-branch.mdc` | .cursor/rules/ | Cursor |
| `.cursor/rules/lovable-deploy.mdc` | .cursor/rules/ | Lovable |
| `.aiox-ai-config.yaml` (com marker ideIAos) | Raiz | ideIAos |
| `docs/playbook-implantacao.md` | docs/ | Lovable |
| `docs/lovable/conclusao-implantacao.md` | docs/lovable/ | Lovable |
| `docs/lovable/_TEMPLATE.md` | docs/lovable/ | Lovable |
| `AGENTS.lovable.md` (seção Lovable no AGENTS.md) | via template `AGENTS.lovable.md.tmpl` | Lovable |
| `docs/learnings/_TEMPLATE.md` | docs/learnings/ | Fase A |
| `docs/learnings/README.md` | docs/learnings/ | Fase A |
| `docs/postmortems/` | docs/ | Fase A |
| `.planning/phases/` | .planning/ | GSD |
| `.planning/intel/` | .planning/ | GSD |
| `.planning/research/` | .planning/ | GSD |

---

## 📖 Como usar no dia a dia

### 🎯 Comando único de entrada (recomendado)

```
/idea <pedido em linguagem natural>
```

Exemplos:
- `/idea quero implementar autenticação OAuth`
- `/idea retoma de onde parei ontem`
- `/idea publicar isso na Lovable`
- `/idea debugar esse bug recorrente`
- `/idea cria nova feature de busca`

O `/idea` roteia automaticamente para a camada certa e mostra qual comando está executando.

---

### 🤖 No Claude Code

#### Projeto novo (primeira vez):

1. Abra o Claude Code dentro da pasta do projeto
2. Aguarde 1 segundo. Se aparecer um aviso `🔧 Setup detector — projeto sem ideIAos`, digite:
   ```
   /ideiaos-setup
   ```
3. A IA lista o que está faltando, pergunta se aplica. Responda **"sim"**.
4. Pronto. Use `/idea <pedido>` daqui em diante.

#### Projeto já configurado:

Não aparece aviso. Pode pedir o que quiser direto via `/idea`.

#### Se você esquecer:

Digita `/ideiaos-setup`. Idempotente — pula tudo que já tem, instala só o que falta.

---

### 🟦 No Cursor

#### Projeto novo (primeira vez):

1. Abra o projeto no Cursor
2. Abra o chat lateral (Cmd+L ou ícone do chat)
3. Peça qualquer coisa. Se a IA disser `🔧 Setup incompleto detectado — Considere @ideiaos-checker`, digite:
   ```
   @ideiaos-checker
   ```
4. O agente lista, confirma, aplica.

#### Projeto já configurado:

IA não sugere setup. Pode trabalhar direto.

#### Se você esquecer:

Digita `@ideiaos-checker` no chat **ou** abre terminal embutido e roda `idea-setup`.

---

### ⚡ Terminal (qualquer IDE ou shell puro)

Com alias configurado:
```bash
cd /caminho/do/projeto
idea-setup
```

Sem alias:
```bash
bash "$HOME/.../ideiaos-setup/setup.sh" --lovable "$PWD"
```

#### Modos de contexto (Fase 07 — source/contexts/)

O setup.sh implanta os contexts em `~/.ideiaos/contexts/` e oferece funções shell via snippet (opt-in).
Após adicionar ao seu rc de shell (`~/.zshrc` ou `~/.bashrc`):

```bash
claude-dev       # abre em modo dev — implementação, qualidade, commits atômicos
claude-review    # abre em modo review — análise, critique, nunca edita arquivos
claude-research  # abre em modo research — deep research, mapeamento de domínio
```

Usa `--append-system-prompt` (preserva CLAUDE.md, hooks e memória automáticos do IdeiaOS).
**Não usa** `--system-prompt` (que substituiria o prompt padrão inteiro).

#### Statusline IdeiaOS (source/statusline/ideiaos-statusline.sh)

Após instalar via setup.sh (passo 5.23), adicione ao `~/.claude/settings.json`:
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash /Users/<você>/.ideiaos/statusline/ideiaos-statusline.sh"
  }
}
```
Exibe: branch · modelo · dir · fase GSD · context ativo. O setup.sh **não modifica** `settings.json` (T-01-10).

#### Suíte de evals (evals/)

```bash
bash evals/run-evals.sh --list   # lista os ≥20 casos
bash evals/run-evals.sh          # roda todos os casos
```
Ativo de repo-level (não instalável via setup.sh) — regressão de qualidade do IdeiaOS.

---

## 🎯 O que você precisa decorar

| Lugar | Comando | Função |
|-------|---------|--------|
| Claude Code | `/idea <pedido>` | **Orquestrador ideIAos** — único comando real necessário |
| Claude Code (setup) | `/ideiaos-setup` | Quando suspeitar que setup está incompleto |
| Cursor | `@ideiaos-checker` | Equivalente no Cursor |
| Terminal | `idea-setup` | Atalho do `setup.sh --lovable .` |

**Só isso.** Se você esquecer, o próprio sistema te lembra. Se ainda assim esquecer, rode `/ideiaos-setup` ou `@ideiaos-checker` — não estraga nada.

📚 Tabela completa de comandos por camada: cada projeto ideIAos recebe `docs/ideiaos/DECISION-MATRIX.md`.

---

## 🏗️ Arquitetura — como tudo se conecta

```
                            USUÁRIO
                               │ (pedido em linguagem natural)
                               ▼
                          ┌─────────┐
                          │  /idea  │  ← orquestrador ideIAos
                          └────┬────┘
                               │
                               ▼
                  ┌──────────────────────────┐
                  │  Matriz de Roteamento    │
                  │  (DECISION-MATRIX.md)    │
                  └────────────┬─────────────┘
                               │
        ┌───────────┬──────────┴──────────┬─────────┬─────────────┐
        ▼           ▼                     ▼         ▼             ▼
    ┌────────┐  ┌────────┐           ┌────────┐ ┌────────┐  ┌────────────┐
    │  AIOX  │  │  GSD   │           │Lovable │ │ Fase A │  │Continuation│
    │ Core   │  │        │           │Handoff │ │Learning│  │   X-IDE    │
    └────┬───┘  └───┬────┘           └────┬───┘ └────┬───┘  └─────┬──────┘
         │          │                     │          │            │
    ┌────┴──────────┴──────┐         ┌────┴──────────┴────────────┴────────┐
    │  Quality Gates       │         │  setup.sh (idempotente)             │
    │  Constitution Gates  │         │  Cada execução é independente       │
    └──────────────────────┘         └─────────────────────────────────────┘
                                                       │
                  ┌────────────────────────────────────┴──────────┐
                  │  Você (humano) — não precisa lembrar de nada │
                  └───────────────────────────────────────────────┘
```

### Idempotência é a chave

O `setup.sh` é **idempotente**: roda 1x ou 100x, dá o mesmo resultado. Isso permite que múltiplas formas de invocá-lo coexistam sem coordenação. Detalhes em `docs/learnings/2026-05-28-idempotency-enables-multi-entry-tooling.md` no projeto ideiapartner (espelho global em memória Claude).

---

## 🔀 Arquitetura Multi-Harness (Fase 03+)

O IdeiaOS v2 separa **fonte de verdade** de **artefatos de harness**. Nunca edite os artefatos gerados diretamente — edite `source/` e recompile.

```
source/                         manifests/modules.json
├── skills/                     (catálogo — 77 módulos)
├── agents/        ──────────────────────┐
├── hooks/                               │
├── templates/                           ▼
└── rules/              scripts/build-adapters.sh
    ├── common/                          │
    ├── supabase/          ┌─────────────┴──────────────┐
    ├── lovable/           ▼                            ▼
    └── ecc/        adapters/claude/          adapters/cursor/
        ├── common/ (~/.claude/hooks/          (.cursor/rules/*.mdc
        ├── typescript/  ~/.claude/agents/)     no projeto-alvo)
        └── react/
```

### Rebuild rápido

```bash
# Rebuild completo (todos os harnesses)
bash scripts/build-adapters.sh --target all

# Seletivo
bash scripts/build-adapters.sh --target claude
bash scripts/build-adapters.sh --target cursor --project-dir /caminho/do/projeto

# Dry-run (ver o que seria feito sem executar)
bash scripts/build-adapters.sh --target all --dry-run
```

### Harnesses suportados

| Harness | Status | Destino |
|---------|--------|---------|
| `claude` | ATIVO | `~/.claude/hooks/` + `~/.claude/agents/` |
| `cursor` | ATIVO | `.cursor/rules/*.mdc` no projeto-alvo |
| `codex` | planejado (Fase 04+) | `adapters/_scaffold/` como template |
| `gemini` | planejado (Fase 04+) | `adapters/_scaffold/` como template |
| `zed` | planejado (Fase 04+) | `adapters/_scaffold/` como template |

> **Princípio:** `source/` é imutável durante o dia a dia. `build-adapters.sh` é o único ponto de saída para harnesses. Filtro por stack (`detect_stack()` + `installStrategy` do catálogo) entra na Fase 04 com a skill `/ideiaos-catalog`.

---

## 🌊 Camada Lovable (deploy via Lovable Cloud)

Para projetos cujo deploy final acontece na **Lovable Cloud**, adicione `--lovable`:

```bash
bash setup.sh --lovable /caminho/do/projeto
```

Sem a flag, o setup **detecta automaticamente** (procura `lovable.config.*`, `.lovable/`, marker no `AGENTS.md`). Detalhes no `AGENTS.md` do projeto após instalação.

### O que vem com a camada Lovable

- **Playbook de implantação:** typecheck → commit → push → handoff → postmortem
- **Arquivos protegidos:** `src/integrations/supabase/{client,types}.ts`, `.env`, `supabase/config.toml` — nunca editar localmente
- **Padrões de debugging em produção** (3 regras obrigatórias):
  1. **"Bug persiste após fix" → check deploy ANTES de mexer no código** (80%+ é deploy drift)
  2. **Schema-first verification** — validar SELECT antes de UPDATE em produção
  3. **Hotfixes inline em sistemas externos → sync explícito pro repo** (sem isso, bug volta no próximo redeploy)
- **Modelo canônico de resposta de conclusão** (8 blocos): cabeçalho → entendimento → causa raiz → correção → verificação → **ação necessária ⚠️** → aprendizado → próximo passo

---

## 🧠 Loop de aprendizado contínuo (Fase A)

Cada implantação não-trivial passa por 3 momentos:

1. **Antes do plano — `/recall-learnings`**: IA lê AGENTS.md, 5 learnings mais recentes, postmortems relevantes, memória global.
2. **Durante a sessão:** marca mentalmente candidatos a aprendizado.
3. **Ao concluir — `/extract-learnings`**: aplica gate triplo (replicável + não-óbvio + estável) e cria `docs/learnings/YYYY-MM-DD-<slug>.md` se passar.

**Enforcement automático (Claude Code):** hook PostToolUse injeta lembrete do gate triplo em **3 gatilhos** (composição AIOX × GSD — Contrato 3):

1. **`git commit`** (gatilho original)
2. **Write/Edit em `docs/qa/gates/*.yaml` com `gate: PASS`** (qa-gate AIOX concluído)
3. **Write/Edit em `.planning/phases/*/*-VERIFICATION.md` com goal atingido** (verify-work GSD concluído)

Sem isso, sob pressão a IA tende a pular o passo de reflexão.

**Enforcement Cursor:** rule `agents-md-protocol.mdc` lida em todo turno orienta a IA a aplicar o mesmo gate.

---

## 🔄 Mantendo atualizado — Bundle versioning (v1.1+)

Quando houver melhorias:

```bash
cd ideIAos
git pull
bash setup.sh
```

O script detecta diferenças e atualiza só o que mudou. Em projetos existentes:

```bash
bash setup.sh --project-only --lovable /caminho/do/projeto
```

### Detecção automática de versão do bundle (v1.1)

O `setup.sh` compara a versão do `IDEIAOS.md.tmpl` (template) com a versão instalada no projeto (`IDEIAOS.md` na raiz). Comportamento:

| Cenário | Ação |
|---------|------|
| Projeto não tem `IDEIAOS.md` | Renderiza bundle completo (IDEIAOS + GUIDE-AI + DECISION-MATRIX + GUIDE-HUMANS) |
| Versão instalada = versão template | Pula (idempotente — comportamento histórico) |
| Versão template > versão instalada | **Bundle refresh atômico** — re-renderiza todos os docs ideIAos preservando data de instalação original |

**Por que bundle refresh é atômico:** os 4 docs ideIAos (`IDEIAOS.md`, `GUIDE-HUMANS.md`, `GUIDE-AI.md`, `DECISION-MATRIX.md`) são gerados como conjunto coerente. Atualizar só um deixaria o sistema inconsistente. Por isso o bump de versão no `IDEIAOS.md.tmpl` força refresh de todos.

**Importante:** os docs ideIAos são **artefatos gerados, não customizáveis localmente**. Se você quer customizar, edite o template no repo ideIAos — assim a mudança propaga pra todos os projetos.

A versão também é refletida em `.aiox-ai-config.yaml` (`ideiaos.version: X.Y`) e atualizada automaticamente no upgrade.

---

## 🔁 Mantendo o ambiente global sincronizado (Caminho C — v1.1)

O `setup.sh` cuida dos arquivos do **projeto**. Para os **arquivos globais** (skills Claude Code, workflow GSD, hook Fase A, settings.json, agente qa AIOX-core) o ideIAos aplica um **overlay** via patches idempotentes.

### Os 13 patches do overlay ideIAos

| # | Onde | O que adiciona |
|---|------|----------------|
| 1 | `~/.claude/skills/gsd-plan-phase/SKILL.md` | Flag `--story <file>` (Contrato 1 da composição) |
| 2 | `~/.claude/get-shit-done/workflows/plan-phase.md` | Pipeline `STORY_MODE` para parsing de AC AIOX |
| 3 | `~/.claude/hooks/extract-learnings-reminder.sh` | 3 gatilhos Fase A (commit + qa-gate PASS + verify SUCCESS) |
| 4 | `~/.claude/settings.json` | Matcher expandido `Bash\|Write\|Edit\|MultiEdit` |
| 5 | `.aiox-core/.../agents/qa.md` | Flag `--verification <path>` em `*gate` (Contrato 2) |
| 6 | `.aiox-core/.../tasks/qa-gate.md` | Seção "Optional Input — ideIAos Composition" |
| 7 | `~/.claude/skills/design-system/SKILL.md` | Tokens **OKLCH** (`--brand-hue`) na Suíte de Design (upstream de terceiros) |
| 8 | `~/.claude/settings.json` (SessionStart hook) | `git-sync-check`: auto fast-forward cross-máquina na abertura de sessão |
| 9 | `~/.config/git/ignore` | Gitignore global: `settings.local.json` + `.DS_Store` (evita dirty tree no autosync) |
| 10 | `~/.claude/settings.json` (permissions.deny) | **Deny rules baseline de segurança**: `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Read(**/.env*)`, `Write(~/.ssh/**)`, `Bash(curl * \| bash)`, `Bash(nc *)` |
| 11 | `~/.claude/settings.json` (SessionStart hook) | `backlog-sync-check`: análogo de **runtime** do git-sync-check — injeta a contagem REAL de incidentes abertos em prod (ops-db-gateway, read-only) na abertura de sessão, confrontando "Pendências Cloud" do handoff com a verdade. Gated p/ repos com `scripts/ops-db-query.mjs` (ideiapartner); silencioso nos demais |
| 12 | `~/.claude/settings.json` (SessionStart hook) | `memory-import` (v5): importa os fatos `shared/` do branch `planning` para a memória nativa da IDE; registrado **após** git-sync-check e backlog-sync-check (depende dos refs já buscados); read-only via `git show`/`git archive`, sem checkout; exit 0 offline-safe |
| 13 | `~/.claude/settings.json` (Stop hook) | `memory-export` (v5): exporta a memória nativa alterada para o branch `planning` via git plumbing (`hash-object`→`commit-tree`→`update-ref`); NUNCA toca `main`, sem resíduo no working tree; secret-scan gate antes de cada export |

### Scripts de manutenção + lockfile

| Comando | Quando usar |
|---------|-------------|
| `bash scripts/idea-doctor.sh` | **SEMPRE PRIMEIRO** — diagnóstico read-only: skills, MCPs, 13 patches, versões vs lock, drift, autosync, **Security Audit** (Seção 7), **Memória v5** (Seção 9). Não muda nada. |
| `bash scripts/sync-all.sh` | **O DE SEMPRE** — atualiza tudo: `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| `bash scripts/install-global-patches.sh` | só re-aplicar o overlay (13 patches, incl. deny rules + backlog-sync-check + memória v5 import/export) — idempotente, roda 100x |
| `bash scripts/update-upstream.sh` | checar updates de GSD/AIOX vs `versions.lock`. `--bump` re-pina o lock no instalado |
| `bash scripts/update-design-suite.sh` | atualizar a Suíte de Design do upstream (controlado, mostra diff, **sob demanda**) |
| `bash scripts/apply-to-all-projects.sh` | propagar `setup.sh --project-only` a todos os repos `~/dev/*` — dry-run por padrão; `--apply` executa; `--only proj1,proj2` filtra |

> **`versions.lock`** (raiz do repo) fixa as versões que toda máquina deve convergir (aiox-core CLI, gsd, ref da Suíte, specs de MCP). `idea-doctor` acusa drift; `update-upstream --bump` re-pina.

### Como atualizar CADA componente

| Componente | Como atualizar |
|------------|----------------|
| **Skills nossas** (idea, frontend-visual-loop, motion, web-quality…) | edite em `source/skills/` → commit/push → nas outras máquinas: `git pull` + `bash scripts/sync-all.sh` |
| **Suíte de Design** (upstream de terceiros) | `bash scripts/update-design-suite.sh [ref]` → revisa o diff → commit. O OKLCH (Patch 7) re-aplica sozinho |
| **GSD plugin** | menu de plugins do Claude Code (interativo) → `sync-all.sh` (re-aplica overlay) → `update-upstream.sh --bump` (re-pina) |
| **AIOX-core** | `aiox update` (ou npm) → `sync-all.sh` → `update-upstream.sh --bump` |
| **MCPs** (chrome-devtools, context7) | usam `@latest` (auto no runtime). Reinstalar: `setup.sh --global-only` |
| **O próprio IdeiaOS** | `git pull` no repo → `bash scripts/sync-all.sh` |

```bash
# Diagnóstico primeiro (read-only — não muda nada)
bash scripts/idea-doctor.sh

# Atualizar TUDO de uma vez (o comando do dia a dia)
bash scripts/sync-all.sh
```

### Quando rodar `sync-all.sh`

- **Após atualizar Claude Code, GSD plugin ou AIOX-core** — porque updates upstream sobrescrevem os patches do overlay
- **Após trocar de máquina** — restaura o ambiente do zero
- **Quando algo "parou de funcionar magicamente"** — provavelmente um update silencioso quebrou o overlay
- **Toda 1ª segunda do mês** (hábito) — garante consistência sem precisar lembrar
- **Antes de uma sessão importante** — zero surpresas

### Como o overlay sobrevive a updates upstream

Cada patch tem um **marcador único** (string que só existe se o patch foi aplicado). O script detecta presença antes de aplicar:

| Cenário | Comportamento |
|---------|---------------|
| Patch já aplicado | `⊙ skip` (idempotente) |
| Arquivo vanilla (sem patch) | `✓ apply` (overlay restaurado) |
| Upstream renomeou marcadores | `✗ fail` (alerta — requer adaptação manual do script) |

A simulação testada em 2026-05-30: apagar manualmente os 3 gatilhos do hook → rodar `install-global-patches.sh` → patch detecta ausência e restaura. ✓

### Arquitetura: vanilla / overlay / projeto

```
┌─────────────────────────────────────────────────────────────┐
│                    UPSTREAM (vanilla)                       │
│  GSD plugin                       AIOX-core                 │
│  ~/.claude/skills/gsd-*           Projects/.aiox-core/      │
│  Claude Code settings             package: @aiox-fullstack  │
└─────────────────────────────────────────────────────────────┘
                            ↓ atualiza via npm / plugin manager
┌─────────────────────────────────────────────────────────────┐
│              OVERLAY ideIAos (Caminho C)                    │
│  install-global-patches.sh aplica 13 patches idempotentes   │
│  Detecta marcadores únicos antes de aplicar                 │
└─────────────────────────────────────────────────────────────┘
                            ↓ sobrescreve com nossa adição
┌─────────────────────────────────────────────────────────────┐
│               PROJETO (bundle ideIAos)                      │
│  setup.sh renderiza IDEIAOS.md + docs/ideiaos/* do template│
│  Bundle versioning detecta v1.0 → v1.1 e faz refresh atômico│
└─────────────────────────────────────────────────────────────┘
```

**Princípio:** mudanças sempre nascem nos templates do repo ideIAos e propagam pra cada nível via scripts idempotentes. Nada vive "só na sua máquina" — tudo é reproduzível.

---

## 📁 Estrutura do repositório

```
ideIAos/
├── setup.sh                                ← script principal (global + projeto); flag --global-only
├── setup-dev-machine.sh                    ← bootstrap de máquina nova (clona repos + autosync + setup global)
├── versions.lock                           ← pin de versões (aiox-core/gsd/Suíte/MCPs/plugins)
├── .claude-plugin/
│   └── marketplace.json                    ← marketplace 'ideiaos' (3 plugins: core/design-suite/lovable)
├── plugins/                                ← GERADO por scripts/build-plugins.sh — não editar à mão (edite source/)
│   ├── ideiaos-core/                       ← 15 agents + 13 hooks + 24 skills de workflow
│   ├── ideiaos-design-suite/               ← 10 skills de design (ui-ux-pro-max, design-system, brand…)
│   └── ideiaos-lovable/                    ← skill /lovable-handoff + doutrina + templates
├── scripts/
│   ├── install-alias.sh                    ← Instala alias idea-setup
│   ├── install-git-hooks.sh                ← Instala pre-commit hook
│   ├── check-readme-sync.sh                ← Audita README sync (aponta para source/)
│   ├── check-versions-lock.sh              ← Guarda do pin GSD no versions.lock (anti-revert pré-redux)
│   ├── check-memory-not-on-main.sh          ← Guarda Lovable-safe (v5): memória nunca no main; bloqueia merge planning→main
│   ├── idea-doctor.sh                      ← Diagnóstico saúde + drift (read-only)
│   ├── install-global-patches.sh           ← Overlay ideIAos (Caminho C — 13 patches idempotentes)
│   ├── update-upstream.sh                  ← Detecta updates GSD + AIOX vs versions.lock (--bump re-pina)
│   ├── update-design-suite.sh              ← Atualização controlada da Suíte (re-vendoriza do upstream)
│   ├── sync-all.sh                         ← Orquestrador (pull → upstream → setup --global-only → overlay → doctor)
│   ├── ideiaos-update.sh                   ← Atualização de máquina em 1 comando (sync-all + shell + statusline)
│   ├── build-adapters.sh                   ← Compila source/ → harness targets (claude + cursor)
│   └── build-plugins.sh                    ← Gera plugins/ a partir de source/ (marketplace)
├── source/                                 ← FONTE ÚNICA DE VERDADE (Fase 03+)
│   ├── skills/                             ← 35 skills (24 core incl. /memory-sync + 10 design + 1 lovable)
│   ├── agents/                             ← 15 agents ECC
│   ├── hooks/                              ← 13 hooks de produto (incl. memory-import.sh + memory-export.sh) + 3 test-hooks
│   ├── templates/                          ← templates de projeto (hybrid/ideiaos/lovable/learnings/memory/global-patches)
│   ├── contexts/                           ← contexts de modo (dev.md / review.md / research.md)
│   ├── statusline/                         ← ideiaos-statusline.sh
│   └── rules/
│       ├── common/                         ← token-economy, mcp-hygiene, orchestration
│       ├── supabase/                       ← rls-patterns
│       ├── lovable/                        ← deployment-protocol
│       └── ecc/                            ← rules ECC absorvidas via quarentena (MIT)
│           ├── common/                     ← code-quality, testing, documentation
│           ├── typescript/                 ← typescript strict rules
│           └── react/                      ← hooks rules, component patterns
├── manifests/
│   ├── modules.json                        ← catálogo de 77 módulos (hooks/agents/skills/templates/contexts/statusline/lsp/script) + campo plugin
│   └── plugin-membership.md               ← mapeamento módulo → plugin (fonte de verdade legível)
├── adapters/                               ← artefatos compilados por harness (gerados por build-adapters.sh)
│   ├── _scaffold/                          ← template para novos harnesses (codex, gemini, zed)
│   │   ├── README.md                       ← como criar um novo adapter
│   │   └── adapter.sh.tmpl                 ← template de script de adapter
│   ├── claude/                             ← output dir para build artifacts Claude
│   └── cursor/                             ← output dir para build artifacts Cursor
├── security/
│   ├── scan-absorbed.sh                    ← Pipeline de quarentena obrigatório (unicode/payload/comandos/AgentShield)
│   └── quarantine/                         ← Staging area para conteúdo de terceiros antes do scan
├── docs/
│   ├── IDEIAOS.md                          ← Especificação canônica do ideIAos
│   ├── CONTINUATION_HANDOFF.md
│   └── security/
│       └── memory-hygiene.md               ← Regras de higiene de memória (sem secrets, reset pós-quarentena)
├── evals/                                  ← suíte de regressão (≥20 casos reais) + run-evals.sh
│   ├── run-evals.sh                        ← runner: bash evals/run-evals.sh [--list]
│   ├── cases/                              ← EVAL-*.md (≥20 casos com input/expected/actual)
│   └── README.md                          ← documentação da suíte
├── AGENTS.md                               ← Identidade do ideIAos
├── CLAUDE.md                               ← Instruções Claude para ideIAos
├── STATE.md                                ← Estado do ideIAos
└── README.md                               ← Este arquivo
```

---

## 🆘 Troubleshooting

### "Rodei o setup mas o hook não dispara no Claude Code"

O hook precisa estar registrado em `~/.claude/settings.json`. O setup.sh **não modifica** esse arquivo automaticamente (regra de segurança — IA não pode auto-modificar config).

Snippet pra adicionar manualmente:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash|Write|Edit|MultiEdit",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/extract-learnings-reminder.sh\"",
          "timeout": 5
        }]
      },
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/ideiaos-readme-reminder.sh\"",
          "timeout": 3
        }]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/typecheck-on-edit.sh\"",
          "timeout": 60,
          "async": true,
          "asyncRewake": true
        }]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/console-log-guard.sh\"",
          "timeout": 5
        }]
      }
    ],
    "PreToolUse": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/strategic-compact.sh\"",
          "timeout": 3
        }]
      }
    ],
    "PreCompact": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/precompact-state-save.sh\"",
          "timeout": 10
        }]
      }
    ],
    "Stop": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/session-summary.sh\"",
          "timeout": 30
        }]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/ideiaos-detector.sh\"",
          "timeout": 3
        }]
      }
    ]
  }
}
```

> **Observação A5 (PreCompact):** Se o evento `PreCompact` não disparar, tente a chave `"Compact"` em vez de `"PreCompact"` no `settings.json`.

Depois reinicia o Claude Code.

### "Não recebo a sugestão proativa no Cursor"

A rule `.cursor/rules/agents-md-protocol.mdc` precisa estar no projeto. Confira com:

```bash
ls -la .cursor/rules/agents-md-protocol.mdc
```

Se não existir, roda `@ideiaos-checker` no chat ou `idea-setup` no terminal.

### "Como sei se o setup está completo?"

**Comando direto:** `bash scripts/idea-doctor.sh` — diagnóstico read-only que audita skills, MCPs, os 13 patches, versões vs `versions.lock`, drift, autosync e **Security Audit** (deny rules, hooks perigosos, secrets em memória, pipeline de quarentena). Mostra `OK / WARN / FAIL` por item com a remediação. Ver também: [`docs/security/memory-hygiene.md`](docs/security/memory-hygiene.md).
No Claude Code: `/ideiaos-setup` → mostra ✅/❌ por camada do ideIAos.
No Cursor: `@ideiaos-checker` → idem.

### "Rodei o setup mas faltou skill ou MCP (ex: context7) — parou no meio?"

Quase sempre é um **passo interativo sem terminal** (TTY). Instaladores de terceiros (ex: `aiox-core`) pedem input via prompt; sem TTY eles crasham e, sob `set -e`, abortavam o setup inteiro **antes** de instalar o resto.

- **Já corrigido** no `setup.sh`: o passo do AIOX Core agora é idempotente (pula se instalado), só roda o instalador interativo com TTY (`[ -t 0 ]`) e nunca é fatal.
- **Diagnóstico/correção:** `bash scripts/idea-doctor.sh` (vê o que falta) → `bash scripts/sync-all.sh` (reinstala) → se o `aiox` ainda faltar, rode **num terminal interativo**: `npx aiox-core@latest install`.

> Regra ao escrever qualquer script de setup: instalador de terceiro = **skip-if-installed + guard `[ -t 0 ]` + `|| warn` (não-fatal)**. Teste com `bash setup.sh 2>&1 | cat` (o pipe remove o TTY e revela o bug que o terminal esconde).

### "Posso rodar várias vezes seguidas sem estragar nada?"

Sim. **Idempotência** é design fundamental. Pula tudo que já está instalado, atualiza só o que mudou.

### "OPENROUTER_API_KEY pra que serve?"

Chave opcional que habilita um modelo mais barato (DeepSeek via OpenRouter) para tarefas simples. Crie conta gratuita em [openrouter.ai](https://openrouter.ai) e adicione no `.env` do projeto:

```bash
OPENROUTER_API_KEY=sk-or-...
```

### "Skills /gsd-* não aparecem"

GSD vem com Claude Code via plugins. Se não estão aparecendo:
- Confirme que está usando Claude Code (não Cursor)
- Verifique `~/.claude/skills/gsd-*` existe
- Se não existir, habilite via menu de plugins do Claude Code ou consulte a documentação do plugin GSD

### "Funciona com qualquer stack?"

Sim. Os agentes/skills leem histórico, memória e estado — não dependem de linguagem ou framework.

---

## 📚 Documentação complementar

Os padrões emergentes do trabalho real estão capturados como **learnings** com versão expandida nos repos:

| Learning | Quando aplicar |
|----------|----------------|
| `bug-persists-after-fix-likely-deploy-drift` | Sintoma persiste em produção após fix aparente |
| `schema-first-verification-before-prod-updates` | Antes de UPDATE/INSERT em produção |
| `inline-hotfixes-need-explicit-repo-sync` | Lovable/IA externa corrigiu inline no edge |
| `protocol-discipline-needs-hooks-not-guidelines` | Antes de desenhar protocolo "obrigatório" para IA |
| `idempotency-enables-multi-entry-tooling` | Antes de adicionar segunda forma de invocar ferramenta |

Versões expandidas em `docs/learnings/` de qualquer projeto Lovable do setup. Espelhos em memória Claude global de quem clonou o ideIAos.

### Documentação canônica do ideIAos

- **`docs/IDEIAOS.md`** — especificação completa do sistema (arquitetura, decisões, roadmap)
- **`source/templates/ideiaos/IDEIAOS.md.tmpl`** — manifesto que vai pra raiz de cada projeto
- **`source/templates/ideiaos/GUIDE-HUMANS.md.tmpl`** — guia detalhado para devs
- **`source/templates/ideiaos/GUIDE-AI.md.tmpl`** — instruções operacionais para IAs
- **`source/templates/ideiaos/DECISION-MATRIX.md.tmpl`** — tabela canônica "tarefa → comando"
- **`../mapa-github-ai-dev-tools.md`** — pesquisa de mercado (60+ projetos comparados)

### Revisão v3 (Fase 08 — auditorias de prontidão)

- **`docs/v3/v3-review.md`** — síntese consolidada das 3 auditorias Wave 1 + gaps de orquestração; 15 gaps priorizados (P1/P2/P3) que definem o que v3 deve resolver
- **`docs/v3/v3-roadmap.md`** — fases candidatas v3 derivadas dos gaps priorizados
- **`docs/v3/agents-audit.md`** — auditoria dos 15 agents (model/tools/directedness)
- **`docs/v3/skills-guide.md`** — guia das 34 skills com mapa de redundância
- **`docs/v3/token-economy-review.md`** — matriz modelo×ação + decisões mgrep/LSP

---

## 🤝 Contribuindo

- Cada mudança em template/skill/hook precisa atualizar o setup.sh para idempotência
- Testar com `bash -n setup.sh` (syntax) + smoke test em projeto Lovable de teste
- Atualizar este README quando adicionar componente novo
- Seguir o protocolo Fase A: criar learning se mudança gerar padrão replicável
- Mudanças no ideIAos (arquitetura, camadas, roteamento) também atualizam `docs/IDEIAOS.md`

---

## ❓ Dúvidas rápidas

- **Preciso rodar o setup toda vez que abrir um projeto?** Não. Uma vez instalado, vale pra sempre.
- **E se eu usar Windows?** Use WSL — o setup.sh assume bash/zsh em ambiente Unix-like.
- **Lovable vai sobrescrever meu AGENTS.md?** Não. A camada Lovable usa marcadores `BEGIN/END` para preservar conteúdo customizado.
- **Posso desativar o loop de aprendizado em um projeto?** Sim. Remova a seção `Loop de aprendizado contínuo` do `AGENTS.md` — hooks param de disparar automaticamente.
- **Posso desativar o ideIAos num projeto?** Tecnicamente sim (delete `IDEIAOS.md` e `docs/ideiaos/`), mas você perde o orquestrador. Não recomendado.
- **`/idea` substitui os comandos diretos?** Não — eles continuam funcionando. `/idea` é só um atalho cognitivo. Quem aprende os comandos diretos ganha velocidade.

---

*ideIAos v1.1 · Última atualização: 2026-05-30*
*Mantido por: equipe Ideia Business + IAs (Claude Code, Cursor)*

**Mudanças v1.1 (2026-05-30):** Caminho C — composição AIOX × GSD.
- Deia agora aplica decisão única (2 exceções + 5 critérios) em vez de matriz por categoria.
- Três contratos formais: `--story` em `/gsd-plan-phase`, `--verification` em `@qa *gate`, hook Fase A com 3 gatilhos (commit + qa-gate PASS + verify SUCCESS).
- DECISION-MATRIX refatorado de catálogo (158 linhas) para árvore de decisão (~190 linhas com fluxos compostos).
- **Bundle versioning no setup.sh** — detecção automática de versão template vs instalada, com refresh atômico dos 4 docs ideIAos.
- **3 scripts de manutenção do overlay** — `install-global-patches.sh` (idempotente), `update-upstream.sh` (detecta updates), `sync-all.sh` (orquestrador). Resolvem o problema "patches sobrescritos por updates upstream".
