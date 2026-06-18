---
phase: B-sandbox
plan: B-01
type: experiment            # NÃO é build de código — é medição empírica gateada
wave: 1
depends_on: []              # independente de A; mas é o GATE de C e D
autonomous: false           # EXIGE go humano + deny-lift @devops (mutação outward-facing, queima crédito)
requirements: [R10-06]
verified_by: "wf_ad9c6be1-327 (3 lentes adversariais: contenção/medição/custo) — v2 incorpora todos os achados high/critical"
files_modified:
  - .claude/settings.json                                      # janela deny->ask (Task 0) + restauração (Task 6) — TEMPORÁRIO
  - .planning/milestones/v10-phases/B-sandbox/B-01-WINDOW-STATE.json  # estado janela-aberta (recovery)
  - docs/research/2026-06-17-lovable-mcp-integration-plan.md   # §2.5 — gravar resultados + veredito
  - .planning/milestones/v10-phases/B-sandbox/B-01-SUMMARY.md   # (criar ao concluir)
must_haves:
  truths:
    - "As suposições A1-A3 da §2.5 estão respondidas com EVIDÊNCIA observável (sha, timestamp, diff), ou explicitamente marcadas INDETERMINADAS — e indeterminado conta a favor de BLOQUEAR, nunca de liberar"
    - "Existe um veredito binário derivado de uma TABELA-VERDADE (não interpretativo): LIBERAR ou BLOQUEAR publish/send_message para as Fases C/D"
    - "Nenhuma mutação tocou um produto de produção nem o DB/connectors do produto-pai — isolamento do fork confirmado por leitura ANTES de qualquer escrita"
    - "A janela de permissão foi fechada — deny reaplicado e confirmado por assert binário (deny==19 E ask-lovable==0 E allow-lovable==0 E server em disabledMcpServers) — OU o panic-close foi documentado e executado em caminho de abort"
  artifacts:
    - path: "docs/research/2026-06-17-lovable-mcp-integration-plan.md"
      provides: "§2.5 atualizada com medições + veredito de liberação/bloqueio do write-path"
      contains: "VEREDITO"
  key_links: []
---

<objective>
Medir, **sem risco em produção**, as suposições não-validadas que decidem se o write-path da v10 (Fases C/D) é seguro. A doc do MCP **não documenta** como/quando um commit do agente Cloud chega ao mirror GitHub. Toda escrita (`send_message`, `deploy_project`, `publish`) está **demovida** até este experimento passar.

Purpose: se o agente Cloud commitar num repo interno desacoplado do GitHub, ou se `deploy_project` publicar de um estado interno em vez de `main`, então qualquer governança que o IdeiaOS imponha via Git é **ignorada** — e `publish` deve permanecer bloqueado. Este experimento mede isso num **fork descartável** (`remix_project`) — zero risco em prod, custo = créditos de build (com teto).

Output: §2.5 do dossiê com A1-A3 respondidas (evidência) + um **veredito binário por tabela-verdade**; fork contido e deny reaplicado (binário).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@docs/research/2026-06-17-lovable-mcp-integration-plan.md
@.planning/milestones/v10-REQUIREMENTS.md
@.planning/milestones/v10-ROADMAP.md
@docs/decisions/v10-lovable-mcp-readfirst-containment.md
@source/rules/lovable/mcp-protocol.md
@source/skills/lovable-mcp/SKILL.md
</context>

<gates>
**Esta fase NÃO é autônoma. Antes da Task 0, TODAS as condições abaixo devem ser verdadeiras:**

