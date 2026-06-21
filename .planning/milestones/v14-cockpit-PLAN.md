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
| R14-01 | `idea-doctor.sh --json` — flag nova (14 seções → JSON) **+ fallback ANSI testado** antes de qualquer consumidor depender do JSON | v14.0 | 🔵 PROPOSTO |
| R14-02 | `ideiaos-agentd` coletor read-only → `snapshots/<machine_id>.json` no ref `cockpit` via git-plumbing (working tree limpo) + `com.ideiaos.cockpit.plist` (4º LaunchAgent, 900s) + push do ref pelo autosync (nunca `main`) | v14.0 | 🔵 PROPOSTO |
| R14-03 | `console-ingest` → read-model SQLite descartável (`~/.ideiaos/console/read-model.db`, `rm && rebuild` reconstrói dos refs) | v14.0 | 🔵 PROPOSTO |
| R14-04 | Scaffold Vite/React/TS/Tailwind/shadcn black-gold OKLCH (reuso nfideia) + `check-cockpit.sh` + `idea-doctor §15` (dogfooding: agentd ativo? ref existe? snapshot fresco?) | v14.0 | 🔵 PROPOSTO |
| R14-05 | MVP Bridge read-only (loopback, sem login): Overview (System Pulse local-vivo) + Frota + Cofre-Espelho (metadata-only, zero botão de mutação) + Command Palette ⌘K (allowlist fixo de verbos locais reversíveis) | v14.1 | 🔵 PROPOSTO |
| R14-06 | Gate **Zero-Leak** (`test:zeroleak`, exit-code binário, bloqueia release) + harness de medição de **Time-to-Truth** (baseline terminal N≥5 J1/J4/J2 → meta <10s) | v14.1 | 🔵 PROPOSTO |
| R14-07 | Pilares completos (ainda read-only): Constelação (produtos) + Sinapse (IAs & MCP + deny-list watch) + Pulso honesto (4 KPIs entrega-verificada) + Atalaia (alertas/drift) | v14.2 | 🔵 PROPOSTO |
| R14-08 | Inteligência (Wave 2): Time-Travel determinístico (demo: incidente deny-list 5/5→2/5) + CTO Copiloto (readers de args FIXOS, anti-injection) + Token-Cost Ledger (estimativa rotulada) + Atlas de instincts | v14.3 | 🔵 PROPOSTO |
| R14-09 | **Comando cross-máquina + mutação de produção (rotate/revoke/deploy)** — só com `/spec` de segurança + threat-model STRIDE/OWASP-LLM aprovado; RBAC cto/dev + step-up; janela de privilégio com teardown | v14.4 | ⛔ GATED (aprovado em princípio; depende do threat-model) |

## Ondas (ordem integridade-antes-de-capacidade)

- **v14.0 — Substrato + Espinha** (R14-01..04): tornar o substrato federável e nascer a SPA, sem UI de valor. `idea-doctor --json` + fallback · ref `cockpit` · agentd coletor (4º LaunchAgent) · ingest→SQLite · scaffold. **Consome** `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md`.
- **v14.1 — MVP Bridge** (R14-05, R14-06): vertical slice read-only + comando local; Overview/Frota/Cofre + ⌘K; gate Zero-Leak; medição de TtT.
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
2. `/gsd-plan-phase v14.0` consumindo `specs/_archive/2026-06-20-v14-cockpit-foundation/tasks.md` → `PLAN.md` task-a-task da fase 0.
3. (Recomendado) ADR `docs/decisions/v14-cockpit-local-first-git-as-bus.md` registrando a decisão arquitetural irreversível (git-as-bus por ref + agentd) e o teto de poder gated.

## Riscos & decisões adiadas
- **Single-operator (P0):** P1/P2 (líder de squad, dev individual) e metade do Pulso dependem de sinal multi-usuário que ainda não existe (toda observação é `gustavo@`) → rotulados **vaporware honesto** até segundo ator.
- **idea-doctor não roda nos Lovable** → health-score por produto com sub-sinal `n/a` honesto, nunca nota inventada.
- **Assimetria entre máquinas** (todo recon foi no MacBook; Mac mini só via ref) → collector declara `agentd_version`/`os_version`; divergência vira drift âmbar, não quebra.
- **"Mapa do tesouro"** (listar onde as chaves críticas vivem) → mitigado por loopback + Zero-Leak; nunca exposto fora de `127.0.0.1`.
- **Adiado p/ v14.4+:** RBAC/passkey/mTLS/step-up; rotate/revoke/deploy; comando cross-máquina; flight-recorder + Simulador "E-se".
