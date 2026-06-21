# IdeiaOS Cockpit — Pilar Pulso · Fórmulas de Produtividade Honestas

> **Doc 76 · Analytics Engineer (cético-a-vaidade).** Define as fórmulas EXATAS dos 4 KPIs do
> pilar **Pulso** ("onde o tempo de IA virou ENTREGA VERIFICADA — sinal, não vaidade"), a
> classificação determinística de ator, o caminho do multi-usuário e a lista anti-vaidade.
>
> **Disciplina:** toda fórmula aqui é **determinística** (parseável sem LLM, exit-code-verificável),
> ancorada no substrato real apurado no doc 73, e desenhada para **resistir à vaidade**. Onde um
> número não tem fonte verificável, ele é **rotulado estimativa** ou **não existe** — nunca inventado.
>
> **Fontes verificadas (doc 73 — DADOS, não suposição):** atividade real por transcript (Jarvis 469,
> ideiapartner 361, IdeiaOS 353, evals 22, cfoai 4); ~35 escopos de observations; **toda** observação
> é `gustavo@` (monousuário); git log carrega hostname nas msgs `wip:` do autosync; SOAK ledger =
> entrega verificada cross-máquina; security ledger; instincts = telemetria comportamental (NÃO conduta).

---

## 0. O princípio que governa as 4 fórmulas

**Vaidade é qualquer número que sobe quando o trabalho NÃO aumentou.** Tamanho de transcript sobe
com verbosidade. Contagem bruta de sessão sobe com retomadas triviais. Linha de código sobe com
boilerplate. Commit de bot sobe com automação. Nenhum desses é entrega.

**Sinal é o número que só sobe quando algo verificável foi entregue.** A âncora-mestra do Pulso é
o **SOAK ledger**: é a ÚNICA prova de "entrega verificada cross-máquina" que o OS produz — um
milestone que passou validação determinística (doctor + regression) em ≥2 máquinas, com span ≥1d.
Tudo o mais (commits, sessões) é **textura de atividade**, subordinada à âncora, nunca ranking.

A hierarquia de confiança das 4 fontes, da mais defensável à menos:

| Rank | Fonte | Por quê | KPI |
|------|-------|---------|-----|
| 1 | **SOAK ledger** | append-only, cross-máquina, exit-code-validado, impossível de inflar sem entregar | KPI-2 |
| 2 | **Security ledger** | append-only, risk-weighted, ator-real exigido (não automatizável) | KPI-4 |
| 3 | **git log humano** | determinístico após filtro de ator; commit é unidade discreta de mudança | KPI-1 |
| 4 | **transcripts (human_turns)** | proxy de esforço cognitivo; o mais ruidoso → exige o filtro mais agressivo | KPI-3 |

---

## 1. Os 4 KPIs — fórmula EXATA, fonte, por que é sinal

### KPI-1 · Commits humanos / semana

**Fórmula:**
```
commits_humanos_semana(repo, semana) =
  | { c ∈ git_log(repo)
      : iso_week(c.author_date) == semana
      ∧ is_human(c)                              # §2 — classificação determinística
      ∧ c.author_email ∈ normalize(autores_humanos)  # §2.2 — dedup de email
    } |
```
Comando-base (determinístico, sem LLM):
```bash
git -C "$repo" log --no-merges --since="$week_start" --until="$week_end" \
  --pretty='%H|%ae|%aI|%s'
# então filtra por is_human() (§2.1) e normaliza email (§2.2)
```

**Fonte:** `git log` dos repos descobertos (`~/dev/*` com `.git` — descoberta dinâmica, doc 73 §4,
nunca lista fixa de 5).

**Por que é SINAL, não vaidade:**
- O commit é a **unidade discreta de mudança intencional** — diferente de LOC, não infla com
  boilerplate (1 commit de 500 linhas geradas conta **1**, não 500).
- `--no-merges` remove merges (ruído de fluxo, não trabalho).
- O filtro `is_human` (§2) remove os **~70 commits-fantasma** do autosync no Mac mini e os commits
  Lovable/Actions — que são propagação de máquina, não decisão humana.
- Granularidade **semanal** (não diária) suaviza o burst de milestone (99–110/dia) sem apagá-lo:
  a tendência semanal é a velocity real; o pico diário vira anotação, não a métrica.

