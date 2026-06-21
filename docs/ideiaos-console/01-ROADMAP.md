# IdeiaOS Bridge — Mission Control · ROADMAP

> **Documento 01 · Roadmap de execução · Lead Architect**
> **Status:** PROPOSTO · **Data:** 2026-06-20 · **Milestone:** **v14.x** do IdeiaOS
> **Depende de:** `00-BLUEPRINT.md` (decisões `[DECIDIDO]`/`[CORRIGIDO]`)
> **Linguagem ubíqua:** os termos abaixo (`agentd`, ref `mission-control`, snapshot, read-model, Frota, Cofre-Espelho, Pulse, TtT, Zero-Leak) são canônicos — ver glossário em `00-BLUEPRINT.md`.

---

## Princípios de fechamento (gate padrão IdeiaOS, vale para TODA fase)

Cada fase só fecha com:
1. **SOAK 2 máquinas + span ≥ 1 dia** (`check-soak.sh <milestone> --record` em ambas, com re-record após ≥1d — o span é delta dos epochs gravados, não wall-clock).
2. **`idea-doctor` verde** (incluindo a nova §15 de self-monitoring do console).
3. **`check-security-freshness.sh --gate`** re-selado (advisory no 1º ciclo, `SECFRESH_GATE_ENABLED=0`).
4. **Zero-Leak = 0** verificado por teste de invariante (gate de release, não advisory).
5. **README do GitHub atualizado** com os novos recursos.
6. **Vault Obsidian** atualizado (Changelog + extract-learnings).

**v14.4 NÃO inicia** sem o `/spec` de segurança aprovado (threat-model dedicado).

---

## Visão geral das fases

| Fase | Nome | Risco | Esforço | Bloqueia |
|------|------|-------|---------|----------|
| **v14.0** | Substrato + Espinha | baixo | ~1 sem | v14.1 |
| **v14.1** | MVP Bridge (read-only + comando local) | baixo | ~1–2 sem | v14.2 |
| **v14.2** | Pilares completos | baixo | ~2 sem | v14.3 |
| **v14.3** | Inteligência (Wave 2) | médio | ~2–3 sem | — |
| **v14.4** | Comando cross-máquina (Wave 3) | **ALTO** | gated | — |

---

## v14.0 — Substrato + Espinha

**Objetivo:** tornar o substrato **federável** e nascer a SPA, sem nenhuma UI de valor ainda. É a fase de canalização.

**Entregáveis:**
- `idea-doctor.sh --json` — **flag nova**, emite as 14 (→15) seções como JSON estruturado. **Trabalho real, não trivial** (o fonte hoje tem 0 parsing de `--json`, só strings ANSI).
- **Fallback ANSI testado** — parser dos blocos `━━━` para quando `--json` não existir/falhar, com **teste que prova o fallback** antes de a Frota depender do JSON.
- `com.ideiaos.missioncontrol.plist` — 4º LaunchAgent, `StartInterval 900`, irmão de envsync/gitautosync/refresh-ai-security.
- `ideiaos-agentd` (modo **coletor**) — `scripts/console-collect.sh` materializa estado efêmero (`launchctl`, `idea-doctor --json`, contas de IA, versões) em `snapshots/<machine_id>.json`.
- **Escrita por ref via plumbing** — `source/lib/mission-control.sh` grava o snapshot em `refs/heads/mission-control` por `git commit-tree`+`update-ref`, **sem tocar o working tree** (padrão `push_planning_ref`). Autosync ganha um `git push origin mission-control` análogo ao do `planning`.
- `console-ingest` — funde N snapshots do ref → `~/.ideiaos/console/read-model.db` (SQLite descartável; `rm && rebuild`).
- Scaffold Vite/React/TS/Tailwind/shadcn black-gold (reusa componentes do nfideia/health-dashboard).
- `machine-aliases.json` / `user-aliases.json` (dedup `192`↔`Mac-mini`, ator determinístico).
- `scripts/check-mission-control.sh` + **§15 do `idea-doctor`** (agentd ativo? ref existe? snapshot fresco?).

**Dependências:** nenhuma externa. Reusa `gates.sh`, `handoff-packet.sh`, padrão de ref do `planning`.

