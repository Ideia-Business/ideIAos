---
phase: "v15-A"
plan: "A-07"
type: execute
wave: 2
depends_on: ["A-01", "A-02"]
requirements: [R15-02]
slug: registro-hooks-bootstrap
dir: .planning/milestones/v15-phases/A-destravar/
must_haves:
  truths:
    - "setup-dev-machine.sh (raiz) passa a REGISTRAR os hooks em ~/.claude/settings.json APÓS o passo 7 (linha 199: `bash \"$DEV/IdeiaOS/setup.sh\" --global-only` deploya os ARQUIVOS) e ANTES do passo 8 (linhas 209-240, que já edita settings.json em permissions.additionalDirectories p/ o vault) — provando que o bootstrap-mantenedor já é o ator que toca settings.json"
    - "O registro REUSA o registrador idempotente existente: o mesmo bloco python3 do step 3 de scripts/ideiaos-update.sh (linhas 172-225, heredoc PYEOF), que itera plugins/ideiaos-core/hooks/hooks.json, deriva o name via command.rstrip('\"').split('/')[-1], pula hook já-registrado ('name in registered'), pula arquivo-ausente em ~/.claude/hooks/ (os.path.exists falso), e faz backup .bak-hooks. SEM extrair script novo, SEM duplicar a lógica do step 3"
    - "T-01-10 PRESERVADO: setup.sh continua SÓ imprimindo snippet (linhas 1384/1428 'setup.sh nunca auto-edita' intocadas; ~15 menções a ~/.claude/settings.json são checagens grep + warns 'adicione manualmente', nunca escrita) — o Quickstart-CONSUMIDOR não ganha registro silencioso. Só o bootstrap-MANTENEDOR (setup-dev-machine.sh) registra — porque rodar o setup-dev-machine.sh É o consentimento explícito do mantenedor. Provado por diff-real: `git diff --quiet -- setup.sh` permanece exit 0"
    - "Idempotente: rodar setup-dev-machine.sh N vezes não duplica entradas em settings.json (o registrador pula 'name in registered'). Verificado em sandbox por exit-code: 1ª passada registra 11 hooks, 2ª passada mantém 11 (contagem estável); um hook SEM arquivo correspondente é PULADO (contagem < 11) — exercitando o caminho INVÁLIDO, não só o feliz"
  artifacts:
    - path: "setup-dev-machine.sh"
      provides: "Passo 7.5 de registro de hooks no settings.json no bootstrap do mantenedor, reusando ideiaos-update.sh --hooks-only (step 3)"
      contains: "ideiaos-update.sh --hooks-only"
    - path: "scripts/ideiaos-update.sh"
      provides: "Flag --hooks-only que isola o step 3 (registro de hooks) sem duplicar a lógica"
      contains: "--hooks-only"
  key_links:
    - from: "setup-dev-machine.sh (novo passo 7.5, após o passo 7 / linha 207)"
      to: "scripts/ideiaos-update.sh --hooks-only (registrador idempotente, step 3)"
      via: "invocação do registrador existente (sem reimplementar) — caminho canônico de registro"
      pattern: "ideiaos-update.sh --hooks-only"
    - from: "scripts/ideiaos-update.sh step 3 (linhas 172-225)"
      to: "plugins/ideiaos-core/hooks/hooks.json"
      via: "fonte canônica de evento/matcher/timeout/async dos 11 hooks (6 eventos)"
      pattern: "hooks.json"
---

# A-07 — Registro de hooks DENTRO do bootstrap (R15-02)

## META — goal-backward

**Estado final desejado (o "depois"):** numa máquina-de-MANTENEDOR recém-configurada por
`setup-dev-machine.sh`, os hooks IdeiaOS não ficam só COPIADOS em `~/.claude/hooks/` — ficam
**REGISTRADOS** em `~/.claude/settings.json` e portanto VIVOS. O failure-mode #1
("hooks copiados-mas-mortos") está fechado para o bootstrap-mantenedor, **sem** tocar no caminho
do Quickstart-CONSUMIDOR (T-01-10: consentimento visível mantido) e **sem** extrair script novo.

**Caminho de volta (por que cada task existe):**

1. Hoje `setup-dev-machine.sh` passo 7 (`setup.sh --global-only`, invocação real na **linha 199**,
   bloco 192-207) **deploya os ARQUIVOS** dos hooks mas — por T-01-10 — **nunca registra** em
   settings.json; o snippet fica só impresso. Resultado: hook morto até alguém colar à mão ou rodar
   `ideiaos-update.sh`.
