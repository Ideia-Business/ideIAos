# A-07 — Registro de hooks no bootstrap (R15-02) · SUMMARY

**Status:** ✅ DONE 2026-06-25 · **Wave:** 2 · **depends_on:** A-01, A-02 · **Executor:** sessão principal

## Objetivo

Failure-mode #1 ("hooks copiados-mas-mortos"): `setup-dev-machine.sh` deployava os ARQUIVOS dos
hooks (passo 7, `setup.sh --global-only`) mas — por T-01-10 — **nunca os registrava** em
`~/.claude/settings.json`. A-07 fecha isso **para o bootstrap-mantenedor**, sem tocar o
Quickstart-CONSUMIDOR e sem extrair script novo.

## Decisão de design (ASSUMPTION registrada)

Como o `ideiaos-update.sh` não tinha como isolar o step 3 (registro de hooks), a abordagem de
**menor superfície** foi adicionar a flag **`--hooks-only`** que executa SÓ o step 3, pulando
sync-all + patchers do autosync (steps 1-2e) e shell/statusline (4-5). A lógica de registro
permanece em **uma única fonte** (o step 3, heredoc python3 `PYEOF`, backup `.bak-hooks`) — zero
duplicação. O `setup-dev-machine.sh` (passo 7.5) **invoca** esse registrador, não o copia.

## O que foi feito (escopo cirúrgico — só 2 scripts)

1. **`scripts/ideiaos-update.sh`**: flag `--hooks-only` (init `HOOKS_ONLY=0` + case no parser),
   `HOOKS_ONLY=1` ⇒ `NO_SHELL=1; NO_STATUSLINE=1` (desliga 4-5), e os steps 1-2e envolvidos num
   `if [ "$HOOKS_ONLY" -eq 0 ]; then ... fi`. **Step 3 (registro) intocado e fora do bloco** — roda
   sempre, inclusive sob `--hooks-only`. Header `Uso:` atualizado.
2. **`setup-dev-machine.sh`**: novo **passo 7.5** entre o passo 7 (deploy dos arquivos) e o passo 8
   (vault), invocando `bash "$DEV/IdeiaOS/scripts/ideiaos-update.sh" --hooks-only`. Rodar o
   bootstrap-mantenedor É o consentimento explícito que T-01-10 exige.

## No-Invention (drift do plano corrigido)

Os números de linha do plano haviam driftado. Verifiquei por grep e usei os **reais**:
`--global-only` na linha **248** (plano dizia 199), `settings_path` na **266** (plano dizia 217),
step 3 na **176**. Também corrigi o **regex do gate de ordem** do plano: a linha real é
`...ideiaos-update.sh" --hooks-only` (com aspas), e o regex esperava sem o `"` — o código estava
correto, o gate é que precisava de `.*` para absorver o aspas-fecha.

## Verificação (exit-code, cada gate exercita também input INVÁLIDO)

| Task | Gate | Resultado |
|------|------|-----------|
| 1 | autosync pausável + guard DEPLOYADO (grep) + registrador localizado + 11 hooks no hooks.json | ✅ |
| 2 | `bash -n` + flag `--hooks-only` + `HOOKS_ONLY` guarda step 1 + step 3 intacto (`.bak-hooks`, `["command"].rstrip`) | ✅ |
| 3 | sandbox: registra **11**, idempotente **11**, pula arquivo ausente **10** | ✅ |
| 4 | passo 7.5 invoca `--hooks-only` + **T-01-10 por diff-real** (`setup.sh` inalterado, 2 sentinelas) | ✅ |
| 5 | ordem executável 7(248) < 7.5(266) < 8(281); idempotência no REAL (25→25, restaurado a 25); sync-all NÃO rodou sob `--hooks-only`, step 3 rodou | ✅ |

## Arquivos

- `scripts/ideiaos-update.sh` (flag `--hooks-only`)
- `setup-dev-machine.sh` (passo 7.5)

## Carry-forward / debt

- `debt:` o `ideiaos-update.sh` poderia virar um dispatcher de steps data-driven (R15-21, fora do
  escopo de R15-02) — marcado, não consertado.
- Autosync pausado durante a cirurgia; teardown (despausar) executado após o commit atômico.
