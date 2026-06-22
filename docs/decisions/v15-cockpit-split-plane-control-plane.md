# ADR — v15: Cockpit split-plane (autoridade local + Plano de View web), sucede o local-first/git-as-bus

**Status:** **PROPOSTO (DRAFT — saída de spike, NÃO ratificado pelo operador).** Recomendação de síntese de um painel de 4 propostas + 3 julgamentos (arquitetura, segurança, operabilidade). Reversível por edição. **Ratificar NÃO abre o gate R-WP10** nem cria tabela alguma — este ADR é *pure design*.
**Sucede:** `docs/decisions/v14-cockpit-local-first-git-as-bus.md` no eixo de **leitura/federação**; **preserva-o intacto** no eixo de autoridade/segredo/write-path.
**Design completo:** `docs/ideiaos-console/80-split-plane-control-plane-DESIGN.md`.
**Não revoga:** O2 (`v14.4-origin-auth-signing-mechanism.md`), step-up HYBRID (`v14.4-step-up-without-relying-party.md`), Q5 (`v14.4-command-ref-origin-exposure.md`), R-WP1..R-WP11 (`specs/cockpit/spec.md`).
**Proveniência:** nativo IdeiaOS — colhe o "Caminho C híbrido" parqueado em `20-architecture.md` §2.1.

## Contexto

O Cockpit nasceu **local-first, zero backend, git-as-bus por ref** para "audiência de 1 operador" (ADR-pai, linha 34/46). Agora expande para **multi-usuário / multi-máquina / multi-projeto**. O operador pergunta: (1) por que local-first/zero-backend — ou por que NÃO mais; (2) uma versão WEB mitiga os problemas de atualização/sync.

Existe um **projeto Supabase DEDICADO** já provisionado e isolado (org própria, ref `xdikjgpkiqzgebcjgqmu`, "IdeiaOS - Cockpit") — candidato a plano de leitura web. Nenhuma tabela criada; este spike é PURE DESIGN.

A tensão de fundo é a mesma do ADR-pai: um console multi-ator que centraliza visão é a maior superfície de ataque imaginável. A regra-piso `credential-isolation` permanece: o **valor** de um segredo nunca transita pelo contexto do LLM/browser/control-plane.

## Princípio (a convicção, em uma linha)

> O Cockpit não precisa ser local-first em TUDO; precisa que a **AUTORIDADE** (assinar O2, verificar contra o pin, mutar a lista pinada, possuir segredo) seja **local e intocada** — e a **VIEW** (leitura de metadata + identidade de quem-olha) pode ser **remota**.

O cloud é um quadro-de-avisos compartilhado de **metadata** + (no futuro, gated) um roteador de envelopes **lacrados**: quem assina e quem abre os envelopes nunca está no cloud.

## O que muda da premissa "audiência de 1 operador"

O ADR-pai rejeitou backend por DOIS motivos. Este ADR os separa:

- **(a) "custódia central de credenciais (anátema à `credential-isolation`)"** — **HONRADO integralmente.** O Plano de View é metadata-only, zero SERVICE_ROLE de produto no caminho de leitura, zero segredo, zero capacidade de assinar. Multi-ator **agrava** esta regra (mais alvos), não a revoga.
- **(b) "backend pesado para audiência de 1 operador"** — **EXPIRA.** Multi-usuário/máquina/projeto é o requisito agora. A premissa (b) era contingente à audiência; (a) é regra-piso permanente.

O precedente já é load-bearing: o ADR de step-up HYBRID **já** reintroduziu um Supabase dedicado (sensor de presença, blast-radius = "forjar aprovações, não vazar dados") e o operador aceitou. Este ADR generaliza esse mesmo padrão (backend só no plano que não custodia segredo nem assina) ao read-fan-out + auth-de-leitura — e colhe o "Caminho C" que `20-architecture.md` §2.1 parqueou como "evolução natural se/quando surgir necessidade de acesso fora-da-máquina".

## Decisão (proposta)

