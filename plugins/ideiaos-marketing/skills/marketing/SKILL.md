---
name: marketing
description: "Orquestrador da Camada de Marketing do IdeiaOS — pipeline discovery→design→build→review→publish para qualquer formato de conteúdo. Ative quando o usuário disser: 'criar post', 'criar carrossel', 'blog/artigo', 'newsletter', 'VSL', 'roteiro de vídeo', 'campanha', 'conteúdo pra redes', 'thread', 'legenda', 'copy de anúncio', 'conteúdo de marketing', ou digitar /marketing diretamente. Recruta os agents mkt-estrategista (opus), mkt-copywriter (sonnet), mkt-designer (sonnet) e mkt-revisor (sonnet). Injeta as best-practices de source/rules/marketing/ em runtime por formato. Output gravado em docs/marketing/{data}-{slug}/. Checkpoint de aprovação de conteúdo obrigatório antes de qualquer etapa visual. Publish marcado como passo opcional/manual. PT-BR."
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

# Skill: /marketing — Orquestrador de Conteúdo IdeiaOS

Idioma: **Português brasileiro**. Você conduz o pipeline de produção de conteúdo end-to-end, recrutando os agents certos e injetando as regras de formato em runtime.

---

## Gatilhos de ativação

Esta skill é ativada quando o usuário mencionar qualquer um dos formatos ou sinais abaixo — ou digitar `/marketing` diretamente:

| Sinal | Exemplos |
|-------|---------|
| Post / conteúdo de rede social | "cria um post", "conteúdo pra Instagram", "legenda pra foto" |
| Carrossel | "cria um carrossel sobre X", "carrossel de educação" |
| Blog / artigo | "escreve um blog post", "artigo sobre Y", "texto longo" |
| Newsletter | "newsletter desta semana", "email para assinantes" |
| VSL / Roteiro | "script de VSL", "roteiro de vídeo", "argumento de venda em vídeo" |
| Campanha | "campanha de lançamento", "campanha de Black Friday" |
| Thread | "thread para o Twitter/X", "sequência de tweets" |
| Copy | "copy de anúncio", "copy de vendas", "CTA para landing" |

---

## Pipeline de produção (5 fases)

Consulte `references/pipeline.md` para o detalhamento técnico completo. Este SKILL.md descreve o que fazer; o pipeline.md descreve como cada fase opera internamente.

```
Discovery → Design → Build → Review → Publish
```

---

### Fase 1: Discovery

**Objetivo:** Entender o pedido, classificar o formato e coletar o mínimo necessário.

**O que fazer:**

1. Leia o pedido em linguagem natural.
2. Classifique o(s) formato(s)-alvo usando o índice de `source/rules/marketing/README.md`.
3. Faça no máximo **3 perguntas de esclarecimento**, uma por vez, apenas se a resposta não estiver implícita no pedido:
   - Qual o público-alvo e sua dor principal?
   - Qual o tom desejado? (informal/educativo/urgência/aspiraçional)
   - Qual a plataforma/canal prioritário?
4. Ofereça investigação de referências como opção:
   > "Quer que eu investigue perfis de referência antes de criar? (usa `/marketing-research` — leva ~5 min, calibra os hooks com dados reais)"

**Gate de saída (test -s):**
```bash
# Verificar se briefing inicial existe antes de avançar
test -s /tmp/mkt_discovery_briefing.txt && echo "DISCOVERY_OK" || echo "DISCOVERY_PENDING"
```

**Mostrar ao usuário antes de avançar:**
```
Marketing — Discovery concluído
Formato detectado: <formato>
Público: <público>
Tom: <tom>
Plataforma: <plataforma>
Best-practice a usar: source/rules/marketing/<formato>.md

Avançar para Design? [s/n]
```

---

### Fase 2: Design (checkpoint de ângulos)

**Objetivo:** Definir o ângulo estratégico e a big idea antes de produzir.

**O que fazer:**

1. Carregar a best-practice do formato:
   ```bash
   # Injeção de best-practice em runtime
   FORMAT_RULE="source/rules/marketing/<formato>.md"
   test -f "$FORMAT_RULE" && echo "BP_OK" || echo "BP_MISSING"
   ```
2. Carregar `source/rules/marketing/strategist.md` e `copywriting.md`.
3. **Recrutar `mkt-estrategista` (opus):** injete o briefing da Discovery + as regras carregadas. Solicite 5 ângulos distintos com big idea por ângulo.
4. **Checkpoint de ângulos (OBRIGATÓRIO):** Apresentar os 5 ângulos ao usuário para seleção. NÃO avançar sem aprovação explícita.

```
Marketing — Ângulos propostos pelo mkt-estrategista

[Tabela de 5 ângulos: Família | Big idea | Por que funciona | Formato recomendado]

Qual ângulo você aprova? (1-5 ou ajuste livre)
```

**Gate de saída:**
```bash
test -s /tmp/mkt_angulo_aprovado.txt && echo "DESIGN_OK" || echo "AGUARDANDO_APROVACAO"
```

---

### Fase 3: Build (copy + visual)

**Objetivo:** Produzir o conteúdo completo com copy e design.

**O que fazer:**

**3a. Copy — `mkt-copywriter` (sonnet):**

Recrute o `mkt-copywriter` com:
- Ângulo aprovado + briefing de produção do estrategista
- Best-practice do formato injetada (o arquivo carregado na fase 2)
- Regras de `copywriting.md` como guia de escrita
- Instrução: produzir **3 variações de hook → body → CTA** no formato escolhido

