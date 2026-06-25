# ideIAos no Windows (e Linux)

> Como rodar o ideIAos numa máquina **Windows**. Há **dois caminhos** — escolha pelo seu papel.
> Companheiro de [`onboarding-novo-dev.md`](onboarding-novo-dev.md): substitui as **seções 1–6**
> daquele guia quando você está no Windows. Acessos (seção 0), primeira sessão e dia a dia
> (seções 7–10) são **idênticos** — siga lá.
>
> 🐧 **Linux nativo?** Use o **Caminho B** a partir do *Passo 1* (pule o Passo 0 do WSL). Onde
> o guia disser "WSL", leia como "seu shell Linux". O resto é igual.

---

## Antes de tudo — acessos (pré-condição que trava o clone)

**Leia e cumpra a [seção 0 do onboarding](onboarding-novo-dev.md) ANTES de começar:** ser membro
da org `Ideia-Business` **com `push` (write)** nos 5 repos, token `gh` autorizado para SSO (se a
org tiver), e conta Claude Code. **Sem write, o `git clone` de repo privado já falha** — não é só o
autosync depois.

> ⚠️ Tudo o que envolve credencial roda **dentro do ambiente que você escolher**. No Caminho B
> (WSL), o login do `gh`/`claude` precisa ser **dentro do Ubuntu** — autenticação do Windows host
> **não conta** (o WSL é um Linux separado, com `~/.config` próprio).

---

## Qual caminho?

| Você é… | Caminho | Status | Por quê |
|---------|---------|--------|---------|
| **Dev-consumidor** (trabalha nos projetos) | **A — Nativo + Git Bash** | ⚗️ **experimental** (valide com o teste de 5 min) | leve, sem virtualizar Linux |
| **Mantenedor** do IdeiaOS, ou o teste do Caminho A falhou | **B — WSL2 (Ubuntu)** | ✅ **garantido** | paridade total com o Mac |

A diferença de fundo: a **config** do ideIAos (skills/agents/rules) instala via **plugin nativo**
do Claude Code em qualquer SO; o que precisa de um shell bash são os **hooks** e o ferramental.
No Caminho A esse bash é o **Git Bash** (vem com o Git for Windows, sem VM); no B é o Ubuntu do WSL.

---

# Caminho A — Nativo + Git Bash (consumidor)

Claude Code nativo no Windows executa hooks `.sh` **via Git Bash** quando ele está instalado. Logo,
um consumidor pode rodar tudo **sem WSL**. O ponto ainda **não validado na nossa frota** é se os
hooks de fato disparam — por isso comece pelo teste.

## A.0 — Teste de 5 min (faça ISTO primeiro) 🖐️

Valida a única incerteza: os hooks `.sh` executam no Claude Code Windows nativo?

```powershell
# 1. Pré-requisitos (instaladores oficiais):
#    - Git for Windows (MARQUE "Git Bash"):  https://git-scm.com/download/win
#    - Node.js 18+ LTS:                       https://nodejs.org
#    - Claude Code CLI:
npm install -g @anthropic-ai/claude-code
```
```bash
# 2. Instale o plugin core (no terminal do Claude Code, ou via CLI):
claude plugin marketplace add Ideia-Business/IdeiaOS    # ou: add <caminho local do repo>
claude plugin install ideiaos-core@ideiaos
```
3. Abra o Claude Code num projeto qualquer e **edite + salve um arquivo `.ts`**.
4. **Observe se um hook disparou** (ex.: `typecheck-on-edit` ou `console-log-guard` injetam um aviso/contexto):
   - ✅ **Hook executou** → o Caminho A funciona nesta frota. Siga A.1.
   - ❌ **Nada disparou / abriu o `.sh` no editor / erro** → use o **Caminho B (WSL2)**.

