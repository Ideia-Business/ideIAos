# Guias de instalação e operação do ideIAos · índice

Mapa único de "por onde começar". Cada guia tem **um** dono de assunto — não há cópias paralelas
do mesmo passo a passo. Comece pelo seu sistema operacional; os demais guias são consultados a
partir dele quando necessário.

## Por onde começar (por SO)

| Seu SO | Comece em | Autosync |
|--------|-----------|----------|
| **macOS** | [`onboarding-novo-dev.md`](onboarding-novo-dev.md) — bootstrap `setup-dev-machine.sh` | LaunchAgent (`launchd`) |
| **Windows** | [`windows-wsl.md`](windows-wsl.md) — Caminho A (nativo, ⚗️) ou Caminho B (WSL2, ✅) | Task Scheduler ou cron |
| **Linux** | [`windows-wsl.md`](windows-wsl.md) — Caminho B a partir do *Passo 1* | cron / systemd |

> O atalho da raiz [`INSTALL-WINDOWS.md`](../../INSTALL-WINDOWS.md) é só um **ponteiro** para o
> Caminho B — a fonte única do passo a passo Windows é `windows-wsl.md`.

## Cada assunto, um guia (sem duplicar)

| Assunto | Guia | Observação |
|---------|------|------------|
| **Acessos** (org GitHub + Claude Code) — pré-condição | [`onboarding-novo-dev.md` §0](onboarding-novo-dev.md) | universal a todos os SO |
| **Instalação macOS** (passos 1–6) | [`onboarding-novo-dev.md`](onboarding-novo-dev.md) | trilha mantenedor/consumidor |
| **Instalação Windows / Linux** (passos 1–6) | [`windows-wsl.md`](windows-wsl.md) | substitui os passos 1–6 do onboarding |
| **Variáveis de ambiente** (`.env` por projeto) | [`env-setup-dev.md`](env-setup-dev.md) | qual chave cada projeto precisa |
| **Primeira sessão · branches/autosync · manutenção · troubleshooting** (seções 7–10) | [`onboarding-novo-dev.md`](onboarding-novo-dev.md) | universal a todos os SO |

A **seção 0** (acessos) e as **seções 7–10** do onboarding valem para **todos os SO** — só os
passos 1–6 divergem por sistema.

## Os 3 gotchas que mais quebram (single-source no runbook Windows)

Estes três pontos derrubam instalações novas com falha **silenciosa**. O passo a passo completo
está em [`windows-wsl.md`](windows-wsl.md); aqui só o resumo do "porquê":

- **`git checkout work`** — o autosync só empurra a branch `work`; na `main` (default do `git clone`)
  os commits **nunca sobem ao GitHub, sem erro visível**.
- **Manter os repos em `~/dev`, nunca em `/mnt/c/...`** (WSL) — no disco Windows o git e o
  `npm install` ficam ordens de magnitude mais lentos e permissões de hook quebram.
- **`git config --global core.autocrlf input`** — sem isso o CRLF do Windows corrompe os scripts `.sh`.

---

_Outros guias desta pasta não são de instalação_ (ex.: [`hf-cookbook-patterns.md`](hf-cookbook-patterns.md),
guia de padrões) — este índice cobre apenas instalação e operação.
