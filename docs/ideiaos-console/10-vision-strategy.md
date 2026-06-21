# IdeiaOS Mission Control — Visão & Estratégia de Produto

> Documento 10 · Camada: Visão/Estratégia · Persona-autor: PM/CTO-visionário · Status: **PROPOSTO**
> Codinome de trabalho: *Mission Control*. Nome final proposto neste documento (§2): **IdeiaOS Bridge**.
> Data: 2026-06-20 · Branch: `work`

---

## 0. TL;DR (para quem tem 60 segundos)

O IdeiaOS **já se auto-telemetra**. Cada máquina, cada produto, cada commit, cada heartbeat de saúde, cada selo de segurança, cada sessão de IA já deixa rastro determinístico em arquivo — SOAK ledgers, security-freshness ledger, git log, `versions.lock`, observações JSONL, LaunchAgents, `idea-doctor`. O sistema operacional de desenvolvimento da Ideia Business **não precisa de mais sensores**. Precisa de uma **ponte de comando**: uma camada de *surfacing* + *controle* que leia o substrato que já existe e o transforme em visão de CTO em tempo real.

Esse é o produto. Não é "mais um dashboard". É a **ponte de comando de um OS que já voa por instrumentos** — a tela que faltava num avião que já tem todos os instrumentos a bordo, mas cujo único jeito de lê-los hoje é abrir 14 arquivos no terminal.

**One-liner:** *A ponte de comando do IdeiaOS — todas as máquinas, contas, produtos, chaves e a produtividade de IA do seu ecossistema, numa só tela de CTO. Controle, não cofre.*

**North-star:** **Time-to-Truth** — segundos entre "tenho uma pergunta de CTO sobre o ecossistema" e "tenho a resposta confiável, sem abrir um terminal".

---

## 1. O "porquê" — a dor real que isto mata

### 1.1 O CTO-de-um-só (solo operator com escala de time)

A Ideia Business opera num regime que está se tornando o regime dominante da indústria pós-2025: **um operador, um exército de agentes**. Gustavo é simultaneamente CTO, tech-lead e principal contribuidor de **5 codebases** (`nfideia`, `ideiapartner`, `cfoai-grupori`, `lapidai`, `IdeiaOS`), distribuídas em **2+ máquinas** (MacBook-Air, Mac mini), tocadas por **3 IDEs** (Claude Code, Cursor, Lovable) e **5+ provedores de IA** (Anthropic, OpenRouter/DeepSeek, OpenAI, Ollama, EXA), sobre **4 instâncias Supabase distintas**, com deploy automático Lovable em vários produtos.

O recon não é abstrato. É medido: `nfideia` tem **737 sessões** de Claude Code e **535 migrations**; `ideiapartner`, **361 sessões** e **815 migrations**; o `IdeiaOS` em si, **13 milestones** (v2→v13) entregues em ~3 semanas. Isso é o output de uma fábrica — operada por uma pessoa que orquestra IA.

**A dor:** não existe uma única superfície que responda às perguntas que essa pessoa faz dez vezes por dia.

- *"O Mac mini está sincronizado e saudável agora, ou divergiu?"* → hoje: ler `git log` remoto + cruzar com SOAK ledger, à mão.
- *"Em quais dos 5 produtos a deny-list de 19 tools mutantes do Lovable regrediu?"* (isso **já aconteceu**: 5/5 → 2/5 → remediado) → hoje: rodar `idea-doctor` em cada repo.
- *"Quando foi a última revisão de segurança do `cfoai`, e o tier está fresco?"* → hoje: abrir o `review-ledger.log` de cada produto.
- *"O `SUPABASE_SERVICE_ROLE_KEY` está presente onde deveria, e em lugar nenhum onde não deveria?"* → hoje: nenhum lugar único responde.
- *"Onde meu tempo de IA foi gasto esta semana — e quanto disso foi entrega real vs. ruído de autosync?"* → hoje: impossível sem um parser ad-hoc.

Cada uma dessas respostas **existe num arquivo determinístico**. Nenhuma delas tem uma tela. Esse é o vão. Esse é o produto.

### 1.2 Por que isto dói AGORA (e não doía há 18 meses)

Porque o regime "1 humano + N agentes" inverteu a economia da observabilidade. Quando um time tem 8 engenheiros, a observabilidade do *trabalho* é social — você sabe quem está fazendo o quê porque conversa com eles. Quando o "time" são 40 sessões de agente espalhadas por 5 repos e 2 máquinas, **o estado do trabalho deixou de ser legível por conversa** e passou a viver só em rastros de máquina. O CTO perdeu o sentido periférico do próprio sistema. O Mission Control devolve esse sentido — é **propriocepção para um corpo que cresceu mais rápido que os nervos**.

