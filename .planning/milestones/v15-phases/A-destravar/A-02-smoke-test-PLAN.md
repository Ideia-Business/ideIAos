---
phase: "v15-A"
plan: "A-02"
type: execute
wave: 1
depends_on: []
requirements: [R15-03]
must_haves:
  truths:
    - "scripts/idea-smoke.sh e PURO-BASH (bash 3.2): zero python3, zero sqlite3, zero rg, zero `declare -A`, zero leitura de `.env` — exatamente os pontos onde o idea-doctor degrada cego no Windows nativo (idea-doctor.sh usa python3 em 257/304/311/528/635 + heredocs 334/427/745, sqlite3 em 767/774, rg em 322)"
    - "Default = build-contract: exit 1 se qualquer check ESSENCIAL falhar (espelha check-cockpit.sh:145-150). Flag `--hook` = hook-contract: SEMPRE exit 0 (warn em stderr), nunca trava sessao IDE (antifragile-gates: Hook Contract)"
    - "Reusa source/lib/gates.sh quando IDEIAOS_DIR esta disponivel; senao define o fallback inline `assert_nonempty` (padrao identico a check-cockpit.sh:34-35) — nunca quebra por lib ausente"
    - "Fronteira contratual EXPLICITA no cabecalho do script: smoke responde 'o bootstrap MINIMO esta vivo?' (plugins/skills no disco, hooks registrados em settings.json, comandos basicos resolvem); doctor responde 'a saude PROFUNDA + drift?' (versoes vs lock, secrets em memoria, contencao Lovable MCP, frescor). O smoke NUNCA duplica os checks profundos do doctor"
    - "`claude plugin list` tem fallback gracioso: se `claude` ausente OU o subcomando falhar, o smoke NAO falha o check de plugins — cai para a verificacao no disco (`~/.claude/skills/<nome>/SKILL.md` via `test -s`), que e a fonte-de-verdade do bootstrap (confirmado: `claude plugin list` retorna 'No plugins installed' mesmo com skills instaladas no disco)"
  artifacts:
    - path: "scripts/idea-smoke.sh"
      provides: "Smoke-test puro-bash do bootstrap minimo (exit-code binario), default build / flag --hook"
      contains: "idea-smoke"
  key_links:
    - from: "scripts/idea-smoke.sh"
      to: "source/lib/gates.sh"
      via: "source com guard + fallback inline assert_nonempty"
      pattern: "gates.sh"
    - from: "scripts/idea-smoke.sh"
      to: "~/.claude/settings.json"
      via: "grep -q dos hooks registrados (sem python3/jq — substring match)"
      pattern: "settings.json"
    - from: "scripts/idea-smoke.sh"
      to: "~/.claude/skills/<skill>/SKILL.md"
      via: "test -s no disco (fonte-de-verdade do bootstrap; fallback de `claude plugin list`)"
      pattern: "SKILL.md"
---

<objective>
Criar `scripts/idea-smoke.sh` — um smoke-test **puro-bash** (bash 3.2, sem `python3`, sem `sqlite3`,
sem `rg`, sem `.env`) que prova por **exit-code binario** que o **bootstrap minimo** do IdeiaOS esta
vivo numa estacao fresca, **inclusive no Windows nativo meio-instalado** onde o `idea-doctor` degrada
cego (ele depende de `python3` em 8 pontos — `scripts/idea-doctor.sh:257,304,311,528,635` + heredocs
`334,427,745` — alem de `sqlite3` em `767,774` e `rg` em `322`; sem esses binarios o doctor pula
checagens em silencio ou falha).

O smoke responde UMA pergunta estreita: **"o bootstrap minimo OK?"** — checa tres familias de fato,
todas verificaveis sem dependencia externa:
  (1) **plugins/skills instaladas** no disco (`~/.claude/skills/<nome>/SKILL.md` via `test -s`),
  (2) **hooks registrados** em `~/.claude/settings.json` (substring `grep -q`, sem parser JSON),
  (3) **comandos basicos resolvem** (`command -v` de `node`/`git`/`bash`; `claude` é opcional).

