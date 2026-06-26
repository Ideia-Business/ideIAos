# SOURCE: IdeiaOS v15 | kind: plan | phase: v15-A (destravar) | plan: A-04 | targets: claude,cursor

---
phase: "v15-A"
plan: "A-04"
type: execute
wave: 1
depends_on: []
requirement: R15-05
files_modified:
  - scripts/install-alias.sh
  - source/agents/ideiaos-checker.md
  - source/skills/ideiaos-setup/SKILL.md
  - README.md
autonomous: true
must_haves:
  truths:
    - "O alias `idea-setup` aponta para o caminho REAL do repo (`$HOME/dev/IdeiaOS`), nunca para `Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS` (path iCloud inexistente nesta frota)."
    - "Toda FONTE que herda esse path (install-alias.sh, ideiaos-checker.md, ideiaos-setup/SKILL.md) é corrigida — não só o sintoma."
    - "As 3 cópias REAIS e LEGÍTIMAS do `.aiox-core` ficam DESAMBIGUADAS por papel no README (npm-global = runtime; `~/dev/.aiox-core` = debug instalado/alvo do overlay; vendor no repo = cópia PRISTINE **ignorada pelo git**); o vendor PRISTINE é PRESERVADO, NUNCA editado, NUNCA unificado."
    - "FATO GIT VERDADEIRO (verificado): o vendor `.aiox-core/` está em `.gitignore:34` e `git ls-files .aiox-core` = 0 — é **UNTRACKED/IGNORED**, NÃO versionado. Nenhuma linha do README pode afirmar que o `.aiox-core` é 'tracked'/'versionado'."
    - "O slug GitHub no README é `Ideia-Business/ideIAos` (casing exato do remote `git remote -v`, repo PÚBLICO confirmado 2026-06-25); o casing errado `Ideia-Business/IdeiaOS` é eliminado (2 ocorrências: README:119, :124)."
    - "Usos LEGÍTIMOS de iCloud (vault Obsidian, transporte de `.env.local` pelo envsync) NÃO são tocados — só o path morto do alias."
  invariants:
    - "O diretório `.aiox-core/` do repo permanece byte-idêntico — provado por **checksum de conteúdo no FS** (`find .aiox-core -type f -exec shasum {} + | sort | shasum`), NUNCA por `git rev-parse HEAD:.aiox-core` (o vendor não está em HEAD: esse comando sai exit 128 / STDOUT vazio → teatro-verde)."
    - "Verificação SEMPRE por exit-code binário (grep/test/checksum), NUNCA pelo Read tool (antifragile-gates)."
    - "Pausa do autosync usa o mecanismo SANCIONADO `scripts/autosync-pause.sh` (pause-file canônico `${HOME}/.local/state/git-autosync.pause` que `source/autosync/git-autosync.sh:85` realmente lê), NÃO um path inerte."
    - "O plano NÃO faz git push nem gh pr (exclusivo @devops)."
---

## META — goal-backward

**Objetivo final (o que o usuário ganha):** um README e um alias em que CADA fato é verdadeiro
— o `idea-setup` funciona em qualquer máquina da frota (path real, não iCloud-fantasma), o leitor
entende POR QUE há 3 `.aiox-core` (em vez de achar que é bug/lixo), e quem clona usa o slug certo
(`Ideia-Business/ideIAos`) sem 404. Isto destrava o debug (R15-15 depende de R15-05 mergeado) e
remove erosão de confiança.

**Backward da meta às tasks:**
1. Para o slug ficar certo → corrigir as 2 ocorrências de casing errado no README (119, 124). ← Task 4
2. Para as 3 cópias deixarem de parecer bug → rotular cada uma por PAPEL no README (224, 237, 839)
   **com o estado git VERDADEIRO** (vendor = ignorado, não tracked), sem mexer no FS nem no vendor. ← Task 3
3. Para o alias funcionar → corrigir o path na FONTE (`install-alias.sh:7`) E nas fontes que o
   copiam verbatim (`ideiaos-checker.md`, `ideiaos-setup/SKILL.md`). ← Tasks 1 e 2
4. Para nada disso corromper a entrega → pausar autosync (mecanismo sancionado) antes da cirurgia
   multi-arquivo e provar o vendor PRISTINE intacto por **checksum de FS**. ← Task 0 (pré) e Task 5 (gate final).