### 1.3 A frase que define o ângulo

> O IdeiaOS é um avião que já voa por instrumentos. Faltava a cabine. O Mission Control não constrói os instrumentos — constrói a **bridge** de onde se lê todos eles e se aciona os comandos.

---

## 2. NOME do produto

Três candidatos fortes, avaliados, e a escolha justificada.

### Candidato A — **IdeiaOS Bridge** ✅ ESCOLHIDO

A *bridge* (ponte de comando) é o lugar de um navio/nave de onde se comanda tudo, lê-se todos os instrumentos e se toma a decisão. Captura a metáfora central — **um OS que já tem todos os sensores, faltava o posto de comando** — sem prometer o que o produto não é.

- **Pró:** preciso (é exatamente um *control plane*, não um data lake); curto; soa premium e técnico sem ser pomposo; "bridge" também evoca a *ponte entre máquinas/IDEs/contas* que o produto literalmente faz; herda o equity da marca-mãe (`IdeiaOS Bridge`, como `macOS Finder`).
- **Contra:** "bridge" tem uso colidente em integração de dados (data bridges) — mitigável pelo prefixo `IdeiaOS`.
- **Veredito:** vence porque é o **único nome que descreve a função arquitetural real** (control plane de leitura + comando) em vez do artefato visual (dashboard). Diferencia do "mais um dashboard" já no nome.

### Candidato B — **Cockpit**

A cabine de pilotagem. Forte na metáfora "voar por instrumentos", muito alinhado ao §1.3.

- **Pró:** imagem mental imediata de "uma pessoa, muitos instrumentos, controle total"; agressivo e memorável.
- **Contra:** **saturado** — "cockpit" virou nome genérico de painel admin em dezenas de produtos SaaS; perde a distintividade que o produto merece. E "cockpit" enfatiza *pilotar* (operação contínua) mais que *comandar* (decisão estratégica), que é o registro de CTO.

### Candidato C — **Atalaia** (PT-BR)

Atalaia = torre de vigia, posto elevado de onde se enxerga todo o território e se dá o alarme. Profundamente alinhado à cultura PT-BR do projeto (todo o IdeiaOS opera em português) e à função de *vigilância de saúde + alerta* (security-freshness, deny-list regression, autosync divergence).

- **Pró:** **zero colisão** no espaço de produtos dev; lindo, raro, culturalmente enraizado; "torre de vigia" casa exatamente com a postura de *alertar antes do incidente* (a regressão da deny-list teria sido pega por uma atalaia); reforça a identidade Ideia Business PT-BR como um diferencial, não um detalhe.
- **Contra:** enfatiza *vigilância* (passivo, observação) sobre *comando* (ativo, controle) — e o produto precisa ser os dois; menos auto-explicativo para quem não conhece a palavra.

### Decisão

**Nome canônico: `IdeiaOS Bridge`.** Subtítulo de produto: *Mission Control*. Convenção de marca: `IdeiaOS Bridge — Mission Control`, encurtável para **"a Bridge"** no dia-a-dia (como "o Finder").

**Por quê Bridge e não Atalaia, dado o carinho cultural?** Porque o produto é **control plane antes de ser watchtower**. Ele *lê e comanda* (pausar autosync, forçar heartbeat, disparar revisão de segurança, reabilitar/conter MCP). Atalaia descreveria perfeitamente metade da alma (a vigilância) e subdescreveria a outra metade (o comando). `Bridge` cobre as duas. Reservamos **Atalaia** como nome do **subsistema de alertas** dentro da Bridge — "os alertas da Atalaia" — preservando o equity cultural sem comprometer a precisão do nome do produto. (Decisão sujeita a override do usuário via `/grelha`; ver §13.)

---

## 3. Os Pilares (5)

Cada pilar é uma promessa funcional ancorada num substrato de dados **que já existe** (a viabilidade vem daí). A ordem é deliberada: é a ordem de prioridade de valor para o CTO.

### Pilar 1 — **Frota** (Fleet Health)
*"Quais máquinas existem, estão sincronizadas e saudáveis — agora."*

A visão de **propriocepção cross-máquina**. Substrato: SOAK ledger (`.planning/soak/*.log` — hostname, epoch, `idea_doctor=PASS/FAIL`, `regression=PASS/FAIL`, commit), commits WIP do autosync (hostname embutido), `launchctl list | grep ideiaos` (status dos 3 daemons), `idea-doctor` (health-score parseável). Responde: *está tudo verde, e há quanto tempo o Mac mini não dá sinal de vida?*

