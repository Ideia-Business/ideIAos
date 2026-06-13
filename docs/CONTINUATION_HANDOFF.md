# Handoff — continuar em outro turno

**Projeto:** `IdeiaOS` · **Branch:** `work` (= main) · **Atualizado:** 2026-06-13

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

1. Aplicar o novo padrão AIOX nas máquinas: `cd ~/dev/IdeiaOS && git pull && bash scripts/ideiaos-update.sh`.
2. Em clone novo / máquina nova, regenerar o engine por projeto: `npx aiox-core@latest install` (personas e `/idea` já são globais — funcionam sem isso).
3. Depois, `/gsd-new-milestone "IdeiaOS v5"` se desejar abrir o próximo ciclo.

## Ultima sessao automatica (2026-06-13)

- Sessão salva em: `/Users/gustavolopespaiva/.claude/sessions/2026-06-13-ideiaos-cb9a23f7-4792-4d92-badf-78feaf46.tmp`
- Próximo passo: (definir antes de retomar)