Purpose: e a unidade A-02 da Onda 1 (Fase A "Destravar & Estancar"). No grafo de dependencias do v15,
**R15-02 (registro de hooks no bootstrap) depende de R15-03**: o smoke e a **prova binaria** de que o
registro funcionou (`.planning/milestones/v15-ROADMAP.md:22`). Default = build (exit 1 numa estacao
quebrada); `--hook` = exit 0 sempre (pode ser plugado num SessionStart sem travar a IDE).

Output: `scripts/idea-smoke.sh` (novo, com header `# SOURCE: IdeiaOS v15 | kind: gate | targets: claude,cursor`).

**Fronteira contratual (definida ANTES de codar, exigida pelo requisito R15-03):**

| Eixo | `idea-smoke.sh` (este) | `idea-doctor.sh` (existente) |
|------|------------------------|------------------------------|
| Pergunta | "o **bootstrap MINIMO** esta vivo?" | "qual a **saude PROFUNDA + drift** do ambiente?" |
| Dependencias | **puro-bash 3.2** (zero python3/sqlite3/rg) | python3 (8 pts), sqlite3, rg, launchctl, git refs |
| Ambiente-alvo | estacao fresca / **Windows nativo meio-instalado** | macOS dev-machine totalmente provisionada |
| Escopo | skills no disco · hooks registrados · comandos resolvem | versoes vs lock · secrets em memoria · contencao Lovable MCP · frescor de seguranca · drift global×fonte · cockpit |
| Default exit | build: **1** em falha (com `--hook` → **0** sempre) | 1 se FAIL, 0 caso contrario |

