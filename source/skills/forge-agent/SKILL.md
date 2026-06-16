---
name: forge-agent
description: "Fundamenta a criação de agents e skills em pesquisa real do domínio antes de produzir spec — cita fontes verificáveis, lista anti-patterns derivados de pesquisa, justifica model routing com racional documentado. Use quando o domínio-alvo não está mapeado na codebase."
---

# SOURCE: IdeiaOS v2

# Skill: forge-agent

**Idioma:** Português brasileiro.

---

## Quando usar

- Criar um novo agent (`source/agents/`) ou nova skill (`source/skills/`) cujo domínio não está mapeado na codebase.
- Quando spec genérica produziria persona sem fundamento real (anti-pattern: agent criado sem pesquisa do domínio).
- Antes de começar qualquer agent novo — mesmo que pareça simples, o processo força verificação de anti-patterns reais e model routing consciente.

## Quando NÃO usar

- Agent/skill cujo domínio já está documentado em `docs/research/` com fontes recentes (< 90 dias).
- Ajustes incrementais em agent existente — use o agent diretamente com o prompt de contexto.
- Quando o prazo não permite os 3 ciclos de pesquisa — documente a limitação e use best-effort com 1 ciclo.

---

## Processo (4 fases)

### Fase 1 — Definir domínio e tipo

Coletar do usuário:

- **(a) Domínio-alvo** — ex.: "copywriting para LinkedIn", "geração de queries SQL seguras", "design de APIs REST para mobile".
- **(b) Tipo de artefato** — agent (tem model: e tools:, toma decisões e executa ações) ou skill (orquestra processo, não tem model: próprio).
- **(c) Contexto de uso** — quando será invocado, quem chama, qual problema resolve que nada na codebase resolve hoje.

Critério de GO para Fase 2: domínio definido em 1 frase, tipo determinado, problema de negócio claro.

### Fase 2 — Pesquisa fundamentada (delegar a /deep-research)

Delegar pesquisa iterativa (máx 3 ciclos) à skill `/deep-research` com as seguintes queries obrigatórias para o domínio recebido:

1. `"{domínio} frameworks and best practices"` — extrair: 1-2 frameworks operacionais com etapas concretas (não apenas nomes).
2. `"{domínio} mistakes to avoid anti-patterns"` — extrair: no mínimo 4 "nunca faça" com explicação de **por quê prejudica** (não lista genérica).
3. `"{domínio} quality criteria evaluation rubric"` — extrair: critérios mensuráveis de sucesso (ex.: taxa de aprovação, latência, NPS, cobertura de casos).
4. *(Opcional, se domínio envolve escolha de modelo/tool)* `"{task type} LLM model selection"` — extrair: quando usar opus vs sonnet vs haiku para este tipo de tarefa específica.

Para cada achado: **registrar fonte com URL + data**. Sem fonte verificável = achado não entra na spec.

### Fase 3 — Model routing com justificativa

Com base nos achados de pesquisa, justificar a escolha de modelo para o agent (se tipo = agent):

| Modelo | Quando usar neste domínio |
|--------|--------------------------|
| **opus** | Raciocínio estrutural de alto impacto, planejamento estratégico, auditoria de segurança, decisões com trade-offs complexos |
| **sonnet** | Implementação, revisão de código, análise, geração de conteúdo — equilíbrio custo/qualidade para volume |
| **haiku** | Tarefas leves, observação, extração de metadados, triagem — máxima velocidade e mínimo custo |

Registrar o **racional** na spec (ex.: "opus porque este agent avalia risco de segurança com impacto direto em prod"), não apenas o nome do modelo.

### Fase 4 — Produzir spec grounded

Produzir o arquivo de destino (`source/agents/<nome>.md` ou `source/skills/<nome>/SKILL.md`) com:

**Frontmatter:**
- Skills: `name:`, `description:` (sem `model:` ou `tools:`).
- Agents: `name:`, `description:`, `model:`, `tools:`.

**Header de atribuição:** `# SOURCE: IdeiaOS v2` logo após o fechamento do frontmatter.

**Seções obrigatórias derivadas da pesquisa:**
1. **Quando usar** — casos de uso reais derivados dos frameworks pesquisados.
2. **Quando NÃO usar** — exclusões explícitas (evita uso indevido).
3. **Processo** — derivado dos frameworks reais encontrados na Fase 2; não inventado.
4. **Anti-patterns** — ≥4 itens derivados da pesquisa, cada um com justificativa de por quê prejudica.
5. **Qualidade** — critérios mensuráveis extraídos da Fase 2.
6. **Fontes** — lista de URLs + datas. **Mínimo 2 fontes externas.** Sem fontes = spec não é grounded e deve ser rejeitada.

---

## Output esperado

Arquivo `source/agents/<nome>.md` ou `source/skills/<nome>/SKILL.md` com:

- Seção `## Fontes` com ≥2 entradas externas citadas (URL + data de acesso).
- Anti-patterns com justificativa derivada de pesquisa (não lista genérica copiada).
- Model routing com racional documentado para agents.
- Zero comentários HTML no arquivo (tag de abertura html-comment proibida).
- `# SOURCE: IdeiaOS v2` presente logo após o frontmatter.

---

## Anti-patterns

- **Gerar spec sem executar a Fase 2** — produz persona genérica sem ancoragem real no domínio; o agent passa no lint mas falha em produção por aplicar frameworks errados.
- **Citar fontes sem URL + data** — não auditável; impossibilita verificar se a fonte ainda é válida ou se o domínio evoluiu desde a pesquisa.
- **Copiar frameworks sem adaptar ao padrão IdeiaOS** — frontmatter faltando, SOURCE ausente, idioma misto; quebra a consistência da codebase e confunde outros agents que leem os arquivos.
- **Reutilizar anti-patterns genéricos** — "não use variáveis globais" não é um anti-pattern de domínio; anti-patterns devem derivar da pesquisa específica do domínio.
- **Pular justificativa de model routing** — listar "opus" sem explicar por quê torna a decisão opaca; na próxima atualização do agent, o model pode ser trocado sem entender o impacto.

---

## Relações

- Delega pesquisa a `/deep-research` (iterative retrieval, máx 3 ciclos).
- Produz artefato compatível com `source/agents/` ou `source/skills/` que passa em `validate_agent_contracts` (se agent).
- Resultado pode ser inspecionado por `/ideiaos-catalog`.
- Spec gerada deve ser registrada em `manifests/modules.json` (entrada manual após criação).

---

## Fontes

- Anthropic. "Build effective agents." Anthropic Documentation. Acessado em 2026-06-16. https://www.anthropic.com/engineering/building-effective-agents
- Anthropic. "Model overview — when to use which model." Anthropic Documentation. Acessado em 2026-06-16. https://docs.anthropic.com/en/docs/about-claude/models/overview
