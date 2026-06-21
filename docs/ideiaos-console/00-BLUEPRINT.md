# IdeiaOS Cockpit · BLUEPRINT

> **Documento 00 · Blueprint FINAL · Lead Architect**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Milestone-alvo:** **v14.x** do IdeiaOS
> **Substitui:** `00-BLUEPRINT-DRAFT.md` (NEEDS_WORK) — incorpora a crítica adversarial e fecha 6 contradições, 6 buracos de segurança e 6 gaps.
> **Supera os 6 docs-fonte** (`10`…`60`) onde divergiam. As correções estão marcadas `[CORRIGIDO]` com a contradição que resolvem.

> ### ✅ Decisões do usuário (2026-06-20)
> | # | Pergunta (§12) | Decisão |
> |---|----------------|---------|
> | D1 | Nome do produto | **IdeiaOS Cockpit** (metáfora glass-cockpit; "Atalaia" = subsistema de alertas; daemon = `ideiaos-agentd`). O ref de federação passa a ser `cockpit`. |
> | D2 | Próximo passo | **Formalizar antes via `/spec` + GSD** — contrato da capability `cockpit` + plano de fase v14.0 antes de código. |
> | D3 | Teto de poder | **Comando cross-máquina aprovado para v14.4**, gated por `/spec` + threat-model STRIDE/OWASP-LLM. v14.0–v14.3 permanecem read-only quanto a produção. |
> | D4 | Brand-hue | Ouro IdeiaOS (`--brand-hue:75`) — default aceito (reversível em 1 linha). |

---

## 0. O que mudou em relação ao DRAFT (sumário das correções)

A crítica `NEEDS_WORK` apontou que o DRAFT prometia coisas mutuamente exclusivas. Este blueprint resolve cada uma de forma cravada:

| # | Problema no DRAFT | Decisão FINAL |
|---|-------------------|---------------|
| **C1** | "piggyback no SOAK `--record`" (manual) vs "heartbeat vivo" | **Há um 4º LaunchAgent dedicado** `com.ideiaos.missioncontrol` (~900s). SOAK `--record` é manual — verificado: nenhum LaunchAgent o invoca — logo **NUNCA** é o coletor. Piggyback descartado. O Pulse é local-vivo (polling de arquivo local, ~1–5s) e cross-máquina-eventual (~15min). |
| **C2** | "não há backend" vs "backend assina o comando" | **Não há backend HTTP, e não há assinatura de comando.** Comando nunca é um arquivo no working tree. O agentd escreve a fila **diretamente no ref `mission-control` via git-plumbing** — fora do alcance do `git add -A` do autosync. O *process boundary* (só o agentd local escreve aquele ref) é a autoridade, não um HMAC sobre um arquivo plantável. |
| **C3** | `idea-doctor --json` "já dá" | **FALSO, verificado:** 40 ocorrências de `json` no fonte, **zero** parsing de `--json`. É **feature nova não-trivial**, pré-requisito de v14.0, com fallback ANSI **testado antes** de prometer a Frota. |
| **C4** | RBAC multi-tenant (passkey/mTLS/step-up) para 1 operador em localhost | **v14.1 é read-only local sem login.** Todo o RBAC/WebAuthn/mTLS é **adiado para v14.4**, atrás do `/spec` de segurança, e só existe **se** o comando cross-máquina existir. |
| **C5** | North-Star `TtT<10s` não-mensurável | **Protocolo de medição cravado** (§8) — cronômetro sobre J1/J4/J2 com e sem a Bridge, baseline medido antes de v14.1, não assumido. |
| **C6** | Nome morto `ideiaos-console-agent` no doc de segurança | Nome canônico único: **`ideiaos-agentd`**. O doc 30 era o último a usar o nome morto. |
| **C7** | Snapshot em `mission-control` (órfão) vs `.planning/console/snapshots/` | **Destino único: ref `mission-control`** (órfão, git-plumbing, só no repo IdeiaOS). `.planning/console/` é descartado como destino federado. |
| **C8** | `rotate/revoke/deploy` no design da Wave 1 | **v14.1 é ESTRITAMENTE read-only.** Nenhum verbo de mutação de produção entra no allowlist antes do `/spec` de segurança (v14.4). O Cofre-Espelho da Wave 1 é **mapa metadata-only sem botão de rotação**. |
| **C9** | VERCEL_TOKEN: ALTO (doc 30) vs sensitive (doc 40) | **Catálogo de risco único** (§9). VERCEL_TOKEN = **ALTO** (redeploy de produção). A escada de tiers é uma só. |

