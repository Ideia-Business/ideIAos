# IdeiaOS Bridge — Mission Control · BLUEPRINT-DRAFT

> **Documento 00 · Blueprint consolidado · Lead Architect**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Milestone-alvo:** **v14.x** do IdeiaOS
> **Consolida:** `10-vision-strategy` · `20-architecture` · `30-security-credential-isolation` · `40-data-model-telemetry-mesh` · `50-ux-experience` · `60-moonshot-outside-the-box`
> **Este doc escolhe UM caminho.** Onde os seis docs divergiam (nome do daemon, escopo da v1, brand-hue), a decisão está cravada abaixo e marcada `[DECIDIDO]`. As questões que ainda exigem o usuário estão isoladas em §12 — não são opções abertas no resto do texto.

---

## 1. O produto em uma frase

**IdeiaOS Bridge — Mission Control** é a **ponte de comando** de um sistema operacional de desenvolvimento de IA que já voa por instrumentos: uma única tela de CTO que faz *surfacing* + *controle* sobre o substrato auto-telemetrado que o IdeiaOS produz há 13 milestones — máquinas, produtos, chaves (por referência), conexões de IA/MCP e entrega real — sem nunca coletar dado novo, sem nunca tocar o valor de um segredo, e fechando o loop com comando (cada alerta tem ao lado um botão que dispara um script que o OS já sancionou).

**One-liner (canônico):**
*A ponte de comando do IdeiaOS — todas as máquinas, contas, produtos, chaves e a produtividade de IA do seu ecossistema, numa só tela de CTO. **Controle, não cofre.***

**North-Star:** **Time-to-Truth (TtT)** — mediana de segundos entre uma pergunta de CTO sobre o estado do ecossistema e a resposta confiável, sem abrir um terminal. Baseline manual hoje: 2–15 min. Meta v14: **< 10 s**.

---

## 2. Nome final `[DECIDIDO]`

- **Nome canônico do produto:** **IdeiaOS Bridge**
- **Subtítulo:** *Mission Control*
- **Convenção de marca:** `IdeiaOS Bridge — Mission Control`, encurtável para **"a Bridge"** no dia-a-dia (como "o Finder").
- **Atalaia:** preservada como nome do **subsistema de alertas** dentro da Bridge ("os alertas da Atalaia"), mantendo o equity cultural PT-BR sem comprometer a precisão.
- **Daemon local:** **`ideiaos-agentd`** (resolve a divergência de nomes entre docs 20 e 30; um único componente, dois papéis — coletor + executor). O termo `ideiaos-console-agent` do doc 30 é descontinuado em favor de `ideiaos-agentd`.

**Por quê Bridge e não Atalaia/Cockpit:** "Bridge" é o único nome que descreve a **função arquitetural real** (control plane de leitura **e** comando), não o artefato visual ("dashboard") nem só a vigilância ("Atalaia") nem a categoria saturada ("Cockpit"). (Sujeito a override do usuário — §12, Q1.)

---

## 3. Pilares (5 + 1 transversal)

Cada pilar é uma promessa funcional ancorada num substrato **que já existe** — daí a viabilidade. Ordem = prioridade de valor para o CTO.

| # | Pilar | Promessa | Substrato existente |
|---|-------|----------|---------------------|
| 1 | **Frota** (Fleet) | Quais máquinas existem, estão sincronizadas e saudáveis — agora. | SOAK ledger, commits WIP do autosync, `launchctl`, `idea-doctor` |
| 2 | **Constelação** (Products) | Cada produto, sua stack, seu deploy, sua velocidade **real** (humano-filtrada). | `git log` classificado, `supabase/config.toml`, `git remote`, Lovable MCP read-only, transcripts |
| 3 | **Cofre-Espelho** (Credentials) | Onde cada chave existe, seu escopo, sua idade, status de rotação — **nunca o valor**. | nomes de var (`grep`+`sed`), `.env.example`, `stat`, `gh auth status`, envsync log (hash) |
| 4 | **Sinapse** (AI & MCP) | Quantas contas de cada IA, quais MCPs ligados onde, e a contenção está de pé. | `~/.claude.json`, `~/.cursor/mcp.json`, `.claude/settings.json` deny-list, Lovable MCP UUID |
| 5 | **Pulso** (Delivery) | Onde o tempo de IA virou **entrega verificada** — sinal, não vaidade. | transcripts (`human_turns>5`), git log humano por tipo, SOAK (entrega validada), security ledger, instincts |
| + | **Atalaia** (Alerts/Drift, transversal) | O que mudou e merece olhar — antes de virar incidente. | diff `versions.lock`, regressão de deny-list, autosync parado, security-tier→stale, `.env` órfão, SOAK pronto-p/-tag |