2. O registrador idempotente **já existe e está testado**: `scripts/ideiaos-update.sh` **step 3**
   (linhas 172-225, heredoc `PYEOF`) lê `plugins/ideiaos-core/hooks/hooks.json` (11 hooks em 6
   eventos: PostToolUse, PreToolUse, UserPromptSubmit, SessionStart, PreCompact, Stop), deriva o
   `name` por `command.rstrip('"').split("/")[-1]`, registra o que falta, pula o que já está
   (`name in registered`), pula arquivo ausente (`os.path.exists(local)` falso), faz backup
   `.bak-hooks`. Não há por que reimplementar.
3. O `setup-dev-machine.sh` **já edita** `~/.claude/settings.json` no passo 8 (vault, linhas
   209-240) — escrevendo em `permissions.additionalDirectories` (NÃO em `hooks`), ancorado em
   `settings_path = os.path.expanduser("~/.claude/settings.json")` na **linha 217**. Logo,
   registrar hooks ali **não é uma nova licença** — é a MESMA superfície que o bootstrap-mantenedor
   já assume. A precisão cirúrgica é: **invocar o registrador existente**, não copiar sua lógica.
4. Como A-07 modifica um script de bootstrap que pode estar sob autosync, e mexe num único
   arquivo de produto (`setup-dev-machine.sh`) + um script (`scripts/ideiaos-update.sh`) + um
   `.planning/`, **pausamos o autosync** antes (autosync-race) e verificamos por **exit-code**
   (nunca o Read tool) que o passo novo realmente invoca o registrador.

**Dependências (por que Wave 2):**
- **A-01** (hooks corrigidos) — registrar hooks que ainda apontam `/usr/bin/python3` quebrado
  propagaria o defeito; A-01 conserta a fonte antes.
- **A-02** (smoke `idea-smoke.sh` confirma o registro por exit-code) — o smoke é a prova binária
  externa de que "o registro funcionou"; A-07 produz o registro, A-02 o ratifica. Por isso A-07
  é Wave 2 (depende dos dois) e a cadeia do ROADMAP é R15-01 → R15-03 → R15-02.

---

<context>
@.planning/milestones/v15-REQUIREMENTS.md
@.planning/milestones/v15-ROADMAP.md
@setup-dev-machine.sh
@scripts/ideiaos-update.sh
@plugins/ideiaos-core/hooks/hooks.json
@source/lib/gates.sh
</context>

<tasks>

