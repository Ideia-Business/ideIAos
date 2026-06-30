# Runbook A' — Migração de autenticação GitHub: token org-wide → FG-PAT escopado por-máquina

> **Requisito:** R16-03 (Frente A do gate F1 do v16) · **ADR:** `docs/decisions/v16-r16-03-github-identity-transport.md` (ACEITO, Opção C híbrida, regime FREE advisory) · **Idioma:** pt-BR

---

> ## ⚠️ INVARIANTE — credential-isolation (regra-piso, inegociável)
>
> O **valor** de qualquer token/segredo (FG-PAT, token clássico, senha) **NUNCA** transita pelo contexto do LLM/agente, **NUNCA** é colado no chat, e **NUNCA** é commitado em arquivo algum.
>
> - O **dono** emite o token na UI do GitHub e o injeta **fora do contexto do agente**, digitado/colado interativamente no terminal da máquina-alvo (stdin/prompt).
> - Este runbook referencia tokens **por NOME** — `$FGPAT_<MAQUINA>` — nunca por valor.
> - **Nenhum passo escreve o token em arquivo.** A entrega é sempre via prompt interativo de stdin. Não há arquivo efêmero de token neste runbook.
> - Se em qualquer passo um valor de token aparecer no history do terminal, no chat ou num arquivo, **PARE** e revogue o token imediatamente.
> - **Cuidado copia-cola:** os blocos abaixo nunca contêm um campo `password=<valor>` copiável. O valor é sempre digitado quando o helper aguarda stdin — copiar um bloco inteiro com Enter jamais grava uma string-placeholder como senha.

---

## 1. Objetivo + pré-condição

**Objetivo:** substituir a credencial de automação GitHub (autosync/CI) — hoje um **token OAuth/clássico org-wide** da service account `DevIdeiaBusiness`, com escopo `[repo, workflow, read:org]` — por **um FG-PAT escopado por-máquina**, restrito **apenas aos repos que aquela máquina sincroniza**.

**Por que (o ganho central — blast-radius):**

| Estado | Comprometer 1 máquina dá acesso a... |
|--------|--------------------------------------|
| **Hoje** (token org-wide) | push em **TODOS** os repos da org `Ideia-Business` |
| **Depois** (FG-PAT por-máquina) | push **apenas** nos repos daquela máquina (escopo do FG-PAT) |

A reversão também fica isolada: revogar 1 dev/máquina = revogar 1 FG-PAT, sem rotação global.

**Pré-condições e fatos de transporte (confirmados por exit-code nesta máquina):**
- A automação real é o autosync (`source/autosync/git-autosync.sh`), que **não gerencia auth próprio** — faz `git push` direto e delega ao **credential helper do git**.
- **Descompasso de superfície a tratar:** nesta máquina `gh auth status` reporta storage = **keyring**, mas `git config --get credential.helper` = **osxkeychain**. São **duas camadas distintas**: o `gh` guarda no keyring; o `git push` puro do autosync lê do **osxkeychain**. **O caminho que importa para a automação é o osxkeychain** — é nele que o FG-PAT precisa estar.
- A **autoridade** do v16 (RBAC por assinatura O2 + pin local) **não depende do GitHub** — esta migração toca só o **transporte**. Push indevido em repos de código é o pior caso; não há perda de autoridade de comando.
- **Regime FREE / advisory** (decisão do dono no ADR): o escopo do FG-PAT é **disciplina por convenção**, não enforcement de organização. Não há política central de FG-PAT nem branch protection em repos privados.

---

## 2. Passo 0 — Descobrir os repos que ESTA máquina sincroniza

O autosync lê a lista de diretórios de `~/.local/state/git-autosync-repos.txt`. Cada linha é um caminho de repo local; o `owner/repo` real vem do `remote origin`. Rode na máquina-alvo:

```bash
# Lista owner/repo de cada repo que ESTA máquina sincroniza, derivado do remote real
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  case "$dir" in \#*) continue ;; esac          # ignora comentários
  url=$(git -C "$dir" remote get-url origin 2>/dev/null) || continue
  # normaliza https e ssh -> owner/repo
  echo "$url" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##'
done < ~/.local/state/git-autosync-repos.txt | sort -u
```

**Resultado esperado nesta máquina (MacBook-Air-2) — 5 repos, todos owner `Ideia-Business`:**

```
Ideia-Business/cfoai-grupori
Ideia-Business/ideIAos
Ideia-Business/ideiapartner
Ideia-Business/lapidai
Ideia-Business/nfideia
```

