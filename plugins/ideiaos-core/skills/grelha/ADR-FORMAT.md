# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9

# Formato do ADR inline do `/grelha`

Um ADR (Architecture Decision Record) registra **que** uma decisão foi tomada e **por
quê** — não para preencher seções, mas para capturar o "porquê irreversível" no momento
em que ele se cristaliza, com atrito mínimo. Este é o formato que o `/grelha` usa quando,
durante o grilling no modo `--docs`, uma decisão difícil de reverter aparece e o **gate
dos 3 critérios** (abaixo) passa.

## Onde moram (reuso, não reinvenção)

ADRs vivem em **`docs/decisions/`** — o IdeiaOS já usa esse diretório. **Não crie um
diretório `adr/` paralelo**: isso fragmentaria o histórico de decisões em dois lugares.
Reuse `docs/decisions/`.

### Duas convenções de nome coexistem

| Convenção | Quem usa | Exemplo |
|-----------|----------|---------|
| `NNNN-slug.md` (numeração sequencial) | ADRs **táticos** gerados pelo grilling | `0001-estado-no-servidor.md` |
| `vN-slug.md` | ADRs de **milestone** (já em uso no repo) | `v5-memory-topology.md` |

Os dois padrões convivem no mesmo `docs/decisions/`. Para o ADR tático do grilling: varra
o maior número `NNNN` já existente e **incremente em um** (se nenhum existe ainda, comece
em `0001`). Não renumere os `vN-slug.md` — eles permanecem como estão.

## Criação preguiçosa

Só crie o arquivo quando o **1º ADR** for realmente necessário. Não crie arquivo vazio em
antecipação — arquivo vazio é ruído.

## Formato mínimo

```md
# {Título curto da decisão}

{1 a 3 frases: qual o contexto, o que decidimos e por quê.}
```

É só isso. **Um ADR pode ser um único parágrafo.** O valor está em registrar *que* a
decisão existiu e *por quê* — não em preencher campos.

## Seções opcionais (só quando agregam)

A maioria dos ADRs não precisa delas. Inclua apenas quando há valor genuíno:

- **Status** — `proposto | aceito | descontinuado | substituído por ADR-NNNN`. Útil quando
  a decisão for revisitada.
- **Opções consideradas** — só quando as alternativas rejeitadas valem ser lembradas.
- **Consequências** — só quando há efeitos não-óbvios rio abaixo a sinalizar.

## GATE dos 3 critérios — os TRÊS precisam ser verdadeiros

O `/grelha` só **oferece** (nunca impõe) um ADR quando **todos** os três valem:

1. **Difícil de reverter** — o custo de mudar de ideia depois é real e relevante.
2. **Surpreendente sem contexto** — um leitor futuro olharia o código e perguntaria "por
   que diabos fizeram assim?".
3. **Resultado de um trade-off real** — havia alternativas genuínas e uma foi escolhida por
   razões específicas.

Se **qualquer um** falha → **NÃO oferecer ADR** (pular silenciosamente):

- decisão **fácil de reverter** → você só reverte quando precisar; não há o que registrar;
- decisão **não-surpreendente** → ninguém vai questionar o óbvio;
- **sem alternativa real** → não há trade-off a documentar, só "fizemos o óbvio".

## O que qualifica (exemplos)

- **Forma arquitetural.** "Usamos monorepo." "Write model event-sourced, read model
  projetado no Postgres."
- **Padrão de integração entre contextos.** "Pedidos e Faturamento se falam por eventos de
  domínio, não HTTP síncrono."
- **Escolha de tecnologia com lock-in.** Banco, message bus, provedor de auth, alvo de
  deploy. Não toda biblioteca — só as que levariam um trimestre para trocar.
- **Decisão de fronteira/escopo.** "Dados do Cliente pertencem ao contexto Cliente; outros
  só referenciam por ID." Os "nãos" explícitos valem tanto quanto os "sins".
- **Desvio deliberado do caminho óbvio.** "Usamos SQL manual em vez de ORM porque X." Tudo
  em que um leitor razoável presumiria o contrário — evita que o próximo engenheiro
  "conserte" o que foi intencional.
- **Restrição não-visível no código.** "Não podemos usar AWS por exigência de compliance."
  "Tempo de resposta < 200ms por contrato com a API parceira."
- **Alternativa rejeitada por razão não-óbvia.** Considerou GraphQL e escolheu REST por
  motivos sutis? Registre — senão alguém vai sugerir GraphQL de novo em seis meses.

## Integração com o Obsidian (sem pipeline novo)

ADRs gravados em `docs/decisions/` já entram no **espelhamento ADR→Obsidian existente** do
`/extract-learnings` (**Passo 4c** — espelha `docs/decisions/` → vault `Decisions/`). O
`/grelha` **não cria pipeline próprio**: ele apenas escreve o arquivo em `docs/decisions/`,
e o fluxo de fechamento de sessão (extract-learnings) cuida do espelhamento condensado para
o vault. A fonte canônica continua sendo o ADR no repo; o vault é a vista cross-projeto.
