---
name: profile-investigation
description: Detalhamento por plataforma para a skill marketing-research — detecção de URL, modos de investigação e formato da análise de padrões.
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

Referência de investigação por plataforma para a skill `marketing-research`. Condensado do Sherlock original, adaptado para Chrome DevTools MCP (sem Playwright).

## Detecção de URL e extratores

| URL contém | Plataforma | Tipo de conteúdo | Extrator |
|------------|-----------|-----------------|---------|
| `instagram.com/p/` ou `instagram.com/reel/` | Instagram | Post único ou Reel | `single_post` |
| `instagram.com/{username}/` | Instagram | Perfil completo | `profile_1` ou `profile_3` |
| `youtube.com/watch?v=` ou `youtu.be/` | YouTube | Vídeo único | `single_post` |
| `youtube.com/@{channel}` ou `youtube.com/c/` | YouTube | Canal | `profile_3` |
| `x.com/{username}/status/` ou `twitter.com/{username}/status/` | X/Twitter | Tweet único ou thread | `single_post` |
| `x.com/{username}` ou `twitter.com/{username}` | X/Twitter | Perfil | `profile_3` |
| `linkedin.com/posts/` ou `linkedin.com/pulse/` | LinkedIn | Post ou artigo único | `single_post` |
| `linkedin.com/in/{name}` | LinkedIn | Perfil | `profile_3` |

Se URL não corresponder a nenhum padrão: informar o usuário. Plataformas suportadas: Instagram, YouTube, X/Twitter, LinkedIn.

## Modos de investigação por plataforma

### Instagram

| Modo | Comportamento |
|------|--------------|
| `single_post` | Navegar direto ao post. Extrair: caption completo, texto de todos os slides (carrossel), transcrição se reel com texto visível, métricas visíveis |
| `profile_1` | Navegar ao grid do perfil via Chrome DevTools MCP. Coletar o post mais recente. Parar após 1. |
| `profile_3` | Navegar ao grid. Coletar até 3 posts. Parar em 3 mesmo com mais disponíveis. Priorizar: carrosséis > reels > posts simples (maior sinal para padrões de escrita). |

**Login wall no Instagram:** pausar, pedir login manual. O usuário faz login na aba já aberta no Chrome (Chrome DevTools MCP usa a sessão real do browser do usuário).

**Conteúdo a extrair por tipo:**
- Carrossel: caption + texto de cada slide (nomear Slide 1, Slide 2, etc.)
- Reel: caption + transcrição se audio-to-text estiver disponível; caso contrário: `"Transcrição não disponível."`
- Post simples: caption completo

### YouTube

| Modo | Comportamento |
|------|--------------|
| `single_post` | Navegar ao vídeo. Extrair: título, descrição completa (expandir "mais"), transcrição via legendas automáticas se disponível |
| `profile_3` | Navegar ao canal → aba Videos. Coletar 3 vídeos mais recentes OU 3 mais populares (perguntar ao usuário). Extrair título + descrição de cada um. |

**Transcrição de vídeo:** use legendas visíveis na interface (acessíveis via snapshot/scroll) — não requer yt-dlp/ffmpeg/whisper. Se legendas não visíveis, registrar: `"Legendas não disponíveis via interface — transcrição não extraída."`

### X/Twitter

| Modo | Comportamento |
|------|--------------|
| `single_post` | Navegar ao tweet. Extrair: texto completo, todos os tweets da thread se for thread, métricas visíveis (curtidas, RT, respostas, views) |
| `profile_3` | Navegar ao perfil → aba Posts. Coletar 3 posts mais recentes. Priorizar threads (maior sinal). |

**Recomendação para squads de escrita:** focar em threads (`Threads only`) — maior sinal de padrões de escrita.

### LinkedIn

| Modo | Comportamento |
|------|--------------|
| `single_post` | Navegar ao post. Expandir "ver mais". Extrair: texto completo, reactions, comentários visíveis |
| `profile_3` | Navegar ao perfil → seção Atividade → Publicações. Coletar 3 posts mais recentes. |

**Artigos LinkedIn:** se URL for `linkedin.com/pulse/`, extrair título + texto completo do artigo.

## Formato do raw-content.md

