# IdeiaOS Bridge — Mission Control · FASE 1 (v14.1) · SPEC

> **Documento 02 · Spec da Fase 1 · Lead Architect**
> **Status:** PROPOSTO · **Data:** 2026-06-20 · **Fase:** **v14.1 — MVP Bridge (vertical slice)**
> **Depende de:** `00-BLUEPRINT.md`, `01-ROADMAP.md`, e da fase **v14.0** concluída (ref `mission-control` + read-model + scaffold).
> **Capability `/spec`-alvo:** `mission-control` (a estrutura `specs/mission-control/` nasce no repo IdeiaOS).
> **Regra dos 4 hashtags (`####`) nos cenários é OBRIGATÓRIA** (parser de merge `/spec`).

---

## 1. Tese e fronteira do slice

A Fase 1 entrega a **alma do produto** — *surfacing que já nasce cheio* + *comando local reversível que herda a constituição do OS* — em **3 telas + 1 plano de comando**, **read-only quanto a produção, sem login, em loopback `http://127.0.0.1`**.

**O que ESTÁ no escopo:** ler metadado do ref `mission-control`/disco e renderizar; executar verbos **locais reversíveis** (pausar autosync, rodar idea-doctor, re-selar segurança).

**O que NÃO está (empurrado para v14.2+/v14.4):** Constelação, Sinapse, Pulso completo, Atalaia-tela, Time-Travel, Copiloto; **qualquer** verbo que mute produção (`rotate`/`revoke`/`deploy`), **qualquer** ação cross-máquina, **qualquer** login/RBAC. Esses são v14.4, atrás do `/spec` de segurança.

---

## 2. STACK concreta (zero escolha nova)

| Camada | Tecnologia | Versão | Origem do reúso |
|--------|-----------|--------|-----------------|
| Build/dev | **Vite** | 7.x | stack canônico dos 4 produtos |
| UI | **React** + **TypeScript** | 18.x / 5.x | idem |
| Estilo | **Tailwind CSS** | 3.x | idem |
| Componentes | **shadcn/ui** | (Radix) | 54 componentes já no nfideia |
| Charts | **Recharts** | 2.x | health-dashboard |
| Read-model | **SQLite** (`better-sqlite3`) single-file | — | `~/.ideiaos/console/read-model.db` (descartável) |
| Coletor/executor | **Node.js** (`ideiaos-agentd`) | 18+ | 4º LaunchAgent `com.ideiaos.missioncontrol` |
| Federação | **git plumbing** (`commit-tree`/`update-ref`) | — | padrão `push_planning_ref` (verificado) |
| Tema | **black-gold OKLCH** | `--brand-hue:75` | `graph-dashboard/THEME` |

**Componentes reaproveitados diretos:** `KPICard`, `AppLayout`, `AppSidebar`, `NotificationBell` (nfideia); `HealthScore`, `TrendChart` (health-dashboard); tema estrutural do cfoai-grupori.

**Sem dependência nova além de `better-sqlite3`** (e o que já vem no scaffold shadcn). Nenhuma lib de auth, nenhum servidor HTTP de comando — preferir o nativo (`credential-isolation` + Enforce Simplicity).

---

## 3. Entregáveis da Fase 1

1. **Tela Overview** (bento-grid): System Pulse local-vivo, cards Frota / Segurança / Releases-SOAK / Atenção-Agora.
2. **Tela Frota**: card por máquina + tabela densa de heartbeats + drift de versão.
3. **Tela Cofre-Espelho**: matriz var × projeto metadata-only, banner-doutrina, estado-vazio celebrado.
4. **Command Palette ⌘K**: verbos locais reversíveis com resultado inline.
5. **Teste de invariante Zero-Leak** (gate de release).
6. **Harness de medição de TtT** (baseline terminal + medição Bridge).
7. **Atualização do `idea-doctor §15`** consumindo o estado real do console.

---

## 4. Contratos `/spec` chave — capability `mission-control`

> Requisitos em `SHALL`/`DEVE`. Cenários com `####` (4 hashtags). Termos canônicos do glossário.

### Requisito: Isolamento de credencial (Zero-Leak)

O sistema DEVE expor credenciais **apenas por referência** (nome, presença, idade, escopo, risco, status de rotação) e NUNCA o valor do segredo em qualquer superfície (estado React, DOM, rede, log, snapshot ou ledger). A entidade `ApiKey` do read-model NÃO DEVE ter coluna `value`.

