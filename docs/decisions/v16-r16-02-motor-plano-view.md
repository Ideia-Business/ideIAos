# ADR — v16 / R16-02: motor do Plano de View (P3) = Supabase Postgres dedicado, projeto NOVO distinto do step-up

**Status:** **ACEITO 2026-06-30** (decisão do dono). Resolve a escolha de motor multi-usuário da Frente B (read-fan-out com RLS). Fundamentado na análise multi-agente `wf_631edb5c-e96` (4 lentes independentes + síntese sobre arquivos reais — Article IV) + confirmação do estado real da org Supabase pelo dono (screenshots).
**Não revoga:** a autoridade do v16 (RBAC por assinatura O2 + pin local). Esta decisão é sobre o **engine do Plano de View (P3)** — metadata-only, read-only. `credential-isolation` permanece regra-piso.
**Relaciona:** materializa a precondição de infra de R16-02 (`.planning/milestones/v16-REQUIREMENTS.md`); consome o contrato `specs/cockpit/spec.md` (R16-02, R-WP12). Análise completa em `.planning/milestones/v16-motor-decision-analysis.md`.

## Contexto

A Frente B (read-fan-out: N devs veem o estado da frota com RBAC) exige um motor que satisfaça os SHALL de R16-02 — **RLS deny-all + mascaramento por-campo por papel + admissão de estação por pin O2**. O read-model atual é **SQLite descartável** (gerado por console-ingest; `api_key` sem coluna `value`; reconstruído a cada ciclo do agentd) — **sem RLS nativa**. A análise das 4 lentes convergiu (sem forçar): **Supabase Postgres dedicado** é a única opção que satisfaz cada SHALL **no engine**; SQLite+app é teatro de RLS, Postgres self-hosted mata o propósito (loopback não alcança 3 máquinas), Neon é dominada (fragmenta a stack sem ganho).

### Achado crítico (corrige o `v16-REQUIREMENTS`)

O `v16-REQUIREMENTS.md` R16-02 nomeava `xdikjgpkiqzgebcjgqmu` como "Supabase dedicado" do motor de view. **Esse ref está incorreto:** a memória `stepup-backend-provisioned` + o STATE + os screenshots do painel confirmam que `xdikjgpkiqzgebcjgqmu` é o projeto **"IdeiaOS - Cockpit" do STEP-UP (P4)** — contém a `STEPUP_SIGNING_KEY`, as edge functions de OTP, os trusted-devices. Reusá-lo como P3 **violaria o invariante S-04 / R-WP12** (P3 fisicamente distinto de P4): acoplaria a view (metadata-rica, lida por N devs sob anon-key) e a infraestrutura de autoridade do step-up no mesmo Postgres/`SERVICE_ROLE`.

Estado real da org Supabase (painel, 2026-06-30): org **IdeiaOS** = **Free Plan, 1 projeto** (`IdeiaOS - Cockpit`/step-up; uso ~zero: DB 26 MB/500 MB, MAU 0/50.000). Há **folga para um 2º projeto free** — logo, criar o P3 novo é **grátis**. O reuso não teria ganho de custo algum.

## Decisão

1. **Motor = Supabase Postgres dedicado** (RLS nativa enforced + mascaramento por-campo via view/SECURITY DEFINER + Auth + edge functions).
2. **P3 (Plano de View) = projeto Supabase NOVO**, criado na **org IdeiaOS (Free)** como **2º projeto**, **fisicamente distinto** do `IdeiaOS - Cockpit` (P4/step-up = `xdikjgpkiqzgebcjgqmu`). **Ref do P3 (provisionado 2026-06-30): `ysttvskswqsvtdftjhfn`** — ≠ `xdikjgpkiqzgebcjgqmu` → **P3≠P4 confirmado por ref distinto**. As chaves (`SERVICE_ROLE`/`anon`/DB password) ficam no `.env` local do dono, nunca no contexto do agente.
3. **Regime free** (escolha do dono): cold-start por inatividade aceito (frescor honesto cobre a latência do 1º acesso). Sem custo recorrente esperado p/ 3 máquinas + N devs lendo.
4. **Auth-de-leitura por contas pessoais** (`gustavolpaiva`, `lucas-abreu56`) via GitHub OAuth — **não** a service account `DevIdeiaBusiness` (que R16-03 reservou p/ automação/bot).
5. **Hosting da UI:** decidido na fase de telas (não bloqueia schema/RLS). Default provável: "UI local + data-source remoto".

