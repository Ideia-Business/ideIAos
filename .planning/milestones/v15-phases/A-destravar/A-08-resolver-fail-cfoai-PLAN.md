---
phase: "v15-A"
plan: "A-08"
type: execute
wave: 2
depends_on: []
requirements: [R15-06]
gated_on_owner_decision: false   # RESOLVIDO 2026-06-25
owner_decision: "A — remediar os 19 deny no prefixo do server ATIVO (claude_ai_Lovable) no cfoai. Branch B (allowlist §7e INFO-datado) DESCARTADA. O fix §7e prefix-aware (Task 3) permanece INCONDICIONAL nos 4 produtos."
must_haves:
  truths:
    - "O §7e do idea-doctor (scripts/idea-doctor.sh:418-503) conta um PREFIXO FIXO `6f530143` (linha 427, arg do python3 embutido) — não o prefixo do server Lovable ATUALMENTE ATIVO (`claude.ai Lovable - gustavolpaiva`, tools `mcp__claude_ai_Lovable_-_gustavolpaiva__*`). VERIFICADO por exit-code: deny_OLD(6f530143)=19 e deny_NEW(claude_ai_Lovable)=0 nos QUATRO produtos (cfoai, ideiapartner, nfideia, lapidai). Logo o §7e dá PASS pelos 19 deny do id-velho enquanto deploy/remix/query_database do server ATIVO permanecem NÃO-denegados — verde-falso."
    - "O verde-falso é do INSTRUMENTO DE MEDIÇÃO (o gate conta o prefixo errado) e afeta os 4 produtos por igual — é ORTOGONAL à decisão A/B do dono (que é sobre como CONTER o cfoai). Logo o fix prefix-aware do §7e DEVE ser INCONDICIONAL (Task 3, antes da bifurcação A/B). Sob OWNER_CHOICE=B sem esse fix, nfideia e lapidai seguiriam com PASS falso e o verde-falso que R15-06 manda matar PERSISTIRIA."
    - "O requisito apresenta DOIS caminhos para o cfoai (A: remediar os 19 deny no prefixo correto; B: allowlist por-nome-auditável INFO-datado no §7e). O plano os apresenta AMBOS como branches GATED na decisão do dono — NÃO escolhe por ele."
    - "cfoai é projeto PARTICULAR do Gustavo (memória project-cfoai-particular) — a decisão A vs B é DELE."
    - "Persistência precisa SOBREVIVER (learning uncommitted-security-config-ephemeral). VERIFICADO por git: cfoai e nfideia têm `.claude/settings.json` TRACKED (branch main → commit de IA vai p/ branch work, NUNCA main automática); ideiapartner tem `.claude/settings.json` GITIGNORED (não-tracked) → já é local-only, persiste por reclone-manual; lapidai está na branch `work` com settings.json tracked."
    - "ideiapartner NÃO migrou nada para settings.local.json: seu `.claude/settings.json` (gitignored) JÁ tem deny=19 no prefixo velho. Re-materializar = ADICIONAR as 19 entries do prefixo novo no MESMO arquivo (que é gitignored=local-only ali). O §7e conta via `max(settings.json, settings.local.json)`, então o arquivo gitignored é contado."
  artifacts:
    - path: ".planning/milestones/v15-phases/A-destravar/A-08-PROBE.txt"
      provides: "Prova por exit-code de qual prefixo o §7e conta vs. o prefixo do server ATIVO (gate-zero anti-verde-falso), nos 4 produtos"
      contains: "PREFIX_ACTIVE="
    - path: "scripts/idea-doctor.sh"
      provides: "§7e prefix-aware INCONDICIONAL (Task 3) + caminho A (deny no prefixo ativo) OU caminho B (allowlist INFO-datado), conforme decisão do dono"
      contains: "7e"
  key_links:
    - from: "scripts/idea-doctor.sh:427"
      to: "prefixo do server MCP Lovable ATIVO"
      via: "argumento do python3 embutido (hoje hardcoded `6f530143`)"
      pattern: "6f530143"
    - from: "/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json"
      to: "permissions.deny (19 tools mutantes)"
      via: "prefixo das entries deve casar o formato exato mcp__claude_ai_Lovable_-_gustavolpaiva__<tool> do server ATIVO"
      pattern: "permissions"
---

<objective>
Resolver de forma DURÁVEL o FAIL crônico do gate Lovable-MCP (§7e do `scripts/idea-doctor.sh`) sobre o
cfoai-grupori, eliminando antes o **verde-falso de prefixo** que o requisito alerta. Hoje o §7e conta o
prefixo FIXO `6f530143` (o connector-id ANTIGO; `scripts/idea-doctor.sh:427`), mas o server MCP da Lovable
ATUALMENTE ATIVO se registra como `claude.ai Lovable - gustavolpaiva` (`https://mcp.lovable.dev`) e suas
tools usam o prefixo `mcp__claude_ai_Lovable_-_gustavolpaiva__*`. VERIFICADO por exit-code: os 19 deny de
TODOS os 4 produtos estão no prefixo VELHO (deny_OLD=19, deny_NEW=0 em cfoai, ideiapartner, nfideia,
lapidai) — então o §7e dá `pass` enquanto `deploy_project`/`remix_project`/`query_database` do server
ATIVO ficam NÃO-denegados. O gate verde mente.

R15-06 exige: (1) provar por EXIT-CODE qual prefixo o §7e conta vs. o do server ativo, nos 4 produtos;
(2) **tornar o §7e prefix-aware de forma INCONDICIONAL** — esse é o fix do INSTRUMENTO de medição,
ortogonal à decisão A/B (sem ele, nfideia e lapidai seguem com PASS falso mesmo sob B); (3) deixar o dono
decidir, PARA O CFOAI, entre **caminho A** (remediar os 19 deny no prefixo do server ativo — recomendado)
e **caminho B** (allowlist por-nome-auditável no §7e: INFO datado, NUNCA um FAIL→OK mudo); (4) persistir
de forma sobrevivente; (5) re-materializar ideiapartner (deny do prefixo NOVO=0).

