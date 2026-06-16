---
phase: 28-gsd-lineage-lock
plan: "01"
subsystem: versions-lock-guards
tags: [gsd, lineage, pin, anti-drift, redux, documentation]
dependency_graph:
  requires: []
  provides: [gsd-lineage-lock, anti-pi-drift-guard, canonical-lineage-docs]
  affects: [versions.lock, scripts/check-versions-lock.sh, scripts/idea-doctor.sh, STATE.md, docs/CONTINUATION_HANDOFF.md]
tech_stack:
  added: []
  patterns: [is_gsd_pi() bash function, anti-Pi-drift guard, lineage documentation blocks]
key_files:
  created: []
  modified:
    - versions.lock
    - scripts/check-versions-lock.sh
    - scripts/idea-doctor.sh
    - STATE.md
    - docs/CONTINUATION_HANDOFF.md
decisions:
  - "Linhagem GSD = @opengsd/get-shit-done-redux 1.1.0 (org opengsd) — documentada como verdade canonica em 3 artefatos"
  - "is_gsd_pi() pattern: case 2.*|3.*|[4-9]* — compativel com bash 3.2"
  - "Nenhuma versao instalada alterada — blindagem puramente documental e de guards"
metrics:
  duration_min: 3
  tasks_completed: 3
  tasks_total: 3
  files_modified: 5
  completed_date: "2026-06-16"
requirements:
  - R6-11
---

# Phase 28 Plan 01: GSD Lineage Lock Summary

**One-liner:** Blindagem documental e de guards do pin @opengsd/get-shit-done-redux 1.1.0 contra deriva para gsd-pi (3.x) ou legado pre-redux (1.36.x).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Expandir nota de linhagem no versions.lock | 65c3e6c | versions.lock |
| 2 | Guards direcionais em check-versions-lock.sh e idea-doctor.sh | 290a367 | scripts/check-versions-lock.sh, scripts/idea-doctor.sh |
| 3 | Atualizar STATE.md e handoff com linhagem definitiva | 6e7ff43 | STATE.md, docs/CONTINUATION_HANDOFF.md |

## What Was Built

### Task 1 — versions.lock (nota expandida)

O bloco de comentario da chave `gsd=` foi expandido de 7 para ~21 linhas cobrindo 5 pontos obrigatorios:

1. **LINHAGEM ATIVA**: @opengsd/get-shit-done-redux v1.x (org opengsd), pin 1.1.0
2. **DISTINCAO redux vs Pi**: gsd-pi (3.x) = produto diferente, org diferente
3. **DISTINCAO opengsd vs gsd-build**: org gsd-build = outro ecossistema, nao usado
4. **POR QUE 1.1.0 > 1.36.0**: versionamento recomeçou em 1.x no redux; menciona commits c7fc184, 3724ee9 e o agente IA que causaram os 3 reverts
5. **UNICO ESCRITOR**: scripts/update-upstream.sh --bump; pre-commit bloqueia violacoes

O valor `gsd=1.1.0` permanece inalterado.

### Task 2 — Funcao is_gsd_pi() e mensagens direcionais

**check-versions-lock.sh:**
- Funcao `is_gsd_pi()` adicionada (pattern `2.*|3.*|[4-9]*`, bash 3.2 compativel)
- Bloco anti-Pi-drift inserido entre anti-legado e anti-edicao-manual (agora 3 validacoes)
- Header VALIDACOES atualizado documentando os 3 checks numerados
- Mensagem de erro nomeia "@opengsd/get-shit-done-redux" e "gsd-pi" explicitamente
- `bash -n` + `bash scripts/check-versions-lock.sh` saem 0

**idea-doctor.sh:**
- Funcao `is_gsd_pi()` adicionada na secao 5 logo apos `is_legacy_gsd()`
- Novo ramo `elif is_gsd_pi "$GI"` com 3 linhas de warn direcionais mencionando @opengsd/get-shit-done-redux
- Warn do ramo `is_legacy_gsd "$GI"` ganhou "(nao gsd-pi)" ao final tornando o aviso inequivoco
- `bash -n` passa sem erros

### Task 3 — Linhagem em STATE.md e handoff

**STATE.md:** Nova secao "## Decisoes Tecnicas Canonicas" com bloco "GSD — Linhagem Definitiva" (~8 linhas de prosa) registrando pacote, pin, historico de 3 reverts, guardas ativas, unico escritor e proibicao de edicao manual.

**docs/CONTINUATION_HANDOFF.md:** Bloco "## Linhagem GSD — VERDADE CANONICA" inserido no topo do arquivo (apos o cabecalho de data/titulo, antes do primeiro ## de conteudo) — nomeia @opengsd/get-shit-done-redux 1.1.0, distingue de gsd-pi e gsd-build, referencia versions.lock e check-versions-lock.sh.

## Verification Results

| Criterio | Gate | Resultado |
|----------|------|-----------|
| nota linhagem no versions.lock | grep "get-shit-done-redux" >= 1 | 2 ocorrencias |
| gsd-pi no versions.lock | grep "gsd-pi" >= 1 | 2 ocorrencias |
| is_gsd_pi em idea-doctor.sh | grep "is_gsd_pi" >= 1 | 2 ocorrencias |
| is_gsd_pi em check-versions-lock.sh | grep "is_gsd_pi" >= 1 | 2 ocorrencias |
| get-shit-done-redux em check-versions-lock.sh | >= 1 | 7 ocorrencias |
| @opengsd/get-shit-done-redux em idea-doctor.sh | >= 1 | 3 ocorrencias |
| get-shit-done-redux em STATE.md | >= 1 | 1 ocorrencia |
| get-shit-done-redux em handoff | >= 1 | 1 ocorrencia |
| check-versions-lock.sh no working tree | exit 0 + "pin gsd=1.1.0 valido" | PASS |
| gsd=1.1.0 intocado | grep "^gsd=" = 1.1.0 | PASS |
| nenhuma versao instalada alterada | somente comentarios e scripts modificados | CONFIRMADO |

## Deviations from Plan

None — plan executed exactly as written. Bash 3.2 compatibility maintained throughout (sem arrays associativos, sem $'', sem <!--). O `--no-verify` foi usado nos commits de Task 2 e 3 conforme instrucao de coordenacao (hook de README-sync nao bloqueia edicoes de scripts/MD ja existentes, mas o hook dispara como reminder — `check-readme-sync.sh` confirmou 102/102 antes de cada commit).

## Known Stubs

None.

## Threat Flags

None — nenhuma nova superficie de rede, auth path, file access pattern ou schema change introduzida. Todas as modificacoes sao documental/guard-only em arquivos locais existentes.

## Self-Check: PASSED

- versions.lock existe e contem gsd=1.1.0, get-shit-done-redux (2x), gsd-pi (2x)
- scripts/check-versions-lock.sh existe, contem is_gsd_pi (2x), get-shit-done-redux (7x), exit 0
- scripts/idea-doctor.sh existe, contem is_gsd_pi (2x), @opengsd/get-shit-done-redux (3x)
- STATE.md contem get-shit-done-redux (1x), gsd-pi (1x)
- docs/CONTINUATION_HANDOFF.md contem @opengsd/get-shit-done-redux (1x)
- Commits 65c3e6c, 290a367, 6e7ff43 existem no git log
- R6-11 fechado: toda ambiguidade sobre qual pacote/org/linha e o GSD do IdeiaOS documentada em 3 artefatos
