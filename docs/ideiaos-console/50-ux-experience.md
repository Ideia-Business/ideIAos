# IdeiaOS Mission Control — Experiência UX/UI

> **Doc 50 — Experiência (UX/UI).** Projeta a experiência completa do console: arquitetura de
> informação, os 7 ecrãs-chave, o layout detalhado do Overview ("visão de bordo de CTO"),
> sistema de estados (saudável/atenção/crítico), realtime, momentos de deleite, e o token-set
> OKLCH/black-gold suficiente para construir um mockup HTML fiel.
>
> **Persona de design:** Product Designer premiado — linguagem Linear / Vercel / Raycast.
> Dark-first, denso, legível, sem ruído. Nada de gradiente decorativo, nada de skeumorfismo.
> O dado é o herói; o chrome desaparece.
>
> **Princípio-âncora (do recon):** o IdeiaOS **já coleta** quase todos os sinais. O Mission
> Control é uma **camada de surfacing + controle** sobre substrato existente — não um problema
> greenfield de coleta. Isso muda tudo no design: o ecrã não "espera dados chegarem", ele
> **revela** um organismo que já está respirando. A estética tem que comunicar *vivo agora*.

---

## 0. Tese de design (opinião, não menu de opções)

Três decisões de design que NÃO estão em aberto. Surface assumptions primeiro
(`operating-discipline §1`):

1. **É um instrumento, não um relatório.** A referência mental não é "dashboard de BI" — é o
   **glass cockpit** de um jato e o **command palette** do Linear/Raycast. Densidade alta,
   resposta instantânea, teclado em primeiro lugar. Um CTO abre isto às 23h num dia de milestone
   e precisa ler o estado de TODO o ecossistema em **3 segundos** sem rolar. Se exige scroll para
   o "está tudo bem?", o design falhou.

2. **A paleta canônica é a black-gold do IdeiaOS, não o slate-green dos produtos.** O
   `graph-dashboard/html-formatter.js` (`THEME`) é a **fonte de verdade visual da camada
   OS/CLI**: `bg-base #000000`, `accent-gold #C9B298`, `text-primary #E8E8DF`, bordas
   `rgba(255,255,255,0.06)`. O Mission Control É camada-OS — herda a black-gold. O slate-green do
   `cfoai` é o template **estrutural** mais próximo (dark-first, shadcn, Recharts) e é de onde se
   copiam componentes, mas **o brand-hue muda para a marca-OS**. Ouro = autoridade, raridade,
   "isto é o painel do dono". Justificativa em §10.

3. **Control-plane, nunca cofre.** A regra `credential-isolation` é **piso inegociável**: nenhum
   valor de segredo transita pelo ecrã. O Cofre de Chaves mostra **metadata** (existe? idade?
   escopo? last-used? onde?) — nunca plaintext. Isso não é limitação: é **postura de design**. A
   tela de chaves comunica *controle por referência*, e isso por si só é um diferencial premium
   (a maioria dos "secret managers" expõe demais). O design celebra a ausência do valor, não a
   esconde.

> **Assunção material que pode estar errada — corrija agora:** assumo **deploy local-first**
> (o console roda na máquina do CTO, lê o filesystem direto via uma camada de leitura
> Node/Bun; sem servidor central). Toda a IA de realtime abaixo (polling de ledgers, `git log`,
> `launchctl`) pressupõe isso. Se houver intenção de hospedar isto multi-tenant/remoto, a seção
> de realtime e a de segurança mudam. → me corrija ou sigo com local-first.

---

## 1. Arquitetura de Informação

### 1.1 Modelo mental: 1 órbita + 6 luas

O CTO vive no **Overview** (a "órbita"). Os outros 6 ecrãs são **drill-downs** — cada um
responde a UMA pergunta que o Overview levanta mas não esgota. O Overview nunca é um índice
morto: cada card é uma **porta** para a lua correspondente.

```
                        ┌─────────────────────────────┐
                        │      MISSION CONTROL         │  ← órbita (visão de bordo)
                        │   "está tudo bem? o que      │
                        │    exige minha atenção?"     │
                        └──────────────┬──────────────┘
                                       │  cada card = porta
          ┌──────────┬──────────┬──────┴─────┬──────────┬──────────┐
          ▼          ▼          ▼            ▼          ▼          ▼
     ┌────────┐ ┌────────┐ ┌─────────┐ ┌────────┐ ┌────────┐ ┌──────────┐
     │MÁQUINAS│ │CONTAS  │ │PROJETOS │ │COFRE   │ │CONEXÕES│ │PRODUTIV. │
     │        │ │& IAs   │ │& USERS  │ │CHAVES  │ │  MCP   │ │          │
     │"a frota│ │"quem   │ │"o que   │ │"o que  │ │"o que  │ │"quanto   │
     │ está   │ │ está   │ │ estamos │ │ pode   │ │ está   │ │ valor    │
     │ viva?" │ │conectado│ │construindo"│ vazar?"│ │ligado?"│ │ entregue"│
     └────────┘ └────────┘ └─────────┘ └────────┘ └────────┘ └──────────┘
```

### 1.2 Navegação

- **Rail lateral fixo, 64px colapsado / 232px expandido** (à la Linear). Ícones Lucide + label.
  No estado colapsado, só ícones com tooltip gold no hover. Ativo = barra gold de 2px à esquerda
  + ícone em `--accent-gold`, resto em `--text-tertiary`.
- **Command palette `⌘K`** — o coração da navegação rápida. Não é só "ir para tela": executa
  **ações de controle** (pausar autosync, rodar idea-doctor, re-selar segurança, kickstart de um
  daemon). Ver §3.3 (é um momento-wow).
- **Breadcrumb mínimo no topo** só nos drill-downs (`Mission Control / Máquinas / MacBook-Air-2`).
  O Overview não tem breadcrumb — ele é a raiz.
- **Sem tabs horizontais.** Tabs competem com a densidade. Cada lua é uma rota inteira.

### 1.3 Ordem das luas no rail (intencional, por frequência de atenção do CTO)