> 📣 **Reporte o resultado ao Gustavo.** É essa prova que decide se o nativo vira o caminho
> padrão Windows da frota (e dispara o milestone de hardening que torna os hooks 100% portáveis).
> Por que pode falhar hoje: 12 dos 14 hooks ainda referenciam `/usr/bin/python3` (inexistente no
> Windows) e há um bug conhecido de file-association de `.sh` no Claude Code Windows — ambos no
> radar do milestone "multi-OS hardening".

## A.1 — Instalação consumidor nativo

Se o teste passou:

```powershell
# GitHub CLI + auth (no PowerShell ou Git Bash)
winget install --id GitHub.cli
gh auth login
gh auth setup-git
git config --global core.autocrlf input        # evita CRLF corromper scripts

# plugins por perfil (core já instalado no teste)
claude plugin install ideiaos-design-suite@ideiaos   # se faz UI
claude plugin install ideiaos-lovable@ideiaos        # se mexe em projeto Lovable
claude plugin install ideiaos-marketing@ideiaos      # se produz conteúdo
```
```bash
# clonar os projetos (Git Bash) — checkout work + npm install; a config vem no clone
mkdir -p ~/dev && cd ~/dev
for r in cfoai-grupori lapidai nfideia ideiapartner; do
  git clone https://github.com/Ideia-Business/$r.git
  git -C $r checkout work 2>/dev/null || git -C $r checkout -b work
  ( cd $r && npm install )
done
```
- **GSD:** `/plugin` no Claude Code → adicionar o plugin GSD (get-shit-done).
- **`.env`:** peça ao Gustavo por canal seguro → `~/dev/<projeto>/.env`.
- O consumidor **não roda `setup.sh`** — a config (AGENTS.md, `.claude/`, `.cursor/rules`) já vem no clone.

## A.2 — Autosync no nativo (Task Scheduler, opcional)

Sem `launchd`/`cron`. O daemon roda via Git Bash, agendado pelo **Task Scheduler**:

```powershell
schtasks /create /tn IdeiaOS-GitAutosync /sc minute /mo 15 ^
  /tr "\"C:\Program Files\Git\bin\bash.exe\" -lc \"~/.local/bin/git-autosync --all\""
```
(Requer o `git-autosync` copiado para `~/.local/bin` — ver Caminho B Passo 5 para o conteúdo.)

> ⚗️ Experimental: se o `schtasks` for bloqueado por política/UAC, **use `git push` manual** na
> `work` — o autosync é conveniência, não obrigatório.

---

# Caminho B — WSL2 / Ubuntu (garantido)

Linux real dentro do Windows. Todo o ferramental roda **idêntico ao Mac**.

## Passo 0 — Instalar o WSL2 🖐️

No **PowerShell como Administrador**:
```powershell
wsl --install
```
Instala WSL2 + Ubuntu. **Reinicie o Windows**, abra "Ubuntu", crie usuário/senha do Linux.

```powershell
wsl -l -v        # CONFIRME: o Ubuntu deve aparecer em VERSION 2 (WSL2, não WSL1)
# se vier VERSION 1:  wsl --set-version Ubuntu 2
```
> WSL1 anula as garantias de performance/permissão deste guia — tem que ser WSL2. Se o Ubuntu não
> aparecer após o reinício, rode `wsl --install -d Ubuntu` de novo (em máquinas novas o 1º
> `wsl --install` só habilita os componentes; o 2º provisiona a distro).

## Passo 1 — Base no Ubuntu (dentro do WSL)

```bash
sudo apt update && sudo apt install -y git curl wget cron

# GitHub CLI — NÃO está no apt padrão do Ubuntu; adiciona o repo oficial do GitHub
type -p gh >/dev/null || {
  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt update && sudo apt install -y gh
}

# Node via nvm (LTS) — não use o node do apt (costuma ser antigo; precisa 18+)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
export NVM_DIR="$HOME/.nvm"                       # carrega o nvm na sessão atual
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"   # (não depende de shell interativo)
nvm install --lts && nvm use --lts

# Claude Code CLI
npm install -g @anthropic-ai/claude-code
```
Confira: `node --version` (≥18), `gh --version`, `claude --version`.

