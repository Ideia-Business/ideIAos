# Estado do projeto — ideIAos

**Atualizado:** 2026-06-18 · **Branch:** `work` → `main` · **Versão ideIAos:** v9 shipped (tag `v9.0`); v10 Lovable MCP — Fase A (v1 read-only) SHIPPED; **Fase B (sandbox) CONCLUÍDA 2026-06-18 — veredito 🔴 BLOQUEAR `publish` via MCP** (A1-lag + A2 inmensuráveis no sandbox: o MCP não expõe/gerencia gitsync GitHub). Contenção `deny=19` confirmada enforçada mid-session (íntegra nos 5 alvos — auditada `wf_4fec3ed7-fc0`). Fases C/D PARQUEADAS-GATED. Janela fechada (assert deny=19). Fork descartável (`1d0652c4`) **deletado** pelo usuário (get_project=404). **v10 FECHADO em escopo PARCIAL** (read-only SHIPPED; write-path BLOQUEADO; sem tag) — ver `.planning/v10-MILESTONE-AUDIT.md`

## Snapshot

| Área | Status |
|------|--------|
| **Milestones v2.0–v9** | ✅ Todos shipped (tags v2.0 … v9.0) |
| **v10 Lovable MCP — Fase A** | ✅ v1 read-only SHIPPED (2026-06-18): `/lovable-mcp` + helper + harness-deny 19 tools + rule. Rollout: deny aplicado nos 4 produtos + no próprio IdeiaOS (deny=19); ✅ toggles de painel feitos (só 1 workspace no alcance); ⏳ resta só rodar `/lovable-mcp verify-deploy` num produto real |
| **v10 Lovable MCP — Fase B** | ✅ CONCLUÍDA 2026-06-18 — **veredito 🔴 BLOQUEAR `publish` via MCP**. Read-only: A1-namespace=ACOPLADO + A3=PASS. Escrita (fork `1d0652c4`, janela aberta+fechada): **muro de viabilidade** — MCP não expõe/gerencia gitsync GitHub (sem connector github, `get_project` sem repo, `add_connector` negado), logo A1-lag + A2 **inmensuráveis no sandbox** → indeterminado vota BLOQUEAR. Pior-caso do A2 refutado (git pushes entram no Cloud via `developer_update`). Contenção `deny=19` **enforçada mid-session** (comprovado). Fases C/D gateadas. Janela fechada (assert deny=19). Ver `B-01-SUMMARY.md` |
| **v9 Camada de Alinhamento** | ✅ SHIPPED (tag `v9.0`) — `/grelha`, glossário `CONTEXT.md`, `ubiquitous-language`, Passo 1.5, `/aprofundar` |
| **v8 Camada de Disciplina** | ✅ `/doubt`, `operating-discipline`, `/context-engineering`, R8-09 (rules Claude×Cursor) |
| **v7 Resiliência + Spec** | ✅ Piloto `/spec` nfideia, drift-guard, branch `spec/multi-tenancy-pilot` |
| **v6 Marketing + GSD** | ✅ `/marketing`, antifragile gates, `/spec` delta-spec brownfield |
| **v5 Memória entre IDEs** | ✅ import/export hooks, branch `planning`, 3 suites verdes |
| **Branches** | ✅ `main` = `work` · `planning` — alinhados e pushed (ver `git log`; hashes voláteis não fixados aqui) |
| **idea-doctor** | ⚠️ 61 OK · 1 WARN · 2 FAIL — secrets em memória Claude de **outros projetos** (Jarvis, iCloud Projects); IdeiaOS repo OK |
| **README sync** | ✅ 112/112 |
| **Deploy máquinas** | ✅ MacBook-Air-2 · ⚠️ Mac mini confirmar (`ideiaos-update.sh`) |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` § Próximo passo |

## Sessão 2026-06-16 (Cursor) — pesquisa+plano milestone v9

Sessão de **pesquisa + planejamento** do milestone **v9 — "Camada de Alinhamento"** (absorção seletiva de `mattpocock/skills`, MIT). **Nenhuma skill/código implementado** — só planejamento; tudo já commitado/pushado.

1. **Análise comparativa** — `docs/research/2026-06-16-mattpocock-skills-analise.md` (8 seções): mattpocock/skills × IdeiaOS, 3 GAPs reais (glossário de linguagem ubíqua durável; grilling colaborativo pré-plano desacoplado de fase GSD; ritual de "deepening" arquitetural), veredito por skill, encaixe do `/grill-with-docs`, orquestração da Deia, exemplo real no nfideia.
2. **Quarentena** — `security/quarantine/mattpocock-skills/` (18 arquivos, LICENSE MIT preservada, `scan-absorbed.sh` PASS/exit 0).
3. **ADR** — `docs/decisions/v9-mattpocock-skills-absorcao.md` (Aceito): absorver a TÉCNICA, não a ideologia anti-framework; `/grelha` roda SOB a Deia (gate opcional). Espelhado no Obsidian `Decisions/`.
4. **Plano GSD** — `.planning/milestones/v9-REQUIREMENTS.md` (R9-01..R9-07) + `v9-ROADMAP.md` (Fases A–F) + `v9-IMPLEMENTATION-PLAN.md` (grafo de dependências, esforço, gates, DoD, Fase G could-haves) + `v9-phases/{A..F}-*/*-01-PLAN.md` (PLAN por fase, formato GSD).
5. **Recomendação** — skill `/grelha` (alias `/grill`) = grilling pré-plano + glossário `CONTEXT.md` + ADR inline; rule nova `ubiquitous-language`; gate opcional Passo 1.5 na Deia (`source/skills/idea/SKILL.md`); SHOULD: `/improve-architecture` (deepening). Padrão de absorção = igual v8.

**Estado git ao fim:** `main` == `work`; `planning` pushado; working tree limpo (ver `git log`).

## Sessão 2026-06-16 (Cursor) — fechamento final

1. **Encerramento + docs** — handoff/STATE sincronizados; commits `a834544` → `d4d5887` (autosync Mac mini).
2. **Alinhamento de branches** — `main` = `work` fast-forward (23+ commits v6–v8); `planning` merge + memória v5 preservada.
3. **Commit/push (pedido do usuário)** — `fd56c8d`, `0ffd912`, `647c242` pushed em `work`/`main`/`planning`. Repo limpo @ `647c242`.
4. **Propagação** — `propagate-if-changed` rodou ao merge em `main`; setup propagado a 6 projetos `~/dev/*` (0 erros).
5. **Verificação** — README 112/112 ✅ · idea-doctor 2 FAIL (secrets Jarvis/iCloud Projects — remediação manual).

## Pendências não-bloqueantes

- ⏳ **AÇÃO DO USUÁRIO — rollout Lovable MCP Fase A (residual):** os toggles de painel já estão feitos (usuário deixou só **Grupo Ideia - Dev** `2NHPnABxF0jdSX3qVLCw` no alcance, satisfazendo o Gate 3 da Fase B). **Resta só** rodar `/lovable-mcp verify-deploy` de dentro de um produto real (ex.: nfideia) como teste end-to-end. _Lado-agente (harness-deny nos 4 produtos) feito 2026-06-18; contenção íntegra confirmada na auditoria de fechamento._
- ✅ **Fase B (sandbox) CONCLUÍDA — veredito 🔴 BLOQUEAR `publish`.** Read-only (A1-namespace ACOPLADO + A3 PASS) + escrita ao vivo (fork descartável, janela `deny→ask` aberta+fechada). Muro de viabilidade: o MCP não tem superfície p/ gitsync GitHub → A1-lag + A2 inmensuráveis no sandbox → bloqueio conservador. Fases C/D gateadas até medir A2 fora do MCP (gitsync manual na UI). Fork descartável **deletado pelo usuário** (confirmado get_project=404) — zero resíduo na conta Lovable.
- ⏳ **Rollout Fase A (residual):** rodar `/lovable-mcp verify-deploy` de dentro de um produto real como teste end-to-end (os toggles de painel já estão todos feitos — só 1 workspace no alcance).
- **Higiene de memória Claude:** inspecionar/remover secrets em sessões Jarvis e iCloud Projects (`idea-doctor` seção 7).
- **nfideia** (`spec/multi-tenancy-pilot`): 2 specs vivas + `PILOT-BACKLOG.md` — PR/merge quando conveniente.
- **gsd-browser:** monitorar upstream (ainda não publicado).
- **DeepSeek V4 Pro:** decisão adiada — habilitar nos produtos (fora do escopo IdeiaOS); ver handoff sessão consultiva 2026-06-16.
- **Mac mini:** `git pull && bash scripts/ideiaos-update.sh` — confirmar quando conveniente.

## Fonte de verdade

- Operacional curto prazo: este arquivo + `docs/CONTINUATION_HANDOFF.md`
- Médio/longo prazo: `.planning/*` no branch `planning`
- Especificação canônica: `docs/IDEIAOS.md`