<task type="auto">
  <name>Task 1: Pausar o autosync + capturar a linha de invocação canônica do registrador</name>
  <files>(somente leitura/preparação — nenhum artefato de produto editado nesta task)</files>
  <read_first>
    - scripts/autosync-pause.sh (mecanismo de pause-file: ~/.local/state/git-autosync.pause — o autosync pula o repo inteiro; restauração garantida no teardown)
    - scripts/ideiaos-update.sh:172-225 (step 3 "registro de hooks no settings.json" — o registrador a REUSAR; capturar exatamente como é invocado: SETTINGS=$HOME/.claude/settings.json, PLUGIN_HOOKS=$SETUP_DIR/plugins/ideiaos-core/hooks/hooks.json, e o heredoc python3 PYEOF que deriva name por command.rstrip('"').split("/")[-1], pula 'name in registered', pula os.path.exists falso, faz backup .bak-hooks)
    - scripts/ideiaos-update.sh:39-45 (parse de args atual: NO_SHELL=0; NO_STATUSLINE=0 + loop `for arg in "$@"` com case --no-shell/--no-statusline — NÃO há --hooks-only ainda)
    - setup-dev-machine.sh:192-207 (passo 7 — invocação real `bash "$DEV/IdeiaOS/setup.sh" --global-only` na linha 199; os ARQUIVOS dos hooks são deployados aqui; o registro novo entra DEPOIS)
    - setup-dev-machine.sh:209-240 (passo 8 — precedente de edição de settings.json via python3 VAULT_EOF; escreve em permissions.additionalDirectories, ancorado em `settings_path = os.path.expanduser` na linha 217; confirma que o mantenedor já toca settings.json)
  </read_first>
  <action>
    Pausar o autosync ANTES da cirurgia (esta fase edita setup-dev-machine.sh, que vive sob autosync):
      bash scripts/autosync-pause.sh on   # ou: touch ~/.local/state/git-autosync.pause
    Verificar que o guard de pause está presente no binário DEPLOYADO (não confiar em "status PAUSADO"):
      grep -qF "git-autosync.pause" "$HOME/.local/bin/git-autosync"
    (se ausente, o pause-file não tem efeito — re-rodar setup-dev-machine.sh para regravar o daemon
    canônico ANTES de prosseguir, conforme learning autosync-pause-file-guard-not-deployed.)

    Decidir a ESTRATÉGIA DE REUSO (sem extrair script novo, sem duplicar a lógica):
    o `setup-dev-machine.sh` invocará o registrador existente chamando o `ideiaos-update.sh`
    de forma a executar EXATAMENTE o step 3 (registro de hooks) sem disparar o sync-all completo.
    Como o `ideiaos-update.sh` atual NÃO tem flag que isole o step 3, a abordagem cirúrgica de
    MENOR superfície é: adicionar ao `ideiaos-update.sh` uma flag `--hooks-only` que executa
    SOMENTE o bloco do step 3 (pulando os demais steps quando a flag está presente),
    e o `setup-dev-machine.sh` chama `bash "$DEV/IdeiaOS/scripts/ideiaos-update.sh" --hooks-only`.
    Isso mantém UMA fonte da lógica de registro (o step 3) e satisfaz "reusar o registrador
    idempotente já existente / sem extrair script novo".
    (Registrar esta decisão como ASSUMPTION explícita no SUMMARY — ver invariantes.)
  </action>
  <gate>
    # GATE Task1 — pré-condições verdadeiras por exit-code (nunca Read tool).
    # Inclui caso INVÁLIDO: se o guard de pause estiver AUSENTE do binário deployado, falha (exit≠0)
    # — não basta "status PAUSADO" (learning autosync-pause-file-guard-not-deployed).
    test -f scripts/autosync-pause.sh \
      && grep -qF "git-autosync.pause" "$HOME/.local/bin/git-autosync" \
      && grep -qF "registro de hooks no settings.json" scripts/ideiaos-update.sh \
      && grep -qF "plugins/ideiaos-core/hooks/hooks.json" scripts/ideiaos-update.sh \
      && grep -qF ".bak-hooks" scripts/ideiaos-update.sh \
      && test -f plugins/ideiaos-core/hooks/hooks.json \
      && test "$(/usr/bin/python3 -c "import json;h=json.load(open('plugins/ideiaos-core/hooks/hooks.json'))['hooks'];print(sum(len(e.get('hooks',[])) for ev in h.values() for e in ev))")" -eq 11
    echo "GATE Task1 exit=$?"   # exit 0 ⇒ autosync pausável+guard-deployado, registrador localizado, fonte canônica com 11 hooks
  </gate>
</task>

