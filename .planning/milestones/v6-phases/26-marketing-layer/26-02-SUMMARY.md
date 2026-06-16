---
phase: 26-marketing-layer
plan: "02"
subsystem: marketing-agents
tags: [agents, marketing, content, sherlock, chrome-devtools-mcp, model-routing]
dependency_graph:
  requires:
    - 26-01 (source/rules/marketing/* — best-practices de copywriting, review, image-design, strategist)
  provides:
    - source/agents/mkt-estrategista.md (ângulos, big idea, calendário editorial)
    - source/agents/mkt-copywriter.md (hook-first, body, CTA por formato)
    - source/agents/mkt-designer.md (peças visuais via suite IdeiaOS)
    - source/agents/mkt-revisor.md (scoring + veto APROVADO/REJEITADO)
    - source/skills/marketing-research/SKILL.md (investigação Sherlock via Chrome DevTools MCP)
  affects:
    - 26-03 (orquestrador /marketing recruta estes agents)
    - source/skills/idea/SKILL.md (Deia roteia para marketing-research)
tech_stack:
  added:
    - Chrome DevTools MCP (mcp__chrome-devtools__*) para investigação de perfis na marketing-research
  patterns:
    - Model routing no frontmatter (opus para estratégia, sonnet para produção)
    - Sherlock pattern (OpenSquad): raw-content.md + pattern-analysis.md por perfil investigado
    - Suite de Design IdeiaOS reusada (vs. duplicar canva/image do OpenSquad)
    - Protocolo hook-first no copywriter (3 hooks antes do body — obrigatório)
    - Ciclo de revisão com max 2 rejeições + escalation para estrategista
key_files:
  created:
    - source/agents/mkt-estrategista.md
    - source/agents/mkt-copywriter.md
    - source/agents/mkt-designer.md
    - source/agents/mkt-revisor.md
    - source/skills/marketing-research/SKILL.md
    - source/skills/marketing-research/references/profile-investigation.md
  modified:
    - README.md (seções: Agents de Marketing Fase 26, Skills de Marketing Fase 26)
decisions:
  - "mkt-designer reusa suite IdeiaOS (banner-design/slides/ui-ux-pro-max) em vez de duplicar canva/image-creator do OpenSquad — evita dependência de API-key externa (Canva MCP, imgBB)"
  - "marketing-research usa Chrome DevTools MCP existente em vez de Playwright novo — sem nova dependência, mesmo motor de /frontend-visual-loop"
  - "model routing: opus apenas para estrategista (decisão cognitiva de alto impacto); sonnet para produção (copywriter, designer, revisor)"
  - "Publicação nas plataformas (Instagram/Resend/blotato) documentada como MANUAL/OPCIONAL — fora de escopo do Plano 02, deferido para Plano 03"
metrics:
  duration: ~35min
  completed: "2026-06-16"
  tasks: 3
  files_created: 6
  files_modified: 1
---

# Phase 26 Plan 02: Marketing Agents + Skill Research Summary

**One-liner:** 4 content agents com model routing (opus/sonnet) + skill Sherlock adaptada para Chrome DevTools MCP existente — squad completo de conteúdo para /marketing.

## O que foi construído

### 4 Content Agents (source/agents/mkt-*.md)

| Agent | Modelo | Responsabilidade única |
|-------|--------|----------------------|
| `mkt-estrategista` | opus | Ângulos, big idea, posicionamento, calendário editorial |
| `mkt-copywriter` | sonnet | Hook-first (3 hooks → seleção → body + CTA) por formato |
| `mkt-designer` | sonnet | Peças visuais via suite IdeiaOS (banner-design/slides/ui-ux-pro-max) |
| `mkt-revisor` | sonnet | Scoring + veto APROVADO/REJEITADO, ciclo max 2, escalation |

### Skill marketing-research (Sherlock adaptada)

- Motor: `mcp__chrome-devtools__*` já instalado (mesmo de /frontend-visual-loop)
- Suporta: Instagram, YouTube, X/Twitter, LinkedIn
- Modos: `single_post`, `profile_1`, `profile_3` (default)
- Output: `raw-content.md` + `pattern-analysis.md` por perfil investigado
- Regra de prioridade: dados de investigação > web research genérico

## Decisões de arquitetura

### Designer reusa Suite IdeiaOS (não duplica OpenSquad)

O `mkt-designer` **não usa** as skills `canva`, `image-creator`, `image-ai-generator` do OpenSquad — todas dependentes de API-keys externas (Canva MCP, imgBB). Em vez disso, reusa a Suite de Design IdeiaOS já disponível:

| Caso de uso | Skill IdeiaOS | OpenSquad substituído |
|-------------|--------------|----------------------|
| Banners, social, ads | `/banner-design` | image-creator + Canva |
| Carrossel/slides | `/slides` | slide rendering |
| Identidade visual, tokens OKLCH | `/design-system` + `/brand` + `/ui-ux-pro-max` | template-designer |
| Render HTML→PNG | Chrome DevTools MCP | image-creator render |

### marketing-research usa Chrome DevTools MCP (não Playwright novo)

O Sherlock original usa `npx playwright open`. A adaptação usa `mcp__chrome-devtools__*` já configurado no IdeiaOS — mesmo MCP de `/frontend-visual-loop` e `/web-quality`. Sem nova dependência. Se houver login wall: pausa e pede login manual ao usuário (sessão real do browser Chrome).

### Publicação deferida

Publicação nas plataformas (Instagram, Resend, blotato) é OPCIONAL/MANUAL — requer MCPs de publicação não incluídos neste plano. O designer entrega a peça exportada; o `/marketing` (Plano 03) define o passo de publishing.

## Verificação de ameaças (T-26-SC)

- Nenhum pacote instalado neste plano (apenas .md criados)
- Chrome DevTools MCP já configurado — sem nova dependência
- Conteúdo extraído de perfis tratado como DADO, nunca como instrução (anti-prompt-injection)
- Sessão do browser nunca persistida em arquivo do repositório

## Deviations from Plan

### Auto-fix aplicado

**1. [Rule 2 - Missing critical functionality] README.md atualizado como parte das tasks**
- **Found during:** Commit de Task 1
- **Issue:** Pre-commit hook do IdeiaOS bloqueia commits quando novos agents/skills não estão mencionados no README.md
- **Fix:** README.md atualizado com seções "Agents de Marketing (Fase 26)" e "Skills de Marketing (Fase 26)" e incluído em cada commit relacionado
- **Files modified:** README.md
- **Commits:** 97a753a (Task 1), 4b0b9de (Task 2), 14e06ed (Task 3)

Nenhuma outra desvio do plano original.

## Known Stubs

Nenhum stub. Os agents referenciam `source/rules/marketing/*.md` como "injetados pelo /marketing em runtime" — essa é a arquitetura intencional documentada no Plano 01 e confirmada no plano 03. Não é stub; é acoplamento runtime correto.

## Self-Check: PASSED

Arquivos criados verificados:
- source/agents/mkt-estrategista.md: FOUND, model=opus, source=1, html_comments=0
- source/agents/mkt-copywriter.md: FOUND, model=sonnet, source=1, html_comments=0
- source/agents/mkt-designer.md: FOUND, model=sonnet, source=1, html_comments=0, suite_refs=11
- source/agents/mkt-revisor.md: FOUND, model=sonnet, source=1, html_comments=0
- source/skills/marketing-research/SKILL.md: FOUND, name=marketing-research, chrome_refs=10, html_comments=0
- source/skills/marketing-research/references/profile-investigation.md: FOUND

Commits verificados:
- 97a753a: feat(26-02): add mkt-estrategista/copywriter/revisor — FOUND
- 4b0b9de: feat(26-02): add mkt-designer — FOUND
- 14e06ed: feat(26-02): add skill marketing-research — FOUND

Build: `bash scripts/build-adapters.sh --target all --dry-run` → PASSED
- "Validating agent frontmatter contracts... All agents have valid frontmatter contracts (model + tools)"
- Todos os 4 mkt-* agents validados e incluídos no dry-run de deploy