Purpose: um FAIL ignorado normaliza ignorar FAILs E bloqueia o gate SOAK futuro do v15. Este plano NÃO
empurra git (apenas @devops empurra) e NÃO escolhe A ou B pelo dono — ele PROVA o estado, CONSERTA O
INSTRUMENTO (prefix-aware, incondicional), EXECUTA o caminho que o dono escolher PARA O CFOAI, e GATEIA
a persistência por exit-code.

Output: `A-08-PROBE.txt` (prova do prefixo, 4 produtos) + §7e prefix-aware INCONDICIONAL + (branch A)
settings.json/local.json com deny no prefixo ATIVO + ideiapartner re-materializado; OU (branch B) §7e com
allowlist INFO-datado por-nome para o cfoai (os demais já contidos pelo prefix-aware).

**GOTCHA que SOBREPÕE a memória v10:** a memória `project-lovable-mcp-v10-candidate` afirma "5/5 deny=19
persistido" — isso era POINT-IN-TIME para o prefixo `6f530143`. Verificado HOJE por exit-code: o deny do
prefixo NOVO (`claude_ai_Lovable`) = **0 em cfoai, ideiapartner, nfideia, lapidai**. A memória é contexto
histórico (anti-injection): a verdade viva é a sonda da Task 0.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@scripts/idea-doctor.sh
@source/rules/lovable/mcp-protocol.md
</context>

<owner_decision_gate>
ESTE PLANO É GATED **na contenção do cfoai** (A vs B). O fix prefix-aware do §7e (Task 3) é INCONDICIONAL
e NÃO depende dessa escolha — corrige o instrumento de medição para os 4 produtos. Antes da Task 4, o
executor DEVE apresentar ao dono (Gustavo) o resultado da Task 0 (PROBE) e a escolha binária abaixo. NÃO
escolher por ele. Registrar a escolha como variável `OWNER_CHOICE`.

| Caminho | O que faz (para o CFOAI) | Trade-off | Recomendação do requisito |
|---------|--------------------------|-----------|---------------------------|
| **A — Remediar os 19 deny** | Adiciona as 19 entries de deny no cfoai (e re-materializa ideiapartner) usando o prefixo do server ATIVO provado na Task 0 | Mais trabalho; contém de fato a capability (deploy/db-write bloqueados ao vivo) | **RECOMENDADA** |
| **B — Allowlist por-nome no §7e** | Adiciona ao §7e uma allowlist auditável e DATADA: cfoai aparece como **INFO** ("FAIL aceito pelo dono em AAAA-MM-DD, cfoai é particular"), NUNCA convertendo o FAIL em OK mudo | Menos trabalho, mas a capability do cfoai segue NÃO-contida — risco aceito explicitamente, com trilha datada | aceitável p/ projeto particular |

Nota importante: sob **qualquer** escolha, nfideia e lapidai são contidos por outro movimento — sob A, recebem deny no prefixo novo (housekeeping fora do escopo R15-06 → marcar, não consertar aqui, salvo se o dono pedir); o que R15-06 garante é que o §7e prefix-aware (Task 3) PARA DE MENTIR sobre eles (passam a contar BAD honestamente até receberem o deny novo, em vez de PASS falso). O cfoai é o único alvo de contenção DESTE plano; ideiapartner é re-materializado sob A por ter regredido junto.

Condição inviolável de B: NUNCA `FAIL→OK` silencioso. O verdict do §7e p/ cfoai sob B deve ser `info`
(amarelo/cinza datado), distinguível de um `pass` real, e referenciar a data + razão.
</owner_decision_gate>

<tasks>

