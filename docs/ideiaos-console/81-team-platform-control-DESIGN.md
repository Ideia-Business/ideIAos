# 81 — Plataforma de Time Controlada (Cockpit multi-dev) — DESIGN

> **Documento:** `81-team-platform-control-DESIGN.md`
> **Persona:** Arquiteto-chefe (síntese de re-escopo — expande o split-plane v15 de read-fan-out para plataforma de time)
> **Status:** PROPOSTO (design completo — NÃO ratificado pelo operador)
> **Data:** 2026-06-22
> **Estende:** `80-split-plane-control-plane-DESIGN.md` (planos P0..P5) no eixo **multi-dev controlado**; preserva-o intacto.
> **Tece os requisitos de:** `82-team-coordination-onboarding-requirements.md` (R-COORD1..R-COORD5).
> **ADR-sucessor:** `docs/decisions/v15-cockpit-split-plane-control-plane.md` (DRAFT — este design pede a EXPANSÃO do ADR de read-fan-out para plataforma de time).
> **Princípio-âncora (frase do operador):** **"delegar o TRABALHO sem delegar o CONTROLE."** E — pela camada de coordenação — sem os trabalhos colidirem entre si.

---

## 0. A convicção, em uma página

O rig de 1 operador (2 máquinas, contas Cursor/Claude/Lovable + GitHub compartilhado `desenvolvimento@ideiabusiness.com.br`) está **provado**. O salto agora é: **colaboradores (devs) entram na MESMA estrutura para ajudar, sem o CTO e o TechLead perderem o controle.**

A plataforma é hospedada em `cockpit.ideiabusiness.com.br`, acessível **só por usuários validados**. Ela **NÃO move a autoridade**: continua valendo o invariante zero-trust do v15 — os **três ativos de poder total** (chave de assinatura **O2**, **lista pinada autoritativa-local**, **valor de segredo**) nunca vão ao cloud. O que se torna remoto é exatamente o que o split-plane (doc 80) já autorizou: **a VIEW (leitura de metadata + identidade de quem-olha) + a coordenação**. A AUTORIDADE permanece local e intocada.

O coração do design são **5 alavancas de controle** (todas na mão dos admins) e **2 pilares** (onde a visão encosta na regra-piso de segurança). Tudo reusa o que já foi construído.

### As 5 alavancas (resumo)

| # | Alavanca | O que faz | Artefato que JÁ a suporta |
|---|----------|-----------|---------------------------|
| 1 | **Admissão** | máquina gera hash → PENDENTE → admin aprova (o "pin" O2) | `pinned-keys.sh` + enrollment TOFU+pin-out-of-band do **ADR O2** |
| 2 | **Autorização** | admin define escopo "user X nos projetos A,B,C" (RBAC-de-leitura/escopo) | `user_project_scope` (doc 80 §5) + RBAC-de-leitura `30-security` §5.2 |
| 3 | **Reserva de poder** | rotacionar segredo / revogar máquina / deploy-prod atrás do step-up E privilégio de admin | step-up **HYBRID** (ADR Q3) + R-WP10/R-WP11 (verbos gated/fronteira-permanente) |
| 4 | **Visão** | cada estação reporta; commits/pushes/acessos por usuário agregados → **Vault** | read-fan-out (P3) + `commit_log.actor_class` + Pilar A (autor-do-commit) |
| 5 | **Reversão** | admin revoga máquina/usuário (re-pin out-of-band local) sem quebrar os outros | FRONTEIRA-DE-PIN do ADR O2 (`process-*-revocation` = exit 9) |

### Os 2 pilares (resumo)

- **Pilar A — atribuição por AUTOR-DO-COMMIT, não por conta GitHub.** GitHub é compartilhado → atribuição per-usuário NÃO pode vir do GitHub. Vem de: (i) o cockpit configura o git local de cada estação com a identidade-cockpit do dev (`joao@ideiabusiness`) como **autor** do commit; (ii) cada estação reporta "estação-do-João empurrou branch X" via telemetria. Auditoria = cockpit + autor-do-commit → Vault.
- **Pilar B — cockpit guarda VÍNCULO, máquina guarda VALOR.** O cockpit hospedado guarda **vínculo+autorização** ("user X tem Cursor ligado, expira Y; pode em A,B,C"). O **VALOR** do token fica no keychain LOCAL da máquina do dev (depositado no fluxo OAuth direto no agente local), NUNCA no banco hospedado. O cockpit sabe **QUEM PODE**; a máquina é quem **TEM**. `credential-isolation` intacta.

---

## 1. Glossário (linguagem ubíqua — estende `CONTEXT.md` do doc 80 §1)

| Termo canônico | Definição | _Evite_ |
|----------------|-----------|---------|
| **Admin** | CTO ou TechLead. Único papel que cria usuários, aprova estações, define escopo, e detém os verbos de Reserva-de-poder. | "owner", "root" |
| **Dev (colaborador)** | usuário não-admin. Trabalha em branch própria nos projetos autorizados; NÃO herda poder irreversível. | "membro", "user comum" |
| **Estação** | uma máquina física de um dev, com `ideiaos-agentd` instalado, identificada por `machine_id` + hash de enrollment. | "device", "host" |
| **identidade-cockpit** | o email canônico do dev na plataforma (`joao@ideiabusiness`) — gravado como `git user.email` LOCAL da estação (Pilar A) e mapeado ao `console_user`. | "conta GitHub", "git author qualquer" |
| **vínculo (de provedor)** | registro no cockpit de que "estação E do user U tem provedor P ligado, expira em T, escopo A,B,C". Metadata. **NÃO** é o token. | "credencial", "segredo" |
| **liberações pendentes** | fila de estações em estado PENDENTE aguardando aprovação de admin (alavanca Admissão). | "aprovações", "requests" |
| **claim (soft-lock)** | reivindicação advisory de um item de plano/handoff ou de um arquivo/área, visível a todos, que **alerta** na sobreposição. | "lock", "trava" |
| **Admissão / Autorização / Reserva de poder / Visão / Reversão** | as 5 alavancas de controle — ver §3. | — |

