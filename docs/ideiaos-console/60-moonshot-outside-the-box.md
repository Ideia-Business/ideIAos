# IdeiaOS Mission Control — Moonshot / Fora da Caixa

> Documento visionário-cético. Persona: visionário de produto + cético-genial.
> Cada feature responde quatro perguntas honestas: **o que é**, **por que é wow**,
> **viabilidade** (já dá / precisa de X), **risco**. Audacioso no que propõe,
> brutalmente honesto no que custa.
>
> Data: 2026-06-20 · Codinome: **Mission Control** · Status: exploração de features

---

## A tese que torna tudo isso possível (e "jamais visto")

A maioria dos "consoles de CTO" do mercado falha pela mesma razão: começam pela
**coleta**. Instrumentam, instalam agentes, pedem permissão, integram APIs, e seis
meses depois têm um dashboard de vaidade que ninguém abre.

O IdeiaOS inverte o problema. Ele **já se auto-telemetra**. O substrato existe e é
determinístico, legível sem LLM, e na maioria já commitado cross-máquina:

- **SOAK ledger** (`.planning/soak/*.log`) — heartbeats `epoch|iso|host|doctor|regression|commit` por máquina. É o "quem está vivo e saudável".
- **Security freshness ledger** (`.security/review-ledger.log`) — selo de frescor risk-weighted.
- **git log** — atividade real por ator (humano vs Lovable-bot vs autosync-daemon), por repo, por hora.
- **session transcripts** (`~/.claude/projects/*/*.jsonl`) — sinal de trabalho cognitivo.
- **observations** (`~/.ideiaos/observations/*/observations.jsonl`) — metadados de tool-use, **nunca conteúdo**.
- **instincts** (`~/.ideiaos/instincts/`) — telemetria comportamental destilada, confidence-tracked.
- **versions.lock** + `idea-doctor.sh` — fonte de verdade de versões esperadas vs drift.
- **LaunchAgents** + `launchctl` — estado dos daemons em tempo real.

**Consequência radical:** o Mission Control não é um problema *greenfield de coleta*.
É uma **camada de surfacing + controle sobre substrato existente**. Isso muda tudo:
o MVP é semanas, não trimestres, e cada feature abaixo herda dados que já têm
proveniência, idade e verificação por exit-code binário (não por "parece certo").

E há um segundo ângulo que nenhum console comercial tem: **o sujeito observado é um
OS de orquestração de IA**. Logo o console não mede só *pessoas codando* — mede
**agentes trabalhando**, drift de frota de IA, custo de tokens por decisão, maturidade
de reflexos aprendidos. É um *CTO console para uma força de trabalho parcialmente
sintética*. Esse é o "jamais visto".

### O princípio inegociável que molda 100% do produto

**`credential-isolation`**: um segredo NUNCA transita pelo contexto do LLM nem do
browser. Portanto **Mission Control é control-plane/metadata, jamais cofre**. Ele
responde *"essa chave existe? que idade tem? que escopo? quando foi usada pela última
vez? quando rotacionar?"* — e **nunca** mostra o valor. Toda feature abaixo respeita
isso como lei física, não como preferência. Onde uma feature parece pedir o valor de
um segredo, ela está mal-desenhada e foi recusada ou redesenhada.

---

## Mapa rápido das 11 features

