# Onboarding — Novo Dev no ideIAos

> Passo a passo **cirúrgico** para um dev novo, em máquina nova, sair do zero e começar a
> trabalhar nos projetos da Ideia Business com o ideIAos rodando.
>
> Tempo total: ~20–40 min (a maior parte é download/`npm install` rodando sozinho).
> Os passos manuais estão marcados com 🖐️.

## 🖥️ Qual é o seu sistema operacional?

O ideIAos é bash-based; o caminho muda no **Passo 1–6** conforme o SO:

| SO | Trilha | Autosync |
|----|--------|----------|
| **macOS** | **este guia** — bootstrap `setup-dev-machine.sh` faz quase tudo em 1 comando | LaunchAgent (`launchd`) |
| **Windows** | → **[`windows-wsl.md`](windows-wsl.md)** — 2 caminhos: **nativo + Git Bash** (⚗️ consumidor) ou **WSL2** (✅ garantido) | Task Scheduler ou cron |
| **Linux** | siga o **[`windows-wsl.md`](windows-wsl.md)** (Caminho B) a partir do *Passo 1* (pule o Passo 0 do WSL) | cron / systemd |

A **seção 0** (acessos) e as **seções 7–10** (primeira sessão, branches/autosync, manutenção,
troubleshooting) valem para **todos os SO** — só os passos de instalação 1–6 divergem.

## 👤 Você é consumidor ou mantenedor?

A distinção que mais simplifica a instalação:

- **Consumidor** (a maioria) — trabalha **nos projetos** (cfoai, nfideia, lapidai, ideiapartner).
  Precisa de **muito pouco**: **Claude Code + git + Node + os plugins** (`claude plugin install
  ideiaos-core@ideiaos`). A config dos projetos (AGENTS.md, `.claude/`, `.cursor/rules`) **já vem
  no `git clone`** — não roda `setup.sh`. No Windows, pode tentar o caminho **nativo** (sem WSL).
- **Mantenedor** — mexe **no próprio ideIAos** (skills, hooks, build, autosync). Aí sim roda o
  bootstrap completo abaixo (e, no Windows, usa **WSL2** para paridade total).

Este guia detalha o caminho **completo/mantenedor** (macOS). Um consumidor pode parar após
instalar os plugins + clonar os projetos na branch `work`.

---

## 0. Antes de tocar no teclado (combinar com o Gustavo)

Três acessos precisam existir **antes** — não são auto-instaláveis:

| Acesso | Como obter | Quem provê |
|--------|-----------|------------|
| **Org GitHub `Ideia-Business`** (com **write**) | membro da org **+ push** nos 5 repos | 🖐️ Gustavo (admin) — ver nota abaixo |
| **Claude Code** (Anthropic) | conta/assinatura ativa para logar no CLI | 🖐️ Gustavo libera no plano do time |
| **Cursor IDE** (opcional) | conta Cursor — só se o dev for usar o Cursor além do Claude Code | o próprio dev |

> ⚠️ **Ser "membro" da org não basta — precisa de dois níveis de acesso:**
> - **Read** nos 5 repos → permite `git clone` e trabalhar localmente (geralmente vem do
>   *base permission* da org).
> - **Write / push** nos repos → **essencial**, porque o autosync empurra a branch `work`
>   a cada 15 min e os commits do dev precisam subir. Write costuma vir por **team** ou
>   **por repo**, não automaticamente por ser membro. Sem ele, o autosync **falha no push
>   silenciosamente** (erro em `~/.local/state/git-autosync.err.log`).
>
> **Confirme o write (rode após `gh auth login`) — `push` tem que ser `true` nos cinco:**
> ```bash
> for r in cfoai-grupori IdeiaOS lapidai nfideia ideiapartner; do
>   echo -n "$r → "; gh api repos/Ideia-Business/$r --jq '.permissions'
> done
> ```
> Se algum vier `"push":false`, o admin adiciona o dev a um **team com write** (ou concede
> push por repo). **Gotcha SAML/SSO:** se a org tiver SSO, o token do `gh` precisa ser
> **autorizado para a org**, senão o clone HTTPS de repo privado nega mesmo sendo membro.

