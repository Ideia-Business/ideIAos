# ideIAos no Windows — via WSL2 (Ubuntu)

> Guia para rodar o ideIAos numa máquina **Windows**. O caminho oficial é **WSL2**
> (Windows Subsystem for Linux), não PowerShell nativo — ver o "porquê" abaixo.
>
> Companheiro de [`onboarding-novo-dev.md`](onboarding-novo-dev.md): este guia substitui
> os **Passos 1–6** daquele documento quando o dev está no Windows. Acessos (org GitHub
> com **write**), `.env`, plugin GSD e o fluxo do dia a dia são **idênticos** — siga lá.

---

## Por que WSL2 e não PowerShell nativo

O ideIAos é um conjunto de **scripts bash** + ferramental Unix:

- `setup.sh`, `sync-all.sh`, `git-autosync.sh`, todos os hooks (`*.sh`) e várias skills
  são bash — não há equivalente `.ps1`.
- Portar tudo para PowerShell **dobraria a superfície de manutenção** e divergiria da
  fonte única (`source/`). Decisão: **bash continua a fonte única**; o Windows roda essa
  fonte dentro de um Linux real (WSL2).
- Mesmo que o Claude Code tenha app Windows nativo, os hooks/skills do ideIAos exigem um
  ambiente bash de qualquer forma.

> Já há precedente no ecossistema: o CodeRabbit roda via `wsl bash -c '…'` (rule
> `tool-examples.md`). WSL é ambiente de primeira classe aqui.

---

## Pré-requisito do Windows

- **Windows 11**, ou **Windows 10 versão 2004+** (build 19041+).
- Direitos de administrador para instalar o WSL (uma vez).

---

## Passo 0 — Instalar o WSL2 🖐️

No **PowerShell como Administrador**:

```powershell
wsl --install
```

Isso instala o WSL2 + **Ubuntu** por padrão. **Reinicie o Windows**, abra **"Ubuntu"** no
menu Iniciar e crie usuário/senha do Linux (independente da conta Windows).

> Se `wsl --install` reclamar, rode `wsl --update` e garanta a virtualização ligada na BIOS.

---

## Passo 1 — Base no Ubuntu (dentro do WSL)

```bash
sudo apt update && sudo apt install -y git curl

# GitHub CLI
type -p gh >/dev/null || sudo apt install -y gh

# Node via nvm (LTS) — não use o node do apt (costuma ser antigo; precisa 18+)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
exec $SHELL                       # recarrega o shell para o nvm valer
nvm install --lts

# Claude Code CLI
npm install -g @anthropic-ai/claude-code
```

Confira: `node --version` (≥ 18), `gh --version`, `claude --version`.

---

## Passo 2 — Autenticar + identidade

```bash
gh auth login            # GitHub.com → HTTPS → login no browser
gh auth setup-git
git config --global user.name  "Nome do Dev"
git config --global user.email "dev@redeideia.com.br"

# Line endings: evita CRLF do Windows contaminar os repos
git config --global core.autocrlf input

claude                   # login na Anthropic; depois /exit
```

> Confirme o **write** nos repos (igual ao Mac — ver onboarding §0):
> ```bash
> for r in cfoai-grupori IdeiaOS lapidai nfideia ideiapartner; do
>   echo -n "$r → "; gh api repos/Ideia-Business/$r --jq '.permissions'
> done
> ```
> `push:true` nos cinco = liberado.

---

## Passo 3 — Clonar o ideIAos + ambiente global

No Windows **não** se roda o `setup-dev-machine.sh` (ele é Mac-only: `launchd`, AirDrop,
`~/Library`). Use o `setup.sh --global-only` e clone os projetos à mão:

```bash
mkdir -p ~/dev
git clone https://github.com/Ideia-Business/ideIAos.git ~/dev/IdeiaOS

# ambiente global: skills (/idea, dev-loop, suíte), MCPs (chrome-devtools, context7),
# hooks Claude, agentes Cursor, overlay de patches
bash ~/dev/IdeiaOS/setup.sh --global-only

# clonar os projetos que o dev vai tocar
for r in cfoai-grupori lapidai nfideia ideiapartner; do
  git clone https://github.com/Ideia-Business/$r.git ~/dev/$r
done

# configurar o ideIAos em cada projeto (cria IDEIAOS.md, .planning/, rules, etc.)
for r in cfoai-grupori lapidai nfideia ideiapartner; do
  bash ~/dev/IdeiaOS/setup.sh --project-only ~/dev/$r
done
```

> **IMPORTANTE — filesystem:** mantenha os repos em `~/dev` (filesystem **do Linux**),
> **nunca** em `/mnt/c/...` (disco Windows montado). No `/mnt/c` o git e o `npm install`
> ficam ordens de magnitude mais lentos e `chmod`/permissões de hook quebram.

---

## Passo 4 — Plugin GSD + `.env`

