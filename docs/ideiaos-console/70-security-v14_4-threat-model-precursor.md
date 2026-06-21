# 70 — Threat-Model PRECURSOR · v14.4 (Comando Cross-Máquina + Mutação de Produção)

> **Documento 70 · PRECURSOR do threat-model formal · AppSec / Security Architect**
> **Status:** PROPOSTO — esqueleto do futuro `/spec` de segurança da v14.4. **Zero código.**
> **Data:** 2026-06-20 · **Branch:** `work` · **Criticidade: MÁXIMA.**
> **Escopo:** SÓ o **write-path** da v14.4 (comando cross-máquina + `rotate`/`revoke`/`deploy`). O read-path da v14.0–v14.3 está coberto em `30-security-credential-isolation.md` e **não** é reaberto aqui.
> **Não-é:** o threat-model final. É o **andaime honesto** que separa o RESOLVIDO do ABERTO, para que o `/spec` formal saiba exatamente o que precisa cravar antes de uma linha de código.

---

## 0. Por que este documento existe (a tese da v14.4)

A v14.1–v14.3 fecharam as 6 brechas da crítica adversarial **eliminando a necessidade**: não há arquivo de comando no working tree (nada a sequestrar), o `agentd` não possui segredo, e nenhum verbo muta produção. A defesa é **estrutural**, não disciplinar.

A v14.4 **reabre todas elas de propósito**. Ela aprova (em princípio, `D3` do blueprint) três mudanças que cada uma, isolada, é catastrófica — e juntas se multiplicam:

1. **Comando cross-máquina** — uma máquina manda outra fazer algo. O `agentd` deixa de ser coletor read-only e vira **executor com posse de segredo**.
2. **Mutação de produção** — `rotate`/`revoke`/`deploy` são **RCE-equivalentes** sobre 4 bancos Supabase, Vercel, Railway e a org GitHub inteira.
3. **Fila propagada por git** — o canal de comando passa a viajar pelo mesmo bus (git) que o `git-autosync` faz `git add -A` + push **cego** a cada ~900s.

> **Frase-âncora desta fase:** comprometer o `ideiaos-agentd` da v14.4 = comprometer **TUDO**. Ele é a "chave do reino" (§1.1 do doc 30 já o classificava CRÍTICO antes mesmo de poder mutar). Logo o ônus da prova se inverte: **nada entra no allowlist write até o threat-model formal provar que a mitigação é estrutural, não uma promessa de disciplina.**

**Surface assumptions (corrija-me agora — ver `operating-discipline` §1):**

- **A1** — A v14.4 quer comandar a partir do MacBook uma rotação que executa no Mac mini (e vice-versa). Cross-máquina = N≥2 hosts, **não** loopback. *(Se o real for "sempre o operador na máquina-alvo", metade deste doc é over-engineering — confirme.)*
- **A2** — O canal cross-máquina é **git por ref** (o `cockpit`/`mission-control`), porque é o único bus que já federa sem backend novo. *(Se houver apetite por SSH direto host↔host fora do git, o modelo de ameaça muda — ver §2.)*
- **A3** — O operador hoje é **1** (`gustavo@`). O RBAC `cto`/`dev` é **provisão para o segundo ator** (`desenvolvimento@`), não necessidade atual. Construir RBAC pesado para 1 operador em loopback seria o anti-padrão que a crítica `C4` já pegou.
- **A4** — Estado de **SSH/GPG commit-signing NÃO foi verificado** nesta sessão (comando negado por permissão). O doc trata signing como **capacidade a confirmar**, nunca como dado. Se já houver `commit.gpgsign=true` + `gpg.format=ssh`, a opção O2 de §2 ganha tração imediata; se não, é trabalho de bootstrap.

---

## 1. O fluxo sob análise (o que muda em relação ao read-path)

