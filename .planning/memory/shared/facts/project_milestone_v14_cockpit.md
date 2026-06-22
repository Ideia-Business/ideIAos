---
name: project-milestone-v14-cockpit
description: v14 "IdeiaOS Cockpit" — console web CTO local-first. v14.0 (Substrato+Espinha) EXECUTADO/COMPLETO 2026-06-21. v14.1 (MVP Bridge) EXECUTADO/code-complete + CLOSEOUT 2026-06-22 (bug CORS-preflight S-05 corrigido). v14.4 (write-path security) contrato /spec PROPOSTO/staged 2026-06-22 (pré-merge, 11 reqs R-WP1..R-WP11, painel adversarial 3 lentes SOUND, Q1-Q3 gated, merge≠resolução). Tags v14.0/v14.1 DEFERIDAS (1 máq/0d). GOTCHA: CLI GSD não resolve fases v14 (sem v14-ROADMAP.md) → planejar/fechar espelhando o método v14.0.
metadata:
  node_type: memory
  type: project
  originSessionId: e2d20fda-07d9-4d22-a7ac-b952167fa73d
---

**v14 — IdeiaOS Cockpit** (nome escolhido pelo usuário; metáfora glass-cockpit). Console web de
visão CTO/Tech-Lead sobre TODO o ecossistema: máquinas, contas/IAs, projetos+usuários, chaves
(por-referência), conexões MCP e produtividade. **Insight central:** o IdeiaOS já se
auto-telemetra cross-máquina via git (SOAK, security-freshness, idea-doctor, autosync,
instincts) → o Cockpit é **camada de surfacing + controle**, não coleta nova.

**Decisões do usuário (2026-06-20, via AskUserQuestion):**
- Nome = **IdeiaOS Cockpit**; ref de federação git = `cockpit`; daemon = `ideiaos-agentd`.
- Caminho = **formalizar via /spec + GSD antes de código** (não build imediato).
- Teto de poder = **comando cross-máquina aprovado para v14.4**, gated por /spec de segurança +
  threat-model STRIDE/OWASP-LLM. v14.0–v14.3 permanecem read-only quanto a produção.
- Brand-hue = ouro (`--brand-hue:75`), black-gold OKLCH (herda o `graph-dashboard/THEME`).

**Arquitetura (decidida):** local-first, **git-as-bus por REF** (`cockpit`, via commit-tree/update-ref —
NUNCA working tree, então o `git add -A` cego do autosync não captura) + 4º LaunchAgent
`com.ideiaos.cockpit` (900s) + read-model SQLite descartável + SPA Vite/React/shadcn em
127.0.0.1 sem login. **Invariante-piso: Zero-Leak=0** (valor de segredo nunca no browser/LLM;
`ApiKey` sem coluna value).

**Feito neste turno (2026-06-20):**
- Blueprint multi-agente (13 agentes/5 fases; crítico adversarial pegou contradição fatal
  "piggyback no SOAK --record é manual") em `docs/ideiaos-console/` (00-BLUEPRINT + 01-ROADMAP +
  02-PHASE-1-SPEC + 10..60).
- Contrato `/spec` **vivo**: `specs/cockpit/spec.md` (9 requisitos SHALL/DEVE); change
  validada+merged+arquivada em `specs/_archive/2026-06-20-v14-cockpit-foundation/` (gates
  spec-validate + spec-analyze verdes). Foi o **1º uso de `specs/` dentro do próprio IdeiaOS**.
- Plano GSD: `.planning/milestones/v14-cockpit-PLAN.md` (R14-00..09; v14.0→v14.4), status PROPOSTO.

**Pendente p/ abrir v14 ATIVO:** (1) v13 fechar (tag via SOAK — agendado). ADR
`docs/decisions/v14-cockpit-local-first-git-as-bus.md` = ✅ criado (2026-06-20).