**Por que A-04 é Wave 1 / depends_on: [] :** é correção factual auto-contida (texto/path), não
depende de nenhuma outra unidade; e R15-15 (consolidação de docs de instalação) tem HARD-GATE
"só após R15-05 mergeado", logo A-04 é pré-requisito de fase posterior.

---

## ACHADOS REAIS (fundamentação — confirmados por grep/git/FS, não por suposição)

| # | Achado (arquivo:linha) | Estado atual (VERIFICADO) | Ação |
|---|------------------------|--------------|------|
| a1 | `scripts/install-alias.sh:7` | `DEV_SETUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS"` (path iCloud inexistente; repo real = `~/dev/IdeiaOS`) | corrigir FONTE |
| a2 | `source/agents/ideiaos-checker.md:29` e `:199` | mesma string iCloud legada (`:29` define `DEV_SETUP=...`; `:199` é `bash "$HOME/.../setup.sh" --project-only ...`) | corrigir |
| a3 | `source/skills/ideiaos-setup/SKILL.md:38` | `ls "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS/setup.sh" ...` | corrigir |
| b1 | `README.md:224` | `\| AIOX-core (framework) \| ~/dev/.aiox-core/ \|` (cópia DEBUG/instalada — alvo do overlay; sem rótulo de papel) | rotular "debug/instalado" |
| b2 | `README.md:237` | `\| AIOX Core \| npm global via npx aiox-core \| ...` (runtime npm; `aiox-core@5.2.9` confirmado em `npm ls -g`) | rotular "runtime npm-global" |
| b3 | `README.md:839` | árvore upstream `Projects/.aiox-core/` (refere a cópia INSTALADA via npm upstream, não o vendor do repo) | nota de desambiguação (3 papéis) |
| c1 | `README.md:119` | "Se o repo `Ideia-Business/IdeiaOS` ainda não estiver público…" + "Decisão de tornar o repo público: **pendente do usuário**" (casing errado + premissa obsoleta) | `Ideia-Business/ideIAos` + remover premissa-pendente |
| c2 | `README.md:124` | `claude plugin marketplace add Ideia-Business/IdeiaOS` (casing errado) | `Ideia-Business/ideIAos` |

**FATO GIT do vendor (verificado — corrige a premissa falsa do draft anterior):**
- `grep -n "aiox-core" .gitignore` → `34:.aiox-core/` e `74:.aiox-core/local/`.
- `git ls-files .aiox-core | wc -l` → **0** (nenhum arquivo do vendor está versionado).
- `git check-ignore .aiox-core` → exit **0** (está ignorado).
- ∴ O vendor é **PRISTINE no sentido de "cópia local intocada, IGNORADA pelo git"** — NÃO é "tracked/versionado". Qualquer texto no README que diga "tracked" sobre o `.aiox-core` é **FATO FALSO** (Article IV — No Invention).

**Por que `git rev-parse HEAD:.aiox-core` NÃO serve (corrige o teatro-verde do draft anterior):**
- Reproduzido: `git rev-parse 'HEAD:.aiox-core'` → `fatal: path '.aiox-core' exists on disk, but not in 'HEAD'`, **exit 128**, STDOUT vazio.
- Logo o baseline ficaria vazio e o gate `[ "$(git rev-parse ...)" = "$(cat ...)" ]` compararia **vazio == vazio = exit 0 INCONDICIONAL** — passaria mesmo com o vendor deletado. **Falso-verde absoluto** (memória antitheater-gate-blind-spot-happy-path).
- Substituto provado: `find .aiox-core -type f -exec shasum {} + | sort | shasum` muda quando o conteúdo muda (testado: baseline `15f8f2b2…` vs recálculo com 1 arquivo a menos `48d7cbd6…` → DIFEREM). Gate REAL.

**As 3 cópias são REAIS (confirmado no FS):**
- `~/dev/IdeiaOS/.aiox-core` (**vendor PRISTINE**, EXISTE, **ignorado pelo git**).
- `~/dev/.aiox-core` (**debug/instalado**, EXISTE) — é onde o overlay aplica. `find_aiox_core` (`scripts/install-global-patches.sh:54`) busca `$(dirname "$SETUP_DIR")/.aiox-core` (= `~/dev/.aiox-core` quando o repo está em `~/dev/IdeiaOS`) e `$HOME/Projects/.aiox-core`.
- `aiox-core@5.2.9` (**runtime npm-global**, confirmado em `npm ls -g`).
- Logo: **DESAMBIGUAR, não unificar** (memória project-aiox-core-pristine-overlay).