**Armadilha barrada:** contar commits raw (incluindo `wip: autosync`) inflaria a velocity do Mac
mini em ~70 commits/semana de PURO ruído de daemon. Ver §6.

---

### KPI-2 · Milestones SOAK-validados

**Fórmula:**
```
milestones_soak_validados(período) =
  | { m : m.machines_distintas ≥ 2
        ∧ span(m) ≥ 1 dia
        ∧ m.último_record.iso ∈ período }
  |

onde:
  machines_distintas(m) = | distinct(host : linha ∈ ledger(m)) |   # após alias-map §2.3
  span(m)               = max(epoch gravado) − min(epoch gravado)  # delta de RECORDS, NÃO wall-clock
```
Comando-base:
```bash
# por ledger .planning/soak/<milestone>.log  (formato: epoch|iso|host|doctor|regression|commit)
awk -F'|' '{print $1, $3}' "$ledger"   # epochs + hosts → span e contagem de hosts distintos
```

**Fonte:** SOAK ledgers (`.planning/soak/*.log`), append-only, **commitados** (prova cross-máquina).

**Por que é SINAL — o KPI mais defensável (ver §7):**
- É a **única** entrega que passou validação **determinística** (`doctor` + `regression` por exit-code)
  em **hardware distinto** (≥2 máquinas reais). Impossível de fabricar sem de fato entregar e a
  durabilidade sobreviver à troca de máquina.
- `span ≥ 1d` é **delta de epochs GRAVADOS**, não wall-clock — esperar não amadurece o soak; tem que
  **re-gravar** depois de 1 dia (learning `soak-span-is-record-delta-not-wallclock`). Isso fecha a
  fraude "deixa o relógio correr".
- Não conta milestone PARCIAL/no-tag até os dois critérios baterem → o KPI mede **entrega selada**,
  não "trabalho em progresso que parece pronto".

**Gotcha respeitado:** `host` distinto após alias-map `192 → MacBook-Air-2` (doc 73 §3 — o `192` é a
MacBook-Air-2, NÃO a Mac-mini). Sem o alias-map, 2 máquinas reais poderiam contar como 3, ou 1
máquina sob dois nomes poderia falsamente satisfazer o "≥2".

---

### KPI-3 · Sessões cognitivas / meaningful

**Fórmula:**
```
sessoes_meaningful(escopo, período) =
  | { s ∈ transcripts(escopo)
      : human_turns(s) > 5
      ∧ s.last_ts ∈ período }
  |

onde human_turns(s) = | { msg ∈ parse_jsonl(s) : msg.role == "user"
                                                ∧ ¬ is_tool_result(msg)
                                                ∧ ¬ is_system_synthetic(msg) } |
```
Parse (determinístico, linha-a-linha do JSONL):
```bash
# conta turns de usuário REAL (exclui tool_result e mensagens sintéticas/hook)
# por sessão; mantém só as com contagem > 5
```

**Fonte:** session transcripts (`~/.claude/projects/*/*.jsonl`) + observations scopes (~35, doc 73 §6).

**Por que é SINAL:** um turn humano real é um ato de **direção cognitiva** — o operador leu, decidiu
e respondeu. `> 5` turns separa uma sessão de **trabalho deliberado** (ir-e-vir, correção de rumo,
decisão) de uma retomada trivial (1 pergunta, 1 resposta, fecha).

**Por que contagem BRUTA de sessão é VAIDADE — o exemplo canônico:**
> **Jarvis tem 469 sessões. Isso NÃO é 469 entregas.**

469 é o número mais sedutor e mais vazio do substrato. Uma sessão abre por mil motivos triviais:
retomar contexto, uma pergunta de 1 linha, um teste que reabriu a IDE, um hook de SessionStart.
Contar sessões puras premia **quem abre a IDE**, não **quem entrega**. O filtro `human_turns > 5`
é o que transforma "abri o editor" em "trabalhei de verdade" — é a barreira anti-vaidade do KPI-3.
A copy da UI DEVE mostrar ambos para não enganar: `469 sessões · 137 meaningful` (números ilustrativos),
nunca só o 469.

