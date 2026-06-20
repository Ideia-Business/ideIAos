# Estado do projeto — ideIAos

**Atualizado:** 2026-06-19 · **Branch:** `work` → `main` · **Sessão 2026-06-19:** validação de resíduos **5/5 COMPLETA** — itens 1–4 fechados (verify-deploy `IN_SYNC` · ENV-04 · Mac mini · nfideia spec PR [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40)); **item 5 (2 stashes) RESOLVIDO:** nfideia `stash@{0}` + ideiapartner autostash dropados (noise regenerável); ideiapartner `stash@{1}` (type-safety pass, 20 arq — 16 casts puros + 4 mudanças schema-coupled NÃO-verificáveis) **arquivado em patch git-excluded** (`~/dev/ideiapartner/.stash-archive/`, 24 KB) e dropado — não aplicado (repo Lovable, stale 3 sem, conflito em 1 arq). **PR ideIAos [#4](https://github.com/Ideia-Business/ideIAos/pull/4) MERGED** (2026-06-19, merge commit `7e4809f` — `main` consolidado v6→v10; `origin/main..origin/work=0`). · **Versão ideIAos:** v9 shipped (tag `v9.0`); v10 Lovable MCP — Fase A (v1 read-only) SHIPPED; **Fase B (sandbox) CONCLUÍDA 2026-06-18 — veredito 🔴 BLOQUEAR `publish` via MCP** (A1-lag + A2 inmensuráveis no sandbox: o MCP não expõe/gerencia gitsync GitHub). Contenção `deny=19` enforçada mid-session; a "integridade 5 alvos" da auditoria `wf_4fec3ed7-fc0` era POINT-IN-TIME e REGREDIU p/ 2/5 — **RE-REMEDIADA p/ 5/5 PERSISTIDO em 2026-06-18** (`wf_247740a6`, ver §Sessão 2026-06-18). Fases C/D PARQUEADAS-GATED. Janela fechada (assert deny=19). Fork descartável (`1d0652c4`) **deletado** pelo usuário (get_project=404). **v10 FECHADO em escopo PARCIAL** (read-only SHIPPED; write-path BLOQUEADO; sem tag) — ver `.planning/v10-MILESTONE-AUDIT.md`

## Snapshot

| Área | Status |
|------|--------|
| **Milestones v2.0–v9** | ✅ Todos shipped (tags v2.0 … v9.0) |
| **v10 Lovable MCP — Fase A** | ✅ v1 read-only SHIPPED (2026-06-18): `/lovable-mcp` + helper + harness-deny 19 tools + rule. Rollout: deny=19 em **5/5** (4 produtos + IdeiaOS) — **PERSISTIDO** após regressão 2/5 remediada 2026-06-18 (nfideia/cfoai commit na `work`; ideiapartner `settings.local.json`); ✅ toggles de painel feitos; ✅ `/lovable-mcp verify-deploy` validado e2e contra nfideia real → `IN_SYNC` (2026-06-19). **Fase A 100% entregue e validada** |
| **v10 Lovable MCP — Fase B** | ✅ CONCLUÍDA 2026-06-18 — **veredito 🔴 BLOQUEAR `publish` via MCP**. Read-only: A1-namespace=ACOPLADO + A3=PASS. Escrita (fork `1d0652c4`, janela aberta+fechada): **muro de viabilidade** — MCP não expõe/gerencia gitsync GitHub (sem connector github, `get_project` sem repo, `add_connector` negado), logo A1-lag + A2 **inmensuráveis no sandbox** → indeterminado vota BLOQUEAR. Pior-caso do A2 refutado (git pushes entram no Cloud via `developer_update`). Contenção `deny=19` **enforçada mid-session** (comprovado). Fases C/D gateadas. Janela fechada (assert deny=19). Ver `B-01-SUMMARY.md` |
| **v9 Camada de Alinhamento** | ✅ SHIPPED (tag `v9.0`) — `/grelha`, glossário `CONTEXT.md`, `ubiquitous-language`, Passo 1.5, `/aprofundar` |
| **v8 Camada de Disciplina** | ✅ `/doubt`, `operating-discipline`, `/context-engineering`, R8-09 (rules Claude×Cursor) |
| **v7 Resiliência + Spec** | ✅ Piloto `/spec` nfideia, drift-guard, branch `spec/multi-tenancy-pilot` |
| **v6 Marketing + GSD** | ✅ `/marketing`, antifragile gates, `/spec` delta-spec brownfield |
| **v5 Memória entre IDEs** | ✅ import/export hooks, branch `planning`, 3 suites verdes |
| **Branches** | ✅ `main` = `work` · `planning` — alinhados e pushed (ver `git log`; hashes voláteis não fixados aqui) |
| **idea-doctor** | ✅ 65 OK · 0 WARN · 0 FAIL (2026-06-18) — FAIL anterior era **falso-positivo** num dummy de fixture de teste (`sk-abcdEFGH…`, do `test-memory-export.sh`); `plausible_sk()` endurecido p/ rejeitar corridas sequenciais/dicionário. IdeiaOS repo limpo |
| **README sync** | ✅ 118/118 |
| **Deploy máquinas** | ✅ MacBook-Air-2 · ✅ Mac mini git-synced (autosync ativo 06-18/06-19); `ideiaos-update.sh` aceito como baixo-risco (rodar quando for usar o mini) |
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
8. **Prevenção + fechamento:** novo **check 7e** no `idea-doctor` (valida `deny>=19` por produto Lovable, **FAIL** se regredir) + teste de regressão (`tests/idea-doctor/`, 9 asserts) + wiring no CI; verificação adversarial 4 lentes (`wf_a910bea1`/`wf_455c4880`) = PASS após corrigir claims stale. **ENV-06 DESCONSIDERADO** (Ideia Chat é teste, não vai a produção). **PR [#3](https://github.com/Ideia-Business/ideIAos/pull/3)** (`work`→`main`) aberto consolidando a sessão (11 commits).

**Estado git ao fim:** IdeiaOS `work` = `origin/work` limpo (**PR #3** aberto p/ `main`); nfideia/cfoai `work` com deny+rules pushados; ideiapartner `main` intacta (contenção local); autosync ativo. **Verificação binária:** doctor **69/0/0** (5 alvos contidos via 7e), deny=19 em 5/5, teste 9/9.

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

- 🟢 **Milestone v11 — Integridade & Auditoria de Spec — TODAS as 6 ondas DONE (fechamento PARCIAL/no-tag, 2026-06-19):** plano+notas em `.planning/milestones/v11-arsenal-absorption-PLAN.md`. **W1** autosync guard-aware (`44336c5`) · **W2** CI repo-self-consistency gates + `check-source-headers` + design-suite ref resolvido (`ccb3ff0`) · **W3** SOAK gate `check-soak.sh` + surface budget + `/idea` routing eval cases EVAL-023/24/25 (`70f0cd6`) · **W4** `/spec --analyze`+`--converge` (libs `spec-grammar`/`analyze`/`converge` + tests/spec-analyze.bats 23 asserts) (`e65d0e0`) **+ hardening pós-verificação adversarial** wf_99173505 (`4011186` — corrigiu bloqueador A2-template-FP + 9 achados) · **W5** deltas LOW R2/R4/R6/R8 (`4637b1d`) · **W6** 2 ADRs (`v11-spec-kit-analyze-converge`, `v11-license-provenance-quarantine`) + SOAK heartbeat gravado. **Design por painel (wf_449a5952) + verificação adversarial (wf_99173505).** **TAG `v11.0` — SOAK 2/2 máquinas PASS (2026-06-19):** ledger `.planning/soak/v11-arsenal.log` tem MacBook-Air-2 @17:51 (`4011186`) + Mac-mini-de-Gustavo @18:30 (`2ca25df`), ambos idea_doctor+regressão PASS → **durabilidade cross-máquina GREEN**. Falta só o **span ≥1d** (ambos heartbeats de 06-19, ~39min → `0d`): gravar 1 heartbeat **≥ 2026-06-20 17:51:44** (qualquer máquina) → `check-soak.sh v11-arsenal` exit 0 → `git tag v11.0`. Nada de código pendente.

- ✅ **Lovable MCP Fase A — rollout FECHADO (2026-06-19):** teste e2e `/lovable-mcp verify-deploy` **RODADO contra nfideia real** → verdict binário **`IN_SYNC`** (`CLOUD_SHA latest_commit_sha=3921f440a44eed620de6e60d3832f5c16f1022b8` == `origin/main`); resolver de escopo `in:todos` (projeto na pasta canônica "Grupo Ideia"); só tools read-only (`get_me`/`list_projects`/`get_project`); repo não-shallow. Toggles de painel já feitos; deny=19 **PERSISTIDO em 5/5** (regressão 2/5 remediada 2026-06-18, `wf_247740a6`). Fase A 100% operacional e validada end-to-end.
- ✅ **Fase B (sandbox) CONCLUÍDA — veredito 🔴 BLOQUEAR `publish`.** Read-only (A1-namespace ACOPLADO + A3 PASS) + escrita ao vivo (fork descartável, janela `deny→ask` aberta+fechada). Muro de viabilidade: o MCP não tem superfície p/ gitsync GitHub → A1-lag + A2 inmensuráveis no sandbox → bloqueio conservador. Fases C/D gateadas até medir A2 fora do MCP (gitsync manual na UI). Fork descartável **deletado pelo usuário** (confirmado get_project=404) — zero resíduo na conta Lovable.
- ✅ **Segurança (ENV-06) — DESCONSIDERADO (decisão do usuário, 2026-06-18):** o Ideia Chat é um **teste e NÃO vai a produção** → o `IDEIA_CHAT_SYSADMIN_PASSWORD` no histórico de `origin/main` do ideiapartner é inócuo; rotação dispensada. _Reabrir SÓ se o Ideia Chat for promovido a produção: aí rotacionar antes de ativar `FEATURE_IDEIA_CHAT_PROVISIONING_ENABLED`._
- ✅ **OpenRouter (ENV-04) — FECHADO (2026-06-19, decisão do usuário):** revogação da chave antiga confirmada/dispensada no painel. Sem ação pendente.
- ✅ **Stashes — RESOLVIDO (2026-06-19):** nfideia `stash@{0}` + ideiapartner autostash dropados (noise regenerável); ideiapartner `stash@{1}` (type-safety pass) revisado e **arquivado** em patch git-excluded (`~/dev/ideiapartner/.stash-archive/`, 24 KB) + dropado — não aplicado (repo Lovable, stale 3 sem, 4 mudanças schema-coupled não-verificáveis, conflito em 1 arq). Ambas as pilhas vazias.
- ✅ **Higiene de memória Claude — RESOLVIDO (2026-06-18):** o FAIL do `idea-doctor` (seção 7) era **falso-positivo** num dummy de fixture (`OPENAI_API_KEY=sk-abcdEFGH…`, do `test-memory-export.sh`); varredura exaustiva confirmou **zero secret real** comprometido (só anon keys Supabase públicas-por-design + tokens de sessão expirados em transcripts locais). Fix durável: `plausible_sk()` rejeita corridas sequenciais. Doctor verde 65/0/0.
- ✅ **nfideia spec PR — RESOLVIDO (2026-06-19):** specs do piloto portadas p/ `main` via **PR limpo [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40)** (`spec/pilot-port`, cherry-pick doc-only sobre a main atual, 6 arquivos 100% em `specs/`, zero código). Branch stale `spec/multi-tenancy-pilot` (71 atrás) **não** foi arrastada. Achado: o `fix(nfse-retry-stuck)` da branch original **já está na main** (não-órfão); a metodologia `/spec` já é viva na main (`onda1-honorarios`). Autosync pausado/religado durante a cirurgia. **PR #40 MERGED (2026-06-19).**
- **gsd-browser:** monitorar upstream (ainda não publicado).
- **DeepSeek V4 Pro:** decisão adiada — habilitar nos produtos (fora do escopo IdeiaOS); ver handoff sessão consultiva 2026-06-16.
- ✅ **Mac mini — FECHADO como baixo-risco (2026-06-19, decisão do usuário):** git-synced confirmado (autosync `Mac-mini-de-Gustavo` ativo 06-18 12h→18h + sessão 06-19 07:53); `main` em dia lá. Rodar `ideiaos-update.sh` no mini só quando for usá-lo (aplica overlay de patches no install local; `versions.lock` já protegido repo-wide).

## Fonte de verdade

- Operacional curto prazo: este arquivo + `docs/CONTINUATION_HANDOFF.md`
- Médio/longo prazo: `.planning/*` no branch `planning`
- Especificação canônica: `docs/IDEIAOS.md`