---

## 1. O produto em uma frase

**IdeiaOS Bridge — Mission Control** é a **ponte de comando** de um sistema operacional de desenvolvimento de IA que já voa por instrumentos: uma única tela de CTO que faz *surfacing* sobre o substrato auto-telemetrado que o IdeiaOS produz há 13 milestones — máquinas, produtos, chaves (**por referência**), conexões de IA/MCP e entrega real — **sem nunca coletar dado novo, sem nunca tocar o valor de um segredo**. Na v14.1 ela **lê e comanda só o que é local e reversível**; comando cross-máquina e mutação de produção chegam depois, atrás de um threat-model dedicado.

**One-liner (canônico):**
*A ponte de comando do IdeiaOS — todas as máquinas, contas, produtos, chaves e a produtividade de IA do seu ecossistema, numa só tela de CTO. **Controle local, não cofre.***

**North-Star:** **Time-to-Truth (TtT)** — mediana de segundos entre uma pergunta de CTO sobre o estado do ecossistema e a resposta confiável, sem abrir um terminal. **Baseline medido (não assumido)** antes da v14.1 por cronômetro sobre J1/J4/J2 (§8). Meta v14: **< 10 s**.

---

## 2. Nome final `[DECIDIDO pelo usuário — 2026-06-20]`

- **Produto:** **IdeiaOS Cockpit** · encurtável para **"o Cockpit"**. A metáfora glass-cockpit é a âncora de UX (doc 50: *instrumento, não relatório*); a tela de overview é a *visão de cockpit*.
- **Atalaia:** nome do **subsistema de alertas** dentro do Cockpit.
- **Daemon local:** **`ideiaos-agentd`** — nome **único e canônico** em TODOS os docs (o `ideiaos-console-agent` do doc 30 está morto). `[CORRIGIDO C6]`
- **Ref de federação:** **`cockpit`** (branch órfão via git-plumbing; substitui o nome provisório `mission-control` usado nos diagramas abaixo).

---

## 3. Pilares (5 + 1 transversal)

| # | Pilar | Promessa | Substrato existente |
|---|-------|----------|---------------------|
| 1 | **Frota** (Fleet) | Quais máquinas existem, estão sincronizadas e saudáveis — agora. | SOAK ledger, commits WIP do autosync, `launchctl`, `idea-doctor --json` |
| 2 | **Constelação** (Products) | Cada produto, sua stack, deploy, velocidade **real** (humano-filtrada). | `git log` classificado, `supabase/config.toml`, `git remote`, Lovable MCP read-only, transcripts |
| 3 | **Cofre-Espelho** (Credentials) | Onde cada chave existe, escopo, idade, status de rotação — **nunca o valor, nunca um botão que muta produção (na v14.1).** | nomes de var (`grep`+`sed`), `.env.example`, `stat`, `gh auth status`, envsync log (hash) |
| 4 | **Sinapse** (AI & MCP) | Quantas contas de cada IA, quais MCPs ligados onde, contenção de pé. | `~/.claude.json`, `~/.cursor/mcp.json`, `.claude/settings.json` deny-list, Lovable MCP UUID |
| 5 | **Pulso** (Delivery) | Onde o tempo de IA virou **entrega verificada** — sinal, não vaidade. | transcripts (`human_turns>5`), git log humano por tipo, SOAK, security ledger, instincts |
| + | **Atalaia** (Alerts/Drift, transversal) | O que mudou e merece olhar — antes de virar incidente. | diff `versions.lock`, regressão de deny-list, autosync parado, security-tier→stale, `.env` órfão, SOAK pronto-p/-tag |

