# 80 — Split-Plane Control Plane (Cockpit web multi-ator)

> **Documento:** `80-split-plane-control-plane-DESIGN.md`
> **Persona:** Arquiteto-chefe (síntese de spike — painel de 4 propostas + 3 julgamentos)
> **Status:** PROPOSTO (saída de spike — design completo, NÃO ratificado pelo operador)
> **Data:** 2026-06-22
> **Sucede o design de:** `20-architecture.md` (local-first, git-as-bus, zero backend) no eixo de **leitura/federação**; preserva-o intacto no eixo de **autoridade/segredo/write-path**.
> **ADR-sucessor:** `docs/decisions/v15-cockpit-split-plane-control-plane.md` (DRAFT).
> **Princípio-guia:** `enforce-simplicity` + invariante zero-trust — o menor plano novo que cura a dor de sync sem mover NENHUMA decisão de enforcement para fora do agentd local.

---

## 0. As duas perguntas do operador, respondidas com convicção

### Pergunta 1 — "Por que o Cockpit precisa ser local-first/zero-backend — ou por que NÃO mais?"

**A convicção mudou de "tudo é local" para "a AUTORIDADE é local; a VIEW pode ser remota".** Isto não é recuo do `credential-isolation` — é a sua aplicação precisa.

O ADR-pai (`v14-cockpit-local-first-git-as-bus.md`, linhas 44–46) rejeitou backend por **DOIS** motivos:

- **(a)** "exigiria custódia central de credenciais (anátema à `credential-isolation`)" — esta razão **NÃO morre**. É regra-piso permanente. Vale para 1 ou 100 operadores; multi-ator **agrava-a** (mais alvos), não a revoga.
- **(b)** "backend pesado para uma audiência de 1 operador" — esta razão **EXPIRA**. A audiência-de-1 é exatamente a premissa que este spike derruba: o Cockpit expande para multi-usuário / multi-máquina / multi-projeto.

A prova de que dá para ter backend **honrando (a)** já existe na própria casa: o ADR de step-up HYBRID (`v14.4-step-up-without-relying-party.md`) **já reintroduziu** um Supabase dedicado (`ideiaos-cockpit-stepup`) cujo blast-radius é "forjar aprovações, **não** vazar dados de produto" — e o operador aceitou. O `20-architecture.md` §2.1 também já **parqueou** o "Caminho C híbrido" como "evolução natural se/quando surgir necessidade de acesso fora-da-máquina". Multi-ator é exatamente esse gatilho.

**Convicção em uma frase:** o Cockpit não precisa ser local-first em TUDO; precisa que a **AUTORIDADE** (assinar O2, verificar contra o pin, mutar a lista pinada, possuir segredo) seja local — e essa parte permanece **byte-a-byte intocada**. O que o local-first nunca deu, e multi-ator exige, é uma **superfície de leitura acessível de fora da máquina** + **identidade de quem-é-quem**. Isso é resolvível sem mover a autoridade.

### Pergunta 2 — "Uma versão WEB mitiga os problemas de ATUALIZAÇÃO/sync entre projetos/usuários/máquinas?"

**SIM — a dor de sync que o operador SENTE é a de LEITURA, e a versão web a cura.** Mas a resposta honesta tem três faces (`operating-discipline` §3 — push-back quando couber):

1. **Acessibilidade (a dor real):** hoje a SPA é loopback-only (`read.js` em `127.0.0.1`). Para ver o estado do ecossistema de outra máquina/usuário você precisa estar NA máquina com o ref puxado. A versão web dá uma **URL** que qualquer ator autenticado abre de qualquer lugar — fim do "tenho que estar no terminal certo". **Resolvido.**
2. **Latência de propagação:** o git-as-bus por ref propaga em ~15min (1 ciclo de autosync). Um **read-fan-out** com push direto do agentd para o plano de view (notificação "algo-mudou" + Realtime/polling) reduz a leitura para **segundos**. **Resolvido — com a ressalva de que continua *self-reported*** (a view só fica fresca quando alguma máquina empurrou; a máquina remota não fica "ao-vivo", só a *última leitura empurrada* fica acessível de fora).
3. **Identidade multi-ator:** o local-first não tinha "quem é o dev vs o cto" (`30-security` §5.3, gap de identidade). Auth no plano de view resolve, habilitando RBAC-de-leitura. **Resolvido.**

