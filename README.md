# Ideia Business — Dev Setup

> **Configura o ambiente de IA da equipe em um único comando.**
> Todas as ferramentas (Claude Code, Cursor, terminal) ficam padronizadas, com loop de aprendizado contínuo, padrões de debugging em produção e enforcement automático para você não ter que lembrar de nada.

---

## 🚀 Quickstart (instalação em 30 segundos)

```bash
# 1. Clone
git clone git@github.com:Ideia-Business/dev-setup.git
cd dev-setup

# 2. Instale globalmente (uma vez na vida)
bash setup.sh

# 3. (Opcional) Adicione o atalho de terminal
bash scripts/install-alias.sh
source ~/.zshrc  # ou ~/.bashrc
```

Pronto. Em qualquer projeto novo, você precisa decorar **2 comandos**:

| Ferramenta | Comando |
|------------|---------|
| Claude Code | `/dev-setup` |
| Cursor | `@setup-checker` |
| Terminal | `idea-setup` |

E você não precisa decorar nem isso, porque **o sistema te avisa quando precisar**. Veja [Como usar no dia a dia](#-como-usar-no-dia-a-dia).

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
| **AIOX Core** | npm global via `npx aiox-core` | Orquestrador de agentes IA — base de tudo |
| **Agente Cursor `@claude-continuation`** | `~/.cursor/agents/` | Retoma no Cursor o trabalho do Claude Code |
| **Agente Cursor `@setup-checker`** | `~/.cursor/agents/` | Audita + completa setup do projeto no Cursor |
| **Skill Claude `/cursor-continuation`** | `~/.claude/skills/` | Retoma no Claude Code o trabalho do Cursor |
| **Skill Claude `/lovable-handoff`** | `~/.claude/skills/` | Playbook de implantação Lovable (typecheck → commit → push → handoff) |
| **Skill Claude `/recall-learnings`** | `~/.claude/skills/` | Lê aprendizados antes de propor plano |
| **Skill Claude `/extract-learnings`** | `~/.claude/skills/` | Registra aprendizado ao fim de implantação |
| **Skill Claude `/dev-setup`** | `~/.claude/skills/` | Audita + completa setup do projeto no Claude Code |
| **Hook Claude `extract-learnings-reminder`** | `~/.claude/hooks/` | Após cada `git commit`, lembra de aplicar gate triplo de learning |
| **Hook Claude `dev-setup-detector`** | `~/.claude/hooks/` | Detecta projeto sem Fase A no início da sessão e sugere `/dev-setup` |
| **Alias `idea-setup`** | `~/.zshrc` ou `~/.bashrc` (via `install-alias.sh`) | Atalho terminal — `cd projeto && idea-setup` |

### Componentes do projeto (instalados quando você roda em projeto específico)

| Componente | Arquivo |
|------------|---------|
| `AGENTS.md` com seção Lovable + Fase A | Raiz do projeto (idempotente — atualizável) |
| `.cursor/rules/agents-md-protocol.mdc` | Rule sempre-ativa para Cursor |
| `.cursor/rules/session-continuation.mdc` | Rule de retomada |
| `.cursor/rules/planning-branch.mdc` | Rule de branch planning isolada |
| `docs/playbook-implantacao.md` | Fluxo obrigatório (typecheck → commit → push → handoff) |
| `docs/lovable/conclusao-implantacao.md` | Modelo canônico de resposta (8 blocos) |
| `docs/lovable/_TEMPLATE.md` | Esqueleto de handoff Lovable |
| `docs/learnings/_TEMPLATE.md` | Esqueleto de learning extraído |
| `docs/learnings/README.md` | Convenções do loop de aprendizado |
| `docs/postmortems/` | Estrutura para postmortems de incidentes |

---

## 📖 Como usar no dia a dia

### 🤖 No Claude Code

#### Projeto novo (primeira vez):

1. Abra o Claude Code dentro da pasta do projeto
2. Aguarde 1 segundo. Se aparecer um aviso `🔧 Setup detector — projeto sem Fase A`, digite:
   ```
   /dev-setup
   ```
3. A IA lista o que está faltando, pergunta se aplica. Responda **"sim"**.
4. Pronto. Trabalhe normalmente.

#### Projeto já configurado:

Não aparece aviso. Pode pedir o que quiser direto.

#### Se você esquecer:

Digita `/dev-setup`. Idempotente — pula tudo que já tem, instala só o que falta.

---

### 🟦 No Cursor

#### Projeto novo (primeira vez):

1. Abra o projeto no Cursor
2. Abra o chat lateral (Cmd+L ou ícone do chat)
3. Peça qualquer coisa. Se a IA disser `🔧 Setup incompleto detectado — Considere @setup-checker`, digite:
   ```
   @setup-checker
   ```
4. O agente lista, confirma, aplica.

#### Projeto já configurado:

IA não sugere setup. Pode trabalhar direto.

#### Se você esquecer:

Digita `@setup-checker` no chat **ou** abre terminal embutido e roda `idea-setup`.

---

### ⚡ Terminal (qualquer IDE ou shell puro)

Com alias configurado:
```bash
cd /caminho/do/projeto
idea-setup
```

Sem alias:
```bash
bash "$HOME/.../dev-setup/setup.sh" --lovable "$PWD"
```

---

## 🎯 O que você precisa decorar

| Lugar | Comando |
|-------|---------|
| Claude Code | `/dev-setup` |
| Cursor | `@setup-checker` |
| Terminal | `idea-setup` |

**Só isso.** Se você esquecer, o próprio sistema te lembra. Se ainda assim esquecer, rode `/dev-setup` ou `@setup-checker` — não estraga nada.

---

## 🏗️ Arquitetura — como tudo se conecta

```
        ┌─────────────────────────────────────────────────┐
        │  setup.sh (idempotente, fonte de verdade)        │
        │  Sem hierarquia: cada execução é independente   │
        └────────────┬───────────┬──────────────┬─────────┘
                     │           │              │
       ┌─────────────┴──┐  ┌─────┴────┐  ┌─────┴──────┐
       │ Skill Claude   │  │  Hook    │  │ Alias CLI  │
       │  /dev-setup    │  │ detector │  │ idea-setup │
       └─────────────┬──┘  └─────┬────┘  └─────┬──────┘
                     │           │              │
                     │      [SessionStart]      │
                     │                          │
       ┌─────────────┴──────────────────────────┴────────┐
       │  Você (humano) — não precisa lembrar de nada     │
       └──────────────────────────────────────────────────┘
                     │
                     ▼
              No Cursor:
              ┌──────────────┐
              │ Rule         │
              │ alwaysApply  │ → sugere @setup-checker proativamente
              └──────────────┘
```

### Idempotência é a chave

O `setup.sh` é **idempotente**: roda 1x ou 100x, dá o mesmo resultado. Isso permite que múltiplas formas de invocá-lo coexistam sem coordenação. Detalhes: [`docs/learnings/2026-05-28-idempotency-enables-multi-entry-tooling.md`](../ideiapartner/docs/learnings/2026-05-28-idempotency-enables-multi-entry-tooling.md) no projeto ideiapartner (espelho global em memória Claude).

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
cd dev-setup
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
dev-setup/
├── setup.sh                                ← script principal, idempotente
├── agents/
│   ├── claude-continuation.md              ← Cursor agent
│   └── setup-checker.md                    ← Cursor agent — audita setup
├── skills/
│   ├── cursor-continuation/SKILL.md        ← Claude — retoma do Cursor
│   ├── lovable-handoff/SKILL.md            ← Claude — playbook Lovable
│   ├── recall-learnings/SKILL.md           ← Claude — load context
│   ├── extract-learnings/SKILL.md          ← Claude — registra aprendizado
│   └── dev-setup/SKILL.md                  ← Claude — audita setup
├── hooks/
│   ├── extract-learnings-reminder.sh       ← Claude PostToolUse Bash
│   └── dev-setup-detector.sh               ← Claude SessionStart
├── scripts/
│   └── install-alias.sh                    ← Instala alias idea-setup
├── templates/
│   ├── aiox-ai-config.yaml                 ← Config IA do projeto
│   ├── hybrid/
│   │   ├── AGENTS.md.tmpl                  ← Identidade do projeto
│   │   ├── CLAUDE.md.tmpl                  ← Instruções Claude
│   │   ├── STATE.md.tmpl                   ← Snapshot operacional
│   │   ├── CONTINUATION_HANDOFF.md.tmpl    ← Handoff de continuidade
│   │   ├── agents-md-protocol.mdc.tmpl     ← Cursor rule principal
│   │   ├── planning-branch.mdc.tmpl        ← Convenção branch planning
│   │   └── session-continuation.mdc.tmpl   ← Rule de retomada
│   ├── lovable/
│   │   ├── AGENTS.lovable.md.tmpl          ← Seção Lovable no AGENTS.md
│   │   ├── playbook-implantacao.md.tmpl    ← Fluxo obrigatório
│   │   ├── conclusao-implantacao.md.tmpl   ← Modelo de resposta (8 blocos)
│   │   └── _TEMPLATE.md.tmpl               ← Esqueleto de handoff Lovable
│   └── learnings/
│       ├── README.md.tmpl                  ← Convenções
│       └── _TEMPLATE.md.tmpl               ← Esqueleto de learning
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
      }
    ],
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "bash \"/Users/<você>/.claude/hooks/dev-setup-detector.sh\"",
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