<task type="auto">
  <name>Task 0 (GATE-ZERO, anti-verde-falso): Provar por exit-code qual prefixo o §7e conta vs. o do server ATIVO, nos 4 produtos</name>
  <files>.planning/milestones/v15-phases/A-destravar/A-08-PROBE.txt</files>
  <read_first>
    - scripts/idea-doctor.sh:418-503 (§7e completo) e :427 (o python3 é chamado com o arg literal `6f530143` como `prefix`; `deny_count` em :433-439 conta entries com `prefix in x`; `count = max(sj, sl)` em :473)
    - source/rules/lovable/mcp-protocol.md:35-37 (a própria rule já AVISA: "Se o seu cliente registrar o servidor sob outro id/nome, ajuste o prefixo para casar — leia-o da lista de tools do MCP")
    - /Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json (as 19 entries de deny — confirmar o prefixo gravado)
  </read_first>
  <action>
    Gerar `A-08-PROBE.txt` capturando, de forma reproduzível e binária:
    (a) PREFIX_DOCTOR = o prefixo que o §7e conta hoje:
        `grep -oE '"6f530143"' scripts/idea-doctor.sh | head -1` → literal `6f530143` (o arg do python3 em :427).
    (b) PREFIX_ACTIVE = o prefixo do server Lovable ATIVO. Derivar do nome do server registrado:
        `claude mcp list 2>/dev/null | grep -i lovable` → nome `claude.ai Lovable - gustavolpaiva`
        (VERIFICADO: server `https://mcp.lovable.dev`, status Connected). O prefixo de tool correspondente é
        `mcp__claude_ai_Lovable_-_gustavolpaiva__` (substituição de espaços/pontos por `_`, conforme as tools
        deferidas `mcp__claude_ai_Lovable_-_gustavolpaiva__deploy_project`). Registrar o slug-âncora
        `claude_ai_Lovable` (substring estável do prefixo ativo) e o FORMATO completo
        `mcp__claude_ai_Lovable_-_gustavolpaiva__`.
    (c) Para CADA um dos 4 produtos (cfoai-grupori, ideiapartner, nfideia, lapidai): DENY_OLD = quantos deny
        casam o prefixo VELHO; DENY_NEW = quantos casam o slug NOVO — via o MESMO `python3` de contagem do §7e
        (deny_count sobre settings.json E settings.local.json, registrando `max`), parametrizado pelos dois
        prefixos. (Estado conhecido a confirmar: OLD=19, NEW=0 nos quatro.)
    Escrever no arquivo as linhas `PREFIX_DOCTOR=...`, `PREFIX_ACTIVE=...`, e por produto
    `<REPO>_DENY_OLD=...` / `<REPO>_DENY_NEW=...`, mais `VERDE_FALSO=<sim|nao>` (sim se ALGUM produto tem
    DENY_NEW < 19 enquanto o §7e contaria OK pelo velho). NÃO escrever nenhum settings ainda; só provar.
  </action>
  <acceptance_criteria>
    - `test -s .planning/milestones/v15-phases/A-destravar/A-08-PROBE.txt` exit 0 (arquivo não-vazio — gate antifragile).
    - O arquivo registra os DOIS prefixos distintos: `grep -q 'PREFIX_DOCTOR=' .../A-08-PROBE.txt && grep -q 'PREFIX_ACTIVE=' .../A-08-PROBE.txt` exit 0.
    - A divergência de prefixo está PROVADA (não são iguais): `grep 'PREFIX_DOCTOR=' .../A-08-PROBE.txt | grep -q 'claude_ai_Lovable' && exit 1 || exit 0` (o doctor NÃO conta o prefixo novo) — confirma o verde-falso por exit-code.
    - A contagem do prefixo NOVO no cfoai é < 19: `awk -F= '/^CFOAI_DENY_NEW=/{exit ($2>=19)?1:0}' .../A-08-PROBE.txt` exit 0.
    - INPUT NEGATIVO genuíno: a contagem do prefixo VELHO no cfoai É >= 19 (prova que o gate-zero está medindo de verdade, não retornando 0 por bug de leitura): `awk -F= '/^CFOAI_DENY_OLD=/{exit ($2>=19)?0:1}' .../A-08-PROBE.txt` exit 0.
  </acceptance_criteria>
  <done>A-08-PROBE.txt prova por exit-code que o §7e conta `6f530143` (id velho, OLD=19) enquanto o server ativo é `claude_ai_Lovable` e o deny do prefixo novo = 0 nos 4 produtos — verde-falso confirmado. Apresentar ao dono o gate A vs B (para o cfoai).</done>
</task>

<task type="auto">
  <name>Task 1: Pausar autosync e capturar baseline (pré-cirurgia multi-arquivo)</name>
  <files>(nenhum artefato de produto; preparação)</files>
  <read_first>
    - learning autosync-races-ai-git-surgery (autosync atropela cirurgia git multi-repo) e autosync-pushes-feature-branches
    - learning autosync-pause-file-guard-not-deployed (verificar o BINÁRIO DEPLOYADO por grep, não confiar em "status PAUSADO")
    - scripts/autosync-pause.sh (mecanismo codificado: `on [motivo]` cria pause-file `${HOME}/.local/state/git-autosync.pause`; `off` remove; `status` mostra)
  </read_first>
  <action>
    (a) Confirmar PRIMEIRO que o guard de pause existe no BINÁRIO DEPLOYADO (não só na fonte): o daemon
        deployado é `/Users/gustavolopespaiva/.local/bin/git-autosync` e respeita o pause-file global
        `${HOME}/.local/state/git-autosync.pause` (ou por-repo `<repo>/.git/autosync-pause`). VERIFICADO:
        grep do pattern de pause no binário deployado = 4 matches (linha ~85). Se o guard NÃO estiver no
        binário deployado, ABORTAR a Task 4 e escalar (não prosseguir cego).
    (b) Pausar via `bash scripts/autosync-pause.sh on "v15-A-08 cirurgia settings cfoai/ideiapartner"`.
        NÃO assumir "PAUSADO" pelo status — confirmar pela existência do pause-file (item nos critérios).
    (c) Capturar baseline sha256 dos arquivos que serão tocados, p/ provar mudança/idempotência depois:
        `shasum -a 256 /Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json /Users/gustavolopespaiva/dev/ideiapartner/.claude/settings.json scripts/idea-doctor.sh > "$SCRATCH/A-08-baseline.sha" 2>/dev/null` (SCRATCH = diretório scratchpad da sessão).
    NÃO fazer `git checkout` cego em nenhum settings (learning claude-settings-deny-live-reload-autosync-capture).
  </action>
  <acceptance_criteria>
    - O guard de pause existe no binário DEPLOYADO (não só na fonte): `grep -ciE 'pause|paused' /Users/gustavolopespaiva/.local/bin/git-autosync | awk '{exit ($1>=1)?0:1}'` exit 0. Se 0, ABORTAR e escalar.
    - Autosync efetivamente pausado (pause-file presente — não confiar em "status PAUSADO" como string): `test -f "${HOME}/.local/state/git-autosync.pause"` exit 0.
    - INPUT NEGATIVO: ANTES de pausar, o pause-file NÃO existia (provar que a pausa foi este plano que criou) — registrar `test -f "${HOME}/.local/state/git-autosync.pause" && echo "JA-PAUSADO-POR-OUTRO" || echo "criado-por-nos"` no log da task; se já pausado por outro processo, NÃO despausar no final (Task 6).
    - Baseline gravado: `test -s "$SCRATCH/A-08-baseline.sha"` exit 0.
  </acceptance_criteria>
  <done>Guard confirmado no binário deployado por grep; autosync pausado via autosync-pause.sh (pause-file presente); baseline sha256 capturado. Cirurgia multi-arquivo segura.</done>
</task>