**Limite honesto declarado:** o transcript é **incompleto** onde o IDE primário não é o Claude Code.
cfoai = 4 sessões → IDE primário provável **Cursor/Lovable**. O card DEVE rotular
`IDE primário: provável Cursor/Lovable — sinal de transcript incompleto`, nunca fingir que 4 sessões
é a atividade real do produto.

---

### KPI-4 · Freshness de segurança

**Fórmula (proxy de responsabilidade técnica no tempo — não é contagem, é estado):**
```
freshness(sistema) = tier( score(diff_desde_último_selo), idade(último_selo) )

tier = fresco    se score < 10  ∧ idade < 90d
     = stale     se score ≥ 10  ∨ idade ≥ 90d  ∨ (mudança_crítica ∧ sem_revisão_30d)
     = egrégio   se score ≥ 20  ∨ idade ≥ 180d

score = Σ peso(path) sobre os paths tocados no diff desde o último selo
        peso = 3 (crítico: auth/RLS/secret/LLM-endpoint/enforce/.env)
             | 1 (sensível: rotas API/deps/lockfile/*.sql/edge)
             | 0 (neutro: UI/docs/teste/refactor)
```
Comando-base: `check-security-freshness.sh --tier` (palavra única parseável) + ledger
`.security/review-ledger.log` (`epoch|iso|commit|revisor|veredito|escopo`).

**Fonte:** security freshness ledger (append-only, commitado).

**Por que é SINAL:** é o **único KPI de responsabilidade contínua** — mede `rigor = risco da
superfície tocada × idade da última revisão`. Sobe (piora) sozinho com o tempo (CVE apodrece sem
mudança de código) e com risco tocado. Não é automatizável: o re-selo exige um **ator real**
(`@security-reviewer`) — automatizar o carimbo fraudaria a distinção que o gate protege
(learning `automate-the-reminder-not-the-integrity-stamp`). A automação lembra; nunca sela.

**Por que NÃO é vaidade:** não há como "inflar" frescor — só revisar de verdade zera o contador.
É o oposto estrutural de uma métrica de vaidade (que sobe com atividade vazia).

---

## 2. Classificação determinística de ator (o filtro que separa sinal de ruído)

Toda métrica humana do Pulso depende deste filtro. É **determinístico** (regex, exit-code), roda
ANTES de qualquer agregação. Ordem de avaliação importa — primeiro match vence.

### 2.1 Regex de exclusão (commit → classe de ator)

```
classify(commit):
  # avaliar nesta ordem; primeiro match decide
  1. AUTOSYNC  se  subject =~ /^wip: autosync/        # msg do daemon git-autosync
              OU  author_email =~ /@[^@]*\.local$/    # ex.: gustavolopespaiva@Mac-mini-de-Gustavo.local
  2. BOT       se  author_email =~ /\[bot\]@/          # gpt-engineer-app[bot] (Lovable), github-actions[bot]
              OU  author_email =~ /\[bot\]$/
              OU  author_name  =~ /\bbot\b/i
  3. HUMAN     caso contrário
```
- `is_human(c) ≡ classify(c) == HUMAN`.
- O `@*.local$` é a chave: o autosync do Mac mini comita como
  `gustavolopespaiva@Mac-mini-de-Gustavo.local` — é **propagação de máquina**, não sessão humana.
  Esses são os ~70 commits-fantasma que TÊM que sair de toda métrica humana (doc 00 §9).
- `^wip: autosync` pega a msg-padrão do daemon mesmo quando o email parece humano.

### 2.2 Normalização de email (mesmo humano sob aliases)

```
normalize(email):
  gustavo@redeideia.com.br      → gustavo            # alias canônico
  gustavolpaiva@<qualquer>      → gustavo            # mesmo humano (doc 50 §5)
  gustavolopespaiva@<NÃO .local> → gustavo           # idem (só se não for *.local → senão é autosync, §2.1)
  desenvolvimento@ideiabusiness.com.br → desenvolvimento   # 2º humano — VAPORWARE hoje (§5)
```
Um humano com N emails conta como **1 ator**. Sem isso, a "Equipe" infla atores fictícios e a
contribuição de Gustavo se fragmenta em 3 linhas. **Cuidado de precedência:** a regra `@*.local$`
do §2.1 é avaliada ANTES da normalização — `...@Mac-mini.local` é autosync, não Gustavo-humano.

