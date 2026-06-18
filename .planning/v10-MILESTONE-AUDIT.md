# Auditoria de Fechamento — Milestone v10 (Camada de Integração Lovable MCP)

**Data:** 2026-06-18 · **Branch:** `work` (= `main` = `origin`) · **Veredito:** 🟡 PARCIAL — camada read-only SHIPPED; write-path 🔴 BLOQUEADO por evidência; Fases C/D PARQUEADAS-GATED
**Fonte de verdade:** dossiê 2026-06-17 + ADR `docs/decisions/v10-lovable-mcp-readfirst-containment.md` + `.planning/milestones/v10-phases/B-sandbox/B-01-SUMMARY.md` + commit `1dc1e1b`
**Escopo deste fechamento:** Fase A SHIPPED · Fase B executada-com-veredito · Fases C/D parqueadas
**Tag:** `no-tag` (precedente v2.0..v9.0: tag só em milestone COMPLETO; este fecha PARCIAL)
**Como foi auditado:** workflow `wf_4fec3ed7-fc0` (4 auditores paralelos — soundness do veredito, contenção, consistência documental, gap de closure-doc — + sintetizador).

---

## 1. Origem e tese

O v10 nasce para **somar verificação programática read-first** ao plano-GitHub maduro
(`/lovable-handoff`), sem substituí-lo. Ataca dois incidentes recorrentes: nº1 deploy-drift
(o que está publicado ≠ o que está no Git) e nº3 hotfix inline (edição direta na Cloud que
não volta ao repositório). Postura inegociável, lapidada via `/grelha` (4 forks de decisão
fechados): **aditiva, read-first, contenção em 2 níveis** (off-by-default + harness-deny).

O princípio de design: o MCP da Lovable é classificado **High/Critical** na régua
`mcp-hygiene` (write access + outward-facing, sem `delete_project`). A camada read-only é
segura e durável; toda capacidade mutante fica atrás de um gate de evidência.

## 2. Escopo entregue (Fase A) vs parqueado (B veredito + C/D gated)

- **Fase A — SHIPPED 2026-06-18.** Skill `/lovable-mcp` v1 read-only (`verify-deploy` +
  `detect-hotfix`), resolver de escopo identity-aware, contenção dura, empacotamento completo,
  ADR de postura. Nenhum verbo da skill chama tool mutante.
- **Fase B — EXECUTADA COM VEREDITO 🔴 BLOQUEAR publish-via-MCP (2026-06-18).** Sandbox via
  fork remixado; A1-namespace=ACOPLADO + A3=PASS (read-only confirmado), mas A1-lag e A2
  ficaram INMENSURÁVEIS no instrumento usado (fork sem gitsync). Indeterminado-vota-bloquear.
- **Fases C/D — PARQUEADAS-GATED.** R10-07 (v2: schema-check + dois cérebros) e R10-08
  (v3: publish + compilador de knowledge) gateadas atrás de R10-06. `publish` permanece
  bloqueado por design enquanto A2 não for medido fora do MCP.

## 3. Tabela de disposição de requisitos (R10-01..08)

| ID | Requisito | Fase | Disposição | Evidência de wiring |
|----|-----------|------|------------|---------------------|
| R10-01 | Skill `/lovable-mcp` v1 read-only (`verify-deploy` + `detect-hotfix`) | A | ✅ DONE | helper `source/lib/lovable-mcp.sh` gateado por `gates.sh`; verbos sem tool mutante |
| R10-02 | Resolver de escopo identity-aware (2 tiers + override `lovable-scope.yaml`) | A | ✅ DONE | `in_scope = na-pasta OU created_by==get_me.id`; refinado via `/grelha` |
| R10-03 | Contenção dura (off-by-default + harness-deny 19 tools + `query_database` deny puro) | A | ✅ DONE | deny=19 validado binário nos 5 alvos; `@devops` único a promover a `ask` |
| R10-04 | Empacotamento (build-plugins CORE_SKILLS + modules.json + membership + README + rule) | A | ✅ DONE | `mcp-protocol.md` na lista explícita do `build_lovable()`; gates verdes |
| R10-05 | ADR de postura (read-first aditivo + contenção 2 níveis) | A | ✅ DONE | `docs/decisions/v10-lovable-mcp-readfirst-containment.md` (5969 bytes) |
| R10-06 | Fase Sandbox — gate de todo write-path | B | ✅ DONE — veredito 🔴 BLOQUEAR | A1-namespace ACOPLADO + A3 PASS; A1-lag+A2 inmensuráveis → indeterminado vota bloquear |
| R10-07 | v2 — schema-check + teste dos dois cérebros | C | ⏸️ PARQUEADO-GATED | gated em R10-06; reabre só ao medir A2 fora do MCP |
| R10-08 | v3 — drive-cloud-agent/publish + compilador `build-lovable-knowledge.sh` | D | ⏸️ PARQUEADO-GATED | duplamente atrás de R10-06; `publish` bloqueado por design |