---

## 1. Pré-requisitos da máquina — **macOS** (uma vez — **não** são auto-instalados)

> 🪟🐧 **Windows/Linux:** as seções **1–6** abaixo são o caminho **macOS**. No Windows/Linux,
> siga **[`windows-wsl.md`](windows-wsl.md)** e volte aqui na **seção 7**.

```bash
# Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Ferramentas base — o bootstrap ABORTA se faltar git/gh/node/npm
brew install git gh node

# Claude Code CLI (se 'claude' não estiver no PATH)
npm install -g @anthropic-ai/claude-code
```

Requisito de versão: **Node.js 18+** (o `setup.sh` valida e recusa versões antigas).

---

## 2. Autenticar (identidade + acessos) 🖐️

```bash
# GitHub — login + credential helper (deixa o git/gh empurrar sem pedir senha)
gh auth login            # escolha GitHub.com → HTTPS → login no browser
gh auth setup-git

# Identidade do git (aparece nos commits)
git config --global user.name  "Nome do Dev"
git config --global user.email "dev@redeideia.com.br"

# Claude Code — login na conta Anthropic
claude        # na primeira execução ele abre o fluxo de login; depois saia (/exit)
```

> O `setup-dev-machine.sh` (passo 3) também chama `gh auth login` se você ainda não
> estiver logado — mas adiantar aqui evita o prompt no meio do bootstrap.

---

## 3. Rodar o bootstrap (faz o grosso) 🖐️ 1 comando

Escolha **A** (recomendado) ou **B**:

```bash
# A) Clonar o ideIAos primeiro, depois rodar o bootstrap de dentro dele
mkdir -p ~/dev
git clone https://github.com/Ideia-Business/ideIAos.git ~/dev/IdeiaOS
bash ~/dev/IdeiaOS/setup-dev-machine.sh

# B) Se alguém te passou o arquivo via AirDrop:
bash ~/Downloads/setup-dev-machine.sh
```

O `setup-dev-machine.sh` é **idempotente** (pode rodar quantas vezes quiser) e executa,
em sequência:

1. **Pré-requisitos** — confere `git gh node npm` (aborta se faltar).
2. **GitHub auth** — `gh auth login` (se preciso) + `gh auth setup-git`.
3. **npm cache gravável** — evita `EACCES` em `~/.npm`.
4. **Shim `timeout`** — instala o comando `timeout` (o macOS não traz o do GNU) em
   `~/.local/bin`, usado pelo GSD e por vários workflows. Garante `~/.local/bin` no PATH.
5. **Clona os 5 repos** em `~/dev/` na branch **`work`** e roda `npm install` em cada:
   - `cfoai-grupori` · `IdeiaOS` · `lapidai` · `nfideia` · `ideiapartner`
6. **Autosync** — instala o daemon `git-autosync` como **LaunchAgent** (roda a cada
   **15 min** + no login, com kill-switch `timeout 120s`). Ele faz `pull`/`commit`/`push`
   automático da branch `work` de cada repo. (Detalhes e cuidados na seção 8.)
7. **Ambiente global ideIAos** — roda `setup.sh --global-only` + `sync-all.sh`:
   - **skills** globais (`/idea`, `/frontend-visual-loop`, `/motion`, `/web-quality`,
     Suíte de Design…) em `~/.claude/skills/`
   - **MCPs** `chrome-devtools` + `context7` (user scope)
   - **hooks** Claude Code (Fase A, deia-trigger, typecheck-on-edit…) em `~/.claude/hooks/`
   - **agentes Cursor** (`@claude-continuation`, `@ideiaos-checker`) em `~/.cursor/agents/`
   - o **overlay** de 15 patches sobre GSD/AIOX/Claude (`install-global-patches.sh`)
8. **Vault Obsidian** — registra o "Segundo Cérebro" nos working-dirs do Claude Code.

> ⚠️ No passo do **AIOX-core** pode aparecer um prompt de idioma — responda
> (só roda interativo porque há terminal). Se for pulado, rode depois:
> `npx aiox-core@latest install`.

---

## 4. Plugin GSD (passo manual do Claude Code) 🖐️

