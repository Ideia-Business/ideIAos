# v14 — IdeiaOS Cockpit · PLAN + status

**Origem:** sessão de design 2026-06-20 (orquestração multi-agente — 13 agentes / 5 fases; 3 decisões via AskUserQuestion).
**Design:** `docs/ideiaos-console/00-BLUEPRINT.md` (+ `01-ROADMAP.md`, `02-PHASE-1-SPEC.md`, `10`…`60` por especialista).
**Contrato vivo:** `specs/cockpit/spec.md` (capability `cockpit`, 9 requisitos SHALL/DEVE — `/spec` aplicado e arquivado em `specs/_archive/2026-06-20-v14-cockpit-foundation/`).
**Disciplina:** local-first · git-as-bus por REF (não working tree) · control-plane (metadata), nunca cofre · defesa estrutural, não disciplinar · Zero-Leak=0 como gate · SOAK antes de tag.
**Status:** 🔵 **PROPOSTO (zero código)** — contrato `/spec` + plano GSD formalizados 2026-06-20. Construção começa **após** o v13 fechar (tag) e um `/gsd-plan-phase v14.0` consumir `specs/_archive/.../tasks.md`.

> **Decisões do usuário (2026-06-20):** nome = **IdeiaOS Cockpit** (ref de federação `cockpit`); caminho = **formalizar via `/spec` + GSD antes de código**; teto de poder = **comando cross-máquina aprovado para v14.4**, gated por `/spec` de segurança + threat-model; brand-hue = ouro (`--brand-hue:75`).

## Princípio
O IdeiaOS já se auto-telemetra cross-máquina (SOAK, security-freshness, idea-doctor, git-autosync, instincts). O Cockpit é **camada de surfacing + controle** sobre esse substrato — não coleta nova. Lê por referência, comanda só o **local e reversível**; mutação de produção e ação cross-máquina ficam atrás de um threat-model (v14.4). O valor de um segredo **jamais** transita pelo browser/LLM (`credential-isolation`).

## Requisitos

| ID | Requisito | Fase | Status |
|----|-----------|------|--------|
| R14-00 | Contrato de comportamento `cockpit` vivo (`specs/cockpit/spec.md`, 9 req SHALL/DEVE) — fonte-de-verdade que os gates `spec-validate`/`spec-analyze` protegem | transversal | ✅ DONE (este turno) |
| R14-01 | `idea-doctor.sh --json` — flag nova (14 seções → JSON) **+ fallback ANSI testado** antes de qualquer consumidor depender do JSON | v14.0 | ✅ DONE 2026-06-21 (24/24 verif) |
| R14-02 | `ideiaos-agentd` coletor read-only → `snapshots/<machine_id>.json` no ref `cockpit` via git-plumbing (working tree limpo) + `com.ideiaos.cockpit.plist` (4º LaunchAgent, 900s) + push do ref pelo autosync (nunca `main`) | v14.0 | ✅ DONE 2026-06-21 (24/24 verif) |
| R14-03 | `console-ingest` → read-model SQLite descartável (`~/.ideiaos/console/read-model.db`, `rm && rebuild` reconstrói dos refs) | v14.0 | ✅ DONE 2026-06-21 (24/24 verif) |
| R14-04 | Scaffold Vite/React/TS/Tailwind/shadcn black-gold OKLCH (reuso nfideia) + `check-cockpit.sh` + `idea-doctor §15` (dogfooding: agentd ativo? ref existe? snapshot fresco?) | v14.0 | ✅ DONE 2026-06-21 (24/24 verif) |
| R14-05 | MVP Bridge read-only (loopback, sem login): Overview (System Pulse local-vivo) + Frota + Cofre-Espelho (metadata-only, zero botão de mutação) + Command Palette ⌘K (allowlist fixo) + **Flight Recorder v0** (naco de wow estrutural — replay determinístico do flip-flop real do pin `gsd` no `versions.lock`, via `git show <sha>:versions.lock`; o card Releases cede o countdown decorativo — doc 71) | v14.1 | 🔵 PROPOSTO |
| R14-06 | Gate **Zero-Leak** (`test:zeroleak`, exit-code binário, bloqueia release) + harness de medição de **Time-to-Truth** (baseline terminal N≥5 J1/J4/J2 → meta <10s) | v14.1 | 🔵 PROPOSTO |
| R14-07 | Pilares completos (ainda read-only): Constelação (produtos) + Sinapse (IAs & MCP + deny-list watch **que grava LEDGER ESTRUTURADO append-only de contenção: `epoch\|iso\|produto\|deny_count\|total\|commit`** — pré-requisito do momento-prêmio da v14.3, doc 71) + Pulso honesto (4 KPIs entrega-verificada) + Atalaia (alertas/drift) | v14.2 | 🔵 PROPOSTO |
| R14-08 | Inteligência (Wave 2): Time-Travel completo (evolui o Flight Recorder v0) + CTO Copiloto (readers de args FIXOS, anti-injection) + Token-Cost Ledger (estimativa rotulada) + Atlas de instincts. **Dependência (doc 71):** o "momento-prêmio" deny-list 5/5→2/5 exige um **ledger estruturado** que só pode nascer na v14.2 — hoje só existe em prosa de commit (alucinável); sem ele, é vaporware | v14.3 | 🔵 PROPOSTO |
| R14-09 | **Comando cross-máquina + mutação de produção (rotate/revoke/deploy)** — só com `/spec` de segurança + threat-model STRIDE/OWASP-LLM aprovado; RBAC cto/dev + step-up; janela de privilégio com teardown. **Precursor de threat-model = doc 70**: o `/spec` formal DEVE consumir as 9 questões abertas (§8) como requisitos literais. Achado bloqueante: **autenticação de origem** (`sha256≠assinatura`; quem assina o comando cross-máquina sem segredo no contexto) ainda aberta → habilitar incrementalmente (1º `rotate` local-na-máquina, sem cross-máquina) | v14.4 | ⛔ GATED (precursor escrito; write-path NÃO-pronto até origin-auth cravada) |