## 4. Gates binários (exit code, não Read tool) — escopo Fase A

Todos verdes no ship da Fase A, verificados por exit code:

- `idea-doctor` → 0 FAIL
- `check-plugin-membership` → 0 deriva
- `check-readme-sync` → N/N
- `build-plugins` → `lovable-mcp` presente em `CORE_SKILLS`
- `build-lovable` → `mcp-protocol.md` na lista explícita
- `node JSON.parse modules.json` → válido
- **harness-deny → 19 tools mutantes (binário)**
- helper `lovable-mcp.sh` → gateado por `gates.sh`

## 5. Verificação adversarial

- **Fase A:** painel 4-lentes PASSED após fixes (parser awk, exit-codes, shallow-clone,
  contagem README).
- **Fase B:** veredito 🔴 BLOQUEAR. Raciocínio: A1-namespace=ACOPLADO, A3=PASS (read-only),
  A1-lag + A2 INMENSURÁVEIS no sandbox. A regra de decisão (indeterminado→bloquear) estava
  **pré-comprometida no PLAN antes de medir** — não é racionalização pós-hoc. Para destravar
  uma ação irreversível e outward-facing, o ônus correto é evidência POSITIVA de que o deploy
  lê de `main`; sem ela, bloqueia-se. **Soundness confirmada (confiança alta)** pela auditoria
  de fechamento (`wf_4fec3ed7-fc0`).

  Correção de precisão retórica aplicada neste doc (não inverte o veredito):
  - O achado real é "A2 inmensurável **no INSTRUMENTO fork sem gitsync**", não "impossível
    via MCP". A2 **é** mensurável via MCP num PRODUTO REAL com gitsync (push divergente +
    `deploy_project` + ler bundle).
  - "Pior-caso refutado" prova que a Cloud **INGERE** git (`developer_update` aparece em
    `list_edits`), não que o **DEPLOY** constrói o bundle a partir do git pós-ingestão.
    O resíduo "deploy lê snapshot pré-ingestão" NÃO foi excluído pelo read-only — isso
    **reforça** o BLOCK, não o enfraquece.

## 6. Muro de viabilidade (achado central)

A Fase B quis medir A2 (de qual fonte o `deploy_project` constrói o bundle) dentro do sandbox.
Quatro candidatos de medição via MCP foram avaliados e caíram na mesma parede:

| Candidato | Por que falha |
|-----------|----------------|
| deploy + read-back (`get_project.latest_commit_sha` / `get_diff` / preview) | fork tem 1 só escritor (agente Cloud) → "main" e "estado interno" são o MESMO commit; impossível separá-los |
| `read_file` `ref=main` vs `ref=latest_commit_sha` | mesma parede: single-writer → refs idênticos |
| `list_edits` sequencial / sha antes-depois de `send_message` | mede direção Cloud→git (A1-lag), não main→deploy (A2) |
| concorrência / revert para divergência interna | nenhum cria um escritor-não-Cloud em `main` |

**Conclusão:** A2 só é mensurável onde existe um 2º escritor a `main` = `git push`
(developer_update via gitsync) — que o FORK não tem. O fork foi o **instrumento errado**.
O muro segura PARA O FORK; não prova "inmensurável por qualquer meio MCP".
**Aprendizado registrado:** `mcp-wrapper-hides-underlying-layer` — um MCP/wrapper pode
abstrair justamente a camada (Git/gitsync) que a verificação precisa manipular.

