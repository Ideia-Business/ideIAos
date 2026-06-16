---
gsd_state_version: 1.0
milestone: v6
milestone_name: Resiliência + Marketing + GSD/OpenSpec
status: shipped
last_updated: "2026-06-16"
progress:
  total_phases: 9
  completed_phases: 9
  total_plans: 11
  completed_plans: 11
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
| Próximo milestone (v7) | ⬜ A definir |

## Decisões Tecnicas Canonicas

### GSD — Linhagem Definitiva
- Usamos `@opengsd/get-shit-done-redux@1.1.0` (linha VIVA/estável, org open-gsd).
- redux 1.x ≠ gsd-pi 3.x (produto diferente, NÃO migrar). open-gsd ≠ gsd-build (legado).
- versions.lock blindado (fase 28); guards anti-Pi-drift em check-versions-lock.sh + idea-doctor.sh.

## Próximo passo

Milestone v6 completo. Próximo: definir v7 (candidatos: piloto delta-spec brownfield num produto; gsd-browser se publicado; outras absorções). Ou novas demandas.

## Pendências (opt-in, decisão do usuário)
- Piloto /spec (delta-spec) num produto brownfield (nfideia) — spike documentado na fase 30.
- gsd-browser: reavaliar quando publicar npm/crates (ADR docs/decisions/).
