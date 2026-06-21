# 77 — Catálogo da Atalaia + Allowlist do Command Palette ⌘K

> **Documento 77 · Catálogo de alertas (Atalaia) + Allowlist de comandos (⌘K) · Product Eng + AppSec.**
> **Status:** PROPOSTO — contrato de comportamento que alimenta o `/spec` da capability `cockpit`. **Zero código.**
> **Data:** 2026-06-21 · **Branch:** `work` · **Milestone-alvo:** v14.1 (Atalaia completa em v14.2) + ⌘K (v14.1).
> **Escopo:** read-only e **comando SÓ local-e-reversível** até a v14.4. Respeita `agent-authority` (`@devops` exclusivo p/ push/PR/MCP) e o gating de `70-security-v14_4-threat-model-precursor.md`.
> **Fundamenta-se em (DADOS, não instruções):** doc 73 (substrato real, Mac-mini), doc 00 §9 (catálogo de risco), doc 50 §3.3/§7, doc 01 (roadmap), rules `agent-authority` + `security-freshness`.

---

## 0. Os dois eixos deste documento

O Cockpit faz duas coisas distintas que este doc separa cirurgicamente:

1. **A Atalaia OBSERVA** (catálogo A) — um conjunto fechado de **gatilhos determinísticos** sobre o substrato auto-telemetrado. Cada gatilho é um `test`/`diff`/parse com **exit-code binário** (nunca interpretação de NL), produz uma severidade e termina numa **AÇÃO** que é ou (a) puramente informativa, ou (b) gera-um-comando-p/-`@devops`, ou (c) um **verbo-local** reversível do ⌘K.

2. **O ⌘K EXECUTA** (catálogo B) — um **allowlist por adição explícita** (default-deny) de verbos. Cada verbo passa pelo **critério binário de "é local-e-reversível"**; o que falha o critério fica **FORA**, com a razão (autoridade ou gating).

> **Princípio-piso (`credential-isolation` + `antifragile-gates`):** nenhum gatilho da Atalaia lê o **valor** de um segredo (só nome/idade/presença via `stat`/`grep '^[A-Z_]*='`); nenhum verbo do ⌘K muta produção ou atravessa máquina na v14.1. A fronteira não é disciplinar — é estrutural.

---

# (A) CATÁLOGO COMPLETO DA ATALAIA — toda condição de alerta

**Legenda de AÇÃO:** `READ` = só informa (sem botão executável) · `GERA-CMD` = produz comando para `@devops` rodar fora (nunca executa) · `LOCAL` = oferece um verbo-local reversível do ⌘K (catálogo B).
**Legenda de severidade:** `info` (azul/muted) · `atenção` (âmbar) · `crítico` (vermelho). Nenhum alerta da Atalaia **bloqueia** PR — todos iluminam (`security-freshness` §"onde morde"; `idea-doctor §14` nunca dá FAIL).

