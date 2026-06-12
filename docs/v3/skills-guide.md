# SOURCE: IdeiaOS v2

# Guia de Skills IdeiaOS — Quando Usar, Em Que Ordem, O Que Evitar

**Versão:** v2 (baseada em inspeção direta dos 34 SKILL.md em `source/skills/`)
**Atualizado:** 2026-06-12

---

## Resumo

As 34 skills do IdeiaOS se organizam em 5 clusters de workflow: **Dev Diário** (lógica e back-end), **Design/Visual** (UI, identidade, apresentações), **Learning Loop** (captura e evolução de conhecimento), **Receitas/Handoff** (orquestração, pesquisa, otimização) e **Meta/Setup** (instalação e continuidade). Há **10 candidatos de redundância** detectados — principalmente na suíte de design (onde `design` engloba `banner-design`, `brand`, `slides` e `design-system` como sub-skills) e no par `codebase-onboarding`/`code-tour`. O `/instinct-analyze` é invocação manual sem scheduler (gap documentado). Contagem total: 34 skills, nenhuma omitida.

---

## Skills por Workflow

### Dev Diário

Skills para o ciclo de desenvolvimento cotidiano: desde a ideia até testes e qualidade de API.

**Skills do grupo (8):**
`idea` · `tdd` · `e2e-testing` · `code-tour` · `codebase-onboarding` · `web-quality` · `api-design` · `database-migrations`

**Sequência recomendada — cenário: implementar feature nova em projeto existente**

```
1. /codebase-onboarding  → entender o projeto (só na primeira vez ou retorno longo)
2. /idea                 → rotear o pedido para a camada certa (GSD, AIOX, etc.)
3. /api-design           → definir o contrato antes de codar (endpoint novo)
4. /tdd                  → escrever teste falhando → implementar → passar
5. /e2e-testing          → cobrir o happy path crítico do fluxo completo
6. /database-migrations  → schema novo: diff → preview → rollback plan → push
7. /code-tour            → documentar o fluxo para o próximo dev/agente
8. /web-quality          → auditar performance/a11y/SEO antes de publicar
```

**Anti-patterns / quando NÃO usar:**

- `/tdd` — lógica visual (UI/estilos) não tem asserção verificável; use revisão manual.
- `/e2e-testing` — lógica unitária isolada; use `tdd` (e2e é lento e frágil para isso).
- `/database-migrations` — queries de leitura/INSERT sem DDL; o processo de diff/preview é overhead desnecessário.
- `/api-design` — funções internas sem surface de rede; não cria um documento de contrato para funções helper.
- `/codebase-onboarding` — projeto já conhecido; vai direto para `/code-tour` se precisar do detalhe de um fluxo.
- `/web-quality` — mudança não-visual ou back-end puro; sem URL renderizável a auditoria não roda.
- `/idea` — quando o comando direto já foi digitado (ex: `/gsd-plan-phase`); não re-roteie.

**Exemplo canônico:**

> Feature: endpoint `POST /api/orders` em projeto Next.js + Supabase existente.
>
> 1. `/api-design` → contrato TypeScript (`CreateOrderRequest`, `CreateOrderResponse`, status codes).
> 2. `/tdd` → RED: `expect(createOrder(validPayload)).resolves.toMatchObject({status:"pending"})` falhando. GREEN: implementação mínima. REFACTOR: extrair `validateItems()`.
> 3. `/database-migrations` → nova coluna `confirmed_at`: `supabase db diff` → branch preview → checklist RLS → `supabase db push`.
> 4. `/e2e-testing` → Playwright: `page.goto("/checkout")` → preencher → `expect(page).toHaveURL("/order/confirmed")`.

---

### Design / Visual

Skills para toda a camada visual: identidade de marca, sistema de tokens, componentes, animação, banners, apresentações e qualidade visual.

**Skills do grupo (10):**
`design` · `design-system` · `ui-styling` · `ui-ux-pro-max` · `frontend-visual-loop` · `motion` · `banner-design` · `brand` · `slides` · `accessibility`

**Sequência recomendada — cenário: criar identidade visual e UI de produto novo**