**O que a versão web NÃO resolve (limites estruturais preservados conscientemente):**

- **Comando concorrente cross-máquina** (estado-compartilhado de ESCRITA) — uma view read-only não resolve a corrida que o `74-resilience` §4.3 admite que o union-merge não escala. Isto fica no write-path existente, gated por R-WP10. **Não é dor sentida ainda** (vaporware até o 2º ator real, por ADR-pai). A justificativa técnica de QUANDO evoluir (fila transacional com ACK) está documentada na §9, mas **não se constrói agora**.
- **Sync de SEGREDO** (rotacionei em A, B tem valor velho) — é endereçado pelo **write-path** (rotate gera o valor no alvo, R-WP5), não pela view. A view só reflete *que* rotacionou.

---

## 1. Glossário (linguagem ubíqua — `CONTEXT.md`)

| Termo canônico | Definição | _Evite_ |
|----------------|-----------|---------|
| **Plano de Autoridade Local** | O `ideiaos-agentd` por máquina + keychain + lista pinada. Único que assina O2, verifica comando, pina chave, possui segredo. | "backend de comando", "servidor" |
| **Plano de Bus Git** | Ref órfão `cockpit` (+ ref de comando dedicado). Transporte de federação durável, source-of-truth do transporte. | "fila", "broker" |
| **Plano de View** | Projeto Supabase dedicado `xdikjgpkiqzgebcjgqmu`. Read-fan-out de metadata + auth/RBAC-de-leitura. NÃO é control plane de comando. | "control plane", "hub de telemetria" |
| **Plano de Step-up** | Projeto Supabase dedicado `ideiaos-cockpit-stepup` (já decidido). Sensor de presença-humana na origem (email-OTP). | "auth", "login" |
| **read-fan-out** | Projeção read-only de metadata, populada por push do agentd, servida por RLS+Realtime/polling. Cache descartável reconstruível do ref. | "read-model autoritativo" |
| **espelho não-confiável** | Cópia de leitura cujo conteúdo divergente do disco/ref = **alerta**, nunca atualização da fonte (doutrina do ADR O2 estendida ao Supabase). | "fonte-de-verdade replicada" |
| **veto-de-design** | Gate de revisão: "o plano de view segura segredo? assina? pina? abre verbo?" — qualquer SIM reprova (espelha `30-security` §10). | — |

---

## 2. Os planos (a topologia)

Quatro planos. Os **três ativos que, juntos, dariam controle total** — chave de assinar O2, lista pinada autoritativa, valor de segredo — vivem TODOS em planos **locais distintos**, **nenhum** no cloud. Esse é o teorema do invariante zero-trust.