> Essa lista é o **escopo exato** do FG-PAT desta máquina (Passo 1). Cada máquina da frota tem a sua própria lista — **rode este passo em cada máquina** antes de emitir o token dela.

Anote também a **identidade ativa atual** e o **helper efetivo do git** (sem expor valor de token):

```bash
gh auth status                         # conta/identidade ativa (camada gh/keyring)
git config --get credential.helper     # helper que o git push REALMENTE usa — esperado: osxkeychain
```

Esperado nesta máquina: conta `DevIdeiaBusiness`; `gh` storage = keyring; **helper do git = `osxkeychain`** (a camada que a automação usa).

---

## 3. Passo 1 — Emissão do FG-PAT por-máquina (GitHub UI)

> ### Quem emite cada token (ator emissor — resolve a lacuna do ThinkPad)
>
> Emitir um FG-PAT com **resource owner = org `Ideia-Business`** exige estar autenticado **como a service account `DevIdeiaBusiness`**. Nenhum dev não-admin (ex.: Lucas, `lucas-abreu56`) tem essa sessão — então **o dono é o emissor de TODOS os FG-PATs da frota**.
>
> **Para preservar credential-isolation, o dono executa Passo 1 + Passo 2 NA SESSÃO DA PRÓPRIA MÁQUINA-ALVO** (acesso direto ou SSH para aquela máquina), de modo que o valor do token **só toque o terminal local daquela máquina** e **nunca um canal de mensageria** (Slack/e-mail/arquivo). **Nunca** emitir o token numa máquina e "entregar" para outra — isso põe o valor num canal e viola a regra-piso.
> - **ThinkPad do Lucas:** o dono acessa a máquina do Lucas (SSH/remoto), emite logado como `DevIdeiaBusiness`, e instala o FG-PAT direto no helper local daquela máquina. Lucas **não** recebe e **não** precisa da credencial da service account em mãos.
>
> **Antes de emitir — verificar a policy de FG-PAT da org:** GitHub → org `Ideia-Business` → **Settings** → **Personal access tokens** → **Settings**. Se **"Require approval"** estiver ativo (pode estar, mesmo em plano FREE), cada FG-PAT recém-emitido fica **pendente** até um admin da org aprovar. Documente/execute esse passo de aprovação **antes** de tentar usar o token (senão o Passo 3 falha por token ainda-não-aprovado, não por escopo).

Passos na UI, logado como `DevIdeiaBusiness`:

1. GitHub → avatar `DevIdeiaBusiness` → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
2. **Token name:** nome que identifique a máquina e o propósito — ex.: `autosync-macbook-air-2`, `autosync-mac-mini`, `autosync-thinkpad-lucas`.
3. **Resource owner:** `Ideia-Business` (a organização — **não** a conta pessoal).
4. **Expiration:** **curta** (ex.: 30–90 dias). Anote a data e crie lembrete de renovação (ver Passo 5). FG-PAT escopado + expiração curta é a postura do regime advisory.
5. **Repository access:** **Only select repositories** → selecione **APENAS os repos da saída do Passo 0 daquela máquina**.
   - MacBook-Air-2 → os 5 repos listados acima.
   - Mac-mini / ThinkPad do Lucas → exatamente os repos da saída do Passo 0 **daquela** máquina (podem diferir).
   - **Nunca** selecione "All repositories" — isso recria o blast-radius org-wide que estamos eliminando.
6. **Permissions → Repository permissions** (mínimas — least-privilege / Excessive Agency):
   - **Contents:** **Read and write** (o autosync faz `git push` — exige isto).
   - **Workflows:** **Read and write** **SOMENTE se** o CI daquela máquina precisar push de arquivos em `.github/workflows/`. Se não há esse caso, **deixe "No access"**.
   - **Metadata:** **Read-only** (concedida automaticamente; obrigatória).
   - Todo o resto: **No access**.
7. **Generate token.** O GitHub mostra o valor **uma única vez**. Se a policy exigir aprovação, o token só funciona **após** o aprovador da org liberá-lo.
8. **Uso imediato, sem persistir:** o dono mantém o valor na área de transferência **apenas** o tempo de colá-lo no prompt do Passo 2 (naquela mesma máquina). **Não** escreva o valor em arquivo, no chat, ou neste runbook. Referência por nome: **`$FGPAT_<MAQUINA>`** (ex.: `$FGPAT_MACBOOK_AIR_2`).

---

## 4. Passo 2 — Instalar o FG-PAT no helper que a automação USA (osxkeychain)

> Executado na máquina-alvo, pelo dono. **A automação faz `git push` puro e lê do `osxkeychain`** — então o FG-PAT vai **direto no osxkeychain**, e **não** se usa `gh auth setup-git` (que trocaria o helper do git para `gh`/keyring e deixaria a camada errada autenticada).

