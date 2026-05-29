# IdeiaOS — Especificação do Sistema Operacional Unificado de Desenvolvimento

> **Documento canônico de design.** Quem mantém o dev-setup mantém este documento.
> Versão: 1.0 · Status: Lançado · Última atualização: 2026-05-29

---

## 1. Visão

IdeiaOS é o **Sistema Operacional de desenvolvimento** da Ideia Business. Não é um framework, não é uma ferramenta — é a camada de orquestração que combina ferramentas distintas em um sistema coerente, com um único ponto de entrada para o humano e instruções operacionais claras para qualquer IA.

### Objetivo central

Eliminar a complexidade cognitiva de operar com 50+ comandos espalhados entre Claude Code, Cursor, AIOX-Core e GSD. Substituir por **um comando** (`/idea`) que roteia para a camada certa, com fallback transparente para comandos diretos quando o usuário aprende o sistema.

### Por que existe

Antes do IdeiaOS, o dev precisava decorar:
- 5 personas AIOX e suas autoridades exclusivas
- 30+ comandos GSD (skills `/gsd-*`)
- Comandos Lovable (`/lovable-handoff`)
- Loop de aprendizado (`/recall-learnings`, `/extract-learnings`)
- Continuation cross-IDE (`/cursor-continuation`, `@claude-continuation`)
- Setup (`/dev-setup`, `@setup-checker`, `idea-setup`)

Sob pressão, o dev pulava etapas e perdia governance. O IdeiaOS resolve isso com roteamento automático + documentação de decisão clara.

---

## 2. Arquitetura — 5 camadas

```
┌─────────────────────────────────────────────────────────────┐
│                       /idea                                  │
│       (orquestrador de entrada — Skill Claude Code)         │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
       ┌───────────────────────────────────────────┐
       │  Matriz de roteamento (DECISION-MATRIX)   │
       └───────────────────────────────────────────┘
                           │
       ┌───────────┬───────┴────────┬──────────────┬──────────┐
       ▼           ▼                ▼              ▼          ▼
   ┌────────┐  ┌──────┐         ┌─────────┐   ┌───────┐  ┌──────────┐
   │  AIOX  │  │  GSD │         │ Lovable │   │ Fase A│  │Continuation│
   │  Core  │  │      │         │ Handoff │   │       │  │           │
   └────┬───┘  └──┬───┘         └────┬────┘   └───┬───┘  └─────┬─────┘
        │         │                  │            │            │
        ▼         ▼                  ▼            ▼            ▼
    Personas   Phases           docs/lovable/  learnings/  Cross-IDE
    Stories    PLAN.md          handoff        postmortems handoffs
    Gates      Atomic commits   Playbook       Memory      State
    Constitution Verify         8-block resp   Hooks
```

### Camadas

| # | Camada | Responsabilidade | Tecnologia |
|---|--------|-----------------|------------|
| 1 | **AIOX-Core** | Personas, stories, Constitution gates, governance formal | `npx aiox-core`, `.aiox-core/` |
| 2 | **GSD** | Execução goal-backward com phases, plans, atomic commits, verification | Skills `/gsd-*` (Claude Code) |
| 3 | **Lovable Handoff** | Deploy via Lovable Cloud, sync local↔remoto, modelo 8-blocos | Skill `/lovable-handoff` + templates |
| 4 | **Fase A (Learning)** | Ritual recall+extract, gate triplo, memory global | Skills `/recall-learnings`, `/extract-learnings` + hooks |
| 5 | **Continuation** | Cross-IDE handoff (Cursor↔Claude), state preservation | Skills/agents + STATE.md + CONTINUATION_HANDOFF.md |

### Princípios

1. **Camadas se complementam, não competem** — cada uma tem domínio próprio
2. **Orquestrador é transparente** — `/idea` sempre mostra o comando antes de executar
3. **Comando direto é caminho válido** — usuário avançado pula `/idea`
4. **Gates são bloqueantes** — não são sugestões, são contratos
5. **Idempotência total** — qualquer setup roda 1x ou 100x com mesmo resultado
6. **Falar a língua do humano** — sempre português brasileiro

