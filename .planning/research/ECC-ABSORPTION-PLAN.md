# IdeiaOS × ECC — Plano de Absorção Total e Transformação (v3)

## Contexto

O ECC (Everything Claude Code, github.com/affaan-m/ECC, **MIT** — absorção livre com atribuição) é o framework open-source mais maduro de otimização de harness para IA: 140k+ stars, 262 skills, 64 agents, rules em 18 stacks, adapters para 11 harnesses. Além do repo, analisamos os 3 guias do criador (Shorthand CC, Longform CC, Agentic Security) — as "receitas mágicas" de uso que mudaram este plano em 3 pontos:

1. **Segurança virou fase própria e pré-requisito**: vamos absorver conteúdo de terceiros em escala. O estudo ToxicSkills (Snyk, fev/2026) achou prompt injection em **36% de 3.984 skills públicas**. Todo conteúdo absorvido passa por pipeline de quarentena ANTES de instalar. CVE-2025-59536 (código executando pré-trust) e CVE-2026-21852 (`ANTHROPIC_BASE_URL` exfiltrando API key) provam que config de projeto É superfície de ataque.
2. **Contexts via `--system-prompt`** (não arquivo lido por tool): conteúdo injetado no system prompt tem autoridade maior que tool output. Aliases CLI por modo.
3. **Economia de tokens como disciplina**: model routing por agent (`model:` frontmatter), MCP→CLI+skills, regra de higiene de MCPs (<10 ativos), strategic compact.

**Decisão (com Gustavo):** absorção ampla — IdeiaOS como canivete suíço universal: todos os stacks e harnesses no catálogo, seleção por projeto. Marketplace próprio. Multi-harness por arquitetura.

## Arquitetura-alvo

```
IdeiaOS/
├── .claude-plugin/          # marketplace.json + plugin.json (IdeiaOS como plugin)
├── source/                  # fonte única de verdade
│   ├── skills/  agents/  rules/  hooks/  contexts/
├── manifests/               # catálogo de módulos (id, kind, targets, deps, installStrategy)
├── adapters/                # compiladores por harness
│   ├── claude/  cursor/  _scaffold/   # scaffold p/ codex, gemini, opencode, zed...
├── security/                # NOVO — pipeline de quarentena + baseline
│   ├── quarantine/          # conteúdo absorvido aguardando scan
│   └── scan-absorbed.sh     # greps unicode/injection + agentshield
└── scripts/build-adapters.sh
```

Princípios ECC adotados: "Profiles express user intent" · "never let the convenience layer outrun the isolation layer" · "minimum viable parallelization" · Tier 1 antes de Tier 2 (subagents e metaprompting antes de multi-agent paralelo).

## Fases

### Fase 1 — Quick Wins: Hooks de Qualidade + Memória (1 sessão)

1. **`typecheck-on-edit.sh`** (PostToolUse `.ts/.tsx`): `tsc --noEmit` — erro em segundos
2. **`console-log-guard.sh`** (PostToolUse): alerta `console.log` indo pra produção Lovable
3. **`precompact-state-save.sh`** (PreCompact): snapshot automático em `STATE.md` — ataca o "drift de retomada"
4. **`session-summary.sh`** (Stop): sessão em `~/.claude/sessions/YYYY-MM-DD-<topico>.tmp` no padrão ECC (o que funcionou com evidência / o que falhou / o que não foi tentado / próximos passos) + atualiza `CONTINUATION_HANDOFF.md`
5. **`strategic-compact.sh`** (PreToolUse, contador): sugere `/compact` manual a cada ~50 tool calls em transição de fase — compactar após exploração e antes de execução, não em ponto arbitrário

### Fase 2 — Security Baseline + Pipeline de Quarentena (1 sessão — PRÉ-REQUISITO das fases 4-6)

Do guia Agentic Security, antes de absorver qualquer coisa:

1. **Deny rules baseline** nos templates de `settings.json` (e propagado via setup):
   `Read(~/.ssh/**)`, `Read(~/.aws/**)`, `Read(**/.env*)`, `Write(~/.ssh/**)`, `Bash(curl * | bash)`, `Bash(nc *)` etc.