### 4.1 — Apagar a credencial antiga do osxkeychain (obrigatório)

O `osxkeychain` **cacheia a credencial por host** (`github.com`). Sem apagar a entrada antiga, o autosync continua usando o **token org-wide** silenciosamente. Apague primeiro:

```bash
printf "protocol=https\nhost=github.com\n" | git credential-osxkeychain erase
```

### 4.2 — Instalar o FG-PAT no osxkeychain via prompt interativo (caminho recomendado p/ automação)

> O bloco abaixo **não contém o valor**. As 4 primeiras linhas são fixas; ao chegar na 5ª (`password=`) o operador **digita/cola o FG-PAT e dá Enter**, depois uma linha em branco para fechar. Nada do token vai para arquivo ou history.

Inicie o helper em modo store e alimente os campos **digitando-os** (username da service account = `DevIdeiaBusiness`):

```bash
git credential-osxkeychain store
# Agora DIGITE, uma linha por vez (o helper lê de stdin até a linha em branco):
#   protocol=https⏎
#   host=github.com⏎
#   username=DevIdeiaBusiness⏎
#   password=  <- DIGITE/COLE O FG-PAT AQUI e dê Enter (nunca aparece neste doc)
#   ⏎          <- linha em branco encerra o store
```

> Não copie um bloco pronto com `password=<...>` — digite o campo `password=` na hora e cole só o valor após o `=`. Assim é impossível gravar uma string-placeholder como senha por engano.

### 4.3 — (Alternativa humana/interativa) via gh CLI

Reserve este caminho para **uso humano interativo**, **não** para a credencial de automação. Aviso do próprio `gh`: o `gh auth login` foi desenhado para **scopes clássicos** (`repo, read:org, gist`) e adverte que passar um **FG-PAT** a `--with-token` pode gerar **comportamento confuso** — um FG-PAT não carrega scopes clássicos, então `gh auth status` pode exibir estado incompleto. Se usar mesmo assim:

```bash
# Lê o token de STDIN no prompt interativo (não passe como argumento de linha de comando):
gh auth login --hostname github.com --git-protocol https --with-token
# cole o FG-PAT quando o prompt aguardar stdin; nada vai para o history
```

> **Não rode `gh auth setup-git`** se o objetivo é a automação por `git push` puro — ele aponta o helper do git para `gh` (keyring), divergindo da camada osxkeychain que o autosync usa. Se você intencionalmente quiser que o git passe a usar o `gh` como helper, então o helper efetivo muda para `gh` e o `erase` do 4.1 é só higiene de entrada órfã — documente essa escolha e revalide o Passo 3 contra o helper resultante.

### 4.4 — Fixar e PROVAR qual credencial o git efetivamente usa (sem expor valor)

Não confie no `gh auth status` (camada keyring) como prova para a automação. Confirme o **helper ativo** e **qual credencial o git de fato resolve** para `github.com`:

```bash
# 1) Helper que o git usa — esperado: osxkeychain
git config --get credential.helper

# 2) Credencial que o git RESOLVE para github.com — confirma só o username, nunca o valor.
#    Forneça protocol/host por stdin; o git imploded preenche pelo helper.
printf "protocol=https\nhost=github.com\n" | git credential fill 2>/dev/null | grep '^username='
# ESPERADO: username=DevIdeiaBusiness  (o password é retornado pelo fill mas NÃO o exibimos/gravamos)
```

> Se `credential.helper` não for `osxkeychain`, ou o `username` resolvido não for `DevIdeiaBusiness`, **PARE**: a automação está apontando para a camada errada. Corrija antes do Passo 3 — caso contrário o teste de validação roda contra um helper indeterminado e pode dar **verde validando o caminho errado**.

---

## 5. Passo 3 — Teste por exit-code COM inspeção de status (provar o blast-radius isolado, sem falso-verde)

O ponto central: o FG-PAT de uma máquina **não** pode operar em repo **fora** do seu escopo. `exit≠0` **sozinho não prova isolamento** — pode ser rede caída, repo inexistente/typo, ou erro genérico. Pior: um FG-PAT escopado retorna **404 (not found)** — não 403 — para repo fora do escopo, indistinguível de repo que não existe. Por isso o teste exige: (a) **repo-alvo que comprovadamente EXISTE e está fora do escopo**, (b) **controle de conectividade na mesma janela de rede**, (c) **inspeção da mensagem**, e (d) **prova de bloqueio de ESCRITA** via `push --dry-run`.

