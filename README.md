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

# 3. Aplique o overlay (7 patches sobre GSD/AIOX/Claude) e confira a saúde
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

Detalhes completos: cada projeto ideIAos recebe [`docs/ideiaos/DECISION-MATRIX.md`](templates/ideiaos/DECISION-MATRIX.md.tmpl) e [`docs/ideiaos/GUIDE-AI.md`](templates/ideiaos/GUIDE-AI.md.tmpl).

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
- instala o **autosync** (LaunchAgent, a cada 15 min)
- `setup.sh --global-only` → **skills** (idea, frontend-visual-loop, motion, web-quality, Suíte de Design) + **MCPs** (chrome-devtools, context7) + hooks + agentes Cursor
- `sync-all.sh` → aplica os **7 patches** do overlay + roda `idea-doctor`

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
| **MCP `chrome-devtools`** | user scope (via `claude mcp`) | Auditoria de console/rede do browser direto no Claude Code |
| **MCP `context7`** | user scope (via `claude mcp`) | Docs versionadas de 1000+ libs (React/Tailwind/etc) ao vivo |
| **Alias `idea-setup`** | `~/.zshrc` ou `~/.bashrc` (via `install-alias.sh`) | Atalho terminal — `cd projeto && idea-setup` |

### Manutenção do próprio ideIAos (rodados manualmente)

