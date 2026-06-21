# IdeiaOS Cockpit — Confiabilidade, Federação e Retenção

> **Documento 74 · Staff SRE / Platform Engineering · 2026-06-21 · Branch `work`**
> **Status:** PROPOSTO (zero código). Fecha os gaps de **confiabilidade** que a crítica
> adversarial deixou abertos sobre o `00-BLUEPRINT.md`: dependência circular da Frota,
> retenção/rotação dos artefatos novos, Trust Rate vs cache, e recovery do read-model/ref.
> **Disciplina:** enforce-simplicity, verify-don't-assume, exit-code binário onde houver,
> honestidade (rotular o que fica aberto). Não introduz nenhum verbo de mutação — read-only
> até v14.4 gated, igual ao resto do blueprint.

---

## 0. Fatos verificados (não assumidos) — base desta análise

Antes de desenhar qualquer mitigação, confirmei no **código vivo** (não em prosa de blueprint):

| Fato | Onde foi verificado | Consequência de design |
|------|---------------------|------------------------|
| `push_planning_ref()` faz `git push --quiet origin planning` e é chamado **também no braço `main`** | `~/.local/bin/git-autosync:16-24,70` | O padrão "empurra um ref **sem** escrever no main" é real e testado em produção. O ref `cockpit` é o análogo exato — **não** é mecanismo novo. |
| `git add -A` cego só roda quando o branch **≠ main** (linha 85-90); no main, memória nunca é staged | `~/.local/bin/git-autosync:82-90` | Snapshot escrito por plumbing dentro do ref **nunca existe no working tree** → o `add -A` não tem o que capturar. Confirmado. |
| O **próprio autosync** é (a) o que a Frota monitora e (b) o que empurra o ref `cockpit` | mesmo arquivo, fluxo único | **A dependência circular é real e load-bearing.** É o gap nº 1 (abaixo). |
| Daemon em repouso reporta PID `-` (normal); 3 daemons na Mac-mini | doc 73 §1 | "PID `-`" **não** é sinal de morte — cruzar sempre com heartbeat, nunca inferir morte do PID. |
| Ledgers são pipe-delimited `epoch\|iso\|host\|…\|commit`, append-only, **commitados** | `.planning/soak/*.log`, `.security/review-ledger.log` | Retenção do `cockpit`/audit-log deve seguir o mesmo formato e a mesma armadilha de `.gitignore` (learning abaixo). |
| Pausar autosync é por **pause-file** (`~/.local/state/git-autosync.pause`), não bootout | `scripts/autosync-pause.sh` | O daemon **continua disparando a cada 900s** mesmo pausado — sai cedo e loga. Relevante para distinguir "pausado" de "morto". |

---

## 1. Dependência circular: a Frota depende do autosync que ela monitora `[gap nº 1 — o mais grave]`

### O problema, cravado

O `ideiaos-agentd` coleta o snapshot e o grava no ref `cockpit` por plumbing. Mas **quem empurra
esse ref para `origin` é o `push_planning_ref`-análogo do git-autosync** (verificado: é o autosync
que dá `git push origin <ref>`, linha 22/112). Logo:

> Se o **autosync de uma máquina morre**, dois efeitos ocorrem **juntos e em silêncio**:
> (a) o snapshot local até pode continuar sendo **gerado** pelo agentd (são daemons distintos),
> mas (b) ele **nunca chega ao `origin`** → para todas as outras máquinas, aquele nó **congela no
> último push**. A Bridge remota mostraria dado velho **sem saber que está velho**.

Pior: a própria Bridge **não pode distinguir** "máquina desligada" de "máquina viva com autosync
morto" só olhando o ref — em ambos os casos o snapshot remoto para de avançar.

### A regra de ouro que NÃO pode ser violada

