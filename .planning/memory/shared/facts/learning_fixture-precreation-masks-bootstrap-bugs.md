---
name: fixture-precreation-masks-bootstrap-bugs
description: Fixtures de teste que pré-criam o ambiente (mkdir do alvo) escondem bugs de bootstrap/first-run; valide num alvo real e fresco
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**Por quê:** No v7, o `spec-merge.sh` falhava no archive (`mv ... specs/_archive/...: No such file or directory`) na **primeira change de qualquer produto**, porque não fazia `mkdir -p` do `_archive/`. A suíte `spec-merge.bats` tinha 27 asserts verdes — mas **todo fixture pré-criava `$TMP/specs/_archive`** no setup, então nenhum teste jamais exercitou o caminho "produto novo, `_archive/` ainda não existe". O bug só apareceu ao pilotar a capability `/spec` num produto **real e fresco** (nfideia). Mesma sessão: o mesmo piloto expôs 4 bugs/gaps que os unit tests não pegavam.

**How to apply:** Quando um fixture pré-cria diretórios/estado que o **código de produção deveria criar sozinho** (mkdir, init, migrate, primeira-execução, criação de tabela/bucket), ele mascara bugs de bootstrap. Para qualquer código que faz setup, inclua um caso que **NÃO** pré-cria o ambiente — ou valide num alvo real/limpo. Regra prática: "teste verde com fixture que prepara o terreno ≠ funciona na primeira vez de verdade". Pilotar em produto real é o que fura essa bolha. Pareia com [[verify-guards-in-sandbox-not-live-repo]].