A Atalaia começa como um *strip* ("Atenção Agora") dentro do Overview e é promovida a tela própria quando a lógica de regras amadurecer (fase 3).

---

## 4. Arquitetura escolhida `[DECIDIDO]`

**Local-first, git-as-bus, ZERO backend cloud novo.** (Caminho A do doc 20. Cloud/Supabase rejeitado; híbrido parqueado mas o snapshot JSON é o contrato híbrido-ready.)

```
┌──────────────────────────────────────────────────────────────────────┐
│ DATA-PLANE (read-only, flui para CIMA — metadata-only, ZERO segredo)  │
│  Substrato → ideiaos-agentd LÊ → normaliza → snapshot JSON assinado    │
│  → git plumbing → branch órfão 'mission-control'                       │
└──────────────────────────────────────────────────────────────────────┘
                         │  git-autosync propaga (~900s)
                         ▼
┌──────────────────────────────────────────────────────────────────────┐
│ CONSOLE SPA (Vite+React+shadcn, localhost:127.0.0.1)                   │
│  console-ingest funde N snapshots → SQLite read-model (cache descartável)│
└──────────────────────────────────────────────────────────────────────┘
                         │  enfileira INTENÇÃO tipada (nunca a ação)
                         ▼  command queue versionada em git
┌──────────────────────────────────────────────────────────────────────┐
│ CONTROL-PLANE (write privilegiado, flui para BAIXO)                   │
│  agentd da máquina-alvo: valida verbo no ALLOWLIST FIXO → executa      │
│  script sancionado → escreve resultado. push/PR BLOQUEADOS (@devops).  │
└──────────────────────────────────────────────────────────────────────┘
```

**Decisões cravadas:**

1. **`ideiaos-agentd`** — um daemon Node.js por máquina, 4º LaunchAgent irmão do `git-autosync` (`com.ideiaos.missioncontrol`, ~900s). Dois papéis e só dois: **coletor** (data-plane) e **executor** (control-plane). É o único componente com posse de segredo — o "@devops dos segredos".
2. **Git é o message bus.** Cada máquina escreve **só** seu `snapshots/<machine_id>.json` (1 escritor por arquivo → zero conflito de merge). `machine_id = sha256(hardware-uuid)` dedupe o gap de hostname (`Mac-mini-de-Gustavo` vs `192`). Branch vive **só no repo IdeiaOS** (hub); produtos ficam limpos.
3. **Sem banco de dados de verdade, sem API HTTP no v1.** O **read-model é SQLite single-file** (`~/.ideiaos/console/read-model.db`), **cache 100% descartável** — `rm db && rebuild` reconstrói tudo dos ledgers. A fonte-de-verdade são os arquivos no disco/git (antifragile-gates). SPA lê os snapshots/read-model; o "backend" é o filesystem + git.
4. **Stack = stack canônico dos 4 produtos, zero escolha nova:** Vite 7 + React 18 + TS + Tailwind + shadcn/ui (54 componentes já no nfideia) + Recharts. Reúso direto: `KPICard`/`AppLayout`/`AppSidebar`/`NotificationBell` do nfideia, `HealthScore`/`TrendChart` do health-dashboard, tema do cfoai-grupori como template estrutural.
5. **Único componente de coleta NOVO** é o collector (`scripts/console-collect.sh`), que materializa o estado **efêmero** (`launchctl`, `idea-doctor`, contas de IA, versões instaladas) num snapshot. **Recomendação: piggyback no SOAK `--record`** (que já roda `idea-doctor`) → zero daemon extra.
6. **Latência cross-máquina ~15 min (1 ciclo autosync) é ACEITA** — a Bridge é estratégica, não real-time. Ações na máquina **local** são rápidas (modo `watch`); cross-máquina é eventual. Staleness honesto: 🟢 <30min · 🟡 <6h · 🔴 >6h.
7. **Gateway MCP read-first por construção:** reusa `source/lib/lovable-mcp.sh` (verify-deploy/detect-hotfix) e a **deny-list de 19 tools mutantes** já enforçada; o console **audita** essa deny-list como health-check contínuo, **nunca a modifica**. Lovable write/publish permanece bloqueado (Fases C/D parqueadas, v10).

