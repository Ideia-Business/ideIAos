---
phase: "v15-A"
plan: "A-03"
type: execute
wave: 1
depends_on: []
files_modified:
  - setup-dev-machine.sh
requirements: [R15-04]
must_haves:
  truths:
    - "Antes de cada `git clone`, o loop roda um probe `gh api repos/<slug> --silent` envolto em `timeout` e classifica o resultado em 3 estados por EXIT-CODE: acessível (exit 0), sem-acesso (exit≠0 + stderr contém 'HTTP 404'), inconclusivo (exit≠0 sem 'HTTP 404' — timeout/SSO/403/rede)"
    - "O slug `<owner>/<repo>` é derivado da própria URL do array REPOS (sed sobre `https://github.com/...git`), NÃO hardcoded — a única fonte de verdade dos repos continua sendo o array REPOS (linhas 30-36)"
    - "Estado 'sem-acesso' (404): pula o repo com aviso DIRECIONAL ('sem acesso no GitHub — se você não trabalha neste projeto, remova-o do array REPOS'), exit-code do setup permanece sucesso. Corrige o cfoai-grupori (1º do array, particular) para um dev sem acesso"
    - "Estado 'inconclusivo': aviso DIRECIONAL DISTINTO ('probe inconclusivo: rede/SSO/timeout — não confirma falta de acesso') e TENTA o clone mesmo assim (não pune um repo que o dev PODE ter acesso por causa de rede instável)"
    - "Clone de repo OBRIGATÓRIO (IdeiaOS) permanece FATAL: se o IdeiaOS especificamente não puder ser clonado, o setup morre (`die`) — o probe NÃO rebaixa o IdeiaOS a 'pula'. O passo 4 (linha 144) já depende do clone do IdeiaOS"
    - "Escopo MÍNIMO: nenhuma estrutura de tiers/flags por-repo, nenhum array paralelo, nenhum campo novo no formato 'nome|url|branch'. A obrigatoriedade do IdeiaOS é decidida por comparação de nome ('IdeiaOS'), não por um framework de classificação"
  artifacts:
    - path: "setup-dev-machine.sh"
      provides: "Loop de clone (passo 3) com probe gh api por exit-code antes do clone, 3 estados, IdeiaOS fatal"
      contains: "gh api repos/"
  key_links:
    - from: "setup-dev-machine.sh (loop passo 3, ~linha 104)"
      to: "gh api repos/<slug>"
      via: "probe por exit-code + classificação stderr 'HTTP 404', envolto em timeout"
      pattern: "gh api repos/"
---

<objective>
Tornar o passo 3 (clone) do `setup-dev-machine.sh` resiliente a repositório que o dev NÃO consegue
acessar. Hoje (linha 111) qualquer falha de clone vira `warn "clone falhou — pulando"; continue` —
indistintamente para um repo particular legítimo (cfoai-grupori, 1º do array, ao qual só o Gustavo tem
acesso) e para um repo obrigatório (IdeiaOS, do qual o passo 4 na linha 144 DEPENDE com `die`). O resultado
é ruído enganoso: um dev sem acesso ao cfoai vê "clone falhou — pulando" como se fosse erro, e um IdeiaOS
inacessível só estoura tarde, no passo 4.

