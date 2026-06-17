---
phase: E-deepening
plan: E-01
type: execute
wave: 2
depends_on: [B-grelha-glossario, C-adr-inline]
autonomous: false
requirements: [R9-05]
files_modified:
  - source/skills/improve-architecture/SKILL.md
  - source/skills/improve-architecture/LANGUAGE.md
  - source/skills/improve-architecture/HTML-REPORT.md
  - docs/decisions/NNNN-deepening-skill-vs-agente.md   # (ADR da decisão skill-nova-vs-enriquecer)
must_haves:
  truths:
    - "Está registrada (ADR) a decisão: skill nova `/improve-architecture` (alias `/aprofundar`) vs enriquecer refactor-cleaner/code-simplifier — com a recomendação do relatório (skill nova)"
    - "A skill busca 'deepening opportunities' (módulo raso → profundo, Ousterhout) usando o deletion test"
    - "Usa o glossário de arquitetura (Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality) E o CONTEXT.md do projeto para o domínio"
    - "Produz relatório HTML em tmp (não suja o repo) e cai num grilling loop reusando CONTEXT.md (R9-02) e ADR inline (R9-03)"
    - "É um ritual RECORRENTE (recomendação: rodar a cada poucos dias) e não re-litiga ADRs existentes"
  artifacts:
    - path: "source/skills/improve-architecture/SKILL.md"
      provides: "Ritual de deepening (Ousterhout) informado por CONTEXT.md + docs/decisions/"
      contains: "name: improve-architecture"
      min_lines: 70
    - path: "docs/decisions/NNNN-deepening-skill-vs-agente.md"
      provides: "ADR: skill nova vs enriquecer agente de limpeza"
      min_lines: 12
  key_links:
    - from: "source/skills/improve-architecture/SKILL.md"
      to: "source/skills/grelha/CONTEXT-FORMAT.md"
      via: "atualiza CONTEXT.md no grilling loop (mesma disciplina do /grelha)"
      pattern: "CONTEXT"
---

<objective>
Entregar o ritual recorrente de **saúde de design** — "deepening" no sentido de Ousterhout (módulos profundos: muito comportamento atrás de interface simples). Fecha **R9-05** (GAP 3).

Purpose: o IdeiaOS tem limpeza pontual (agents `code-simplifier`, `refactor-cleaner`) mas nenhum ritual recorrente que avalie a ARQUITETURA contra o vocabulário do domínio (`CONTEXT.md`) e as decisões registradas (`docs/decisions/`). Absorve `improve-codebase-architecture` de `mattpocock/skills` (MIT) como skill nova `/improve-architecture` (alias `/aprofundar`), reusando o glossário (R9-02) e o ADR inline (R9-03) no seu grilling loop.

Output: ADR da decisão skill-vs-agente + skill `/improve-architecture` + resources (LANGUAGE, HTML-REPORT) adaptados. SHOULD do milestone (pode ser v9.1).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@docs/research/2026-06-16-mattpocock-skills-analise.md   # §3 (verdito ADAPTAR) + §8 (SHOULD #4)
@.planning/milestones/v9-REQUIREMENTS.md
@security/quarantine/mattpocock-skills/skills/improve-codebase-architecture.md
@security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/LANGUAGE.md
@security/quarantine/mattpocock-skills/skills/improve-codebase-architecture/HTML-REPORT.md
@source/skills/grelha/SKILL.md
@source/skills/grelha/CONTEXT-FORMAT.md
@source/skills/grelha/ADR-FORMAT.md
# Comparar com o que já temos
@source/agents/refactor-cleaner.md
@source/agents/code-simplifier.md
</context>

<tasks>

<task type="decision" gate="blocking">
  <name>Task 1: ADR — skill nova vs enriquecer refactor-cleaner/code-simplifier</name>
  <files>docs/decisions/NNNN-deepening-skill-vs-agente.md</files>
  <action>