Idênticos ao Mac:

- **GSD:** dentro do Claude Code, `/plugin` → adicionar o plugin GSD (get-shit-done).
- **`.env`:** peça ao Gustavo por canal seguro e copie para `~/dev/<projeto>/.env`
  (nunca por chat em texto plano).

---

## Passo 5 — Autosync no Windows (substituto do `launchd`)

No macOS o autosync roda como **LaunchAgent**. No Windows/WSL **não há `launchd`** — use
**cron** dentro do WSL. Instalação manual do daemon + agendamento:

```bash
mkdir -p ~/.local/bin ~/.local/state
cp ~/dev/IdeiaOS/source/autosync/git-autosync.sh ~/.local/bin/git-autosync
chmod +x ~/.local/bin/git-autosync

# lista de repos sincronizados (work auto-push; main só pull)
printf '%s\n' ~/dev/cfoai-grupori ~/dev/IdeiaOS ~/dev/lapidai ~/dev/nfideia ~/dev/ideiapartner \
  > ~/.local/state/git-autosync-repos.txt

# agendar a cada 15 min
( crontab -l 2>/dev/null; \
  echo '*/15 * * * * $HOME/.local/bin/git-autosync --all >> $HOME/.local/state/git-autosync.cron.log 2>&1' \
) | crontab -

# o cron não sobe sozinho no WSL — inicie e (opcional) persista via systemd
sudo service cron start
```

Para o cron **persistir entre reinícios** do WSL, habilite systemd criando `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```
…e reinicie o WSL (`wsl --shutdown` no PowerShell). Com systemd ligado, `sudo systemctl
enable --now cron`.

> **Alternativa simples:** se não quiser cron, o dev só faz `git push` normal na `work`,
> ou roda `git-autosync --all` manualmente quando quiser sincronizar. O autosync é
> conveniência, não obrigatório.

---

## Passo 6 — Editar com Cursor / VS Code

Edite com a IDE no Windows e o ambiente no Linux via **Remote – WSL**:

1. Instale a extensão **WSL** (Microsoft) no VS Code / Cursor.
2. No WSL: `cd ~/dev/nfideia && code .` (ou `cursor .`) — abre a IDE conectada ao WSL.
3. Ou, na IDE: paleta de comandos → **"WSL: Reopen Folder in WSL"**.

O terminal integrado já cai no Ubuntu; `claude` roda ali dentro.

---

## Passo 7 — Verificar

```bash
bash ~/dev/IdeiaOS/scripts/idea-doctor.sh
```

> ⚠️ **Esperado no WSL:** a checagem de autosync do `idea-doctor` procura o LaunchAgent via
> `launchctl` (Mac) e vai dar **`warn: git-autosync não carregado`** — isso é **cosmético**
> no Windows/WSL (você usa cron). Não é um FAIL e não bloqueia nada. O resto do diagnóstico
> vale igual.

---

## Diferenças vs macOS (resumo)

| Aspecto | macOS | Windows (WSL2) |
|---------|-------|----------------|
| Bootstrap | `setup-dev-machine.sh` (1 comando) | `setup.sh --global-only` + clones manuais |
| Agendador do autosync | `launchd` / LaunchAgent | **cron** (dentro do WSL) |
| Transferência de arquivo | AirDrop | `git clone` (sempre) |
| Notificação do autosync | `osascript` | fail-soft (silencioso; sem `osascript`) |
| Vault Obsidian (iCloud) | caminho iCloud registrado | n/a por padrão (vault é Mac/iCloud) |
| `idea-doctor` §autosync | `launchctl` detecta | dá `warn` cosmético (use cron) |

Tudo o mais — skills, `/idea`, GSD, AIOX, hooks, fluxo `work`/`main`, Lovable — é **idêntico**.

---

## Troubleshooting Windows/WSL

| Sintoma | Causa | Correção |
|---------|-------|----------|
| `wsl: command not found` no PowerShell | WSL não instalado | `wsl --install` (admin) + reiniciar |
| `npm install`/git lentíssimos | repo em `/mnt/c` | mover para `~/dev` (filesystem Linux) |
| hooks `.sh` "permission denied" | repo em `/mnt/c` ou sem `+x` | mover para `~/dev`; `chmod +x` |
| autosync não roda após reiniciar WSL | cron não persistiu | habilitar systemd em `/etc/wsl.conf` + `systemctl enable --now cron` |
| arquivos com `^M` / diffs ruidosos | CRLF do Windows | `git config --global core.autocrlf input` e re-clonar |
| `idea-doctor` warn de autosync | sem `launchctl` no WSL | esperado — cosmético; use cron |

---

**Próximo:** volte ao [`onboarding-novo-dev.md`](onboarding-novo-dev.md) §7 (primeira sessão)
e §8 (branches/autosync/Lovable) — daqui em diante o fluxo é o mesmo de qualquer SO.
