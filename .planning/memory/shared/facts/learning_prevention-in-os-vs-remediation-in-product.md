---
name: prevention-in-os-vs-remediation-in-product
description: "Ao escopar milestone do IdeiaOS, separe PREVENÇÃO (constrói no OS) de REMEDIAÇÃO de instâncias antigas (housekeeping nos repos-produto) — não misture num requisito só"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6894cb82-2e04-4b3c-8682-fa14d0531c0f
---

Ao escrever requisitos de um milestone do IdeiaOS que cria uma barreira/guard, **separe duas coisas que parecem uma**:
- **Prevenção** — guard, `.gitignore`, doctor-check, hooks. É construção de framework → vive no **IdeiaOS** e é o deliverable do milestone.
- **Remediação** — limpar instâncias pré-existentes do problema que já estão em **repos-produto** (nfideia, ideiapartner, etc.). É housekeeping operacional de OUTRO repo.

Caso real (v5, R5-01): o requisito juntou "criar prevenção de leak" (IdeiaOS) com "remover o `.lovable_mem_tmp.md` que já estava em `nfideia:main`". Isso criou confusão de "pra onde gravar?", coupling cross-repo, e um falso flag de "milestone incompleto" — quando o trabalho de v5 já estava 100% no IdeiaOS. O usuário pegou: "isso devia ser no IdeiaOS, não no nfideia?".

**Why:** misturar os dois acopla o milestone do framework ao estado de um repo de produção em dev ativo (branch mudando, working tree sujo, autosync) — coisas que a IA não deve dirigir e que travam o fechamento do milestone por algo que nem é trabalho dele.

**How to apply:** no REQUIREMENTS, escreva a prevenção como requisito do milestone (verificável no IdeiaOS) e liste a remediação de instâncias antigas como **item operacional separado**, fora do "done" do milestone, a ser feito no repo-produto quando estiver calmo. A prevenção bem-feita (guard + gitignore) já contém o problema — a remediação vira opcional/sem urgência. Pareia com [[git-info-exclude-branch-agnostic-ignore]] e [[verify-guards-in-sandbox-not-live-repo]].
