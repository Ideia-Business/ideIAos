---
name: project-cockpit-daemon-nvm-install-and-cwd
description: Ativar o daemon do Cockpit (com.ideiaos.cockpit) em máquina nvm + bug de cwd residual no collect.js
metadata: 
  node_type: memory
  type: project
  originSessionId: 2bc6b4ee-e331-4ec9-ae8f-bed36cd18a66
---

Ao ativar o LaunchAgent do Cockpit (`com.ideiaos.cockpit`) numa máquina que usa **nvm**,
dois gotchas aparecem (resolvidos na MacBook-Air-2 / machine_id `582572114c20` em 2026-06-26):

**1. Plist hardcoda `/usr/local/bin/node` que não existe em máquina nvm.**
O template versionado `infra/launchd/com.ideiaos.cockpit.plist` aponta `/usr/local/bin/node`.
Em máquina nvm o node vive em `~/.nvm/versions/node/vX/bin/node` e `/usr/local/bin` é root:wheel
(não-gravável sem sudo). Solução aplicada (mesmo padrão do `com.ideiaos.gitautosync.plist`, que
usa paths absolutos em `~/.local/bin`): criar symlink estável `~/.local/bin/node → $(which node)`
e materializar a **cópia instalada** do plist (em `~/Library/LaunchAgents/`) apontando para
`~/.local/bin/node` — o template versionado fica PRISTINE (per-máquina diverge só no node path).
Instalação é manual e deliberada (`launchctl bootstrap gui/$(id -u) <plist>`); não há instalador
automático e o `idea-doctor §15` só verifica via `launchctl list`, nunca reinstala.
**Instalar LaunchAgent dispara o classifier de segurança** (persistência/auto-run) → exige
autorização explícita do usuário, não basta "resolve tudo".

**2. `collect.js` tinha 2 pontos cwd-dependentes além do `versions.lock` (R15-12).**
O comentário do próprio arquivo condena "depender de cwd num daemon" (sob launchd o cwd NÃO é o
repo), mas só o `versions.lock` tinha sido ancorado em `__dirname`. Restavam: o `soakDir`
(`process.cwd()`) e a chamada `bash scripts/check-security-freshness.sh` (path relativo) — esta
causava `safeExec warn` no stderr do daemon e deixava `security_freshness` ausente do snapshot.
Fix: constante `const ROOT = path.resolve(__dirname,'..','..')` no topo, usada nos 3 pontos; a
chamada do script passou a path absoluto + `{ cwd: ROOT }`. Prova determinística = rodar
`agentd.js --once` e `ingest.js` de `cwd=/tmp` (simula launchd): sem warn + `tier: ok`.

Nota: o snapshot por-máquina NÃO carrega soak (`readSoakHeartbeats` é exportada mas não consumida
no fluxo do snapshot); os soak heartbeats vão ao read-model via `ingest.js`, que usa a própria
`REPO_ROOT`. Cross-link [[autosync-durability-hardening]] (mesmo gotcha "launchd não herda PATH/nvm")
e [[project-milestone-v14-cockpit]].
