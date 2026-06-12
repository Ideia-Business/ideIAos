---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: milestone
status: Ready to plan
last_updated: "2026-06-12T03:38:57.223Z"
progress:
  total_phases: 8
  completed_phases: 6
  total_plans: 22
  completed_plans: 22
  percent: 100
---

# State — IdeiaOS v2

**Atualizado:** 2026-06-12
**Milestone:** v2.0 — Canivete Suíço Universal (absorção ECC)

## Snapshot

| Item | Status |
|------|--------|
| PROJECT.md + ROADMAP.md | ✅ Criados via /gsd-import (2026-06-11) |
| Plano-fonte | `.planning/research/ECC-ABSORPTION-PLAN.md` |
| Fase 01 — quality-memory-hooks | ✅ Completa |
| Fase 02 — security-quarantine | ✅ Completa (VERIFICATION.md PASSED) |
| Fase 03 — multiharness-rules | ✅ Completa (4/4 planos) |
| — 03-01 source/ migration | ✅ Completo (commit 466a16f) |
| — 03-02 manifests + stack detection | ✅ Completo (commit 0ca4a27) |
| — 03-03 rules layer | ✅ Completo (commit ebcfc06) |
| — 03-04 build-adapters.sh + Wave 2 | ✅ Completo (commit 4ada601) |
| Fase 04 — ecc-catalog | ✅ Completa (4/4 planos) |
| — 04-01 ECC review agents | ✅ Completo (commit 6555a16) |
| — 04-02 ECC worker agents | ✅ Completo (commit 2cb9d98) |
| — 04-03 ECC workflow skills | ✅ Completo (commit eccc1ac) |
| — 04-04 receitas + catalog + manifests + /idea + README | ✅ Completo (commit 2197f2f) |
| Fase 05 — instincts | ✅ Completa (3/3 planos) |
| — 05-01 captura de observações | ✅ Completo (commit f9137a5) |
| — 05-02 motor de instincts | ✅ Completo (commit 24f1e92) |
| — 05-03 integração Wave 2 | ✅ Completo (commit 0b16996) |
| Fase 06 — plugin-marketplace | ⬜ Não planejada |
| Fase 07 — contexts-evals | ⬜ Não planejada |
| Fase 08 — ideiaos-v3-review | ⬜ Não planejada (após 04-07) |

## Próximo passo

Fase 05 completa (3/3 planos). Próximo: Fase 06 — plugin-marketplace (não planejada ainda).

## Decisões Registradas

- **03-01:** `source/` como fonte única de verdade; dirs originais (skills/, agents/, hooks/, templates/) mantidos como fallback até 03-04 Wave 2 os remover após verificação de integração.
- **03-01:** `source/contexts/` criado vazio — será populado na Fase 07 (07-contexts-evals).
- **03-02:** `manifests/modules.json` como fonte de verdade ECC para 33 módulos IdeiaOS (hooks, agents, skills, templates).
- **03-02:** `detect_stack()` no setup.sh detecta 7 stacks (node/typescript/react/nextjs/supabase/lovable/python) — base para instalação seletiva em Phase 04+.
- **03-03:** `source/rules/ecc/` permanece placeholder vazio — populado em 03-04 após quarentena ECC. Header `<!--SOURCE: IdeiaOS v2 | kind: rule | targets: ...-->` em todos os arquivos para rastreabilidade pelo `build-adapters.sh`.
- **03-04:** Header ECC absorvido como `# SOURCE: ECC MIT` (Markdown heading) em vez de `<!--SOURCE:...-->` (HTML comment) — scan-absorbed.sh Check 2 detecta `<!--` como payload HTML, falso positivo bloqueante.
- **03-04:** Dirs originais (skills/, agents/, hooks/) mantidos — remoção definitiva na Fase 06.
- **03-04:** ECC rules (common, typescript, react) criadas inline com curadoria IdeiaOS; WARNs de `nc ` são falsos positivos (substring em "function"/"sync"/"async"), inspecionados e aprovados.
- **04-04:** skills-receita ECC (two-instance-kickoff, llms-txt, mcp-to-cli) com `installStrategy: manual` — receitas sob demanda.
- **04-04:** skill-ideiaos-catalog com `installStrategy: always` — meta-ferramenta universal.
- **04-04:** campo `model` adicionado ao schema de agent em modules.json (extensão retrocompatível).
- **04-04:** mgrep e LSP plugins documentados como candidatos Fase 08 — nada instalado nesta fase.
- **04-04:** manifests/modules.json: 33→60 módulos (+27: 13 agents + 14 skills da Fase 04).
- **05-02:** schema do instinct definido como contrato central: trigger, action, confidence 0.3-0.9, domain, scope, evidence_count, created, updated, source — consumido por /instinct-analyze, /learn, /instinct-status e /evolve (05-03).
- **05-02:** dedup por slug(trigger) compartilhado entre /instinct-analyze e /learn — mesma regra nos dois para não divergir.
- **05-02:** confidence manual (/learn) nasce em 0.5; análise automática começa em 0.3-0.6 conforme número de evidências; reforço +0.1 por ciclo, cap 0.9.
- **05-02:** docs/instincts/instincts-layout.md entrou no repo via autosync (commit 3303c7a) antes do feat commit — conteúdo correto, desvio documentado.
- **05-01:** bash_verb captura somente o 1º token do comando Bash, descartando args/flags — privacidade por design. "jq " em comentário era falso positivo no Check 6; corrigido para "Sem-jq:".
- **05-01:** session_end usa tool+event ambos como "session_end" para facilitar detecção em 05-02 sem campo adicional.
- **05-03:** /evolve usa referência em prosa ao formato de rule header (sem literal HTML-comment no corpo da skill, per no-`<!--` constraint; reader é direcionado para `source/rules/common/*.mdc`).
- **05-03:** recall-learnings Passo 6 instincts inserido antes de postmortems; postmortems renumerado Passo 7. Saída esperada ganhou linha "Instincts aplicáveis".
- **05-03:** manifests/modules.json: 60→66 módulos (+6: 2 hooks observe + 4 skills instinct-analyze/instinct-status/learn/evolve). Fase 05 completa.

## Notas

- Decisões travadas em PROJECT.md `<decisions>` — quarentena obrigatória antes de qualquer absorção de terceiros.
- Plans: 12 criados (4 por fase para fases 01-03), 9 executados (fases 01+02 completas + 03-01).
- Fase 02 checker: 3 warnings menores (sem blockers) — I-01 cosmético, I-02 HTML payload test, I-03 python3 quoting (endereçar na execução).

## Compact Snapshot

**Auto-saved:** 2026-06-11 22:49 (PreCompact hook, trigger: manual)

- Snapshot automático antes do /compact.
- Detalhes da sessão em ~/.claude/sessions/ (session-summary hook).
