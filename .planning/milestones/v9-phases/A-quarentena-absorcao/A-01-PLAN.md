---
phase: A-quarentena-absorcao
plan: A-01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: []   # habilita R9-01, R9-02, R9-03, R9-05 (não fecha nenhum sozinho)
files_modified:
  - security/quarantine/mattpocock-skills/skills/grill-with-docs/CONTEXT-FORMAT.md   # (capturar)
  - security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md       # (capturar)
  - security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/LANGUAGE.md   # (capturar)
  - security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/HTML-REPORT.md # (capturar)
  - security/quarantine/mattpocock-skills/_catalog.yaml   # (atualizar vereditos finais)
must_haves:
  truths:
    - "Os resources de apoio que vamos absorver (CONTEXT-FORMAT, ADR-FORMAT, LANGUAGE, HTML-REPORT) estão capturados na quarentena — não só os SKILL.md"
    - "O scan de segurança (security/scan-absorbed.sh) re-roda sobre a pasta atualizada com exit 0 (sem FAIL)"
    - "Os 2 WARNs preexistentes (curl/ssh em docs; AgentShield offline) estão inspecionados e anotados como benignos"
    - "Os vereditos finais do _catalog.yaml batem com o relatório (grill-with-docs/grill-me/improve-architecture = absorver; o resto = ignore/overlaps-existing)"
    - "Reset de sessão pós-quarentena é registrado como obrigatório antes de Fase B (higiene de memória)"
  artifacts:
    - path: "security/quarantine/mattpocock-skills/_catalog.yaml"
      provides: "Catálogo com vereditos finais alinhados ao relatório + bloco security_scan revalidado"
      contains: "verdict"
  key_links: []
---

<objective>
Fechar a etapa de **quarentena & atribuição** antes de qualquer absorção real. A pasta `security/quarantine/mattpocock-skills/` já foi estagiada (commit upstream `694fa30`, LICENSE MIT, `_catalog.yaml`, scan `APROVADO COM RESSALVA` exit 0). O que falta é cirúrgico: capturar os **resources de apoio** que as Fases B/C/E vão adaptar (hoje listados em `not_captured`), revisar manualmente os 2 WARNs do scan, congelar os vereditos do catálogo conforme o relatório, e marcar o **reset de sessão pós-quarentena** como pré-condição da Fase B.

Purpose: garantir que o material de terceiro está **auditado, atribuído e completo** antes de virar `source/`. Sem os resources (`CONTEXT-FORMAT`/`ADR-FORMAT`/`LANGUAGE`/`HTML-REPORT`), a Fase B/E teria que ir buscar upstream no meio da autoria — quebrando o princípio de quarentena ("absorve do material já auditado, não da internet ao vivo").

Output: quarentena completa e congelada; `_catalog.yaml` com vereditos finais; nota de reset de sessão.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@docs/research/2026-06-16-mattpocock-skills-analise.md
@.planning/milestones/v9-REQUIREMENTS.md
@security/quarantine/mattpocock-skills/_catalog.yaml
@security/scan-absorbed.sh
@docs/security/memory-hygiene.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Capturar os resources de apoio que serão absorvidos (B/C/E)</name>
  <files>security/quarantine/mattpocock-skills/skills/grill-with-docs/CONTEXT-FORMAT.md, security/quarantine/mattpocock-skills/skills/grill-with-docs/ADR-FORMAT.md, security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/LANGUAGE.md, security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/HTML-REPORT.md</files>
  <action>
Baixar via raw.githubusercontent.com (mesmo método/commit `694fa30` do catálogo) os 4 resources hoje em `not_captured` que as fases seguintes adaptam:
- `skills/engineering/grill-with-docs/CONTEXT-FORMAT.md` → formato do glossário (Fase B / R9-02)
- `skills/engineering/grill-with-docs/ADR-FORMAT.md` → gate dos 3 critérios + formato ADR (Fase C / R9-03)
- `skills/engineering/improve-codebase-architecture/LANGUAGE.md` → glossário Module/Interface/Depth/Seam (Fase E / R9-05)
- `skills/engineering/improve-codebase-architecture/HTML-REPORT.md` → scaffold do relatório HTML (Fase E / R9-05)

Salvar sob `security/quarantine/mattpocock-skills/skills/<skill>/` preservando o caminho upstream. Conteúdo lido **verbatim** (revisão manual de injection inline — são docs, sem payload). NÃO promover para `source/` nesta fase.
  </action>
  <verify>
    <automated>for f in skills/grill-with-docs/CONTEXT-FORMAT.md skills/grill-with-docs/ADR-FORMAT.md skills/improve-codebase-architecture/LANGUAGE.md skills/improve-codebase-architecture/HTML-REPORT.md; do test -s "security/quarantine/mattpocock-skills/$f" || { echo "FALTA: $f"; exit 1; }; done && echo OK</automated>
  </verify>
  <done>Os 4 resources existem e são não-vazios na quarentena; conteúdo verbatim do commit 694fa30.</done>
