---
name: marketing-research
description: "Investiga perfis públicos de referência (Instagram, LinkedIn, YouTube, X/Twitter) para extrair padrões reais de conteúdo de alto desempenho. Usa o Chrome DevTools MCP já instalado no IdeiaOS — NÃO requer Playwright nem nova dependência de browser. Ative quando o usuário disser: 'analisa o perfil @X', 'inspira-se no estilo de Y', 'quero entender o que Z posta', 'pesquisa referências de conteúdo', 'investigação de perfis', 'sherlock de marketing'. Output: raw-content.md + pattern-analysis.md por perfil, alimentando mkt-estrategista e mkt-copywriter com dados de primeira mão. Nunca fabricar dados. Se extração falhar, salvar nota de erro."
---

# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6

Skill Sherlock de marketing — investiga perfis públicos reais e produz análise de padrões que calibra a geração de conteúdo com dados de primeira mão (não best-practices genéricas). Idioma: Português brasileiro.

## Motor de automação

Usa exclusivamente o **Chrome DevTools MCP** já instalado no IdeiaOS (`mcp__chrome-devtools__*`) — o mesmo motor de `/frontend-visual-loop` e `/web-quality`. NÃO requer Playwright, NÃO adiciona nova dependência de browser.

```
mcp__chrome-devtools__list_pages      # listar abas abertas
mcp__chrome-devtools__navigate_page   # navegar para URL
mcp__chrome-devtools__take_snapshot   # accessibility tree (barato, semântico)
mcp__chrome-devtools__take_screenshot # evidência visual
mcp__chrome-devtools__list_console_messages
```

## Quando usar

- Usuário quer se inspirar no estilo de criadores específicos
- Antes de criar um squad de conteúdo (fase discovery do `/marketing`)
- Para calibrar hooks, estrutura e cadência com dados reais de plataforma
- Quando a estratégia precisa de referências, não só de best-practices

## Quando NÃO usar

- Perfis privados ou protegidos por paywall sem login manual
- Investigação de concorrentes para fins de vigilância (use `/deep-research`)
- Extração de dados pessoais sensíveis de usuários comuns

## Prioridade de dados (regra herdada do Sherlock)

Dados extraídos via investigação direta **têm prioridade** sobre web research genérico. Os agents `mkt-estrategista` e `mkt-copywriter` devem referenciar explicitamente os padrões encontrados: `[Fonte: investigação — @usuario]` vs `[Fonte: web research]`.

## Aviso de sessão (OBRIGATÓRIO no início de toda investigação)

Antes de qualquer ação no browser, informe o usuário:

> "O browser que usarei é o Chrome DevTools MCP conectado ao seu Chrome local. Se o perfil estiver atrás de login, vou pausar e pedir que você faça login manualmente na aba que abrir — a sessão já aberta no seu browser é usada diretamente. Você controla o browser."

## Configuração por URL

Detecta a plataforma pela URL e aplica o extrator correto (detalhado em `references/profile-investigation.md`):

| URL contém | Plataforma | Comportamento |
|------------|-----------|---------------|
| `instagram.com` | Instagram | Posts, carrosséis, reels |
| `youtube.com` / `youtu.be` | YouTube | Vídeos, descrições, títulos |
| `x.com` / `twitter.com` | X/Twitter | Tweets, threads |
| `linkedin.com` | LinkedIn | Posts, artigos |

Se a URL não corresponde a nenhuma plataforma conhecida: informar o usuário. Plataformas suportadas: Instagram, YouTube, X/Twitter, LinkedIn.

## Modos de investigação

| Modo | Significado | Comportamento |
|------|------------|---------------|
| `single_post` | URL de post/reel específico | Só aquele post — não navega o perfil |
| `profile_1` | Scan do perfil, 1 post | Post mais recente; para após 1 |
| `profile_3` | Scan do perfil, padrões | Até 3 posts; para em 3 mesmo se houver mais |

Default: `profile_3`.

## Processo de investigação

### Passo 1 — Receber URLs e confirmar configuração

Receba 1-5 URLs de perfis públicos do usuário. Para cada uma, confirme:
- Plataforma detectada
- Modo de investigação (default: `profile_3`)
- Tipo de conteúdo (todos, carrosséis, reels, threads, etc.)

