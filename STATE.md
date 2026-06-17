# Estado do projeto — ideIAos

**Atualizado:** 2026-06-16 · **Branch:** `work` → `main` · **Versão ideIAos:** v8 shipped (2026-06-16); v2.0–v8 todos SHIPPED

## Snapshot

| Área | Status |
|------|--------|
| **Milestones v2.0–v8** | ✅ Todos shipped (tags v2.0 … v8.0) |
| **v8 Camada de Disciplina** | ✅ `/doubt`, `operating-discipline`, `/context-engineering`, R8-09 (rules Claude×Cursor) |
| **v7 Resiliência + Spec** | ✅ Piloto `/spec` nfideia, drift-guard, branch `spec/multi-tenancy-pilot` |
| **v6 Marketing + GSD** | ✅ `/marketing`, antifragile gates, `/spec` delta-spec brownfield |
| **v5 Memória entre IDEs** | ✅ import/export hooks, branch `planning`, 3 suites verdes |
| **Branches** | ✅ `main` = `work` = `0ffd912` · `planning` = `a89e34b` (pushed) |
| **idea-doctor** | ⚠️ 61 OK · 1 WARN · 2 FAIL — secrets em memória Claude de **outros projetos** (Jarvis, iCloud Projects); IdeiaOS repo OK |
| **README sync** | ✅ 112/112 |
| **Deploy máquinas** | ✅ MacBook-Air-2 · ⚠️ Mac mini confirmar (`ideiaos-update.sh`) |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` § Próximo passo |

## Sessão 2026-06-16 (Cursor) — fechamento

1. **Encerramento admin** — `STATE.md` + handoff sincronizados; commit `a834544` pushed em `work`.
2. **Alinhamento de branches** — `main` fast-forward ← `work` (23 commits, pushed); `planning` merge ← `work` (pushed `5c23b48`). Repo limpo, working tree clean.
3. **Verificação** — README 112/112 ✅; idea-doctor 2 FAIL por secrets em `~/.claude/projects/` (Jarvis + iCloud Projects) — remediação manual, fora do repo.

## Pendências não-bloqueantes

- **Higiene de memória Claude:** inspecionar/remover secrets em sessões Jarvis e iCloud Projects (`idea-doctor` seção 7).
- **nfideia** (`spec/multi-tenancy-pilot`): 2 specs vivas + `PILOT-BACKLOG.md` — PR/merge quando conveniente.
- **gsd-browser:** monitorar upstream (ainda não publicado).
- **DeepSeek V4 Pro:** decisão adiada — habilitar nos produtos (fora do escopo IdeiaOS); ver handoff sessão consultiva 2026-06-16.
- **Mac mini:** `git pull && bash scripts/ideiaos-update.sh` — confirmar quando conveniente.

## Fonte de verdade

- Operacional curto prazo: este arquivo + `docs/CONTINUATION_HANDOFF.md`
- Médio/longo prazo: `.planning/*` no branch `planning`
- Especificação canônica: `docs/IDEIAOS.md`