Se não existir, roda `@setup-checker` no chat ou `idea-setup` no terminal.

### "Como sei se o setup está completo?"

No Claude Code: `/dev-setup` → mostra ✅/❌ por componente.
No Cursor: `@setup-checker` → idem.
No terminal: roda setup e ele lista o que foi feito vs pulado.

### "Posso rodar várias vezes seguidas sem estragar nada?"

Sim. **Idempotência** é design fundamental. Pula tudo que já está instalado, atualiza só o que mudou.

### "OPENROUTER_API_KEY pra que serve?"

Chave opcional que habilita um modelo mais barato (DeepSeek via OpenRouter) para tarefas simples. Crie conta gratuita em [openrouter.ai](https://openrouter.ai) e adicione no `.env` do projeto:

```bash
OPENROUTER_API_KEY=sk-or-...
```

### "Funciona com qualquer stack?"

Sim. Os agentes/skills leem histórico, memória e estado — não dependem de linguagem ou framework.

---

## 📚 Documentação complementar

Os 4 padrões emergentes do trabalho real estão capturados como **learnings** com versão expandida nos repos:

| Learning | Quando aplicar |
|----------|----------------|
| `bug-persists-after-fix-likely-deploy-drift` | Sintoma persiste em produção após fix aparente |
| `schema-first-verification-before-prod-updates` | Antes de UPDATE/INSERT em produção |
| `inline-hotfixes-need-explicit-repo-sync` | Lovable/IA externa corrigiu inline no edge |
| `protocol-discipline-needs-hooks-not-guidelines` | Antes de desenhar protocolo "obrigatório" para IA |
| `idempotency-enables-multi-entry-tooling` | Antes de adicionar segunda forma de invocar ferramenta |

Versões expandidas em `docs/learnings/` de qualquer projeto Lovable do setup. Espelhos em memória Claude global de quem clonou o dev-setup.

---

## 🤝 Contribuindo

- Cada mudança em template/skill/hook precisa atualizar o setup.sh para idempotência
- Testar com `bash -n setup.sh` (syntax) + smoke test em projeto Lovable de teste
- Atualizar este README quando adicionar componente novo
- Seguir o protocolo Fase A: criar learning se mudança gerar padrão replicável

---

## ❓ Dúvidas rápidas

- **Preciso rodar o setup toda vez que abrir um projeto?** Não. Uma vez instalado, vale pra sempre.
- **E se eu usar Windows?** Use WSL — o setup.sh assume bash/zsh em ambiente Unix-like.
- **Lovable vai sobrescrever meu AGENTS.md?** Não. A camada Lovable usa marcadores `BEGIN/END` para preservar conteúdo customizado.
- **Posso desativar o loop de aprendizado em um projeto?** Sim. Remova a seção `Loop de aprendizado contínuo` do `AGENTS.md` — hooks param de disparar automaticamente.

---

*Última atualização: 2026-05-28*
*Mantido por: equipe Ideia Business + IAs (Claude Code, Cursor)*
