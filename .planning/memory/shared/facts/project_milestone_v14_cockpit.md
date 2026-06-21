---
name: project-milestone-v14-cockpit
description: v14 "IdeiaOS Cockpit" — console web CTO local-first sobre o substrato auto-telemetrado; blueprint multi-agente + contrato /spec (capability cockpit, 9 req) + plano GSD formalizados em 2026-06-20 como PROPOSTO (zero código). Aguarda v13 fechar (tag) + /gsd-plan-phase v14.0.
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

**⚠️ Gate de execução (NÃO entrelaçar):** `/gsd-execute-phase 14.0` só **depois do v13 tagar**.
Razão concreta (não só disciplina): o plano `14.0-01` edita `scripts/idea-doctor.sh`, que o SOAK
pendente do v13 RE-EXECUTA na re-gravação (`idea_doctor=PASS|regression=PASS`) — editar agora
arriscaria a tag do v13. Ver [[learning-active-milestone-gate-couples-via-shared-file]]. Se forçar
antes, rodar só Wave 1 **menos o 14.0-01**.

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
Cross-link:
[[project-milestone-v13-security-freshness]], [[project-aiox-core-pristine-overlay]].
