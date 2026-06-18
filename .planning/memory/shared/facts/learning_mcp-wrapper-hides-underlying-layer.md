---
name: learning-mcp-wrapper-hides-underlying-layer
description: Um MCP/wrapper pode abstrair justamente a camada (Git/DB/FS) que sua verificação precisa manipular — acoplamento observável (read-only) ≠ acoplamento endereçável (a API te dá handle p/ mexer). Sonde a viabilidade ANTES de desenhar o experimento.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Quando um experimento/feature depende de **manipular** uma camada subjacente (Git, DB, filesystem, fila) através de um wrapper (MCP, SDK, plataforma no-code), confirme **antes de planejar a manipulação** que o wrapper te dá um **handle endereçável** para essa camada (URL de repo, connection id, path, endpoint).

**Why:** o acoplamento ser real e observável read-only (ex.: SHAs da Cloud == SHAs do `git log`) **não** implica que ele seja endereçável pela API. Desenhar o experimento assumindo "se estão acoplados, mexo em ambos" leva a um muro **estrutural** descoberto só na execução, depois de gastar crédito/recurso.

**How to apply:** rode uma **sonda read-only de viabilidade** primeiro — *"a API me devolve handle p/ essa camada?"*. Se não, o teste de manipulação é inviável por esse caminho → re-desenhe (medir por fora do wrapper) ou declare **indeterminado** (que, em decisão de segurança, vota **bloquear**). Não confie em feature-flag ligado (`gitsync_github:true`) como prova de superfície exposta — pode ser só-UI. Não insista em "mais um alvo" quando o limite é a API, não o projeto.

Evidência: milestone v10 Lovable MCP, Fase B — o MCP acopla Cloud↔GitHub (provado read-only) mas **não expõe/gerencia o gitsync** (sem connector github, `get_project` sem URL de repo, `add_connector` negado, fork sem repo via `gh search commits`) → A2/A1-lag inmensuráveis → veredito BLOQUEAR. Repo: `docs/learnings/2026-06-18-mcp-wrapper-may-hide-the-layer-your-experiment-depends-on.md`.

Relaciona-se a [[project-lovable-mcp-v10-candidate]] e [[learning-temp-privilege-window-teardown-grants]].