1. **Go humano explícito** — `remix_project`/`send_message`/`deploy_project` criam um projeto real na conta Lovable e queimam crédito. Não há `delete_project` no MCP -> irreversível por MCP. Exigem "pode rodar a Fase B" explícito.
2. **Deny-lift controlado (@devops)** — hoje o `.claude/settings.json` do IdeiaOS **nega as 19 tools mutantes** (`deny=19`) + `disabledMcpServers`. As mutações estão **harness-bloqueadas agora** (a contenção funciona). @devops promove de `deny`->`ask` SÓ as **5-6 tools do experimento** (ver Task 0) e reaplica `deny` ao fim. Nunca `allow`.
3. **🔴 BLOQUEANTE (promovido de "recomendado" pela verificação adversarial): os 2 toggles de painel do usuário** (`mcp_enabled` OFF em "Grupo IDeia - Projects" + "Dev's Lovable") **DEVEM estar feitos ANTES de abrir a janela.** O OAuth é account-level (~1.640 projetos no alcance). Não se abre uma janela `ask` de tools mutantes account-wide enquanto o token ainda alcança os 1.622 projetos seed — um `project_id` errado durante a janela seria catastrófico e irreversível. "Conter antes de escrever" é pré-condição dura desta fase.
4. **Alvo = fork na workspace dev** — `remix_project` de um produto **pouco ativo** (candidato: cfoai) cria o fork em "Grupo Ideia - Dev" (`2NHPnABxF0jdSX3qVLCw`). Alternativa mais segura se a Task 1b achar backend compartilhado: remixar um `list_template_projects` descartável (sem backend de prod). Nunca remixar para fora da pasta de trabalho.
</gates>

<preflight>
**Read-only (sem janela aberta, tools já permitidas):**
- **Saldo de crédito:** `get_workspace(2NHPnABxF0jdSX3qVLCw)` -> registrar saldo. Definir **TETO** do experimento (ex.: abortar se saldo < N; máx M mensagens). Sem teto, não abrir janela.
- **IDs de prod a proteger (guard):** resolver via `list_projects(folder_id)` e registrar os 4 IDs de produção (nfideia `bf83d98a-…`, ideiapartner `afce7743-…`, cfoai `0e911cfd-…`, ideia-partner-hub `748a31c2-…`) para a barreira anti-confusão das Tasks 2-3.
</preflight>

<tasks>

<task type="manual-gate">
  <name>Task 0: Abrir a janela controlada + persistir estado para recovery</name>
  <files>.claude/settings.json (temporário), B-01-WINDOW-STATE.json</files>
  <action>
Confirmados os 3 gates: @devops move de `permissions.deny` -> uma lista `ask` as **5 tools do experimento**: `remix_project`, `send_message`, `deploy_project`, **`set_project_visibility`, `move_projects_to_folder`** (as 2 últimas são o cleanup da Task 6 — estavam fora da janela na v1, seriam harness-bloqueadas: o achado CRÍTICO da verificação). `query_database` (6ª) SÓ se a Task 5 rodar E a Task 1b confirmar DB isolado. As demais 13-14 permanecem em `deny`. Gravar `B-01-WINDOW-STATE.json` com o conjunto EXATO promovido + timestamp, para o recovery reverter sem depender da memória de conversa.
  </action>
  <verify>
    <automated>python3 -c "import json;d=json.load(open('.claude/settings.json'));dn=[x for x in d.get('permissions',{}).get('deny',[]) if '6f530143' in x];print('deny lovable:',len(dn));assert len(dn) in (13,14),'janela inesperada (esperado 14 com 5 promovidas, 13 com query_database)'"</automated>
  </verify>
  <done>Janela aberta com 5-6 tools em `ask`; `B-01-WINDOW-STATE.json` gravado; deny lovable em 13-14.</done>
</task>

<task type="auto">
  <name>Task 1: Criar fork descartável (remix_project) + persistir id IMEDIATAMENTE</name>
  <action>
`remix_project(<cfoai_id>)` -> fork `F`. **IMEDIATAMENTE** (antes de qualquer outra mutação) gravar `F.project_id` em `B-01-WINDOW-STATE.json` — se a sessão morrer aqui, a contenção/deleção manual ainda é possível. Registrar `F.latest_commit_sha` = **sha_0** e a workspace/folder de destino (confirmar = dev).
  </action>
  <verify>
    <automated>echo "registrar: F.project_id (em WINDOW-STATE.json), sha_0, destino=dev"</automated>
  </verify>
  <done>Fork F na workspace dev; F.project_id persistido ANTES de qualquer escrita subsequente.</done>
</task>

<task type="auto">
  <name>Task 1b: [GATE read-only] Isolamento do backend + herança de gitsync</name>
  <action>
