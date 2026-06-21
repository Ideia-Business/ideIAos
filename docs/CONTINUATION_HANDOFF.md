# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-06-19

---

## Linhagem GSD — VERDADE CANONICA

GSD neste projeto = @opengsd/get-shit-done-redux 1.1.0 (org opengsd).
NAO e gsd-pi (3.x) nem pacote da org gsd-build.
Pin revertido 3x — ver versions.lock (nota expandida) e check-versions-lock.sh.
Proibido editar gsd= no versions.lock manualmente.

---

## Sessão 2026-06-18 — remediação doctor + incidente autosync + housekeeping produtos

**Manutenção, NÃO muda o milestone v10.** A seção `## Próximo passo` (v10, abaixo) segue válida.

Disparada por `git pull && bash scripts/ideiaos-update.sh` → `idea-doctor` deu **FAIL de secret**. Tratado:

1. **Scanner endurecido (durável)** — `scripts/idea-doctor.sh:225`: o FAIL era **falso-positivo** num dummy de fixture (`OPENAI_API_KEY=sk-abcdEFGH1234…`, do `test-memory-export.sh`). `plausible_sk()` agora rejeita corridas sequenciais/dicionário. **Insight (observer effect):** redigir o transcript não converge — auditar o dummy o **propaga** para novos logs (a contagem subiu 1→4); fix certo é a heurística, não caçar transcripts. Doctor → **65 OK / 0 WARN / 0 FAIL**. Varredura exaustiva: **zero secret real** comprometido (só anon keys Supabase públicas-por-design + tokens de sessão expirados).
2. **Incidente autosync × cirurgia git** — o daemon `com.ideiaos.gitautosync` correu em paralelo às operações multi-repo: entregou o IdeiaOS sozinho (commit `wip: autosync`, conteúdo correto), **bloqueou** o push do nfideia (clone 78 atrás) e **contaminou** uma branch do ideiapartner (`add -A` varreu `package-lock.json` + um `CONTINUATION_HANDOFF.md` com marcadores de conflito). Com autorização do usuário: **pausado** (`launchctl bootout`) → repos reconciliados limpos → **religado** (`launchctl bootstrap`, status=0). _Lição: pausar autosync (com restauração garantida) antes de entrega git multi-repo assistida por IA._
3. **Housekeeping produtos (Lovable — branch, nunca main):** nfideia `.env` **untrackeado** + push (`94fffd05` em `work`; `.env` no disco preservado, só `.env.example` rastreado). ideiapartner: branch suja **removida** (local+remote), de volta na `main` `d0dc883c`; split público(`.env`)/secret(`.env.local`) preservado por design (não recebeu untrack — intencional).
4. **2 learnings extraídos** (memória global + vault): `secret-scanner-observer-effect`, `autosync-races-ai-git-surgery`.

**Notas informativas (resolvido 2026-06-19, não-pendência):** os stashes citados aqui foram triados no item 5 — nfideia `stash@{0}` e o autostash órfão do ideiapartner eram noise regenerável (dropados); o type-safety pass do ideiapartner foi arquivado em patch git-excluded e dropado (ver bloco "▶ RETOMAR AQUI"). SHAs dropados recuperáveis via reflog ~90 dias.

**2ª onda — gap-closure audit (ultracode) + prevenção:**
5. **Regressão de segurança HIGH achada e remediada:** auditoria read-only (`wf_247740a6`) achou a contenção Lovable MCP (`deny=19`) em só **2/5** alvos — os blocos uncommitted-on-main de nfideia/cfoai se perderam. Reaplicado e **PERSISTIDO em 5/5**: nfideia `e43f35f5` + cfoai `cdfa8d6` (commit na `work`) + ideiapartner `settings.local.json` (local; `.claude` gitignored lá). Verificação adversarial 4 lentes (`wf_a910bea1` + `wf_455c4880`) = PASS após corrigir claims stale de doc (MEMORY/STATE/handoff).
6. **Prevenção (a regressão passou despercebida porque nada falhava alto):** novo **check 7e** no `idea-doctor` — valida `deny>=19` por produto Lovable, **FAIL** se regredir; lê `settings.json` ou `settings.local.json`; skip gracioso sem produto. + teste de regressão (`tests/idea-doctor/test-lovable-mcp-containment.sh`, 9 asserts, prova o caminho de FALHA) + wiring no CI (`evals.yml`). 3ª learning: `uncommitted-security-config-ephemeral`.
7. **ENV-06 DESCONSIDERADO** (decisão do usuário): Ideia Chat é teste, não vai a produção → secret no histórico do ideiapartner é inócuo, rotação dispensada (memória `project-ideia-chat-test-secret-acceptable`).
8. **Housekeeping rules (PRG-03):** 8 `.claude/rules/ideiaos-common-*` materializadas em nfideia/cfoai/ideiapartner (paridade lapidai). Gap de propagação já fechado em código (`66598c1`).