| Script | O que faz |
|--------|-----------|
| `scripts/install-alias.sh` | Adiciona alias `idea-setup` ao seu shell rc (zsh/bash) |
| `scripts/install-git-hooks.sh` | Instala pre-commit hook que BLOQUEIA commits sem README sincronizado |
| `scripts/check-readme-sync.sh` | Audita se README menciona todos os componentes do repo |
| **`scripts/idea-doctor.sh`** | Diagnóstico read-only: skills, MCPs, 7 patches, versões vs `versions.lock`, drift, autosync |
| **`scripts/install-global-patches.sh`** | Aplica overlay ideIAos (Caminho C) sobre GSD/AIOX/Claude — idempotente, 7 patches |
| **`scripts/update-upstream.sh`** | Detecta updates do GSD plugin e AIOX-core vs `versions.lock`; `--bump` re-pina |
| **`scripts/update-design-suite.sh`** | Atualização CONTROLADA da Suíte de Design (re-vendoriza do nextlevelbuilder, mostra diff, sob demanda) |
| **`scripts/sync-all.sh`** | Orquestrador — `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| **`versions.lock`** | Lockfile de versões (aiox-core, gsd, ref da Suíte, MCPs) que toda máquina deve convergir |

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

### Os 7 patches do overlay ideIAos

| # | Onde | O que adiciona |
|---|------|----------------|
| 1 | `~/.claude/skills/gsd-plan-phase/SKILL.md` | Flag `--story <file>` (Contrato 1 da composição) |
| 2 | `~/.claude/get-shit-done/workflows/plan-phase.md` | Pipeline `STORY_MODE` para parsing de AC AIOX |
| 3 | `~/.claude/hooks/extract-learnings-reminder.sh` | 3 gatilhos Fase A (commit + qa-gate PASS + verify SUCCESS) |
| 4 | `~/.claude/settings.json` | Matcher expandido `Bash\|Write\|Edit\|MultiEdit` |
| 5 | `.aiox-core/.../agents/qa.md` | Flag `--verification <path>` em `*gate` (Contrato 2) |
| 6 | `.aiox-core/.../tasks/qa-gate.md` | Seção "Optional Input — ideIAos Composition" |
| 7 | `~/.claude/skills/design-system/SKILL.md` | Tokens **OKLCH** (`--brand-hue`) na Suíte de Design (upstream de terceiros) |

### Scripts de manutenção + lockfile

| Comando | Quando usar |
|---------|-------------|
| `bash scripts/idea-doctor.sh` | **SEMPRE PRIMEIRO** — diagnóstico read-only: skills, MCPs, 7 patches, versões vs lock, drift, autosync. Não muda nada. |
| `bash scripts/sync-all.sh` | **O DE SEMPRE** — atualiza tudo: `git pull` → `update-upstream` → `setup.sh --global-only` → overlay → `idea-doctor` |
| `bash scripts/install-global-patches.sh` | só re-aplicar o overlay (7 patches) — idempotente, roda 100x |
| `bash scripts/update-upstream.sh` | checar updates de GSD/AIOX vs `versions.lock`. `--bump` re-pina o lock no instalado |
| `bash scripts/update-design-suite.sh` | atualizar a Suíte de Design do upstream (controlado, mostra diff, **sob demanda**) |

> **`versions.lock`** (raiz do repo) fixa as versões que toda máquina deve convergir (aiox-core CLI, gsd, ref da Suíte, specs de MCP). `idea-doctor` acusa drift; `update-upstream --bump` re-pina.

### Como atualizar CADA componente

| Componente | Como atualizar |
|------------|----------------|
| **Skills nossas** (idea, frontend-visual-loop, motion, web-quality…) | edite em `skills/` → commit/push → nas outras máquinas: `git pull` + `bash scripts/sync-all.sh` |
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
│  install-global-patches.sh aplica 7 patches idempotentes   │
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
├── versions.lock                           ← pin de versões (aiox-core/gsd/Suíte/MCPs)
├── agents/
│   ├── claude-continuation.md              ← Cursor agent — Cursor lê do Claude
│   └── ideiaos-checker.md                    ← Cursor agent — audita setup
├── skills/
│   ├── idea/SKILL.md                       ← Claude — ORQUESTRADOR ideIAos
│   ├── cursor-continuation/SKILL.md        ← Claude — retoma do Cursor
│   ├── lovable-handoff/SKILL.md            ← Claude — playbook Lovable
│   ├── recall-learnings/SKILL.md           ← Claude — load context
│   ├── extract-learnings/SKILL.md          ← Claude — registra aprendizado
│   ├── ideiaos-setup/SKILL.md              ← Claude — audita setup
│   ├── frontend-visual-loop/               ← Claude — loop render→screenshot→fix (Chrome DevTools MCP)
│   ├── motion/                             ← Claude — animação (Framer Motion / GSAP)
│   ├── web-quality/                        ← Claude — auditoria CWV / WCAG / SEO
│   ├── ui-ux-pro-max/  design/  design-system/   ← Suíte de Design (vendorizada, nextlevelbuilder)
│   ├── ui-styling/  brand/  banner-design/  slides/
│   └── .design-suite-version               ← pin da Suíte (update-design-suite.sh)
├── hooks/
│   ├── extract-learnings-reminder.sh       ← Claude PostToolUse Bash
│   ├── ideiaos-detector.sh               ← Claude SessionStart
│   ├── ideiaos-readme-reminder.sh        ← Claude PostToolUse Edit/Write
│   └── deia-trigger.sh                     ← Claude UserPromptSubmit — gatilho "Deia,"
├── scripts/
│   ├── install-alias.sh                    ← Instala alias idea-setup
│   ├── install-git-hooks.sh                ← Instala pre-commit hook
│   ├── check-readme-sync.sh                ← Audita README sync
│   ├── idea-doctor.sh                      ← Diagnóstico saúde + drift (read-only)
│   ├── install-global-patches.sh           ← Overlay ideIAos (Caminho C — 7 patches idempotentes)
│   ├── update-upstream.sh                  ← Detecta updates GSD + AIOX vs versions.lock (--bump re-pina)
│   ├── update-design-suite.sh              ← Atualização controlada da Suíte (re-vendoriza do upstream)
│   └── sync-all.sh                         ← Orquestrador (pull → upstream → setup --global-only → overlay → doctor)
├── templates/
│   ├── aiox-ai-config.yaml                 ← Config IA + marker ideIAos
│   ├── hybrid/
│   │   ├── AGENTS.md.tmpl                  ← Identidade do projeto + ideIAos
│   │   ├── CLAUDE.md.tmpl                  ← Instruções Claude (ideIAos-aware)
│   │   ├── STATE.md.tmpl                   ← Snapshot operacional
│   │   ├── CONTINUATION_HANDOFF.md.tmpl    ← Handoff de continuidade
│   │   ├── CONTRIBUTING.md.tmpl            ← Onboarding dev (ideIAos commands)
│   │   ├── agents-md-protocol.mdc.tmpl     ← Cursor rule principal
│   │   ├── planning-branch.mdc.tmpl        ← Convenção branch planning
│   │   └── session-continuation.mdc.tmpl   ← Rule de retomada
│   ├── ideiaos/
│   │   ├── IDEIAOS.md.tmpl                 ← Manifesto ideIAos (raiz do projeto)
│   │   ├── GUIDE-HUMANS.md.tmpl            ← Guia para devs humanos
│   │   ├── GUIDE-AI.md.tmpl                ← Guia para IAs (Claude/Cursor/Codex)
│   │   └── DECISION-MATRIX.md.tmpl         ← Matriz "tarefa → camada → comando"
│   ├── lovable/
│   │   ├── AGENTS.lovable.md.tmpl          ← Seção Lovable no AGENTS.md
│   │   ├── lovable-deploy.mdc.tmpl         ← Cursor rule: doutrina Lovable única (merge main → Update, botão cinza, confirmar bundle)
│   │   ├── playbook-implantacao.md.tmpl    ← Fluxo obrigatório
│   │   ├── conclusao-implantacao.md.tmpl   ← Modelo de resposta (8 blocos)
│   │   └── _TEMPLATE.md.tmpl               ← Esqueleto de handoff Lovable
│   ├── learnings/
│   │   ├── README.md.tmpl                  ← Convenções
│   │   └── _TEMPLATE.md.tmpl               ← Esqueleto de learning
│   └── global-patches/
│       ├── extract-learnings-reminder.sh   ← Fonte de verdade do hook (3 gatilhos)
│       └── oklch-tokens.md                  ← Doc OKLCH copiado pelo Patch 7
├── docs/
│   ├── IDEIAOS.md                          ← Especificação canônica do ideIAos
│   └── CONTINUATION_HANDOFF.md
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

Depois reinicia o Claude Code.

### "Não recebo a sugestão proativa no Cursor"

A rule `.cursor/rules/agents-md-protocol.mdc` precisa estar no projeto. Confira com:

```bash
ls -la .cursor/rules/agents-md-protocol.mdc
```

Se não existir, roda `@ideiaos-checker` no chat ou `idea-setup` no terminal.

### "Como sei se o setup está completo?"

**Comando direto:** `bash scripts/idea-doctor.sh` — diagnóstico read-only que audita skills, MCPs, os 7 patches, versões vs `versions.lock`, drift e autosync. Mostra `OK / WARN / FAIL` por item com a remediação.
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
- **`templates/ideiaos/IDEIAOS.md.tmpl`** — manifesto que vai pra raiz de cada projeto
- **`templates/ideiaos/GUIDE-HUMANS.md.tmpl`** — guia detalhado para devs
- **`templates/ideiaos/GUIDE-AI.md.tmpl`** — instruções operacionais para IAs
- **`templates/ideiaos/DECISION-MATRIX.md.tmpl`** — tabela canônica "tarefa → comando"
- **`../mapa-github-ai-dev-tools.md`** — pesquisa de mercado (60+ projetos comparados)

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
