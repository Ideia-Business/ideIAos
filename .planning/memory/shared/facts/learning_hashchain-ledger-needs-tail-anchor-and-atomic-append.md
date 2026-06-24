---
name: hashchain-ledger-needs-tail-anchor-and-atomic-append
description: Um ledger hash-chained (prev_hash) é CEGO na última entrada (nada a checa) e PERDE entradas sob append não-atômico — precisa de âncora-de-cauda (HEAD-file contagem+sha) + lock-por-dir/O_APPEND
metadata:
  node_type: memory
  type: feedback
  originSessionId: a6ecbb78-45bd-4705-807c-27b430912bf8
---

Construí um ledger de auditoria hash-chained append-only (v14.4 B6, `source/agentd/ledger.sh`):
cada entrada carrega `prev_hash = sha256(linha-entrada anterior)`. A verificação adversarial achou
**2 defeitos estruturais** que o gate verde do próprio agente NÃO pegava (o teste só cobria append
SEQUENCIAL + adulteração do INTERIOR):

1. **CEGUEIRA NA CAUDA (CRITICAL):** a hash-chain prova cada entrada via o `prev_hash` da entrada
   SEGUINTE. A **última** entrada não tem "seguinte" → **nada a checa**. Editar/substituir/truncar a
   última, ou fazer append-forjado-no-fim (com `prev_hash` real), dava `verify=0` (íntegro). Não-repúdio
   quebrado na cauda. **Fix:** ÂNCORA-DE-CAUDA — um HEAD-file 0600 separado = `"<contagem>|sha256(última-linha)"`,
   atualizado atomicamente a cada append; `verify` exige contagem==HEAD.count E sha(última)==HEAD.sha.
   Traz a cauda à PARIDADE do interior.

2. **APPEND NÃO-ATÔMICO PERDE ENTRADAS (HIGH):** o append fazia read-modify-write do arquivo INTEIRO
   (`{ cat store; printf linha; } > tmp; mv tmp store`). Sob concorrência = last-writer-wins → 20 appends
   paralelos preservavam ~5-7, e a cadeia quebrava (`verify=3`). Uma corrida acidental vira
   INDISTINGUÍVEL de adulteração. **Fix nativo (sem dep — macOS não tem flock(1)):** lock-por-diretório
   (`mkdir "$STORE.lock.d"` é atômico no FS local) ao redor de ler-tail+computar-prev+gravar, e
   **O_APPEND** de 1 linha (`printf >> store`, atômico <PIPE_BUF) no lugar do RMW. Contraste: o irmão
   `ack.sh` (1-arquivo-por-hash + noclobber) já preservava 20/20 — o anti-padrão que ele evita e o
   ledger não evitava.

**Why:** "hash-chain" soa completo, mas prova só elos INTERNOS; o último elo fica solto. E "escrita
atômica" do `mv` final não torna atômico o ler-todo→reescrever-todo. Os dois são modos de falha
clássicos de log append-only que um gate happy-path (sequencial + interior) não exercita.

**How to apply:**
- Todo ledger/log append-only verificável precisa de uma **âncora externa da cauda** (HEAD/checkpoint
  com contagem + hash da última), senão a última entrada é forjável/truncável sem detecção.
- Append concorrente: **lock-por-dir (`mkdir`) + O_APPEND**, nunca read-modify-write do arquivo inteiro.
  Teste com N appends PARALELOS exigindo `linhas==N E verify==0` — não só sequencial.
- **Limite honesto:** cadeia+âncora NÃO-assinadas só detectam adulteração acidental/parcial/uncoordenada
  (um store-writer reescreve cadeia+HEAD juntos, ou apaga tudo). Tamper-evidência real contra
  store-writer = **assinar a âncora** com chave fora do store (ex.: chave de máquina). Declare esse
  limite no header + `debt:` se diferir.
- Cross-link: [[antitheater-gate-blind-spot-happy-path]] (o gate verde escondia ambos — exercite input
  inválido em CADA eixo + mutação), [[learning-review-own-design-before-build-with-refutation]],
  rule `antifragile-gates`, [[credential-isolation]].
