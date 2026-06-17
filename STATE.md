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
| **Branches** | ✅ `main` = `work` = `1f1f9ed` · `planning` = `045b4b0` (todos pushed) |
| **idea-doctor** | ⚠️ 61 OK · 1 WARN · 2 FAIL — secrets em memória Claude de **outros projetos** (Jarvis, iCloud Projects); IdeiaOS repo OK |
| **README sync** | ✅ 112/112 |
| **Deploy máquinas** | ✅ MacBook-Air-2 · ⚠️ Mac mini confirmar (`ideiaos-update.sh`) |
| Próximo passo | Ver `docs/CONTINUATION_HANDOFF.md` § Próximo passo |

## Sessão 2026-06-16 (Cursor) — fechamento final

1. **Encerramento + docs** — handoff/STATE sincronizados; commits `a834544` → `d4d5887` (autosync Mac mini).
2. **Alinhamento de branches** — `main` = `work` fast-forward (23+ commits v6–v8); `planning` merge + memória v5 preservada.
3. **Commit/push (pedido do usuário)** — `fd56c8d`, `0ffd912`, `647c242` pushed em `work`/`main`/`planning`. Repo limpo @ `647c242`.
4. **Propagação** — `propagate-if-changed` rodou ao merge em `main`; setup propagado a 6 projetos `~/dev/*` (0 erros).
5. **Verificação** — README 112/112 ✅ · idea-doctor 2 FAIL (secrets Jarvis/iCloud Projects — remediação manual).

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