---

## 3. Componentes instalados pelo IdeiaOS

### Componentes globais (uma vez por máquina)

| Tipo | Nome | Localização | Função |
|------|------|------------|--------|
| Skill | `/idea` | `~/.claude/skills/idea/SKILL.md` | Orquestrador IdeiaOS |
| Skill | `/dev-setup` | `~/.claude/skills/dev-setup/SKILL.md` | Audita + completa setup |
| Skill | `/cursor-continuation` | `~/.claude/skills/cursor-continuation/SKILL.md` | Cursor → Claude |
| Skill | `/lovable-handoff` | `~/.claude/skills/lovable-handoff/SKILL.md` | Deploy Lovable |
| Skill | `/recall-learnings` | `~/.claude/skills/recall-learnings/SKILL.md` | Fase A — recall |
| Skill | `/extract-learnings` | `~/.claude/skills/extract-learnings/SKILL.md` | Fase A — extract |
| Skill | `/gsd-*` (suite) | `~/.claude/skills/gsd-*` | 60+ comandos GSD (via Claude Code plugins) |
| Agent | `@claude-continuation` | `~/.cursor/agents/claude-continuation.md` | Claude → Cursor |
| Agent | `@setup-checker` | `~/.cursor/agents/setup-checker.md` | Setup audit no Cursor |
| Personas | `@dev`, `@qa`, `@pm`, `@po`, `@sm`, `@architect`, `@data-engineer`, `@ux-design-expert`, `@devops`, `@analyst`, `@aiox-master` | via AIOX-Core | Personas story-driven |
| Hook | `extract-learnings-reminder.sh` | `~/.claude/hooks/` | PostToolUse Bash — gate triplo |
| Hook | `dev-setup-detector.sh` | `~/.claude/hooks/` | SessionStart — detecta Fase A |
| Hook | `dev-setup-readme-reminder.sh` | `~/.claude/hooks/` | PostToolUse Edit/Write — README sync |
| CLI | `idea-setup` | alias em `~/.zshrc`/`~/.bashrc` | Atalho terminal |
| Engine | AIOX Core | `npx aiox-core` | Orquestrador de agentes |

### Componentes do projeto (por projeto)

| Arquivo | Localização | Função |
|---------|-------------|--------|
| `IDEIAOS.md` | raiz | Manifesto do sistema no projeto |
| `docs/ideiaos/GUIDE-HUMANS.md` | docs/ | Guia operacional para devs |
| `docs/ideiaos/GUIDE-AI.md` | docs/ | Guia operacional para IAs |
| `docs/ideiaos/DECISION-MATRIX.md` | docs/ | Tabela de roteamento canônica |
| `AGENTS.md` | raiz | Identidade do projeto + Fase A |
| `CLAUDE.md` | raiz | Instruções Claude início/fim sessão |
| `STATE.md` | raiz | Snapshot operacional curto |
| `CONTRIBUTING.md` | raiz | Onboarding de dev novo |
| `docs/CONTINUATION_HANDOFF.md` | docs/ | Próximo passo executável |
| `docs/playbook-implantacao.md` | docs/ (Lovable) | Fluxo Lovable obrigatório |
| `docs/lovable/conclusao-implantacao.md` | docs/lovable/ | Modelo 8 blocos |
| `docs/lovable/_TEMPLATE.md` | docs/lovable/ | Esqueleto handoff |
| `docs/learnings/` | docs/ | Padrões replicáveis |
| `docs/postmortems/` | docs/ | Histórias de incidentes |
| `.planning/phases/` | .planning/ | Fases GSD |
| `.planning/intel/` | .planning/ | Codebase intelligence |
| `.planning/research/` | .planning/ | Pesquisa pré-planejamento |
| `.cursor/rules/agents-md-protocol.mdc` | .cursor/rules/ | Rule alwaysApply Cursor |
| `.cursor/rules/session-continuation.mdc` | .cursor/rules/ | Rule de retomada |
| `.cursor/rules/planning-branch.mdc` | .cursor/rules/ | Convenção branch planning |
| `.aiox-ai-config.yaml` | raiz | Config providers + IdeiaOS marker |