```markdown
# Conteúdo Bruto: @{username} ({plataforma})

Investigado: {AAAA-MM-DD}
Total de conteúdos: {N}
Tipos: {ex: carrossel, reel, post simples}

---

## Conteúdo 1: [{Tipo: N slides | Formato}]

**Data:** AAAA-MM-DD
**Métricas:** {N} curtidas, {N} comentários, {N} saves
**URL:** {url}

### Caption
Texto exato do caption, com todos os emojis, hashtags e quebras de linha.
Sem editar. Sem resumir.

### Slide 1
Texto exato visível no slide 1. Se puramente visual: "[Apenas visual — sem texto]"

### Slide 2
Texto do slide 2.

(Continuar para todos os slides)

---

## Conteúdo 2: [Reel: Xs | {categoria}]

**Data:** AAAA-MM-DD
**Métricas:** {N} views, {N} curtidas
**URL:** {url}

### Caption
Texto exato.

### Transcrição
Transcrição completa do áudio/texto em tela, se disponível.
Se não disponível: "Transcrição não disponível — legendas não acessíveis via interface."

---
```

## Formato do pattern-analysis.md

```markdown
# Análise de Padrões: @{username} ({plataforma})

Analisado: {AAAA-MM-DD}
Amostra: {N} conteúdos
Período: {data mais antiga} a {data mais recente}

## Resumo executivo
[3-5 frases: o que torna este criador distintivo? qual a estratégia central de conteúdo?
quais padrões correlacionam com alto engajamento?]

## Padrões estruturais

### Mix de conteúdo
| Tipo | Qtd | % | Engaj. médio |
|------|-----|---|-------------|
| Carrossel | N | % | N curtidas |
| Reel | N | % | N views |
| Post simples | N | % | N curtidas |

### Cadência
- Posts por semana: N
- Dias mais comuns: [dias]
- Rotação de tipos: [padrão se houver]

## Padrões de linguagem

### Perfil de tom
[2-3 frases: formal/casual, autoritativo/conversacional, objetivo, etc.]

### Hooks de alto desempenho (top 5 por engajamento)
1. "{hook exato}" — Padrão: [nome: ex. contrariedade, curiosidade, pergunta desafiadora]
2. "{hook exato}" — Padrão: [nome]
3. "{hook exato}" — Padrão: [nome]
4. "{hook exato}" — Padrão: [nome]
5. "{hook exato}" — Padrão: [nome]

### CTAs mais usados
1. [Tipo de CTA]: "{exemplo}" — N de N posts
2. [Tipo de CTA]: "{exemplo}" — N de N posts

### Vocabulário recorrente
- "{frase}" — aparece em N posts, contexto: [uso]
- "{frase}" — aparece em N posts, contexto: [uso]
- "{frase}" — aparece em N posts, contexto: [uso]

### Estilo
- Comprimento de frase: [curto/médio/longo, média de palavras]
- Emojis: [frequência e posicionamento]
- Formatação: [quebras de linha, bullets, negrito/caps]
- Hashtags: [quantidade, posição, tipo]

## Padrões de engajamento

### Conteúdo de alto desempenho
| Rank | Hook/Título | Tipo | Métrica | Por que funcionou |
|------|-------------|------|---------|------------------|
| 1 | "{hook}" | Carrossel | N saves | [razão específica] |
| 2 | "{hook}" | Reel | N views | [razão específica] |

### Fatores de engajamento
- [Padrão]: posts com este padrão têm X% mais [curtidas/saves/views]
- [Padrão]: correlaciona com alto engajamento em N de N posts

## 5 Recomendações para o squad

1. **[Título da recomendação]**: [recomendação específica com exemplo do conteúdo analisado
   e como adaptar para a marca do usuário]

2. **[Título]**: [recomendação detalhada]

3. **[Título]**: [recomendação detalhada]

4. **[Título]**: [recomendação detalhada]

5. **[Título]**: [recomendação detalhada]
```

## Recomendações por tipo de squad

| Tipo de squad | Foco recomendado no Instagram | Foco no X/Twitter | Foco no LinkedIn |
|---------------|------------------------------|-------------------|-----------------|
| Conteúdo / copywriting | Carrosséis + Reels | Threads | Posts longos |
| Vídeo | Reels | N/A | N/A |
| Estratégia / análise | Todos os tipos | Todos | Posts + Artigos |
| Geral | Todos (`profile_3`) | Todos | Posts |

## Tratamento de erros

### error.md

Se extração falhar completamente, salvar em `assets/marketing/_investigations/{usuario}/error.md`:

```markdown
# Erro de investigação: @{username} ({plataforma})

Data: {AAAA-MM-DD}
Causa: {descrição do erro}
O que foi tentado: {tentativas feitas}
Retry realizado: Sim/Não

Recomendação: {ação sugerida ao usuário}
```

**Regras:**
- Nunca produzir investigação sem `raw-content.md` OU `error.md` — um dos dois deve existir sempre
- Resultado parcial: salvar em `raw-content.md` com nota sobre o que faltou
- Não criar `error.md` se há dados parciais suficientes para análise de padrões