| Plano | Responsabilidade | Segura segredo? | Nível de confiança |
|-------|------------------|:---------------:|--------------------|
| **P0 — Substrato local** | Disco vivo: ledgers, `.env` (nomes), git log, launchctl, keychain. Fonte-de-verdade. | **sim** (valor de segredo só aqui + keychain) | CONFIÁVEL-ISOLADO |
| **P1 — Plano de Autoridade Local** (`ideiaos-agentd`) | Coleta read-only; **assina** O2 (`sign-payload.sh`); **verifica** comando contra o pin local (`verify-payload.sh`, fail-closed); **pina** (`pinned-keys.sh`); executa allowlist; resolve segredo na borda e descarta (R-WP6); grava ledger hash-chained. Faz o step-up na origem. | **sim** (chave privada O2 + posse de segredo na borda) | CONFIÁVEL-ISOLADO — raiz de confiança |
| **P2 — Plano de Bus Git** (ref `cockpit` + ref de comando dedicado) | Transporte durável de federação; carrega snapshots particionados por `machine_id` (union-merge sem conflito); carrega o ref de comando **selado** (Q5). Source-of-truth do transporte — o Plano de View projeta DELE. | **não** | SEMI-CONFIÁVEL (atravessa o `origin`/GitHub; integridade por assinatura O2 fim-a-fim, não pelo canal) |
| **P3 — Plano de View** (Supabase `xdikjgpkiqzgebcjgqmu`) | **read-fan-out** de metadata (machine, project, api_key-sem-value, soak_heartbeat, security_seal) + **auth/RBAC-de-leitura**. Populado por push do agentd via função autenticada-O2; UI lê por anon-key + RLS deny-all. NÃO assina, NÃO verifica comando, NÃO pina, NÃO segura segredo. | **não** | NÃO-CONFIÁVEL (control plane, como o browser) |
| **P4 — Plano de Step-up** (Supabase `ideiaos-cockpit-stepup`) | Sensor de presença na origem (email-OTP amarrado a `payload_hash`, comprovante assinado). Projeto **separado** de P3. | possui SERVICE_ROLE própria isolada (zero dado de produto) | NÃO-CONFIÁVEL-CONTIDO (forja presença, não comando) |
| **P5 — UI web** (SPA Vite/React, evolução de `apps/cockpit`) | Cliente read do P3 (ou `read.js` local em fallback). Emite **intenção** referenciada-por-nome, nunca a ação. | **não** | NÃO-CONFIÁVEL (equivalente ao contexto do LLM, `30-security` §0) |

> **Nota sobre P3 vs P4 — separação inegociável.** O projeto de view (`xdikjgpkiqzgebcjgqmu`) e o de step-up (`ideiaos-cockpit-stepup`) **permanecem projetos Supabase separados, com SERVICE_ROLE distintas**. Misturá-los reacopla blast-radius — exatamente o que o ADR de step-up rejeitou (S-04). Comprometer o read-fan-out NÃO compromete o sensor de aprovação, e vice-versa.

---

## 3. Fronteiras de confiança (onde cada corte fica)

1. **FRONTEIRA-PISO (`credential-isolation`, `30-security` §1.2):** entre P0/P1 (seguram valor + chave) e TODOS os outros. **Nada** cruza para cima carregando valor de segredo nem material de chave. A `ApiKey` projetada em P3 **não tem coluna `value`** — herda o schema-que-impede-o-erro (`40-data-model` §2.5). Um dump total do Supabase rende metadata, **nunca** segredo.

2. **FRONTEIRA-DE-AUTORIDADE:** assinar e verificar comando vivem SÓ no agentd local (`sign/verify-payload.sh`). P3 é espelho da VIEW, não autoridade do COMANDO. Um comando que chegue "autorizado pelo Supabase" sem assinatura O2 verificável contra o pin local é **RECUSADO** (`verify-payload.sh` exit≠0 — sha256 ou booleano-de-backend nunca autoriza; é a lição **S-01** do `{verified:true}` solto que a fronteira proíbe o Supabase de produzir).

3. **FRONTEIRA-DE-PIN (ADR O2, fecha o DoS de revogação-forjada):** a lista pinada autoritativa-local (`pinned-keys.sh`, store 0600) NUNCA é alterada por dado vindo do Supabase nem do ref. `process-ref-revocation/addition` já retornam exit 9 ALERT; estende-se: `process-supabase-revocation/addition` = **mesmo exit 9**. Revogar/adicionar peer = re-pin out-of-band local.

4. **FRONTEIRA-DE-PROJEÇÃO (espelho não-confiável):** o fluxo é **unidirecional** — ref/disco → ingest → push assinado → P3 → SELECT da UI. P3 NUNCA escreve de volta no ref nem no read-model local. Divergência view↔ref/disco = **ALERTA** (a view mente), nunca atualização da fonte. O `--verify` recomputa do disco (`74-resilience` §3).

5. **FRONTEIRA-DE-IDENTIDADE-vs-POSSE:** P3 (Supabase Auth) prova **quem é o humano** (AuthN/RBAC-de-leitura), mas RBAC-de-AÇÃO é re-provado no alvo pela assinatura+pin (R-WP2 default-deny no agentd, não na UI). Auth-de-humano e papel-autorizador-de-comando são planos distintos.

