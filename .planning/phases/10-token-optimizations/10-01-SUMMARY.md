---
phase: 10-token-optimizations
plan: 01
subsystem: infra
tags: [token-economy, bash, agents, lsp, typescript, strategic-compact, silent-failure-hunter]

# Dependency graph
requires:
  - phase: 09-agent-contracts
    provides: build-adapters.sh frontmatter validation, ideiaos-checker canonical name
provides:
  - silent-failure-hunter model:sonnet (opus → sonnet downgrade, ~5x token cost reduction)
  - strategic-compact.sh bash puro sem python3 (~5ms overhead elimnado por tool call)
  - typescript-lsp entry em modules.json com installStrategy:stack:typescript
  - setup.sh wiring condicional — primeira consumidora real de detect_stack() para LSP
affects: [11-instinct-loop-automation, 13-security-dx-manifest]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "installStrategy:stack:X — instalação condicional por stack via detect_stack()"
    - "Counter file plain-text integer vs JSON — mais simples/eficiente para scalar"
    - "Plugin copy sync obrigatório — source/agents/ e plugins/ideiaos-core/agents/ devem estar alinhados"

key-files:
  created: []
  modified:
    - source/agents/silent-failure-hunter.md
    - plugins/ideiaos-core/agents/silent-failure-hunter.md
    - source/hooks/strategic-compact.sh
    - manifests/modules.json
    - setup.sh

key-decisions:
  - "R3-05: opus → sonnet no silent-failure-hunter; processo grep-based validado em 3 casos; ~5x economia"
  - "R3-06: counter file muda de .json para plain-text integer — simpler format para scalar único"
  - "R3-06: jq proibido (zero dependência externa) — grep/sed bash builtins para parse de session_id"
  - "R3-07: typescript-lsp registrado como kind:lsp, source:null — config-only, não instala pacote npm"
  - "Deviation: plugin copy (plugins/ideiaos-core/agents/) sempre sincronizada com source/agents/"

patterns-established:
  - "installStrategy:stack:typescript — padrão para módulos condicionais por stack"
  - "detect_stack() chamada em setup.sh para wiring condicional de LSPs"

requirements-completed: [R3-05, R3-06, R3-07]

# Metrics
duration: 25min
completed: 2026-06-12
---

# Phase 10 Plan 01: Token Optimizations Summary

**silent-failure-hunter opus→sonnet (~5x economy), strategic-compact.sh reescrito em bash puro (zero python3), typescript-lsp registrado no manifesto com installStrategy:stack:typescript e wiring condicional em setup.sh**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-06-12T16:05:00Z
- **Completed:** 2026-06-12T16:30:00Z
- **Tasks:** 3
- **Files modified:** 5 (+ ~/.claude/hooks/strategic-compact.sh instalado)

## Accomplishments

- Downgrade opus→sonnet em silent-failure-hunter com justificativa documentada referenciando token-economy-review.md; plugin copy (plugins/ideiaos-core/) sincronizada; entry em modules.json atualizada
- strategic-compact.sh reescrito eliminando 3 invocações de python3 — parse de session_id via grep/sed, contador plain-text integer em /tmp (sem JSON), printf para JSON output; todos os guards de segurança preservados (T-10-01, T-10-03); instalado em ~/.claude/hooks/
- typescript-lsp registrado em manifests/modules.json com kind:lsp, installStrategy:stack:typescript, config.tsconfig_path; setup.sh wiring condicional usando detect_stack() como primeira consumidora real do padrão stack:*

## Task Commits

1. **Task 1: Downgrade silent-failure-hunter opus → sonnet** - `e05c505` (feat)
2. **Task 2: Reescrever contador strategic-compact.sh em bash puro** - `d25860f` (autosync capturou — veja Desvios)
3. **Task 3: Registrar typescript-lsp no manifesto e wiring em setup.sh** - `ee6eda7` (feat)

## Files Created/Modified

- `source/agents/silent-failure-hunter.md` — model: opus → sonnet; description atualizada com justificativa
- `plugins/ideiaos-core/agents/silent-failure-hunter.md` — cópia sincronizada (Fase 09 lesson)
- `source/hooks/strategic-compact.sh` — reescrito em bash puro; zero python3; counter plain-text
- `manifests/modules.json` — model opus→sonnet em agent-silent-failure-hunter; entry typescript-lsp adicionada (módulo 71)
- `setup.sh` — bloco condicional TypeScript LSP após setup_lovable_project usando detect_stack()

## Decisions Made

