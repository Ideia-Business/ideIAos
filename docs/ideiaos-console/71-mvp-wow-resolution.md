# IdeiaOS Cockpit — Resolução da tensão MVP × Wow

> **Documento 71 · Resolução de tensão · Principal Product Designer + estrategista**
> **Status:** PROPOSTO (zero código) · **Data:** 2026-06-20 · **Branch:** `work`
> **Responde a:** crítica adversarial "o MVP v14.1 corta justamente o categoricamente novo —
> Time-Travel e Black-box (★★★★★) estão em Wave 2/3, e o slice inicial fica indistinguível de um
> bom dark admin panel; o wow real chega tarde demais para a primeira impressão."
> **Depende de:** `00-BLUEPRINT.md` (§6, §7, §10), `02-PHASE-1-SPEC.md`, `50-ux-experience.md`, `60-moonshot-outside-the-box.md`.
> **Não substitui** o blueprint — emenda **cirurgicamente** o escopo da v14.1 (§5 deste doc).

---

## 0. TL;DR (a decisão, antes do raciocínio)

A crítica está **certa**. O recorte mínima-viável (Overview + Frota + Cofre-metadata + ⌘K) é
competente mas categoricamente *familiar* — qualquer um já viu um dark admin panel com cards e
command palette. O único elemento do produto que **nenhum dashboard SaaS tem** — porque eles
guardam estado-atual e jogam fora a história — é a **reconstrução determinística do passado a
partir de um event-store append-only**. E esse elemento está agendado para v14.3/v14.4.

**Resolução:** trazer um **naco** do Time-Travel para a v14.1, com codinome **Flight Recorder
v0**, escopado a **UMA** reconstrução, **read-only**, dentro do orçamento de ~1–2 semanas.

**A reconstrução escolhida: a timeline de drift do pin `gsd` no `versions.lock`** — o flip-flop
real `1.36.0 → 1.1.0 → 1.36.0 → 1.1.0` revertido 3× ao longo de 18 dias, reconstruído
inteiramente por `git show <commit>:versions.lock`. (Justificativa em §1; descarte dos outros
dois candidatos em §1.3.)

**O ajuste de escopo:** o card **Releases/SOAK** do Overview **cede o slot do hero secundário**
para uma faixa **Flight Recorder v0** — uma fita de tempo de um único pin que se reconstrói ao
vivo. SOAK não some (continua no Overview como card 1×1); perde só o destaque (§5).

O Time-Travel **completo** (slider sobre toda a frota, multi-ledger, reconstrução do incidente
deny-list) permanece v14.3. O Flight Recorder v0 é o **vertical-slice de UMA fita**, não o
produto inteiro (§4).

---

## 1. A escolha: timeline de drift do `versions.lock` (`gsd` pin)

### 1.1 Por que ESTA reconstrução é o maior wow defensável

O wow não é estético (a audiência é 1 operador em localhost — confete não impressiona ninguém
sozinho). O wow é **estrutural**: provar, ao vivo e sem trapaça, que *o substrato é uma
fonte-de-verdade auditável de que se reconstrói o passado deterministicamente*. Um dark admin
panel mostra **agora**; o Flight Recorder mostra **como chegamos aqui** — e essa é a fronteira
categórica.

Dos três candidatos, o `versions.lock` é o único que combina **as três** propriedades exigidas
para um wow defensável dentro do orçamento:

1. **Tem um INCIDENTE real e visualmente dramático.** Não é uma reta de PASS/PASS — é um
   flip-flop. O pin `gsd` foi `1.36.0`, virou `1.1.0` (migração redux), o autosync do Mac-mini
   reverteu para `1.36.0`, foi re-pinado para `1.1.0`, reverteu de novo, e foi finalmente fixado.
   **Verificado no git history** (datas/hosts/mensagens reais):

   | Data | `gsd=` | O que aconteceu (commit subject) | Ator |
   |------|--------|----------------------------------|------|
   | 2026-06-02 | `1.36.0` | `wip: autosync` | Mac-mini (daemon) |
   | 2026-06-04 | `1.36.0` | `feat(setup): AIOX alinhado` | humano |
   | 2026-06-05 | `1.1.0` | `chore: gsd 1.36.0 → 1.1.0 (migração redux)` | humano |
   | 2026-06-08 | `1.36.0` | `wip: autosync 2026-06-08 (Mac-mini)` | **daemon REVERTEU** |
   | 2026-06-08 | `1.1.0` | `fix: re-pin gsd 1.36.0 → 1.1.0 (autosync Mac-mini reverteu)` | humano |
   | 2026-06-11 | `1.36.0` | `fix: re-pin gsd doctor version` | **regrediu de novo** |
   | 2026-06-12 | `1.36.0` | `feat(06): plugin/marketplace` | humano |
   | 2026-06-12 | `1.1.0` | `feat(16-01): marketplace-ready` | humano (fixou) |
   | 2026-06-16…20 | `1.1.0` | estável | — |

   Essa fita **conta uma história sozinha**: a tensão `1.1.0 (redux) > 1.36.0 (pré-redux)` que
   inverte o semver, o daemon do Mac-mini sobrescrevendo o humano, três reversões. É exatamente o
   tipo de drift silencioso que a memória `version-reset-migration-semver-trap` e
   `ambiguous-drift-warning-induces-agent-revert` documentaram **à mão** — e o Flight Recorder o
   torna **visível de relance**, sem ninguém precisar caçar 13 commits.

2. **É 100% DETERMINÍSTICO — zero interpretação NL.** O valor pinado em qualquer ponto do tempo é
   `git show <commit>:versions.lock | grep '^gsd='` — um comando shell com exit-code binário.
   Nada de LLM, nada de parsear prosa, nada de "parece que mudou". `git log` **é** o event-store
   append-only; a reconstrução é a função pura `pin(commit) = fold(versions.lock até commit)`. A
   verificação é `antifragile-gates` literal (§4).

3. **Cabe no orçamento — é um único arquivo, uma única chave.** Não exige o folder multi-ledger
   do Time-Travel completo, não exige o grafo de dependência, não exige slider sobre a frota
   inteira. É **13 commits, 1 grep, 1 fita SVG**. Construível em dias, não semanas (§4, §6).

### 1.2 O que prova ao abrir o Cockpit pela primeira vez

> A primeira impressão deixa de ser "que admin panel bonito" e passa a ser "**espera — ele
> reconstruiu o histórico de uma decisão de versão que eu mesmo revertí três vezes, e está
> certo**". Esse é o momento em que o produto sai da categoria "dashboard" e entra na categoria
> "instrumento de verdade auditável" — sem esperar a v14.3.

### 1.3 Por que NÃO os outros dois candidatos (honestidade de trade-off)

**Replay do histórico SOAK cross-máquina — descartado para a v14.1 (não é o maior wow).**
Viabilidade altíssima (7 heartbeats, 3 hosts, parsing `awk -F'|'` trivial, verificado no disco).
Mas o conteúdo é **PASS/PASS/PASS** — durabilidade, não incidente. Reconstruir "em 19/06 as duas
máquinas davam PASS" é honesto e bonito, mas **não tem drama** — não há flip, não há reversão, não
há "uau, ele pegou o erro". É o segundo-melhor wow e tem lugar: vira a **fita irmã** no
Flight Recorder *completo* da v14.3. Para a v14.1, drama > volume.

