# Requirements — v7: Delta-Spec Brownfield + Robustez de Empacotamento

**Milestone:** v7
**Aberto:** 2026-06-16
**Origem:** piloto `/spec` no nfideia (decisão do usuário em 2026-06-16) + gaps que o piloto expôs.

---

## Contexto

O v6 entregou a capability `/spec` (delta-spec brownfield) com testes unitários, mas **conceito**, não uso real. Este milestone nasce do **piloto ao vivo** num produto brownfield (nfideia), que validou a capability ponta-a-ponta **e** expôs bugs/gaps reais que os testes unitários mascaravam.

---

## Requisitos

| ID | Requisito | Severidade | Status |
|----|-----------|------------|--------|
| R7-01 | `/spec` deve produzir uma spec viva válida a partir do comportamento real de uma capability brownfield (nfideia/multi-tenancy) | MUST | ✅ DONE |
| R7-02 | O ciclo de delta (propose → delta → tasks → validate → merge → archive) deve funcionar ponta-a-ponta num produto real | MUST | ✅ DONE |
| R7-03 | `spec-merge.sh` deve criar `specs/_archive/` ausente — a 1ª change de qualquer produto não pode falhar no archive | MUST | ✅ DONE |
| R7-04 | Requisitos ADICIONADOS devem ser inseridos dentro de `## Requisitos` (antes de seções finais), não anexados no EOF | SHOULD | ✅ DONE |
| R7-05 | A suíte `spec-merge.bats` deve cobrir os dois bugs acima com testes de regressão | MUST | ✅ DONE (27/27) |
| R7-06 | Skills declaradas `plugin: ideiaos-core` no manifesto devem ser empacotadas pelo `build-plugins.sh` (fechar deriva manifesto×array que deixava spec/forge-agent/memory-sync de fora) | MUST | ✅ DONE |
| R7-07 | Deve existir um **gate** que detecte deriva entre os arrays de `build-plugins.sh` e as atribuições `plugin:` do `modules.json`, prevenindo recorrência do R7-06 | SHOULD | ⬜ TODO (Fase 2) |
| R7-08 | Os artefatos de spec do piloto devem ser versionados no nfideia de forma **Lovable-safe** (branch, nunca main automática) | MUST | ⬜ TODO (Fase 1b) |
| R7-09 | Rollout: autorar specs vivas para +1 capability brownfield (candidatos: nfideia cofre-digital/billing, ou ideiapartner/cfoai) | COULD | ⬜ Backlog (Fase 3) |
| R7-10 | Decisão DeepSeek V4 Pro (prazo: legados aposentam 2026-07-24) — habilitar nos produtos ou no Claude Code | SHOULD | ⬜ Backlog (decisão do usuário) |

---

## Fora de escopo (decisão registrada)

- **Migrar para gsd-pi/gsd-2** — não (trocaria o host Claude Code).
- **gsd-browser / agent-inbox** — opt-in, reavaliar quando publicados (ADRs já existem em `docs/decisions/`).
- **Substituir GSD por OpenSpec** — não; são complementares (delta-spec = contrato; GSD = execução).
