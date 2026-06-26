# R15-09 — `idea-doctor --fleet` (agregador de saúde cross-máquina) · PLAN

**Milestone:** v15 · **Fase:** B · **Wave:** 1 · **Req:** R15-09 · **Origem:** GER-01 / CKF-05(perna 3)
**Movimento-âncora da Onda 2** — "o ponto de costura barato entre instalar e gerenciar".

## Objetivo (goal-backward)

De qualquer máquina, ver a saúde da frota inteira SEM rodar nada em cada estação: agregar os
snapshots do ref `cockpit` num painel único que mostra **nome** (não hash), **idade** do snapshot
(anti-falso-verde) e **status**, distinguindo "sem sinal" (DORMANT) de "vermelho" (FAIL).

## Contexto verificado (No-Invention)

- `idea-doctor.sh` (867 linhas) parseia só `--json` hoje (loop `for _arg in "$@"`). Helpers
  pass/warn/fail/info + cores (linha 33) já definidos. Já lê `git show cockpit:snapshots/<mid>.json`
  no §Cockpit (linha 746).
- Snapshot (verificado nos 2 reais): top-level `{schema, machine_id, agentd_version, os_version,
  taken_epoch, daemons, doctor:{ok,warn,fail,exit,sections}, installed_versions, accounts, projects}`.
  **`taken_epoch`** = idade; **`doctor.exit`** = veredito binário. Dado já presente → zero coleta nova.
- Alias-map A-05 (`source/console/machine-aliases.json`) mapeia `sha256[:12] → nome`.
- Ref `cockpit` tem 2 snapshots (Mac-mini + MacBook-Air-2) → DoD ≥2 máquinas satisfeito.

## Tasks

1. **Parser:** `FLEET_MODE=0` + `[ "$_arg" = "--fleet" ] && FLEET_MODE=1` no loop existente. Header `Uso:`.
2. **`run_fleet()` + early-exit** após `find_aiox_core` (antes do banner/diagnóstico local). Read-only:
   `git ls-tree cockpit snapshots/` → por snapshot, `node` (sem jq) extrai mid/epoch/doctor/versões,
   resolve nome via alias-map, calcula idade legível e status. `echo -e` próprio (não toca PASS/WARN/FAIL).
3. **Status honesto (anti-falso-verde):** DORMANT se idade>1d; **VAZIO se `exit<0` ou sem checks**
   (doctor não coletou — não é OK verde); FAIL se `fail>0` ou `exit==1`; WARN se `warn>0`; senão OK.
4. **Degradação graciosa:** sem ref cockpit ou sem snapshots → WARN direcional + exit 0 (não crash).

## Gates (exit-code, cada um exercita também input INVÁLIDO)

| Gate | Verificação | Resultado |
|------|-------------|-----------|
| 1 | `bash -n` sintaxe | ✅ |
| 2 | `--fleet` real: exit 0, ≥2 máquinas, **nomes** (não hash), **idade**, sumário | ✅ |
| 3 | **não-regressão** do `--json`: vazamento idêntico antes/depois (5=5) — minha mudança não piora | ✅ |
| 4 | anti-teatro: `--fleet` em sandbox `/tmp` SEM ref cockpit → mensagem direcional + exit 0 | ✅ |

## Invariantes

- bash 3.2 / sem `declare -A` (node faz o parse JSON). Autosync pausado durante a cirurgia.
- `--fleet` é read-only sobre o ref `cockpit`; não escreve nada; metadata-only.
- Não trata `--fleet` como visão live — mostra a IDADE; máquina parada = "sem sinal" (alerta certo).

## Carry-forward

- O `--fleet` expôs `doctor.exit=-1` em todos os snapshots → **causa-raiz:** `idea-doctor --json`
  emite JSON inválido (vazamento de debt-markers §12 sem guard `JSON_MODE`). Fix em commit separado
  (bugfix); resto da coleta incompleta (`installed_versions={}`) é **R15-12**.