6. **FRONTEIRA-DE-EXECUÇÃO (`agent-authority`):** `git push` / `gh pr` / config MCP permanecem EXCLUSIVOS de @devops e FORA do allowlist do agentd (R-WP7 fronteira-permanente), independente de quão forte seja a auth de P3. P3 NÃO vira bypass de `agent-authority`.

7. **FRONTEIRA-DE-EGRESS (`mcp-hygiene`):** a função que popula P3 só ACEITA payloads assinados-O2 e metadata-only (Zero-Leak scan server-side, reuso de `zeroleak-snapshot.sh` antes de qualquer push); CORS só para a origem da UI; SERVICE_ROLE de P3 NUNCA vai ao browser (anon-key + RLS é o que a UI usa).

---

## 4. Fluxos de dados

### 4.1 Diagrama ASCII (a topologia de planos)

```
  P0 SUBSTRATO LOCAL (máquina A)         P0 SUBSTRATO LOCAL (máquina B)
  ledgers · .env(nomes) · git · keychain  (idem)
        │  read-only                              │
        ▼                                         ▼
 ┌──────────────────────┐               ┌──────────────────────┐
 │ P1 AUTORIDADE LOCAL  │               │ P1 AUTORIDADE LOCAL  │
 │ ideiaos-agentd       │               │ ideiaos-agentd       │
 │ • collect (read-only)│               │ • verify-payload.sh  │  ◄─ comando só executa
 │ • sign-payload.sh    │               │   (fail-closed, pin) │     se a assinatura O2
 │ • pinned-keys.sh     │               │ • executa allowlist  │     casa o pin LOCAL
 │ • keychain (segredo) │               │ • ledger hash-chained│
 └─────────┬────────────┘               └──────────┬───────────┘
   snapshot│ metadata-only                ACK/ledger│
   (Zero-Leak gate)                                 │
           ▼                                         ▼
 ════════════════════ FRONTEIRA-PISO (nenhum valor/chave cruza) ═══════════
           │                                         │
           ▼ git plumbing (commit-tree/update-ref)   ▼
 ┌──────────────────────────────────────────────────────────────────┐
 │ P2 BUS GIT — ref órfão `cockpit` (snapshots) + ref de comando      │
 │ dedicado `refs/ideiaos/cmd/<alvo>` (SELADO ao destinatário, Q5)    │  ← atravessa origin/GitHub
 │ • particionado por machine_id (union-merge, zero conflito)         │     (semi-confiável)
 │ • source-of-truth do TRANSPORTE                                    │
 └───────────────┬──────────────────────────────────────┬────────────┘
                 │ push direto (read-fan-out)            │ ledger autoritativo
                 │ função autenticada-O2 + Zero-Leak     │ NUNCA sai do local
                 ▼                                        ▼ (P3 só ESPELHA p/ render)
 ┌──────────────────────────────────────────┐   ┌───────────────────────┐
 │ P3 PLANO DE VIEW (Supabase dedicado       │   │ P4 STEP-UP (Supabase  │
 │ xdikjgpkiqzgebcjgqmu) — read-fan-out      │   │ dedicado, SEPARADO)   │
 │ • views metadata-only (SEM coluna value)  │   │ email-OTP → payload_  │
 │ • RLS deny-all-por-default + RBAC-leitura │   │ hash (comprovante     │
 │ • Realtime/polling                        │   │ assinado, não boolean)│
 │ • Supabase Auth (quem-é-quem)             │   └───────────┬───────────┘
 └───────────────┬──────────────────────────┘               │ comprovante alimenta
                 │ SELECT (anon-key + RLS)                   │ a assinatura O2 em P1
                 ▼                                           │ (na ORIGEM)
 ┌──────────────────────────────────────────┐               │
 │ P5 UI WEB (SPA, acessível de fora)        │ ──intenção────┘
 │ • lê metadata de P3 (ou read.js local)    │   (referenciada-por-nome,
 │ • emite INTENÇÃO, nunca a ação            │    zero valor, zero comando)
 └──────────────────────────────────────────┘
```

### 4.2 READ-MODEL (read-fan-out — o que cura a dor de sync de leitura)

