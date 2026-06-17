# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-06-16

---

## Linhagem GSD — VERDADE CANONICA

GSD neste projeto = @opengsd/get-shit-done-redux 1.1.0 (org opengsd).
NAO e gsd-pi (3.x) nem pacote da org gsd-build.
Pin revertido 3x — ver versions.lock (nota expandida) e check-versions-lock.sh.
Proibido editar gsd= no versions.lock manualmente.

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

**▶ PRIMEIRO PASSO EXECUTÁVEL (milestone v9 — planejado e pronto):**

```
/gsd-new-milestone "IdeiaOS v9 — Camada de Alinhamento"
```

Depois começar pela **Fase B**:

```
/gsd-plan-phase B-grelha-glossario
```

A **Fase A (quarentena) já está pré-feita** — antes de autorar `/grelha`: **revalidar a Fase A** (re-rodar `scan-absorbed.sh` em `security/quarantine/mattpocock-skills/`, esperar PASS/exit 0) e **resetar a sessão** (higiene pós-quarentena, ver `docs/security/memory-hygiene.md`) para só então iniciar a autoria.

**Artefatos v9 para contexto (ler antes de planejar a fase):**
- `docs/research/2026-06-16-mattpocock-skills-analise.md` (análise + 3 GAPs)
- `docs/decisions/v9-mattpocock-skills-absorcao.md` (ADR — postura de absorção)
- `.planning/milestones/v9-REQUIREMENTS.md` · `v9-ROADMAP.md` · `v9-IMPLEMENTATION-PLAN.md`
- `.planning/milestones/v9-phases/{A..F}-*/*-01-PLAN.md`
- `security/quarantine/mattpocock-skills/` (material-fonte)

---

_v2.0–v8 todos SHIPPED._ v8 (Camada de Disciplina) fechado em 2026-06-16 — 4 waves, auditoria PASSED, tag `v8.0`. Absorção de `addyosmani/agent-skills` (MIT): `/doubt` (doubt-driven) + rule sempre-on `operating-discipline` (6 condutas) + `/context-engineering` + convenção de autoria anti-racionalização + opt-in `/observability`/`/deprecation-migration`. **Dogfood:** doubt-driven rodado sobre o próprio diff achou e corrigiu citação fabricada no `/doubt`. Detalhes em `.planning/v8-MILESTONE-AUDIT.md`.

**R8-09 FECHADO (2026-06-16):** `build-adapters.sh build_claude_project_rules()` deploya `source/rules/common/*.md` → `<projeto>/.claude/rules/ideiaos-common-*.md` (paridade Claude×Cursor; Claude auto-carrega `.claude/rules/`). Verificado em sandbox `/tmp` + dogfoodado no repo (manual `operating-discipline.md` → gerado). **Sem pendências do v8.**

**Executável quando houver demanda:** (1) higiene memória Claude — limpar secrets em sessões Jarvis/iCloud Projects (`idea-doctor` FAIL); (2) backlog passivo v7 — `nfideia:spec/multi-tenancy-pilot` (2 specs + `PILOT-BACKLOG.md`); (3) monitorar `gsd-browser` upstream; (4) DeepSeek V4 Pro nos **produtos** (decisão adiada); (5) `ideiaos-update.sh` no Mac mini.

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

## Ultima sessao automatica (2026-06-17)

- Sessão salva em: `/Users/gustavolopespaiva/.claude/sessions/2026-06-17-ideiaos-2c827553-7be6-4e39-8be2-5d62bdff.tmp`
- Próximo passo: (definir antes de retomar)
