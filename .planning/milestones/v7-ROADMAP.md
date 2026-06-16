# Roadmap — v7: Delta-Spec Brownfield + Robustez de Empacotamento

**Milestone:** v7
**Aberto:** 2026-06-16
**Status:** 🚧 IN PROGRESS

## Tese

Provar a capability `/spec` (delta-spec) num produto brownfield real, endurecer o que o piloto expôs, e estabelecer o delta-spec como prática viva — sem substituir o GSD (complementar: `/spec` = contrato de comportamento; GSD = execução).

---

## Fases

### Fase 1 — Piloto `/spec` brownfield no nfideia ✅ DONE (2026-06-16)

**Entregue:**
- Spec viva `nfideia/specs/multi-tenancy/spec.md` — 6 requisitos derivados do comportamento **real** (funções `SECURITY DEFINER`, RLS por `escritorio_id`, cargos admin/operador, 31 policies). Mapeada a RN-001..004 + RN-010..014.
- Ciclo de delta completo ponta-a-ponta: change `add-storage-tenant-isolation` (propose → delta → tasks → validate → merge → archive datado).
- **2 bugs do engine corrigidos** (R7-03, R7-04): `mkdir -p _archive` (toda 1ª change falhava) + splice do ADICIONADO dentro de `## Requisitos` (era anexado no EOF). 2 testes de regressão → suite **27/27**.
- **Gap de empacotamento fechado** (R7-06): `spec`/`forge-agent`/`memory-sync` estavam `plugin:ideiaos-core` no manifesto mas fora do `CORE_SKILLS` do `build-plugins.sh` → fix do `/spec` não chegava às máquinas via marketplace. Empacotadas + `plugin-membership.md` atualizado.

**Cobre:** R7-01, R7-02, R7-03, R7-04, R7-05, R7-06.

### Fase 1b — Versionar artefatos do piloto (Lovable-safe) ⬜ TODO

nfideia **é projeto Lovable** (lovable-tagger + componentTagger). Commitar `specs/` em **branch** (ex.: `spec/multi-tenancy-pilot`), nunca disparar deploy. Cobre R7-08.

### Fase 2 — Drift-guard manifesto×plugin-arrays ⬜ TODO

Gate binário que falha se alguma skill/agent/hook `plugin: X` no `modules.json` não estiver no array correspondente do `build-plugins.sh` (e vice-versa). Wire no `idea-doctor` e/ou pre-commit. Previne a recorrência do R7-06. Cobre R7-07. **Antifragile** (barreira ativa > doc passiva).

### Fase 3 — Rollout delta-spec ⬜ BACKLOG

Autorar specs vivas para +1 capability brownfield de alto valor (candidatos: nfideia `cofre-digital`/`billing`/`emissão`; ou ideiapartner/cfoai). Cobre R7-09.

### Fase 4 — Decisões opt-in com prazo ⬜ BACKLOG

DeepSeek V4 Pro (prazo 2026-07-24, R7-10) · gsd-browser/agent-inbox quando publicados. Decisões do usuário.

---

## Progresso

| Fase | Status |
|------|--------|
| 1 — Piloto `/spec` nfideia | ✅ DONE |
| 1b — Versionar (Lovable-safe) | ⬜ TODO |
| 2 — Drift-guard | ⬜ TODO |
| 3 — Rollout delta-spec | ⬜ BACKLOG |
| 4 — Opt-in com prazo | ⬜ BACKLOG |