```
P0 substrato → P1 collect (read-only) → snapshot metadata-only
   → zeroleak-snapshot.sh (gate Zero-Leak, R-WP5)
   → DOIS destinos idempotentes:
       (1) P2 ref `cockpit` (git plumbing — DURÁVEL, source-of-truth do transporte)
       (2) P3 push direto via função autenticada-O2 (UPSERT por machine_id — FRESCURA)
   → P5 UI faz SELECT via anon-key + RLS deny-all + RBAC-de-leitura
```

Latência: push direto a P3 = **segundos**; o ref permanece como redundância durável (~15min). A UI exibe **frescor honesto** ("verificado há Xs", nunca animar fluxo contínuo sobre lote — R do Frescor honesto + `74-resilience` §1).

> **Disciplina de fonte:** P3 é **cache descartável reconstruível do ref** (`40-data-model` §0). `TRUNCATE + rebuild` periódico do P3 a partir do ref é mais simples que squash. Se P3 cai, a UI degrada para o último estado conhecido + `read.js` local como fallback frio.

### 4.3 COMANDO LOCAL-REVERSÍVEL (v14.1, web→local)

```
P5 emite intenção {verb:'pause_autosync', target} → chega ao P1 da máquina-alvo
   → enum fechado (read.js VERBS) + token efêmero por-boot + Origin/Host gate (same-origin)
   → armar-antes-de-disparar (confirmed:true) → spawnSync sem shell, args constantes
   → stdout via Zero-Leak scan → ACK no ledger.
```

Para cross-máquina, a intenção viaja pelo ref **selado** (idempotente + ACK, R-WP8) — NUNCA "FEITO" sem ACK do alvo no ledger.

### 4.4 COMANDO ASSINADO (write-path gated, rotate/revoke/deploy)

```
P5 emite intenção referenciada-por-nome → P1-ORIGEM (não o browser, não o Supabase) monta o
payload canônico → exige step-up (P4) → assina com O2 (sign-payload.sh) → payload+sig SELADOS
ao alvo viajam no ref de comando dedicado (Q5) → P1-ALVO abre o selo, verifica contra o pin
local (verify-payload.sh, fail-closed) → executa server-side → gera novo valor NA MÁQUINA-ALVO,
grava no keychain do alvo, retorna só metadata (R-WP5) → ACK + ledger hash-chained LOCAL.
P3 NUNCA toca este fluxo — só reflete o ACK/ledger depois, para render.
```

### 4.5 STEP-UP OTP (presença humana, HYBRID — inalterado)

```
P5 pede OTP → P4 send-otp (CSPRNG, rate-limit por email, CORS loopback) → humano insere OTP
   → P4 verify-otp amarra a payload_hash=sha256(canonical{action,ref,scope,target,nonce,expiry})
   → retorna COMPROVANTE ASSINADO (não booleano — fix S-01) → P1 só assina o token O2 se casar.
Tier crítico/deploy: + O4 out-of-band SEMPRE (P4 comprometido não basta).
```

---

## 5. Esboço de schema do Plano de View (P3 — read-fan-out)

> **SEM DDL aplicável neste spike (pure design — nenhuma tabela criada).** Esboço conceitual para o `/spec` + `@data-engineer`. **Regra-piso materializada no schema:** nenhuma tabela tem coluna `value`. P3 é projeção das tabelas metadata-only de `40-data-model` §3 (SQLite local → Postgres-federado, com RLS).

**Tabelas read-fan-out (espelham `40-data-model`, metadata-only):**

- **`machine`** — `machine_id` (PK, hostname normalizado), `display_name`, `aliases_json`, `first/last_seen_epoch`, `last_doctor`, `last_regression`, `is_active`. **Sem** IP atual, sem segredo.
- **`project`** — `project_slug` (PK), `github_remote`, `is_lovable`, `supabase_project_id`, `under_autosync`, `lovable_deny_count`. **Sem** `.env` content.
- **`api_key`** — `(project_slug, var_name)` (PK), `present`, `expected`, `risk_tier`, `file_mtime_epoch`, `committed`. **SEM coluna `value` — por construção, herda o schema-que-impede-o-erro.**
- **`soak_heartbeat`** — `(milestone, epoch, machine_id)` (PK), `idea_doctor`, `regression`, `commit`.
- **`security_seal`** — `(repo, epoch)` (PK), `reviewer`, `verdict`, `scope`. Espelho do ledger; a cadeia hash autoritativa é recomputada LOCAL (detecção ≠ prevenção, R-WP9).