> **Honestidade de substrato `[CORRIGIDO gaps]`:** o Pulso por-usuário é **monousuário hoje** (toda observação é `gustavo@`). Personas P1/P2 (líder de squad, dev individual) são **explicitamente vaporware** até `desenvolvimento@` ter volume — o pilar Pulso da v14.x serve P0 (CTO-de-um-só) e rotula o resto como "aguardando segundo ator". `idea-doctor` **não roda igual** nos produtos Lovable → o health-score por produto declara um **sub-sinal ausente honesto** (`doctor: n/a neste produto`), não inventa nota.

---

## 4. Arquitetura escolhida `[DECIDIDO]`

**Local-first, git-as-bus por REF (não por working tree), ZERO backend cloud novo, ZERO assinatura de comando.**

```
┌────────────────────────────────────────────────────────────────────────┐
│ DATA-PLANE (read-only, flui para CIMA — metadata-only, ZERO segredo)    │
│  Substrato → ideiaos-agentd LÊ → normaliza → snapshot JSON               │
│  → git COMMIT-TREE/UPDATE-REF (plumbing) → refs/heads/mission-control    │
│    (NUNCA toca o working tree; autosync não consegue capturá-lo)         │
└────────────────────────────────────────────────────────────────────────┘
                          │  git-autosync faz SÓ `git push origin mission-control`
                          │  (mesmo padrão de push_planning_ref — pull-only no main)
                          ▼  latência cross-máquina ~15min (1 ciclo, ACEITA)
┌────────────────────────────────────────────────────────────────────────┐
│ CONSOLE SPA (Vite+React+shadcn, http://127.0.0.1 — SEM login na v14.1)   │
│  console-ingest funde N snapshots do ref → SQLite read-model (cache)     │
│  Pulse local: file-watch do snapshot LOCAL (~1–5s) = "vivo agora"        │
└────────────────────────────────────────────────────────────────────────┘
                          │  v14.1: ações LOCAIS reversíveis, executadas
                          ▼  pelo agentd LOCAL via IPC de processo (NÃO via git)
┌────────────────────────────────────────────────────────────────────────┐
│ CONTROL-PLANE LOCAL (v14.1) — allowlist FIXO de verbos reversíveis       │
│  autosync-pause/resume · idea-doctor · security --record (re-selo local) │
│  push/PR/rotate/revoke/deploy = FORA do allowlist (bloqueados)           │
│                                                                          │
│  CONTROL-PLANE CROSS-MÁQUINA (v14.4) — só atrás do /spec de segurança    │
└────────────────────────────────────────────────────────────────────────┘
```

### Decisões cravadas

1. **`ideiaos-agentd` — 4º LaunchAgent dedicado** `[CORRIGIDO C1]`. `com.ideiaos.missioncontrol`, `StartInterval 900`, irmão dos 3 existentes (`envsync`, `gitautosync`, `refresh-ai-security` — verificados). **Não há piggyback no SOAK** porque `check-soak.sh --record` é **manual** (verificado: nenhum LaunchAgent o invoca). O agentd é o coletor agendado; SOAK continua sendo gravado por humano quando re-sela durabilidade.

2. **Git é o bus, mas por REF — não por arquivo no working tree** `[CORRIGIDO C2, C7]`. O agentd escreve `snapshots/<machine_id>.json` **dentro de `refs/heads/mission-control`** via `git commit-tree` + `update-ref` (mesmo mecanismo do `push_planning_ref`, verificado no autosync). **Consequência de segurança decisiva:** o snapshot **nunca existe como arquivo no working tree**, então o `git add -A` cego do autosync (verificado, linhas 82–110) **não tem o que capturar**. O autosync só faz `git push origin mission-control` se o ref estiver à frente — exatamente como já faz com `planning`. `machine_id = sha256(hardware-uuid)`. Branch só no repo IdeiaOS (hub); produtos ficam limpos.

3. **Sem banco real, sem API HTTP, SEM login na v14.1** `[CORRIGIDO C4]`. Read-model = **SQLite single-file descartável** (`~/.ideiaos/console/read-model.db`); `rm db && rebuild` reconstrói tudo dos refs. Fonte-de-verdade = arquivos no ref/disco. A SPA serve em `http://127.0.0.1` **sem autenticação** — é um operador único em loopback. RBAC/passkey/mTLS/step-up **não existem na v14.1**; entram **só** na v14.4 **se** o comando cross-máquina for aprovado pelo `/spec`.

