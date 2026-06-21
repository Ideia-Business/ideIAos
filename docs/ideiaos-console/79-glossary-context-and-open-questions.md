# 79 — Glossário (rascunho CONTEXT.md) + Registro consolidado de questões abertas & riscos

> **Documento 79 · Linguagem ubíqua + risk register · Domain modeler / risk manager**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Produto:** **IdeiaOS Cockpit** · capability `/spec` = `cockpit` · ref de federação = `cockpit`
> **Lê (read-only):** docs `00`–`02`, `10`–`73`, `specs/cockpit/spec.md`, `.planning/milestones/v14-cockpit-PLAN.md`, `docs/decisions/v14-cockpit-local-first-git-as-bus.md`, rule `ideiaos-common-ubiquitous-language.md`.
> **Disciplina:** DDD/Evans (linguagem ubíqua) + forma `CONTEXT.md` de Pocock (glossário-only, zero implementação/decisão/spec). As 5 regras de ouro do `CONTEXT-FORMAT` valem aqui.

---

## NOTA DE PROVENIÊNCIA (leia antes)

- **Parte A é RASCUNHO durável do glossário.** O `CONTEXT.md` **canônico** do Cockpit morará na **raiz do produto** quando o código nascer (rule `ubiquitous-language`: glossário vive na raiz, mantido inline por `/grelha --docs`). Este doc preserva os termos para não se perderem entre o design e o 1º commit — **nada se perde**.
- **Glossário ≠ spec ≠ decisão-de-fase** (a tabela-chave dos três "CONTEXT"). Aqui há **só termos**: definição canônica curta + `_Evite_` (sinônimos a não usar). Comportamento contratado vive em `specs/cockpit/spec.md`; decisão de fase em `{phase}-CONTEXT.md`; decisão irreversível em ADR.
- **Os docs `74`/`76`/`78` citados no pedido NÃO existem como arquivos** (a série vai até `73`). As questões abertas que eles nomeavam (autenticação de origem v14.4, dependência circular autosync↔Frota, multi-usuário vaporware) **existem de fato** e foram rastreadas às suas fontes reais: doc `70` (origin-auth), docs `00`/`20`/`13.x` (autosync↔ref), docs `00`/`10`/`50` (multi-usuário). O registro (Parte B) usa as fontes reais, não os números inexistentes.

---

# PARTE A — GLOSSÁRIO (rascunho do `CONTEXT.md` do Cockpit)

> Termo canônico → definição curta (1–2 linhas) + `_Evite_` (sinônimos a não usar). Ordenado por camada conceitual. Zero implementação — só o nome das coisas.

## A.1 Produto, telas e pilares

### Cockpit
A ponte de comando do IdeiaOS: uma tela única de CTO que faz **surfacing + controle** sobre o substrato auto-telemetrado do OS — máquinas, produtos, chaves (por referência), conexões de IA/MCP e entrega real. Lê por referência; comanda só o local e reversível.
_Evite:_ "Bridge", "Mission Control" (codinomes mortos pré-decisão), "dashboard", "console" genérico, "painel admin".

### Frota _(Fleet)_
Pilar 1. O conjunto de máquinas do ecossistema e sua saúde/sincronização **agora** — quais existem, estão vivas e PASS.
_Evite:_ "máquinas conectadas", "nós", "cluster".

### Constelação _(Products)_
Pilar 2. O portfólio de produtos — stack, deploy, velocidade humana real (filtrada de bot/autosync). **Descobre** os projetos (`~/dev/*` com `.git`), nunca hardcoda a lista.
_Evite:_ "portfólio" (ok como sinônimo de leitura, não como termo de UI), "repos" (subconjunto), "lista de 5 produtos" (são 7+).

### Cofre-Espelho _(Credentials control-plane)_
Pilar 3. O mapa **metadata-only** de credenciais: onde cada chave existe, escopo, idade, status de rotação — **nunca o valor, nunca um botão que mute produção** (na v14.1). É espelho (reflete), não cofre (não guarda).
_Evite:_ "cofre", "vault", "secret manager", "gestor de chaves" (todos sugerem posse do valor — proibido).

### Sinapse _(AI & MCP)_
Pilar 4. O inventário de IA: contas por provedor, MCPs ligados onde, e o estado da contenção (deny-list). Inclui o **deny-list containment ledger** (v14.2).
_Evite:_ "integrações", "conexões" (ambíguo com `McpConnection`), "inventário de IA" (use como prosa, não como nome de tela).

