# Estado do projeto — ideIAos

**Atualizado:** 2026-06-18 · **Branch:** `work` → `main` · **Versão ideIAos:** v9 shipped (tag `v9.0`); v10 Lovable MCP — Fase A (v1 read-only) SHIPPED; **Fase B (sandbox) CONCLUÍDA 2026-06-18 — veredito 🔴 BLOQUEAR `publish` via MCP** (A1-lag + A2 inmensuráveis no sandbox: o MCP não expõe/gerencia gitsync GitHub). Contenção `deny=19` enforçada mid-session; a "integridade 5 alvos" da auditoria `wf_4fec3ed7-fc0` era POINT-IN-TIME e REGREDIU p/ 2/5 — **RE-REMEDIADA p/ 5/5 PERSISTIDO em 2026-06-18** (`wf_247740a6`, ver §Sessão 2026-06-18). Fases C/D PARQUEADAS-GATED. Janela fechada (assert deny=19). Fork descartável (`1d0652c4`) **deletado** pelo usuário (get_project=404). **v10 FECHADO em escopo PARCIAL** (read-only SHIPPED; write-path BLOQUEADO; sem tag) — ver `.planning/v10-MILESTONE-AUDIT.md`

## Snapshot

| Área | Status |
|------|--------|
| **Milestones v2.0–v9** | ✅ Todos shipped (tags v2.0 … v9.0) |
| **v10 Lovable MCP — Fase A** | ✅ v1 read-only SHIPPED (2026-06-18): `/lovable-mcp` + helper + harness-deny 19 tools + rule. Rollout: deny=19 em **5/5** (4 produtos + IdeiaOS) — **PERSISTIDO** após regressão 2/5 remediada 2026-06-18 (nfideia/cfoai commit na `work`; ideiapartner `settings.local.json`); ✅ toggles de painel feitos; ⏳ resta só rodar `/lovable-mcp verify-deploy` num produto real |
| **v10 Lovable MCP — Fase B** | ✅ CONCLUÍDA 2026-06-18 — **veredito 🔴 BLOQUEAR `publish` via MCP**. Read-only: A1-namespace=ACOPLADO + A3=PASS. Escrita (fork `1d0652c4`, janela aberta+fechada): **muro de viabilidade** — MCP não expõe/gerencia gitsync GitHub (sem connector github, `get_project` sem repo, `add_connector` negado), logo A1-lag + A2 **inmensuráveis no sandbox** → indeterminado vota BLOQUEAR. Pior-caso do A2 refutado (git pushes entram no Cloud via `developer_update`). Contenção `deny=19` **enforçada mid-session** (comprovado). Fases C/D gateadas. Janela fechada (assert deny=19). Ver `B-01-SUMMARY.md` |
| **v9 Camada de Alinhamento** | ✅ SHIPPED (tag `v9.0`) — `/grelha`, glossário `CONTEXT.md`, `ubiquitous-language`, Passo 1.5, `/aprofundar` |
| **v8 Camada de Disciplina** | ✅ `/doubt`, `operating-discipline`, `/context-engineering`, R8-09 (rules Claude×Cursor) |
| **v7 Resiliência + Spec** | ✅ Piloto `/spec` nfideia, drift-guard, branch `spec/multi-tenancy-pilot` |
| **v6 Marketing + GSD** | ✅ `/marketing`, antifragile gates, `/spec` delta-spec brownfield |
| **v5 Memória entre IDEs** | ✅ import/export hooks, branch `planning`, 3 suites verdes |
| **Branches** | ✅ `main` = `work` · `planning` — alinhados e pushed (ver `git log`; hashes voláteis não fixados aqui) |
| **idea-doctor** | ✅ 65 OK · 0 WARN · 0 FAIL (2026-06-18) — FAIL anterior era **falso-positivo** num dummy de fixture de teste (`sk-abcdEFGH…`, do `test-memory-export.sh`); `plausible_sk()` endurecido p/ rejeitar corridas sequenciais/dicionário. IdeiaOS repo limpo |
| **README sync** | ✅ 112/112 |
| **Deploy máquinas** | ✅ MacBook-Air-2 · ⚠️ Mac mini confirmar (`ideiaos-update.sh`) |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` § Próximo passo |

## Sessão 2026-06-18 — remediação doctor + incidente autosync + housekeeping produtos

Sessão de **manutenção/remediação** (não altera o milestone v10). Disparada por `ideiaos-update.sh` → `idea-doctor` deu FAIL de secret.

1. **Scanner de secrets endurecido** (`scripts/idea-doctor.sh:225`) — o FAIL era **falso-positivo** num dummy de fixture (`sk-abcdEFGH1234…` do `test-memory-export.sh`). `plausible_sk()` agora rejeita corridas sequenciais/dicionário (`abcdefgh`, `0123456789`, `qwerty`). Fix **durável na heurística**, não caça-transcripts (o "observer effect" propaga o dummy ao auditá-lo). Doctor → **65 OK / 0 / 0**.
2. **Incidente autosync × cirurgia git** — o daemon correu em paralelo às operações multi-repo: entregou o IdeiaOS sozinho, **bloqueou** o push do nfideia (clone defasado) e **contaminou** uma branch do ideiapartner (varreu `package-lock.json` + `CONTINUATION_HANDOFF.md` com marcadores de conflito). Com autorização do usuário: autosync **pausado** (`bootout`) → repos reconciliados → autosync **religado** (`bootstrap`, status=0).
3. **Housekeeping produtos:** nfideia `.env` **untrackeado** + push (`94fffd05`, branch `work` — Lovable nunca na main); ideiapartner branch suja **removida** (local+remote), de volta na `main` `d0dc883c` (split público/secret do `.env` preservado por design).
4. **2 learnings extraídos** → memória + vault: `secret-scanner-observer-effect`, `autosync-races-ai-git-surgery`.

### Gap-closure audit (2026-06-18, wf_247740a6 — 6 auditores read-only)
5. **Regressão de segurança HIGH achada e REMEDIADA:** a contenção Lovable MCP (`deny=19`) estava só em **2/5** alvos (lapidai+IdeiaOS) — os blocos que a sessão de rollout deixou **uncommitted na main** de nfideia/cfoai se perderam (regressão silenciosa). Reaplicado e **PERSISTIDO**: nfideia `e43f35f5` + cfoai-grupori `cdfa8d6` (commit na branch `work` + push); ideiapartner via `settings.local.json` (local, `.claude` gitignored lá). Agora **5/5** (deny=19, revalidado binário). 3ª learning extraída: `uncommitted-security-config-ephemeral`.
6. **Housekeeping rules (PRG-03):** materializadas as 8 `.claude/rules/ideiaos-common-*.md` + `.cursor/rules` nos 3 produtos (paridade com lapidai). Gap de propagação em si = já fechado em código (66598c1); memória `propagate-rules-gap` corrigida de PENDENTE→RESOLVIDO.
7. **Doc/memória stale corrigidas:** item "Jarvis/iCloud secrets" encerrado no handoff; memória v10 reconciliada (4-produtos→2/5→5/5). **`.env` ideiapartner confirmado SEGURO** (3 vars públicas; NÃO untrack — untrack causou SEV-1 antes). Itens user-decision (rotação de secrets em histórico, stashes) deixados para você.

**Estado git ao fim:** IdeiaOS `work` limpo; nfideia/cfoai `work` com deny+rules pushados; ideiapartner `main` intacta (contenção local); autosync religado (status=0). **Verificação binária:** doctor 65/0/0, deny=19 em 5/5, guard `idea-doctor.sh:225`.

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

- ⏳ **AÇÃO DO USUÁRIO — rollout Lovable MCP Fase A (residual):** os toggles de painel já estão feitos (usuário deixou só **Grupo Ideia - Dev** `2NHPnABxF0jdSX3qVLCw` no alcance, satisfazendo o Gate 3 da Fase B). **Resta só** rodar `/lovable-mcp verify-deploy` de dentro de um produto real (ex.: nfideia) como teste end-to-end. _Lado-agente: deny=19 **PERSISTIDO em 5/5** (após regressão 2/5 remediada 2026-06-18, `wf_247740a6` — ver §Sessão 2026-06-18)._
- ✅ **Fase B (sandbox) CONCLUÍDA — veredito 🔴 BLOQUEAR `publish`.** Read-only (A1-namespace ACOPLADO + A3 PASS) + escrita ao vivo (fork descartável, janela `deny→ask` aberta+fechada). Muro de viabilidade: o MCP não tem superfície p/ gitsync GitHub → A1-lag + A2 inmensuráveis no sandbox → bloqueio conservador. Fases C/D gateadas até medir A2 fora do MCP (gitsync manual na UI). Fork descartável **deletado pelo usuário** (confirmado get_project=404) — zero resíduo na conta Lovable.
- ⚠️ **Segurança (ENV-06) — AÇÃO DO USUÁRIO:** `IDEIA_CHAT_SYSADMIN_PASSWORD` ainda LIVE no histórico de `origin/main` do ideiapartner — **rotacionar ANTES** de ativar `FEATURE_IDEIA_CHAT_PROVISIONING_ENABLED` (aceitável só enquanto o Ideia Chat dessa senha não for a produção). OpenRouter (ENV-04): confirmar no painel que a chave já rotacionada foi revogada no provedor.
- **Stashes (revisar antes de dropar):** nfideia `stash@{0}` (handoff trivial, regenerável); ideiapartner `stash@{1}` (type-safety pass real, ~20 arquivos — **NÃO** dropar sem revisar).
- ✅ **Higiene de memória Claude — RESOLVIDO (2026-06-18):** o FAIL do `idea-doctor` (seção 7) era **falso-positivo** num dummy de fixture (`OPENAI_API_KEY=sk-abcdEFGH…`, do `test-memory-export.sh`); varredura exaustiva confirmou **zero secret real** comprometido (só anon keys Supabase públicas-por-design + tokens de sessão expirados em transcripts locais). Fix durável: `plausible_sk()` rejeita corridas sequenciais. Doctor verde 65/0/0.
- **nfideia** (`spec/multi-tenancy-pilot`): 2 specs vivas + `PILOT-BACKLOG.md` — PR/merge quando conveniente.
- **gsd-browser:** monitorar upstream (ainda não publicado).
- **DeepSeek V4 Pro:** decisão adiada — habilitar nos produtos (fora do escopo IdeiaOS); ver handoff sessão consultiva 2026-06-16.
- **Mac mini:** `git pull && bash scripts/ideiaos-update.sh` — confirmar quando conveniente.

## Fonte de verdade

- Operacional curto prazo: este arquivo + `docs/CONTINUATION_HANDOFF.md`
- Médio/longo prazo: `.planning/*` no branch `planning`
- Especificação canônica: `docs/IDEIAOS.md`