## Passo 2 — Autenticar + identidade (DENTRO do WSL)

```bash
gh auth login            # GitHub.com → HTTPS → browser. DENTRO do Ubuntu (não conta o do Windows)
gh auth setup-git
git config --global user.name  "Nome do Dev"
git config --global user.email "dev@redeideia.com.br"
git config --global core.autocrlf input

claude                   # login na Anthropic; depois /exit
```
Confirme o **write** nos repos (`push:true` nos cinco):
```bash
for r in cfoai-grupori IdeiaOS lapidai nfideia ideiapartner; do
  echo -n "$r → "; gh api repos/Ideia-Business/$r --jq '.permissions'
done
```

## Passo 3 — Clonar + ambiente global + projetos

```bash
mkdir -p ~/dev
git clone https://github.com/Ideia-Business/ideIAos.git ~/dev/IdeiaOS
git -C ~/dev/IdeiaOS checkout work 2>/dev/null || git -C ~/dev/IdeiaOS checkout -b work

bash ~/dev/IdeiaOS/setup.sh --global-only        # skills, MCPs, hooks, agentes Cursor, overlay

for r in cfoai-grupori lapidai nfideia ideiapartner; do
  git clone https://github.com/Ideia-Business/$r.git ~/dev/$r
  git -C ~/dev/$r checkout work 2>/dev/null || git -C ~/dev/$r checkout -b work
  ( cd ~/dev/$r && npm install )                        # node_modules (pode demorar)
  bash ~/dev/IdeiaOS/setup.sh --project-only ~/dev/$r   # IDEIAOS.md, .planning/, rules
done
```
> 🔴 **O `checkout work` é obrigatório:** o autosync só empurra **`work`**; na **`main`** ele só
> **puxa** (e avisa "push MANUAL" se houver commits locais). Na `main` — default do `git clone` —
> seus commits **nunca sobem ao GitHub, sem erro visível.**
>
> 📁 **Mantenha os repos em `~/dev`** (filesystem do Linux), **nunca** em `/mnt/c/...` (disco
> Windows) — lá o git e o `npm install` ficam ordens de magnitude mais lentos e permissões de
> hook quebram.

## Passo 4 — Plugin GSD + `.env`

- **GSD:** dentro do Claude Code, `/plugin` → adicionar o plugin GSD (get-shit-done). Confira: `/gsd-help`.
- **`.env`:** peça ao Gustavo por canal seguro → `~/dev/<projeto>/.env`. O `setup.sh --project-only`
  avisa `.env ausente` e `OPENROUTER_API_KEY` — esperado em máquina nova.

## Passo 5 — Autosync via cron (substituto do launchd)

```bash
mkdir -p ~/.local/bin ~/.local/state
cp ~/dev/IdeiaOS/source/autosync/git-autosync.sh ~/.local/bin/git-autosync
chmod +x ~/.local/bin/git-autosync
printf '%s\n' ~/dev/cfoai-grupori ~/dev/IdeiaOS ~/dev/lapidai ~/dev/nfideia ~/dev/ideiapartner \
  > ~/.local/state/git-autosync-repos.txt

# agendar a cada 15 min — ASPAS DUPLAS gravam o caminho absoluto já resolvido
( crontab -l 2>/dev/null; \
  echo "*/15 * * * * $HOME/.local/bin/git-autosync --all >> $HOME/.local/state/git-autosync.cron.log 2>&1" \
) | crontab -
crontab -l    # confira: caminho /home/<você>/... absoluto (sem '$HOME' literal)

sudo service cron start          # SEM systemd: re-rode a cada boot do WSL
```
**Persistir entre reinícios** (recomendado) — habilite systemd. ⚠️ `wsl --shutdown` **encerra a
sessão WSL** (feche o `claude` antes):
```ini
# /etc/wsl.conf
[boot]
systemd=true
```
```powershell
wsl --shutdown        # no PowerShell; depois reabra o Ubuntu
```
```bash
sudo systemctl enable --now cron    # COM systemd: não precisa do 'service cron start'
```
> **Alternativa simples (1º dia):** pule o cron e use `git push` manual, ou rode
> `git-autosync --all` quando quiser. O autosync é conveniência.