ANTES de qualquer `send_message`/`deploy`/`query_database` (tools read-only, já permitidas): `get_project(F)` + `get_database_status(F)` + `list_connections(F)`/`list_connectors(F)`. **Confirmar binariamente:**
- (a) **DB/connectors do fork são DISTINTOS do cfoai-pai (ou inexistentes).** Se o fork COMPARTILHA o Supabase/connectors de prod -> a Task 5 (`query_database`) NÃO roda (seria SELECT em prod) e o deploy é tratado como tocando backend real (abortar deploy ou trocar alvo p/ template descartável).
- (b) **gitsync_github herdado?** Se NÃO -> o fork não reproduz o mirror de produção: A1/A3 ficam **INDETERMINADAS para o caso real**; registrar veredito condicional "BLOQUEAR por falta de evidência" (não maquiar medição de namespace interno como resposta sobre o mirror).
  </action>
  <verify>
    <automated>echo "binário: fork DB != pai (sim/não); connectors isolados (sim/não); gitsync_github herdado (sim/não)"</automated>
  </verify>
  <done>Isolamento confirmado/refutado; Task 5 condicionada; ramo de gitsync decidido (medir vs BLOQUEAR-por-falta-de-evidência).</done>
</task>

<task type="auto">
  <name>Task 2: [A1 - TRAVA TUDO] Namespace + timing do mirror (com timeout)</name>
  <action>
Guard anti-confusão: assert `target == F.project_id` E `target != cada um dos 4 IDs de prod` antes de chamar `send_message`. Disparar UMA edição identificável: `send_message(F, "adicione // SANDBOX-PROBE-<n> no topo do README")`. Marcar **T_send**; poll `get_message(id)` (intervalo 5s, **deadline 10min**) até `completed` -> **T_complete**. Registrar sha_1 + `list_edits(F)[0]`. Se F tem mirror: verificar **sha_1 ∈ git log** do mirror; medir lag = poll `origin/main` (5s, **deadline 10min**) até sha_1 aparecer.
**Ramo negativo (não é falha, é resultado):** se sha_1 NÃO propagar até o deadline -> `lag = INDETERMINADO/não-propagou` = evidência de **mirror desacoplado** -> A1 já vota BLOQUEAR.
  </action>
  <verify>
    <automated>echo "evidência: sha_1; T_send/T_complete/T_github OU lag=INDETERMINADO; sha_1 ∈ git log? (sim/não)"</automated>
  </verify>
  <done>A1 respondida (mirror vs interno + lag finito) OU INDETERMINADO -> BLOQUEAR.</done>
</task>

<task type="auto">
  <name>Task 3: [A2] deploy_project lê de main ou do interno? (divergência determinística)</name>
  <action>
Criar divergência main×interno **independente do lag** (corrige a dependência circular com a Task 2): via o plano-GitHub do IdeiaOS, **`git push` um commit que a Cloud NÃO originou** ao `origin/main` do mirror de F (ex.: editar README com marca `GIT-ONLY-PROBE-<n>`). Guard anti-confusão antes de `deploy_project(F)`. Publicar e **ler o `preview_url` com cache-bust** (`?t=<epoch>`, `Cache-Control:no-cache`), confirmando o status de deploy via `get_project(F)` ANTES do fetch (descarta CDN stale).
**Binário:** bundle contém `GIT-ONLY-PROBE` -> deploy lê de **main**; contém só o `SANDBOX-PROBE` do agente Cloud -> lê do **interno** -> `publish` IGNORA gates IdeiaOS -> BLOQUEAR.
  </action>
  <verify>
    <automated>echo "evidência: bundle (cache-busted) contém GIT-ONLY-PROBE? (main) ou só SANDBOX-PROBE? (interno)"</automated>
  </verify>
  <done>A2 respondida binariamente; método de divergência não depende do lag.</done>
</task>

<task type="auto">
  <name>Task 4: [A3] commit_sha do list_edits casa com git log (com limiar)</name>
  <action>