R15-04 insere um **probe `gh api repos/<slug>` por EXIT-CODE ANTES do clone**, classificando em três estados
com avisos DIRECIONAIS distintos:
- **acessível** (exit 0) → segue para o clone normalmente;
- **sem-acesso** (exit≠0 + stderr `HTTP 404`) → pula com aviso direcional ("remova do array se não trabalha
  nele") — caso cfoai corrigido; setup termina com sucesso;
- **inconclusivo** (exit≠0 SEM `HTTP 404` — timeout/SSO/403/rede) → aviso direcional DISTINTO e TENTA o clone
  mesmo assim (não pune acesso real por instabilidade de rede).

Repo OBRIGATÓRIO (IdeiaOS) permanece FATAL: probe sem-acesso OU clone falho do IdeiaOS especificamente
chamam `die`. Escopo cirúrgico — NÃO criar framework de tiers; a obrigatoriedade é decidida por nome.

Output: `setup-dev-machine.sh` com o loop do passo 3 estendido (probe + 3 estados + IdeiaOS fatal).

**Fundamentação verificada (exit-codes reais, medidos nesta máquina):**
`gh api repos/Ideia-Business/ideIAos --silent` → exit **0** (acessível). `gh api repos/.../inexistente --silent`
→ exit **1**, stderr `gh: Not Found (HTTP 404)`. GitHub retorna **404** tanto para repo-inexistente quanto para
privado-sem-acesso (não vaza existência) — é exatamente esse 404 que distingue "sem acesso" de "inconclusivo".
`timeout` já está garantido em `~/.local/bin/timeout` pelo passo 2.5 (linhas 68-92), que roda ANTES do passo 3.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@setup-dev-machine.sh
@source/lib/gates.sh
@.claude/rules/ideiaos-common-antifragile-gates.md
</context>

<conditions_invariants>
O executor DEVE respeitar TODAS as invariantes abaixo (são parte do contrato — uma violação reprova o plano):

1. **Fonte única dos repos = array REPOS (linhas 30-36).** O slug do probe é DERIVADO da URL de cada `entry`
   por transformação de string; NUNCA hardcodar nomes de repo no probe. O array NÃO ganha campo novo (formato
   `nome|url|branch` intacto) nem array paralelo de classificação.

2. **Escopo MÍNIMO — sem framework de tiers.** A obrigatoriedade do IdeiaOS é uma comparação literal de nome
   (`[ "$name" = "IdeiaOS" ]`), não uma coluna/flag/tabela. Proibido introduzir conceito genérico de
   "required/optional/private" no formato de dados. Só o IdeiaOS é obrigatório neste plano.

3. **cfoai-grupori PERMANECE no array REPOS.** Este plano NÃO remove cfoai do array (Gustavo trabalha nele na
   máquina primária — memória `project-cfoai-particular`). O plano só faz o clone dele DEGRADAR
   graciosamente quando o dev não tem acesso. Tocar o array REPOS é fora de escopo.

4. **Verificação por EXIT-CODE, nunca interpretação de NL.** A classificação 404-vs-inconclusivo usa o
   exit-code do `gh` E o grep determinístico em stderr (`grep -qi "HTTP 404"`), nunca "parece um 404".

5. **Probe com timeout — não pode pendurar o setup.** O probe é envolto em `timeout` (shim do passo 2.5).
   Timeout estoura → exit≠0 sem `HTTP 404` → classificado como INCONCLUSIVO (tenta o clone), nunca como
   sem-acesso. Rede ruim jamais bloqueia um dev que TEM acesso.

6. **Build-script sai 1 em falha real (antifragile-gates).** `setup-dev-machine.sh` é build-script, não hook:
   o caminho fatal usa `die` (que faz `exit 1`). Os caminhos sem-acesso/inconclusivo de repos NÃO-obrigatórios
   NÃO derrubam o setup (continuam o loop). Só o IdeiaOS inacessível é fatal.

7. **Idempotência preservada.** O probe roda igualmente em repo já clonado e em repo novo; quando o `.git`
   já existe (linha 108), o probe é informativo mas não impede o `fetch`/`pull` local. O setup continua
   re-executável N vezes sem efeito colateral.

8. **Avisos DIRECIONAIS, não ambíguos (learning ambiguous-drift-warning-induces-agent-revert).** A mensagem de
   sem-acesso DIZ o que fazer ("remova do array REPOS se você não trabalha neste projeto"); a de inconclusivo
   DIZ que NÃO é falta de acesso ("rede/SSO/timeout — vou tentar clonar mesmo assim"). Nada de "X ≠ Y — corrija
   se intencional".

9. **Autosync pausado antes da cirurgia.** Antes de editar o `setup-dev-machine.sh`, pausar o git-autosync
   (autosync-race) e restaurar no fim. Como é cirurgia de 1 arquivo só, a janela é curta — mas a regra vale.

10. **NÃO empurrar.** Este plano NUNCA roda `git push`/`gh pr` (exclusivo @devops). Termina com o arquivo
    editado, gates verdes e o autosync restaurado.
</conditions_invariants>

<tasks>

<task type="auto">
  <name>Task 1: Pausar autosync + inserir helper de probe e classificação por exit-code antes do loop</name>
  <files>setup-dev-machine.sh</files>
  <read_first>
    - setup-dev-machine.sh linhas 17-41 (set -uo pipefail; vars; helpers say/ok/warn/die — reusar say/ok/warn/die, NÃO criar novos)
    - setup-dev-machine.sh linhas 30-36 (array REPOS: formato `nome|url|branch`; cfoai-grupori 1º; IdeiaOS 2º com URL https://github.com/Ideia-Business/ideIAos.git)
    - setup-dev-machine.sh linhas 63-100 (passo 2.5: o shim `timeout` é instalado em $BIN_DIR/timeout e ~/.local/bin entra no PATH ANTES do passo 3 — o probe pode confiar em `timeout`)
    - setup-dev-machine.sh linhas 102-127 (passo 3: o loop a estender)
    - source/lib/gates.sh (gate_output por exit-code; este plano valida a SINTAXE do script por `bash -n`, não produz artefato-de-arquivo de pipeline — gates.sh é referência de disciplina)
  </read_first>
  <action>
    (a) PAUSAR AUTOSYNC (invariante 9): antes de qualquer edição, parar o LaunchAgent do autosync para esta
        cirurgia de 1 arquivo:
          launchctl bootout "gui/$(id -u)/com.ideiaos.gitautosync" 2>/dev/null || true
        Registrar (ex.: variável de sessão / nota) que ele DEVE ser religado na Task 3. NÃO usar `git checkout`
        cego para nada (learning claude-settings-deny-live-reload-autosync-capture).

    (b) Inserir, ENTRE o passo 2.5 (termina ~linha 100) e o passo 3 (`# ── 3) Clonar...`, linha 102), um helper
        de proveniência-implícita (o arquivo já tem shebang/header no topo; não duplicar header de SOURCE — é
        edição de arquivo EXISTENTE, não artefato novo). O helper `probe_repo_access`:
          - recebe a URL do entry;
          - deriva o slug: `slug=$(printf '%s' "$url" | sed -E 's#^https?://github\.com/##; s#\.git$##')`
            (ex.: https://github.com/Ideia-Business/ideIAos.git → Ideia-Business/ideIAos);
          - roda o probe por exit-code, com timeout curto (o shim do passo 2.5 garante `timeout`):
              local err rc
              err=$(timeout 20 gh api "repos/$slug" --silent 2>&1 >/dev/null); rc=$?
          - CLASSIFICA e ecoa um token determinístico em stdout (consumido por `case` no loop):
              if [ "$rc" -eq 0 ]; then printf 'OK';
              elif printf '%s' "$err" | grep -qi 'HTTP 404'; then printf 'NOACCESS';
              else printf 'INCONCLUSIVE'; fi
          - retornar 0 sempre (a decisão é do chamador, via o token — não via exit do helper).
        O token (OK | NOACCESS | INCONCLUSIVE) é a interface por-exit-code: comparação literal, sem parsing NL.

    (c) NÃO alterar o array REPOS (invariante 3). NÃO adicionar campo. NÃO adicionar lista de "required".
  </action>
  <acceptance_criteria>
    - Autosync efetivamente parado nesta sessão (informativo): `launchctl list 2>/dev/null | grep -q gitautosync && echo STILL_LOADED || echo STOPPED` — esperado STOPPED (ou nunca-carregado). NÃO é gate fatal (a máquina pode não ter o agente), mas a Task 1 DEVE ter executado o bootout.
    - Sintaxe do script válida após a inserção: `bash -n setup-dev-machine.sh` exit 0.
    - Helper presente e por-exit-code: `grep -q 'gh api "repos/\$slug"' setup-dev-machine.sh || grep -q 'gh api .repos/' setup-dev-machine.sh` exit 0.
    - Classificação 404 determinística (não-NL): `grep -q "grep -qi 'HTTP 404'" setup-dev-machine.sh || grep -qi 'HTTP 404' setup-dev-machine.sh` exit 0.
    - Probe envolto em timeout (invariante 5): `grep -Eq 'timeout[[:space:]]+[0-9]+[[:space:]]+gh api' setup-dev-machine.sh` exit 0.
    - Slug DERIVADO da URL, não hardcoded (invariante 1): `grep -Eq "sed -E 's#\\^https" setup-dev-machine.sh || grep -q 'github\\.com/' setup-dev-machine.sh` exit 0; E nenhum slug literal novo de repo no helper: `! grep -Eq 'repos/Ideia-Business/(cfoai|ideIAos|lapidai|nfideia|ideiapartner)' setup-dev-machine.sh` exit 0 (o probe NÃO cita repo literal — vem do array).
    - Array REPOS intacto (invariante 3): `grep -c '^  "' setup-dev-machine.sh` retorna 5 (as 5 linhas de repo entre 31-35); `grep -q 'cfoai-grupori|https' setup-dev-machine.sh` exit 0.
  </acceptance_criteria>
  <done>Autosync pausado; helper `probe_repo_access` inserido antes do passo 3, derivando slug da URL e classificando OK/NOACCESS/INCONCLUSIVE por exit-code + grep determinístico 'HTTP 404', envolto em timeout; array REPOS intacto; `bash -n` verde.</done>
</task>

<task type="auto">
  <name>Task 2: Plugar o probe no loop de clone com 3 estados e IdeiaOS fatal</name>
  <files>setup-dev-machine.sh</files>
  <read_first>
    - setup-dev-machine.sh linhas 104-127 (o loop: `for entry in REPOS; IFS='|' read -r name url branch; dst=$DEV/$name; say "Projeto: $name"; if [ -d "$dst/.git" ] ... else git clone ... || { warn "clone falhou — pulando"; continue; }`)
    - setup-dev-machine.sh linha 111 (o `git clone ... || { warn "clone falhou — pulando"; continue; }` — o ponto exato que ganha o probe antes e o tratamento fatal-vs-skip)
    - setup-dev-machine.sh linha 144 (o `die "fonte do git-autosync ausente ... o clone do IdeiaOS (Passo 3) falhou?"` — confirma que IdeiaOS é PRÉ-REQUISITO dos passos seguintes; por isso seu clone-falho deve ser fatal já no passo 3)
    - helper `probe_repo_access` inserido na Task 1
  </read_first>
  <action>
    No corpo do loop (linhas 104-127), DENTRO do ramo `else` (repo ainda NÃO clonado — linha 110-112) e ANTES do
    `git clone`, inserir o probe e o tratamento por estado. O probe roda só quando vai clonar (repo já clonado
    com `.git` segue pelo ramo `fetch` da linha 109 — invariante 7). Estrutura:

      else
        access=$(probe_repo_access "$url")
        case "$access" in
          NOACCESS)
            if [ "$name" = "IdeiaOS" ]; then
              die "IdeiaOS é obrigatório e não está acessível (HTTP 404) na sua conta gh — verifique 'gh auth status' e acesso ao repo Ideia-Business/ideIAos."
            fi
            warn "$name: sem acesso no GitHub (HTTP 404). Se você NÃO trabalha neste projeto, remova a linha de \"$name\" do array REPOS (linhas ~30-36). Pulando."
            continue
            ;;
          INCONCLUSIVE)
            warn "$name: probe de acesso inconclusivo (rede/SSO/timeout — NÃO confirma falta de acesso). Vou tentar clonar mesmo assim."
            ;;
          OK)
            : # acessível — segue o fluxo normal
            ;;
        esac
        if git clone --quiet "$url" "$dst"; then
          ok "clonado"
        else
          if [ "$name" = "IdeiaOS" ]; then
            die "IdeiaOS é obrigatório e o clone falhou — sem ele os passos 4-7 não rodam. Verifique rede/credenciais e rode de novo."
          fi
          warn "clone falhou — pulando"
          continue
        fi
      fi

    Pontos cirúrgicos (invariantes 1, 2, 6):
    - A obrigatoriedade é a comparação literal `[ "$name" = "IdeiaOS" ]` — SEM tier/flag (invariante 2).
    - O ramo OK não muda o comportamento atual (acessível clona como sempre).
    - O ramo NOACCESS para repo não-obrigatório substitui o "clone falhou — pulando" ENGANOSO por um aviso
      DIRECIONAL e pula ANTES de o clone falhar (não desperdiça o clone de um repo que sabidamente dá 404).
    - INCONCLUSIVE preserva o comportamento legado de TENTAR o clone (defesa contra falso-negativo de rede).
    - O clone-falho do IdeiaOS vira FATAL aqui (antes só estourava no passo 4, linha 144).
    - Manter o `git clone --quiet` e o restante do loop (checkout/pull/npm/.env, linhas 113-126) INTOCADOS.
  </action>
  <acceptance_criteria>
    - Sintaxe válida: `bash -n setup-dev-machine.sh` exit 0.
    - Os 3 estados existem no loop: `grep -q 'NOACCESS)' setup-dev-machine.sh && grep -q 'INCONCLUSIVE)' setup-dev-machine.sh && grep -q 'OK)' setup-dev-machine.sh` exit 0.
    - Probe chamado no loop antes do clone: `grep -q 'access=$(probe_repo_access' setup-dev-machine.sh` exit 0; e o probe aparece ANTES do `git clone` no arquivo (ordem de linhas): `awk '/access=\$\(probe_repo_access/{p=NR} /git clone --quiet "\$url"/{c=NR} END{exit !(p>0 && c>0 && p<c)}' setup-dev-machine.sh` exit 0.
    - IdeiaOS FATAL nos dois caminhos (invariante: obrigatório morre): no ramo NOACCESS e no clone-falho há `die` gated por nome — `grep -Eq 'name. = .IdeiaOS.*' setup-dev-machine.sh && grep -c 'die "IdeiaOS' setup-dev-machine.sh` retorna ≥1; verificação direta: `grep -c 'IdeiaOS é obrigatório' setup-dev-machine.sh` retorna 2 (probe-404 + clone-falho).
    - Sem framework de tiers (invariante 2): o array continua `nome|url|branch` (3 campos) — `! grep -Eq '^\s*"[^"]*\|[^"]*\|[^"]*\|' setup-dev-machine.sh` exit 0 (nenhum entry com 4+ campos); E nenhuma flag por-repo nova: `! grep -Eqi 'required=|optional=|tier=|private=' setup-dev-machine.sh` exit 0.
    - Aviso direcional de sem-acesso presente (invariante 8): `grep -q 'remova a linha' setup-dev-machine.sh && grep -q 'array REPOS' setup-dev-machine.sh` exit 0.
    - Aviso direcional de inconclusivo DISTINTO (invariante 8): `grep -q 'inconclusivo' setup-dev-machine.sh && grep -q 'tentar clonar mesmo assim' setup-dev-machine.sh` exit 0.
    - Comportamento legado preservado para não-obrigatório inconclusivo: o `git clone --quiet "$url" "$dst"` ainda existe e o `warn "clone falhou — pulando"` ainda existe para o fallback não-IdeiaOS — `grep -q 'git clone --quiet "$url" "$dst"' setup-dev-machine.sh && grep -q 'clone falhou — pulando' setup-dev-machine.sh` exit 0.
  </acceptance_criteria>
  <done>Loop do passo 3 roda o probe antes do clone; NOACCESS de repo comum pula com aviso direcional, INCONCLUSIVE tenta o clone, OK clona normal; IdeiaOS é fatal tanto no probe-404 quanto no clone-falho; array REPOS de 3 campos intacto.</done>