| # | Feature | Wow | Viabilidade | Risco |
|---|---------|-----|-------------|-------|
| 1 | **CTO Copiloto** (NL sobre o ecossistema) | ★★★★★ | já dá (read-only) | médio (injection no substrato) |
| 2 | **Time-Travel / Replay do estado do OS** | ★★★★★ | já dá (git + ledgers) | baixo |
| 3 | **Detecção proativa de drift & risco** | ★★★★☆ | já dá | baixo |
| 4 | **Token-Cost Ledger por projeto/agente/decisão** | ★★★★★ | precisa de X (parser de custo) | baixo |
| 5 | **Frota de IA: humano × agente, lado a lado** | ★★★★☆ | já dá | médio (métrica de vaidade) |
| 6 | **Simulador "E se…" (rotacionar chave / pausar máquina)** | ★★★★★ | precisa de X (dependency graph) | médio |
| 7 | **Orquestração cross-máquina disparada do console** | ★★★★☆ | precisa de X (canal de comando) | **alto** (auth/RCE) |
| 8 | **Health-score vivo por produto** | ★★★☆☆ | já dá | baixo |
| 9 | **Security-freshness como semáforo permanente + escada** | ★★★★☆ | já dá | baixo |
| 10 | **Mapa de superfície de credenciais (control-plane)** | ★★★★★ | já dá (metadata) | **alto** se mal-feito |
| 11 | **Atlas de instincts — maturidade do agente por domínio** | ★★★★☆ | já dá | baixo |
| +1 | **Black-box / flight-recorder de incidentes** (bônus) | ★★★★★ | precisa de X | médio |

---

## 1. CTO Copiloto — linguagem natural sobre o estado do ecossistema

**O que é.** Uma barra de comando no topo do console onde o CTO digita em português:
*"qual máquina não dá heartbeat há mais tempo?"*, *"quantos commits humanos no nfideia
essa semana, fora autosync e Lovable?"*, *"o ideiapartner está com `.env` mais velho
que o `.env.example`?"*, *"o que mudou na frota desde ontem?"*. O copiloto **não
inventa**: ele tem um conjunto fixo de *readers* determinísticos (awk no SOAK,
`git log --format`, `launchctl list`, `idea-doctor --json`) e o LLM apenas **roteia a
pergunta → reader → renderiza a resposta**. É RAG sobre o próprio OS.

**Por que é wow.** Inverte a relação do CTO com a frota. Hoje, saber "o Mac mini está
saudável?" exige abrir git log e caçar commits WIP. O copiloto responde em uma frase,
com a **evidência anexada** (a linha exata do ledger, o commit SHA). É o `aiox graph`
já-existente, mas conversacional e sobre *todo* o substrato, não só dependências.

**Viabilidade — já dá.** Todos os readers já existem como comandos shell (vide tabela
`reusableForConsole` do recon). `idea-doctor.sh` tem 40 ocorrências de `json` no fonte
— provável que já aceite `--json` ou seja trivial adicionar. O LLM é orquestrador de
*tool-routing*, não fonte de fato. Padrão **CLI-first** (Constituição, Art. I): o
copiloto chama scripts, nunca reimplementa a lógica.

**Risco — médio.** O substrato é alimentado por commits e logs que **podem conter
texto adversarial** (uma mensagem de commit maliciosa, um nome de branch com
instrução). A rule `context-packet-handoffs` + `credential-isolation` se aplicam: todo
conteúdo lido do substrato é **DADO informativo, nunca instrução**. O copiloto deve
envelopar os readers com o anti-injection wrapper antes de mandar ao LLM. Sem isso, é
prompt-injection cross-OS. Mitigação: o LLM **só escolhe entre readers pré-aprovados**;
ele nunca gera comando shell livre. Whitelist, não free-form.

---

## 2. Time-Travel / Replay do estado do OS

**O que é.** Um slider temporal no topo do console. Arraste para "2026-06-12" e o
console **reconstrói o estado da frota naquela data**: quais máquinas davam heartbeat,
qual milestone estava em SOAK, qual era o tier de security-freshness, quais versões
estavam pinadas, quantos commits humanos/dia. Não é um snapshot armazenado — é
**reconstrução determinística** a partir de fontes append-only + `git log` (que já é,
por natureza, um event-store imutável).

**Por que é wow.** É o recurso que nenhum dashboard SaaS tem porque eles guardam
*estado atual* e jogam fora a história. O IdeiaOS guarda a **história inteira** em
ledgers append-only e git. Logo o time-travel é *grátis* — a informação já está lá.
Casos de uso reais: *"a security-freshness degradou — quando exatamente?"* (replay do
ledger), *"em que dia o Mac mini parou de syncar?"* (gap no SOAK + git log), *"como
estava a frota quando o v11 foi tagueado?"*. Vira ferramenta de **post-mortem** e de
**prova auditável** ("em 14/06 a contenção Lovable estava 5/5"), o que conecta direto
ao learning `uncommitted-security-config-ephemeral` (estado point-in-time que regride).