Cruzar os `commit_sha` de `list_edits(F)` contra `git log` do mirror, **normalizando para SHA-cheio** antes do grep. **Regra de decisão fixa:** A3 **PASS sse 100%** dos commit_sha de edits que JÁ propagaram (`completed` + dentro do lag medido na Task 2) aparecem em `git log origin/main`. Edits ainda dentro da janela de lag NÃO contam contra. Qualquer SHA `completed`+fora-do-lag ausente do git log = **FAIL** -> `detect-hotfix` (Fase A) precisa de ajuste de namespace.
  </action>
  <verify>
    <automated>echo "evidência: % de commit_sha propagados encontrados no git log (normalizado); PASS sse 100%"</automated>
  </verify>
  <done>A3 PASS/FAIL por limiar explícito; impacto no detect-hotfix registrado.</done>
</task>

<task type="auto">
  <name>Task 5: [A4 - opcional, condicionado] query_database multi-statement</name>
  <action>
**SÓ se** `query_database` foi promovido (Task 0) E a Task 1b confirmou **DB do fork isolado de prod.** Probe read-only com SQL FIXO `information_schema`: aceita múltiplos statements por `;`? (informa o anti-DML do `schema-check` da Fase C). Concorrência de `send_message` = **deferida** (exige 2 msgs concorrentes, risco/custo extra) — não-medida, não bloqueia o veredito de B.
  </action>
  <verify>
    <automated>echo "evidência: query_database aceita ';'-separated? (sim/não) — ou PULADO (DB não-isolado)"</automated>
  </verify>
  <done>A4 registrado ou explicitamente pulado por não-isolamento.</done>
</task>

<task type="manual-gate">
  <name>Task 6: Conter o fork + REAPLICAR o deny (fechar a janela) — assert endurecido</name>
  <files>.claude/settings.json (restaurar), B-01-SUMMARY.md</files>
  <action>
Contenção (sem `delete_project`): `set_project_visibility(F, private)` + `move_projects_to_folder(F -> "_sandbox-trash")`. **Verificar se o `preview_url` ainda responde** pós-`private` (visibility no projeto pode NÃO despublicar um deploy já feito) e registrar o subdomínio público no SUMMARY. Registrar em `B-01-SUMMARY.md` (seção durável "forks pendentes de deleção manual") **F.project_id + preview_url** para o usuário deletar/despublicar no painel. DEPOIS: @devops restaura TODAS as tools promovidas (`ask`->`deny`).
  </action>
  <verify>
    <automated>python3 -c "import json;p=d=json.load(open('.claude/settings.json'));perm=d.get('permissions',{});dn=[x for x in perm.get('deny',[]) if '6f530143' in x];ask=[x for x in perm.get('ask',[]) if '6f530143' in x];al=[x for x in perm.get('allow',[]) if '6f530143' in x];dis='6f530143-e779-405d-bf42-190cae4e231b' in d.get('disabledMcpServers',[]);assert len(dn)==19 and len(ask)==0 and len(al)==0 and dis,f'FALHA janela aberta: deny={len(dn)} ask={len(ask)} allow={len(al)} disabled={dis}';print('OK: janela fechada — deny=19, ask=0, allow=0, disabled=True')"</automated>
  </verify>
  <done>Fork contido + preview_url checado + ids no SUMMARY; assert binário endurecido passa (deny=19 E ask=0 E allow=0 E disabled).</done>
</task>

</tasks>

<recovery>
**Fail-safe — rodar SE qualquer Task 1-5 abortar (timeout do agente Cloud, crash, sessão encerrada):**
1. Ler `B-01-WINDOW-STATE.json` (conjunto de tools promovidas + F.project_id) — fonte de verdade independente da conversa.
2. **Re-fechar a janela:** restaurar as tools promovidas para `deny` no `.claude/settings.json` + reconfirmar `disabledMcpServers`; rodar o assert endurecido da Task 6.
3. **Conter o fork órfão:** se F.project_id existe, `set_project_visibility(private)` + mover p/ `_sandbox-trash` (precisa das tools de contenção promovidas — por isso elas entram na janela na Task 0); senão, registrar F.project_id como **pendência de deleção manual** no SUMMARY.
4. Idealmente a abertura/fechamento da janela é um **script único `open|close`** parametrizado (não edição manual), para o close ser idempotente em qualquer caminho de saída.
**Invariante:** nenhuma sessão termina com a janela aberta. O fechamento roda no happy path (Task 6) E no abort (este bloco).
</recovery>

