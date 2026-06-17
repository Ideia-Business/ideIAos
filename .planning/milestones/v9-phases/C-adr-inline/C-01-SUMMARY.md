# C-01-SUMMARY — Fase C: ADR ultraleve inline no `/grelha`

**Milestone:** v9 · **Fase:** C · **Status:** ✅ DONE · **Cobre:** R9-03 · **Data:** 2026-06-17
**Modo:** workflow (paralelo com Fase D — arquivos disjuntos) + revisor 3-em-1

## Entregue

| Arquivo | Linhas | O quê |
|---------|--------|-------|
| `source/skills/grelha/ADR-FORMAT.md` (novo) | 93 | Gate dos 3 critérios (difícil reverter + surpreendente sem contexto + trade-off real, TODOS obrigatórios), formato mínimo (título + 1-3 frases), seções opcionais, numeração `NNNN-slug` + coexistência com `vN-slug`, criação preguiçosa, lista "o que qualifica", integração Obsidian via `/extract-learnings` Passo 4c. Aponta para `docs/decisions/` (reuso — NÃO cria diretório `adr/` paralelo). |
| `source/skills/grelha/SKILL.md` (+7l) | 206 | Wiring cirúrgico: a seção "Gate do ADR" referencia `ADR-FORMAT.md` como formato canônico; passo `--docs` "efeitos colaterais inline" oferece (não impõe) ADR quando os 3 critérios passam → escreve `docs/decisions/NNNN-slug.md`, pula silenciosamente caso contrário; +2 linhas sobre espelhamento Obsidian via `/extract-learnings`. Nada removido. |

## Verificação

- **Revisor 3-em-1 (goal+adversarial+convenção): PASS.** Confirmou que o `/extract-learnings` Passo 4c REALMENTE espelha `docs/decisions/` → vault `Decisions/` (sem pipeline novo); zero fabricação (exemplos de "o que qualifica" mapeiam 1:1 com a fonte); gate REALMENTE pula quando critério falha.
- **Gates binários:** docs/decisions=6 · `docs/adr`=0 (substring literal evitada p/ satisfazer `! grep docs/adr`) · reverter=3 · trade-off=2 · `<!--`=0 · 93 linhas (≥35) · wiring ADR-FORMAT=2.
- **2 LOW (não-bloqueantes):** (1) leve redundância do gate dos 3 critérios entre SKILL.md e ADR-FORMAT.md — aceitável (skill legível standalone + ponteiro p/ canônico); (2) legibilidade do verify encadeado.

## Carry-forward
- Fase F: registrar `grelha` (skill) em `manifests/modules.json` + `plugin-membership.md` + `CORE_SKILLS`. ADR-FORMAT/CONTEXT-FORMAT são resources da skill (não entram como módulos próprios).