**Não-óbvio:** o SOAK ledger nunca foi pensado como telemetria de frota — foi pensado como gate de maturação de milestone. A Bridge **reaproveita o ledger como heartbeat de máquina**. Custo de instrumentação: zero.

### Pilar 2 — **Constelação** (Products & Pipelines)
*"Cada produto, sua stack, seu deploy, sua velocidade real."*

A visão de **portfólio**. Substrato: `git log` filtrado (humano vs. bot Lovable `gpt-engineer-app[bot]` vs. autosync vs. CI), `supabase/config.toml` (project_id por produto), `git remote -v`, Lovable MCP read-only (`list_projects`, `get_project_analytics`, `verify-deploy`), session transcripts JSONL. Responde: *qual produto está quente esta semana, quem commitou (humano ou IA), quando foi o último deploy Lovable, e o produto está IN_SYNC?*

**Não-óbvio:** distingue **velocidade real** de **vaidade**. Commit raw inclui autosync e bots; a Bridge filtra para `feat`/`fix` de autor humano. É a única métrica honesta de entrega.

### Pilar 3 — **Cofre-Espelho** (Credentials Control Plane)
*"Onde cada chave existe, qual seu escopo, há quanto tempo não roda — nunca o valor."*

A visão de **gestão de credenciais por referência**. Este é o pilar de maior risco e maior diferenciação. Substrato: nomes de variáveis (`grep '^[A-Z_]*=' .env | sed 's/=.*//'` — **só nomes, nunca valores**), `.env.example` como contrato, `stat` (idade do arquivo), `gh auth status` (contas/scopes via Keychain), envsync log (último sync, sem valores), catálogo de risco classificado (service_role=crítico, anon_key=baixo).

**Regra-piso inegociável (rule `credential-isolation`):** a Bridge é **control plane / metadata** — mostra *existe? idade? escopo? last-used? rotação pendente?* — e **JAMAIS** o valor em plaintext. Um segredo nunca transita pelo contexto do LLM nem pelo browser. Isto não é uma feature: é a fronteira constitucional que torna o pilar legítimo. Ver §7.

**Não-óbvio:** o ecossistema já tem `credential-isolation` *bem implementada* — as chaves reais nunca aparecem em arquivo lido. Isso significa que o Cofre-Espelho **não precisa inventar segurança**: ele apenas surface o metadado que já está seguro por design. O risco é só não regredir essa garantia na UI.

### Pilar 4 — **Sinapse** (AI & MCP Connections)
*"Quantas contas de cada IA, quais MCPs ligados onde, e a contenção está de pé?"*

A visão de **inventário de IA**. Substrato: `~/.claude.json` (conta OAuth, modelo, effort), `.claude/settings.json` (MCPs habilitados/desabilitados por projeto, deny-list de 19 tools), `~/.cursor/mcp.json` (MCPs do Cursor), `core-config.yaml` (IDEs habilitadas), Lovable MCP UUID. Responde: *quais provedores de IA estão conectados, em quais produtos o Lovable MCP está contido (deny=19), e algum MCP de alto risco foi reabilitado sem revisão?*

**Não-óbvio:** a regressão real da deny-list (5/5 → 2/5 → remediado) **prova que este pilar é necessário, não decorativo**. Uma tela que mostrasse `deny=19 em 3/5 ⚠️` teria pego a regressão no minuto em que aconteceu. Sinapse é o pilar que transforma um incidente reativo num alerta preventivo.

### Pilar 5 — **Pulso** (Productivity & Delivery)
*"Onde o tempo de IA virou entrega real — sinal, não vaidade."*

A visão de **produtividade honesta**. Substrato: session transcripts JSONL (sessões com `human_turns > 5` = trabalho cognitivo real; sub-2-turns = ruído de subagente), `git log` de autor humano por tipo (`feat`/`fix`), SOAK ledger (milestones validados cross-máquina = "entrega verificada"), security-freshness ledger (responsabilidade técnica ao longo do tempo), instincts agregados (maturidade do agente por domínio). Responde: *esta semana, quanto trabalho cognitivo real aconteceu, em quais produtos, e quanto virou entrega validada?*

**Não-óbvio (e a tese mais forte do produto):** o Pulso **se recusa a contar vaidade**. Total de commits raw mente (inclui autosync/bots/docs triviais). Tamanho de transcript mente (correlaciona com tokens, não valor). Contagem bruta de sessões mente. A Bridge mede só os quatro sinais honestos: commits humanos por tipo, sessões-com-substância, milestones validados em SOAK, e frescor de segurança. **Isto é uma posição de produto, não só uma feature** — e é o que a separa de qualquer painel de métricas de vaidade existente.

