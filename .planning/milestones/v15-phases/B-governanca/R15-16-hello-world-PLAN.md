# R15-16 — Hello-world de 10 min (vende o valor antes do custo do setup) · PLAN

**Milestone:** v15 · **Fase:** B · **Wave:** 1 · **Req:** R15-16 · **Origem:** INST-07 · **Imp/Esf:** 4/2

## Objetivo (goal-backward)

Um dev novo (já com os **acessos da §0**) vê o VALOR do ideIAos em ~10 min ANTES de pagar o custo do
setup completo (§1–6). Termina com prova binária (`idea-smoke.sh`). Anti-decoreba: aponta o catálogo
vivo (`/ideiaos-catalog`), não uma lista para memorizar.

## Contexto verificado (No-Invention)

- Onboarding `docs/guides/onboarding-novo-dev.md`: §0 = acessos, §1–6 = setup, **§7 = "Primeira sessão
  / dia a dia"** (a fonte única do dia-a-dia — o hello-world NÃO a duplica, aponta para ela).
- A matriz da Deia (`source/skills/idea/SKILL.md`) JÁ roteia `/code-tour` (linha 92) e
  `/ideiaos-catalog` (linha 102) — faltava a entrada de **hello-world/boas-vindas**.
- `idea-smoke.sh` (R15-03) existe e é puro-bash (roda no ambiente meio-instalado) — perfeito p/ a
  prova binária antes do setup completo.
- **Contagem real do `modules.json` = 101** (47 skills, 19 agents, 13 hooks, 7 rules) — os números do
  requisito (17 hooks, 42 rules, ~196) NÃO batem; o hello-world usa "dezenas" + aponta o catálogo
  vivo (sem cravar número que drifta).

## Tasks

1. **§0.5 "Hello-world (~10 min)"** no onboarding (entre §0 e §1): clone mínimo → a Deia situa + roda
   `/code-tour` + `/ideiaos-catalog` → `idea-smoke.sh` (exit 0). Single-source: aponta §7 p/ o
   dia-a-dia e §1–6 p/ o setup. "Trailer vs filme".
2. **Linha de roteamento** na matriz da Deia: "primeira vez aqui / me dá um tour / hello world / …"
   → tour hello-world (situa + `/code-tour` + `/ideiaos-catalog`, termina no `idea-smoke.sh`).

## Gates (exit-code / grep)

| Gate | Verificação | Resultado |
|------|-------------|-----------|
| 1 | §0.5 existe + termina com `idea-smoke.sh` + aponta `/code-tour` + `/ideiaos-catalog` + referencia §7 | ✅ |
| 2 | a frase de hello-world roteia para `/code-tour` (requisito) | ✅ |
| 3 | **No-Invention:** não crava 196/42-rules/17-hooks (usa "dezenas" / catálogo vivo) | ✅ |
| 4 | `idea-smoke.sh` roda exit 0 (a prova binária é real) | ✅ |
| 5 | skill idea ainda válida (frontmatter + tabela markdown) | ✅ |

## Nota de deploy

A fonte (`source/skills/idea/SKILL.md`) é o que conta no repo. Para a Deia GLOBAL (instalada) pegar a
linha nova: `setup.sh --global-only` (gated por versão do SKILL.md — ver
`global-skill-deploy-version-gated-misses-lib-changes`). Fora do escopo de R15-16 (housekeeping).