### Passo 2 — Verificar acesso ao perfil

```
mcp__chrome-devtools__navigate_page → URL do perfil
mcp__chrome-devtools__take_snapshot → checar se há login wall
```

Se login wall detectado:
> "Encontrei uma barreira de login em [plataforma]. Por favor, faça login manualmente na aba que está aberta no seu Chrome e me avise quando terminar."

Aguardar confirmação do usuário antes de continuar. Nunca persistir credenciais em arquivos do repositório.

### Passo 3 — Extrair conteúdo real

Para cada post/conteúdo no modo selecionado:
- Navegar até o post
- Capturar snapshot + screenshot (como evidência)
- Extrair: caption completo, texto de slides (carrossel), transcrição se texto estiver disponível, métricas visíveis (curtidas, comentários, saves, views)
- Screenshot path: `assets/marketing/_investigations/{usuario}/screenshots/{post-id}.png`

**Limites:**
- Máximo 10 minutos por perfil. Se exceder: salvar o que foi coletado e anotar "Investigação truncada em N conteúdos por limite de tempo."
- Se plataforma bloquear acesso: tentar uma vez. Se falhar: salvar `error.md` e informar o usuário.
- **Nunca salvar screenshots sem path completo** — omitir o path polui a raiz do repositório.

### Passo 4 — Produzir raw-content.md

Salvar em `assets/marketing/_investigations/{usuario}/raw-content.md`:
- Todo conteúdo extraído, exatamente como aparece na plataforma (sem editar, sem resumir)
- Métricas coletadas
- Data da investigação
- Se transcrição de vídeo não foi possível: `"Transcrição não disponível — extração de áudio requer yt-dlp/whisper."`

### Passo 5 — Produzir pattern-analysis.md

Salvar em `assets/marketing/_investigations/{usuario}/pattern-analysis.md`:
- Análise de padrões estruturais (mix de formatos, cadência, comprimento)
- Padrões de linguagem (tom, hooks de alto desempenho, CTAs, vocabulário recorrente)
- Padrões de engajamento (o que performa mais e por quê)
- 5 recomendações acionáveis para o squad (como adaptar esses padrões para a marca)

## Output canônico

```
## Investigação concluída — @{usuario} ({plataforma})

Arquivos:
- assets/marketing/_investigations/{usuario}/raw-content.md
- assets/marketing/_investigations/{usuario}/pattern-analysis.md

Conteúdos extraídos: N
Período coberto: {data mais antiga} a {data mais recente}

Top 3 padrões encontrados:
1. [padrão com exemplo específico]
2. [padrão com exemplo específico]
3. [padrão com exemplo específico]

Próximo passo: disponível para mkt-estrategista e mkt-copywriter como contexto de investigação.
```

## Tratamento de falhas

**Nunca fabricar dados. Nunca declarar sucesso sobre resultados vazios.**

- Extração falha por qualquer motivo → salvar `error.md` em `assets/marketing/_investigations/{usuario}/error.md` com descrição do erro
- Resultado parcial: salvar o que foi coletado com nota sobre o que faltou. Não criar `error.md` se há dados parciais suficientes.
- Browser não responde: salvar dados coletados até então, reportar a falha

## Roteamento pelo /marketing e Deia

Esta skill é invocável diretamente ou pelo orquestrador `/marketing` na fase de discovery:
- Sinal de ativação: "analisa o perfil @X", "inspira-se no estilo de Y", "investigação de referências"
- O `/marketing` injeta a skill como passo opcional de discovery antes de acionar o `mkt-estrategista`
- Deia também pode rotear para esta skill quando detectar pedido de "pesquisa referências de conteúdo"

## Integração com a suite de agentes de marketing

| Skill | Papel |
|-------|-------|
| `mkt-estrategista` | Consome `pattern-analysis.md` para calibrar ângulos e big idea com dados reais |
| `mkt-copywriter` | Consome `raw-content.md` para adotar hooks e vocabulário de alto desempenho |
| `mkt-revisor` | Pode usar `quality-criteria` extraídos da investigação como benchmark de scoring |
