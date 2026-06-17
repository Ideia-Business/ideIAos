---
name: project-milestone-v3-completo
description: Milestone v3 shipped em 2026-06-12 (mesmo dia do v2.0) — loop de instincts provado ao vivo; próximo é v4 a definir
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Milestone **v3 — Refinamento pós-auditoria** shipped em 2026-06-12, tag `v3.0` (5 fases 09-13, 19 reqs, 15/15 gaps G-01..G-15, auditoria 19/19). `work` = `main`, ambas pushed.

**Fato-chave:** o loop de Continuous Learning está FUNCIONANDO em produção nesta máquina — hooks capturam, Stop hook com gate de sentinela spawna haiku headless, instincts em `~/.ideiaos/instincts/project/ideiaos--*.md` (50 gerados no teste vivo). Quando houver instincts ≥0.7, rodar `/evolve` para promover ao vault.

**Bugs sistêmicos corrigidos no teste vivo** (lição: teste vivo > verificação estrutural): skills não eram instaladas do manifesto (novo setup.sh step 5.21b) e slug de projeto divergia entre hooks (lowercase sanitizado) e skills (basename cru).

**Pendências:** MacBook rodar `ideiaos-update.sh` para pegar v3; conferir GitHub Actions verde no primeiro push em evals/; secret ANTHROPIC_API_KEY opcional para job LLM.

**Próximo:** `/gsd-new-milestone "IdeiaOS v4"` — candidatos: instinct-loop multi-projeto, evals LLM em CI, marketplace público. Relacionado: [[project-milestone-v2-completo]].
