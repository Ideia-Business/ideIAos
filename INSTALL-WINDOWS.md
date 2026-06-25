# Instalar o ideIAos no Windows (WSL2) — guia de entrega

> Passo a passo **autossuficiente** para um dev novo rodar o ideIAos no Windows pelo caminho
> **garantido** (WSL2 / Ubuntu — Linux real dentro do Windows). Copie e siga na ordem.
>
> _Versão de referência no repo: [`docs/guides/windows-wsl.md`](docs/guides/windows-wsl.md) (Caminho B).
> Para o caminho leve sem WSL (experimental), ver o Caminho A do mesmo guia._

---

## ✅ Antes de começar (acessos)

Sua conta GitHub precisa:
- ser **membro da org `Ideia-Business`** com **`push` (write)** nos 5 repos — o Gustavo confirma;
- ter uma **conta Claude Code** (Anthropic) ativa.

> ⚠️ **Tudo roda DENTRO do Ubuntu (WSL).** O login do `gh` e do `claude` tem que ser feito **no
> terminal do Ubuntu** — estar logado no Windows **não conta** (o WSL é um Linux separado).

---

## Passo 0 — Instalar o WSL2

No **PowerShell como Administrador**:
```powershell
wsl --install
```
Reinicie o Windows, abra **"Ubuntu"** no menu Iniciar, crie usuário/senha do Linux. Confirme que é WSL2:
```powershell
wsl -l -v        # o Ubuntu deve aparecer em VERSION 2
# se vier VERSION 1:  wsl --set-version Ubuntu 2
```
> Se o Ubuntu não aparecer após o reinício, rode `wsl --install -d Ubuntu` de novo.

---

## Passo 1 — Base no Ubuntu (dentro do WSL)
```bash
sudo apt update && sudo apt install -y git curl wget cron

# GitHub CLI — NÃO está no apt padrão; adiciona o repo oficial do GitHub
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
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts

# Claude Code CLI
npm install -g @anthropic-ai/claude-code
```
Confira: `node --version` (≥18), `gh --version`, `claude --version`.

---

## Passo 2 — Autenticar + identidade (DENTRO do WSL)
```bash
gh auth login            # GitHub.com → HTTPS → login no browser
gh auth setup-git
git config --global user.name  "Seu Nome"
git config --global user.email "voce@redeideia.com.br"
git config --global core.autocrlf input

claude                   # login na Anthropic; depois digite /exit
```
Confirme o **write** nos repos (`push:true` nos cinco):
```bash
for r in cfoai-grupori IdeiaOS lapidai nfideia ideiapartner; do
  echo -n "$r → "; gh api repos/Ideia-Business/$r --jq '.permissions'
done
```

---

## Passo 3 — Clonar + ambiente global + projetos
```bash
mkdir -p ~/dev
git clone https://github.com/Ideia-Business/ideIAos.git ~/dev/IdeiaOS
git -C ~/dev/IdeiaOS checkout work 2>/dev/null || git -C ~/dev/IdeiaOS checkout -b work

bash ~/dev/IdeiaOS/setup.sh --global-only        # skills, MCPs, hooks, agentes Cursor

for r in cfoai-grupori lapidai nfideia ideiapartner; do
  git clone https://github.com/Ideia-Business/$r.git ~/dev/$r
  git -C ~/dev/$r checkout work 2>/dev/null || git -C ~/dev/$r checkout -b work
  ( cd ~/dev/$r && npm install )                        # node_modules (pode demorar)
  bash ~/dev/IdeiaOS/setup.sh --project-only ~/dev/$r
done
```
> 🔴 **`checkout work` é obrigatório** — o autosync só empurra `work`; na `main` seus commits
> **nunca sobem ao GitHub, sem erro visível.**
> 📁 **Mantenha os repos em `~/dev`**, nunca em `/mnt/c/...` (lá fica lentíssimo e quebra permissões).

---

## Passo 4 — Plugin GSD + `.env`
- **GSD:** dentro do Claude Code, digite `/plugin` → adicionar o plugin **get-shit-done**. Confira com `/gsd-help`.
- **`.env`:** peça ao Gustavo por canal seguro → coloque em `~/dev/<projeto>/.env` (nunca por chat em texto plano).

---

## Passo 5 — Autosync via cron (opcional)

Pode **pular no 1º dia** e usar `git push` manual. Para ativar o sync automático a cada 15 min:
```bash
mkdir -p ~/.local/bin ~/.local/state
cp ~/dev/IdeiaOS/source/autosync/git-autosync.sh ~/.local/bin/git-autosync
chmod +x ~/.local/bin/git-autosync
printf '%s\n' ~/dev/cfoai-grupori ~/dev/IdeiaOS ~/dev/lapidai ~/dev/nfideia ~/dev/ideiapartner \
  > ~/.local/state/git-autosync-repos.txt

( crontab -l 2>/dev/null; \
  echo "*/15 * * * * $HOME/.local/bin/git-autosync --all >> $HOME/.local/state/git-autosync.cron.log 2>&1" \
) | crontab -
sudo service cron start
```
> Para o cron persistir entre reinícios do WSL, habilite systemd: crie `/etc/wsl.conf` com
> `[boot]\nsystemd=true`, rode `wsl --shutdown` no PowerShell (fecha o `claude` antes!), reabra o
> Ubuntu e rode `sudo systemctl enable --now cron`.

---

## Passo 6 — Editar com Cursor / VS Code
Instale o VS Code ou Cursor **no Windows (host)** + a extensão **WSL** (Microsoft). Abra a IDE →
comando **"WSL: Connect to WSL"** → *Open Folder* em `~/dev/<projeto>`.

---

## Passo 7 — Verificar
```bash
bash ~/dev/IdeiaOS/scripts/idea-doctor.sh
```
> ⚠️ Vai dar um WARN cosmético de autosync (*"git-autosync não carregado"*) — **normal no WSL**
> (você usa cron, não o `launchd` do Mac). Não é erro.

---

## ✅ Pronto — como trabalhar

```bash
cd ~/dev/nfideia      # ou qualquer projeto
claude                # abre o Claude Code
```
Fale com a **Deia** em português natural — ex.: *"Deia, implementar busca por CNPJ"*. Ela roteia
para a camada certa. No início de cada sessão: `/recall-learnings`; no fim: `/extract-learnings`.

**Branches:** trabalhe sempre na `work` (o autosync empurra). A `main` é release.

Dúvidas de fluxo do dia a dia: `~/dev/IdeiaOS/docs/guides/onboarding-novo-dev.md` (seções 7–10). 🚀