<task type="auto">
  <name>Task 2: Adicionar a flag --hooks-only ao ideiaos-update.sh (isola o step 3 sem duplicar)</name>
  <files>scripts/ideiaos-update.sh</files>
  <read_first>
    - scripts/ideiaos-update.sh:39-45 (parse de args existente: `NO_SHELL=0; NO_STATUSLINE=0` + loop `for arg in "$@"` com case --no-shell/--no-statusline — ESTENDER este mesmo loop, não criar parser novo)
    - scripts/ideiaos-update.sh:47-52 (step 1 "1/6: sync-all.sh" — o ponto onde --hooks-only deve PULAR tudo até o step 3)
    - scripts/ideiaos-update.sh:54-170 (steps 2/2c — também devem ser pulados sob --hooks-only)
    - scripts/ideiaos-update.sh:172-225 (step 3 a isolar — deve permanecer LITERALMENTE o mesmo código; --hooks-only apenas PULA os demais steps)
    - scripts/ideiaos-update.sh:227+ (steps 4/5 já desligáveis por NO_SHELL/NO_STATUSLINE)
  </read_first>
  <action>
    Editar SOMENTE scripts/ideiaos-update.sh (escopo cirúrgico):
    (a) Inicializar `HOOKS_ONLY=0` junto de NO_SHELL/NO_STATUSLINE (linha ~39) e, no loop de args
        (linha ~40-45), adicionar o case:
          --hooks-only)    HOOKS_ONLY=1 ;;
    (b) Implementar o isolamento por GUARDAS (bash 3.2, sem `declare -A`, sem refatorar a ordem):
        — inserir logo após o parse de args um bloco que liga os desligamentos existentes:
            if [ "$HOOKS_ONLY" -eq 1 ]; then NO_SHELL=1; NO_STATUSLINE=1; fi
          (assim os steps 4 e 5 já não rodam);
        — envolver os steps 1, 2 e 2c (linhas ~47-170) com `if [ "$HOOKS_ONLY" -eq 0 ]; then ... fi`
          (ou um `[ "$HOOKS_ONLY" -eq 1 ] && skip "..."` no topo de cada, conforme o que der MENOR diff)
          de modo que SOMENTE o step 3 execute quando --hooks-only.
        Escolher a forma de MENOR diff que deixe o step 3 EXECUTANDO inalterado.
        debt: avaliar refatorar ideiaos-update.sh num dispatcher de steps data-driven (R15-21, fora do escopo de R15-02; marcar, não consertar).
    (c) NÃO alterar UMA LINHA do step 3 (172-225) — só decidir SE ele roda.
    (d) Atualizar o cabeçalho-comentário (linhas 22-26 "Uso:") documentando `--hooks-only` (registra só os hooks).
  </action>
  <gate>
    # GATE Task2 — exercita também o caso INVÁLIDO (script que não parseia / step 3 mutilado):
    # 1) sintaxe bash válida do script editado (input inválido = script quebrado → bash -n falha):
    bash -n scripts/ideiaos-update.sh \
      && grep -qF -- "--hooks-only" scripts/ideiaos-update.sh \
      && grep -qF "HOOKS_ONLY" scripts/ideiaos-update.sh \
      && grep -qF "registro de hooks no settings.json" scripts/ideiaos-update.sh \
      && grep -qF ".bak-hooks" scripts/ideiaos-update.sh \
      && grep -qF '["command"].rstrip' scripts/ideiaos-update.sh
    echo "GATE Task2-positivo exit=$?"   # exit 0 ⇒ flag+guarda adicionadas, registrador (step 3 + heredoc + backup) preservado, sintaxe OK
    # 2) caso INVÁLIDO explícito: --hooks-only NÃO pode ter destravado um step que deveria pular.
    #    Provar que o gate `[ "$HOOKS_ONLY" -eq 0 ]` (ou equivalente) está presente guardando o sync-all (step 1):
    grep -qE 'HOOKS_ONLY.*-eq 0|HOOKS_ONLY.*-eq 1' scripts/ideiaos-update.sh
    echo "GATE Task2-guarda exit=$?"   # exit 0 ⇒ o step 1 (sync-all) está condicionado a HOOKS_ONLY (não roda sob --hooks-only)
  </gate>
</task>