## Ondas (ordem integridade-antes-de-capacidade)

- **v14.0 — Substrato + Espinha** (R14-01..04): tornar o substrato federável e nascer a SPA, sem UI de valor. `idea-doctor --json` + fallback · ref `cockpit` · agentd coletor (4º LaunchAgent) · ingest→SQLite · scaffold. **Consome** `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md`.
- **v14.1 — MVP Bridge** (R14-05, R14-06): vertical slice read-only + comando local; Overview/Frota/Cofre + ⌘K; gate Zero-Leak; medição de TtT. ✅ **PLANEJADO 2026-06-21** → 8 `PLAN.md` (17 tasks, 4 waves) em `.planning/milestones/v14-phases/14.1-mvp-bridge/`. Ver "## v14.1 — PLANEJADO" abaixo.
- **v14.2 — Pilares completos** (R14-07): Constelação + Sinapse + Pulso + Atalaia, ainda read-only.
- **v14.3 — Inteligência** (R14-08): Time-Travel, Copiloto (args fixos), Token-Cost, Atlas — médio risco, sem mutação cross-máquina.
- **v14.4 — Comando cross-máquina** (R14-09): **GATED** por `/spec` + threat-model. Só aqui nasce RBAC/rotação/deploy, junto do canal de confiança.

## Definition of Done

1. **Zero-Leak binário:** nenhum valor de segredo em qualquer superfície (UI/DOM/rede/log/snapshot/ledger); teste de invariante como gate de release (exit-code, nunca Read tool).
2. **Read-only quanto a produção até v14.4:** nenhum verbo de mutação de produção/cross-máquina no allowlist antes do threat-model aprovado.
3. **Coleta não-mutante:** agentd grava só no ref `cockpit` via plumbing; `git status` dos repos permanece limpo; `main` nunca é empurrado pelo agentd/autosync.
4. **Frescor honesto:** local-vivo (file-watch) vs cross-máquina-eventual (~15min) distintos na UI; nunca animar fluxo sobre lote.
5. **Autoridade @devops respeitada:** push/PR/MCP nunca executados pelo Cockpit (no máximo gera o comando).
6. **TtT medido, não assumido:** baseline cronometrado antes da v14.1; Trust Rate verificado contra o disco no instante da pergunta.
7. **idea-doctor verde** (incl. nova §15 do Cockpit) + gates `/spec` verdes (`spec-validate` + `spec-analyze`).