Registrar a decisão num ADR curto (formato do ADR-FORMAT — gate dos 3 critérios passa: difícil reverter? médio; surpreendente? sim; trade-off real? sim). Recomendação do relatório (§8 SHOULD #4): **skill nova `/improve-architecture`** (alias `/aprofundar`), porque:
- O ritual é RECORRENTE e tem um fluxo próprio (explorar → relatório HTML → escolher candidato → grilling loop) que não cabe num agente de limpeza pontual (`refactor-cleaner` remove código morto; `code-simplifier` simplifica trecho).
- Precisa de glossário de arquitetura próprio + integração com `CONTEXT.md`/ADR — comportamento de skill orquestradora, não de agente single-shot.
- Alternativa (enriquecer os agentes) ficaria espremida e perderia a recorrência e o relatório visual.
Confirmar a decisão com o usuário no checkpoint antes de autorar a skill (Task 2).
  </action>
  <verify>
    <automated>test -s docs/decisions/*deepening* && echo OK</automated>
  </verify>
  <done>ADR registrado com a decisão (recomendação: skill nova) e o racional; aguardando confirmação no checkpoint.</done>
</task>

<task type="auto">
  <name>Task 2: Skill /improve-architecture (alias /aprofundar) + resources</name>
  <files>source/skills/improve-architecture/SKILL.md, source/skills/improve-architecture/LANGUAGE.md, source/skills/improve-architecture/HTML-REPORT.md</files>
  <action>
Criar a skill PT-BR (frontmatter-first), absorvendo `improve-codebase-architecture` (MIT). Header `# SOURCE: mattpocock/skills MIT | adapted: IdeiaOS v9`.
- **Frontmatter `name: improve-architecture`**, description ativando em "melhorar arquitetura", "achar refactor", "módulos profundos/deepening", "consolidar acoplamento", "deixar mais testável/navegável por IA", "/aprofundar".
- **Glossário de arquitetura** (`LANGUAGE.md`, adaptado): Module/Interface/Implementation/Depth/Seam/Adapter/Leverage/Locality + princípios (deletion test; "a interface é a superfície de teste"; "1 adapter = seam hipotético, 2 = seam real"). Instruir a usar esses termos com consistência.
- **Processo (3 fases):**
  1. **Explorar** — ler `CONTEXT.md` (domínio) + `docs/decisions/` (ADRs da área) antes; depois explorar a codebase notando fricção (entender 1 conceito exige pular entre N módulos; módulos rasos; pure-functions extraídas só por testabilidade sem locality; acoplamento vazando seams; partes não-testáveis). Aplicar o **deletion test**.
  2. **Relatório HTML** (`HTML-REPORT.md`, adaptado) — arquivo self-contained no tmp do SO (`$TMPDIR`/`/tmp`), Tailwind+Mermaid CDN, 1 card por candidato (Files/Problem/Solution/Benefits/Before-After/Recommendation strength) + "Top recommendation". NÃO sujar o repo. Usar vocabulário do `CONTEXT.md` para o domínio e o glossário de arquitetura para a estrutura.
  3. **Grilling loop** — ao escolher candidato, cair num grilling (reusa a disciplina do `/grelha`): atualiza `CONTEXT.md` inline ao nomear módulo novo; oferece ADR (gate dos 3 critérios, `ADR-FORMAT.md`) quando o usuário rejeita candidato com razão load-bearing; não re-litiga ADRs existentes (só sinaliza conflito quando a fricção justifica reabrir).
- **Recorrência:** recomendar rodar "a cada poucos dias" / ao fim de um ciclo de feature.
- **Fronteira:** vs `refactor-cleaner` (remove morto) / `code-simplifier` (simplifica trecho) / `/doubt` (audita decisão). Aqui é design de arquitetura recorrente.
- Tabela anti-racionalização + Red flags + Verificação. Zero `<!--`.
  </action>
  <verify>
    <automated>test -s source/skills/improve-architecture/SKILL.md && grep -q '^name: improve-architecture' source/skills/improve-architecture/SKILL.md && grep -q 'SOURCE: mattpocock/skills MIT' source/skills/improve-architecture/SKILL.md && grep -qi 'deletion test\|deletion' source/skills/improve-architecture/SKILL.md && test -s source/skills/improve-architecture/LANGUAGE.md && test -s source/skills/improve-architecture/HTML-REPORT.md && ! grep -rq '<!--' source/skills/improve-architecture/ && echo OK</automated>
  </verify>
  <done>Skill + LANGUAGE + HTML-REPORT presentes; glossário de arquitetura + deletion test + relatório HTML em tmp + grilling loop reusando CONTEXT.md/ADR; recorrência; proveniência MIT; zero `<!--`.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
Ritual de deepening: ADR da decisão skill-vs-agente + skill `/improve-architecture` (glossário de arquitetura, deletion test, relatório HTML em tmp, grilling loop) reusando CONTEXT.md/ADR.
  </what-built>
  <how-to-verify>
1. Aprovar a decisão do ADR (Task 1): skill nova vs enriquecer agente.
2. **Smoke:** rodar a skill contra a própria codebase do IdeiaOS (ou um produto) e confirmar que produz ≥1 candidato de deepening num relatório HTML no tmp (não no repo), usando termos do CONTEXT.md + glossário de arquitetura, com before/after.
3. Confirmar que o grilling loop atualiza CONTEXT.md ao nomear módulo e oferece ADR conforme o gate.
  </how-to-verify>
  <resume-signal>Digite "aprovado: E" / "skill nova" / "enriquecer agente" + ajustes.</resume-signal>
</task>

</tasks>

<verification>
R9-05: ADR skill-vs-agente (Task 1); skill com glossário de arquitetura + deletion test + relatório HTML + grilling loop reusando R9-02/R9-03 (Task 2); recorrência + não-re-litiga-ADR (Task 2).
</verification>

<success_criteria>
- Decisão skill-vs-agente registrada em ADR (recomendação: skill nova `/improve-architecture`, alias `/aprofundar`).
- Skill absorve glossário de arquitetura + deletion test + relatório HTML em tmp + grilling loop reusando CONTEXT.md/ADR.
- Usa vocabulário do CONTEXT.md (domínio) + glossário de arquitetura (estrutura); não re-litiga ADRs.
- Ritual recorrente documentado; proveniência MIT; zero `<!--`.
</success_criteria>

<notes>
## SHOULD, não MUST
R9-05 é SHOULD (relatório §8). Pode ser fatiado como v9.1 se o tempo apertar — B/C/D fecham o núcleo (MUST). Esta fase depende de B (glossário) e C (ADR inline) porque reusa ambos no grilling loop.

## Por que skill nova (recomendação)
`refactor-cleaner`/`code-simplifier` são agentes single-shot de limpeza pontual. O deepening é um ritual recorrente com fluxo próprio (explorar→HTML→grilling) e glossário de arquitetura — não cabe num agente de limpeza. A decisão final é do checkpoint.
</notes>

<output>
Criar `.planning/milestones/v9-phases/E-deepening/E-01-SUMMARY.md` ao concluir.
</output>
