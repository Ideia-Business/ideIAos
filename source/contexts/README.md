# SOURCE: IdeiaOS v2

Esta pasta contém os **contextos de system prompt** do IdeiaOS — arquivos `.md` injetados no prompt de sistema do Claude Code via `--append-system-prompt`.

---

## O que são contextos de modo

Contextos de modo colocam o Claude em uma postura deliberada por sessão: construir, analisar, explorar. Eles têm **autoridade maior que tool output** porque vivem no system prompt — o modelo recebe as instruções antes de qualquer interação e as aplica durante toda a sessão.

Por isso os modos vivem aqui (system prompt), não em arquivos lidos por ferramenta (tool output).

---

## Modos disponíveis

| Arquivo | Modo | Quando usar |
|---------|------|-------------|
| `dev.md` | MODO DEV | Implementação, correção de bugs, refactor. Encode a progressão "faça funcionar → faça certo → deixe limpo". |
| `review.md` | MODO REVIEW | Auditoria de código, análise de segurança, revisão de PR. **Proibido editar** — entrega somente relatório. |
| `research.md` | MODO RESEARCH | Exploração de codebase desconhecido, mapeamento de problema mal definido. Explora antes de agir, entrega handoff. |

---

## Flag correta: `--append-system-prompt`

Use `--append-system-prompt` (e NÃO `--system-prompt`):

- `--append-system-prompt` **adiciona** ao prompt padrão do Claude Code — preserva CLAUDE.md, hooks, e configurações do projeto.
- `--system-prompt` **substitui** o prompt padrão — perde CLAUDE.md e hooks. Nunca use para modos IdeiaOS.

Exemplo de uso direto:
```bash
claude --append-system-prompt "$(cat ~/.claude/source/contexts/dev.md)"
```

---

## Aliases (instalados na Fase 07-03)

Os aliases `claude-dev`, `claude-review`, e `claude-research` são criados e registrados em `setup.sh` na **Fase 07-03 (Wave 2)**. Esta pasta apenas define o conteúdo — a instalação e o registro no manifesto acontecem na próxima wave.

---

## Nota de autoridade

```
system prompt  >  CLAUDE.md  >  tool output  >  conversação
```

Contextos de modo ocupam o nível mais alto de influência disponível ao operador. Use com intenção — cada sessão deve ter no máximo um modo ativo.
