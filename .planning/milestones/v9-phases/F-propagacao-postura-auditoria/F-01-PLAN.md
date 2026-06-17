---
phase: F-propagacao-postura-auditoria
plan: F-01
type: execute
wave: 3
depends_on: [B-grelha-glossario, C-adr-inline, D-gate-deia, E-deepening]
autonomous: false
requirements: [R9-06, R9-07]
files_modified:
  - scripts/build-plugins.sh                 # CORE_SKILLS += grelha, improve-architecture
  - manifests/plugin-membership.md           # tabela "Skills core" 28 → 30
  - manifests/modules.json                   # +entradas grelha, improve-architecture, ubiquitous-language
  - README.md                                # "O que instala" + "Estrutura" + "Como usar"
  - docs/decisions/v9-mattpocock-skills-absorcao.md   # (já existe — referenciar nos headers)
  - .planning/v9-MILESTONE-AUDIT.md          # auditoria final (estilo v8)
must_haves:
  truths:
    - "`grelha` e `improve-architecture` estão em CORE_SKILLS (build-plugins.sh) E na tabela Skills core do plugin-membership.md — em sincronia"
    - "modules.json tem entradas para as 2 skills (kind:skill, plugin:ideiaos-core) e a rule ubiquitous-language (kind:rule)"
    - "README.md menciona /grelha + /improve-architecture nas 3 seções (instala/estrutura/como usar) e passa check-readme-sync.sh"
    - "check-plugin-membership.sh → 0 deriva; build-plugins.sh + build-adapters.sh exit 0; idea-doctor 0 FAIL"
    - "atribuição MIT presente no header # SOURCE: de todas as skills/resources/rule novos"
    - "Dogfood /doubt sobre o diff do v9 + auditoria .planning/v9-MILESTONE-AUDIT.md no estilo do v8 → PASSED"
  artifacts:
    - path: ".planning/v9-MILESTONE-AUDIT.md"
      provides: "Auditoria do milestone v9 (requisitos, gates binários, dogfood, veredito)"
      contains: "PASSED"
      min_lines: 30
  key_links:
    - from: "scripts/build-plugins.sh"
      to: "manifests/plugin-membership.md"
      via: "CORE_SKILLS deve bater com a tabela Skills core (drift-guard R7-07)"
      pattern: "grelha"
---

<objective>
Propagar o delta v9 às máquinas, documentar, registrar a postura, e auditar o milestone. Fecha **R9-06** (empacotamento/propagação) e **R9-07** (ADR de postura — o arquivo já existe; aqui é referenciar + espelhar + auditar).

Purpose: sem propagação, o `/grelha` fica só no `source/` e nunca chega às máquinas via marketplace/adapters. Sem auditoria, o milestone não fecha. Esta fase é a "saída" do v9 — espelha exatamente o que a Fase D do v8 fez (wiring + gates binários + dogfood).

Output: edições EXATAS nos 4 pontos de empacotamento + README + auditoria + referência ao ADR de postura. Não toca em GSD/AIOX (aditivo).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/milestones/v9-REQUIREMENTS.md
@.planning/v8-MILESTONE-AUDIT.md   # molde da auditoria
@scripts/build-plugins.sh
@manifests/plugin-membership.md
@manifests/modules.json
@scripts/check-plugin-membership.sh
@scripts/build-adapters.sh
@docs/decisions/v9-mattpocock-skills-absorcao.md   # ADR de postura (R9-07) — JÁ EXISTE
</context>

<tasks>

<task type="auto">
  <name>Task 1: Empacotamento — CORE_SKILLS + plugin-membership + modules.json (em sincronia)</name>
  <files>scripts/build-plugins.sh, manifests/plugin-membership.md, manifests/modules.json</files>
  <action>
**Edição EXATA 1 — `scripts/build-plugins.sh`, array `CORE_SKILLS` (linhas ~28-57):**
Adicionar 2 entradas em ordem alfabética:
- `grelha` (entre `forge-agent` e `idea`)
- `improve-architecture` (entre `idea` e `ideiaos-catalog`) — apenas se a Fase E produziu a skill; se E virou v9.1, adicionar só `grelha` agora e `improve-architecture` quando E fechar.

**Edição EXATA 2 — `manifests/plugin-membership.md`, seção "### Skills core (28)":**
Bump para "(29)" ou "(30)"; adicionar as linhas de tabela correspondentes (`| grelha | source/skills/grelha/ |`, `| improve-architecture | source/skills/improve-architecture/ |`). O drift-guard `check-plugin-membership.sh` exige que CORE_SKILLS e esta tabela batam.