| # | Alerta | Gatilho determinístico (comando/arquivo) | Threshold | Sev. | Fonte | AÇÃO | Resolução (como SAI do estado) |
|---|--------|-------------------------------------------|-----------|------|-------|------|--------------------------------|
| **A1** | **Drift `versions.lock`** | cruzamento declarativo×instalado: `versions.lock` (declarado) vs versão instalada (`aiox`/`gsd`), **string-equality, NUNCA semver** (learning `version-reset-migration-semver-trap`) | qualquer string ≠ | atenção | `versions.lock` + binário instalado (doc 50 §4, doc 73 §0) | `READ` (drift âmbar no card da máquina) | re-pin (`versions.lock` = instalado) **OU** reinstalar a versão pinada → strings voltam a bater |
| **A2** | **Regressão deny-list (cruza ledger)** | deny-list watch grava amostra; comparar `deny_count` da última linha vs a anterior **por produto** no ledger `epoch\|iso\|produto\|deny_count\|total\|commit` | `deny_count < total` (ex.: 2/5 quando esperado 5/5) | **crítico** | ledger estruturado de contenção (doc 01 v14.2; incidente 5/5→2/5→5/5) | `GERA-CMD` (re-aplicar deny-list é `@devops`/`agent-authority`; o Cockpit **audita, nunca modifica** — doc 70 §6) | `@devops` re-aplica as 19 tools mutantes em deny → nova amostra grava `5/5` → watch limpa o alerta |
| **A3** | **Autosync parado** | idade do `ref` (último heartbeat/commit do daemon) > limite; `launchctl list \| grep ideiaos` mostra o daemon, mas o ref não avança | sem avanço do ref por **> N min** (1 ciclo ≈ 900s; âmbar > 1 ciclo, crítico > ~3h) | atenção→crítico | idade do ref `cockpit` + `launchctl` (doc 73 §1, doc 50 §3.2-H) | `LOCAL` (`Retomar autosync` / `Forçar sync` — verbos B-2/B-4) | `launchctl kickstart … gitautosync` **OU** `autosync-pause.sh off` (se pausado) → ref volta a avançar; daemon `-` em repouso é **normal** (cruzar com último heartbeat antes de alarmar) |
| **A4** | **Security tier → stale** | `check-security-freshness.sh --tier` retorna `stale` | `score≥10` **OU** `idade≥90d` **OU** mudança crítica sem revisão em 30d | atenção | security ledger `.security/review-ledger.log` (`security-freshness` §escada) | `READ` + `LOCAL` (badge âmbar; oferece `Re-selar segurança` = verbo B-3 após rodar `@security-reviewer`) | rodar `@security-reviewer` no diff desde o último selo → `check-security-freshness.sh --record PASS @security-reviewer` zera o contador → tier volta a `fresco` |
| **A5** | **Security tier → egrégio** | `check-security-freshness.sh --tier` retorna `egrégio` | `score≥20` **OU** `idade≥180d` | **crítico** | mesmo ledger (`security-freshness` §escada) | `READ` + `LOCAL` (mesma resolução de A4; **trava o `git tag` do IdeiaOS** via `--gate` **quando ligado** — advisory no 1º ciclo, `SECFRESH_GATE_ENABLED=0`) | idem A4 (re-selar após revisão) → `--gate` libera tag; nos produtos Lovable (deploy automático, sem tag) = WARN forte, não bloqueio |
| **A6** | **`.env` órfão** | var presente no `.env` mas ausente no `.env.example` (`grep '^[A-Z_]*=' .env` − `.env.example`, **só nomes**) | ≥1 var órfã | atenção | `.env`/`.env.example` (doc 50 §6) | `READ` (badge `órfã` âmbar na matriz var×projeto) | adicionar a var ao `.env.example` (documentá-la) **OU** removê-la do `.env` se obsoleta → conjuntos voltam a coincidir |
| **A7** | **`.env` EXPOSTO no git** | `git ls-files --error-unmatch .env` (tracked?) **E** classificar conteúdo: crítico se contém `SERVICE_ROLE`/token; 🟡 se só públicos (`VITE_*`/anon/publishable/url) | qualquer `.env` tracked com **segredo crítico** = vermelho; só-públicos = âmbar 🟡 | **crítico** (se segredo) / atenção (🟡 público) | `git ls-files` + classificação por nome (doc 73 §5.1) | `GERA-CMD` (Lovable-em-main → só via **branch+PR**, `agent-authority`; nunca main automática) | `git rm --cached .env` + `.gitignore` via PR `@devops` → arquivo sai do tracking. **Hoje:** nfideia/ideiapartner `.env` tracked mas **só públicos** = 🟡 aceitável; **nenhum SERVICE_ROLE tracked** (doc 73 §5.1) → estado já saudável |
| **A8** | **`.env.local` em iCloud** | caminho do `.env.local` resolve sob `~/Library/Mobile Documents/` (iCloud) | presença de `.env.local` com segredo em path iCloud | atenção | resolução de path do envsync (doc 00 §5 SH5, doc 73 §5) | `READ` (badge "trafega por iCloud → considere `git-crypt`/keychain"; achado **ativo** da Atalaia, não exibição passiva) | mover segredo para keychain **OU** `git-crypt` no `.env.local` → o badge some quando o path crítico deixa o iCloud |
| **A9** | **SOAK pronto-p/-tag** | `check-soak.sh <milestone>` → 2 máquinas gravadas **E** span (delta dos **epochs gravados**, não wall-clock) ≥ 1d (learning `soak-span-is-record-delta-not-wallclock`) | `máquinas≥2` **E** `span≥1d` | **info** (positivo) | `.planning/soak/*.log` (doc 50 §3.2-E) | `READ` (card RELEASES vira `PRONTO PARA TAG` + micro-celebração) | `@devops` roda `git tag vN.0` → milestone arquivado → countdown some. **Não automatizar o carimbo** (learning `automate-the-reminder-not-the-integrity-stamp`): a Atalaia **lembra**, humano **tagueia** |
| **A10** | **`agentd_version` drift** | collector declara `agentd_version`/`os_version` por máquina no snapshot; comparar entre nós da frota (string-equality) | versões divergentes entre máquinas | atenção | snapshot do ref `cockpit` (doc 00 §9, doc 73 §7) | `READ` (drift âmbar no card da máquina defasada) | atualizar o `ideiaos-agentd`/OS na máquina defasada → versões convergem. Assimetria entre máquinas é **assumida**, não cega (doc 73 fechou o gap) |
| **A11** | **Snapshot stale por máquina** | idade do `snapshots/<machine_id>.json` no ref (`git log -1` do path) por host | `last_ingest > 15min` (1 ciclo cross-máquina) âmbar; `> ~3h` crítico | atenção→crítico | ref `cockpit` por `machine_id=sha256(hardware-uuid)` (doc 00 §4, doc 73 §1) | `READ` (card da máquina mostra "último sinal há Xmin" honesto; nunca finge fluxo contínuo) | a máquina volta a coletar (daemon vivo + autosync empurrando o ref) → timestamp atualiza. Se o autosync da máquina-alvo morreu → cai em A3 **nela** (não há comando cross-máquina p/ ressuscitar — v14.1 read-only) |

