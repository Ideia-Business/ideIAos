# Milestone Audit — v8: Camada de Disciplina

**Data:** 2026-06-16
**Veredito:** ✅ **PASSED / SHIPPED** (tag v8.0)

## Requisitos

| ID | Requisito | Status |
|----|-----------|--------|
| R8-01 | Skill `/doubt` (doubt-driven, 5 passos, spawn adversarial) | ✅ |
| R8-02 | Rule `operating-discipline` (6 condutas, Claude+Cursor) | ✅ |
| R8-03 | Skill `/context-engineering` | ✅ |
| R8-04 | Convenção anti-racionalização + template de skill | ✅ |
| R8-05 | Opt-in `/observability` + `/deprecation-migration` (plugin:null) | ✅ |
| R8-06 | Quarentena + atribuição MIT | ✅ |
| R8-07 | Dogfood doubt-driven sobre o diff | ✅ |
| R8-08 | Wiring + gates binários verdes | ✅ |
| R8-09 | Deploy de rules common p/ projetos Claude-Code-alvo | ✅ (fechado 2026-06-16 — `build-adapters` Claude rules) |

**Cobertura: 9/9 — R8-09 fechado em follow-up (`build_claude_project_rules()` no `build-adapters.sh`, verificado em sandbox).**

## Gates binários (exit code, não Read)

| Gate | Resultado |
|------|-----------|
| `security/scan-absorbed.sh` | PASS=3 WARN=1 (AgentShield offline) FAIL=0 → **exit 0** |
| `node JSON.parse modules.json` | **OK** |
| `check-plugin-membership.sh` | **71 módulos, sem deriva** |
| `check-readme-sync.sh` | **111/111 mencionados, 0 faltando** |
| `build-plugins.sh` | doubt + context-engineering empacotados; opt-in fora (plugin:null) — **exit 0** |
| `build-adapters.sh` | `operating-discipline.md` → `.cursor/rules/*.mdc` — **exit 0** |
| `idea-doctor.sh` | OK 61 · WARN 1 (pré-existente) · **FAIL 0** |
| `tests/spec-merge.bats` | **27/27 VERDE** (sem regressão) |

## Dogfood — doubt-driven sobre o próprio milestone (R8-07)

Subagente adversarial (`general-purpose`, prompt issues-only) sobre o diff v8. **8 achados; reconciliação:**

| # | Severidade | Classificação | Ação |
|---|-----------|---------------|------|
| 1 | IMPORTANTE | acionável | **FIX** — `/doubt` citava `agent-authority.md "personas não invocam outras personas"` (frase inexistente no repo). Citação fabricada removida — *a própria skill de duvidar pegou a si mesma inventando uma autoridade.* |
| 3 | IMPORTANTE | acionável | **FIX** — contradição `plugin-membership.md` (rules=null) × `modules.json` (rules=ideiaos-core); reescrito: tag de catálogo ≠ empacotamento. |
| 5 | MENOR | acionável | **FIX** — nota de que `general-purpose` é built-in (os outros 5 reviewers são custom em `source/agents/`). |
| 6 | MENOR | trade-off | aceito — fraseado de gatilho não-espelhado, ambos casam por NL. |
| 2 | IMPORTANTE | ~~trade-off herdado~~ → **FIX (follow-up)** | **R8-09 fechado** — `build-adapters.sh build_claude_project_rules()` deploya `common/` → `.claude/rules/` (paridade com Cursor). Verificado em sandbox `/tmp` + dogfood no repo. |
| 4 | MENOR | ruído/ortogonal | documentado — label `(opus)` stale de `silent-failure-hunter` na matriz (pré-existente); scope discipline → não tocar. |
| 7,8 | RUÍDO/positivo | — | sem ação — fallback de `/doubt` coerente; sem duplicação real com ECC. |

**STOP:** 1 ciclo, achados acionáveis corrigidos e re-verificados (citação fabricada ausente em source + plugin; gates re-verdes). Restantes documentados.

## Veredito

A camada de disciplina foi absorvida nativamente, sem duplicar o ECC, plugada na Deia/GSD/AIOX. O milestone **dogfoodou a própria entrega** (doubt-driven encontrou e corrigiu um defeito real no `/doubt`). Wiring consistente nas 4 fontes, todos os gates verdes. **SHIPPED.**

> **Atribuição:** conteúdo absorvido de `addyosmani/agent-skills` (MIT), nativizado PT-BR. Fonte em `security/quarantine/agent-skills/`.