**Mudanças no substrato — mínimas, aditivas, com fallback:**
`idea-doctor.sh --json` (flag nova, fallback para parse ANSI `━━━`) · `com.ideiaos.missioncontrol.plist` · branch órfão `mission-control` (git plumbing, padrão `planning`) · `source/lib/mission-control.sh` (reusa `gates.sh` + `handoff-packet.sh`) · `scripts/check-mission-control.sh` + §15 nova no `idea-doctor` (self-monitoring/dogfooding). Nenhum ledger muda de formato; nenhum script existente muda de comportamento (só ganha flag).

---

## 5. Modelo de segurança (um parágrafo forte)

A Bridge é, por construção, **um plano de controle sobre cofres que ela nunca abre** — e essa não é uma escolha de UI, é a aplicação direta da regra-piso `credential-isolation`: o browser do console é tratado como ambiente **não-confiável**, equivalente ao contexto do LLM, onde o **valor** de um segredo (API key, token, `SERVICE_ROLE`) **jamais** transita — nem no estado React, nem no DOM, nem na rede, nem em log, nem no snapshot, nem no ledger. O console conhece a credencial **só por referência** (nome, presença, idade via `stat`, escopo via `gh auth status`, `last-used`, `risk_tier`, status de rotação = risco × idade), todos derivados sem ler o RHS do `=` (o pipeline usa `grep '^[A-Z_]*=' | sed 's/=.*//'`, e a entidade `ApiKey` **não tem coluna `value` by construction**); o único componente autorizado a resolver e usar valores é o `ideiaos-agentd` **server-side**, que recebe uma **intenção tipada por nome**, resolve o segredo do keychain/daemon, chama a API do provedor, grava o novo valor de volta no keychain — e devolve ao browser **apenas metadado** ("rotacionado há 0 dias"), nunca o valor. Toda ação privilegiada (rotate/revoke/deploy, pausar autosync, re-selar segurança) passa por um **allowlist FIXO de verbos** (sem `exec` arbitrário — anti-Excessive-Agency/OWASP LLM06), respeita o `agent-authority` (deploy de produção e `git push`/PR continuam exclusivos do `@devops`/`cto`-role, o console **não os expõe**), exige **step-up auth** para credenciais `critical`, e é registrada num **ledger append-only com encadeamento de hash**, commitado e protegido por `!console-audit.log` no `.gitignore` (learning `broad-gitignore-sweeps-tracked-ledger`). O resultado é uma defesa **estrutural, não disciplinar**: um XSS total, um screenshot, uma extensão comprometida não acham valor algum para exfiltrar porque o valor nunca esteve no plano de controle — e a regra de bolso para o time é absoluta: **se o valor de um segredo pode aparecer num screenshot da tela, o design está errado.**

**Invariante de release (gate, não advisory):** **Zero-Leak = 0 sempre.** Um único valor de segredo em qualquer superfície da Bridge é incidente P0 e bloqueia o merge.

---

## 6. Top-10 features (read-only puras → moonshots viáveis)

Todas respeitam `credential-isolation` como lei física e ancoram entrega em SOAK, não em vaidade.