<task type="auto">
  <name>Task 2 (INCONDICIONAL, antes da bifurcação): construir fixtures de prova isolada do §7e prefix-aware</name>
  <files>$SCRATCH/A-08-fixture-new/.claude/settings.json, $SCRATCH/A-08-fixture-empty/.claude/settings.json</files>
  <read_first>
    - scripts/idea-doctor.sh:427-439 (a função deny_count e o arg prefix; é exatamente esse algoritmo que o teste isolado vai exercitar)
    - source/rules/lovable/mcp-protocol.md:42-66 (lista canônica das 19 tools mutantes — fonte-de-verdade dos NOMES; só o PREFIXO muda)
  </read_first>
  <action>
    Construir DOIS fixtures de settings em diretório scratchpad (NÃO nos repos reais), para provar a lógica
    do §7e modificado ANTES de gravar nos produtos — isolando o gate da gravação (gap do checker):
    - `A-08-fixture-new`: um `.claude/settings.json` com as 19 entries de deny SÓ no prefixo NOVO
      (`mcp__claude_ai_Lovable_-_gustavolpaiva__<tool>` para as 19 tools da rule), zero no prefixo velho.
      É o caso que o §7e prefix-aware DEVE contar como contido (count>=19) e que o §7e ANTIGO contaria 0.
    - `A-08-fixture-empty`: um `.claude/settings.json` com deny=[] (input INVÁLIDO/negativo) — o §7e deve
      dar BAD (count<19) em AMBAS as versões.
    Gerar as 19 entries derivando os NOMES da rule (`grep -oE 'mcp__6f530143-[^"]+' | sed 's/.*__//'`) e
    recompondo com o prefixo novo — não inventar nomes (No-Invention; a fonte é a rule).
  </action>
  <acceptance_criteria>
    - Fixture-new tem 19 deny no prefixo NOVO e formato exato: `/usr/bin/python3 -c "import json,re,sys; d=json.load(open('$SCRATCH/A-08-fixture-new/.claude/settings.json')); deny=(d.get('permissions') or {}).get('deny') or []; pat=re.compile(r'^mcp__claude_ai_Lovable_-_gustavolpaiva__[a-z_]+$'); sys.exit(0 if sum(1 for x in deny if isinstance(x,str) and pat.match(x))>=19 else 1)"` exit 0.
    - Fixture-new tem ZERO no prefixo velho (prova que o teste isola o caminho novo): `! grep -q '6f530143' "$SCRATCH/A-08-fixture-new/.claude/settings.json"` exit 0.
    - Fixture-empty é input inválido genuíno: `/usr/bin/python3 -c "import json,sys; d=json.load(open('$SCRATCH/A-08-fixture-empty/.claude/settings.json')); sys.exit(0 if not ((d.get('permissions') or {}).get('deny') or []) else 1)"` exit 0.
    - Ambos JSON válidos: `/usr/bin/python3 -c "import json; json.load(open('$SCRATCH/A-08-fixture-new/.claude/settings.json')); json.load(open('$SCRATCH/A-08-fixture-empty/.claude/settings.json'))"` exit 0.
  </acceptance_criteria>
  <done>Dois fixtures prontos em scratchpad: um com deny SÓ no prefixo novo (caso de contenção real, formato exato) e um vazio (input negativo). Prontos para provar a lógica do §7e modificado na Task 3, ANTES de tocar repos reais.</done>
</task>