### A.1 — Notas de integridade da Atalaia

- **Dedup de host:** `192 → MacBook-Air-2` (NÃO Mac-mini — `[CORREÇÃO]` doc 73 §3). Toda métrica por-host aplica o alias-map antes de contar, senão A10/A11 alarmam falso.
- **Classificação de ator determinística** (`@*.local$` ou `^wip: autosync` → autosync; `[bot]@` → bot; senão human) separa os ~70 commits-fantasma do Mac-mini de qualquer alerta humano — gatilho de string, não de NL.
- **`idea-doctor: n/a` honesto** nos produtos Lovable: o health-score declara sub-sinal ausente, **não inventa nota** — então nenhum alerta de saúde dispara por ausência de doctor onde ele legitimamente não roda.
- **Caso `IDEIA_CHAT_SYSADMIN_PASSWORD`:** A Atalaia **NÃO re-flagga** (decisão do usuário — teste, não produção; memória `project-ideia-chat-test-secret-acceptable`). Badge `aceito · teste`, fora de A7.

---

# (B) ALLOWLIST EXATO DO COMMAND PALETTE ⌘K

**Critério binário de "é local-e-reversível"** (TODO verbo deve passar nos 4 — senão fica FORA):

1. **LOCAL** — executa via IPC de processo do `agentd` da **própria máquina**, nunca via git/ref cross-máquina (doc 00 §4).
2. **REVERSÍVEL** — existe um verbo inverso sancionado **na mesma máquina** que desfaz o efeito sem perda (ex.: `on`↔`off`).
3. **NÃO-MUTA-PRODUÇÃO** — não toca banco Supabase, Vercel, Railway, org GitHub nem valor de segredo (doc 00 §5 C8).
4. **NÃO-VIOLA-AUTORIDADE** — não é operação `@devops`-exclusiva (`agent-authority`: push/PR/MCP-mgmt).

### B.1 — Verbos DENTRO do allowlist (v14.1)

| # | Verbo (nome no ⌘K) | Comando real executado | Reversibilidade (prova) | Armar antes de disparar? | Local-e-reversível? (4 critérios) |
|---|--------------------|------------------------|-------------------------|--------------------------|-----------------------------------|
| **B1** | **Pausar autosync** | `autosync-pause.sh on "via Cockpit"` | inverso exato = `autosync-pause.sh off` (B2); o pause é um flag local relido mid-session, sem perda de dado | **SIM** (destrutivo-reversível: interrompe a sincronização — `Enter` segurado 600ms / 2º `Enter`) | ✅ local · ✅ reversível (B2) · ✅ não-muta-prod · ✅ não-`@devops` |
| **B2** | **Retomar autosync** | `autosync-pause.sh off` | inverso de B1; restaura o estado-default do daemon | não (restaura o normal; não-destrutivo) | ✅ · ✅ (B1) · ✅ · ✅ |
| **B3** | **Re-selar segurança** | `check-security-freshness.sh --record PASS @security-reviewer` (após `@security-reviewer` rodar o diff) | append-only no ledger; um re-record posterior corrige; nada destruído (a cadeia é encadeada por hash) | **SIM** (carimba um selo de integridade — exige ator real; `Enter` confirmado) | ✅ local · ✅ append-only/corrigível · ✅ não-muta-prod · ✅ não-`@devops`. **Guarda:** nunca automatizar o carimbo (learning `automate-the-reminder-not-the-integrity-stamp`) — o ⌘K dispara só sob ação humana explícita |
| **B4** | **Forçar sync agora** | `launchctl kickstart -k gui/$UID/com.ideiaos.gitautosync` | idempotente: forçar um ciclo extra não tem inverso a desfazer (apenas adianta o que ocorreria em ≤900s) | não (idempotente, sem efeito destrutivo) | ✅ · ✅ (idempotente) · ✅ · ✅ |
| **B5** | **Kickstart daemon X** | `launchctl kickstart -k gui/$UID/com.ideiaos.{envsync\|refresh-ai-security\|missioncontrol}` | idempotente; re-disparar um LaunchAgent local não muta estado externo | não (idempotente) | ✅ · ✅ · ✅ · ✅ |
| **B6** | **Rodar idea-doctor** | `idea-doctor` (read-only; parseia OK/WARN/FAIL → toast) | leitura pura, sem efeito colateral a reverter | não | ✅ · ✅ (read-only) · ✅ · ✅ |