## Pendente para abrir v14 como milestone ATIVO
1. v13 fechar (tag `v13.0` via SOAK — em andamento, agendado).
2. ✅ `/gsd-plan-phase v14.0` EXECUTADO (2026-06-21) → 7 `PLAN.md` (20 tasks, 3 waves) em `.planning/milestones/v14-phases/14.0-substrate-spine/`, verificados por 3 lentes adversariais. Ver "## v14.0 — PLANEJADO" abaixo.
3. ✅ ADR `docs/decisions/v14-cockpit-local-first-git-as-bus.md` criado (decisão arquitetural irreversível: git-as-bus por ref + agentd; teto de poder gated).
4. ✅ **`/gsd-execute-phase 14.0` EXECUTADO (2026-06-21)** — 7/7 planos DONE, verificação goal-backward **24/24 gates por exit-code** (`14.0-VERIFICATION.md` status=passed). Ref `cockpit` pushed (`cockpit@{u}=30edb3e`); SPA renderiza card real (screenshot). Tag v14.0 deferida (SOAK ≥2 máq + span≥1d). **Próximo:** v14.1 (MVP Bridge).

## v14.1 — ✅ PLANEJADO (2026-06-21)

**Planos** (`.planning/milestones/v14-phases/14.1-mvp-bridge/`) — vertical slices read-only sobre a Espinha v14.0; cada `<task>` por exit-code (A1–A12). Naming = `cockpit` (nunca mission-control); data access = `node:sqlite` (nunca better-sqlite3); Zero-Leak = regex+entropia; Flight Recorder = git vivo.