**Checkpoint de aprovação de conteúdo (OBRIGATÓRIO — antes de qualquer passo visual):**

```
Marketing — Conteúdo produzido pelo mkt-copywriter

[3 variações de copy]

Qual variação aprovamos? (1-3 ou ajuste livre)
ATENÇÃO: Aprovação aqui é pré-requisito para o passo visual (mkt-designer).
Não avançamos para design visual sem copy aprovada.
```

Gate de aprovação de copy:
```bash
test -s /tmp/mkt_copy_aprovada.txt && echo "COPY_OK" || echo "AGUARDANDO_APROVACAO_COPY"
```

**3b. Visual — `mkt-designer` (sonnet):** _(somente após copy aprovada)_

Recrute o `mkt-designer` com:
- Copy aprovada
- Best-practice visual de `source/rules/marketing/image-design.md`
- Instrução: gerar a peça visual reutilizando a Suíte de Design IdeiaOS (`/banner-design`, `/slides` ou `/ui-ux-pro-max` conforme o formato)

**Gate de saída:**
```bash
OUTPUT_DIR="docs/marketing/$(date +%Y-%m-%d)-<slug>"
test -s "${OUTPUT_DIR}/copy.md" && echo "BUILD_OK" || echo "BUILD_INCOMPLETO"
```

---

### Fase 4: Review

**Objetivo:** Validar qualidade antes de publicar.

**O que fazer:**

Recrute o `mkt-revisor` (sonnet) com:
- Conteúdo produzido (copy + visual description)
- Regras de `source/rules/marketing/review.md`
- Instrução: scoring com veredito APPROVE/REJECT e justificativa

**Loop de revisão (máx. 2 ciclos):**

```
Se REJECT:
  → Enviar feedback específico ao mkt-copywriter
  → mkt-copywriter corrige (ciclo de correção)
  → mkt-revisor reavalia
  → Se REJECT no ciclo 2: entregar mesmo assim com flag [WAIVED — revisor ciclo 2]

Se APPROVE:
  → Avançar para Publish
```

**Gate de saída:**
```bash
test -s "${OUTPUT_DIR}/review.md" && echo "REVIEW_OK" || echo "REVIEW_PENDENTE"
```

---

### Fase 5: Publish (OPCIONAL/MANUAL)

**Objetivo:** Entregar os arquivos finais e instruir a publicação.

**O que fazer:**

1. Verificar que todos os arquivos de output estão em `docs/marketing/{data}-{slug}/`:
   ```bash
   OUTPUT_DIR="docs/marketing/$(date +%Y-%m-%d)-<slug>"
   ls "$OUTPUT_DIR/"
   ```
2. Apresentar sumário final ao usuário:

```
Marketing — Conteúdo pronto para publicação

Arquivos entregues:
- docs/marketing/<data>-<slug>/copy.md       (copy aprovada)
- docs/marketing/<data>-<slug>/visual.md     (especificação visual)
- docs/marketing/<data>-<slug>/review.md     (scoring do revisor)

Publicação: MANUAL/OPCIONAL
As skills de publicação automática (blotato, resend, instagram-publisher) são
MCP-dependentes e requerem configuração de API keys. Para publicar:
1. Copie o conteúdo de copy.md para a plataforma
2. Use o visual.md como briefing para geração de imagem (ex: /banner-design)
3. Quando disponível: /publish-instagram, /publish-linkedin ou /resend-newsletter
   via skill de publicação MCP configurada por @devops
```

---

## Estrutura de output canônica

```
docs/marketing/
└── {YYYY-MM-DD}-{slug}/
    ├── copy.md           # Copy aprovada (hooks + body + CTA, todas as variações)
    ├── visual.md         # Especificação visual (instrução para mkt-designer)
    ├── review.md         # Scoring do mkt-revisor + veredito
    └── briefing.md       # Briefing completo (discovery + ângulo + instrução)
```

**Convenção de slug:** versão kebab-case do tema principal (ex: `2026-06-16-carrossel-produtividade`).

---

## Transparência IdeiaOS (mostrar antes de fazer)

Antes de cada fase, exibir:

```
Marketing — Fase <N>: <nome>
Agent: <mkt-*> (<modelo>)
Best-practice: source/rules/marketing/<formato>.md
O que vou fazer: <1 linha>
```

---

## Quando NÃO usar /marketing

| Situação | Use isto em vez disso |
|----------|-----------------------|
| Implementar código / feature | `/gsd-do` ou `/gsd-quick` |
| Deploy pra produção | `/lovable-handoff` |
| Design de UI de app | `/ui-ux-pro-max` direto |
| Investigar perfis antes de criar | `/marketing-research` (pode ser Discovery opcional) |
| Design de apresentação/slides | `/slides` |
| Identidade de marca / logo | `/brand` ou `/design` |
| Auditoria SEO do blog | `/web-quality` |

---

## Referências internas

- `references/pipeline.md` — detalhamento técnico das 5 fases, checkpoints, ordem de recrutamento, tabela de injeção formato→best-practice
- `source/rules/marketing/README.md` — índice das 22 best-practices (disciplinas + plataformas)
- `source/agents/mkt-estrategista.md` — estrategista (opus)
- `source/agents/mkt-copywriter.md` — copywriter (sonnet)
- `source/agents/mkt-designer.md` — designer (sonnet)
- `source/agents/mkt-revisor.md` — revisor (sonnet)
- `source/skills/marketing-research/SKILL.md` — Sherlock de marketing (Discovery opcional)
