---
gsd_state_version: 1.0
milestone: v8
milestone_name: Camada de Disciplina (Discipline Layer)
status: shipped
last_updated: "2026-06-16"
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 4
  completed_plans: 4
  percent: 100
---

# State — IdeiaOS

**Atualizado:** 2026-06-16

## Snapshot

| Item | Status |
|------|--------|
| v2.0/v3/v4 (plano maior ECC) | ✅ SHIPPED |
| v5 (memória cross-IDE) | ✅ SHIPPED |
| **v6 (Resiliência + Marketing + GSD/OpenSpec)** | ✅ **SHIPPED 2026-06-16** — 9 fases, auditoria 15/15, tag v6.0 |
| **v7 (Delta-Spec Brownfield + Robustez de Empacotamento)** | ✅ **SHIPPED 2026-06-16** — 4 fases, auditoria PASSED, tag v7.0: piloto `/spec` (specs vivas multi-tenancy + cofre-digital) + 4 bugs/gaps corrigidos + **drift-guard**. Fase 4 = backlog passivo (upstream). |
| **v8 (Camada de Disciplina)** | ✅ **SHIPPED 2026-06-16** — 4 waves, auditoria PASSED, tag v8.0: absorção de `addyosmani/agent-skills` (MIT) — `/doubt` (doubt-driven) + rule `operating-discipline` (6 condutas) + `/context-engineering` + convenção anti-racionalização + opt-in `/observability`+`/deprecation-migration`. **Dogfood:** doubt-driven achou e corrigiu citação fabricada no próprio `/doubt`. |

## Decisões Tecnicas Canonicas

### GSD — Linhagem Definitiva
- Usamos `@opengsd/get-shit-done-redux@1.1.0` (linha VIVA/estável, org open-gsd).
- redux 1.x ≠ gsd-pi 3.x (produto diferente, NÃO migrar). open-gsd ≠ gsd-build (legado).
- versions.lock blindado (fase 28); guards anti-Pi-drift em check-versions-lock.sh + idea-doctor.sh.

## Próximo passo

Milestone v8 (Camada de Disciplina) SHIPPED — tag v8.0. `/doubt` e `/context-engineering` no marketplace; `/observability` e `/deprecation-migration` no catálogo opt-in. **R8-09 FECHADO (2026-06-16):** `build-adapters.sh` deploya `source/rules/common/*` → `.claude/rules/ideiaos-common-*.md` (paridade Claude×Cursor). **Sem pendências do v8.** Próximo: novas demandas.

## Pendências (opt-in, decisão do usuário)
- Piloto /spec (delta-spec) num produto brownfield (nfideia) — spike documentado na fase 30.
- gsd-browser: reavaliar quando publicar npm/crates (ADR docs/decisions/).

## Compact Snapshot

**Auto-saved:** 2026-06-16 19:50 (PreCompact hook, trigger: manual)

- Snapshot automático antes do /compact.
- Detalhes da sessão em ~/.claude/sessions/ (session-summary hook).
