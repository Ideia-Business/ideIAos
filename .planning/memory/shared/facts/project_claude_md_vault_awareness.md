---
name: project_claude_md_vault_awareness
description: "Todos os CLAUDE.md dos projetos atualizados com seção \"Segundo Cérebro\" referenciando o vault Obsidian"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Em 2026-06-08, todos os CLAUDE.md dos projetos foram atualizados para incluir a seção "Segundo Cérebro (Obsidian Vault)", informando a IA de:
- Que o vault existe e tem documentação permanente do projeto
- Qual nota cobre o projeto: `Projects/<NomeProjeto>.md`
- Que `/recall-learnings` (Passo 5) consulta o vault automaticamente via `grep`
- O caminho do vault

**Arquivos atualizados:**
- `IdeiaOS/templates/hybrid/CLAUDE.md.tmpl` — template para novos projetos
- `lapidai/CLAUDE.md`
- `nfideia/CLAUDE.md`
- `cfoai-grupori/CLAUDE.md`
- `ideiapartner/CLAUDE.md`

**Why:** Os projetos precisavam "saber" explicitamente que têm um segundo cérebro permanente — não apenas via skill recall-learnings, mas declarado no CLAUDE.md que é lido no início de toda sessão.

**How to apply:** Projetos novos gerados a partir do template já nascem com essa consciência. Os 4 projetos existentes já estão atualizados.
