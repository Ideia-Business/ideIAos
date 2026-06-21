# Spec: cockpit

## Propósito

Spec criada via delta-spec em 2026-06-20.

## Requisitos


### Requisito: Isolamento absoluto de credenciais (Zero-Leak)

O Cockpit DEVE tratar o browser e o contexto do LLM como ambientes não-confiáveis e NUNCA
permitir que o valor de um segredo (API key, token, senha, `service_role`) transite por
qualquer superfície — estado de UI, DOM, rede, log, snapshot ou ledger. A representação de uma
credencial DEVE conter apenas referência (nome, presença, idade, escopo, classe de risco),
nunca o valor.

#### Cenário: render de uma credencial conhecida

- **QUANDO** o Cockpit exibe uma credencial existente (ex.: `SUPABASE_SERVICE_ROLE_KEY`)
- **ENTÃO** mostra nome, presença, idade e classe de risco, e NUNCA o valor — nem parcial, nem mascarado a partir do valor real

#### Cenário: invariante de release

- **QUANDO** o build de release é avaliado pelo gate Zero-Leak
- **ENTÃO** qualquer ocorrência de um valor de segredo em qualquer artefato do Cockpit reprova o build (incidente P0, bloqueia merge)


### Requisito: Coleta read-only sem mutar o working tree

O agente coletor (`ideiaos-agentd`) DEVE derivar todo o estado por leitura do substrato
existente (ledgers, `git log`, `launchctl`, nomes de variáveis) e NÃO DEVE escrever nenhum
arquivo no working tree dos repositórios durante a coleta.

#### Cenário: ciclo de coleta

- **QUANDO** o coletor executa um ciclo de telemetria
- **ENTÃO** grava o snapshot diretamente no ref de federação via git-plumbing e o working tree dos repositórios permanece inalterado (`git status` limpo)


### Requisito: Federação por ref dedicado fora do alcance do autosync

Os snapshots de telemetria DEVEM ser propagados entre máquinas por um ref git dedicado
(`cockpit`), de modo que o `git add -A` cego do git-autosync não consiga capturá-los, e a
proteção pull-only do branch `main` permaneça intacta.

#### Cenário: propagação cross-máquina

- **QUANDO** uma máquina produz um novo snapshot
- **ENTÃO** o autosync apenas faz push do ref `cockpit` (nunca de `main`), e nenhum arquivo de snapshot aparece no working tree de qualquer branch


### Requisito: Frescor honesto (vivo local, eventual cross-máquina)

O Cockpit DEVE distinguir visivelmente sinal local-vivo (file-watch de baixa latência) de
sinal cross-máquina-eventual (propagado por ciclo de autosync), e NÃO DEVE animar fluxo
contínuo sobre dado que chega em lote.

#### Cenário: máquina remota atrasada

- **QUANDO** o último snapshot de uma máquina remota tem idade maior que um ciclo de propagação
- **ENTÃO** o Cockpit exibe a idade real do último sinal ("há X min") em vez de simular atividade contínua


### Requisito: Comando local reversível com allowlist fixo

O Cockpit DEVE executar apenas verbos de um allowlist fixo de ações locais e reversíveis
(ex.: pausar/retomar autosync, rodar idea-doctor, re-selar frescor de segurança). Qualquer
verbo fora do allowlist DEVE ser recusado.

#### Cenário: ação fora do allowlist

- **QUANDO** uma ação de mutação de produção (deploy, rotação de chave) ou de comando cross-máquina é solicitada na superfície de comando local
- **ENTÃO** o Cockpit recusa a execução e indica que a capacidade exige o gate de v14.4

#### Cenário: ação reversível confirmada

- **QUANDO** o operador dispara um verbo destrutivo-mas-reversível (ex.: pausar autosync)
- **ENTÃO** o Cockpit exige uma confirmação explícita ("armar antes de disparar") antes de executar


### Requisito: Respeito à autoridade exclusiva de @devops

O Cockpit NÃO DEVE executar operações exclusivas de @devops (`git push`, `gh pr`,
adicionar/remover/configurar MCP). Quando tais operações forem pertinentes, o Cockpit DEVE no
máximo gerar o comando para o @devops executar.

#### Cenário: operação exclusiva solicitada

- **QUANDO** o operador pede push ou alteração de MCP a partir do Cockpit
- **ENTÃO** o Cockpit não executa a operação e apresenta o comando correspondente para execução por @devops


### Requisito: Saúde por produto com sub-sinal honesto

O Cockpit DEVE computar um indicador de saúde por produto e DEVE rotular explicitamente
qualquer sub-sinal indisponível (ex.: idea-doctor não roda em produtos Lovable) como `n/a`,
sem inventar nota.

#### Cenário: produto sem idea-doctor

- **QUANDO** um produto não suporta a verificação idea-doctor
- **ENTÃO** o card de saúde mostra o sub-sinal correspondente como `n/a` e o score agregado não conta esse sub-sinal como falha nem como sucesso fabricado


### Requisito: Verdade verificável contra o disco (Time-to-Truth)

Quando o Cockpit afirma um estado do ecossistema, DEVE ser possível verificar essa afirmação
contra a fonte no disco no instante da pergunta, e o Cockpit DEVE expor há quanto tempo o dado
foi verificado.

#### Cenário: verificação on-demand

- **QUANDO** o operador solicita verificação de uma afirmação exibida
- **ENTÃO** o Cockpit recomputa do disco no momento e exibe o resultado com o carimbo "verificado há Xs"


### Requisito: Comando cross-máquina e mutação de produção gated

O Cockpit NÃO DEVE habilitar comando cross-máquina nem mutação de produção (rotação/revogação
de chave, deploy) antes de um contrato `/spec` de segurança com threat-model (STRIDE +
OWASP-LLM) aprovado. Até lá, essas capacidades permanecem fora do allowlist.

#### Cenário: tentativa antes do gate

- **QUANDO** uma ação cross-máquina é solicitada sem o contrato de segurança aprovado
- **ENTÃO** o Cockpit a recusa e referencia o gate de v14.4 como pré-condição