**Tabelas de auth/RBAC-de-leitura (NOVAS — só identidade do humano-que-olha):**

- **`console_user`** — `user_id` (PK, de Supabase Auth), `display_name`, `role` ∈ {cto, dev}, `email`. Mapeia a identidade autenticada ao RBAC-de-leitura.
- **`user_project_scope`** — `(user_id, project_slug)` (PK). Escopo binário/por-projeto (`dev` vê só os atribuídos; `cto` vê tudo). Curadoria manual (de onde vem o mapa subject→projetos é **fork aberto**).

**Tabela mailbox de comando (DEFERIDA — não no read-fan-out inicial):**

- **`command_mailbox`** — `(command_id)` (PK, idempotência), `recipient_machine_id`, `sealed_payload` (**ciphertext** endereçado ao alvo — sign-then-seal, Q5), `status` (PENDENTE/ACKED), `created_epoch`. **Conteúdo opaco a P3** (cifrado à chave do alvo). Anti-replay (nonce-visto/expiry) é estado **100% durável no ALVO**, nunca em P3. **Só entra na Fase 2, gated por R-WP10 + Q5.** No read-fan-out inicial, o comando continua pelo ref `cockpit` selado.

**RLS (todas as tabelas):** `deny-all-por-default`, então `SELECT` liberado por `role` + `user_project_scope` (espelha o RBAC de `30-security` §5.2). **Nenhuma policy de INSERT/UPDATE para a UI** — a UI só lê; o UPSERT vem só da função autenticada-O2 (server-side, SERVICE_ROLE nunca no browser).

> **O backend de step-up OTP (P4) é o PRIMEIRO TIJOLO.** P4 (`ideiaos-cockpit-stepup`) já está decidido (ADR HYBRID) e seu bootstrap (B3-HYBRID) é a próxima peça a executar — antes mesmo de P3. P3 reusa o **padrão** de RLS deny-all + sanitização do P4/ideiapartner, mas é projeto separado.

---

## 6. Mapa de migração do local-first atual

**Estratégia: aditivo, faseável, reversível — espírito SOAK.** A Fase 1 entrega ~80% do valor (a dor de leitura) sem tocar o write-path.

| O que | Reusa (intacto) | Novo a construir |
|-------|-----------------|------------------|
| **P0/P1 autoridade** | `source/agentd/{sign,verify,pinned-keys}.sh` (19/19 proof-gates), keychain, `collect.js`, `zeroleak-snapshot.sh`, enum fechado do `read.js` | — (write-path INTOCADO) |
| **P2 bus git** | ref `cockpit`, autosync, git plumbing | ref de comando dedicado selado (já desenhado em Q5 ADR) — **só Fase 2** |
| **P3 view** | padrão RLS deny-all do ideiapartner/P4 | schema read-fan-out + **1 função UPSERT autenticada-O2** + Supabase Auth + RBAC-de-leitura |
| **P4 step-up** | ADR HYBRID já decidido | bootstrap B3-HYBRID (próximo passo — **primeiro tijolo**) |
| **P5 UI** | SPA `apps/cockpit`, `read.js` local (fallback) | data-source alternativo (Supabase anon-key+RLS quando remoto; `read.js` quando local) |

**Faseamento gated:**

- **Fase 1 — read-fan-out PURO (P3 read-only).** Cura a dor de sync de leitura. Blast-radius mínimo. **NÃO toca o write-path.** Estreia em **modo ADVISORY** (a UI mostra a view P3 AO LADO do `read.js` local, comparando; divergência = ALERTA) por um ciclo SOAK antes de a view virar data-source primário. Reversível: remover P3 volta ao git-as-bus puro sem perda (P3 é cache).
- **Fase 2 — mailbox de comando (só DEPOIS).** Qualquer roteamento de comando por terceiro entra só após **Q5 decidida em ADR** (já PROPOSTO em `v14.4-command-ref-origin-exposure.md`, com o princípio topology-independent que carrega para o v15) e gated por R-WP10. Hoje, comando continua pelo ref selado.