```
┌── MÁQUINA-ORIGEM (onde o operador clica) ──────────────────────────────┐
│  Browser 127.0.0.1 (NÃO-CONFIÁVEL)                                      │
│     │ intenção: {action:"rotate", ref:"VERCEL_TOKEN", scope:"nfideia", │
│     │            target_machine:"<sha-mini>"}  ← zero valor de segredo  │
│     ▼                                                                   │
│  agentd-ORIGEM ── enfileira comando no ref git `cockpit` ───────────┐   │
└──────────────────────────────────────────────────────────────────┼───┘
                  git-autosync push do ref (~900s) · ⚠️ MESMO BUS    │
                  que faz `git add -A` cego em branch não-main       │
                                                                     ▼
┌── MÁQUINA-ALVO (Mac mini) ─────────────────────────────────────────────┐
│  agentd-ALVO ── lê o comando do ref ── DECIDE executar?                 │
│     │  ❓ QUEM pediu? (não há sessão autenticada — só um commit num ref)│
│     │  ❓ o comando é AUTÊNTICO ou plantado? (sha256≠assinatura)        │
│     ▼                                                                   │
│  resolve $VERCEL_TOKEN do keychain ── chama API Vercel SERVER-SIDE ─────│
│     │  novo valor grava de volta no keychain · NUNCA sobe ao browser    │
│     ▼  grava resultado (metadado) no ledger + no ref de volta           │
└────────────────────────────────────────────────────────────────────────┘
```

**As 3 brechas que a v14.1 fechara e a v14.4 reabre** (rastreabilidade com o doc 00 §5):