**Invariante de nao-duplicacao:** o smoke NUNCA reimplementa um check profundo do doctor (versao,
secret-scan, drift, frescor). Se um fato exige python3/sqlite3/rg, ele e do DOCTOR, nao do smoke.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/milestones/v15-ROADMAP.md
@.planning/milestones/v15-REQUIREMENTS.md
@scripts/idea-doctor.sh
@scripts/check-cockpit.sh
@source/lib/gates.sh
@setup.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Esqueleto puro-bash + fronteira contratual no header + sourcing de gates.sh com fallback inline + parse de --hook/--help</name>
  <files>scripts/idea-smoke.sh</files>
  <read_first>
    - scripts/check-cockpit.sh:1-52 (o MOLDE: header `# SOURCE: IdeiaOS v14 | kind: gate`; `set -uo pipefail`; `ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"`; cores ok/warn/err/info; fallback inline do gate em 34-35: `type assert_nonempty >/dev/null 2>&1 || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }`; `FAIL=0`; resultado 144-150 com exit 1)
    - source/lib/gates.sh:18-44 (guard `__IDEIAOS_GATES_LOADED`; `assert_nonempty PATH [LABEL]` = `test -s`; sinonimos `gate_output`/`require_file`; contrato "Hooks → warn + exit 0 / Scripts → exit 1" em 12-16)
    - scripts/idea-doctor.sh:21-33 (estilo de cabecalho ANSI + `set -uo pipefail` + paleta de cores — REUSAR o mesmo visual)
    - .planning/milestones/v15-REQUIREMENTS.md:24 (texto canonico de R15-03 — copiar a fronteira "smoke = bootstrap minimo OK? / doctor = saude profunda" no header)
  </read_first>
  <action>
    Criar `scripts/idea-smoke.sh` com:
    (a) Shebang `#!/usr/bin/env bash` + header de proveniencia
        `# SOURCE: IdeiaOS v15 | kind: gate | targets: claude,cursor` e um bloco-comentario que DECLARA a
        FRONTEIRA CONTRATUAL com o doctor (a tabela do <objective> em prosa curta): smoke = "bootstrap minimo
        OK?" puro-bash p/ Windows nativo; doctor = "saude profunda" (python3/sqlite3). Documentar `Exit: 0=ok,
        1=bootstrap quebrado` e `Uso: bash scripts/idea-smoke.sh [--hook]`.
    (b) `set -uo pipefail` (NAO `set -e` — queremos rodar TODOS os checks e contar falhas, igual idea-doctor/check-cockpit).
    (c) Paleta de cores + helpers `ok/warn/err/info` copiados de check-cockpit.sh:27-31. Contador `FAIL=0` e `WARN=0`.
    (d) Parse de flags: `MODE="${1:-}"`. `--hook` liga `HOOK_MODE=1`; `--help`/`-h` imprime uso e sai 0; flag
        desconhecida → uso + exit 2 (erro de invocacao, espelha check-cockpit.sh:17).
    (e) Sourcing de gates.sh com guard + fallback inline (PADRAO check-cockpit.sh:33-35):
        `IDEIAOS_DIR="${IDEIAOS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"`;
        `[ -f "$IDEIAOS_DIR/source/lib/gates.sh" ] && . "$IDEIAOS_DIR/source/lib/gates.sh"`;
        depois `type assert_nonempty >/dev/null 2>&1 || assert_nonempty() { test -s "${1:-}" 2>/dev/null; }`.
        ZERO `declare -A` (bash 3.2). ZERO python3/sqlite3/rg/jq em QUALQUER linha.
    (f) Stub das tres familias de check (funcoes vazias `check_skills`, `check_hooks`, `check_commands`) e do
        sumario (a Task 2 preenche). Por ora cada uma so faz `:` para o esqueleto compilar.
    (g) `chmod +x scripts/idea-smoke.sh`.
  </action>
  <acceptance_criteria>
    - Sintaxe valida bash: `bash -n scripts/idea-smoke.sh` exit 0.
    - PURO-BASH (negativa, exit-code): nenhuma chamada a python3/sqlite3/rg/jq nem `declare -A` —
      `! grep -Eqn 'python3|sqlite3|[^a-zA-Z]rg |[^a-zA-Z]jq |declare -A' scripts/idea-smoke.sh` exit 0.
    - NAO le `.env`: `! grep -Eqn '\.env([^a-zA-Z]|$)' scripts/idea-smoke.sh` exit 0.
    - Header de proveniencia presente: `grep -q '# SOURCE: IdeiaOS v15' scripts/idea-smoke.sh` exit 0.
    - Fronteira contratual citada no header: `grep -qiE 'bootstrap m[ií]nimo' scripts/idea-smoke.sh && grep -qi 'doctor' scripts/idea-smoke.sh` exit 0.
    - Fallback inline do gate presente (resiliencia a lib ausente): `grep -q 'assert_nonempty() { test -s' scripts/idea-smoke.sh` exit 0.
    - `--help` sai 0: `bash scripts/idea-smoke.sh --help >/dev/null 2>&1; [ $? -eq 0 ]` (gate: `bash scripts/idea-smoke.sh --help >/dev/null 2>&1`).
    - Executavel: `test -x scripts/idea-smoke.sh` exit 0.
  </acceptance_criteria>
  <done>idea-smoke.sh existe, compila (`bash -n`), e puro-bash 3.2 (gate nega python3/sqlite3/rg/jq/declare -A e `.env`), declara a fronteira com o doctor no header, e tem o fallback inline de gates.sh.</done>
</task>

<task type="auto">
  <name>Task 2: Os 3 checks essenciais (skills no disco · hooks registrados · comandos resolvem) com fallback gracioso de `claude plugin list` + dual-contract de exit (build 1 / --hook 0)</name>
  <files>scripts/idea-smoke.sh</files>
  <read_first>
    - scripts/idea-doctor.sh:152-161 (§1 "Skills globais": `GSKILLS="$HOME/.claude/skills"`; lista canonica de orquestracao `ORCH="idea ideiaos-setup cursor-continuation lovable-handoff recall-learnings extract-learnings"`; criterio `[ -f "$GSKILLS/$s/SKILL.md" ]`; GSD `ls -d "$GSKILLS"/gsd-* | wc -l`) — REUSAR o MESMO conjunto-minimo, mas com `test -s` (gate antifragil), nao `[ -f ]`
    - setup.sh:740-760 (registro do hook extract-learnings-reminder: `grep -q "extract-learnings-reminder.sh" "$SETTINGS_FILE"`), setup.sh:787-804 (ideiaos-detector.sh), setup.sh:810-830 (skill ideiaos-setup) — os nomes EXATOS dos hooks que o bootstrap registra em ~/.claude/settings.json
    - scripts/idea-doctor.sh:174-181 (§3 MCPs: `command -v claude` antes de chamar `claude mcp get`) — o smoke faz o MESMO probe defensivo com `claude plugin list`
    - scripts/check-cockpit.sh:144-150 (resultado: `if [ "$FAIL" -gt 0 ]; then ... exit 1; fi; ... exit 0`) — o dual-contract envolve isso num if HOOK_MODE
    - setup.sh:557-578 (§1 Pre-requisitos: `command -v node`, `command -v git` — os comandos basicos que devem resolver)
  </read_first>
  <action>
    (a) `check_commands` — comandos basicos resolvem: `command -v node`, `command -v git`, `command -v bash`
        (ESSENCIAIS → contam FAIL se ausentes). `command -v claude` e OPCIONAL (warn se ausente, nunca FAIL —
        o smoke deve passar mesmo onde o `claude` CLI nao esta no PATH, cf. idea-doctor.sh:179 que so avisa).
    (b) `check_skills` — bootstrap de skills no DISCO (fonte-de-verdade): `GSKILLS="$HOME/.claude/skills"`. Para
        cada skill do conjunto-minimo `idea ideiaos-setup cursor-continuation lovable-handoff` (subconjunto do
        ORCH do doctor — o nucleo que o setup.sh instala), gate `assert_nonempty "$GSKILLS/$s/SKILL.md"` →
        FAIL por skill ausente/vazia. GSD: contar `ls -d "$GSKILLS"/gsd-* 2>/dev/null | wc -l` > 0 (warn, nao
        FAIL — GSD vem de plugin de marketplace, pode faltar numa estacao crua sem travar o smoke).
        FALLBACK GRACIOSO de `claude plugin list`: SE `command -v claude` E `claude plugin list` sair 0,
        emitir um `info` com a saida (contexto); MAS a decisao PASS/FAIL vem SEMPRE do `test -s` no disco —
        nunca do `claude plugin list` (confirmado em runtime: `claude plugin list` retorna "No plugins installed"
        mesmo com as skills instaladas no disco; usa-lo como criterio daria falso-FAIL). Envolver a chamada em
        `if command -v claude >/dev/null 2>&1 && claude plugin list >/dev/null 2>&1; then ... fi` — nunca deixar
        o exit do `claude` propagar.
    (c) `check_hooks` — hooks REGISTRADOS em settings.json por SUBSTRING (sem parser JSON, puro grep, igual
        setup.sh:742). `SETTINGS="$HOME/.claude/settings.json"`. Se ausente → FAIL ("settings.json nao
        encontrado"). Para cada hook-nucleo que o bootstrap registra — `extract-learnings-reminder.sh`,
        `ideiaos-detector.sh`, `deia-trigger.sh` (nomes EXATOS de setup.sh:742/788/913) — `grep -q "<nome>"
        "$SETTINGS"` → FAIL se nao-registrado. (Substring match e suficiente e e puro-bash; NAO parsear o JSON
        com python3 — isso seria recair no modo-falha do doctor.)
    (d) Roteador + dual-contract de exit: chamar as 3 funcoes; imprimir sumario `OK/WARN/FAIL`. No fim:
        `if [ "${HOOK_MODE:-0}" -eq 1 ]; then [ "$FAIL" -gt 0 ] && echo "idea-smoke: bootstrap incompleto ($FAIL)" >&2; exit 0; fi`
        (HOOK CONTRACT — sempre 0, warn em stderr; antifragile-gates "Hooks → exit 0"). Senao (BUILD CONTRACT):
        `[ "$FAIL" -gt 0 ] && exit 1; exit 0` (espelha check-cockpit.sh:145-150). Cada FAIL imprime a REMEDIACAO
        concreta (ex.: "rode: bash setup.sh --global-only" para skill ausente; "rode: bash scripts/ideiaos-update.sh"
        ou "bash setup-dev-machine.sh" para hook nao-registrado — espelhando as remediacoes do idea-doctor).
  </action>
  <acceptance_criteria>
    - Sintaxe ok: `bash -n scripts/idea-smoke.sh` exit 0.
    - PURO-BASH preservado (re-checar apos Task 2): `! grep -Eqn 'python3|sqlite3|[^a-zA-Z]rg |[^a-zA-Z]jq |declare -A' scripts/idea-smoke.sh` exit 0.
    - BUILD CONTRACT verde nesta estacao (bootstrap real instalado): `bash scripts/idea-smoke.sh >/dev/null 2>&1; [ $? -eq 0 ]` (gate: `bash scripts/idea-smoke.sh >/dev/null 2>&1`).
    - HOOK CONTRACT = SEMPRE exit 0, mesmo com bootstrap quebrado: provar com HOME falso vazio —
      `tmp="$(mktemp -d)"; HOME="$tmp" bash scripts/idea-smoke.sh --hook >/dev/null 2>&1; rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]`
      (gate: `tmp="$(mktemp -d)"; HOME="$tmp" bash scripts/idea-smoke.sh --hook >/dev/null 2>&1 && rm -rf "$tmp"`).
    - BUILD CONTRACT FALHA num HOME vazio (prova que o gate morde — anti-teatro-verde): exit != 0 →
      gate: `tmp="$(mktemp -d)"; ! HOME="$tmp" bash scripts/idea-smoke.sh >/dev/null 2>&1; rc=$?; rm -rf "$tmp"; [ "$rc" -eq 0 ]`
      (i.e. o build-contract retorna nao-zero num HOME sem skills/settings).
    - Fallback gracioso de `claude plugin list` (nao e criterio de PASS/FAIL): `grep -q 'claude plugin list' scripts/idea-smoke.sh && grep -q 'command -v claude' scripts/idea-smoke.sh` exit 0;
      e o `claude plugin list` esta guardado por `command -v claude` na MESMA condicao (sem deixar o exit propagar):
      `grep -Eq 'command -v claude[^|]*claude plugin list|command -v claude.*&&.*claude plugin list' scripts/idea-smoke.sh` exit 0.
    - Hooks checados por SUBSTRING (nao por parser JSON): `grep -q 'extract-learnings-reminder.sh' scripts/idea-smoke.sh && grep -q 'ideiaos-detector.sh' scripts/idea-smoke.sh` exit 0.
    - `claude` e OPCIONAL (smoke nao falha por ausencia de claude): rodar com um PATH sem `claude` mas com node/git ainda DEVE distinguir-se do caso skills-ausentes — verificacao manual: a funcao `check_commands` marca `claude` como warn, nao FAIL (`grep -nA3 'command -v claude' scripts/idea-smoke.sh` mostra `warn`, nao `FAIL=`).
  </acceptance_criteria>
  <done>os 3 checks rodam; build-contract verde nesta estacao e nao-zero num HOME vazio (gate morde); hook-contract sai 0 sempre; `claude plugin list` e contexto gracioso (nunca criterio); hooks checados por substring.</done>
</task>

</tasks>

<conditions>
## Invariantes que o executor DEVE respeitar

1. **PURO-BASH 3.2, inegociavel.** Zero `python3`, `sqlite3`, `rg`, `jq`, `declare -A`, leitura de `.env`.
   O proposito do script e rodar ONDE o doctor NAO roda (Windows nativo sem python3 —
   `scripts/idea-doctor.sh:257,304,311,528,635,334,427,745,767,774,322`). Usar qualquer um desses binarios
   ANULA o requisito. Gate negativo em ambas as tasks.
2. **Antifragile-gates.** Toda verificacao de existencia de arquivo usa `test -s` / `assert_nonempty`
   (exit-code binario), NUNCA o Read tool. Cada `<task>` termina num GATE por exit-code.
3. **Dual-contract de exit (lei de antifragile-gates).** Default (build) = exit 1 em falha; `--hook` = exit 0
   SEMPRE (warn em stderr). Um hook que sai != 0 trava a sessao IDE — proibido.
4. **Fallback gracioso, nunca cego.** `claude plugin list` e `claude` sao OPCIONAIS: o smoke usa o DISCO
   (`test -s ~/.claude/skills/<n>/SKILL.md`) como fonte-de-verdade e so usa `claude` como contexto extra,
   guardado por `command -v claude`. NUNCA deixar o exit do `claude` propagar para o exit do smoke.
5. **Fronteira contratual respeitada (R15-03).** O smoke NAO reimplementa nenhum check profundo do doctor
   (versoes vs lock, secret-scan em memoria, contencao Lovable MCP, frescor de seguranca, drift global×fonte,
   cockpit). Se um fato exige python3/sqlite3/rg, ele e do DOCTOR. A fronteira fica DOCUMENTADA no header.
6. **Reuso, nao reinvencao.** Reusar `source/lib/gates.sh` (com fallback inline de check-cockpit.sh:34-35),
   o conjunto-minimo de skills de `idea-doctor.sh:154` e os nomes de hook de `setup.sh` (742/788/913).
   Nao duplicar a logica de cor/sumario — copiar o molde de check-cockpit.sh.
7. **Escopo cirurgico.** Tocar APENAS `scripts/idea-smoke.sh` (arquivo novo). NAO editar idea-doctor.sh,
   setup.sh, gates.sh nem qualquer hook. R15-02 (registro no bootstrap) e R15-01 (fix python3) sao unidades
   SEPARADAS desta Fase A — nao antecipar. Divida fora de escopo vira marcador `# debt:`.