### 5.1 — Pré-requisitos do teste

- Escolha um repo da org `Ideia-Business` que **comprovadamente EXISTE** e está **FORA** da lista do Passo 0 desta máquina. **A existência deve ser confirmada separadamente pelo dono** (com uma credencial que enxergue o repo) — senão um 404 por "não existe" se disfarça de 404 por "sem permissão". Use abaixo como `<repo-fora-do-escopo-que-existe>`.
- Desabilite prompt interativo para o git não pendurar pedindo senha: `GIT_TERMINAL_PROMPT=0`.

### 5.2 — Controle de transporte (mesma janela de rede)

```bash
# Conectividade a github.com AGORA — descarta falso-negativo por rede caída.
git ls-remote https://github.com/Ideia-Business/ideIAos.git >/dev/null 2>&1
echo "controle_rede_exit=$?"   # ESPERADO: 0 (rede+credencial OK p/ repo NO escopo)
```

Se este controle **falhar** (`≠0`), **a rede ou a credencial está quebrada** — o teste negativo abaixo seria inconclusivo. Resolva antes.

### 5.3 — Teste NEGATIVO de LEITURA (com inspeção da mensagem)

```bash
# Captura saída+status; exige NEGAÇÃO DE AUTORIZAÇÃO, não erro genérico.
out=$(GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/Ideia-Business/<repo-fora-do-escopo-que-existe>.git 2>&1); rc=$?
echo "negativo_read_exit=$rc"
echo "$out"
# ESPERADO: rc != 0  E  a saída indica falta de permissão / 'not found' por autorização
#           (ex.: 'Repository not found', 'could not read Username', '403'/'404' de auth).
# REPROVA se a saída indicar erro de REDE/DNS/timeout (resultado inconclusivo, repita).
```

### 5.4 — Teste NEGATIVO de ESCRITA (o blast-radius real)

```bash
# Push de escrita ao repo fora-do-escopo DEVE ser negado. --dry-run não muta nada.
out=$(GIT_TERMINAL_PROMPT=0 git push --dry-run \
  https://github.com/Ideia-Business/<repo-fora-do-escopo-que-existe>.git HEAD:refs/heads/__perm_probe__ 2>&1); rc=$?
echo "negativo_write_exit=$rc"
echo "$out"
# ESPERADO: rc != 0 com negação de permissão de escrita (403/denied/not found por auth).
```

### 5.5 — Teste POSITIVO de controle (mesma janela)

```bash
# Repo DENTRO do escopo: leitura deve SUCEDER (prova que o FG-PAT funciona p/ o autosync).
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/Ideia-Business/ideIAos.git >/dev/null 2>&1
echo "positivo_read_exit=$?"   # ESPERADO: 0
```

### 5.6 — Critério de aprovação

| Teste | Repo | Esperado | Significado |
|-------|------|----------|-------------|
| Controle de rede (5.2) | dentro do escopo | exit `0` | rede+credencial OK na janela |
| Negativo leitura (5.3) | fora do escopo (existe) | exit `≠0` **+ mensagem de autorização** (não rede) | leitura isolada ✅ |
| Negativo escrita (5.4) | fora do escopo (existe) | exit `≠0` **+ negação de escrita** | **blast-radius de push isolado** ✅ |
| Positivo (5.5) | dentro do escopo | exit `0` | autosync ainda funciona ✅ |

> Só prossiga se **todos os quatro** baterem. Se o negativo retornar `0` (sucesso indevido), o FG-PAT **está mais amplo que o devido** — volte ao Passo 1 e reescopo. Se a mensagem do negativo for de **rede/DNS/timeout**, o teste é **inconclusivo** — repita com rede estável. **Não** revogue o token org-wide enquanto esta tabela não fechar.

---

## 6. Passo 4 — Revogar o token org-wide (só DEPOIS de validar a frota toda)

> **Ordem inviolável:** o token org-wide só é revogado **após** o autosync de **TODAS as 3 máquinas** estar provado funcionando com seus FG-PATs. Revogar antes derruba a automação das máquinas ainda não migradas.

### Checklist de validação por-máquina (preencher antes de revogar)

Para **cada** máquina da frota, confirme:

- [ ] Passo 0 rodado — lista de repos da máquina conhecida; `git config --get credential.helper` = `osxkeychain` (ou helper documentado).
- [ ] Passo 1 — FG-PAT emitido **pelo dono na sessão local daquela máquina**, escopo = só esses repos, permissões mínimas, **aprovado pela org** se a policy exigir.
- [ ] Passo 2 — entrada antiga do keychain apagada + FG-PAT no **osxkeychain**; **4.4 provou** `credential.helper=osxkeychain` e `username=DevIdeiaBusiness` resolvido.
- [ ] Passo 3 — controle de rede `=0`, negativo leitura **e** escrita `≠0` com mensagem de autorização, positivo `=0`.
- [ ] **Autosync real validado:** um ciclo de autosync completou um `git push` num repo da máquina usando o FG-PAT (verificar por **exit-code do push / log do daemon** — não por leitura). Ex.: tocar um arquivo de teste num repo no escopo, deixar o autosync rodar, confirmar push bem-sucedido.

### Revogação (após o checklist completo nas 3 máquinas)

GitHub (logado como `DevIdeiaBusiness`) → **Settings** → **Developer settings** → localizar o **token org-wide** (OAuth/classic com `repo, workflow, read:org`) → **Revoke**.

**Pós-revogação — confirmar que nada quebrou:**

```bash
# Em cada máquina, re-rodar o positivo de controle após a revogação:
GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/Ideia-Business/ideIAos.git >/dev/null 2>&1
echo "pos_revogacao_exit=$?"   # ESPERADO: 0 (FG-PAT segue válido; só o org-wide foi revogado)
```

---

## 7. Passo 5 — Replicar nas 3 máquinas (tabela de status)

Repita Passos 0→3 em cada máquina (o **dono** executa Passo 1+2 na sessão local de cada uma); só então execute o Passo 4 (revogação global, uma única vez).

| Máquina | Conta da automação | Emissor do FG-PAT | Passo 0 | Passo 1 | Passo 2 (osxkeychain) | 4.4 helper provado | Passo 3 (neg leit+esc / pos) | Autosync validado | Token (por nome) |
|---------|--------------------|-------------------|---------|---------|-----------------------|--------------------|------------------------------|-------------------|------------------|
| **MacBook-Air-2** (esta) | `DevIdeiaBusiness` (bot) | dono (local) | ✅ 5 repos | ☐ | ☐ | ☐ | ☐ | ☐ | `$FGPAT_MACBOOK_AIR_2` |
| **Mac-mini** | `DevIdeiaBusiness` (bot) | dono (local) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | `$FGPAT_MAC_MINI` |
| **ThinkPad do Lucas** | `DevIdeiaBusiness` (bot)¹ | dono (remoto na máquina do Lucas)² | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | `$FGPAT_THINKPAD_LUCAS` |

> ¹ **Atenção (ThinkPad do Lucas):** a **automação** (autosync) usa a service account `DevIdeiaBusiness` com FG-PAT escopado — igual às demais. A **ação humana interativa** do Lucas (PRs, commits manuais) usa a **conta pessoal dele** (`lucas-abreu56`, dev não-admin, já autorizada por-repo) — Fase humana do ADR, fora do escopo deste runbook de transporte de automação. Não misture: commit de daemon = bot; commit de pessoa = conta pessoal.
>
> ² **Emissor e canal:** Lucas é não-admin e não tem a sessão da service account → **o dono** emite e instala o FG-PAT acessando **a própria máquina do Lucas** (SSH/remoto), para o valor tocar só o terminal local daquela máquina — **nunca** entregue o token por mensagem/arquivo. Lucas não recebe a credencial da service account.
>
> ³ **SO ≠ macOS:** o ThinkPad roda Linux/Windows — **o GOTCHA do `osxkeychain` (Passo 2) é específico do macOS**. Naquela máquina, o helper a operar é o equivalente do SO (Linux: `git credential-libsecret`/`cache`; Windows: `manager`). O princípio é idêntico — **apagar a entrada antiga de `github.com` e instalar o FG-PAT pelo helper local, sem `gh auth setup-git`** — e o **4.4 deve provar** que `credential.helper` é esse helper e que o `username` resolvido é `DevIdeiaBusiness`. Só o comando muda.

**Renovação:** cada FG-PAT tem expiração curta. Anote a data de expiração de cada token e crie lembrete de renovação por-máquina antes do vencimento — um FG-PAT expirado para o autosync **daquela** máquina (falha de push), não da frota.

---

## Critério de conclusão (Frente A do gate F1)

R16-03 está **concluído** quando, nas 3 máquinas: FG-PAT escopado instalado **no helper que a automação usa** (4.4 provado), teste por exit-code **com inspeção de status** prova o isolamento de leitura **e** escrita, autosync validado por push real, e o token org-wide **revogado**. A Frente B (motor multi-usuário com RLS + read-fan-out) é independente e não é desbloqueada nem bloqueada por este runbook — ambas as frentes precisam fechar para liberar F1.