<task type="auto">
  <name>Task 3: Provar isoladamente que --hooks-only registra (idempotente E pula arquivo ausente) num settings.json sandbox</name>
  <files>(teste em sandbox $TMPDIR — nenhum artefato de produto)</files>
  <read_first>
    - scripts/ideiaos-update.sh:184-220 (o heredoc python3 PYEOF do step 3: deriva `name` do command, pula `name in registered`, pula `os.path.exists(local)` falso, append por evento/matcher, backup `.bak-hooks`)
    - plugins/ideiaos-core/hooks/hooks.json (os 11 hooks em 6 eventos que devem aparecer registrados quando os arquivos existem em ~/.claude/hooks/)
  </read_first>
  <action>
    Provar o comportamento do registrador SEM tocar no settings.json real do usuário, exercitando
    o caminho-feliz (arquivos presentes), o invariante de idempotência E o caminho INVÁLIDO
    (hook sem arquivo é pulado). Todo o harness vive DENTRO do <gate> (não no <action>), porque
    <action> e <gate> rodam em shells separados — $SBOX precisa nascer e morrer no MESMO bloco.
    (learning verify-guards-in-sandbox-not-live-repo: validar em sandbox limpo, não no repo/settings vivo.)
  </action>
  <gate>
    # GATE Task3 — harness COMPLETO num único bloco de shell (sandbox criado, exercitado e destruído aqui).
    # Reproduz o heredoc do step 3 apontado para o sandbox; prova 3 coisas por exit-code:
    #   (i) caminho-feliz: 1ª passada com os 11 arquivos presentes registra 11;
    #   (ii) idempotência: 2ª passada NÃO duplica (contagem estável = 11);
    #   (iii) caso INVÁLIDO: removendo 1 arquivo de hook, uma nova passada NÃO o registra (count < 11).
    SBOX=$(mktemp -d); mkdir -p "$SBOX/.claude/hooks"
    echo '{"hooks":{}}' > "$SBOX/.claude/settings.json"
    # semear os 11 arquivos com os nomes derivados de hooks.json:
    /usr/bin/python3 -c "import json,os; h=json.load(open('plugins/ideiaos-core/hooks/hooks.json'))['hooks']; [open(os.path.join('$SBOX/.claude/hooks', hk['command'].rstrip(chr(34)).split('/')[-1]),'w').close() for ev in h.values() for e in ev for hk in e.get('hooks',[])]"
    reg() { /usr/bin/python3 - "$SBOX/.claude/settings.json" "plugins/ideiaos-core/hooks/hooks.json" "$SBOX" <<'PYEOF'
import json, sys, shutil, os
settings_path, plugin_hooks_path, home = sys.argv[1], sys.argv[2], sys.argv[3]
settings = json.load(open(settings_path)); canon = json.load(open(plugin_hooks_path))["hooks"]
registered = json.dumps(settings.get("hooks", {})); added = []
for event, entries in canon.items():
    for entry in entries:
        for hk in entry.get("hooks", []):
            name = hk["command"].rstrip('"').split("/")[-1]
            if name in registered: continue
            local = f'{home}/.claude/hooks/{name}'
            if not os.path.exists(local): continue
            new_hk = {"type":"command","command":f'bash "{local}"'}
            for fld in ("timeout","async","asyncRewake"):
                if fld in hk: new_hk[fld]=hk[fld]
            new_entry={"hooks":[new_hk]}
            if "matcher" in entry: new_entry["matcher"]=entry["matcher"]
            settings.setdefault("hooks",{}).setdefault(event,[]).append(new_entry); added.append(name)
if added:
    shutil.copy(settings_path, settings_path+".bak-hooks")
    json.dump(settings, open(settings_path,"w"), indent=2, ensure_ascii=False)
PYEOF
    }
    cnt() { /usr/bin/python3 -c "import json;print(sum(len(v) for v in json.load(open('$SBOX/.claude/settings.json')).get('hooks',{}).values()))"; }
    reg; C1=$(cnt)            # (i)  caminho-feliz
    reg; C2=$(cnt)            # (ii) idempotência
    # (iii) caso INVÁLIDO: zerar settings + remover 1 arquivo de hook → registra só 10:
    echo '{"hooks":{}}' > "$SBOX/.claude/settings.json"
    rm -f "$SBOX/.claude/hooks/$(ls "$SBOX/.claude/hooks" | head -1)"
    reg; C3=$(cnt)
    test "$C1" -eq 11 && test "$C2" -eq 11 && test "$C3" -eq 10
    RC=$?
    rm -rf "$SBOX"
    echo "GATE Task3 exit=$RC (C1=$C1 C2=$C2 C3=$C3)"   # exit 0 ⇒ registra 11, idempotente (11), e PULA arquivo ausente (10)
  </gate>
</task>