---

## 2. Os planos (topologia — estende doc 80 §2)

Nenhum plano novo de autoridade. A plataforma de time **adiciona conteúdo às tabelas de P3** (vínculo, escopo, claims) e **adiciona estações** (mais instâncias de P0/P1), mas o teorema do invariante zero-trust do doc 80 §2 vale byte-a-byte: os três ativos de poder total vivem em planos **locais distintos**, **nenhum** no cloud.

| Plano | Papel na plataforma de time | Muda do doc 80? |
|-------|------------------------------|-----------------|
| **P0 — Substrato local** (por estação) | disco vivo da estação do dev: ledgers, `.env`(nomes), git, **keychain do dev** (onde os tokens OAuth de Cursor/Claude/Lovable/GitHub são depositados — Pilar B). | +N instâncias (1 por estação de dev). Inalterado em natureza. |
| **P1 — Autoridade Local** (`ideiaos-agentd`, por estação) | assina O2 COMO a estação; verifica comando contra o pin local; **executa o fluxo OAuth do dev e deposita o token no keychain local** (Pilar B); grava ledger; configura `git user.email`=identidade-cockpit (Pilar A). | +N instâncias. Ganha a sub-tarefa de enrollment/OAuth-local. |
| **P2 — Bus Git** (ref `cockpit` + ref de comando selado) | espinha de transporte durável; carrega snapshots por `machine_id`. **Fonte dos claims** (R-COORD5) que P3 espelha. | Inalterado. |
| **P3 — Plano de View** (Supabase `xdikjgpkiqzgebcjgqmu`) | read-fan-out de metadata **+ vínculo + autorização + claims + identidade**. **Aqui mora a coordenação remota.** Continua: NÃO assina, NÃO verifica comando, NÃO pina, NÃO segura valor de segredo. | **Expande**: ganha `console_user`/`user_project_scope`/`station_enrollment`/`provider_link`/`task_claim`/`file_claim` (todas metadata). |
| **P4 — Step-up** (Supabase `ideiaos-cockpit-stepup`, SEPARADO) | sensor de presença-humana na origem (email-OTP HYBRID) para os verbos de Reserva-de-poder. | Inalterado. Projeto distinto de P3 (S-04). |
| **P5 — UI web** (SPA, `cockpit.ideiabusiness.com.br`) | duas faces: **cockpit-admin** (CTO/TechLead) e **cockpit-operador** (dev — R-COORD2). Lê P3; emite **intenção**, nunca a ação. | **Expande**: ganha onboarding dinâmico (R-COORD1), quadro de claims (R-COORD3/4/5). |

