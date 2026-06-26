---
phase: "v15-A"
plan: "A-05"
type: execute
wave: 1
depends_on: []
files_modified:
  - source/console/machine-aliases.json
  - scripts/check-alias-map.sh
autonomous: true
requirements: [R15-07]
must_haves:
  truths:
    - "O bug é de CHAVE, não de código: ingest.js:325 chama resolveAlias(mid, aliases) com mid=sha256[:12], mas machine-aliases.json indexa por hostname → resolveAlias (ingest.js:60 `aliases[host] || host`) nunca casa e devolve o sha256 cru como canonical_name (ingest.js:331 + upsertMachine ingest.js:170/179) → Frota.tsx:221 `{m.canonical_name ?? \"—\"}` mostra o hash."
    - "Rota MANUAL (re-chavear o JSON por sha256[:12]) — NUNCA 'agentd deriva o nome sozinho': o snapshot v1 não carrega hostname e collect.js:29 deriva machine_id=sha256(IOPlatformUUID)[:12], com collect.js:33-34 PROIBINDO hostname como id (gotcha alias 192↔MacBook-Air-2 — hostname é ambíguo)."
    - "O gate CRUZA chave×MID: prova que cada machine_id real do ref cockpit (52ae4ab0681a, c706ac77d577) resolve para um NOME != ao próprio sha256. test -s sozinho não pega esse bug (o JSON antigo era não-vazio e válido — só não casava)."
    - "Máquina-nova-não-curada (MID no ref cockpit sem entrada no alias-map) = WARN, não FAIL — o sistema federa hosts novos antes de você curar o nome; reprovar travaria a federação."
    - "O pause-file REAL do autosync é ${HOME}/.local/state/git-autosync.pause (autosync-pause.sh:19) — NÃO .local/share/ideiaos/. O verbo `off` faz no-op SILENCIOSO se o flag estiver ausente (autosync-pause.sh:30), logo o gate de teardown precisa exercitar o estado 'flag presente' antes de validar a remoção (senão é teatro-verde)."
  artifacts:
    - path: "source/console/machine-aliases.json"
      provides: "Alias-map re-chaveado por sha256[:12] — chave = machine_id real, valor = nome legível"
      contains: "52ae4ab0681a"
    - path: "scripts/check-alias-map.sh"
      provides: "Gate que CRUZA chave×MID (resolveAlias real != sha256) + WARN para MID não-curado"
      contains: "resolveAlias"
  key_links:
    - from: "source/console/ingest.js:325 resolveAlias(mid, aliases)"
      to: "source/console/machine-aliases.json (chaveado por sha256[:12])"
      via: "aliases[mid] casa agora que a chave é o MID"
      pattern: "machine-aliases.json"
    - from: "scripts/check-alias-map.sh"
      to: "git ls-tree --name-only cockpit snapshots/ (MIDs reais)"
      via: "cruza cada MID do ref cockpit contra o alias-map (resolved != mid → OK; ausente → WARN)"
      pattern: "ls-tree"
---

<meta_goal_backward>
## META (goal-backward)

**Estado final desejado:** a aba Frota do Cockpit exibe na coluna "nome" um nome humano
(`Mac-mini-de-Gustavo`, `MacBook-Air-2`) em vez do sha256 cru (`52ae4ab0681a`).

**Retrocedendo a partir do efeito observável:**
1. Frota.tsx:221 renderiza `{m.canonical_name ?? "—"}` cru do endpoint `/fleet`.
2. `/fleet` (read.js:404 handler; SELECT em read.js:422; serve `canonical_name` em read.js:459)
   serve `m.canonical_name` da coluna `machine.canonical_name`.
3. `machine.canonical_name` (schema.sql:29 — `canonical_name TEXT`, comentário literal
   "nome legível via machine-aliases.json") é gravado em ingest.js:170/179 (upsertMachine)
   com o valor de `resolveAlias(mid, aliases)` (ingest.js:325, campo em ingest.js:331).
4. `resolveAlias(host, aliases)` (ingest.js:60) é `aliases[host] || host`. Com
   `host = mid = sha256[:12]` e `aliases` chaveado por **hostname**, a busca falha e
   devolve o `mid` cru. **A causa-raiz é a CHAVE do JSON, não a função.**

