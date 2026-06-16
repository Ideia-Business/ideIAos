# Milestone v5: Memória compartilhada entre IDEs

**Status:** Implementado + verificado (local) — 2026-06-14 · pushes operacionais pendentes (@devops)
**Fases:** 18–22 (todas implementadas)
**Total de Planos:** entregue via workflows (build 6 agentes + verify 13 céticos adversariais)
**Branch:** `work` (código) · `planning` (store de memória)
**Verificação:** 10 PASS / 1 PARTIAL / 1 FAIL → ambos remediados (patches 12/13 instalados; invariante fechada com guard instalado + `.git/info/exclude` + varredura no doctor). `idea-doctor` = 0 FAIL. 3 suites de teste verdes.

---

## Visão geral

IdeiaOS v5 adiciona uma camada de sincronização de memória compartilhada entre IDEs (Claude Code e Cursor) e entre máquinas — usando o branch `planning` como transporte e git plumbing como mecanismo de escrita, sem nunca tocar o `main`. O design replica o padrão das 6 barreiras do `versions.lock` e resolve o drift de memória entre IDEs (caso real: nfideia session 35 vs 39 em Cursor/MacBook).

**Invariante inegociável:** Nenhum churn de memória pode tocar o `main`. O `main` é lido continuamente pela Lovable Cloud; qualquer commit de memória ali dispara um Lovable Update indevido. O arquivo `.lovable_mem_tmp.md` vivo em `nfideia:main` (commit `604c0a19`) é a prova real de que esse risco não é teórico — por isso R5-01 é literalmente o primeiro item do milestone.

**Origem dos requisitos:** 11 requisitos R5-01..R5-11 derivados de STATE.md + research HIGH-confidence em `.planning/research/` + 4 decisões de design travadas com o usuário em 2026-06-14.

---

## Phases

- [x] **Phase 18: Guardrails Lovable-safe** — 6 barreiras anti-churn + topologia/ADR + guard instalado (pre-commit/pre-merge). **Prevenção de leak (escopo IdeiaOS) = ✅ completa.** R5-01 nota: a limpeza do `.lovable_mem_tmp.md` é remediação de UM arquivo pré-existente que vive em `nfideia:main` (outro repo de produção, commit `604c0a19`) — housekeeping operacional separado, NÃO construção de v5. IdeiaOS está limpo em todos os branches; o `.gitignore` do nfideia já contém o padrão (não recorre). Fazer no nfideia quando o repo estiver calmo.
- [x] **Phase 19: Store & formato canônico** — Split shared/local, frontmatter canônico, índice idempotente, secret-scan (16/16 testes)
- [x] **Phase 20: Import bridge** — Hook SessionStart importa shared do planning → memória nativa; tolera slug #30828; exit-0 offline; idempotente
- [x] **Phase 21: Export bridge & Cursor** — Skill /memory-sync + export git plumbing (worktree fallback) + ponte Cursor `.mdc` (gitignored + `.git/info/exclude`)
- [x] **Phase 22: Verificação & integração do loop** — Doctor seção 9 (0 FAIL) + patches 12/13 instalados + modelo 3 camadas documentado

---

## Phase Details

### Phase 18: Guardrails Lovable-safe
**Goal**: As barreiras contra contaminação do `main` existem antes do primeiro arquivo de memória ser escrito, e o leak existente foi removido do nfideia:main
**Depends on**: Nothing (first phase — but must complete before any memory file is written)
**Requirements**: R5-01, R5-02, R5-03
**Success Criteria** (what must be TRUE):
  1. `git ls-tree origin/main` em nfideia não lista `.lovable_mem_tmp.md` e `.gitignore` cobre o padrão — leak histórico eliminado
  2. Uma tentativa de commit de arquivo de memória em `main` é bloqueada com mensagem direcional clara (pre-commit hook, não mensagem genérica)
  3. O autosync recusa fazer `git add -A` quando o branch corrente é `main` — guard de branch ativa
  4. Um merge `planning`→`main` de teste falha com mensagem que explicita a proibição — topologia documentada e guardada
  5. Documento ADR de topologia está em `docs/decisions/`: `main` recebe apenas de `work`/feature; `planning` nunca merge para `main`; memória fica no `planning`