<verification>
- A1/A2/A3 respondidas com evidência observável OU marcadas INDETERMINADAS (que votam BLOQUEAR) — Tasks 2-4.
- Isolamento do backend do fork confirmado por leitura ANTES de qualquer escrita — Task 1b.
- Contenção pós-experimento + reaplicação do deny provadas por exit-code binário endurecido (deny=19, ask=0, allow=0, disabled) — Task 6 / recovery. Princípio antifrágil.
- Veredito binário por tabela-verdade gravado no SUMMARY e espelhado na §2.5 do dossiê.
</verification>

<success_criteria>
- A1 (mirror namespace/timing) · A2 (deploy source) · A3 (list_edits×git log) respondidas com evidência ou explicitamente INDETERMINADAS; A4 (query_database) registrado ou pulado.
- **Veredito por TABELA-VERDADE (mecânico, não interpretativo):** BLOQUEAR se `(A2=interno)` OU `(A1=desacoplado/lag-indeterminado)` OU `(A3=FAIL)` OU `(fork não isolou backend)`. LIBERAR-sob-gates-da-Fase-D apenas se `A2=main` E `A1=acoplado-com-lag-finito` E `A3=PASS`.
- Fork contido + deny reaplicado (assert endurecido) + F.project_id + preview_url registrados como pendência de deleção manual do usuário.
- Custo: estimativa a-priori (nº de mutações cobradas) + saldo pré/pós (`get_workspace`) + teto respeitado.
</success_criteria>

<notes>
## Por que esta fase é autonomous:false
Diferente das fases A/C de build (código local, reversível por `git`), a Fase B faz **mutações outward-facing na conta Lovable** (cria projeto, dispara o agente Cloud, publica), queima crédito e **não tem `delete_project`** no MCP. A contenção atual (deny=19 no IdeiaOS) bloqueia estas tools agora — feature, não obstáculo: a janela é deliberada, mínima (5-6 tools) e fechada ao fim (happy path + recovery).

## Achados da verificação adversarial (wf_ad9c6be1-327) incorporados nesta v2
- **CRÍTICO:** as 2 tools de cleanup (`set_project_visibility`/`move_projects_to_folder`) estavam fora da janela -> cleanup seria harness-bloqueado. **Corrigido** (entram na Task 0).
- **HIGH:** sem fail-safe em abort -> bloco `<recovery>` + `B-01-WINDOW-STATE.json`.
- **HIGH:** sem teto/saldo de crédito -> `<preflight>` com `get_workspace` + teto.
- **HIGH:** fork podia compartilhar DB/connectors de prod -> Task 1b read-only de isolamento, gate da Task 5.
- **HIGH:** fork sem gitsync não responde A1/A3 do caso real -> gate na Task 1b (BLOQUEAR-por-falta-de-evidência, não maquiar).
- **HIGH:** Task 2 sem timeout/ramo negativo -> deadline 10min + INDETERMINADO=BLOQUEAR.
- **HIGH:** Task 3 circular com a 2 -> divergência via `git push` determinístico + cache-bust.
- **MEDIUM:** toggles do usuário promovidos a **gate BLOQUEANTE** (Gate 3).
- **MEDIUM:** confusão de project_id -> guard anti-prod-id antes de cada mutação.
- **MEDIUM/LOW:** Task 4 limiar 100%; Task 6 assert endurecido (deny=19 E ask=0 E allow=0 E disabled); preview_url despublicação verificada.

## Ordem limpa
toggles de painel do usuário (Gate 3, agora BLOQUEANTE) -> preflight (saldo+IDs) -> Task 0 (abrir janela) -> 1/1b/2-5 -> Task 6 (fechar + conter) — ou `<recovery>` em qualquer abort.
</notes>

<output>
Criar `.planning/milestones/v10-phases/B-sandbox/B-01-SUMMARY.md` ao concluir, com: tabela A1-A4 (resposta + evidência), a **TABELA-VERDADE do VEREDITO**, custo (estimado/real), e a seção durável "forks pendentes de deleção manual" (project_id + preview_url). Espelhar o veredito na §2.5 do dossiê.
</output>
