---
name: learning-aggregator-status-from-verdict-not-absence
description: "Agregador read-only de saúde deve derivar status do VEREDITO explícito (exit-code), não da ausência de FAIL — e o agregador honesto EXPÕE o bug de coleta a montante"
metadata:
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Ao construir painel/agregador read-only de saúde sobre snapshots de terceiros (caso real: `idea-doctor --fleet` / R15-09 sobre o ref `cockpit`), derive o status do **VEREDITO EXPLÍCITO** da fonte (`doctor.exit`), nunca da ausência de sinal negativo (`fail==0`). Coleta quebrada a montante zera os contadores (`ok=warn=fail=0, exit=-1`): se o critério for só "sem FAIL", isso vira **FALSO-VERDE**. Marque `exit<0` ou total-de-checks==0 como **VAZIO/sem-veredito** — estado distinto de OK e de FAIL.

Bônus diagnóstico: o agregador honesto **EXPÕE o bug de coleta a montante**. Aqui o `--fleet` revelou que `idea-doctor --json` emitia JSON inválido (vazamento do detalhe de debt-markers do §12, ~linha 742, via `printf` sem guard `JSON_MODE`) → `collect.js` falhava o parse e gravava o fallback `doctor.exit=-1`. O fix foi commit SEPARADO (`f80e9c5`, bugfix) do feature do agregador (`3b05c00`, R15-09).

**Why:** "Sem FAIL" e "saudável" não são a mesma coisa quando a coleta pode falhar e zerar os contadores: um pipeline quebrado (exit=-1, contadores=0) se disfarça de verde se o critério for ausência de negativo. Derivar status do veredito explícito torna o agregador antifrágil (não confia em ausência de sinal) e o transforma em sonda do próprio pipeline de coleta — acende quando a montante quebra, em vez de mascarar. Liga a [[antitheater-gate-blind-spot-happy-path]] (verde que esconde bypass).

**How to apply:** (1) Em qualquer agregador read-only de status, trate `exit<0`/ausente e total-de-checks==0 como um terceiro estado VAZIO/sem-veredito, computado ANTES de FAIL/WARN/OK; nunca colapse "sem FAIL" em "OK". (2) Em todo script com modo `--json`, qualquer `printf`/`echo` de detalhe humano DEVE estar sob `if [ "$JSON_MODE" -eq 0 ]` — vazamento p/ stdout invalida o JSON que o sink (collect.js) parseia e produz `exit=-1` silencioso. (3) Quando o agregador mostrar VAZIO/exit=-1, suspeite primeiro de poluição de stdout no produtor do JSON, não de falha real do sistema observado. (4) Mantenha o bugfix da coleta em commit separado do feature do agregador (disciplina de escopo).