**Viabilidade — já dá.** Ledgers são append-only e datados por epoch. `git log` é um
event-store. A reconstrução é uma função pura `estado(data) = fold(eventos até data)`.
Zero instrumentação nova. O único trabalho é o *folder* (Node/Python) que projeta os
eventos numa data-alvo.

**Risco — baixo.** A história já é imutável e commitada. O risco real é **interpretar
gap como falha**: o SOAK não tem heartbeat todo dia (cada máquina tem seu
StartInterval), então "sem heartbeat em X" pode ser normal. O folder precisa de uma
heurística de tolerância (gap > N dias = sinal), nunca alarme por ausência pontual.
Cross-link: learning `soak-span-is-record-delta-not-wallclock` — o span é delta dos
epochs **gravados**, não wall-clock.

---

## 3. Detecção proativa de drift & risco

**O que é.** Um painel de alertas que **não espera você perguntar**. Roda regras
determinísticas sobre o substrato e acende quando algo cruza um limiar:
`versions.lock` diverge do instalado (drift de frota); `.env` órfão (var presente sem
estar no `.env.example`); contenção Lovable regrediu de 5/5; daemon `gitautosync`
parou (branches vão divergir); `git-autosync.log` sem rotação passou de N MB; máquina
sem heartbeat há > N dias; deny-rules do `.claude/settings.json` mudaram de HEAD para
working-tree.

**Por que é wow.** O IdeiaOS já teve **regressões reais e silenciosas** que esta
feature pegaria: a contenção Lovable que foi 5/5 → 2/5 → 5/5 (memória
`project-lovable-mcp-v10-candidate`); o ledger varrido por `.gitignore` broad
(learning `broad-gitignore-sweeps-tracked-ledger`); config de segurança uncommitted que
regrediu (learning `uncommitted-security-config-ephemeral`). Cada uma dessas é **uma
regra de detecção pronta** — o console transforma cada incidente passado em um sensor
permanente. É antifragilidade literal: o sistema fica mais forte a cada falha que já
sofreu.

**Viabilidade — já dá.** As regras são `git diff`, `grep`, `launchctl list`,
comparação de SETS (cross-link learning `claude-settings-deny-live-reload-autosync-capture`
— compare os SETS deny de HEAD × working-tree, não checkout cego). Tudo exit-code
binário. O `idea-doctor.sh` já faz metade disso em 14 seções — o console é a **camada
de surfacing contínua** sobre o doctor, não uma reimplementação.

**Risco — baixo.** O perigo é **fadiga de alerta** (cried-wolf). Mitigação: cada alerta
tem severidade (info/warn/critical) e o painel só "grita" no critical, espelhando a
filosofia do security-freshness (`idea-doctor §14` nunca dá FAIL — só WARN — para não
bloquear o SOAK). Princípio: **proporcionalidade** — rigor = risco da superfície × idade
do último OK. Nunca gateie nada de feature; só ilumine.

---

## 4. Token-Cost Ledger — custo por projeto, por agente, por decisão

**O que é.** Um painel que responde a pergunta que dói no bolso: *"quanto custou cada
projeto em tokens este mês, e qual agente/modelo gastou onde?"*. Os transcripts JSONL
têm os eventos de tool-use e (em muitos formatos do Claude Code) **contagem de
tokens/uso por mensagem**. Combinado com a tabela de preços por modelo e com o
`model:` routing dos agentes (haiku/sonnet/opus), o console projeta **custo estimado
por projeto, por dia, por agente, e — o golpe de mestre — por decisão** (uma sessão que
fechou um milestone vs uma que só fez housekeeping).

