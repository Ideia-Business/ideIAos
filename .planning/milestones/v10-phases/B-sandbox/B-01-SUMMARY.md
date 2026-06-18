# B-01-SUMMARY — Fase B (sandbox) · COMPLETA

**Data:** 2026-06-18 · **Status:** ✅ CONCLUÍDA · **Veredito:** 🔴 **BLOQUEAR `publish` via MCP** (Fases C/D do write-path permanecem gateadas).

A Fase B rodou em duas metades: (1) **read-only** em produto real (zero crédito) e (2) **escrita ao vivo** num fork descartável (janela `deny→ask` aberta e fechada). A metade de escrita bateu num **muro estrutural de viabilidade**: o MCP da Lovable não expõe nem gerencia o gitsync GitHub, então A2 e A1-lag **não são mensuráveis num sandbox MCP**.

---

## Tabela das suposições (§2.5) — FINAL

| ID | Pergunta | Resultado | Evidência |
|----|----------|-----------|-----------|
| **A1-namespace** | `commit_sha` da Cloud é do mirror GitHub ou interno? | ✅ **ACOPLADO ao GitHub** | (read-only) `commit_sha` do `list_edits(nfideia)` casa 1:1 com `git log origin/main` (`c35b5207`, `a1151b79`, `76e9cee5`, …). |
| **A1-lag** | Lag `edit:completed → origin/main`? | 🟡 **INDETERMINADO (não-mensurável no sandbox)** | Fork não tem mirror GitHub → sem `origin/main` para observar propagação. Indício read-only de lag ≈ 0 (`ai_update 76e9cee5`: `created_at` = commit-date do git, ao segundo). |
| **A2** | `deploy_project` lê de `main` ou do estado interno? | 🟡 **INDETERMINADO (não-mensurável no sandbox)** | Teste de divergência exige `git push` ao `origin/main` do fork — que **não existe**. **Pior caso REFUTADO** pelo read-only: `developer_update` (git pushes) aparecem no `list_edits` → a Cloud **ingere** commits do Git; logo `publish` não ignora o Git por completo (resta risco de **lag de ingestão**, não de bypass total). |
| **A3** | `commit_sha` do `list_edits` casa com `git log`? | ✅ **PASS** | (read-only) 100% dos SHAs `completed` aparecem em `git log origin/main`. `detect-hotfix` no namespace certo. |
| **A4** | `query_database` aceita multi-statement? | ⏭️ **PULADO** | Fork sem DB (`enabled:false`) + `query_database` não-promovido. Não-bloqueante. |

---

## O MURO de viabilidade (achado central da metade de escrita)

O MCP da Lovable **não tem superfície para o gitsync GitHub**:
- `list_connectors(workspace)` — 50+ integrações (standard/seamless/mcp), **nenhuma é "github"**.
- `list_connections(workspace)` — 6 conexões ativas, **zero GitHub**.
- `get_project` — expõe `latest_commit_sha`, mas **nenhuma URL de repo nem campo gitsync**.
- **Empírico:** fork `1d0652c4` criado; seu `sha_0` `cac6c856…` **não existe em nenhum repo GitHub** (`gh search commits --hash` = `[]`); **nenhum repo** foi auto-criado na org; a própria fonte ("Mornings Day POA") **não tem repo** → gitsync é manual-por-projeto, só nos 5 produtos principais, **na UI do editor**.

**Consequência:** um fork remixado não herda nem auto-provisiona gitsync, e o MCP não consegue configurá-lo (`add_connector` está no `deny`). Sem `origin/main` no fork, o teste de divergência do A2 (e a medição de lag do A1) são **estruturalmente impossíveis via MCP**. Medir A2 exigiria configurar gitsync manualmente na UI do editor num projeto descartável — **fora do escopo de um experimento MCP autônomo**.

---

## VEREDITO — TABELA-VERDADE (mecânico)

Regra: **BLOQUEAR** se `(A2=interno)` OU `(A1=desacoplado/lag-indeterminado)` OU `(A3=FAIL)` OU `(fork não isolou backend)`.

| Condição | Estado | Vota |
|---|---|---|
| A1-namespace | ACOPLADO ✅ | liberar |
| A1-lag | INDETERMINADO 🟡 | **BLOQUEAR** |
| A2 | INDETERMINADO 🟡 | **BLOQUEAR** |
| A3 | PASS ✅ | liberar |
| fork backend isolado | SIM (DB disabled) ✅ | liberar |

➡️ **VEREDITO: 🔴 BLOQUEAR `publish` via MCP.** Indeterminado conta a favor de bloquear (regra do PLAN). Não se destrava uma capacidade irreversível e outward-facing com base em evidência incompleta. **A contenção atual (`deny=19`) permanece a postura correta do write-path.** As Fases C (schema-check) e D (write-path + compiler) seguem gateadas até que A2 seja medido por outro caminho.

**Nuance (não muda o veredito, mas caracteriza o risco):** o pior cenário do A2 — "deploy ignora o Git por completo" — está **refutado**: o read-only mostrou que git pushes (`developer_update`) entram no histórico da Cloud. O risco residual real é **lag de ingestão Git→Cloud**, não bypass total. Isso torna o BLOQUEIO conservador (correto), mas sinaliza que um teste futuro bem-feito tende a LIBERAR sob gates.

---

## Achado de SEGURANÇA da contenção (bônus)

O `permissions.deny` **é relido mid-session e bloqueia de fato** as mutações MCP: o `remix_project` só funcionou **depois** de `lovable-window.py open` (deny=14) e o assert pós-`close` (deny=19) passou. Ou seja, a contenção do harness não depende de restart — o deny vale ao vivo. (Questão menor em aberto: se o harness exibiu prompt `ask` por chamada durante a janela — não confirmado nesta sessão; não afeta o veredito.)

---

## Custo

- Saldo pré: 100/0 em ambas as workspaces (sem mudança material).
- Mutações cobradas: 1 remix bem-sucedido (`Mornings Day POA` → fork). 1 tentativa de remix do cfoai **falhou** (Supabase) e **não criou projeto** (0 órfão). Bem abaixo do teto (≤8).

## Forks pendentes de deleção manual do usuário

| Fork | project_id | Estado | Ação |
|---|---|---|---|
| **SANDBOX-FASEB-DELETAR-2** | `1d0652c4-5477-49cc-bafd-70761a7f9fd6` | `private` + `unpublished` (contido, não-público) | **Deletar no painel Lovable** (não há `delete_project` no MCP). `editor_url`: https://lovable.dev/projects/1d0652c4-5477-49cc-bafd-70761a7f9fd6 |

(A tentativa falha do cfoai não deixou projeto — confirmado por `list_projects(query=SANDBOX)` = 0 antes do fork-2.)

---

## Recomendação para C/D

1. **Manter `publish`/write-path BLOQUEADO** (postura read-first do v10 confirmada pela evidência).
2. Para eventualmente destravar: medir A2 **fora do MCP** — configurar gitsync manual na UI do editor num projeto 100% descartável, fazer 1 `git push` divergente, 1 deploy, e inspecionar o bundle. Só então reavaliar a tabela-verdade.
3. As Fases A (`verify-deploy`/`detect-hotfix`) **não dependem do A2** e seguem operacionais — o read-only já está provado (A1-namespace ACOPLADO + A3 PASS).