<task type="auto">
  <name>Task 3 (INCONDICIONAL — ambas as branches): tornar o §7e prefix-aware e PROVAR a lógica contra os fixtures</name>
  <files>scripts/idea-doctor.sh</files>
  <read_first>
    - scripts/idea-doctor.sh:418-503 (o §7e e o python3 embutido; o arg `6f530143` em :427 passado como `prefix`; o uso em deny_count :433-439; o threshold "19" em :427; o `fail "Lovable MCP SEM contenção` em :497)
    - source/rules/lovable/mcp-protocol.md:35-37 (a rule já manda "ajuste o prefixo para casar — leia-o da lista de tools do MCP" — este é o fix que materializa isso no gate)
    - $SCRATCH/A-08-fixture-new e A-08-fixture-empty (Task 2)
    - learning ambiguous-drift-warning-induces-agent-revert (manter as mensagens direcionais)
  </read_first>
  <action>
    Este fix é o do INSTRUMENTO de medição — INCONDICIONAL, roda independentemente de OWNER_CHOICE (corrige o
    verde-falso dos 4 produtos, ortogonal a como o dono decide CONTER o cfoai). Tornar a contagem do §7e
    tolerante a AMBOS os prefixos (id-curto histórico `6f530143` e slug do server ativo `claude_ai_Lovable`),
    de modo que um deny no prefixo ATIVO conte como contido e o drift de id não reabra o verde-falso.
    Concretamente: passar uma LISTA de prefixos aceitos ao python3 embutido (ex.: arg `6f530143|claude_ai_Lovable`,
    split por `|`) e fazer `deny_count` casar QUALQUER um deles (`any(p in x for p in prefixes)`). Manter o
    threshold 19 e o comportamento FAIL on BAD intacto. Escopo CIRÚRGICO: tocar só o §7e (linha :427 — o arg
    de prefixo; :431 — o parse do arg; :439 — o `prefix in x` vira `any(p in x for p in prefixes)`) e o
    cabeçalho-comentário :419 que cita "prefixo 6f530143". Atualizar o comentário p/ refletir os dois prefixos.
    Comentar a mudança inline com `# v15-A-08:`. Não adicionar novo SOURCE header (o arquivo já tem o seu).
    PROVA isolada (gap do checker — antes de qualquer gravação em repo real): rodar o python3 de contagem do
    §7e MODIFICADO contra os dois fixtures da Task 2.
    debt: o ideal futuro é DERIVAR o prefixo do server ativo via `claude mcp list` em vez de lista hardcoded —
    fora do escopo de R15-06; deixar marcador `# debt: derivar prefixo do server ativo via claude mcp list`.
  </action>
  <acceptance_criteria>
    - Sintaxe do script intacta: `bash -n scripts/idea-doctor.sh` exit 0.
    - A LÓGICA (não só a string) conta o prefixo NOVO: extrair o bloco python3 do §7e e rodá-lo contra fixture-new com `prefixes=6f530143|claude_ai_Lovable` retorna count>=19/OK. Operacionalmente, validar pelo invariante: `/usr/bin/python3 -c "import json,sys; pref='6f530143|claude_ai_Lovable'.split('|'); d=json.load(open('$SCRATCH/A-08-fixture-new/.claude/settings.json')); deny=(d.get('permissions') or {}).get('deny') or []; sys.exit(0 if sum(1 for x in deny if isinstance(x,str) and any(p in x for p in pref))>=19 else 1)"` exit 0 (prova que a expressão `any(p in x for p in prefixes)` conta o fixture-new).
    - INPUT NEGATIVO genuíno: o MESMO algoritmo dá BAD (count<19) no fixture-empty: `/usr/bin/python3 -c "import json,sys; pref='6f530143|claude_ai_Lovable'.split('|'); d=json.load(open('$SCRATCH/A-08-fixture-empty/.claude/settings.json')); deny=(d.get('permissions') or {}).get('deny') or []; sys.exit(0 if sum(1 for x in deny if isinstance(x,str) and any(p in x for p in pref))<19 else 1)"` exit 0.
    - O script agora MENCIONA o prefixo novo na lista de prefixos do §7e: `grep -q 'claude_ai_Lovable' scripts/idea-doctor.sh` exit 0 (presença — complementar à prova de lógica acima, não substituta).
    - O threshold 19 e o FAIL seguem presentes: `grep -q '"19"' scripts/idea-doctor.sh && grep -q 'fail "Lovable MCP SEM contenção' scripts/idea-doctor.sh` exit 0.
    - Marcador de dívida registrado (scope discipline): `grep -q 'debt: derivar prefixo do server ativo' scripts/idea-doctor.sh` exit 0.
  </acceptance_criteria>
  <done>§7e conta deny em QUALQUER um dos dois prefixos (id velho + slug do server ativo); lógica `any(p in x for p in prefixes)` PROVADA por exit-code contra fixture-new (OK) e fixture-empty (BAD), antes de tocar repos reais; threshold 19 e FAIL preservados; drift de id não reabre o verde-falso; dívida de derivação automática marcada. Vale para os 4 produtos, sob A ou B.</done>
</task>

<task type="auto">
  <name>Task 4 — BRANCH A (se OWNER_CHOICE=A): remediar os 19 deny no prefixo do server ATIVO no cfoai + re-materializar ideiapartner</name>
  <files>/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json, /Users/gustavolopespaiva/dev/ideiapartner/.claude/settings.json</files>
  <read_first>
    - source/rules/lovable/mcp-protocol.md:42-66 (lista canônica das 19 tools mutantes — fonte-de-verdade dos NOMES de tool a denegar; só o PREFIXO muda)
    - A-08-PROBE.txt (PREFIX_ACTIVE provado na Task 0)
    - /Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json (TRACKED, branch main — preservar o resto do JSON; só ADICIONAR as 19 entries do prefixo novo + disabledMcpServers)
    - /Users/gustavolopespaiva/dev/ideiapartner/.claude/settings.json (GITIGNORED/não-tracked, branch main — já tem deny=19 no prefixo velho; ADICIONAR as 19 do prefixo novo no MESMO arquivo, que é local-only ali)
    - learning uncommitted-security-config-ephemeral + memória feedback-lovable-projects-branch-commit (cfoai .claude/settings.json é TRACKED e repo em main → commit de IA vai p/ branch work, NUNCA main automática; ideiapartner .claude/settings.json é GITIGNORED → já é local-only, persiste por reclone-manual)
  </read_first>
  <action>
    SOMENTE se o dono escolheu A. Para cada produto, ADICIONAR as 19 entries de deny no prefixo PREFIX_ACTIVE
    (as mesmas 19 tools da rule, com o prefixo `mcp__claude_ai_Lovable_-_gustavolpaiva__`). Decisão de manter
    ou remover as entries do prefixo VELHO: MANTER ambas (defense-in-depth — denegar os dois prefixos não custa
    nada e cobre reconexões antigas). Atualizar `disabledMcpServers` p/ incluir o identificador do server ativo
    também (`claude.ai Lovable - gustavolpaiva` ou o id que `claude mcp list` reportar).
    - **cfoai** (`.claude/settings.json` TRACKED, repo em `main`): gravar no `.claude/settings.json`. Como é main
      Lovable, o COMMIT é de @dev em branch `work` (NUNCA main automática — feedback-lovable). Este plano NÃO
      commita nem empurra — apenas grava o arquivo; o commit/push é passo separado de @dev/@devops.
    - **ideiapartner** (`.claude/settings.json` GITIGNORED): gravar no MESMO `.claude/settings.json` (que é
      gitignored=local-only ali — NÃO migrar para settings.local.json; o §7e conta via `max(sj, sl)`).
      É o caminho persistível possível ("re-materializar após reclone").
    Editar o JSON preservando indentação e o restante das chaves (edição cirúrgica via python3, não reescrever
    o arquivo inteiro à mão). bash 3.2: SEM `declare -A`.
  </action>
  <acceptance_criteria>
    - cfoai deny do prefixo ATIVO >= 19 NO FORMATO EXATO (não só substring): `/usr/bin/python3 -c "import json,re,sys; d=json.load(open('/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json')); deny=(d.get('permissions') or {}).get('deny') or []; pat=re.compile(r'^mcp__claude_ai_Lovable_-_gustavolpaiva__[a-z_]+$'); sys.exit(0 if sum(1 for x in deny if isinstance(x,str) and pat.match(x))>=19 else 1)"` exit 0.
    - ideiapartner re-materializado com o MESMO critério de formato exato (sobre o seu settings.json): mesmo python3 apontando para `/Users/gustavolopespaiva/dev/ideiapartner/.claude/settings.json` exit 0.
    - JSON ainda válido em ambos: `/usr/bin/python3 -c "import json; json.load(open('/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json')); json.load(open('/Users/gustavolopespaiva/dev/ideiapartner/.claude/settings.json'))"` exit 0.
    - Defense-in-depth preservado (deny velho NÃO removido): `/usr/bin/python3 -c "import json,sys; d=json.load(open('/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json')); deny=(d.get('permissions') or {}).get('deny') or []; sys.exit(0 if sum(1 for x in deny if isinstance(x,str) and '6f530143' in x)>=19 else 1)"` exit 0.
    - INPUT NEGATIVO (as 19 NÃO são um `allow` disfarçado): `/usr/bin/python3 -c "import json,sys; d=json.load(open('/Users/gustavolopespaiva/dev/cfoai-grupori/.claude/settings.json')); a=(d.get('permissions') or {}).get('allow') or []; sys.exit(1 if any('deploy_project' in x or 'query_database' in x for x in a) else 0)"` exit 0 (nenhuma tool mutante em allow).
  </acceptance_criteria>
  <done>cfoai e ideiapartner têm deny>=19 no prefixo do server ATIVO (formato exato, não só substring), mantendo o deny velho (defense-in-depth); JSON válido; nada mutante em allow; persistência no arquivo certo por repo (cfoai=settings.json tracked p/ commit-em-branch-work; ideiapartner=settings.json gitignored=local-only).</done>
