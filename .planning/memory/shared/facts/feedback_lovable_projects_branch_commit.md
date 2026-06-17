---
name: feedback-lovable-projects-branch-commit
description: "Em projetos Lovable, commits de IA vão para branch (nunca main automática); cuidar só dos Lovable — IdeiaOS pode ir direto na main"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Regra do usuário (2026-06-16): ao commitar trabalho em repositórios, **a cautela de não tocar a `main` automaticamente vale APENAS para os projetos gerenciados pela Lovable**. Para projetos que NÃO estão na Lovable (como o próprio **IdeiaOS**), pode commitar direto na main sem cerimônia.

**Como identificar um projeto Lovable:** `package.json` tem `lovable-tagger` e `vite.config.ts` importa/usa `componentTagger()` da lovable-tagger. Projetos Lovable confirmados: **nfideia** (verificado), e provavelmente **ideiapartner**, **cfoai-grupori**, **lapidai** (todos produtos). **IdeiaOS NÃO é Lovable.**

**Why:** a Lovable observa a branch de produção (main) e pode disparar build/deploy ao detectar push. Commitar docs/artefatos diretamente na main de um projeto Lovable arrisca um deploy não intencional.

**How to apply:** em projeto Lovable, criar uma branch dedicada (ex.: `spec/<capability>-pilot`) e commitar lá; **não dar push automático** — oferecer ao usuário. Em projeto não-Lovable (IdeiaOS), seguir o fluxo normal (work→main / commit direto). Aplicado no piloto `/spec` do nfideia (branch `spec/multi-tenancy-pilot`, não pushada). Relaciona-se a [[feedback-readme-update-no-final]].
