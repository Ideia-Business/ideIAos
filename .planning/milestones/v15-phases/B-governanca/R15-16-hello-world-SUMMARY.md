# R15-16 — Hello-world de 10 min · SUMMARY

**Status:** ✅ DONE 2026-06-26 · **Wave:** 1 · **Executor:** sessão principal

## O que foi feito

- **§0.5 "Hello-world — veja o valor em ~10 min"** em `docs/guides/onboarding-novo-dev.md` (entre §0
  acessos e §1 setup): um dev que já tem os acessos clona o mínimo, abre o Claude Code e a **Deia** o
  situa — `Deia, primeira vez aqui — me dá um tour` roda `/code-tour`; `Deia, o que tem disponível?`
  roda `/ideiaos-catalog`. Termina com **`idea-smoke.sh`** (exit 0 = bootstrap mínimo OK). Aponta a
  **§7** p/ o dia-a-dia (single-source — não duplica) e §1–6 p/ o setup. "Trailer vs filme."
- **Linha de roteamento** na matriz da Deia (`source/skills/idea/SKILL.md`, após a de `/code-tour`):
  "primeira vez aqui / me dá um tour / tour de 10 min / hello world / me mostra o valor / novo no
  ideiaos" → tour hello-world (situa + `/code-tour` + `/ideiaos-catalog`, termina no `idea-smoke.sh`).

## Verificação (gate / exit-code)

| Gate | Resultado |
|------|-----------|
| §0.5 completa: smoke + `/code-tour` + `/ideiaos-catalog` + referencia §7 | ✅ |
| a frase de hello-world roteia para `/code-tour` (requisito explícito) | ✅ |
| **No-Invention:** não crava 196/42-rules/17-hooks — usa "dezenas" + catálogo vivo | ✅ |
| `idea-smoke.sh` exit 0 (a prova binária que o hello-world promete é real) | ✅ |
| skill idea válida (frontmatter + 73 linhas de tabela na matriz) | ✅ |

## Decisões

- **Não cravar números:** o requisito citava "~196 affordances / 42 rules / 17 hooks", mas o
  `modules.json` real tem 101 (47 skills, 19 agents, 13 hooks, 7 rules). Em vez de cravar (e driftar),
  o hello-world diz "dezenas" e aponta o catálogo VIVO (`/ideiaos-catalog` conta em runtime). Honra o
  espírito anti-decoreba do requisito sem inventar número.
- **Single-source:** o hello-world é o "preview ANTES do setup"; a §7 é "o dia-a-dia DEPOIS". Distintos
  e ligados — o hello-world aponta a §7, não copia.
- **Deploy global** da Deia é housekeeping (`setup.sh --global-only`, gated por versão) — fora do
  escopo do requisito (a fonte está correta).

## Arquivos

- `docs/guides/onboarding-novo-dev.md` (§0.5), `source/skills/idea/SKILL.md` (linha de roteamento).
- PLAN/SUMMARY. (Nenhum arquivo novo na árvore → README inalterado.)
