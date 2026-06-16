# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

# Pipeline de Produção de Conteúdo — Referência Técnica

Detalhamento das 5 fases do `/marketing`, checkpoints obrigatórios, ordem de recrutamento dos agents e tabela de injeção formato→best-practice.

---

## Visão geral do pipeline

```
[Discovery] → [Design] → [Build: Copy] → [Checkpoint Aprovação] → [Build: Visual] → [Review] → [Publish]
     ↑               ↑              ↑                    ↑                  ↑              ↑
  Perguntas     mkt-estrategista  mkt-copywriter     GATE HUMANO       mkt-designer   mkt-revisor
  (máx 3)         (opus)          (sonnet)         (sem isso, para)     (sonnet)       (sonnet)
```

---

## Fase 1: Discovery

### Inputs
- Pedido em linguagem natural do usuário
- (Opcional) Análise de `marketing-research` se solicitada

### Processo
1. Classificar formato pela tabela de injeção (ver abaixo)
2. Formular mínimo de perguntas (máx 3, uma por vez)
3. Oferecer `marketing-research` como opção enriquecedora

### Output esperado
Briefing compacto com: tema | público | tom | plataforma | formato | best-practice a carregar

### Gate
```bash
# Confirmar que briefing foi registrado antes de avançar
BRIEFING="/tmp/mkt_discovery_briefing.txt"
test -s "$BRIEFING" && echo "DISCOVERY_GATE: PASS" || echo "DISCOVERY_GATE: FAIL — registre o briefing"
```

---

## Fase 2: Design

### Inputs
- Briefing da Discovery
- Best-practice do formato (injetada em runtime)
- `source/rules/marketing/strategist.md`
- `source/rules/marketing/copywriting.md`

### Agent: mkt-estrategista (opus)
**Por que opus:** estratégia de ângulo é decisão de alto impacto cognitivo — tradeoff intencional de custo por qualidade.

**Instrução ao agent:**
```
Contexto: <briefing da Discovery>
Best-practice do formato: <conteúdo de source/rules/marketing/<formato>.md>
Regras de estratégia: <conteúdo de source/rules/marketing/strategist.md>
Regras de copywriting: <conteúdo de source/rules/marketing/copywriting.md>

Gere 5 ângulos distintos para o tema "<tema>" no formato "<formato>".
Para cada ângulo: família psicológica | big idea (1 linha) | por que funciona (2 frases) | formato recomendado.
```

### Checkpoint de ângulos (OBRIGATÓRIO)
```
Marketing — Checkpoint: Aprovação de ângulo

O mkt-estrategista propôs 5 ângulos. Escolha um (1-5) ou ajuste livremente.
NÃO prosseguimos sem aprovação explícita — o ângulo define todo o conteúdo.
```

### Gate
```bash
test -s "/tmp/mkt_angulo_aprovado.txt" && echo "DESIGN_GATE: PASS" || echo "DESIGN_GATE: FAIL — aguardando seleção de ângulo"
```

---

## Fase 3a: Build — Copy

### Inputs
- Ângulo aprovado + briefing de produção (output do estrategista)
- Best-practice do formato (mesmo arquivo carregado no Design)
- `source/rules/marketing/copywriting.md`

### Agent: mkt-copywriter (sonnet)
**Por que sonnet:** produção de copy é tarefa de alta frequência — equilíbrio custo/qualidade.

**Instrução ao agent:**
```
Contexto: <briefing de produção do mkt-estrategista>
Ângulo aprovado: <ângulo selecionado pelo usuário>
Best-practice do formato: <conteúdo de source/rules/marketing/<formato>.md>
Regras de copywriting: <conteúdo de source/rules/marketing/copywriting.md>

Produza 3 variações de copy para "<tema>" no formato "<formato>".
Cada variação: hook (captura atenção) → body (conteúdo) → CTA (ação).
Siga estritamente as regras do formato injetado.
```

### Checkpoint de copy (OBRIGATÓRIO — gate de conteúdo)
```
Marketing — Checkpoint: Aprovação de copy

3 variações produzidas pelo mkt-copywriter. Aprove uma antes de avançar para o visual.
REGRA: nenhum passo visual começa sem copy aprovada.
```

### Gate
```bash
test -s "/tmp/mkt_copy_aprovada.txt" && echo "COPY_GATE: PASS" || echo "COPY_GATE: FAIL — aguardando aprovação de copy"
```

---

## Fase 3b: Build — Visual

### Inputs
- Copy aprovada
- `source/rules/marketing/image-design.md`
- Suíte de Design IdeiaOS (conforme formato)

### Agent: mkt-designer (sonnet)
**Por que sonnet:** design de peças é tarefa criativa recorrente — equilíbrio custo/qualidade.

**Instrução ao agent:**
```
Copy aprovada: <copy selecionada>
Best-practice visual: <conteúdo de source/rules/marketing/image-design.md>
Formato: <formato>

Gere a especificação visual da peça. Use a Suíte de Design IdeiaOS:
- Carrossel → /slides (N slides com copy dividida)
- Post estático → /banner-design
- Story → /banner-design (formato 9:16)
- Blog → sem visual (copy já é o produto)
```

