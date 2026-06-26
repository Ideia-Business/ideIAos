# R15-09 — `idea-doctor --fleet` · SUMMARY

**Status:** ✅ DONE 2026-06-25 · **Wave:** 1 · **Executor:** sessão principal

## O que foi feito

Adicionado o modo **`--fleet`** ao `idea-doctor.sh` — agregador read-only de saúde cross-máquina
sobre o ref `cockpit`. Entra como **early-exit** (após `find_aiox_core`, antes do diagnóstico local),
com renderização própria via `echo -e` (não toca os contadores PASS/WARN/FAIL do doctor local).
Parse dos snapshots via `node` (sem jq, bash 3.2). Resolve **nomes** pelo alias-map A-05.

Saída: tabela `MÁQUINA | IDADE | STATUS | DETALHE` + sumário `N máquina(s) · X sem sinal · Y sem
veredito · Z com falha`. Status honesto (anti-falso-verde):

- **DORMANT** ("sem sinal") — idade > 1d sem reportar (≠ falha).
- **VAZIO** — `doctor.exit < 0` ou sem checks (snapshot sem veredito; coleta incompleta).
- **FAIL** — `doctor.fail > 0` ou `exit == 1`.
- **WARN** — `doctor.warn > 0`. **OK** — saudável de verdade.

## Achado decisivo (anti-falso-verde funcionando)

A 1ª versão mostrava os 2 snapshots como **OK verde** — mas a inspeção revelou `doctor.exit = -1`
e `sections = []` em ambos. Renderizar isso como OK seria o **falso-verde** que o requisito proíbe.
Corrigi a lógica para usar `doctor.exit` e emitir **VAZIO** — expondo a verdade: o doctor não está
sendo coletado na frota.

## Verificação (exit-code)

| Gate | Resultado |
|------|-----------|
| `bash -n` sintaxe | ✅ |
| `--fleet` real: exit 0, 2 máquinas (Mac-mini 2m, MacBook-Air-2 23h53m), NOMES não hashes, idade | ✅ |
| falso-verde corrigido: status VAZIO (não OK) + sumário "2 sem veredito" | ✅ |
| não-regressão do `--json`: vazamento de debt-markers idêntico antes/depois (5=5) | ✅ |
| anti-teatro: `--fleet` em sandbox `/tmp` SEM ref cockpit → mensagem direcional + exit 0 (não crash) | ✅ |

## Carry-forward → R15-12 (PRIORITÁRIO)

O `--fleet` isolou a **causa-raiz** do VAZIO: `idea-doctor --json` emite **JSON inválido** porque o
§12 (debt-markers, linha 742) imprime as ocorrências para stdout **sem guard `JSON_MODE`** (a função
`warn` acima já suprime; o `printf` seguinte não). O `collect.js` falha o `JSON.parse` e grava o
fallback `{ok:0,warn:0,fail:0,exit:-1,sections:[]}` — que vira o VAZIO no painel.

**Fix cirúrgico aplicado em commit SEPARADO** (bugfix, fora de R15-09): guard `[ "$JSON_MODE" -eq 0 ]`
no `printf` da linha 742. Destrava a coleta do doctor em coletas FUTURAS de toda a frota. O resto da
investigação de coleta incompleta (`installed_versions={}`, `readMcp()`) permanece em **R15-12**.

## Arquivos

- `scripts/idea-doctor.sh` (modo `--fleet`: parser, header, `run_fleet`).
- `.planning/milestones/v15-phases/B-governanca/{INDEX,R15-09-fleet-PLAN,R15-09-fleet-SUMMARY}.md`.