| # | Ícone Lucide | Rota | Pergunta | Frequência |
|---|---|---|---|---|
| — | `gauge` | `/` Overview | está tudo bem? | sempre (home) |
| 1 | `server` | `/machines` Máquinas | a frota está viva? | diária |
| 2 | `folder-git-2` | `/projects` Projetos & Users | o que construímos? | diária |
| 3 | `activity` | `/productivity` Produtividade | quanto valor saiu? | semanal |
| 4 | `key-round` | `/vault` Cofre (metadata) | o que pode vazar? | semanal/incidente |
| 5 | `plug` | `/connections` Conexões MCP | o que está ligado? | quinzenal/auditoria |
| 6 | `users` | `/accounts` Contas & IAs | quem está conectado? | mensal/onboarding |

> Decisão: "Contas & IAs" vai por último no rail apesar de ser pedido cedo no brief — é o ecrã de
> **menor frequência de consulta** (muda no onboarding de máquina/conta, não no dia-a-dia). O rail
> ordena por *quão frequentemente o dono olha*, não por importância nominal.

---

## 2. Sistema de Estados (a gramática visual inteira deriva disto)

Três estados. **Toda** célula, card, badge e linha do console fala esta língua. Um CTO aprende a
gramática uma vez e ela vale em todo lugar.

| Estado | Token | Cor (hex base) | OKLCH | Significado | Onde aparece |
|---|---|---|---|---|---|
| **Saudável** | `--status-success` | `#4ADE80` | `oklch(0.80 0.18 150)` | nominal, fresco, passou | dot 6px, texto secundário |
| **Atenção** | `--status-warning` | `#FBBF24` | `oklch(0.83 0.16 85)` | stale, drift, idade limítrofe | dot pulsante lento, halo |
| **Crítico** | `--status-error` | `#F87171` | `oklch(0.70 0.18 25)` | falhou, egrégio, parado | dot pulsante rápido + ring |
| **Info/inativo** | `--status-info` / `--text-muted` | `#60A5FA` / `#6B6B63` | — | neutro, desconhecido, off | texto muted |

**Regras de aplicação (não-negociáveis para a fidelidade do mockup):**

1. **O dot é a unidade atômica de saúde.** Círculo de 6px. Saudável = sólido, opacidade 1. Atenção
   = `box-shadow: 0 0 0 3px rgba(251,191,36,0.15)` + animação `pulse` 2s. Crítico = halo vermelho
   + `pulse` 0.9s (mais rápido = mais urgente; a *frequência* codifica a severidade, à la
   monitor cardíaco).
2. **Cor só para semântica, nunca decoração.** Verde/âmbar/vermelho aparecem SÓ por estado. Tudo
   o mais é a escala neutra (preto → ouro → cinzas). Isso faz o vermelho **gritar** quando aparece
   — porque é a única coisa colorida na tela. Um ecrã saudável é quase monocromático preto-ouro;
   um problema queima.
3. **Ouro ≠ estado.** `--accent-gold` é hierarquia/seleção/marca, nunca "tudo certo". "Certo" é
   verde discreto. Confundir os dois é o erro nº1 a evitar no mockup.
4. **Estado agregado rola para cima.** O dot de uma máquina = pior estado dos seus checks. O dot
   do card "Frota" no Overview = pior estado das máquinas. O **dot global no header** = pior
   estado de TODO o sistema. O CTO lê o header primeiro; se está verde, pode relaxar.

```css
@keyframes pulse-warn { 0%,100%{box-shadow:0 0 0 3px rgba(251,191,36,.18)} 50%{box-shadow:0 0 0 5px rgba(251,191,36,.06)} }
@keyframes pulse-crit { 0%,100%{box-shadow:0 0 0 3px rgba(248,113,113,.30)} 50%{box-shadow:0 0 0 6px rgba(248,113,113,.05)} }
.dot{width:6px;height:6px;border-radius:50%;display:inline-block}
.dot--ok{background:var(--status-success)}
.dot--warn{background:var(--status-warning);animation:pulse-warn 2s ease-in-out infinite}
.dot--crit{background:var(--status-error);animation:pulse-crit .9s ease-in-out infinite}
.dot--idle{background:var(--text-muted)}
```

---

## 3. ECRÃ 1 — Mission Control (Overview) · "visão de bordo de CTO"

Este é o ecrã que justifica o produto. Detalhe máximo aqui.

### 3.1 Princípio de layout: **bento-grid de comando**, acima da dobra

Tudo que importa cabe num viewport de **1440×900 sem scroll**. Estilo bento (do `ui-ux-pro-max`
para "admin/internal tool"): blocos de tamanhos diferentes, hierarquia por área. Grid base de
**12 colunas, gutter 16px, padding externo 24px**, content-width máx 1440px centralizado.

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ HEADER (sticky, 56px) ── ● IDEIAOS MISSION CONTROL    [veredito global]   ⌘K  🌙 │
├────┬─────────────────────────────────────────────────────────────────────────────┤
│ R  │  ┌──────────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │
│ A  │  │  SYSTEM PULSE  (hero) │ │ FROTA        │ │ SEGURANÇA    │ │ RELEASES    │ │
│ I  │  │  ▓▓▓▓▓ heartbeat ▓▓▓  │ │ 2/2 máquinas │ │ tier: FRESCO │ │ v13 ◷ 18h   │ │
│ L  │  │  "tudo nominal"       │ │ ● ● both PASS│ │ ● 0d revisão │ │ SOAK 2/2    │ │
│    │  │  3 col × 2 row        │ │              │ │              │ │             │ │
│ 64 │  └──────────────────────┘ └──────────────┘ └──────────────┘ └─────────────┘ │
│ px │  ┌─────────────────────────────────┐ ┌──────────────────────────────────────┐│
│    │  │ PROJETOS (5)  velocity sparkline│ │ ATENÇÃO AGORA (action feed)          ││
│    │  │ nfideia ●  ideiapartner ●  ...   │ │ ⚠ git-autosync log sem rotação       ││
│    │  │ commits humanos hoje: ▁▃▅▇▅▃     │ │ ⚠ Lovable deny-list: 5/5 ✓ (resolvido)││
│    │  │ 6 col × 1.5 row                 │ │ ● tudo o mais nominal                 ││
│    │  └─────────────────────────────────┘ └──────────────────────────────────────┘│
│    │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────────────────────┐ │
│    │  │AUTOMAÇÕES│ │ CONTAS   │ │ MCP      │ │ ATIVIDADE AO VIVO (live ticker)  │ │
│    │  │3 daemons │ │ 5 prov.  │ │ 2 ativos │ │ Mac-mini · commit há 2min · work │ │
│    │  │● ● ●     │ │ ● Claude │ │ ● ●      │ │ MacBook · idea-doctor PASS · now │ │
│    │  └──────────┘ └──────────┘ └──────────┘ └──────────────────────────────────┘ │
└────┴─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 Inventário de widgets do Overview (com copy exata)

