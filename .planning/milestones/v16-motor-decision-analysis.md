# v16 — Análise de decisão do MOTOR multi-usuário (Frente B)

**Status:** 🔵 **ANÁLISE PRÉ-DECISÃO** (alimenta a decisão do dono; vira ADR quando decidida). Produzida 2026-06-29 pelo workflow `wf_631edb5c-e96` (4 lentes independentes + síntese, sobre os arquivos reais — Article IV / No-Invention).
**Pergunta:** qual motor multi-usuário satisfaz os SHALL de **R16-02** (RLS deny-all + mascaramento por-campo por papel + admissão por pin O2) para o read-fan-out da Frente B?
**Não confunde com R16-03 (Frente A):** transporte GitHub é eixo ortogonal. Esta é a escolha do **engine do Plano de View (P3)**.

---

## Matriz de decisão (4 opções × 6 eixos)

| Opção | Contrato/RLS | Stack-fit | Segurança/blast | Custo | Tensão local-first | Migração | Veredito |
|-------|-------------|-----------|-----------------|-------|--------------------|----------|----------|
| **1. Supabase Postgres dedicado** (`xdikjgpkiqzgebcjgqmu`) | **FORTE** — único que satisfaz literalmente cada SHALL no engine (RLS deny-all enforced; mascaramento por-campo via view/SECURITY DEFINER; sem coluna `value`; só UPSERT por `machine_id`) | **FORTE** — precedente vivo (step-up P4 já é Supabase/Deno+RLS); produtos já Supabase | **FORTE** com aumento irredutível de superfície (custo de ser multi-ator); blast isolado por projeto separado | JÁ provisionado; free provável, pode cruzar p/ Pro (~US$25/mês) | **RESOLVIDA por design** (autoridade fica local; P3 = cache descartável) | **BAIXO** — só schema, zero migração de dados | ✅ **RECOMENDADO** |
| **4. Outro Postgres gerenciado** (Neon) | VIÁVEL (é Postgres) | FRACO — 2º provedor cloud fragmenta a stack; Auth/anon-key/edge à parte | FRACO — sem ganho de blast + piora credential-isolation (2º fornecedor) | Free generoso, scale-to-zero | Neutro | MÉDIO-ALTO — montar Auth+API+ingestão à mão | 🟡 ALTERNATIVA (dominada) |
| **2. Postgres self-hosted/local** | VIÁVEL no core (RLS é do Postgres) | FRACO — tecnologia operacional NOVA que ninguém opera (container/TLS/backup/CVE) numa org sem SRE | VIÁVEL/transferido — loopback mata o propósito (3 máquinas não alcançam); expor porta = cloud caseiro sem Auth | SW ~zero, OPERAÇÃO alta e mal-distribuída (qual host 24×7?) | Falso ganho | ALTO efetivo — refazer o produto | ❌ DESCARTAR |
| **3. SQLite + autorização na app** (read.js) | **INVIÁVEL — teatro de RLS** (SQLite não tem ROW LEVEL SECURITY; deny na app = allow-by-default) | read.js é loopback-only (single-machine) | INVIÁVEL — bug de autz vaza recon sem rastro; bloqueia o teste negativo por exit-code | Zero (falso-barato: custa o requisito) | Preserva local-first mas NÃO entrega read-fan-out | Nenhuma (ganho ilusório) | ❌ DESCARTAR |

**Convergência das 4 lentes = forte e não-forçada:** todas apontam Opção 1. Divergência só de **grau** (não de direção): Opção 2 é VIÁVEL-pelo-RLS-puro mas FRACA-na-operação; Opção 4 é concorrente só na lente custo. As Opções 2/4 são **dominadas**, não teatro — só a 3 é teatro de RLS.

---

## Recomendação: Opção 1 (Supabase Postgres dedicado `xdikjgpkiqzgebcjgqmu`)

**Por quê, em uma frase por descartada:**
- **Opção 3** falha 3 SHALL de R16-02 (autorização-na-app ≠ RLS-no-engine; anti-padrão [[antitheater-gate-blind-spot-happy-path]] / [[mitigated-label-must-not-outrun-precondition]]).
- **Opção 2** satisfaz o RLS mas **mata o propósito** do read-fan-out (Postgres loopback não alcança as 3 máquinas; expor a porta reconstrói à mão Auth/TLS/anon-key/edge — viola Enforce Simplicity).
- **Opção 4** empata com a 1 só no RLS-puro, mas fragmenta a stack num 2º provedor (pior credential-isolation multi-ator) e troca um motor **já provisionado e nomeado em R16-02** por outro sem ganho (Article IV).
- **Decisiva pró-1:** R16-02 mede "RLS enforced no ENGINE" e **nomeia** `xdikjgpkiqzgebcjgqmu`; o mascaramento por-campo (ponto mais exigente) é nativo do Postgres; o blast de um P3 comprometido é exatamente o teto que o invariante v16 permite (metadata + mentir-a-view; nunca assinar/pinar/vazar segredo — os 3 ativos vivem em planos LOCAIS, `api_key` sem coluna `value` confirmado no schema).