#### Cenário: snapshot não contém valor de segredo
- **QUANDO** o `ideiaos-agentd` coleta as credenciais de um projeto
- **ENTÃO** o snapshot grava apenas `name`, `present`, `age_days`, `risk_tier`, `scope`, `rotation_status` — derivados via `grep '^[A-Z_]*=' | sed 's/=.*//'`, sem ler o RHS do `=`

#### Cenário: teste de invariante bloqueia release com valor vazado
- **QUANDO** o teste Zero-Leak varre estado/DOM/rede/log/snapshot/read-model em busca de um padrão de segredo conhecido
- **ENTÃO** se encontrar qualquer valor, o teste falha com exit-code não-zero e o merge é bloqueado (gate de release, não advisory)

#### Cenário: Cofre-Espelho não oferece ação que toque valor
- **QUANDO** o operador abre a tela Cofre-Espelho na v14.1
- **ENTÃO** nenhum controle de UI permite ler, copiar, escrever ou rotacionar o valor de uma credencial — só metadado é exibível

---

### Requisito: Federação por ref sem captura pelo autosync

O `ideiaos-agentd` DEVE escrever o snapshot diretamente em `refs/heads/mission-control` via git-plumbing, sem nunca materializá-lo no working tree. O snapshot NÃO DEVE ser capturável pelo `git add -A` do git-autosync.

#### Cenário: working tree permanece limpo após coleta
- **QUANDO** o `ideiaos-agentd` grava `snapshots/<machine_id>.json` no ref `mission-control`
- **ENTÃO** `git status --porcelain` no working tree do branch corrente retorna vazio (o snapshot não existe como arquivo rastreável)

#### Cenário: autosync propaga o ref sem tocar a árvore
- **QUANDO** o git-autosync roda seu ciclo de ~900s e o ref `mission-control` está à frente do upstream
- **ENTÃO** ele executa `git push origin mission-control` (análogo a `push_planning_ref`) e NUNCA faz checkout nem `git add` do conteúdo do ref

#### Cenário: read-model é reconstruível do ref
- **QUANDO** o operador remove `~/.ideiaos/console/read-model.db` e roda `console-ingest`
- **ENTÃO** o read-model é integralmente reconstruído a partir dos snapshots do ref `mission-control` (cache 100% descartável)

---

### Requisito: System Pulse vivo sobre heartbeat local

O System Pulse DEVE animar continuamente sobre o **heartbeat local** (file-watch do snapshot da própria máquina, ~1–5s) e NÃO DEVE simular fluxo contínuo sobre dados cross-máquina que chegam em lote.

#### Cenário: pulse local anima em tempo quase-real
- **QUANDO** o snapshot local é regravado pelo `ideiaos-agentd`
- **ENTÃO** o System Pulse reflete o novo heartbeat em ≤ 5s, sem recarregar a página

#### Cenário: nó remoto mostra idade honesta
- **QUANDO** uma máquina remota não atualiza seu snapshot há mais de 6h
- **ENTÃO** a Frota a marca 🔴 com "último sinal há Xh", sem animar o pulse dela como se fosse vivo

#### Cenário: pulse vira arrítmico no crítico
- **QUANDO** um sinal crítico é detectado (ex.: security-tier egrégio ou autosync parado)
- **ENTÃO** o System Pulse muda para o estado vermelho/arrítmico e a cor não é o único indicador (há label textual — WCAG)

---

### Requisito: Comando local reversível via allowlist fixo

O Command Palette ⌘K DEVE executar apenas verbos de um **allowlist fixo** de operações **locais e reversíveis**, sem `exec` arbitrário. Verbos `@devops`-exclusivos (`git push`, `gh pr`) e verbos de mutação de produção (`rotate`/`revoke`/`deploy`) NÃO DEVEM estar no allowlist na v14.1.

#### Cenário: verbo local sancionado executa com resultado inline
- **QUANDO** o operador dispara `autosync-pause` pelo ⌘K
- **ENTÃO** o `ideiaos-agentd` local executa o script sancionado via IPC de processo (não via git) e o resultado aparece inline na palette

#### Cenário: verbo destrutivo exige armar antes de disparar
- **QUANDO** o operador seleciona um verbo destrutivo reversível (ex.: `autosync-pause`)
- **ENTÃO** a palette exige uma confirmação explícita ("armar") antes de executar

#### Cenário: verbo de mutação de produção é inexistente na v14.1
- **QUANDO** o operador procura por `rotate`, `deploy`, `revoke`, `git push` ou `gh pr` na palette
- **ENTÃO** nenhum desses verbos é listado nem executável (fora do allowlist até v14.4)

