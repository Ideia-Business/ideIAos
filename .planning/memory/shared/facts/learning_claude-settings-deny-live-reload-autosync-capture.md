---
name: learning-claude-settings-deny-live-reload-autosync-capture
description: "Janela temporária de permissão no .claude/settings.json: o deny é RELIDO mid-session (sem restart) E um auto-committer/autosync pode CAPTURAR a janela aberta — nunca faça git checkout cego p/ limpar; compare os SETS deny de HEAD×working tree."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Ao abrir/fechar uma **janela temporária** de permissão no `.claude/settings.json` (mover tools `deny`→`ask` p/ uma operação gateada e reaplicar `deny`), dois fatos operacionais valem (Claude Code, qualquer projeto):

1. **Reaplicação vale ao vivo** — a mudança em `permissions.deny`/`ask` é relida **mid-session**; não precisa restart. O `open` e o `close` fazem efeito na hora (comprovado: `remix_project` só funcionou após `open`; bloqueou de novo após `close`).
2. **Auto-committer captura o estado transitório** — um autosync em background pode fotografar a janela **ABERTA** (contenção reduzida) e empurrá-la ao remoto; o estado seguro só volta quando o **seu commit de fechamento vira o HEAD**.

**Why:** combinados, criam uma armadilha — ao "limpar o diff" do settings.json, um `git checkout`/revert cego pode reverter para o **estado-aberto** capturado pelo autosync, **reabrindo a janela**.

**How to apply:** (a) use script idempotente `open|close` + `WINDOW-STATE.json` durável + assert binário no close (`deny==N E ask==0 E allow==0`); (b) garanta que o **commit de fechamento seja o HEAD**; (c) p/ limpar, **compare os sets deny HEAD×working tree** antes de qualquer revert — nunca checkout cego num arquivo de permissão que esteve aberto; (d) mantenha a janela na branch de trabalho, nunca propague aberta à main. Nota: `disabledMcpServers` **não** contém connector OAuth account-level ao vivo — só `permissions.deny` bloqueia de fato.

Evidência: milestone v10 Fase B — autosync `ead28b5` capturou `deny=14/ask=5`; set-diff abortou um checkout que reabriria; close `2a87a5c` restaurou `deny=19`. Repo: `docs/learnings/2026-06-18-claude-settings-deny-live-reload-and-autosync-capture.md`.

Relaciona-se a [[autosync-pushes-feature-branches]], [[learning-temp-privilege-window-teardown-grants]] e [[project-lovable-mcp-v10-candidate]].