| Plano | Slice | Wave | depends_on | Requisito | Gate-âncora |
|-------|-------|------|------------|-----------|-------------|
| `14.1-01` data-access foundation (read.js +/overview//fleet//vault//verify + tokens --status-*) | fundação | 1 | — | R14-05, R14-06 | /vault metadata-only (sem `value`) + bind 127.0.0.1 |
| `14.1-05` Flight Recorder v0 (git→flight-recorder.json + FlightRecorder.tsx + test:recorder) | wow estrutural | 1 | — | R14-05 | A12 SET-to-SET git==render + ≥1 nó amber |
| `14.1-07` TtT Bridge harness (ttt-baseline/median `--mode=bridge`) | gate TtT | 1 | — | R14-06 | A2 mediana Bridge <10s |
| `14.1-02` Overview + App shell/nav (seam ⌘K) + System Pulse | tela Overview | 2 | 01,05 | R14-05 | frescor honesto + Releases-SOAK lean (sem countdown) |
| `14.1-03` Frota + Cofre-Espelho | telas Frota/Cofre | 3 | 01,02 | R14-05 | Cofre metadata-only (sem controle de valor) + drift string-equality |
| `14.1-04` Command Palette ⌘K (cmdk + POST /command enum) | comando local | 3 | 01,02 | R14-05 | default-deny 403 + armar-antes-de-disparar + A8 forever-OUT |
| `14.1-06` Zero-Leak gate (7 superfícies + entropia + dogfood duplo) | gate P0 | 4 | 01,02,03,04 | R14-06 | A3 Zero-Leak=0 + veneno duplo (sk- + alta-entropia) |
| `14.1-08` Phase closeout (idea-doctor §15 + suite A1–A12 + SOAK + re-selo) | fechamento | 4 | todos | R14-05, R14-06 | A1–A12 verde + A9 §15 sem regressão ANSI + SOAK/re-selo |

**Cobertura:** R14-05 (01,02,03,04,05,08) + R14-06 (01,06,07,08); todo requisito em ≥1 plano. **Threat-model** em cada PLAN (ASVS L1; foco no ⌘K POST /command e nos gates Zero-Leak/Cofre). **Próximo:** `/gsd-execute-phase 14.1` (contexto fresco, autosync pausado).

## v14.0 — ✅ EXECUTADO/COMPLETO (2026-06-21)

**Planos** (`.planning/milestones/v14-phases/14.0-substrate-spine/`), consomem `docs/ideiaos-console/72` (37 tarefas N.M, exit-code-gated) + `specs/cockpit/spec.md` (9 req):

| Plano | Grupo | Wave | depends_on | Requisito | Gate-âncora |
|-------|-------|------|------------|-----------|-------------|
| `14.0-01` idea-doctor --json | §1+§0 | 1 | — | R14-01 | não-regressão ANSI (diff stripped exit 0) |
| `14.0-02` ref cockpit (plumbing) | §2 | 1 | — | R14-02 | A4 `git status --porcelain` vazio |
| `14.0-03` TtT baseline | §5 | 1 | — | R14-06 | N≥5/jornada + mediana bash puro |
| `14.0-04` SPA scaffold | §6.1/6.2 | 1 | — | R14-04 | `npm run build` + loopback |
| `14.0-05` agentd coletor | §3 | 2 | 01,02 | R14-02 | Zero-Leak snapshot + dogfood veneno DUPLO (sk- + JWT) |
| `14.0-06` console-ingest | §4 | 2 | 02,05 | R14-03 | api_key sem `value` (PRAGMA) + A5 rm+rebuild |
| `14.0-07` UI lê DB + gates | §6.3/§7 | 3 | 04,06 | R14-04 | bind-loopback explícito + Zero-Leak=0 + SOAK |

**Verificação adversarial (3 lentes, 2026-06-21):**
- **gsd-plan-checker** → CONCERNS (0 blocking; cobertura/ondas/escopo PASS).
- **security-reviewer (opus)** → arquitetura SOUND; credential-isolation estruturalmente fechada.
- **antifragile-gates auditor** → **0 violações** (81 critérios, 74 exit-code, 1 runtime-UI legítimo).

**6 correções aplicadas pós-revisão** (todas verificadas por exit-code):
- **W1** (gate-teatro): exit-code do baseline ANSI era tautológico (`$B=$B`) → grava `/tmp/ansi_baseline_exit` e compara sem fallback auto-anulável.
- **H-01** (HIGH, jóia): regex JWT do Zero-Leak fortalecido p/ `eyJ…\.eyJ` (o `service_role` É um JWT) + poison dogfood DUPLO (sk- **e** JWT-veneno).
- **M-01** (MEDIUM): gate de exit-code provando bind explícito em `127.0.0.1` (curl passaria com 0.0.0.0) — contém o treasure-map ao loopback.
- **W2**: prova de que SÓ a §15 foi adicionada ao idea-doctor (diff ancorado em "━━━ Resumo ━━━").
- **W3** (rastreabilidade): removidos IDs-fantasma `R14-CTX-A*` (inexistentes em fonte canônica — Article IV No-Invention); `requirements:` agora só R14-0x reais.
- **W4**: card lê `last_doctor` de `machine` (não `machine_snapshot`).

**Carry-forward p/ v14.3 (A-02):** subject de commit / tool-description MCP entram no read-model como DADO-não-confiável (anti-injection) — o Copiloto herda a quarentena.

## Apuração (2026-06-20) — 4 eixos aprofundados

Pente-fino pós-blueprint (Wave 1 = validação na própria Mac-mini; Wave 2 = 3 especialistas paralelos). Docs: `docs/ideiaos-console/70`–`73`.

- **Eixo 1 — substrato REAL validado** (`doc 73`): rodou na Mac-mini (gap "1 máquina só" fechado). Confirmou `idea-doctor --json` ausente; **corrigiu** `192→MacBook-Air-2` (não Mac-mini); **expandiu** a Constelação p/ 7 projetos (Jarvis 469 sessões, ideia-chat) → descobrir, não hardcodar; mapeou a superfície de credenciais real e provou que **nenhum segredo crítico está git-tracked** (`credential-isolation` segura na prática).
- **Eixo 2 — segurança v14.4** (`doc 70`): veredito = **write-path é GATE, não milestone**. ~metade fechada estruturalmente; a outra metade (**autenticação de origem**) é bloqueante — sem ela o RBAC é teatro. Gating incremental: `rotate` local primeiro; cross-máquina só após origin-auth. O `/spec` consome as 9 questões abertas.
- **Eixo 3 — tensão MVP×wow** (`doc 71`): resolvida com **Flight Recorder v0** na v14.1 (replay determinístico do flip-flop do pin `gsd`, 100% exit-code, ~2 dias; o card Releases cede o countdown). Wow estrutural já na 1ª impressão. Achado: o Time-Travel da v14.3 depende de ledger estruturado nascido na v14.2.
- **Eixo 4 — v14.0 buildável** (`doc 72`): 37 tarefas `- [ ] N.M` com critério por exit-code, prontas p/ `/gsd-plan-phase`. Maior risco = não-regressão da saída ANSI do `idea-doctor` (script vivo de ~593 linhas); mitigado por teste de diff ANSI-stripped. Escopo ~1 semana = realista p/ 1 dev (~5–7 dias úteis).

### Wave de completude (100% — docs `74`–`79`)

Seis especialistas paralelos fecharam os eixos restantes (cada doc gateado por `test -s`):

- **`74` Resiliência/federação/retenção** — fecha a **dependência circular autosync↔Frota**: o `agentd` empurra o ref `cockpit` por si (`git push origin refs/heads/cockpit:refs/heads/cockpit`, hard-scoped, jamais `main`/`--all`) → o autosync vira **redundância, não SPOF**; cada snapshot carrega `autosync_last_push` (auto-denúncia do autosync agonizando). Retenção: squash 48h/30d/90d do ref + audit-log encadeado por hash. Trust-Rate via `--verify` (recompute-from-disk, exit-code).
- **`75` Modelo de dados + DDL** — 13 tabelas fundamentadas nos dados REAIS; **`ApiKey` isolada por construção** (sem coluna `value`; prova em 4 elos — `INSERT` com segredo falha por falta de coluna). Risco-chave: curadoria do alias-map/classificação-de-ator (não tem exit-code que a proteja — normalizar antes do UPSERT).
- **`76` Pulso/produtividade** — KPI-âncora = **milestones SOAK-validados** (ininflável: `span≥1d` é delta de epochs gravados); barra a vaidade nº1 (contagem bruta de sessão — Jarvis 469 ≠ 469 entregas; filtro `human_turns>5`). Multi-usuário **já computado** (partição por email); gate revela P1/P2 só com 2º ator ≥10 commits/90d; até lá UI rotula "monousuário hoje", não card-fantasma.
- **`77` Atalaia + allowlist** — 11 alertas (A1–A11) + 6 verbos ⌘K (B1–B6). Fora do allowlist **para sempre:** `revoke` em massa (DoS estrutural — nenhuma assinatura o torna seguro como ação atômica).
- **`78` Testes & verificação** — Zero-Leak **materializa cada superfície de runtime em arquivo** antes de varrer (traz regime-2 p/ regime-1 = exit-code) + dogfood de veneno (`sk-ant-FAKE…` DEVE reprovar, senão o gate é teatro); harness de TtT; teste ANSI-stripped do `idea-doctor`.
- **`79` Glossário + REGISTRO MESTRE** — 22 termos canônicos (rascunho do `CONTEXT.md`) + **registro consolidado de 39 questões/riscos** (9 abertos · 18 mitigados · 12 resolvidos). **É o índice canônico de risco do plano.**

**Topo do registro mestre (`doc 79`):** a questão 🔴 de maior severidade ainda aberta é **Q1 — autenticação de origem cross-máquina** (`sha256 ≠ assinatura`; sem ela o RBAC é teatro) — o achado que faz a v14.4 ser **gate, não milestone**. Q2 (step-up sem relying-party server) e Q3 acompanham. Todas alimentam o `/spec` de segurança da v14.4.

## Riscos & decisões adiadas
- **Single-operator (P0):** P1/P2 (líder de squad, dev individual) e metade do Pulso dependem de sinal multi-usuário que ainda não existe (toda observação é `gustavo@`) → rotulados **vaporware honesto** até segundo ator.
- **idea-doctor não roda nos Lovable** → health-score por produto com sub-sinal `n/a` honesto, nunca nota inventada.
- **Assimetria entre máquinas** (todo recon foi no MacBook; Mac mini só via ref) → collector declara `agentd_version`/`os_version`; divergência vira drift âmbar, não quebra.
- **"Mapa do tesouro"** (listar onde as chaves críticas vivem) → mitigado por loopback + Zero-Leak; nunca exposto fora de `127.0.0.1`.
- **Adiado p/ v14.4+:** RBAC/passkey/mTLS/step-up; rotate/revoke/deploy; comando cross-máquina; flight-recorder + Simulador "E-se".
