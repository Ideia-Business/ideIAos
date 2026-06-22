# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6

# Delta: cockpit — v14.4-write-path-security

**Capability alvo:** cockpit
**Change slug:** v14.4-write-path-security
**Data do delta:** 2026-06-22

Rastreabilidade: todo requisito abaixo deriva de `docs/ideiaos-console/70-security-v14_4-threat-model-precursor.md`
(§2 STRIDE, §2-bis assinatura O1–O6, §3 emissor-como-commit, §4 RBAC, §5 janela-teardown,
§6 fronteira, §7 least-privilege, §8 Q1–Q9, §9 veredito) e `77-atalaia-alerts-command-allowlist.md` §B.2.
Nenhum comportamento inventado — cada DEVE traça a uma seção do precursor.

---

## ADICIONADO Requisitos

### Requisito: Autenticação de origem do comando cross-máquina (fail-closed)

O Cockpit DEVE autenticar todo comando cross-máquina por uma **assinatura verificável da
máquina-origem**, cuja chave privada reside no keychain do SO e NUNCA transita pelo contexto do
LLM, do browser, nem por qualquer ref git. O `agentd`-alvo DEVE verificar a assinatura contra uma
chave-pública **fixada** (pinned) antes de executar; sem assinatura válida e verificada, DEVE
recusar a execução (fail-closed) e registrar a recusa. Um checksum de integridade (`sha256`) do
conteúdo NÃO satisfaz este requisito — integridade ≠ autenticidade. A confiabilidade da
chave-pública fixada depende do bootstrap (Q1) e da revogação (Q2) cravados em R-WP10/ADR:
verificar a assinatura NÃO basta se a chave foi pinada por canal não-confiável.

#### Cenário: comando assinado por máquina confiável

- **QUANDO** chega um comando cross-máquina com assinatura válida verificável contra uma chave-pública fixada
- **ENTÃO** o `agentd`-alvo prossegue para a verificação de autorização (papel/escopo)

#### Cenário: comando sem assinatura ou com assinatura inválida

- **QUANDO** chega um comando sem assinatura, com assinatura inválida, ou de chave não-fixada
- **ENTÃO** o `agentd`-alvo recusa a execução (fail-closed) e grava a recusa no ledger

#### Cenário: comando apenas com sha256

- **QUANDO** o comando traz só um `sha256` do payload como prova de origem
- **ENTÃO** o `agentd`-alvo recusa — checksum de integridade não é prova de autenticidade


### Requisito: Papel (RBAC) provado por assinatura, nunca auto-declarado

O papel do emissor (`cto`/`dev`) que autoriza uma ação DEVE ser **provado pela assinatura** da
máquina-origem, amarrando papel↔chave↔máquina, e NUNCA aceito como campo auto-declarado no payload.
A autorização DEVE ser **default-deny no `agentd`-alvo** (não apenas na UI, que é cosmética e
falsificável): qualquer capacidade não-listada para o papel é negada.

#### Cenário: papel declarado sem lastro de assinatura

- **QUANDO** o payload declara `role:cto` mas a assinatura verificada não amarra esse papel à chave da máquina-origem
- **ENTÃO** o `agentd`-alvo recusa a ação (RBAC sem assinatura é falsificável)

#### Cenário: UI permite, agentd nega

- **QUANDO** a UI do Cockpit oferece uma ação que o papel provado por assinatura não autoriza
- **ENTÃO** o `agentd`-alvo recusa (a decisão é do enforcement server-side, não da UI)


### Requisito: Aprovação humana como token de capability assinado de uso único

Para ações que exigem step-up (tiers `sensível`/`alto`/`crítico`), a aprovação humana DEVE ser
convertida num **token de aprovação assinado, de uso único**, com binding completo
(`subject+role+action+ref+scope+nonce+expiry`) que **viaja com o comando** — nunca uma sessão de
browser. O segredo que assina o step-up NÃO DEVE residir no browser. O `agentd`-alvo DEVE rejeitar
token expirado, `nonce` reusado, ou binding que não case com o comando.

#### Cenário: token válido e inédito

