---
name: learning-daemon-cwd-fix-needs-whole-file-sweep
description: "Fix de dependência-de-cwd num daemon deve varrer o arquivo inteiro, não só o ponto comentado; warn em log append pode ser resíduo"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2bc6b4ee-e331-4ec9-ae8f-bed36cd18a66
---

Ao corrigir uma dependência de **cwd / path-relativo** em código que roda como **daemon**
(launchd/systemd/cron), trate como defeito de ARQUIVO, não de linha: o daemon não herda o cwd
interativo (roda em `/` ou home), então `process.cwd()`/paths-relativos quebram em silêncio.

**Why:** quando alguém corrige UM ponto, costuma deixar um comentário ("ancorado em __dirname porque
sob o daemon o cwd não é o repo") — esse comentário é a prova de que o arquivo tem MAIS pontos com o
mesmo bug, mas o autor raramente varre os irmãos. Fix parcial: o ponto comentado funciona, os
silenciosos seguem quebrados até o daemon rodar de verdade. Visto em IdeiaOS `collect.js` (R15-12 só
ancorou o `versions.lock`; `soakDir` e a chamada `check-security-freshness.sh` ficaram cwd-dependentes
→ `safeExec warn` + `security_freshness` ausente do snapshot; commit 9d9e129).

**How to apply:**
1. Ao tocar cwd num daemon, `grep` o arquivo inteiro por `process.cwd()`/getcwd/paths-relativos e
   ancore TODOS numa constante raiz `__dirname`-based.
2. Para subprocessos (exec de script), use path absoluto **E** passe `cwd` explícito (o filho pode ter
   a própria dependência, ex: `git diff`).
3. Verifique no regime REAL do daemon (rodar de `cwd=/tmp` simula; `launchctl kickstart`/`systemctl
   start` prova). "Funciona quando rodo do repo" não vale.
4. Armadilha: warn em log de daemon é *append* — a última linha pode ser resíduo de run pré-fix.
   Trunque o log + force run fresco + observe o novo; confira se o warn aparece 1× (resíduo) ou N×.

Cross-link [[project-cockpit-daemon-nvm-install-and-cwd]] (gotcha de domínio da mesma sessão) e
[[autosync-durability-hardening]] (mesmo eixo launchd/nvm). Repo: docs/learnings/2026-06-26-daemon-cwd-fix-needs-whole-file-sweep.md
