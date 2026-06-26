# Fase B — "Governança visível + Cockpit rico" (Onda 2 do v15) · INDEX

**Milestone:** v15 (DX & Frota) · **Fase:** B · **Status:** 🔵 EM ANDAMENTO (3/8 — R15-09, R15-10, R15-11 DONE; 2026-06-26).
**Origem:** método-espelho GSD (CLI não resolve fases v15 — mesma razão da Fase A e do v14). Planejado/executado plano-a-plano a partir de `v15-REQUIREMENTS.md` (R15-09..16) e `v15-ROADMAP.md`.

## Objetivo da fase (goal-backward)

A saúde da frota e a governança ficam visíveis SEM rodar nada localmente em cada máquina; o Cockpit
mostra o valor que já coleta. CI verde em PR; `--fleet` mostra ≥2 máquinas com idade honesta; o
Overview tem card de governança servido por GET; runbook único passa o gate de cobertura de gotchas.

## Planos

| Plano | Req | Wave | depends_on | Veredito | Arquivo |
|-------|-----|------|-----------|----------|---------|
| B-01 | R15-09 | 1 | — | ✅ pass | `R15-09-fleet-PLAN.md` |
| B-02 | R15-10 | 1 | — | ✅ pass (code-complete) | `R15-10-ci-gates-PLAN.md` |
| B-03 | R15-11 | 1 | R15-06 ✅ | ✅ pass | `R15-11-lembrete-selos-PLAN.md` |
| B-04 | R15-12 | 1 | — | 🔵 a fazer | (dados ricos + **fix coleta doctor** — ver R15-09 carry) |
| B-05 | R15-13 | 1 | — | 🔵 a fazer | (Flight Recorder 1ª-classe) |
| B-06 | R15-14 | 1 | — | 🔵 a fazer | (card Saúde & Governança GET) |
| B-07 | R15-15 | 2 | **R15-05** ✅ | 🔵 a fazer | (runbook único — HARD-GATE em R15-05) |
| B-08 | R15-16 | 1 | — | 🔵 a fazer | (hello-world 10 min) |

## Grafo de execução

- **R15-09** (costura) é independente e o movimento-âncora — feito 1º.
- **R15-10/12/13/14/16** independentes (paralelizáveis).
- **R15-11** depende de R15-06 (✅ A-08 fechou) — desbloqueado.
- **R15-15** HARD-GATE em R15-05 (✅ Fase A) — desbloqueado, mas é Wave 2 (consolida docs já corrigidos).

## Movimento-âncora

**R15-09 (`idea-doctor --fleet`)** — "o ponto de costura barato entre instalar e gerenciar".
Independente, dado já no ref `cockpit`, validável por exit-code. ✅ DONE.

## Carry-forward / achados

- **R15-09 → R15-12 (PRIORITÁRIO):** o `--fleet` expôs que `doctor.exit=-1` + `sections=[]` em
  TODOS os snapshots (status VAZIO honesto). **Causa-raiz isolada:** `idea-doctor --json` emite JSON
  inválido — o §12 (debt-markers) vaza as ocorrências para stdout sem guard `JSON_MODE` (linha 742).
  O `collect.js` falha o parse e grava o fallback vazio. **Fix cirúrgico aplicado em commit separado**
  (bugfix `f80e9c5`, não-R15-09); R15-12 herda a investigação do resto da coleta (`installed_versions={}`).
- **2 FAILs reais do doctor (agora visíveis) — resíduo do item 1 / R15-06:** `cfoai` e `nfideia`
  "Lovable MCP SEM contenção (deny=0)" em **`main`** — o fix de segurança vive na branch `sec/lovable-mcp-deny`
  (pushada para origin), não em main. **Fecham quando o PR `sec→main` for mergeado** (decisão do dono —
  merge controlado vs. `settings.local.json` gitignored). O DoD do v15 exige `idea_doctor=PASS` p/ o SOAK
  → estes 2 FAILs precisam fechar antes de tagear o milestone. **Não é regressão do R15-09** (pré-existentes,
  só estavam mascarados pelo `--json` quebrado).

## Invariantes (não-negociáveis na execução)

- **antifragile-gates:** verificação por exit-code (`bash -n`, grep, JSON.parse), nunca Read tool.
- **autosync-race:** pausar autosync ANTES de cirurgia; verificar binário DEPLOYADO por grep.
- **No-Invention:** cada fato bate com o código real (verificado por grep/inspeção do snapshot).
- **Anti-falso-verde:** `--fleet` SEMPRE mostra idade; distingue DORMANT (>1d) e VAZIO (exit=-1) de OK.
- **bash 3.2 / sem declare -A:** agregação via `node` (sem jq), arrays/loops compatíveis.
