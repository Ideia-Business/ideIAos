# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9

# Glossário de Arquitetura — Linguagem do `/improve-architecture`

**Idioma:** Português brasileiro.

Vocabulário compartilhado de TODA sugestão que esta skill faz. Use estes termos **exatamente** —
não substitua por "componente", "serviço", "API" ou "fronteira". **Linguagem consistente é o ponto
inteiro:** o glossário do domínio (`CONTEXT.md`) dá nomes aos bons *seams*; este glossário dá nomes à
*estrutura*. Dois eixos, um relatório.

---

## Termos

**Module (Módulo)**
Qualquer coisa com uma **interface** e uma **implementação**. Deliberadamente agnóstico à escala —
vale igual para uma função, classe, pacote ou fatia que cruza camadas.
_Evite_: unidade, componente, serviço.

**Interface**
Tudo que um chamador precisa saber para usar o módulo **corretamente**. Inclui a assinatura de tipos,
mas também invariantes, restrições de ordenação, modos de erro, configuração obrigatória e
características de performance.
_Evite_: API, assinatura (estreito demais — referem-se só à superfície de tipos).

**Implementation (Implementação)**
O que está **dentro** do módulo — o corpo de código. Distinta de **Adapter**: uma coisa pode ser um
adapter pequeno com implementação grande (um repositório Postgres) ou um adapter grande com
implementação pequena (um fake em memória). Use "adapter" quando o *seam* é o tópico; "implementação"
caso contrário.

**Depth (Profundidade)**
**Leverage na interface** — quanto comportamento um chamador (ou teste) consegue exercitar por unidade
de interface que precisa aprender. Um módulo é **deep (profundo)** quando há muito comportamento atrás
de uma interface pequena. É **shallow (raso)** quando a interface é quase tão complexa quanto a
implementação.

**Seam**
_(de Michael Feathers)_ Um lugar onde você pode **alterar comportamento sem editar naquele lugar**. A
*localização* onde a interface de um módulo vive. Escolher onde colocar o seam é uma decisão de design
por si só, distinta do que vai atrás dele.
_Evite_: fronteira/boundary (sobrecarregado com o *bounded context* do DDD).

**Adapter**
Uma coisa concreta que **satisfaz uma interface num seam**. Descreve *papel* (que vaga preenche), não
substância (o que tem dentro).

**Leverage (Alavancagem)**
O que os **chamadores** ganham com profundidade. Mais capacidade por unidade de interface a aprender.
Uma implementação se paga ao longo de N call sites e M testes.

**Locality (Localidade)**
O que os **mantenedores** ganham com profundidade. Mudança, bugs, conhecimento e verificação
**concentram-se num lugar** em vez de espalhar pelos chamadores. Conserta uma vez, consertado em todos.

---

## Princípios

- **Profundidade é propriedade da interface, não da implementação.** Um módulo profundo pode ser
  internamente composto de partes pequenas, mockáveis, trocáveis — elas só não fazem parte da
  interface. Um módulo pode ter **seams internos** (privados à sua implementação, usados pelos próprios
  testes) além do **seam externo** na sua interface.
- **O deletion test (teste de deleção).** Imagine deletar o módulo. Se a complexidade **desaparece**,
  o módulo não escondia nada (era um pass-through). Se a complexidade **reaparece espalhada por N
  chamadores**, o módulo estava ganhando o pão dele. Um "sim, concentra" é o sinal que você quer.
- **A interface é a superfície de teste.** Chamadores e testes cruzam o mesmo seam. Se você precisa
  testar *além* da interface, o módulo provavelmente está na forma errada.
- **1 adapter = seam hipotético. 2 adapters = seam real.** Não introduza um seam a menos que algo
  realmente varie através dele.

---

## Relações

- Um **Module** tem exatamente uma **Interface** (a superfície que apresenta a chamadores e testes).
- **Depth** é uma propriedade de um **Module**, medida contra sua **Interface**.
- Um **Seam** é onde a **Interface** de um **Module** vive.
- Um **Adapter** fica num **Seam** e satisfaz a **Interface**.
- **Depth** produz **Leverage** para chamadores e **Locality** para mantenedores.

---

## Enquadramentos rejeitados

- **Profundidade como razão linhas-de-implementação ÷ linhas-de-interface** (Ousterhout): premia
  inflar a implementação. Usamos profundidade-como-leverage no lugar.
- **"Interface" como a palavra-chave `interface` do TypeScript ou os métodos públicos de uma classe**:
  estreito demais — aqui interface inclui todo fato que um chamador precisa saber.
- **"Fronteira/boundary"**: sobrecarregado com o *bounded context* do DDD. Diga **seam** ou
  **interface**.