</task>

<task type="auto">
  <name>Task 3: Verificação de comportamento dry (probe isolado) + restaurar autosync</name>
  <files>setup-dev-machine.sh</files>
  <read_first>
    - setup-dev-machine.sh inteiro após as Tasks 1-2 (revisão da integração)
    - setup-dev-machine.sh linhas 17 (`set -uo pipefail` — confirmar que nenhuma var nova fica unbound)
  </read_first>
  <action>
    (a) PROVAR a classificação por exit-code contra o GitHub REAL (não fixture — learning
        prove-crypto-against-real-backend / missing-tool-not-cant-verify), extraindo o helper para um sandbox
        em $TMPDIR e exercitando os 3 estados:
          - acessível: `gh api repos/Ideia-Business/ideIAos --silent` → token esperado OK;
          - sem-acesso/404: `gh api repos/Ideia-Business/repo-inexistente-xyz123 --silent` → token NOACCESS;
          - inconclusivo: simular timeout/rede forçando um host morto OU `timeout 1 gh api ...` contra slug que
            demore → token INCONCLUSIVE (e CONFIRMAR que NÃO é classificado como NOACCESS).
        Isto exercita o caso NEGATIVO em cada ramo (learning antitheater-gate-blind-spot-happy-path): o gate não
        pode só testar o caminho feliz.
    (b) PROVAR que o gating por nome é correto: um `bash -n` não basta — fazer um teste de mesa lógico de que
        `[ "$name" = "IdeiaOS" ]` só dispara `die` para o IdeiaOS e NUNCA para cfoai-grupori (que, com 404, deve
        PULAR, não morrer). Verificar por grep que o `die` está DENTRO do ramo gated, não solto.
    (c) RESTAURAR o autosync (invariante 9) — re-bootstrap do LaunchAgent que a Task 1 parou:
          launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.ideiaos.gitautosync.plist" 2>/dev/null || true
          launchctl enable "gui/$(id -u)/com.ideiaos.gitautosync" 2>/dev/null || true
        Garantir a restauração mesmo que as provas acima falhem (executar SEMPRE no fim).
    (c) NÃO empurrar (invariante 10). O plano termina com o arquivo editado e o autosync religado.
  </action>
  <acceptance_criteria>
    - Sintaxe final válida: `bash -n setup-dev-machine.sh` exit 0.
    - Prova REAL estado OK: `gh api repos/Ideia-Business/ideIAos --silent >/dev/null 2>&1; test $? -eq 0` exit 0 (acessível → exit 0, base do token OK).
    - Prova REAL estado NOACCESS (404 distinto): `err=$(gh api repos/Ideia-Business/repo-inexistente-xyz123 --silent 2>&1 >/dev/null); test $? -ne 0 && printf '%s' "$err" | grep -qi 'HTTP 404'` exit 0 (exit≠0 E stderr tem HTTP 404 → NOACCESS).
    - Prova REAL estado INCONCLUSIVE ≠ NOACCESS: `err=$(timeout 1 gh api repos/Ideia-Business/ideIAos --silent --hostname nonexistent.invalid 2>&1 >/dev/null); test $? -ne 0 && ! printf '%s' "$err" | grep -qi 'HTTP 404'` exit 0 (falha SEM HTTP 404 → INCONCLUSIVE, jamais NOACCESS).
    - Gating de IdeiaOS confinado (não solto): cada `die "IdeiaOS é obrigatório` é precedido (mesma estrutura) por um teste de nome — `grep -B2 'die "IdeiaOS é obrigatório' setup-dev-machine.sh | grep -q 'name. = .IdeiaOS'` exit 0.
    - cfoai NÃO é tratado como fatal: nenhuma referência literal a cfoai num caminho `die` — `! grep -A3 'cfoai' setup-dev-machine.sh | grep -q 'die '` exit 0 (cfoai segue pelo array genérico, 404→pula, nunca die).
    - Nenhuma var unbound sob `set -u`: `bash -n setup-dev-machine.sh` exit 0 E o helper declara `local` em todas as vars novas — `grep -Eq 'local err rc|local slug' setup-dev-machine.sh` exit 0.
    - Autosync RESTAURADO: a Task 3 executou o `launchctl bootstrap` de religação — `launchctl list 2>/dev/null | grep -q gitautosync && echo RELOADED || echo ABSENT` (esperado RELOADED se a máquina tinha o agente; ABSENT é tolerável só se a máquina nunca teve — informativo, não fatal).
  </acceptance_criteria>
  <done>Os 3 estados provados contra o GitHub real (OK/NOACCESS/INCONCLUSIVE, com NEGATIVO exercitado); IdeiaOS-fatal confinado ao ramo gated por nome; cfoai jamais cai em die; autosync religado; nada empurrado.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| array REPOS (config) → loop de clone | a URL é a única fonte do slug; nenhum nome de repo hardcoded no probe |