8. **Autosync.** Este plano cria UM arquivo novo (`scripts/idea-smoke.sh`); nao e cirurgia multi-arquivo
   git. Ainda assim, se o executor for tocar varios arquivos por engano, PAUSAR o autosync antes
   (`scripts/autosync-pause.sh`) e restaurar depois — mas o escopo correto e 1 arquivo, sem necessidade.
9. **@devops exclusivo.** Este plano NUNCA faz `git push` nem `gh pr`. Commit local (se houver) e do @dev;
   push e do @devops.
10. **Anti-teatro-verde.** O gate de sucesso DEVE incluir um caso NEGATIVO que prova que o build-contract
    MORDE (HOME vazio → exit != 0). Um smoke que passa em TUDO, inclusive num ambiente quebrado, e teatro.
</conditions>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| ambiente meio-instalado (Windows nativo) → idea-smoke.sh | o script roda SEM python3/sqlite3/rg; qualquer dep externa quebraria silenciosamente o proprio proposito |
| `claude plugin list` (terceiro) → decisao PASS/FAIL | a saida do CLI `claude` e CONTEXTO, nunca criterio; o disco (`test -s`) e a fonte-de-verdade |
| `~/.claude/settings.json` → check de hooks | leitura por substring `grep -q` (read-only); o smoke nunca escreve em settings.json |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-A02-DoS | Denial of Service | `--hook` saindo != 0 | mitigate | dual-contract: `--hook` sempre exit 0 (warn stderr); gate prova HOOK_MODE=0-exit mesmo com HOME vazio (antifragile Hook Contract) |
| T-A02-FP | False Positive | criterio em `claude plugin list` | mitigate | PASS/FAIL vem so do `test -s` no disco; `claude` guardado por `command -v` e exit nunca propaga; gate confirma o guard |
| T-A02-Hidden | Hidden dependency | python3/sqlite3/rg infiltrado | mitigate | gate negativo `! grep -Eq 'python3|sqlite3|rg|jq|declare -A'` em AMBAS as tasks — falha o build se algum reaparecer |
| T-A02-Theater | Green Theater | smoke passa sempre | mitigate | gate negativo obrigatorio: build-contract DEVE sair != 0 num HOME vazio (o gate que morde) |
</threat_model>