> **Hospedagem (resolve fork doc 80 §10.3, sob a luz da restrição de step-up):** a UI vai a `cockpit.ideiabusiness.com.br` (web-acessível, requisito da plataforma de time). MAS o **write-path e o step-up (`send-otp`/`verify-otp` + O2-sign) só são disparados da UI LOCAL (loopback) da estação** — a UI remota P3 é **read-only + coordenação**, e NUNCA inicia write-path (preserva S-08 CORS-loopback; é o must-fix #4 do v15 ADR). Ir web-acessível **troca** a propriedade de mínimo-recon que o loopback dava (perda consciente — must-fix #2 do v15 ADR; ver §10).

---

## 3. As 5 alavancas de controle (o coração) — detalhadas

### Alavanca 1 — ADMISSÃO (máquina gera hash → PENDENTE → admin aprova)

É o **"pin" O2** aplicado a estações de dev. O fluxo é exatamente o enrollment TOFU + pin-out-of-band do **ADR O2**, com o admin no lugar do "operador comparando duas telas":

```
1. dev roda o instalador na estação → agentd gera par O2 (Ed25519, privada no keychain)
   + chave de encriptação (Q5) → calcula fingerprint → calcula HASH de enrollment
   {machine_id, signing_fingerprint, enc_pubkey} e o publica como PENDENTE (via ref cockpit + push P3).
2. a estação entra em "liberações pendentes" — visível ao admin no cockpit-admin.
3. o ADMIN aprova: compara o fingerprint exibido na tela do dev com o exibido no cockpit
   (out-of-band: o dev lê o fingerprint por canal já-confiável — chamada/Slack), e confirma.
4. APROVAÇÃO = re-pin AUTORITATIVO-LOCAL: a entrada {machine_id, fingerprint, enc_pubkey, role}
   é gravada na lista pinada LOCAL de cada agentd existente (out-of-band, NUNCA pelo ref).
   P3 só ESPELHA o estado "APROVADA" (metadata) — não é a autoridade.
```

**Invariante:** ninguém opera sem OK do admin. A `station_enrollment` em P3 é metadata (status PENDENTE/APROVADA); a **confiança real** é o pin local. O ref nunca adiciona pin (FRONTEIRA-DE-PIN do ADR O2).

> **Suporte existente:** `source/agentd/pinned-keys.sh` (store 0600, `{machine_id, pubkey_fingerprint, role}` — já provado 19/19) + o enrollment do ADR O2. **Novo:** a UI de aprovação no cockpit-admin (P3 reflete a fila; o pin é local).

### Alavanca 2 — AUTORIZAÇÃO (escopo "user X nos projetos A,B,C")

RBAC-de-**leitura/escopo**. O admin define, em `user_project_scope` (P3), quais projetos cada dev vê e em quais pode trabalhar. É o RBAC-de-leitura do `30-security` §5.2 com escopo por-projeto (não-binário).

- **default-deny:** capacidade/projeto não-listado = negado.
- **fronteira com RBAC-de-AÇÃO:** Autorização governa **o que o dev VÊ e onde trabalha** (control plane). A **autorização de COMANDO** (rotate/deploy) é re-provada no alvo pela assinatura+pin (R-WP2 default-deny no agentd) — Autorização-de-leitura **não** dá poder de mutação. FRONTEIRA-DE-IDENTIDADE-vs-POSSE (doc 80 §3.5).

> **Suporte existente:** `console_user.role ∈ {cto, dev}` + `user_project_scope` (doc 80 §5). **Expansão:** `role` ganha `techlead` (admin) — ver §11 fork.

### Alavanca 3 — RESERVA DE PODER (verbos irreversíveis = step-up + admin)

Rotacionar segredo / revogar máquina / deploy-prod ficam atrás do **step-up E são privilégio de admin**. Dev logado NÃO herda poder irreversível.

- **step-up:** ADR HYBRID (email-OTP universal + Touch ID local), amarrado a `payload_hash` (R-WP3), comprovante assinado, nunca booleano. Tier `crítico`/`deploy` exige **O4 out-of-band** sempre.
- **privilégio de admin:** o `role` provado pela chave pinada (Pilar A) tem de ser admin para o agentd-alvo aceitar o verbo; um payload `role:cto` auto-declarado de uma chave-de-dev é recusado (R-WP2).
- **fronteira-permanente (R-WP11):** `reveal` de valor, `exec`, `git push`/`gh pr`, config MCP, rotação/deploy automáticos sem humano, chave-mestra central, revoke/rotate em massa atômico — **nunca** entram no allowlist, independente da auth.
- **deploy-prod (bate exato com os mapas):** em TODOS os 4 repos o deploy de frontend é um **clique humano manual Update→Publish na Lovable**. O cockpit **intercepta/gateia esse clique** como verbo `deploy` (step-up + admin + O4). O backend (Edge Functions via `supabase functions deploy`, Cloud Run Redeploy) é verbo `deploy` **separado**, gateado por-projeto (ver §6).

### Alavanca 4 — VISÃO (telemetria por-usuário → Vault)

Cada estação reporta; commits/pushes/acessos **por usuário** são agregados e fluem ao **Vault Obsidian**. É o Pilar A operacionalizado: como o autor-do-commit carrega a identidade-cockpit, o read-model atribui atividade ao dev certo mesmo com GitHub compartilhado.

- **fonte:** `commit_log` (doc 40 §2.8) com `author_email`=identidade-cockpit + `actor_class` (human/bot/autosync — regra determinística doc 40 §6) + telemetria de estação (snapshot, `MachineSnapshot`).
- **destino:** relatório por-usuário → Vault (alavanca Visão + concern #2 do brief).
- **honestidade (R-WP3/Frescor honesto):** "verificado há Xs"; nunca anima fluxo contínuo sobre lote; só sinal real entra (doc 40 §6 — `human-feat-commits`, `sessões meaningful`), nunca vaidade (autosync, bots).

### Alavanca 5 — REVERSÃO (revogar máquina/usuário sem quebrar os outros)

O admin revoga uma estação/usuário; isso é um **re-pin out-of-band LOCAL** na lista pinada (o admin remove a entrada `{machine_id,...}` na máquina sobrevivente). Não quebra os outros: cada estação tem seu par e seu pin; não há chave-mestra central.

- **FRONTEIRA-DE-PIN (ADR O2):** revogação **via ref/P3 é detectiva/advisória apenas** — `process-supabase-revocation`/`process-ref-revocation` = **exit 9 ALERT**, nunca remove pin. A revogação AUTORITATIVA é o re-pin local out-of-band. Isso fecha o DoS de **revogação-forjada** (uma estação comprometida NÃO pode assinar a revogação da chave boa de outra).
- **blast-radius (doc 80 §7):** comprometer 1 estação = posse de segredo **daquela** máquina + assinar como ela até o re-pin. NÃO ganha as chaves das outras. Por-estação, não global.

---

## 4. Ciclo de vida do usuário (admin cria → onboard → enrollment+hash → admin aprova → vínculo → trabalho)

Materializa R-COORD1 (onboarding dinâmico, idempotente, re-entrante).

```
┌─ ADMIN (cockpit-admin, P5) ───────────────────────────────────────────┐
│ 1. cria usuário {joao@ideiabusiness, role=dev}          → console_user │
│ 2. atribui "joao trabalha em nfideia, cfoai"            → user_project_scope │
└───────────────────────────────────────────────────────────────────────┘
            │ (joao recebe convite / primeiro login web)
            ▼
┌─ DEV — PRIMEIRO LOGIN (cockpit-operador, P5) ─ guia DINÂMICO R-COORD1 ─┐
│ 3. login web (Supabase Auth, GitHub OAuth org DevIdeiaBusiness)        │
│ 4. guia mostra "rode ISTO p/ instalar o IdeiaOS na sua máquina"        │
│    (o canivete suíço: agentd, autosync, gates, idea-doctor)            │
└───────────────────────────────────────────────────────────────────────┘
            │ dev roda o instalador na ESTAÇÃO (P0/P1 local)
            ▼
┌─ ESTAÇÃO (P1 agentd) ─ ENROLLMENT + HASH (alavanca Admissão) ─────────┐
│ 5. agentd gera par O2 (privada→keychain) + enc-key (Q5)               │
│ 6. configura git LOCAL: user.email = joao@ideiabusiness (PILAR A)     │
│ 7. publica enrollment {machine_id, fingerprint, enc_pubkey} PENDENTE  │
│    → entra em "liberações pendentes"                                  │
└───────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─ ADMIN APROVA (alavanca Admissão) ────────────────────────────────────┐
│ 8. compara fingerprint out-of-band → re-pin LOCAL autoritativo        │
│    (entrada gravada na lista pinada de cada agentd; P3 espelha APROVADA)│
└───────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─ DEV — VÍNCULO OAUTH (PILAR B — guia continua, idempotente) ──────────┐
│ 9. p/ cada provedor (GitHub compartilhado / Cursor / Claude / Lovable):│
│    o agentd LOCAL roda o fluxo OAuth; o VALOR do token → keychain LOCAL │
│    o cockpit grava só o VÍNCULO {provider, status:✅, expira:T, escopo} │
│    em provider_link (P3). NUNCA o token. Guia mostra ✅/⏳/❌ ao vivo.   │
└───────────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─ DEV — TRABALHO EM BRANCH (por projeto autorizado) ───────────────────┐
│ 10. trabalha em feat/* própria; commit carrega joao@ideiabusiness     │
│ 11. claim de tarefa/arquivo (R-COORD3/4/5) visível aos demais         │
│ 12. telemetria flui (alavanca Visão) → Vault                          │
└───────────────────────────────────────────────────────────────────────┘
```

**Idempotência (R-COORD1):** se joao volta, o guia mostra **só o que falta** (estação já aprovada? pula 5-8; Cursor já vinculado? mostra ✅ e segue). Cada passo tem status ✅/⏳/❌ derivado de P3 (vínculo) cruzado com a saúde da estação (snapshot, R-COORD2).

---

## 5. Modelo de credencial (Pilar B) — por provedor

**Regra-piso:** o cockpit guarda **VÍNCULO**; a máquina guarda **VALOR**. O `provider_link` em P3 **não tem coluna `value`** (herda o schema-que-impede-o-erro, doc 40 §2.5). O fluxo OAuth roda no **agentd local** da estação e deposita o token no **keychain local**.

| Provedor | O que o CLOUD (P3) guarda — VÍNCULO | O que a MÁQUINA (keychain local) guarda — VALOR | Mecanismo de depósito |
|----------|-------------------------------------|--------------------------------------------------|------------------------|
| **GitHub (conta compartilhada `desenvolvimento@ideiabusiness.com.br`)** | `{provider:github, identifier:DevIdeiaBusiness, status:✅, scopes:[repo,workflow,read:org], bound_machine_id, last_verified}` — metadata do `gh auth status` | o **OAuth token** já vive no **macOS keyring** (`gh auth status → (keyring)`, verificado `30-security` §2.3); 0 `oauth_token` em plaintext | `gh auth login` (CLI keychain-nativa — agentd NUNCA lê o valor, R-WP6) |
| **Cursor** | `{provider:cursor, status:✅, expira:T, escopo}` — presença de auth OAuth, nunca o token | `~/.cursor/projects/*/mcp_auth.json` (OAuth do plugin) — local | fluxo OAuth do Cursor na estação; cockpit conta a **existência**, não lê o token (doc 40 §2.2) |
| **Claude** | `{provider:anthropic, identifier (email), mechanism:oauth, status:✅}` | `~/.claude.json` `oauthAccount` — local | login do Claude Code na estação; cockpit lê só `oauthAccount.emailAddress` (metadata) |
| **Lovable** | `{provider:lovable, mcp_uuid:6f530143-…, enabled-por-projeto, lovable_deny_count:19}` | OAuth do MCP Lovable — local (`~/.cursor/mcp.json`); **deny-list de 19 tools mutantes** auditada | conexão MCP na estação; cockpit audita o deny-count (regride sozinho — `30-security` §6.4) |

**Invariantes do Pilar B:**
- **OAuth roda LOCAL, valor fica LOCAL.** O agentd da estação conduz o handshake e deposita no keychain. O cockpit hospedado **nunca** vê o token (FRONTEIRA-PISO, doc 80 §3.1).
- **Vínculo é metadata + expiração + escopo.** "QUEM PODE" (cloud) ≠ "QUEM TEM" (máquina). Revogar o vínculo no cockpit **não** apaga o token local — apenas marca o dev como sem-autorização (e a Reversão/re-pin é o que efetivamente corta a autoridade da estação).
- **Provider sem keychain-nativo (R-WP6):** onde a CLI exige o valor via env (não-`gh`), o valor vive só no env de um **processo-filho efêmero** na estação, documentado como risco residual aceito, nunca em log/arquivo durável.

---

## 6. Modelo de isolação de branch/deploy (concern #1) — POR REPO, fundamentado nos mapas

**O achado central, comum aos 4 repos:** *branch isola o CÓDIGO, mas NÃO isola o DEPLOY.* Nenhum dos 4 repos oferece **preview-deploy por branch** para o frontend — todos são **Lovable, com UM editor / UM estado publicável por projeto, derivado SÓ de `main`, e produção é um clique humano manual Update→Publish**. Logo a não-colisão de deploy **não** é resolvível por Git; exige uma **camada de coordenação ACIMA do git** (R-COORD5) + **serialização do Publish** pela alavanca Reserva-de-poder.

E há um agravante estrutural comum: **`main` NÃO tem branch protection enforçável** nos 4 repos (`gh api branches/main/protection` = **403 "Upgrade to GitHub Pro"**). A disciplina PR→merge é **convenção, não enforçada pela plataforma**. Push direto a `main` é tecnicamente possível; o autosync auto-pusha branches não-main. Portanto o cockpit é a **única** camada onde a serialização pode de fato ser imposta (e ainda assim advisory, pois não há enforcement no servidor).

### 6.1 Matriz por repo (DADO dos mapas — não palpite)

| Repo | Preview por branch? | Gatilho de deploy frontend | Backend (gate separado) | Risco de colisão (dos mapas) | Isolação que o cockpit impõe |
|------|:-------------------:|----------------------------|-------------------------|------------------------------|------------------------------|
| **nfideia** | **NÃO** (só preview único do editor Lovable, atrelado a main; `qa-readonly.yml` dá screenshots em PR como artefato de CI, não URL navegável) | push-to-main NÃO publica; **clique humano Update→Publish**; cadeia `feat/*→PR→merge main→Update→Publish` | Edge Functions via `supabase functions deploy --project-ref pdljyfyyxufkqejncccv` (CLI, independente do main); Cloud Run proxy-mtls = botão Redeploy em Admin→Status; `lovable-rebuild-trigger.yml` é MANUAL (auto-disparo desativado 2026-06-04 — commit de bot deixava Update cinza) | ALTO na publicação (1 alvo serializado por main + clique único); baixo-médio no código. Lovable commita direto em main como `gpt-engineer-app[bot]` → atropela arquivos editados em paralelo | **fila de Publish** (verbo `deploy` gated, admin+step-up) + **file_claim** (R-COORD5) p/ não editar arquivo que a Lovable também edita; backend `supabase functions deploy` = verbo `deploy` **separado**, per-projeto |
| **cfoai-grupori** | **NÃO** (Lovable só sincroniza/preview `main`; feat/* não entra — CLAUDE.md regra 8) | sync em 2 estágios: push/merge main SINCRONIZA o editor; **Publish MANUAL** publica o estado de main inteiro | Edge functions + migrations aplicam no **sync de main globalmente** (uma migration de B entra no Publish de A); `ci.yml` = só Test+Lint (lint `continue-on-error`), sem build/deploy | ALTO no deploy (1 editor/1 estado publicável; migration de B vai junto no Publish de A; autosync + main não-protegida = push concorrente) | **fila de Publish serializada** + **claim de migration/edge** (área backend) — duas migrations concorrentes precisam de claim, pois aplicam no MESMO banco no sync de main |
| **ideiapartner** | **NÃO** (sem PaaS com preview-env; `.env` RASTREADO no git é estado GLOBAL de build que o sandbox Lovable lê a cada deploy — `git rm --cached .env` derrubou prod 2026-06-13; "Lovable sem git" — hash em prod é aleatório) | push origin/main (auto-sync Lovable é PARCIAL/oportunista) → **Update/Publish manual** | ~100 Edge Functions deployadas pela Lovable Cloud; **Supabase/Lovable Cloud é UM project_id COMPARTILHADO** (jtsevyeoymefkcrydhcg) → migrations/edge de 2 devs no MESMO banco de produção, sem ambiente por-branch | MÉDIO-ALTO no estado publicado; baixo no fonte. Backend compartilhado é o risco real: colisão de schema/edge sem ambiente intermediário | **fila de Publish** + **alerta forte de claim em `supabase/migrations` e `supabase/functions`** (backend compartilhado é a superfície mais perigosa); o `.env` rastreado entra em **file_claim de alto peso** (editar VITE_* afeta o build de todos) |
| **lapidai** | **NÃO** (1 ambiente preview/prod ligado a main; CI `ci.yml`/`e2e.yml` não publica) | push main só SINCRONIZA; **Publish MANUAL** sobre a main; Claude/Cursor não clicam (ação humana) | Edge functions/migrations via Lovable Cloud (sem CLI direto neste repo); project_id suzztzorxqurzqgquptc | ALTO p/ concern #1. "Update cinza": autosync/Actions empurrando commit de bot como HEAD da main travam o Publish de TODOS (documentado). Autosync auto-pusha branch `work` — 2 estações na mesma conta → autosync concorrente na mesma branch | **fila de Publish** + **guarda anti-"Update cinza"** (o cockpit serializa para não deixar commit de bot virar HEAD da main entre o sync e o Publish) + claim de arquivo |

### 6.2 A doutrina de não-colisão (comum, fundamentada)

1. **Código:** branches feat/* próprias isolam o trabalho no GitHub (Git isola). Isso já funciona nos 4.
2. **Arquivo:** branch NÃO previne dois devs editando `foo.ts` (colidem no merge). → **`file_claim` soft-lock** (R-COORD5): claim advisory por arquivo/área, visível no cockpit, **alerta na sobreposição**. Mata a maioria das colisões antes do commit. Inclui o caso especial **"não editar o mesmo arquivo que a Lovable edita"** (CLAUDE.md dos 4 repos).
3. **Deploy frontend:** há **UM alvo serializado por main + clique humano único**. → **fila de Publish**: o verbo `deploy` é gated (alavanca Reserva-de-poder: admin + step-up); o cockpit serializa "quem publica o estado de main agora", e exibe o que está prestes a ir ao ar (o estado de main, não "a feature do dev X"). Quem clica Publish publica **todo** o main.
4. **Deploy backend:** é **separado** do frontend e **per-projeto** — Edge Functions (CLI `supabase functions deploy` em nfideia; via Lovable Cloud nos demais), migrations (sync de main em cfoai; UI Lovable em nfideia), Cloud Run (Redeploy em nfideia). O cockpit gateia cada um como verbo `deploy` distinto. **ideiapartner/cfoai compartilham 1 project_id Supabase** → claim de `migrations`/`functions` é obrigatório (backend de produção compartilhado, sem ambiente por-branch).
5. **`main` não-protegida (os 4):** o cockpit é a única camada de serialização possível, mas **advisory** — não há enforcement no servidor GitHub (403 Pro). O design declara isso honestamente (ver §10): a serialização do Publish + claims **reduz** colisão, não a **impede** tecnicamente enquanto não houver branch protection real.

> **Quem mora o quadro de claims (fork doc 82 §3):** recomendação = **fonte no projeto-alvo** (`.planning/`/handoff do repo — onde o GSD e o "plano maior" já vivem), **espelho em P3** para visibilidade web (coerente com "git-as-bus espinha, P3 cache"). O claim é metadata; flui pelo ref `cockpit` (P2) e P3 reflete.

---

## 7. Diagrama ASCII dos planos (plataforma de time)

```
  ┌──────── ESTAÇÃO do DEV (joao) — P0/P1 LOCAL ────────┐   ┌── ESTAÇÃO ADMIN (CTO) — P0/P1 LOCAL ──┐
  │ P0: keychain (tokens OAuth do joao — PILAR B/VALOR) │   │ P0: keychain · lista pinada AUTORITATIVA│
  │ P1 agentd:                                          │   │ P1 agentd:                              │
  │  • enrollment → hash {machine_id,fpr,enc} PENDENTE  │   │  • APROVA estação (re-pin LOCAL)        │
  │  • git user.email = joao@ideiabusiness (PILAR A)    │   │  • assina verbos de RESERVA-DE-PODER     │
  │  • OAuth local → token → keychain (NUNCA ao cloud)  │   │  • revoga estação (re-pin out-of-band)   │
  │  • verify-payload (pin local, fail-closed)          │   └────────────────┬───────────────────────┘
  └───────────────────┬─────────────────────────────────┘                    │
        snapshot/claim │ metadata-only (Zero-Leak)              re-pin/aprovação│ (OUT-OF-BAND, nunca pelo ref)
  ════════════════════╪══════ FRONTEIRA-PISO (nenhum VALOR/CHAVE cruza) ═══════╪═══════════════════
                      ▼                                                        ▼ (pin é LOCAL)
  ┌──────────────────────────────────────────────────────────────────────────────────────┐
  │ P2 BUS GIT — ref `cockpit` (snapshots por machine_id + CLAIMS) + ref de comando SELADO │ ← origin/GitHub (semi-confiável)
  └───────────────────────────────┬──────────────────────────────────────────────────────┘
                  push direto (read-fan-out, função autenticada-O2 + Zero-Leak)
                                  ▼
  ┌───────────────────────────────────────────────┐        ┌──────────────────────────────┐
  │ P3 PLANO DE VIEW (Supabase xdikjg…) — metadata │        │ P4 STEP-UP (Supabase SEPARADO)│
  │  read-fan-out: machine·project·api_key(s/value)│        │  email-OTP HYBRID → payload_  │
  │  + console_user · user_project_scope (AUTORIZ.) │        │  hash (comprovante assinado)  │
  │  + station_enrollment (ADMISSÃO: PEND/APROV)   │        └───────────┬──────────────────┘
  │  + provider_link (VÍNCULO — PILAR B, s/ value) │                    │ comprovante alimenta a
  │  + task_claim · file_claim (COORDENAÇÃO)       │                    │ assinatura O2 na ORIGEM
  │  RLS deny-all + RBAC-leitura + escopo/projeto  │                    │ (UI LOCAL/loopback p/ write)
  └───────────────────────────────┬───────────────┘                    │
                  SELECT (anon-key+RLS)                                 │
                                  ▼                                     │
  ┌───────────────────────────────────────────────┐                    │
  │ P5 UI WEB (cockpit.ideiabusiness.com.br)       │ ──intenção─────────┘
  │  • cockpit-ADMIN: fila admissão, escopo, fila  │   (referenciada-por-nome,
  │    de Publish, telemetria→Vault                │    zero valor, zero comando;
  │  • cockpit-OPERADOR (dev): onboarding dinâmico,│    write-path só da UI LOCAL)
  │    saúde da estação, quadro de claims          │
  └────────────────────────────────────────────────┘
       │ telemetria por-usuário (PILAR A: autor-do-commit)
       ▼
  ┌──────────────────────┐
  │ VAULT OBSIDIAN        │  ← alavanca VISÃO + concern #2 (relatório por-usuário)
  └──────────────────────┘
```

---

## 8. O que reusa do já-construído (No Invention)

| Capacidade da plataforma de time | Reusa intacto | Novo (mínimo) |
|----------------------------------|----------------|----------------|
| Admissão (hash→PENDENTE→aprova) | `pinned-keys.sh` (19/19), enrollment ADR O2 | UI de fila de aprovação; `station_enrollment` em P3 |
| Autorização (escopo) | RBAC-leitura `30-security` §5.2, `user_project_scope` (doc 80 §5) | papel `techlead`; UI de atribuição |
| Reserva de poder | step-up HYBRID (ADR Q3), R-WP10/R-WP11, `sign/verify-payload.sh` | gate do clique Publish (interceptação) |
| Visão → Vault | `commit_log.actor_class` (doc 40 §6), read-fan-out (doc 80), snapshot | relatório por-usuário; sink Vault |
| Reversão | FRONTEIRA-DE-PIN (exit 9), re-pin local | UI de revogação (espelho P3) |
| Pilar A (autor-do-commit) | `git user.email` config; `commit_log` | passo de enrollment grava identidade-cockpit no git local |
| Pilar B (vínculo vs valor) | keychain local, `gh`/Cursor/Claude OAuth-local, `provider_link` s/ value | fluxo de vínculo idempotente no agentd |
| Concern #1 (branch/deploy) | ref `cockpit`, P2 bus, `file_claim`/`task_claim` (R-COORD5) | fila de Publish; claims espelhados em P3 |
| Onboarding dinâmico | snapshot de saúde (R-COORD2), `read.js` local | guia idempotente re-entrante (P5) |

**Vetos-de-design (estende doc 80 §8 — a UI de time NÃO os afrouxa):** P3 segura valor de segredo? assina? pina? abre verbo? P3==P4? a UI decide autoridade só pela view? a função de ingestão aceita payload não-assinado? **+ NOVOS:** `provider_link` tem coluna de valor de token? a aprovação de estação muta o pin a partir de P3 (em vez de re-pin local)? um claim em P3 vira hard-lock que bloqueia o git? — **qualquer SIM é veto.**

---

## 9. Faseamento gated

| Fase | Entrega | Gated por |
|------|---------|-----------|
| **F0 — Step-up (P4)** | bootstrap B3-HYBRID do `ideiaos-cockpit-stepup` (send-otp/verify-otp + binding payload_hash + as 8 condições) | é o **primeiro tijolo** (doc 80 §6); não depende dos must-fix do v15 |
| **F1 — View + Autorização + Admissão (read)** | P3 read-fan-out + `console_user`/`user_project_scope`/`station_enrollment`; cockpit-admin (fila de admissão, escopo) e cockpit-operador (saúde R-COORD2). Estreia ADVISORY (P3 ao lado do `read.js` local, 1 ciclo SOAK) | **4 must-fix do v15 ADR** aplicados (ingestão menor-privilégio, RLS por-campo, R-WP12 SHALL, step-up só-loopback) |
| **F2 — Pilar A + Pilar B (enrollment completo)** | agentd grava identidade-cockpit no git local; fluxo de vínculo OAuth idempotente; `provider_link`; onboarding dinâmico R-COORD1 | F1 estável; Pilar B verificado por exit-code (OAuth-local não vaza valor a P3) |
| **F3 — Coordenação (claims)** | `task_claim`/`file_claim` (R-COORD3/4/5); quadro de claims; soft-lock advisory com alerta de sobreposição | F2; fonte-no-projeto + espelho-P3 |
| **F4 — Reserva de poder (write gated)** | fila de Publish (verbo `deploy` interceptado, admin+step-up+O4); rotate same-machine; reversão | **R-WP10**: ADR O2 + step-up + Q5 cravados E bootstrap verificado por exit-code. Cross-máquina só após Q1-Q3. |
| **F5 — Visão → Vault + DEV Tasks (futuro)** | relatório por-usuário ao Vault; orquestrador DEV consome claims p/ paralelizar sem colidir (doc 82 §"DEV Tasks") | F3+F4; `enforce-simplicity` (medir antes de automatizar) |

**Espírito SOAK:** aditivo, faseável, reversível. F1 é reversível (remover P3 = git-as-bus puro). A irreversibilidade real está em F4 (write-path cross-máquina) e fica gated por R-WP10.

---

## 10. Superfícies novas de segurança (para a fase de verificação)

A plataforma de time **agrava** superfícies do v15 e **introduz** novas. Para o `@security-reviewer` (STRIDE + OWASP LLM Top 10) e o `security-freshness` (todas crítica=3 salvo nota):

1. **Multi-tenant em P3 (RLS por-usuário, não só por-papel).** Com N devs, o RLS tem de isolar por `user_project_scope` real — um `dev` lendo recon de projeto fora do escopo é vazamento (must-fix #2 do v15: mascarar nomes `risk_tier=critical`, cadência de rotação não-exposta a `dev`). **STRIDE-I.**
2. **`provider_link` — nova tabela com tentação de guardar valor.** É a superfície onde o Pilar B pode regredir. Veto explícito: sem coluna de valor; o token nunca sai do keychain local. **STRIDE-I / credential-isolation.**
3. **Enrollment de N estações (TOFU em escala).** Cada nova estação é um 1º-contato; o admin tem de comparar fingerprint out-of-band **por estação**. Phishing de enrollment (estação envenenada no 1º pin) é o residual Q1 — agora multiplicado por N devs. **STRIDE-S.**
4. **OAuth-local conduzido pelo agentd (Pilar B).** O agentd ganha a capacidade de conduzir handshakes OAuth e gravar no keychain — Excessive Agency potencial (OWASP LLM06). Conjunto fechado de provedores; sem `exec` arbitrário; janela de privilégio com teardown (R-WP4). **STRIDE-E.**
5. **Sessão web de dev roubada (P5 remoto).** Dá ver-metadata-do-escopo + emitir intenção autorizada-pelo-RBAC-do-subject. NÃO dá valor de segredo (nunca no DOM) nem comando crítico (step-up O2 local que a sessão sozinha não satisfaz). **STRIDE-S/E — contido por construção.**
6. **Fila de Publish como ponto de coordenação privilegiado.** Quem controla a fila influencia o que vai a produção (em `main` não-protegida, sem enforcement servidor). Tem de ser admin+step-up; e é **advisory** (não impede push direto a main — limite honesto). **STRIDE-T/E.**
7. **`main` sem branch protection (os 4 repos, 403 Pro) é superfície herdada.** O cockpit serializa advisory, mas não há required-PR-review/required-checks no servidor. Declarar: a não-colisão de deploy depende de disciplina + serialização do cockpit, **não** de garantia técnica do GitHub. **STRIDE-T.**
8. **`claim` em P3 não pode virar autoridade.** Soft-lock advisory; um claim NUNCA bloqueia o git nem vira gate de execução (seria a UI/P3 tomando decisão de autoridade — veto doc 80 §8). **STRIDE-E.**
9. **Backend Supabase compartilhado (ideiapartner/cfoai, 1 project_id cada).** Migrations/edge de 2 devs no MESMO banco de produção sem ambiente por-branch — colisão de schema é risco real; claim de `migrations`/`functions` é mitigação parcial, não isolamento. **STRIDE-T/D.**

---

## 11. Forks abertos (do operador) — para `/grelha`

1. **Papel `techlead`:** admin pleno (= CTO) ou admin-restrito (aprova estação/escopo mas NÃO rotaciona `critical`/deploy sem CTO)? Recomendação: **admin pleno no MVP**, restrição por-verbo como evolução (enforce-simplicity).
2. **Granularidade do soft-lock (R-COORD5 / doc 82 §3):** por arquivo · por módulo/área · por ambos. Recomendação: **ambos, com alerta** (arquivo pega o caso Lovable; área pega `migrations`/`functions`).
3. **Hard-lock vs soft-lock:** bloquear de fato vs só alertar. Recomendação: **soft/advisory** — visibilidade, não burocracia (e hard-lock no git é inviável sem branch protection servidor de qualquer modo).
4. **Onde mora o quadro de claims:** P3 vs projeto-alvo espelhado em P3. Recomendação: **fonte no projeto-alvo (`.planning`/handoff) + espelho em P3**.
5. **Fila de Publish — manual-serializada vs lock-de-publish:** o cockpit só **mostra** "é a vez de A" (advisory) ou **gateia** o verbo `deploy` por step-up de admin? Recomendação: **gateia o verbo `deploy`** (Reserva-de-poder), e **mostra** a fila — mas reconhecer que, em `main` não-protegida, a serialização não impede push direto.
6. **Projeto Lovable por-dev/feature (alternativa estrutural ao concern #1):** vale provisionar um projeto Lovable separado por feature para dar preview-isolado, em vez de serializar o Publish? Recomendação: **não no MVP** (custo/proliferação de projetos Supabase+Lovable); serialização + claims primeiro, medir a dor.
7. **Numeração do milestone:** v15 (expandir o ADR de read-fan-out para plataforma de time) vs novo v16. Recomendação: **expandir v15** (mesma família split-plane; a plataforma de time é a aplicação multi-ator do read-fan-out).

---

## 12. Rastreabilidade

- **Estende:** `docs/ideiaos-console/80-split-plane-control-plane-DESIGN.md` (planos P0..P5, vetos, blast-radius).
- **Tece:** `docs/ideiaos-console/82-team-coordination-onboarding-requirements.md` (R-COORD1..R-COORD5).
- **Preserva intacto:** `v14.4-origin-auth-signing-mechanism.md` (O2/Admissão/Reversão), `v14.4-step-up-without-relying-party.md` (step-up HYBRID/Reserva-de-poder), `v14.4-command-ref-origin-exposure.md` (Q5/selo).
- **Design existente:** `30-security-credential-isolation.md` (RLS/RBAC, Pilar B), `40-data-model-telemetry-mesh.md` (read-model, `commit_log.actor_class`, Pilar A).
- **Contrato vivo:** `specs/cockpit/spec.md` (R-WP1..R-WP11 preservados; R-WP12 do v15; a plataforma de time pede novos requisitos de Admissão/Autorização/Vínculo/Claim — a registrar em `/spec`).
- **ADR-sucessor a expandir:** `docs/decisions/v15-cockpit-split-plane-control-plane.md` (DRAFT) — ver guidance de escopo.
- **Rules-piso:** `credential-isolation`, `agent-authority`, `security-freshness`, `antifragile-gates`, `mcp-hygiene`, `delta-spec`, `ubiquitous-language`, `operating-discipline`.