**Custo de RISCO (não de código):** P3 é uma superfície de rede/Supabase permanente que o local-first não tinha — paga-se com a contenção (metadata-only + sem autoridade) e entra no `security-freshness` (P3 conta como **crítica=3**).

---

## 7. Blast-radius por plano (o teste do invariante zero-trust)

> Invariante alvo: **NÃO existe UM ponto que, comprometido, dê controle TOTAL da produção.** Comprometer o control plane deve render metadata + roteamento — nunca segredo nem capacidade de forjar comando.

| Plano comprometido | O adversário GANHA | O adversário NÃO ganha | Veredito |
|--------------------|--------------------|------------------------|----------|
| **P0/P1 (agentd local de UMA máquina)** | posse de segredo daquela máquina + assinar comandos válidos COMO aquela máquina, até o re-pin | as chaves de **outras** máquinas (cada uma tem seu par e pin local); NÃO há chave-mestra central (R-WP7) | É o risco residual **Q2 já DECLARADO e ACEITO** (janela comprometimento→re-pin; mitigado por encurtar a janela + O4 no crítico). **Por-máquina, não global.** Este spike NÃO aumenta esse raio (autoridade não se moveu). |
| **P2 (bus git / origin GitHub)** | entregar um ref forjado (capacidade de DoS de entrega) + mentir a TELEMETRIA (metadata) | assinar comando válido (sem a privada O2 → verify exit≠0); adicionar/revogar pin (`process-ref-*` = exit 9 ALERT) | Comando forjado é **RECUSADO** no alvo; revogação forjada da chave BOA é **IGNORADA** (DoS fechado). Rende metadata + DoS de entrega — nunca segredo nem comando válido. |
| **P3 (Plano de View Supabase — a MAIOR superfície NOVA)** | (a) LER toda a metadata do ecossistema (máquinas, projetos, NOMES de chave, idades, tiers) — **reconnaissance real**; (b) MENTIR a view para a UI (injetar linha falsa de ledger/"tudo verde") | **segredo** (sem coluna `value`); **assinar comando** (chave O2 é local); **mutar a lista pinada** (re-pin é out-of-band); **executar verbo** no agentd (verify-payload local é a porta) | **DEFESA contra mentira:** `--verify` recomputa do disco/ref; quebra de cadeia do ledger detectada LOCAL; divergência view↔ref = ALERTA. **VEREDITO: rende metadata + capacidade de mentir a VIEW — exatamente o teto que o invariante permite.** O invariante SOBREVIVE. |
| **P4 (step-up Supabase)** | forjar APROVAÇÕES de presença | executar comando (precisa da assinatura O2 local) | Contido por binding `payload_hash` + O4 out-of-band no crítico (email-comprometido sozinho não rotaciona SERVICE_ROLE). Já analisado (8 condições). |
| **P5 (sessão web roubada)** | emitir INTENÇÃO autorizada-pelo-RBAC-do-subject roubado (ver metadata do escopo) | valor de segredo (defesa estrutural: nunca no DOM); comando crítico (exige step-up O2 local que a sessão sozinha não satisfaz) | Mau no escopo daquele subject (control plane), mas sessão web ≠ capacidade de rotacionar SERVICE_ROLE. |

**Reconnaissance via P3 — o risco honesto a declarar:** mesmo sem segredo, a metadata agregada (topologia da frota, quais chaves críticas existem onde, cadência de rotação) é inteligência valiosa. Mitigação: RLS deny-all + escopo por RBAC, anon-key (nunca SERVICE_ROLE no browser), CORS pinado, entra no `security-freshness` como crítica.

---

## 8. Vetos-de-design (lei de revisão — protege a arquitetura do drift)

O maior risco estrutural é o **escopo-creep**: a pressão de produto para "deixar o plano de view mais esperto" empurra segredo/lógica-de-assinatura para dentro do Supabase. Esse é o vetor que MATA a arquitetura. Gravam-se vetos auditáveis (espelham `30-security` §10):