**Mecanismo de pausa do autosync (corrige o GAP-3):**
- `source/autosync/git-autosync.sh:85` lê `${HOME}/.local/state/git-autosync.pause` **ou** `$REPO/.git/autosync-pause`. NÃO lê `~/.ideiaos/autosync.pause`.
- O wrapper sancionado é `scripts/autosync-pause.sh` (`on` cria o pause-file canônico, `off` remove, `status` mostra). É o que se usa antes de cirurgia git multi-arquivo (memórias autosync-races-ai-git-surgery + autosync-pushes-feature-branches — estamos em `work`, que o autosync auto-pusha).

**NÃO-tocar (usos legítimos de iCloud, confirmados por grep — fora de escopo):** vault Obsidian
(`docs/memory-sync-model.md`, `source/skills/{evolve,extract-learnings,recall-learnings,memory-sync}`,
`source/templates/hybrid/CLAUDE.md.tmpl`), transporte `.env.local` pelo envsync
(`docs/ideiaos-console/*`). Essas referências a `iCloud~md~obsidian` e `Library/Mobile Documents/`
são CORRETAS — marcá-las viraria scope-creep.

**O requisito cita linhas 224/237/839 — confirmadas; 301 NÃO se aplica** (README:301 é
`code-explorer`, irrelevante).

---

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/milestones/v15-REQUIREMENTS.md
@.planning/milestones/v15-ROADMAP.md
@README.md
@.gitignore
@scripts/install-alias.sh
@scripts/install-global-patches.sh
@scripts/autosync-pause.sh
@source/autosync/git-autosync.sh
</context>

<tasks>

<task type="auto">
  <name>Task 0 (pré): Pausar autosync (mecanismo sancionado) e gravar checksum-FS baseline do vendor PRISTINE</name>
  <files>(nenhum arquivo de produto — operação de segurança)</files>
  <read_first>
    - memória learning-autosync-races-ai-git-surgery (o autosync `add -A` + commit + push atropela cirurgia multi-arquivo)
    - memória learning-autosync-pushes-feature-branches (autosync auto-pusha branch não-main; estamos em `work`)
    - scripts/autosync-pause.sh (wrapper SANCIONADO: `on`/`off`/`status`; cria `${HOME}/.local/state/git-autosync.pause`)
    - source/autosync/git-autosync.sh:85 (o guard REAL lê `${HOME}/.local/state/git-autosync.pause` ou `$REPO/.git/autosync-pause` — NÃO `~/.ideiaos/autosync.pause`)
    - .gitignore:34 (`.aiox-core/` — o vendor é IGNORADO; baseline NÃO pode vir de `git rev-parse HEAD:.aiox-core`)
  </read_first>
  <action>
    (a) Pausar o autosync ANTES da cirurgia multi-arquivo, usando o wrapper sancionado (path correto, restauração garantida):
        `bash scripts/autosync-pause.sh on "A-04 cirurgia multi-arquivo R15-05"`
        e VERIFICAR que o pause-file canônico foi criado E que o binário DEPLOYADO de fato lê esse path
        (grep no deployado — learning autosync-pause-file-guard-not-deployed: o guard pode estar ausente do binário instalado):
        - `bash scripts/autosync-pause.sh status` deve reportar PAUSADO;
        - `grep -q 'git-autosync.pause' source/autosync/git-autosync.sh` confirma que a FONTE honra o path;
        - se houver binário deployado em `~/.local/state` ou `~/.ideiaos`, grep nele por `git-autosync.pause`; se NÃO casar, anotar no SUMMARY e proceder com janela curta (commit local atômico minimiza risco).
    (b) Gravar o CHECKSUM-FS baseline do vendor PRISTINE (NÃO `git rev-parse HEAD:.aiox-core` — esse sai exit 128/vazio):
        `find .aiox-core -type f -exec shasum {} + 2>/dev/null | sort | shasum | awk '{print $1}' > /tmp/a04_aiox_fs_before.txt`
    NOTA: este plano NÃO faz commit/push — apenas edita. A pausa protege contra o autosync capturar arquivos meio-editados; o commit/push é do executor/@devops no fechamento.
  </action>
  <acceptance_criteria>
    - Pausa SANCIONADA ativa (POSITIVA, path real): `bash scripts/autosync-pause.sh status` reporta pausado E `test -f "${HOME}/.local/state/git-autosync.pause"` exit 0.
    - A FONTE do daemon honra esse path (anti-path-inerte): `grep -q 'git-autosync.pause' source/autosync/git-autosync.sh` exit 0.
    - Baseline gravado NÃO-VAZIO (anti-teatro: input inválido = arquivo vazio reprova `test -s`): `test -s /tmp/a04_aiox_fs_before.txt` exit 0.
    - Baseline é um checksum REAL e estável (auto-teste anti-teatro — recalcular DEVE bater): `[ "$(cat /tmp/a04_aiox_fs_before.txt)" = "$(find .aiox-core -type f -exec shasum {} + 2>/dev/null | sort | shasum | awk '{print $1}')" ]` exit 0.
  </acceptance_criteria>
  <done>Autosync pausado pelo mecanismo sancionado (path real verificado); checksum-FS do vendor gravado não-vazio e auto-consistente, pronto para provar intocabilidade.</done>