#### A) Header global (sticky, 56px, `bg rgba(10,10,10,0.9)` + `backdrop-blur(12px)`)

- **Esquerda:** dot global (atômico, §2) + wordmark `IDEIAOS` em `--text-primary` peso 600 +
  `MISSION CONTROL` em `--accent-gold`, `letter-spacing: 0.18em`, `text-transform: uppercase`,
  11px. Esta é a assinatura tipográfica do produto.
- **Centro:** **veredito global** — uma frase, não um número. Copy condicional:
  - tudo verde → `“Todos os sistemas nominais.”` em `--text-secondary`
  - ≥1 warn → `“2 itens pedem atenção.”` em `--status-warning`, clicável (rola ao feed)
  - ≥1 crit → `“⚠ 1 sistema crítico — autosync parado no Mac-mini.”` em `--status-error`
- **Direita:** botão `⌘K` (pill com borda sutil), relógio realtime `HH:MM:SS` em mono +
  toggle de tema (lua/sol) — mesmo dark-first, o toggle existe por hábito.

#### B) SYSTEM PULSE (hero card, 3×2, o maior bloco — momento-wow nº1)

O card-âncora. Ocupa o canto superior-esquerdo, o ponto de fixação ocular natural.

- Fundo `--bg-surface #0A0A0A`, borda `--border-gold rgba(201,178,152,0.25)` (o ÚNICO card com
  borda dourada — sinaliza "este é o coração").
- **Heartbeat line:** uma linha de SVG ECG/sparkline animada que pulsa em tempo real, **derivada
  do intervalo real entre heartbeats do SOAK ledger + commits do autosync**. Não é decoração: a
  amplitude/frequência reflete atividade real do ecossistema. Sistema saudável = batida regular
  verde. Algo crítico = a linha fica vermelha e a batida arritmica. **Copy abaixo da linha:**
  `“ECOSSISTEMA VIVO”` (uppercase, 10px, gold) + estado: `“último sinal há 2 min · MacBook-Air-2”`.
- **Métrica gigante central:** `2` máquinas + `5` projetos + `75` checks OK, em layout de 3 números
  grandes (`font-size: 40px`, mono, `--text-primary`) com micro-label abaixo de cada
  (`MÁQUINAS` `PROJETOS` `CHECKS OK`, 9px gold uppercase).
- **Rodapé:** `idea-doctor: 75 OK · 0 WARN · 0 FAIL` com os números coloridos por estado.

#### C) FROTA (card 1×1, porta → Máquinas)

- Micro-header `FROTA` (gold uppercase 10px) + ícone `server` 14px tertiary.
- Linha grande: `2 / 2` em mono 28px + label `MÁQUINAS ATIVAS`.
- Duas linhas-máquina: `● MacBook-Air-2 · PASS · agora` / `● Mac-mini · PASS · há 1h`. Dot por
  máquina, hostname truncado, último heartbeat relativo.
- Hover: card sobe 2px (`translateY(-2px)`), borda passa a gold-subtle, cursor pointer.

#### D) SEGURANÇA (card 1×1, porta → nenhuma tela própria; abre painel lateral de freshness)

- `SEGURANÇA` + `shield-check` 14px.
- **Badge de tier gigante:** `FRESCO` em verde / `STALE` em âmbar / `EGRÉGIO` em vermelho,
  pill grande. Vem direto de `check-security-freshness.sh --tier`.
- Sub-linha: `revisão há 0 d · score 0 · @bootstrap` em mono tertiary.
- Mini-barra de "idade até stale": progresso de 0→90d, gold preenchendo. Comunica *quanto tempo
  resta* antes de virar amarelo. (No `idea-doctor §14` isto é só WARN — o card reflete isso: nunca
  fica vermelho-bloqueante, no máximo âmbar.)

#### E) RELEASES / SOAK (card 1×1)

- `RELEASES` + `git-tag` 14px.
- Linha-foco no milestone PARCIAL mais quente: `v13 · aguarda tag` + countdown `◷ 18h 12m` (até o
  span SOAK ≥1d ser satisfeito — derivado do delta de epochs do ledger, ver
  learning `soak-span-is-record-delta-not-wallclock`).
- Barra SOAK: `máquinas 2/2 ✓ · span 0/1d`. Quando os dois ✓ → o card pisca gold e a copy vira
  `“PRONTO PARA TAG”` (momento-wow nº4, ver §3.4).
- Lista compacta dos últimos shipped: `v12 ✓ · v11 ✓ · v9 ✓` em tertiary.

#### F) PROJETOS (card largo 6×1.5, porta → Projetos & Users)

- `PROJETOS` + contador `5`.
- **Linha de chips por projeto** (um chip por repo): cada chip = dot de estado + nome +
  mini-stat. `● nfideia · 20/dia` `● ideiapartner · 15/dia` `● cfoai · 3` `● lapidai · 1`
  `● IdeiaOS · 17/dia`. Estado do chip = saúde do último idea-doctor/autosync daquele repo.
- **Sparkline de velocity** abaixo: commits **humanos** (filtrados de bots/autosync — ver
  recon, é o sinal REAL) dos últimos 14 dias, área gold translúcida. Hover num ponto → tooltip
  `Jun-19 · 99 commits humanos`.
- Micro-copy honesta: `velocity = commits humanos (exclui bots/autosync)`.

