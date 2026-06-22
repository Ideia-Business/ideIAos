---
name: learning-autosync-pause-file-guard-not-deployed
description: "O guard de pause do git-autosync pode estar ausente do binário DEPLOYADO mesmo existindo na fonte — um binário deployado pode driftar atrás do heredoc. FIXED na Mac mini 2026-06-21 (patcher ideiaos-update.sh step 2d). Verifique com grep, não confie em \"status PAUSADO\"."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 146e6aba-0a22-495c-9758-caf9927b4217
---

`scripts/autosync-pause.sh on` grava `~/.local/state/git-autosync.pause`, mas em 2026-06-21 o binário **deployado** `~/.local/bin/git-autosync` da Mac mini **não tinha o guard de pause-file** — então a pausa era INERTE e o daemon capturou um write de executor mid-build (`a16907a wip: autosync`) e empurrou `work`. Causa raiz: **drift de 2 vias** entre o binário deployado e a fonte canônica (heredoc do `setup-dev-machine.sh`). O guard JÁ EXISTIA na fonte (heredoc + patcher `ideiaos-update.sh` step 2d); o binário é que estava velho (pré-guard) e ainda por cima tinha meu `push_cockpit_ref` ad-hoc do v14.0 que nunca subiu ao heredoc.

**Why:** "status PAUSADO" do `autosync-pause.sh` prova só que o ARQUIVO existe, NÃO que o daemon o respeita. Um binário deployado pode estar atrás (e/ou à frente) da sua fonte. Confiar na abstração sem verificar o binário em execução é verificação enganosa.

**How to apply (FIXED na Mac mini, mas vale p/ qualquer máquina):**
1. Verifique o binário REAL: `grep -c 'git-autosync.pause' ~/.local/bin/git-autosync` (0 = guard ausente = pausa inerte).
2. Se ausente, deploy o guard **sem regredir** features locais: rode o patcher idempotente `scripts/ideiaos-update.sh` step 2d (grafa pause-file + conflict-marker guards preservando `push_cockpit_ref`). NÃO re-rode `setup-dev-machine.sh` cru se o binário tiver edits locais que não estão no heredoc — ele regenera do heredoc e DELETA o que faltar lá (foi o caso do `push_cockpit_ref`).
3. Reconcilie o heredoc do `setup-dev-machine.sh` com qualquer feature que só esteja no binário (provei convergência: `diff` código heredoc-body × binário vivo = vazio).
4. Teste determinístico: `touch ~/.local/state/git-autosync.pause; ~/.local/bin/git-autosync <repo-path>` → tem que logar `pausado (pause-file)` e sair 0 sem commit/push; depois `rm` o pause-file.
5. **Enquanto o guard não estiver deployado**, pause de verdade com `launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync` e restaure com `launchctl bootstrap`.

**Cross-máquina:** o fix de 2026-06-21 foi aplicado só na **Mac mini** (binário) + no repo (heredoc, commit `2dcf2bc`). Outras máquinas (ex.: MacBook-Air-2) só ganham o guard ao rodar `ideiaos-update.sh` step 2d ou `setup-dev-machine.sh` — até lá, o binário delas pode estar igualmente inerte. Liga a [[learning-autosync-races-ai-git-surgery]] e [[learning-autosync-pushes-feature-branches]].