1. **System Pulse — heartbeat vivo do ecossistema.** Linha SVG/ECG no hero que bate no **ritmo real** dos epochs do SOAK ledger + commits do autosync; vira vermelha e arrítmica quando algo fica crítico. Comunicação pré-cognitiva de "sistema vivo". *(Wave 1 — já dá.)*
2. **Mapa de superfície de credenciais (control-plane).** Matriz provedor × projeto: presença, idade, classe de risco, var órfã, `.env` exposto no git — destacando `SUPABASE_SERVICE_ROLE_KEY` como crítica **sem nunca exibi-la**. A "central de chaves" pedida, feita do jeito certo. *(Wave 1 — já dá, metadata.)*
3. **Health-score vivo por produto + deny-list watch.** Card por produto (idea-doctor, security-tier, drift, contenção Lovable 5/5?, recência humana, deploy Lovable via MCP read-only). O incidente real da deny-list (5/5→2/5→remediado) vira sensor permanente. *(Wave 1 — já dá.)*
4. **Security-freshness como semáforo permanente + escada.** Badge fresco/stale/egrégio (de `check-security-freshness.sh --tier`) no header; quando degrada, mostra o que tocou superfície crítica e o botão "agendar `@security-reviewer` no diff desde o último selo". **Ilumina, nunca bloqueia** PR de feature. *(Wave 1 — já dá.)*
5. **Command Palette ⌘K — cockpit de comando.** Não só navega: **comanda** o substrato (pausar/retomar autosync, rodar idea-doctor, re-selar segurança, kickstart de daemon) com resultado inline tipo Raycast. Destrutivos exigem "armar antes de disparar"; operações `@devops`-exclusivas ficam fora. *(Wave 1 local — já dá.)*
6. **Pulso honesto — entrega verificada, não vaidade.** 4 KPIs ancorados em sinal real: commits humanos `feat`/`fix`/dia (exclui bot+autosync+wip), sessões `meaningful` (human_turns>5), co-ocorrência commit↔sessão, **milestones SOAK-validados** (a única entrega verificada cross-máquina). Banner explícito recusando vaidade. *(Wave 1 — já dá.)*
7. **Time-Travel / Replay do estado do OS.** Slider temporal que reconstrói **deterministicamente** a frota em qualquer data passada a partir de ledgers append-only + git (event-store imutável). Vira post-mortem e prova auditável point-in-time ("em 14/06 a contenção Lovable estava 5/5"). *(Wave 2 — já dá, precisa do folder.)*
8. **CTO Copiloto — NL sobre o ecossistema, com evidência anexada.** Barra de comando: "qual máquina não dá heartbeat há mais tempo?" → resposta em uma frase com a **linha exata do ledger / commit SHA**. O LLM é **orquestrador de tool-routing** sobre readers determinísticos pré-aprovados (whitelist), nunca fonte de fato nem shell livre. Retornos do substrato envelopados como DADO (anti-injection). *(Wave 2 — precisa de wrapper.)*
9. **Token-Cost Ledger por projeto/agente/decisão.** Custo de tokens atrelado a propósito (milestone vs housekeeping), possível porque transcripts são particionados por projeto e agentes declaram modelo no frontmatter. Pricing canônico da skill `claude-api`, **nunca de memória**; sem campo de uso nativo, cai para estimativa **honestamente rotulada**. *(Wave 2 — precisa de parser.)*
10. **Atlas de instincts — maturidade do agente por domínio.** Skill-tree de confidence + evidence_count por domínio (git/bash/ts/sql), mostrando onde a parte sintética da equipe já é confiável e o que está pronto para `/evolve`. Rotulado honestamente como "maturidade observada", não conduta ao vivo (`learning-channel-routing`). *(Wave 1 — já dá.)*

**Bônus parqueado (Wave 3, threat-model dedicado):** *Black-box / flight-recorder* (congela pacote forense datado no critical) e *Simulador "E se…"* (dry-run de blast-radius de rotação de chave) entram quando 7 e 3 estiverem maduros. **Recusado por convicção:** ranking de produtividade individual de humanos (ético-tóxico) e qualquer "prévia" de valor de segredo.

---

## 7. Roadmap em fases (milestone v14.x do IdeiaOS)

| Fase | Nome | Objetivo | Entregáveis-chave | Esforço |
|------|------|----------|-------------------|---------|
| **v14.0** | **Substrato + Espinha** | Tornar o substrato federável e nascer a SPA | `idea-doctor --json`; branch órfão `mission-control`; `console-collect.sh` (piggyback SOAK) gerando snapshot por máquina; `console-ingest` → SQLite read-model; scaffold Vite/React/shadcn black-gold; `machine-aliases.json`/`user-aliases.json`; `check-mission-control.sh` + §15 | ~1 sem |
| **v14.1** | **MVP "Bridge" (vertical slice)** | Provar surfacing + control-plane-seguro de ponta a ponta | **Overview** (System Pulse vivo, cards Frota/Segurança/Releases/Atenção); **Frota**; **Cofre-Espelho** (matriz metadata-only); Command Palette ⌘K com ações **locais** sancionadas; invariante Zero-Leak como gate de release | ~1–2 sem |
| **v14.2** | **Pilares completos** | Fechar os 5 pilares + Atalaia | **Constelação** (produtos, velocity humana, Lovable MCP); **Sinapse** (Conexões MCP + Contas & IAs, deny-list watch); **Pulso** (entrega honesta); strip Atalaia → tela | ~2 sem |
| **v14.3** | **Inteligência (Wave 2)** | Camada que exige parser/grafo, baixo risco | Time-Travel; CTO Copiloto (anti-injection); Token-Cost (estimativa rotulada); Atlas de instincts maduro; Simulador "E se…" (dry-run, nunca executa) | ~2–3 sem |
| **v14.4** | **Comando cross-máquina (Wave 3)** | Ação real cross-máquina **só com segurança desenhada** | `/spec` próprio + threat-model; command-via-commit assinado/whitelist; step-up auth; RBAC cto/dev; black-box/flight-recorder | gated por threat-model |

