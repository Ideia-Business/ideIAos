# Milestone v6 — Resiliência + Marketing + GSD/OpenSpec (SHIPPED 2026-06-16)

**Stats:** 54 commits ·  156 files changed, 25516 insertions(+), 48 deletions(-) · 9 fases (23-31) · 15 reqs (R6-01..R6-15)
**Auditoria:** PASSED 15/15 (.planning/v6-MILESTONE-AUDIT.md)

## Realizações
1. **Antifragilidade** (23): `source/lib/gates.sh` — gates binários `test -s` anti-alucinação (do OpenSquad) em memory-export/observe/build-adapters.
2. **Resiliência do instinct loop** (24): `instinct-recover.sh` — breadcrumb + recovery de spawn pós-crash (Agent Immortality adaptado do AIOX); 12/12 testes; bug de timezone UTC-3 corrigido.
3. **Geração fundamentada + paridade** (25): skill `/forge-agent` (research-before-create) + `build-adapters --validate-parity`.
4. **Camada de Marketing** (26): `/marketing` orquestra pipeline de conteúdo + 4 agents mkt-* + 22 best-practices OpenSquad + `/marketing-research` (Sherlock) + sub-plugin ideiaos-marketing. Roteada pela Deia.
5. **Test hardening** (27): `tests/v6-hooks/` — 5 suites, 78 asserts, no CI estrutural.
6. **Blindagem linhagem GSD** (28): versions.lock + guards anti-Pi-drift (redux 1.1.0 ≠ gsd-pi; open-gsd ≠ gsd-build) — fecha o pin-revertido-3×.
7. **Context-packet handoffs** (29): `source/lib/handoff-packet.sh` — token budget + anti-injection + idempotência por hash (do GSD ecosystem).
8. **Delta-spec brownfield** (30): skill `/spec` + spec-merge/validate — corpus de specs vivas com deltas (conceito OpenSpec, complementar ao GSD); 21/21 testes.
9. **Tooling eval** (31): ADRs gsd-browser (adiar) + agent-inbox (opt-in).

## Origem
Análises comparativas AIOX×OpenSquad (Temas A+B) e GSD×OpenSpec (Tema D) — vault Decisions/.