- **QUANDO** o comando carrega um token de aprovação com assinatura válida, `nonce` inédito, dentro do `expiry`, e binding que casa com `action`/`ref`/`scope`
- **ENTÃO** o `agentd`-alvo autoriza a ação

#### Cenário: replay ou expiração

- **QUANDO** o token está expirado OU seu `nonce` já consta no registro de nonces-vistos do alvo
- **ENTÃO** o `agentd`-alvo recusa (anti-replay)

#### Cenário: binding divergente

- **QUANDO** o binding do token (`action`/`ref`/`scope`) não corresponde ao comando recebido
- **ENTÃO** o `agentd`-alvo recusa (aprovação não vale para esta ação)


### Requisito: Nenhum valor de segredo trafega no canal de comando

O comando cross-máquina e seu resultado DEVEM conter apenas **referência e metadado** (nome,
escopo, `new_age`, `new_id`, `result`) — NUNCA o valor de um segredo. Na rotação, o novo valor DEVE
ser gerado **na máquina-alvo**, gravado no keychain do alvo, e NUNCA retornar à origem, ao browser
ou ao ref. Estende o invariante Zero-Leak ao write-path. Além do valor, a EXPOSIÇÃO de metadado
sensível a um terceiro (o histórico "quem rotacionou o quê quando" no `origin`/GitHub) DEVE ser
minimizada: se/como o ref de comando alcança o `origin` (não empurrar; ou ref órfão squashed por
janela curta) é decisão **gated** registrada em ADR (Q5) antes da habilitação cross-máquina.

#### Cenário: rotação de credencial

- **QUANDO** uma rotação cross-máquina conclui
- **ENTÃO** o ref de comando e o ledger carregam só metadado (`new_age=0`, `new_id`, `result`), e o novo valor permanece exclusivamente no keychain do alvo

#### Cenário: gate de release sobre o canal de comando

- **QUANDO** o build de release avalia qualquer artefato do canal de comando (ref, payload, ledger, log)
- **ENTÃO** a ocorrência de um valor de segredo reprova o build (incidente P0, bloqueia merge)

#### Cenário: superfície de metadado no terceiro

- **QUANDO** o ref de comando seria propagado ao `origin` (GitHub, terceiro semi-confiável)
- **ENTÃO** a exposição do nome+escopo das credenciais mutadas é minimizada conforme a decisão Q5 (ADR), nunca propagada por padrão sem essa decisão


### Requisito: Janela de privilégio com grants de teardown enumerados na abertura

Toda janela de privilégio para uma ação irreversível (`rotate`/`revoke`/`deploy`) DEVE enumerar,
**no instante da abertura**, tanto os grants de trabalho quanto os grants de **teardown/rollback**
(revogar token órfão, restaurar valor anterior, registrar no ledger). O fechamento da janela DEVE
ser verificado por exit-code, não por inspeção. Nenhuma janela passa na revisão do contrato sem a
coluna de teardown preenchida. A enumeração-de-teardown é um gate de **revisão de contrato/desenho**
(verificado em tempo de revisão), distinto dos cenários de fail-closed em runtime — o fechamento da
janela em runtime continua verificado por exit-code (`antifragile-gates`).

#### Cenário: rollback após falha de gravação

- **QUANDO** o novo token já foi criado na API do provedor mas a gravação no keychain do alvo falha
- **ENTÃO** o rollback (revogar o token órfão + restaurar o valor anterior) está autorizado **dentro da mesma janela**, sem precisar reabrir privilégio

#### Cenário: janela sem teardown declarado

- **QUANDO** o desenho de uma janela de privilégio para ação irreversível omite os grants de rollback
- **ENTÃO** a revisão do `/spec` recusa o desenho (teardown é pré-condição de aprovação)


### Requisito: Least-privilege de posse — o agentd nunca retém valor de segredo

O `agentd` NÃO DEVE manter valores de segredo em memória ou estado durável. Cada ação DEVE resolver
o segredo sob demanda dentro da janela e descartá-lo ao fechar. Quando a CLI do provedor resolve do
keychain por si (ex.: `gh`), o `agentd` DEVE preferir esse caminho e NÃO ler o valor. Onde o valor
precise entrar no env de um processo-filho efêmero, isso DEVE ser tratado como **risco residual
documentado por provedor**, nunca ignorado nem persistido em log/arquivo/variável durável.