### (Pilar 6 candidato, fase 2) — **Atalaia** (Alerts & Drift)
*"O que mudou e merece seu olhar — antes de virar incidente."*

Camada transversal de alertas: drift de versão (`versions.lock` vs. instalado), regressão de deny-list, autosync parado/divergente, security-tier→stale/egregious, `.env` órfão, milestone PARCIAL pronto-para-tag (span ≥1d). Inicialmente pode ser um *strip* dentro dos 5 pilares; promovido a pilar próprio quando a lógica de regras amadurecer. Preserva o equity cultural do nome "Atalaia" (§2).

---

## 4. Diferenciais — por que isto é "jamais visto"

Não basta ser bom; o briefing pede "jamais visto". Aqui está a defesa honesta de por que este produto é categoricamente diferente — e onde NÃO é (anti-sicofância, conduta 3).

### 4.1 O diferencial estrutural: **surfacing sobre substrato auto-telemetrado, não coleta greenfield**

Todo "console de CTO" do mercado começa instrumentando: instale o agent, configure o webhook, conecte o data warehouse, espere semanas de dados acumularem. **A Bridge começa já cheia.** O IdeiaOS produz, desde a v2, ledgers commitados, observações JSONL, gates determinísticos com exit-code, heartbeats cross-máquina. O produto é uma **camada de leitura sobre um data substrate que se preenche sozinho há 13 milestones**. Isso muda a natureza do produto de "projeto de instrumentação" (caro, lento, falível) para "projeto de surfacing" (rápido, barato, viável). **Esse é o ângulo que torna isto exequível por uma pessoa em dias, não meses — e por isso "jamais visto" no contexto de um OS de IA pessoal.**

### 4.2 O diferencial filosófico: **control plane, não cofre**

A maioria dos painéis de credenciais é um cofre — guarda e exibe segredos. A Bridge é o oposto arquitetural: **mostra tudo sobre a chave exceto a chave**. Esta inversão (metadata-first, value-never) não é uma limitação de segurança bolt-on; é a **postura nativa** herdada da `credential-isolation`. É raro um produto de gestão de chaves cujo design-piso é *nunca tocar o segredo*. Isso o torna seguro-por-construção e auditável.

### 4.3 O diferencial de honestidade: **mede entrega, recusa vaidade**

Painéis de produtividade quase universalmente vendem vaidade (commits, linhas, "atividade") porque é o que é fácil de contar. A Bridge toma a posição oposta e **mais difícil**: filtra atores não-humanos, ignora ruído de autosync, e ancora "entrega" no único sinal que passou por validação cross-máquina (SOAK). Um CTO que confia nessa métrica confia porque ela **se recusa a inflar**.

### 4.4 O diferencial nativo: **a Bridge é parte do OS, não um observador externo**

Ela não *monitora* o IdeiaOS de fora via API. Ela **é uma faceta do IdeiaOS**, lendo os mesmos arquivos que `idea-doctor` lê, respeitando as mesmas rules (`credential-isolation`, `agent-authority`, `mcp-hygiene`), rodando local-first como o resto do OS. Os botões de comando dela (pausar autosync, forçar heartbeat, disparar `@security-reviewer`) são os **mesmos scripts sancionados** que o CLI já expõe — a UI é um *front* sobre `autosync-pause.sh`, `check-soak.sh`, `check-security-freshness.sh`. **Zero caminho de comando novo = zero superfície de ataque nova.** Isto é o que nenhum dashboard externo pode oferecer: ele herda a constituição do sistema que observa.

### 4.5 Onde NÃO é mágico (a verdade que vende o resto)

- **Não há usuários-finais dos produtos.** A Bridge vê desenvolvimento, não runtime de produto. "Usuários conectados a cada projeto" no briefing = **contributors do repo**, não end-users do Supabase Auth (acessar isso violaria `credential-isolation`). Isto precisa ser dito com clareza para não prometer o que o substrato não dá.
- **Multi-usuário humano é raso hoje.** Toda atividade está sob um ator (`gustavo@`). "Relatório de produtividade por usuário" só fica rico se/quando houver `desenvolvimento@ideiabusiness.com.br` ativo em volume — o substrato suporta (git author email), mas o sinal hoje é majoritariamente single-operator.
- **Cross-máquina é assíncrono.** A saúde do Mac mini chega via git (SOAK ledger commitado + WIP commits), não via conexão ao vivo. "Tempo real" significa "tão real quanto o último autosync de 15 min" — honesto, não instantâneo.
- **`idea-doctor` ainda não emite JSON.** O parsing por seções é frágil; o caminho limpo é adicionar `--json` (ver dependências, §11).

