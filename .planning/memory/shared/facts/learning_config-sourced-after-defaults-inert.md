---
name: learning-config-sourced-after-defaults-inert
description: "Um arquivo de override sourced DEPOIS das linhas `${VAR:-default}` que ele deveria sobrescrever é silenciosamente INERTE — o source tem que vir ANTES dos defaults; pega-se ligando algo que \"deveria\" e nada muda"
metadata: 
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

Quando um script lê config como `VAR="${ENV_VAR:-default}"` E depois faz `. policy.sh` (override por arquivo), a **ordem é load-bearing**: se o `source` vem **depois** das linhas de default, o arquivo de override é **silenciosamente inerte** — os defaults já foram capturados, e o `policy.sh` só consegue afetar variáveis lidas APÓS o seu `source`.

**Caso real (IdeiaOS):** `scripts/check-security-freshness.sh` lia `GATE_ENABLED="${SECFRESH_GATE_ENABLED:-0}"` na linha 56 e só sourçava `.security/policy.sh` na linha 64 → o mecanismo "tunável por `policy.sh`" **nunca funcionou** para NENHUM override (gate, globs, limiares). Descoberto ao tentar LIGAR o gate via policy.sh e ver `gate=advisory` mesmo assim. Fix: mover o `[ -f policy.sh ] && . policy.sh` para **antes** do bloco de defaults.

**How to apply:** num script com defaults `${VAR:-…}` + override sourced, o `source` do override vem **logo após** definir o path dele e **antes** de qualquer `${VAR:-default}`. Sintoma de diagnóstico: "liguei X via o arquivo de config e nada mudou" → confira a ordem source-vs-default. Bônus: para ligar algo na FROTA, mude o **default versionado** no script (`:-1`), não um arquivo de override **gitignored/local-only** (que liga só naquela máquina). Cross-link [[learning-uncommitted-security-config-ephemeral]].