O GSD (60+ comandos `/gsd-*`) vem por **plugin** do Claude Code, instalado de dentro
da IDE:

```
# abra o Claude Code em qualquer projeto e digite:
/plugin     → adicionar o plugin GSD (get-shit-done)
```

Verifique depois: dentro do Claude Code, `/gsd-help` deve listar os comandos.

---

## 5. Segredos (`.env`) 🖐️

Os arquivos `.env` (chaves de API, tokens) são **gitignored** — não vêm pelo clone. Cada projeto
tem o seu.

- Peça ao Gustavo o **`.env` mínimo de dev** de cada projeto por **canal seguro** (1Password /
  Bitwarden ou onetimesecret), **nunca** por chat/e-mail em texto plano.
- Coloque na raiz do projeto: `~/dev/<projeto>/.env` (no WSL, crie com `nano .env`).
- **Least-privilege:** o `.env` de dev **não** inclui `SERVICE_ROLE_KEY` nem tokens de deploy
  (Vercel/Railway/GitHub/N8N) — só o necessário para rodar o app + IA. Quais chaves por projeto:
  [`env-setup-dev.md`](env-setup-dev.md).
- O bootstrap avisa `⚠ .env ausente em <projeto>` quando falta — é esperado em máquina nova.

> Regra-piso de segurança do ideIAos: **segredo nunca transita pelo contexto do LLM**.
> Você referencia por nome (`$ASAAS_API_KEY`); o valor vive no `.env`/secret-store.

---

## 6. Verificar (gate de saúde)

```bash
bash ~/dev/IdeiaOS/scripts/idea-doctor.sh      # alvo: 0 FAIL
```

Se acusar algo, o próprio `idea-doctor` mostra o comando de correção — quase sempre:

```bash
bash ~/dev/IdeiaOS/scripts/sync-all.sh
```

Checagens rápidas adicionais:

```bash
claude mcp list                 # deve listar chrome-devtools + context7
ls ~/.claude/skills | grep idea # deve existir a skill 'idea' (a Deia)
launchctl list | grep gitautosync   # autosync ativo
```

---

## 7. Primeira sessão de trabalho — como o dia a dia funciona

O ponto de entrada é a **Deia** (orquestrador `/idea`). Você não precisa decorar 20
comandos — fala em português natural e ela roteia:

```bash
cd ~/dev/nfideia        # ou qualquer projeto
claude                  # abre o Claude Code no projeto
```

Dentro do Claude Code:

| Você quer… | Diga (ou comando direto) |
|------------|--------------------------|
| Implementar uma feature | `Deia, implementar busca por CNPJ` → roteia p/ GSD |
| Retomar de onde parou | `Deia, retoma de onde paramos` → `/cursor-continuation` |
| Fix rápido | `Deia, corrige esse bug do total` → `/gsd-quick` |
| Alinhar antes de codar | `/grelha` (te entrevista antes do plano) |
| Duvidar de uma decisão | `/doubt` (revisão adversarial em-voo) |
| Subir pra Lovable | `/lovable-handoff` (só em projeto Lovable) |
| Personas (story-driven) | `@pm`, `@po`, `@sm`, `@dev`, `@qa`, `@architect`, `@devops` |

**No início de cada sessão não-trivial:** `/recall-learnings`.
**No fim:** `/extract-learnings` (registra o que aprendeu).

---

## 8. Branches, autosync e Lovable — **leia antes do 1º commit**

Modelo de branches da frota:

- **`work`** = motor. É onde você trabalha e onde o **autosync empurra automaticamente**
  (a cada 15 min).
- **`main`** = release. Nos projetos **Lovable**, `main` dispara deploy automático — por
  isso **a IA nunca commita direto na `main`** desses projetos; vai sempre por branch/PR.
  - **Exceção:** o **próprio ideIAos não é Lovable** → pode ir direto na `main`.

Implicações práticas:

- Você não precisa `git push` manual no fluxo normal — o autosync cuida da `work`.
- O autosync faz `git add -A` da árvore inteira: **se você está no meio de uma cirurgia
  git multi-passo, pause-o** para não contaminar commits:
  ```bash
  bash ~/dev/IdeiaOS/scripts/autosync-pause.sh on    # pausa
  # … sua operação git …
  bash ~/dev/IdeiaOS/scripts/autosync-pause.sh off   # retoma (SEMPRE retome)
  ```
