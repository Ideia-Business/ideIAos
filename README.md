# IdeiaOS — Sistema Operacional Unificado de Desenvolvimento

> **Configura o ambiente de IA da equipe em um único comando.**
> O IdeiaOS combina 5 camadas (AIOX-Core, GSD, Lovable, Fase A, Continuation) em um sistema único, com **um comando de entrada** (`/idea`) que roteia para a camada certa.
> Implementado como `IdeiaOS` — instalável, idempotente, com enforcement automático para você não ter que lembrar de nada.

---

## 🚀 Quickstart (instalação em 30 segundos)

```bash
# 1. Clone
git clone git@github.com:Ideia-Business/IdeiaOS.git
cd IdeiaOS

# 2. Instale globalmente (uma vez na vida)
bash setup.sh

# 3. (Opcional) Adicione o atalho de terminal
bash scripts/install-alias.sh
source ~/.zshrc  # ou ~/.bashrc
```

Pronto. Em qualquer projeto, você precisa decorar **um comando** — ou apenas chamar a **Deia** por nome:

| Onde | Como chamar | Função |
|------|-------------|--------|
| Claude Code | `Deia, <pedido>` ou `/idea <pedido>` | **Orquestrador IdeiaOS** — roteia para a camada certa |
| Cursor | `@ideiaos-checker` | Audita setup do projeto |
| Terminal | `idea-setup` | Roda setup do projeto atual |

A **Deia** é a assistente IdeiaOS — basta começar a mensagem com `Deia,` (ou `deia,` / `Déia,`) e ela ativa automaticamente. Reforçada por hook `UserPromptSubmit` para máxima confiabilidade.