## Passo 6 — Editar com Cursor / VS Code (Remote-WSL)

1. Instale o VS Code ou Cursor **no Windows (host)**, não no WSL.
2. Instale a extensão **WSL** (Microsoft).
3. Caminho robusto: abra a IDE no Windows → comando **"WSL: Connect to WSL"** → *Open Folder* em `~/dev/<projeto>`.
   - O `code .`/`cursor .` no terminal do Ubuntu só funciona se a IDE registrou seu CLI no PATH do
     WSL (VS Code: marque "Add to PATH" no instalador; Cursor: paleta → "Install cursor command").

## Passo 7 — Verificar

```bash
bash ~/dev/IdeiaOS/scripts/idea-doctor.sh
```
> ⚠️ **Esperado no WSL:** o doctor procura o autosync via `launchctl` (Mac) e vai dar um WARN tipo
> *"git-autosync não carregado — rode setup-dev-machine.sh"*. É **cosmético** (você usa cron) — não
> é FAIL. O resto do diagnóstico vale igual.

**Pronto.** Para começar: `cd ~/dev/nfideia && claude` e fale com a Deia em português. O dia a dia
está no [onboarding §7 (primeira sessão)](onboarding-novo-dev.md) e [§8 (branches/autosync)](onboarding-novo-dev.md).

---

## Diferenças vs macOS (resumo)

| Aspecto | macOS | Windows nativo (A) | Windows WSL2 (B) / Linux |
|---------|-------|--------------------|--------------------------|
| Config (skills/agents/rules) | plugin nativo | plugin nativo | plugin nativo |
| Hooks `.sh` | `sh -c` | **Git Bash** (⚗️ validar) | bash do Ubuntu |
| Bootstrap | `setup-dev-machine.sh` | plugins (consumidor) | `setup.sh --global-only` + clones |
| Agendador autosync | `launchd` | Task Scheduler | cron / systemd |
| `idea-doctor` §autosync | detecta | n/a | WARN cosmético |

Skills, `/idea`, GSD, AIOX, hooks, fluxo `work`/`main`, Lovable — **idênticos** em todos.

---

## Troubleshooting Windows/WSL

| Sintoma | Causa | Correção |
|---------|-------|----------|
| hook `.sh` não dispara (Caminho A) | Git Bash ausente ou bug file-association | instalar Git for Windows; se persistir, usar Caminho B |
| `git clone` falha (repo privado) | sem write no repo, ou token SSO não autorizado | confirmar `push:true` + autorizar token na org (SSO) |
| commits não sobem | repo na `main`, não `work` | `git -C <repo> checkout work` |
| `apt install gh` "Unable to locate" | gh não está no apt padrão | usar o bloco do repo oficial (Passo 1) |
| crontab não roda | `$HOME` literal (aspas simples) ou cron parado | aspas duplas + `sudo service cron start` |
| `npm install`/git lentíssimos | repo em `/mnt/c` | mover para `~/dev` (filesystem Linux) |
| autosync não persiste após reboot | cron sem systemd | systemd em `/etc/wsl.conf` + `systemctl enable --now cron` |
| `cursor .` "command not found" no WSL | CLI não exposto ao WSL | abrir via "WSL: Connect" na IDE do host |
| `idea-doctor` warn de autosync | sem `launchctl` fora do macOS | esperado — cosmético; use cron/Task Scheduler |

---

**Próximo:** volte ao [`onboarding-novo-dev.md`](onboarding-novo-dev.md) **seção 7** ("Primeira
sessão") e **seção 8** ("Branches/autosync") — daqui em diante o fluxo é o mesmo de qualquer SO.
