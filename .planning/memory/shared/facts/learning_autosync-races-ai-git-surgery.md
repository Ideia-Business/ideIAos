---
name: learning-autosync-races-ai-git-surgery
description: O git-autosync (add -A + commit + push em ciclo) ATROPELA cirurgia git de IA — contamina commits por pathspec e bloqueia pushes; pause-o (com restauração garantida) antes de entregas git multi-repo
metadata: 
  node_type: memory
  type: project
  originSessionId: 42c36737-b3a2-418a-95f3-f4ec2664e30c
---

Durante uma entrega git em múltiplos repos sob autosync, o daemon `com.ideiaos.gitautosync` (LaunchAgent, roda a cada 15 min + on-demand) causou DOIS modos de falha simultâneos:

1. **Contaminação de commit por pathspec:** ao rodar `git rm --cached .env` + `git commit -- .env .gitignore`, o autosync correu em paralelo, fez `git add -A` e criou seu PRÓPRIO commit (`wip: autosync …`) varrendo arquivos NÃO relacionados para dentro — inclusive `package-lock.json` e um `CONTINUATION_HANDOFF.md` com **marcadores de conflito de merge não resolvidos** (`<<<<<<<`), e já empurrou para origin. O `git commit -- pathspec` da IA então falhou com "pathspec did not match" porque o índice já fora limpo.
2. **Push bloqueado por divergência:** noutro repo (clone defasado, 78 commits atrás do origin via autosync de outra máquina), o commit local não fazia fast-forward → push rejeitado; resolver exigiria rebase/merge ou --force.

**Why:** `git add -A` periódico é incompatível com commits cirúrgicos por pathspec — qualquer arquivo sujo no working tree (mesmo lixo auto-gerado por hooks, ou marcadores de conflito) vira parte do commit do autosync. E clones defasados + autosync de outra máquina geram divergência que bloqueia push.

**How to apply:** Antes de QUALQUER entrega git assistida por IA em repos sob autosync (especialmente multi-repo): **(1)** confirme o plist (`~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`) para garantir a restauração ANTES de pausar; **(2)** pause: `launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync`; **(3)** faça os commits/pushes limpos (para clone defasado: `git stash` → `git reset --hard origin/<branch>` → reaplica a mudança num commit limpo → push fast-forward); **(4)** RESTAURE: `launchctl bootstrap gui/$(id -u) <plist>` e confirme `launchctl list | grep gitautosync`. Pausar o autosync é escopo além de "commit/push" — o classifier bloqueia sem autorização explícita do usuário; peça. Tudo recuperável via reflog/stash se algo der errado. Relacionado: [[autosync-pushes-feature-branches]], [[learning-claude-settings-deny-live-reload-autosync-capture]], [[learning-temp-privilege-window-teardown-grants]].