Declarar estes limites **agora** é o que dá credibilidade ao "jamais visto" do resto. (Conduta `operating-discipline` §3 — push back com número, não promessa vazia.)

### 4.6 A frase de posicionamento contra o óbvio

> "Mais um dashboard" coleta dados que você não tem e os mostra bonitos. A Bridge **comanda um OS que já tem todos os dados** — e por isso ela já nasce cheia, segura por construção, e parte do próprio sistema que observa. Não é uma janela para o IdeiaOS. **É a cabine dele.**

---

## 5. Personas

Três personas, em ordem de prioridade. A primeira é o caso de uso fundador (Gustavo, hoje); as outras duas são o horizonte de generalização (quando o IdeiaOS for usado por outros).

### Persona 1 — **O CTO-de-um-só** (P0, é quem existe hoje)
*"Gustavo": fundador-CTO-tech-lead-IC, dono de 5 produtos, 2 máquinas, deploy Lovable.*

- **Contexto:** orquestra IA o dia inteiro através de 3 IDEs; é o único humano com visão de todo o ecossistema; o gargalo é a **largura de banda da própria atenção**, não a capacidade de execução (a IA executa).
- **Dor central:** perde o sentido periférico do sistema — não sabe, sem investigar, se algo regrediu, divergiu, ou apodreceu (CVE, deny-list, autosync).
- **O que a Bridge faz por ele:** devolve propriocepção. Uma tela responde "está tudo verde?" e, quando não está, aponta exatamente onde, com o botão de remediar ao lado.
- **Momento de uso:** abre a Bridge ao começar o dia (estado da frota), antes de um release (SOAK + security gates), e quando o instinto diz "algo está estranho" (Atalaia).

### Persona 2 — **O Líder de Squad** (P1, horizonte próximo)
*Lidera um time pequeno (2-5 devs humanos + agentes) sobre um subconjunto dos produtos.*

- **Contexto:** precisa saber quem (humano ou agente) está mexendo em quê, sem microgerenciar; responde por velocidade e saúde de 1-2 produtos.
- **Dor central:** atribuição — distinguir trabalho humano de output de IA, e velocidade real de ruído.
- **O que a Bridge faz por ele:** o Pulso filtrado por ator e por produto; a Constelação como visão de portfólio do squad; alertas de drift no escopo dele.
- **Pré-requisito de produto:** o campo de ator (`git author email`) precisa ganhar sinal real (mais de um humano ativo) — substrato existe, dado ainda é raso (§4.5).

### Persona 3 — **O Dev Individual** (P2, horizonte)
*Um IC humano que trabalha num produto, com agentes como copilotos.*

- **Contexto:** foco num repo; quer saber seu próprio pulso e o estado do que afeta seu trabalho (deploy, migrations, security tier do produto).
- **Dor central:** falta de feedback sobre o próprio impacto e sobre o estado do produto que toca.
- **O que a Bridge faz por ele:** uma visão *scoped* a um produto — meu Pulso, último deploy, migrations recentes, tier de segurança do meu repo.
- **Nota:** P2 porque o valor incremental sobre "abrir o próprio terminal" é menor para quem só toca um repo — a Bridge brilha na **visão de portfólio**, não na de repo-único. Honestidade de escopo.

---

## 6. Jobs-to-be-done (JTBD)

Formulados como *quando…, eu quero…, para…* — cada um mapeado a um pilar e a um substrato real.

| # | Job (quando… quero… para…) | Pilar | Substrato |
|---|------------------------------|-------|-----------|
| J1 | Quando começo o dia, quero ver num relance se **toda a frota está sincronizada e saudável**, para saber se posso confiar no estado antes de trabalhar. | Frota | SOAK ledger, autosync log, `launchctl`, `idea-doctor` |
| J2 | Quando vou fazer um release, quero ver se o **SOAK e o security-gate passam**, para não taguear sobre base imatura ou insegura. | Frota+Atalaia | `check-soak.sh`, `check-security-freshness.sh --gate` |
| J3 | Quando suspeito de regressão de contenção, quero ver **em quantos produtos a deny-list de 19 tools está de pé**, para remediar antes que vire incidente. | Sinapse | `.claude/settings.json` deny-list por produto |
| J4 | Quando audito credenciais, quero ver **quais chaves existem, onde, e há quanto tempo não mudam — nunca o valor**, para gerir rotação sem nunca expor segredo. | Cofre-Espelho | nomes de var, `.env.example`, `stat`, `gh auth status` |
| J5 | Quando reviso a semana, quero ver **entrega real por produto e por ator** (humano vs. IA, feat vs. ruído), para saber onde o esforço virou valor. | Pulso | git log filtrado, JSONL `human_turns>5`, SOAK |
| J6 | Quando algo parece estranho, quero **um feed de alertas do que mudou e merece olhar** (drift, stale security, autosync parado), para agir preventivamente. | Atalaia | `versions.lock` diff, ledgers, `launchctl` |
| J7 | Quando preciso agir, quero **disparar o comando dali mesmo** (pausar autosync, forçar heartbeat, rodar revisão de segurança), para fechar o loop sem trocar de contexto. | Todos | `autosync-pause.sh`, `check-soak.sh --record`, `@security-reviewer` |
| J8 | Quando quero ver o portfólio de IA, quero saber **quantas contas de cada provedor, quais MCPs ligados onde**, para entender minha superfície de IA. | Sinapse | `~/.claude.json`, `~/.cursor/mcp.json`, `core-config.yaml` |

