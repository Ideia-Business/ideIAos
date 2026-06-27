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

# 3. Aplique o overlay (15 patches sobre GSD/AIOX/Claude) e confira a saúde
bash scripts/sync-all.sh         # já roda o idea-doctor no final

# 4. (Opcional) Atalho de terminal
bash scripts/install-alias.sh && source ~/.zshrc   # ou ~/.bashrc
```

> **Máquina nova do zero?** Use o bootstrap: `bash setup-dev-machine.sh` — clona todos os repos da Ideia, configura o autosync (LaunchAgent) **e** roda o setup global do IdeiaOS + overlay automaticamente.
>
> **Manutenção (qualquer dia):** `bash scripts/idea-doctor.sh` (diagnóstico) · `bash scripts/idea-doctor.sh --fleet` (saúde da frota cross-máquina: nome, idade do snapshot, status — agrega o ref `cockpit`) · `bash scripts/sync-all.sh` (atualiza tudo). Veja [Mantendo o ambiente global sincronizado](#-mantendo-o-ambiente-global-sincronizado-caminho-c--v11).

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

> **Visibilidade:** O marketplace lê diretamente do repositório. O repo `Ideia-Business/ideIAos` é **público** no GitHub, então a **Opção A** (via slug GitHub) é a padrão. A **Opção B** (path local) segue válida para quem já tem o clone na máquina: `claude plugin marketplace add /caminho/para/IdeiaOS`.

```bash
# Adicionar o marketplace ideIAos (uma vez)
# Opção A — via GitHub (repo público; padrão):
claude plugin marketplace add Ideia-Business/ideIAos
# Opção B — via path local (clone já na máquina):
claude plugin marketplace add /caminho/para/IdeiaOS

# Instalar o núcleo (sempre — orquestrador, agents, hooks, skills de workflow)
claude plugin install ideiaos-core@ideiaos

# Instalar a Suíte de Design (perfil UI/design)
claude plugin install ideiaos-design-suite@ideiaos

# Instalar a camada Lovable (projetos Lovable)
claude plugin install ideiaos-lovable@ideiaos