4. **`idea-doctor --json` é trabalho real, não "já dá"** `[CORRIGIDO C3]`. Flag **nova** (14 seções → JSON estruturado), pré-requisito de v14.0. **Fallback ANSI testado** (parse dos blocos `━━━`) é entregue e validado **antes** de a Frota depender do JSON. Critério de pronto da v14.0 inclui um teste que prova o fallback.

5. **Stack = stack canônico, zero escolha nova:** Vite 7 + React 18 + TS + Tailwind + shadcn/ui (54 componentes já no nfideia) + Recharts. Reúso: `KPICard`/`AppLayout`/`AppSidebar` (nfideia), `HealthScore`/`TrendChart` (health-dashboard), tema black-gold do `graph-dashboard/THEME`.

6. **Latência honesta:** local-vivo (~1–5s, file-watch) · cross-máquina-eventual (~15min, 1 ciclo autosync). O System Pulse anima sobre o **heartbeat local** (contínuo de verdade) e mostra os outros nós com **timestamp do último ingest** — nunca finge fluxo contínuo sobre dado em lote `[CORRIGIDO freshness]`.

7. **Gateway MCP read-first:** reusa `source/lib/lovable-mcp.sh` + a deny-list de 19 tools mutantes já enforçada; o console **audita** essa deny-list como health-check, **nunca a modifica**.

**Mudanças no substrato — mínimas, aditivas, com fallback:** `idea-doctor.sh --json` (flag nova + fallback ANSI testado) · `com.ideiaos.missioncontrol.plist` · ref órfão `mission-control` (plumbing) · `source/lib/mission-control.sh` (reusa `gates.sh`) · `scripts/check-mission-control.sh` + §15 no `idea-doctor` (dogfooding). Nenhum ledger muda de formato.

---

## 5. Modelo de segurança (estrutural, não disciplinar)

A Bridge é, por construção, **um plano de leitura sobre cofres que ela nunca abre, e um plano de comando que na v14.1 só executa o reversível e o local** — aplicação direta de `credential-isolation`: o browser é ambiente **não-confiável**, equivalente ao contexto do LLM, onde o **valor** de um segredo **jamais** transita (nem em estado React, DOM, rede, log, snapshot ou ledger). O console conhece a credencial **só por referência** (nome, presença, idade via `stat`, escopo via `gh auth status`, `risk_tier`), derivados sem ler o RHS do `=` (`grep '^[A-Z_]*=' | sed 's/=.*//'`); a entidade `ApiKey` **não tem coluna `value`**.

**Como as 6 brechas da crítica são FECHADAS:**

| Brecha (crítica) | Fechamento estrutural |
|------------------|------------------------|
| **Command-queue não-assinada capturada pelo autosync** | **Não existe arquivo de comando no working tree.** Na v14.1 não há fila cross-máquina; ações locais vão por **IPC de processo** do agentd local, não por git. O `git add -A` cego não tem o que propagar. `[fecha SH1]` |
| **Chave de assinatura / HMAC sem home** | **Não há assinatura porque não há comando-via-arquivo.** Eliminamos o requisito em vez de gerenciar uma chave que `credential-isolation` proibiria no contexto. `[fecha SH2]` |
| **agentd com posse de segredo + excessive-agency** | Na v14.1 o agentd **não resolve segredo nenhum** — é coletor read-only de metadado + executor de verbos **reversíveis locais** (autosync-pause, idea-doctor, re-selo). `rotate/revoke/deploy` **não estão no allowlist** e não entram antes do `/spec` v14.4. `[fecha SH3]` |
| **rotate/revoke/deploy = RCE-equivalente** | **v14.1 é estritamente read-only quanto a produção.** O Cofre-Espelho é mapa metadata-only **sem** "Marcar para rotação". O minuto em que um verbo de mutação for proposto, ele vai por `/spec` + threat-model (v14.4), nunca por blueprint. `[fecha SH4, C8]` |
| **envsync transporta `.env.local` por iCloud (mapa do tesouro)** | O console **lista a localização** das chaves (já visível pelo recon) mas **mitiga ativamente**: badge "este `.env.local` trafega por iCloud → considere `git-crypt`/keychain" como **achado da Atalaia**, não só exibição passiva. O painel roda **só em loopback** — não é exposto. `[mitiga SH5]` |
| **CTO Copiloto — injection via substrato** | O Copiloto (v14.3) é **orquestrador de tool-routing sobre readers determinísticos com args FIXOS** (não derivados da NL) — a whitelist é de readers **parametrizados de forma fechada**. Retornos do substrato (commit msg, branch name, tool-description MCP) entram **envelopados como DADO** (anti-injection, `context-packet`). Nenhum reader toca valor de segredo. `[fecha SH6]` |