#### G) ATENÇÃO AGORA (card largo, action feed — o "to-do do CTO")

O único lugar do Overview que **prioriza por urgência**, não por categoria. Ordena: crítico →
atenção → resolvido-recente. Cada item é acionável (botão inline).

- Item crítico: `⚠ autosync parado no Mac-mini há 3h` + botão `Retomar` (executa
  `autosync-pause.sh off` via command-plane).
- Item atenção: `⚠ git-autosync.log sem rotação (linear)` + botão `Ver`.
- Item resolvido (some em 24h, com check verde): `✓ Lovable deny-list 5/5 — remediado hoje`.
- Vazio ideal: estado-vazio elegante — `“Nada pede sua atenção. ●”` centralizado, dot verde,
  `--text-tertiary`. (Estados-vazios bem-feitos são deleite, ver §3.4.)

#### H) Cluster de cards pequenos (linha inferior, 4 cards 3×1)

- **AUTOMAÇÕES** (→ painel daemons): `3 daemons` + 3 dots `gitautosync ● envsync ● refresh ●`.
  Estado vem de `launchctl list | grep ideiaos` (PID = verde, `-` = muted/atenção conforme
  schedule esperado).
- **CONTAS** (→ Contas & IAs): `5 provedores` + linha de logos-dot: `● Claude ● OpenRouter
  ● GitHub ● Supabase ● Vercel`.
- **MCP** (→ Conexões): `2 ativos` + `chrome-devtools ● context7 ●` + nota `19 mutantes em deny`.
- **ATIVIDADE AO VIVO** (live ticker, ver §3.3): feed rolante dos últimos eventos cross-máquina
  derivados do `git log` (commits WIP do autosync trazem o hostname).

### 3.3 Realtime — como o Overview "respira"

A diferença entre "dashboard" e "instrumento" é o realtime. Três camadas de atualização
(local-first; sem servidor — a camada de leitura faz polling do filesystem/git):

| Camada | Fonte | Cadência | Efeito visual |
|---|---|---|---|
| **Pulse** | epoch do último heartbeat SOAK + último commit autosync | 1s (relógio) / 5s (re-leitura) | heartbeat-line anima continuamente; relógio do header conta |
| **Ledgers** | `.planning/soak/*.log`, `.security/review-ledger.log`, `versions.lock` | 15s | tier badge, FROTA, RELEASES re-renderizam com fade 200ms |
| **Atividade** | `git log --pretty` dos 6 repos + `~/.ideiaos/observations/*.jsonl` (tail) | 10s | live ticker adiciona linha no topo com slide-in; máquina "acende" |

**Live ticker (card H-Atividade)** — momento-wow nº2:
- Cada novo evento entra com `slide-in-from-top` + flash gold de 400ms que desvanece.
- Formato: `[dot-estado] [host] · [ação] · [branch] · [há Xmin]`.
- Ex: `● Mac-mini · commit feat(v13) · work · há 2min` / `● MacBook · idea-doctor PASS · now`.
- A máquina que acabou de agir **pulsa** no card FROTA e no ecrã Máquinas por 3s (cross-highlight).
- "Quem está ativo agora" = derivado do evento mais recente por host (proxy honesto; o recon nota
  que não há sinal nativo de presença — o design assume isso e usa o último-evento como proxy,
  com copy honesta `“ativo há 2 min”`, nunca `“online”`).

**Command palette `⌘K`** — momento-wow nº3:
- Abre overlay centrado, `bg rgba(10,10,10,0.95)` + blur, input com cursor gold piscando.
- Duas seções: **Ir para** (telas) e **Executar** (ações de controle). Cada ação executa um
  comando real do recon e devolve resultado inline (toast):
  - `Pausar autosync` → `autosync-pause.sh on "via Mission Control"`
  - `Retomar autosync` → `autosync-pause.sh off`
  - `Rodar idea-doctor` → spawn, parseia OK/WARN/FAIL, mostra no toast
  - `Re-selar segurança` → confirma + `check-security-freshness.sh --record PASS @security-reviewer`
  - `Kickstart daemon X` → `launchctl kickstart …`
  - `Forçar sync agora` → `launchctl kickstart … gitautosync`
- **Guard-rail de design:** ações destrutivas/irreversíveis (re-selar, pausar) exigem `Enter`
  segurado 600ms ou um segundo `Enter` de confirmação — o "armar antes de disparar" do glass
  cockpit. E o palette NUNCA oferece operações `@devops`-exclusivas sem indicar isso (push/PR
  ficam fora — respeitam `agent-authority`).

### 3.4 Os 5 momentos de deleite ("wow")

1. **Heartbeat vivo (Pulse hero).** A linha ECG não é mock — bate no ritmo real do ecossistema.
   Abrir o console e VER o sistema pulsando comunica "isto está vivo" antes de qualquer número.
   Quando algo fica crítico, a batida vira vermelha e arrítmica — visceral, pré-cognitivo.

2. **Live ticker com cross-highlight.** Um commit chega do Mac-mini → a linha desliza no ticker E
   o card da máquina pulsa gold simultaneamente. O CTO *vê* a frota agir em tempo real, sem refresh.

3. **Command palette como cockpit.** `⌘K` → não só navega, **comanda** o substrato. Pausar um
   daemon, re-selar segurança, rodar o doctor — tudo do teclado, com resultado inline. Sensação
   Raycast: o poder está a um atalho.

4. **"Pronto para tag" celebration.** Quando um milestone PARCIAL satisfaz SOAK (2 máquinas +
   span ≥1d), o card RELEASES faz uma micro-celebração: pulso gold + a copy vira
   `“v13 PRONTO PARA TAG”` + um confete sutil gold (3 partículas, 600ms, respeitando
   `prefers-reduced-motion`). Recompensa a paciência do gate sem ser cafona.

5. **Estados-vazios com personalidade.** "Nada pede sua atenção. ●" com dot verde no centro de um
   feed vazio. O Cofre sem vazamentos: `“Zero segredos no contexto. Como deve ser.”` Pequenas
   frases que reforçam a doutrina (credential-isolation) e fazem o silêncio parecer vitória, não
   ausência de conteúdo.