- **opus→sonnet para silent-failure-hunter:** Processo é inteiramente grep-based (catch vazio, promise sem .catch, retornos ignorados, Supabase .error). Validado em 3 casos: (1) `catch {}` vazio — detectável por grep pattern `catch.*\{[\s]*\}`; (2) `.then(fn)` sem `.catch` — regex simples; (3) `supabase.from().select()` sem check de `.error` — pattern grep fixo. Nenhum dos casos exige raciocínio aberto que justifique opus.
- **jq proibido:** Convenção IdeiaOS é zero dependência externa em hooks. grep/sed bash builtins são suficientes para extrair session_id de JSON simples.
- **Counter plain-text vs JSON:** Um único inteiro não justifica o overhead de JSON; plain-text é mais simples, sem dependência de python3, e mais eficiente.
- **typescript-lsp como config-only:** source:null confirma que não é um arquivo instalável — é referência de configuração para detect_stack(). Não instala pacote npm.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Plugin copy (plugins/ideiaos-core/agents/) sincronizada em Task 1**
- **Found during:** Task 1 (downgrade silent-failure-hunter)
- **Issue:** A Fase 09 mostrou que plugins/ideiaos-core/agents/ diverge de source/agents/ se esquecida. O PLAN.md mencionava o risco ("Fase 09 mostrou que cópias divergem") mas não incluía a cópia do plugin como arquivo explícito na task.
- **Fix:** Editada a cópia em plugins/ideiaos-core/agents/silent-failure-hunter.md com as mesmas mudanças (model: sonnet, description atualizada).
- **Files modified:** plugins/ideiaos-core/agents/silent-failure-hunter.md
- **Verification:** build-adapters.sh --target all exit 0 (valida ambas as cópias)
- **Committed in:** e05c505 (Task 1 commit)

**2. [Autosync - Info] Task 2 capturada por autosync antes do commit feat()**
- **Found during:** Task 2 commit
- **Issue:** O autosync do Mac-mini rodou durante a execução e commitou strategic-compact.sh como wip (d25860f) antes de eu poder criar o commit feat(). O arquivo está corretamente commitado com o conteúdo novo.
- **Fix:** Nenhum — content correto, commit wip serve como evidência. Não foi possível criar commit feat() separado sem amend.
- **Impact:** Nenhum impacto funcional. O hash d25860f referencia o conteúdo correto de strategic-compact.sh.

---

**Total deviations:** 2 (1 auto-fix Rule 2, 1 autosync informativo)
**Impact on plan:** Auto-fix necessário para manter consistência de plugin copies. Autosync não afeta funcionalidade.

## Validação de Comportamento — R3-05 (3 casos)

Os três casos confirmam que silent-failure-hunter é grep-based, não requer raciocínio aberto:

| Caso | Pattern | Sonnet suficiente? |
|------|---------|-------------------|
| `catch {}` vazio | `grep -nE "catch.*\{[\s]*\}"` | Sim — match direto |
| `.then(fn)` sem `.catch` | regex de promessa sem tratamento | Sim — pattern fixo |
| `supabase.from().select()` sem `.error` check | grep por `.select()` sem `.error` | Sim — grep estrutural |

## Acceptance Gates

| Gate | Resultado |
|------|-----------|
| `grep "^model: sonnet" source/agents/silent-failure-hunter.md` | PASS |
| `grep -c "opus" source/agents/silent-failure-hunter.md` → 0 | PASS |
| `grep -c "python3" source/hooks/strategic-compact.sh` → 0 | PASS |
| `bash -n source/hooks/strategic-compact.sh` → exit 0 | PASS |
| Hook silencioso calls 1-49 | PASS |
| Hook emite additionalContext na 50a chamada | PASS |
| `grep -c '"id": "typescript-lsp"' manifests/modules.json` → 1 | PASS |
| `grep '"installStrategy": "stack:typescript"' manifests/modules.json` → 1 | PASS |
| `python3 -m json.tool manifests/modules.json` → exit 0 | PASS |
| `grep -c "TypeScript LSP" setup.sh` → 3 | PASS |
| `bash -n setup.sh` → exit 0 | PASS |
| `bash scripts/build-adapters.sh --target all` → exit 0 | PASS |
| `bash scripts/check-readme-sync.sh` → 91/91 exit 0 | PASS |

## Issues Encountered

Nenhum além dos desvios documentados.

## Known Stubs

Nenhum — todos os três changes são funcionais e completos.

## Threat Flags

Nenhuma superfície nova não coberta pelo threat_model do plano. T-10-01 e T-10-03 preservados intactos na reescrita bash.

## Next Phase Readiness

- Fase 11 (instinct-loop-automation): independente, pode avançar
- modules.json agora tem 71 entries — R3-17 (Fase 13) deve verificar consistência com ideiaos-catalog/SKILL.md
- Pattern installStrategy:stack:* estabelecido e pronto para reuso em outros LSPs/ferramentas condicionais

## Self-Check

- [x] source/agents/silent-failure-hunter.md — model: sonnet, sem opus
- [x] plugins/ideiaos-core/agents/silent-failure-hunter.md — sincronizado
- [x] source/hooks/strategic-compact.sh — zero python3, bash puro
- [x] manifests/modules.json — typescript-lsp presente, JSON válido, 71 modules
- [x] setup.sh — bloco TypeScript LSP presente, bash -n OK
- [x] Commits: e05c505 (R3-05), d25860f (autosync R3-06), ee6eda7 (R3-07)

---
*Phase: 10-token-optimizations*
*Completed: 2026-06-12*