**Critério de PRONTO (verificável):**
- `idea-doctor --json | jq .` retorna JSON válido **OU** o fallback ANSI produz o mesmo modelo (teste passa em ambos os caminhos — exit-code binário).
- `git show mission-control:snapshots/<machine_id>.json` existe e é não-vazio (`test -s` via `git cat-file`).
- O working tree **continua limpo** após o collector rodar (prova de que o snapshot não vaza para `git add -A`): `git status --porcelain` vazio.
- `console-ingest` reconstrói o read-model do zero após `rm read-model.db`.
- `idea-doctor §15` reporta o estado do console.

---

## v14.1 — MVP Bridge (vertical slice · read-only + comando local)

**Objetivo:** provar a **alma do produto** — surfacing que já nasce cheio + comando **local reversível** que herda a constituição do OS — no menor nº de telas, com o wow intacto. **Estritamente read-only quanto a produção; sem login; loopback.**

**Escopo (3 telas + 1 plano de comando):**
- **Overview** — bento-grid: **System Pulse** (heartbeat **local** vivo via file-watch ~1–5s), cards **Frota** (2/2 PASS), **Segurança** (badge de tier + barra "idade até stale"), **Releases/SOAK** (countdown até span≥1d + "PRONTO PARA TAG"), **Atenção Agora** (action feed priorizado).
- **Frota** — card por máquina (vital signs, mini-timeline 7d, drift âmbar), tabela densa de heartbeats, dedup honesta (`Mac-mini aka 192`), **divergência de `agentd_version` como drift** (assimetria entre máquinas assumida).
- **Cofre-Espelho** — matriz var × projeto **metadata-only** (presença `●/○`, risco por var via catálogo único, órfã/`.env` exposto), banner-doutrina "Control-plane local, não cofre", estado-vazio celebrado. **Zero botão que leia/escreva/rotacione valor.**
- **Command Palette ⌘K** — ações **locais reversíveis** sancionadas: `autosync-pause/resume`, `idea-doctor`, `security --record` (re-selo local). Resultado inline; "armar antes de disparar" nos destrutivos; `@devops`-exclusivos e mutação de produção **fora do allowlist**.

**Stack & tema:** Vite+React+TS+shadcn/ui+Recharts; black-gold OKLCH (`--brand-hue:75`, `bg #000000`, `accent-gold #C9B298`). Mono em todo numérico; cor só semântica; ouro = hierarquia/marca/seleção.

**Dependências:** v14.0 (ref + read-model + scaffold).

**Critério de PRONTO (verificável):**
- **Baseline de TtT medido** (cronômetro sobre J1/J4/J2 **via terminal**, N≥5) **registrado antes** de medir a Bridge.
- **TtT < 10s** (mediana, N≥5) na Bridge para J1 (frota saudável?), J4 (chave existe/idade?), J2 (pronto p/ tag?).
- **Zero-Leak = 0** por teste de invariante (varre estado/DOM/rede/log/snapshot por padrão de segredo) — gate de release.
- **Trust Rate 100% contra o disco-agora** (modo `--verify` recomputa do disco, não do cache).
- ⌘K executa `autosync-pause`, `idea-doctor`, `security --record` **localmente**, com resultado inline.
- `idea-doctor §15` audita o próprio console.
- WCAG 2.1 AA (contraste, cor nunca único sinal, teclado, `prefers-reduced-motion`).

---

## v14.2 — Pilares completos

**Objetivo:** fechar os 5 pilares + Atalaia, ainda **read-only**.

**Entregáveis:**
- **Constelação** — produtos, stack, deploy, **velocity humana** (commits humanos filtrados), Lovable MCP **read-only** (verify-deploy/detect-hotfix). Health-score com `idea-doctor: n/a` honesto nos Lovable.
- **Sinapse** — Conexões MCP (`~/.claude.json`, `~/.cursor/mcp.json`) + Contas & IAs; **deny-list watch** (audita as 19 tools mutantes, alerta em regressão 5/5→N/5).
- **Pulso** — 4 KPIs honestos (feat/fix humano/dia, sessões meaningful, co-ocorrência, milestones SOAK-validados); banner recusando vaidade; P1/P2 rotulados vaporware até segundo ator.
- **Atalaia** — strip "Atenção Agora" promovido a tela própria (regras: drift `versions.lock`, regressão deny-list, autosync parado, tier→stale, `.env` órfão, SOAK pronto-p/-tag, `.env.local` em iCloud).

