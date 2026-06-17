# B-01-SUMMARY — Fase B: `/grelha` + glossário `CONTEXT.md` + rule ubiquitous-language

**Milestone:** v9 (Camada de Alinhamento) · **Fase:** B (caminho crítico) · **Status:** ✅ DONE
**Cobre:** R9-01 (GAP 2 — grilling colaborativo pré-plano) · R9-02 (GAP 1 — glossário ubíquo durável)
**Data:** 2026-06-17 · **Modo:** workflow (1 builder + painel 3-lentes), orquestrador commitou

## Entregue

| Arquivo | Linhas | O quê |
|---------|--------|-------|
| `source/skills/grelha/SKILL.md` | 198 | Skill `/grelha` (alias `/grill`) frontmatter-first PT-BR: grilling colaborativo pré-plano, 1 pergunta por vez com resposta recomendada, lê o código quando explorável; modos `--docs` (default em código) e `--rapido` (não-código); fronteira `/grelha × gsd-discuss-phase × /doubt`; R8-04 (anti-racionalização + red flags + verificação) |
| `source/skills/grelha/CONTEXT-FORMAT.md` | 93 | Formato do glossário `CONTEXT.md` (adaptado PT-BR do upstream): 5 regras de ouro (opinativo / tight / só-domínio / zero-implementação / agrupar), single vs multi-context (`CONTEXT-MAP.md`), criação preguiçosa |
| `source/skills/grelha/templates/CONTEXT.md.tmpl` | 9 | Esqueleto mínimo PT-BR do glossário (copiado p/ raiz do projeto-alvo no 1º termo) |
| `source/rules/common/ubiquitous-language.md` | 66 | Rule: princípio Evans/DDD + a TABELA dos 3 CONTEXT (glossário `CONTEXT.md` × `{phase}-CONTEXT.md` GSD × `specs/<cap>/spec.md` /spec) + como /spec e GSD consomem os termos canônicos |
| `source/skills/idea/SKILL.md` | +1 linha | 1 rota direta para `/grelha` na matriz (o Passo 1.5 gate é Fase D) |

## Fonte adaptada

`grill-me.md` (prompt-núcleo) + `grill-with-docs.md` (modo `--docs`) + `grill-with-docs/CONTEXT-FORMAT.md` da quarentena `mattpocock/skills` (MIT, commit `694fa30`), nativizados PT-BR. Postura **colaborativa** preservada (oposta ao `/doubt` adversarial), **sob orquestração da Deia** — conforme ADR `docs/decisions/v9-mattpocock-skills-absorcao.md`. Conceito de linguagem ubíqua creditado a Evans/DDD; a forma `CONTEXT.md`, a Pocock.

## Verificação

- **Painel 3-lentes:** verifier goal-backward = **PASS** (R9-01+R9-02 entregues); convenção R8-04 = CONCERNS só por falso-positivo de gate `<!--` em rule (header `<!--SOURCE-->` é convenção correta); `/doubt` adversarial = CONCERNS com 1 **MED**.
- **MED corrigido:** citação ao _Pragmatic Programmer_ estava embelezada (glosa dentro da atribuição). Corrigida: literal `"Ninguém sabe exatamente o que quer" (Thomas & Hunt)` separada da paráfrase. Eco do precedente do dogfood do `/doubt`.
- **Gates binários:** `name: grelha` ✓; SOURCE ✓; `--docs`/`--rapido` ✓; fronteira ✓; R8-04 ✓; ZERO `<!--` em SKILL/CONTEXT-FORMAT/template ✓; rule com TABELA dos 3 CONTEXT ✓; rota `/grelha` na Deia sem remover rotas existentes ✓.
- **Deploy (dry-run):** a rule deploya em `.claude/rules/ideiaos-common-ubiquitous-language.md` + `.cursor/rules/ideiaos-common-ubiquitous-language.mdc` (paridade R8-09 confirmada).

## Decisões / desvios

- `docs/adr/` (upstream) → **`docs/decisions/`** (reuso do diretório existente) — sancionado pelo ADR e pela pesquisa.
- Hooks PREVISTOS mas diferidos corretamente: Passo 1.5 gate na Deia = **Fase D**; `ADR-FORMAT.md` = **Fase C** (o gate dos 3 critérios já está documentado na SKILL.md).
- Reset de sessão pós-quarentena (gate A→B): satisfeito estruturalmente por isolamento de subagente (conteúdo de terceiro lido em contexto descartável, scan limpo, output revisado).

## Carry-forward

- **Fase C:** criar `source/skills/grelha/ADR-FORMAT.md` (gate dos 3 critérios + formato mínimo) e fiar o "oferece ADR" do `/grelha` em `docs/decisions/`.
- **Fase D:** Passo 1.5 (gate de alinhamento opcional) + nota de fronteira longa em `idea/SKILL.md`.
- **Fase F:** registrar a rule + skill em `manifests/modules.json` + `plugin-membership.md` + `CORE_SKILLS` (drift-guard R7-07); confirmar paridade de deploy no build real.
- **`/grill` alias:** validado como gatilho no `description`; confirmar no loader de skills se exige campo de alias dedicado (LOW).