| `gh` (rede/GitHub) → classificação | exit-code + stderr 'HTTP 404' são os ÚNICOS sinais; nunca interpretação NL |
| timeout shim → probe | rede instável vira INCONCLUSIVE (tenta clone), nunca NOACCESS (pula) — falso-negativo de rede não pune acesso real |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-A03-D | Denial of Service | probe pendura o setup | mitigate | probe envolto em `timeout 20`; estouro → INCONCLUSIVE → tenta clone; gate exige `timeout N gh api` |
| T-A03-FN | False Negative | rede ruim classificada como sem-acesso | mitigate | só exit≠0 COM 'HTTP 404' vira NOACCESS; tudo mais é INCONCLUSIVE (tenta clone); prova REAL do estado INCONCLUSIVE ≠ NOACCESS |
| T-A03-FATAL | Availability | IdeiaOS inacessível passa silencioso | mitigate | `die` gated por nome no probe-404 E no clone-falho; gate conta 2 ocorrências de 'IdeiaOS é obrigatório' |
| T-A03-SCOPE | Scope creep | framework de tiers introduzido | mitigate | gate proíbe entry com 4+ campos e flags required=/tier=/private=; obrigatoriedade = comparação de nome |
| T-A03-RACE | Tampering | autosync atropela a edição | mitigate | autosync pausado na Task 1, religado SEMPRE no fim da Task 3 (autosync-race) |
</threat_model>

