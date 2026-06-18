# B-01-SUMMARY — Fase B (sandbox) · metade READ-ONLY executada

**Data:** 2026-06-18 · **Status:** 🟡 PARCIAL — A1-namespace + A3 respondidas read-only (zero crédito, zero risco, sem deny-lift). A1-lag + A2 ainda exigem o experimento de escrita gateado.

## Como foi feito (sem mutação)

Descoberta-chave: `list_edits`/`get_project`/`get_diff` são **read-only** (não estão no harness-deny) e os produtos têm o mirror GitHub local em `~/dev/`. Logo, A1-namespace e A3 se medem num **produto REAL** (mais rigoroso que num fork), sem `remix_project`, sem crédito, sem abrir janela.

Método: `list_edits(nfideia)` (20 edits, `bf83d98a-…`) × `git log origin/main` do `~/dev/nfideia` (remote `github.com/Ideia-Business/nfideia`).

## Tabela das suposições (§2.5)

| ID | Pergunta | Resultado | Evidência |
|----|----------|-----------|-----------|
| **A1-namespace** | `commit_sha` da Cloud é do mirror GitHub ou interno? | ✅ **ACOPLADO ao GitHub** | Todo `commit_sha` do `list_edits` casa 1:1 (SHA-cheio) com `git log origin/main`: `c35b5207`, `a1151b79`, `081c385e`, `b7b41495`, `c50bcaee`, `87b2a36f`, `a323bb41`, `96135c30`, `b5e68812`, `76e9cee5`. |
| **A1-lag** | Lag `edit:completed → origin/main`? | 🟡 **não-medido (magnitude)** — mas indício forte de ~0 | O `ai_update` `76e9cee5` tem `created_at`=`2026-06-18T02:00:01Z` **idêntico** ao commit-date no git (`02:00:01 +0000`). Coincidência ao segundo sugere acoplamento apertado; magnitude real exige observar 1 edit fresco propagar (precisa `send_message`). |
| **A2** | `deploy_project` lê de `main` ou do estado interno? | 🟡 **não-medido** — exige fork + deploy com divergência controlada (Task 3 do PLAN). Permanece o único gate real de `publish`. |
| **A3** | `commit_sha` do `list_edits` casa com `git log`? | ✅ **PASS** | 100% dos SHAs `completed` aparecem em `git log origin/main`. `detect-hotfix` da Fase A opera no namespace correto. |

## Achados não-óbvios (read-only)

1. **Mirror bidirecional confirmado:** o `list_edits` traz tanto `type: developer_update` (meus commits via `git push`) quanto `type: ai_update` (commits do agente Cloud, ex.: `76e9cee5` "Rescan security concluído"). Ambos no MESMO namespace de SHA do GitHub. O agente Cloud **escreve no mirror** — o problema dos "dois escritores" é real e visível no histórico.
2. **`status` do `list_edits` = status de BUILD da Lovable, não do git:** o edit `c35b5207` ("Wave 0") aparece `status: failed` no `list_edits`, mas o commit `c35b5207` ESTÁ em `origin/main` (push de dev que quebrou o build Cloud, mas existe no GitHub). Implicação para `verify-deploy`/`detect-hotfix`: não confundir "build falhou na Lovable" com "commit ausente no Git".

## VEREDITO (tabela-verdade do PLAN — parcial)

Regra: BLOQUEAR se `(A2=interno)` OU `(A1=desacoplado/lag-indeterminado)` OU `(A3=FAIL)`.

- A1-namespace = ACOPLADO ✅ · A3 = PASS ✅ → **dois dos três riscos de desacoplamento RETIRADOS.**
- A2 = ainda não medido + A1-lag (magnitude) ainda não medido → **write-path PERMANECE BLOQUEADO até o experimento de escrita gateado** (Tasks 1-3 do PLAN: fork + `send_message` para medir lag + `deploy_project` com divergência `GIT-ONLY-PROBE` para resolver A2).

**Efeito líquido:** o experimento de escrita restante ficou **muito mais estreito e de menor risco** — já sabemos que o mirror é acoplado e que o agente Cloud commita no GitHub; resta só medir o **lag** e a **fonte de leitura do `deploy_project`**.

## Forks pendentes de deleção manual do usuário

Nenhum — nenhuma mutação foi feita nesta metade. (Quando a metade de escrita rodar, registrar aqui `F.project_id` + `preview_url`.)