- A `main` **só recebe pull** pelo autosync. Se você commitar na `main`, o autosync **não
  empurra automaticamente** — mas **avisa** (notificação "push MANUAL: N commit(s) no main").
  Ou seja, commits na `main` não "somem" sem aviso; só exigem `git push` manual.

---

## 9. Manutenção do ambiente (recorrente)

| Quando | Comando | O que faz |
|--------|---------|-----------|
| Atualizar tudo (1 comando) | `bash ~/dev/IdeiaOS/scripts/ideiaos-update.sh` | `sync-all` + guardas autosync + registra hooks/statusline no `settings.json` |
| Só puxar + reaplicar overlay | `bash ~/dev/IdeiaOS/scripts/sync-all.sh` | pull → upstream → setup global → overlay → doctor |
| Diagnóstico de saúde | `bash ~/dev/IdeiaOS/scripts/idea-doctor.sh` | read-only, aponta drift e correção |
| Configurar o ideIAos num projeto novo | `bash ~/dev/IdeiaOS/setup.sh /caminho/do/projeto` | cria `IDEIAOS.md`, `.planning/`, AGENTS.md, rules, etc. |
| (No Claude Code) auditar setup de um projeto | `/ideiaos-setup` | idempotente — só aplica o que falta |

> Diferença: `setup.sh` **nunca** edita seus dotfiles/`settings.json` (só imprime
> snippets). O `ideiaos-update.sh` **edita** — rodá-lo é o consentimento explícito.

---

## 10. Troubleshooting rápido

| Sintoma | Causa provável | Correção |
|---------|----------------|----------|
| `clone falhou` nos repos | sem read no repo, ou token SSO não autorizado | confirmar membership/SSO (`gh api user/memberships/orgs/Ideia-Business`) |
| autosync não empurra (commita local mas não sobe) | falta **write/push** nos repos | checar `gh api repos/Ideia-Business/<repo> --jq '.permissions'` → `push:true`; admin concede write |
| `timeout: command not found` | shim ausente / PATH | re-rodar `setup-dev-machine.sh` (passo 4) |
| skills `/idea` não aparecem | setup global não rodou | `bash ~/dev/IdeiaOS/setup.sh --global-only` |
| GSD `/gsd-*` ausente | plugin não instalado | `/plugin` no Claude Code (seção 4) |
| MCP chrome-devtools/context7 some | user scope não configurado | `bash ~/dev/IdeiaOS/scripts/sync-all.sh` |
| autosync não roda | LaunchAgent não carregou | `launchctl kickstart -k gui/$(id -u)/com.ideiaos.gitautosync` |
| `idea-doctor` com FAIL | drift do overlay | rodar o comando que ele sugere (quase sempre `sync-all.sh`) |

---

## Caminhos que ficam instalados (referência)

| O quê | Onde |
|-------|------|
| Repos de trabalho | `~/dev/<projeto>/` |
| ideIAos (este repo) | `~/dev/IdeiaOS/` |
| Skills globais | `~/.claude/skills/` |
| Hooks Claude | `~/.claude/hooks/` |
| MCPs (user scope) | config do Claude Code (`claude mcp list`) |
| Agentes Cursor | `~/.cursor/agents/` |
| AIOX-core (engine, por-máquina) | via `npx aiox-core` (não versionado) |
| Autosync (LaunchAgent) | `~/Library/LaunchAgents/com.ideiaos.gitautosync.plist` |
| Contexts/statusline | `~/.ideiaos/` |

---

**Documentação complementar no projeto-alvo** (criada pelo `setup.sh`):
`IDEIAOS.md` (manifesto) · `docs/ideiaos/GUIDE-HUMANS.md` · `docs/ideiaos/GUIDE-AI.md` ·
`docs/ideiaos/DECISION-MATRIX.md`.

Visão completa do ecossistema: [`README.md`](../../README.md) na raiz do ideIAos.
