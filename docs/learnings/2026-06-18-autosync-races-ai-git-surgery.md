---
date: 2026-06-18
session_type: infra/incident
incident: git-autosync atropelou cirurgia git multi-repo
commit: n/a
tags: [git, autosync, launchd, multi-repo, pathspec, race-condition]
applies_to_projects: [global]
promote_to_vault: true
---

# Autosync (add -A + commit + push em ciclo) atropela cirurgia git de IA — pause-o (com restauração garantida) antes de entrega multi-repo

> O padrão é "auto-committer periódico × operação git cirúrgica concorrente", não só o
> `com.ideiaos.gitautosync`. Vale para qualquer cron/daemon/hook que faça `git add -A`
> sem coordenação com o trabalho em andamento.

## Trigger (quando reler isso)

Antes de QUALQUER entrega git assistida por IA em repos sob um auto-committer —
especialmente **multi-repo** ou com `git rm --cached` / commits por pathspec / pushes a
clones que podem estar defasados.

## O padrão (abstrato)

Um `git add -A` periódico é **incompatível** com commits cirúrgicos:

1. **Contaminação de commit por pathspec.** Ao rodar `git rm --cached .env` +
   `git commit -- .env .gitignore`, o autosync correu em paralelo, fez `git add -A` e
   criou seu **próprio** commit (`wip: autosync …`) varrendo arquivos não-relacionados —
   inclusive `package-lock.json` e um `CONTINUATION_HANDOFF.md` com **marcadores de
   conflito de merge não resolvidos** (`<<<<<<<`) — e já empurrou para `origin`. O
   `git commit -- pathspec` da IA então falhou (índice já limpo).
2. **Push bloqueado por divergência.** Noutro repo (clone 78 commits atrás, via autosync
   de outra máquina), o commit local não fazia fast-forward → push rejeitado; resolver
   exigiria rebase/merge ou `--force` (proibido).

Qualquer arquivo sujo no working tree — mesmo lixo auto-gerado por hooks, ou marcadores
de conflito — vira parte do commit do autosync. Clones defasados + autosync de outra
máquina geram divergência que bloqueia push.

## Evidência (concreta — desta sessão)

- IdeiaOS: hardening do scanner foi entregue pelo **próprio autosync** (`bdbd689`,
  conteúdo correto) antes do commit manual.
- nfideia: push do untrack de `.env` **bloqueado** (clone defasado) → reconciliado com
  `reset --hard origin/work` + commit limpo + push (`94fffd05`).
- ideiapartner: branch `chore/untrack-env` **contaminada** (`0568e52d` com
  `package-lock.json` −485 + handoff com marcadores) → branch deletada local+remote,
  voltou para `main` `d0dc883c`.

## Regra prática (procedimento)

1. **Confirme o plist ANTES de pausar** (`~/Library/LaunchAgents/com.ideiaos.gitautosync.plist`)
   — garante a restauração. _Cross-link: janela de privilégio temporário deve conceder as
   tools do teardown, não só as do trabalho._
2. **Pause:** `launchctl bootout gui/$(id -u)/com.ideiaos.gitautosync`.
3. **Commits/pushes limpos.** Para clone defasado: `git stash` → `git reset --hard
   origin/<branch>` → reaplica a mudança num commit limpo → push fast-forward.
4. **RESTAURE:** `launchctl bootstrap gui/$(id -u) <plist>` e confirme
   `launchctl list | grep gitautosync` (status 0).
5. Pausar autosync é **escopo além de "commit/push"** — o classifier bloqueia sem
   autorização explícita do usuário; **peça**. Tudo recuperável via reflog/stash.