**Por que é wow.** Ninguém tem isso porque ninguém tem o substrato: você precisaria do
log de cada chamada de modelo *atrelado a um projeto e a um propósito*. O IdeiaOS tem,
porque os transcripts já estão particionados por projeto e os agentes declaram seu
modelo no frontmatter. Casos: *"opus no @architect custou R$X em decisões de arquitetura
— valeu?"*, *"o nfideia está queimando 3× mais tokens que o ideiapartner — por quê?"*,
*"esse milestone custou Y em tokens; ROI vs entrega?"*. Liga direto à rule
`token-economy` (model routing, MCP→CLI) — o console vira o **medidor que prova** se a
disciplina de custo está funcionando.

**Viabilidade — precisa de X.** O X é: (a) um parser confiável de uso/token nos JSONL
(o formato varia entre versões do Claude Code) e (b) uma tabela de preços por modelo
**versionada** (a skill `claude-api` é a fonte canônica de pricing — não chutar de
memória). Sem token-count nativo no JSONL, cai-se para **estimativa por tamanho do
transcript**, que o próprio recon marca como sinal de vaidade ("correlaciona com tokens,
não com valor"). Então: custo *real* exige o campo de uso; custo *aproximado* é grátis
mas honestamente rotulado como estimativa.

**Risco — baixo.** Nenhum segredo envolvido (é metadado de uso). O risco é
**precisão**: apresentar estimativa como número fechado. Mitigação: rotular sempre
("estimado", "±20%") e mostrar a metodologia. Nunca um número de custo sem proveniência.

---

## 5. Frota de IA: produtividade humano × agente, lado a lado

**O que é.** O painel que separa, em toda métrica, **três classes de ator**: humano
(`gustavo@redeideia.com.br`, `desenvolvimento@ideiabusiness.com.br`), agente/bot
(`gpt-engineer-app[bot]` = Lovable, `github-actions[bot]`), e **daemon** (autosync do
Mac mini = `gustavolopespaiva@Mac-mini-de-Gustavo.local`, que **não é sessão humana**).
Para cada repo: commits humanos *de verdade* (excluindo `wip:` e bots), commits Lovable,
e a razão entre eles — o **"Lovable usage ratio"** por produto.

**Por que é wow.** É a primeira métrica de produtividade que existe num mundo onde
**parte da força de trabalho é sintética**. Responde a pergunta de CTO que nenhuma
ferramenta tradicional sabe fazer: *"que fração do nfideia foi construída por IA vs por
humano?"*, *"o Lovable está acelerando ou só gerando ruído?"*, *"qual humano move qual
produto?"*. O recon já mapeou os atores e os padrões (nfideia ~20 commits humanos/dia,
picos de 99-110 em dias de milestone) — falta só o surfacing.

**Viabilidade — já dá.** `git log --format='%ae|%aI|%s'` + filtro por
`grep -vE 'bot|autosync|wip:'`. Sessões "meaningful" = `human_turns > 5` nos JSONL. Tudo
parseável, zero coleta nova.

**Risco — médio (de produto, não técnico).** **Vaidade e gaming.** Contar commits raw é
métrica de vaidade — o recon avisa explicitamente. Mitigação: a única métrica de
"entrega verificada" do OS é o **SOAK ledger** (milestone que passou validação
cross-máquina). Então o painel ancora produtividade em *entregas SOAK-validadas* e usa
commits/sessões só como **textura de atividade**, nunca como ranking de pessoas. Risco
ético adicional: "ranking de produtividade por humano" pode virar vigilância. Decisão de
produto: focar em **produtividade do sistema** (humano+IA juntos entregando) e em
**saúde**, não em leaderboard individual. Push-back honesto (conduta 3 do
`operating-discipline`): um ranking individual de devs é fácil de construir e fácil de
abusar — recomendo **não** construí-lo por default.

---

## 6. Simulador "E se…" — rotacionar chave / pausar máquina