**v14.0 (Substrato + Espinha) PLANEJADO (2026-06-21, commit `9bcb15c`, multi-agente Ultracode):**
7 PLAN.md GSD em `.planning/milestones/v14-phases/14.0-substrate-spine/` (20 tasks / 3 waves) —
01 idea-doctor `--json` (R14-01) · 02 ref `cockpit` por plumbing (R14-02) · 03 TtT baseline (R14-06) ·
04 SPA scaffold Vite/React/black-gold (R14-04) · 05 agentd collector + plist (R14-02) · 06 schema.sql
8 tabelas (ApiKey sem value) + ingest.js (R14-03) · 07 SPA lê read-model + gates/SOAK (R14-04).
Frota: gsd-pattern-mapper → gsd-planner → 3 verificadores adversariais paralelos (plan-checker +
security-reviewer + auditor antifragile). **6 defeitos pegos e corrigidos** (gate-theater
tautológico; regex JWT fraca p/ service_role; falta gate bind-loopback; falta diff §15; IDs
`R14-CTX-A*` fantasma = violação Art. IV No-Invention; tabela errada p/ `last_doctor`) — todos
re-verificados por exit-code, 0 violações antifragile. `14.0-CONTEXT.md` + `14.0-PATTERNS.md` +
seção "v14.0 PLANEJADO" no `v14-cockpit-PLAN.md`.

**✅ Gate de execução LIBERADO (2026-06-21):** o v13 **tagou** (`v13.0`, SOAK fechado manualmente na Mac mini) → o acoplamento via `scripts/idea-doctor.sh` (que o SOAK do v13 RE-EXECUTAVA) está resolvido, não há mais milestone ativo em SOAK tocando o arquivo. Ver [[learning-active-milestone-gate-couples-via-shared-file]].

**✅ Planos v14.0 CORRIGIDOS + VERIFICADOS (2026-06-21, pré-execução):** rodada de prontidão (`wf_98a657c0`) achou **GO_WITH_FIXES** — ambiente PASS mas **5/7 planos com defeitos** (ACs insatisfazíveis/gate-teatro + 1 gate de segurança OCO). Corrigidos (`wf_00f74ad3`: 7 fixers disjuntos + verify adversarial **13/13 sondas exit-code** → **CLEAR_TO_EXECUTE**), commit `ac68817`. As 3 estruturais: (a) `cockpit_write_snapshot` `git mktree` em 2 níveis (subárvore flat + topo `040000 tree`) — o slash em `snapshots/<MID>.json` dava `fatal: contains slash` exit 128 e impedia o ref; (b) gate credential-isolation **discriminante** (`! sqlite3 … | cut -d'|' -f2 | grep -qiw value` — o `grep -qiv '|value|'` antigo era OCO, passava com e sem coluna); (c) **`node:sqlite`** built-in (Node 24) no lugar de `better-sqlite3` (dep nativa órfã, não resolvia em wave order). As correções cruzaram doc 72 + 14.0-PATTERNS.md. **Próximo: `/gsd-execute-phase 14.0` em contexto fresco** (config: worktree-paralelo, executor sonnet, branching none/commita em `work`; ⚠️ autosync PAUSADO — religar ao fim). Lição: rodar a revisão de prontidão ANTES de `execute-phase` pegou um build que teria quebrado no happy-path.

**Gotchas honestos (do blueprint):** P1/P2 multi-usuário = vaporware (tudo é `gustavo@`);
idea-doctor `n/a` nos Lovable (health-score por produto com sub-sinal honesto).