<task type="auto">
  <name>Task 4: Inserir o passo 7.5 de registro no setup-dev-machine.sh (bootstrap-mantenedor) reusando --hooks-only</name>
  <files>setup-dev-machine.sh</files>
  <read_first>
    - setup-dev-machine.sh:192-207 (passo 7 "IdeiaOS — setup global"; invocação real `bash "$DEV/IdeiaOS/setup.sh" --global-only` na LINHA 199; o passo novo entra IMEDIATAMENTE APÓS o `fi` do bloco — linha ~207 — depois que os ARQUIVOS dos hooks foram deployados)
    - setup-dev-machine.sh:209-240 (passo 8 "Obsidian Second Brain" — usa `python3 - <<'VAULT_EOF'` p/ editar settings.json em permissions.additionalDirectories; replicar o ESTILO de mensagem say()/ok()/warn() e a checagem de settings.json existir)
    - setup-dev-machine.sh:38-41 (helpers say/ok/warn/die — usar os mesmos: say usa printf '▶', ok usa '✓', warn usa '⚠')
    - setup-dev-machine.sh:19 (DEV="$HOME/dev") e :199 ($DEV/IdeiaOS/setup.sh) — o caminho do IdeiaOS já está disponível (clonado no passo 3); reusar para chamar scripts/ideiaos-update.sh
  </read_first>
  <action>
    Editar SOMENTE setup-dev-machine.sh (escopo cirúrgico). Inserir, ENTRE o passo 7 (após o `fi`
    do bloco do setup global, linha ~207) e o passo 8 (linha ~209), um novo passo 7.5:

      # ── 7.5) Registrar hooks IdeiaOS em ~/.claude/settings.json (bootstrap-mantenedor) ──
      # O passo 7 (setup.sh --global-only) DEPLOYA os ARQUIVOS dos hooks mas, por T-01-10,
      # NÃO os registra (só imprime snippet). Aqui o bootstrap-mantenedor registra —
      # rodar este script É o consentimento explícito. Reusa o registrador idempotente
      # existente (scripts/ideiaos-update.sh step 3) via --hooks-only — sem extrair script
      # novo, sem duplicar lógica. O Quickstart-CONSUMIDOR continua SEM registro silencioso.
      say "Registrando hooks IdeiaOS no settings.json (mantenedor)"
      if [ -f "$DEV/IdeiaOS/scripts/ideiaos-update.sh" ] && [ -f "$HOME/.claude/settings.json" ]; then
        bash "$DEV/IdeiaOS/scripts/ideiaos-update.sh" --hooks-only \
          && ok "hooks registrados em ~/.claude/settings.json (idempotente)" \
          || warn "registro de hooks retornou erro — rode: bash $DEV/IdeiaOS/scripts/ideiaos-update.sh --hooks-only"
      else
        warn "ideiaos-update.sh ou ~/.claude/settings.json ausente — pulei o registro de hooks"
      fi

    NÃO tocar em setup.sh (T-01-10 intacto). NÃO tocar nos passos 7 e 8 existentes além da inserção.
    Opcional (escopo do requisito): acrescentar 1 linha no bloco RESUMO (heredoc RESUMO, linha ~244)
    mencionando que os hooks foram registrados — só se couber sem reescrever o bloco.
  </action>
  <gate>
    # GATE Task4a — invocação canônica presente E bem-formada (cadeia única, sem '|| true' que mascara):
    bash -n setup-dev-machine.sh \
      && grep -qF -- "ideiaos-update.sh --hooks-only" setup-dev-machine.sh \
      && grep -qF "bootstrap-mantenedor" setup-dev-machine.sh
    echo "GATE Task4a exit=$?"   # exit 0 ⇒ sintaxe OK + registrador invocado via --hooks-only no mantenedor

    # GATE Task4b (T-01-10 por DIFF-REAL — não teatro-verde): setup.sh NÃO pode ter sido tocado por A-07.
    # `git diff --quiet -- setup.sh` retorna 1 se houver QUALQUER edição (provado: detecta input inválido);
    # e as 2 linhas-comentário "setup.sh nunca auto-edita" continuam presentes (== 2, não-removidas).
    git diff --quiet -- setup.sh && git diff --quiet --cached -- setup.sh
    DIFF_RC=$?
    NSENT=$(grep -c "setup.sh nunca auto-edita" setup.sh)
    test "$DIFF_RC" -eq 0 && test "$NSENT" -eq 2
    echo "GATE Task4b(T-01-10 diff-real) exit=$? (diff=$DIFF_RC sentinelas=$NSENT)"
    # ambos exit 0 ⇒ registro inserido no mantenedor; consumidor (setup.sh) comprovadamente INALTERADO
  </gate>
</task>

