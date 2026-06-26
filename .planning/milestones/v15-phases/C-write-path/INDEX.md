# Fase C — "Write-path own-fleet + consolidação + prevenção" (Onda 3 do v15) · INDEX

**Milestone:** v15 (DX & Frota) · **Fase:** C · **Status:** 🔵 EM ANDAMENTO.
**Origem:** método-espelho GSD (CLI não resolve fases v15 — mesma razão das Fases A/B e do v14).
Planejado/executado plano-a-plano a partir de `v15-REQUIREMENTS.md` (R15-17..23) e `v15-ROADMAP.md`.

## Objetivo da fase (goal-backward)

O operador comanda a PRÓPRIA frota (single-operator, own-fleet) com segurança provada por exit-code,
e o caminho de instalar/atualizar/auto-curar deixa de ser caixa-preta. Cada degrau de poder só abre
depois que o anterior está provado: **ver → prevenir race → telemetria → DX de update → write-path
local-reversível → reservar poder irreversível (chaves)**. Nenhum invariante-piso é violado
(credential-isolation, @devops, antifragile-gates, autosync-race, bash 3.2, no-invention).

## Planos (ordem por risco crescente — seguro→sensível)

| Plano | Req | Wave | depends_on | Risco | Veredito | Arquivo |
|-------|-----|------|-----------|-------|----------|---------|
| C-01 | R15-22 | 1 | — | baixo (prevenção) | 🔵 | `R15-22-preop-guard-PLAN.md` |
| C-02 | R15-20 | 1 | — | baixo (telemetria local) | 🔵 | `R15-20-autocura-visivel-PLAN.md` |
| C-03 | R15-19 | 2 | R15-22 | médio (caminho de update) | 🔵 | `R15-19-idea-update-PLAN.md` |
| C-04 | R15-21 | 3 | R15-19 ✓, R15-01/02 ✓ | médio (gerador de hooks) | 🔵 | `R15-21-refactor-hooks-PLAN.md` |
| C-05 | R15-18 | 4 | substrato /command ✓ | **alto** (write-path) | 🔵 | `R15-18-allowlist-local-PLAN.md` |
| C-06 | R15-23 | 4 | pinned-keys ✓ | **alto** (chaves de selo) | 🔵 | `R15-23-repin-local-PLAN.md` |
| — | **R15-17** | — | enc-keys N=2 | — | 🔒 **GATED** (decisão do dono) | — |

## Grafo de execução / waves

- **Wave 1 (isolados, prevenção+telemetria):** R15-22 (guard anti-race) ‖ R15-20 (ledger auto-cura).
  Nenhum toca mutação cross-máquina nem chaves. R15-22 edita o autosync (auto-modificante → verificar
  binário DEPLOYADO por grep, com autosync PAUSADO durante a cirurgia).
- **Wave 2 (DX):** R15-19 (`idea update`) — depende do guard (R15-22) estar no lugar para reconciliar
  o daemon sem race. Prova equivalência vs binário legado.
- **Wave 3 (dívida estrutural):** R15-21 (refactor gerador hooks data-driven) — **por último**, após
  R15-01/02 (Fase A ✓) e R15-19 estabilizarem. Só a metade "deploy-do-arquivo".
- **Wave 4 (write-path sensível — adjacente ao R15-17 GATED):** R15-18 (allowlist /command LOCAL) ‖
  R15-23 (re-pin local O2). Substrato já existe (canal POST /command hardened v14.4; pinned-keys.sh).
  O delta é refinar/wirear + provar por **gate-negativo** (input inválido), não "já provado".

## Movimento-âncora

**R15-22 (pre-op guard)** — a alavanca preventiva que o crítico identificou e nenhuma proposta capturou.
Protege as próprias cirurgias da Fase C contra o autosync (3 incidentes de race em produção). Construído 1º.

## Invariantes (não-negociáveis na execução)

- **antifragile-gates:** verificação por exit-code (`bash -n`, grep, JSON.parse, kill -0), nunca Read tool.
- **autosync-race:** autosync PAUSADO durante toda a Fase C; verificar binário DEPLOYADO por grep antes de religar.
- **falha-segura:** todo lock/sentinela automático EXPIRA (stale-guard por PID+TTL) — um crash NUNCA trava
  o autosync para sempre (senão a cura vira a doença). Espelha `temp-privilege-window-teardown-grants`.
- **write-path:** o /command nunca executa @devops; verbos LOCAL-reversíveis só; `reseal_security` é exceção
  declarada (nunca carimbo automático). Provar por **gate-negativo**, não por "lib já testada" (lib≠integração).
- **credential-isolation:** nenhum segredo na UI/contexto/ledger; referência por nome.
- **bash 3.2 / sem declare -A / sem jq.**

## R15-17 — por que fica GATED

`push_cmd_ref` + executor de mutação cross-máquina + **cerimônia N=2 das ENC-KEYS do selo (B0-bis)**.
A N=2 anterior provou só signing, não as enc-keys. Exige 2ª máquina física + decisão do dono — não é
executável autonomamente (carimbar seria fraudar o gate de integridade). Ver `automate-the-reminder-not-the-integrity-stamp`.