### 2.3 Alias-map de host (para SOAK / Frota)

```
host_alias:  192 → MacBook-Air-2     # doc 73 §3 (CORRIGIDO: 192 é a MacBook, não a Mac-mini)
```
Aplicado antes de contar `machines_distintas` no KPI-2.

---

## 3. Co-ocorrência commit ↔ sessão (atribuição de trabalho a tempo de IA)

**O que responde:** "deste commit humano, quanto saiu de uma sessão de IA?" — atribui **entrega**
(commit) ao **esforço cognitivo com IA** (sessão), fechando o loop "tempo de IA → entrega verificada".

**Fórmula (janela temporal, determinística):**
```
co_ocorre(commit, sessão) ≡
     commit.author_date ∈ [ sessão.first_ts , sessão.last_ts + Δ ]
   ∧ same_project(commit.repo, sessão.scope)

Δ = 30 min   # janela de graça pós-sessão (commit logo após fechar a sessão)

attributed_rate(repo, período) =
   | { c humano em repo : ∃ s meaningful . co_ocorre(c, s) } |
   ─────────────────────────────────────────────────────────
   | { c humano em repo no período } |
```

**Interpretação honesta (o que o número É e o que NÃO é):**
- `attributed_rate` alto = a entrega humana **co-ocorre** com trabalho de IA → o tempo de IA está
  virando commit. É **correlação temporal**, não causa provada.
- É **proxy**, e a UI rotula assim: `commits em janela de sessão de IA` — nunca "a IA escreveu X%".
- Caso de divergência saudável: cfoai tem commits humanos mas ~4 sessões → `attributed_rate` baixo
  **não** significa pouca IA; significa **IA fora do Claude Code** (Cursor/Lovable). O card cruza
  com o rótulo de IDE-incompleto do KPI-3 e mostra `atribuição parcial — IDE primário externo`.
- **Nunca** usar isto para ranquear pessoas nem para "provar produtividade da IA" — é textura de
  atribuição, subordinada à âncora SOAK.

---

## 4. CRÍTICO — O caminho do multi-usuário (de vaporware a real)

**Estado hoje (verificado, doc 73):** **toda** observação, **todo** commit humano, **toda** sessão é
`gustavo@`. O sistema é **monousuário de fato**. Logo as personas **P1 (líder de squad)** e
**P2 (dev individual)** do pilar Pulso são **vaporware** — não há um segundo ator que as alimente.
A desonestidade a evitar é mostrar um card P1/P2 vazio fingindo que a feature existe.

### 4.1 Que sinal precisa NASCER

Um **segundo ator humano distinto** com volume real. Concretamente: commits humanos cujo
`normalize(email) ∉ { gustavo }` — o candidato natural é `desenvolvimento@ideiabusiness.com.br`.
"Nascer" = aparecer no `git log` humano (após filtro §2) de forma recorrente, não 1 commit isolado.

### 4.2 Gate determinístico para "ligar" as personas

```
multiuser_unlocked ≡
     | distinct_human_actors(últimos_90d) | ≥ 2
   ∧ ∃ ator a ≠ gustavo : commits_humanos(a, últimos_90d) ≥ N_MIN

N_MIN = 10    # piso anti-ruído: 1 commit não é um colaborador; 10 é presença sustentada
```
- **Determinístico e auditável:** conta atores humanos distintos (emails normalizados, §2.2) com
  ≥ `N_MIN` commits humanos numa janela de 90d. Sem LLM, sem julgamento.
- `N_MIN = 10` é o piso anti-ruído (um commit de teste de outra máquina não destrava uma persona).
- O segundo ator distinto **TEM** que sobreviver ao filtro §2 — um `@*.local` (autosync) ou `[bot]@`
  jamais conta como "segundo humano". É exatamente o que impede o Mac-mini-autosync de falsamente
  destravar o multi-usuário.

### 4.3 O que a UI mostra ENQUANTO é monousuário (rótulo honesto, não card-fantasma)