**O JTBD que define a alma do produto é J7** — a Bridge não é leitura passiva; é **comando**. Toda métrica que merece ação tem o botão de ação ao lado, e esse botão chama um script sancionado (não inventa caminho novo). Sem J7, é "mais um dashboard". Com J7, é uma *bridge*.

---

## 7. A fronteira de segurança (não-negociável)

Este é o único bloco do documento que **não admite trade-off**. É o piso constitucional (rules `credential-isolation`, `agent-authority`, `mcp-hygiene`).

1. **Control plane, nunca cofre.** A Bridge exibe metadado de chave (nome, presença, idade, escopo, last-used, tier de risco). **Nunca** o valor. Um segredo jamais transita pelo contexto do LLM, pela rede do browser, ou por um log.
2. **Leitura por nome, não por valor.** Para saber "a `SUPABASE_SERVICE_ROLE_KEY` existe no `.env` do `nfideia`?", a Bridge faz `grep '^SUPABASE_SERVICE_ROLE_KEY=' .env >/dev/null && echo presente` — **nunca** lê o que vem depois do `=`.
3. **Output é superfície (OWASP LLM02).** Se qualquer parte da Bridge for gerada/assistida por LLM, o output passa por checagem anti-eco-de-segredo antes de renderizar.
4. **Comando = script sancionado, não caminho novo.** Os botões de ação chamam exatamente os scripts que o CLI já expõe e que respeitam `agent-authority` (ex.: `git push` continua exclusivo de `@devops`; a Bridge **não** ganha autoridade de push). Least-privilege (OWASP LLM06 — Excessive Agency): a Bridge tem só a capacidade que cada job exige.
5. **MCP read-only.** A integração Lovable é read-only; as 19 tools mutantes permanecem em deny-list. A Bridge **não** abre caminho de escrita via MCP.

Qualquer feature que viole 1-5 é **rejeitada na origem**, independentemente do valor de produto. Isto é o que torna o pilar Cofre-Espelho legítimo em vez de uma bomba.

---

## 8. North-Star Metric & métricas de apoio

### North-star: **Time-to-Truth (TtT)**

> Mediana de segundos entre uma **pergunta de CTO sobre o estado do ecossistema** e a **resposta confiável**, sem abrir um terminal.

**Por que esta é a north-star certa:**
- **Captura a tese inteira.** O produto não cria dados (já existem); cria *acesso veloz e confiável* a eles. TtT mede exatamente isso.
- **É honesta.** Não é uma métrica de vaidade (uso, pageviews). É uma métrica de **valor entregue ao usuário** — quanto a Bridge encurta o caminho da pergunta à verdade.
- **É falsificável.** Baseline mensurável hoje: responder J1-J8 manualmente leva de **2 a 15 minutos** (abrir múltiplos terminais, rodar scripts, cruzar arquivos à mão). A meta é **< 10 segundos** por pergunta. Esse delta é o produto.
- **Alinha incentivos.** Otimizar TtT força o produto a ser rápido, legível e correto — não a acumular features ou inflar engajamento.

### Métricas de apoio (guardrails — para não otimizar TtT à custa de algo)

| Métrica | O que protege | Alvo |
|---------|---------------|------|
| **Trust Rate** | TtT é inútil se a resposta estiver errada. % de respostas da Bridge que batem com o ground-truth do arquivo. | 100% (determinístico; qualquer divergência é bug P0) |
| **Coverage** | Quantos dos JTBD J1-J8 a Bridge responde sem cair pro terminal. | 8/8 na v1.0 |
| **Zero-Leak invariant** | A métrica de segurança. Nº de valores de segredo que apareceram em qualquer superfície da Bridge. | **0, sempre** (binário; 1 é incidente) |
| **Freshness lag** | Quão "real" é o tempo real. Mediana de idade do dado cross-máquina exibido. | ≤ 1 ciclo de autosync (~15 min) |
| **Action close-rate** | A alma de J7. % de alertas acionáveis que têm botão de ação inline (vs. só leitura). | ≥ 80% dos alertas |

