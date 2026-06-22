---
name: learning-curl-masks-cors-preflight-verify-browser
description: Um canal cross-origin validado SÓ por curl/exit-code pode estar quebrado no browser — curl não faz preflight CORS; o regime-R (visual loop) pega o que o exit-code não pega
metadata: 
  node_type: memory
  type: project
  originSessionId: 0252a118-7307-44d0-9330-f58e118941cf
---

Um `POST` **cross-origin** com header custom (ex.: `X-Cockpit-Token`) e `Content-Type: application/json` é "non-simple" → o browser dispara um **preflight `OPTIONS`** ANTES do POST. **curl NÃO faz preflight.** Logo um canal validado SÓ por curl (exit-code) pode passar verde e estar **completamente quebrado no browser** (`net::ERR_FAILED`) por falta de um handler `OPTIONS` que devolva os headers `Access-Control-Allow-Methods/Headers`.

Caso real: Cockpit v14.1, canal `POST /command` (⌘K). A fase foi verificada por curl/exit-code (A7 regime-F) e passou; o `frontend-visual-loop` (A7 regime-R) revelou que o SPA em `:5273 → :3073` falhava no preflight (`OPTIONS /command` caía no 404). Fix S-05: handler de preflight gated por `isTrustedOrigin` (204 só p/ origem confiável, 403 caso contrário; `Allow-Origin` exato, nunca `*`; `Vary: Origin`). A auth real do POST permanece intacta — o preflight só AUTORIZA o browser a enviar.

**Why:** o exit-code é lei para artefato-de-arquivo, mas o regime de runtime/UI tem modos de falha que o curl não reproduz (CORS, foco, render). Confiar só no curl viola "verify, don't assume" para superfícies de browser. Liga a [[learning-active-milestone-gate-couples-via-shared-file]] (verificação que parece completa mas não é) e ao princípio dos dois regimes em `antifragile-gates`.

**How to apply:** ao verificar um endpoint que um **browser** vai chamar cross-origin, rode o regime-R (navegar + screenshot + checar a aba Network por `ERR_FAILED`/preflight), não só curl. Para qualquer `POST`/`PUT`/`DELETE` cross-origin com header custom, garanta um handler `OPTIONS` fail-closed. Cross-link: skill `/frontend-visual-loop`, rule `antifragile-gates` (dois regimes de verificação).
