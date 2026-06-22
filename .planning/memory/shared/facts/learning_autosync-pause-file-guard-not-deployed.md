---
name: learning-autosync-pause-file-guard-not-deployed
description: O pause-file do autosync-pause.sh é INERTE nesta máquina — o binário deployado ~/.local/bin/git-autosync não tem o guard; pausar de verdade exige launchctl bootout
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 146e6aba-0a22-495c-9758-caf9927b4217
---

`scripts/autosync-pause.sh on` grava `~/.local/state/git-autosync.pause`, mas o binário **deployado** em `~/.local/bin/git-autosync` **não lê esse arquivo** — o guard de pause-file existe só na intenção do script (comentário "guard adicionado em 2026-06") e **nunca foi deployado** a esta máquina (Mac mini). Resultado: o daemon `com.ideiaos.gitautosync` continua disparando a cada 900s mesmo "PAUSADO", e capturou um write de executor mid-build como `a16907a wip: autosync`, empurrando `work` p/ origin (incidente v14.0, 2026-06-21).

**Why:** confiar no pause-file é confiar numa abstração que não está implementada no binário em execução. `autosync-pause.sh status` dizer "⏸ PAUSADO" prova só que o ARQUIVO existe — NÃO que o daemon o respeita. Verificação enganosa.

**How to apply:** antes de cirurgia git/infra multi-commit, pause de verdade com `launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync` (hard-stop real) e confirme com `launchctl list | grep autosync` (ausente = parado). RESTAURE no fim com `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`. O pause-file sozinho é INSUFICIENTE até o guard ser deployado ao binário (follow-up: deployar o guard OU fazer `autosync-pause.sh` usar bootout/bootstrap). Liga a [[learning-autosync-races-ai-git-surgery]] e [[learning-autosync-pushes-feature-branches]].
