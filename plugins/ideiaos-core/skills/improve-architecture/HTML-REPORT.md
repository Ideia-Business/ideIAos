# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9

# Formato do Relatório HTML

**Idioma:** Português brasileiro.

A revisão de arquitetura é renderizada como **um único arquivo HTML self-contained no diretório
temporário do SO** — nada aterrissa no repo. Tailwind e Mermaid vêm de CDNs. O Mermaid cuida de
diagramas em formato de grafo de forma confiável; `<div>`s construídos à mão e SVG inline cuidam dos
visuais mais editoriais (diagramas de massa, cortes transversais). **Misture os dois** — não dependa
do Mermaid para tudo, ou começa a parecer genérico.

## Onde gravar (não sujar o repo)

Resolva o tmp do SO a partir de `$TMPDIR`, caindo para `/tmp` (ou `%TEMP%` no Windows). Grave em
`<tmpdir>/architecture-review-<timestamp>.html` para cada execução ganhar um arquivo fresco. Abra-o
para o usuário — `open <path>` no macOS, `xdg-open <path>` no Linux, `start <path>` no Windows — e
informe o **caminho absoluto**. Verifique a gravação com `test -s <path>` (gate binário; ver R8-04 na
SKILL.md).

## Scaffold

```html
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="utf-8" />
    <title>Revisão de arquitetura — {{nome do repo}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* camada custom pequena para o que o Tailwind não cobre limpo:
         linhas de seam tracejadas, setas com cara desenhada à mão, etc. */
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

> Os **únicos** scripts são o CDN do Tailwind e o import ESM do Mermaid. O relatório é estático no
> resto — sem código de app, sem interatividade além da renderização do próprio Mermaid.

## Header

Nome do repo, data e uma **legenda compacta**: caixa sólida = módulo, linha tracejada = seam, seta
vermelha = vazamento (leak), caixa escura grossa = módulo profundo (deep). Sem parágrafo de
introdução — direto aos candidatos.

## Card de candidato

**Os diagramas carregam o peso.** A prosa é escassa, simples, e usa os termos do glossário
([LANGUAGE.md](LANGUAGE.md)) sem cerimônia.

Cada candidato é um `<article>`:

- **Título** — curto, nomeia o deepening (ex.: "Colapsar o pipeline de recebimento de Pedido").
- **Linha de badges** — força da recomendação (`Forte` = emerald, `Vale explorar` = amber,
  `Especulativo` = slate), mais uma tag da categoria de dependência (`in-process`,
  `local-substitutável`, `ports & adapters`, `mock`).
- **Files** — lista monoespaçada, `font-mono text-sm` — quais arquivos/módulos estão envolvidos.
- **Diagrama Antes / Depois** — a peça central. Duas colunas, lado a lado. Ver padrões abaixo.
- **Problema** — uma frase. O que dói. (Por que a arquitetura atual gera fricção.)
- **Solução** — uma frase. O que muda, em português claro.
- **Ganhos** — bullets, ≤6 palavras cada, em termos de **locality** e **leverage** e em como os testes
  melhoram. Ex.: "Testes batem numa interface", "Lógica de preço para de vazar", "Deleta 4 wrappers rasos".
- **Callout de ADR** (quando aplicável) — uma linha numa caixa com tom amber.

Sem parágrafos de explicação. **Se o diagrama precisa de um parágrafo para ser entendido, redesenhe o
diagrama.**

## Padrões de diagrama

Escolha o padrão que serve ao candidato. **Misture-os.** Não faça todo diagrama parecer igual —
variedade é parte do ponto.

### Grafo Mermaid (o cavalo de batalha para dependências / fluxo de chamada)

Use um `flowchart` ou `graph` do Mermaid quando o ponto é "X chama Y chama Z, e olha a bagunça".
Embrulhe num card estilizado com Tailwind para não parecer paraquedado. Estilize com `classDef` para
colorir arestas de vazamento em vermelho e o módulo profundo em escuro. Diagramas de sequência
funcionam bem para "antes: 6 round-trips; depois: 1".

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[RecebedorPedido] --> B[ValidadorPedido]
      B --> C[RepoPedido]
      C -.leak.-> D[ClientePreco]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### Caixas-e-setas à mão (quando o layout do Mermaid briga com você)

Módulos como `<div>`s com bordas e rótulos. Setas como `<line>`/`<path>` SVG inline posicionados
absolutamente sobre um container relativo. Use quando quer que o diagrama "depois" pareça **um módulo
profundo de borda grossa com internos acinzentados** — o Mermaid não renderiza isso com o peso certo.

### Corte transversal (bom para rasura em camadas)

Empilhe faixas horizontais (`h-12 border-l-4`) mostrando as camadas que uma chamada atravessa. Antes:
6 camadas finas cada uma fazendo nada. Depois: 1 faixa grossa rotulada com a responsabilidade
consolidada.

### Diagrama de massa (bom para "interface tão larga quanto a implementação")

Dois retângulos por módulo — um para a área de superfície da **interface**, outro para a
**implementação**. Antes: o retângulo da interface é quase tão alto quanto o da implementação (raso).
Depois: interface baixa, implementação alta (profundo).

### Colapso de grafo de chamadas

Antes: uma árvore de chamadas de função renderizada como caixas aninhadas. Depois: a mesma árvore
colapsada numa caixa, com as chamadas agora-internas mostradas esmaecidas dentro dela.

## Diretrizes de estilo

- **Editorial, não dashboard corporativo.** Bastante whitespace. Serif opcional para títulos
  (`font-serif` casa bem com stone/slate).
- **Cor com parcimônia:** um accent (emerald ou indigo) mais vermelho para vazamento e amber para
  avisos.
- Mantenha diagramas com ~320px de altura para que antes/depois caibam confortáveis lado a lado sem rolar.
- Use `text-xs uppercase tracking-wider` para rótulos de módulo dentro dos diagramas — devem ler como
  esquemáticos, não como UI.

## Seção "Top recommendation"

Um card maior. Nome do candidato, uma frase do porquê, link-âncora para o card dele. Só isso.

## Tom

Português claro, conciso — mas os substantivos e verbos de arquitetura vêm **direto** de
[LANGUAGE.md](LANGUAGE.md). Concisão não é desculpa para derivar.

**Use exatamente:** module, interface, implementation, depth, deep, shallow, seam, adapter, leverage,
locality.

**Nunca substitua:** componente, serviço, unidade (por module) · API, assinatura (por interface) ·
fronteira/boundary (por seam) · camada, wrapper (por module, quando você quer dizer module).

**Frases que casam com o estilo:**

- "Módulo de recebimento de Pedido é raso — interface quase casa com a implementação."
- "Preço vaza através do seam."
- "Aprofundar: uma interface, um lugar para testar."
- "Dois adapters justificam o seam: HTTP em prod, em memória nos testes."

**Bullets de ganho** nomeiam o ganho em termos do glossário: *"locality: bugs concentram num módulo"*,
*"leverage: uma interface, N call sites"*, *"interface encolhe; implementação absorve os wrappers"*.
Não escreva *"mais fácil de manter"* nem *"código mais limpo"* — não estão no glossário e não merecem
o lugar.

Sem hedging, sem pigarro, sem "vale notar que…". Se uma frase poderia ser um bullet, faça bullet. Se
um bullet poderia ser cortado, corte. Se um termo não está em [LANGUAGE.md](LANGUAGE.md), alcance um
que esteja antes de inventar novo.

## Conflitos com ADR no relatório

Se um candidato contradiz um ADR existente (`docs/decisions/`), **só** traga à tona quando a fricção
for real o bastante para justificar reabrir o ADR. Marque claro no card (callout amber: _"contradiz o
ADR `<slug>` — mas vale reabrir porque…"_). **Não** liste todo refactor teórico que um ADR proíbe.