### Pulso _(Delivery)_
Pilar 5. A medida de **entrega verificada** (sinal, não vaidade): commits humanos por tipo, sessões meaningful, co-ocorrência commit↔sessão, milestones SOAK-validados. Recusa contagem bruta.
_Evite:_ "produtividade" (sem qualificador vira vaidade), "métricas de atividade", "volume de commits".

### Atalaia _(Alerts / Drift)_
Subsistema transversal de alertas/drift do Cockpit — o que mudou e merece olhar antes de virar incidente. **Ilumina, nunca gateia** PR de feature.
_Evite:_ "alertas" genérico, "notificações", "watchtower" (tradução), nome de produto (Atalaia é subsistema, não o produto).

### System Pulse _(hero do Overview)_
O card-coração do Overview: o heartbeat **local-vivo** (ECG animado por file-watch) que prova "ecossistema vivo agora". É o ÚNICO card com moldura ouro.
_Evite:_ confundir com o pilar **Pulso** (entrega); aqui é o widget de batimento vivo.

### Flight Recorder _(v0 na v14.1; Time-Travel completo na v14.3)_
A reconstrução **determinística** do passado a partir de event-store append-only (git/ledgers). O **v0** reconstrói UMA série — o flip-flop real do pin `gsd` no `versions.lock` — read-only, exit-code binário. É o "wow estrutural" da 1ª impressão.
_Evite:_ "time-machine", "histórico" (genérico), "replay" (ok só como verbo da ação).

## A.2 Substrato técnico (data/control plane)

### ideiaos-agentd
O daemon local (4º LaunchAgent, `com.ideiaos.cockpit`, `StartInterval 900`) que **coleta** metadado read-only e (na v14.1) **executa** verbos locais reversíveis via IPC de processo. Na v14.1 não possui segredo nenhum.
_Evite:_ "ideiaos-console-agent" (nome morto, doc 30), "backend", "servidor", "coletor" (só uma das duas funções).

### ref `cockpit`
O branch órfão git (escrito por `commit-tree`/`update-ref`, **fora do working tree**) que federa os snapshots cross-máquina. É o **bus** — herda a malha do `planning`. Nunca é `main`.
_Evite:_ "branch mission-control" (nome provisório dos diagramas antigos), "branch de telemetria" (ok como descrição, não como nome).

### snapshot
O JSON por máquina (`snapshots/<machine_id>.json`, schema `ideiaos-cockpit-snapshot/v1`) que o agentd grava no ref `cockpit`. Metadata-only; **um escritor por arquivo** (zero conflito de merge).
_Evite:_ "dump", "telemetria" (genérico), "estado" (ambíguo).

### read-model
O cache **SQLite descartável** (`~/.ideiaos/console/read-model.db`) que o `console-ingest` reconstrói dos refs+ledgers (`rm db && rebuild`). **Não é fonte-de-verdade** — o disco/ref é.
_Evite:_ "banco de dados", "DB" (sugere durabilidade autoritativa), "cache" sem o qualificador "descartável".

### machine_id
A identidade canônica e estável de uma máquina = `sha256(hardware-uuid)` (não-PII, não-mutável). Separada do `hostname` (display, mutável). Resolve o gotcha de alias.
_Evite:_ "hostname" (mutável; `192`≠máquina), "nome da máquina", "IP".

### control-plane _(vs Data-plane)_
O plano **não-confiável** (browser + console) por onde trafegam **metadado, intenções, referências por nome** — nunca o valor de um segredo. O Data-plane (agentd + keychain) é o único que toca valor, server-side.
_Evite:_ usar "control-plane" e "cofre" como sinônimos (são opostos); "backend" para o control-plane.

### allowlist local
A lista **fixa** de verbos locais reversíveis que o Cockpit pode executar na v14.1 (autosync-pause/resume, idea-doctor, security --record). Default-deny: o que não está na lista é recusado.
_Evite:_ "whitelist" (preferir allowlist), "lista de comandos" (sem o "fixo/default-deny" perde o sentido de segurança).

### comando reversível
Verbo de mutação **local** cujo efeito pode ser desfeito (ex.: pausar autosync). Destrutivos-mas-reversíveis exigem "armar antes de disparar".
_Evite:_ "ação", "comando" sem o qualificador; confundir com mutação de produção (irreversível, gated v14.4).