**Edição EXATA 3 — `manifests/modules.json`:**
Adicionar entradas (espelhando o padrão das skills existentes, ex. `spec`):
- `{ "id": "skill-grelha", "kind": "skill", "source": "source/skills/grelha/", "targets": ["claude","cursor"], "plugin": "ideiaos-core", ... }`
- idem `skill-improve-architecture` (se E fechou)
- `{ "id": "rule-ubiquitous-language", "kind": "rule", "source": "source/rules/common/ubiquitous-language.md", "plugin": "ideiaos-core" }` (tag de catálogo — rules não são empacotadas, mas registradas; ver nota do plugin-membership.md "Fora dos plugins")
Validar `node -e "JSON.parse(require('fs').readFileSync('manifests/modules.json'))"`.
  </action>
  <verify>
    <automated>grep -q 'grelha' scripts/build-plugins.sh && grep -q 'grelha' manifests/plugin-membership.md && node -e "JSON.parse(require('fs').readFileSync('manifests/modules.json','utf8'))" && grep -q 'grelha' manifests/modules.json && echo OK</automated>
  </verify>
  <done>grelha (+improve-architecture se E pronto) em CORE_SKILLS, plugin-membership (count bumped) e modules.json; rule ubiquitous-language registrada; JSON válido.</done>
</task>

<task type="auto">
  <name>Task 2: Rodar os geradores + gates binários</name>
  <files>scripts/build-plugins.sh, scripts/build-adapters.sh</files>
  <action>
Rodar (não editar — executar):
- `bash scripts/check-plugin-membership.sh` → esperado **0 deriva**.
- `bash scripts/build-plugins.sh` → empacota grelha (+improve-architecture) em `plugins/ideiaos-core/`; exit 0.
- `bash scripts/build-adapters.sh --target all` → deploya skills + a rule `ubiquitous-language.md` para `.claude/rules/ideiaos-common-ubiquitous-language.md` + `.cursor/rules/*.mdc` (paridade R8-09); exit 0.
- `bash scripts/idea-doctor.sh` → 0 FAIL (WARNs pré-existentes de secrets de outros projetos OK).
- Suíte de testes (`bats` se houver) → sem regressão.
Colar os exit codes/contagens no SUMMARY.
  </action>
  <verify>
    <automated>bash scripts/check-plugin-membership.sh; echo "membership_exit=$?"; bash scripts/build-plugins.sh >/dev/null 2>&1; echo "buildplugins_exit=$?"</automated>
  </verify>
  <done>check-plugin-membership 0 deriva; build-plugins + build-adapters exit 0; rule deploya nos 2 harnesses; idea-doctor 0 FAIL; testes sem regressão.</done>
</task>

<task type="auto">
  <name>Task 3: README.md (3 seções) + atribuição MIT</name>
  <files>README.md</files>
  <action>
Atualizar `README.md` nas 3 seções que o gate `check-readme-sync.sh` cobre:
- **"O que este setup instala"** (tabela de skills core): +linha `/grelha` (grilling pré-plano + glossário linguagem ubíqua) e +`/improve-architecture` (ritual de deepening) se E pronto.
- **"Estrutura do repositório"** (árvore): refletir `source/skills/grelha/` (+ `improve-architecture/`) e `source/rules/common/ubiquitous-language.md`.
- **"Como usar no dia a dia"**: 1-2 linhas — quando usar `/grelha` (antes de planejar feature ambígua/arriscada; montar glossário) e a Deia oferecendo no Passo 1.5.
Confirmar atribuição MIT: header `# SOURCE: mattpocock/skills MIT` presente em SKILL.md/resources/rule novos (grep). Rodar `bash scripts/check-readme-sync.sh` → N/N, 0 faltando.
  </action>
  <verify>
    <automated>grep -q 'grelha' README.md && bash scripts/check-readme-sync.sh && for f in source/skills/grelha/SKILL.md source/rules/common/ubiquitous-language.md; do grep -q 'SOURCE: mattpocock/skills MIT' "$f" || { echo "sem atribuicao: $f"; exit 1; }; done && echo OK</automated>
  </verify>
  <done>README atualizado nas 3 seções; check-readme-sync N/N; atribuição MIT presente nos arquivos novos.</done>
</task>

<task type="auto">
  <name>Task 4: Postura (R9-07) — referenciar o ADR existente + espelhar Obsidian</name>
  <files>docs/decisions/v9-mattpocock-skills-absorcao.md</files>
  <action>
O ADR de postura **já existe** (`docs/decisions/v9-mattpocock-skills-absorcao.md`, Status: Aceito). Nesta fase:
- Confirmar que os headers `# SOURCE: mattpocock/skills MIT` das skills novas referenciam a decisão (1 linha apontando o ADR), e que o relatório de pesquisa o referencia.
- Espelhar o ADR ao Obsidian via o fluxo existente do `/extract-learnings` (Passo 4c — `docs/decisions/` → vault `Decisions/`). NÃO criar pipeline novo.
- Nenhuma reescrita do ADR (só referência cruzada).
  </action>
  <verify>
    <automated>test -s docs/decisions/v9-mattpocock-skills-absorcao.md && grep -qi 'anti-framework\|postura\|técnica' docs/decisions/v9-mattpocock-skills-absorcao.md && echo OK</automated>
  </verify>
  <done>ADR de postura referenciado pelas skills novas e espelhado ao Obsidian via extract-learnings; sem reescrita.</done>
</task>