**Por que não há "backend que assina":** a crítica estava certa — não pode haver assinatura server-side autorizada por RBAC sem um processo backend, e a arquitetura nega esse processo. **Resolvemos eliminando a necessidade:** na v14.1 o comando é **local** (IPC do agentd da própria máquina, autoridade = process boundary do SO). O comando cross-máquina (que *exigiria* signer + RBAC) é **v14.4**, e só nasce **junto** com o backend de confiança que o `/spec` desenhar. Os dois nunca coexistem incoerentes. `[CORRIGIDO C2]`

**Invariante de release (gate, não advisory):** **Zero-Leak = 0 sempre.** Um único valor de segredo em qualquer superfície da Bridge é incidente P0 e bloqueia o merge. Regra de bolso: **se o valor de um segredo pode aparecer num screenshot, o design está errado.**

**Retenção de artefatos novos `[CORRIGIDO gap]`:** o `console-audit.log` (ledger local de ações, encadeado por hash) e o ref `mission-control` têm **rotação definida**: o ref sofre `squash` retroativo a cada 30 dias (mantém o último snapshot por máquina + um marco mensal); o audit-log roda por tamanho (`>1MB → arquiva datado`), fechando o learning `git-autosync.log-sem-rotação` para os artefatos que o console cria.

---

## 6. Top-10 features (read-only puras → moonshots viáveis)

1. **System Pulse — heartbeat vivo (local de verdade).** ECG no hero animado pelo **heartbeat LOCAL** (file-watch ~1–5s, fluxo contínuo real); nós remotos mostram "último sinal há Xmin" honesto. Vira vermelho/arrítmico no crítico. *(Wave 1.)* `[CORRIGIDO C1, freshness]`
2. **Mapa de superfície de credenciais — metadata-only, SEM botão de mutação.** Matriz provedor × projeto: presença, idade, classe de risco, var órfã, `.env` exposto. Destaca `SUPABASE_SERVICE_ROLE_KEY` como crítica **sem nunca exibi-la nem oferecer rotação**. *(Wave 1.)* `[CORRIGIDO C8]`
3. **Health-score vivo por produto + deny-list watch.** Card por produto; sub-sinal `idea-doctor` rotulado `n/a` onde não roda (Lovable). O incidente deny-list 5/5→2/5→remediado vira sensor permanente. *(Wave 1.)*
4. **Security-freshness como semáforo + escada.** Badge fresco/stale/egrégio de `check-security-freshness.sh --tier`. **Ilumina, nunca bloqueia** PR. *(Wave 1.)*
5. **Command Palette ⌘K — comando LOCAL reversível.** Pausar/retomar autosync, rodar idea-doctor, re-selar segurança localmente, com resultado inline. Destrutivos = "armar antes de disparar"; `@devops`-exclusivos e mutação de produção **fora**. *(Wave 1, local.)*
6. **Pulso honesto — entrega verificada.** commits humanos `feat`/`fix`/dia, sessões `meaningful` (human_turns>5), co-ocorrência commit↔sessão, milestones SOAK-validados. Banner recusando vaidade. *(Wave 1.)*
7. **Time-Travel / Replay determinístico.** Slider que reconstrói a frota em data passada a partir de ledgers append-only + ref. Post-mortem auditável. **Demo-wow estrutural: reconstruir o incidente real deny-list 5/5→2/5.** *(Wave 2.)* `[reforça wow]`
8. **CTO Copiloto — NL com evidência anexada.** Readers determinísticos de **args fixos** (whitelist fechada); LLM só roteia; retornos envelopados como DADO; nenhum reader toca segredo. *(Wave 2.)* `[CORRIGIDO SH6]`
9. **Token-Cost Ledger.** Custo por propósito (milestone vs housekeeping). Pricing da skill `claude-api`, nunca de memória; sem campo nativo → estimativa **rotulada**. *(Wave 2.)*
10. **Atlas de instincts.** Skill-tree de confidence por domínio, rotulado "maturidade observada", não conduta ao vivo. *(Wave 1.)*

