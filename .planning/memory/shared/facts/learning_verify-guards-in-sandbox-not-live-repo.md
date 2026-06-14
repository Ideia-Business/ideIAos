---
name: verify-guards-in-sandbox-not-live-repo
description: Valide guards de pre-commit em sandbox /tmp limpo — testar no repo vivo com stash+checkout dá falso resultado se o checkout falhar silenciosamente
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6894cb82-2e04-4b3c-8682-fa14d0531c0f
---

**Por quê:** Testar um guard anti-`main` no repo real fazendo `git stash` + `git checkout main 2>/dev/null` + commit é frágil — se o checkout falhar silenciosamente, o commit cai no branch errado (ex.: `work`, onde a regra permite) e o teste reporta um falso "guard quebrado". Aconteceu no v5: alarme falso de "guard não bloqueou"; reproduzido em sandbox `/tmp` limpo provou que o guard estava 100% correto (bloqueia em main, permite em work, respeita override).

**How to apply:** Prove comportamento de guard/barreira em repo descartável (`/tmp/...`), copiando o script real, com branch e index controlados. Nunca confie em troca de branch no repo de trabalho com saída suprimida. Se um teste de guard "falhar", suspeite do harness de teste ANTES do guard. Pareia com [[learning_ambiguous-drift-warning-induces-agent-revert]].
