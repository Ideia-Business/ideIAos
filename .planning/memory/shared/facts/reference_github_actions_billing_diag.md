---
name: reference-github-actions-billing-diag
description: Diagnóstico de falhas de CI em massa na org Ideia-Business — billing vs bug real
metadata: 
  node_type: memory
  type: reference
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Quando MUITOS workflows do GitHub Actions falham ao mesmo tempo em vários repos privados da org **Ideia-Business** (enxurrada de emails "Run failed"), o suspeito #1 é **billing**, não bug de código.

**Assinatura do problema de billing:** o job falha instantâneo, `gh run view --log-failed` vem **vazio**, e a annotation (`gh api repos/.../check-runs/<jobid>/annotations`) revela: *"The job was not started because recent account payments have failed or your spending limit needs to be increased."* Resolução é do usuário (cartão/limite no painel de Billing) — afeta só repos **privados** (Actions é grátis em público).

**Como diferenciar de bug real:** bug real tem log com `##[error]` específico (ex.: ideia-chat CI quebrava por `tsc --noEmit` type-checando `.test.ts`). Lição secundária: testes `.test.ts` em projeto Next sem runner devem usar `node:test` + `node:assert/strict` (não globals jest `describe/it/expect`, que dão TS2582/TS2304 sem `@types/jest`).

**Limpeza feita 2026-06-15:** nfideia 5→3 workflows, ideiapartner 7→2 (removidos browserslist duplicado, A11y Empty States, INC 350/351 close, Canonical Runtime Audit, Doc Duplicate Guard, Bundle Guard). Comandos úteis: `gh workflow list --repo X`, `gh run list --repo X --workflow "N" --status failure`.