```
1. /brand            → definir voz, identidade visual, guia de marca
2. /design-system    → gerar tokens OKLCH a partir do --brand-hue; camadas primitive→semantic→component
3. /ui-styling       → configurar shadcn/ui + Tailwind com os tokens gerados
4. /ui-ux-pro-max    → aplicar regras de UX (paletas, tipografia, espaçamento, 99 guidelines)
5. /accessibility    → construir com semântica correta; contraste AA, navegação por teclado
6. /frontend-visual-loop → render → screenshot → critique → fix (max 3 iterações, Chrome DevTools MCP)
7. /motion           → adicionar animações Framer Motion / GSAP onde o UX pede
8. /web-quality      → auditoria CWV + WCAG Lighthouse antes de publicar
9. /design           → logo, CIP, banners, ícones, social photos (sub-skills embutidas)
10. /banner-design   → banners específicos para social/ads/print (fluxo próprio com AI)
11. /slides          → apresentações HTML com Chart.js e design tokens
```

> Nota: para feature incremental, entrar diretamente na etapa relevante (ex.: só `/motion` para adicionar animação em componente existente).

**Anti-patterns / quando NÃO usar:**

- `/ui-ux-pro-max` — back-end puro, API design, infra; não tem surface visual.
- `/frontend-visual-loop` — back-end / código não-visual; sem app rodando a skill não se aplica.
- `/motion` — animação trivial resolvível com `transition` do Tailwind CSS puro (hover de cor, opacity simples); não instale Framer Motion só para isso.
- `/accessibility` — back-end puro ou scripts internos sem UI.
- `/design-system` — projeto sem stack de componentes; tokens sem consumidor não têm valor.
- `/brand` — projeto sem identidade visual (MVP técnico interno); pode ser overkill.
- `/design` — não use como substituto de `/ui-ux-pro-max` para decisões de UX; `/design` roteia para sub-skills visuais, não é rubric de qualidade.
- `/banner-design` — UI interna de produto; é para assets de marketing/social, não interfaces de app.
- `/slides` — documentação técnica corrida; slides são para comunicação persuasiva, não para README.

**Exemplo canônico:**

> Dashboard SaaS novo.
>
> 1. `/brand` → `docs/brand-guidelines.md` + `assets/design-tokens.json`.
> 2. `/design-system` → `node scripts/generate-tokens.cjs` → `tokens.css` com `--color-primary`, `--slide-bg`, etc.
> 3. `/ui-styling` → `npx shadcn@latest add card table` → Tailwind config com tokens.
> 4. `/ui-ux-pro-max --domain ux` → aplica os 99 guidelines (hierarquia, espaçamento, estados de loading/empty).
> 5. `/accessibility` → checklist WCAG 2.1 AA (contraste 4.5:1, labels em inputs, foco visível).
> 6. `/frontend-visual-loop` → 3 iterações render→critique→fix, desktop + mobile (390px).

---

### Learning Loop

Skills para capturar, analisar, visualizar e promover aprendizado entre sessões.

**Skills do grupo (6):**
`instinct-analyze` · `instinct-status` · `learn` · `evolve` · `recall-learnings` · `extract-learnings`

**Sequência recomendada — cenário: sessão de implementação não-trivial completa**

```
Início da sessão:
1. /recall-learnings    → carrega learnings, memória Claude, vault Obsidian, instincts (Passos 1-7)

Durante a sessão:
2. /learn               → se descobriu gotcha mid-session que vai se repetir (confidence 0.5 imediato)

Após sessão longa / ao retomar projeto:
3. /instinct-analyze    → destila observations.jsonl em instincts atômicos (background haiku)
4. /instinct-status     → exibe instincts com barras de confidence; identifica ★ (≥0.7)

Final da sessão:
5. /extract-learnings   → gate triplo (replicável? não-óbvio? estável?) → grava docs/learnings/
6. /evolve              → promove instincts ≥0.7 para source/rules/ ou vault Obsidian
```

**Anti-patterns / quando NÃO usar:**

- `/instinct-analyze` — não há observações acumuladas (arquivo `observations.jsonl` inexistente ou vazio); a skill avisa e encerra. **Gap crítico: não há scheduler automático; é invocação manual.**
- `/learn` — soluções triviais ou eventos únicos que não vão se repetir; use o gate: "isso se repete em sessões futuras?".
- `/extract-learnings` — sessões puramente operacionais (dep bump, typo em doc, rename trivial); o gate triplo vai abortar, economizando tempo.
- `/evolve` — instincts com confidence < 0.7; aguardar mais evidências. Nunca promover instinct de evento único.
- `/recall-learnings` — perguntas conversacionais simples ("o que é X?"); só para implementações/correções não-triviais.
- `/instinct-status` — antes de `/instinct-analyze` rodar ao menos uma vez (banco vazio); a skill informa e encerra.

**Exemplo canônico:**

