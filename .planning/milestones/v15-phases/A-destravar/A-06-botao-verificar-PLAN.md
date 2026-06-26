---
phase: "v15-A"
plan: "A-06"
type: execute
wave: 1
depends_on: []
files_modified:
  - apps/cockpit/src/pages/Frota.tsx
requirements: [R15-08]
must_haves:
  truths:
    - "A tela Frota consome GET /verify?cell=<machine_id> do read.js loopback (127.0.0.1:READ_PORT) — endpoint JÁ completo e hardened; zero edição em read.js (read-only sobre o backend)"
    - "O botão verificar distingue 3 estados a partir da DUPLA (verified, disk_epoch) servida pelo /verify: verified===true => VERIFICADO; verified===false && disk_epoch!=null => DIVERGÊNCIA (alarme); verified===false && disk_epoch==null => NÃO-VERIFICÁVEL (neutro, NUNCA alarme)"
    - "O carimbo 'verificado há Xs' é derivado de recomputed_at_epoch do payload (frescor honesto, textual — nunca animação)"
    - "A distinção dos 3 estados é PROVADA no browser (regime runtime, Chrome DevTools MCP), não só por curl — /verify é seguro por construção (metadata-only), não por escaneamento"
  artifacts:
    - path: "apps/cockpit/src/pages/Frota.tsx"
      provides: "Botão verificar por máquina + render dos 3 estados de /verify (verificado / divergência / não-verificável)"
      contains: "/verify"
  key_links:
    - from: "apps/cockpit/src/pages/Frota.tsx"
      to: "apps/cockpit/server/read.js (GET /verify?cell=<MID>)"
      via: "fetch loopback no instante do clique (recompute-from-disk, A6 Trust-Rate)"
      pattern: "/verify"
---

<objective>
Fechar R15-08: o endpoint `/verify` (apps/cockpit/server/read.js:517-585) é completo e hardened
(`git show cockpit:snapshots/<MID>.json` no instante da pergunta, MID validado contra `^[0-9a-f]{12}$`,
argv-array sem shell, metadata-only), mas NENHUMA tela o consome. Adicionar à `Frota.tsx` um botão
"verificar" por máquina que dispara `GET /verify?cell=<machine_id>` e renderiza os **3 estados
distintos honestos**:

| Condição no payload (`verified`, `disk_epoch`) | Estado | Sinal visual |
|---|---|---|
| `verified === true` | **VERIFICADO** | sucesso (`--status-success`/Badge `ok`) + "verificado há Xs" |
| `verified === false` E `disk_epoch != null` | **DIVERGÊNCIA** (alarme real — servido ≠ disco) | alarme (Badge `fail`) + label textual |
| `verified === false` E `disk_epoch == null` | **NÃO-VERIFICÁVEL** (sem snapshot no disco) | **neutro** (Badge `default`) — NUNCA alarme |

