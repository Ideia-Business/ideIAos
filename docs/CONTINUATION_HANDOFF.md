# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-06-14

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

## Próximo passo

Não há pendência de trabalho travando o repo (`work` = `origin/work`, tree limpo). Opções:

1. (Opcional) Mac mini: `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh` — esta máquina já está atualizada.
2. Em clone novo / máquina nova, regenerar o engine por projeto: `npx aiox-core@latest install` (personas e `/idea` já são globais — funcionam sem isso).
3. (Opcional) `/gsd-new-milestone "IdeiaOS v5"` para abrir o próximo ciclo — ainda **não há** milestone v5 em `.planning/` (só v2.0/v3/v4).

## Ultima sessao automatica (2026-06-15)

- Sessão salva em: `/Users/gustavolopespaiva/.claude/sessions/2026-06-15-ideiaos-af4aa8b6-9e62-4008-a648-39421d49.tmp`
- Próximo passo: (definir antes de retomar)