**Recusado por convicção:** ranking de produtividade individual de humanos; qualquer "prévia" de valor de segredo; qualquer verbo cross-máquina antes do `/spec` v14.4.

---

## 7. Roadmap em fases (resumo — detalhe em `01-ROADMAP.md`)

| Fase | Nome | Objetivo | Esforço |
|------|------|----------|---------|
| **v14.0** | Substrato + Espinha | `idea-doctor --json` (+ fallback testado), ref `mission-control`, agentd-coletor (4º LaunchAgent), ingest→SQLite, scaffold | ~1 sem |
| **v14.1** | MVP Bridge (vertical slice, **read-only + comando local**) | Overview + Frota + Cofre-Espelho (metadata-only) + ⌘K local; Zero-Leak gate; **medição de TtT** | ~1–2 sem |
| **v14.2** | Pilares completos | Constelação + Sinapse + Pulso + Atalaia | ~2 sem |
| **v14.3** | Inteligência (Wave 2) | Time-Travel, CTO Copiloto (args fixos), Token-Cost, Atlas | ~2–3 sem |
| **v14.4** | Comando cross-máquina (Wave 3) | **Só com `/spec` + threat-model aprovado:** command cross-máquina, RBAC, step-up, rotate/deploy | gated |

---

## 8. Medição do North-Star `[CORRIGIDO C5]`

`TtT < 10s` e `Trust Rate 100%` deixam de ser não-falsificáveis:

- **Baseline (antes da v14.1):** cronômetro manual sobre 3 jornadas — **J1** "a frota está saudável?", **J4** "a chave X existe e qual a idade?", **J2** "está pronto para tag?" — executadas **via terminal** (estado atual). Registra-se mediana de N≥5 medições por jornada. É esse número (não "2–15min assumido") que vira a linha de base.
- **Pós (na v14.1):** as mesmas 3 jornadas **na Bridge**, mesmo cronômetro. Meta: mediana < 10s.
- **Trust Rate corrigido:** compara a resposta da Bridge **contra o disco no instante da pergunta** (não contra o snapshot em cache, que pode estar stale). A célula da UI exibe "verificado há Xs" e um modo `--verify` recomputa do disco on-demand → o 100% é sobre o disco-agora, não sobre o último ingest. `[CORRIGIDO gap Trust Rate]`

---

## 9. Modelo de dados (resumo)

11 entidades sobre substrato existente: `Machine`, `Account`, `Project`, `User`, **`ApiKey` (sem coluna `value`)**, `McpConnection`, `Session`/`ProductivityEvent`, `Commit` (projeção), `Milestone`/`SoakHeartbeat`, `SecurityFreshnessSeal`, `VersionPin`/`DriftFinding`. Read-model SQLite descartável; ref `mission-control` é a malha de federação.

**Catálogo de risco ÚNICO `[CORRIGIDO C9]`** — uma só escada, sem divergência entre docs:

| Tier | Exemplos | Stale-warn | Stale-egrégio |
|------|----------|-----------|----------------|
| **crítico** | `SUPABASE_SERVICE_ROLE_KEY`, senha de admin | 60d | 180d |
| **alto** | `VERCEL_TOKEN`, `GITHUB_TOKEN`/`gh`, `RESEND_API_KEY`, `RAILWAY_TOKEN` | 90d | 180d |
| **sensível** | `ANTHROPIC_API_KEY`, `OPENROUTER_API_KEY`, `DEEPSEEK_API_KEY`, `EXA_API_KEY` | 90d | 180d |
| **baixo** | chaves `*_PUBLIC`, `anon` | — | — |

