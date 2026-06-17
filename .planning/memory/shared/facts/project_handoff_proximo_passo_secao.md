---
name: project_handoff_proximo_passo_secao
description: "No handoff do IdeiaOS o próximo passo real vai na seção \"## Próximo passo\", não na \"## Ultima sessao automatica\" (regenerada pelo hook)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 32df5c2a-1220-4b2b-877f-3821faf9d3b2
---

O hook `source/hooks/session-summary.sh` regenera **idempotentemente** a seção `## Ultima sessao automatica (DATA)` do `docs/CONTINUATION_HANDOFF.md` ao fim de cada sessão — sempre com `- Próximo passo: (definir antes de retomar)` e o caminho do `.tmp` da sessão.

**Why:** qualquer texto útil escrito dentro dessa seção é sobrescrito na próxima rodada do hook (ele faz replace do bloco entre o marker e o próximo `## `).

**How to apply:** ao fechar sessão, escreva o próximo passo executável na seção `## Próximo passo` principal (que o hook NÃO toca) e documente o trabalho numa seção datada própria no topo do handoff (ex.: `## Sessão YYYY-MM-DD`). Deixe a seção automática para o hook gerenciar — não tente preenchê-la nem removê-la. Relacionado: [[feedback_session_closing_vault]].