> Início de sessão em projeto `nfideia` (com histórico de observações):
>
> 1. `/recall-learnings` → "Contexto carregado: últimos 3 learnings (RLS divergência, cache-race, supabase service_role bypass). Instinct aplicável: `ao editar .ts → rodar tsc --noEmit` (0.7, ★)."
> 2. Sessão: bug fix não-óbvio em política RLS.
> 3. `/learn` → "Instinct registrado: `ao adicionar coluna → verificar RLS para service_role` (confidence 0.5, domain: supabase)."
> 4. Fim da sessão: `/extract-learnings` → gate passou (replicável, não-óbvio, estável) → `docs/learnings/2026-06-12-rls-service-role-new-column.md`.
> 5. `/instinct-analyze` → reforça o instinct criado com `/learn` → confidence 0.5→0.6.
> 6. `/instinct-status` → mostra o instinct reforçado (ainda não ★).

---

### Receitas / Handoff / Otimização

Skills para orquestrar projetos complexos, pesquisa aprofundada, deploy Lovable, otimização iterativa e redução de custo.

**Skills do grupo (7):**
`lovable-handoff` · `two-instance-kickoff` · `llms-txt` · `mcp-to-cli` · `deep-research` · `benchmark-optimization-loop` · `cost-tracking`

> `two-instance-kickoff`, `llms-txt`, `mcp-to-cli` têm `installStrategy: manual` (não instaladas automaticamente — uso sob demanda).

**Sequência recomendada — cenário: kickoff de produto novo com deploy Lovable**

```
1. /two-instance-kickoff  → Instância A: scaffold + setup IdeiaOS. Instância B: deep research do domínio (paralelas)
2. /deep-research         → decisões técnicas com trade-offs (ex: auth lib, estratégia de cache, 3 ciclos iterativos)
3. /llms-txt              → gerar llms.txt da codebase para consumo por agentes externos
4. /cost-tracking         → definir campo model: em cada AGENT.md (haiku/sonnet/opus por tipo cognitivo)
5. /mcp-to-cli            → identificar MCPs pesados com >10 tools usadas e converter para skill+bash
6. /lovable-handoff       → gate Lovable → typecheck → commit → push → merge main → handoff
7. /benchmark-optimization-loop → após deploy, se performance estiver abaixo: baseline → 1 mudança → re-medir
```

**Anti-patterns / quando NÃO usar:**

- `/two-instance-kickoff` — projeto existente com código em produção; use `/gsd-plan-phase` diretamente.
- `/two-instance-kickoff` — mudança incremental (feature nova, bugfix); uma instância é suficiente.
- `/lovable-handoff` — projeto que não é Lovable Cloud; o gate obrigatório vai bloquear (e deve bloquear).
- `/deep-research` — resposta já conhecida e segura (sem trade-offs); não desperdice ciclos de retrieval.
- `/deep-research` — quando o prazo não permite iteração (use 1 ciclo com best-effort e documente incerteza).
- `/benchmark-optimization-loop` — antes de ter baseline estabelecido ("parece lento" não é suficiente); estabeleça o baseline primeiro.
- `/benchmark-optimization-loop` — mudar várias coisas de uma vez; a skill exige mudança isolada por iteração.
- `/cost-tracking` — busca simples com haiku já é a escolha óbvia; não use opus "por precaução".
- `/mcp-to-cli` — MCP com <10 tools e uso intenso; o overhead de conversão não compensa.
- `/llms-txt` — projeto interno sem agentes externos consumindo; o índice não tem audiência.

**Exemplo canônico:**

> Produto novo "IdeiaPartner" (SaaS, Lovable Cloud, Supabase):
>
> 1. `/two-instance-kickoff` → Instância A: `npx create-next-app`, `bash setup.sh --project-only`, `AGENTS.md/CLAUDE.md`. Instância B: `/deep-research` "qual estratégia de auth para Next.js + Supabase (NextAuth vs Supabase Auth vs Clerk)?" — 2 ciclos de retrieval → recomendação: Supabase Auth (integração nativa RLS).
> 2. `/cost-tracking` → `code-explorer` agent: haiku. `security-reviewer` agent: opus. `build-error-resolver`: sonnet.
> 3. `/mcp-to-cli` → Supabase MCP (45 tools) → skill `supabase-cli` com 5 comandos usados → MCP desativado.
> 4. `/llms-txt` → `llms.txt` com 15 entradas (AGENTS.md, CLAUDE.md, manifests/modules.json, principais skills).
> 5. Feature completa: `/lovable-handoff` → typecheck → commit → push → merge main → instrução Lovable Update/Publish.