A proteção **pull-only do `main`** é inegociável (invariante Lovable; memória
`autosync-pushes-feature-branches`). Nenhuma mitigação aqui pode fazer a Bridge empurrar `main`.
Felizmente o `cockpit` é um ref **órfão**, igual `planning` — empurrá-lo **não** toca `main`. Isso
já está provado no código (o `push_planning_ref` roda no braço main e só empurra `planning`).

### Mitigação — detecção honesta de DOIS eixos independentes (não confundir)

O erro fatal seria mostrar um único "🔴 offline". Há **dois sinais ortogonais**, e a Frota DEVE
separá-los:

| Sinal | Como medir (determinístico) | O que significa |
|-------|------------------------------|-----------------|
| **Idade do ref remoto** | `now − commit-time do último snapshot daquele `machine_id` no ref `cockpit`` (via `git log -1 --format=%ct cockpit -- snapshots/<id>.json`) | Há quanto tempo aquela máquina **chegou até nós**. Pode ser velho por máquina-desligada **ou** por autosync-morto. |
| **Heartbeat local** (só da máquina onde a Bridge roda) | file-watch do snapshot **local** (~1–5s) | Prova de vida da **própria** máquina. É o único "vivo de verdade" — o resto é eventual. |

E o eixo que **desambigua** os dois (o pulo do gato):

| Sinal de desambiguação | Como medir na máquina REMOTA | Resultado |
|------------------------|-------------------------------|-----------|
| **Auto-staleness do autosync** | O agentd grava no próprio snapshot dois campos: `agentd_tick` (epoch do último ciclo do coletor) **e** `autosync_last_push` (epoch lido do `~/.local/state/git-autosync.log` da própria máquina). | Se, num snapshot que **chegou**, `agentd_tick` é fresco mas `autosync_last_push` está velho → **o autosync daquela máquina está morrendo** e ela mesma denunciou isso **antes** de parar de empurrar. Self-reported liveness. |

Com isso, a Frota mostra mensagens **direcionais** (memória
`ambiguous-drift-warning-induces-agent-revert` — nunca ambíguas):

- **🟢 vivo** — ref fresco (< 1 ciclo ≈ 15min).
- **🟡 eventual atrasado** — ref entre 1 e N ciclos; "último sinal há X min" (normal para máquina ociosa).
- **🔴 sem sinal há X** — ref além do limiar **e** sem auto-denúncia → **máquina provavelmente desligada** (não acuse autosync).
- **🟠 autosync agonizando** — o **último** snapshot que chegou trazia `autosync_last_push` já defasado vs `agentd_tick` → "esta máquina avisou que o push estava falhando; sinais futuros podem não chegar". Esse é o caso que **só** este campo self-reported pega.

> **Honestidade:** o caso terminal — autosync morto **e** máquina ociosa **e** nenhum snapshot
> recente com a auto-denúncia — é **indistinguível** de máquina-desligada **apenas pelo ref**. A
> Bridge NÃO inventa: rotula 🔴 "sem sinal há X (causa não-determinável remotamente)". A
> desambiguação completa exigiria um canal fora-de-banda (que v14.1 não tem e não vai ter). Aberto
> e rotulado.

### "O agentd pode dar `git push` do ref `cockpit` por si?" — resposta cravada

**Sim, e é a mitigação correta — mas com fronteiras estritas.** Como o autosync pode estar morto
(justamente o cenário), depender só dele para empurrar o ref é um SPOF. Então:

1. **O agentd empurra SOMENTE o ref `cockpit`** — `git push origin cockpit` e nada mais. É um ref
   órfão; empurrá-lo **não toca `main`**, exatamente como o `push_planning_ref` já faz com
   `planning` (verificado). Reusa-se a função existente parametrizada pelo nome do ref — **zero
   mecanismo novo** (enforce-simplicity).
2. **Quem autoriza:** o **process boundary do SO** (o mesmo modelo de autoridade do blueprint §5,
   C2). Só o `com.ideiaos.cockpit` LaunchAgent **local** roda esse push, com a identidade git da
   própria máquina. Não há RBAC, não há signer — porque **não há comando**: empurrar um ref de
   telemetria read-only não é um verbo de mutação de produção. É o mesmo privilégio que o autosync
   já tem hoje.
