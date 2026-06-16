# v7 — Milestone Integration Audit

**Milestone:** v7 — Delta-Spec Brownfield + Robustez de Empacotamento
**Data:** 2026-06-16
**Veredito:** ✅ **PASSED** — SHIPPED

---

## Origem

v7 nasceu de uma decisão do usuário ("piloto `/spec` no nfideia") e cresceu ao expor gaps reais durante o piloto. Diferente de milestones planejados-antes, este foi **descoberta-dirigida**: o produto real revelou os defeitos que os testes unitários mascaravam.

## Fases entregues (4 entregáveis + 1 backlog passivo)

| Fase | Entrega | Verificação |
|------|---------|-------------|
| 1 | Piloto `/spec` no nfideia: spec viva `multi-tenancy` (6 reqs do comportamento real) + ciclo de delta completo | merge OK + archive datado |
| 1b | Artefatos na branch Lovable-safe `spec/multi-tenancy-pilot` (pushada; main intacta) | `origin/spec/multi-tenancy-pilot` |
| 2 | Drift-guard `check-plugin-membership.sh` (pre-commit + doctor seção 10) | 69 módulos, 0 deriva |
| 3 | Rollout: 2ª capability `cofre-digital` (RN-050..053) | spec autorada + pushada |
| 4 | Backlog passivo (gsd-browser/agent-inbox — upstream/sob-demanda) | não-bloqueante |

## Bugs/gaps corrigidos (que o piloto expôs)

1. 🔴 `spec-merge.sh` sem `mkdir -p _archive` → toda 1ª change de qualquer produto falhava. **Fix + teste 11.**
2. 🟡 ADICIONADO anexava no EOF em vez de dentro de `## Requisitos`. **Fix (splice awk) + teste 12.**
3. 🟠 `spec`/`forge-agent`/`memory-sync` fora do `CORE_SKILLS` → fix não chegava via marketplace. **Empacotadas.**
4. 🟠 `memory-import`/`export` (v5) `plugin:ideiaos-core` mas patch-installed → **`plugin:null`** (anti dupla-registração). Pego pelo drift-guard.

## Gates (15/15 conceito → aqui consolidados)

| Gate | Resultado |
|------|-----------|
| spec-merge.bats | ✅ 27/27 |
| check-plugin-membership (drift) | ✅ 0 deriva / 69 módulos |
| check-readme-sync | ✅ 106/106 |
| idea-doctor | ✅ 62 OK / 0 WARN / 0 FAIL |
| git work=origin/work, tree limpo | ✅ 601ed9e |

## Requisitos

R7-01..R7-09: ✅ DONE. R7-10 (DeepSeek): ➖ fora de escopo (decisão do usuário — vai para os produtos).

## Fora de escopo / carried-forward

- **DeepSeek V4 Pro** → habilitado no nível dos **produtos** (não IdeiaOS). Memória: `project-deepseek-v4-enablement-pending`.
- **gsd-browser** → monitorar upstream (não publicado). **agent-inbox** → sob demanda.
- **PRs no nfideia** → branch com 2 specs prontas para revisar/merge quando o usuário quiser.

**Veredito final: SHIPPED. Tag `v7.0`.**
