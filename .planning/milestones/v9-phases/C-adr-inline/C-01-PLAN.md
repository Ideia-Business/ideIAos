---
phase: C-adr-inline
plan: C-01
type: execute
wave: 2
depends_on: [B-grelha-glossario]
autonomous: false
requirements: [R9-03]
files_modified:
  - source/skills/grelha/ADR-FORMAT.md
  - source/skills/grelha/SKILL.md   # (wiring do passo "oferecer ADR" para o ADR-FORMAT)
must_haves:
  truths:
    - "ADR ultraleve é oferecido pelo /grelha SÓ quando os 3 critérios são todos verdadeiros (difícil reverter + surpreendente sem contexto + trade-off real)"
    - "ADRs do grilling moram em docs/decisions/ (reuso do diretório existente) — NÃO se cria docs/adr/ paralelo"
    - "Numeração sequencial NNNN-slug.md, criação preguiçosa do diretório"
    - "ADRs entram no espelhamento ADR→Obsidian já existente do /extract-learnings (Passo 4c) — sem pipeline novo"
    - "Formato mínimo: título + 1-3 frases; seções opcionais (Status/Opções/Consequências) só quando agregam"
  artifacts:
    - path: "source/skills/grelha/ADR-FORMAT.md"
      provides: "Gate dos 3 critérios + formato mínimo de ADR (adaptado PT-BR), apontando para docs/decisions/"
      contains: "docs/decisions"
      min_lines: 35
  key_links:
    - from: "source/skills/grelha/SKILL.md"
      to: "source/skills/grelha/ADR-FORMAT.md"
      via: "referência no passo 'oferecer ADR'"
      pattern: "ADR-FORMAT"
---

<objective>
Entregar o terceiro vértice da tripartição do conhecimento do `/grelha`: o **ADR ultraleve inline**, gerado durante o grilling quando uma decisão irreversível se cristaliza. Fecha **R9-03**.

Purpose: capturar o "porquê" de decisões difíceis de reverter no momento em que elas acontecem, com atrito mínimo, **reusando a infraestrutura que já temos** — o diretório `docs/decisions/` e o espelhamento ADR→Obsidian do `/extract-learnings`. Sem isso, o glossário (R9-02) guarda o *vocabulário* e o `/spec` guarda o *comportamento*, mas o *porquê irreversível* ficaria órfão.

Output: resource `ADR-FORMAT.md` (gate dos 3 critérios + formato mínimo PT-BR) + wiring do passo "oferecer ADR" na skill `/grelha`. Sem novo diretório, sem novo pipeline.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@docs/research/2026-06-16-mattpocock-skills-analise.md
@.planning/milestones/v9-REQUIREMENTS.md
@security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md
@source/skills/grelha/SKILL.md
@docs/decisions/v9-mattpocock-skills-absorcao.md
# Confirmar o formato dos ADRs existentes do repo
@docs/decisions/v5-memory-topology.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Resource ADR-FORMAT.md (gate dos 3 critérios, PT-BR, mora em docs/decisions/)</name>
  <files>source/skills/grelha/ADR-FORMAT.md</files>
  <action>
Adaptar PT-BR de `security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md`, mas APONTANDO PARA `docs/decisions/` (não `docs/adr/`). Conteúdo:
- **Onde moram:** `docs/decisions/NNNN-slug.md` (o repo já usa `docs/decisions/`; conferir os existentes — alguns usam slug sem número, ex. `v5-memory-topology.md`). Decisão: ADRs do grilling usam **numeração sequencial** `NNNN-slug.md` (varrer o maior número existente e incrementar); ADRs de milestone podem manter o padrão `vN-slug.md` já em uso. Documentar as duas convicções coexistindo.
- **Criação preguiçosa:** só criar o arquivo quando o 1º ADR for necessário.
- **Formato mínimo:** título (`# {decisão curta}`) + 1-3 frases (contexto + decisão + porquê). "Um ADR pode ser um único parágrafo."
- **Seções opcionais** (só quando agregam): `Status` (proposto/aceito/descontinuado/substituído), `Opções consideradas`, `Consequências`.
- **GATE dos 3 critérios (TODOS verdadeiros):**
  1. **Difícil de reverter** — custo real de mudar de ideia depois.
  2. **Surpreendente sem contexto** — um leitor futuro perguntaria "por que fizeram assim?".
  3. **Resultado de trade-off real** — havia alternativas e escolhemos uma por razões específicas.
  Se qualquer um falha → **NÃO oferecer ADR** (decisão fácil de reverter você só reverte; não-surpreendente ninguém questiona; sem alternativa não há o que registrar).
