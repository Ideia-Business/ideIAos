---
name: autosync-durability-hardening
description: git-autosync agora é daemon VERSIONADO (source/autosync/) com auto-cura de planning/cockpit + distribuição automática; launchd não herda PATH (gotcha nvm). Onde editar e por quê.
metadata: 
  node_type: memory
  type: project
  originSessionId: a6ecbb78-45bd-4705-807c-27b430912bf8
---

Endurecimento de durabilidade do `git-autosync` (2026-06-24, commits a485588→5af6864→dbfb017→ac37eb3),
fechando os gaps da auditoria `wf_ab41764e`. Fatos duráveis para sessões futuras:

- **O daemon agora é FONTE-DE-VERDADE versionada:** `source/autosync/git-autosync.sh`. **EDITE AQUI**,
  nunca a cópia em `~/.local/bin/git-autosync` (antes o daemon vivia num heredoc em `setup-dev-machine.sh`
  E deployado → drift binário↔molde). O heredoc foi removido; `setup-dev-machine.sh` e `ideiaos-update.sh`
  (step 2e) instalam por **cópia atômica** (`.tmp`+`mv`).
- **Auto-distribuição:** `source/autosync/` está em `GLOBAL_PATHS` do `propagate-if-changed.sh`, que
  re-deploya o daemon (atômico, idempotente via `cmp`) quando muda. Correções no daemon chegam à frota
  **sozinhas** pelo autosync→propagate (antes só re-rodando `setup-dev-machine.sh` à mão em cada Mac).
- **Auto-cura de `planning`/`cockpit`** (`_push_state_ref`, substitui push_planning_ref/push_cockpit_ref):
  local ATRÁS→FF-local via `update-ref` (sem checkout); À FRENTE→push; **DIVERGÊNCIA real**→notify UMA vez
  + flag `~/.local/state/<ref>-diverged.flag` (para o loop de 900s; some ao re-alinhar) apontando
  `/memory-sync`. **Nunca `--force`** (falha-segura). Bootstrap de tracking em clone novo. Provado em
  sandbox `/tmp` (11/11 cenários). Fecha o loop crônico de "push planning/cockpit FALHOU" que antes só se
  resolvia reconciliando à mão. Resolve o porquê: `memory-export`/`cockpit.sh` commitam com
  `commit-tree -p planning` (parent = tip LOCAL) → se local stale, forka.
- **launchd NÃO herda o PATH interativo** (gotcha-raiz do incidente): numa Apple-Silicon o node do **nvm**
  vive em `~/.nvm/versions/node/<v>/bin` (invisível ao launchd). O PATH-hardening no topo de `setup.sh` e
  `propagate-if-changed.sh` resolve Homebrew + `~/.local/bin` + nvm (**`sort -V|tail -1`** — o glob simples
  elegia a MENOR versão lexicográfica, v9>v20) + fnm/volta/asdf. Gate de `setup.sh` agora exige Node **≥18**
  por versão (presença não basta). O plist injeta nvm/`~/.local/bin` no PATH (`setup-dev-machine.sh`).
- **Visibilidade:** `idea-doctor §6` faz `cmp` do daemon deployado vs `source/autosync/git-autosync.sh` →
  WARN direcional "DEFASADO… rode propagate --force" (antes só via `launchctl list` "carregado", nunca a
  lógica → máquina com daemon velho passava verde).
- **Veredito da pergunta do dono "não recorre, inclusive em máquina nova?":** agora **SIM** — a MacBook (e
  qualquer máquina) se auto-cura no próximo `git pull` do autosync (puxa o propagate+fonte novos → deploya).
  Não exige passo manual. `Jarvis` (repo PESSOAL `git@github-personal:...`) fica fora do array canônico de
  REPOS de propósito.

Cross-link [[learning-autosync-races-ai-git-surgery]], [[autosync-pushes-feature-branches]],
[[learning-autosync-pause-file-guard-not-deployed]], [[learning-soak-span-is-record-delta-not-wallclock]].