**Logo, a correção mínima e cirúrgica é re-chavear `machine-aliases.json` por
`sha256[:12]`** (rota manual/curada — o requisito proíbe explicitamente "agentd deriva
sozinho", porque o snapshot v1 não tem hostname e collect.js:33-34 proíbe hostname como id).
Nenhuma mudança em `resolveAlias`, `ingest.js`, `read.js` ou `Frota.tsx` é necessária — todos
já estão corretos; só recebem um map com a chave certa. A prova é um gate que CRUZA chave×MID
real (não `test -s`).
</meta_goal_backward>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/milestones/v15-REQUIREMENTS.md
@.planning/milestones/v15-ROADMAP.md
@source/console/ingest.js
@source/console/machine-aliases.json
@source/agentd/collect.js
@apps/cockpit/src/pages/Frota.tsx
@scripts/autosync-pause.sh
</context>

<assumptions>
## Suposições materiais (corrija-me antes de executar)

1. **O fix é de DADO, não de lógica.** `resolveAlias` (ingest.js:60) já está correto —
   `aliases[host] || host`. O defeito é que a chave do JSON é hostname e o argumento é
   sha256[:12]. Re-chaveio o JSON; NÃO toco em ingest.js/read.js/Frota.tsx.
2. **MIDs reais conhecidos = os do ref cockpit AGORA** (`52ae4ab0681a`, `c706ac77d577`,
   verificados por `git ls-tree --name-only cockpit snapshots/`).
   O mapeamento humano correto vem da curadoria do dono: `52ae4ab0681a` e `c706ac77d577`
   correspondem fisicamente a Mac-mini-de-Gustavo e MacBook-Air-2 (a cerimônia N=2 de v14.4
   usou exatamente esses 2 hosts). Se o dono souber QUAL sha256 é QUAL máquina, ele confirma;
   se não, o gate de WARN cobre o não-curado sem travar, e a troca de rótulo entre os dois
   é cosmética e corrigível depois.
3. **Hostnames legados saem do JSON** (`"192"`, `"MacBook-Air"`, `"MacBook-Air-2"`,
   `"Mac-mini-de-Gustavo"` — os 4 atuais): eles nunca casam com um MID e poluem o map.
   `resolveAlias` é chamado com `mid` em ingest.js:325 (a outra chamada, ingest.js:142, é
   sobre `host` de soak-heartbeat — escopo ORTOGONAL, não toco).
4. **Autosync pausado antes da cirurgia multi-arquivo** (machine-aliases.json + novo gate),
   usando o pause-file REAL `${HOME}/.local/state/git-autosync.pause` (autosync-pause.sh:19).
5. **O plano NÃO faz git push** (@devops exclusivo). Encerra com working tree pronto.
</assumptions>

<tasks>

<task type="auto">
  <name>Task 0: Pausar o autosync ANTES da cirurgia (autosync-race)</name>
  <files>(nenhum versionado — só estado de daemon)</files>
  <read_first>
    - scripts/autosync-pause.sh — verbos `on`/`off`/`status`; é o MESMO script que read.js:88
      (`pause_autosync`) e read.js:90 (`resume_autosync`) invocam via Cockpit.
    - PATH REAL do pause-file (autosync-pause.sh:19, verificado por Read):
        PAUSE="${HOME}/.local/state/git-autosync.pause"
      NÃO é `.local/share/ideiaos/...`. O `on` (linha 25) grava esse arquivo; o `off` (linha 30)
      o remove SÓ se existir (`[ -f "$PAUSE" ]`), com no-op silencioso caso ausente.
    - learning autosync-races-ai-git-surgery (o autosync add -A + commit + push atropela edição
      multi-arquivo).
    - learning autosync-pause-file-guard-not-deployed (verifique o flag REAL por exit-code,
      nunca o "status PAUSADO" verbal do script).
  </read_first>
  <action>
    Pausar o git-autosync para que a edição de `machine-aliases.json` + a criação de
    `scripts/check-alias-map.sh` não sejam capturadas/empurradas no meio da cirurgia:

        bash scripts/autosync-pause.sh on "v15-A-05 alias-map"

    NOTA de durabilidade (learning autosync-pause-file-guard-not-deployed): NÃO confie no
    "status PAUSADO". Verifique por exit-code que o flag de pause foi materializado em disco
    no GATE abaixo (test -s no pause-file REAL), nunca apenas a mensagem do script.
  </action>
  <gate>
    # PATH REAL do pause-file (autosync-pause.sh:19) — NÃO .local/share/ideiaos
    PAUSE_FLAG="${HOME}/.local/state/git-autosync.pause"

    # ANTI-TEATRO-VERDE (estado inválido exercitado): provar que ANTES da pausa o flag
    # reflete o estado real, e que a pausa o MATERIALIZA. Sem isto, um gate que só roda
    # `test -s` no caminho-feliz aprovaria mesmo um pause que falhou silenciosamente.
    # 1) Estado limpo de partida (se já estava pausado de antes, removemos p/ provar o `on`):
    rm -f "$PAUSE_FLAG"
    test -e "$PAUSE_FLAG" && { echo "FAIL: não consegui limpar pause-file pré-pausa"; exit 1; }
    # 2) Executar a pausa de verdade e PROVAR que o flag passou a existir e é não-vazio:
    bash scripts/autosync-pause.sh on "v15-A-05 alias-map" >/dev/null
    test -s "$PAUSE_FLAG" || { echo "FAIL: autosync NÃO pausado (flag ausente/vazio: $PAUSE_FLAG)"; exit 1; }
    echo "OK: autosync pausado e PROVADO por test -s no pause-file real ($PAUSE_FLAG)"
  </gate>
  <done>autosync pausado e PROVADO por test -s no pause-file REAL (.local/state/git-autosync.pause), não pelo status verbal; o `on` materializou um flag que antes não existia.</done>
</task>

<task type="auto">
  <name>Task 1: Re-chavear machine-aliases.json por sha256[:12] (rota manual)</name>
  <files>source/console/machine-aliases.json</files>
  <read_first>
    - source/console/machine-aliases.json (ESTADO BUGADO atual — 4 chaves de HOSTNAME:
      "192", "MacBook-Air-2", "Mac-mini-de-Gustavo", "MacBook-Air"; nenhuma é um sha256[:12])
    - source/console/ingest.js:60-62 (resolveAlias = `aliases[host] || host` — NÃO ALTERAR)
    - source/console/ingest.js:325 (`const canonicalName = resolveAlias(mid, aliases)` —
      mid = snapshot.machine_id = sha256[:12]; é ESTE call que precisa casar)
    - source/agentd/collect.js:29 (machine_id = sha256(IOPlatformUUID)[:12]) e collect.js:33-34
      (proíbe hostname como id — por isso a rota é MANUAL, não derivada)
    - MIDs reais no ref cockpit (descobrir agora, não chutar):
        git ls-tree --name-only cockpit snapshots/   # → snapshots/<MID>.json
  </read_first>
  <action>
    Substituir o conteúdo de `source/console/machine-aliases.json` por um map chaveado por
    **sha256[:12]** (o MID que `ingest.js:325` passa a `resolveAlias`). Valor = nome legível.

    (a) Descobrir os MIDs reais (não inventar):
        git ls-tree --name-only cockpit snapshots/ | sed 's#snapshots/##; s#\.json##'
        # Hoje: 52ae4ab0681a e c706ac77d577

    (b) Curadoria do mapeamento MID→nome. Pela cerimônia N=2 de v14.4 (2 hosts físicos reais:
        Mac mini + MacBook-Air-2), os 2 MIDs do ref cockpit são essas 2 máquinas. Gravar:

        {
          "52ae4ab0681a": "Mac-mini-de-Gustavo",
          "c706ac77d577": "MacBook-Air-2"
        }

        SE houver dúvida sobre QUAL sha256 é QUAL máquina física (o dono é a autoridade),
        ainda assim AMBOS os MIDs DEVEM estar no map com ALGUM nome humano != ao próprio
        sha256 — a troca de rótulo entre os dois é cosmética e corrigível depois; o que o
        requisito exige é "nome, não hash".

    (c) Adicionar header de proveniência. JSON não aceita comentário, então o header vai numa
        chave reservada `_SOURCE` (ignorada por resolveAlias, que só faz lookup direto
        `aliases[mid]`, nunca itera Object.keys):

        {
          "_SOURCE": "IdeiaOS v15 | kind: alias-map | chaveado por sha256[:12] (NUNCA hostname — R15-07/collect.js:33)",
          "52ae4ab0681a": "Mac-mini-de-Gustavo",
          "c706ac77d577": "MacBook-Air-2"
        }

    (d) NÃO manter chaves de hostname legadas ("192", "MacBook-Air", "MacBook-Air-2",
        "Mac-mini-de-Gustavo" como CHAVE) — elas nunca casam com um MID e só poluem. Escopo
        cirúrgico: o JSON passa a conter SÓ `_SOURCE` + MIDs.

    INVARIANTE: NÃO editar ingest.js, read.js, collect.js nem Frota.tsx. O bug é a chave do
    JSON; a lógica já está certa.
  </action>
  <gate>
    . source/lib/gates.sh 2>/dev/null || gate_output() { test -s "${1:-}" 2>/dev/null; }
    F=source/console/machine-aliases.json
    # (1) arquivo não-vazio e JSON válido (node -e parseia — exit-code binário)
    gate_output "$F" "alias-map" || { echo "FAIL: alias-map vazio"; exit 1; }
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$F" \
      || { echo "FAIL: JSON inválido"; exit 1; }
    # (2) PELO MENOS uma chave é um sha256[:12] real (^[0-9a-f]{12}$) — prova o re-chaveamento
    node -e '
      const a=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
      const mids=Object.keys(a).filter(k=>/^[0-9a-f]{12}$/.test(k));
      if(mids.length===0){console.error("FAIL: nenhuma chave sha256[:12] — ainda chaveado por hostname");process.exit(1);}
      process.exit(0);
    ' "$F" || exit 1
    # (3) NEGATIVA (input inválido residual): nenhuma chave de hostname legado sobrou
    #     (exceto _SOURCE reservado) — prova que o re-chaveamento foi COMPLETO, não parcial.
    node -e '
      const a=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
      const bad=Object.keys(a).filter(k=>k!=="_SOURCE" && !/^[0-9a-f]{12}$/.test(k));
      if(bad.length){console.error("FAIL: chaves não-MID residuais:",bad.join(","));process.exit(1);}
      process.exit(0);
    ' "$F" || exit 1
    echo "OK: alias-map chaveado por sha256[:12], JSON válido, sem hostname residual"
  </gate>
  <done>machine-aliases.json chaveado por sha256[:12], JSON válido, sem hostname residual; lógica intacta.</done>
</task>

<task type="auto">
  <name>Task 2: Gate que CRUZA chave×MID (não só test -s) + WARN para MID não-curado</name>
  <files>scripts/check-alias-map.sh</files>
  <read_first>
    - source/console/ingest.js:60-62 (a função real que o gate ESPELHA: `aliases[host] || host`)
    - source/console/ingest.js:325 (o call-site: resolveAlias(mid, aliases))
    - source/lib/gates.sh:24/36/42 (assert_nonempty/gate_output/require_file — reusar; build-script sai 1 em falha)
    - .claude/rules/ideiaos-common-antifragile-gates.md ("Build scripts MUST exit 1 on gate failure";
      "test -s não basta quando o defeito é semântico — chave que não casa")
    - MIDs reais: git ls-tree --name-only cockpit snapshots/
  </read_first>
  <action>
    Criar `scripts/check-alias-map.sh` — um BUILD-SCRIPT (exit 1 em falha, NUNCA hook) que
    PROVA o casamento chave×MID. O ponto-chave do requisito: "Gate que CRUZA chave×MID
    (não só test -s)". `test -s` aprovaria o JSON antigo (não-vazio e válido) que mesmo assim
    NÃO casava. O gate tem de simular o `resolveAlias` real sobre cada MID do ref cockpit.

    Header de proveniência no topo:
        #!/usr/bin/env bash
        # SOURCE: IdeiaOS v15 | kind: gate | targets: source/console/machine-aliases.json
        # R15-07 — cruza cada machine_id real do ref cockpit contra o alias-map:
        #   resolveAlias(mid) != mid  → OK (casou num nome)
        #   mid ausente do map        → WARN (máquina-nova-não-curada — NÃO falha)

    Comportamento (bash 3.2, sem `declare -A`; node faz o cruzamento determinístico):
      1. Sourcear gates.sh; `require_file source/console/machine-aliases.json`.
      2. Listar MIDs reais: `git ls-tree --name-only cockpit snapshots/` →
         basename sem `.json`. Se o ref cockpit não existir (clone fresco), WARN e exit 0
         (não há frota para cruzar ainda — não falha).
      3. Para CADA MID, computar `resolveAlias(mid)` ESPELHANDO ingest.js:60
         (`aliases[mid] || mid`) via node, e classificar:
            - resolved !== mid                → PASS (casou num nome legível)
            - resolved === mid E mid no map    → FAIL (entrada presente mas valor == sha256: rótulo inútil)
            - mid AUSENTE do map               → WARN (máquina-nova-não-curada)
      4. **Decisão de exit (a regra do requisito):**
            - qualquer FAIL                    → exit 1 (build-script)
            - só PASS/WARN                     → exit 0 (WARN não reprova)
            - ZERO PASS e ≥1 MID curável       → exit 1 (o map não resolve NENHUM MID conhecido
                                                  = o bug original ainda vivo)
      5. Imprimir um resumo legível: por MID, "PASS nome=<...>" | "WARN não-curado" | "FAIL".

    Núcleo do cruzamento (node — espelha resolveAlias, não reimplementa lógica nova):
        node -e '
          const fs=require("fs");
          const a=JSON.parse(fs.readFileSync("source/console/machine-aliases.json","utf8"));
          const resolveAlias=(mid)=> a[mid] || mid;          // ESPELHA ingest.js:60
          const mids=process.argv.slice(1).filter(Boolean);
          let pass=0, warn=0, fail=0;
          for(const mid of mids){
            const r=resolveAlias(mid);
            if(r!==mid){ console.log("PASS "+mid+" -> "+r); pass++; }
            else if(Object.prototype.hasOwnProperty.call(a,mid)){ console.log("FAIL "+mid+" (valor == sha256)"); fail++; }
            else { console.log("WARN "+mid+" nao-curado"); warn++; }
          }
          if(fail>0) process.exit(1);
          if(pass===0 && mids.length>0) process.exit(1);     // map nao resolve nenhum MID = bug vivo
          process.exit(0);
        ' "$@"   # "$@" = lista de MIDs do ref cockpit
  </action>
  <gate>
    # (1) sintaxe do gate válida + executável
    bash -n scripts/check-alias-map.sh || { echo "FAIL: sintaxe"; exit 1; }
    chmod +x scripts/check-alias-map.sh
    # (2) o GATE PASSA contra o alias-map corrigido (cruza os MIDs reais do ref cockpit)
    bash scripts/check-alias-map.sh || { echo "FAIL: o cruzamento chave×MID reprovou"; exit 1; }
    # (3) ANTI-TEATRO-VERDE — o gate FALHA contra um alias-map propositalmente bugado
    #     (hostname-keyed, como o original). Prova que o gate detecta o bug que deveria pegar,
    #     não só aprova o caminho feliz (learning antitheater-gate-blind-spot-happy-path).
    TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
    printf '{"192":"Mac-mini-de-Gustavo","MacBook-Air":"MacBook-Air"}' > "$TMP/bad-aliases.json"
    cp source/console/machine-aliases.json "$TMP/good.bak"
    cp "$TMP/bad-aliases.json" source/console/machine-aliases.json
    if bash scripts/check-alias-map.sh >/dev/null 2>&1; then
      cp "$TMP/good.bak" source/console/machine-aliases.json   # restaurar SEMPRE
      echo "FAIL: gate aprovou alias-map hostname-keyed (teatro verde — não cruza chave×MID)"; exit 1
    fi
    cp "$TMP/good.bak" source/console/machine-aliases.json      # restaurar o bom
    echo "OK: gate reprova bugado e aprova corrigido (cruza chave×MID)"
  </gate>
  <done>check-alias-map.sh cruza chave×MID, exit 1 só em FAIL/zero-PASS, WARN para não-curado; provado contra map bugado E corrigido.</done>
</task>

<task type="auto">
  <name>Task 3: Prova end-to-end — re-ingestar e confirmar canonical_name != sha256 na coluna real</name>
  <files>(nenhum — verificação de runtime contra o read-model)</files>
  <read_first>
    - source/console/ingest.js:323-335 (ingestSnapshot → resolveAlias(mid) → upsertMachine canonical_name)
    - source/console/ingest.js:170-184 (upsertMachine grava canonical_name na tabela machine)
    - source/console/schema.sql:29 (machine.canonical_name TEXT — "nome legível via machine-aliases.json";
      é a coluna que /fleet e Frota.tsx:221 leem)
    - apps/cockpit/server/read.js:404-459 (/fleet: handler :404, SELECT canonical_name :422, serve :459)
  </read_first>
  <action>
    Provar que o fix de DADO propaga até a coluna que a Frota lê — sem rodar o browser
    (regime artefato-de-arquivo: exit-code é lei). Re-rodar o ingest e consultar a coluna
    `machine.canonical_name` no read-model; ela DEVE conter nomes, não sha256.

        node source/console/ingest.js            # re-ingesta os snapshots do ref cockpit

    Depois consultar o DB (~/.ideiaos/console/read-model.db) via node:sqlite e verificar que
    para cada machine_id, canonical_name != machine_id (nome casou). Máquina não-curada
    (canonical_name === machine_id) é WARN, não FAIL — consistente com Task 2.

    INVARIANTE: este passo NÃO edita nada; só PROVA o efeito. Se o ingest falhar por ambiente
    (ref cockpit ausente em clone fresco), reportar WARN e considerar a prova satisfeita pelos
    gates determinísticos das Tasks 1-2 (o cruzamento já provou o casamento sem precisar do DB).
  </action>
  <gate>
    DB="$HOME/.ideiaos/console/read-model.db"
    # Se não há ref cockpit nem DB nesta máquina, a prova determinística (Task 1-2) já basta → WARN, exit 0
    if ! git rev-parse --verify cockpit >/dev/null 2>&1; then
      echo "WARN: ref cockpit ausente — prova e2e pulada; cruzamento determinístico (Task 2) é suficiente"; exit 0
    fi
    node source/console/ingest.js >/dev/null 2>&1 || { echo "FAIL: ingest quebrou"; exit 1; }
    test -s "$DB" || { echo "WARN: read-model.db ausente após ingest"; exit 0; }
    # CRUZA na COLUNA REAL: pelo menos 1 machine com canonical_name != machine_id (nome casou)
    node -e '
      const {DatabaseSync}=require("node:sqlite");
      const db=new DatabaseSync(process.argv[1]);
      const rows=db.prepare("SELECT machine_id, canonical_name FROM machine").all();
      db.close();
      if(rows.length===0){console.error("WARN: nenhuma machine no read-model");process.exit(0);}
      const named=rows.filter(r=>r.canonical_name && r.canonical_name!==r.machine_id);
      for(const r of rows){ console.log((r.canonical_name!==r.machine_id?"PASS ":"WARN ")+r.machine_id+" -> "+(r.canonical_name||"(null)")); }
      if(named.length===0){console.error("FAIL: TODA canonical_name == sha256 — bug ainda vivo");process.exit(1);}
      process.exit(0);
    ' "$DB" || exit 1
  </gate>
  <done>Re-ingest grava nomes em machine.canonical_name; gate prova canonical_name != sha256 na coluna que a Frota lê.</done>
</task>

<task type="auto">
  <name>Task 4: Retomar o autosync (teardown — sempre, mesmo se algo acima falhou)</name>
  <files>(nenhum versionado)</files>
  <read_first>
    - scripts/autosync-pause.sh — verbo `off` (linha 29-36): remove o pause-file SÓ se existir
      (`[ -f "$PAUSE" ]`), com no-op silencioso caso ausente. Por isso o gate de teardown
      precisa exercitar o estado "flag presente" ANTES de validar a remoção — senão um
      `test ! -e` passa trivialmente mesmo que o autosync tenha ficado pausado (teatro-verde).
    - PATH REAL do pause-file (autosync-pause.sh:19): `${HOME}/.local/state/git-autosync.pause`.
    - learning temp-privilege-window-teardown-grants (a janela DEVE conceder o teardown;
      retomar o autosync é o cleanup obrigatório desta cirurgia).
    - learning autosync-pause-file-guard-not-deployed (verifique o flag REAL por exit-code).
  </read_first>
  <action>
    Retomar o git-autosync — a cirurgia multi-arquivo terminou:

        bash scripts/autosync-pause.sh off

    Este passo é OBRIGATÓRIO mesmo que uma task anterior tenha falhado: deixar o autosync
    pausado indefinidamente degrada o sync da frota. Se o executor abortou antes daqui,
    rodar este `off` manualmente.
  </action>
  <gate>
    # PATH REAL do pause-file (autosync-pause.sh:19)
    PAUSE_FLAG="${HOME}/.local/state/git-autosync.pause"

    # ANTI-TEATRO-VERDE (estado inválido exercitado): o `off` é no-op silencioso se o flag
    # não existir, então um gate `test ! -e` puro passaria trivialmente sem nunca provar que
    # o `off` REMOVE de fato. Garantimos o estado "flag presente" antes do off e SÓ ENTÃO
    # validamos a ausência — isso exercita o caminho real de remoção.
    # 1) Garantir flag presente (recria se a cirurgia já o removeu por algum motivo):
    test -s "$PAUSE_FLAG" || bash scripts/autosync-pause.sh on "v15-A-05 teardown-proof" >/dev/null
    test -s "$PAUSE_FLAG" || { echo "FAIL: não consegui materializar pause-file p/ provar o off"; exit 1; }
    # 2) Executar o teardown real e PROVAR que o flag SUMIU (exit-code binário):
    bash scripts/autosync-pause.sh off >/dev/null
    test ! -e "$PAUSE_FLAG" || { echo "FAIL: autosync ainda pausado (flag presente: $PAUSE_FLAG)"; exit 1; }
    echo "OK: autosync retomado e PROVADO por ausência do pause-file real (off removeu o flag presente)"
  </gate>
  <done>autosync retomado e PROVADO por ausência do pause-file REAL após exercitar o estado "flag presente" (off removeu de verdade, não teatro-verde).</done>
</task>

</tasks>

<invariants>
## Condições/invariantes que o executor DEVE respeitar

1. **NÃO editar lógica.** `resolveAlias` (ingest.js:60), `ingest.js`, `read.js`, `collect.js`
   e `Frota.tsx` ficam INTOCADOS. O único arquivo de produto alterado é
   `source/console/machine-aliases.json` (dado) + 1 gate novo (`scripts/check-alias-map.sh`).
   Se o executor sentir vontade de "consertar resolveAlias", PARE — a função já está certa;
   o bug é a chave do JSON.
2. **Rota MANUAL, nunca derivada.** Proibido fazer o agentd/collect.js inferir o nome a partir
   de hostname: o snapshot v1 não carrega hostname e collect.js:33-34 proíbe hostname como id
   (gotcha alias 192↔MacBook-Air-2). O nome humano vem SÓ de curadoria no JSON.
3. **Chave = sha256[:12] (`^[0-9a-f]{12}$`)**, valor = nome legível. Nenhuma chave de hostname
   legado pode sobrar (exceto a chave reservada `_SOURCE` do header de proveniência).
4. **O gate CRUZA chave×MID** — não `test -s`. Tem de simular `resolveAlias` sobre os MIDs
   reais do ref cockpit e provar `resolved != mid`. Inclui passo anti-teatro-verde (reprovar
   um map propositalmente bugado), que SEMPRE restaura o map bom no final.
5. **Máquina-nova-não-curada = WARN, não FAIL.** Um MID no ref cockpit ausente do alias-map
   NÃO reprova o gate — a federação aceita hosts novos antes de você curar o rótulo.
   Só é FAIL: (a) uma entrada cujo valor é o próprio sha256, ou (b) ZERO MID resolvido quando
   há MIDs curáveis (= bug original ainda vivo).
6. **Gate é build-script: exit 1 em falha** (`.claude/rules/...antifragile-gates`). NÃO é hook;
   não há contrato "sair 0 sempre" aqui.
7. **bash 3.2 (macOS): sem `declare -A`.** O cruzamento determinístico roda em node (já
   disponível, v24); o shell só orquestra e decide exit-code.
8. **Autosync pausado antes da cirurgia e retomado depois** (Tasks 0 e 4), provado por
   exit-code no PAUSE-FILE REAL `${HOME}/.local/state/git-autosync.pause` (autosync-pause.sh:19)
   — NUNCA pelo "status PAUSADO" verbal, e NUNCA pelo path inventado `.local/share/ideiaos/...`
   (learning autosync-pause-file-guard-not-deployed). Como o `off` é no-op silencioso quando o
   flag está ausente, o gate de teardown exercita o estado "flag presente" antes de validar a
   remoção (anti-teatro-verde). Teardown é obrigatório.
9. **Sem git push / gh pr** — @devops exclusivo. O plano deixa o working tree pronto; o
   commit/push é etapa separada fora deste plano.
10. **Escopo cirúrgico.** Dívida fora de escopo (ex.: a chamada resolveAlias de soak-heartbeat
    em ingest.js:142, que é ortogonal) NÃO é tocada — se notada, vira marcador `debt:`, não fix.
</invariants>

<threat_model>
## STRIDE / honestidade de dado

| Threat ID | Categoria | Componente | Disposição | Mitigação |
|-----------|-----------|------------|------------|-----------|
| T-A05-T | Tampering | rótulo de máquina | mitigar | nome vem de curadoria humana no JSON, não de inferência de hostname (collect.js:33-34); chave = MID criptográfico estável |
| T-A05-I | Honestidade | Frota mostra sha256 | corrigir | re-chavear por sha256[:12]; gate cruza chave×MID — nunca "nome fabricado" para MID não-curado (mostra o sha256 honesto = WARN) |
| T-A05-DoS | Disponibilidade | gate trava federação | mitigar | máquina-nova-não-curada = WARN; o gate só reprova bug real (valor==sha256 ou zero-resolve), nunca um host novo legítimo |
| T-A05-R | Repúdio/durabilidade | autosync atropela cirurgia | mitigar | pause-file REAL (.local/state/git-autosync.pause) provado por exit-code antes e depois; teardown obrigatório exercitando estado "flag presente" |
</threat_model>

<verification>
- node -e JSON.parse no machine-aliases.json (exit 0) + ≥1 chave `^[0-9a-f]{12}$` + zero hostname residual.
- scripts/check-alias-map.sh: PASSA contra o map corrigido E FALHA contra um map hostname-keyed (anti-teatro-verde), restaurando o bom.
- Re-ingest + SELECT machine.canonical_name: ≥1 linha com canonical_name != machine_id (nome na coluna que a Frota lê).
- autosync pausado (Task 0) e retomado (Task 4) provados por exit-code no PAUSE-FILE REAL `${HOME}/.local/state/git-autosync.pause`, com cada gate exercitando o estado inválido (flag ausente na pausa; flag presente no teardown).
</verification>

<success_criteria>
- machine-aliases.json chaveado por sha256[:12] (rota manual), sem hostname legado, com header _SOURCE.
- Gate check-alias-map.sh cruza chave×MID (não test -s); WARN para não-curado, FAIL só para bug real; anti-teatro-verde verde.
- canonical_name na coluna real != sha256 → a Frota passa a mostrar NOME, não hash.
- Zero mudança em resolveAlias/ingest.js/read.js/collect.js/Frota.tsx; autosync retomado (pause-file real removido); sem push.
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-05-SUMMARY.md` when done
</output>
</plan_markdown>
</invoke>