**A north-star em uma frase:** *quanto a Bridge encurta a distância entre a dúvida do CTO e a verdade do sistema — sem nunca vazar um segredo e sem nunca mentir uma métrica.*

---

## 9. Posicionamento (a defesa final contra "mais um dashboard")

| Eixo | "Mais um dashboard" (o óbvio) | IdeiaOS Bridge (a tese) |
|------|-------------------------------|--------------------------|
| **Origem dos dados** | Coleta greenfield (instale, conecte, espere) | Surfacing de substrato auto-telemetrado (já cheio) |
| **Relação com o sistema** | Observador externo via API | Faceta nativa do OS, lê os mesmos arquivos que o `idea-doctor` |
| **Credenciais** | Cofre (guarda/exibe segredo) | Control plane (metadata-first, value-never) |
| **Produtividade** | Vaidade (commits, linhas, atividade) | Entrega honesta (humano-filtrado, SOAK-validado) |
| **Ação** | Leitura passiva | Comando (botão = script sancionado, J7) |
| **Tempo até valor** | Semanas (dados acumulando) | Imediato (13 milestones de dados já no disco) |
| **Superfície de ataque** | Nova (novo serviço, novas creds) | Zero-novo-caminho (herda a constituição do OS) |

O produto não compete na categoria "dashboard". Ele cria uma categoria: **a bridge nativa de um OS de desenvolvimento de IA pessoal que já se auto-telemetra.** Isso só é possível *porque* o IdeiaOS passou 13 milestones construindo o substrato sem saber que estava construindo a fundação de uma cabine. **O Mission Control é a colheita de uma semeadura involuntária** — e é exatamente isso que o torna "jamais visto": ninguém mais tem essa semeadura.

---

## 10. Suposições materiais (surface assumptions — conduta 1)

Declaradas para correção barata agora:

- **S1 — Local-first.** A Bridge roda **localmente** (Vite/React + um leitor Node.js/Python sobre o filesystem), como o resto do OS. Não é um SaaS hospedado com banco central. *Se errado, muda tudo em §11/§7.*
- **S2 — Stack canônica herdada.** Vite + React + TS + Tailwind + shadcn/ui + Recharts — sem escolha nova (é o stack dos 4 produtos). Tema canônico: **preto/ouro do graph-dashboard** (`bg #000000`, `accent-gold #C9B298`, status nomeados), o template estético mais próximo é o `cfoai-grupori` (dark-first).
- **S3 — Leitura, não escrita, é o default.** 95% da Bridge é read-only. Os pontos de comando (J7) são exceções explícitas, cada uma um script sancionado existente.
- **S4 — "Usuários" = contributors, não end-users.** O briefing fala em "projetos + seus usuários"; o substrato só dá *contributors de repo*. End-users de produto exigiriam Supabase Auth de cada produto (viola `credential-isolation`). *Confirmar interpretação no §13.*
- **S5 — `idea-doctor --json` será adicionado.** O parsing por seção ANSI é frágil; assume-se que a v1 inclui um flag `--json`/`--porcelain` no `idea-doctor` como dependência (§11).
- **S6 — Mac mini é assíncrono.** Saúde cross-máquina chega via git, não conexão ao vivo. "Tempo real" = "último autosync".

→ **Corrija qualquer uma agora, ou sigo com estas como base dos documentos seguintes (arquitetura, escopo, UX).**

---

## 11. Dependências (para os documentos/fases seguintes)

- **D1 — `idea-doctor --json`** (ou `--porcelain`): saída estruturada parseável. Hoje a saída é ANSI para humano. *Bloqueia o health-score confiável da Frota.* (Gap reconhecido no recon.)
- **D2 — Camada de leitura unificada** (Node.js ou Python): normaliza os 4 formatos de substrato (pipe-delimited, JSONL, key=value, plist XML) num schema único. É o coração técnico da Bridge. *Não existe ainda.*
- **D3 — App Vite/React do console**: não existe; o `health-dashboard` (`.aiox-core/scripts/diagnostics/health-dashboard/`) é o protótipo mais próximo, mas usa CSS modules (não shadcn/ui) — recriar no stack canônico. Componentes reutilizáveis diretos: `nfideia/src/components/KPICard.tsx`, `AppLayout.tsx`, `AppSidebar.tsx`, `NotificationBell.tsx`, os 54 shadcn/ui de `nfideia`, e o tema HSL de `cfoai-grupori`.
- **D4 — Inventário de contas de IA**: não há arquivo único consolidando "contas por provedor"; a Bridge precisa derivar de `~/.claude.json` + `~/.cursor/mcp.json` + settings Lovable.
- **D5 — Leitura cross-máquina via git log remoto**: para ver atividade do Mac mini, a Bridge lê o git log (não só o ledger local).
- **D6 — Rotação de log do autosync**: `git-autosync.log` cresce sem rotação; leitura eficiente exige `tail` + parsing incremental, não full-read.
- **D7 — `@security-reviewer` acionável da UI** (J7): botão "rodar revisão de segurança" precisa de um caminho sancionado para disparar o agente sobre o diff desde o último selo.