</task>

<task type="auto">
  <name>Task 1: Corrigir o path morto do alias na FONTE (install-alias.sh)</name>
  <files>scripts/install-alias.sh</files>
  <read_first>
    - scripts/install-alias.sh:7 (linha exata: `DEV_SETUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS"`)
    - README.md:219 (fato canônico: `IdeiaOS (este repo) | ~/dev/IdeiaOS/`) — o path REAL da frota é `$HOME/dev/IdeiaOS`
  </read_first>
  <action>
    Substituir na linha 7 o path iCloud inexistente pelo path REAL do clone do repo:
    de  `DEV_SETUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS"`
    para `DEV_SETUP="$HOME/dev/IdeiaOS"`
    (mantendo o uso `$DEV_SETUP/setup.sh` na linha 8 intacto — só o caminho-base muda).
    NÃO alterar a lógica de detecção de shell rc nem o resto do script (escopo cirúrgico).
  </action>
  <acceptance_criteria>
    - String iCloud legada ELIMINADA do script (NEGATIVA, exit-code): `! grep -q "Mobile Documents" scripts/install-alias.sh` exit 0.
    - Path REAL presente (POSITIVA): `grep -q 'DEV_SETUP="\$HOME/dev/IdeiaOS"' scripts/install-alias.sh` exit 0.
    - Sintaxe bash íntegra (input inválido = script quebrado reprova): `bash -n scripts/install-alias.sh` exit 0.
  </acceptance_criteria>
  <done>install-alias.sh aponta para `$HOME/dev/IdeiaOS`; nenhuma string iCloud no script; sintaxe válida.</done>
</task>

