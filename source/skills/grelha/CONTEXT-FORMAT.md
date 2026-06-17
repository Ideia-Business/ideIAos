# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9

# Formato do CONTEXT.md — Glossário de Linguagem Ubíqua

**Idioma:** Português brasileiro.

O `CONTEXT.md` é o **glossário** de linguagem ubíqua do projeto: os termos do domínio com a
definição canônica de cada um. É mantido **inline** pela skill `/grelha --docs` à medida que os
termos vão sendo resolvidos no grilling. Este documento define o formato exato e as regras de ouro.

---

## Estrutura

```md
# {Nome do Contexto}

{Uma ou duas frases descrevendo o que é este contexto e por que ele existe.}

## Linguagem

**Pedido**:
Uma intenção de compra registrada por um Cliente; agrega itens e um endereço de entrega.
_Evite_: Compra, transação

**Fatura**:
Um pedido de pagamento enviado ao Cliente após a entrega.
_Evite_: Conta, boleto, cobrança

**Cliente**:
Pessoa ou organização que faz pedidos.
_Evite_: Comprador, usuário, conta
```

Cada entrada é: `**Termo**:` + uma definição de **1-2 frases** + `_Evite_: <sinônimos a evitar>`.

---

## Regras de ouro (duras)

- **(a) Seja opinativo.** Quando há várias palavras para o mesmo conceito, escolha **a melhor**
  e liste as outras sob `_Evite_`. Um glossário que aceita tudo não alinha ninguém.
- **(b) Definição tight.** No máximo 1-2 frases. Defina o que a coisa **É**, não o que ela **faz**.
- **(c) Só termos do domínio.** Conceitos gerais de programação (timeout, tipos de erro, padrões
  utilitários) **NÃO entram**, mesmo que o projeto os use o tempo todo. Antes de adicionar,
  pergunte: isto é único deste contexto, ou é programação genérica? Só o primeiro pertence.
- **(d) Zero implementação.** O `CONTEXT.md` **NÃO é spec**, **NÃO é scratch pad**, **NÃO é
  repositório de decisões**. É glossário e nada mais. Decisão irreversível vai para um **ADR**
  (`docs/decisions/`, detalhe na Fase C). Comportamento contratado vai para `/spec`
  (`specs/<cap>/spec.md`).
- **(e) Agrupe sob subtítulos** quando clusters naturais emergirem. Se todos os termos pertencem
  a uma única área coesa, uma lista plana basta.

---

## Single vs multi-context

**Contexto único (maioria dos repos):** um único `CONTEXT.md` na raiz do projeto.

**Múltiplos contextos (monorepo):** um `CONTEXT-MAP.md` na raiz lista os contextos, onde cada um
vive e como se relacionam:

```md
# Mapa de Contextos

## Contextos

- [Pedidos](./src/pedidos/CONTEXT.md) — recebe e acompanha os pedidos do Cliente
- [Faturamento](./src/faturamento/CONTEXT.md) — gera faturas e processa pagamentos
- [Expedição](./src/expedicao/CONTEXT.md) — separação e envio no armazém

## Relações

- **Pedidos → Expedição**: Pedidos emite `PedidoColocado`; Expedição consome para iniciar a separação
- **Expedição → Faturamento**: Expedição emite `EnvioDespachado`; Faturamento consome para gerar faturas
- **Pedidos ↔ Faturamento**: tipos compartilhados para `IdCliente` e `Dinheiro`
```

A skill infere qual estrutura aplica:

- Se existe `CONTEXT-MAP.md` → leia-o para achar os contextos
- Se existe só um `CONTEXT.md` na raiz → contexto único
- Se nenhum existe → crie um `CONTEXT.md` na raiz **preguiçosamente**, ao resolver o 1º termo

Quando há vários contextos, infira a qual o tópico atual pertence. Se não estiver claro, **pergunte**.

---

## Criação preguiçosa

O `CONTEXT.md` **nasce só quando o 1º termo é resolvido** no grilling — nunca em antecipação. Use
`source/skills/grelha/templates/CONTEXT.md.tmpl` como esqueleto ao criar o primeiro arquivo no
projeto-alvo. Arquivo de glossário vazio é ruído, não preparação.