#### Cenário: provedor com CLI keychain-nativa

- **QUANDO** a ação usa um provedor cuja CLI resolve o token do keychain (ex.: `gh`)
- **ENTÃO** o `agentd` invoca a CLI sem nunca ler o valor do token

#### Cenário: provedor sem keychain-nativo

- **QUANDO** a CLI do provedor exige o token via env
- **ENTÃO** o valor vive apenas no env de um processo-filho efêmero (resolvido na borda da invocação), é documentado como risco residual aceito, e NUNCA aparece em log, arquivo ou variável durável do `agentd`


### Requisito: Fronteira permanente — verbos que nunca entram no allowlist

O Cockpit NUNCA DEVE expor — independentemente de quão forte seja a autenticação — os verbos:
`reveal`/cópia de valor de segredo; `exec`/shell arbitrário no `agentd`; `git push`/`gh pr`;
adicionar/remover/(re)configurar MCP; rotação/revogação/`deploy` **automáticos** sem ator humano;
custódia de qualquer chave-mestra central; e `revoke`/`rotate` **em massa atômico**. Estas
capacidades ficam fora por risco **estrutural**, não por falta de autenticação.

#### Cenário: pedido de revelar valor de segredo

- **QUANDO** uma ação `reveal`/copiar-valor é solicitada, mesmo por operador autenticado
- **ENTÃO** o Cockpit recusa (regra-piso `credential-isolation`; o valor busca-se na fonte via terminal, fora do Cockpit)

#### Cenário: pedido de revogação em massa

- **QUANDO** uma ação de `revoke`/`rotate` em massa num clique é solicitada
- **ENTÃO** o Cockpit recusa (DoS estrutural sobre produção) — `revoke`/`rotate` em massa num clique nunca é ação atômica admissível

#### Cenário: operação exclusiva de @devops

- **QUANDO** `git push`, `gh pr` ou alteração de MCP é solicitada pelo Cockpit
- **ENTÃO** o Cockpit no máximo gera o comando para `@devops`, nunca o executa (cross-máquina não cria exceção à `agent-authority`)


### Requisito: Comando assíncrono idempotente com ACK do alvo

Como o canal é um bus **eventual** (git, ~1 ciclo de autosync), todo comando cross-máquina DEVE ser
**idempotente** e a máquina-origem DEVE exibir **"PENDENTE"** até receber um **ACK** do alvo gravado
no ledger; NUNCA "FEITO" sem ACK. Um comando reentregue NÃO DEVE produzir efeito duplicado.

#### Cenário: comando emitido aguardando ACK

- **QUANDO** a origem emitiu um comando e ainda não há ACK do alvo no ledger
- **ENTÃO** a origem exibe "PENDENTE" (nunca "FEITO")

#### Cenário: ACK recebido

- **QUANDO** o alvo executa e grava o ACK no ledger
- **ENTÃO** a origem passa a exibir "FEITO há Xs"

#### Cenário: reentrega do mesmo comando

- **QUANDO** o mesmo comando é reentregue pelo bus eventual
- **ENTÃO** o alvo o reconhece como já-aplicado e o efeito permanece único (idempotência)


### Requisito: Não-repúdio por ledger encadeado por hash

Toda ação do write-path DEVE ser registrada num ledger **append-only encadeado por hash**
(`subject|role|action|ref|scope|result|signature|prev_hash`), commitado. A reescrita do ledger DEVE
ser **detectável** pela quebra da cadeia. O contrato DEVE declarar explicitamente que **detecção ≠
prevenção** — uma ação já executada não é desfeita pela detecção — tratando isso como risco residual
**aceito e declarado**, não mascarado.

#### Cenário: ação registrada

- **QUANDO** o alvo executa uma ação do write-path
- **ENTÃO** grava uma entrada encadeada com a assinatura do emissor e o `prev_hash` da entrada anterior

#### Cenário: tentativa de apagar histórico

