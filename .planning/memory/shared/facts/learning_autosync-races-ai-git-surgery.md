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

**ATUALIZAÇÃO 2026-06-21 (sessão headroom):** a corrida morde mesmo em trabalho **single-repo multi-step** — não é só multi-repo. Criei ~6 arquivos de uma skill na `work` sem pausar; o autosync disparou no meio (commit `ddf6bca` "wip: autosync") e varreu tudo (meus arquivos + um `CONTINUATION_HANDOFF.md` de OUTRA sessão) para um commit wip, fazendo meu `git add <pathspec> && git commit` falhar com "nothing to commit". Nada se perdeu (tudo foi pro origin), mas virou commit wip sujo em vez do meu `feat:` limpo. Regra refinada: **pause para QUALQUER trabalho git multi-step (criar/editar+commitar vários arquivos), não só multi-repo.**

**MÉTODO SANCIONADO (substitui o launchctl bootout manual desta memória):** `scripts/autosync-pause.sh on [motivo]` cria um pause-file (`~/.local/state/git-autosync.pause`) que o daemon respeita (sai cedo, no-op) — sem bootout/bootstrap frágil. Retomar = `scripts/autosync-pause.sh off`. **Teardown garantido:** rode o `off` INCONDICIONALMENTE depois (mesmo se o commit falhar) — comprovado nesta sessão (2 janelas pausadas, ambas retomadas via `off` no mesmo bloco do commit). `status` mostra o estado. (Para pausar 1 repo só: criar `<repo>/.git/autosync-pause`.)

**How to apply (legado, pré-script):** se o script não existir, o método antigo era `launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync` → trabalho limpo → `launchctl bootstrap gui/$(id -u) <plist>`. Tudo recuperável via reflog/stash. Relacionado: [[autosync-pushes-feature-branches]], [[learning-claude-settings-deny-live-reload-autosync-capture]], [[learning-temp-privilege-window-teardown-grants]].