- **O que qualifica** (lista do upstream, PT-BR): forma arquitetural; padrão de integração entre contextos; escolha de tecnologia com lock-in; decisão de fronteira/escopo; desvio deliberado do caminho óbvio; restrição não-visível no código; alternativa rejeitada por razão não-óbvia.
- **Integração Obsidian:** registrar que o `/extract-learnings` (Passo 4c — espelhamento `docs/decisions/` → vault `Decisions/`) já cobre esses ADRs; o `/grelha` não cria pipeline próprio, só escreve em `docs/decisions/`.
- Header `# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9`. Zero `<!--`.
  </action>
  <verify>
    <automated>test -s source/skills/grelha/ADR-FORMAT.md && grep -q 'docs/decisions' source/skills/grelha/ADR-FORMAT.md && ! grep -q 'docs/adr' source/skills/grelha/ADR-FORMAT.md && grep -qi 'revert\|reverter' source/skills/grelha/ADR-FORMAT.md && grep -qi 'trade-off\|trade off' source/skills/grelha/ADR-FORMAT.md && ! grep -q '<!--' source/skills/grelha/ADR-FORMAT.md && echo OK</automated>
  </verify>
  <done>ADR-FORMAT.md com gate dos 3 critérios, formato mínimo, aponta docs/decisions/ (não docs/adr/), integração Obsidian via extract-learnings; zero `<!--`; proveniência MIT.</done>
</task>

<task type="auto">
  <name>Task 2: Wiring do passo "oferecer ADR" no /grelha</name>
  <files>source/skills/grelha/SKILL.md</files>
  <action>
No passo do modo `--docs` "efeitos colaterais inline → oferecer ADR" (criado na Fase B), referenciar explicitamente `source/skills/grelha/ADR-FORMAT.md` e o gate dos 3 critérios: o `/grelha` **oferece** ADR (não impõe) quando os 3 critérios passam, escreve em `docs/decisions/NNNN-slug.md`, e **pula** silenciosamente quando qualquer critério falha. Adicionar 1 linha na seção "Interação com outras skills": "ADRs gerados aqui são espelhados ao Obsidian pelo `/extract-learnings` (Passo 4c) — sem pipeline novo."
  </action>
  <verify>
    <automated>grep -q 'ADR-FORMAT' source/skills/grelha/SKILL.md && grep -qi 'docs/decisions' source/skills/grelha/SKILL.md && echo OK</automated>
  </verify>
  <done>SKILL.md referencia ADR-FORMAT.md e o gate dos 3 critérios; menção ao espelhamento Obsidian via extract-learnings.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
ADR ultraleve inline do `/grelha`: gate dos 3 critérios, formato mínimo, mora em `docs/decisions/`, espelhado ao Obsidian pelo fluxo existente.
  </what-built>
  <how-to-verify>
1. Ler `source/skills/grelha/ADR-FORMAT.md`: gate dos 3 critérios claro; aponta `docs/decisions/`; NÃO menciona criar `docs/adr/`.
2. **Smoke:** continuar a sessão sandbox da Fase B; numa decisão irreversível fictícia (ex. "vamos usar estado de servidor, não client-side"), confirmar que o `/grelha` oferece ADR e, ao aceitar, escreve `docs/decisions/0001-<slug>.md` no formato mínimo; e que numa decisão trivial (reversível) ele PULA o ADR.
3. Confirmar que o `/extract-learnings` Passo 4c já espelha `docs/decisions/` → Obsidian (ler o SKILL.md do extract-learnings para validar que o passo existe).
  </how-to-verify>
  <resume-signal>Digite "aprovado: C" ou ajustes no gate / numeração.</resume-signal>
</task>

</tasks>

<verification>
R9-03: gate dos 3 critérios (Task 1), formato mínimo (Task 1), reuso de docs/decisions/ sem docs/adr/ (Task 1 + verify), espelhamento Obsidian via extract-learnings (Task 1+2), oferta-não-imposição (Task 2).
</verification>

<success_criteria>
- `ADR-FORMAT.md` com gate dos 3 critérios (todos obrigatórios) e formato mínimo (título + 1-3 frases).
- ADRs moram em `docs/decisions/` (numeração sequencial NNNN-slug); `docs/adr/` NÃO é criado.
- `/grelha` oferece (não impõe) ADR e pula quando algum critério falha.
- Espelhamento Obsidian reusa `/extract-learnings` Passo 4c — sem pipeline novo.
- Proveniência MIT; zero `<!--`.
</success_criteria>

<notes>
## Reuso, não reinvenção
O IdeiaOS já tem `docs/decisions/` (6 ADRs, incl. o `v9-mattpocock-skills-absorcao.md`) e o espelhamento Obsidian no `/extract-learnings`. Esta fase é fina: um resource + wiring. O erro a evitar é criar `docs/adr/` paralelo (fragmentaria o histórico de decisões).

## Convenção de numeração
Coexistem duas: `vN-slug.md` (ADRs de milestone, ex. `v5-memory-topology.md`) e `NNNN-slug.md` (ADRs táticos do grilling). Documentar para não gerar conflito de nomes.
</notes>

<output>
Criar `.planning/milestones/v9-phases/C-adr-inline/C-01-SUMMARY.md` ao concluir.
</output>
