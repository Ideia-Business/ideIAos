---
name: learning-soak-span-is-record-delta-not-wallclock
description: O span ≥1d do SOAK gate é max-min dos epochs GRAVADOS no ledger, não wall-clock desde o 1º heartbeat — esperar não amadurece o soak; tem que RE-gravar depois de 1 dia
metadata:
  node_type: memory
  type: feedback
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

O `check-soak.sh` calcula o critério "≥1 dia" como `max(epoch) − min(epoch)` sobre
as **linhas já gravadas** no ledger (`analyze()` faz min/max das colunas de epoch).
É o delta entre os **timestamps de gravação**, NÃO o tempo de relógio decorrido
desde o primeiro heartbeat.

**A pegadinha (v11):** com 2 heartbeats gravados no mesmo dia (06-19 17:51 e 18:30),
`span = 0d`. A intuição diz "espero passar a meia-noite / 24h e o soak amadurece" —
**errado**. Se ninguém gravar nada novo, `check-soak` continua dando `0d` amanhã,
porque min e max são os mesmos dois registros de 06-19. O span só cresce quando
**uma nova linha** é appendada com epoch posterior.

**Por quê:** o gate mede diversidade temporal das EVIDÊNCIAS (heartbeats), não
passagem de tempo. Um milestone "soaka" provando que passou nos gates em momentos
distintos — não que ficou parado um dia.

**Como aplicar:**
- Para fechar o `≥1d`: o 1º heartbeat ancora `min`; rode `--record` de novo numa
  máquina **≥ (epoch do 1º heartbeat + 86400s)** — aí `span ≥ 1d`. Ex.: 1º em
  2026-06-19 17:51:44 → re-gravar em ≥ 2026-06-20 17:51:44.
- Não confunda com o critério de **máquinas distintas** (`hosts`), que é satisfeito
  assim que 2 hostnames diferentes aparecem em linhas PASS — independente do span.
- Mesma família de gotcha de [[learning-broad-gitignore-sweeps-tracked-ledger]]: o
  ledger é a fonte de verdade do gate; o que não está gravado nele não conta.
- Vale para qualquer gate que derive "tempo" de timestamps de eventos registrados
  em vez de ler o relógio (cron de maturação, janelas de canary, TTLs por evento).