---

## 4. Fluxo de dados

```
USUÁRIO
  │ (pedido em linguagem natural)
  ▼
/idea
  │ (classifica via matriz)
  ▼
[Pré-condição] verifica setup, GSD-readiness, Lovable detection
  │
  ▼
[Fase A automática] /recall-learnings (se ainda não rodou nesta sessão)
  │
  ▼
[Camada selecionada]
  ├── AIOX → @persona *comando
  ├── GSD  → /gsd-* skill
  ├── Lovable → /lovable-handoff
  ├── Fase A → /recall ou /extract direto
  └── Continuation → /cursor-continuation ou @claude-continuation
  │
  ▼
[Execução]
  │ (sujeita a gates: Quality, Constitution, Pre-commit, Hooks)
  ▼
[Pós-execução]
  ├── Atualizar STATE.md
  ├── Atualizar CONTINUATION_HANDOFF.md
  ├── /extract-learnings (gate triplo)
  └── Se Lovable: resposta 8 blocos
```

---

## 5. Padrões invioláveis

Estes padrões emergem de incidentes reais documentados em `docs/learnings/`. Toda IA operando no IdeiaOS deve aplicá-los.

### 5.1 Debugging em produção

| Padrão | Quando aplicar |
|--------|----------------|
| Bug persiste após fix → check deploy ANTES do código | 80%+ é deploy drift |
| Schema-first verification antes de UPDATE/INSERT | Sempre, em produção |
| Hotfixes inline (Lovable/IA externa) → sync explícito pro repo | Sempre que detectar hotfix em sistema externo |
| cTribNac com 4 dígitos = placeholder silencioso | Validação NFS-e ABRASF |

### 5.2 Operação geral

| Padrão | Quando aplicar |
|--------|----------------|
| `git pull` antes de editar | Sempre, especialmente em projeto Lovable ou com colaborador |
| Idempotência em scripts de config | Detector deve reconhecer variações equivalentes |
| Schema-first sempre antes de UPDATE/INSERT em prod | Não confiar em "deveria existir" |
| Pre-commit hook bloqueia commit sem README sync | dev-setup específico |
| Hooks > guidelines | Protocolo "obrigatório" para IA = barreira ativa, não doc passiva |

### 5.3 UX e UAT

| Padrão | Quando aplicar |
|--------|----------------|
| UAT visual antes de commitar UI | 3+ botões em row, max-w-md com Dialog, coluna nova em tabela |
| Pedir pior caso real antes de codar | Casos canônicos passam, casos reais quebram |
| Preview de transformação invisível em wizards | 3 camadas: heurística + preview ANTES→DEPOIS + toggle bypass |
| Seleção em massa em tabela paginada precisa 2 níveis | "Visíveis da página" + "Todas as N do filtro" |

---

## 6. Decisões de design

### Por que `/idea` e não vários comandos?

**Trade-off:** memorização cognitiva vs precisão.
**Decisão:** comando único reduz cognitive load. Usuário aprende comandos diretos com o tempo via output transparente do `/idea`.

### Por que manter as 5 camadas separadas em vez de fundir?

**Trade-off:** simplicidade conceitual vs flexibilidade operacional.
**Decisão:** cada camada tem domínio próprio. GSD é melhor para execução, AIOX é melhor para governance, Lovable é específico do deploy. Fundir gera tradeoffs ruins. IdeiaOS orquestra sem absorver.

### Por que Fase A é universal e não opcional?

**Trade-off:** velocidade vs aprendizado acumulado.
**Decisão:** sob pressão, dev pula extract. Sem extract, bug volta. Hook é barreira ativa para não esquecer. Custo de Fase A: 5 minutos. Custo de bug recorrente: horas.

### Por que IDEIAOS.md na raiz e não em docs/?

**Trade-off:** visibilidade vs poluição da raiz.
**Decisão:** primeira coisa que dev/IA vê é a raiz do repo. Manifesto precisa estar visível. Os 3 guias detalhados ficam em docs/ideiaos/.