| Eixo | Decisão | Razão |
|------|---------|-------|
| **Topologia** | **Split-plane:** autoridade LOCAL (P1 agentd) + git-as-bus (P2) como espinha de transporte durável + **Plano de View remoto** (P3 Supabase dedicado, read-fan-out + auth-de-leitura). | a AUTORIDADE não se move; só a VIEW vira remota — menor desvio que satisfaz multi-ator |
| **P3 = read-fan-out, NÃO control plane** | P3 projeta metadata-only do que o ingest já produz; UI lê via anon-key + RLS deny-all. P3 **não** assina, **não** verifica comando, **não** pina, **não** segura segredo. | difere do "Caminho B" (SaaS hub) rejeitado: lá o agente dava POST com SERVICE_ROLE; aqui a função de ingestão é autenticada-O2 e a UI lê por anon-key |
| **Bus git PRESERVADO como espinha** | o ref `cockpit` permanece source-of-truth do transporte e fonte da reconstrução de P3 (P3 = cache descartável). NÃO rebaixado a "espelho opcional". | preserva fallback frio + reforça R-WP9 a custo ~zero + reversibilidade total (remover P3 volta ao git-as-bus puro) |
| **Frescura por push direto** | o agentd faz push direto a P3 (função autenticada-O2) **em paralelo** ao ref → leitura em segundos; o ref segue como redundância (~15min). | cura a face de latência da dor de sync sem tirar o ref do caminho |
| **Auth multi-usuário (read)** | Supabase Auth em P3 (GitHub OAuth org `DevIdeiaBusiness`) + RBAC-de-leitura (cto/dev, escopo por projeto). | resolve o gap de identidade (`30-security` §5.3); RBAC-de-AÇÃO continua re-provado no alvo pela assinatura+pin |
| **Step-up P4 = projeto SEPARADO** | `ideiaos-cockpit-stepup` (P4) permanece distinto de `xdikjgpkiqzgebcjgqmu` (P3). | misturar reacopla blast-radius (S-04). É o **primeiro tijolo** a executar (bootstrap B3-HYBRID) |
| **Comando = LOCAL, gated** | o write-path inteiro fica no plano de autoridade local; P3 fica FORA dele. Mailbox de comando por terceiro é **Fase 2**, gated por R-WP10 + Q5. | nenhum R-WP regride; P3 read-only não abre o gate |
| **Faseamento + SOAK** | Fase 1 = read-fan-out puro (advisory por um ciclo, comparando view↔read.js local); Fase 2 = mailbox só após Q5 em ADR. | entrega ~80% do valor (dor de leitura) com blast-radius mínimo |
| **R-WP12 (novo, proposto)** | "O Plano de View é read-only metadata, nunca autoridade; divergência view↔disco é **alerta**, nunca atualização da fonte." | crava a fronteira no contrato vivo, dando ao `spec-analyze`/`security-freshness` algo determinístico para checar |

## Alternativas consideradas (e por que não)

- **Manter o local-first absoluto (status quo do ADR-pai)** — rejeitada para multi-ator: a SPA loopback-only não dá acesso de fora nem identidade de quem-olha. Resolve "não vejo de fora", mas não move a latência se a view for populada só a partir do ref (~15min). É a opção mais fraca em *resolver a dor*.
- **Split-plane zero-trust PLENO (control plane completo: read-model federado + command_envelopes transacional + RBAC + Realtime + 2 backends + loop de pull/ACK no cloud)** — rejeitada como ponto-de-chegada para a audiência atual (1 cto + poucos devs): **super-construção** (capacidade à frente da necessidade), maior custo de migração (rebaixa o git-as-bus, perde fallback), e maximiza o vetor de "drift de doutrina" (pressão para mover segredo/assinatura para o cloud) exatamente onde a opção vencedora o minimiza. **Sua Fase 1 É, na prática, esta decisão**; a Fase 2 (roteamento via cloud) é o que adiciona custo sem ganho proporcional hoje — registrada como o caminho de evolução §9 do design, gated.
- **Cloud (Supabase) como hub de telemetria com POST de SERVICE_ROLE (Caminho B do `20-architecture` §2.1)** — rejeitada (permanece): custódia central de credencial é o anti-padrão exato de `credential-isolation`. O Plano de View deste ADR difere por construção (ingestão autenticada-O2 + Zero-Leak; UI lê por anon-key, sem SERVICE_ROLE no caminho de leitura).
- **Rebaixar o git-as-bus a "espelho de auditoria opcional"** — rejeitada: descarta a espinha provada + o fallback frio sem que a dor (ver-de-fora + identidade) o exija; aumenta a irreversibilidade da migração.

