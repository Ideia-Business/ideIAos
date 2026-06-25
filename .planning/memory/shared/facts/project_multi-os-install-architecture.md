---
name: project-multi-os-install-architecture
description: "Arquitetura de instalação multi-SO do IdeiaOS — consumidor plugin-first, Windows 2 caminhos (nativo+GitBash gated / WSL2), plano de hardening gated no teste"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Exame minucioso da instalação multi-SO do IdeiaOS (workflow `wf_0f029597-a31`, 7 agentes, 2026-06-25; red-team = **sound-with-caveats**) concluiu:

- **A dependência de SO é concentrada e portável**, não "precisa de Linux". Config (47 skills + 19 agents + 42 rules) já é 100% portável via `claude plugin install`. O bloqueador nº1 do Windows é UM defeito mecânico: `/usr/bin/python3` hardcoded em 12 hooks de produto + 2 scripts (42 ocorrências) — não a ausência de WSL.
- **Consumidor vs mantenedor** é a distinção que mais simplifica: um **consumidor** (trabalha nos projetos) precisa só de **Claude Code + git + Node + plugins**; a config dos projetos já vem no `git clone` → **não roda `setup.sh`**. O bootstrap pesado (`setup-dev-machine.sh`, autosync, overlay) é do **mantenedor**.
- **Claude Code Windows nativo executa hooks `.sh` via Git Bash** (pesquisa confirmou: `sh -c` no mac/linux, Git Bash no Windows, PowerShell se ausente) → WSL deixa de ser obrigatório.

**Decisão (doc entregue, código GATED):** Windows tem **2 caminhos** — (A) **nativo + Git Bash** (consumidor, ⚗️ EXPERIMENTAL, gated no teste de 5 min do dev) e (B) **WSL2** (✅ garantido/mantenedor). NÃO portar para PowerShell (mantém bash-based). Doc: `docs/guides/windows-wsl.md` (2 caminhos), `onboarding-novo-dev.md` (consumidor/mantenedor + trilha por SO), README.

**Gate de entrada do hardening de código:** teste de 5 min do Lucas (Windows) — instalar `ideiaos-core@ideiaos` com Git for Windows e ver se um hook `.sh` EXECUTA ao editar arquivo. PASS → habilita o tier nativo + dispara o milestone "multi-OS hardening" (7 fixes: python3→lookup, scheduler adapter launchd/systemd/taskscheduler, notify 3-ramos, paths parametrizados, shell:bash, /tmp→TMPDIR, machine-id Linux). FAIL → WSL2 segue único caminho Windows. Plano completo + caveats em `docs/process/multi-os-hardening-plan.md`.

**Why:** o exame nasceu de um dev novo (Lucas) em Windows; expôs que o IdeiaOS era macOS-only no bootstrap. **How to apply:** ao retomar o multi-SO, primeiro verificar o resultado do teste do Lucas; só então executar `docs/process/multi-os-hardening-plan.md` (validar o DEPLOYADO, não a fonte — [[learning-autosync-pause-file-guard-not-deployed]]; guard diferenciado proteção≠fail-soft; opt-in de push no autosync portado — [[autosync-pushes-feature-branches]]).