---

### Requisito: Confiança verificável contra o disco-agora

O sistema DEVE permitir verificar uma resposta exibida contra o estado do disco **no instante da pergunta**, não apenas contra o snapshot em cache.

#### Cenário: modo verify recomputa do disco
- **QUANDO** o operador aciona o modo `--verify` sobre uma célula da Bridge
- **ENTÃO** o valor é recomputado a partir do disco/ref no momento e a UI exibe "verificado há Xs"; divergência com o cache é sinalizada como stale

---

### Requisito: Surfacing honesto de lacunas de substrato

O sistema NÃO DEVE inventar sinais ausentes. Onde um sub-sinal não existe para um alvo, ele DEVE ser rotulado como ausente, não estimado como zero ou inventado.

#### Cenário: idea-doctor ausente num produto Lovable
- **QUANDO** o health-score de um produto Lovable é montado e `idea-doctor` não roda ali
- **ENTÃO** o card exibe `doctor: n/a` para aquele sub-sinal, sem fabricar nota

#### Cenário: produtividade por-usuário monousuária
- **QUANDO** o Pulso (preview na v14.1) tenta exibir produtividade por usuário e só há `gustavo@`
- **ENTÃO** as personas P1/P2 são rotuladas "aguardando segundo ator", não preenchidas com dado falso

#### Cenário: divergência de versão do agentd entre máquinas
- **QUANDO** duas máquinas reportam `agentd_version` diferentes
- **ENTÃO** a Frota mostra a divergência como drift âmbar, sem quebrar o collector (assimetria assumida)

---

## 5. Critérios de aceite verificáveis (gate da Fase 1)

| # | Critério | Como verificar (exit-code binário onde possível) |
|---|----------|---------------------------------------------------|
| A1 | **Baseline de TtT medido** antes da Bridge | Planilha/registro com N≥5 medições por jornada (J1/J4/J2) via terminal |
| A2 | **TtT < 10s** na Bridge | Mediana N≥5 por jornada < 10s, registrada |
| A3 | **Zero-Leak = 0** | `npm run test:zeroleak` → exit 0 (varre estado/DOM/rede/log/snapshot/read-model) |
| A4 | **Working tree limpo após coleta** | `git status --porcelain` vazio após `console-collect.sh` |
| A5 | **Read-model reconstruível** | `rm read-model.db && console-ingest && test -s read-model.db` → exit 0 |
| A6 | **Trust Rate 100% contra disco** | Modo `--verify` bate com `git show mission-control:...` em 100% das amostras |
| A7 | **⌘K executa 3 verbos locais** | `autosync-pause`, `idea-doctor`, `security --record` retornam resultado inline |
| A8 | **Mutação de produção ausente** | Busca por `rotate`/`deploy`/`revoke`/`git push`/`gh pr` na palette → 0 resultados |
| A9 | **`idea-doctor §15`** audita o console | `idea-doctor` reporta agentd ativo? ref existe? snapshot fresco? |
| A10 | **WCAG 2.1 AA** | contraste OK, cor nunca único sinal, ⌘K e navegação por teclado, `prefers-reduced-motion` |
| A11 | **Gate de fechamento padrão** | SOAK 2 máquinas span≥1d · `idea-doctor` verde · security re-selado · README · vault |

**Coverage-alvo:** ≥ 3/8 JTBD resolvidos na Bridge **sem cair pro terminal** (J1 frota, J4 chave, J2 tag).

---

## 6. Riscos específicos da Fase 1 e mitigação

- **`idea-doctor --json` não pronto** → é dependência da v14.0; a v14.1 **não inicia** sem ela + fallback ANSI testado (não "já dá").
- **Pulse parecer teatro** → animar **só** o heartbeat local (real); remotos com idade honesta. Verificado pelo cenário "pulse local anima / nó remoto mostra idade".
- **⌘K virar superfície de injeção** → allowlist fixo, sem `exec`, IPC local (não git), destrutivos armados. Verificado por A7/A8.
- **Cofre virar mapa do tesouro** → metadata-only por construção (`ApiKey` sem `value`), loopback, badge de mitigação para `.env.local` em iCloud. Verificado por A3 + cenário Cofre.

---

*Spec da Fase 1 — PROPOSTO. Zero código. Próximo passo: `/spec` propõe a capability `mission-control` (delta + tasks.md), o GSD consome `tasks.md` para planejar/executar v14.0 → v14.1.*
