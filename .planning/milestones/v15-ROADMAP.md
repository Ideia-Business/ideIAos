# Roadmap — v15: DX & Frota (Plataforma fácil de instalar + gerenciar)

**Milestone:** v15
**Aberto:** 2026-06-25 · **Status:** 🔵 PROPOSTO (zero código).
**Numeração de fases:** lettered por onda (Onda 1 = Fase A, Onda 2 = Fase B, Onda 3 = Fase C), espelhando v8/v9/v10.
**Grafo de dependências:** `A (quick-wins, paralelizável)` → `B (governança visível + Cockpit rico)` → `C (write-path own-fleet + consolidação)`. Dentro de A: R15-02 depende de R15-03 (smoke confirma o registro); R15-15 (Onda B) hard-gateia em R15-05 (Onda A).

## Tese

As duas perguntas do dono convergem no **Cockpit como leme da frota single-operator**. A sequência é **estancar a hemorragia de confiança** (Onda A: buracos mecânicos de instalação + o FAIL crônico) → **tornar a governança visível e o Cockpit rico** (Onda B: CI, `--fleet`, dados já-coletados) → **fechar o write-path own-fleet e prevenir as armadilhas estruturais** (Onda C). O multi-**dev** (RBAC, ratificação do split-plane) é o **v16**, gated por blockers que não tocam o v15.

---

## Fases

### Fase A — "Destravar & Estancar" (Onda 1) · quick-wins de alto impacto

**Objetivo (goal-backward):** um dev novo (inclusive Windows nativo) instala, vê por exit-code que funcionou, e o painel para de mentir (Frota com nomes, sem FAIL crônico ignorado).

**Entregar:**
- `R15-01` Fix `/usr/bin/python3` (12 hooks fonte) + re-build plugins + guard diferenciado (gate `grep -L` nos 13 deployados). **O movimento-âncora** — validável no macOS, destrava o resto.
- `R15-03` `idea-smoke.sh` puro-bash (prova binária do bootstrap mínimo) → habilita `R15-02` (registro de hooks no bootstrap, confirmado pelo smoke).
- `R15-04` `setup-dev-machine.sh` resiliente (probe `gh api`; cfoai particular não aborta).
- `R15-05` Corrigir 3 fatos (alias iCloud morto / desambiguar 3 cópias `.aiox-core` / slug `ideIAos`).
- `R15-06` Fechar o FAIL crônico cfoai Lovable-MCP (decisão do dono: remediar OU allowlist auditável).
- `R15-07` Alias-map da Frota (nomes, não hashes). `R15-08` Botão verificar (`/verify`, 3 estados).

**Cobre:** R15-01..08.
**Pausar autosync** antes de R15-01/05 (edição de hooks/README). **Decisão do dono:** R15-06 (cfoai).
**Done:** `idea-smoke.sh` exit 0 numa estação fresca; `grep -L` = 0 hooks com path hardcoded; Frota renderiza nomes; `idea-doctor` sem o FAIL do cfoai. Não depende do teste do Lucas.

### Fase B — "Governança visível + Cockpit rico" (Onda 2)

**Objetivo (goal-backward):** a saúde da frota e a governança ficam visíveis SEM rodar nada localmente em cada máquina; o Cockpit mostra o valor que já coleta.

**Entregar:**
- `R15-09` `idea-doctor --fleet` (agrega snapshots do ref `cockpit`, idade honesta) — **o ponto de costura** entre instalar e gerenciar.
- `R15-10` CI dos 4 gates repo-puros em PR (repo público → grátis).
- `R15-11` LaunchAgent de lembrete dos selos (SOAK/security) + ff-merge `work→main` (notifica, nunca carimba). Depende de R15-06.
- `R15-12` Expor dados ricos (gh accounts, drill-down, span SOAK, `supabase_project_id`) + investigar `installed_versions={}` + chamar `readMcp()`.
- `R15-13` Flight Recorder 1ª-classe. `R15-14` Card "Saúde & Governança" (GET read-only).
- `R15-15` Consolidar 5 docs num runbook (**hard-gate em R15-05**). `R15-16` Hello-world de 10 min.