2. **`security/scan-absorbed.sh`** — pipeline de quarentena para TODO conteúdo de terceiros:
   - grep unicode invisível: `rg -nP '[\x{200B}\x{200C}\x{200D}\x{2060}\x{FEFF}\x{202A}-\x{202E}]'`
   - grep payloads: `rg -n '<!--|<script|data:text/html|base64,'`
   - grep comandos suspeitos: `rg -n 'curl|wget|nc |scp |ssh |enableAllProjectMcpServers|ANTHROPIC_BASE_URL'`
   - rodar **AgentShield** (github.com/affaan-m/agentshield) sobre o conteúdo
   - links externos em skills ganham guardrail anti-injection padrão (template ECC)
3. **Memory hygiene como regra**: sem secrets em memória/vault; memória de projeto separada de global (já é assim — formalizar); reset após runs não-confiáveis
4. **idea-doctor += auditoria de config**: hooks com comandos perigosos, MCPs não reconhecidos, permissões largas, secrets em texto plano (categorias AgentShield: secrets, permissions, injection, MCP risk, agent config)
5. **Kill-switch/heartbeat**: revisar autosync LaunchAgent e futuros loops background — kill de process group + dead-man switch por heartbeat (lição OpenClaw)

### Fase 3 — Arquitetura Multi-Harness + Rules Layer (2 sessões)

1. Migrar `skills/`, `agents/`, `hooks/`, `templates/` → `source/` (alias de compatibilidade p/ `setup.sh`)
2. `manifests/modules.json`: catálogo formato ECC (`id`, `kind`, `targets`, `dependencies`, `installStrategy`)
3. **Absorver `rules/` completo do ECC** via pipeline de quarentena (Fase 2): `common/` (8 arquivos) + 18 stacks
4. **Enriquecer com nossas regras** (que o ECC não tem): gotchas do vault → `rules/supabase/`, `rules/lovable/` + novas regras dos guias:
   - `rules/common/token-economy.md` — model routing, MCP→CLI+skills, modular codebase, lean codebase
   - `rules/common/mcp-hygiene.md` — 20-30 configurados, <10 ativos, <80 tools; `disabledMcpServers` por projeto
   - `rules/common/orchestration.md` — iterative retrieval (orquestrador avalia retorno de subagent, follow-up, máx 3 ciclos; passar objetivo + query); fases sequenciais com output em arquivo
5. **`scripts/build-adapters.sh`**: `source/` → `~/.claude/` e `.cursor/rules/*.mdc` — fim do drift entre IDEs; `adapters/_scaffold/` para futuros harnesses
6. **Detecção de stack por projeto**: instala só rules relevantes; catálogo completo disponível para `/idea` orientar projetos novos em qualquer stack

### Fase 4 — Catálogo ECC: Skills + Agents com Model Routing (2 sessões)

Tudo via pipeline de quarentena, com atribuição MIT:

1. **~15 agents** (universais + stack): `build-error-resolver`, `silent-failure-hunter`, `code-simplifier`, `refactor-cleaner`, `planner`, `code-explorer`, `doc-updater`, `pr-test-analyzer`, `performance-optimizer`, `security-reviewer`, `typescript-reviewer`, `react-reviewer`, `database-reviewer` (→ `rls-reviewer` com checklist do vault). Os demais 49 catalogados em `manifests/` como opcionais
2. **Model routing em todo agent** (`model:` frontmatter): haiku = busca/repetitivo/worker; sonnet = default; opus = arquitetura/segurança/falha na 1ª tentativa. Economia ~5x Haiku vs Opus
3. **~20 skills de workflow**: `tdd`, `e2e-testing`, `deep-research`, `codebase-onboarding`, `code-tour`, `database-migrations`, `api-design`, `accessibility`, `benchmark-optimization-loop`, `cost-tracking` + linguagem sob demanda
4. **Receitas dos guias viram skills IdeiaOS**: `two-instance-kickoff` (scaffold + research paralelos em projeto novo), `llms-txt` (docs LLM-otimizadas), conversão MCP→CLI (ex.: skill Supabase via CLI em vez de MCP pesado)
5. Matriz do `/idea` ganha as novas linhas; skill `/ideiaos-catalog` lista módulos disponíveis vs instalados
6. Avaliar **mgrep** (≈50% menos tokens que grep) e **LSP plugins** (typescript-lsp, pyright-lsp) como recomendação padrão

### Fase 5 — Continuous Learning v2: "Fase A Automática" (2 sessões — transformação central)

