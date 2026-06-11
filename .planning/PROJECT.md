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