## 7. Segurança / proveniência / contenção

**Contenção ÍNTEGRA nos 5 alvos** (contagem binária via `python3 json.load`, por-array):

| Alvo | deny | ask | allow | disabled | `query_database` |
|------|------|-----|-------|----------|------------------|
| IdeiaOS | 19 | 0 | 0 | true | deny puro |
| nfideia | 19 | 0 | 0 | true | deny puro |
| ideiapartner | 19 | 0 | 0 | true | deny puro |
| cfoai-grupori | 19 | 0 | 0 | true | deny puro |
| lapidai | 19 | 0 | 0 | true | deny puro |

Os 5 batem 100% com a lista canônica de 19 tools mutantes em
`source/rules/lovable/mcp-protocol.md` (sem falta/extra/duplicata). Os 4 `settings.local.json`
existentes têm ZERO referência ao connector — nenhum override re-habilita mutação.

**Achado de segurança (registrado, não-bloqueante):** o `deny` do `.claude/settings.json` é
**relido mid-session sem restart**, e um autosync pode capturar a janela aberta. Implicação
operacional: nunca fazer `git checkout` cego para limpar a janela; comparar os SETS de deny
de HEAD × working tree. Distinção doutrinária mantida: resolver-de-escopo (operacional) ≠
contenção-dura (capability). `@devops` é o único a promover qualquer tool a `ask`.
Aprendizado: `claude-settings-deny-live-reload-autosync-capture`.

**Buraco de evidência menor (não afeta veredito):** não foi confirmado se o harness exibiu
prompt `ask` por chamada durante a janela aberta — comportamento da contenção mid-session
fica como item de observação futura.

## 8. Estado de rollout

- **Lado-agente — FEITO.** `deny` + `disabledMcpServers` aplicados nos 4 produtos
  (nfideia/ideiapartner/cfoai/lapidai) + no próprio IdeiaOS; deny=19 validado binário.
- **Lado-usuário — toggles de painel FEITOS** (usuário deixou só o workspace
  `Grupo Ideia - Dev` no alcance, satisfazendo o Gate 3 da Fase B).
- **Fork descartável `1d0652c4` — DELETADO** pelo usuário (`get_project`=404 +
  `list_projects`=0; zero resíduo na conta Lovable).
- **Resíduo = SÓ ação do usuário:** rodar `/lovable-mcp verify-deploy` de dentro de um
  produto real (ex.: nfideia) como teste end-to-end.

## 9. Próximos passos para destravar (carried-forward)

R10-06 **reabre** apenas se houver apetite de medir A2 (gitsync) **FORA do MCP**:

1. Num PRODUTO REAL com gitsync ativo, criar um commit em `main` que a Cloud NÃO originou
   (push divergente via Git direto).
2. Disparar `deploy_project` e ler o bundle publicado.
3. **Critério objetivo de reabertura:** se o bundle refletir o commit divergente de `main`,
   A2=main (deploy lê de git) → destrava R10-07; senão, write-path permanece bloqueado.

R10-07 e R10-08 ficam gated atrás desse resultado. `publish` permanece bloqueado por design
até A2 medido.

## 10. Veredito final

**🟡 PARCIAL — fechamento formal.**

- **DONE e durável:** camada read-only (R10-01..R10-05), contenção (deny=19 nos 5 alvos),
  empacotamento, ADR de postura.
- **BLOQUEADO por evidência:** write-path (`publish`/`send_message` mutante) — R10-06 votou
  🔴 BLOQUEAR; soundness do veredito confirmada com confiança alta.
- **PARQUEADO-GATED:** R10-07/R10-08 atrás de medir A2 fora do MCP.

Estado do repo: `work` = `main` = `origin`, limpo. **Tag:** `no-tag` (milestone PARCIAL).
Próximo passo registrado no handoff: rodar `/lovable-mcp verify-deploy` num produto real.

---

## Addendum (follow-ups pós-fechamento)

- _(reservado — registrar aqui medições de A2 fora do MCP, reabertura de R10-06, ou decisão
  de fechar o write-path definitivamente como "read-only-only" com ADR.)_