<task type="auto">
  <name>Task 5: Verificação fim-a-fim por exit-code (ORDEM ancorada em linhas executáveis, idempotência no script real) + restaurar autosync</name>
  <files>(verificação — sem novo artefato; ao final, despausa o autosync)</files>
  <read_first>
    - setup-dev-machine.sh (estado final: passo 7 [linha 199 `--global-only`] → passo 7.5 [invocação `ideiaos-update.sh --hooks-only`] → passo 8 [linha 217 `settings_path = os.path.expanduser`] — a ORDEM importa: registrar DEPOIS de deployar os arquivos, ANTES do vault)
    - scripts/autosync-pause.sh (teardown: remover o pause-file — restauração garantida; learning autosync-races-ai-git-surgery / temp-privilege-window-teardown-grants)
  </read_first>
  <action>
    (a) Provar a ORDEM correta no setup-dev-machine.sh por números de linha das LINHAS EXECUTÁVEIS
        (não comentários): a invocação `bash ... setup.sh --global-only` (passo 7) ANTES da invocação
        `bash ... ideiaos-update.sh --hooks-only` (passo 7.5) ANTES da escrita
        `settings_path = os.path.expanduser` (passo 8). O gate usa regex ancoradas em `^\s*bash` /
        `settings_path = os.path.expanduser` para NÃO casar os comentários homônimos das mesmas seções.
    (b) Idempotência no SCRIPT REAL sem mutar o settings.json do usuário de forma destrutiva:
        fazer backup de ~/.claude/settings.json, rodar `ideiaos-update.sh --hooks-only` duas vezes,
        conferir por exit-code que a contagem de hooks NÃO aumentou na 2ª (e que na 2ª imprime
        "(nenhum hook faltando)"), e restaurar do backup. Como o registrador é genuinamente
        idempotente (Task 3), rodar no real é seguro — ele só ADICIONA o que falta; o backup garante reversão.
    (c) TEARDOWN OBRIGATÓRIO — despausar o autosync (mesmo se algum passo acima falhar):
        bash scripts/autosync-pause.sh off   # ou: rm -f ~/.local/state/git-autosync.pause
        e confirmar a remoção por exit-code. A restauração do autosync é responsabilidade de quem
        pausou (learning temp-privilege-window-teardown-grants — a janela deve incluir o teardown).
    NÃO fazer git push / gh pr (exclusivo @devops). NÃO commitar aqui — o fechamento de sessão e o
    merge work→main são passos do protocolo, fora desta unidade.
  </action>
  <gate>
    # GATE Task5-ordem — ÂNCORAS EXECUTÁVEIS (regex casa a invocação, NÃO o comentário homônimo):
    L7=$(grep -nE '^[[:space:]]*bash .*setup\.sh.* --global-only' setup-dev-machine.sh | head -1 | cut -d: -f1)
    L75=$(grep -nE '^[[:space:]]*bash .*ideiaos-update\.sh --hooks-only' setup-dev-machine.sh | head -1 | cut -d: -f1)
    L8=$(grep -nE '^[[:space:]]*settings_path = os\.path\.expanduser' setup-dev-machine.sh | head -1 | cut -d: -f1)
    # caso INVÁLIDO coberto: se qualquer âncora casasse um COMENTÁRIO (linha iniciada por #), as regex
    # `^[[:space:]]*bash` / `^[[:space:]]*settings_path` NÃO casariam — logo a ordem só passa se as
    # três linhas executáveis existirem e estiverem na sequência certa.
    test -n "$L7" && test -n "$L75" && test -n "$L8" && test "$L7" -lt "$L75" && test "$L75" -lt "$L8"
    echo "GATE Task5-ordem exit=$? (L7=$L7 L75=$L75 L8=$L8)"   # exit 0 ⇒ registra DEPOIS de deployar os arquivos e ANTES do vault

    # GATE Task5-teardown — pause-file removido (autosync restaurado); caso INVÁLIDO = pause-file
    # remanescente faria o autosync seguir parado (regressão silenciosa) → falha:
    test ! -f "$HOME/.local/state/git-autosync.pause"
    echo "GATE Task5-teardown exit=$?"   # exit 0 ⇒ autosync despausado (cirurgia encerrada)
  </gate>
</task>

</tasks>

<conditions>
## Invariantes que o executor DEVE respeitar (não-negociáveis)

1. **T-01-10 é piso.** `setup.sh` NÃO pode ganhar nenhuma auto-edição de `~/.claude/settings.json`
   — continua imprimindo só o snippet (linhas 1384/1428 "setup.sh nunca auto-edita" intocadas; as
   ~15 menções a settings.json em setup.sh são checagens `grep` + warns, nunca escrita). Quem
   registra é o bootstrap-mantenedor (`setup-dev-machine.sh`), porque rodá-lo É o consentimento
   explícito do mantenedor. Provado por **diff-real** (`git diff --quiet -- setup.sh` exit 0), não
   por substring de comentário.
2. **Sem extrair script novo.** O registro REUSA o registrador idempotente que já existe no
   `scripts/ideiaos-update.sh` step 3 (linhas 172-225). A flag `--hooks-only` apenas ISOLA esse
   step — a lógica de registro (heredoc python3 PYEOF, backup `.bak-hooks`) permanece em UMA fonte.
3. **Fonte canônica única dos hooks** = `plugins/ideiaos-core/hooks/hooks.json` (11 hooks, 6 eventos:
   PostToolUse, PreToolUse, UserPromptSubmit, SessionStart, PreCompact, Stop). Não hardcodar a lista
   de hooks em lugar nenhum.
4. **Idempotência por exit-code.** Rodar o bootstrap N vezes não duplica entradas em settings.json
   (o registrador pula `name in registered`). Provado em sandbox (Task 3: 11→11) e no real (Task 5).
5. **Ordem importa:** registrar SÓ DEPOIS de os ARQUIVOS dos hooks terem sido deployados
   (passo 7, `setup.sh --global-only` na linha 199) — registrar um hook cujo arquivo não existe é
   no-op (o registrador pula `os.path.exists(local)` falso, comprovado na Task 3 com count=10). Por
   isso o passo novo entra em 7.5, ANTES do passo 8 (vault, escrita na linha 217).