<task type="auto">
  <name>Task 5: Dogfood /doubt + auditoria de milestone</name>
  <files>.planning/v9-MILESTONE-AUDIT.md</files>
  <action>
1. **Dogfood:** rodar `/doubt` (revisor adversarial de contexto fresco, subagente `general-purpose`, prompt issues-only) sobre o diff do v9 — especialmente sobre a skill `/grelha` e o Passo 1.5 da Deia. Reconciliar achados (acionável/trade-off/ruído). Espelha o que o v8 fez (achou citação fabricada na própria `/doubt`).
2. **Auditoria:** criar `.planning/v9-MILESTONE-AUDIT.md` no molde de `.planning/v8-MILESTONE-AUDIT.md`:
   - Tabela de requisitos R9-01..R9-07 com status.
   - Tabela de gates binários (scan-absorbed, JSON.parse modules.json, check-plugin-membership, check-readme-sync, build-plugins, build-adapters, idea-doctor, testes) com resultado.
   - Seção de dogfood (achados + reconciliação + STOP).
   - Veredito + atribuição (quarentena `security/quarantine/mattpocock-skills/`, MIT).
  </action>
  <verify>
    <automated>test -s .planning/v9-MILESTONE-AUDIT.md && grep -q 'R9-01' .planning/v9-MILESTONE-AUDIT.md && grep -qi 'PASSED\|SHIPPED' .planning/v9-MILESTONE-AUDIT.md && echo OK</automated>
  </verify>
  <done>Dogfood /doubt feito e reconciliado; auditoria v9 criada com requisitos + gates + dogfood + veredito.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
Propagação completa (CORE_SKILLS + membership + modules.json + README), rule deployada nos 2 harnesses, postura referenciada/espelhada, dogfood /doubt, auditoria v9.
  </what-built>
  <how-to-verify>
1. Conferir gates verdes: `check-plugin-membership.sh` (0 deriva), `check-readme-sync.sh` (N/N), `build-plugins.sh`/`build-adapters.sh` (exit 0), `idea-doctor.sh` (0 FAIL).
2. Conferir que `plugins/ideiaos-core/` agora contém `skills/grelha/` (e improve-architecture se E fechou).
3. Ler `.planning/v9-MILESTONE-AUDIT.md` — requisitos cobertos, dogfood reconciliado, veredito PASSED.
4. Decidir tag: `v9.0` (núcleo B/C/D + F) e, se E ficou para depois, `v9.1` quando deepening fechar.
  </how-to-verify>
  <resume-signal>Digite "aprovado: ship v9.0" ou ajustes antes do ship.</resume-signal>
</task>

</tasks>

<verification>
R9-06: CORE_SKILLS + plugin-membership + modules.json em sincronia (Task 1); geradores + gates verdes (Task 2); README 3 seções + atribuição MIT (Task 3).
R9-07: ADR de postura referenciado + espelhado (Task 4) — o arquivo já existia.
Auditoria: dogfood /doubt + v9-MILESTONE-AUDIT (Task 5).
</verification>

<success_criteria>
- `grelha` (+`improve-architecture` se E fechou) empacotados; CORE_SKILLS == tabela Skills core (0 deriva).
- modules.json válido com as 2 skills + rule ubiquitous-language; build-plugins/adapters exit 0; rule nos 2 harnesses.
- README sincronizado (3 seções); check-readme-sync N/N; atribuição MIT nos headers.
- ADR de postura referenciado/espelhado (sem reescrita).
- Dogfood /doubt reconciliado; `.planning/v9-MILESTONE-AUDIT.md` PASSED; pronto para tag v9.0.
</success_criteria>

<notes>
## Espelha a Fase D do v8
Esta fase é o análogo direto da "Wave D — Wiring, gates & dogfood" do v8 (mesmos 4 pontos de empacotamento, mesmos gates binários, mesmo dogfood doubt-driven). Diferença: a rule nova (`ubiquitous-language`) também deploya via `build_claude_project_rules()` (R8-09).

## Drift-guard é o gate que importa
`check-plugin-membership.sh` (R7-07) cruza CORE_SKILLS × tabela do plugin-membership.md. Se editar um e esquecer o outro, o gate pega. Editar os dois em sincronia (Task 1).

## Se E virou v9.1
Empacotar só `grelha` agora; `improve-architecture` entra quando a Fase E fechar (re-rodar Task 1-3 para ela). A auditoria v9.0 cobre R9-01..04, R9-06, R9-07; R9-05 fica marcado como v9.1.

## Could-haves (deltas finos) — ver master plan §G
Os deltas finos `to-prd` (no @pm) e o achado do `diagnose` (no /gsd-debug) NÃO entram aqui por padrão — são uma Fase G opcional "could-haves" descrita no `v9-IMPLEMENTATION-PLAN.md`. Mantê-los fora do caminho de ship do v9.0.
</notes>

<output>
Criar `.planning/milestones/v9-phases/F-propagacao-postura-auditoria/F-01-SUMMARY.md` ao concluir.
</output>