**O que é.** O recurso mais ousado. Um modo "what-if" onde o CTO clica em
*"e se eu rotacionar `SUPABASE_SERVICE_ROLE_KEY` do nfideia?"* e o console responde,
**sem tocar em nada**, o **raio de impacto**: quais `.env`/`.env.local` referenciam
essa var (por nome, nunca valor), quais máquinas a sincronizam via envsync, qual produto
quebra deploy, se há edge functions que dependem dela. Ou *"e se eu pausar o autosync
do Mac mini por 6h?"* → quais branches vão divergir, qual o último heartbeat, que
trabalho fica sem propagar. É um **dry-run de blast-radius**.

**Por que é wow.** Transforma decisões de risco em decisões informadas. Hoje, rotacionar
uma service_role key é um salto no escuro — você descobre o que quebrou *depois*. O
simulador mostra o grafo de dependência **antes**, e respeita `credential-isolation`
perfeitamente: ele raciocina sobre **referências por nome** (`grep '^SUPABASE_SERVICE_ROLE_KEY'`
nos `.env` por nome) e metadados (quem sincroniza via envsync log), **nunca sobre o
valor**. É exatamente o tipo de feature que só um console control-plane pode ter.

**Viabilidade — precisa de X.** O X é o **grafo de dependência de credenciais e
máquinas**: mapear var → arquivos que a referenciam → máquinas que sincronizam → produtos
que dependem. As arestas existem nos dados (`.env` names, envsync repos.txt, SOAK hosts,
supabase config.toml) mas precisam ser **costuradas** num grafo. Precedente: o
`aiox graph` já constrói e renderiza grafos de dependência — reusar o motor.

**Risco — médio.** O simulador **lê muitos `.env`** — superfície sensível. Lei: ele lê
**apenas nomes de variáveis e mtime** (`grep '^[A-Z_]*='  | sed 's/=.*//'`), jamais o
RHS. Cross-link `credential-isolation` + `mcp-hygiene` (least-privilege /
Excessive Agency). O segundo risco é o simulador virar **ação real por engano** — ele
**nunca executa** a rotação/pausa; só simula. Se um dia ganhar o botão "executar de
verdade", isso é a Feature 7, com toda a auth que ela exige. Manter os dois separados é
disciplina de escopo.

---

## 7. Orquestração cross-máquina disparada do console

**O que é.** Botões de ação real: *"pausar autosync em todas as máquinas"*,
*"forçar `idea-doctor` no Mac mini agora"*, *"disparar SOAK heartbeat na frota"*,
*"re-selar security-freshness após revisão"*. O console deixa de ser só leitura e vira
**painel de comando** sobre os daemons e scripts já existentes
(`autosync-pause.sh`, `launchctl kickstart`, `check-soak.sh --record`,
`check-security-freshness.sh --record`).

**Por que é wow.** Fecha o loop: ver o problema *e* agir, do mesmo lugar. A ação local
é trivial (os scripts existem). A ação **cross-máquina** é o sonho do modelo local-first:
disparar algo no Mac mini a partir do MacBook.

**Viabilidade — precisa de X (e o X é sério).** Ação **local** já dá: o console roda na
máquina e chama os scripts. Ação **cross-máquina** precisa de um **canal de comando** —
e aqui o IdeiaOS tem um truque elegante: ele **já propaga estado via git** (branch
`planning`, autosync). Um padrão viável é **comando-via-commit**: o console escreve um
"intent file" num branch, o autosync propaga, e um hook na máquina-alvo o executa e
responde via ledger. Lento (ciclo de 900s) mas **auditável e sem abrir porta de rede**.
Alternativa rápida (SSH/socket) é mais ágil mas abre superfície de ataque.