- [ ] **O Plano de View segura segredo?** → qualquer SIM é veto.
- [ ] **O Plano de View assina algo?** → veto.
- [ ] **O Plano de View pina/muta a lista pinada?** → veto.
- [ ] **O Plano de View abre um verbo de execução?** → veto.
- [ ] **P3 e P4 são o mesmo projeto Supabase?** → veto (S-04, blast-radius).
- [ ] **A UI toma decisão de autoridade só pela view (sem ACK do ref/recompute local)?** → veto.
- [ ] **A função de ingestão aceita payload não-assinado-O2 ou pula o Zero-Leak?** → veto.

---

## 9. Caminho de evolução pré-pensado (NÃO construir agora)

Se/quando a sync de **comando concorrente cross-máquina** doer (gap `74-resilience` §4.3 — union-merge não escala para estado compartilhado), o gatilho documentado é: **fila/mailbox transacional com ACK durável NO ALVO** (idempotência por `command_id` natural; anti-replay nonce-visto/expiry 100% local, com proof-gate por exit-code no bootstrap), **selada ao destinatário** (sign-then-seal, Q5). Isto é a Fase 2 do §6 — ancorada em doc real, mas não antecipada. `enforce-simplicity` hoje; remoção de ambiguidade sobre a fronteira read↔write amanhã.

---

## 10. Perguntas abertas (forks do operador — para `/grelha`)

1. **Git-as-bus: aposentar ou manter em paralelo?** Recomendação: **manter** o ref `cockpit` como espinha de transporte durável e fonte da reconstrução do P3 (reforça R-WP9 a custo ~zero; preserva fallback frio). P3 push direto só acelera a leitura, não substitui o ref.
2. **Modelo de auth / quem são os usuários?** Supabase Auth (P3) com GitHub OAuth da org `DevIdeiaBusiness` (identidade canônica já existente) — confirmar. De onde vem o mapa `user→projetos` para o RBAC-de-leitura (git author email + tabela curada, como `User`≠`Account` de `40-data-model` §2.4)? Quem mantém a curadoria?
3. **Hospedagem da UI web:** servida do próprio P3 (Supabase hosting/Vercel) ou continua local com data-source remoto? `enforce-simplicity` sugere começar local-com-data-source-remoto; hospedar fora só quando "acesso de fora" doer de fato.
4. **Realtime vs polling no MVP?** `enforce-simplicity` sugere **polling primeiro** — medir se segundos importam vs minutos antes de Realtime.
5. **Numeração do milestone:** v15 (sucessor formal) vs v14.5 (extensão da família v14)? Provisório — flag como fork (ver objeto estruturado).
6. **Q5 já PROPOSTO** (`v14.4-command-ref-origin-exposure.md`) — ratificar agora junto, ou no merge da Fase 2? A view remota muda o cálculo: com a leitura indo por P3, o ref de COMANDO pode não precisar ir ao `origin` por padrão.

---

## 11. Rastreabilidade

- **Sucede (eixo leitura/federação):** `docs/ideiaos-console/20-architecture.md` (Caminho A → colhe o Caminho C parqueado §2.1).
- **Preserva intacto:** `docs/decisions/v14.4-origin-auth-signing-mechanism.md` (O2), `v14.4-step-up-without-relying-party.md` (step-up HYBRID), `v14.4-command-ref-origin-exposure.md` (Q5 — princípio topology-independent que já carrega para o v15).
- **Contrato vivo:** `specs/cockpit/spec.md` (R-WP1..R-WP11 — nenhum regride; propõe **R-WP12** "Plano de View read-only metadata, nunca autoridade; divergência view↔disco é alerta, nunca atualização").
- **Design existente:** `30-security-credential-isolation.md`, `40-data-model-telemetry-mesh.md`, `74-resilience-federation-retention.md`, `10-vision-strategy.md`.
- **Rules-piso:** `credential-isolation`, `agent-authority`, `security-freshness`, `antifragile-gates`, `mcp-hygiene`, `delta-spec`, `ubiquitous-language`.