- **QUANDO** alguém reescreve ou remove uma entrada do ledger
- **ENTÃO** a cadeia de hash quebra e o verificador acusa a adulteração (sem, contudo, desfazer a ação já executada — risco residual declarado)


### Requisito: Habilitação incremental gated nas questões críticas Q1–Q3

O write-path em sua forma **cross-máquina** NÃO DEVE ser habilitado enquanto as questões críticas
**Q1** (bootstrap/distribuição de confiança das chaves de máquina, sem CA), **Q2** (revogação de
chave de máquina comprometida) e **Q3** (onde a passkey/Touch ID assina sem relying-party server)
não estiverem **resolvidas em ADR/threat-model formal posterior** — com mecanismo escolhido e
capacidade de assinatura por-máquina **bootstrapada e verificada por exit-code** — **ANTES** da
habilitação. **O merge deste contrato NÃO constitui resolução de Q1–Q3:** ratificar o contrato cria
as exigências, não as satisfaz; logo "contrato de segurança aprovado" (gate vivo) significa contrato
**+ Q1–Q3 cravadas em ADR**, jamais o mero merge do `/spec`. A decisão de exposição do ref de
comando ao `origin` (Q5) integra o mesmo gate. A habilitação DEVE ser **incremental**: primeiro `rotate`
de credencial `sensível` na **própria máquina** (sem cross-máquina); maturado por um ciclo (espírito
SOAK); cross-máquina só **depois** de Q1–Q3 cravadas; `deploy` e `revoke critical` por último,
**sempre** com confirmação out-of-band.

#### Cenário: cross-máquina com questões abertas

- **QUANDO** um comando cross-máquina é solicitado e Q1, Q2 ou Q3 ainda está aberta
- **ENTÃO** o Cockpit recusa e referencia o gate de Q1–Q3 como pré-condição

#### Cenário: contrato merjado mas Q1–Q3 sem ADR

- **QUANDO** o delta v14.4 é merjado (o gate vivo passa a ler "contrato aprovado") mas Q1, Q2 ou Q3 segue sem ADR de resolução
- **ENTÃO** o comando cross-máquina permanece recusado — o merge do contrato não é a resolução das questões críticas

#### Cenário: rotação same-machine sob janela-com-teardown

- **QUANDO** um `rotate` de credencial `sensível` é solicitado na própria máquina (sem cross-máquina), com o contrato aprovado e a janela-com-teardown desenhada
- **ENTÃO** o Cockpit permite a ação na **superfície gated do write-path** (step-up + janela-com-teardown), distinta da superfície de comando local-reversível da v14.1 — que continua recusando rotação —, sem depender de Q1–Q3 (que gatam só o cross-máquina)

#### Cenário: deploy ou revoke critical sem out-of-band

- **QUANDO** um `deploy` de produção ou `revoke` de credencial `crítica` é solicitado sem a confirmação out-of-band
- **ENTÃO** o Cockpit recusa (esses verbos exigem o segundo fator fora do git)


### Requisito: Rate-limit determinístico contra flood de comandos de mutação

O `agentd`-alvo DEVE aplicar um rate-limit/throttle determinístico por `ref`+`subject` às ações de
mutação (`rotate`/`deploy`), recusando ou aplicando backpressure acima de um threshold por janela.
Esta é uma defesa **secundária**: protege contra acidente e rajada, mas NÃO substitui a autenticação
fail-closed (R-WP1) nem o gating (R-WP10) — um atacante autenticado não é contido só por rate-limit.

#### Cenário: rajada acima do threshold

- **QUANDO** comandos de `rotate`/`deploy` chegam acima do threshold por `ref`+`subject` na janela
- **ENTÃO** o `agentd`-alvo recusa ou enfileira com backpressure (nunca dispara os N em paralelo sobre produção)

#### Cenário: rate-limit não substitui autenticação

- **QUANDO** um comando único de mutação chega autenticado e dentro do rate-limit
- **ENTÃO** o rate-limit não o autoriza por si — a autorização continua sendo R-WP1 (assinatura) + R-WP2 (papel) + R-WP10 (gate)