1. **Captura**: hooks PostToolUse/PreToolUse → `~/.ideiaos/observations/<projeto>/observations.jsonl` (100% das sessões, ambas IDEs). Stop hook como gatilho de avaliação (lição ECC: Stop, não UserPromptSubmit — leveza)
2. **Análise**: skill `/instinct-analyze` + agente background **haiku** → instincts atômicos (`trigger`, `confidence` 0.3–0.9, `domain`, `scope`)
3. **Armazenamento**: `~/.ideiaos/instincts/` sincronizado multi-máquina — resolve pendência "memória compartilhada entre IDEs" do roadmap
4. **`/learn`** (do ECC): extração manual mid-session quando algo não-trivial acabou de ser resolvido
5. **`/evolve`**: instincts maduros (≥0.7) → `Learnings/` no vault Obsidian (padrão replicável) ou `source/rules/` (regra de comportamento → propaga às IDEs)
6. `recall-learnings` Passo 6 lê instincts; `extract-learnings` vira curadoria do coletado

### Fase 6 — IdeiaOS como Plugin + Marketplace Privado (1 sessão)

1. `.claude-plugin/marketplace.json` + plugin.json no repo IdeiaOS
2. Máquina nova: `/plugin marketplace add Ideia-Business/IdeiaOS` → `/plugin install` — versionado, update nativo
3. `setup.sh` permanece para bootstrap de máquina (working-dirs, LaunchAgent, vault, git hooks)
4. Sub-plugins por perfil: `ideiaos-core`, `ideiaos-design-suite`, `ideiaos-lovable`

### Fase 7 — Contexts Dinâmicos + Eval Loops (1 sessão)

1. **`source/contexts/`**: dev.md ("get it working → right → clean"), review.md (só análise), research.md (explorar antes de agir)
2. **Injeção via `--system-prompt`** (autoridade de system prompt > tool output): aliases `claude-dev`, `claude-review`, `claude-research` instalados pelo setup; `/idea` recomenda o modo certo
3. **Eval roadmap (Anthropic via ECC)**: converter falhas reais em test cases — começar com 20-50 tarefas dos incidentes documentados (INC-3xx do ideiapartner, bugs NFideia) como suite de evals; pass@k para "precisa funcionar", pass^k para consistência. Integrar ao `gsd-verify-work`
4. Statusline padrão IdeiaOS (branch, contexto %, modelo, todos)

## O que ainda NÃO absorver

- **84 commands legados** — ECC migra para skills; já somos skills-first
- **Nicho sem horizonte** (defi-amm, customs-trade, harmonyos) — ficam em `manifests/` como instaláveis futuros
- **System prompt slimming** (patches no prompt do CC) — o próprio autor não usa; frágil a updates

## Ordem, esforço e dependências

| Fase | Esforço | Valor | Depende de |
|---|---|---|---|
| 1. Hooks qualidade + memória | Baixo | Alto | — |
| 2. Security baseline + quarentena | Baixo | **Crítico (pré-req)** | — |
| 3. Multi-harness + rules | Alto | Estrutural | 2 |
| 4. Catálogo ECC + model routing | Médio | Alto | 2, 3 |
| 5. Instincts CL v2 | Alto | **Transformacional** | 1 |
| 6. Plugin + marketplace | Médio | Alto | 3 |
| 7. Contexts + evals | Baixo | Médio | 3 |

Execução via GSD: `/gsd-new-milestone` "IdeiaOS v2 — Canivete Suíço Universal" com as 7 fases.

## Verificação

- F1: editar `.ts` com erro → aviso em segundos; `/compact` → snapshot no STATE.md; 50 tool calls → sugestão de compact
- F2: rodar `scan-absorbed.sh` numa skill com payload de teste → detecta; idea-doctor reporta config insegura
- F3: `build-adapters.sh` → mesma regra no CLAUDE.md e `.mdc`; projeto Python ganha rules Python, Lovable não
- F4: `/idea revise o RLS` → roteia `rls-reviewer` (rodando em sonnet); agent de busca roda em haiku
- F5: sessão normal → observations.jsonl cresce; `/instinct-status` lista; `/evolve` gera Learning no vault
- F6: máquina limpa → `/plugin marketplace add` + install → IdeiaOS funcional
- F7: `claude-review` abre sessão em modo review; suite de evals roda contra 20+ casos de incidentes reais