**Risco — ALTO.** Este é o único item que vira **vetor de RCE cross-máquina** se mal
feito. Disparar execução remota a partir de um console web exige: (a) **autoridade** —
só `@devops` controla daemons/CI (`agent-authority`); o console não pode contornar isso;
(b) o anti-padrão de comando-via-commit precisa de **comando assinado/whitelist**, senão
qualquer commit malicioso no branch vira execução; (c) o gate de push do harness
bloqueia `git push` por substring — operações sancionadas exigem
`AIOX_ACTIVE_AGENT=devops` (learning `devops-push-gate-command-scoped-agent`).
**Recomendação cética:** shippar **leitura + ações locais** primeiro; ação cross-máquina
só depois de um design de segurança dedicado (provavelmente um `/spec` próprio com
threat-model). Não é MVP. É v3 do console.

---

## 8. Health-score vivo por produto

**O que é.** Um cartão por produto (cfoai, ideiapartner, lapidai, nfideia, IdeiaOS) com
um **score composto**: `idea-doctor` (se rodável no repo), tier de security-freshness,
drift de versões, contenção Lovable (5/5?), recência do último commit humano, último
deploy Lovable (via MCP read-only `get_project_analytics`). Verde/amarelo/vermelho, com
drill-down.

**Por que é wow.** Visão de frota num relance — o CTO vê os 5 produtos como 5 sinais
vitais. O Lovable MCP read-only (v10 SHIPPED) já dá `list_projects`,
`get_project_analytics`, `get_project_analytics_trend`, preview/editor URLs — então o
cartão pode até **linkar o preview live** e mostrar tendência de deploy.

**Viabilidade — já dá.** Cada sub-sinal tem comando: `idea-doctor.sh` (exit-code +
seções), `check-security-freshness.sh --tier` (palavra única `ok|warn|egregious`),
`git log` (recência), Lovable MCP (analytics). É **composição de readers existentes**.

**Risco — baixo.** Cuidado de não inventar um "score mágico" opaco. Mitigação: o score é
**transparente e drilldownable** — cada cor explica de quais sub-sinais veio. E para
produtos Lovable: `idea-doctor` é do IdeiaOS, não roda igual nos produtos; usar o que
**realmente** existe lá (security-freshness via `SECFRESH_ROOT`, git, Lovable MCP), não
forçar checks que não se aplicam.

---

## 9. Security-freshness como semáforo permanente + escada de escalonamento

**O que é.** Um badge permanente no header do console: **fresco / stale / egrégio**,
alimentado por `check-security-freshness.sh --tier`. Quando degrada, o console mostra a
**escada**: o que tocou superfície crítica (auth, RLS, secrets, env), há quanto tempo
ninguém revisa, e o botão *"agendar `@security-reviewer` no diff desde o último selo"*.
Por produto e para o IdeiaOS.

**Por que é wow.** Materializa a rule `security-freshness` (rigor = risco × idade) num
lugar que o CTO vê o tempo todo. É o oposto do "rodar audit quando lembrar": o frescor de
segurança vira um **sinal vital permanente**, risk-weighted e determinístico. O ledger já
existe (`bootstrap|BASELINE @ a2f1a68`); falta o surfacing contínuo.

**Viabilidade — já dá.** O script emite uma palavra parseável e o ledger é texto
pipe-delimited. O console lê e renderiza. O `idea-doctor §14` já consome o mesmo tier.

**Risco — baixo.** O risco é o badge **gatear algo** indevidamente — proibido: o 1º ciclo
é advisory (`SECFRESH_GATE_ENABLED=0`), e o único ponto que trava é o `git tag` do
IdeiaOS no tier egrégio, **nunca** PR de feature. O console respeita isso: ilumina, não
bloqueia. Cross-link learning `automate-the-reminder-not-the-integrity-stamp` — o console
pode **lembrar** de re-selar, mas **nunca carimbar** o selo automaticamente (isso fraudaria
a distinção de ator real que o gate protege).

---

## 10. Mapa de superfície de credenciais — control-plane, jamais cofre