### Condições INEGOCIÁVEIS (viram gate de F1 — sem elas, até o Supabase vira teatro)
1. **SERVICE_ROLE nunca no browser** — UI lê só por anon-key sob RLS.
2. **Schema sem coluna `value`** e **sem policy de INSERT/UPDATE para a UI** (só UPSERT por `machine_id` da ingestão autenticada-O2) — replicar no Postgres o guard que `source/agentd/stepup/schema.sql` já enforça.
3. **Teste NEGATIVO de RLS por-campo** (dev fora do escopo NÃO vê nome de chave `risk_tier=critical` nem cadência de rotação) é **gate de release obrigatório, por exit-code, contra o backend Supabase REAL deployado** — não fixture ([[prove-crypto-against-real-backend-cross-runtime]]). RLS-enforced é **necessário**; o teste negativo é o **suficiente**.
4. **P3 (`xdikjgpkiqzgebcjgqmu`) fisicamente distinto de P4 (step-up)** — R-WP12 / invariante S-04.

---

## Decisões que SÓ o dono toma (antes de provisionar tabelas)

1. **Custo recorrente (token-economy):** teto mensal aceitável para o Plano de View? Free basta p/ 3 máquinas + N devs lendo, ou cruza MAU/egress/compute → Pro (~US$25/mês)? **Declarar o teto antes de provisionar** (provisionar = gastar).
2. **Confirmar `xdikjgpkiqzgebcjgqmu` = P3 (view) e DISTINTO do P4 (step-up `ideiaos-cockpit-stepup`).** Se for o mesmo, R-WP12/S-04 exige um **segundo** projeto Supabase para P3.
3. **Pausa por inatividade:** free pausa projeto ocioso (cold-start na leitura) — aceitável p/ console-de-CTO intermitente, ou quer plano sempre-quente?
4. **Hosting da UI:** web-pública (anon-key no bundle) vs "UI local + data-source remoto" (default mais seguro). Muda a superfície de ataque permanente.
5. **Auth-de-leitura vs R16-03:** a Auth do P3 (GitHub OAuth) deve usar as **contas pessoais** (`gustavolpaiva`, `lucas-abreu56`), **não** a service account `DevIdeiaBusiness` (reservada à automação) — para não reacoplar identidade-humana ao bot.
6. **`user_project_scope`:** onde vive a tabela de escopo dev→projetos (no P3 sob RLS, gerida por admin via UI gated?) e quem aprova escopos, por qual canal out-of-band? (refinar via `/spec` antes do código.)
7. **Credencial de ingestão de menor-privilégio** (não-SERVICE_ROLE, UPSERT por `machine_id`): onde vive e como é escopada por máquina sem virar novo segredo org-wide (mesmo blast que o R16-03 acabou de resolver no GitHub)? Emissão/cola fora do contexto do LLM (`credential-isolation`).
8. **2FA adiado (ADR R16-03):** aceitável que o login na view dependa de conta GitHub pessoal sem 2FA obrigatório, ou a view exige 2º fator próprio?

## Riscos a vigiar
- **RLS mal-escrita** (policy permissiva acidental / mascaramento incompleto) reabre o reconnaissance — risco de IMPLEMENTAÇÃO, não do modelo. Mitigação = o teste negativo por exit-code contra o backend real (condição #3).
- **Regime FREE/advisory** (sem branch protection enforced nem audit-log): monitorar bypass de RLS é só logs do Supabase — confirmar se `spec-analyze` + `security-freshness` (crítica=3) cobrem os vetos R-WP12 deterministicamente ou se precisa gate de CI extra.
- **Superfície de rede permanente nova, metadata-rica** (recon: nomes de chave, topologia, cadência) — custo irredutível de ser multi-ator; mitigada por RLS+mascaramento+anon-key+CORS+hosting "UI local".
- **Confusão P3=P4** reacopla blast-radius (S-04) — manter os 2 projetos distintos é invariante.
- **Frescor cross-máquina vira EVENTUAL** ao mover a view p/ cloud (read.js loopback dá vivo-local instantâneo); a UI DEVE distinguir os 2 regimes (contrato spec linha 53).

---

## Sequência da Frente B DEPOIS da escolha do motor

1. Provisionar/confirmar P3 (`xdikjgpkiqzgebcjgqmu`) **distinto** do P4; dono emite SERVICE_ROLE + credencial de ingestão de menor-privilégio **fora do contexto do LLM**.
2. **Schema Postgres:** portar as 8 tabelas como DDL, guard "`api_key` sem coluna `value`" replicado; `ENABLE`+`FORCE ROW LEVEL SECURITY` em todas, deny-all por default.
3. **RLS deny-all + mascaramento por-campo** por papel via views/SECURITY DEFINER (admin vê tudo; dev vê só `user_project_scope`, com `risk_tier=critical` e cadência mascarados fora do escopo). Sem INSERT/UPDATE p/ a UI; só UPSERT por `machine_id`.
4. **GATE — teste NEGATIVO de RLS** por exit-code contra o Supabase REAL deployado. Bloqueia F1 se falhar.
5. **Admissão de estação por pin O2** + escopo default-deny (verificação O2 fica 100% no agentd LOCAL; P3 nunca verifica O2 — incapacidade estrutural).
6. **Re-apontar o ingest:** destino SQLite-local → UPSERT por `machine_id` no P3 via credencial de menor-privilégio; agentd permanece local e metadata-only (Zero-Leak).
7. **Auth-de-leitura:** Supabase Auth via GitHub OAuth com **contas pessoais**; UI lê por anon-key sob RLS resolvendo role/`user_project_scope`.
8. **Read-fan-out / telas:** as views p/ N devs em 3 máquinas; UI distingue frescor vivo-local (read.js) de cross-máquina eventual (P3).
9. **Consolidar contrato:** `/spec` merge+archive do delta R16-02 implementado; registrar custo real + re-selar security-freshness (`@security-reviewer` no diff).