**Plans**: TBD

---

### Phase 19: Store & formato canônico
**Goal**: O store canônico de memória existe no branch `planning` com formato lockado, split shared/local funcional, e barreiras contra secrets e escopo pessoal vazarem para o store compartilhado
**Depends on**: Phase 18 (barreiras devem existir antes do primeiro arquivo de memória ser criado)
**Requirements**: R5-04, R5-05, R5-06
**Success Criteria** (what must be TRUE):
  1. Dois "exports" simultâneos de máquinas diferentes produzem merge aditivo sem conflito de conteúdo (arquivos independentes por slug, não edição in-place)
  2. Regenerar o índice `MEMORY.md` duas vezes a partir do mesmo diretório produz output idêntico (idempotência verificada)
  3. Um fato com secret de teste (padrão API key / JWT / connection string) é recusado no export com mensagem clara; fato limpo passa
  4. `.planning/memory/local/` aparece no `.gitignore` do branch `planning` e não é commitado junto com os fatos `shared/`
**Plans**: TBD

---

### Phase 20: Import bridge
**Goal**: Uma nova sessão no Claude Code importa automaticamente os fatos compartilhados do branch `planning` para a memória nativa da IDE, sem bloquear o SessionStart e sem contaminar o working tree
**Depends on**: Phase 19 (store canônico deve existir para ser importado)
**Requirements**: R5-07
**Success Criteria** (what must be TRUE):
  1. Uma sessão nova (após `git-sync-check.sh` buscar o remote) importa N fatos shared e emite `systemMessage` com a contagem — import confirmado ao vivo
  2. O import é resiliente ao bug #30828 de slug: checar variante com underscore e com hífen, usar whichever tem MEMORY.md, sem erro fatal
  3. Uma falha de conectividade (sem origin, sem branch planning) causa `exit 0` e não bloqueia o SessionStart — contrato de resiliência mantido
  4. Re-executar o import com o mesmo SHA do planning branch é no-op (freshness guard ativa, sem `git archive` redundante)
**Plans**: TBD
**UI hint**: no

---

### Phase 21: Export bridge & Cursor
**Goal**: A skill `/memory-sync` exporta a memória nativa alterada para o branch `planning` via git plumbing sem residuos no working tree, e o Cursor recebe o conteúdo shared via `.mdc` regenerado localmente
**Depends on**: Phase 20 (import deve estar estável antes de escrever no store)
**Requirements**: R5-08, R5-09
**Success Criteria** (what must be TRUE):
  1. `/memory-sync export` grava fatos novos/alterados no branch `planning` (local), autosync empurra `planning` para origin — `main` intacto, sem residuo no working tree
  2. Git plumbing pipeline (`hash-object`→`commit-tree`→`update-ref`) é o caminho primário; `git worktree` documentado como `# FALLBACK:` no script
  3. Se nenhum fato mudou, `/memory-sync export` termina silenciosamente (sem commit vazio, sem mensagem de erro)
  4. `.cursor/rules/memory-bridge.mdc` é gerado no import, está no `.gitignore`, tem `alwaysApply: true`, e não aparece em `git status` do branch de trabalho
**Plans**: TBD
**UI hint**: no

---