**Cobre:** R15-09..16.
**Done:** CI verde em PR; `--fleet` mostra ≥2 máquinas com idade; o Overview tem o card de governança servido por GET; runbook único passa o gate de cobertura de gotchas.

### Fase C — "Write-path own-fleet + consolidação + prevenção" (Onda 3)

**Objetivo (goal-backward):** o operador comanda a própria frota cross-máquina com segurança provada por exit-code, o update vira 1 comando, e as armadilhas estruturais (autosync-race, revogação) viram guards automáticos.

**Entregar:**
- `R15-17` Fechar o write-path cross-máquina own-fleet (`push_cmd_ref` daemon + executor + **cerimônia enc-keys** + HEAD-assinado). ⚠️ **GATED na decisão do dono** (cerimônia B0-bis). Gate próprio mutação-testado; verificar binário deployado por grep/`launchctl bootout` (fase auto-modificante).
- `R15-18` Allowlist de verbos locais (corrigida — `reseal_security` como exceção sob arm+revisão; wiring do ledger provado por gate-negativo).
- `R15-19` `idea update` (prova equivalência contra binário legado real). `R15-20` Auto-cura visível (ledger local-only append atômico).
- `R15-22` **Pre-op guard anti-autosync-race** (detecção automática de cirurgia git). `R15-23` Proof-gate de teardown (re-pin local O2).
- `R15-21` Refatorar gerador de hooks do `setup.sh` (data-driven) — **por último**, após R15-01/02 estáveis.

**Cobre:** R15-17..23.
**Done:** se a cerimônia enc-keys rodar, executor passa o gate com input inválido; `idea update` reconcilia hooks+overlay+daemon provado vs. legado; o pre-op guard barra o autosync durante cirurgia em sandbox `/tmp`.

---

## Ordem de execução recomendada (3 ondas)

| Onda | Quando | Conteúdo | Dependências |
|------|--------|----------|--------------|
| **1 (Fase A)** | 1-2 semanas | R15-01→03→02 (cadeia smoke→registro) · R15-04/05/07/08 (paralelo) · R15-06 (decisão dono) | R15-02←R15-03 |
| **2 (Fase B)** | semanas 3-6 | R15-09 (costura) · R15-10 (CI) · R15-11/12/13/14 · R15-15/16 | R15-15←R15-05; R15-11←R15-06 |
| **3 (Fase C)** | meses | R15-17 (gated enc-keys) · R15-18/19/20/22/23 · R15-21 por último | R15-21←R15-01/02; R15-17←cerimônia |

## Riscos / o que NÃO fazer (herdados da análise)

1. **Não super-construir** — itens multi-dev (RBAC, ratificação split-plane, claims, fila-Publish) são **v16**, não entram aqui.
2. **Não confundir lib-provada com wiring-provado** — R15-17/18 exigem gate mutação-testado com input INVÁLIDO (happy-path verde esconde bypass).
3. **Não automatizar carimbo de gate** — R15-11/20 automatizam o LEMBRETE, nunca o selo.
4. **Não editar hooks/autosync com autosync rodando** — R15-22 reduz a dependência de memória, mas até ele existir, pausar é passo explícito de R15-01/05/17/21.
5. **Não tratar `--fleet` como visão live** — mostra a IDADE do snapshot; máquina parada = "sem sinal" (alerta certo, não live).

## Pendente para abrir v15 como milestone ATIVO

1. Confirmar a numeração v15/v16 (DONE — decisão do dono 2026-06-25).
2. `/gsd-plan-phase v15-A` consumindo este ROADMAP → `PLAN.md` por fase (espelha v10).
3. Decisão do dono sobre R15-06 (cfoai) antes de fechar a Fase A.
4. Decisão do dono sobre a cerimônia enc-keys antes de abrir R15-17.