**O que é.** Uma matriz **provedor × projeto**: para cada var do `.env.example` canônico
(`ANTHROPIC_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `OPENROUTER_API_KEY`, `VERCEL_TOKEN`,
`GITHUB_TOKEN`, …) e cada produto, o console mostra **presença (sim/não)**, **idade do
arquivo `.env`** (`stat -f %m`), **classe de risco** (service_role=crítica, anon=baixa,
NODE_ENV=nenhuma), e **var órfã** (no `.env` mas não no `.env.example`). Para contas:
`gh auth status` (contas GitHub + scopes), `~/.claude.json` (conta OAuth + modelo),
Cursor MCP auth (quais plugins OAuth por projeto). **Tudo metadado. Zero valor.**

**Por que é wow.** É a "central de gestão de chaves" que o CTO pediu — mas feita do jeito
**certo**: control-plane puro. Responde *"que produtos ainda não têm `VERCEL_TOKEN`?"*,
*"que `.env` está velho e talvez precise rotação?"*, *"a service_role do nfideia está
referenciada em quantos lugares?"* (liga à Feature 6). Surfacia a superfície de risco
real que o recon mapeou: a `SUPABASE_SERVICE_ROLE_KEY` é o secret de maior blast-radius
do ecossistema (bypassa RLS). O console a **destaca como crítica** sem nunca exibi-la.

**Viabilidade — já dá.** `grep '^[A-Z_]*=' .env | sed 's/=.*//'` (nomes), `stat`
(mtime), `diff` contra `.env.example`, `gh auth status`, leitura de `~/.claude.json`. Os
readers estão na tabela `reusableForConsole`.

**Risco — ALTO se mal-feito; baixo se feito certo.** A tentação fatal é mostrar "só uma
prévia" do valor, ou ler o RHS "para validar". **Proibido por lei** (`credential-isolation`):
o segredo nunca entra no contexto do LLM nem do browser. O console **nunca abre o `.env`
inteiro** — ele faz `grep` por prefixo de nome e `stat`, e ponto. Segundo risco: o
**próprio console** vira alvo (se ele lista onde estão as chaves, comprometê-lo é um mapa
do tesouro). Mitigação: o console roda **local**, não exposto à rede; a matriz é
metadado-only, então comprometê-lo revela *nomes e idades*, não *valores* —
blast-radius limitado por design. Auditar também o **log do envsync** para garantir que
ele nunca loga valores (gap apontado no recon).

---

## 11. Atlas de instincts — maturidade do agente por domínio

**O que é.** Um mapa de calor da **maturidade do agente de IA por domínio**:
`~/.ideiaos/instincts/` tem instincts atômicos com `confidence` (0-1) e
`evidence_count`. O console agrega: quais domínios (git, bash, typescript, sql, yaml) têm
reflexos consolidados (confidence ≥0.7, evidence alto) vs emergentes; quantos instincts
estão maduros e prontos para `/evolve` (promoção a `source/rules/` ou vault). Um
"skill-tree" do agente.

**Por que é wow.** É a métrica que só existe num OS que **aprende sobre si mesmo**. Mostra
*onde o agente já é confiável* e *onde ainda está aprendendo* — informação de CTO sobre a
parte sintética da equipe. Baseado em 1500+ observações de 99 sessões (instinct-analyze
jun/2026). Vira gatilho visual para `/evolve` ("3 instincts maduros prontos para
promover").

**Viabilidade — já dá.** Os instincts são `.md` com frontmatter parseável
(`confidence:`, `evidence_count:`). Agregação é `find + grep + awk`. Zero coleta nova.

**Risco — baixo, com uma armadilha conceitual.** A rule
`learning-channel-routing` é explícita: **instincts são write-only, NÃO injetados no
contexto ao vivo** — são *telemetria comportamental*, não fonte de conduta. Então o
console deve rotular o atlas honestamente como **"maturidade observada de padrões"**, não
como "o que o agente vai fazer". E não promover instinct de **telemetria de frequência**
("usou grep N vezes") como se fosse reflexo de engenharia — isso violaria `token-economy`
(curadoria, não dump). O atlas *mostra*; `/evolve` *decide*.

---

## +1 (bônus). Black-box / flight-recorder de incidentes

**O que é.** Quando a detecção proativa (Feature 3) acende um *critical*, o console
**congela um pacote forense**: o estado do OS naquele instante (via Feature 2,
time-travel), o diff que causou, os últimos heartbeats, o tier de segurança, os daemons
ativos. Um "caixa-preta" datado, salvo num ledger append-only de incidentes. Depois, o
CTO Copiloto (Feature 1) responde *"o que aconteceu no incidente de 14/06?"* lendo o
pacote.

**Por que é wow.** Os learnings do IdeiaOS **são post-mortems escritos à mão**. Esta
feature os geraria **automaticamente** no momento do incidente, com evidência fresca, em
vez de reconstruir depois de memória. Conecta a história inteira: detecção (3) → snapshot
(2) → narrativa (1) → aprendizado (`/extract-learnings`, `/evolve`).

**Viabilidade — precisa de X.** O X é pequeno: um ledger de incidentes append-only e o
gatilho que, no critical, chama o folder do time-travel e serializa. Reusa Features 2 e 3.

**Risco — médio.** O pacote forense **pode capturar texto sensível** (nomes de var,
paths). Lei: mesmo filtro `credential-isolation` — nomes e metadados, nunca valores. E o
ledger de incidentes não pode crescer sem bound (cf. learning do `git-autosync.log` sem
rotação) — precisa de retenção/rotação desde o dia 1.

---

## Veredito do cético: o que shippar, em que ordem, e o que recusar

**Wave 1 (semanas, não meses) — surfacing puro, read-only, alto valor:**
Features **2 (time-travel)**, **3 (drift proativo)**, **8 (health-score)**,
**9 (security badge)**, **10 (mapa de credenciais control-plane)**, **11 (atlas de
instincts)**. Todas "já dá", todas determinísticas, todas respeitam `credential-isolation`
trivialmente. Este é o MVP que prova a tese — e é construível porque **o substrato já
existe** e o stack é o canônico dos 4 produtos (Vite+React+TS+Tailwind+shadcn/ui+Recharts).
Assets reusáveis: `KPICard`/`AppLayout`/`AppSidebar` do nfideia, theme dark do
cfoai-grupori, o THEME object do graph-dashboard (preto/ouro), os componentes
`HealthScore`/`TrendChart` do health-dashboard.

**Wave 2 — exige parser/grafo novo mas baixo risco:**
Features **1 (CTO copiloto)**, **4 (token-cost)**, **5 (frota humano×agente)**,
**6 (simulador what-if)**. Precisam de costura (grafo de dependência, parser de custo,
anti-injection wrapper) mas nada de superfície de ataque nova.

**Wave 3 — só com design de segurança dedicado:**
Feature **7 (orquestração cross-máquina com ação real)**. É a única que abre vetor de
RCE. Não é MVP; exige `/spec` próprio + threat-model + respeito a `agent-authority`
(@devops exclusivo). O bônus **+1 (black-box)** entra junto, pois depende de 2 e 3 já
maduros.

**O que eu recuso por convicção (push-back honesto):**
- **Ranking de produtividade individual de humanos.** Fácil de construir, fácil de
  abusar, ético-tóxico. Métrica do sistema (humano+IA entregando) e saúde, sim;
  leaderboard de pessoas, não — a menos que o CTO peça explicitamente e assuma o trade-off.
- **Qualquer "prévia" de valor de segredo.** Não negociável. O console é control-plane.
- **Ação cross-máquina no MVP.** Sedutor, mas é o único caminho para um RCE. Espera a
  Wave 3 com segurança desenhada.

**A frase que resume o produto:** *Mission Control não coleta dados — ele dá rosto,
voz e memória a um OS que já se observa.* Tudo o mais é surfacing disciplinado sobre um
substrato que já tem proveniência, idade e verificação por exit-code. Esse é o ângulo que
o torna **viável em semanas** e, ao mesmo tempo, **jamais visto** — porque ninguém mais
tem um OS de IA que se auto-telemetra cross-máquina via git.