**Gate de fechamento de cada fase (padrão IdeiaOS):** SOAK 2 máquinas + span ≥1d, `idea-doctor` verde, security-freshness re-selado, README atualizado, vault Obsidian (Changelog + learnings). v14.4 **não inicia** sem o `/spec` de segurança aprovado.

---

## 8. Fase 1 — recorte mínima-viável-mas-impressionante (v14.1)

**Tese do slice:** entregar a **alma do produto** (surfacing que já nasce cheio + control-plane que herda a constituição do OS) com o menor número de telas possível, mas com o "wow" intacto.

**Escopo (3 telas + 1 plano de comando):**
- **Overview** — bento-grid de comando, tudo acima da dobra em 1440×900: **System Pulse** (heartbeat vivo no ritmo real do SOAK/autosync, momento-wow nº1), cards **Frota** (2/2 máquinas, PASS), **Segurança** (badge de tier + barra "idade até stale"), **Releases/SOAK** (countdown até span≥1d + celebração "PRONTO PARA TAG"), e **Atenção Agora** (action feed priorizado por urgência, com botão inline).
- **Frota** — card por máquina (vital signs, mini-timeline de heartbeats 7d, drift de versão âmbar), tabela densa de heartbeats brutos, dedup de hostname surfaceada honestamente (`Mac-mini-de-Gustavo aka 192`).
- **Cofre-Espelho** — matriz variável × projeto **metadata-only** (presença `●/○`, risco por var, alertas de órfã/rotação/`.env` exposto), banner-doutrina "Control-plane, não cofre", estado-vazio celebrado ("Zero segredos no contexto. Como deve ser."). Zero ação que leia/escreva valor.
- **Command Palette ⌘K** — ações **locais** sancionadas (pausar/retomar autosync, rodar idea-doctor, re-selar segurança, kickstart daemon), resultado inline, "armar antes de disparar" nos destrutivos. Operações `@devops`-exclusivas ficam fora.

**Por que esse recorte impressiona:** Frota prova *surfacing que já nasce cheio* (o SOAK ledger vira heartbeat de frota a custo zero); Cofre-Espelho prova *control-plane seguro por construção* (a inversão metadata-first/value-never); o System Pulse prova *vivo agora*; o Command Palette prova *J7 — comando, não leitura passiva*. Juntos, são a tese inteira num slice construível em ~1–2 semanas.

**Stack & tema:** Vite+React+TS+shadcn/ui+Recharts; tema **black-gold OKLCH** (`--brand-hue:75`, `bg #000000`, `accent-gold #C9B298`, do `graph-dashboard/THEME`). Componentes reaproveitados: `KPICard`/`AppLayout`/`AppSidebar` (nfideia), `HealthScore`/`TrendChart` (health-dashboard). Mono em todo dado numérico; micro-labels gold uppercase; cor só para semântica (verde/âmbar/vermelho), ouro = hierarquia/marca/seleção, nunca estado.

**Critérios de aceite do slice:**
- TtT < 10 s para J1 (frota saudável?), J4 (chave existe/idade?) e J2 (pronto p/ tag?).
- **Zero-Leak = 0** verificado por teste de invariante (gate de release, não advisory).
- Coverage ≥ 3/8 JTBD sem cair pro terminal; Trust Rate 100% (bate com ground-truth do arquivo).
- ⌘K executa pelo menos `autosync-pause`, `idea-doctor`, `security --record` localmente, com resultado inline.
- `idea-doctor §15` audita o próprio console (agentd ativo? snapshot fresco? branch existe?).
- Acessibilidade WCAG 2.1 AA (contraste, cor nunca único sinal, ⌘K e navegação por teclado, `prefers-reduced-motion`).

