# AGENTS.md — IdeiaOS

> Este repositório é a **implementação do IdeiaOS** — Sistema Operacional unificado de desenvolvimento da Ideia Business.
> Documento canônico de design: [`docs/IDEIAOS.md`](docs/IDEIAOS.md).
> Mudanças aqui afetam **todos os projetos** que usam o setup. Trate com cuidado.

## Continue / resume (padrão híbrido)

Quando o pedido for genérico ("continuar", "retomar", etc.), leia nesta ordem:

1. `docs/IDEIAOS.md` (especificação canônica — sempre primeiro neste repo)
2. `docs/CONTINUATION_HANDOFF.md` (estado operacional no `main`)
3. `STATE.md` (snapshot curto)
4. `planning:.planning/STATE.md` e `planning:.planning/ROADMAP.md` (quando existir no projeto-alvo)

## Fechamento de sessão (obrigatório)

Antes de encerrar qualquer sessão:

1. Atualize `STATE.md` com estado real.
2. Atualize `docs/CONTINUATION_HANDOFF.md` com:
   - o que foi feito,
   - pendências,
   - próximo passo executável.
3. Se houve decisão estratégica, sincronize `.planning/*` no branch `planning` (quando aplicável).

## Fonte de verdade

- Curto prazo operacional: `STATE.md` + `docs/CONTINUATION_HANDOFF.md`.
- Médio/longo prazo: `.planning/*` no branch `planning` (nos projetos que usam esse fluxo).

## Git

Sempre sincronize (`git pull`) antes de editar, especialmente em projetos com Lovable/agents em paralelo.

## Manutenção do README (obrigatório)

Toda mudança em `hooks/`, `skills/`, `agents/`, `scripts/` ou `templates/` **DEVE** vir acompanhada de atualização correspondente no `README.md`:

1. Seção **"O que este setup instala"** (tabelas de componentes globais e do projeto)
2. Seção **"Estrutura do repositório"** (árvore de pastas)
3. Se for skill/agent novo: seção **"Como usar no dia a dia"**
4. Se for hook novo: seção **"Manutenção do próprio IdeiaOS"** (scripts) ou seção troubleshooting

**Enforcement (barreira ativa):**

- Pre-commit hook do Git (instalado via `bash scripts/install-git-hooks.sh`) **bloqueia** commits que mexam em componentes sem incluir `README.md` no commit OU sem passar no `scripts/check-readme-sync.sh`.
- Hook Claude Code `ideiaos-readme-reminder.sh` (PostToolUse Edit/Write) injeta lembrete imediato quando a IA modifica componente.
- Validação manual: `bash scripts/check-readme-sync.sh` — output ✅/❌ por componente.

**Por que existe:** em 28/05/2026 o README ficou 1 sessão inteira desatualizado sem ninguém notar — barreira ativa > documentação passiva ([[learning-protocol-discipline-needs-hooks-not-guidelines]]).