---

### Meta / Setup

Skills para instalação, continuidade cross-IDE e navegação do catálogo.

**Skills do grupo (3):**
`ideiaos-catalog` · `ideiaos-setup` · `cursor-continuation`

**Sequência recomendada — cenário: entrar em projeto com IdeiaOS em máquina nova**

```
1. /ideiaos-setup        → diagnóstico das 5 camadas → aplicar gaps → confirmar setup completo
2. /ideiaos-catalog      → listar módulos disponíveis vs instalados; instalar sob demanda
3. /cursor-continuation  → retomar contexto do Cursor: plans, memória Claude, STATE.md, git log
```

**Anti-patterns / quando NÃO usar:**

- `/ideiaos-setup` — projeto já verificado recentemente; rode apenas quando suspeitar de gap.
- `/ideiaos-setup` — quando o usuário pediu uma tarefa específica; não interrompa para sugerir setup.
- `/ideiaos-catalog` — quando já sabe qual módulo quer e como instalar; `cp source/skills/<nome>/SKILL.md ~/.claude/skills/<nome>/SKILL.md` diretamente.
- `/cursor-continuation` — quando não há histórico no Cursor (projeto só no Claude Code); o fluxo de Fase 4 não encontrará nada e os passos 1-3 são suficientes sem a skill.

**Exemplo canônico:**

> Máquina nova, clone do repositório `ideiapartner`:
>
> 1. `/ideiaos-setup` → "Detectado: IDEIAOS.md ausente, hooks não registrados, 3/10 skills de design instaladas." → `bash ~/dev/IdeiaOS/setup.sh --project-only --lovable $PWD`. → output: "Setup IdeiaOS completo."
> 2. `/ideiaos-catalog --kind skill --status available` → lista 12 skills disponíveis não instaladas. Instala `skill-motion` e `skill-deep-research` sob demanda.
> 3. `/cursor-continuation` → "Fase 07 em execução, 07-01 completo, último commit `5cf37d4`, plano Cursor: 2 todos pendentes (07-03)."

---

## Mapa de Redundância

| Skill A | Skill B | Sobreposição | Recomendação |
|---------|---------|-------------|--------------|
| `design` | `banner-design` | `design` tem banner embutido como sub-skill (`references/banner-sizes-and-styles.md`); `banner-design` é skill standalone com o mesmo workflow | Esclarecer escopo: usar `design` como orquestrador; `banner-design` standalone quando o projeto não tem a suíte completa instalada |
| `design` | `brand` | `design` roteia para `brand` como sub-skill externa; `brand` existe standalone | Manter ambas: `brand` standalone para projetos com apenas identidade visual; `design` orquestra quando há logo + CIP + slides juntos |
| `design` | `design-system` | `design` roteia para `design-system` como sub-skill; `design-system` tem token architecture completo (OKLCH, scripts, slide system) | Manter ambas: `design-system` é profunda (scripts, CSVs, slide strategies); `design` é entry point de roteamento |
| `design` | `slides` | `design` tem slides embutido (`references/slides-create.md`); `slides` é skill standalone (claudekit) | Esclarecer escopo: `design` para apresentações dentro de pacote de marca; `slides` standalone quando projeto só precisa de apresentações |
| `design-system` | `slides` | `design-system` tem slide system completo com BM25 search, CSVs de estratégia e `search-slides.py`; `slides` (claudekit) também cobre criação de apresentações HTML | Fundir ou esclarecer: o slide system do `design-system` é mais robusto (CSVs, contextual decision flow); `slides` é mais simples. Candidato a aposentar `slides` standalone em favor do subsistema do `design-system` |
| `design` | `ui-styling` | `design` roteia para `ui-styling` (shadcn+Tailwind) como sub-skill; `ui-styling` existe standalone | Manter ambas: `ui-styling` é usada diretamente por devs sem precisar do `design` completo |
| `codebase-onboarding` | `code-tour` | Ambas mapeiam código; overlap no "traçar 1 fluxo end-to-end" do `codebase-onboarding` (Passo 3) | Manter ambas com escopo distinto (documentado nos dois SKILL.md): `codebase-onboarding` = visão geral do projeto; `code-tour` = detalhe de 1 fluxo (arquivo:linha) |
| `instinct-status` | `recall-learnings` | `recall-learnings` lê instincts (Passo 6) como parte do seu pipeline; `instinct-status` é UI dedicada para o mesmo banco | Manter ambas: `instinct-status` é visualização interativa (barras de confidence); `recall-learnings` faz leitura automática silenciosa como pré-condição |
| `extract-learnings` | `evolve` | Ambas finalizam aprendizado; `extract-learnings` → `docs/learnings/`; `evolve` → `source/rules/` e vault Obsidian. O SKILL.md do `extract-learnings` descreve a cadeia: instincts maduros → `/evolve` → vault/rules, diferenciando o papel de cada uma | Manter ambas: escopo diferente (repositório vs global); a cadeia `extract-learnings → evolve` é intencional |
| `frontend-visual-loop` | `web-quality` | Ambas rodam sobre Chrome DevTools MCP; `frontend-visual-loop` = visual subjetivo (screenshot + critique); `web-quality` = métricas objetivas (Lighthouse, CWV, WCAG) | Manter ambas: scopes distintos e complementares. `frontend-visual-loop` é *during* o trabalho; `web-quality` é auditoria programática de números |
| `accessibility` | `web-quality` | `web-quality` inclui WCAG 2.1 como 1 dos 3 eixos (Lighthouse a11y); `accessibility` orienta a *construir* acessível (HTML semântico, ARIA, keyboard nav) | Manter ambas: `accessibility` é proativo (construção); `web-quality` é reativo (medição). Não são duplicatas — são momentos diferentes do ciclo |