### Por que skill `/idea` e não comando próprio?

**Trade-off:** integração nativa vs CLI próprio.
**Decisão:** skills do Claude Code são o ponto de entrada padrão. Reuso de infra existente (memory, hooks, settings.json). Sem necessidade de binário próprio.

---

## 7. Roadmap

### v1.0 — Lançado (2026-05-29)
- ✅ Skill `/idea` com matriz de roteamento
- ✅ Templates IDEIAOS.md, GUIDE-HUMANS.md, GUIDE-AI.md, DECISION-MATRIX.md
- ✅ Integração GSD readiness no setup.sh
- ✅ Documentação humana + IA
- ✅ Marker em `.aiox-ai-config.yaml`

### v1.1 — Planejado
- [ ] Hook `idea-router-debug` para logar roteamentos automaticamente (otimizar matriz)
- [ ] Comando `/idea status` que mostra estado de todas as 5 camadas
- [ ] Comando `/idea learn <observação>` que vira learning automaticamente
- [ ] Integração com `claude-mem` (cross-session memory) — vide [mapa-github-ai-dev-tools.md](../../../mapa-github-ai-dev-tools.md)

### v2.0 — Visão
- [ ] Visual workflow viewer (inspirado em Langflow/Flowise)
- [ ] A/B testing de rules (inspirado em `agents-md-evals`)
- [ ] Marketplace interno de skills/agents personalizados por cliente

---

## 8. Como contribuir

Mudanças no IdeiaOS seguem o ciclo:

1. Identificar gap (via learning, postmortem, ou feedback do dev)
2. Discutir em issue ou via `/gsd-discuss-phase`
3. Atualizar este `docs/IDEIAOS.md` com a mudança
4. Atualizar componentes afetados (skills, templates, setup.sh)
5. Atualizar `README.md` (barreira ativa: pre-commit bloqueia)
6. Bump de versão se mudança breaking
7. Push (via `@devops` se AIOX, direto se patch)

---

## 9. Glossário canônico

| Termo | Definição |
|-------|-----------|
| **Camada** | Uma das 5 subsidiárias do IdeiaOS (AIOX, GSD, Lovable, Fase A, Continuation) |
| **Roteamento** | Decisão automática do `/idea` sobre qual camada ativar |
| **Gate** | Verificação bloqueante (Quality, Constitution, Lint, Pre-commit) |
| **Persona** | Agente AIOX com autoridade exclusiva (@dev, @qa, @pm…) |
| **Phase** | Unidade de trabalho do GSD em `.planning/phases/` |
| **Story** | Unidade de trabalho do AIOX em `docs/stories/` |
| **Handoff** | Pacote de transferência de contexto (cross-IDE ou cross-session) |
| **Gate triplo** | Critérios Fase A: replicável + não-óbvio + estável (>1 mês) |
| **Constitution** | Regras invioláveis do AIOX (`.aiox-core/constitution.md`) |
| **Atomic commit** | Commit GSD que cobre exatamente 1 step do plano |
| **Goal-backward** | Verificação contra objetivo original, não contra checklist de tasks |
| **Idempotência** | Propriedade de rodar 1x ou N vezes com mesmo resultado |
| **Barreira ativa** | Hook ou gate que enforça comportamento (vs doc passiva que sugere) |

---

## 10. Referências externas

| Recurso | Descrição |
|---------|-----------|
| [mapa-github-ai-dev-tools.md](../../mapa-github-ai-dev-tools.md) | Mapa do ecossistema GitHub (60+ projetos) e posicionamento do IdeiaOS |
| GSD skills | Documentação inline em `~/.claude/skills/gsd-*/SKILL.md` |
| AIOX Core | https://github.com/aiox-core (npx aiox-core) |
| Lovable Cloud | https://lovable.dev |
| Claude Code | https://claude.ai/code |
| Cursor | https://cursor.sh |

---

*Documento canônico. Quem altera o IdeiaOS, altera este arquivo. Quem altera este arquivo, altera os componentes.*