`VERCEL_TOKEN = alto` (redeploy de produção) é o valor canônico — o "sensitive" do doc 40 fica deprecado.

**4 gotchas verificados que o schema deve respeitar:** dedup `192`↔`Mac-mini` por alias-map; `gsd 1.1.0`(redux) por **string-equality, nunca semver**; daemon `-` em repouso é **normal** (cruzar com último heartbeat); security ledger de produto é **local** (`.git/info/exclude`) — federa via a string `--tier` no snapshot, não o ledger. Classificação de ator **determinística** (`@*.local$` ou `^wip: autosync` → autosync; `[bot]@` → bot; senão human) separa os 70 commits-fantasma do Mac mini de toda métrica humana.

**Assimetria entre máquinas, assumida honestamente `[CORRIGIDO gap]`:** todo o recon foi no MacBook; o Mac mini só é visto via ref commitado. O collector **não assume simetria** — cada snapshot declara `agentd_version` e `os_version`; a Frota mostra **divergência de versão do collector** como drift âmbar, em vez de quebrar quando os ambientes diferirem.

---

## 10. Como isto é "jamais visto" (ângulo de prêmio)

Não compete na categoria "dashboard" — **cria** a categoria: a ponte nativa de um OS de desenvolvimento de IA pessoal que **já se auto-telemetra cross-máquina via git**. A telemetria não foi instrumentada para o console — já existia como auto-governança (SOAK prova durabilidade, security-freshness prova responsabilidade, idea-doctor prova saúde).

**O wow defensável é ESTRUTURAL, não estético `[CORRIGIDO missingWowFactor]`:** a audiência é 1 operador, então o momento-prêmio não é o confete — é o **Time-Travel reconstruindo o incidente real da deny-list (5/5→2/5→remediado) deterministicamente a partir do event-store**. Isso prova que o substrato é uma fonte-de-verdade auditável, coisa que nenhum "dark admin panel" tem. O Pulse vivo (heartbeat LOCAL real, não teatro sobre lote) é o segundo wow, agora honesto.

---

## 11. Riscos & trade-offs (assumidos)

- **Zero-Leak binário e fatal** → leitura só-de-nomes + teste de invariante como gate de release.
- **Frescor ≠ tempo real** (~15min cross-máquina) → lag exibido por card; Pulse anima só o heartbeat **local**.
- **Sem comando cross-máquina na v14.1** → toda ação remota é v14.4, atrás do `/spec`. Aceito: a v14.1 é leitura + comando local.
- **Single-operator rasa P1/P2** → construir P0 primeiro; P1/P2 rotulados vaporware até segundo ator.
- **`idea-doctor` não roda nos Lovable** → sub-sinal `n/a` honesto, não nota inventada.
- **Staleness cross-máquina não-detectável se o autosync morre** → a Frota mostra 🔴 por idade do ref; **não** se contorna a proteção pull-only do main (o agentd só empurra o ref `mission-control`, igual `planning` — nunca `main`).

---

## 12. Questões abertas (decisão do usuário — `/grelha`)

As contradições do DRAFT foram **resolvidas neste doc**; as escolhas de gosto/escopo foram **decididas pelo usuário em 2026-06-20** (ver banner no topo):

1. **Nome:** ✅ **IdeiaOS Cockpit** (Atalaia = subsistema de alertas; ref de federação `cockpit`).
2. **v14.1 = vertical slice read-only + comando local** ✅ recomendado mantido (default).
3. **Brand-hue:** ✅ ouro IdeiaOS (`--brand-hue:75`).
4. **v14.4 (cross-máquina/rotação):** ✅ **aprovado, gated** por `/spec` + threat-model. v14.0–v14.3 permanecem read-only quanto a produção.

**Próximo passo decidido:** formalizar via `/spec` (capability `cockpit`) → GSD (fase v14.0). Sem código antes do contrato.

---

*Blueprint FINAL — PROPOSTO. Zero código. Próximo passo: `/grelha` sobre §12, depois `/spec` da capability `mission-control` + GSD da fase v14.0.*