---

## 9. Modelo de dados (resumo)

11 entidades sobre substrato existente: `Machine`, `Account`, `Project`, `User`, **`ApiKey` (sem coluna `value`, by construction)**, `McpConnection`, `Session`/`ProductivityEvent`, `Commit` (projeção), `Milestone`/`SoakHeartbeat`, `SecurityFreshnessSeal`, `VersionPin`/`DriftFinding`. Read-model em SQLite descartável; git é a malha de federação. Quatro gotchas verificados no disco que o schema **deve** respeitar: dedup `192`↔`Mac-mini` por alias-map; `gsd 1.1.0`(redux) comparado por **string-equality, nunca semver**; daemon `-` em repouso é **normal** (cruzar com último heartbeat, não tratar como falha); security ledger de produto é **local** (`.git/info/exclude`) — federa via a string `--tier` no snapshot, não o ledger inteiro. Classificação de ator **determinística** (`@*.local$` ou `^wip: autosync` → autosync; `[bot]@` → bot; senão human) separa os 70 commits-fantasma do daemon do Mac mini de toda métrica humana.

---

## 10. Como isto é "jamais visto" (o ângulo de prêmio)

Não compete na categoria "dashboard" — **cria** a categoria: a ponte nativa de um OS de desenvolvimento de IA pessoal que **já se auto-telemetra cross-máquina via git**. A telemetria não foi instrumentada para o console — já existia como mecanismo de auto-governança (SOAK prova durabilidade, security-freshness prova responsabilidade, idea-doctor prova saúde). O console é a **leitura humana e o comando** de um sistema que já se governa assim. O bus de telemetria É o bus de código; o control-plane herda o `agent-authority`; a gestão de chaves é control-plane por princípio constitucional, não por escolha de UI. **A colheita de uma semeadura involuntária** — e é exatamente isso que ninguém mais tem.

---

## 11. Riscos & trade-offs (assumidos)

- **Zero-Leak é binário e fatal** → leitura só-de-nomes + teste de invariante como gate de release.
- **Frescor ≠ tempo real** (~15 min cross-máquina) → freshness lag exibido por card; staleness tiers honestos.
- **`idea-doctor` sem `--json`** → `--json` é pré-requisito da v14.0, com fallback de parse ANSI.
- **Command queue = vetor de injeção** → allowlist FIXO + `agent-authority` + validação na execução; push/PR nunca expostos.
- **Single-operator hoje** rasa as personas P1/P2 → construir para P0 (CTO-de-um-só) primeiro; ator amadurece com `git author email`.
- **Escopo-creep para runtime de produto (end-users)** viola `credential-isolation` → fechado por design.
- **Hostname inconsistente** → `machine_id = sha256(hardware-uuid)` + alias-map curado.

---

## 12. Questões abertas (decisão do usuário — `/grelha`)

1. **Nome:** confirma **IdeiaOS Bridge** (Atalaia = subsistema de alertas)? Ou prefere **Atalaia** como nome do produto inteiro?
2. **"Usuários dos projetos"** = **contributors do repo** (o que o substrato dá) `[default assumido]`, ou expectativa de **end-users dos produtos** (exigiria Supabase Auth de cada produto e esbarra em `credential-isolation`)?
3. **Local-first confirmado** `[default assumido]`, ou há intenção futura de instância remota (mudaria a postura de segurança)?
4. **Escopo da v14.1:** confirma o **vertical slice** (Overview + Frota + Cofre-Espelho + ⌘K local) `[recomendado]`, ou quer os 5 pilares de uma vez?
5. **Brand-hue:** **ouro IdeiaOS** (`--brand-hue:75`) `[default]`, ou um azul/outro hue para a identidade-OS? (Reversível por 1 linha OKLCH.)
6. **Command-plane na UI:** executar não-destrutivos + confirmar destrutivos a partir da UI `[default]`, ou tudo como "gera o comando para copiar" (versão ultra-segura dado `agent-authority`)?

---

*Blueprint consolidado — PROPOSTO. Zero código. Decisões `[DECIDIDO]` aqui valem como base dos docs de execução; as de §12 cedem ao usuário. Próximo passo: `/grelha` sobre §12, depois `/spec` da capability `mission-control` + GSD da fase v14.0.*