**Apuração 4 eixos (2026-06-20, docs `docs/ideiaos-console/70`–`73`; Wave 1 validação NA Mac-mini +
Wave 2 = 3 agentes):** (1) assimetria entre máquinas FECHADA — rodou na própria Mac-mini; (2)
CORREÇÃO `192→MacBook-Air-2` (não Mac-mini) no alias-map SOAK; (3) Constelação tem **7 projetos**
reais (Jarvis 469 sessões, ideia-chat) → descobrir, não hardcodar 5; (4) **nenhum segredo crítico
git-tracked** (só `.env` públicos rastreados em nfideia/ideiapartner) — credential-isolation segura
na prática; (5) **v14.4 write-path é GATE, não milestone** — autenticação de origem é bloqueante
(`sha256≠assinatura`; doc 70 lista 9 questões p/ o /spec consumir); (6) MVP ganha **Flight Recorder
v0** na v14.1 (replay determinístico do flip-flop do pin `gsd`, doc 71); (7) v14.0 = 37 tarefas
buildáveis, risco-chave = não-regressão ANSI do idea-doctor (doc 72). **Wave de completude (100%,
docs 74-79):** resiliência (agentd empurra o ref `cockpit` por si → autosync vira redundância, não
SPOF; doc 74); DDL completo, 13 tabelas, ApiKey sem coluna value provada em 4 elos (doc 75); fórmulas
de produtividade — KPI-âncora = milestones SOAK (ininflável), multi-usuário gated por 2º ator
≥10 commits/90d (doc 76); 11 alertas Atalaia + allowlist ⌘K, `revoke`-em-massa fica FORA pra sempre
(doc 77); estratégia de testes Zero-Leak + dogfood de veneno `sk-ant-FAKE` (doc 78); glossário 22
termos + **REGISTRO MESTRE de 39 questões/riscos (doc 79 = índice canônico)**. Topo aberto 🔴 = Q1
autenticação de origem cross-máquina (`sha256≠assinatura`) — faz a v14.4 ser gate, não milestone.
**✅ v14.0 EXECUTADO/COMPLETO (2026-06-21, `/gsd-execute-phase 14.0`, sessão noturna):** modo **SEQUENCIAL** (escolha do usuário — fase auto-modificante: o OS edita o próprio autosync + empurra ref novo) dos 7 planos via subagentes `gsd-executor`. **7/7 DONE**; verificação goal-backward **24/24 gates por exit-code** (`14.0-VERIFICATION.md` status=passed — feita INLINE pelo orquestrador porque o `gsd-verifier` bateu 529 2×; exit-code é mais robusto que NL). Entregue: `idea-doctor --json` (§0-§15, ANSI byte-idêntico) · `source/lib/cockpit.sh` ref-federation (git-plumbing, A4) + **`push_cockpit_ref` no `~/.local/bin/git-autosync` + `git push -u origin cockpit` (user-aprovado, @devops) → `cockpit@{u}=30edb3e`** · `source/agentd/` (Zero-Leak=0, snapshot metadata-only, plist 4º LaunchAgent NÃO-bootstrapped) · `source/console/` (read-model SQLite, api_key sem `value`, A5, 7 proj/121 keys/0 value) · TtT harness · `apps/cockpit/` SPA black-gold loopback → **frontend-visual-loop PASSED** (screenshot: card `c706ac77d577`/`doctor:unknown`). SOAK v14.0 1 máq/0d; security re-selo PASS. **Tag DEFERIDA** (≥2 máq + span≥1d, igual v11-13). **Incidente:** autosync ignorou o pause-file (binário deployado sem guard) → **hard-stop via `launchctl bootout`** durante o build, restaurado ao fim → [[learning-autosync-pause-file-guard-not-deployed]]. **`phase.complete` CLI falhou** (milestone sem `v14-ROADMAP.md`) → completude marcada manualmente. Commits limpos `24290e6`→`85de7dd` (origin/work 0/0).

**✅ v14.1 (MVP Bridge) PLANEJADO (2026-06-21 noite, `/gsd-plan-phase v14.1`, multi-agente):** 8 `PLAN.md` (17 tasks/4 waves) + `14.1-CONTEXT/RESEARCH/PATTERNS/VALIDATION.md` em `.planning/milestones/v14-phases/14.1-mvp-bridge/`. **GOTCHA RECORRENTE:** o CLI GSD **não resolve** fases v14 (`roadmap.get-phase 14.1`→`found:false`) porque o milestone usa `v14-cockpit-PLAN.md` (igual v11–v13), nunca registrado no `.planning/ROADMAP.md` canônico — mesma causa do `phase.complete` falho no 14.0. **Solução:** planejar/fechar fases v14 **espelhando o método v14.0** (dir manual `14.X-<slug>/` + multi-agente pattern-mapper→planner→verificadores), NÃO o fluxo CLI. (Follow-up opcional aberto: criar `v14-ROADMAP.md` p/ destravar o CLI nas 14.2–14.4 — não feito, decisão do usuário.) Fluxo: CONTEXT (das fontes travadas; capability/ref=`cockpit`, NÃO `mission-control` dos docs 02/71) → research-alvo + pattern-map (paralelo) → planner opus → **3 lentes** (plan-checker CONCERNS/0-blocker · security-reviewer SOUND-WITH-FIXES → **S-01 HIGH**: canal `POST /command` autenticava origem só por CORS → CSRF/DNS-rebinding driva `spawnSync`; corrigido c/ Origin+Host fail-closed + token efêmero `X-Cockpit-Token` · antifragile **0 violações**, 52 critérios) → **9 fixes aplicados**. **Reconciliações código-real vs docs:** `node:sqlite` (NÃO `better-sqlite3`); Flight Recorder = 13 commits reais via `ingest.js:classifyActor` (não 4); Zero-Leak regex+entropia+veneno triplo; `cmdk` = única dep nova. Verificado por exit-code (não pela alegação dos agentes). **Mergeado em `main` por FF + push (@devops), `f8c224c`** — main=work=origin alinhados, idea-doctor 76/2/0. Próximo: `/gsd-execute-phase 14.1` (contexto fresco; autosync pausado p/ gates git; `14.1-08` Task 2 após `/compact`).