> **Disciplina de motion (`enforce-simplicity`):** todas as animações 150–300ms, easing
> `cubic-bezier(0.16,1,0.3,1)` (out-expo, à la Linear), e TODAS atrás de `prefers-reduced-motion:
> reduce` → degradam para fade simples ou nada. Pulse de dots permanece (é semântico, não
> decorativo) mas com amplitude reduzida. Sem parallax, sem gradiente animado de fundo.

---

## 4. ECRÃ 2 — Máquinas ("a frota")

**Pergunta:** quais máquinas existem, estão vivas, saudáveis, e em que commit/versão?

### Layout
- **Topo:** faixa de "cards de máquina" lado a lado (1 por host conhecido, derivado do SOAK
  ledger + `git log` hostnames). Cada card de máquina:
  - Header: ícone `laptop`/`server` + hostname (`MacBook-Air-2`, `Mac-mini-de-Gustavo`) + dot.
  - **"Vital signs":** último heartbeat (relativo + absoluto no hover), `idea-doctor: PASS`,
    `regression: PASS`, commit atual (sha curto + link), branch.
  - **Mini-timeline de heartbeats** (últimos 7 dias): faixa de quadradinhos estilo
    GitHub-contributions, mas com 3 estados (verde PASS / âmbar sem-heartbeat-no-dia / vazio).
  - Badge de versões: `aiox 5.2.9 · gsd 1.1.0` cruzado com `versions.lock` — se divergir, badge
    fica âmbar com `drift` (cruzamento declarativo×instalado, ver
    learning `declarative-manifest-vs-imperative-list-drift`).
- **Inconsistência de hostname surfaceada honestamente:** o recon nota `Mac-mini` aparecer também
  como `192` (IP-as-hostname). O card mostra `Mac-mini-de-Gustavo` com um sub-badge
  `aka 192` + tooltip explicando a deduplicação — não esconde o ruído, explica-o.
- **Abaixo:** tabela densa de heartbeats brutos (todos os ledgers SOAK), colunas
  `host · milestone · iso · doctor · regression · commit`, mono, ordenável, com filtro por host.
- **Empty/single-machine:** se só 1 host reportou, banner âmbar
  `“Apenas 1 máquina ativa — SOAK exige ≥2 para tag.”`

### Controles (command-plane)
- `Forçar sync nesta máquina` (`launchctl kickstart gitautosync`).
- `Pausar/retomar autosync` (global, com motivo).
- `Rodar idea-doctor` (resultado parseado e gravado no histórico do card).
- **Importante:** controles de OUTRA máquina (Mac-mini a partir do MacBook) são **read-only** —
  o recon confirma que não há canal de comando cross-máquina; o card do Mac-mini mostra
  `controles locais indisponíveis (cross-máquina read-only)` com tooltip honesto.

---

## 5. ECRÃ 3 — Projetos & Usuários ("o que construímos")

**Pergunta:** o que cada produto é, quão ativo está, quem trabalha nele.

### Layout
- **Grid de cards de projeto** (nfideia, ideiapartner, cfoai-grupori, lapidai, IdeiaOS):
  - Header: nome + stack-badges (`Vite · React · TS · Supabase`) + dot de saúde + link
    `git remote` (abre GitHub) e link Supabase `project_id` (metadata, nunca credencial).
  - **3 mini-KPIs** (reusa o padrão `KPICard` do nfideia): `commits humanos (30d)` ·
    `migrações Supabase` · `sessões Claude (ativas)`. Trend ↑/↓ vs período anterior.
  - **Heat-strip de atividade**: commits humanos/dia últimos 30d (filtrados de bot/autosync).
  - **Atores**: avatares-dot dos contributors humanos reais (`Gustavo · CTO`,
    `Dev Ideia Business`) com % de commits. Bots/autosync explicitamente **separados** numa
    linha `não-humano: Lovable bot · GitHub Actions · autosync` para não inflar produtividade.
  - Flag `Lovable` quando aplicável + status do último deploy (via `lovable-mcp.sh verify-deploy`,
    read-only).
- **Drill-down de projeto** (clicar no card): timeline de sessões (transcripts JSONL, só
  meaningful = human_turns>5), distribuição feat/fix/docs, branches ativos, último milestone.
- **Honestidade de dados:** cfoai/lapidai têm 4/1 sessões Claude — provável uso de Cursor/Lovable
  como IDE primário. O card mostra `IDE primário: provável Cursor/Lovable` em vez de fingir que
  o sinal de transcript é completo.

### Usuários
- Sub-aba "Equipe": lista de atores humanos únicos derivados do `git log` (emails normalizados —
  `gustavo@redeideia` = `gustavolpaiva`, mesmo humano). Para cada: projetos que toca, commits
  humanos no período, último commit. **Gap honesto na copy:** `“usuários FINAIS dos produtos não
  são rastreados aqui (exigiria credenciais de cada Supabase — viola credential-isolation)”`.

---

## 6. ECRÃ 4 — Cofre de Chaves (SÓ metadata) · "o que pode vazar"

**Pergunta:** quais segredos existem, onde, há quanto tempo, com que escopo — **sem nunca ver o
valor**. Este ecrã é uma declaração de princípio (`credential-isolation`).

### Layout
- **Banner-doutrina no topo** (fixo, sutil, gold-border): `“Control-plane, não cofre. Este painel
  mostra metadata — nome, presença, idade, escopo. Nenhum valor de segredo transita por aqui.
  Por design.”` Com ícone `shield-off`/`eye-off`. É o estado-vazio celebrado (§3.4-5).
- **Tabela-matriz: variáveis × projetos.** Linhas = variáveis do catálogo (`.env.example`
  canônico). Colunas = projetos. Célula = **presença** (`●` presente / `○` ausente / `–` n/a),
  NUNCA o valor. Hover na célula → `presente · modificado há 3d · escopo: admin DB`.