3. **Por que NÃO reintroduz risco no main:** o push do agentd é **hard-scoped** ao refspec
   `refs/heads/cockpit:refs/heads/cockpit`. Nunca `git push` sem refspec (que empurraria o branch
   atual), nunca `--all`, nunca `main`. Um teste de invariante (gate de fase) faz
   `grep -E 'push.*\b(main|master|--all|--mirror)\b'` sobre o script do agentd → **exit 1** se casar.
   Exit-code binário, não confiança.
4. **Anti-corrida com o autosync** (memória `autosync-races-ai-git-surgery`): os dois podem tentar
   empurrar `cockpit` ao mesmo tempo. Resolução: o agentd faz **fetch+fast-forward-only**
   (`git push --force-with-lease=refs/heads/cockpit` jamais; em vez disso `git fetch origin cockpit`
   → se divergiu, **reconcilia por merge de árvore** — ver §4 — e re-empurra). Push perde a corrida →
   re-tenta no próximo tick. Idempotente, sem `--force`.

> **Resultado:** a Frota deixa de depender de **um** mecanismo (autosync) para a federação. O agentd
> é o caminho primário do push do ref; o autosync vira **redundância** (se ainda vivo, empurra também
> — fast-forward é no-op). A circularidade é quebrada: o monitor não depende mais exclusivamente do
> monitorado para reportar a própria morte.

---

## 2. Retenção e rotação dos artefatos NOVOS que o Cockpit cria `[gap nº 2]`

O blueprint §5 prometeu "squash a cada 30 dias" e "audit-log roda por tamanho" — mas sem esquema
concreto. Aqui está, cravado, e **aplicando o learning `git-autosync.log-sem-rotação`** aos dois
artefatos novos (o ref `cockpit` e o `console-audit.log`).

### 2.1 O ref `cockpit` — snapshots acumulam a cada 900s

**Problema de crescimento:** cada máquina grava um snapshot por ciclo (~96/dia/máquina). Sem
rotação, o ref vira um histórico de dezenas de milhares de commits — clones lentos, `git log`
inutilizável, e o read-model reconstrói lendo lixo.

**Esquema de rotação (determinístico, commit-time-based):**

| Janela | Granularidade retida | Por quê |
|--------|----------------------|---------|
| **Últimas 48h** | **todos** os snapshots (full resolution, ~96/máquina/dia) | Time-Travel recente e debug de incidente precisam de resolução fina. |
| **48h – 30d** | **1 snapshot/máquina/hora** (mantém o último de cada hora-cheia) | Pós-mortem de médio prazo (ex.: reconstruir deny-list 5/5→2/5) só precisa de granularidade horária. |
| **> 30d** | **1 marco/máquina/dia** + sempre o snapshot citado por um ledger (SOAK/security) | Long-tail histórico. Densidade diária basta para o slider de Time-Travel (v14.3). |

**Como o squash roda (sem `--force`, sem reescrever história compartilhada de forma perigosa):**

- O ref `cockpit` é **órfão e append-only por convenção**, mas **regravável** (não é o main). A
  rotação é feita por **`git commit-tree` reconstruindo uma nova linha** que contém só os snapshots
  retidos, e `update-ref` apontando `cockpit` para ela — o mesmo plumbing do agentd. O ref antigo
  é descartável (não há PR, não há review do ref de telemetria).
- **Quem roda:** uma única máquina-coordenadora por vez, eleita deterministicamente
  (`machine_id` lexicograficamente menor presente no ref nas últimas 24h) — evita N máquinas
  squashando em paralelo e divergindo. As outras detectam o novo ref no próximo fetch e adotam
  por fast-forward (ou, se já tinham snapshot novo, reconciliam por §4).