</task>

<task type="auto">
  <name>Task 2: Re-rodar o scan de segurança + inspecionar os 2 WARNs</name>
  <files>security/quarantine/mattpocock-skills/_catalog.yaml</files>
  <action>
Re-rodar `bash security/scan-absorbed.sh security/quarantine/mattpocock-skills` sobre a pasta agora com os resources novos. Confirmar **exit 0** (sem FAIL). Inspecionar manualmente os 2 WARNs já registrados:
- "comandos suspeitos (curl/ssh/wget)" — confirmar que aparecem só em docs legítimas (`diagnose.md`, `setup-matt-pocock-skills.md`, `handoff.md` — nenhuma das quais será absorvida) e nos novos resources se houver; anotar como benigno.
- "AgentShield indisponível/offline" — scan parcial; anotar.
Atualizar o bloco `security_scan` do `_catalog.yaml` com `ran_at` novo e `counts` revalidados.
  </action>
  <verify>
    <automated>bash security/scan-absorbed.sh security/quarantine/mattpocock-skills; echo "exit=$?"  # esperado exit 0</automated>
  </verify>
  <done>scan exit 0 (0 FAIL); WARNs inspecionados e anotados como benignos; `security_scan` do catálogo atualizado.</done>
</task>

<task type="auto">
  <name>Task 3: Congelar vereditos finais no _catalog.yaml conforme o relatório</name>
  <files>security/quarantine/mattpocock-skills/_catalog.yaml</files>
  <action>
Trocar os `verdict: pending` por vereditos FINAIS alinhados ao relatório (`docs/research/2026-06-16-mattpocock-skills-analise.md`, §3 tabela):
- `grill-with-docs` → `absorб` (ADOTAR — núcleo da Fase B)
- `grill-me` → `absorber` (ADOTAR — modo `--rapido`)
- `improve-codebase-architecture` → `adaptar` (ADOTAR como ritual — Fase E)
- `to-prd` → `adaptar` (delta fino no @pm — Fase F/G)
- `diagnose` → `overlaps-existing` (gsd-debug; absorver só 1 nota — Fase F/G)
- `to-issues`, `triage`, `setup-matt-pocock-skills`, `tdd`, `zoom-out`, `prototype`, `handoff`, `write-a-skill` → `ignore`/`overlaps-existing` (já refletido)
- `caveman`, `zoom-out` → `ignore` (rebaixar de `candidate` — decisão do relatório: WON'T/COULD baixo)
Adicionar comentário apontando o relatório como fonte do veredito.
  </action>
  <verify>
    <automated>! grep -q 'verdict: pending' security/quarantine/mattpocock-skills/_catalog.yaml && echo OK</automated>
  </verify>
  <done>Nenhum `verdict: pending` restante; vereditos batem com a §3 do relatório.</done>
</task>

</tasks>

<verification>
- Resources de apoio capturados (Task 1) → habilitam Fase B (CONTEXT-FORMAT), C (ADR-FORMAT), E (LANGUAGE/HTML-REPORT).
- Scan exit 0 + WARNs benignos (Task 2) → pré-condição de segurança para promover qualquer conteúdo a `source/`.
- Vereditos finais (Task 3) → o catálogo deixa de ser placeholder e vira decisão rastreável.
</verification>

<success_criteria>
- 4 resources presentes e não-vazios na quarentena.
- `security/scan-absorbed.sh` exit 0; 2 WARNs anotados como benignos.
- `_catalog.yaml` sem `verdict: pending`; vereditos alinhados ao relatório; `security_scan` revalidado.
- Nota registrada: **reset de sessão obrigatório** antes de iniciar a Fase B (higiene de memória — `docs/security/memory-hygiene.md`).
</success_criteria>

<notes>
## Estado de entrada (já pronto antes desta fase)
A quarentena já existe e passou o scan uma vez (PASS 2 / WARN 2 / FAIL 0). Esta fase é o "finishing touch" + congelamento — por isso é curta e `autonomous: true`.

## Por que capturar os resources agora (e não na Fase B)
Princípio de quarentena: a absorção (Fase B/C/E) deve copiar/adaptar a partir do material **auditado em disco**, nunca buscar upstream ao vivo no meio da autoria. Capturar aqui mantém B/C/E offline-safe e auditáveis.

## Higiene
Após absorver/testar conteúdo de terceiro, **iniciar nova sessão** antes de seguir para trabalho confiável (regra do AGENTS.md / memory-hygiene). Esta fase marca isso como gate de transição A→B.
</notes>

<output>
Criar `.planning/milestones/v9-phases/A-quarentena-absorcao/A-01-SUMMARY.md` ao concluir.
</output>