- **Coluna de risco** por variável (do recon): `SERVICE_ROLE_KEY` = badge `CRÍTICO` vermelho,
  `ANON_KEY` = `baixo` muted, `NODE_ENV` = `não-segredo` cinza. A linha crítica tem um leve
  realce vermelho de fundo `rgba(248,113,113,0.04)`.
- **Alertas derivados** (control-plane, nunca valor):
  - var órfã: presente no `.env` mas ausente no `.env.example` → âmbar `órfã`.
  - var antiga: `.env` não modificado há >N dias numa var crítica → âmbar `rotação?`.
  - `.env` commitado: `git status` detecta tracking → vermelho `EXPOSTO NO GIT`.
- **Painel lateral por variável** (clique): metadata completa — onde aparece (lista de arquivos),
  idade (`stat -f %m`), último sync via envsync (hash curto de 12 chars, nunca valor), risco,
  e **referências no código** (onde `$VAR` é citada por nome). Nada de valor, jamais.
- **Caso `IDEIA_CHAT_SYSADMIN_PASSWORD`:** o ecrã NÃO re-flagga (decisão do usuário — teste, não
  produção). Mostra com badge `aceito · teste` e tooltip referenciando a decisão. (Memória
  `project-ideia-chat-test-secret-acceptable`.)

### Controle
- `Marcar para rotação` (cria lembrete, NÃO roda rotação — automatizar o lembrete, nunca o
  carimbo, ver learning `automate-the-reminder-not-the-integrity-stamp`).
- Sem nenhuma ação que leia/escreva valor. O ecrã é deliberadamente "impotente" sobre o segredo —
  e isso é a feature.

---

## 7. ECRÃ 5 — Conexões MCP ("o que está ligado")

**Pergunta:** quais MCPs estão ligados, em que IDE, e estão dentro da higiene?

### Layout
- **Inventário por IDE** (3 colunas: Claude Code · Cursor · Lovable):
  - Claude: `chrome-devtools ●`, `context7 ●` (de `claude mcp get`) + lista de desabilitados.
  - Cursor: `chrome-devtools · lovable · context7 · resend` (de `~/.cursor/mcp.json`) + plugins
    OAuth por projeto (Stripe/Vercel/Supabase).
  - Lovable: card de contenção — `read-only ✓ · 19 tools mutantes em deny`.
- **Health bar de higiene MCP** (`mcp-hygiene`): contador `2/10 ativos · 12/80 tools visíveis` com
  barra; verde se sob limite, âmbar se perto. Surface da regra dos ≤10 ativos / ≤80 tools.
- **Auditoria de contenção Lovable** (porta para o histórico da regressão 5/5→2/5→5/5): matriz
  `produto × deny-list aplicada`, cada célula ✓/✗. Esta foi uma regressão real — o ecrã a
  monitora continuamente como health-check. Se algum cair, vira crítico no Overview.
- **Risco por MCP** (do `mcp-hygiene`): badge de classificação (Critical/High/Medium/Low) e flag
  de "tool mutante sem deny" como achado âmbar.
- **Proliferação de sessões tmp** (recon, risco med): contador `~30 sessões Cursor com auth
  Vercel/Stripe armazenada` + botão `Ver` — surfaceia a superfície sem expor token.

### Controle
- **Read-only por padrão.** Gestão de MCP é `@devops`-exclusiva (`agent-authority`). O ecrã
  mostra, não modifica. Qualquer botão de "habilitar/desabilitar" leva a um modal que **gera o
  comando** para o @devops rodar, com aviso explícito — nunca executa direto. (Respeita a
  fronteira de autoridade; o console não vira @devops sintético.)

---

## 8. ECRÃ 6 — Contas & IAs ("quem está conectado")

**Pergunta:** quantas contas de cada provedor de IA/infra, em que estado.

### Layout
- **Grid de cards por provedor** (Claude/Anthropic, OpenRouter/DeepSeek, OpenAI, GitHub, Supabase,
  Vercel, + auxiliares):
  - Claude: conta OAuth (`gustavo@redeideia.com.br`), modelo ativo (`opus[1m]`), effort
    (`xhigh`) — de `~/.claude.json` + `settings.json`. Token vive no keychain → badge
    `auth: keychain (fora do contexto) ✓`.
  - GitHub: `gh auth status` → contas (`DevIdeiaBusiness` ativa, `gustavolpaiva` inativa), scopes
    (`repo · workflow · read:org`), protocolo. Token = keychain.
  - Supabase: 4 projetos com `project_id` + presença do `access-token` (`test -s`, nunca valor).
  - Vercel/OpenRouter/etc.: presença de token por referência + onde (`.env` de qual projeto).
- **"Mapa de conexões":** um diagrama compacto (reusa o `aiox graph --html`/vis-network como
  precedente técnico) — máquinas → contas → projetos, com as cores de agente nomeadas do `THEME`.
  Nós dourados = contas, nós cinza = projetos, arestas = "usa". Hover destaca o cluster.
- **Inventário consolidado de contas** que o recon nota como gap: o ecrã *constrói* esse
  inventário (Claude ~/.claude.json + Cursor configs + GitHub gh + Lovable MCP) num único quadro —
  resolvendo o gap "não há inventário consolidado".

### Controle
- `Verificar auth` por provedor (roda `gh auth status` / `supabase projects list` — metadata).
- Sem login/logout pelo console (toca credencial → fora de escopo por `credential-isolation`).

---

## 9. ECRÃ 7 — Produtividade ("quanto valor foi entregue")

**Pergunta:** quanto trabalho REAL saiu — sem métricas de vaidade.

### Princípio (do recon, crítico): **sinal real vs vaidade**
O ecrã inteiro é desenhado para **resistir à vaidade**. Banner explícito no topo:
`“Medimos entrega verificada, não volume. Commits de bot/autosync, tamanho de transcript e
contagem bruta de sessões NÃO contam.”`

### Layout
- **4 KPIs de entrega real** (topo, reusa `KPICard`):
  1. `Commits humanos / semana` (exclui bot+autosync+wip).
  2. `Milestones SOAK-validados` (a ÚNICA "entrega verificada cross-máquina" do OS).
  3. `Sessões cognitivas` (human_turns>5, não contagem bruta).
  4. `Freshness de segurança` (proxy de responsabilidade técnica no tempo).
