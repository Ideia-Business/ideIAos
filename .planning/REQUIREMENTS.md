# Requirements — IdeiaOS v5 (Memória compartilhada entre IDEs)

**Total de requisitos v5:** 11
**Origem:** STATE.md "Roadmap / Ideias futuras" (drift multi-IDE/máquina, caso nfideia 35 vs 39) + research `.planning/research/SUMMARY.md` (HIGH confidence) + 4 decisões de design travadas com o usuário (2026-06-14)
**Invariante inegociável:** nenhum churn de memória pode tocar o `main` (branch que a Lovable Cloud lê). `/lovable-handoff` segue como único gate pro `main`.

---

## Tema A — Guardrails Lovable-safe (fundação)

### R5-01 (P1) — Pré-requisito: limpar o leak existente no main
O arquivo `.lovable_mem_tmp.md` (vivo em `nfideia:main`, commit `604c0a19`) é removido do tracking antes de qualquer tooling de memória ser escrito. Critério: `git ls-tree origin/main` em nfideia não lista `.lovable_mem_tmp.md`; `.gitignore` cobre o padrão.

### R5-02 (P1) — 6 barreiras anti-churn no main
Espelhando o precedente `versions.lock`: (1) autosync exclui paths de memória do `git add -A`; (2) pre-commit barra memória chegando em `main`; (3) `.gitignore` cobre `.planning/memory/local/` e a `.mdc` do Cursor; (4) mensagens direcionais (não ambíguas); (5) comentário anti-armadilha no store; (6) escrita só pelo caminho autorizado (plumbing/worktree). Critério: teste reproduz tentativa de commit de memória em `main` e prova bloqueio; autosync em branch de trabalho não captura memória.

### R5-03 (P1) — Topologia: `planning` como transporte, nunca `main`
A memória trafega exclusivamente pelo branch `planning` (reuso do branch existente, já lido por `git show planning:...`). Guard de pre-commit barra merge/fast-forward de `planning`→`main`. Critério: doc de topologia (ADR curto) + guard que falha um merge planning→main de teste.

---

## Tema B — Store & formato canônico

### R5-04 (P1) — Split shared/local, um arquivo por fato
Memória compartilhada em `.planning/memory/shared/` (commitada no `planning`, visível ao time); memória pessoal em `.planning/memory/local/` (gitignored, por membro). Um arquivo por fato (md + frontmatter) para merges aditivos sem conflito. Critério: dois "exports" simultâneos de máquinas diferentes produzem merge aditivo sem conflito de conteúdo.

### R5-05 (P1) — Frontmatter canônico + índice idempotente
Cada fato tem frontmatter: `scope` (shared|local), `type` (project|reference|user|feedback), `project`, `contributed_by`, `expires?`. O índice `MEMORY.md` é reconstruído por varredura de diretório (idempotente), nunca editado in-place. Critério: schema validado; regenerar o índice 2× produz output idêntico (idempotência).

### R5-06 (P2) — Secret-scan no export
O export bloqueia qualquer fato com segredo aparente (chaves, tokens, .env) de entrar no store compartilhado. Critério: fato com secret de teste é recusado no export com mensagem clara; fato limpo passa.

---

## Tema C — Bridges (import / export / Cursor)