**Dependências:** v14.1.

**Critério de PRONTO:** 5 pilares navegáveis; deny-list watch detecta uma regressão simulada; Pulso bate com `git log` filtrado; Atalaia dispara ≥1 alerta real do substrato; gate padrão verde.

---

## v14.3 — Inteligência (Wave 2)

**Objetivo:** camada que exige parser/grafo — **médio risco, ainda sem mutação cross-máquina**.

**Entregáveis:**
- **Time-Travel / Replay determinístico** — slider reconstrói a frota em data passada a partir do event-store (ledgers + ref). **Demo-wow: reconstruir o incidente deny-list 5/5→2/5→remediado.**
- **CTO Copiloto** — readers determinísticos de **args FIXOS** (whitelist fechada); LLM só roteia; nenhum reader toca segredo; retornos envelopados como DADO (anti-injection).
- **Token-Cost Ledger** — custo por propósito; pricing da skill `claude-api` (nunca de memória); estimativa **rotulada** onde não há campo nativo.
- **Atlas de instincts** — skill-tree de confidence por domínio, "maturidade observada".

**Dependências:** v14.2. O Copiloto depende do wrapper anti-injection (`handoff-packet.sh`).

**Critério de PRONTO:** Time-Travel reconstrói um estado passado **verificável contra o ledger**; Copiloto responde J1/J4 com **SHA/linha exata** anexada e **nenhum** acesso a valor de segredo; teste de injection (commit-msg adversarial) **não** desvia o roteamento; Token-Cost rotula estimativas honestamente.

---

## v14.4 — Comando cross-máquina (Wave 3) · **GATED**

**Objetivo:** ação real cross-máquina e/ou mutação de produção — **só com segurança DESENHADA**.

**Pré-requisito inegociável:** `/spec` próprio da capability `mission-control-control-plane` + threat-model aprovado. **Esta fase não começa sem isso.**

**Entregáveis (todos atrás do `/spec`):**
- Command cross-máquina — desenho do canal de confiança (signer + autorização) que o `/spec` definir. Só então entra um arquivo/fila de comando; até lá, **não existe**.
- **RBAC cto/dev**, **step-up auth**, sessões curtas — só se o `/spec` justificar para o modelo de operação real (não copiar console multi-tenant para um operador único sem justificativa).
- Verbos de mutação (`rotate`/`revoke`/`deploy`) — entram no allowlist **um a um**, cada um com janela de privilégio temporário que **inclui o teardown** (learning `temp-privilege-window-teardown-grants`).
- Black-box / flight-recorder (pacote forense datado no crítico) + Simulador "E se…" (dry-run de blast-radius, **nunca executa**).

**Dependências:** v14.3 + `/spec` aprovado. `git push`/`gh pr` permanecem exclusivos do `@devops` — o console **nunca** os expõe.

**Critério de PRONTO:** `/spec` mergeado e arquivado; threat-model com STRIDE+OWASP-LLM cobrindo o canal de comando; cada verbo de mutação com teste de janela-de-privilégio (incluindo rollback); Zero-Leak mantido; gate padrão verde.

---

## Mapa de dependências (resumo)

```
v14.0 (substrato federável: --json, ref, agentd-coletor, ingest)
   └─> v14.1 (read-only + comando LOCAL: Overview/Frota/Cofre/⌘K + TtT medido)
          └─> v14.2 (5 pilares + Atalaia, read-only)
                 └─> v14.3 (Time-Travel, Copiloto args-fixos, Token-Cost, Atlas)
                        └─> v14.4 [GATED por /spec de segurança]
                              (comando cross-máquina, RBAC, rotate/deploy)
```

**Regra de ouro do roadmap:** nenhum verbo que mute produção ou atinja outra máquina entra antes da v14.4. Tudo até v14.3 é **leitura + comando local reversível**. Isso é o que torna v14.0–v14.3 baixo-risco e construível com confiança.