</task>

<task type="auto">
  <name>Task 5 — BRANCH B (se OWNER_CHOICE=B): allowlist por-nome-auditável no §7e para o cfoai (INFO datado, NUNCA FAIL→OK mudo)</name>
  <files>scripts/idea-doctor.sh, .security/lovable-mcp-allowlist.txt</files>
  <read_first>
    - scripts/idea-doctor.sh:487-499 (o ramo de verdict: lê `status=OK|BAD`, emite `pass`/`fail`; é aqui que entra o caso INFO datado)
    - learning ambiguous-drift-warning-induces-agent-revert (mensagens devem ser direcionais — a allowlist tem de dizer claramente "aceito pelo dono em DATA", não ambíguo)
    - memória project-cfoai-particular (cfoai é particular → razão legítima da exceção)
  </read_first>
  <action>
    SOMENTE se OWNER_CHOICE=B. (O §7e já é prefix-aware pela Task 3 INCONDICIONAL — logo nfideia e lapidai
    passam a contar BAD honestamente, não mais PASS falso. Esta task trata SÓ o cfoai.) Adicionar ao §7e uma
    allowlist por-NOME de repo, DATADA, lida de um arquivo auditável `.security/lovable-mcp-allowlist.txt` com
    linhas no formato `cfoai-grupori|2026-06-25|particular-do-dono|R15-06`. Quando um produto BAD está na
    allowlist (e a linha TEM data ISO YYYY-MM-DD), o §7e emite `info` (NÃO `pass`, NÃO `fail`) com mensagem
    DIRECIONAL: "Lovable MCP NÃO-contido em cfoai-grupori — FAIL ACEITO pelo dono em 2026-06-25 (cfoai é
    particular), R15-06. Allowlist datada; re-revisar se mudar de dono."
    Condições invioláveis:
      - NUNCA converter o FAIL em `pass` mudo: o verdict é `info`, visualmente distinto.
      - A entrada carrega DATA (ISO) + RAZÃO + requisito; linha SEM data → trata como FAIL normal (não silenciar
        sem trilha).
      - Só cfoai (ou o que o dono nomear) entra; demais produtos BAD seguem FAIL.
    Escopo cirúrgico: tocar só o ramo de verdict do §7e (:488-499) + criar o arquivo de allowlist. `# v15-A-08:`
    inline. bash 3.2 — SEM `declare -A` (ler a allowlist com `grep`/`while read`, não array associativo).
  </action>
  <acceptance_criteria>
    - A allowlist NÃO usa `declare -A` (bash 3.2): `! grep -q 'declare -A' scripts/idea-doctor.sh` exit 0.
    - O caso allowlistado emite INFO, não pass nem fail: `grep -Eq 'info "Lovable MCP.*ACEITO|info .*allowlist' scripts/idea-doctor.sh` exit 0; e o FAIL original NÃO é removido p/ os demais: `grep -q 'fail "Lovable MCP SEM contenção' scripts/idea-doctor.sh` exit 0.
    - GATE ANTI-TEATRO-VERDE (escopado ao DIFF, não ao arquivo inteiro): a data ISO foi ADICIONADA no bloco novo — `git diff scripts/idea-doctor.sh .security/lovable-mcp-allowlist.txt | grep '^+' | grep -Eq '[0-9]{4}-[0-9]{2}-[0-9]{2}'` exit 0. (Substitui o critério antigo `grep -Eq 'data|date|AAAA' scripts/idea-doctor.sh`, VERIFICADO casando 19 linhas pré-existentes no arquivo inteiro — passaria verde sem nada adicionado.)
    - A allowlist EXIGE data (input inválido cai em FAIL): construir uma linha de teste SEM data num arquivo-fixture e provar que o ramo a trata como FAIL — `printf 'repo-sem-data||sem-razao\n' > "$SCRATCH/allow-nodate.txt"` e validar pela lógica do parser (linha sem campo-2 ISO → não-allowlistada): `awk -F'|' '{exit ($2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/)?1:0}' "$SCRATCH/allow-nodate.txt"` exit 0 (a linha NÃO casa data → seria FAIL).
    - Sintaxe intacta: `bash -n scripts/idea-doctor.sh` exit 0.
  </acceptance_criteria>
  <done>§7e ganha allowlist por-nome DATADA (arquivo .security/lovable-mcp-allowlist.txt): cfoai vira INFO direcional (não pass mudo, não fail), demais BAD seguem FAIL; data ISO provada ADICIONADA no diff (não casando linhas pré-existentes); linha sem data → FAIL; bash 3.2 (sem declare -A); trilha auditável com data+razão+requisito.</done>
