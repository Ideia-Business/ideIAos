# Ideia Business — Dev Setup

Configura o ambiente de IA para qualquer projeto da equipe em um único comando.

## O que este setup instala

| Componente | O que faz |
|-----------|-----------|
| **AIOX Core** | Orquestrador de agentes IA — base de tudo (https://github.com/SynkraAI/aiox-core) |
| **Agente Cursor** (`claude-continuation`) | No Cursor: retoma automaticamente o que você estava fazendo no Claude Code |
| **Skill Claude Code** (`cursor-continuation`) | No Claude Code: retoma automaticamente o que você estava fazendo no Cursor |

Os dois agentes formam um par que mantém o contexto entre as duas ferramentas, sem precisar re-explicar o trabalho a cada sessão.

---

## Requisitos

- **Node.js 18+** — [nodejs.org](https://nodejs.org)
- **Cursor IDE** — [cursor.sh](https://cursor.sh)
- **Claude Code CLI** — [claude.ai/code](https://claude.ai/code)
- **Git**

---

## Instalação (fazer uma vez)

```bash
# 1. Clone este repositório
git clone https://github.com/Ideia-Business/dev-setup.git

# 2. Entre na pasta e rode o setup
cd dev-setup
bash setup.sh
```

Pronto. Os agentes ficam instalados globalmente e funcionam em **qualquer projeto** que você abrir no Cursor ou no Claude Code.

---

## Configurar um projeto específico

Para aplicar o setup em um projeto existente (cria `.aiox-ai-config.yaml`, memória Claude e estrutura `.planning/`):

```bash
bash setup.sh /caminho/para/o/projeto

# Exemplo:
bash setup.sh ~/Projects/meu-projeto
```

Modo somente projeto (não instala/atualiza componentes globais):

```bash
bash setup.sh --project-only /caminho/para/o/projeto
```

Inicializar também o **AIOX Core local** do projeto (`.aiox-core`) no mesmo comando:

```bash
bash setup.sh --with-aiox-core-project /caminho/para/o/projeto
```

---

## Como usar no dia a dia

### No Cursor
Quando abrir um projeto e quiser saber o que estava fazendo no Claude Code:
> "retoma o que estava no Claude Code"
> "continua onde parei"

O agente `claude-continuation` lê automaticamente o histórico e memória do Claude Code e te dá um resumo completo do estado do projeto.

### No Claude Code
Quando abrir o Claude Code e quiser saber o que estava fazendo no Cursor:
```
/cursor-continuation
```
Ou simplesmente diga:
> "retoma o contexto do Cursor"

O skill `cursor-continuation` lê os planos, estado do projeto, git recente e te entrega um handoff completo.

---

## Mantendo os agentes atualizados

Quando houver melhorias nos agentes, basta rodar novamente:

```bash
cd dev-setup
git pull
bash setup.sh
```

O script detecta automaticamente se há diferença e atualiza só o que mudou.

---

## Padrão híbrido de continuidade (instalado pelo setup)

Ao configurar um projeto, o script cria (apenas se não existirem):

- `AGENTS.md`
- `CLAUDE.md`
- `STATE.md`
- `docs/CONTINUATION_HANDOFF.md`
- `.cursor/rules/session-continuation.mdc`

Esse conjunto padroniza retomada entre Cursor/Claude/Lovable:
- operacional no `main` (`STATE` + handoff),
- estratégico no `planning` (quando o projeto usa `.planning/`).

Se quiser inicializar também o **AIOX Core local do projeto** (`.aiox-core`), use a flag `--with-aiox-core-project`.

---

## Estrutura do repositório

```
dev-setup/
├── setup.sh                              ← script principal
├── agents/
│   └── claude-continuation.md            ← agente Cursor
├── skills/
│   └── cursor-continuation/
│       └── SKILL.md                      ← skill Claude Code
└── templates/
    └── aiox-ai-config.yaml               ← template de config IA
```

---

## Dúvidas frequentes

**Preciso rodar o setup toda vez que abrir um projeto?**
Não. Roda uma vez e os agentes ficam instalados globalmente.

**E se eu quiser usar em um projeto que já existe?**
`bash setup.sh /caminho/do/projeto` — adiciona só o que está faltando.

**O que é o OPENROUTER_API_KEY?**
Uma chave opcional que habilita um segundo modelo de IA mais barato (DeepSeek via OpenRouter) para tarefas simples, economizando créditos do Claude. Crie uma conta gratuita em [openrouter.ai](https://openrouter.ai) e adicione no `.env` do projeto: `OPENROUTER_API_KEY=sk-or-...`

**Os agentes funcionam com qualquer linguagem/framework?**
Sim. Eles leem o histórico de sessões e o estado do projeto — não dependem da stack.
