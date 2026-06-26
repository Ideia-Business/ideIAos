# A-02 — Smoke-test puro-bash (R15-03) — SUMMARY

**Fase:** v15-A (Destravar & Estancar) · Onda 1 · plano A-02
**Requisito:** R15-03
**Status:** ✅ DONE
**Data:** 2026-06-25
**Executor:** @dev (Dex)
**Escopo:** 1 arquivo novo (`scripts/idea-smoke.sh`) — cirúrgico

---

## Entregue

- `scripts/idea-smoke.sh` (novo, executável) — smoke-test PURO-BASH 3.2 do bootstrap
  mínimo do IdeiaOS, exit-code binário. Default = build-contract (exit 1 em falha);
  flag `--hook` = hook-contract (exit 0 sempre). Header `# SOURCE: IdeiaOS v15 | kind: gate`.

### Os 3 checks essenciais
1. **Comandos resolvem** — `command -v node/git/bash` (ESSENCIAIS → FAIL); `claude` OPCIONAL (warn).
2. **Skills no disco** — `assert_nonempty ~/.claude/skills/<n>/SKILL.md` para o conjunto-mínimo
   `idea ideiaos-setup cursor-continuation lovable-handoff` (subconjunto do ORCH do doctor).
   GSD = warn (plugin de marketplace, não FAIL).
3. **Hooks registrados** — `grep -q` por SUBSTRING em `~/.claude/settings.json` para
   `extract-learnings-reminder.sh`, `ideiaos-detector.sh`, `deia-trigger.sh` (sem parser JSON).

### Invariantes cumpridas
- PURO-BASH 3.2: zero `python3`/`sqlite3`/`rg`/`jq`/`declare -A`; não lê `.env`. `grep -c python3` = **0**.
- Reusa `source/lib/gates.sh` (sourcing + guard + fallback inline `assert_nonempty`).
- Fallback gracioso de `claude plugin list`: CONTEXTO (`info`), nunca critério de PASS/FAIL
  (o disco via `test -s` é a fonte-de-verdade — confirmado em runtime que `claude plugin list`
  retorna "No plugins installed" mesmo com 67 GSD + 4 skills instaladas).
- Fronteira contratual smoke↔doctor DOCUMENTADA no header (smoke = bootstrap mínimo; doctor = saúde profunda).

---

## Gates (exit-code colado)

| # | Gate | Resultado |
|---|------|-----------|
| 1a | `test -s scripts/idea-smoke.sh` | exit **0** |
| 1b | `bash -n scripts/idea-smoke.sh` | exit **0** |
| 2a | `grep -c python3 scripts/idea-smoke.sh` | **0** (zero menção) |
| 2b | `! grep -Eqn 'python3\|sqlite3\|rg\|jq\|declare -A'` | exit **0** (puro-bash) |
| 2c | `! grep -Eqn '\.env'` | exit **0** (não lê .env) |
| 3 | `bash scripts/idea-smoke.sh` (build, máquina instalada) | exit **0** (FAIL=0 WARN=0) |
| 4a | `bash scripts/idea-smoke.sh --hook` (máquina normal) | exit **0** |
| 4b | `HOME=<vazio> bash scripts/idea-smoke.sh --hook` (bootstrap quebrado) | exit **0** (hook-contract) |
| 5a | `HOME=<vazio> bash scripts/idea-smoke.sh` (anti-teatro) | exit **1** (gate MORDE) |
| 5b | build com 1 hook ausente (deia-trigger) + skills OK | exit **1**, FAIL=1, aponta o hook específico |

**Secundárias:** `--help` exit 0 · flag desconhecida exit 2 · fallback inline presente ·
header v15 + fronteira citada · `claude plugin list` guardado por `command -v claude` na mesma
condição (exit não propaga) · hooks por substring · `claude` é warn (não FAIL).

---

## Anti-teatro-verde (T-A02-Theater)

O gate NÃO passa em tudo: com HOME vazio o build sai 1 (5a), e com setup quase-completo
faltando exatamente 1 hook o build sai 1 e aponta o hook ausente (5b). O detector é sensível
a falhas isoladas por família — não só ao caso catastrófico.

## Decisões

- `[AUTO-DECISION]` Plano cita `setup.sh:913` para `deia-trigger.sh`; o real é linha 896 →
  usei o NOME exato do hook (`deia-trigger.sh`), que é o que o `grep -q` casa. Número de linha do
  plano é referência, não o contrato.

## Carry-forward

- README sync: o hook lembrou que `scripts/idea-smoke.sh` deve entrar na seção "O que este
  setup instala" / "Estrutura do repositório" do README.md. NÃO feito nesta sessão (fechamento
  do lead). R15-02 (registro do hook no bootstrap) e R15-01 (fix python3, já no HEAD a323e39)
  são unidades separadas — não antecipadas.

## Git / autosync

- **NÃO commitei, NÃO pushei, NÃO mexi no autosync** (já pausado). Único artefato meu:
  `scripts/idea-smoke.sh` (untracked). Os 5 arquivos `M` no working tree pré-existiam
  (nenhum menciona `idea-smoke`). Commit/push são de @dev (local)/@devops (push), no fechamento.
