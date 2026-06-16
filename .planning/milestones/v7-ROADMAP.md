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

### Fase 1b — Versionar artefatos do piloto (Lovable-safe) ✅ DONE (2026-06-16)

nfideia **é Lovable** (lovable-tagger + componentTagger). `specs/` commitados na branch `spec/multi-tenancy-pilot` e **pushados** (`origin/spec/multi-tenancy-pilot`), main intacta. Cobre R7-08.

### Fase 2 — Drift-guard manifesto×plugin-arrays ✅ DONE (2026-06-16)

`scripts/check-plugin-membership.sh` — gate binário que cruza `plugin:` do `modules.json` com os arrays do `build-plugins.sh`. Wired no **pre-commit** (`install-git-hooks.sh`, quando manifesto/build/membership staged) e no **idea-doctor** (seção 10). **Já provou valor:** pegou `memory-import`/`export` (v5) declarados `plugin:ideiaos-core` mas patch-installed → marcados `plugin:null` (empacotá-los causaria dupla-registração SessionStart/Stop). 69 módulos, 0 deriva. Cobre R7-07.

### Fase 3 — Rollout delta-spec ✅ DONE (2026-06-16)

Segunda capability autorada: `nfideia/specs/cofre-digital/spec.md` (4 reqs das RN-050..053 — A1-only, tokens efêmeros, alertas de validade, auditoria). Provou repetibilidade num 2º domínio. Na branch `spec/multi-tenancy-pilot` (`ffc48c9c`). Cobre R7-09.

### Fase 4 — Decisões opt-in com prazo ⬜ BACKLOG

DeepSeek V4 Pro (prazo 2026-07-24, R7-10) · gsd-browser/agent-inbox quando publicados. Decisões do usuário.

---

## Progresso

| Fase | Status |
|------|--------|
| 1 — Piloto `/spec` nfideia | ✅ DONE |
| 1b — Versionar (Lovable-safe) | ✅ DONE |
| 2 — Drift-guard | ✅ DONE |
| 3 — Rollout delta-spec | ✅ DONE |
| 4 — Opt-in com prazo | ⬜ BACKLOG (decisão do usuário) |