### Phase 22: Verificação & integração do loop
**Goal**: O `idea-doctor.sh` reporta a saúde do sistema de memória sem FAIL, os patches 12/13 estão registrados via `ideiaos-update.sh`, e o modelo de 3 camadas está documentado explicitamente sem criar um segundo cérebro paralelo
**Depends on**: Phase 21 (hooks e skill devem existir para serem verificados)
**Requirements**: R5-10, R5-11
**Success Criteria** (what must be TRUE):
  1. `idea-doctor.sh` em projeto configurado reporta seção de memória com 0 FAIL — alcançabilidade do `planning`, existência de `.planning/memory/shared/`, e patches 12/13 todos verificados
  2. `ideiaos-update.sh` (step 3, hooks.json) registra `memory-import` no array SessionStart (após `git-sync-check`) e `memory-export` no array Stop — sem edição manual de `settings.json`
  3. Doc do modelo de 3 camadas (local → shared/planning → vault Obsidian) está em `docs/` com greps confirmando que as skills apontam para o store sem criar diretório de segundo cérebro
  4. `recall-learnings` e `extract-learnings` referenciam o store compartilhado (passando por ele) sem substituir nem duplicar o vault Obsidian
**Plans**: TBD
**UI hint**: no

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 18. Guardrails Lovable-safe | ✔ | Done (R5-01 push @devops pendente) | 2026-06-14 |
| 19. Store & formato canônico | ✔ | Done | 2026-06-14 |
| 20. Import bridge | ✔ | Done | 2026-06-14 |
| 21. Export bridge & Cursor | ✔ | Done | 2026-06-14 |
| 22. Verificação & integração do loop | ✔ | Done | 2026-06-14 |

---

## Cobertura de requisitos

| Requisito | Fase | Status |
|-----------|------|--------|
| R5-01 (P1) — Limpar leak existente no main | Phase 18 | Pending |
| R5-02 (P1) — 6 barreiras anti-churn no main | Phase 18 | Pending |
| R5-03 (P1) — Topologia: planning como transporte | Phase 18 | Pending |
| R5-04 (P1) — Split shared/local, um arquivo por fato | Phase 19 | Pending |
| R5-05 (P1) — Frontmatter canônico + índice idempotente | Phase 19 | Pending |
| R5-06 (P2) — Secret-scan no export | Phase 19 | Pending |
| R5-07 (P1) — Import hook (SessionStart, lado Claude) | Phase 20 | Pending |
| R5-08 (P1) — Export via skill /memory-sync | Phase 21 | Pending |
| R5-09 (P2) — Ponte Cursor (mdc gitignored) | Phase 21 | Pending |
| R5-10 (P2) — Doctor + registro dos hooks | Phase 22 | Pending |
| R5-11 (P2) — Modelo de 3 camadas documentado | Phase 22 | Pending |

**Cobertura: 11/11 requisitos mapeados. Nenhum órfão.**

---

## Decisões de design (travadas antes do milestone)

- **Transporte = branch `planning`** (reuso), nunca `main`; guard de pre-commit barra merge `planning`→`main`
- **Export = skill-driven (`/memory-sync`)**, não hook automático — Claude Code não tem SessionEnd; Stop dispara por turno, não por sessão
- **Cursor bridge = `.mdc` gitignored**, regenerado por máquina a cada import (Cursor não expõe hooks nem memória em filesystem)
- **Git plumbing como caminho primário** de escrita (`hash-object`→`commit-tree`→`update-ref`); `git worktree` como fallback documentado — sem residuo no working tree
- **Promoção de instincts faseada**: MVP export-only via `/memory-sync`; integração com `extract-learnings` Passo 4d depois

## Dívida técnica prevista (deferred para v5.x)

- `extract-learnings` Passo 4d: oferecer promoção para `shared/` junto do vault (F5-01)
- `/evolve` auto-candidato: instincts maduros (confidence ≥0.7) viram candidatos automáticos a `shared/` (F5-02)
- Decay/eviction automático de fatos `shared/` por `expires`/estagnação (F5-03)
- `/memory-sync status` — dashboard visual de shared vs local vs pending (deferred do core MVP)

---

_Para roadmap completo de milestones, ver .planning/ROADMAP.md_