## Condições INEGOCIÁVEIS (gate de F1)

Sem elas, até o Supabase vira teatro por policy mal-escrita:
1. **`SERVICE_ROLE` nunca no browser** — UI lê só por anon-key sob RLS.
2. **Schema sem coluna `value`** e **sem policy de INSERT/UPDATE para a UI** (só UPSERT por `machine_id` da ingestão autenticada-O2) — replicar no Postgres o guard que `source/agentd/stepup/schema.sql` já enforça.
3. **Teste NEGATIVO de RLS por-campo, por exit-code, contra o backend Supabase REAL deployado** (dev fora do escopo NÃO vê nome de chave `risk_tier=critical` nem cadência de rotação) = gate de release obrigatório, não fixture. RLS-enforced é **necessário**; o teste negativo é o **suficiente**.
4. **P3 fisicamente distinto de P4** — invariante S-04 / R-WP12; mantido pela decisão #2.

## Consequências

- ✅ Split-plane preservado: comprometer o P3 rende, no máximo, metadata + capacidade de mentir-a-view; nunca assinar/pinar/vazar segredo (os 3 ativos vivem em planos LOCAIS; `api_key` sem `value`). A autoridade da frota nunca esteve no cloud.
- ✅ Blast-radius isolado do step-up: um bug de RLS/vazamento de `SERVICE_ROLE` no P3 **não** alcança o projeto da chave de assinatura (P4 separado).
- ✅ Custo zero (2º projeto free na org IdeiaOS).
- ⚠️ Superfície de rede permanente NOVA, metadata-rica (recon: nomes de chave, topologia, cadência) — custo irredutível de ser multi-ator; mitigada por RLS+mascaramento+anon-key+CORS+hosting "UI local". Já catalogada como crítica=3 no security-freshness.
- ⚠️ Regime free/advisory: monitorar bypass de RLS é só logs do Supabase (sem audit-log API). Confirmar se `spec-analyze` + `security-freshness` cobrem os vetos R-WP12 ou se precisa gate de CI extra.

## Runbook do dono (provisionamento — credenciais NUNCA pelo contexto do agente)

1. Supabase → org **IdeiaOS** → **New project** → nome ex. `IdeiaOS - Cockpit View` (ou `ideiaos-cockpit-p3`), região `sa-east-1` (latência BR; o step-up usa `us-west-2` — escolha do dono).
2. Anotar o **ref** do projeto (público, da URL) e registrá-lo neste ADR + no `v16-REQUIREMENTS`. **Não** colar SERVICE_ROLE/anon-key/credencial de ingestão no contexto do agente — o agente referencia por nome.
3. Confirmar que o projeto é **distinto** do `xdikjgpkiqzgebcjgqmu` (step-up).

## Sequência da Frente B após o motor (detalhe em `v16-motor-decision-analysis.md`)

Provisionar P3 → **schema Postgres** (8 tabelas + guard sem `value`, ENABLE+FORCE RLS deny-all) → **mascaramento por-campo** por papel (views/SECURITY DEFINER) → **GATE teste negativo de RLS** por exit-code contra backend real → **admissão por pin O2** (verificação O2 fica 100% no agentd local) → **re-apontar ingest** (SQLite-local → UPSERT por `machine_id`) → **Auth-leitura** por contas pessoais → **read-fan-out/telas** → **consolidar `/spec`** (merge+archive do delta R16-02 implementado) + re-selar security-freshness.

## Rastreabilidade

- Requisito: `.planning/milestones/v16-REQUIREMENTS.md` R16-02 (ref corrigido por este ADR).
- Análise: `.planning/milestones/v16-motor-decision-analysis.md` (workflow `wf_631edb5c-e96`).
- Contrato: `specs/cockpit/spec.md` (R16-02, R-WP12).
- Invariante preservado: `credential-isolation`, S-04 (P3≠P4), RBAC-por-assinatura local.
- Frente A (transporte GitHub) = ADR irmão `v16-r16-03-github-identity-transport.md` (eixo ortogonal).
