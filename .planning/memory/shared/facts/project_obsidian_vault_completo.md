---
name: project_obsidian_vault_completo
description: "Obsidian Second Brain — vault completamente populado em 2026-06-08 com todos os projetos, referências, gotchas e changelogs"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Vault Obsidian da Ideia Business completamente populado em 2026-06-08.
Caminho: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideia Business - Second Brain`
Acesso: filesystem direto (`grep -rIl`) — sem MCP, sem plugin.

**Conteúdo do vault:**
- `Projects/`: IdeiaOS, Ideiapartner, NFideia, CFO AI - Grupo RI, Lapidai
- `References/`: Supabase, Lovable Cloud, Asaas, Stripe
- `Stack Gotchas/`: RLS silencioso no Supabase, Lovable deploy drift, Sync pesado esgota pool
- `Changelog/`: NFideia, Ideiapartner, CFO AI - Grupo RI, Lapidai
- `Learnings/`: Auditoria de rules Cursor ao introduzir alwaysApply
- `_Templates/`: Learning, Project, Decision, Reference
- `00 Index.md`: índice completo com navegação para tudo

**Why:** Gustavo pediu que todos os projetos fossem documentados em detalhes no vault para que qualquer IA futura pudesse abrir o Obsidian e entender plenamente cada sistema.

**How to apply:** Ao iniciar sessão em qualquer projeto, `/recall-learnings` (Passo 5) já busca no vault automaticamente. Ao encerrar sessão com entrega relevante, atualizar `Changelog/<Projeto>.md`.