### deny-list containment ledger
O ledger **estruturado append-only** de contenção por produto (`epoch|iso|produto|deny_count|total|commit`), emitido pelo deny-list watch na **v14.2**. É **pré-requisito** do momento-prêmio da v14.3 (sem ele, reconstruir 5/5→2/5→5/5 é vaporware — vive só em prosa de commit).
_Evite:_ "watch de deny-list" (é o sensor, não o ledger), "histórico de contenção" (genérico).

### Flight Recorder containment ledger
_(sinônimo informal a evitar)_ — use **deny-list containment ledger** para o artefato e **Flight Recorder** para a reconstrução visual; não os funda.

## A.3 Métricas e invariantes (North-Star)

### Zero-Leak
O invariante-piso de release: **0 valores de segredo** em qualquer superfície (estado/DOM/rede/log/snapshot/ledger), sempre. Um único valor visível é incidente P0 e **bloqueia merge** (gate, não advisory). `ApiKey` não tem coluna `value`.
_Evite:_ "no-leak", "secret-safe", "mascarar segredo" (mascarar ainda implica o valor presente — proibido).

### Time-to-Truth _(TtT)_
North-Star: mediana de **segundos** entre uma pergunta de CTO sobre o estado do ecossistema e a resposta confiável, sem abrir terminal. Meta v14: **< 10 s**. **Baseline medido** (cronômetro, N≥5, J1/J4/J2), nunca assumido.
_Evite:_ "tempo de resposta", "latência" (ambíguo com a latência de federação ~15min).

### Trust Rate
Guardrail: % de respostas do Cockpit que batem com o **disco no instante da pergunta** (modo `--verify` recomputa do disco/ref), não com o cache. Meta 100%; qualquer divergência é bug P0.
_Evite:_ "acurácia", "precisão", "bater com o cache" (o cache pode estar stale — não é o ground-truth).

### entrega verificada
A unidade honesta de output do Pulso: trabalho que passou validação cross-máquina (milestone SOAK-satisfeito) ou commit humano `feat`/`fix` correlacionado a sessão meaningful.
_Evite:_ "produtividade", "output", "commits" (cru inclui vaidade).

### vaporware _(rótulo honesto)_
Marcação explícita de uma promessa que o substrato **ainda não suporta** (ex.: personas P1/P2 multi-usuário; momento-prêmio antes do ledger da v14.2). Rotular como vaporware é disciplina, não defeito — torna o limite auditável.
_Evite:_ esconder a lacuna; "em breve", "roadmap" (eufemismos que apagam o limite honesto).

---

# PARTE B — REGISTRO CONSOLIDADO DE QUESTÕES ABERTAS & RISCOS

> Varredura de TODO o plano (`00`–`73` + spec + PLAN + ADR). Uma tabela mestra. **Estado**: `aberto` (sem resolução cravada) · `mitigado` (mitigação desenhada, não fechada estruturalmente) · `gated` (resolução adiada atrás de gate explícito) · `resolvido` (fechado/corrigido). **Severidade**: 🔴 crítica · 🟠 alta · 🟡 média · ⚪ baixa.