</task>

<task type="auto">
  <name>Task 6 (ambas as branches): rodar o §7e real, provar que o verde-falso morreu por exit-code e restaurar autosync</name>
  <files>(verificação; regrava A-08-PROBE.txt)</files>
  <read_first>
    - scripts/idea-doctor.sh (o §7e modificado: prefix-aware sempre + branch escolhida)
    - A-08-PROBE.txt (estado ANTES)
    - scripts/autosync-pause.sh (`off` remove o pause-file)
  </read_first>
  <action>
    Rodar o idea-doctor (ou ao menos a seção 7e isolada) e capturar as linhas dos produtos Lovable. Provar o
    invariante por exit-code conforme a branch:
      - Branch A: a linha do cfoai é `pass "Lovable MCP contido"` E o deny do prefixo ATIVO é >=19 (não é mais
        verde-falso: o pass corresponde a contenção REAL do server ativo). ideiapartner idem.
      - Branch B: a linha do cfoai é `info` com data e razão — distinguível de pass real; e o §7e NÃO retorna
        FAIL global SÓ por causa do cfoai (mas SEGUE retornando FAIL p/ outro produto Lovable não-allowlistado
        sem contenção, ex.: nfideia/lapidai que ainda não receberam o deny novo — isso é correto e esperado:
        o prefix-aware da Task 3 os faz contar BAD honestamente).
    Re-rodar a sonda de prefixo da Task 0 (regravar A-08-PROBE.txt) e confirmar `VERDE_FALSO=nao` agora
    (o instrumento não mente mais: o §7e conta o prefixo ativo nos 4).
    Restaurar o autosync: `bash scripts/autosync-pause.sh off` — restauração garantida (learning autosync-races).
    Exceção: se a Task 1 detectou que o pause-file JÁ existia por outro processo, NÃO remover (não despausar o
    que não fomos nós que pausamos).
  </action>
  <acceptance_criteria>
    - `bash scripts/idea-doctor.sh 2>&1 | grep -i 'lovable mcp' | grep -i 'cfoai'` retorna a linha esperada da branch (exit 0 do grep).
    - Branch A: `bash scripts/idea-doctor.sh 2>&1 | grep -i cfoai | grep -qi 'contido'` exit 0 E `bash scripts/idea-doctor.sh 2>&1 | grep -i cfoai | grep -qi 'SEM contenção' && exit 1 || exit 0`.
    - Branch B: `bash scripts/idea-doctor.sh 2>&1 | grep -i cfoai | grep -Eqi 'aceito|allowlist'` exit 0 E a linha do cfoai NÃO é um `pass` puro indistinguível (`bash scripts/idea-doctor.sh 2>&1 | grep -i cfoai | grep -qiE '^.*pass "Lovable MCP contido' && exit 1 || exit 0`).
    - Sonda re-rodada confirma fim do verde-falso do INSTRUMENTO: regravar A-08-PROBE.txt e `grep -q 'VERDE_FALSO=nao' .../A-08-PROBE.txt` exit 0.
    - Autosync despausado (salvo exceção da Task 1): `test -f "${HOME}/.local/state/git-autosync.pause" && exit 1 || exit 0` (pause-file removido).
  </acceptance_criteria>
  <done>O §7e roda real e a linha do cfoai prova o invariante da branch escolhida (A=pass-real / B=info-datado); a sonda confirma VERDE_FALSO=nao (o instrumento conta o prefixo ativo nos 4 produtos); autosync restaurado.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| §7e (gate) ↔ server MCP ativo | o gate conta um prefixo; se ≠ prefixo do server ativo, o gate é cego à capability real (verde-falso). VERIFICADO: divergente nos 4 produtos (deny_NEW=0) |
| settings.json/local.json ↔ persistência git | cfoai/nfideia=tracked em main → deny exige commit-em-branch-work (não main automática); ideiapartner=settings.json gitignored → local-only por design; lapidai=tracked em work |
| allowlist (branch B) ↔ auditoria | uma exceção sem data/razão silencia um FAIL sem trilha — anti-padrão; a exceção tem de ser DATADA e INFO; o gate da data deve olhar o DIFF (não casar datas pré-existentes do script) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-A08-FALSEGREEN | Spoofing (do gate) | §7e conta prefixo morto `6f530143` (afeta os 4 produtos) | mitigate | Task 0 prova por exit-code o drift; **Task 3 (INCONDICIONAL) torna o §7e prefix-aware nas duas branches** — provada por fixture isolada (Task 2); o verde-falso do instrumento morre independentemente de A/B (Task 6) |
| T-A08-EPHEMERAL | Tampering (silencioso) | settings em main Lovable | mitigate | persistir em settings.json TRACKED (commit em branch work, não main) p/ cfoai; settings.json gitignored=local-only p/ ideiapartner; gate de JSON-válido + deny>=19 formato-exato |
| T-A08-MUTE-PASS | Repudiation | allowlist branch B | mitigate | INFO datado (nunca FAIL→OK mudo); gate exige data ISO ADICIONADA no DIFF (não casa datas pré-existentes); linha sem data → FAIL; demais produtos seguem FAIL |
| T-A08-AUTOSYNC | Tampering (corrida) | cirurgia multi-repo | mitigate | pausar via autosync-pause.sh com guard confirmado no BINÁRIO deployado (grep, não "status PAUSADO"); restaurar ao final salvo se já-pausado-por-outro |
| T-A08-EXCESS | Elevation (Excessive Agency) | tool mutante em allow | mitigate | gate exit-code prova que nenhuma tool mutante (deploy/query_database) entrou em `permissions.allow` |
</threat_model>