Purpose: é uma quick-win da Fase A (Onda 1) — destrava capacidade já construída (zero código novo no
backend; só wiring de UI read-only). A invariante crítica é a **3ª linha**: ausência de prova ≠ prova de
falha; o estado não-verificável é neutro e jamais pinta alarme (honestidade de frescor, spec "Verdade
verificável contra o disco" — specs/cockpit/spec.md:106-115).

**Reconciliação verificada no código shipado (NÃO inventar):**
- O shape REAL do `/verify` (testado ao vivo neste plano): `{cell, verified, served_epoch, disk_epoch, recomputed_at_epoch, source:"git-show-cockpit"}`. O campo de divergência é `disk_epoch` (não `disk` nem outro nome).
- `--status-success` e `--status-warning` JÁ EXISTEM em `apps/cockpit/src/index.css:45-46`. Este plano NÃO os adiciona (escopo cirúrgico). O alarme reusa a variante `fail` do Badge (badge.tsx:9), o neutro reusa `default`.
- O backend NÃO é tocado. R15-08 diz "endpoint completo e hardened, zero tela consome" → a única mudança é em `Frota.tsx`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/milestones/v15-REQUIREMENTS.md
@.planning/milestones/v15-ROADMAP.md
@specs/cockpit/spec.md
@apps/cockpit/server/read.js
@apps/cockpit/src/pages/Frota.tsx
</context>

<preconditions>
Antes de qualquer cirurgia multi-arquivo, PAUSAR o autosync (autosync-race — o daemon faz `add -A + commit + push` em ciclo e atropela edição da IA):

```
bash scripts/autosync-pause.sh on "A-06 botão verificar Frota"
```

Esta fase NÃO é auto-modificante (não edita o próprio autosync/daemon) — basta o pause normal; não há
necessidade de verificar binário deployado por grep. Ao final (após o gate da última task), RETOMAR:

```
bash scripts/autosync-pause.sh off
```

Esta fase NUNCA faz `git push` nem `gh pr` — isso é exclusivo de @devops (agent-authority).
</preconditions>

<tasks>

<task type="auto">
  <name>Task 1: Botão "verificar" por máquina na Frota + fetch on-demand a /verify (3 estados)</name>
  <files>apps/cockpit/src/pages/Frota.tsx</files>
  <read_first>
    - apps/cockpit/src/pages/Frota.tsx (o arquivo a modificar — reusar: API_BASE loopback da linha 33 `http://127.0.0.1:${READ_PORT}`; o padrão useState/fetch do useEffect existente linhas 84-111; a tabela densa de heartbeat linhas 198-248 — a coluna "verificar" entra aqui, ao lado de "frescor"; o helper ageLabel linhas 49-60 como modelo de label textual honesto)
    - apps/cockpit/server/read.js:517-585 (handleVerify — CONTRATO QUE A UI CONSOME, não modificar: shape REAL `{cell, verified, served_epoch, disk_epoch, recomputed_at_epoch, source}`; `verified = diskEpoch !== null && servedEpoch !== null && diskEpoch === servedEpoch` na linha 574; quando NÃO há snapshot no disco, `diskEpoch = null` (linha 571) e `verified=false` — este é o estado NÃO-VERIFICÁVEL; query param é `?cell=<MID>`, validado por MID_RE=/^[0-9a-f]{12}$/ no server)
    - apps/cockpit/src/components/ui/badge.tsx:9 (BadgeVariant = "default" | "ok" | "warn" | "fail" — usar `ok` p/ verificado, `fail` p/ divergência/alarme, `default` p/ não-verificável/neutro; NUNCA criar variante nova)
    - apps/cockpit/src/components/MachineCard.tsx (padrão de Badge + ícone lucide já estabelecido — manter consistência visual; cor NUNCA é o único sinal: sempre acompanhar de label textual, conforme comentário Frota.tsx:14-22)
  </read_first>
  <action>
    Em `Frota.tsx`, adicionar consumo on-demand de `/verify` SEM tocar o backend e SEM mudar o fetch
    inicial de `/fleet`:

    (a) Estado por-célula: um `useState` mapeando `machine_id -> VerifyResult | "loading" | undefined`.
        Tipar `VerifyResult` EXATAMENTE pelo shape real do endpoint (verificado ao vivo):
        `{ cell: string; verified: boolean; served_epoch: number | null; disk_epoch: number | null;
           recomputed_at_epoch: number; source: string }`.
        NÃO inventar campos. NÃO assumir um campo "disk" — o nome real é `disk_epoch`.

    (b) Handler `verifyCell(machineId)`: `fetch(\`${API_BASE}/verify?cell=${machineId}\`)`, marca a célula
        como "loading" antes, grava o resultado depois. Tratar `!res.ok` gravando um estado de erro de FETCH
        distinto dos 3 estados de domínio (erro de rede ≠ divergência ≠ não-verificável). O machine_id já vem
        do `/fleet` e casa o regex do server; mesmo assim, NÃO interpolar nada além do machine_id da linha.

    (c) Derivação dos 3 ESTADOS a partir da DUPLA `(verified, disk_epoch)` — função pura local
        `verifyState(r): "verified" | "divergence" | "unverifiable"`:
          - `r.verified === true`                          -> "verified"
          - `r.verified === false && r.disk_epoch != null` -> "divergence"   (alarme real)
          - `r.verified === false && r.disk_epoch == null` -> "unverifiable" (neutro)
        INVARIANTE-PISO: o ramo `unverifiable` NUNCA usa a variante `fail`/alarme — usa `default` (neutro).

    (d) Render na tabela de heartbeat (linhas 198-248): nova coluna `<th>verificar</th>` no `<thead>` e, em
        cada `<tr>`, uma célula com um `<button>` "verificar" + a área de resultado:
          - estado undefined (nunca clicado): só o botão.
          - "loading": texto "verificando…".
          - "verified": Badge `ok` com label textual "verificado" + "verificado há Xs" derivado de
            `recomputed_at_epoch` (reusar a forma de `ageLabel`, mas a partir de `recomputed_at_epoch`,
            NÃO de last_seen_epoch — é o carimbo de quando a verdade-contra-o-disco foi recomputada).
          - "divergence": Badge `fail` + label textual "divergência" (servido ≠ disco).
          - "unverifiable": Badge `default` (neutro) + label textual "não-verificável" (sem snapshot no disco).
          - erro de fetch: texto de erro neutro (não alarme de domínio).
        O `<button>` deve ser acessível (elemento `<button>` nativo, texto visível; cor nunca é o único sinal —
        sempre há label textual ao lado do Badge, conforme a disciplina já em Frota.tsx:14-22 e o accessibility skill).

    Escopo cirúrgico: NÃO mexer em version-drift, MachineCard, App.tsx, nem no backend. Qualquer dívida fora
    do escopo vira marcador `// debt:` — não conserte agora.
  </action>
  <acceptance_criteria>
    - O arquivo modificado existe e não está vazio (gate de artefato — antifragile-gates):
      `test -s apps/cockpit/src/pages/Frota.tsx` exit 0.
    - Frota consome /verify (rota citada na UI): `grep -q "/verify" apps/cockpit/src/pages/Frota.tsx` exit 0.
    - Os 3 ESTADOS estão presentes no código (string-match dos discriminantes):
      `grep -q "verified" apps/cockpit/src/pages/Frota.tsx && grep -q "disk_epoch" apps/cockpit/src/pages/Frota.tsx` exit 0.
    - INVARIANTE não-verificável NUNCA é alarme — prova estrutural por exit-code de que o ramo do estado neutro
      referencia o token/variante neutro e não o de alarme. Gate: garantir que existe tratamento explícito de
      `disk_epoch` null como ramo separado:
      `grep -Eq "disk_epoch[^=]*(==|===|!=|!==)?[^=]*null|disk_epoch == null|disk_epoch === null" apps/cockpit/src/pages/Frota.tsx` exit 0.
    - NÃO houve edição do backend (read-only sobre /verify — R15-08 "endpoint completo, zero tela usa"):
      `git diff --name-only -- apps/cockpit/server/read.js | grep -q read.js` exit != 0
      (gate: `! (git diff --name-only -- apps/cockpit/server/read.js | grep -q read.js)`).
    - Build do SPA não quebra (typecheck + vite build): `cd apps/cockpit && npm run build` exit 0.
  </acceptance_criteria>
  <done>Frota tem botão "verificar" por máquina consumindo /verify; os 3 estados (verified/divergence/unverifiable) estão codificados a partir da dupla (verified, disk_epoch); backend intacto; build verde.</done>
</task>

<task type="auto">
  <name>Task 2: Prova no BROWSER dos 3 estados (regime runtime — Chrome DevTools MCP, não só curl)</name>
  <files>apps/cockpit/src/pages/Frota.tsx</files>
  <read_first>
    - apps/cockpit/vite.config.ts:20 (port 5273 strictPort — o SPA SEMPRE sobe nesta porta ou FALHA; o gate sabe a porta)
    - apps/cockpit/src/App.tsx:108 (Frota montada por estado local `screen === "frota"` — navegar até a aba "Frota" no SPA antes de capturar)
    - apps/cockpit/server/read.js:574 (a regra que produz cada estado: verified true/false e disk_epoch null/não-null — usada para entender o que o screenshot DEVE mostrar)
    - .claude/rules/ideiaos-common-antifragile-gates.md ("Dois regimes de verificação": estado-de-runtime/UI = render+screenshot+a11y-tree é legítimo, NÃO viola o gate por exit-code; mas exige critério explícito declarado)
  </read_first>
  <action>
    Provar no REGIME RUNTIME que a UI distingue os 3 estados — curl prova só o JSON, não o render. Sequência:

    (1) Subir o backend e o SPA em background (loopback):
        - `node apps/cockpit/server/read.js &` (após `node source/console/ingest.js` se o read-model precisar de dados).
        - `cd apps/cockpit && npm run dev &` (Vite strictPort 5273).
        Confirmar saúde por exit-code ANTES de abrir o browser:
        `curl -sf http://127.0.0.1:5273/ | grep -q 'id="root"'` exit 0 (SPA no ar) e
        `curl -sf http://127.0.0.1:3073/health | grep -q '"ok":true'` exit 0 (backend no ar).

    (2) Via Chrome DevTools MCP: navegar a `http://127.0.0.1:5273`, clicar na aba "Frota", clicar no botão
        "verificar" de uma máquina e capturar screenshot + accessibility-tree.
        - Estado VERIFICADO: para uma máquina cujo snapshot no disco bate com o servido (a maioria), o
          resultado deve mostrar "verificado" + "verificado há Xs". (Caso real testado: machine_id 52ae4ab0681a
          retornou `verified:true, disk_epoch=served_epoch`.)
        - Estado NÃO-VERIFICÁVEL: usar uma célula sem snapshot no disco (o /verify retorna `verified:false,
          disk_epoch:null`) e CONFIRMAR no screenshot/a11y-tree que o sinal é NEUTRO (label "não-verificável"),
          jamais um alarme vermelho. Esta é a invariante-piso do R15-08.
        - Estado DIVERGÊNCIA (alarme): se nenhuma célula divergir naturalmente, induzir o caso de forma
          controlada e EFÊMERA — apontar a UI a um endpoint mock que devolva `{verified:false, disk_epoch:<n>}`
          (ex. variável VITE_READ_PORT para um read.js de teste, ou um stub local), capturar o screenshot do
          alarme, e DESFAZER o stub (não deixar resíduo). NÃO alterar o read.js de produção.

    (3) Critério explícito declarado (exigência do regime-runtime): o screenshot+a11y-tree de cada estado
        DEVE conter o label textual correspondente ("verificado" / "não-verificável" / "divergência") — cor
        nunca é o único sinal. Registrar os 3 caminhos no SUMMARY com a descrição do que foi observado.

    Ao final, encerrar os processos de background (kill por PID/porta).
  </action>
  <acceptance_criteria>
    - SPA sobe e serve o root (exit-code, pré-condição do regime runtime):
      `curl -sf http://127.0.0.1:5273/ | grep -q 'id="root"'` exit 0.
    - Backend /verify responde o shape esperado por exit-code (sanidade do contrato consumido):
      `curl -sf "http://127.0.0.1:3073/verify?cell=$(curl -sf http://127.0.0.1:3073/fleet | grep -oE '[0-9a-f]{12}' | head -1)" | grep -Eq '"verified":(true|false)'` exit 0
      E `... | grep -q '"disk_epoch"'` exit 0 (o discriminante do 3º estado existe na resposta).
    - Prova de runtime (regime-UI, antifragile-gates "dois regimes"): screenshots dos 3 estados capturados via
      Chrome DevTools MCP, cada um exibindo o LABEL TEXTUAL do estado (verificado / não-verificável / divergência),
      anexados/descritos no SUMMARY. Critério: o estado não-verificável aparece NEUTRO (nunca alarme).
    - Sem resíduo: o stub usado p/ induzir divergência foi desfeito —
      `git diff --name-only -- apps/cockpit/server/read.js | grep -q read.js` exit != 0
      (gate: `! (git diff --name-only -- apps/cockpit/server/read.js | grep -q read.js)`).
  </acceptance_criteria>
  <done>Os 3 estados estão provados no browser (não só curl): verificado mostra carimbo "há Xs"; não-verificável é NEUTRO (nunca alarme); divergência é alarme. Backend intacto, sem resíduo de stub.</done>
</task>

</tasks>

<invariants>
Condições que o executor DEVE respeitar (piso, não-negociável):
1. **NÃO-VERIFICÁVEL ≠ FALHA.** `verified===false && disk_epoch==null` é NEUTRO — Badge `default`, label "não-verificável". NUNCA alarme. Ausência de snapshot no disco é falta de prova, não prova de divergência (spec/cockpit/spec.md:106-115; R15-08 frase explícita "não-verificável = neutro, NUNCA alarme").
2. **Backend read-only.** Zero edição em `apps/cockpit/server/read.js` — o `/verify` já é completo e hardened (linhas 517-585). R15-08: "zero tela consome" → a lacuna é só de UI. Gate prova por `git diff`.
3. **Shape real, nunca inventado.** Os campos consumidos são EXATAMENTE `{verified, disk_epoch, served_epoch, recomputed_at_epoch, cell, source}` (verificado ao vivo). Não assumir `disk`, `epoch`, `ok` ou outro nome (Article IV — No Invention).
4. **Recompute-from-disk no instante do clique.** O fetch a `/verify` acontece ON-DEMAND (no clique), não em cache nem no load inicial — o backend recomputa do disco (A6 Trust-Rate). O "verificado há Xs" vem de `recomputed_at_epoch`, não de `last_seen_epoch`.
5. **Cor nunca é o único sinal.** Todo estado tem label textual ao lado do Badge (WCAG / disciplina já em Frota.tsx:14-22 e MachineCard.tsx). Provado no a11y-tree (Task 2).
6. **Regime de verificação correto.** Artefato-de-arquivo (build, arquivo gravado) → exit-code `test -s`/`npm run build`. Estado-de-runtime/UI (os 3 estados renderizados) → render+screenshot+a11y-tree (legítimo, não viola o gate — antifragile-gates "dois regimes"). curl NÃO é suficiente para fechar R15-08 (prova só o JSON).
7. **Escopo cirúrgico.** Tocar SÓ `Frota.tsx`. Não refatorar version-drift, MachineCard, App.tsx, badge.tsx, index.css (os tokens `--status-success/--status-warning` já existem). Dívida fora de escopo → marcador `// debt:`.
8. **Autosync pausado antes / retomado depois** (autosync-race). Esta fase NÃO é auto-modificante; pause normal basta. NUNCA `git push`/`gh pr` (agent-authority — @devops exclusivo).
9. **Loopback preservado.** Todo fetch é `127.0.0.1` (API_BASE Frota.tsx:33); nada de host arbitrário. O canal /verify é GET com CORS já fixado no server a `127.0.0.1:5273`.
</invariants>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| browser (não-confiável) -> read.js /verify | só 127.0.0.1 alcança; /verify é GET metadata-only; o MID é validado no server (^[0-9a-f]{12}$) e o git roda por argv-array sem shell |
| /verify -> UI (Frota) | a UI consome metadata (epochs + boolean); nenhum valor de segredo transita; o estado não-verificável não pode ser exibido como falha (honestidade) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-A06-S | Spoofing / Honestidade | render do estado não-verificável | mitigate | invariante-piso: disk_epoch==null => NEUTRO, nunca alarme; provado no a11y-tree (Task 2) — UI não pode "fabricar" divergência onde só há ausência de prova |
| T-A06-T | Tampering | input do botão -> /verify | mitigate (herdado) | machine_id vem do /fleet e o server revalida MID_RE + argv-array sem shell (read.js:526,562-565); a UI não interpola nada além do machine_id da linha |
| T-A06-I | Information Disclosure | payload /verify exibido | mitigate | /verify é metadata-only por construção (epochs + boolean); seguro por construção, não por escaneamento (R15-08) — nenhum valor de segredo no shape |
</threat_model>

<verification>
- Artefato + build: `test -s apps/cockpit/src/pages/Frota.tsx` exit 0; `cd apps/cockpit && npm run build` exit 0.
- Wiring: `grep -q "/verify"` e os discriminantes `verified` + `disk_epoch` presentes em Frota.tsx (exit 0).
- Backend intacto: `! (git diff --name-only -- apps/cockpit/server/read.js | grep -q read.js)` exit 0.
- Runtime (regime-UI): SPA serve root (`curl ...:5273 | grep id="root"` exit 0); 3 estados provados por screenshot+a11y-tree no browser, com o estado não-verificável NEUTRO.
</verification>

<success_criteria>
- O botão "verificar" na Frota consome /verify on-demand e distingue os 3 estados (verificado / divergência-alarme / não-verificável-neutro) a partir da dupla (verified, disk_epoch).
- O estado não-verificável NUNCA é alarme (invariante-piso provada no browser).
- Backend /verify intacto (read-only); build verde; loopback preservado; escopo cirúrgico (só Frota.tsx).
</success_criteria>

<goal_backward>
## Meta (goal-backward)

**Objetivo final:** R15-08 fechado — a Frota consome o `/verify` (já hardened) com um botão que distingue 3 estados honestos, provado no browser.

Trabalhando de trás pra frente:
- Para R15-08 estar **fechado**, é preciso a PROVA no browser dos 3 estados (Task 2) — curl prova só o JSON, e o requisito exige o regime runtime.
- Para provar no browser, é preciso o **botão + render dos 3 estados** codificado em Frota.tsx (Task 1), consumindo o shape REAL `(verified, disk_epoch)`.
- Para codificar os 3 estados sem inventar, foi preciso **ler o contrato real** do /verify (read.js:517-585) e TESTÁ-LO ao vivo (feito: shape confirmado `{verified, disk_epoch, served_epoch, recomputed_at_epoch, cell, source}`).
- O backend já está pronto (R15-08: "endpoint completo e hardened, zero tela usa") → a única lacuna é UI, e ela é **read-only** sobre o backend.

A invariante que carrega o requisito é a 3ª linha: **não-verificável = neutro, nunca alarme**. Tudo no plano (tipos, ramo explícito de `disk_epoch==null`, prova no a11y-tree) existe para garantir que ausência de prova nunca seja pintada como prova de falha.
</goal_backward>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-06-botao-verificar-SUMMARY.md` when done
</output>
