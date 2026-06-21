# Spec: tool-output-compressor

## Propósito

Spec criada via delta-spec em 2026-06-21.

## Requisitos


### Requisito: Roteamento por tipo de conteúdo

O sistema DEVE detectar o tipo de uma saída de ferramenta (log, JSON tabular, resultados de
busca, diff, texto) e aplicar o compressor determinístico correspondente. Quando o tipo não
for reconhecido ou o conteúdo for incompressível, o sistema DEVE devolver o original intacto
(passthrough), nunca uma versão corrompida.

#### Cenário: log repetitivo é template-izado

- **QUANDO** uma saída de ferramenta contém muitas linhas de log com estrutura repetida
- **ENTÃO** o sistema substitui as linhas por um template + contagem/variações e a contagem de tokens cai materialmente

#### Cenário: JSON tabular vira schema + linhas

- **QUANDO** a saída é um array de objetos de schema uniforme
- **ENTÃO** o sistema o representa como um cabeçalho de schema único seguido de linhas compactas, preservando todos os valores

#### Cenário: conteúdo não reconhecido passa intacto

- **QUANDO** a saída não casa com nenhum compressor conhecido
- **ENTÃO** o sistema devolve os bytes originais sem alteração e reporta redução de 0%

---


### Requisito: Proteção da intenção do usuário

O sistema NUNCA DEVE comprimir o conteúdo de uma mensagem do usuário. A compressão DEVE
atuar somente sobre saída de ferramenta ou conteúdo explicitamente marcado como compressível
pelo chamador.

#### Cenário: mensagem de usuário é preservada

- **QUANDO** o conteúdo submetido tem papel de mensagem do usuário
- **ENTÃO** o sistema o devolve byte-a-byte idêntico e registra que foi protegido

#### Cenário: só o segmento marcado é comprimido

- **QUANDO** uma carga mista contém mensagem de usuário e saída de ferramenta
- **ENTÃO** o sistema comprime apenas a saída de ferramenta e deixa a mensagem de usuário intacta

---


### Requisito: Reversibilidade por CCR

O sistema DEVE oferecer um modo reversível (Compress-Cache-Retrieve) no qual qualquer conteúdo
derrubado é substituído por uma sentinela contendo um hash estável, e o conteúdo original fica
recuperável sob demanda a partir desse hash enquanto o item for válido.

#### Cenário: original recuperável pela sentinela

- **QUANDO** o agente pede o original referenciado por uma sentinela de um item ainda válido
- **ENTÃO** o sistema devolve o conteúdo original exato correspondente àquele hash

#### Cenário: recuperação indisponível é um erro explícito, não um silêncio

- **QUANDO** o agente pede um original cujo item já não está disponível
- **ENTÃO** o sistema retorna um resultado de erro explícito (não um conteúdo vazio nem um substituto silencioso)

---


### Requisito: Verificação por exit-code e integridade do round-trip

O sistema DEVE sinalizar sucesso ou falha de cada operação por exit-code binário, sem jamais
corromper conteúdo em silêncio. No modo reversível, o sistema DEVE garantir que a recuperação
reconstrói o original de forma verificável (igualdade por hash entre original e recuperado).

#### Cenário: round-trip lossless é verificável por hash

- **QUANDO** um conteúdo é comprimido em modo reversível e em seguida recuperado
- **ENTÃO** o sha256 do recuperado é igual ao do original e o exit-code é 0

#### Cenário: falha de compressão não emite artefato parcial

- **QUANDO** a compressão falha por qualquer motivo
- **ENTÃO** o sistema retorna exit-code não-zero e não grava uma saída comprimida parcial

---


### Requisito: Economia medida honestamente

O sistema DEVE reportar a economia de tokens a partir de contagem real por tokenizer (antes e
depois), nunca um número inventado. Quando o valor for uma estimativa (e não uma medição
direta), o sistema DEVE rotulá-lo explicitamente como estimativa.

#### Cenário: redução reportada bate com a medição

- **QUANDO** o sistema comprime um artefato e reporta a economia
- **ENTÃO** o percentual reportado deriva de tokens-antes e tokens-depois contados pelo tokenizer, não de um valor fixo

#### Cenário: estimativa é rotulada

- **QUANDO** o sistema não tem como medir diretamente e precisa estimar
- **ENTÃO** o número é apresentado marcado como estimativa, não como medição

---


### Requisito: Operação local, CLI-First, sem rede

O sistema DEVE operar inteiramente local, como skill/CLI, sem proxy, sem definir
`ANTHROPIC_BASE_URL`, sem qualquer egress de rede e sem telemetria. Se o compressor não
estiver disponível em runtime, o sistema DEVE deixar o conteúdo original passar (fail-open),
sem bloquear a operação do agente.

#### Cenário: nenhuma chamada de rede é feita

- **QUANDO** qualquer compressão ou recuperação é executada
- **ENTÃO** nenhuma conexão de rede externa é aberta e nenhum `*_BASE_URL` de provedor é alterado

#### Cenário: indisponibilidade não bloqueia o agente

- **QUANDO** o componente de compressão não está instalado ou falha ao carregar
- **ENTÃO** o conteúdo original é repassado e o agente continua sem erro fatal

---


### Requisito: Determinismo e idempotência

O sistema DEVE ser determinístico: a mesma entrada produz a mesma saída comprimida. Recomprimir
um conteúdo já comprimido por esta capability DEVE ser um no-op (idempotente).

#### Cenário: mesma entrada, mesma saída

- **QUANDO** o mesmo artefato é comprimido duas vezes com a mesma configuração
- **ENTÃO** as duas saídas são byte-a-byte idênticas

#### Cenário: recompressão é no-op

- **QUANDO** uma saída já comprimida por esta capability é submetida de novo
- **ENTÃO** o sistema a reconhece como já comprimida e a devolve sem nova redução