- **Gatilho:** dentro do próprio agentd, advisory, **uma vez por dia** (guard por
  `last_squash_epoch` no ref). Nunca bloqueia coleta.

**Quanto histórico manter para Time-Travel (v14.3):** com o esquema acima, **90 dias** de histórico
custam ≈ `(48×N_máq) + (28×24×N_máq) + (60×N_máq)` snapshots ≈ **~750 snapshots/máquina** —
trivial para git. O slider do Time-Travel cobre 90d com granularidade que **degrada honestamente**
(minutos→horas→dias conforme recua). A UI rotula a resolução: "antes de 30d: 1 ponto/dia". Não
finge resolução de minuto onde só há marco diário.

### 2.2 `console-audit.log` — ledger local encadeado por hash

**Formato (pipe-delimited, igual aos ledgers irmãos):**
`epoch|iso|machine_id|verbo|resultado|prev_hash|this_hash`. Encadeado por hash (cada linha inclui
o hash da anterior) → adulteração detectável por re-cálculo.

**Rotação por tamanho (fecha o learning):** quando `> 1 MB`, arquiva datado
(`console-audit-AAAA-MM-DD.log`) e abre um novo cujo `prev_hash` da 1ª linha = `this_hash` da
última do arquivado → **a cadeia atravessa a rotação** (não quebra a auditabilidade).

> **ARMADILHA crítica (learning `broad-gitignore-sweeps-tracked-ledger`):** o `console-audit.log`
> é **local por máquina** (igual ao security ledger de produto, doc 73 §6) e **não** deve federar.
> Mas se algum dia precisar ser versionado, ele **casa o `*.log` de qualquer `.gitignore` broad** e
> some em silêncio. **Decisão:** o audit-log é deliberadamente **`.git/info/exclude`** (local,
> branch-agnóstico, memória `git-info-exclude-branch-agnostic-ignore`) — nunca versionado, nunca
> federado. Se o design mudar, exige negação explícita `!console-audit*.log` + comentário do porquê.

---

## 3. Trust Rate vs cache: o read-model é cache, a verdade é o disco-agora `[gap nº 3]`

### O problema, nomeado

O read-model SQLite é **cache do último ingest**. Quando a Bridge afirma "a chave X tem 47 dias",
está dizendo "no último ingest, tinha 47 dias". Se alguém tocou o arquivo entre o ingest e a
pergunta, **a Bridge mente sem saber**. Trust Rate medido contra o cache é Trust Rate de si mesmo —
circular e sem valor.

### Desenho do modo `--verify` (recompute-from-disk on-demand)

A spec viva (`Requisito: Verdade verificável contra o disco`) exige isso. Concretamente:

1. **Toda célula de verdade carrega proveniência:** além do valor, o read-model guarda
   `source_path`, `source_kind` (qual reader determinístico produziu), e `ingested_at`. A UI sempre
   mostra **"verificado há Xs"** = `now − ingested_at` (já é honestidade passiva).
2. **`--verify` recomputa do disco no instante da pergunta:** o usuário (ou o teste de Trust Rate)
   dispara verificação de **uma** afirmação. O agentd **re-executa o mesmo reader determinístico
   de args fixos** (`stat` na chave, `grep '^[A-Z_]*=' | sed 's/=.*//'` para presença, etc.) **no
   disco-agora**, e compara com o cache:
   - **match** → célula vira 🟢 "verificado há 0s (disco)".
   - **drift** → célula vira 🟠 "cache divergiu do disco — re-ingest pendente" + mostra **ambos** os
     valores. **Nunca** esconde a divergência.
3. **Zero-Leak preservado:** `--verify` recomputa **referência**, nunca valor (a entidade `ApiKey`
   não tem coluna `value`; o reader de credencial só faz `stat`+nome). O modo `--verify` herda o
   mesmo invariante — varre o resultado por padrão-de-segredo antes de renderizar.