| Condição | UI |
|----------|-----|
| `multiuser_unlocked == false` (hoje) | Personas P1/P2 renderizam **desabilitadas** com rótulo honesto: `Aguardando 2º ator de desenvolvimento — monousuário hoje (todo trabalho é gustavo@).` Um **contador de progresso** `desenvolvimento@: 0 / 10 commits para destravar` torna o gate visível e não-mágico. |
| Card "Equipe" | Mostra **1 ator real** (`Gustavo · CTO`) com 100% — honesto, não inventa um segundo avatar. |
| `multiuser_unlocked == true` | P1/P2 **acendem automaticamente**; as métricas já existiam (eram só single-actor) e passam a particionar por ator. Zero migração de dados — o gate só revela o que o filtro já computa. |

**Princípio:** a feature multi-usuário não é construída-depois; ela **já está computada** (as fórmulas
particionam por `normalize(email)` desde o dia 1). O gate só **revela** quando o dado justifica.
Enquanto não justifica, o rótulo diz a verdade — "monousuário hoje" — em vez de um card vazio fingindo.

---

## 5. Lista anti-vaidade — o que NUNCA conta

Banner obrigatório no topo do ecrã Pulso (doc 50 §9):
`"Medimos entrega verificada, não volume. Bot/autosync, tamanho de transcript e contagem bruta de
sessões NÃO contam."`

| ❌ NUNCA conta | Por quê é vaidade | O que medimos no lugar |
|----------------|-------------------|------------------------|
| **Tamanho do transcript** (chars/linhas do JSONL) | Correlaciona com verbosidade do modelo, não com valor entregue | `human_turns > 5` (esforço cognitivo discreto) |
| **Contagem bruta de sessões** | Sobe com retomadas triviais — **Jarvis 469 ≠ 469 entregas** | Sessões meaningful (KPI-3) |
| **Commits de bot/autosync/wip** | É propagação de máquina, não decisão humana (~70 fantasmas no Mac mini) | Commits humanos pós-filtro §2 (KPI-1) |
| **Linhas de código (LOC)** | Infla com boilerplate/código gerado; deletar código bom REDUZ LOC | Commit como unidade discreta de mudança |
| **Nº de tool-calls / observations** | Telemetria de frequência ("usou grep N vezes") — `token-economy` proíbe promover frequência a sinal | Nada — é só sinal bruto de telemetria |
| **Confidence de instinct como "produtividade"** | Instinct é telemetria comportamental write-only, **NÃO conduta ao vivo** (`learning-channel-routing`) | Rotulado "maturidade observada de padrões", nunca entrega |
| **Ranking de produtividade individual de humanos** | Fácil de abusar, ético-tóxico; vira vigilância (doc 60 §5 recusa por convicção) | Produtividade do **sistema** (humano+IA entregando) ancorada em SOAK |

**Regra de bolso:** se o número sobe quando ninguém entregou nada verificável, é vaidade — fora do Pulso.

---

## 6. Rastreabilidade (o que cada fórmula consome — substrato existente)

| KPI / mecanismo | Fonte primária (já existe) | Filtro determinístico |
|-----------------|----------------------------|----------------------|
| KPI-1 commits humanos | `git log --pretty` dos repos descobertos | §2.1 ator + §2.2 email |
| KPI-2 milestones SOAK | `.planning/soak/*.log` | span = delta de epochs gravados; §2.3 host-alias |
| KPI-3 sessões meaningful | `~/.claude/projects/*/*.jsonl` + observations scopes | `human_turns > 5`; rótulo IDE-incompleto |
| KPI-4 freshness | `check-security-freshness.sh --tier` + `.security/review-ledger.log` | tier risk-weighted; re-selo por ator real |
| Co-ocorrência | git log humano + transcripts | janela [first_ts, last_ts+30min] + same_project |
| Gate multi-usuário | git log humano (90d) | `≥2 atores distintos ∧ 2º ator ≥ 10 commits` |

---

*Doc 76 — fórmulas PROPOSTAS, zero código. Cético-a-vaidade, verify-don't-assume. Toda fórmula é
determinística e ancorada no substrato verificado (doc 73). A âncora-mestra é o SOAK ledger; tudo o
mais é textura subordinada. O multi-usuário já está computado — o gate só revela quando o dado justifica.*