| id | descrição | fase | sev. | dono-da-decisão | estado | onde-é-tratado |
|----|-----------|------|:----:|-----------------|--------|----------------|
| **Q1** | **Autenticação de origem (v14.4):** `sha256 ≠ assinatura` — como a máquina-alvo prova que um comando cross-máquina veio de quem diz, sem segredo no contexto e sem o autosync sequestrar a chave? Sem isto o RBAC é teatro (papel auto-declarado). | v14.4 | 🔴 | `/spec` segurança + @security-reviewer; usuário aprova gate | **aberto** (bloqueante do write-path) | doc 70 §2-bis (O2/O3/O4), §8 Q1; PLAN R14-09; ADR (teto gated) |
| **Q2** | **Revogação da chave de máquina** se um host é comprometido — sem CA nem canal já-confiável (raposa guardando o galinheiro). | v14.4 | 🔴 | `/spec` segurança | **aberto** | doc 70 §8 Q2 |
| **Q3** | **Step-up auth sem RP-server:** WebAuthn exige relying-party; sem backend, a passkey em loopback é não-trivial. Alternativa: Touch ID via agentd (LocalAuthentication) — a confirmar. | v14.4 | 🔴 | `/spec` segurança | **aberto** | doc 70 §3, §8 Q3 |
| **Q4** | **Replay + sincronia de relógio** entre máquinas assimétricas (registro de nonces-vistos + expiry com clocks dessincronizados). | v14.4 | 🟠 | `/spec` segurança | **aberto** | doc 70 §8 Q4 |
| **Q5** | **Separar ref-de-telemetria de ref-de-comando:** o `origin` (GitHub, terceiro) deve ver o ref de comando, ou só o de leitura? Metadado "quem rotacionou o quê" é superfície sensível. | v14.4 | 🟠 | `/spec` segurança + @devops | **aberto** | doc 70 §2 (I), §8 Q5 |
| **Q6** | **CLI-por-provedor que resolve do keychain:** enumerar Vercel/Railway/Supabase — quais têm caminho keychain-nativo vs deixam valor no env-da-borda (least-privilege real). | v14.4 | 🟠 | `/spec` segurança | **aberto** | doc 70 §7, §8 Q6 |
| **Q7** | **Estado de commit-signing git (A4):** `commit.gpgsign`/`gpg.format=ssh` ligados? NÃO-verificado nesta sessão (permissão negada). Decide O2 vs O3. Se off, é bootstrap antes de qualquer write. | v14.4 | 🟡 | @devops + `/spec` | **aberto** | doc 70 §2-bis (A4/O3), §8 Q7 |
| **Q8** | **Protocolo de ACK idempotente** cross-máquina: sem ACK do alvo, a origem mostra "PENDENTE", nunca "FEITO" (bus eventual ~15min). | v14.4 | 🟡 | `/spec` segurança | **aberto** | doc 70 §2 (D), §8 Q8 |
| **Q9** | **Ledger: detecção ≠ prevenção** — o encadeamento de hash detecta reescrita mas não desfaz a ação já executada. Aceitar como residual ou endurecer? | v14.4 | 🟡 | `/spec` segurança | **aberto** | doc 70 §2 (T/R), §8 Q9; doc 30 §7 |
| **R01** | **Dependência circular autosync↔Frota / ref:** o ref `cockpit` é propagado pelo **mesmo** git-autosync que faz `git add -A` cego e que a própria Frota monitora; se o autosync morre, o estado cross-máquina congela e o sinal de "autosync parado" também depende dele. | v14.0–v14.2 | 🟠 | @architect | **mitigado** (estrutural: snapshot fora do working tree → autosync nada captura; Frota mostra 🔴 por **idade do ref**, não por conexão viva; agentd pode push do próprio ref, nunca `main`) | doc 00 §11; doc 20 §13 (última linha); doc 72 task 2.5; spec "Federação por ref" |
| **R02** | **Multi-usuário (P1/P2) é vaporware:** toda observação é `gustavo@`; personas líder-de-squad/dev-individual e metade do Pulso dependem de 2º ator (`desenvolvimento@`) que não tem volume. Observations JSONL **não têm campo `user`**. | v14.2+ | 🟡 | usuário (PM) | **mitigado** (rotulado vaporware honesto; constrói P0 primeiro; git-author email separa CTO de Dev Team, mas é raso) | doc 00 §3,§11; doc 10 §4.5,§5; doc 40 §6 (gap); doc 50 §5; spec "produtividade monousuária" |
| **R03** | **idea-doctor não roda nos Lovable:** health-score por produto perde um sub-sinal nos produtos Lovable. | v14.2 | 🟡 | @architect | **mitigado** (sub-sinal `doctor: n/a` honesto; score não conta como falha nem sucesso fabricado) | doc 00 §3; doc 60 §8; spec "saúde por produto com sub-sinal honesto"; PLAN riscos |
| **R04** | **Retenção do ref `cockpit` + audit-log:** ambos crescem sem rotação (learning `git-autosync.log-sem-rotação`). | v14.0+ | 🟡 | @architect / @devops | **mitigado** (ref sofre `squash` retroativo a cada 30d — último snapshot/máquina + marco mensal; audit-log roda por tamanho `>1MB→arquiva datado`) | doc 00 §5 (retenção); doc 30 §7; doc 60 §+1 (risco) |
| **R05** | **Trust Rate: cache vs disco** — o read-model é cache descartável que pode estar stale; afirmar contra o cache mente o North-Star. | v14.1 | 🟠 | @dev + @qa | **mitigado** (modo `--verify` recomputa do disco/ref no instante; UI exibe "verificado há Xs"; divergência marcada stale; gate A6) | doc 00 §8; doc 02 §4 (Confiança verificável), A6; spec "verdade verificável contra o disco" |
| **R06** | **Ledger de contenção como pré-requisito do momento-prêmio:** reconstruir deny-list 5/5→2/5→5/5 (blueprint §10) é **impossível deterministicamente** enquanto o estado viver só em prosa de commit + memória. | v14.2 (ledger) → v14.3 (replay) | 🟠 | @architect / @po | **mitigado** (achado registrado: v14.2 DEVE emitir `deny-list containment ledger` estruturado; Flight Recorder v0 usa `versions.lock` em vez disso na v14.1) | doc 71 §1.3,§7.1; PLAN R14-07/R14-08; doc 02 (Flight Recorder v0) |
| **R07** | **Zero-Leak binário e fatal:** um único valor de segredo em qualquer superfície mata a confiança no produto inteiro. | transversal | 🔴 | @qa (gate de release) | **mitigado** (estrutural: `ApiKey` sem coluna `value`; leitura só de nomes via `grep\|sed`; teste de invariante `test:zeroleak` exit-code; gate de release, não advisory) | doc 00 §5; doc 30 §2,§10; doc 40 §2.5; doc 72 task 3.4; spec "Zero-Leak"; PLAN DoD 1 |
| **R08** | **"Mapa do tesouro":** o Cofre lista ONDE as chaves críticas vivem → comprometer o Cockpit é um mapa de alvos. | v14.1 | 🟠 | @security-reviewer | **mitigado** (loopback `127.0.0.1` only; metadata-only → comprometer revela nomes/idades, não valores; badge ativo p/ `.env.local` em iCloud) | doc 00 §5 (SH5); doc 20 §9.2; doc 60 §10 (risco) |
| **R09** | **Comando local pelo browser = superfície de injeção (⌘K):** uma palette que executa scripts é vetor se não contida. | v14.1 | 🟠 | @security-reviewer | **mitigado** (allowlist fixo, sem `exec` arbitrário, IPC local não-git, destrutivos "armam antes de disparar"; gates A7/A8) | doc 00 §6 feature 5; doc 02 §4 (allowlist), A8; spec "comando local reversível" |
| **R10** | **Autoridade @devops:** o Cockpit poderia virar bypass de `git push`/`gh pr`/MCP-mgmt (escalonamento de privilégio). | transversal | 🟠 | @devops (exclusivo) | **resolvido** (estrutural: esses verbos NÃO entram no allowlist; no máximo o Cockpit **gera** o comando p/ @devops; RBAC do console espelha `agent-authority`) | doc 10 §7.4; doc 20 §3; doc 30 §5.2; doc 70 §6; spec "autoridade exclusiva de @devops" |
| **R11** | **CTO Copiloto — injection via substrato** (commit-msg/branch/tool-description adversarial interpretado como instrução). | v14.3 | 🟠 | @security-reviewer | **mitigado** (readers determinísticos de args FIXOS; LLM só roteia; retornos envelopados como DADO/anti-injection; nenhum reader toca segredo; não há verbo `reveal` p/ injeção invocar) | doc 00 §5 (SH6),§6 feature 8; doc 30 §6.1; doc 60 §1 (risco) |
| **R12** | **Pulse parecer teatro:** animar fluxo contínuo sobre dado que chega em lote (~15min cross-máquina) seria desonesto. | v14.1 | 🟡 | @ux-design-expert | **mitigado** (System Pulse anima SÓ o heartbeat local real; nós remotos mostram "último sinal há Xmin"; vira arrítmico no crítico, cor não é único sinal) | doc 00 §4,§6; doc 02 §4 (System Pulse), §6; doc 50 §3.4; spec "frescor honesto" |
| **R13** | **idea-doctor --json é feature nova não-trivial** (0 parsing hoje; script vivo ~593 linhas que É o gate de saúde) — risco de regressão da saída ANSI. | v14.0 | 🟠 | @dev | **mitigado** (emissão paralela, NÃO reescrita; fallback ANSI testado por diff ANSI-stripped ANTES de qualquer consumidor; gate C3/task 1.4) | doc 00 §4 (C3); doc 72 §1; doc 73 §2; PLAN R14-01 |
| **R14** | **Frescor ≠ tempo real** (~15min cross-máquina): usuário pode decidir sobre dado de 15min atrás achando que é ao-vivo. | transversal | 🟡 | @ux-design-expert | **mitigado** (lag exibido por card; local-vivo vs cross-máquina-eventual distintos; aceito como trade-off do git-as-bus) | doc 00 §11; doc 20 §13; doc 50 §3.3; ADR consequências |
| **R15** | **Assimetria entre máquinas:** todo recon foi no MacBook; Mac mini só via ref. Divergência de `agentd_version`/`os_version`. | v14.0 | 🟡 | @data-engineer | **resolvido** (recon rodou NA Mac-mini, doc 73: 3 daemons + `--json` ausente conferem; collector declara `agentd_version`/`os_version`; divergência vira drift âmbar, não quebra) | doc 00 §9; doc 73 §3,§7.3; doc 40 §1 |
| **R16** | **Gotcha de alias `192`:** dedup de máquina errada quebraria o gate SOAK `≥2 máquinas` e a contagem da Frota. | v14.0 | 🟡 | @data-engineer | **resolvido** (corrigido na Mac-mini: `192 → MacBook-Air-2`, NÃO Mac-mini; alias-map curado `machine-aliases.json`) | doc 73 §3,§7.1; doc 40 §1 (gotcha 2); doc 00 §9 |
| **R17** | **Constelação hardcodava 5 produtos:** há 7+ reais (Jarvis 469 sessões, ideia-chat). | v14.2 | 🟡 | @data-engineer | **resolvido** (collector DESCOBRE `~/dev/*` com `.git` e classifica produto/test-dir/tooling; nunca assume N=5) | doc 73 §4; doc 00 §9; doc 72 task 3.2 |
| **R18** | **gsd semver-trap:** `1.1.0`(redux) > `1.36.0`(pré-redux) — comparar por semver numérico inverteria o drift. | v14.0 | 🟡 | @data-engineer | **resolvido** (read-model compara `gsd` por **string-equality** contra o pin, nunca semver; learning `version-reset-migration-semver-trap`) | doc 40 §1,§8; doc 72 task 4; doc 00 §9 |
| **R19** | **SOAK span = delta de epochs gravados, não wall-clock:** esperar não amadurece o soak; tem que RE-gravar após ≥1d. | transversal | 🟡 | @devops | **resolvido** (countdown derivado do delta de epochs do ledger; learning `soak-span-is-record-delta-not-wallclock`) | doc 40 §2.9; doc 50 §3.2 (E); doc 72 §5; PLAN princípios |
| **R20** | **`IDEIA_CHAT_SYSADMIN_PASSWORD` em `.env.local`:** crítico no catálogo, mas é teste que não vai a produção. | v14.1 | ⚪ | usuário (decisão tomada) | **resolvido** (NÃO re-flagar; badge `aceito · teste`; rotação dispensada por decisão 2026-06-18; memória `project-ideia-chat-test-secret-acceptable`) | doc 50 §6; doc 73 §5 |
| **R21** | **`.env` tracked no git** (ideiapartner/nfideia): risco de exposição. | v14.0 | ⚪ | @security-reviewer | **resolvido** (verificado doc 73 §5.1: os 2 `.env` rastreados têm SÓ valores públicos `VITE_*`/anon/url; nenhum SERVICE_ROLE git-tracked → 🟡 aceitável, não 🔴) | doc 73 §5.1; doc 40 §2.5 (`committed`) |
| **R22** | **Piggyback no SOAK como coletor** (proposta do doc 40 §4): SOAK `--record` é manual (nenhum LaunchAgent o invoca) → quebraria o "heartbeat vivo". | v14.0 | 🟡 | @architect | **resolvido** (rejeitado pela crítica adversarial C1; 4º LaunchAgent dedicado `com.ideiaos.cockpit` `StartInterval 900` em vez de piggyback) | doc 00 §4 (C1); ADR alternativas; doc 40 §4 (proposta superada) |
| **R23** | **Single-operator limita personas 2/3** (sobrepõe R02 no eixo de produto): valor incremental de P2 sobre "abrir o terminal" é baixo. | v14.2+ | ⚪ | usuário (PM) | **mitigado** (P0 primeiro; honestidade de escopo declarada) | doc 10 §5 (P2 nota); doc 00 §11 |
| **R24** | **"Usuários" = contributors, não end-users:** o briefing pede "usuários dos projetos"; o substrato só dá contributors de repo (end-users exigiriam Supabase Auth → viola `credential-isolation`). | transversal | 🟡 | usuário (interpretação) | **resolvido** (S4 confirmado; o Cockpit mostra contributors; copy honesta declara o limite) | doc 10 §4.5,§10 (S4),§13 Q2; doc 50 §5 (gap) |
| **R25** | **Fadiga de alerta (cried-wolf) na Atalaia:** alertas demais dessensibilizam. | v14.2 | ⚪ | @ux-design-expert | **mitigado** (severidade info/warn/critical; só "grita" no critical; proporcionalidade rigor=risco×idade; nunca gateia feature) | doc 60 §3 (risco); doc 00 §6 (feature 4) |
| **R26** | **Token-Cost: estimativa vendida como número fechado** (formato de uso/token varia entre versões do Claude Code). | v14.3 | ⚪ | @dev | **mitigado** (pricing da skill `claude-api`, nunca de memória; sem campo nativo → estimativa **rotulada** "±20%" com metodologia) | doc 60 §4; doc 00 §6 (feature 9); PLAN R14-08 |
| **R27** | **Atlas de instincts confundido com conduta ao-vivo:** instincts são write-only, NÃO injetados no contexto (telemetria comportamental). | v14.3 | ⚪ | @analyst | **mitigado** (rótulo "maturidade observada", não "o que o agente vai fazer"; não promove telemetria de frequência; rule `learning-channel-routing`) | doc 60 §11; doc 00 §6 (feature 10) |
| **R28** | **envsync transporta `.env.local` por iCloud** (mapa do tesouro / I-disclosure): o log poderia gravar valor. | v14.1 | 🟡 | @security-reviewer | **mitigado** (badge-achado da Atalaia "considere git-crypt/keychain"; auditoria contínua: regex de segredo no log do envsync → WARN, gate testável; loopback) | doc 00 §5 (SH5); doc 30 §4 (I); doc 60 §10 (risco) |
| **R29** | **Brand-hue ouro vs azul-OS:** decisão de gosto reversível em 1 linha (`--brand-hue:75`). | v14.0 | ⚪ | usuário (decidido) | **resolvido** (ouro IdeiaOS aceito como default; reversível) | doc 00 §12 (D4); doc 50 §10.2; ADR |
| **R30** | **Command-plane executa da UI vs "gera comando p/ copiar":** se ⌘K pode mesmo rodar `autosync-pause`/`--record` ou só gerar o comando. | v14.1 | 🟡 | usuário (confirmar) | **mitigado** (default assumido: executa não-destrutivos locais + confirma destrutivos; @devops-exclusivos sempre só geram comando; sujeito a override) | doc 50 §11 (fecho, item 3); doc 02 §4 (allowlist) |