# Instalar a camada de Marketing (produção de conteúdo)
claude plugin install ideiaos-marketing@ideiaos
```

| Plugin | Versão | Conteúdo | Quando instalar |
|--------|--------|----------|-----------------|
| `ideiaos-core` | 3.0.0 | 15 agents + 11 hooks + 31 skills (idea, tdd, evolve, instincts, memory-sync, spec, doubt, grelha, tool-output-compressor…) | Sempre — núcleo do sistema |
| `ideiaos-design-suite` | 3.0.0 | 10 skills de design (ui-ux-pro-max, design-system, brand…) | Quem faz UI/design |
| `ideiaos-lovable` | 3.0.0 | Skills `/lovable-handoff` + `/lovable-mcp` (verificação read-only via MCP) + doutrina de deploy + templates | Projetos Lovable |
| `ideiaos-marketing` | 3.0.0 | 2 skills (`/marketing` + `/marketing-research`) + 4 agents (mkt-estrategista/copywriter/designer/revisor) + 22 best-practices (OpenSquad MIT) | Quem produz conteúdo de marketing |

> **Plugin e setup.sh são complementares** — não excludentes. O plugin entrega skills/agents/hooks versionados com atualização nativa (`claude plugin update`). O `setup.sh` entrega o ambiente de máquina completo: working-dirs, autosync (LaunchAgent), vault Obsidian, git hooks e config de projeto. Para uma máquina nova do zero, use o setup.sh (ou o bootstrap `setup-dev-machine.sh`) — ele faz tudo em sequência.

---

## 🍎 Instalação em máquina nova (completa)

Fluxo de ponta a ponta pra um Mac do zero. O bootstrap faz o grosso; só GSD fica manual.

> 👋 **Dev novo no time?** Há um runbook cirúrgico passo a passo (acessos, autenticação,
> bootstrap, 1ª sessão, branches/autosync, troubleshooting) em
> **[`docs/guides/onboarding-novo-dev.md`](docs/guides/onboarding-novo-dev.md)** — siga por lá.
> A seção abaixo é o resumo técnico do mesmo fluxo.
>
> 🪟🐧 **Windows ou Linux?** Esta seção (e o `setup-dev-machine.sh`) é o caminho **macOS/mantenedor**.
> Um **dev-consumidor** (trabalha nos projetos, não no próprio ideIAos) precisa de muito pouco —
> **Claude Code + git + Node + os plugins** (`claude plugin install ideiaos-core@ideiaos`); a config
> dos projetos já vem no `git clone`. No **Windows** há **2 caminhos** — nativo + Git Bash (⚗️
> consumidor) ou **WSL2** (✅ garantido) — em **[`docs/guides/windows-wsl.md`](docs/guides/windows-wsl.md)**.
> No **Linux**, o Caminho B a partir do Passo 1. (Autosync via cron/Task Scheduler, não `launchd`.)
>
> 📑 **Índice de todos os guias de instalação** (qual doc cobre cada SO/assunto, sem cópias
> paralelas): **[`docs/guides/README.md`](docs/guides/README.md)**.

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
- `sync-all.sh` → aplica os **15 patches** do overlay + roda `idea-doctor`

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
| AIOX-core (instalado — alvo do overlay) | `~/dev/.aiox-core/` (cópia **debug/instalada** — recebe os 15 patches do `install-global-patches.sh`; ≠ vendor PRISTINE do repo) |
| Autosync (LaunchAgent) | `~/Library/LaunchAgents/com.ideiaos.gitautosync.plist` |

> ⚠️ **Não auto-instalado:** pré-requisitos (passo 1) e o **plugin GSD** (passo 4, interativo do Claude Code).

> ℹ️ **Por que há 3 cópias do `.aiox-core` (desambiguação, não duplicação):** são 3 papéis LEGÍTIMOS e distintos —
> (1) **vendor PRISTINE** no repo (`~/dev/IdeiaOS/.aiox-core`): cópia local **ignorada pelo git** (`.gitignore`),
> nunca editada direto; (2) **debug/instalado** (`~/dev/.aiox-core`): alvo do overlay `install-global-patches.sh`,
> que aplica os 15 patches aqui (mutável); (3) **runtime npm-global** (`npx aiox-core`, binário CLI `aiox-core@5.x`).
> É **DESAMBIGUAÇÃO por papel, não unificação** — cada cópia existe por uma razão diferente.

---

## 🎯 O que este setup instala

### Componentes globais (uma vez, vale pra qualquer projeto)

| Componente | Onde | Para quê |
|------------|------|----------|
| **AIOX Core** | npm global via `npx aiox-core` (**runtime npm-global**; binário CLI `aiox-core@5.x`) | Orquestrador de agentes IA — base do AIOX |
| **GSD skills** | `~/.claude/skills/gsd-*` | Suite com 60+ comandos GSD (vem com Claude Code via plugins) |
| **Skill Claude `/idea`** | `~/.claude/skills/idea/` | **Orquestrador ideIAos** — comando único de entrada |
| **Skill Claude `/ideiaos-setup`** | `~/.claude/skills/ideiaos-setup/` | Audita + completa setup do projeto |
| **Skill Claude `/cursor-continuation`** | `~/.claude/skills/cursor-continuation/` | Retoma no Claude Code o trabalho do Cursor |
| **Skill Claude `/lovable-handoff`** | `~/.claude/skills/lovable-handoff/` | Playbook de implantação Lovable |
| **Skill Claude `/lovable-mcp`** | `~/.claude/skills/lovable-mcp/` | Verificação read-only via MCP Lovable (deploy-drift + hotfix) |
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
| **Hook Claude `instinct-recover.sh`** | `~/.claude/hooks/` | SessionStart (v6) — detecta breadcrumbs órfãos do spawn de `/instinct-analyze` após crash; re-spawna exatamente uma vez (gate de pid + idade + cooldown 30min); fail-silent (exit 0 sempre) |
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

### Agents de Marketing (Fase 26 — source/agents/mkt-*.md)

4 agents da Camada de Marketing — recrutados e orquestrados pelo `/marketing` (Plano 26-03):

| Agent | Modelo | Quando usar |
|-------|--------|-------------|
| `mkt-estrategista` | opus | Definir ângulos, big idea, posicionamento e calendário editorial |
| `mkt-copywriter` | sonnet | Produzir copy por formato com protocolo hook-first (3 hooks → body → CTA) |
| `mkt-designer` | sonnet | Criar peças visuais reusando a Suite de Design IdeiaOS (banner-design/slides/ui-ux-pro-max) |
| `mkt-designer` | sonnet | Criar peças visuais reusando a Suite de Design IdeiaOS (banner-design/slides/ui-ux-pro-max) |
| `mkt-revisor` | sonnet | Scoring + veto APROVADO/REJEITADO com feedback acionável |

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

### Skills de Marketing (Fase 26 — source/skills/marketing-research/)

| Skill | installStrategy | Descrição |
|-------|-----------------|-----------|
| `/marketing-research` | always | Investigar perfis públicos de referência via Chrome DevTools MCP e extrair padrões reais (hooks, estrutura, cadência, CTAs) |

### Skills v6 — Resiliência, Spec e Forge (Fases 25/30)

| Skill | installStrategy | Descrição |
|-------|-----------------|-----------|
| `/forge-agent` | always | Fundamenta a criação de agents e skills em pesquisa real do domínio antes de produzir spec — cita fontes verificáveis, lista anti-patterns derivados de pesquisa, justifica model routing com racional documentado. 4 fases: definir domínio → pesquisa (`/deep-research`, máx 3 ciclos) → model routing → spec grounded. |
| `/spec` | always | Delta-spec brownfield — mantém contratos de comportamento vivos de produto por capability em `specs/<capability>/spec.md`. Fluxo: propose → spec/delta → tasks → merge+archive. **Subcomandos de auditoria (v11):** `--analyze` (gate determinístico da spec viva pós-merge) e `--converge` (ponte append-only spec↔código). Complementar ao GSD (spec = contrato; GSD = implementação). Adaptado do OpenSpec MIT. |
| `/tool-output-compressor` | always | Comprime saídas de ferramenta volumosas (logs, JSON tabular) ANTES de entrarem no contexto — local, determinístico, reversível (CCR via store keyed por sha256), CLI-First, sem rede/dep. NUNCA toca mensagem do usuário; fail-open; verificação por exit-code. Padrão minerado de headroom (Apache-2.0); a dependência NÃO foi adotada. Contrato vivo em `specs/tool-output-compressor/`. |

### Skills v8 — Camada de Disciplina (absorvida de agent-skills MIT, addyosmani)

| Skill | installStrategy | Descrição |
|-------|-----------------|-----------|
| `/doubt` | always | Doubt-Driven Development — revisor adversarial de contexto-fresco EM-VOO (spawn de subagente) antes de uma decisão não-trivial valer. Complementa `/code-review` (pós-PR). 5 passos: CLAIM→EXTRACT→DOUBT→RECONCILE→STOP. |
| `/context-engineering` | always | Engenharia de contexto — informação certa, na hora certa (hierarquia de 5 níveis, brain dump, selective include, <2k linhas/tarefa). Operacionaliza token-economy/orchestration/handoffs. |
| `/grelha` | always | Grilling colaborativo PRÉ-plano (alias `/grill`) — me entrevista 1 pergunta por vez com resposta recomendada, lê o código quando dá; modos `--docs` (afia contra o glossário `CONTEXT.md`) e `--rapido` (não-código). Simétrico ao `/doubt` (adversarial). Produz alinhamento + glossário de linguagem ubíqua (v9). |
| `/improve-architecture` | always | Ritual recorrente de deepening (alias `/aprofundar`) — busca módulos rasos→profundos (Ousterhout) via deletion test, falado no vocabulário do `CONTEXT.md` + glossário de arquitetura; relatório HTML em tmp; grilling loop reusando ADR inline. Complementa `refactor-cleaner`/`code-simplifier` (limpeza pontual) com saúde de design contínua (v9). |
| `/observability` | manual (opt-in) | Observabilidade & instrumentação — log estruturado + correlation ID, RED/USE metrics, OpenTelemetry, alertas em sintomas. |
| `/deprecation-migration` | manual (opt-in) | Deprecação & migração — remover sistemas antigos e migrar usuários com segurança (strangler/adapter/feature-flag, código zumbi). |

> Camada de disciplina comportamental: também adiciona a rule sempre-on `operating-discipline` (6 condutas de base) e a convenção de autoria anti-racionalização (`source/templates/skill/SKILL.md.tmpl`).

### Manutenção do próprio ideIAos (rodados manualmente)

| Script | O que faz |
|--------|-----------|
| `scripts/install-alias.sh` | Adiciona alias `idea-setup` ao seu shell rc (zsh/bash) |
| `scripts/install-git-hooks.sh` | Instala pre-commit (README sync + versions.lock) + post-merge (propagação automática) + pre-merge-commit (guarda memória) |
| `scripts/check-readme-sync.sh` | Audita se README menciona todos os componentes do repo |
| `scripts/validate-agent-yaml.sh` | Valida o bloco YAML embutido dos agentes AIOX com o parser **autoritativo** (js-yaml do aiox-core → ruby/psych → python3+yaml; skip gracioso se nenhum). Consumido pelo `idea-doctor` (gate read-only) e pelo Patch 14 do overlay (auto-validação + rollback após inserção) |
| **`scripts/check-versions-lock.sh`** | **Guarda do pin GSD** — bloqueia valor pré-redux (1.3x/1.4x) e edição manual do `gsd=` que não corresponda à versão instalada (único escritor: `update-upstream.sh --bump`; bypass: `IDEIAOS_LOCK_OVERRIDE=1`). Roda no pre-commit. |
| **`scripts/check-memory-not-on-main.sh`** | **Guarda Lovable-safe da memória (v5)** — bloqueia qualquer caminho de memória (`.planning/memory/`, `.lovable_mem_tmp.md`, `.cursor/rules/memory-bridge.mdc`) staged no branch `main` e o merge `planning`→`main`; mensagem direcional (diz qual lado está errado); bypass consciente: `IDEIAOS_MEM_OVERRIDE=1`. Modos `--staged` (pre-commit) e `--merge` (pre-merge-commit). |
| **`scripts/check-plugin-membership.sh`** | **Guarda anti-deriva de plugins (v7)** — bloqueia commit que toque `manifests/modules.json`, `manifests/plugin-membership.md` ou `scripts/build-plugins.sh` se houver deriva entre as atribuições `plugin:` do manifesto e os arrays do `build-plugins.sh` (o bug que deixou `spec`/`forge-agent`/`memory-sync` fora do empacotamento). Roda no pre-commit e no `idea-doctor` (seção 10). |
| **`scripts/check-source-headers.sh`** | **Guarda de proveniência das skills (v11, ADVISORY)** — toda `source/skills/*/SKILL.md` deve declarar origem com uma linha `# SOURCE:` após o frontmatter (absorvida: upstream+licença; nativa: `IdeiaOS`). As 7 skills vendorizadas da Suíte de Design são OK-via-pin (`source/skills/.design-suite-version`), pois o `cp -R` do `update-design-suite.sh` apagaria header inline — a lista vendorizada é derivada da linha `SUITE=` do próprio script (sem duplicação). WARN por padrão; `--strict` falha se faltar. Roda no CI (anotação non-blocking) e no `idea-doctor` (seção 11). |
| **`scripts/check-soak.sh`** | **SOAK gate de fechamento de milestone (v11)** — nenhum milestone tagueado até passar `idea-doctor` (0 FAIL) + regressão estrutural em **≥2 máquinas** por **≥1 dia**. `--record` roda os gates e grava heartbeat em `.planning/soak/<milestone>.log`; o verify (default) só dá exit 0 quando o soak satisfaz a política (`SOAK_MIN_MACHINES`/`SOAK_MIN_DAYS`). Barreira contra "verificação point-in-time numa única máquina". Doc: [`docs/process/soak-gate.md`](docs/process/soak-gate.md). |
| **`scripts/refresh-ai-security.sh`** | **Refresh mensal de AI-security intel (v12)** — recheca `github.com/muellerberndt/awesome-ai-security` 1×/mês (`curl`+`diff`+`sha256`, **nunca executa o conteúdo baixado**), compara com snapshot versionado em `security/intel/` e reporta as novidades. Idempotente (hash-gated); `--accept` promove o snapshot revisado. Anti-injection: 1 host pinado, sem `clone`/`exec`/follow-de-link. Agendável via launchd (`infra/launchd/com.ideiaos.refresh-ai-security.plist`, per-máquina, mensal). Check ADVISORY no `idea-doctor` §13. Spec: [`MONTHLY-REFRESH-SPEC.md`](docs/research/2026-06-19-qa-security-arsenal/MONTHLY-REFRESH-SPEC.md). |
| **`scripts/check-security-freshness.sh`** | **Selo de Frescor de Segurança (v13)** — segurança verificada periodicamente e por sistema, não só sob demanda. Padrão SOAK aplicado a dívida de segurança: gatilho **determinístico** risk-weighted (`git diff`+path-globs+idade → tier) → revisão `@security-reviewer` → re-selo (`--record`) em `.security/review-ledger.log`. **Nunca gateia PR de feature**; `--gate` trava só o `git tag` do IdeiaOS no tier egrégio (1º ciclo advisory via `SECFRESH_GATE_ENABLED`); WARN nos Lovable via `idea-doctor §14`. Bootstrap (`--bootstrap`) evita "dia-1 vermelho". **Surfacing por produto** (opção C): `setup.sh --project-only` instala um hook **`post-commit` advisory** (`SECFRESH_ROOT` → 1 engine audita qualquer repo; husky-aware; `.git/info/exclude` → local-only, zero footprint versionado) que avisa quando o frescor está defasado sem nunca bloquear commit/deploy. Rule: [`security-freshness`](source/rules/common/security-freshness.md) · ADR: [`v13`](docs/decisions/v13-security-freshness-gate.md). |
| **`scripts/remind-closeout-gates.sh`** | **Lembrete dos gates de fechamento (v15, R15-11)** — NOTIFICA (nunca carimba): ff-merge `work→main` pendente, selo SOAK velho de milestone ATIVO (sem tag) e frescor de segurança defasado (`--tier`). Gatilho temporal **determinístico** (idade > N h por epoch, não "há mais de uma sessão"). Só lê + `osascript`; jamais executa `--record`/`--gate` — o humano carimba (`automate-the-reminder-not-the-integrity-stamp`). Agendável via launchd (`infra/launchd/com.ideiaos.closeout-reminder.plist`, 1×/dia 19h). Exit 0 sempre. |
| **`scripts/ttt-baseline.sh`** | **Harness Time-to-Truth baseline (v14)** — cronometra as 3 jornadas J1/J4/J2 via terminal e anexa ao TSV `~/.ideiaos/console/ttt-baseline.tsv` (`jornada\tmodo\tsegundos\tepoch`). Satisfaz A1 da spec cockpit: baseline terminal N≥5 por jornada, antes da Bridge. Aceita `--mode=bridge --dry-run` como estrutura para v14.1 (sem exigir Bridge). Gate: `assert_nonempty` do TSV (build script: `exit 1`). |
| **`scripts/ttt-median.sh`** | **Mediana Time-to-Truth por jornada (v14)** — lê o TSV de baseline, agrupa por jornada (J1/J4/J2), ordena os segundos via `sort -n` e imprime a mediana em bash puro (sem dependências externas). N ímpar: linha do meio `(N+1)/2`; N par: linha inferior `N/2` (determinista). Saída: 3 linhas `J1/J4/J2 <mediana>`. Registra o baseline que a v14.1 vai bater (meta <10s pós-Bridge). |
| **`scripts/check-cockpit.sh`** | **Gate de fechamento do Cockpit (v14.0)** — 3 checks por exit-code: (a) agentd `com.ideiaos.cockpit` ativo no launchctl; (b) `refs/heads/cockpit` existe neste repo; (c) snapshot da máquina local dentro de 2 ciclos (2×900s). Exit 0=saudável, 1=falhou. Build script (não hook). Os mesmos 3 checks são expostos como `idea-doctor §15 "Cockpit"` — consumível via `--json` (section id==15). |
| **`scripts/cockpit-up.sh`** | **Launcher único do Cockpit (v15, DX)** — sobe a API `read.js` (loopback 3073) + o SPA Vite (5273) + abre o browser com **1 comando**; `Ctrl-C` derruba os dois (trap, sem órfãos). Best-effort `ingest` antes (read-model fresco). Local-first, sem login, zero mutação de produção. `--no-open` pula o browser. |
| **`scripts/test-cockpit-alerts.sh`** | **Gate do endpoint `/alerts` (Atalaia, v15 · doc 77)** — seeda um read-model TEMPORÁRIO (`COCKPIT_DB`) com estado conhecido, sobe o `read.js` em porta de teste, curla `/alerts` e assere os 11 gatilhos determinísticos A1–A11 (A5/A7/A9/A10/A11 ativos; A1/A2/A6/A8 `no-data` honesto). Não toca o read-model real. Build script (não hook). |
| **`scripts/test-recorder.sh`** | **Gate A12 do Flight Recorder v0 (v14.1)** — re-deriva a fita do pin `gsd` em `versions.lock` do git LOCAL (num `/tmp` sandbox, autosync pausado) e compara SET-to-SET `{hash8\|gsd}` contra `apps/cockpit/src/flight-recorder.json`: exit 0 se idêntico, exit 1 se a UI divergiu; exige ≥1 nó de reversão (âmbar). Anti-teatro: `FR_JSON=<copy>` aponta a uma cópia mutada e DEVE dar exit 1. Build script (não hook). Exposto como `npm run test:recorder` em `apps/cockpit`. |
| **`scripts/test-zeroleak.sh`** | **Gate Zero-Leak (R14-06, A3 — P0 de release, v14.1)** — varre 7 superfícies do Cockpit (S1 snapshot do ref · S2 `read-model.db .dump` · S3 schema PRAGMA · S4 estado React serializado · S5 DOM renderizado via `vite build`+`dist/` em loopback · S6 corpos de rede loopback **incluindo o body de `POST /command`** · S7 logs), cada uma **materializada em arquivo** antes do scan por exit-code (nunca o Read tool). Detector de 2 camadas (`source/agentd/zeroleak-snapshot.sh`): regex de chave literal + **entropia de Shannon ≥4.0** com allowlist por nome/shape (machine_id, input_hash, SHAs, URLs — nunca por valor). Prova estrutural positiva S3 (api_key SEM coluna `value`). **Dogfood-veneno TRIPLO** (sk-ant-FAKEKEY na camada regex + token de alta-entropia na camada b + veneno de superfície-runtime no body de `/command`) DEVE reprovar — senão o gate é teatro. S6 usa só o verbo `run_doctor` (read-only). Build script (não hook). Exposto como `npm run test:zeroleak` em `apps/cockpit`. |
| **`scripts/test-writepath-bootstrap.sh`** | **Gate de bootstrap do write-path (v14.4 · F0a)** — prova por exit-code, fail-closed, o mecanismo O2 (assinatura por-máquina + lista pinada autoritativa-local) + step-up (comprovante Ed25519 assinado + token O2 de uso único): **47 casos** B0–B4 com manifesto fixo, exit-code+REASON específicos por veneno, **canário** (detecta mecanismo quebrado, não só ausente), gate-negativo (sem egress/provedor em `source/agentd/*.sh`) e nonce **durável cross-processo**. Verifica a autenticidade do comprovante **ANTES** do binding (fecha confused-deputy), o subject vem do aprovador-do-OTP (não do chamador), e o OTP nunca toca o disco. ZERO mutação de produção/cross-máquina/chamada a provedor. Build script (não hook): exit 1 em falha. Scaffold do backend dedicado em `source/agentd/stepup/` (deploy = F0b, ação humana gated). |
| **`scripts/test-writepath-substrate.sh`** | **Gate do SUBSTRATO LOCAL do write-path (v14.4 · B5–B8)** — irmão do bootstrap; prova por exit-code o substrato LOCAL que o ADR Q5 (ACEITO) permite construir cripto-local, INDEPENDENTE do seal e do push ao origin (gated no owner): **B5** `source/agentd/cmd-ref.sh` (ref OPACO `refs/ideiaos/cmd` por plumbing puro, ISOLADO do working tree — o `git add -A` do autosync não o captura) · **B6** `ledger.sh` (hash-chained append-only + **âncora-de-cauda** `HEAD-file` que fecha a cegueira-na-cauda + append atômico via lock-por-dir + O_APPEND) · **B7** `ack.sh` (ACK idempotente durável cross-processo + high-water mark) · **B8** `rate-limit.sh` (throttle determinístico por ref+subject, fail-closed, nega-nunca-concede) · **SEAL** `source/agentd/{seal,unseal}.mjs` (**sealed-box X25519 nativo do `node:crypto`** — `age` dispensado, native-first; `assina(P)→sela(P‖sig)`, destinatário **dentro do ciphertext**, seal-then-sign recusado por construção) + **B0-bis** (`enc_pubkey` no pin, retrocompat). Roda os **5** testes standalone (cada um com manifesto+canário+mutação) + meta-canário + gate-negativo (`.sh` **e** `.mjs`). ZERO segredo/produção/provedor. **R-WP10 segue FECHADO** (substrato local ≠ feature cross-máquina). |
| **`scripts/idea-doctor.sh`** | Diagnóstico read-only: skills, MCPs, 15 patches, versões vs `versions.lock`, drift, autosync, **Seção 7 Security Audit** (deny rules, hooks, secrets, quarentena, **7e contenção Lovable MCP** — deny=19 por produto, anti-regressão), **Seção 8 Contexts** (~/.ideiaos/contexts/, funções claude-dev/review/research, statusline), **Seção 9 Memória v5** (planning, store shared/, patches 12/13) |
| **`scripts/install-global-patches.sh`** | Aplica overlay ideIAos (Caminho C) sobre GSD/AIOX/Claude — idempotente, 15 patches (incl. Patch 11: backlog-sync-check, Patches 12/13: memória v5) |
| **`security/scan-absorbed.sh`** | **Pipeline de quarentena obrigatório** — escaneia o conteúdo de terceiros na pasta de quarentena (`security/quarantine/`), **não** `source/`: unicode invisível/payloads/comandos + AgentShield. Só após PASS o material é absorvido para `source/`. Exit 1 = bloqueado. |
| **`scripts/update-upstream.sh`** | Detecta updates do GSD plugin e AIOX-core vs `versions.lock`; `--bump` re-pina |
| **`scripts/update-design-suite.sh`** | Atualização CONTROLADA da Suíte de Design (re-vendoriza do nextlevelbuilder, mostra diff, sob demanda) |
| **`scripts/sync-all.sh`** | Orquestrador — `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| **`scripts/apply-to-all-projects.sh`** | Propaga `setup.sh --project-only` a todos os repos `~/dev/*`. Dry-run por padrão; use `--apply` para executar. `--only proj1,proj2` para filtrar. |
| **`scripts/export-env-dev.sh`** | Extrai o `.env` **mínimo de dev** (least-privilege) por projeto, para entregar a um dev novo por **canal seguro**. Omite `SERVICE_ROLE_KEY` + tokens de deploy. `--list`/`--keys-only` não tocam valores. Read-only. Ver `docs/guides/env-setup-dev.md`. |
| **`scripts/check-env-not-tracked.sh`** | Gate anti-segredo-no-git: **falha (exit 1) só se um `.env` versionado contém chave secreta** (`service_role`/`api_key`/`token`/`password`); config/público (`VITE_`/`anon`/`publishable`) e fixtures de teste (`.env.test`/`.e2e`) = WARN, não falha. Read-only, **nunca lê valores**. `IDEIAOS_ENV_GATE_SKIP` pula forks de terceiros. |
| **`scripts/idea-smoke.sh`** | Smoke-test **puro-bash** (sem python3, sem `.env`) do bootstrap mínimo — prova por exit-code que plugins/hooks/comandos básicos estão de pé, mesmo no ambiente meio-instalado (Windows nativo) onde o `idea-doctor` degrada. Default = build (exit 1 em falha); `--hook` = exit 0 sempre. Fronteira: smoke = "bootstrap mínimo OK?"; doctor = "saúde profunda". (v15 R15-03) |
| **`scripts/check-alias-map.sh`** | Gate que **cruza chave×MID**: para cada `machine_id` real do ref `cockpit`, prova que `source/console/machine-aliases.json` resolve um **nome legível** (não o sha256 cru) — a Frota mostra nome, não hash. `test -s` não basta (o defeito é de chave que não casa). Máquina-nova-não-curada = WARN; valor==sha256 ou zero-resolve = FAIL (exit 1). Espelha `resolveAlias` (ingest.js:60). (v15 R15-07) |
| **`scripts/propagate-if-changed.sh`** | Propagação **automática** — após pull no IdeiaOS, detecta diff em templates/skills/setup e roda global + `apply-to-all --apply`. Gatilhos: `git-autosync`, `post-merge` hook, `sync-all.sh`. Log: `~/.local/state/propagate-projects.log`. |
| **`scripts/ideiaos-update.sh`** | **Atualização de máquina em 1 comando** — sync-all + guardas do git-autosync (versions.lock fora do add -A; **pause-file + conflict-marker**, step 2d) + funções claude-dev/review/research no shell + statusline no settings.json (idempotente, com backup; edita config do usuário por consentimento explícito — diferente do setup.sh/T-01-10). **Patchers in-place do daemon (2/2b/2c/2d) deprecados (R15-19)** — redundantes com o redeploy canônico (step 2e). |
| **`scripts/idea-update.sh`** | **`idea update` — comando único canônico (R15-19)** que reconcilia HOOKS + OVERLAY + DAEMON numa passada, usando SEMPRE o redeploy **canônico** do daemon (`source/lib/redeploy-daemon.sh`, cp-da-fonte que cura qualquer drift), nunca patch in-place. Build-contract: exit 1 se etapa crítica falhar. |
| **`scripts/autosync-pause.sh`** | **Pausa/retoma o git-autosync de forma codificada** (`on`/`off`/`status`) — substitui o `launchctl bootout`/`bootstrap` manual por um pause-file que o autosync respeita; usar durante cirurgia git/infra de IA. O autosync também aborta auto-commit de árvore com conflict markers (`git diff --check`). |
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

### 🖥️ Cockpit — console web local-first (v14.1 MVP Bridge)

Visão de CTO sobre o substrato auto-telemetrado do IdeiaOS. **100% local-first** (loopback-only, zero nuvem); o `git` é o barramento (ref `cockpit`).

```bash
cd apps/cockpit
node server/read.js        # API loopback de leitura — 127.0.0.1:3073 (node:sqlite, zero deps)
npm run dev                # SPA Vite — http://127.0.0.1:5273  (Vite 7 + React 18 + Tailwind + shadcn/ui)
```

**3 telas:**
- **Overview** — System Pulse (frescor + nº de nós), stat-cards (máquinas/projetos/checks), Releases-SOAK (`aguardando segundo ator` até ≥2 máquinas + span ≥1d) e o **Flight Recorder** (fita de dois níveis do pin `gsd` em `versions.lock`, com nós de reversão em âmbar).
- **Frota** — heartbeat por máquina + **version-drift por igualdade-de-string** (nunca semver — `1.1.0 redux > 1.36.0` é uma armadilha de semver que aqui não existe).
- **Cofre-Espelho** — matriz `var × project` **metadata-only**: nome, presença, idade e classe de risco. **O valor de um segredo jamais transita por aqui** (doutrina `credential-isolation`).

**⌘K — paleta de comandos (allowlist fechada B1–B6, default-deny):** `pause_autosync` (B1) · `resume_autosync` (B2) · `reseal_security` (B3) · `force_sync` (B4) · `kickstart_daemon` (B5) · `run_doctor` (B6). Verbos `arm` (B1/B3) exigem **armar-antes-de-disparar** (`Confirmar?`). **Nenhum verbo de mutação-de-produção** (rotate/deploy/revoke/`git push`/`gh pr`) está no allowlist — `agent-authority` continua valendo.

**Segurança do canal `POST /command`** (único endpoint de mutação, fail-closed): bind loopback `127.0.0.1`; **Origin + Host** validados server-side (anti-CSRF/DNS-rebinding — CORS não é a defesa); **token efêmero por-boot** em `X-Cockpit-Token` (obtido via `GET /command-token`, Origin-gated); body com cap 4KB + `JSON.parse` guardado; **preflight CORS** (`OPTIONS /command` → 204 só p/ origem confiável, 403 caso contrário); **stdout varrido pelo Zero-Leak** antes de voltar à UI.

**Gates (exit-code é lei):** `npm run test:zeroleak` (A3 — 7 superfícies + veneno triplo) · `npm run test:recorder` (A12 — re-deriva a fita do git) · `bash scripts/check-cockpit.sh` (agentd + ref + frescor) · `bash scripts/ttt-median.sh --mode=bridge` (A2 — Time-to-Truth <10s) · `idea-doctor §15` (read-model real).

---

### 🧭 Alinhar antes de executar (camada v9)

- **`/grelha`** (alias `/grill`) — use **antes de planejar** uma feature ambígua ou arriscada: a IA te entrevista 1 pergunta por vez (com resposta recomendada), lê o código quando dá, e monta o **glossário de linguagem ubíqua** (`CONTEXT.md`). A Deia oferece o `/grelha` no **Passo 1.5** quando detecta um pedido que merece alinhamento antes do plano.
- **`/improve-architecture`** (alias `/aprofundar`) — **ritual recorrente de saúde de design**: rode a cada poucos dias ou ao fim de um ciclo de feature para achar módulos rasos→profundos (deletion test), com relatório HTML e grilling loop.

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
├── skills/                     (catálogo — 101 módulos)
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

### Os 15 patches do overlay ideIAos

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
| 14 | `.aiox-core/.../agents/pm.md` | **delta `to-prd`** (v9 Fase G, de `mattpocock/skills` MIT): core_principle no @pm/Morgan — "síntese > entrevista" (sintetizar o PRD do contexto já conhecido em vez de re-entrevistar) + quiz curto de seams/módulos (lente `/aprofundar`) registrado como restrição de design |
| 15 | `~/.claude/skills/gsd-debug/SKILL.md` | **nota de seam** (v9 Fase G, do `diagnose` de `mattpocock/skills` MIT): se não há *seam* de teste correto para isolar o bug, isso **é O achado** → sinaliza problema de arquitetura → handoff p/ `/aprofundar`/@architect (não substitui o `/gsd-debug`, complementa) |

### Scripts de manutenção + lockfile

| Comando | Quando usar |
|---------|-------------|
| `bash scripts/idea-doctor.sh` | **SEMPRE PRIMEIRO** — diagnóstico read-only: skills, MCPs, 15 patches, versões vs lock, drift, autosync, **Security Audit** (Seção 7), **Memória v5** (Seção 9). Não muda nada. |
| `bash scripts/sync-all.sh` | **O DE SEMPRE** — atualiza tudo: `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| `bash scripts/install-global-patches.sh` | só re-aplicar o overlay (15 patches, incl. deny rules + backlog-sync-check + memória v5 import/export) — idempotente, roda 100x |
| `bash scripts/update-upstream.sh` | checar updates de GSD/AIOX vs `versions.lock`. `--bump` re-pina o lock no instalado |
| `bash scripts/update-design-suite.sh` | atualizar a Suíte de Design do upstream (controlado, mostra diff, **sob demanda**) |
| `bash scripts/apply-to-all-projects.sh` | propagar `setup.sh --project-only` a todos os repos `~/dev/*` — dry-run por padrão; `--apply` executa; `--only proj1,proj2` filtra |
| `bash scripts/propagate-if-changed.sh` | propagação automática pós-pull (global + projetos) — `--dry-run` preview; `--force` ignora filtro de paths; roda sozinho via autosync/post-merge/sync-all |
| `bash scripts/install-git-hooks.sh` | instala pre-commit + post-merge (propagação) + pre-merge-commit (memória) |

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
│  install-global-patches.sh aplica 15 patches idempotentes   │
│  Detecta marcadores únicos antes de aplicar                 │
└─────────────────────────────────────────────────────────────┘
                            ↓ sobrescreve com nossa adição
┌─────────────────────────────────────────────────────────────┐
│               PROJETO (bundle ideIAos)                      │
│  setup.sh renderiza IDEIAOS.md + docs/ideiaos/* do template│
│  Bundle versioning detecta v1.0 → v1.1 e faz refresh atômico│
└─────────────────────────────────────────────────────────────┘
```

> ℹ️ **Sobre `Projects/.aiox-core/` na árvore acima:** é a cópia **instalada via npm upstream** (vanilla), onde o overlay
> aplica os patches. NÃO confundir com o `.aiox-core` do REPO (`~/dev/IdeiaOS/.aiox-core`), que é **vendor PRISTINE** —
> cópia local **ignorada pelo git** (`.gitignore`), nunca editada direto; deltas só via overlay na cópia instalada.

**Princípio:** mudanças sempre nascem nos templates do repo ideIAos e propagam pra cada nível via scripts idempotentes. Nada vive "só na sua máquina" — tudo é reproduzível.

---

## 📁 Estrutura do repositório

```
ideIAos/
├── setup.sh                                ← script principal (global + projeto); flag --global-only
├── setup-dev-machine.sh                    ← bootstrap de máquina nova (clona repos + autosync + setup global)
├── versions.lock                           ← pin de versões (aiox-core/gsd/Suíte/MCPs/plugins)
├── .claude-plugin/
│   └── marketplace.json                    ← marketplace 'ideiaos' (4 plugins: core/design-suite/lovable/marketing)
├── plugins/                                ← GERADO por scripts/build-plugins.sh — não editar à mão (edite source/)
│   ├── ideiaos-core/                       ← 15 agents + 11 hooks + 31 skills de workflow
│   ├── ideiaos-design-suite/               ← 10 skills de design (ui-ux-pro-max, design-system, brand…)
│   ├── ideiaos-lovable/                    ← skills /lovable-handoff + /lovable-mcp + doutrina + templates
│   └── ideiaos-marketing/                  ← 2 skills (/marketing + /marketing-research) + 4 agents mkt-* + 22 best-practices
├── scripts/
│   ├── install-alias.sh                    ← Instala alias idea-setup
│   ├── install-git-hooks.sh                ← Pre-commit + post-merge (propagação) + pre-merge-commit
│   ├── check-readme-sync.sh                ← Audita README sync (aponta para source/)
│   ├── validate-agent-yaml.sh             ← Valida YAML dos agentes AIOX (parser autoritativo js-yaml→ruby→python)
│   ├── check-versions-lock.sh              ← Guarda do pin GSD no versions.lock (anti-revert pré-redux)
│   ├── check-memory-not-on-main.sh          ← Guarda Lovable-safe (v5): memória nunca no main; bloqueia merge planning→main
│   ├── check-plugin-membership.sh           ← Guarda anti-deriva (v7): manifesto plugin: × arrays do build-plugins.sh
│   ├── check-source-headers.sh             ← Guarda de proveniência (v11): skill sem # SOURCE (advisory; vendorizadas OK-via-pin)
│   ├── check-soak.sh                       ← SOAK gate (v11): milestone só tagueia após idea-doctor+regressão em ≥2 máquinas/≥1 dia
│   ├── refresh-ai-security.sh              ← Refresh mensal AI-security intel (v12): curl+diff+sha, snapshot versionado, nunca executa conteúdo
│   ├── check-security-freshness.sh         ← Selo de Frescor de Segurança (v13): risk-weighted git-diff → tier; --gate trava tag no egrégio (advisory no 1º ciclo)
│   ├── remind-closeout-gates.sh            ← Lembrete dos gates de fechamento (v15): ff-merge/SOAK/frescor por epoch; notifica via osascript, nunca carimba
│   ├── idea-doctor.sh                      ← Diagnóstico saúde + drift (read-only)
│   ├── install-global-patches.sh           ← Overlay ideIAos (Caminho C — 15 patches idempotentes)
│   ├── update-upstream.sh                  ← Detecta updates GSD + AIOX vs versions.lock (--bump re-pina)
│   ├── update-design-suite.sh              ← Atualização controlada da Suíte (re-vendoriza do upstream)
│   ├── apply-to-all-projects.sh            ← Propaga setup --project-only a ~/dev/*
│   ├── export-env-dev.sh                   ← Extrai .env mínimo de dev (least-privilege) p/ entregar a dev novo
│   ├── check-env-not-tracked.sh            ← Gate anti-segredo: detecta .env versionado em repo-produto (read-only)
│   ├── idea-smoke.sh                        ← Smoke-test puro-bash do bootstrap mínimo (exit-code; --hook) (v15)
│   ├── check-alias-map.sh                   ← Gate chave×MID: Frota mostra nome, não sha256 (espelha resolveAlias) (v15)
│   ├── propagate-if-changed.sh             ← Auto-propagação pós-pull (autosync + post-merge + sync-all)
│   ├── sync-all.sh                         ← Orquestrador (pull → upstream → setup --global-only → overlay → propagate → doctor)
│   ├── ideiaos-update.sh                   ← Atualização de máquina em 1 comando (sync-all + shell + statusline)
│   ├── build-adapters.sh                   ← Compila source/ → harness targets (claude + cursor)
│   └── build-plugins.sh                    ← Gera plugins/ a partir de source/ (marketplace)
├── source/                                 ← FONTE ÚNICA DE VERDADE (Fase 03+)
│   ├── skills/                             ← 47 skills (core incl. /memory-sync + 10 design + 2 lovable (/lovable-handoff + /lovable-mcp) + /forge-agent + /spec + /tool-output-compressor + v8 disciplina + v9 alinhamento /grelha + /improve-architecture)
│   │   ├── forge-agent/                    ← /forge-agent (v6 Fase 25) — pesquisa antes de criar agent/skill
│   │   ├── spec/                           ← /spec (v6 Fase 30) — delta-spec brownfield; lib/ + templates/
│   │   ├── doubt/                          ← /doubt (v8) — doubt-driven; revisor adversarial em-voo
│   │   ├── context-engineering/            ← /context-engineering (v8) — curadoria de contexto em camadas
│   │   ├── grelha/                         ← /grelha (v9) — grilling colaborativo pré-plano + glossário CONTEXT.md
│   │   ├── improve-architecture/           ← /improve-architecture (v9) — ritual de deepening (alias /aprofundar)
│   │   └── tool-output-compressor/         ← /tool-output-compressor — compressor local/reversível de tool-output (padrão headroom, dep não adotada)
│   ├── agents/                             ← 19 agents (ECC + 4 mkt-*)
│   ├── hooks/                              ← 14 hooks de produto (incl. instinct-recover.sh v6 + memory-import/export) + 3 test-hooks
│   ├── lib/                                ← libs shell reutilizáveis (v6): gates.sh (antifragile I/O) + handoff-packet.sh (context-packet)
│   ├── templates/                          ← templates de projeto (hybrid/ideiaos/lovable/learnings/memory/global-patches) + skill/SKILL.md.tmpl (v8 — convenção de autoria)
│   ├── contexts/                           ← contexts de modo (dev.md / review.md / research.md)
│   ├── statusline/                         ← ideiaos-statusline.sh
│   ├── agentd/                             ← coletor read-only + step-up híbrido (v14 Cockpit): sign/verify/seal/ledger/cmd-ref (write-path security)
│   ├── console/                            ← read-model do Cockpit (v14): ingest.js + schema.sql → SQLite descartável
│   ├── autosync/                           ← git-autosync.sh versionado (daemon LaunchAgent — fonte canônica, auto-cura planning/cockpit)
│   └── rules/
│       ├── common/                         ← token-economy, mcp-hygiene, orchestration, antifragile-gates, context-packet-handoffs, delta-spec (v6), operating-discipline (v8)
│       ├── marketing/                      ← 22 rules de marketing (copywriting, blog-seo, data-analysis, posts…) (v6 Fase 26)
│       ├── supabase/                       ← rls-patterns
│       ├── lovable/                        ← deployment-protocol
│       └── ecc/                            ← rules ECC absorvidas via quarentena (MIT)
│           ├── common/                     ← code-quality, testing, documentation
│           ├── typescript/                 ← typescript strict rules
│           └── react/                      ← hooks rules, component patterns
├── manifests/
│   ├── modules.json                        ← catálogo de 101 módulos (hooks/agents/skills/templates/contexts/statusline/lsp/script) + campo plugin
│   └── plugin-membership.md               ← mapeamento módulo → plugin (fonte de verdade legível)
├── apps/                                   ← apps de produto do ideIAos
│   └── cockpit/                            ← SPA do Cockpit (v14 — Vite+React+TS, console CTO local-first black-gold)
├── specs/                                  ← contratos de comportamento vivos (/spec delta-spec): cockpit/ + tool-output-compressor/ + _changes/ + _archive/
├── infra/                                  ← infraestrutura local
│   └── launchd/                            ← plists (com.ideiaos.cockpit + com.ideiaos.refresh-ai-security)
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
├── tests/                                  ← suítes de teste estruturais
│   ├── v6-hooks/                           ← 5 suites CI (test-deia-trigger, test-observe-session-end, test-observe-tool-use, test-strategic-compact, test-build-adapters) — v6 Fase 27
│   └── v5-memory/                          ← testes de memória v5
├── evals/                                  ← suíte de regressão (≥20 casos reais) + run-evals.sh
│   ├── run-evals.sh                        ← runner: bash evals/run-evals.sh [--list]
│   ├── cases/                              ← EVAL-*.md (≥20 casos com input/expected/actual)
│   └── README.md                          ← documentação da suíte
├── docs/
│   ├── decisions/                          ← ADRs de tooling (v6 Fase 31): gsd-browser-pilot-evaluation.md + agent-inbox-optin.md + histórico v5
├── AGENTS.md                               ← Identidade do ideIAos
├── CLAUDE.md                               ← Instruções Claude para ideIAos
├── STATE.md                                ← Estado do ideIAos
└── README.md                               ← Este arquivo
```

---

## 🆕 Novidades v6 — Resiliência + Marketing + GSD/OpenSpec

### Resiliência e Antifragilidade (Fases 23, 24, 27, 29)

**Antifragile Gates (`source/lib/gates.sh` + rule `antifragile-gates.md`)**
Helpers shell que usam apenas `test -s PATH` (exit code binário) para verificar I/O — nunca o Read tool, que pode alucinar conteúdo. Use `gates.sh` em qualquer hook ou script que precise garantir que um arquivo foi realmente escrito.

**Recuperação do loop de instincts (`instinct-recover.sh` — SessionStart)**
Detecta breadcrumbs órfãos do spawn de `/instinct-analyze` (crash de sessão) e re-spawna exatamente uma vez, com gate de pid vivo + idade + cooldown de 30 min. Fail-silent: nunca bloqueia o SessionStart.

**Context-Packet Handoffs (`source/lib/handoff-packet.sh` + rule `context-packet-handoffs.md`)**
Padrão de handoff com token budget explícito, wrapper anti-injection e hash SHA-256 de idempotência. Use para emitir pacotes de contexto entre hooks, skills e sessões sem vazar informação sensível ou inflar o contexto inutilmente.

**Test Hardening (`tests/v6-hooks/` — 5 suites, CI estrutural)**
5 suites de teste cobrindo os hooks centrais (`deia-trigger`, `observe-session-end`, `observe-tool-use`, `strategic-compact`, `build-adapters`). Rodar com:
```bash
bash tests/v6-hooks/test-deia-trigger.sh
bash tests/v6-hooks/test-observe-session-end.sh
# ... ou todos via CI
```

---

### Camada de Marketing (Fase 26)

**Skills de marketing:**
```
/marketing           → orquestra campanha completa: estrategista → copywriter → designer → revisor
/marketing-research  → pesquisa de referências públicas via Chrome DevTools MCP (hooks, cadência, CTAs)
```

**4 agents especializados** (`source/agents/mkt-*.md`):
- `@mkt-estrategista` — ângulos, big idea, calendário editorial
- `@mkt-copywriter` — copy hook-first (3 hooks → body → CTA)
- `@mkt-designer` — peças visuais via Suíte de Design IdeiaOS
- `@mkt-revisor` — scoring + veto APROVADO/REJEITADO

**22 rules** em `source/rules/marketing/` (copywriting, data-analysis, blog SEO, posts).

Para usar:
```
/marketing
→ A skill pergunta o objetivo, delega sequencialmente para os 4 agents e entrega o material revisado.
```

---

### GSD/OpenSpec — Spec e Forge (Fases 25, 28, 30, 31)

**Forge Agent (`/forge-agent`) — pesquisa antes de criar**
Fundamenta agents e skills em pesquisa real do domínio antes de produzir spec. Nunca cria agent sem ao menos 2 fontes verificáveis. Fluxo: definir domínio → `/deep-research` (máx 3 ciclos) → model routing com justificativa → spec grounded.
```
/forge-agent
→ Pergunta: domínio-alvo? tipo (agent ou skill)? problema que resolve?
→ Pesquisa → produz source/agents/<nome>.md ou source/skills/<nome>/SKILL.md com fontes.
```

**Delta-Spec Brownfield (`/spec`) — contratos de comportamento vivos**
Mantém contratos de comportamento duráveis por capability em `specs/<capability>/spec.md`. Complementar ao GSD: `/spec` define o CONTRATO (o que o produto deve fazer); GSD executa a IMPLEMENTAÇÃO. Adaptado do OpenSpec MIT.
```
/spec
→ Proposta → delta (ADICIONADO/MODIFICADO/REMOVIDO/RENOMEADO) → tasks.md → merge+archive.

Deia, registra que o login deve suportar 2FA com TOTP
→ Roteado para /spec → capability "auth" → proposta + delta.
```
**Subcomandos de auditoria (v11):**
```
bash source/skills/spec/lib/spec-analyze.sh <produto-root> [<cap>] [--advisory-only]
→ gate determinístico da spec VIVA pós-merge (complementa o spec-validate, que só vê o delta):
  A1 req sem cenário · A2 cenário em nível errado · A3 header duplicado · A4 token de delta
  vazado = HARD (exit 1). A5 path-morto + A6 req fora de ## Requisitos + passes LLM = ADVISORY.
  Tudo na zona ## Requisitos, fence-aware. --advisory-only nunca falha.

bash source/skills/spec/lib/spec-converge.sh <produto-root> [<cap>]
→ ponte APPEND-ONLY spec↔código: gera delta-candidato + relatório numa quarentena
  (_changes/_converge-<TS>/) que reentra no fluxo normal; NUNCA muta a fonte (sha256 antes/depois).
```
Libs internas: `spec-grammar.sh` (gramática única) · `spec-validate.sh` (gate do delta) · `spec-merge.sh` (merge+archive) · `spec-analyze.sh` (gate da fonte) · `spec-converge.sh` (ponte append-only) — em `source/skills/spec/lib/`. Fixture-regression: `tests/spec-analyze.bats` (roda no CI + SOAK). Rule de fronteira: `source/rules/common/delta-spec.md` (inclui `/spec --analyze` × `gsd-code-review`). ADR: `docs/decisions/v11-spec-kit-analyze-converge.md`.

**GSD Lineage Lock (Fase 28) — blindagem do pin redux**
O `versions.lock` traz nota expandida que documenta a distinção `gsd-redux 1.1.0 ≠ gsd-pi 3.x`. O `check-versions-lock.sh` bloqueia pinos fora da linha redux antes de qualquer commit. Histórico: o pin foi revertido 3 vezes antes desta blindagem.

**ADRs de tooling (Fase 31 — `docs/decisions/`)**
2 ADRs com avaliação de adoção gradual: `gsd-browser-pilot-evaluation.md` (browser automation no GSD) e `agent-inbox-optin.md` (inbox opt-in por agent). Consulte antes de adicionar integração de browser ou fila de mensagens ao pipeline GSD.

---

## 🆕 Novidades v14.0 — IdeiaOS Cockpit (Substrato + Espinha)

O **IdeiaOS Cockpit** é um console **local-first** de visão CTO/Tech-Lead sobre o substrato auto-telemetrado. A fase **v14.0 (Substrato + Espinha)** torna o substrato **federável** e faz nascer a SPA — sem UI de valor ainda (fase de canalização). Verificada por **24/24 gates por exit-code**.

**Novas capacidades:**

- **`idea-doctor.sh --json`** — o diagnóstico (14 seções + nova **§15 Cockpit**) agora emite JSON estruturado `ideiaos-doctor/v1` (`sections[]` + `summary{ok,warn,fail,exit}`), com a saída ANSI humana **byte-idêntica** (fallback intocado). Consumível por máquina:
  ```bash
  bash scripts/idea-doctor.sh --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["summary"])'
  ```
- **Federação por ref `cockpit`** (`source/lib/cockpit.sh`) — cada máquina grava `snapshots/<machine_id>.json` em `refs/heads/cockpit` via **git-plumbing puro** (working tree nunca tocado; o `git add -A` do autosync nunca captura). O autosync empurra o ref `cockpit` (nunca `main`).
- **`ideiaos-agentd`** (`source/agentd/`) — coletor **read-only** (4º LaunchAgent `com.ideiaos.cockpit`, 900s) que normaliza só **metadata** (`var_name/present/risk_tier/mtime` — **nunca o valor** de um segredo). Gate **Zero-Leak=0** estrutural por exit-code. Instalar o daemon recorrente é passo manual (`infra/launchd/com.ideiaos.cockpit.plist`):
  ```bash
  node source/agentd/agentd.js --once     # uma coleta → grava no ref cockpit
  ```
- **`console-ingest`** (`source/console/`) — read-model **SQLite descartável** (`~/.ideiaos/console/read-model.db`); `rm && rebuild` reconstrói dos refs. `api_key` **sem coluna `value`** (isolamento de credencial materializado no schema).
  ```bash
  node source/console/ingest.js           # (re)constrói o read-model
  ```
- **SPA do Cockpit** (`apps/cockpit/`) — Vite + React + TS + Tailwind + shadcn, tema **black-gold OKLCH**, em **loopback (127.0.0.1) sem login**. Renderiza ≥1 card de máquina (`machine_id` + `last_doctor`).
  ```bash
  node apps/cockpit/server/read.js        # server local loopback (porta 3073)
  cd apps/cockpit && npm run dev           # SPA em http://127.0.0.1:5273/
  ```
- **`check-cockpit.sh`** — gate de saúde (agentd vivo? ref existe? snapshot fresco?) + harness **Time-to-Truth** (`scripts/ttt-baseline.sh`/`ttt-median.sh`).

> **Fora de escopo (gated p/ v14.4):** qualquer verbo de mutação de produção/cross-máquina (`rotate`/`revoke`/`deploy`/`git push`/`gh pr`). Esta fase é **read-only** quanto a produção.

---

## 🆕 Novidades v14.1 — Cockpit MVP Bridge (read-path de valor)

A v14.1 transforma a Espinha em um console **navegável e útil**, ainda **100% read-only** quanto a produção. Tag `v14.1` SHIPPED (2026-06-23).

- **API read** (`apps/cockpit/server/read.js`) — endpoints `/overview`, `/fleet`, `/vault`, `/verify`, `/command-token` + `POST /command` (allowlist **default-deny**).
- **3 telas** — Overview, Frota, Cofre (metadata-only; nunca o valor de um segredo).
- **⌘K command palette** (cmdk) — verbos seguros via allowlist B1–B6 (ex.: `run_doctor`, `pause_autosync` com confirmação).
- **Flight Recorder v0** — trilha de nós/reversões para auditoria local.
- **Zero-Leak** — 7 superfícies + veneno triplo, gate por exit-code.
- Lição absorvida: **`curl` mascara preflight CORS** — o bug `POST /command` só apareceu no browser (visual-loop), não no `curl` ([[learning-curl-masks-cors-preflight-verify-browser]]).

## 🔒 Em andamento — v14.4 Write-Path Security (gated)

Antes de o Cockpit poder **mutar** algo (rotacionar segredo, deploy, push), o write-path precisa de prova criptográfica de origem. Em construção (não habilitado em produção):

- **Step-up híbrido** (`source/agentd/stepup/`) — autorização por **OTP-por-e-mail** com comprovante assinado (Ed25519), backend Supabase dedicado, binding por `payload_hash`. Provado end-to-end no backend real + cerimônia N=2 (2 hosts físicos).
- **Substrato local B5–B8** — `cmd-ref` / `ledger` (hash-chained + tail-anchor) / `ack` / `rate-limit`, gate `test-writepath-substrate.sh`.
- **Seal nativo** — sealed-box **X25519 nativo do Node** (`age` dispensado, native-first), `enc_pubkey` no pin.
- Status: substrato **LOCAL** fechado e adversarialmente verificado; a **feature cross-máquina** (executor + UI) segue **gated** em 2º host físico real + ação humana (FG-PAT admin). Contrato vivo em [`specs/cockpit/spec.md`](specs/cockpit/spec.md).

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

**Comando direto:** `bash scripts/idea-doctor.sh` — diagnóstico read-only que audita skills, MCPs, os 15 patches, versões vs `versions.lock`, drift, autosync e **Security Audit** (deny rules, hooks perigosos, secrets em memória, pipeline de quarentena, contenção Lovable MCP nos produtos). Mostra `OK / WARN / FAIL` por item com a remediação. Ver também: [`docs/security/memory-hygiene.md`](docs/security/memory-hygiene.md).
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

*ideIAos · Última atualização: 2026-06-25 · Milestone atual: **v14.1 SHIPPED** (tags v2.0 … v14.1; v14.4 write-path em andamento)*
*Mantido por: equipe Ideia Business + IAs (Claude Code, Cursor)*
*Novo no time? Comece por [`docs/guides/onboarding-novo-dev.md`](docs/guides/onboarding-novo-dev.md).*

**Mudanças v1.1 (2026-05-30):** Caminho C — composição AIOX × GSD.
- Deia agora aplica decisão única (2 exceções + 5 critérios) em vez de matriz por categoria.
- Três contratos formais: `--story` em `/gsd-plan-phase`, `--verification` em `@qa *gate`, hook Fase A com 3 gatilhos (commit + qa-gate PASS + verify SUCCESS).
- DECISION-MATRIX refatorado de catálogo (158 linhas) para árvore de decisão (~190 linhas com fluxos compostos).
- **Bundle versioning no setup.sh** — detecção automática de versão template vs instalada, com refresh atômico dos 4 docs ideIAos.
- **3 scripts de manutenção do overlay** — `install-global-patches.sh` (idempotente), `update-upstream.sh` (detecta updates), `sync-all.sh` (orquestrador). Resolvem o problema "patches sobrescritos por updates upstream".