**PR aberto:** [#3](https://github.com/Ideia-Business/ideIAos/pull/3) — `work`→`main`, consolida a sessão (11 commits). Revisar/mergear ou ff-merge direto (padrão IdeiaOS). Estado verificado: idea-doctor **69/0/0** (5/5 contidos) · teste 9/9 · readme-sync 116/116.

---

## Sessão 2026-06-16 (Cursor) — pesquisa + plano milestone v9 (Camada de Alinhamento)

Sessão de **pesquisa + planejamento**. **Nenhuma skill/código implementado** — só o pacote de planejamento do milestone **v9 — "Camada de Alinhamento"** (absorção seletiva de `mattpocock/skills`, MIT). Tudo já commitado/pushado nesta sessão.

**Pacote v9 entregue (artefatos para retomada rápida):**
- `docs/research/2026-06-16-mattpocock-skills-analise.md` — análise comparativa (8 seções): 3 GAPs reais (glossário de linguagem ubíqua durável; grilling colaborativo pré-plano desacoplado de fase GSD; ritual de "deepening" arquitetural), veredito por skill, encaixe do `/grill-with-docs`, orquestração da Deia, exemplo no nfideia.
- `security/quarantine/mattpocock-skills/` — material-fonte estagiado (18 arquivos, LICENSE MIT, `scan-absorbed.sh` PASS/exit 0).
- `docs/decisions/v9-mattpocock-skills-absorcao.md` — ADR (Aceito): absorver a TÉCNICA, não a ideologia anti-framework; `/grelha` roda SOB a Deia (gate opcional). Espelhado no Obsidian `Decisions/`.
- `.planning/milestones/v9-REQUIREMENTS.md` (R9-01..R9-07) · `.planning/milestones/v9-ROADMAP.md` (Fases A–F) · `.planning/milestones/v9-IMPLEMENTATION-PLAN.md` (grafo de dependências, esforço, gates, DoD, Fase G could-haves) · `.planning/milestones/v9-phases/{A..F}-*/*-01-PLAN.md` (PLAN por fase, formato GSD).

**Recomendação (resumo):** skill `/grelha` (alias `/grill`) = grilling pré-plano + glossário `CONTEXT.md` (glossário-only) + ADR inline; rule nova `ubiquitous-language`; gate opcional Passo 1.5 na Deia (`source/skills/idea/SKILL.md`); SHOULD: `/improve-architecture` (deepening). Padrão de absorção = igual v8 (addyosmani/agent-skills).

**Estado git ao fim:** `main` == `work`; `planning` pushado; working tree limpo (ver `git log`; hashes voláteis não fixados aqui).

> **Lição desta sessão:** não fixar hashes voláteis de `work`/`main` em STATE/handoff — hash volátil induz commits em cascata. Referir `git log`.

---

## ✅ v6 SHIPPED (2026-06-16) — atualização do IdeiaOS fechada

Milestone v6 "Resiliência + Marketing + GSD/OpenSpec" COMPLETO: 9 fases (23-31), 15 reqs, auditoria 15/15, tag v6.0. work=main pushed.

**Entregue:** antifragile gates (`source/lib/gates.sh`) · resiliência do instinct loop (`instinct-recover.sh`, 12/12 testes) · `/forge-agent` + `--validate-parity` · **Camada de Marketing** (`/marketing`, 4 agents, 22 BPs, sub-plugin) · 5 suites tests/v6-hooks (78 asserts no CI) · blindagem linhagem GSD (versions.lock) · context-packet handoffs · **`/spec` delta-spec brownfield** (21/21 testes) · 2 ADRs. README atualizado (105/105). Detalhes: `milestones/v6-ROADMAP.md`.

**Próximo (v7 — a definir):** piloto `/spec` num produto brownfield (nfideia) · gsd-browser quando publicado · novas demandas.

**Deploy nas máquinas:** `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh`
---

## Sessão 2026-06-16 — pesquisa: habilitar DeepSeek V4 Pro na AIOX (decisão adiada)

Sessão **consultiva** (ultracode/workflow de research). **Nenhuma mudança no repo IdeiaOS.** Usuário tem chave DeepSeek e perguntou como habilitar V4 Pro na aiox-core; pediu para **adiar a decisão**. Contexto completo em memória (`project-deepseek-v4-enablement-pending`).

**Descoberta-chave (não óbvia):** `.aiox-ai-config.yaml` (consumido pelo runtime Node `ai-provider-factory.js` em `~/dev/.aiox-core/...`) e o **Claude Code são planos separados** — o Claude Code não lê esse arquivo; os agentes AIOX usados aqui são subagentes Claude Code com `model: opus`. A config só alimenta features de IA dos **produtos** (via factory), e **nenhum código de produto chama a factory hoje** (`getProviderForTask`/`executeWithFallback` → grep vazio em `~/dev`). Logo, adicionar o bloco DeepSeek **não tem efeito** até o produto chamar a factory.

**Decisão pendente — onde habilitar:** (a) nos **produtos** (editar `.aiox-ai-config.yaml` + ligar a factory no código de cfoai/nfideia/etc.) ou (b) no **Claude Code** (settings + proxy OpenAI→Anthropic, pois DeepSeek é OpenAI-compatible). Facts verificados (docs oficiais): model `deepseek-v4-pro`, base `https://api.deepseek.com`, env `DEEPSEEK_API_KEY`; legados `deepseek-chat`/`deepseek-reasoner` aposentam **2026-07-24**; campos `bulk`/`feature_flag_env`/`fallback_to` no YAML não são lidos por esta versão do runtime (só `primary`/`fallback`/`routing`).

**Nota de higiene:** working tree tinha mudanças **não-minhas** (hooks/autosync: `.claude-plugin/marketplace.json`, `scripts/build-plugins.sh`) — deixadas como estão; não commitadas.

## Sessão 2026-06-14 (tarde) — v5 Memória entre IDEs IMPLEMENTADO

Milestone v5 aberto E implementado nesta sessão (5 fases 18-22, 11 reqs). Orquestrado por workflows (ultracode): research 4+1 agentes → build 6 agentes → verificação adversarial 13 céticos.

**Entregue (tudo no `work`, verificado local):**
- `source/hooks/memory-import.sh` (SessionStart: planning shared → memória nativa; tolera slug #30828; exit-0 offline; gera ponte Cursor `.mdc`; defesa `.git/info/exclude`)
- `source/hooks/memory-export.sh` (Stop: nativa → planning via **git plumbing** primário, worktree fallback; secret-scan; nunca toca main)
- `source/skills/memory-sync/SKILL.md` (export explícito `/memory-sync`)
- `source/templates/memory/` (MEMORY.header, fact.schema, planning.gitignore)
- `scripts/check-memory-not-on-main.sh` + wiring em `install-git-hooks.sh` (pre-commit/pre-merge) — guard instalado e provado (bloqueia memória em main, permite em work, override OK)
- autosync (`setup-dev-machine.sh`): exclui memória + branch guard + push planning
- `docs/decisions/v5-memory-topology.md` (ADR) + `docs/memory-sync-model.md` (3 camadas)
- `scripts/install-global-patches.sh` Patches 12/13 (instalados live) + `scripts/idea-doctor.sh` Seção 9 (memória) + varredura de leak no main
- `tests/v5-memory/` 3 suites (import, export 16/16, guardrails 10/10) — **todas verdes**
- Store semeado no branch **`planning`** (`.planning/memory/shared/` + `.planning/.gitignore`)
- Propagado: `build-plugins.sh` + `build-adapters.sh`. README sync 96/96. **`idea-doctor` = 0 FAIL (61 OK)**.

**Verificação adversarial:** 10 PASS / 1 PARTIAL / 1 FAIL → ambos remediados (PARTIAL R5-10 = patches não instalados → instalados; FAIL invariante = guard não instalado + defesa → guard instalado + `.git/info/exclude` + doctor leak-scan). Re-provado em sandbox isolado.

### ✅ Dogfood ao vivo + bug corrigido (2026-06-14, fim)
- Usuário publicou `origin/planning`. O `memory-export.sh` rodou de verdade num Stop e exportou **4 fatos reais** para `planning:.planning/memory/shared/facts/` — sistema provado end-to-end com dados reais.
- **Bug pego pelo dogfood:** o export commitava `.planning/memory/local/staging/` (via `update-index`, que ignora `.gitignore`) → buffer per-máquina vazava pro remoto (viola Phase 19 SC#4). **Corrigido** (`945a09b`): export só commita `shared/facts/` + `MEMORY.md`. Regressão T5 adicionada. `planning` limpo via worktree (`ec36f36`). Plugin hooks sincronizados.

### ✅ v5 (deliverable IdeiaOS) = COMPLETO. Itens abaixo são de OUTROS repos/máquinas.
**Re-escopo (2026-06-14, fim):** R5-01 misturava 2 coisas. A **prevenção** de leak (guard, `.gitignore`, doctor Seção 9) é trabalho de v5 e está no IdeiaOS = ✅ feita. A **remediação** do arquivo `.lovable_mem_tmp.md` é de UM artefato pré-existente que vive em `nfideia:main` (outro repo de produção, commit `604c0a19`) — **NÃO é construção de v5**; é housekeeping operacional de outro repo. IdeiaOS está limpo em todos os branches.

1. **Re-push `planning`** (se ainda à frente) — `AIOX_ACTIVE_AGENT=github-devops git -C ~/dev/IdeiaOS push origin planning`. (work o autosync empurra). [pode já estar sincronizado]
2. **nfideia housekeeping (opcional, fora do v5):** remover `.lovable_mem_tmp.md` de `nfideia:main`. O `.gitignore` do nfideia **já contém** o padrão (não recorre), então não há urgência. Fazer com nfideia em `main` limpo: `cd ~/dev/nfideia && git rm -f .lovable_mem_tmp.md && git commit -m "chore: remove leak" -- .lovable_mem_tmp.md && AIOX_ACTIVE_AGENT=github-devops git push origin main`. ⚠️ nfideia é produção em dev ativo (branches mudando) — fazer deliberadamente, não automatizado.
3. Deploy do v5 nas demais máquinas/projetos: `bash scripts/ideiaos-update.sh`.

## Sessão 2026-06-14 — auditoria + limpeza de pendências obsoletas

idea-doctor: **51 OK · 0 WARN · 0 FAIL** (ambiente saudável). Auditadas as pendências registradas contra a realidade — 3 eram registro obsoleto, agora corrigidas:

- **Atualizar máquinas (esta):** ✅ já feito — doctor confirma `ideiaos-update.sh` rodou no `MacBook-Air-2` (11/11 patches, 0 drift, versões = pin).
- **Feature "Novidades":** ✅ mergeada nos 2 repos — `feature/novidades*` não existe mais em `ideiapartner` nem `nfideia`; conteúdo está no `main` (hashes novos via merge/squash). O registro "branches aguardando o usuário" estava defasado.
- **Stub "Ultima sessão automática":** placeholder vazio auto-gerado pelo hook de sessão — consolidado.
- **Doc-drift:** STATE/handoff não mencionavam o 11º patch (`backlog-sync`, `c0da5d1`) nem os fixes do doctor (`94083bf`, `a58bb17`) de 06-13 — registrado.

**Pendências que restam (não-obrigatórias / externas):**
- Mac mini rodar `git pull && bash scripts/ideiaos-update.sh` — baixo risco (esteve ativo 06-13; `versions.lock` protegido repo-wide). Confirmável só rodando o doctor lá.
- Deploy em prod das Novidades (migration + Lovable Publish) — decisão do usuário.
- `/gsd-new-milestone "IdeiaOS v5"` — opção, se desejar abrir o ciclo.

## Sessão 2026-06-13 — padronização AIOX + escopo do manifesto

**Decisão estratégica AIOX (ADR `docs/decisions/aiox-gitignore-npx-vs-global.md`):**
- **Instrução = global, engine = por-máquina.** GSD + `/idea`/Deia + personas AIOX (`@dev`/`@qa`/`@architect`) ficam globais (`~/.claude`/`~/.cursor`); o engine `.aiox-core` (npm `@aiox-squads/core-internal` v5.2.x, stateful, ~58M) é tratado como `node_modules` — instalado por máquina via `npx aiox-core@latest install` e **nunca versionado**. Orquestrador oficial = `/idea` (Deia) + IdeiaOS.
- **`setup.sh`** passou a gitignorar `.aiox-core/` + agentes multi-IDE em todo projeto (previne o drift que divergiu os 4 repos).
- **Aplicado retroativamente nos 4 repos** (ideiapartner, nfideia, lapidai, cfoai-grupori): `.aiox-core` v5.2.9 local + gitignored, tracking antigo `git rm --cached`.

**Manifesto v1.1** (`manifests/modules.json`): `catalogScope` esclarece que o manifesto = só código-fonte próprio (`source/`); GSD/AIOX são camadas centrais mas **dependências upstream** rastreadas em `versions.lock`. Confirmado 1:1 com `source/`.

**Fix:** `source/skills/idea/SKILL.md` — referência morta `/dev-setup` → `/ideiaos-setup` (6×).

**Segundo cérebro (Obsidian) sincronizado:** o `Changelog/IdeiaOS` do vault estava em 12/jun e a pasta `Decisions/` vazia desde 28/mai (ADRs nunca espelhados — sync repo→vault é manual). Corrigido: entrada 2026-06-13 no Changelog, 2 ADRs espelhados em `Decisions/`, `00 Index.md` alinhado (verificado por 3 agentes, 0 issues). Encodado no `extract-learnings` **Passo 4c** para não repetir (commit `caf5ad8`, propagado ao plugin `ideiaos-core`).

**Commits:** `d53c1e7` · `5a81b48` · `5619d17` · `761f8a8` · `caf5ad8` (+ autosyncs). Working tree limpo, `work` = `origin/work`.

## 🏁 PLANO MAIOR 100% CONCLUÍDO

3 milestones shipped em 2026-06-12: **v2.0** (absorção ECC, 8 fases) → **v3** (refinamento, 5 fases) → **v4** (produção, 3 fases). 16 fases, 42 planos, tags v2.0/v3.0/v4.0. Auditorias: 8/8, 19/19, 8/9+1warn.

## Atualizar as máquinas — status (verificado 2026-06-14)

- ✅ `MacBook-Air-2` — feito (doctor confirma: statusline presente, 11/11 patches, 0 drift)
- ⚠️ `Mac mini` — confirmar quando conveniente (baixo risco): `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh`

## Decisões registradas (2026-06-12)

1. **Secret ANTHROPIC_API_KEY: NÃO** — evals LLM só localmente (`bash evals/run-evals.sh --ci`); job de CI skipa limpo por design
2. **Repo: manter PRIVADO** — marketplace funciona nas máquinas autenticadas; público só se quiser distribuir como open source
3. ~~checkout@v4→v5~~ ✅ aplicado (151132a)

## v5 — Fase 17 CONCLUÍDA (2026-06-12)

Critérios de eval robustos entregues: avaliador híbrido Sinais + LLM-judge, 22 casos atualizados, 3 vereditos corrigidos fail→pass. Ver `17-01-SUMMARY.md`.

**Feature Novidades — ✅ MERGEADA nos 2 produtos (verificado 2026-06-14):**
- **NFideia**: feature no `main` (badge não-lidas + "marcar como lida"); `feature/novidades*` não existe mais. Branch original `bab37b99` entrou via merge/squash (hash não preservado).
- **Ideiapartner**: feature no `main` (release_notes + reads RLS, UserChangelog, badge no header); `feature/novidades` não existe mais. Branch original `d124e409` entrou via merge/squash (hash não preservado).
- **Pendente (decisão do usuário):** aplicar migration em prod + Lovable Publish onde aplicável — não verificável por git.

## Sessão 2026-06-16 (Cursor) — encerramento + alinhamento de branches

**Parte 1 — fechamento admin:** commit `a834544` (`STATE.md` + handoff) pushed em `origin/work`. Sem código novo.

**Parte 2 — alinhamento (pedido do usuário):**
- `main` fast-forward ← `work` — **23 commits** (v6/v7/v8, marketing, `/doubt`, etc.) → `origin/main` @ `a834544`
- `planning` merge ← `work` → `origin/planning` @ `5c23b48` (artefatos GSD v6–v8 + memória v5 preservada)
- **`main` = `work`** no mesmo hash; working tree limpa

**Parte 3 — commit/push final (pedido do usuário):**
- Commits docs: `fd56c8d`, `0ffd912`, `647c242` — pushed em `origin/work`, `origin/main`, `origin/planning`
- Estado final: **`main` = `work` = `647c242`** · **`planning` = `a89e34b`** · working tree limpa
- `propagate-if-changed` disparou ao merge em `main` → setup em 6 projetos `~/dev/*` (Jarvis, cfoai, ideiapartner, lapidai, nfideia, IdeiaOS)

**Verificação pós-sync:** README 112/112 ✅ · idea-doctor 61 OK / 2 FAIL — secrets em memória Claude de **Jarvis** e **iCloud Projects** (não IdeiaOS); remediação manual em `~/.claude/projects/`.

## Próximo passo

> **▶ RETOMAR AQUI (2026-06-21, Mac mini — v14.0 PLANEJADO via multi-agente; execução GATED pelo v13) — leia primeiro:**
> A fase **v14.0 (Substrato + Espinha)** do Cockpit foi **planejada** (não executada). Frota Ultracode:
> `gsd-pattern-mapper` → `gsd-planner` → **3 verificadores adversariais paralelos** (plan-checker +
> security-reviewer + auditor antifragile).
> - **Entregue (commit `9bcb15c`, `work` 0/0):** 7 PLAN.md GSD em
>   `.planning/milestones/v14-phases/14.0-substrate-spine/` (**20 tasks / 3 waves**) — 01 idea-doctor
>   `--json` · 02 ref `cockpit` por plumbing · 03 TtT baseline · 04 SPA scaffold black-gold · 05 agentd
>   collector+plist · 06 schema.sql (8 tabelas, **ApiKey sem value**) + ingest.js · 07 SPA lê read-model
>   + gates/SOAK. + `14.0-CONTEXT.md` + `14.0-PATTERNS.md` + seção "v14.0 PLANEJADO" no `v14-cockpit-PLAN.md`.
> - **6 defeitos pegos e corrigidos pela revisão adversarial** (todos re-verificados por exit-code, 0
>   violações antifragile): gate-theater tautológico; regex JWT fraca p/ service_role; falta de gate
>   bind-loopback (`127.0.0.1`); falta de diff de não-regressão §15; IDs `R14-CTX-A*` **fantasma**
>   (violação Art. IV No-Invention); tabela errada p/ `last_doctor`.
> - **🚦 NÃO executar ainda — gate concreto, não só disciplina:** `/gsd-execute-phase 14.0` só **depois
>   do v13 tagar**. O plano `14.0-01` edita `scripts/idea-doctor.sh`, e o SOAK pendente do v13
>   **RE-EXECUTA** o `idea-doctor` na re-gravação (`idea_doctor=PASS|regression=PASS`) → editar agora
>   arriscaria a tag do v13. Os milestones compartilham o **mesmo arquivo vivo**. Se forçar, rodar só
>   Wave 1 **menos o `14.0-01`**. Learning: [[learning-active-milestone-gate-couples-via-shared-file]].
> - **Estado do gate v13 (medido 2026-06-21 01:20):** SOAK 2/2 máquinas ✓, **span 3968s de 86400s** ✗;
>   a janela ≥1d abre quando um heartbeat for gravado **≥ 2026-06-21 17:46:26** — o que a task agendada
>   `close-soak-v13-tag-tomorrow` faz (exige app Claude Code aberto na Mac mini). Só `v11.0` tagado.
> - **Próximo passo real:** quando o v13 tagar → `/gsd-execute-phase 14.0` com **contexto fresco**.

> **▶ RETOMAR AQUI (2026-06-21, Mac mini — v14 IdeiaOS Cockpit: PLANO COMPLETO + apuração 100%, PROPOSTO/zero-código) — leia primeiro:**
> Pedido: transformar instalação/ativação/gestão dos projetos numa **página web de visão CTO** = **IdeiaOS Cockpit** (console local-first sobre o substrato auto-telemetrado do IdeiaOS). **Doc-only, zero código de produto.** Decisões do usuário (AskUserQuestion): nome **Cockpit**; **formalizar via /spec+GSD antes de código**; comando cross-máquina **aprovado p/ v14.4 gated** por threat-model; brand ouro.
> - **Pacote (`docs/ideiaos-console/` — 20 docs):** blueprint multi-agente (13 agentes; o crítico adversarial pegou contradição fatal — "piggyback no SOAK `--record`" é manual) + roadmap + phase-1 spec + 6 docs de especialista (10-60) + apuração (70-79).
> - **Contrato `/spec` VIVO:** `specs/cockpit/spec.md` (9 req SHALL/DEVE), validado+merged+arquivado (`specs/_archive/2026-06-20-v14-cockpit-foundation/`). **1º uso de `specs/` no próprio IdeiaOS.** **ADR** `docs/decisions/v14-cockpit-local-first-git-as-bus.md` (Aceito). **Plano GSD** `.planning/milestones/v14-cockpit-PLAN.md`.
> - **Apuração 100% (validada NA própria Mac mini — doc 73):** corrigiu `192`→**MacBook-Air-2** (não Mac-mini); Constelação = **7 projetos** reais (Jarvis 469 sessões → descobrir, não hardcodar 5); **nenhum segredo crítico git-tracked**. Docs 74-79 fecham: resiliência (agentd empurra o ref `cockpit` por si → autosync vira redundância), DDL (ApiKey **sem coluna value**), produtividade (KPI-âncora SOAK; multi-usuário gated por 2º ator), alertas+allowlist (`revoke`-em-massa fica fora pra sempre), testes (Zero-Leak + dogfood de veneno), glossário 22 termos + **registro mestre de 39 questões (doc 79)**.
> - **Commits limpos:** `90b3062` (ADR+plano) + `2f0d288` (wave 74-79); resto via autosync. `work` 0/0. idea-doctor verde.
> - **Próximo passo real:** `/gsd-plan-phase v14.0` consumindo `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md` — **SÓ quando o v13 tagar** (não entrelaçar milestones ativos). **Aberto 🔴:** Q1 — autenticação de origem cross-máquina (`sha256 ≠ assinatura`) faz a v14.4 ser **GATE, não milestone**; o `/spec` de segurança consome as 9 questões (doc 70/79). _Planning-sync do `.planning/` v14 defere à ativação do milestone; a memória já propaga via hook._ Learning: [[learning-deterministic-replay-needs-structured-event-store]].
>
> **▶ RETOMAR AQUI (2026-06-20 noite, Mac mini — SOAK 2ª máquina v12/v13 + LaunchAgent + tag v12 agendada) — leia primeiro:**
> Rodada operacional na **Mac mini** (2ª máquina) para destravar o SOAK de v12 e v13:
> - **v12-qa-security:** heartbeat da 2ª máquina gravado (idea-doctor+regressão PASS), commit+push (`462ce2b`, capturado pelo autosync — benigno). Ledger agora **2 máquinas distintas**; span fecha **hoje 22:36:36**. **Tag `v12.0` AGENDADA** p/ hoje **22:45** via task local `close-soak-v12-tag-tonight` (`~/.claude/scheduled-tasks/`): re-grava heartbeat (fecha span ≥1d) → verifica `check-soak` exit 0 → `git tag v12.0` + push. **Aborta sem taguear** se qualquer gate falhar. ⚠️ exige o app Claude Code **aberto** na Mac mini às 22:45 (senão roda no próximo launch).
> - **v13-security-freshness:** heartbeat da 2ª máquina gravado (`703da4d`, pushed). Ledger **2 máquinas**; span fecha **amanhã 2026-06-21 17:46:26**. Tag `v13.0` aguarda 1 re-gravação **após** esse horário (`check-soak v13-security-freshness --record` → commit/push → `git tag v13.0`).
> - **LaunchAgent mensal AI-security ATIVADO na Mac mini** (`com.ideiaos.refresh-ai-security`, bootstrap OK status 0; dispara dia 1 de cada mês 09:00). _Pendência v12 do LaunchAgent: FECHADA._
> - Autosync pausado durante a cirurgia e **religado** ao fim. idea-doctor verde nas 2 gravações.
> - **Housekeeping (mesma sessão) — "deixe 100% correto":** idea-doctor **3 WARN → 0** (`75/0/0`): /spec drift corrigido (global sem 3 libs v11 — `setup.sh --global-only` é version-gated, espelhei o dir); AI-security snapshot bootstrapado; **suíte de design re-ancorada à proveniência real `b7e3af80`** (content-match verificado; `update-design-suite.sh` é destrutivo p/ ref-SHA — `f1c4e53`). **Branch `planning` reconciliado + sincronizado p/ v13** (`4dd9c1f`: merge de `origin/planning` 10/2 diverso, memory store preservado 47 facts; STATE v10→v13; ROADMAP +v9–v13; `planning` 0/0). **Os 2 defeitos de script CORRIGIDOS e testados:** (a) `setup.sh` deploy version-gated → content-aware (`4c878b5`); (b) `update-design-suite.sh` destrutivo → `cp -RL` + salvaguarda + clone direto p/ ref-sha (`a5d3590`+`4ab4e9a`). **Causa real do (b) era `cp -R` copiando os symlinks `data//scripts/` do upstream como DANGLING (NÃO o clone-por-sha)** — reproduzir o passo exato pegou a diagnose errada inicial (net-del 9374→112 no teste; pin `b7e3af80` está correto). ⚠️ **Autosync da Mac mini é pré-v11 (não honra o pause-file)** — comitou meus fixes como "wip: autosync"; rode `ideiaos-update.sh` no mini p/ deployar o autosync guard-aware. Ambos os defeitos em memória ([[learning-global-skill-deploy-version-gated-misses-lib-changes]], [[learning-design-suite-sha-pin-clone-destructive]]).
>
> **▶ RETOMAR AQUI (2026-06-20 — v13 Security Freshness Gate: núcleo + surfacing C + propagação, PARCIAL/no-tag) — leia primeiro:**
> Milestone **v13** ("Selo de Frescor de Segurança") implementado e propagado. Segurança verificada periodicamente e **por sistema**, padrão SOAK aplicado a dívida de segurança (gatilho determinístico risk-weighted → `@security-reviewer` → re-selo). **Nunca gateia PR de feature.**
> - **Núcleo W1-W4** (`8779d88`): `check-security-freshness.sh` + ledger + idea-doctor §14 (ADVISORY) + rule `security-freshness` + sandbox 10/10.
> - **Surfacing por produto = opção C** (`a6ab59d`): hook **`post-commit` advisory** (não bloqueia por construção). `SECFRESH_ROOT` → 1 engine no IdeiaOS audita qualquer repo → **produto não versiona script** (zero trigger Lovable). `setup_security_freshness_layer()` no `setup.sh --project-only` (bootstrap ledger local + install husky-aware + `.git/info/exclude`). Sandbox 14/14.
> - **Propagação 4 produtos (local-only, surgical):** nfideia `.husky/post-commit` (excluído); ideiapartner/lapidai/cfoai `.git/hooks/post-commit`. Verificação binária: 4/4 OK, **0 tracked churn** (sem trigger Lovable, sem race autosync → não precisou pausar autosync). Live-test cfoai: warn→exit 0, fresco→silêncio.
> - **SOAK:** heartbeat gravado (`.planning/soak/v13-security-freshness.log`, 1 máquina/0d).
>
> **Passos restantes p/ TAG `v13.0` (operacionais, não-código):**
> 1. **2ª máquina** (Mac mini): `bash scripts/check-soak.sh v13-security-freshness --record` (após pull). 
> 2. **Span ≥1d:** re-gravar 1 heartbeat **≥ 2026-06-21 17:46:26** (o `≥1d` é delta entre gravações, NÃO wall-clock — esperar não basta, tem que RE-gravar; ver [[learning-soak-span-is-record-delta-not-wallclock]]).
> 3. `bash scripts/check-soak.sh v13-security-freshness` → exit 0 → `git tag v13.0`.
> - **Ligar o gate** (`SECFRESH_GATE_ENABLED=1`) é decisão **pós-observação do 1º ciclo** (R13-07 — estreia advisory).
> - **Rule auto-propaga** via post-merge a cada pull de `main` (lapidai já tem); não foi commitada manualmente nos produtos.
> - ⚠️ Antes de cirurgia git multi-repo: pausar autosync (`scripts/autosync-pause.sh on/off`, com `trap`). _Esta sessão não precisou (footprint 100% local/untracked)._
>
> **✅ v11.0 TAGUEADO 2026-06-20** (`ec965b1`→`1ba01c8`, pushed). **SOAK 2ª máquina FEITA na Mac mini para v12 E v13** (2026-06-20 noite) + **LaunchAgent mensal AI-security ATIVADO na Mac mini**. Restam só os spans ≥1d: **v12.0** será taguada via task agendada hoje 22:45 (`close-soak-v12-tag-tonight`); **v13.0** aguarda re-gravação após amanhã 17:46:26. (Nota: a rotina `ideiaos-soak-tag-readiness` NÃO estava persistida nesta máquina — `list_scheduled_tasks` vazio; substituída pela task local one-shot.)

---

> **▶ RETOMAR AQUI (2026-06-19 noite — propagação v12 aos produtos + ROADMAP) — leia primeiro:**
> Esta rodada fechou 2 gaps de documentação/propagação **além** do v12:
> - **ROADMAP atualizado** — `.planning/ROADMAP.md` estava parado no v8; adicionados v9 (tag `v9.0`) + v10/v11/v12 (PARCIAL/no-tag) (`843f499`). Vault `Changelog/IdeiaOS.md` ganhou entrada v11+v12.
> - **Propagação v12 aos 4 produtos = COMPLETA E ATIVA.** A `propagate-if-changed` automática falhara numa corrida com o autosync (21:41). Repropagado com segurança (autosync pausado+religado via `trap`): **lapidai**/**cfoai-grupori** (branch `work`) commitados; **ideiapartner** (rules gitignored → local-ativo, sem commit); **nfideia** (rules **tracked em main**, Lovable) via PR [nfideia#41](https://github.com/Ideia-Business/nfideia/pull/41) — **MERGED** (squash `9728b153`) + pull ff-only → **ativo em main**. Os 4 agora com **10 `ideiaos-common` rules + `credential-isolation`**; drift (7/8/9/8) zerado.
> - **Recomendação (futura, opcional):** alinhar **nfideia** ao modelo do ideiapartner — **gitignorar `.claude/rules`** — para que próximas propagações sejam automáticas (sem PR). Exige `git rm --cached` + 1 commit em main (decisão Lovable à parte).
> - **Mecanismo @devops:** `git push`/`gh pr create|merge` são gated pelo hook constitucional `enforce-git-push-authority.cjs` (Art. II — bloqueia até a string literal em `echo`/`grep`). Sob autorização explícita do usuário, satisfaz-se o gate prefixando o comando com `AIOX_ACTIVE_AGENT=devops` (detecção command-scoped, aliases `devops`/`aiox-devops`). Ver [[learning-devops-push-gate-command-scoped-agent]].
>
> **Pendências restantes = só 2** (operacionais, detalhe no bloco v12 logo abaixo): TAG `v11.0`/`v12.0` (SOAK) + LaunchAgent mensal na Mac mini. **nfideia NÃO é mais pendência.**

---

> **▶ RETOMAR AQUI (2026-06-19, v12 QA & AI-Security — 4 ondas + refresh DONE, PARCIAL/no-tag):**
> milestone implementado e commitado em `work` (`8d18650`). Origem: análise multi-agente
> `docs/research/2026-06-19-qa-security-arsenal/` (`wf_50d8299b-f69`, 20 agentes; 4 docs:
> ANALYSIS/PROPOSAL/SECURITY-KNOWLEDGE/MONTHLY-REFRESH-SPEC). Absorção **conceito-only**
> (licenças via GitHub API: Hercules **AGPL-3.0** · TalEliyahu **MIT** · muellerberndt **SEM LICENÇA**):
> - **W1** `antifragile-gates` (2 regimes: artefato-exit-code vs runtime-NL) + `operating-discipline` #6 + nova rule `credential-isolation` (+ entry no `modules.json`)
> - **W2** `security-reviewer` (OWASP LLM Top 10 condicional + prompt-injection-runtime) + `mcp-hygiene` (critérios MCP SlowMist/TTPs + "Excessive Agency")
> - **W3** `docs/process/qa-coverage-index.md` (índice + 3 gaps) + `docs/reference/ai-governance-crossmap.md`
> - **W4** `evals/cases/EVAL-026/027/028` (anti-injection adversarial, ADVISORY)
> - **Refresh mensal:** `scripts/refresh-ai-security.sh` (curl+diff+sha, nunca executa; snapshot **LOCAL/gitignored** — muellerberndt all-rights-reserved) + `infra/launchd/com.ideiaos.refresh-ai-security.plist` + idea-doctor §13
>
> ADR `docs/decisions/v12-qa-security-absorption.md`; plano `.planning/milestones/v12-qa-security-PLAN.md`.
> Verificado: idea-doctor **73/1/0**, readme-sync 120/120, evals dry-run lista os 3 casos. Propagado a `.claude`/`.cursor`/`plugins`.
>
> **2 passos restantes (ambos operacionais, não-código):**
> 1. **TAG `v12.0`** — pendente do SOAK (`.planning/soak/v12-qa-security.log`: 1 máquina/0d agora; precisa ≥2 máquinas + ≥1d). Rodar `bash scripts/check-soak.sh v12-qa-security --record` na 2ª máquina + esperar 1 dia, como o v11.
> 2. **Ativar o refresh mensal na always-on (Mac mini):**
>    `cp infra/launchd/com.ideiaos.refresh-ai-security.plist ~/Library/LaunchAgents/ && launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ideiaos.refresh-ai-security.plist`
>
> ⚠️ **Lição:** dogfood pegou um agente alucinando "Hercules = Apache-2.0"; a API confirmou **AGPL-3.0**. Verificar licença de repo via `gh api repos/<o>/<r> --jq .license.spdx_id`, NUNCA via alegação de LLM. Ver [[learning-gitignore-third-party-verbatim-snapshot]].

---

> **▶ RETOMAR AQUI (2026-06-19, v11 COMPLETO — fechamento PARCIAL/no-tag · SOAK 2/2 máquinas PASS):** as **6 ondas do v11 estão DONE**, commitadas + pushadas em `work` (`origin/work=049a947`, 0/0):
> - **W1** autosync guard-aware — `44336c5`
> - **W2** CI repo-self-consistency gates + `check-source-headers` + design-suite ref resolvido — `ccb3ff0`
> - **W3** SOAK gate `check-soak.sh` + surface-budget + `/idea` routing eval cases — `70f0cd6`
> - **W4** `/spec --analyze`+`--converge` (libs `spec-grammar`/`analyze`/`converge`, tests 23 asserts) — `e65d0e0` **+ hardening** `4011186` (corrigiu bloqueador A2-template-FP + 9 achados da verificação adversarial wf_99173505)
> - **W5** deltas LOW R2/R4/R6/R8 — `4637b1d`
> - **W6** 2 ADRs (`v11-spec-kit-analyze-converge`, `v11-license-provenance-quarantine`) + SOAK heartbeat — `0ede0c0`; fix ledger gitignored — `c60d97a`; plugins/+README sync — `78e55b9`/`671f2de`
>
> **SOAK status (ledger `.planning/soak/v11-arsenal.log`):** 2/2 máquinas PASS — MacBook-Air-2 @17:51 (`4011186`) + Mac-mini-de-Gustavo @18:30 (`2ca25df`), ambos idea_doctor+regressão PASS → **durabilidade cross-máquina GREEN** (o risco real do gate fechou). Falta **só o span ≥1d** (ambos heartbeats de 06-19, ~39min → `0d`).
>
> **ÚNICO passo restante para a TAG `v11.0` (amanhã ≥ 2026-06-20 17:51:44, qualquer máquina):**
> ```
> bash scripts/check-soak.sh v11-arsenal --record
> git add .planning/soak/v11-arsenal.log && git commit -m "chore(soak): heartbeat +1d v11-arsenal" && git push
> bash scripts/check-soak.sh v11-arsenal     # exit 0
> git tag v11.0 && git push origin v11.0
> ```
> **Nada de código pendente.** O 1º heartbeat ancora a janela em 06-19 17:51:44; o gate só vira verde com um heartbeat ≥ 06-20 17:51:44 (o `≥1d` é delta entre gravações, NÃO wall-clock — esperar não basta, tem que RE-gravar). Sem bypass (`SOAK_MIN_DAYS=0` trairia o gate integridade-first). Metodologia: design por painel (`wf_449a5952`) + verificação adversarial 5-lentes (`wf_99173505`). Tracker: `.planning/milestones/v11-arsenal-absorption-PLAN.md`. ⚠️ Pausar autosync antes de cirurgia git (`scripts/autosync-pause.sh on/off`).

---

> **▶ RETOMAR AQUI (sessão anterior, HISTÓRICO) — leia primeiro:** validação de resíduos um-a-um **COMPLETA (5/5)**. Itens 1–4 fechados (verify-deploy `IN_SYNC` · ENV-04 · Mac mini baixo-risco · nfideia spec → PR [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40)). **Item 5 (stashes) RESOLVIDO em 2026-06-19:**
> - `nfideia stash@{0}` — confirmado noise (1 linha na seção auto-regenerada "Ultima sessao automatica") → **dropado** (`251593f1`).
> - `ideiapartner stash@{0}` (autostash órfão) — noise + deleção stale de `package-lock.json` (−442, blob mudou desde) → **dropado** (`4e37d1be`).
> - `ideiapartner stash@{1}` (type-safety pass, 2026-06-03) — revisado: 16/20 arq = casts `as TablesUpdate` (inócuos), MAS 4/20 = mudanças schema-coupled NÃO-verificáveis (`useAdminPartners` dropa `approved_at`/renomeia `paid_at`→`pix_paid_at`; `useCSAdvanced` reestrutura insert p/ `metadata`; `useAISystemContext` **conflita** na main atual). Veredito: **NÃO aplicar** (repo Lovable = source-of-truth no cloud; stale 3 sem; conflito). **Arquivado** em `~/dev/ideiapartner/.stash-archive/type-safety-pass-cursor-2026-06-03.patch` (24 KB, git-excluded via `.git/info/exclude`) e **dropado** (`b6975338`). Re-aplicável via `git apply` ou alimentar à Lovable se desejado.
>
> **Não há próximo passo pendente de IA** — todos os 5 resíduos fechados. **Resíduos user-only restantes (sua ação):** (a) mergear/squash PR ideIAos [#4](https://github.com/Ideia-Business/ideIAos/pull/4) (work→main, v6→v10; 121 dos 413 commits são autosync → squash recomendado); (b) mergear [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (Lovable-safe, doc-only). ⚠️ Lembrete p/ futura cirurgia git multi-repo: pausar autosync antes (`launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync`) e religar (`bootstrap … ~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`).

> **ATUALIZAÇÃO 2026-06-18 (fechamento) — leia primeiro:** a contenção `deny=19` descrita mais abaixo como "uncommitted em nfideia/cfoai" **REGREDIU e foi RE-REMEDIADA p/ 5/5 PERSISTIDO** (nfideia `e43f35f5` + cfoai `cdfa8d6` na `work`; ideiapartner `settings.local.json`) — ver §Sessão 2026-06-18 (2ª onda). Novo **check 7e** no `idea-doctor` previne nova regressão. **PR [#3](https://github.com/Ideia-Business/ideIAos/pull/3) MERGEADO** (mac-mini, 2026-06-19). **Sessão 2026-06-19 (validação de resíduos um-a-um):** ✅ item 1 `/lovable-mcp verify-deploy` e2e RODADO contra nfideia → `IN_SYNC` (Fase A validada end-to-end); ✅ ENV-04 (OpenRouter) FECHADO (decisão do usuário); ✅ Mac mini FECHADO como baixo-risco (git-synced confirmado; rodar `ideiaos-update.sh` no mini quando for usá-lo); ✅ nfideia spec PR RESOLVIDO — specs do piloto portadas p/ main via PR limpo [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (cherry-pick doc-only, 6 arquivos em `specs/`, fix nfse já estava na main, branch stale não arrastada; autosync pausado/religado). **Resíduos user-only restantes:** mergear [nfideia#40](https://github.com/Ideia-Business/nfideia/pull/40) (Lovable-safe) · revisar stashes (ideiapartner `stash@{1}` = type-safety real). ENV-06 = desconsiderado (Ideia Chat é teste). O texto v10 abaixo segue como contexto histórico.

**🔵 ATUAL (2026-06-18) — Integração Lovable MCP v10: Fase A (v1 read-only) SHIPPED.** A camada de verificação read-only foi construída e verificada. **Entregue:** skill `/lovable-mcp` (`source/skills/lovable-mcp/SKILL.md`) com 2 verbos read-only — `verify-deploy` (deploy-drift cruzando o commit da Cloud com `origin/main`) e `detect-hotfix` (edições do chat Lovable ausentes no Git); helper `source/lib/lovable-mcp.sh` (gateado por `gates.sh`, verdicts binários, **testado em sandbox git** + parser de escopo); resolver de escopo identity-aware (2 tiers `todos`/`pessoal`, override `lovable-scope.yaml`); **harness-deny de 19 tools mutantes** (+ `query_database` em deny PURO) no `.claude/settings.json` + `disabledMcpServers`; rule `source/rules/lovable/mcp-protocol.md` (doutrina: contenção, @devops, dois-escritores, fronteira MCP×GitHub); empacotamento completo (`build-plugins.sh` LOVABLE_SKILLS + `build_lovable()` cp da rule, `modules.json`, `plugin-membership.md`, `README.md`) e cross-link no `/lovable-handoff`. **Gates verdes** (membership 0 deriva, readme-sync 116/116, build OK). **Verificação adversarial de 4 lentes (workflow `wf_e0d15139-74a`)**: deny-completeness CLEAN, read-only-integrity CLEAN, helper + packaging com achados — todos **corrigidos** (parser awk: dash coluna-0 e `#` entre aspas; exit-codes normalizados; shallow-clone com aviso; contagem README 46). R10-01..05 = DONE.

**Rollout operacional Fase A — lado-AGENTE feito (2026-06-18); ⏳ só faltam 2 ações do USUÁRIO no painel.**

✅ **Feito (agente):** harness-deny das 19 tools mutantes + `query_database` deny PURO + `disabledMcpServers` aplicado e **validado por checagem binária** (`deny=19`, `disabled=True`) no `.claude/settings.json` dos **4 produtos Lovable**: nfideia, ideiapartner, cfoai-grupori, lapidai (ideia-chat ficou de fora — sem `.lovable/`). `language` preservado em cada um. Persistência por design: **ideiapartner** = gitignored (local-only); **lapidai** (branch `work`) = autosync commita+pusha pra `origin/work`; **nfideia + cfoai** = tracked-on-main, deixados **uncommitted** (autosync protege main dirty; não commitei em main Lovable — regra `feedback-lovable-projects-branch-commit`). Fonte-de-verdade para reaplicar = snippet canônico em `source/rules/lovable/mcp-protocol.md`.

✅ **Toggles de painel FEITOS (2026-06-18)** — o usuário deixou apenas **Grupo Ideia - Dev** (`2NHPnABxF0jdSX3qVLCw`) no alcance, satisfazendo o Gate 3 da Fase B (os outros workspaces — Grupo IDeia - Projects `A0gwgrenO8S5IrZtE4ig` e Dev's Lovable `pyHOQY0YDL838zK8GbR3` — fora do alcance).

✅ **Resíduo FECHADO (2026-06-19):** `/lovable-mcp verify-deploy` rodado contra nfideia real → verdict binário **`IN_SYNC`** (`latest_commit_sha=3921f440a44eed620de6e60d3832f5c16f1022b8` == `origin/main`); escopo `in:todos`; só tools read-only; repo não-shallow. Fase A validada end-to-end.
   _(ids dos workspaces confirmados ao vivo via `get_me`/`list_workspaces` em 2026-06-18.)_

**Fase B (sandbox) — CONCLUÍDA 2026-06-18 — veredito 🔴 BLOQUEAR `publish` via MCP** (contexto do plano original, mantido como histórico): plano GSD escrito e verificado adversarialmente (3 lentes) em `.planning/milestones/v10-phases/B-sandbox/B-01-PLAN.md`. Experimento: `remix_project` de 1 produto pouco ativo (cfoai) → fork descartável na workspace dev → mede (A1) namespace/timing do mirror GitHub↔Cloud, (A2) se `deploy_project` lê de `main` ou do estado interno, (A3) se `commit_sha` do `list_edits` casa com `git log`. Gate de TODO write-path; C/D dependem de B. **Resultado abaixo + `.planning/v10-MILESTONE-AUDIT.md`.**

🟡 **Metade read-only da Fase B EXECUTADA (2026-06-18, zero crédito):** medido em nfideia real (`list_edits` × `git log origin/main` local) — **A1-namespace = ACOPLADO** (commit_sha da Cloud É o SHA do GitHub) + **A3 = PASS** (detect-hotfix no namespace certo); mirror **bidirecional** confirmado (commit `ai_update` `76e9cee5` do agente Cloud presente em `origin/main`). Ver `B-01-SUMMARY.md` + dossiê §2.5b. Isso retira 2 dos 3 riscos de desacoplamento e estreita o experimento de escrita.

✅ **Fase B (sandbox) CONCLUÍDA (2026-06-18) — veredito 🔴 BLOQUEAR `publish` via MCP.** Experimento de escrita rodado ao vivo: janela `deny→ask` aberta (`lovable-window.py open`), fork descartável criado, janela fechada (`close`, assert `deny=19`).

**Como foi:** preflight read-only (saldo 100/0; 5 IDs prod p/ guard) → Gate 3 satisfeito (usuário deixou **1 só workspace** no alcance; 1.622 + Dev's Lovable fora) → `remix_project(cfoai)` **falhou** (Supabase pesado, 0 órfão) → `remix_project(Mornings Day POA, sem DB)` → fork `1d0652c4` → Task 1b: DB isolado (disabled) + **busca de gitsync/repo = vazia**.

**MURO DE VIABILIDADE (achado central):** o MCP da Lovable **não expõe nem gerencia o gitsync GitHub** — nenhum connector "github" (`list_connectors`), zero conexão GitHub (`list_connections`), `get_project` sem URL de repo; o `sha_0` do fork não existe em repo nenhum (`gh search commits`=`[]`), nenhum repo auto-criado, fonte sem repo; `add_connector` está no `deny`. Logo **A1-lag + A2 são inmensuráveis num sandbox MCP** (sem `origin/main` no fork não há divergência a testar) → indeterminado vota **BLOQUEAR** (regra do PLAN). **Pior-caso do A2 REFUTADO** pelo read-only (git pushes `developer_update` entram no Cloud → não é bypass total; risco residual = lag de ingestão).

**Achado de segurança (bônus):** `permissions.deny` é **relido e enforçado mid-session** (o remix só funcionou com a janela aberta; assert pós-close passou) — a contenção do harness vale ao vivo, não só no startup.

**✅ Fork descartável DELETADO pelo usuário (2026-06-18)** — confirmado `get_project`=404 + `list_projects`=0. Zero resíduo do experimento na conta Lovable. (Não há `delete_project` no MCP → deleção é sempre manual no painel.)

**✅ v10 FECHADO em escopo PARCIAL (2026-06-18)** — auditoria de fechamento `.planning/v10-MILESTONE-AUDIT.md` (workflow `wf_4fec3ed7-fc0`, 4 auditores + síntese): veredito BLOQUEAR confirmado SOUND (confiança alta), contenção ÍNTEGRA nos 5 alvos (deny=19), todo o status obsoleto reconciliado. **Tag: `no-tag`** (precedente v2.0..v9.0: tag só em milestone COMPLETO; este fecha parcial). Disposição: R10-01..05 DONE; R10-06 DONE (veredito BLOQUEAR); R10-07/08 PARQUEADAS-GATED.

**Próximos passos do v10 (carried-forward):** (1) **Fases C/D seguem gateadas** até medir A2 **fora do MCP** (gitsync manual na UI do editor num projeto descartável + 1 push divergente + 1 deploy — critério objetivo de reabertura em `v10-MILESTONE-AUDIT.md` §9). (2) **Fase A** não depende de B e está operacional — falta só rodar `/lovable-mcp verify-deploy` num produto real como teste end-to-end (toggles de painel já todos feitos). Detalhe completo: `.planning/v10-MILESTONE-AUDIT.md` + `B-01-SUMMARY.md` + dossiê §2.5b.

_Contexto da formalização (2026-06-17): plano vetado por 9 agentes (workflow `wf_a9c61aa5-2bf`), 4 forks + modelo de acesso fechados via `/grelha`; dossiê `docs/research/2026-06-17-lovable-mcp-integration-plan.md` (+ `…-synthesis.json`), ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md`._

---

**✅ MILESTONE v9 (Camada de Alinhamento) SHIPPED — 2026-06-17, tag `v9.0`.**

Execução autônoma multi-agente (6 fases A–F, builders + painéis de revisão 3-lentes por fase). Entregue:
- `/grelha` (alias `/grill`) — grilling colaborativo pré-plano + glossário `CONTEXT.md` (R9-01/02)
- rule `ubiquitous-language` (distinção dos 3 CONTEXT) + ADR inline `ADR-FORMAT` (R9-02/03)
- Passo 1.5 (gate de alinhamento opcional/escapável) na Deia (R9-04)
- `/improve-architecture` (`/aprofundar`) — ritual de deepening Ousterhout (R9-05)
- empacotamento + propagação + ADR de postura (R9-06/07); auditoria `.planning/v9-MILESTONE-AUDIT.md` **PASSED**; dogfood `/doubt` sobre o diff = **SHIP** (zero fabricação). Inclui fix de precisão do scanner (`scan-absorbed.sh` Check-2 fence-aware, com control test).

**Fechamento operacional — TODAS as pendências do ship resolvidas (2026-06-17):**
- ✅ `work` = `origin/work` (commit `122da91` + agora o commit da Fase G).
- ✅ **tag `v9.0` empurrada** para `origin` (`9b51679`).
- ✅ branch `planning` sincronizado com os docs de milestone v9 via git plumbing (memory store `.planning/memory/` preservado intacto).
- ✅ LOW do dogfood resolvido — README esclarece que `scan-absorbed.sh` mira a quarentena, não `source/`.
- ✅ **Fase G (could-haves) entregue** — deltas `to-prd` (@pm) + nota de seam (`/gsd-debug`) viraram **Patches 14/15** do overlay (`install-global-patches.sh`); aplicados na cópia instalada (repo `.aiox-core` pristine); contagem "15 patches" sincronizada em script/README/doctor; idea-doctor Patch 14✓/15✓ (0 FAIL). Ver `v9-phases/G-could-haves/G-01-SUMMARY.md`.
- ✅ **Hardening de verificação** — `scripts/validate-agent-yaml.sh` (parser autoritativo js-yaml→ruby→python) wired no `idea-doctor` (gate) + Patch 14 (auto-validação + rollback). Fechou o gap "PyYAML ausente ≠ não dá pra verificar".
- ✅ **`main` reconciliada** com `work` por fast-forward (commit `20b4033`) — `main`=`work`=`origin`, divergência 0/0 (IdeiaOS vai direto na main, sem PR).
- ✅ **Aprendizado extraído + encerramento** — `docs/learnings/2026-06-17-git-plumbing-partial-branch-overlay-sync.md` (global → memória + vault); 3 memórias novas (git-plumbing, parser-autoritativo, aiox-core-pristine); Changelog do vault Obsidian atualizado para v9.

Nada bloqueia o repo. `main`=`work`=`origin`=`20b4033` (+ commits desta sessão de fechamento). Próximo: novas demandas.

---

_v2.0–v8 todos SHIPPED._ v8 (Camada de Disciplina) fechado em 2026-06-16 — 4 waves, auditoria PASSED, tag `v8.0`. Absorção de `addyosmani/agent-skills` (MIT): `/doubt` (doubt-driven) + rule sempre-on `operating-discipline` (6 condutas) + `/context-engineering` + convenção de autoria anti-racionalização + opt-in `/observability`/`/deprecation-migration`. **Dogfood:** doubt-driven rodado sobre o próprio diff achou e corrigiu citação fabricada no `/doubt`. Detalhes em `.planning/v8-MILESTONE-AUDIT.md`.

**R8-09 FECHADO (2026-06-16):** `build-adapters.sh build_claude_project_rules()` deploya `source/rules/common/*.md` → `<projeto>/.claude/rules/ideiaos-common-*.md` (paridade Claude×Cursor; Claude auto-carrega `.claude/rules/`). Verificado em sandbox `/tmp` + dogfoodado no repo (manual `operating-discipline.md` → gerado). **Sem pendências do v8.**

**Executável quando houver demanda:** (1) ✅ higiene memória Claude **RESOLVIDA 2026-06-18** (era falso-positivo de fixture; `idea-doctor` 0 FAIL; Jarvis ausente de `~/dev`); (2) backlog passivo v7 — `nfideia:spec/multi-tenancy-pilot` (2 specs + `PILOT-BACKLOG.md`); (3) monitorar `gsd-browser` upstream; (4) DeepSeek V4 Pro nos **produtos** (decisão adiada); (5) `ideiaos-update.sh` no Mac mini.

---
_Histórico v7 abaixo:_

**v2.0–v7 todos SHIPPED.** v7 fechado em 2026-06-16 (4 fases entregáveis, auditoria PASSED, tag `v7.0`). Nada bloqueia o repo. Detalhes em `.planning/v7-MILESTONE-AUDIT.md`.

- **Fase 1** — piloto `/spec` no nfideia: spec viva `specs/multi-tenancy/spec.md` (6 reqs do comportamento real) + ciclo de delta completo. 2 bugs do `spec-merge.sh` corrigidos (`mkdir -p _archive`; splice do ADICIONADO dentro de `## Requisitos`) + suite **27/27**. Gap de empacotamento fechado (`spec`/`forge-agent`/`memory-sync` no `CORE_SKILLS`).
- **Fase 1b** — artefatos do nfideia na branch **`spec/multi-tenancy-pilot`** e **pushada** (`origin/spec/multi-tenancy-pilot`); main intacta (Lovable-safe).
- **Fase 2** — **drift-guard** `scripts/check-plugin-membership.sh`: cruza `plugin:` do manifesto × arrays do `build-plugins.sh`; wired no pre-commit + idea-doctor (seção 10). Pegou `memory-import`/`export` (v5) → marcados `plugin:null` (patch-installed). 69 módulos, 0 deriva.
- **Fase 3** — rollout: 2ª capability `nfideia/specs/cofre-digital/spec.md` (RN-050..053) na mesma branch (`ffc48c9c`).

**Resta (Fase 4 — backlog passivo, NÃO bloqueante — nada depende de ação do usuário):**
1. **gsd-browser** — monitorar upstream (ainda não publicado no npm/crates); avaliar quando sair.
2. **agent-inbox** — uso sob demanda (só se uma tarefa precisar testar auth-email num produto).
3. **nfideia** (branch `spec/multi-tenancy-pilot`): 2 specs vivas + **`specs/PILOT-BACKLOG.md`** com as tasks de Storage tenant isolation prontas para rodar via GSD/@dev (o `.planning/` do nfideia é gitignored, por isso o backlog mora em `specs/`). Pronta para PR/merge.

> **DeepSeek removido do plano (2026-06-16):** decisão do usuário — habilitado no nível dos **produtos**, fora do escopo IdeiaOS.

> **Lição de segurança:** nfideia É Lovable (`lovable-tagger` + `componentTagger` no vite.config) — cuidar só dos projetos Lovable; IdeiaOS não é Lovable (commit livre). Memória: `feedback-lovable-projects-branch-commit`.

## Ultima sessao automatica (2026-06-21)

- Sessão salva em: `/Users/gustavolopespaiva/.claude/sessions/2026-06-21-ideiaos-e2d20fda-07d9-4d22-a7ac-b952167f.tmp`
- Próximo passo: (definir antes de retomar)
