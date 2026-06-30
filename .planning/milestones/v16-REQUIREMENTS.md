# Requirements — v16: Plataforma de Time (multi-dev, split-plane)

**Milestone:** v16
**Aberto:** 2026-06-25 · **Status:** 🟢 **ATIVO — 4 gates de ativação resolvidos 2026-06-29** (v15 shippado · 2º dev real `lucas-abreu56` · R16-03 decidido [ADR `v16-r16-03-github-identity-transport.md`] · contrato R16-01/02 ratificado). **Construção de F1 gated** em: dono executar o runbook R16-03 (FG-PATs) + escolher motor multi-usuário (RLS). Regime FREE = governança advisory.
**Renumeração:** este milestone **era rotulado "v15"** no ADR `docs/decisions/v15-cockpit-split-plane-control-plane.md` e nos design-docs `docs/ideiaos-console/{80,81,82}`. Por decisão do dono (2026-06-25), o número **v15 foi reatribuído ao milestone "DX & Frota"** (que shipa primeiro), e a plataforma de time passou a ser **v16** (shipa depois = número maior, mantendo número = ordem de ship). **O conteúdo de design permanece válido** — só o número do milestone mudou. (O nome de arquivo do ADR foi preservado para não quebrar cross-refs; um aviso de renumeração foi adicionado no topo dele.)
**Fonte:** ADR `v15-cockpit-split-plane-control-plane.md` (split-plane) + design `80-split-plane-control-plane-DESIGN.md` + `81-team-platform-control-DESIGN.md` + `82-team-coordination-onboarding-requirements.md`. Re-escopo multi-dev fundamentado no deploy real dos 4 repos. `@security-reviewer = NEEDS_REVISION` (4 must-fix do read-fan-out + 4 BLOCKERS da plataforma de time).
**Tese:** quando houver **N devs** (não só o operador), o Cockpit precisa de identidade, RBAC-de-leitura, admissão de estação e coordenação — sem nunca mover a AUTORIDADE (assinar/verificar/pinar/possuir-segredo) da máquina local. O cloud é **plano de VIEW** (metadata-only), nunca control-plane.

> **Pré-condição de existência:** o v16 só faz sentido quando houver um **2º dev real não-admin**. Construí-lo antes é o anti-padrão de super-construção que o próprio ADR já rejeitou (split-plane PLENO recusado para "1 CTO + poucos devs"). **Gate de necessidade comprovada, não de tempo.**

---

## Fronteira herdada do v15

O v15 (DX & Frota) entrega o **single-operator**: instalação excelente, gerência da própria frota, e o write-path **own-fleet** (1 operador comandando N máquinas dele — R15-17). O v16 adiciona a dimensão **multi-ator**: N devs, identidade, RBAC, admissão, claims. Tudo que o v16 constrói **assenta sobre** o write-path own-fleet provado no v15.

## Requisitos (DRAFT — refinar via `/spec` antes de qualquer código)

| ID | Requisito | Origem | Status |
|----|-----------|--------|--------|
| **R16-01** | **Ratificar o split-plane em escopo MAGRO** (F0+F1 read-only) desacoplando do calcanhar GitHub. F0 já está provado (N=2 de signing feita); o delta real é só F1 (read-fan-out). **ANTES de construir F1:** merjar via `/spec` os SHALL `R-WP12` (view read-only, divergência = alerta nunca atualização) + RLS-por-campo + Admissão (hoje só no ADR, não no contrato vivo). Ratificar (pure-design) ≠ construir F1. | CKF-01 | 🟢 ratificado 2026-06-29 (delta merjado: contrato cockpit 20→24 reqs, +R-WP12/RLS/admissão; 4 gates verdes) |
| **R16-02** | **Identidade & RBAC-de-leitura por-projeto** (admissão por pin O2 + escopo). ⚠️ **Precondição de infra:** o read-model atual é **SQLite descartável** — sem RLS/CREATE POLICY/mascaramento-por-papel. **Materializar AGORA só o CONTRATO** (cláusulas SHALL de RBAC + cenário de teste NEGATIVO no `/spec` — barato, pré-condição de P3). A **implementação RLS** fica gated no motor multi-usuário — **DECIDIDO 2026-06-30** (ADR `docs/decisions/v16-r16-02-motor-plano-view.md`): **Supabase Postgres dedicado, projeto P3 NOVO** (org IdeiaOS, free, 2º projeto), **distinto** do `xdikjgpkiqzgebcjgqmu` — ⚠️ este ref era **erro**: é o step-up/P4, reuso violaria S-04. Papel binário admin/dev no MVP (anti-over-build). | CKF-02 | 🟢 contrato materializado 2026-06-29 + **motor DECIDIDO 2026-06-30** (ADR); provisionar P3 (dono) → schema RLS |
| **R16-03** | **Resolver o BLOCKER da conta GitHub compartilhada** (FG-PAT por-estação não provisionado) — o **calcanhar estrutural** que trava a ratificação inteira. Probe `gh` por exit-code; decidir entre FG-PAT por-estação OU migração para contas pessoais (`DevIdeiaBusiness` OAuth). Fork "contas-pessoais" segue **visível e ativo**, não fechado. | ADR v15 BLOCKER #2 | 🟢 DECIDIDO 2026-06-29 — ADR `v16-r16-03-github-identity-transport.md`: Opção C (híbrido faseado), regime FREE advisory, 2FA adiado. Impl operacional (FG-PATs) = runbook do dono |
| **R16-04** | **Coordenação anti-colisão** (claims soft-lock) — F3 do design. **ADIAR** até "2º dev real + colisão medida ≥1×" (gate explícito do design pós-review). Construir antes repete o anti-padrão de super-construção. `depends_on R16-02`. | CKF-04 | ⏸️ parqueado-gated |
| **R16-05** | **Reserva-de-poder & fila-de-Publish** — F4 (último tijolo). **Honestidade estrutural:** "interceptar o clique Update→Publish" é **impossível como hard-gate** (o botão é web na Lovable; main não tem branch protection; o MCP não governa deploy — provado na Fase B do v10). É fila **ADVISORY cooperativa**; a governança HARD real só existe no deploy-**backend** (gate local no agentd). Gated em R15-17 fechado + F1-F3 + ratificação. | CKF-06 | ⏸️ parqueado-gated |
| **R16-06** | **Governança contínua no servidor** (cross-check telemetria↔audit-log) — **re-escopado:** o pilar Audit-Log API é **INVIÁVEL** (org Ideia-Business é plano **free** → API retorna 404; só Enterprise Cloud) → remover/parkear. Os demais pilares convergem com o v15 (R15-10/11 já cobrem CI + lembretes). | CKF-08 | 🔵 parcial |