---

## 12. Riscos & trade-offs

- **R1 — Zero-Leak é binário e fatal.** Um único vazamento de segredo na UI mata a confiança no produto inteiro. *Mitigação:* o pilar Cofre-Espelho lê só nomes; teste de invariante `Zero-Leak = 0` é gate de release (não advisory).
- **R2 — Frescor ≠ tempo real.** Usuário pode interpretar a Frota como ao-vivo e tomar decisão sobre dado de 15 min atrás. *Mitigação:* exibir explicitamente o *freshness lag* de cada card (J6/§8 guardrail).
- **R3 — `idea-doctor` parsing frágil sem `--json`.** Mudança na saída ANSI quebra o health-score silenciosamente. *Mitigação:* D1 é pré-requisito, não opcional.
- **R4 — Escopo-creep para "observabilidade de runtime de produto".** A tentação de mostrar end-users/erros de produção dos produtos é forte e **viola `credential-isolation`**. *Mitigação:* §7 + S4 fecham essa porta por design.
- **R5 — Hostname inconsistente** (`Mac-mini-de-Gustavo` vs. `192` no ledger v12) dificulta deduplicar máquinas. *Mitigação:* camada de normalização (D2) com tabela de aliases de host.
- **R6 — Comando inseguro.** Se um botão J7 ganhasse autoridade que o agente não tem (ex.: `git push` fora do `@devops`), seria escalonamento de privilégio. *Mitigação:* §7.4 — todo comando herda `agent-authority`, sem exceção.
- **R7 — Single-operator hoje** limita o valor das personas 2/3. *Trade-off aceito:* construir para P0 primeiro; P1/P2 amadurecem com o sinal de ator.

---

## 13. Questões abertas (para `/grelha` / decisão do usuário)

1. **Nome final:** confirma `IdeiaOS Bridge` (com Atalaia como subsistema de alertas)? Ou prefere **Atalaia** como nome do produto inteiro (priorizando o equity cultural PT-BR sobre a precisão "control plane")?
2. **"Usuários dos projetos"** (briefing) = **contributors do repo** (o que o substrato dá) ou há expectativa de **end-users dos produtos** (que exigiria Supabase Auth de cada produto e esbarra em `credential-isolation`)? — confirmar S4.
3. **Local-first confirmado** (S1)? Ou há intenção futura de uma instância acessível remotamente (que mudaria radicalmente a postura de segurança)?
4. **Escopo da v1.0:** os 5 pilares completos, ou um *vertical slice* (Frota + Cofre-Espelho como MVP, provando surfacing + control-plane-seguro) e os demais em fases?
5. **Pulso multi-usuário:** vale construir a dimensão de ator agora (mesmo raso), ou adiar até haver volume de `desenvolvimento@`?

---

## 14. Síntese — o produto em um parágrafo

**IdeiaOS Bridge — Mission Control** é a cabine de comando de um sistema operacional de desenvolvimento de IA que já voa por instrumentos. Ele não coleta dados novos: faz *surfacing* do substrato auto-telemetrado que o IdeiaOS produz há 13 milestones — ledgers, git, transcripts, gates, daemons — e o transforma na única tela de CTO que responde, em segundos e sem abrir um terminal, *está tudo verde na minha frota, meus produtos, minhas chaves, minhas conexões de IA e minha entrega?* É **control plane, não cofre** (mostra tudo sobre cada chave exceto o valor); mede **entrega honesta, não vaidade**; e fecha o loop com **comando** (cada alerta tem o botão de remediar ao lado, e esse botão é um script que o OS já sancionou). Sua north-star é o **Time-to-Truth** — a distância encolhida entre a dúvida do CTO e a verdade do sistema. Não é mais um dashboard. É a faceta que faltava de um OS que já estava, sem saber, construindo a própria cabine.

---

*Próximos documentos desta série: `20-architecture.md` (camada de leitura + schema unificado + segurança), `30-scope-mvp.md` (vertical slice v1.0), `40-ux-design.md` (tema preto/ouro, bento-grid, os 5 pilares como telas).*
