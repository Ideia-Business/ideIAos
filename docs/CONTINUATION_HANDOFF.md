# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-06-12

## 🏁 PLANO MAIOR 100% CONCLUÍDO

3 milestones shipped em 2026-06-12: **v2.0** (absorção ECC, 8 fases) → **v3** (refinamento, 5 fases) → **v4** (produção, 3 fases). 16 fases, 42 planos, tags v2.0/v3.0/v4.0. Auditorias: 8/8, 19/19, 8/9+1warn.

## ✅ AÇÃO LIBERADA: atualizar as máquinas

```
cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh
```

## Decisões registradas (2026-06-12)

1. **Secret ANTHROPIC_API_KEY: NÃO** — evals LLM só localmente (`bash evals/run-evals.sh --ci`); job de CI skipa limpo por design
2. **Repo: manter PRIVADO** — marketplace funciona nas máquinas autenticadas; público só se quiser distribuir como open source
3. ~~checkout@v4→v5~~ ✅ aplicado (151132a)

## v5 — Fase 17 CONCLUÍDA (2026-06-12)

Critérios de eval robustos entregues: avaliador híbrido Sinais + LLM-judge, 22 casos atualizados, 3 vereditos corrigidos fail→pass. Ver `17-01-SUMMARY.md`.

**Feature Novidades — ✅ CONCLUÍDA nos 2 produtos (2026-06-12, branches aguardando o usuário):**
- **NFideia**: branch `feature/novidades-portal` (bab37b99) — migration com 2 entradas categoria portal (planilha no lote + XML/cancelar). Produção: merge + aplicar migration; Lovable Publish NÃO necessário (só dados).
- **Ideiapartner**: branch `feature/novidades` (d124e409) — feature completa: release_notes + reads (RLS), UserChangelog (Sheet), badge não-lidas no header, seed 3 entradas, tsc zero erros. Produção: review + merge → Lovable publica → migration via SQL Editor.
- Deploy em produção É DECISÃO DO USUÁRIO — nada foi mergeado nem aplicado em prod.

## Próximo passo

Atualizar máquinas (`git pull && bash scripts/ideiaos-update.sh`); depois `/gsd-new-milestone "IdeiaOS v5"` se desejado.

## Ultima sessao automatica (2026-06-12)

- Sessão salva em: `/Users/gustavolopespaiva/.claude/sessions/2026-06-12-ideiaos-0dc39c83-3226-4cda-8042-33b2fb9f.tmp`
- Próximo passo: (definir antes de retomar)
