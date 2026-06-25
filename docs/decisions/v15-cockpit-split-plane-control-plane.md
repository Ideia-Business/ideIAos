# ADR — v15: Cockpit split-plane → PLATAFORMA DE TIME controlada (autoridade local + Plano de View web), sucede o local-first/git-as-bus

> ⚠️ **RENUMERADO PARA MILESTONE v16 (2026-06-25).** Este design (antes rotulado "v15") é agora o **milestone v16 — Plataforma de Time**. O número **v15 foi reatribuído** ao milestone "DX & Frota" (instalação + gerência + consolidação do Cockpit), que **shipa primeiro** (número = ordem de ship, convenção v2→v14). O **conteúdo de design abaixo permanece válido** — só o número do milestone mudou. Requisitos formalizados em `.planning/milestones/v16-REQUIREMENTS.md`. O nome deste arquivo foi preservado para não quebrar cross-references. (Decisão do dono via análise estratégica `wf_d2ae9a6d-235`.)

**Status:** **PROPOSTO (DRAFT — re-escopado 2026-06-22 para plataforma de time multi-dev; NÃO ratificado).** Síntese de painel (4 propostas + 3 julgamentos) + re-escopo multi-dev fundamentado no deploy real dos 4 repos. **`@security-reviewer` = NEEDS_REVISION** em dois níveis: o read-fan-out (4 must-fix originais) **e** a plataforma de time (4 BLOCKERS novos, que convergem num calcanhar estrutural — a conta GitHub compartilhada; ver "Pendências de segurança da plataforma de time"). Reversível por edição. **Ratificar NÃO abre o gate R-WP10** nem cria tabela — *pure design*. **Design completo:** `docs/ideiaos-console/81-team-platform-control-DESIGN.md` + coordenação `82-team-coordination-onboarding-requirements.md`. **Review adversarial de design `wf_8432e800-818` (2026-06-22, 5 lentes + refutação de HIGHs):** rótulos dos BLOCKERS revisados (atribuição → MITIGADO-PARCIAL/DESLOCADO; reversão → BLOCKER-CONDICIONAL após probe `gh`; step-up-loopback → defesa-em-profundidade, tese "única barreira" refutada); contradições de doc reconciliadas em 81; cortes de MVP aplicados; mini-ADR do comprovante (`v14.4-stepup-comprovante-key-scheme.md`) criado como pré-req de F0.
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

## Pendências de segurança (NEEDS_REVISION — bloqueiam ratificação)

Varredura adversarial do **`@security-reviewer`**: invariante zero-trust **SUSTENTA-SE**, write-path **preservado**, **zero** violações de `credential-isolation`. Veredito **NEEDS_REVISION** — 4 must-fix antes de ratificar, com a direção de resolução já apontada pelo painel:

1. **[ALTO] Mecanismo de ingestão de P3 não-especificado.** Como uma Edge Function Supabase "autenticada-O2" verifica a assinatura sem ter a lista pinada (local-0600; replicá-la no cloud **viola a FRONTEIRA-DE-PIN**)? → **Resolução: P3 NUNCA verifica O2.** A verificação O2 fica 100% local (agentd, antes do push). A ingestão = o agentd escreve com uma **credencial Supabase de menor-privilégio própria** (NÃO `SERVICE_ROLE`), com RLS que só permite UPSERT da **própria `machine_id`**. A fronteira-de-pin nunca vai ao cloud.
2. **[ALTO] RLS por-campo + "acessível de fora" vs "CORS só-loopback".** Sem granularidade por campo, um `dev` (ou `cto` com sessão web roubada) lê nomes de chave `critical`, topologia e cadência — o recon mais valioso. → **Resolução: (i)** hosting default = UI servida local com data-source remoto (mitiga anon-key no bundle público); **(ii)** RLS **mascara campos sensíveis de recon** por papel (nomes `risk_tier=critical` agregados/mascarados fora do escopo do subject; cadência de rotação não-exposta a `dev`) — não basta deny-all + escopo binário. **Ressalva honesta:** ir web-acessível **troca** a propriedade de mínimo-recon que o loopback dava (perda consciente, não-total: não vaza segredo nem forja comando).
3. **[MÉDIO] R-WP12 como prosa é fraco demais.** Um PR futuro com coluna `value` ou policy de INSERT-da-UI passaria por "ainda é metadata". → **Resolução: R-WP12 vira cláusulas SHALL enumeradas e verificáveis** (sem coluna de valor; não assina; não muta a lista pinada [`process-supabase-revocation` = exit 9, espelhando `process-ref-*`]; sem policy de INSERT/UPDATE para a UI; P3 ≠ P4 projetos distintos), cada uma um cenário QUANDO/ENTÃO no `/spec`.
4. **[MÉDIO] Step-up (S-08 CORS-loopback) vs UI servida de P3.** A UI que dispara `send-otp` não pode ser a remota se P4 exige CORS-loopback. → **Resolução:** o step-up (`send-otp`/`verify-otp`) só é disparado da **UI LOCAL (loopback)** e o O2-sign acontece na **origem-local**; a UI remota P3 é **read-only** e NUNCA inicia write-path. S-08 fica intacto. (Reconciliado com o hosting default da #2.)

> Estas 4 resoluções são aplicadas ao texto da Decisão **quando o operador ratificar a direção** (ou no início da construção de P3/Fase 1, o que vier primeiro). P4 (step-up, o primeiro tijolo) **não** depende delas.

## Pendências de segurança da PLATAFORMA DE TIME (re-escopo 2026-06-22 — NEEDS_REVISION)

`@security-reviewer` sobre o re-escopo multi-dev (design `81-...`, coordenação `82-...`): invariante zero-trust **sustenta-se**, **zero** violação direta de credential-isolation no caminho-feliz (P3 `provider_link` sem coluna `value`; OAuth roda local e deposita no keychain). MAS o re-escopo converge num **calcanhar estrutural** + 4 BLOCKERS.

### ⚠️ DECISÃO CRÍTICA — conta GitHub COMPARTILHADA vs. contas PESSOAIS por dev
A conta GitHub compartilhada (`desenvolvimento@ideiabusiness`) **quebra 2 das 5 alavancas de controle** que o operador mais quer:
- **Visão/atribuição (Pilar A) fica FORJÁVEL** — `git -c user.email=outro@ideiabusiness commit` falsifica autoria; o O2 assina *comandos*, não *commits* (commit-signing foi rejeitado no ADR O2); sem branch protection (403 *Upgrade to Pro* nos 4 repos), nada enforça.
- **Reversão fica FURADA** — revogar uma estação (re-pin local) **não** revoga o token OAuth compartilhado no keychain do dev revogado; ele mantém push/PR/workflow na org até a **rotação global** do token (que afeta TODOS).
- **Blast-radius org-wide** — 1 token (`repo`+`workflow`+`read:org`) idêntico em N keychains → comprometer **qualquer** estação = push em **toda** a org, inclusive projetos **fora** do escopo de Autorização daquele dev.

**DECIDIDO (2026-06-22) — MANTER a conta compartilhada (decisão operacional firme); mitigação CONDICIONADA a uma pré-condição de org ainda NÃO satisfeita.** O operador escolheu a simplicidade operacional (a conta já funciona; Lovable/CI a usam). O caminho para que "manter compartilhada" **não** custe o controle é separar "conta compartilhada" de "token compartilhado" via **token POR-ESTAÇÃO (fine-grained PAT)** — MAS o review adversarial (`wf_8432e800-818`) + probe `gh` (abaixo) mostraram que essa mitigação ainda **não está em vigor** e depende de ação do owner. Honestidade primeiro (`operating-discipline` §3/§6): a decisão de conta-compartilhada vale; o **rótulo [MITIGADO]** dos blockers de atribuição/reversão era **prematuro** e foi rebaixado.

- **Token POR-ESTAÇÃO (fine-grained PAT), não token único — ALVO, ainda não realizado.** A conta compartilhada **emitiria N fine-grained PATs distintos** — um por estação —, cada um **escopado aos repos autorizados daquele dev** e com expiração. Cada estação guardaria o SEU PAT no keychain (Pilar B; o cockpit guarda só o binding `{pat_id, machine_id, repos}`, **nunca** o valor). *"Conta compartilhada" ≠ "token compartilhado".*
  - **Reversão SERIA EFETIVA e isolada** (revogar a estação = revogar aquele PAT, sem rotação global) — **somente** sob a pré-condição abaixo.
  - **Blast-radius SERIA ISOLADO** (uma estação expõe só o PAT dela) — **somente** sob a pré-condição abaixo.
- **Atribuição por telemetria assinada-O2 da estação** (não-repúdio da TELEMETRIA, não do PUSH — ver BLOCKER #1 rebaixado); o git author email é **hint cosmético** (forjável, declarado).
- **Detecção de anomalia** de push (estação revogada / PAT fora de escopo) + declaração honesta dos residuais.

**⚠️ Estado verificado por probe `gh` (2026-06-22) — a pré-condição NÃO está satisfeita hoje:**
- Os 4 repos são da **org `Ideia-Business` (plano FREE, 75 repos privados)** — repos org-owned, NÃO conta pessoal.
- O credencial em uso AGORA é o **token OAuth clássico** da conta `DevIdeiaBusiness`, escopado `repo, workflow, read:org` → **org-wide por construção** (exatamente o modelo que colapsa Reversão/blast-radius).
- O endpoint owner-level de gestão de fine-grained PAT da org retorna **404** → gestão centralizada de FG-PAT **não provisionada**. Em org FREE, a política de *restrição/aprovação* de FG-PAT pode exigir plano pago (a confirmar pelo owner no Settings da org).
- **Conclusão:** enquanto a org não habilitar+emitir FG-PATs escopados por-estação, o blast-radius **permanece org-wide** e a Reversão **não é isolada**. A escolha "manter conta compartilhada" segue válida operacionalmente, mas seu **custo de segurança real** (org-wide) só baixa ao status "isolado" depois da ação do owner.

**Residuais honestos:** (i) o git COMMIT author segue forjável (atribuição autoritativa = telemetria assinada, não o commit); (ii) **[PRÉ-CONDIÇÃO NÃO SATISFEITA — probe acima]** a org precisa **habilitar e emitir fine-grained PATs** escopados por-estação (ação do owner; possivelmente plano pago p/ política de restrição); (iii) no audit-log do GitHub o *actor* é a conta compartilhada (a distinção fina é cockpit-side, via `pat_id`+telemetria); (iv) a Reversão é uma **dupla-teardown** (re-pin local O2 **+** revoke-PAT no GitHub) — ver BLOCKER #2; (v) janela working-copy: dev revogado com PAT já no keychain + repo já clonado mantém push até o revoke propagar (a revogação-de-PAT não é instantânea nem puramente local, ao contrário do re-pin O2).

### BLOCKERS (rótulos revisados pelo review adversarial `wf_8432e800-818` — refutação por achado)
1. **[MITIGADO-PARCIAL / DESLOCADO] Atribuição forjável.** A telemetria assinada-O2 é não-repúdio da **TELEMETRIA** ("a estação X assinou esta afirmação com a chave pinada"), **não** da **AÇÃO no GitHub** (o push em si não é assinado — commit-signing foi rejeitado no ADR O2; o audit-log do GitHub só vê a conta compartilhada). Uma estação comprometida (residual Q2 ACEITO) pode assinar telemetria falsa **ou omitir** um push. O proof-gate "rejeita atribuição não-assinada" só prova que ESTÁ assinada, não que CASA com o que ocorreu. → **Não fechar como [MITIGADO]; adicionar cross-check telemetria↔audit-log** (importar `gh api` audit-log read-only e ALERTAR na divergência — espelha "divergência view↔disco = alerta"). Detective, aditivo, F2/F5; não bloqueia F0.
2. **[BLOCKER-CONDICIONAL] Reversão incompleta no GitHub.** O token-por-estação (FG-PAT) tornaria a revogação isolada **somente** se a org habilitar+emitir FG-PATs (probe acima: **NÃO satisfeito** — org FREE, token clássico org-wide em uso, endpoint FG-PAT 404). **Bloqueia F1** até prova por exit-code de que (a) um FG-PAT escopado a `{nfideia,cfoai}` foi emitido E (b) **NÃO** consegue push em `{ideiapartner,lapidai}` (teste negativo real). Além disso, a Reversão é **dupla-teardown** (re-pin local O2 **+** revoke-PAT GitHub) que DEVEM ambos disparar — a doutrina "revogação local out-of-band" cobre o re-pin O2; revogar o PAT via API do emissor é o eixo ortogonal de **posse-de-credencial** (legítimo), mas reintroduz dependência de disponibilidade do GitHub + janela working-copy (residuais iv/v). Se a org não habilitar FG-PAT, **re-ratificar a decisão com o trade-off real (org-wide) exposto** — a opção contas-pessoais re-abre como alternativa honesta.
3. **[BLOCKER] RLS por-campo ainda em prosa** (agora ×N devs) → cláusulas SHALL + **teste NEGATIVO** de RLS por-campo (um SELECT do dev fora do escopo NÃO retorna nomes `risk_tier=critical` nem cadência de rotação — mascaramento por papel exige view/security-definer, não deny-all binário). Bloqueia F1.
4. **[DEFESA-EM-PROFUNDIDADE + nota de coerência] Step-up só-loopback** (era [BLOCKER]; **rebaixado** — a tese "ÚNICA barreira" foi REFUTADA). A escalada "sessão admin web roubada → deploy/rotate" é barrada por **duas barreiras independentes e estruturais** que a sessão remota NÃO satisfaz: (a) **O2-sign é local** (chave privada no keychain P0/P1, nunca no DOM) e o `verify-payload.sh` fail-closed contra o pin local já é exit-code-gated (19/19); (b) **O4 out-of-band SEMPRE** no crítico/deploy (matriz tier×fator). O CORS-loopback (S-08) é **defesa-em-profundidade**, não o gate único — e já é a **condição #7 das 8** do bootstrap step-up (verificada por exit-code em F0). **Ação:** (i) resolver a incoerência documental — BLOCKER #4 = condição #7 (mesmo requisito); (ii) materializar como teste concreto no F0: `send-otp`/`verify-otp` RECUSAM (exit≠0) Origin/Host ≠ loopback, testado por **preflight CORS real no browser** (curl não faz preflight — learning `curl-masks-cors-preflight`).
5. **[HARDENING — novo, do review] Vetor DNS-rebinding / CSRF-contra-loopback** (não-nomeado antes). O caminho-feliz de "deploy induzido por link remoto" está **fechado** por O4 + binding `payload_hash` (o dev vê o ALVO que aprova) + token-por-boot; MAS o vetor não estava nomeado. → Nomear em `81-...DESIGN.md` §10; elevar a proof-gate por exit-code: (a) servidor loopback do agentd valida `Host` literal == 127.0.0.1/localhost (anti-rebinding); (b) toda entrada do write-path gated amarrada ao token-por-boot + arming-nonce que a UI remota P3 não conhece.

(+ warns: cerimônia de enrollment remoto resistente a MITM ×N devs — vincular o fingerprint à sessão web AUTENTICADA do dev, não a um código digitado no Slack; proof-gate do Pilar B [OAuth-local não vaza valor a P3, reusando `zeroleak-snapshot.sh` + gate do env do processo-filho efêmero]; `provider_link`/PAT-binding sem coluna `value` como cláusula determinística no gate; fila de Publish é advisory sobre `main` não-protegida — considerar hard-gate LOCAL no agentd p/ `supabase db push`/`functions deploy` sem claim ativo.)

### Faseamento (design 81)
F0 step-up (P4, **primeiro tijolo, não bloqueado**) → F1 view+admissão+autorização (gated pelos 4 must-fix do read-fan-out + os 4 BLOCKERS) → F2 pilares/enrollment → F3 coordenação/claims (R-COORD3/4/5) → F4 reserva-de-poder/fila-de-Publish gated → F5 Visão→Vault + DEV Tasks (futuro).

## Rastreabilidade

- Design: `docs/ideiaos-console/80-split-plane-control-plane-DESIGN.md`.
- Contrato vivo: `specs/cockpit/spec.md` (R-WP1..R-WP11 preservados; propõe R-WP12).
- Preserva: `v14.4-origin-auth-signing-mechanism.md` (O2), `v14.4-step-up-without-relying-party.md` (step-up HYBRID), `v14.4-stepup-comprovante-key-scheme.md` (esquema de chave do comprovante — pré-req de F0), `v14.4-command-ref-origin-exposure.md` (Q5 — princípio topology-independent que já carrega para o v15).
- ADR-pai sucedido (eixo leitura): `v14-cockpit-local-first-git-as-bus.md`.
- Cross-link: `credential-isolation`, `agent-authority`, `security-freshness`, `antifragile-gates`, `mcp-hygiene`, `delta-spec`, `ubiquitous-language`.