---

## Gaps de Documentação

### 1. `/instinct-analyze` — sem scheduler automático (gap real)

**Arquivo:** `source/skills/instinct-analyze/SKILL.md`

A skill documenta que deve rodar "ao retomar projeto", "após sessão longa", ou "quando `session_end` indicar acúmulo não-analisado" — mas não há hook nem scheduler que a invoque automaticamente. O hook `session-summary` registra `session_end` em `observations.jsonl`, mas nada aciona a análise em seguida. Isso cria um gap entre captura (automática via hooks) e destilação (manual). **Recomendação para 08-04:** criar hook `PostToolUse[session_end] → /instinct-analyze` ou documentar explicitamente que é invocação manual deliberada.

### 2. `banner-design` — referencia skills inexistentes no contexto IdeiaOS

**Arquivo:** `source/skills/banner-design/SKILL.md`

Referencia `ai-artist`, `ai-multimodal`, `chrome-devtools` e `frontend-design` como skills dependentes, mas nenhuma delas está listada em `manifests/modules.json` como módulo IdeiaOS. A skill veio do claudekit sem adaptação completa. **Recomendação:** mapear dependências reais ou marcar como "claudekit-origin — requer setup separado".

### 3. `brand` e `design` — origem claudekit sem `# SOURCE: IdeiaOS v2`

**Arquivos:** `source/skills/brand/SKILL.md`, `source/skills/design/SKILL.md`, `source/skills/design-system/SKILL.md`, `source/skills/ui-styling/SKILL.md`, `source/skills/slides/SKILL.md`, `source/skills/banner-design/SKILL.md`

Esses SKILL.md têm `name: ckm:*` no frontmatter (origem claudekit) e não têm o header `# SOURCE: IdeiaOS v2`. Diferente dos skills adaptados (que têm `# SOURCE: ECC MIT ... adapted: IdeiaOS v2`). Isso não é um bug — é consistente com a decisão de manter a origem. Mas o rastreador `build-adapters.sh` pode precisar tratar esses arquivos diferentemente. **Recomendação para 08-04:** verificar se o `build-adapters.sh` lida corretamente com `name: ckm:*`.

### 4. `frontend-visual-loop` — referencia `gsd-ui-review` (skill não existe em source/skills/)

**Arquivo:** `source/skills/frontend-visual-loop/SKILL.md`

Menciona `gsd-ui-review` como skill complementar ("audit visual 6-pilares retroativo"), mas esse módulo não está em `source/skills/` nem em `manifests/modules.json`. É uma skill planejada ou de outro repositório. **Recomendação:** adicionar ao módulos.json como `available` ou marcar como "planejado v3".

### 5. `ideiaos-catalog` — módulos.json desatualizado (60 módulos, mas Fase 07 adicionou mais)

**Arquivo:** `source/skills/ideiaos-catalog/SKILL.md`

A skill menciona 60 módulos (Fase 04), mas a Fase 05 adicionou 6 (`60→66` per STATE.md) e a Fase 07 adicionou contexts + skills eval. O catálogo pode estar desatualizado. **Recomendação:** atualizar `manifests/modules.json` para refletir o estado pós-Fase 07.