## Pendências de segurança (do `@security-reviewer`, bloqueiam ratificação)

Ver a seção "Pendências de segurança" do ADR `v15-cockpit-split-plane-control-plane.md` (4 must-fix do read-fan-out + 4 BLOCKERS da plataforma de time, convergindo no calcanhar da conta GitHub compartilhada — R16-03). Rótulos revisados pelo review adversarial `wf_8432e800-818` (atribuição → MITIGADO-PARCIAL; reversão → BLOCKER-CONDICIONAL após probe `gh`; step-up-loopback → defesa-em-profundidade).

## Invariante permanente (não revogável pelo v16)

`credential-isolation` AGRAVADO, não relaxado: multi-ator = mais alvos. O **valor** de um segredo nunca transita pelo plano de view/cloud/LLM. Os três ativos que dariam controle total (chave O2, lista pinada, valor de segredo) vivem TODOS em planos locais distintos, nenhum no cloud. Comprometer o plano de view (P3) rende metadata + capacidade de mentir a view — o teto que o invariante permite.

## Gates de ativação do v16 — TODOS RESOLVIDOS 2026-06-29 ✅

1. ✅ v15 (DX & Frota) **shippado** (tag `v15.0`, write-path own-fleet R15-17) — precondição satisfeita.
2. ✅ **2º dev real não-admin** surgiu (`lucas-abreu56`, confirmado pelo dono) — gate de necessidade aberto.
3. ✅ **Decisão R16-03 tomada** — ADR `v16-r16-03-github-identity-transport.md` (Opção C híbrido faseado, regime free advisory).
4. ✅ **`/spec` dos SHALL R16-01/R16-02 merjado** no contrato vivo `specs/cockpit/spec.md` (4 SHALL, 4 gates verdes, delta arquivado `specs/_archive/2026-06-29-v16-ratificacao-split-plane/`).

## Próximo passo (construção F1 — gated, não-bloqueante para a ativação)

- **Frente A (Dono):** runbook **documentado** (`docs/guides/r16-03-fg-pat-migration.md`); executar quando quiser (emitir FG-PATs por-máquina + aposentar o token org-wide). NÃO manuseável pelo agente (credential-isolation).
- **Frente B — motor DECIDIDO 2026-06-30** (ADR `docs/decisions/v16-r16-02-motor-plano-view.md`) = Supabase Postgres dedicado, **projeto P3 NOVO** (≠ `xdikjgpkiqzgebcjgqmu`/step-up). **Próximo passo concreto:** (1) **dono cria o projeto P3** (org IdeiaOS, 2º projeto free) + passa o ref + configura credenciais fora do contexto; (2) **agente escreve o schema** (8 tabelas, RLS deny-all, mascaramento por-campo) → **gate teste negativo** contra backend real → admissão por pin O2 → re-apontar ingest → Auth-leitura (contas pessoais) → read-fan-out/telas → consolidar `/spec`. Sequência de 9 passos em `v16-motor-decision-analysis.md`.
- **Parqueado por necessidade comprovada:** R16-04 (claims, só após colisão medida), R16-05 (fila Publish advisory), R16-06 (audit-log, só se org virar Enterprise).