---

## Sumário do registro

- **Total de itens:** 39 questões/riscos (Q1–Q9 + R01–R30).
- **Por estado:** aberto = 9 (todos v14.4, write-path) · mitigado = 18 · gated = 0 explícito (os 9 abertos são gated pelo `/spec` de segurança, mas listados como `aberto` por não terem resolução cravada) · resolvido = 12.
- **A de maior severidade ainda NÃO-resolvida:** **Q1 — autenticação de origem cross-máquina** (🔴, `sha256 ≠ assinatura`). É o achado bloqueante que torna a v14.4 um **gate, não um milestone**: sem ela, o RBAC `cto`/`dev` é falsificável (papel auto-declarado) e o comando cross-máquina não tem prova de origem. Acompanham-na Q2 (revogação de chave de máquina) e Q3 (step-up sem RP-server), igualmente 🔴 e igualmente bloqueantes do write-path. **Postura cravada (doc 70 §9):** habilitar incrementalmente — `rotate` local-na-máquina primeiro, cross-máquina só após Q1–Q3 fechadas no threat-model formal.

---

*Documento 79 — PROPOSTO. Zero código. Parte A é rascunho durável do `CONTEXT.md` (o canônico nascerá na raiz do produto via `/grelha --docs`). Parte B é o risk register mestre que o `/spec` de segurança da v14.4 deve consumir (Q1–Q9) e que o GSD da v14.0–v14.2 deve manter visível (R01–R30). Nada se perde.*