E você não precisa decorar nem isso, porque **o sistema te avisa quando precisar**. Veja [Como usar no dia a dia](#-como-usar-no-dia-a-dia).

---

## 🧠 O que é o IdeiaOS

IdeiaOS é o **Sistema Operacional** de desenvolvimento da Ideia Business. Não é um framework — é a camada de orquestração que combina ferramentas em um sistema coerente:

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

## 📋 Pré-requisitos

- **Node.js 18+** — [nodejs.org](https://nodejs.org)
- **Git**
- **Claude Code CLI** — [claude.ai/code](https://claude.ai/code)
- **Cursor IDE** — [cursor.sh](https://cursor.sh)
- Shell: `zsh` ou `bash` (macOS/Linux nativamente; Windows via WSL)

---

## 🎯 O que este setup instala

### Componentes globais (uma vez, vale pra qualquer projeto)

| Componente | Onde | Para quê |
|------------|------|----------|
| **AIOX Core** | npm global via `npx aiox-core` | Orquestrador de agentes IA — base do AIOX |
| **GSD skills** | `~/.claude/skills/gsd-*` | Suite com 60+ comandos GSD (vem com Claude Code via plugins) |
| **Skill Claude `/idea`** | `~/.claude/skills/idea/` | **Orquestrador IdeiaOS** — comando único de entrada |
| **Skill Claude `/ideiaos-setup`** | `~/.claude/skills/ideiaos-setup/` | Audita + completa setup do projeto |
| **Skill Claude `/cursor-continuation`** | `~/.claude/skills/cursor-continuation/` | Retoma no Claude Code o trabalho do Cursor |
| **Skill Claude `/lovable-handoff`** | `~/.claude/skills/lovable-handoff/` | Playbook de implantação Lovable |
| **Skill Claude `/recall-learnings`** | `~/.claude/skills/recall-learnings/` | Lê aprendizados antes de propor plano |
| **Skill Claude `/extract-learnings`** | `~/.claude/skills/extract-learnings/` | Registra aprendizado pós-trabalho |
| **Agente Cursor `@claude-continuation`** | `~/.cursor/agents/` | Retoma no Cursor o trabalho do Claude Code |
| **Agente Cursor `@ideiaos-checker`** | `~/.cursor/agents/` | Audita + completa setup do projeto no Cursor |
| **Hook Claude `extract-learnings-reminder`** | `~/.claude/hooks/` | Após `git commit`, lembra de gate triplo |
| **Hook Claude `ideiaos-detector`** | `~/.claude/hooks/` | SessionStart — detecta projeto sem IdeiaOS |
| **Hook Claude `ideiaos-readme-reminder.sh`** | `~/.claude/hooks/` | PostToolUse Edit/Write — lembra de sync README |
| **Hook Claude `deia-trigger.sh`** | `~/.claude/hooks/` | UserPromptSubmit — detecta "Deia," e ativa `/idea` |
| **Alias `idea-setup`** | `~/.zshrc` ou `~/.bashrc` (via `install-alias.sh`) | Atalho terminal — `cd projeto && idea-setup` |

### Manutenção do próprio IdeiaOS (rodados manualmente)

| Script | O que faz |
|--------|-----------|
| `scripts/install-alias.sh` | Adiciona alias `idea-setup` ao seu shell rc (zsh/bash) |
| `scripts/install-git-hooks.sh` | Instala pre-commit hook que BLOQUEIA commits sem README sincronizado |
| `scripts/check-readme-sync.sh` | Audita se README menciona todos os componentes do repo |

### Componentes do projeto (instalados quando você roda em projeto específico)

| Componente | Arquivo | Camada |
|------------|---------|--------|
| `IDEIAOS.md` | Raiz | IdeiaOS — manifesto |
| `docs/ideiaos/GUIDE-HUMANS.md` | docs/ideiaos/ | IdeiaOS — guia para humanos |
| `docs/ideiaos/GUIDE-AI.md` | docs/ideiaos/ | IdeiaOS — guia para IAs |
| `docs/ideiaos/DECISION-MATRIX.md` | docs/ideiaos/ | IdeiaOS — matriz "tarefa → comando" |
| `AGENTS.md` com seção Lovable + Fase A | Raiz | AIOX |
| `CLAUDE.md` (auto-load Claude) | Raiz | AIOX |
| `STATE.md` (snapshot operacional) | Raiz | Continuation |
| `CONTRIBUTING.md` | Raiz | AIOX |
| `docs/CONTINUATION_HANDOFF.md` | docs/ | Continuation |
| `.cursor/rules/agents-md-protocol.mdc` | .cursor/rules/ | Cursor |
| `.cursor/rules/session-continuation.mdc` | .cursor/rules/ | Cursor |
| `.cursor/rules/planning-branch.mdc` | .cursor/rules/ | Cursor |
| `.aiox-ai-config.yaml` (com marker IdeiaOS) | Raiz | IdeiaOS |
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
2. Aguarde 1 segundo. Se aparecer um aviso `🔧 Setup detector — projeto sem IdeiaOS`, digite:
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
| Claude Code | `/idea <pedido>` | **Orquestrador IdeiaOS** — único comando real necessário |
| Claude Code (setup) | `/ideiaos-setup` | Quando suspeitar que setup está incompleto |
| Cursor | `@ideiaos-checker` | Equivalente no Cursor |
| Terminal | `idea-setup` | Atalho do `setup.sh --lovable .` |

**Só isso.** Se você esquecer, o próprio sistema te lembra. Se ainda assim esquecer, rode `/ideiaos-setup` ou `@ideiaos-checker` — não estraga nada.

📚 Tabela completa de comandos por camada: cada projeto IdeiaOS recebe `docs/ideiaos/DECISION-MATRIX.md`.

---

## 🏗️ Arquitetura — como tudo se conecta

```
                            USUÁRIO
                               │ (pedido em linguagem natural)
                               ▼
                          ┌─────────┐
                          │  /idea  │  ← orquestrador IdeiaOS
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

**Enforcement automático (Claude Code):** hook PostToolUse Bash injeta lembrete do gate triplo após cada `git commit`. Sem isso, sob pressão a IA tende a pular o passo de reflexão.

**Enforcement Cursor:** rule `agents-md-protocol.mdc` lida em todo turno orienta a IA a aplicar o mesmo gate.

---

## 🔄 Mantendo atualizado

Quando houver melhorias:

```bash
cd IdeiaOS
git pull
bash setup.sh
```

O script detecta diferenças e atualiza só o que mudou. Em projetos existentes:

```bash
bash setup.sh --project-only --lovable /caminho/do/projeto
```

---

## 📁 Estrutura do repositório

```
IdeiaOS/
├── setup.sh                                ← script principal, idempotente
├── agents/
│   ├── claude-continuation.md              ← Cursor agent — Cursor lê do Claude
│   └── ideiaos-checker.md                    ← Cursor agent — audita setup
├── skills/
│   ├── idea/SKILL.md                       ← Claude — ORQUESTRADOR IdeiaOS
│   ├── cursor-continuation/SKILL.md        ← Claude — retoma do Cursor
│   ├── lovable-handoff/SKILL.md            ← Claude — playbook Lovable
│   ├── recall-learnings/SKILL.md           ← Claude — load context
│   ├── extract-learnings/SKILL.md          ← Claude — registra aprendizado
│   └── ideiaos-setup/SKILL.md                  ← Claude — audita setup
├── hooks/
│   ├── extract-learnings-reminder.sh       ← Claude PostToolUse Bash
│   ├── ideiaos-detector.sh               ← Claude SessionStart
│   ├── ideiaos-readme-reminder.sh        ← Claude PostToolUse Edit/Write
│   └── deia-trigger.sh                     ← Claude UserPromptSubmit — gatilho "Deia,"
├── scripts/
│   ├── install-alias.sh                    ← Instala alias idea-setup
│   ├── install-git-hooks.sh                ← Instala pre-commit hook
│   └── check-readme-sync.sh                ← Audita README sync
├── templates/
│   ├── aiox-ai-config.yaml                 ← Config IA + marker IdeiaOS
│   ├── hybrid/
│   │   ├── AGENTS.md.tmpl                  ← Identidade do projeto + IdeiaOS
│   │   ├── CLAUDE.md.tmpl                  ← Instruções Claude (IdeiaOS-aware)
│   │   ├── STATE.md.tmpl                   ← Snapshot operacional
│   │   ├── CONTINUATION_HANDOFF.md.tmpl    ← Handoff de continuidade
│   │   ├── CONTRIBUTING.md.tmpl            ← Onboarding dev (IdeiaOS commands)
│   │   ├── agents-md-protocol.mdc.tmpl     ← Cursor rule principal
│   │   ├── planning-branch.mdc.tmpl        ← Convenção branch planning
│   │   └── session-continuation.mdc.tmpl   ← Rule de retomada
│   ├── ideiaos/
│   │   ├── IDEIAOS.md.tmpl                 ← Manifesto IdeiaOS (raiz do projeto)
│   │   ├── GUIDE-HUMANS.md.tmpl            ← Guia para devs humanos
│   │   ├── GUIDE-AI.md.tmpl                ← Guia para IAs (Claude/Cursor/Codex)
│   │   └── DECISION-MATRIX.md.tmpl         ← Matriz "tarefa → camada → comando"
│   ├── lovable/
│   │   ├── AGENTS.lovable.md.tmpl          ← Seção Lovable no AGENTS.md
│   │   ├── playbook-implantacao.md.tmpl    ← Fluxo obrigatório
│   │   ├── conclusao-implantacao.md.tmpl   ← Modelo de resposta (8 blocos)
│   │   └── _TEMPLATE.md.tmpl               ← Esqueleto de handoff Lovable
│   └── learnings/
│       ├── README.md.tmpl                  ← Convenções
│       └── _TEMPLATE.md.tmpl               ← Esqueleto de learning
├── docs/
│   ├── IDEIAOS.md                          ← Especificação canônica do IdeiaOS
│   └── CONTINUATION_HANDOFF.md
├── AGENTS.md                               ← Identidade do IdeiaOS
├── CLAUDE.md                               ← Instruções Claude para IdeiaOS
├── STATE.md                                ← Estado do IdeiaOS
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
        "matcher": "Bash",
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

No Claude Code: `/ideiaos-setup` → mostra ✅/❌ por camada do IdeiaOS.
No Cursor: `@ideiaos-checker` → idem.
No terminal: roda setup e ele lista o que foi feito vs pulado.

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

Versões expandidas em `docs/learnings/` de qualquer projeto Lovable do setup. Espelhos em memória Claude global de quem clonou o IdeiaOS.

### Documentação canônica do IdeiaOS

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
- Mudanças no IdeiaOS (arquitetura, camadas, roteamento) também atualizam `docs/IDEIAOS.md`

---

## ❓ Dúvidas rápidas

- **Preciso rodar o setup toda vez que abrir um projeto?** Não. Uma vez instalado, vale pra sempre.
- **E se eu usar Windows?** Use WSL — o setup.sh assume bash/zsh em ambiente Unix-like.
- **Lovable vai sobrescrever meu AGENTS.md?** Não. A camada Lovable usa marcadores `BEGIN/END` para preservar conteúdo customizado.
- **Posso desativar o loop de aprendizado em um projeto?** Sim. Remova a seção `Loop de aprendizado contínuo` do `AGENTS.md` — hooks param de disparar automaticamente.
- **Posso desativar o IdeiaOS num projeto?** Tecnicamente sim (delete `IDEIAOS.md` e `docs/ideiaos/`), mas você perde o orquestrador. Não recomendado.
- **`/idea` substitui os comandos diretos?** Não — eles continuam funcionando. `/idea` é só um atalho cognitivo. Quem aprende os comandos diretos ganha velocidade.

---

*IdeiaOS v1.0 · Última atualização: 2026-05-29*
*Mantido por: equipe Ideia Business + IAs (Claude Code, Cursor)*