4. **Custo controlado (enforce-simplicity):** `--verify` é **on-demand, por célula** — não é um
   re-ingest global a cada pergunta (isso anularia o cache). O cache continua servindo a navegação;
   `--verify` é o "clique para confirmar" de uma afirmação específica.

### Como o Trust Rate fica falsificável (fecha a crítica C5/§8)

> **Trust Rate = fração de afirmações da Bridge que, sob `--verify`, batem com o disco-agora.**
> Mede-se sobre as 3 jornadas (J1/J4/J2): para cada afirmação exibida, dispara `--verify` e conta
> match. Meta **100%** — qualquer drift não-rotulado é falha. Como a comparação é
> `cache == recompute(disco)` com **exit-code binário** (não interpretação NL), é
> auto-verificável e não-alucinável. **Diferença vs blueprint §8:** ali o Trust Rate era promessa;
> aqui é um procedimento determinístico com instrumento (`--verify`) e gate.

---

## 4. Recovery: read-model corrompido, ref corrompido, e snapshots conflitantes `[gap nº 4]`

### 4.1 Read-model SQLite — o caso fácil (descartável por design)

`rm ~/.ideiaos/console/read-model.db && console-ingest` reconstrói **tudo** dos refs. Já é
critério-de-pronto da v14.0 ("`console-ingest` reconstrói o read-model do zero após `rm`"). O
read-model **não é fonte-de-verdade** — é projeção. Corromper o cache **nunca** perde dado; só custa
um rebuild (segundos). **Recovery automático:** se o ingest detecta DB ilegível (SQLite
`PRAGMA integrity_check` ≠ ok → exit não-zero), ele faz `rm`+rebuild sozinho e loga. Exit-code
binário decide, não heurística.

### 4.2 Ref `cockpit` corrompido localmente

O ref local pode ser refeito do `origin`: `git fetch origin cockpit && git update-ref
refs/heads/cockpit origin/cockpit`. Se o **objeto** estiver corrompido (não só o ref), `git fsck`
detecta → re-clone do ref. Como cada snapshot é auto-contido por máquina, perder o ref local **não
perde** os snapshots das outras máquinas (estão no origin) nem o **próprio** (o agentd regrava no
próximo tick a partir do estado-de-disco vivo — o disco é a fonte, o ref é transporte).

### 4.3 Ref divergente entre máquinas — reconciliação de snapshots conflitantes `[o caso difícil]`

Este é o cenário real: máquina A e máquina B ambas empurraram `cockpit` partindo de bases
diferentes (autosync de uma ficou offline, voltou, e há dois "tips" do ref). Política:

> **A árvore do ref é particionada por `machine_id` — `snapshots/<id>.json` — então não há conflito
> SEMÂNTICO real entre máquinas distintas: A só escreve `snapshots/A.json`, B só `snapshots/B.json`.**

A reconciliação é, portanto, **union-merge por caminho**, determinística e sem julgamento:

1. `git fetch origin cockpit`. Se divergiu do local, NÃO `--force`.
2. Constrói uma **nova árvore** que é a **união** dos dois tips: para cada `machine_id`, mantém o
   snapshot com **maior `agentd_tick`** (o mais recente vence — é telemetria, o novo substitui o
   velho da **mesma** máquina). Caminhos de máquinas diferentes **coexistem** (sem conflito).
3. `commit-tree` com **dois parents** (merge real, auditável) + `update-ref`. Empurra fast-forward.
4. **Tie-break impossível por design:** dois snapshots da **mesma** máquina com o **mesmo**
   `agentd_tick` exigiriam dois coletores na mesma máquina no mesmo segundo — não acontece (1
   LaunchAgent, StartInterval 900). Se acontecesse (clock skew), desempata por `commit-time`.

