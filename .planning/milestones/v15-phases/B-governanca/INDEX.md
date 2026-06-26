# Fase B — "Governança visível + Cockpit rico" (Onda 2 do v15) · INDEX

**Milestone:** v15 (DX & Frota) · **Fase:** B · **Status:** ✅ COMPLETA (8/8 DONE; 2026-06-26).
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
| B-04 | R15-12 | 1 | — | ✅ pass (coleta b+c + exposição (a) GET) | `R15-12-dados-ricos-PLAN.md` |
| B-05 | R15-13 | 1 | **R15-12(a)** ✅ | ✅ pass (1ª-classe + microcopy; test-recorder exit 0) | `R15-13-14-ui-pair-SUMMARY.md` |
| B-06 | R15-14 | 1 | **R15-12(a)** ✅ | ✅ pass (card GET consome /soak real; frescor-tier diferido) | `R15-13-14-ui-pair-SUMMARY.md` |
| B-07 | R15-15 | 2 | **R15-05** ✅ | ✅ pass (eliminar dup + índice + gate cobertura) | `R15-15-runbook-SUMMARY.md` |
| B-08 | R15-16 | 1 | — | ✅ pass | `R15-16-hello-world-PLAN.md` |

## Grafo de execução

- **R15-09** (costura) é independente e o movimento-âncora — feito 1º.
- **R15-10/12/16** independentes (paralelizáveis) — ✅ DONE.
- **R15-13/R15-14** dependem de **R15-12(a)** (✅) — a exposição GET é a FONTE que a UI deles
  consome (Flight Recorder drill-down; card governança via `/soak`+`/projects`). Desbloqueados.
- **R15-11** depende de R15-06 (✅ A-08 fechou) — desbloqueado.
- **R15-15** HARD-GATE em R15-05 (✅ Fase A) — desbloqueado, mas é Wave 2 (consolida docs já corrigidos).

## Movimento-âncora

**R15-09 (`idea-doctor --fleet`)** — "o ponto de costura barato entre instalar e gerenciar".
Independente, dado já no ref `cockpit`, validável por exit-code. ✅ DONE.

## Carry-forward / achados

- **FASE B COMPLETA (8/8) — R15-13/R15-14 (par de UI) DONE:** o Flight Recorder subiu a 1ª-classe
  (após o hero) com microcopy LAW vs INTERPRETED visível; o card "Saúde & Governança" consome o
  `GET /soak` REAL (que NENHUMA tela usava — gap que o R15-12 abriu). Verificado regime-R
  (render+screenshot+network: `/overview`,`/soak`,`/fleet` 200) + exit-code (tsc/build/test-recorder
  exit 0). **Frescor-tier de segurança DIFERIDO** (slot honesto `aguardando coleta`): é o único
  net-new de coleta (mexeria no `collect.js`/agentd + re-coleta do ref cockpit). SUMMARY:
  `R15-13-14-ui-pair-SUMMARY.md`. **Resíduo p/ tag (não-fase):** PR `sec→main` cfoai/nfideia +
  re-coleta do agentd (preenche 2 n/a do doctor + supabase_project_id + installed_versions).
- **R15-15 (runbook único) DONE — interpretação não-literal autorizada pelo dono:** "consolidar
  os 5 docs" foi executado como **eliminar duplicação (INSTALL-WINDOWS.md ⊂ windows-wsl.md, 54%
  verbatim → stub 163→22 linhas) + índice (`docs/guides/README.md`)**, NÃO fusão num monólito
  (onboarding/env-setup são heterogêneos, single-source dos seus assuntos). Enforcement durável:
  `check-readme-sync.sh` ganhou gate de cobertura (gotcha ≥1 no runbook + âncora de corpo ausente
  no stub), **anti-teatro provado** (exit 1 em input inválido nos 2 sub-gates). SUMMARY:
  `R15-15-runbook-SUMMARY.md`.
- **R15-12(a) → R15-13/R15-14 (FRONTEIRA exposição↔render):** R15-12(a) entregou a camada de
  EXPOSIÇÃO GET (`/projects`, `/soak`, `/doctor?cell`, `accounts` no `/fleet`) — provada por
  exit-code (7 gates). O **render** desses 4 dados na SPA é dos requisitos de UI: R15-13 (Flight
  Recorder/drill-down) e R15-14 (card Saúde & Governança consome `/soak`+`/projects`). Não
  renderizei aqui (disciplina de escopo). `doctor.sections=[]` e `supabase_project_id=null` hoje
  são honestos (snapshots pré-fix `--json`); preenchem no próximo ciclo do agentd.
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
