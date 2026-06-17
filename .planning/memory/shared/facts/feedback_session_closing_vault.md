---
name: feedback_session_closing_vault
description: Protocolo de fechamento de sessão inclui atualização do vault Obsidian — Changelog e extract-learnings
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

O fechamento obrigatório de sessão em todos os projetos da Ideia Business inclui passos relacionados ao vault:

1. `/extract-learnings` (gate triplo: replicável + não-óbvio + estável) → promove learnings para `Learnings/` no vault
2. Se houve entrega relevante → registrar em `Changelog/<Projeto>.md` no vault
3. Se houve **decisão arquitetural/estratégica** (ADR em `docs/decisions/` do repo) → espelhar em `Decisions/<Título legível>.md` no vault, com `[[link]]` no Changelog e registro no `00 Index.md`.

**Why:** Gustavo quer que o vault seja a fonte de verdade de conhecimento e evolução dos projetos, alimentado a cada sessão, para que futuras IAs (e humanos) possam abrir o Obsidian e entender completamente cada sistema.

**Gap encontrado (2026-06-13):** a sincronização repo→vault é MANUAL (não há hook). A pasta `Decisions/` ficou **vazia de 28/mai a 13/jun** mesmo o Index a anunciando — ninguém espelhava os ADRs. Corrigido ao espelhar os 2 ADRs do IdeiaOS; passo 3 acima existe para não repetir. Sintoma típico: `Changelog/<Projeto>.md` defasa em relação aos commits (ver [[project_handoff_proximo_passo_secao]] para o gap análogo no handoff).

**How to apply:** Em todo fechamento não-trivial: (1) `/extract-learnings`; (2) `Changelog/<Projeto>.md` se houve entrega; (3) espelhar ADRs novos em `Decisions/` — agora **encodado** na skill `extract-learnings` (Passo 4c, commit `caf5ad8`). Os passos 1-2 estão no CLAUDE.md de todos os projetos.