### Gate
```bash
OUTPUT_DIR="docs/marketing/$(date +%Y-%m-%d)-<slug>"
mkdir -p "$OUTPUT_DIR"
test -s "${OUTPUT_DIR}/copy.md" && echo "BUILD_GATE: PASS" || echo "BUILD_GATE: FAIL — salve os arquivos"
```

---

## Fase 4: Review

### Inputs
- Conteúdo completo (copy + visual)
- `source/rules/marketing/review.md`

### Agent: mkt-revisor (sonnet)
**Instrução ao agent:**
```
Conteúdo para revisão:
<copy aprovada>
<especificação visual>

Regras de revisão: <conteúdo de source/rules/marketing/review.md>

Faça o scoring e emita veredito APPROVE ou REJECT com justificativa.
```

### Loop de correção (máx. 2 ciclos)
```
Ciclo 1 (REJECT):
  → feedback específico → mkt-copywriter corrige → mkt-revisor reavalia

Ciclo 2 (REJECT):
  → Entregar com flag [WAIVED — aprovação após ciclo 2]
  → Documentar no review.md: motivo do waiver + riscos identificados
```

### Gate
```bash
test -s "${OUTPUT_DIR}/review.md" && echo "REVIEW_GATE: PASS" || echo "REVIEW_GATE: FAIL"
```

---

## Fase 5: Publish (OPCIONAL/MANUAL)

Entrega de arquivos + instrução de publicação. Sem automação neste plano.

Skills de publicação automática são MCP-dependentes (blotato, resend, instagram-publisher) e requerem configuração por `@devops`. Quando disponíveis, serão integradas como passo opcional pós-review.

---

## Tabela de injeção formato → best-practice

Esta tabela mapeia o sinal detectado na Discovery para o arquivo de best-practice a carregar no Design/Build.

| Formato detectado | Arquivo a carregar | Sinal(s) típico(s) |
|-------------------|--------------------|---------------------|
| Carrossel Instagram | `source/rules/marketing/instagram-feed.md` | "carrossel", "feed Instagram", "slides pra Instagram" |
| Post Instagram (feed) | `source/rules/marketing/instagram-feed.md` | "post Instagram", "legenda", "conteúdo de feed" |
| Reels / Shorts | `source/rules/marketing/instagram-reels.md` | "reels", "vídeo curto", "shorts" |
| Stories | `source/rules/marketing/instagram-stories.md` | "story", "stories" |
| Post LinkedIn | `source/rules/marketing/linkedin-post.md` | "post LinkedIn", "linkedin" |
| Artigo LinkedIn | `source/rules/marketing/linkedin-article.md` | "artigo LinkedIn", "artigo longo" |
| Tweet | `source/rules/marketing/twitter-post.md` | "tweet", "post Twitter", "X/Twitter" |
| Thread | `source/rules/marketing/twitter-thread.md` | "thread", "sequência de tweets" |
| Newsletter | `source/rules/marketing/email-newsletter.md` | "newsletter", "email pra assinantes" |
| Email de vendas | `source/rules/marketing/email-sales.md` | "email de vendas", "cold email", "outreach" |
| Blog post | `source/rules/marketing/blog-post.md` | "blog post", "artigo de blog" |
| Blog SEO | `source/rules/marketing/blog-seo.md` | "blog SEO", "artigo otimizado", "conteúdo para busca" |
| Roteiro YouTube | `source/rules/marketing/youtube-script.md` | "roteiro YouTube", "script de vídeo longo", "VSL" |
| YouTube Shorts | `source/rules/marketing/youtube-shorts.md` | "YouTube Shorts", "vídeo curto YouTube" |
| WhatsApp Broadcast | `source/rules/marketing/whatsapp-broadcast.md` | "mensagem WhatsApp", "broadcast", "lista de transmissão" |
| Copy / CTA | `source/rules/marketing/copywriting.md` | "copy", "CTA", "copy de anúncio", "texto de vendas" |
| Campanha (multi-formato) | `source/rules/marketing/strategist.md` + formato específico | "campanha de lançamento", "campanha completa" |

**Quando ambíguo** (ex: "cria um post" sem especificar plataforma): perguntar "Para qual plataforma?" antes de avançar para Design.

---

## Ordem de recrutamento dos agents

```
Discovery → (usuário + marketing-research opcional)
Design    → mkt-estrategista (opus)   [checkpoint]
Build-A   → mkt-copywriter (sonnet)   [checkpoint]
Build-B   → mkt-designer (sonnet)     (somente pós-checkpoint copy)
Review    → mkt-revisor (sonnet)      [loop máx 2 ciclos]
Publish   → manual/MCP futuro
```

---

## Checkpoints obrigatórios (resumo)

| Fase | Checkpoint | Gate | Pode pular? |
|------|-----------|------|-------------|
| Discovery→Design | Confirmar briefing + formato | `test -s briefing.txt` | NÃO |
| Design→Build | Aprovar ângulo estratégico | `test -s angulo_aprovado.txt` | NÃO |
| Build Copy→Visual | Aprovar copy antes de design visual | `test -s copy_aprovada.txt` | NÃO (T-26-10) |
| Review→Publish | Veredito do revisor | `test -s review.md` | Somente com flag WAIVED |

**Fundamento do checkpoint de copy (T-26-10):** publicação é ação irreversível em plataformas sociais. O gate de aprovação antes do visual garante que nenhum conteúdo não-aprovado avança para distribuição ou design final.