<verification>
- `bash -n scripts/idea-smoke.sh` exit 0 (sintaxe).
- `! grep -Eq 'python3|sqlite3|[^a-zA-Z]rg |[^a-zA-Z]jq |declare -A' scripts/idea-smoke.sh` exit 0 (puro-bash).
- `bash scripts/idea-smoke.sh` exit 0 nesta estacao (build verde) E `! HOME=<vazio> bash scripts/idea-smoke.sh` (gate morde).
- `HOME=<vazio> bash scripts/idea-smoke.sh --hook` exit 0 (hook contract).
- header com `# SOURCE: IdeiaOS v15` + fronteira "bootstrap minimo" vs "doctor"; fallback `claude plugin list` guardado por `command -v claude`.
</verification>

<success_criteria>
- `scripts/idea-smoke.sh` existe, executavel, puro-bash 3.2 (gate nega python3/sqlite3/rg/jq/declare -A/.env).
- Default = build (exit 1 em bootstrap quebrado, provado com HOME vazio); `--hook` = exit 0 sempre.
- Checa skills no disco (`test -s`), hooks registrados (substring em settings.json), comandos basicos resolvem.
- `claude plugin list` e fallback gracioso (contexto, nunca criterio).
- Fronteira contratual smoke↔doctor documentada no header (R15-03 cumprido).
- Reusa source/lib/gates.sh com fallback inline; escopo cirurgico (so 1 arquivo novo).
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-02-smoke-test-SUMMARY.md` when done
</output>