**✅ v14.1 (MVP Bridge) EXECUTADO/code-complete + CLOSEOUT (2026-06-22, sessão pós-/compact):** modo **SEQUENCIAL com gate por wave** (escolha do usuário) dos 8 planos via `gsd-executor` — **8/8 DONE**, suite **A1–A12 9/9 por exit-code** (cada plano re-verificado pelo orquestrador, não pela alegação do subagente). Entregue: `read.js` (+`/overview /fleet /vault /verify /command-token` + `POST /command`) · Flight Recorder v0 (13 nós/3 reversões, re-derivado do git) · Zero-Leak 7-superfícies + veneno triplo · TtT Bridge harness · telas Overview/Frota/Cofre + ⌘K (cmdk, allowlist B1–B6 default-deny). **Closeout (A11):** **passe visual A7/A10 via frontend-visual-loop (Chrome DevTools MCP)** screenshotou Overview/Frota/Cofre + rodou verbos inline (`run_doctor→exit 0`, `pause_autosync` arm→Confirmar?→exit 0). **🔴 BUG MATERIAL achado no visual-loop (não pelo exit-code/curl):** o `POST /command` falhava no browser (`net::ERR_FAILED`) — faltava handler de **preflight CORS** (`OPTIONS /command`→404); curl mascarava (curl não faz preflight). **Fix S-05** (+25 linhas, aditivo): handler de preflight gated por `isTrustedOrigin` (204 confiável / 403 caso contrário; `Allow-Origin` exato + `Vary`; auth do POST intacta) → re-revisão `@security-reviewer` focada = **PASS, 0 findings**. Re-selo de segurança **PASS** no ledger. README atualizado (seção console). **SOAK v14.1 1 máq/0d → tag DEFERIDA** (≥2 máq + span≥1d, igual v11–v14.0). Lição: [[learning-curl-masks-cors-preflight-verify-browser]] — o regime-R pega o que o exit-code não pega.

**✅ v14.4 (write-path security) — contrato `/spec` PROPOSTO/staged (2026-06-22 tarde, pré-merge):** sessão "faça tudo que pode ser feito" durante o SOAK das tags. Autorado `specs/_changes/v14.4-write-path-security/` (proposta + `delta/cockpit.md` + tasks) — **11 requisitos R-WP1..R-WP11 / 29 cenários** materializando o gate vivo "Comando cross-máquina e mutação de produção gated", consumindo o precursor `docs/ideiaos-console/70-...` §8 (Q1-Q9) + doc 77 §B.2. Define **COMPORTAMENTO** (SHALL/DEVE), NÃO mecanismo (O2 assinatura-por-máquina / O3 SSH-signing / O4 out-of-band = decisão do operador). **Q1-Q3 (CRÍTICAS, estruturalmente abertas) = pré-condições bloqueantes em R-WP10; merge ≠ resolução** (achado HIGH do painel: o loophole "resolvidas neste contrato" foi reescrito p/ ratificar o /spec NUNCA ser lido como resolver Q1-Q3). Verificação: `spec-validate.sh` exit 0 + **painel adversarial 3 lentes** (`wf_7cb55bba`: security-STRIDE/no-invention/contract-quality) = **SOUND, 0 CRITICAL, 0 fabricação**; 9 achados (1 HIGH + 2 MED [STRIDE-I metadado-ao-origin/Q5; STRIDE-D flood→**R-WP11** rate-limit] + 6 LOW) integrados. **Commit `c119afb` pushado, STAGED não merjado** — ratificação (`spec-merge.sh . v14.4-write-path-security --yes`) é decisão do operador; depois **Q1-Q3 viram ADRs** (mecanismo de assinatura, bootstrap/revogação de chave, step-up sem RP-server) **antes** de qualquer código v14.4.

Cross-link:
[[project-milestone-v13-security-freshness]], [[project-aiox-core-pristine-overlay]], [[learning-autosync-pause-file-guard-not-deployed]], [[learning-active-milestone-gate-couples-via-shared-file]], [[learning-curl-masks-cors-preflight-verify-browser]], [[credential-isolation]], [[agent-authority]].