<verification>
- `bash -n setup-dev-machine.sh` exit 0 após cada task.
- 3 estados (OK/NOACCESS/INCONCLUSIVE) provados contra o GitHub REAL, com o caso NEGATIVO de cada ramo exercitado.
- `die "IdeiaOS é obrigatório"` aparece 2× (probe-404 + clone-falho), sempre gated por `[ "$name" = "IdeiaOS" ]`.
- cfoai jamais cai em `die`; array REPOS de 3 campos intacto (sem tiers/flags).
- Probe envolto em `timeout`; slug derivado da URL (sem repo literal no helper).
- Autosync pausado antes da cirurgia e religado no fim. NADA empurrado (push é @devops).
</verification>

<success_criteria>
- O passo 3 do `setup-dev-machine.sh` roda `gh api repos/<slug>` por exit-code ANTES do clone e classifica em
  acessível / sem-acesso(404) / inconclusivo com avisos DIRECIONAIS distintos.
- cfoai-grupori (1º do array, particular) DEGRADA graciosamente para um dev sem acesso (404 → pula com aviso de
  "remova do array"), sem derrubar o setup — caso corrigido.
- IdeiaOS (obrigatório) permanece FATAL: 404 no probe OU clone-falho chamam `die`.
- Escopo mínimo: nenhum framework de tiers; array REPOS intacto; só o arquivo `setup-dev-machine.sh` tocado.
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-03-setup-resiliente-SUMMARY.md` when done
</output>
