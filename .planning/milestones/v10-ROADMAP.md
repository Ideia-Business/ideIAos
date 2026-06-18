# Roadmap — v10: Camada de Integração Lovable MCP

**Milestone:** v10
**Aberto:** 2026-06-17 · **Status:** 🔵 EM ANDAMENTO — Fase A SHIPPED 2026-06-18 (1/4); B/C/D pendentes/gated
**Numeração de fases:** lettered (Fase A–D), espelhando v8/v9.
**Grafo de dependências:** `A (independente, buildável já)` ; `B → C → D` (B é o gate de toda escrita).

## Tese

Somar ao plano-GitHub maduro (`/lovable-handoff`) uma **camada de verificação programática** sobre o que hoje é manual e cego, **aditiva e read-first**. O valor read-only chega já (Fase A), sem créditos e sem suposições; tudo que escreve fica atrás de um experimento de sandbox (Fase B) que mede o comportamento não-documentado do sync GitHub↔Cloud. Contenção real (harness-deny + toggle de workspace + folder-scope), `@devops` para mutações, `.aiox-core` PRISTINE (tudo em `source/`). Postura em `docs/decisions/v10-lovable-mcp-readfirst-containment.md`.

---

## Fases

### Fase A — v1 read-only (a "cabana" que entrega 80%) · ✅ SHIPPED 2026-06-18

**Objetivo (goal-backward):** rodar `/lovable-mcp verify-deploy` e `detect-hotfix` num produto e detectar drift/hotfix de verdade, sem tocar prod, sem crédito, sem depender de nenhuma suposição.
**Entregar:**
- `source/skills/lovable-mcp/SKILL.md` (verbos `verify-deploy` + `detect-hotfix`) + helper gateado por `source/lib/gates.sh`.
- Escopo dinâmico via pasta "Grupo Ideia" (`list_projects(folder_id)`, recusa fora).
- `.claude/settings.json` dos produtos: MCP `disabledMcpServers` + harness-deny das ~15 tools mutantes (`query_database` em deny puro).
- Rule `source/rules/lovable/mcp-protocol.md` + entrada na lista de `build_lovable()`; cross-link no `/lovable-handoff`.
- Empacotamento: `build-plugins.sh` (CORE_SKILLS), `manifests/modules.json`, `plugin-membership.md`, `README.md`.
**Cobre:** R10-01, R10-02, R10-03, R10-04, R10-05.
**Pré-condições do usuário (painel Lovable, ~1 min):** desligar `mcp_enabled` nos 2 workspaces não-dev; passar o `folder_id` da pasta "Grupo Ideia".
**Done:** dry-run de `verify-deploy` num produto pega (ou confirma ausência de) drift comparando com um `/lovable-handoff` recém-feito; `idea-doctor` 0 FAIL; membership 0 deriva; README N/N. **Não depende da Fase B.**

### Fase B — Sandbox / validação de suposições (gate de TODA escrita)

**Objetivo (goal-backward):** medir, sem risco em prod, as suposições que decidem se o write-path é seguro.
**Entregar:** experimento via `remix_project` de 1 produto; medições de (1) namespace/timing do mirror GitHub↔Cloud, (2) fonte de leitura do `deploy_project` (main vs estado Cloud interno); resultado registrado no dossiê.
**Cobre:** R10-06.
**Done:** as 4 suposições da §2.5 do dossiê respondidas com evidência; veredito explícito sobre liberar (ou bloquear) `publish`/`send_message`. Custo: alguns créditos de build.

### Fase C — v2: schema-check + teste manual dos dois cérebros · após B

**Objetivo (goal-backward):** automatizar a verificação schema-first com segurança, e MEDIR se a governança no agente Cloud funciona antes de construir o compilador.
**Entregar:** verbo `schema-check` (SQL fixo `information_schema`, `query_database` ask-gated sob @devops) + teste manual de `set_project_knowledge` em cfoai (com backup), com teste de aceitação (agente recusa arquivo protegido?).
**Cobre:** R10-07.
**Done:** `schema-check` reflete o schema REAL de prod sem expor SQL arbitrário; o teste manual decide se o compilador (Fase D) se justifica — se o agente não muda, o compilador morre aqui.

### Fase D — v3: write-path + compilador de governança · após C provar valor

**Objetivo (goal-backward):** dirigir o agente Cloud e publicar com segurança, e propagar a governança IdeiaOS para o agente Cloud de forma idempotente.
**Entregar:** verbos `drive-cloud-agent` (`plan_mode` primeiro, quiesce + bracketing SHA, check de saldo) e `publish` (só se a Fase B confirmar que `deploy_project` lê de main); `build-lovable-knowledge.sh` (compila `source/rules/lovable/*` → Knowledge/Skills, gera artefato) + gate de drift source→artefato por SHA.
**Cobre:** R10-08.
**Done:** write-path com detecção+reconciliação (não exclusão); compilador com gate binário local; publicação de Knowledge é verbo @devops separado.

---

## Sequência recomendada

`A` (já) → `B` (quando houver apetite p/ escrita; custa créditos) → `C` → `D` (só se C provar valor).
A Fase A é independente e entrega o grosso do valor; B/C/D são incrementais e cada uma só abre após a anterior.