**Reconstrução do incidente deny-list 5/5→2/5→5/5 — descartado para a v14.1 (viola "determinístico
= lei").** É o wow conceitualmente mais forte (e o blueprint §10 o nomeia como o momento-prêmio).
Mas — **verificado** — o estado `5/5→2/5→5/5` **não vive num event-store estruturado**. Ele está
espalhado em **mensagens de commit em prosa** (`docs(closing): gap-closure audit — remedia
regressão deny Lovable MCP (2/5→5/5)`) + memória curada. Reconstruí-lo deterministicamente
exigiria ou (a) interpretar texto livre de commit — o que é NL, alucinável, proibido como "lei"
por `antifragile-gates`; ou (b) um event-store que **ainda não existe** (o
`check-idea-doctor 7e`/deny-list-watch só nasce na v14.2). Logo: alto risco, baixa viabilidade
read-only **hoje**. Fica na v14.3 — **mas** com um pré-requisito que este doc torna explícito:
*a v14.2 deve emitir um ledger estruturado de contenção deny-list por produto* (não só o check),
senão a reconstrução determinística do incidente nunca será possível. Sem esse ledger, o
"momento-prêmio" do blueprint §10 é vaporware. (Achado registrado em §7.)

---

## 2. O event-store mínimo (tudo já existe — zero coleta nova)

| Recurso | Onde | Formato | Parsing | Já existe? |
|---------|------|---------|---------|------------|
| **Histórico de `versions.lock`** | git (qualquer clone do IdeiaOS) | append-only por natureza (git é event-store) | `git log --format='%H|%cI|%s' -- versions.lock` → 13 commits; `git show <H>:versions.lock \| grep '^gsd='` por commit | ✅ verificado (13 commits, range 2026-06-02 → 06-20) |
| **Ator por commit** | a própria mensagem | string | `^wip: autosync` ou `@*.local$` → daemon; senão humano (classificação determinística do blueprint §9) | ✅ |
| **Host por commit** | sufixo das msgs `wip: autosync … (MacBook-Air-2)` / `(Mac-mini-de-Gustavo)` | string entre parênteses | regex fixo | ✅ |

**Tamanho do dataset:** 13 commits, ~18 dias, 1 chave. Cabe inteiro em memória; a fita inteira é
um array de `{commit, iso, gsd_value, actor, host, subject}`.

**Sem mudança de substrato.** A v14.0 já planeja o ref `mission-control` e o read-model SQLite —
mas o Flight Recorder v0 **nem precisa do ref**: ele lê o **git local do próprio repo IdeiaOS**.
Isso é uma propriedade deliciosa: o naco de wow é construível **antes mesmo** do agentd-coletor
estar maduro, porque sua fonte (`git log` local) é a mais primitiva possível. Reduz acoplamento e
risco de cronograma.

**Reader determinístico (pseudo-shell, o contrato exato):**

```bash
# Flight Recorder v0 — reconstrói a fita do pin gsd. Zero LLM, zero NL.
git log --format='%H|%cI|%s' -- versions.lock | while IFS='|' read -r H ISO SUBJ; do
  GSD=$(git show "$H:versions.lock" 2>/dev/null | grep -m1 '^gsd=' | cut -d= -f2)
  case "$SUBJ" in
    "wip: autosync"*) ACTOR=daemon ;;
    *) ACTOR=human ;;
  esac
  printf '%s|%s|%s|%s|%s\n' "$H" "$ISO" "${GSD:-<absent>}" "$ACTOR" "$SUBJ"
done
```

Cada linha é um **evento**; a fita é o fold. Um commit onde `versions.lock` não tinha `gsd=`
ainda devolve `<absent>` — honesto, nunca inventado (respeita `surfacing honesto de lacunas`,
`02-PHASE-1-SPEC.md` §4).

---

## 3. A affordance de UI (coerente com o black-gold do doc 50)

### 3.1 A forma: **fita de tempo de UM pin** (não slider de frota)

A decisão de affordance é deliberadamente **mais modesta** que o slider-de-tempo do Time-Travel
completo — e essa modéstia é o que a mantém no orçamento e honesta. O Time-Travel completo é um
**slider que reconstrói a frota inteira** numa data (multi-ledger, multi-máquina). O Flight
Recorder v0 é uma **fita horizontal de eventos de uma única série temporal** — o pin `gsd` ao
longo do tempo. Uma dimensão, não N.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ FLIGHT RECORDER · pin gsd                            13 eventos · 18 dias  ◷ │
│                                                                             │
│  1.36.0 ●━━━━━●━━━━●        ●━━━━●                                          │
│              │     ╲      ╱      ╲                                          │
│  1.1.0       │      ●━━━━●        ●━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━●  ✓   │
│              │      ↑daemon reverteu      ↑humano fixou                      │
│         06-02   06-05  06-08   06-11  06-12 ················· 06-20          │
│                                                                             │
│  ⚠ 3 reversões · último ator: humano · estável há 8 dias                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **Step-line de dois níveis** (`1.36.0` em cima, `1.1.0` embaixo) — a forma de degrau **mostra o
  flip-flop visualmente**. Cada transição é um nó clicável.
- **Cor por estado, nunca decoração** (gramática do doc 50 §2): a linha é `--text-tertiary`
  neutra; um nó de **reversão por daemon** (humano→daemon→valor-anterior) acende **âmbar**
  (`--status-warning`) — é o drift; o nó final estável acende **verde discreto**
  (`--status-success`) com `✓`. O ouro (`--accent-gold`) é só a moldura/seleção, jamais "estado".
- **Hover no nó** → tooltip mono: `06-08 · gsd=1.36.0 · daemon (Mac-mini) · "wip: autosync"`.
  A evidência (SHA curto + subject) **anexada**, à la `git blame` — prova auditável, não
  afirmação.
- **Clique no nó** → o resto do Overview **não muda** na v0 (isso seria o Time-Travel completo);
  em vez disso, abre um painel lateral com o `git show --stat` daquele commit. Reconstrução de
  **uma série**, não do mundo. (Fronteira v0 vs v14.3 em §4.)

### 3.2 Linguagem visual (tokens do doc 50 §10, verbatim)

- Fundo `--bg-surface #0A0A0A`, moldura `--border` (NÃO gold-border — o hero gold é reservado ao
  System Pulse, doc 50 §3.2-B; o Flight Recorder é o **segundo** instrumento, não compete pelo
  coração).
- Mono em **todo** numérico (versões, SHAs, datas) — `--font-mono`, `tnum`.
- MicroLabel gold `FLIGHT RECORDER` uppercase 10px letter-spacing 0.18em.
- Step-line: SVG `path`, `stroke-width:1.5px`. Transições animam com o easing do doc 50
  (`cubic-bezier(0.16,1,0.3,1)`, 150–300ms) **atrás de `prefers-reduced-motion`** — reduz a
  step-line estática, sem movimento, quando o usuário pede.
- **Momento de deleite (honesto, não cafona):** ao abrir, a fita **desenha-se da esquerda para a
  direita** uma vez (stroke-dashoffset, ~600ms), como um sismógrafo lendo o passado. Comunica
  "estou reconstruindo" — e é literal, porque está. Respeitando reduced-motion (aparece pronta).

### 3.3 Por que fita-de-uma-série e não snapshot-em-data nem diff-entre-dois-pontos

- **Snapshot-em-data** (slider → estado da frota naquela data) exige reconstruir N séries
  simultâneas → é o Time-Travel completo (v14.3). Fora do orçamento.
- **Diff entre dois pontos** (escolher data A e data B, ver o que mudou) é poderoso mas **pede
  mais de uma série** para valer a pena, e a interação de dois-seletores é mais cara de fazer
  bem. v14.3.
- **Fita-de-uma-série** é o **mínimo** que ainda entrega o wow estrutural: uma dimensão, uma
  história, reconstrução visível, evidência anexada. É o vertical-slice correto.

---

## 4. Lei (determinístico) vs interpretado vs adiado para v14.3

### 4.1 O que é LEI (determinístico, exit-code binário) na v0

| Fato | Como se prova | Instrumento |
|------|---------------|-------------|
| O valor de `gsd=` em cada commit | `git show <H>:versions.lock \| grep '^gsd='` | exit-code (`antifragile-gates`) |
| A ordem cronológica dos eventos | `git log --format='%cI'` (committer date ISO) | git, append-only |
| Houve reversão por daemon | classificação de ator `^wip: autosync` → daemon (regra fixa do blueprint §9) | string-match determinístico |
| A fita reconstruída bate com o git | teste: reconstruir e re-derivar de `git show` deve dar SETS idênticos | exit 0 / exit 1 |

**Teste de invariante (gate, espelha o Zero-Leak):** `npm run test:recorder` re-deriva a fita do
git e compara com o render → exit 0 se idênticos, exit 1 se a UI divergiu da fonte. A fita **nunca
pode mostrar um pin que o git não confirma** — é o `--verify` do blueprint §8 aplicado ao passado.

### 4.2 O que é INTERPRETADO (rotulado como tal, nunca "lei")

- **A NARRATIVA** ("daemon reverteu o humano", "migração redux inverteu o semver"). A *causa* é
  inferência humana sobre os fatos — a UI a mostra como **anotação rotulada** (`⚠ provável
  reversão de autosync`), com link para a memória `version-reset-migration-semver-trap`, nunca
  como fato cravado. Os **fatos** (valores, datas, atores) são lei; a **história** que os conecta
  é leitura, e a UI mantém a distinção visível (igual `learning-channel-routing` separa fato de
  conduta).
- **"Estável há 8 dias"** é derivado (hoje − último-evento) — correto, mas rotulado como
  cálculo, não como selo.

### 4.3 O que FICA EXPLICITAMENTE para v14.3 (Time-Travel completo)

O Flight Recorder v0 **NÃO** entrega — e dizê-lo agora evita scope-creep:

1. **Slider que reconstrói a FROTA inteira** numa data (multi-ledger: SOAK + security + versões +
   estado de daemon simultâneos). v0 é **uma série**.
2. **Reconstrução do incidente deny-list 5/5→2/5→5/5** — bloqueada até a v14.2 emitir um **ledger
   estruturado** de contenção (§1.3, §7). v0 não tenta.
3. **Diff entre dois pontos no tempo** (seletor A/B). v0 é leitura de uma fita, não comparação
   parametrizada.
4. **Reconstrução cross-máquina via ref `mission-control`** — v0 lê só o git local do IdeiaOS.
5. **Black-box / flight-recorder de incidentes** (pacote forense automático no critical, blueprint
   §6.+1) — depende da detecção proativa (v14.2) e do Time-Travel completo (v14.3). v0 é
   manualmente-aberto, não auto-disparado.

O nome **"Flight Recorder v0"** carrega essa promessa: é o *embrião* do flight-recorder do
blueprint, entregando a **prova de conceito do wow estrutural** (reconstrução determinística
visível) numa única série, deixando o organismo completo para v14.3.

---

## 5. Reavaliação do vertical slice da v14.1 (o que cede espaço)

### 5.1 Diagnóstico: o Overview tem gordura de redundância de SOAK

O Overview da v14.1 (doc 50 §3.1, `02-PHASE-1-SPEC.md` §3) tem **dois** lugares falando de
releases/durabilidade:

- card **Releases/SOAK** (countdown até span≥1d + "PRONTO PARA TAG"), e
- o estado SOAK também aparece no **System Pulse** (heartbeat) e no card **Frota** (2/2 PASS).

O "PRONTO PARA TAG" é genuinamente útil, mas o **countdown** é um relógio — informação de baixa
densidade ocupando um slot de hero. **Esse é o slot que cede.**

### 5.2 A emenda cirúrgica (escopo discipline — toca só o pedido)

| Antes (v14.1 no blueprint) | Depois (v14.1 emendado) |
|----------------------------|--------------------------|
| Overview: Pulse (hero) + Frota + Segurança + **Releases/SOAK (card 1×1 com countdown)** + Atenção-Agora | Overview: Pulse (hero) + Frota + Segurança + **Releases/SOAK (card 1×1, ENXUTO: só "PRONTO PARA TAG" + `v13 2/2 ✓ span 0/1d`, sem o countdown grande)** + **FLIGHT RECORDER v0 (faixa nova, 6×1)** + Atenção-Agora |
| 3 telas + ⌘K | **3 telas + ⌘K + 1 faixa Flight Recorder no Overview** |

**O que NÃO muda (a prova de surfacing fica intacta):**

- **Frota, Cofre-Espelho, ⌘K** — inalterados. A "prova de surfacing" (J1 frota, J4 chave, J2 tag)
  que o blueprint §8 mede continua **inteira**: J2 ("pronto pra tag?") ainda é respondida pelo
  card Releases/SOAK enxuto + Pulse; só perde o countdown decorativo.
- **System Pulse hero** — continua sendo o coração (gold-border exclusivo). O Flight Recorder é
  explicitamente o **segundo** instrumento, sem moldura gold.
- **Zero-Leak gate, TtT, Trust-Rate** — inalterados; o Flight Recorder lê só `versions.lock`
  (não toca segredo), então **não amplia** a superfície do Zero-Leak.

**Custo de cronograma da emenda:** o Flight Recorder v0 reusa o reader determinístico (§2,
~meio-dia), uma fita SVG step-line (~1 dia com os tokens do doc 50 já prontos), e o teste de
invariante (~meio-dia). **~2 dias** dentro da janela de ~1–2 semanas da v14.1 — e **subtrai**
trabalho do card Releases (countdown removido). Net: cabe.

### 5.3 Critério de PRONTO adicional para a v14.1 (1 linha no gate)

Adicionar ao `02-PHASE-1-SPEC.md` §5:

> **A12 — Flight Recorder v0 reconstrói a fita do pin `gsd`** | `npm run test:recorder` → exit 0
> (a fita renderizada bate, SET a SET, com `git show <H>:versions.lock` em todos os commits) |
> e a faixa exibe ≥1 nó de reversão âmbar (o flip-flop real), sem inventar evento (`<absent>` onde
> o git não tem `gsd=`).

---

## 6. Honestidade: cabe no orçamento? (sim — e a alternativa se não coubesse)

**Cabe.** Razões verificadas:

1. **Fonte é git local** — não depende do ref `mission-control` nem do agentd maduro (§2). Menos
   acoplamento ao caminho crítico da v14.0.
2. **Dataset minúsculo** — 13 commits, 1 chave, 1 dimensão. Sem grafo, sem multi-ledger, sem
   parser de custo.
3. **Reusa o que já está pronto** — tokens black-gold (doc 50 §10), padrão de teste-invariante
   (Zero-Leak), classificação de ator (blueprint §9), padrão SVG sparkline (doc 50 §10.4).
4. **Subtrai** o countdown do card Releases (§5.2) — não é puro acréscimo.

**Estimativa: ~2 dias dentro da janela de ~1–2 semanas.**

### Alternativa mínima (se mesmo ~2 dias estourarem o orçamento)

Se a v14.1 estiver apertada, o **piso irredutível** que ainda entrega wow estrutural é uma
**fita estática (não-interativa)**: renderizar a step-line do pin `gsd` **sem** hover/clique/painel
lateral — só a forma de degrau + os 3 nós âmbar de reversão + label "3 reversões, fixado em
1.1.0". Custo: **~0.5 dia** (é um SVG path derivado do reader). Perde a evidência-no-hover, mas
**mantém o momento categórico**: o passado reconstruído deterministicamente, visível de relance.
Tudo o mais (interação, painel, diff) desce naturalmente para a v14.3 sem perda.

Abaixo desse piso, a recomendação honesta é **não** fazer um meio-Flight-Recorder mal-feito — é
melhor manter a v14.1 como está e shippar o Flight Recorder completo, bem-feito, junto do
Time-Travel na v14.3, do que entregar uma fita confusa que não comunica o wow. Mas isso seria
ceder à crítica — e os números dizem que não precisamos.

---

## 7. Achados que este doc registra (para não se perderem)

1. **Pré-requisito não-explícito do blueprint §10:** o "momento-prêmio" (reconstrução do incidente
   deny-list) é **impossível deterministicamente** enquanto o estado `5/5→2/5→5/5` viver só em
   prosa de commit + memória. A **v14.2 deve emitir um ledger estruturado** de contenção deny-list
   por produto (`epoch|iso|produto|deny_count|total|commit`), análogo ao SOAK/security ledger.
   Sem ele, o blueprint §10 promete um wow que a v14.3 não conseguirá entregar como "lei". **Marcar
   como requisito da v14.2**, não da v14.3.
2. **O `versions.lock` é o melhor primeiro event-store** justamente por ser o mais primitivo (git
   local) — sugere uma heurística geral para o Time-Travel completo: **priorizar séries cuja fonte
   é git puro** (versions.lock, qualquer arquivo versionado) antes de séries que dependem do ref
   federado ou de parsing de prosa.
3. **SOAK como fita-irmã na v14.3:** quando o Time-Travel completo chegar, a série SOAK (PASS/PASS,
   3 hosts) é a segunda fita natural — durabilidade ao lado de drift. Já verificada e parseável.

---

*Resolução PROPOSTA. Zero código. Emenda cirúrgica à v14.1 (§5). Próximo passo sugerido: levar a
emenda A12 + a faixa Flight Recorder ao `/spec` da capability `mission-control` e ao plano GSD da
fase v14.1; registrar o achado §7.1 como requisito da v14.2.*