## Consequências

**Positivas:**
- Cura a dor de sync de LEITURA (acessibilidade de fora + identidade multi-ator + latência em segundos) — a dor que o operador sente.
- Aditivo e reversível: remover P3 volta ao git-as-bus puro sem perda (P3 é cache descartável reconstruível do ref).
- Reusa praticamente tudo: O2 (19/19 proof-gates), `zeroleak-snapshot.sh`, `collect.js`, read-model/ingest, SPA, projeto step-up. Novo crítico = 1 função de ingestão autenticada-O2 + schema read-fan-out + auth/RBAC-de-leitura.
- Invariante zero-trust satisfeito por construção: os três ativos que dariam controle total (chave O2, lista pinada, valor de segredo) vivem TODOS em planos locais distintos, nenhum no cloud. Comprometer P3 rende metadata + capacidade de mentir a view — o teto que o invariante permite.

**Aceitas (trade-offs — `operating-discipline` §6):**
- **Nova superfície de rede permanente:** P3 é metadata-rica e acessível pela web — reconnaissance valioso mesmo sem segredo (nomes de chave, topologia, cadência). Mitigado: RLS deny-all + escopo RBAC, anon-key (nunca SERVICE_ROLE no browser), CORS pinado; entra no `security-freshness` como **crítica=3**.
- **Latência self-reported:** a view só fica fresca quando alguma máquina empurrou; a máquina remota não fica "ao-vivo". A UI exibe frescor honesto ("verificado há Xs"), nunca anima fluxo contínuo sobre lote.
- **Não resolve comando concorrente cross-máquina** (estado-compartilhado de escrita) nem sync de segredo — limites estruturais preservados conscientemente; o primeiro é vaporware até o 2º ator, o segundo é trabalho do write-path (R-WP5).
- **Risco de drift de doutrina:** pressão de produto para "deixar P3 mais esperto" empurraria segredo/assinatura para o cloud. Mitigado por **vetos-de-design auditáveis** (§8 do design): P3 segura segredo? assina? pina? abre verbo? — qualquer SIM é veto.

**Irreversível-ish:** "existe agora um backend remoto que reflete metadata do ecossistema" é uma superfície de ataque permanente nova — daí este ADR. Mitigado por ser metadata-only + sem autoridade + faseável (Fase 1 reversível). A Fase 2 (mailbox de comando por terceiro) é genuinamente mais irreversível e fica gated por Q5 + R-WP10.

## Rastreabilidade

- Design: `docs/ideiaos-console/80-split-plane-control-plane-DESIGN.md`.
- Contrato vivo: `specs/cockpit/spec.md` (R-WP1..R-WP11 preservados; propõe R-WP12).
- Preserva: `v14.4-origin-auth-signing-mechanism.md` (O2), `v14.4-step-up-without-relying-party.md` (step-up HYBRID), `v14.4-command-ref-origin-exposure.md` (Q5 — princípio topology-independent que já carrega para o v15).
- ADR-pai sucedido (eixo leitura): `v14-cockpit-local-first-git-as-bus.md`.
- Cross-link: `credential-isolation`, `agent-authority`, `security-freshness`, `antifragile-gates`, `mcp-hygiene`, `delta-spec`, `ubiquitous-language`.