### R5-07 (P1) — Import hook (SessionStart, lado Claude)
No SessionStart, um hook lê `.planning/memory/shared/` do `planning` (via `git show`/archive, sem checkout) e popula a memória nativa `~/.claude/projects/<slug>/memory/`, tolerando o bug de não-determinismo de slug (#30828: checar variantes). Critério: sessão nova importa N fatos shared e emite systemMessage com a contagem; resiliente às duas variantes de slug.

### R5-08 (P1) — Export via skill `/memory-sync`
A skill `/memory-sync` leva a memória nativa nova/alterada de volta ao `planning` via git plumbing (`hash-object`→`commit-tree`→`update-ref`; `git worktree` como fallback documentado), commitando e empurrando `planning` — **nunca** `main`. Export é explícito (não há hook automático: Claude Code não tem SessionEnd; Stop dispara por turno). Critério: export real grava no `planning`, `main` intacto, working tree sem resíduo.

### R5-09 (P2) — Ponte Cursor (mdc gitignored)
No import, gera `.cursor/rules/memory-bridge.mdc` (`alwaysApply: true`) com o conteúdo da memória shared. Arquivo gitignored e regenerado por máquina (Cursor não tem hooks nem memória em filesystem — esta é a única ponte viável). Critério: `.mdc` é gerado no import, está no `.gitignore`, e o Cursor o carrega como always-apply.

---

## Tema D — Verificação & integração do loop

### R5-10 (P2) — Doctor + registro dos hooks
`idea-doctor.sh` ganha uma seção que verifica: alcançabilidade do `planning`, existência de `.planning/memory/shared/`, e frescor do último sync. Os novos hooks entram como Patches 12/13, registrados via `ideiaos-update.sh` (settings.json) como os anteriores. Critério: doctor reporta a seção memória com 0 FAIL num projeto configurado; patches verificados.

### R5-11 (P2) — Modelo de 3 camadas documentado
O modelo local → shared/`planning` → vault Obsidian é documentado explicitamente; `recall-learnings`/`extract-learnings` referenciam o store compartilhado **sem duplicar** o vault (Obsidian permanece a biblioteca cross-projeto, não o transporte). Critério: doc do modelo + greps confirmando que as skills apontam pro store sem criar segundo cérebro paralelo.

---

## Future Requirements (deferidos — fora do MVP por decisão)

- **F5-01** — `extract-learnings` Passo 4d: ao extrair um fato, oferecer promoção para `.planning/memory/shared/` junto da promoção ao vault (v5.x, depois do loop básico rodar 1 sprint real).
- **F5-02** — `/evolve` auto-candidato: instincts maduros (confidence ≥0.7) viram candidatos automáticos a `shared/` (future; thresholds calibrados com dados de uso).
- **F5-03** — Decay/eviction automático de fatos `shared/` por `expires`/estagnação + `memory-audit.sh` com métricas de curadoria.

## Out of Scope (anti-features — exclusões explícitas)

- ❌ Qualquer memória em `main` ou que dispare Lovable Update (viola a invariante Lovable)
- ❌ Injeção/sync de memória **cross-projeto** (é exatamente o drift que o usuário quer evitar; scoping por projeto é estrutural)
- ❌ Segundo cérebro paralelo ao vault Obsidian (PROJECT.md proíbe explicitamente)
- ❌ Auto-push de memória a cada commit via autosync (re-introduziria o hazard do `versions.lock`)
- ❌ Sync automático do Cursor via hook (Cursor não expõe hooks nem memória em filesystem)
- ❌ Live/realtime sync entre IDEs (complexidade desproporcional; import/export discreto basta)

---

## Traceability

| Requisito | Fase | Status |
|-----------|------|--------|
| R5-01 (P1) — Limpar leak existente no main | Phase 18 | Prevenção (IdeiaOS) ✅ · remediação do arquivo existe só em nfideia:main (outro repo) = housekeeping operacional separado, fora do deliverable IdeiaOS |
| R5-02 (P1) — 6 barreiras anti-churn no main | Phase 18 | Done |
| R5-03 (P1) — Topologia: planning como transporte | Phase 18 | Done |
| R5-04 (P1) — Split shared/local, um arquivo por fato | Phase 19 | Done |
| R5-05 (P1) — Frontmatter canônico + índice idempotente | Phase 19 | Done |
| R5-06 (P2) — Secret-scan no export | Phase 19 | Done |
| R5-07 (P1) — Import hook (SessionStart, lado Claude) | Phase 20 | Done |
| R5-08 (P1) — Export via skill /memory-sync | Phase 21 | Done |
| R5-09 (P2) — Ponte Cursor (mdc gitignored) | Phase 21 | Done |
| R5-10 (P2) — Doctor + registro dos hooks | Phase 22 | Done |
| R5-11 (P2) — Modelo de 3 camadas documentado | Phase 22 | Done |

**Cobertura: 11/11 — nenhum requisito órfão.**