- **Gráfico principal:** velocity de commits humanos por dia, **stacked por tipo**
  (feat/fix/docs/refactor), 30–90d, Recharts area. Cores semânticas (feat=gold, fix=verde,
  docs=tertiary). Picos de milestone (99–110/dia) anotados.
- **Heatmap por projeto × dia:** intensidade = commits humanos. Vê-se de relance qual produto
  esteve quente em que dia.
- **Cadência de release do OS:** timeline de milestones v2→v13 com datas de tag — KPI de ritmo do
  próprio IdeiaOS.
- **Maturidade do agente** (instincts agregados): por domínio (git/bash/ts/sql), confidence média
  e evidence_count. Proxy honesto de "onde o agente mais aprendeu". Copy: `“telemetria
  comportamental — não é conduta ao vivo”` (respeita `learning-channel-routing`).
- **Distinção de atores** em TODA métrica: toggle `humano / IA / autosync` para filtrar. O default
  é só-humano.

### Controle
- Sem ações de escrita (é analítico). Export `CSV/PNG` do gráfico. `Rodar idea-doctor` para
  refrescar o health snapshot.
- **Gap honesto:** sem ACs/stories (produtos usam GSD+commits direto). Sem usuários finais
  (credential-isolation). O ecrã declara esses limites em vez de inventar métrica.

---

## 10. Design Tokens — set completo para o mockup HTML

### 10.1 Base canônica (black-gold, da camada OS — `graph-dashboard/THEME`)

```css
:root {
  /* ── brand hue (OKLCH) — ouro IdeiaOS ─────────────────────────────── */
  --brand-hue: 75;            /* ouro/âmbar quente — accent #C9B298 ≈ oklch(0.78 0.045 80) */
  --brand-chroma: 0.045;      /* ouro dessaturado, sóbrio (não "dourado cafona") */

  /* ── backgrounds (preto absoluto + superfícies) ───────────────────── */
  --bg-base:      #000000;                 /* oklch(0 0 0)        — fundo da app */
  --bg-surface:   #0A0A0A;                 /* oklch(0.13 0 0)     — cards */
  --bg-surface-2: #111111;                 /* card aninhado / hover */
  --bg-overlay:   rgba(10,10,10,0.90);     /* header/modal + backdrop-blur */

  /* ── texto (escala quente neutra) ─────────────────────────────────── */
  --text-primary:   #E8E8DF;   /* oklch(0.92 0.008 95) — números/títulos */
  --text-secondary: #B8B8AC;   /* oklch(0.76 0.010 95) — corpo */
  --text-tertiary:  #8A8A7F;   /* oklch(0.58 0.010 95) — labels/meta */
  --text-muted:     #6B6B63;   /* oklch(0.46 0.008 95) — inativo/placeholder */

  /* ── ouro (hierarquia/marca/seleção — NUNCA estado) ───────────────── */
  --accent-gold:        #C9B298;            /* oklch(0.78 0.045 80) */
  --accent-gold-strong: #DAC4A8;            /* hover/foco do gold */
  --border-gold:        rgba(201,178,152,0.25);
  --border-gold-strong: rgba(201,178,152,0.50);

  /* ── estados (semântica — ver §2) ─────────────────────────────────── */
  --status-success: #4ADE80;   /* oklch(0.80 0.18 150) */
  --status-warning: #FBBF24;   /* oklch(0.83 0.16 85)  */
  --status-error:   #F87171;   /* oklch(0.70 0.18 25)  */
  --status-info:    #60A5FA;   /* oklch(0.70 0.14 250) */

  /* ── bordas / divisores ───────────────────────────────────────────── */
  --border:        rgba(255,255,255,0.06);
  --border-subtle: rgba(255,255,255,0.04);
  --border-focus:  var(--border-gold-strong);

  /* ── cores de agente (do THEME — usar no mapa de conexões/MCP) ─────── */
  --agent-dev:#22c55e; --agent-sm:#f472b6; --agent-po:#f97316;
  --agent-qa:#eab308;  --agent-architect:#8b5cf6;
  --agent-devops:#ec4899; --agent-analyst:#06b6d4;

  /* ── raio / sombra / blur ─────────────────────────────────────────── */
  --radius-sm: 4px; --radius-md: 8px; --radius-lg: 12px; --radius-pill: 999px;
  --shadow-card:   0 1px 2px rgba(0,0,0,0.4);
  --shadow-pop:    0 8px 24px rgba(0,0,0,0.55);
  --shadow-gold:   0 0 0 1px var(--border-gold), 0 8px 32px rgba(201,178,152,0.06);
  --blur: 12px;

  /* ── espaçamento (escala 4px) ─────────────────────────────────────── */
  --sp-1:4px; --sp-2:8px; --sp-3:12px; --sp-4:16px; --sp-5:20px;
  --sp-6:24px; --sp-8:32px; --sp-10:40px; --sp-12:48px;

  /* ── grid ─────────────────────────────────────────────────────────── */
  --grid-cols:12; --grid-gutter:16px; --content-max:1440px; --pad-x:24px;
}
```

### 10.2 Por que ouro e não o slate-green dos produtos (justificativa)

- O slate-green (`cfoai`) é a identidade **dos produtos** (financeiro, CFO). O Mission Control é o
  painel **do OS sobre os produtos** — precisa de identidade própria, hierarquicamente "acima".
- O `graph-dashboard` (a única UI já-shippada da camada OS) já é **preto+ouro**. Manter coerência
  com o que existe > introduzir um 4º tema. (`reuse > create`.)
- Psicologia: ouro sobre preto = autoridade, raridade, "cockpit do dono". Verde diria "saudável"
  (que é estado, não marca — confundiria a gramática do §2). O ouro é neutro quanto a estado,
  liberando verde/âmbar/vermelho para serem PURAMENTE semânticos.
- OKLCH: derivar tudo de `--brand-hue: 75` permite reskin (ex.: um cliente quer azul-OS) trocando
  uma linha — alinhado ao sistema de tokens já documentado.