<task type="auto">
  <name>Task 2: Corrigir o mesmo path morto nas fontes que o herdam (ideiaos-checker.md, ideiaos-setup/SKILL.md)</name>
  <files>source/agents/ideiaos-checker.md, source/skills/ideiaos-setup/SKILL.md</files>
  <read_first>
    - source/agents/ideiaos-checker.md:29 (`DEV_SETUP="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS"`)
    - source/agents/ideiaos-checker.md:199 (`bash "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS/setup.sh" --project-only --lovable "$PWD"`)
    - source/skills/ideiaos-setup/SKILL.md:38 (`ls "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS/setup.sh" 2>/dev/null \`)
  </read_first>
  <action>
    Em CADA um dos 3 pontos, substituir o prefixo iCloud
    `$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects/IdeiaOS`
    por `$HOME/dev/IdeiaOS` — preservando o sufixo de cada ocorrência (`/setup.sh` etc.) e o resto da linha.
    Estas são as MESMAS fontes que herdam o erro do alias (corrigir o sintoma só no README/script
    deixaria estas regenerando o path morto). NÃO tocar referências de iCloud ao VAULT Obsidian
    (são legítimas — fora de escopo).
  </action>
  <acceptance_criteria>
    - Zero ocorrências do path iCloud-Projects nestes 2 arquivos (NEGATIVA): `! grep -rq "com~apple~CloudDocs/Projects/IdeiaOS" source/agents/ideiaos-checker.md source/skills/ideiaos-setup/SKILL.md` exit 0.
    - Path REAL presente em ambos (POSITIVA): `grep -q "dev/IdeiaOS" source/agents/ideiaos-checker.md && grep -q "dev/IdeiaOS" source/skills/ideiaos-setup/SKILL.md` exit 0.
    - Varredura de cauda do path morto em todo `source/` + `scripts/` (input inválido = qualquer fonte esquecida reprova): `! grep -rq "com~apple~CloudDocs/Projects/IdeiaOS" source/ scripts/` exit 0.
  </acceptance_criteria>
  <done>As 2 fontes que copiavam o path iCloud agora usam `$HOME/dev/IdeiaOS`; nenhuma fonte com o path morto remanescente.</done>
</task>

<task type="auto">
  <name>Task 3: DESAMBIGUAR as 3 cópias .aiox-core no README por papel — com o FATO GIT VERDADEIRO (vendor = ignorado, não tracked)</name>
  <files>README.md</files>
  <read_first>
    - README.md:224 (`| AIOX-core (framework) | ~/dev/.aiox-core/ |` — a cópia DEBUG/instalada, alvo do overlay)
    - README.md:237 (`| AIOX Core | npm global via npx aiox-core | ...` — runtime npm-global; `aiox-core@5.2.9` confirmado em `npm ls -g`)
    - README.md:839 (árvore upstream: `Projects/.aiox-core/` — refere a cópia INSTALADA via npm upstream, NÃO o vendor do repo)
    - .gitignore:34 (`.aiox-core/`) + fato verificado: `git ls-files .aiox-core` = 0 → o vendor do repo é **IGNORADO/UNTRACKED**, não versionado
    - memória project-aiox-core-pristine-overlay (vendor do repo é PRISTINE; deltas vão por overlay em install-global-patches.sh na cópia INSTALADA achada por find_aiox_core)
    - scripts/install-global-patches.sh:54 (`find_aiox_core` busca `$(dirname "$SETUP_DIR")/.aiox-core` = `~/dev/.aiox-core` + `$HOME/Projects/.aiox-core` — a cópia instalada onde o overlay aplica)
  </read_first>
  <action>
    Editar APENAS o texto do README (nenhum arquivo no FS muda; nada de unificar). Em cada um dos 3
    pontos, adicionar um RÓTULO DE PAPEL curto que torne explícito por que há 3 cópias legítimas —
    SEM afirmar que o vendor é "tracked" (ele é IGNORADO pelo git):
    (a) Linha 224 — rotular a cópia `~/dev/.aiox-core/` como **"debug/instalado"** (cópia onde o
        overlay `install-global-patches.sh` aplica os 15 patches via `find_aiox_core`; mutável).
        Ex.: `| AIOX-core (instalado — alvo do overlay) | ~/dev/.aiox-core/ (cópia DEBUG/instalada — recebe os 15 patches; ≠ vendor PRISTINE do repo) |`
    (b) Linha 237 — rotular `npx aiox-core` como **"runtime npm-global"**. Ex.: acrescentar à célula "(runtime npm-global; binário CLI `aiox-core@5.x`)".
    (c) Linha 839 — na árvore upstream, anotar que `Projects/.aiox-core/` é a cópia **INSTALADA via npm upstream**, e que o `.aiox-core` do REPO é **vendor PRISTINE** — cópia local **IGNORADA pelo git** (`.gitignore`), nunca editada direto; deltas só via overlay na cópia instalada. (comentário/nota de rodapé curta após o bloco da árvore).
    Adicionar (se ainda não houver) UMA frase-âncora de desambiguação perto da tabela 235-237 ou 219-225,
    com o ESTADO GIT CORRETO:
    "Há 3 cópias LEGÍTIMAS do `.aiox-core`, por papéis distintos — não é duplicação: (1) **vendor
    PRISTINE** no repo (`~/dev/IdeiaOS/.aiox-core`) — cópia local **ignorada pelo git** (`.gitignore`),
    nunca editada direto; (2) **debug/instalado** (`~/dev/.aiox-core`, alvo do overlay
    `install-global-patches.sh`); (3) **runtime npm-global** (`npx aiox-core`, binário CLI).
    DESAMBIGUAÇÃO, não unificação."
    PROIBIDO escrever que o `.aiox-core` é "tracked"/"versionado" (FATO FALSO — Article IV).
    NÃO editar nenhum arquivo dentro de `.aiox-core/` (vendor PRISTINE).
  </action>
  <acceptance_criteria>
    - Rótulo PRISTINE presente no README (POSITIVA): `grep -qi "PRISTINE" README.md` exit 0.
    - Estado git CORRETO afirmado — "ignorado pelo git" ou ".gitignore" perto do vendor (POSITIVA): `grep -qi "ignorad" README.md && grep -q ".gitignore" README.md` exit 0.
    - FATO FALSO ausente (NEGATIVA anti-invenção — exercita o erro do draft anterior): nenhuma frase diz que o `.aiox-core` é "tracked"/"versionado": `! grep -niE "aiox-core.{0,80}(tracked|versionad)" README.md` exit 0.
    - Os 3 papéis nomeados (POSITIVA): `grep -qi "npm-global\|npm global" README.md && grep -qi "debug\|instalad" README.md && grep -qi "vendor" README.md` exit 0.
    - As 3 linhas-alvo preservam os paths reais (não houve troca de path): `grep -q "~/dev/.aiox-core/" README.md && grep -q "npx aiox-core" README.md` exit 0.
    - VENDOR INTOCADO (invariante crítica — CHECKSUM DE FS, NÃO tree-sha de HEAD): `[ "$(find .aiox-core -type f -exec shasum {} + 2>/dev/null | sort | shasum | awk '{print $1}')" = "$(cat /tmp/a04_aiox_fs_before.txt)" ]` exit 0.
  </acceptance_criteria>
  <done>README explica os 3 papéis do .aiox-core com o estado git VERDADEIRO (vendor PRISTINE = ignorado pelo git / debug-instalado / npm-global); zero afirmação "tracked"; vendor do FS byte-idêntico ao baseline; nenhuma unificação.</done>
</task>

<task type="auto">
  <name>Task 4: Corrigir o slug GitHub no README (Ideia-Business/ideIAos)</name>
  <files>README.md</files>
  <read_first>
    - README.md:119 (`Se o repo Ideia-Business/IdeiaOS ainda não estiver público… Decisão de tornar o repo público: pendente do usuário.` — casing errado + premissa obsoleta: repo É público desde 2026-06-25)
    - README.md:124 (`claude plugin marketplace add Ideia-Business/IdeiaOS` — casing errado)
    - `git remote -v` = `https://github.com/Ideia-Business/ideIAos.git` (slug canônico, casing exato)
    - README.md:13 e :184 (já corretos: `Ideia-Business/ideIAos`) — usar como referência de casing
  </read_first>
  <action>
    Substituir as 2 ocorrências de casing errado `Ideia-Business/IdeiaOS` por `Ideia-Business/ideIAos`
    (casing EXATO do remote). Nas linhas 119 e 124.
    Linha 119: além do casing, atualizar a premissa obsoleta — o repo é PÚBLICO (confirmado 2026-06-25).
    Reescrever para refletir que o slug GitHub agora funciona (Opção A é a padrão), mantendo a Opção B
    (path local) como alternativa para quem já tem o clone. Remover/ajustar "Decisão de tornar o repo
    público: pendente do usuário" (já decidido). NÃO alterar as ocorrências já corretas (13, 184).
  </action>
  <acceptance_criteria>
    - Casing errado ELIMINADO (NEGATIVA, regex case-sensitive — exercita o erro exato que existe hoje): `! grep -q "Ideia-Business/IdeiaOS" README.md` exit 0.
    - Slug correto presente (POSITIVA): `[ "$(grep -c "Ideia-Business/ideIAos" README.md)" -ge 4 ]` exit 0 (as 2 já existentes em 13/184 + as 2 corrigidas em 119/124).
    - Premissa "pendente do usuário" sobre publicação removida/atualizada (NEGATIVA): `! grep -q "Decisão de tornar o repo público: pendente" README.md` exit 0.
  </acceptance_criteria>
  <done>README usa `Ideia-Business/ideIAos` (casing do remote) em 100% das ocorrências; premissa de repo-privado obsoleta corrigida.</done>
</task>

<task type="auto">
  <name>Task 5 (gate final): Provar as 3 correções + intocabilidade do vendor por exit-code/checksum-FS; despausar autosync</name>
  <files>(verificação — nenhum arquivo de produto)</files>
  <read_first>
    - source/lib/gates.sh (helper antifrágil `assert_nonempty`/`gate_output` — bash 3.2, sem jq/python3)
    - /tmp/a04_aiox_fs_before.txt (checksum-FS baseline do vendor da Task 0)
    - scripts/autosync-pause.sh (wrapper sancionado — `off` restaura)
  </read_first>
  <action>
    Rodar a bateria de gates consolidados (build-script semantics: exit 1 em qualquer falha). Reusar
    `source/lib/gates.sh` quando aplicável (`assert_nonempty /tmp/a04_aiox_fs_before.txt`). Sequência:
    1. (a) `! grep -rq "com~apple~CloudDocs/Projects/IdeiaOS" scripts/ source/` (path morto extinto na fonte)
       e `! grep -q "Mobile Documents" scripts/install-alias.sh` (alias limpo).
    2. (b) `grep -qi "PRISTINE" README.md` E estado git correto (`grep -qi "ignorad" README.md && grep -q ".gitignore" README.md`)
       E zero "tracked"/"versionad" sobre o aiox-core (`! grep -niE "aiox-core.{0,80}(tracked|versionad)" README.md`)
       E vendor inalterado por CHECKSUM-FS:
       `[ "$(find .aiox-core -type f -exec shasum {} + 2>/dev/null | sort | shasum | awk '{print $1}')" = "$(cat /tmp/a04_aiox_fs_before.txt)" ]`.
    3. (c) `! grep -q "Ideia-Business/IdeiaOS" README.md` e `[ "$(grep -c "Ideia-Business/ideIAos" README.md)" -ge 4 ]`.
    4. NÃO-REGRESSÃO de iCloud legítimo (vault Obsidian intacto): `grep -q "iCloud~md~obsidian" source/skills/evolve/SKILL.md` exit 0 (não apagamos usos legítimos).
    5. Despausar o autosync pelo wrapper sancionado (restauração garantida — learning autosync-races-ai-git-surgery):
       `bash scripts/autosync-pause.sh off` e confirmar que o pause-file canônico sumiu.
    Imprimir um sumário PASS/FAIL por sub-gate. Qualquer FAIL → exit 1.
  </action>
  <acceptance_criteria>
    - Gate (a) alias/fonte: `! grep -rq "com~apple~CloudDocs/Projects/IdeiaOS" scripts/ source/` exit 0 E `! grep -q "Mobile Documents" scripts/install-alias.sh` exit 0.
    - Gate (b) aiox-core fato + intocabilidade (CHECKSUM-FS, não tree-sha): `grep -qi "PRISTINE" README.md && grep -qi "ignorad" README.md && grep -q ".gitignore" README.md && ! grep -niE "aiox-core.{0,80}(tracked|versionad)" README.md && [ "$(find .aiox-core -type f -exec shasum {} + 2>/dev/null | sort | shasum | awk '{print $1}')" = "$(cat /tmp/a04_aiox_fs_before.txt)" ]` exit 0.
    - Gate (c) slug: `! grep -q "Ideia-Business/IdeiaOS" README.md && [ "$(grep -c "Ideia-Business/ideIAos" README.md)" -ge 4 ]` exit 0.
    - Não-regressão iCloud legítimo: `grep -q "iCloud~md~obsidian" source/skills/evolve/SKILL.md` exit 0.
    - Autosync despausado (path REAL): `bash scripts/autosync-pause.sh off >/dev/null 2>&1; ! test -f "${HOME}/.local/state/git-autosync.pause"` exit 0.
  </acceptance_criteria>
  <done>As 3 correções provadas por exit-code; vendor PRISTINE byte-idêntico ao baseline (checksum-FS); zero "tracked" sobre o aiox-core; usos legítimos de iCloud intactos; autosync restaurado pelo mecanismo sancionado.</done>
</task>

</tasks>

## CONDIÇÕES / INVARIANTES que o executor DEVE respeitar

1. **Verificação = exit-code, nunca Read tool** (antifragile-gates). Cada task fecha num GATE
   `grep`/`test`/`checksum` que retorna 0/≠0, exercitando TAMBÉM input inválido (negativa). "Parece corrigido" não conta.
2. **Vendor `.aiox-core/` do repo é PRISTINE e IGNORADO PELO GIT** (`.gitignore:34`, `git ls-files`=0) —
   NUNCA editar arquivo dentro dele; a desambiguação é 100% no README (texto). Provar intocabilidade por
   **igualdade de checksum-FS** (`find .aiox-core -type f -exec shasum {} + | sort | shasum`, Task 0 baseline ↔ Task 3/5),
   **NUNCA** por `git rev-parse HEAD:.aiox-core` (sai exit 128/vazio → teatro-verde). DESAMBIGUAR, não unificar.
   PROIBIDO afirmar no README que o `.aiox-core` é "tracked"/"versionado" (Article IV — No Invention).
3. **Escopo cirúrgico** — tocar SÓ: `install-alias.sh:7`, `ideiaos-checker.md:29,199`,
   `ideiaos-setup/SKILL.md:38`, e as linhas 119/124/224/237/839 do README. Qualquer dívida adjacente
   (ex.: README:200 menciona `npx aiox-core@latest install`) vira marcador `debt:`, não conserto.
4. **Não tocar usos LEGÍTIMOS de iCloud** — vault Obsidian (`evolve`, `extract-learnings`,
   `recall-learnings`, `memory-sync`, `memory-sync-model.md`, `hybrid/CLAUDE.md.tmpl`) e transporte
   `.env.local` pelo envsync (`docs/ideiaos-console/*`). Só o path-morto do ALIAS é o alvo.
5. **bash 3.2 (macOS)** — sem `declare -A`; gates por grep/test/shasum simples. Reusar `source/lib/gates.sh`
   onde fizer sentido (`assert_nonempty`).
6. **Build-script semantics** no gate final (exit 1 em falha). Não há hook neste plano; se algum
   passo virar hook, ele sai 0 sempre (contrato de hook).
7. **Autosync**: pausar ANTES (Task 0) pelo wrapper SANCIONADO `scripts/autosync-pause.sh on`
   (pause-file canônico `${HOME}/.local/state/git-autosync.pause` — o que `git-autosync.sh:85` realmente lê),
   despausar com `off` e GARANTIR restauração ao fim (Task 5). NÃO usar `~/.ideiaos/autosync.pause` (path inerte).
   Verificar o guard no binário DEPLOYADO por grep, não confiar em "status PAUSADO".
8. **O plano NÃO faz `git push` nem `gh pr`** — exclusivo @devops. O executor edita e (se a sessão
   pedir) faz `git add`/`commit` local; push/PR/merge `work→main` são do fechamento de sessão/@devops.
9. **R15-15 depende deste mergeado** — não consolidar docs de instalação antes de A-04 entrar (HARD-GATE
   do próprio R15-15: consolidar antes propagaria o erro).

<verification>
- (a) alias: `! grep -q "Mobile Documents" scripts/install-alias.sh` + `! grep -rq "com~apple~CloudDocs/Projects/IdeiaOS" source/ scripts/` + `bash -n scripts/install-alias.sh`.
- (b) aiox-core: `grep -qi PRISTINE README.md` + estado git correto (`grep -qi ignorad README.md && grep -q .gitignore README.md`) + ZERO "tracked"/"versionad" (`! grep -niE "aiox-core.{0,80}(tracked|versionad)" README.md`) + checksum-FS do vendor == baseline (intocado, via `find … shasum`, NÃO tree-sha de HEAD).
- (c) slug: `! grep -q "Ideia-Business/IdeiaOS" README.md` + `grep -c "Ideia-Business/ideIAos" README.md` ≥ 4 + `! grep -q "Decisão de tornar o repo público: pendente" README.md`.
- não-regressão: usos legítimos de iCloud (vault em evolve/SKILL.md) ainda presentes; autosync despausado (path REAL `${HOME}/.local/state/git-autosync.pause` ausente).
</verification>

<success_criteria>
- O alias `idea-setup` aponta para `$HOME/dev/IdeiaOS` na FONTE e em todas as fontes que o herdam.
- As 3 cópias `.aiox-core` ficam desambiguadas por papel no README com o ESTADO GIT VERDADEIRO (vendor PRISTINE = ignorado pelo git, não tracked); vendor byte-idêntico por checksum-FS.
- Slug `Ideia-Business/ideIAos` (casing do remote) em 100% das ocorrências; premissa de repo-privado corrigida.
- Nenhum uso legítimo de iCloud removido; autosync restaurado pelo mecanismo sancionado; zero push/PR pelo plano.
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-04-corrigir-fatos-SUMMARY.md` when done.
</output>