6. **A-01 antes:** os hooks da FONTE já tiveram o `/usr/bin/python3` corrigido (R15-01); A-07 não
   registra defeito. **A-02 ratifica:** o smoke `idea-smoke.sh` confirma o registro por exit-code
   externamente — A-07 produz, A-02 valida.
7. **Autosync pausado ANTES da cirurgia, despausado DEPOIS (teardown garantido).** Verificar o
   guard de pause no binário DEPLOYADO por `grep`, não confiar em "status PAUSADO"
   (learning autosync-pause-file-guard-not-deployed). O teardown roda mesmo em falha.
8. **Verificação = exit-code binário** (`bash -n`, `grep -q`, `test`, `git diff --quiet`), NUNCA o
   Read tool (antifragile-gates). Cada task fecha num GATE por exit-code que exercita TAMBÉM o
   caminho INVÁLIDO — não só o caminho-feliz (anti-teatro-verde): idempotência (2ª passada estável),
   arquivo-de-hook ausente (pulado → count<11), settings.json ausente (warn, não crash), e diff-real
   de setup.sh (detectaria violação de T-01-10).
9. **bash 3.2 (macOS):** sem `declare -A`. O `setup-dev-machine.sh` e o `ideiaos-update.sh` usam
   `set -uo pipefail`; reusar `source/lib/gates.sh` (assert_nonempty/gate_output/require_file) quando aplicável.
10. **Escopo cirúrgico:** tocar SOMENTE `scripts/ideiaos-update.sh` (flag --hooks-only) e
    `setup-dev-machine.sh` (passo 7.5). Dívida fora de escopo (ex.: dispatcher data-driven do
    ideiaos-update.sh, que é R15-21) vira marcador `debt:`, não conserto agora.
11. **@devops é exclusivo para git push / gh pr.** Este plano NUNCA empurra nem abre PR.
12. **Cabeçalho de proveniência** nos artefatos novos quando houver criação de arquivo
    (`# SOURCE: IdeiaOS v15 | ...`). Aqui só há EDIÇÃO de scripts existentes — preservar seus
    cabeçalhos; o PLAN.md/SUMMARY recebem o header de proveniência v15.
</conditions>

<verification>
- `bash -n scripts/ideiaos-update.sh` e `bash -n setup-dev-machine.sh` exit 0 (sintaxe).
- `grep -qF -- "--hooks-only" scripts/ideiaos-update.sh` + `HOOKS_ONLY` guardando o step 1 + step 3 intacto (`registro de hooks no settings.json` + `.bak-hooks` + `["command"].rstrip`).
- `grep -qF "ideiaos-update.sh --hooks-only" setup-dev-machine.sh` (registrador invocado no mantenedor).
- **T-01-10 por diff-real:** `git diff --quiet -- setup.sh` exit 0 E `grep -c "setup.sh nunca auto-edita" setup.sh` == 2 (consumidor comprovadamente inalterado — NÃO substring de teatro-verde).
- **Idempotência + caso inválido** (Task 3, sandbox): C1=11 (registra), C2=11 (idempotente), C3=10 (pula arquivo ausente). E no real (Task 5): contagem estável na 2ª passada.
- **Ordem por nº de linha ANCORADA EM EXECUTÁVEL:** `^[[:space:]]*bash .*--global-only` (199) < `^[[:space:]]*bash .*ideiaos-update.sh --hooks-only` (7.5) < `^[[:space:]]*settings_path = os.path.expanduser` (217) — regex que NÃO casam os comentários homônimos.
- **Teardown:** `test ! -f ~/.local/state/git-autosync.pause` (autosync restaurado).
</verification>

<success_criteria>
- `setup-dev-machine.sh` registra os hooks em `~/.claude/settings.json` reusando `ideiaos-update.sh --hooks-only` (registrador idempotente existente, step 3), fechando o failure-mode #1.
- T-01-10 preservado e PROVADO por diff-real: setup.sh inalterado (só-snippet); consumidor sem registro silencioso; só o mantenedor registra.
- Sem script novo extraído; lógica de registro permanece em uma única fonte (step 3).
- Idempotente e verificado 100% por exit-code, com cada GATE exercitando TAMBÉM input inválido (idempotência, arquivo-ausente, settings-ausente, diff-real); autosync pausado/restaurado em volta da cirurgia.
</success_criteria>

<output>
Criar `.planning/milestones/v15-phases/A-destravar/A-07-registro-hooks-bootstrap-SUMMARY.md` ao concluir
(o diretório `.planning/milestones/v15-phases/A-destravar/` ainda NÃO existe — criar no início da execução).
</output>
