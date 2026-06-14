# IdeiaOS v2 — Canivete Suíço Universal

## Visão

Transformar o IdeiaOS de um sistema de 5 camadas focado em Claude+Cursor/stack-Lovable em um **canivete suíço universal de desenvolvimento com IA**: catálogo completo de skills/agents/rules para todos os stacks, arquitetura multi-harness (fonte única → adapters), aprendizado contínuo automático (instincts), distribuição via marketplace de plugins, e segurança de agentes como infraestrutura.

Base da transformação: absorção curada do framework **ECC** (everything-claude-code, github.com/affaan-m/ECC, MIT) + receitas dos 3 guias do criador (Shorthand CC, Longform CC, Agentic Security).

## O que o IdeiaOS já tem (não regredir)

- **GSD** — execução goal-backward (superior ao /plan do ECC)
- **AIOX-Core** — agentes com personalidade
- **Lovable Handoff** — protocolo de deploy específico
- **Fase A** — learning loop (recall/extract) → será automatizado, não substituído
- **Vault Obsidian** — segundo cérebro humano+IA (vantagem sobre o homunculus do ECC)
- **Continuation** — handoff Cursor ↔ Claude
- **Autosync multi-máquina** — LaunchAgent + setup-dev-machine.sh

## Decisões travadas

<decisions>
- **Absorção ampla, não seletiva**: todos os stacks e harnesses no catálogo; seleção por projeto via manifests + detecção de stack (decisão de Gustavo, 2026-06-11)
- **Quarentena obrigatória**: NENHUM conteúdo de terceiros é instalado sem passar por `security/scan-absorbed.sh` (greps unicode/injection + AgentShield). ToxicSkills: 36% das skills públicas têm prompt injection
- **Atribuição MIT**: todo conteúdo absorvido do ECC carrega header de atribuição
- **Fonte única → adapters**: `source/` compila para cada harness via `build-adapters.sh`; nunca editar artefatos gerados diretamente
- **Skills-first**: não absorver os 84 commands legados do ECC (o próprio ECC migra para skills)
- **Instincts desaguam no vault Obsidian**: `/evolve` promove para `Learnings/` (padrão) ou `source/rules/` (comportamento) — não criar um segundo cérebro paralelo
- **setup.sh permanece** para bootstrap de máquina; plugin/marketplace distribui o conteúdo versionável
- **Contexts via `--system-prompt`** (aliases CLI), não arquivos lidos por tool — autoridade de system prompt
- **Model routing obrigatório** em agents absorvidos: haiku (busca/worker), sonnet (default), opus (arquitetura/segurança)
</decisions>

## Restrições

- Não quebrar o `setup.sh` atual durante a migração para `source/` (aliases de compatibilidade)
- Não quebrar os 4 projetos-produto que dependem do IdeiaOS hoje (ideiapartner, nfideia, cfoai-grupori, lapidai)
- README sync hook continua valendo — todo componente novo precisa estar no README
- Branch `work` para desenvolvimento; `main` para releases

## Fonte

- Plano aprovado: `.planning/research/ECC-ABSORPTION-PLAN.md` (importado de ~/.claude/plans/synchronous-conjuring-breeze.md, 2026-06-11)
- Repo ECC: https://github.com/affaan-m/ECC (MIT)
- AgentShield: https://github.com/affaan-m/agentshield


## Current Milestone: v5 — Memória compartilhada entre IDEs

**Goal:** Sincronizar a memória durável dos agentes (instincts/learnings/decisões) entre Claude Code, Cursor e outras IDEs — por projeto e por membro — usando o branch `planning` como transporte, sem nunca poluir o `main` sincronizado com a Lovable.

**Target features:**
- Store canônico de memória em `.planning/memory/` no branch `planning` (nunca `main`), com split `shared/` (commitado, time) vs `local/` (gitignored, por membro)
- Bridge de import (hook SessionStart, lado Claude) que traz a memória compartilhada do `planning` para a memória nativa da IDE
- Bridge de export via skill `/memory-sync` (explícito) que leva a memória nativa de volta ao `planning` via git plumbing (worktree como fallback)
- Ponte Cursor via `.cursor/rules/*.mdc` (`alwaysApply`), gitignored e regenerada localmente (Cursor não tem hooks nem memória em filesystem)
- 6 barreiras espelhando o precedente `versions.lock` para manter todo churn de memória fora do `main`
- Integração com o loop de aprendizado existente (3 camadas: local → shared/planning → vault Obsidian)

**Decisões travadas (v5):**
- Transporte = branch `planning` (reuso), nunca `main`; guard de pre-commit barra merge `planning`→`main`
- Export = skill-driven (`/memory-sync`), não hook automático (Claude Code não tem evento SessionEnd; Stop dispara por turno)
- Cursor bridge = `.mdc` gitignored, regenerado por máquina
- Promoção de instincts faseada: MVP export-only; `extract-learnings` Passo 4d depois; `/evolve` auto no futuro
- Pré-requisito: limpar o leak `.lovable_mem_tmp.md` do `nfideia:main` (commit 604c0a19) antes de escrever tooling de memória
- Obsidian permanece a biblioteca cross-projeto, não o transporte

**Key context:** Restrição inegociável = Lovable. `main` é o branch que a Lovable Cloud lê (Update lê só `main`, puxa automático); `/lovable-handoff` segue como único gate pro `main`. Pesquisa em `.planning/research/` (SUMMARY.md), HIGH confidence, git plumbing provado ao vivo.


## Current State (v4 shipped 2026-06-12)

- **Shipped:** v4 — Produção do plano maior. 3 fases (14-16): anti-runaway provado (1331 spawns → 3 barreiras), evals LLM fim-a-fim, marketplace 3.0.0 com install real validado, tag v4.0. Auditoria 8/9 + 1 warn aceito.
- **Shipped:** v3 — Refinamento pós-auditoria. 5 fases (09-13), 19 reqs, 15/15 gaps G-01..G-15 fechados, tag v3.0.
- **Destaque:** loop de Continuous Learning FECHADO e provado ao vivo (574 observações → 50 instincts via haiku headless); skills agora instaladas via manifesto (setup 5.21b); evals em CI (GitHub Actions) com política pass^k.
- **Auditoria:** .planning/v3-MILESTONE-AUDIT.md — PASSED 19/19 (1 blocker corrigido inline).

<details><summary>v2.0 (anterior)</summary>

## Current State (v2.0 shipped 2026-06-12)

- **Shipped:** v2.0 — Canivete Suíço Universal. 8/8 fases, 29/29 planos, tag v2.0.
- **Inventário:** 70 módulos (manifests/modules.json) · 15 agents · 34 skills · 13 hooks · 4 contexts · 22 eval cases · 3 sub-plugins (core/design-suite/lovable)
- **Distribuição:** `/plugin marketplace add Ideia-Business/IdeiaOS` (versionado) + `setup.sh` (bootstrap de máquina) + `scripts/ideiaos-update.sh` (update 1-comando)
- **Auditoria:** .planning/v2.0-MILESTONE-AUDIT.md — PASSED 8/8 integração cross-fase

## Next Milestone Goals (v3)

Fonte: `docs/v3/v3-review.md` (15 gaps priorizados) + `docs/v3/v3-roadmap.md` (6 fases candidatas).
Ordem sugerida: agent-contracts → token-optimizations → instinct-loop-automation → evals-ci → security-dx + manifest-cleanup.
Top P1: contratos model/tools nos agents (G-01/G-02) · scheduler do instinct loop (G-03) · automação dos evals (G-04).


</details>