> **Honestidade:** essa reconciliação é segura **porque** o ref é particionado por máquina e a
> semântica é "último vence para a mesma máquina". Se algum dia o ref guardasse estado
> **compartilhado** (ex.: uma fila de comando cross-máquina — v14.4), o union-merge **não bastaria**
> e exigiria CRDT ou lock — e isso é **exatamente** o tipo de coisa que o `/spec` de segurança da
> v14.4 tem que desenhar. Para a telemetria read-only de v14.0-v14.3, union-merge é correto e
> suficiente. Aberto e rotulado para v14.4.

### 4.4 Recovery total ("apaguei tudo")

`rm read-model.db` + ref local perdido + máquina nova: `git fetch origin cockpit` traz todos os
snapshots de todas as máquinas; `console-ingest` reconstrói o read-model; o agentd local regrava o
snapshot da própria máquina a partir do disco vivo no 1º tick. **Nada do que importa vive só no
cache.** A fonte-de-verdade é sempre: disco-vivo (presente) + ledgers append-only commitados
(passado). O ref e o SQLite são transporte e projeção — ambos descartáveis.

---

## 5. O que fica ABERTO (rotulado, não varrido)

1. **Causa terminal indistinguível** (§1): autosync-morto + máquina-ociosa + sem snapshot recente
   com auto-denúncia = indistinguível de máquina-desligada **só pelo ref**. Sem canal fora-de-banda
   (que v14.1 não tem por princípio), a Bridge rotula 🔴 "causa não-determinável" em vez de adivinhar.
2. **Auto-denúncia depende de UM último push ter passado** (§1): o campo `autosync_last_push` só
   chega se **pelo menos** o agentd-push (não o autosync) conseguir empurrar. Se a máquina perdeu
   conectividade total, nem a auto-denúncia sai. Mitigado por o agentd ser caminho de push
   independente, mas não 100% — rede morta é rede morta.
3. **Squash coordenado tem janela de corrida** (§2.1): a eleição da coordenadora é determinística,
   mas entre o squash e o fetch das outras há uma janela onde duas linhas do ref coexistem. Resolve
   por §4.3 (union-merge), mas adiciona um merge-commit ocasional ao ref. Aceito (ruído baixo).
4. **`--verify` é por-célula, não global** (§3): o Trust Rate cobre as afirmações **testadas**, não
   prova que **toda** célula do cache bate com o disco a cada instante. É a escolha certa (custo),
   mas é uma garantia **amostral**, não total — e está rotulada como tal.
5. **Reconciliação union-merge não escala para estado compartilhado** (§4.3): vale só enquanto o ref
   for particionado por máquina (telemetria read-only). Comando cross-máquina (v14.4) **quebra essa
   premissa** e exige o `/spec` de segurança redesenhar a federação. Explicitamente fora de escopo
   até lá.

---

## 6. Cross-links

- `00-BLUEPRINT.md` §4-5 (arquitetura, modelo de segurança), §8 (medição), §11 (riscos).
- `73-substrate-validation-mac-mini.md` (fatos verificados na Mac-mini).
- `specs/cockpit/spec.md` — requisitos *Frescor honesto*, *Verdade verificável contra o disco*,
  *Federação por ref dedicado*.
- Rules: `credential-isolation` (Zero-Leak), `antifragile-gates` (exit-code binário),
  `agent-authority` (`@devops` exclusivo de push de branch — o agentd só empurra o ref órfão `cockpit`).
- Learnings/memória: `autosync-pushes-feature-branches`, `autosync-races-ai-git-surgery`,
  `broad-gitignore-sweeps-tracked-ledger`, `git-info-exclude-branch-agnostic-ignore`,
  `ambiguous-drift-warning-induces-agent-revert`, `soak-span-is-record-delta-not-wallclock`.

---

*Doc 74 — PROPOSTO. Zero código. Alimenta o `/spec` da capability `cockpit` (novos requisitos de
liveness/retenção/verify) e o GSD da fase v14.0 (campos `agentd_tick`/`autosync_last_push` no
snapshot; agentd-push do ref; rotação; modo `--verify`).*