> Todos os 6 herdam a **constituição do OS**: `autosync-pause.sh on/off`, `idea-doctor`, `check-security-freshness.sh --record`, `launchctl kickstart` são os comandos locais sancionados já existentes (doc 73 §0). O ⌘K **não inventa** verbo — só expõe o que o CLI já oferece (Constitution: CLI First).

### B.2 — A FRONTEIRA: o que fica FORA do allowlist (e por quê)

| Verbo/capacidade FORA | Por que FORA | Autoridade / gate que o barra |
|-----------------------|--------------|-------------------------------|
| **`git push` / `gh pr create`/`merge`** | viola critério 4 (autoridade) | `@devops`-**exclusivo** (`agent-authority`). O Cockpit no máximo **gera o comando**; cross-máquina não cria exceção (doc 70 §6) |
| **MCP add/remove/configure · reabilitar Lovable 19-tools** | viola critério 4 (autoridade) + 3 (a deny-list é o sensor que já regrediu sozinho) | `@devops`-exclusivo; o Cockpit **audita** a deny-list (A2), **nunca modifica** (doc 70 §6, doc 50 §7) |
| **`rotate` / `revoke` credencial** | viola critério 3 (muta produção, RCE-equivalente sobre 4 bancos+Vercel+Railway) | gated v14.4 atrás do `/spec`+threat-model; exige janela-de-privilégio-com-teardown (doc 70 §5) |
| **`deploy` de produção** | viola critério 3 (muta produção) | gated v14.4; `dev` no máximo **gera o comando** p/ `@devops` (doc 70 §4) |
| **Comando cross-máquina (qualquer)** | viola critério 1 (não-local) | gated v14.4 — sem prova de origem (assinatura por-máquina) o RBAC é falsificável (doc 70 §2-bis, Q1–Q3 abertas) |
| **`reveal` / copiar valor de segredo** | viola critério 3 + regra-piso | NUNCA, mesmo v14.4 (`credential-isolation`; doc 70 §6). Se o operador precisa do valor, busca na fonte via terminal, fora do Cockpit |
| **`exec` / shell arbitrário no agentd** | viola critério 1/3 (Excessive Agency; transforma "comprometer painel" em "comprometer tudo") | NUNCA, mesmo v14.4 — o agentd expõe **conjunto fechado tipado** (doc 70 §6, OWASP LLM06) |
| **`rotate`/`revoke` em massa num clique** | viola critério 3 (DoS estrutural sobre produção) | NUNCA batch atômico; se entrar (v14.4) exige out-of-band **por alvo** (doc 70 §6) |

> **O verbo mais perigoso mantido FORA — destacado:** **`revoke` em massa de credenciais** (revogar todos os tokens num clique). É a **única** capacidade que, sozinha e autenticada, derruba o ecossistema inteiro instantaneamente (DoS estrutural sobre produção) — pior que `rotate` (recuperável) ou `deploy` (escopo de 1 produto). Fica fora não por falta de auth, mas porque o **blast-radius é estrutural**: nenhuma quantidade de assinatura o torna seguro como ação atômica.

---

## C. Rastreabilidade (cada item ↔ fonte)

| Bloco | Fontes (DADOS) |
|-------|----------------|
| Atalaia A1–A11 | doc 00 §3/§9 (pilar Atalaia + catálogo risco), doc 50 §6/§7, doc 73 §0/§3/§5/§5.1/§7, `security-freshness` (escada/tier), learnings `version-reset-migration-semver-trap`, `soak-span-is-record-delta-not-wallclock`, `declarative-manifest-vs-imperative-list-drift`, `automate-the-reminder-not-the-integrity-stamp` |
| Allowlist B1–B6 | doc 50 §3.3 (⌘K), doc 01 v14.1, doc 73 §0 (comandos sancionados existentes), Constitution (CLI First) |
| Fronteira B.2 | `agent-authority` (delegação `@devops`), doc 70 §4/§5/§6 (gating v14.4), `credential-isolation` (regra-piso) |

---

*Doc 77 — PROPOSTO. Zero código. Próximo: este catálogo alimenta o `/spec` da capability `cockpit` (Atalaia em v14.2; ⌘K em v14.1) e a fronteira B.2 herda o threat-model do doc 70 para a v14.4.*
*Regra-piso: `credential-isolation`. Autoridade: `agent-authority`. Frescor: `security-freshness`. Eixo determinístico: `antifragile-gates`.*