| Brecha (SH#) | Como a v14.1 fechou | Como a v14.4 a REABRE |
|--------------|---------------------|------------------------|
| **SH1** command-queue capturada pelo autosync | não existia fila no working tree | agora **existe** fila (no ref) — e o autosync toca o mesmo bus |
| **SH2** chave de assinatura sem home | não havia comando-via-arquivo a assinar | agora **é preciso** autenticar comando entre máquinas |
| **SH3/SH4** `agentd` com posse + `rotate/deploy` = RCE | `agentd` não resolvia segredo | agora **resolve** e **muta produção** |

Este doc ataca essas três reaberturas. As demais (SH5 envsync, SH6 injection) continuam como no doc 30, com o adendo de §7/§8 abaixo.

---

## 2. STRIDE completo sobre o fluxo de comando cross-máquina

Vetor concreto **neste substrato** (git-as-bus + autosync cego + agentd com keychain), não STRIDE genérico de livro.

### S — Spoofing (falsificação de identidade)

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| Qualquer processo local que possa `git commit` no ref `cockpit` se passa pelo agentd-origem e injeta um comando de rotação | Só o agentd escreve o ref via plumbing (`update-ref`), mas **o ref é só-append por convenção, não por enforcement** — qualquer `git` na máquina escreve nele. Precisa de **assinatura por-máquina** (§2-bis) para a máquina-alvo distinguir comando legítimo de plantado. | **❌ ABERTO** — é o núcleo do problema da assinatura |
| Atacante com acesso ao `origin` (GitHub) faz push de um ref `cockpit` forjado | O `origin` é um terceiro semi-confiável (GitHub). Um comando que chega via `git fetch` do origin **não tem prova de origem** sem assinatura verificável fim-a-fim. mTLS não ajuda: o transporte é git/HTTPS para o GitHub, não host↔host. | **❌ ABERTO** |
| Commit-fantasma do autosync (`wip: autosync`, autor `@*.local`) é confundido com comando | Classificador determinístico de ator (doc 00 §9) separa autosync de humano **para métrica** — mas isso é heurística de string, **não** autenticação. Não pode autorizar execução. | **⚠️ PARCIAL** — bom p/ analytics, inútil p/ authz |

### T — Tampering (adulteração)

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| `git add -A` do autosync captura um arquivo de comando deixado no working tree e o propaga sem autorização | **Comando NUNCA no working tree** — vai no ref via `update-ref`, igual ao `memory-export.sh` (verificado: `commit-tree`→`update-ref refs/heads/planning`). O autosync só dá `push` do ref se estiver à frente. | **✅ FECHADO** estruturalmente (herda da v14.1) |
| Adulterar o comando em trânsito: `rotate VERCEL` vira `revoke SERVICE_ROLE` | Exige **integridade verificável** do payload. `sha256` do conteúdo **não basta** (atacante recomputa o hash). Precisa de assinatura sobre o payload (§2-bis). | **❌ ABERTO** |
| Reescrever o ledger `console-audit.log` para apagar uma ação | Append-only com encadeamento de hash (`prev_hash`), commitado (doc 30 §7). Reescrita quebra a cadeia → detectável. **Mas detecção ≠ prevenção** — um atacante com write no repo reescreve e o próximo verificador acusa, sem desfazer a ação já executada. | **⚠️ PARCIAL** — detecta, não previne |

### R — Repudiation (repúdio)

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| "Eu não mandei rotacionar a SERVICE_ROLE do nfideia" | Ledger registra `subject|role|action|ref|scope|result|prev_hash`. **Mas** sem assinatura de comando, o `subject` no ledger é **auto-declarado pela origem** — repudiável. Só vira não-repudiável se o comando for **assinado pela chave da máquina-origem** e a assinatura for gravada no ledger. | **⚠️ PARCIAL** — depende de §2-bis |
| Quem aprovou o deploy de produção? | Step-up auth (§4) carimba a aprovação **na máquina-origem**. O problema: essa prova precisa **viajar com o comando** até o alvo — e a sessão do browser não chega ao agentd remoto (§3). | **❌ ABERTO** |

### I — Information Disclosure (vazamento) — **a ameaça-mãe**

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| O comando que viaja no ref carrega o **valor** do novo segredo (na rotação) | **PROIBIDO por invariante.** O novo valor é gerado **no alvo**, gravado no keychain do alvo, **nunca** trafega no ref nem volta à origem. A origem só recebe metadado (`new_age=0`, `new_id`). É a regra-piso `credential-isolation` aplicada ao write-path. | **✅ FECHADO** por design (gate de release) |
| O comando vaza o **nome+escopo** da credencial crítica para o histórico git do `origin` (GitHub, terceiro) | Nome de var já é visível no recon — não é segredo. **Mas** um histórico de "quem rotacionou o quê quando" no GitHub é metadado sensível de superfície de ataque. Mitigação: ref `cockpit` é **órfão e squashed a cada 30d** (doc 00 §5); avaliar se o `origin` deve sequer receber o ref de comando ou só o de telemetria. | **⚠️ ABERTO** — separar ref-de-telemetria de ref-de-comando? |
| Log do agentd grava o valor resolvido do keychain durante a rotação | CSP de logging: valores resolvidos nunca passam por `logger`. **Gate testável** (regex de segredo no log → falha), igual à auditoria do envsync (doc 30 §4-I). | **✅ FECHÁVEL** com gate (não suposição) |

### D — Denial of Service

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| Flood de comandos de rotação no ref derruba os 4 bancos de produção simultaneamente | Rate-limit por `ref`+`subject` no agentd-alvo; rotação de `critical` exige confirmação dupla. **Mas** se a autenticação do comando (§2-bis) não existe, o rate-limit protege contra acidente, não contra atacante autenticado. | **⚠️ PARCIAL** |
| Comando malicioso pede `revoke` em massa (revoga todos os tokens → ecossistema offline) | `revoke` em massa é exatamente o tipo de verbo que **não deve entrar no allowlist v14.4** sem dupla-confirmação out-of-band (§6). | **⚠️ depende do allowlist** |
| Autosync morre → comando nunca chega ao alvo → operador acha que executou | A Frota mostra 🔴 por idade do ref (doc 00 §11). Comando deve ser **idempotente + com ACK no ledger**: sem ACK do alvo, a origem mostra "PENDENTE", nunca "FEITO". | **✅ FECHÁVEL** (precisa de protocolo de ACK no design) |

### E — Elevation of Privilege

| Vetor concreto | Mitigação proposta | Resolvido? |
|----------------|--------------------|:---------:|
| `dev` (RBAC limitado) emite comando que o agentd-alvo executa como `critical` | RBAC **fail-closed** no agentd-alvo, não só no browser-origem. **Problema:** o agentd-alvo precisa **verificar o papel do emissor** — e o papel viaja no comando, que é auto-declarado sem assinatura. Sem §2-bis, o RBAC é teatro: o emissor declara `role:cto` e o alvo acredita. | **❌ ABERTO** — RBAC sem assinatura é falsificável |
| Agentd com posse de segredo + injeção via tool-description MCP escala para rotação arbitrária | Conjunto fechado de verbos tipados, sem `exec` arbitrário; retornos MCP envelopados como DADO (doc 30 §6). | **✅ FECHADO** por design |
| `agentd` resolve um segredo de escopo maior do que o comando exige (Excessive Agency) | Janela de privilégio por-ação que abre só o segredo do escopo exato (§5 + §7). | **✅ FECHÁVEL** (precisa do design da janela) |

---

## 2-bis. O PROBLEMA DA ASSINATURA / IDENTIDADE (o crítico estava certo)

> **A crítica:** "sha256 do conteúdo ≠ assinatura". Correto e decisivo. `sha256` é **checksum de integridade contra corrupção**, não prova de **origem**: qualquer um que possa escrever o conteúdo recomputa o hash. Um comando que diz `{action:rotate, role:cto}` com um sha256 válido prova apenas que o conteúdo não corrompeu — **não** que veio de quem diz ter vindo.

O problema central da v14.4: **como a máquina-A autoriza um comando para a máquina-B SEM (a) um segredo transitar pelo contexto do LLM/browser E SEM (b) o autosync sequestrar o material?**

### Opções avaliadas — honestamente, qual resolve e qual não

| # | Opção | Mecanismo | Resolve? | Veredito |
|---|-------|-----------|:--------:|----------|
| **O1** | **`sha256` do payload** | hash do conteúdo no ref | **NÃO** | É o que o crítico rejeitou. Integridade ≠ autenticidade. **Descartado como autorização.** Útil só p/ dedup (igual `input_hash` do context-packet). |
| **O2** | **Chave por-máquina no keychain assina o ref / o commit** | cada agentd tem um par de chaves; a privada vive no **keychain do SO** (resolvida server-side, **nunca** no contexto do LLM/browser — satisfaz `credential-isolation`); assina o payload; a pública de cada máquina é distribuída e fixada (TOFU + pin). O alvo verifica a assinatura antes de executar. | **SIM** (a mais viável) | **VIÁVEL e recomendada.** A chave privada nunca trafega; só a assinatura viaja no ref; o autosync não tem o que sequestrar (assinatura ≠ segredo). É o análogo exato do "keychain resolve server-side" que o doc 30 já adota para tokens de provedor. **Custo:** gerir distribuição/rotação/revogação das chaves públicas por-máquina (um mini-PKI de N=2 hosts). |
| **O3** | **SSH-signed commits/tags via git** | `git commit -S` / `git tag -s` com chave SSH; `gpg.ssh.allowedSignersFile` lista as chaves de máquina autorizadas; o alvo roda `git verify-commit`/`verify-tag` | **SIM** (se a infra existir) | **VIÁVEL** e elegante: reusa o próprio git como transporte da assinatura, `git verify-*` é o verificador. **Mas** o comando vai num **ref órfão escrito por plumbing** (`update-ref`), e `commit-tree` **não assina** por padrão — é preciso assinar explicitamente o objeto. **Estado de signing NÃO verificado nesta máquina (A4)** → é capacidade a bootstrapar, não dado. Converge com O2 (a chave SSH de máquina É a chave por-máquina). |
| **O4** | **Canal fora-de-banda (out-of-band)** | a aprovação de uma ação `critical` exige um segundo fator que **não** viaja pelo git: push-notification para o device do operador, ou confirmação manual na máquina-alvo | **SIM, para o subconjunto crítico** | **VIÁVEL como defesa-em-profundidade**, não como mecanismo único. Resolve o repúdio e o EoP do `critical` mesmo se a assinatura falhar, ao custo de fricção. **Recomendado especificamente para `rotate/revoke critical` e `deploy`.** |
| **O5** | **Process-boundary do SO** | "só o agentd local escreve aquele ref" | **NÃO, cross-máquina** | **Só vale LOCAL** (foi a autoridade da v14.1, correta lá). Cross-máquina, o ref atravessa o `origin` (GitHub) e chega via `fetch` — o process-boundary da origem **não** acompanha o dado. **Não resolve a v14.4.** O blueprint já admite isso implicitamente ao dizer que cross-máquina "exigiria signer + RBAC". |
| **O6** | **Backend que assina (HMAC server-side)** | um serviço central assina comandos autorizados por RBAC | **SIM, mas** | A arquitetura **nega** backend cloud (ADR). Um signer precisa de uma chave-mestra — que `credential-isolation` proíbe no contexto e que vira novo SPOF/alvo. **Descartado** por contradizer o local-first; O2 entrega o mesmo sem central. |

### Recomendação de §2-bis

**Combinar O2 + O4, com O3 como implementação concreta de O2 se o signing-git for bootstrapado.**

1. **O2/O3 (assinatura por-máquina)** autentica **todo** comando cross-máquina. Sem assinatura verificável → o agentd-alvo **recusa** (fail-closed). Isto fecha S, o T-em-trânsito e o E-of-P do RBAC de uma vez (o `role` deixa de ser auto-declarado: a assinatura amarra papel↔chave↔máquina).
2. **O4 (out-of-band)** é exigido **adicionalmente** para o tier `critical` e para `deploy`/`revoke` — defesa-em-profundidade contra comprometimento da própria chave de máquina.

**O que continua ABERTO mesmo assim** (para o threat-model formal):
- **Bootstrap de confiança das chaves públicas** (TOFU é vulnerável ao primeiro contato; quem assina a lista de `allowedSigners`?).
- **Rotação/revogação da própria chave de máquina** — se a chave do Mac mini vaza, como a revogo cross-máquina sem um canal já comprometido? (problema clássico de PKI sem CA).
- **Confirmação A4:** signing-git está ligado? Se não, O3 vira trabalho de fase própria antes de qualquer write.

---

## 3. Autenticação do EMISSOR quando o pedido chega como commit (não como sessão)

**O problema, cru:** o step-up auth (§4) acontece no **browser da máquina-origem**. Mas o comando chega ao agentd-alvo como um **commit num ref** — não como uma requisição HTTP autenticada com a sessão. **A sessão do browser nunca alcança o agentd remoto.** Então: como o alvo sabe que um humano `cto` autenticado, e não um processo qualquer, autorizou aquela rotação?

**A cadeia de prova que precisa existir** (e que hoje **não** existe):

```
humano (passkey/Touch ID) ─autentica→ browser-origem
   │  step-up produz um TOKEN DE APROVAÇÃO assinado pela CHAVE DA MÁQUINA-ORIGEM
   │  (binding: subject + role + action + ref + scope + nonce + expiry)
   ▼
agentd-origem assina o comando+aprovação com a chave de máquina (O2/O3)
   │  → escreve no ref `cockpit`
   ▼
agentd-alvo VERIFICA: assinatura de máquina válida? aprovação não-expirada?
                       nonce não-reusado? papel autoriza esta ação neste scope?
   │  TODAS sim → executa.  Qualquer não → recusa + loga.
   ▼
```

**O ponto crítico:** a aprovação do humano (o "touch" da passkey) precisa ser **convertida num artefato verificável que viaja com o comando** — não pode ser uma sessão. Ou seja: o step-up não é "manter sessão", é "**produzir um token de aprovação assinado, de uso único, com expiry curto**", que o agentd-origem encapsula no comando assinado.

**Resolvido vs. aberto:**
- **Resolvível no design:** o token-de-aprovação como artefato assinado de uso único (binding completo + nonce + expiry). É padrão conhecido (capability token).
- **❌ ABERTO:** **onde a passkey assina.** WebAuthn assina um desafio **do relying-party** — e aqui não há RP-server (não há backend). Uma passkey em loopback sem RP é não-trivial. **Alternativa realista:** o step-up local **não** é WebAuthn-do-browser, mas **Touch ID via o agentd-origem** (LocalAuthentication do macOS, server-side, fora do browser) — o browser só **dispara** o pedido; o agentd-origem é quem **colhe** o Touch ID e assina. Isso mantém o segredo de assinatura fora do browser (coerente com `credential-isolation`) e dá um artefato verificável. **Confirmar viabilidade no threat-model formal** (LocalAuthentication + assinatura de máquina no mesmo processo).
- **❌ ABERTO:** **replay entre máquinas.** Nonce precisa de um registro de nonces-vistos no alvo (estado), e o expiry precisa de relógios minimamente sincronizados entre hosts — assimetria de máquina (doc 00 §9) complica.

---

## 4. RBAC mínimo realista (`cto`/`dev`) — só o que o multi-operador exige

**Princípio anti-over-engineering (`enforce-simplicity` + crítica `C4`):** há **1 operador** hoje. RBAC só existe porque a v14.4 abre a porta para `desenvolvimento@`. Logo: **dois papéis, fail-closed, escopo binário** — nada de tenancy granular, nada de hierarquia de roles, nada de ABAC.

| Capacidade (write-path v14.4) | `cto` | `dev` |
|-------------------------------|:-----:|:-----:|
| Ver metadados (herdado read-path) | ✅ | ✅ (projetos atribuídos) |
| Comando **local** reversível (autosync-pause, idea-doctor) | ✅ | ✅ |
| Comando **cross-máquina** read-only (forçar re-coleta) | ✅ | ⚠️ assinado |
| `rotate` credencial `sensível`/`alto` | ✅ (step-up) | ⚠️ step-up + assinado, só scope atribuído |
| `rotate`/`revoke` credencial `crítica` (`SERVICE_ROLE`, senha admin) | ✅ (step-up **+ out-of-band O4**) | ❌ |
| `deploy` de produção | ✅ (step-up + O4) | ❌ (no máx. **gera o comando** p/ @devops, espelha `agent-authority`) |
| Gerir RBAC / adicionar chave de máquina | ✅ | ❌ |
| (Re)configurar MCP / reabilitar Lovable mutante | ❌ **ninguém pelo Cockpit** (ritual `@devops` fora) | ❌ |

**Regras inegociáveis:**
- **Default-deny:** capacidade não-listada para o papel = negada **no agentd-alvo** (não só na UI — UI authz é cosmética e falsificável).
- **O papel é provado por assinatura, não declarado** (§2-bis). Sem isso, esta tabela é decorativa.
- **Escopo por projeto binário** (`próprio`/`atribuído` vs `todos`) — não inventar grafo de permissões para N=1.
- **Espelha `agent-authority`:** `deploy`/`MCP-mgmt` são para humanos o que `git push` é para `@devops` — exclusivos ou ritualizados fora do Cockpit. O Cockpit **não pode virar bypass** da `agent-authority`.

---

## 5. Janela de privilégio temporário **com teardown** (o learning, aplicado)

Cita `temp-privilege-window-teardown-grants`: **uma janela de privilégio para operação irreversível deve conceder as tools do TEARDOWN/cleanup, não só as do trabalho — senão o rollback trava DEPOIS da ação irreversível**, que é o pior momento possível.

**Aplicação concreta à rotação de `VERCEL_TOKEN` do nfideia:**

```
abrir janela(scope = VERCEL_TOKEN@nfideia, ttl = 90s):
  CONCEDE:
    • ler VERCEL_TOKEN atual do keychain          (trabalho)
    • chamar Vercel API: criar novo token          (trabalho)
    • gravar novo token no keychain                (trabalho)
    • ⟵ chamar Vercel API: REVOGAR token antigo    (TEARDOWN — sucesso)
    • ⟵ chamar Vercel API: REVOGAR token novo      (TEARDOWN — rollback se a gravação falhar)
    • ⟵ RESTAURAR token antigo no keychain         (TEARDOWN — rollback)
    • escrever resultado no ledger                 (sempre, dentro da janela)
  NEGA: qualquer outro segredo, qualquer outro escopo, shell arbitrário
fechar janela (mesmo em erro): revogar todos os grants
```

**A falha que o learning previne, encenada:** se a janela conceder só os 3 grants de "trabalho", e a gravação do novo token no keychain falhar **depois** de o token já existir na Vercel, o rollback (revogar o token órfão na Vercel + restaurar o antigo) **fica bloqueado pela própria fronteira** — a janela já não autoriza chamar a API de revogação. Resultado: um token órfão vivo em produção e o sistema sem como limpá-lo. **Por isso os grants de teardown entram na janela desde a abertura**, não são pedidos depois.

**Invariante de design:** **toda janela de privilégio para ação irreversível DEVE enumerar, na abertura, os grants de sucesso E os grants de rollback.** Gate de revisão do `/spec`: nenhuma janela passa sem a coluna "teardown grants" preenchida. Cross-link `antifragile-gates` — o fechamento da janela é verificado por exit-code, não por "parece que fechou".

---

## 6. A fronteira do allowlist — o que NUNCA entra (mesmo na v14.4)

A v14.4 **expande** o allowlist; não o abre. Há verbos que permanecem fora **mesmo com threat-model aprovado**, porque o risco é estrutural, não mitigável por mais autenticação:

| Verbo / capacidade | Por que NUNCA (mesmo v14.4) |
|--------------------|------------------------------|
| **`reveal` / "copiar valor de segredo"** | Violação direta da regra-piso. Não há autenticação que torne aceitável o valor no browser. Se o operador precisa do valor literal, busca na fonte via terminal — fora do Cockpit. |
| **`exec` / shell arbitrário no agentd** | Excessive Agency clássico. O agentd expõe **conjunto fechado tipado**. Um shell remoto autenticado ainda é um shell remoto = a porta que transforma "comprometer o painel" em "comprometer tudo" instantaneamente. |
| **`git push` / `gh pr` a partir do Cockpit** | `@devops`-exclusivo por `agent-authority`. O Cockpit no máximo **gera o comando**. Cross-máquina não cria exceção à autoridade. |
| **(Re)habilitar MCP mutante (Lovable 19-tools)** | `@devops`-exclusivo + a deny-list é o sensor que já regrediu sozinho (5/5→2/5). O Cockpit **audita**, nunca **modifica**. |
| **Rotação/deploy AUTOMÁTICOS (sem ator humano)** | `automate-the-reminder-not-the-integrity-stamp`: automatizar a CONCLUSÃO de uma ação que exige ator real = a automação vira ator sintético e frauda a distinção. O Cockpit **lembra** que a `SERVICE_ROLE` está overdue; **nunca** rotaciona sozinho. |
| **Custódia central de qualquer chave-mestra** | Contradiz o ADR (zero backend) e cria o SPOF que `credential-isolation` proíbe. As chaves de máquina vivem cada uma em seu keychain — não há cofre central. |
| **`revoke` em massa / `rotate` em massa num clique** | DoS estrutural sobre produção. Se algum dia entrar, exige confirmação out-of-band **por alvo**, nunca batch atômico. |

**Princípio da fronteira:** o allowlist write é uma **lista de adição explícita** (default-deny). Um verbo só entra com (a) caso de uso real, (b) mitigação STRIDE estrutural, (c) janela-com-teardown desenhada, (d) entrada no `/spec` aprovada. **Nada entra por blueprint, por conveniência, ou por "já que estamos aqui".**

---

## 7. Least-privilege de posse (OWASP LLM06) — o agentd NUNCA retém o valor

**Tese:** o `agentd` é o componente mais poderoso e portanto o mais contido. Ele **usa** segredo sem **possuí-lo durável** — a posse é uma janela, não um estado.

**Como `rotate`/`deploy` acontecem sem o agentd reter o valor:**

1. **O agentd não tem os valores em memória persistente.** Não há "cache de segredos". Cada ação **resolve sob demanda** dentro da janela (§5) e **descarta** ao fechar.
2. **Preferir invocar a CLI do provedor que lê do keychain ela mesma**, em vez de o agentd ler o valor e repassá-lo:
   - **GitHub:** `gh` já resolve o token do **keyring** internamente (verificado no doc 30: tokens em `(keyring)`, `hosts.yml` sem `oauth_token`). O agentd chama `gh ...` — **nunca lê o token**. O valor jamais entra no processo do agentd.
   - **Vercel/Railway:** se a CLI suportar resolução de token do keychain (`security find-generic-password` server-side dentro da própria invocação), preferir esse caminho. Onde a CLI exige o token via env, o agentd resolve **na borda da invocação** (`VERCEL_TOKEN=$(security ...) vercel ...`) e o valor vive só no env do processo-filho efêmero — nunca num arquivo, log, ou variável durável do agentd.
   - **Supabase `SERVICE_ROLE`:** posse legada em `.env` (doc 30). O agentd lê **na borda** para a chamada de rotação e a re-grava **no keychain** (migração de posse), reduzindo a janela de exposição a cada rotação.
3. **O valor novo (rotação) é gerado e gravado no destino sem nunca subir.** O agentd-alvo cria o novo token via API do provedor, grava no keychain do alvo, e retorna **só metadado** (`new_age=0`, `new_id`, `result`). O valor **nunca** volta à origem nem ao browser.
4. **Pergunta de revisão obrigatória** (do `mcp-hygiene` §Excessive Agency), por capacidade do agentd: *"essa capacidade é necessária para a ação, ou é agência excessiva?"* — se um verbo pode tocar mais segredo do que o scope pede, é cortado.

**O delta da v14.4 sobre o doc 30:** o doc 30 já descreve isto para o read-path; aqui o ponto crítico é que **mesmo possuindo a capacidade de mutar, o agentd nunca acumula valor**. A diferença entre "tem capacidade de rotacionar" e "tem os segredos" é a diferença entre um agente contido e a chave do reino vazada.

**❌ ABERTO:** nem toda CLI de provedor resolve do keychain nativamente — onde não resolve, há uma janela (curta) em que o valor está no env de um processo-filho. O threat-model formal deve **enumerar por provedor** qual caminho existe (CLI-keychain-nativo vs env-na-borda) e tratar o segundo como risco residual aceito-e-documentado, não ignorado.

---

## 8. QUESTÕES ABERTAS — o que o threat-model FORMAL precisa resolver

Listadas explicitamente para **não fingir que está tudo resolvido** (`operating-discipline` §2 e §6). Cada uma bloqueia uma parte do write-path.

| # | Questão aberta | Bloqueia | Severidade |
|---|----------------|----------|:----------:|
| **Q1** | **Bootstrap de confiança das chaves de máquina** (§2-bis): TOFU é vulnerável ao 1º contato; quem assina a lista de `allowedSigners`? Sem CA, como? | toda autenticação cross-máquina | 🔴 CRÍTICA |
| **Q2** | **Revogação da chave de máquina** se um host é comprometido — sem um canal já-confiável, é o problema do galinheiro guardado pela raposa | conter um host comprometido | 🔴 CRÍTICA |
| **Q3** | **Onde a passkey/Touch ID assina sem RP-server** (§3): WebAuthn precisa de relying-party; sem backend, a alternativa LocalAuthentication-via-agentd precisa ser provada viável | step-up auth cross-máquina | 🔴 CRÍTICA |
| **Q4** | **Replay + sincronia de relógio** entre máquinas assimétricas (§3): registro de nonces-vistos + expiry com clocks dessincronizados | integridade do step-up | 🟠 ALTA |
| **Q5** | **Separar ref-de-telemetria de ref-de-comando** (§2 I): o `origin` (GitHub, terceiro) deve sequer ver o ref de comando, ou só o de leitura? | superfície no terceiro | 🟠 ALTA |
| **Q6** | **CLI-por-provedor que resolve do keychain** (§7): enumerar Vercel/Railway/Supabase — quais têm caminho keychain-nativo e quais deixam valor no env-da-borda | least-privilege real | 🟠 ALTA |
| **Q7** | **Estado de signing-git (A4)**: `commit.gpgsign`/`gpg.format=ssh` ligados? Não-verificado nesta sessão. Se off, O3 é trabalho de bootstrap antes de tudo | escolha O2 vs O3 | 🟡 MÉDIA |
| **Q8** | **Protocolo de ACK idempotente** (§2 D): comando sem ACK do alvo = "PENDENTE", nunca "FEITO"; desenhar o handshake sobre um bus eventual (~15min) | honestidade de estado | 🟡 MÉDIA |
| **Q9** | **Detecção ≠ prevenção no ledger** (§2 T/R): o encadeamento de hash detecta reescrita mas não desfaz a ação já executada — aceitar como residual ou endurecer? | não-repúdio | 🟡 MÉDIA |

---

## 9. Veredito do precursor (para o `/spec` formal)

- **✅ Estruturalmente fechado:** comando-fora-do-working-tree (T), valor-de-segredo-nunca-trafega (I), sem-`exec`-arbitrário (E), allowlist default-deny com fronteira explícita (§6), least-privilege-de-posse com keychain-na-borda (§7), janela-com-teardown (§5).
- **❌ Estruturalmente ABERTO e bloqueante:** **autenticação de origem** (Q1/Q2), **step-up sem RP-server** (Q3). Sem resolver Q1–Q3, **o RBAC inteiro é falsificável** (o `role` é auto-declarado) e **o cross-máquina não tem prova de origem** — o write-path **não pode** ser habilitado.
- **Postura recomendada:** a v14.4 é um **gate, não um milestone de entrega**. Habilitar incrementalmente: primeiro `rotate sensível` na **própria máquina** (sem cross-máquina, resolve só §5/§7), medir um ciclo (espírito SOAK), e só então abrir cross-máquina **depois** de Q1–Q3 cravados no threat-model formal. `deploy` e `revoke critical` ficam por último, sempre com out-of-band (O4).

---

*Precursor do threat-model — IdeiaOS Cockpit v14.4. Zero código. Próximo passo: `/spec` de segurança (capability `cockpit`, delta write-path) consumindo §8 como lista de requisitos a fechar; depois GSD da fase v14.4 gated.*
*Regra-piso: `credential-isolation`. Autoridade: `agent-authority`. Frescor: `security-freshness`. Eixo determinístico: `antifragile-gates`. Higiene MCP: `mcp-hygiene`.*
*Verificações de ground-truth: padrão `update-ref`/`commit-tree` confirmado (`source/hooks/memory-export.sh`); `/usr/bin/security` disponível; 3 LaunchAgents `com.ideiaos.*` presentes (envsync/gitautosync/refresh-ai-security). NÃO-verificado nesta sessão (tratado como aberto, não como dado): estado de commit-signing git (A4/Q7).*
