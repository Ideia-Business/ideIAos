---
name: project_changelog_vault
description: Estrutura Changelog/ no vault Obsidian + protocolo de fechamento atualizado para incluir registro de entregas
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Estrutura `Changelog/` criada no vault em 2026-06-08. Cada projeto tem uma nota com histórico de entregas por milestone (mais recente primeiro), com: data, impacto para usuários, o que foi entregue, decisões técnicas.

**Protocolo de fechamento atualizado (CLAUDE.md.tmpl + 4 projetos):**
Todo fechamento de sessão com entrega relevante deve agora incluir o passo:
"Registrar em `Changelog/<Projeto>.md` no vault Obsidian com data, impacto e o que foi entregue."

**Pendência de produto registrada:**
- NFideia: changelog voltado ao usuário ("Novidades") — registrado em `nfideia/docs/CONTINUATION_HANDOFF.md` P2 #4
- Ideiapartner: idem — registrado em `ideiapartner/docs/CONTINUATION_HANDOFF.md` P3 (novo)
- Lapidai: já tem implementação (referência)
- CFO AI: não se aplica (ferramenta interna, 2 usuários)

**Why:** Gustavo identificou que os projetos não tinham área de evolução documentada — nem interna (histórico de entregas) nem externa (changelog para usuários).

**How to apply:** Ao encerrar sessão com feature/fix relevante, sempre atualizar `Changelog/<Projeto>.md`. Ao retomar NFideia ou Ideiapartner, lembrar da pendência de feature "Novidades" para usuários.