<invariants>
Condições/invariantes que o executor DEVE respeitar (todos GATED por exit-code onde aplicável):

1. **O fix prefix-aware do §7e (Task 3) é INCONDICIONAL.** Corrige o INSTRUMENTO de medição (conta o prefixo do server ativo nos 4 produtos), ortogonal à decisão A/B do dono. Sem ele, sob B, nfideia e lapidai seguiriam com PASS falso — o verde-falso que R15-06 manda matar persistiria.
2. **NÃO escolher A ou B pelo dono** (para o cfoai). O `owner_decision_gate` é bloqueante: apresentar o PROBE e a tabela A/B; só prosseguir com `OWNER_CHOICE` explícito. cfoai é particular do Gustavo (memória project-cfoai-particular).
3. **Verificação = EXIT-CODE binário**, nunca o Read tool (antifragile-gates). Cada task termina num gate por exit-code que exercita TAMBÉM input INVÁLIDO (anti-teatro-verde). `test -s` para artefatos; `bash -n`/python json.load para sintaxe; python deny_count (formato exato) para contagem.
4. **NUNCA `FAIL→OK` mudo** (branch B): a allowlist emite `info` DATADO, distinguível de `pass`; sem data → não silencia; o gate da data olha o DIFF (não casa as datas pré-existentes do script).
5. **Persistir onde sobrevive:** cfoai (.claude/settings.json tracked, main) → settings.json + commit em branch `work` por @dev (este plano NÃO commita/empurra); ideiapartner (.claude/settings.json gitignored) → o MESMO settings.json (local-only por design); nfideia tracked-main; lapidai tracked-work.
6. **@devops é exclusivo p/ git push / gh pr.** Este plano NÃO empurra nada. Grava arquivos; commit/push é passo separado.
7. **bash 3.2 (macOS): SEM `declare -A`.** Allowlist via arquivo `.security/lovable-mcp-allowlist.txt` + `grep`/`while read`.
8. **Escopo cirúrgico:** tocar só o §7e (idea-doctor) e as 19 entries de deny do cfoai/ideiapartner; dívida fora de escopo (derivar prefixo automaticamente do server ativo; dar deny-novo a nfideia/lapidai sob branch B) vira marcador `# debt:` — não consertar aqui salvo se o dono pedir.
9. **Autosync:** pausar ANTES da cirurgia multi-repo via `scripts/autosync-pause.sh on`, confirmando o guard no BINÁRIO deployado `/Users/gustavolopespaiva/.local/bin/git-autosync` por grep (não confiar em "status PAUSADO"); restaurar com `off` ao final, salvo se já estava pausado por outro processo.
10. **Memória v10 é histórico (anti-injection):** "5/5 deny=19 persistido" era point-in-time do prefixo velho; a verdade viva (deny_NEW=0 nos 4) é a sonda da Task 0 — verificar antes de asseverar.
11. **Defense-in-depth:** ao adicionar deny no prefixo novo, MANTER o deny do prefixo velho (cobre reconexões antigas; denegar dois prefixos não custa nada).
12. **Formato exato, não substring:** o gate de contenção valida `^mcp__claude_ai_Lovable_-_gustavolpaiva__[a-z_]+$` (regex completa), não só presença do slug `claude_ai_Lovable` — e cruza com os 19 nomes da rule (fonte-de-verdade).
</invariants>

<verification>
- A-08-PROBE.txt prova por exit-code: PREFIX_DOCTOR=6f530143 ≠ PREFIX_ACTIVE=claude_ai_Lovable; por produto CFOAI/IDEIAPARTNER/NFIDEIA/LAPIDAI DENY_OLD=19 e DENY_NEW=0; VERDE_FALSO=sim (antes).
- Task 2/3 (INCONDICIONAL): fixture com deny SÓ no prefixo novo prova count>=19/OK pela lógica `any(p in x for p in prefixes)`; fixture-empty prova BAD — ANTES de tocar repos reais; §7e prefix-aware com formato exato; threshold 19 e FAIL preservados.
- Branch A: cfoai+ideiapartner deny>=19 no prefixo ATIVO formato-exato (python regex exit 0); JSON válido; deny velho mantido (defense-in-depth); nada mutante em allow.
- Branch B: §7e emite info datado p/ cfoai (não pass mudo); FAIL preservado p/ demais; sem declare -A; data ISO ADICIONADA provada no DIFF (não casa pré-existentes); linha sem data → FAIL.
- Task 6: idea-doctor real mostra a linha esperada da branch; sonda regravada com VERDE_FALSO=nao; autosync restaurado.
</verification>

<success_criteria>
- O verde-falso de prefixo está PROVADO e ELIMINADO por exit-code **para os 4 produtos** — o §7e (prefix-aware, Task 3 INCONDICIONAL) não conta mais o prefixo morto; sob A ou B, não há §7e verde com server ativo não-contido por bug de instrumento.
- A escolha A vs B (contenção do cfoai) foi do DONO; o plano executou só o caminho escolhido para o cfoai.
- cfoai resolvido de forma persistível (settings.json tracked → commit em branch work, OU allowlist INFO-datada); ideiapartner re-materializado (deny novo no settings.json gitignored) quando branch A.
- O gate SOAK futuro do v15 não é mais bloqueado por um FAIL crônico nem normaliza ignorar FAIL.
</success_criteria>

<output>
Create `.planning/milestones/v15-phases/A-destravar/A-08-SUMMARY.md` when done.
</output>