### 10.3 Tipografia

```css
--font-sans: "Geist", "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
--font-mono: "Geist Mono", "JetBrains Mono", ui-monospace, "SF Mono", monospace;
```
- **Mono para TODO dado numérico** (heartbeats, sha, contadores, timestamps, scores) — alinhamento
  tabular, sensação de instrumento. Inter/Geist para prosa/labels.
- **Micro-labels** (a assinatura IdeiaOS, do graph-dashboard): `font-size:10px; text-transform:
  uppercase; letter-spacing:0.18em; color:var(--accent-gold)`.
- Escala: `display 40/44 · h1 24/30 · h2 18/24 · body 14/20 · small 12/16 · micro 10/14`.
  `font-feature-settings:"tnum" 1, "cv01" 1` para números tabulares.

### 10.4 Componentes-chave (specs para o mockup)

| Componente | Spec |
|---|---|
| **Card** | `bg:var(--bg-surface); border:1px solid var(--border); border-radius:12px; padding:16-20px`. Hover: `border:var(--border-gold); translateY(-2px); transition:200ms`. Hero: `border:var(--border-gold)` + `--shadow-gold`. |
| **StatDot** | 6px, regras do §2. Sempre antecede label de saúde. |
| **TierBadge** | pill `padding:2px 10px; border-radius:999px; font:11px mono`. Cor por estado (success/warning/error bg em 12% + texto 100%). |
| **MicroLabel** | uppercase 10px gold letter-spacing 0.18em — todo header de card. |
| **BigStat** | mono 28–40px `--text-primary` + MicroLabel abaixo. |
| **Sparkline** | SVG path, stroke gold 1.5px, fill `rgba(201,178,152,0.08)`, 0 eixo visível. |
| **Heartbeat ECG** | SVG animado, stroke = estado global, `stroke-dasharray` anim por JS no ritmo dos epochs reais. |
| **TickerRow** | flex, slide-in 250ms + flash gold 400ms decay. mono. |
| **CommandPalette** | overlay center, `max-width:560px`, input gold-cursor, listas "Ir/Executar", `kbd` pills. |
| **DataTable** | mono, linhas 32px, `border-bottom:var(--border-subtle)`, header gold uppercase, zebra `rgba(255,255,255,0.015)`, ordenável. |
| **EmptyState** | dot/ícone central + frase com personalidade (§3.4-5) em tertiary. |

### 10.5 Acessibilidade (gate, não opcional)

- Contraste: `--text-secondary #B8B8AC` sobre `--bg-surface #0A0A0A` ≈ AA. `--text-tertiary` só
  para meta não-crítica. **Validar com `web-quality`/lighthouse 4.5:1** antes de publicar
  (`accessibility` skill + WCAG 2.1 AA).
- **Cor nunca é o único sinal de estado** — sempre dot+texto+ícone juntos (daltonismo). O ticker
  e os badges têm rótulo textual além da cor.
- Foco visível gold em todo interativo; `⌘K` e navegação por teclado completos (cockpit = teclado).
- `prefers-reduced-motion` desliga heartbeat-anim/confete/slide; mantém só pulse semântico atenuado.

---

## 11. Notas de construção para o mockup HTML

1. **Stack do mockup:** HTML único auto-contido (precedente: graph-dashboard html-formatter) OU
   Vite+React+Tailwind+shadcn copiando de `cfoai`/`nfideia` (precedente estrutural). Para um
   mockup *fiel e rápido*, HTML+CSS vars desta seção + Recharts/sparkline em SVG inline.
2. **Dados:** usar os exemplos REAIS do recon como fixtures (2 máquinas, 5 projetos, tier FRESCO,
   v13 aguardando tag, 75 OK / 0 WARN / 0 FAIL, commits humanos ~20/dia). Mockup com dados reais
   convence mais que lorem ipsum.
3. **Fidelidade de cor:** copiar os hex do §10.1 verbatim — são os mesmos do `THEME` canônico.
4. **A "cara" em 1 frase:** *Linear-grade dark UI, preto absoluto, ouro sóbrio, mono nos números,
   micro-labels gold uppercase, um heartbeat vivo no canto, vermelho que só aparece quando algo
   realmente queima.*
5. **Anti-padrões a evitar no mockup:** gradiente decorativo de fundo; ouro usado como "tudo
   certo"; valores de segredo em qualquer lugar; tabs horizontais; cards de igual tamanho (mata a
   hierarquia bento); animação >300ms; emoji como ícone de estado (usar Lucide + dot).

---

## 12. Rastreabilidade (o que cada ecrã consome — do recon)

| Ecrã | Fontes primárias (já existentes) |
|---|---|
| Overview | SOAK ledger · security ledger · idea-doctor · git log · launchctl · versions.lock |
| Máquinas | SOAK ledger · git log (hostnames WIP) · versions.lock · idea-doctor |
| Projetos & Users | git log filtrado · transcripts JSONL · supabase config.toml · git remote · lovable-mcp |
| Cofre (metadata) | `.env`/`.env.example` (nomes+stat) · envsync log (hash) · git status |
| Conexões MCP | `~/.claude.json` · `~/.cursor/mcp.json` · settings.json deny-lists · mcp-hygiene |
| Contas & IAs | `~/.claude.json` · gh auth · supabase project_id · `.env` refs · aiox graph |
| Produtividade | git log humano · transcripts (human_turns>5) · SOAK · security ledger · instincts |

> **Fecho — verify, don't assume:** este doc projeta a EXPERIÊNCIA. Antes de tratá-lo como
> contrato, três coisas precisam de confirmação humana: (1) deploy local-first vs remoto
> (§0); (2) brand-hue ouro vs azul-OS (§10.2 — é opinião forte, mas reversível por 1 linha);
> (3) se o command-plane pode mesmo executar `autosync-pause`/`--record` a partir da UI ou se
> isso deve ficar só como "gera o comando p/ copiar" (a versão segura, dado `agent-authority`).
> Defaults assumidos: local-first, ouro, command-plane executa não-destrutivos + confirma
> destrutivos. → corrija qualquer um agora ou o mockup segue com estes.
