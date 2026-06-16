---
phase: 30-openspec-delta-spec
plan: 01
subsystem: spec
tags: [delta-spec, brownfield, openspec, shell, skill, r6-13]
dependency_graph:
  requires: []
  provides: [skill-spec, rule-delta-spec, spec-merge-engine]
  affects: [source/skills/idea/SKILL.md, manifests/modules.json]
tech_stack:
  added: [bash-shell-motor-spec-merge]
  patterns: [delta-spec-brownfield, source-of-truth-viva, archive-datado]
key_files:
  created:
    - source/skills/spec/SKILL.md
    - source/skills/spec/templates/proposal.md
    - source/skills/spec/templates/spec.md
    - source/skills/spec/templates/delta.md
    - source/skills/spec/templates/tasks.md
    - source/skills/spec/lib/spec-validate.sh
    - source/skills/spec/lib/spec-merge.sh
    - source/rules/common/delta-spec.md
    - tests/spec-merge.bats
  modified:
    - source/skills/idea/SKILL.md
    - manifests/modules.json
decisions:
  - "Motor delta-spec implementado em bash puro (nao TypeScript/npm) para nao depender do CLI @fission-ai/openspec"
  - "Tokens canonicos internos em ingles (ADDED/MODIFIED/REMOVED/RENAMED); superficie PT-BR (ADICIONADO/MODIFICADO/REMOVIDO/RENOMEADO)"
  - "Regra dos 4 hashtags em cenarios (####) herdada do schema OpenSpec e enforced pelo spec-validate.sh"
  - "Piloto em produto real (30-02) adiado como spike/follow-up — skill completa e testada no IdeiaOS; piloto aguarda demanda real de delta num produto brownfield"
  - "Zero html comments (<!-- >): templates IdeiaOS usam <...> ou prosa, nunca <!-- -->"
metrics:
  duration_minutes: 75
  completed_date: "2026-06-16"
  tasks_completed: 4
  tasks_total: 4
  files_created: 9
  files_modified: 2
---

# Fase 30 Plano 01: Delta-Spec Brownfield — Capability /spec

Uma linha: skill `/spec` orquestrada em PT-BR com motor shell determinístico (spec-merge.sh + spec-validate.sh) que absorve o conceito OpenSpec (MIT) de source-of-truth viva + delta (ADDED/MODIFIED/REMOVED/RENAMED) + archive datado — sem fork nem dependência do CLI `openspec`.

---

## O que foi construído

### Skill `/spec` (Task 1)

`source/skills/spec/SKILL.md` — orquestrador frontmatter-first com:
- `name: spec`; ativa em "spec viva", "delta de spec", "contrato de comportamento", "especificar capability", /spec direto
- Fluxo de 5 ações fluidas: propose → spec/delta → design (opcional) → tasks → merge+archive
- Seção "O que é vs o que NÃO é" com fronteira clara vs GSD; R6-13 citado
- Vocabulário canônico PT-BR → tokens internos (ADICIONADO→ADDED etc.)
- Proveniência: `# SOURCE: OpenSpec MIT Fission-AI/OpenSpec | adapted: IdeiaOS v6`

4 templates PT-BR criados (sem nenhum `<!--`):
- `templates/proposal.md` — Por quê / O que muda / Capabilities afetadas / Impacto
- `templates/spec.md` — `# Spec:` + `## Requisitos` + `### Requisito:` + `#### Cenário:` (QUANDO/ENTÃO)
- `templates/delta.md` — ADICIONADO/MODIFICADO/REMOVED/RENOMEADO com regras explícitas
- `templates/tasks.md` — checklist `- [ ] N.M` consumível pelo GSD

### Motor shell determinístico (Task 2)

`source/skills/spec/lib/spec-validate.sh` — gate binário (exit 0/1/2):
- Validação (a): cenários com `###` (3 hashtags) → exit 1
- Validação (b): cada `### Requisito:` em ADDED/MODIFIED precisa de `>= 1 #### Cenário:`
- Validação (c): headers de requisito duplicados no mesmo arquivo → exit 1
- Validação (d): bloco MODIFICADO deve ter pelo menos 1 cenário (requisito completo)
- Validação (e): REMOVIDO precisa de `**Motivo**` e `**Migração**`

`source/skills/spec/lib/spec-merge.sh` — motor de merge (get-and-apply):
- Gate: chama spec-validate.sh antes de qualquer escrita; aborta se exit ≠ 0
- ADDED: anexa requisito; conflito (header já existe) → exit 1 sem escrita parcial
- MODIFIED: substitui bloco completo; alvo ausente → exit 1
- REMOVED: remove bloco; alvo ausente → exit 1
- RENAMED: renomeia header DE→PARA; verifica conflito de nome
- Archive: `mv specs/_changes/<slug>/ specs/_archive/AAAA-MM-DD-<slug>/`; falha se destino já existe
- `--dry-run`: mostra o que faria sem escrever; `--yes`: pula confirmação interativa

`tests/spec-merge.bats` — suite bash-puro (10 testes, 21 asserts):
- VERDE 21/21 em bash sem bats instalado
- Cobre: ADDED, MODIFIED, REMOVED, archive datado, validate-falha (3-hashtags), REMOVIDO sem Motivo, requisito sem cenário, idempotência em conflito, dry-run, exit codes 0/1/2

### Rule de fronteira + roteamento (Task 3)

`source/rules/common/delta-spec.md` — fronteira `/spec` × GSD:
- Tabela comparativa 6 eixos (pergunta central, horizonte, unidade, operação, output, quando usar)
- Fluxo "usar OS DOIS": /spec gera tasks.md → GSD planeja/executa → /spec merge+archive
- Estrutura de diretórios `specs/` documentada
- Regra dos 4 hashtags + SHALL/DEVE

`source/skills/idea/SKILL.md` — roteamento da Deia (INSERT-ONLY):
- Nova linha na matriz: "spec viva" / "contrato de comportamento" / "delta de spec" etc. → **Spec** → `/spec`
- Nota de fronteira adicionada em "Filosofia"
- Todas as rotas existentes preservadas (marketing, GSD, AIOX, etc.)

`manifests/modules.json` — 2 entries adicionadas (87 módulos total, JSON válido):
- `skill-spec` (always, ideiaos-core, deps: rule-delta-spec)
- `rule-delta-spec` (always, ideiaos-core)

### Checkpoint (Task 4 — auto-aprovado)

Verificação executada autonomamente (autorização total do usuário):
- SKILL.md: frontmatter, SOURCE, R6-13, fluxo, zero `<!--` — OK
- Suite: 21/21 VERDE
- Smoke dry-run: `+ 1 adicionados / ~ 0 modificados / - 0 removidos / -> 0 renomeados` — OK
- Decisão de escopo: piloto (30-02) classificado como spike/follow-up explícito

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Primeiro loop chamava `_apply_req` inexistente**
- **Found during:** Task 2, ao rodar o dry-run no checkpoint
- **Issue:** spec-merge.sh tinha um primeiro loop de "pré-processamento" que chamava `_apply_req` (função que nunca foi definida). Exibia warning `command not found` no stderr mas não afetava o resultado (segunda passagem era o código real)
- **Fix:** Removido o primeiro loop inteiro e as funções auxiliares órfãs (`map_section_token`, `extract_req_block`, `count_section_entries`)
- **Commit:** 6457784

**2. [Rule 1 - Bug] spec-validate rejeitava REMOVIDO por regra de cenário**
- **Found during:** Task 2, ao rodar Test 7
- **Issue:** A validação (b) "requisito sem cenário" disparava para requisitos em blocos REMOVIDO, que por definição NÃO têm cenários (só Motivo + Migração). Também a detecção de Motivo/Migração era muito restritiva (regex com encoding específico)
- **Fix:** Reescrita do spec-validate.sh com rastreamento explícito de `CURRENT_SECTION`; validação (b) só se aplica a ADDED/MODIFIED; detecção de Motivo/Migração usa `grep -qi 'Motivo'` e `grep -qi 'migra'`
- **Commit:** ba89313 (parte do commit de Task 2)

---

## Decisão de Escopo: Piloto (30-02) como Spike/Follow-up

O piloto real em produto brownfield (nfideia) está classificado como **spike/follow-up explícito**. Razão: a capability completa (skill + motor + testes + rule + roteamento) está entregue e testada. O piloto só adiciona valor quando houver demanda real de delta num produto — não tem sentido forçar um delta artificial apenas para fechar o critério de piloto. R6-13 fecha no nível "estrutura+fluxo+skill" conforme previsto na nota do plano.

Se o piloto for necessário: instalar a skill via `scripts/build-adapters.sh` no produto-alvo, criar `specs/<primeira-capability>/spec.md` a partir do comportamento existente, e rodar 1 delta ponta-a-ponta com spec-merge.sh.

---

## Threat Flags

Nenhum: os arquivos criados são markdown e scripts shell sem endpoints de rede, paths de autenticação, ou acesso a banco de dados.

---

## Known Stubs

Nenhum: a skill orquestra o usuário através de fluxo completo; o motor shell é funcional e testado; não há dados mockados ou placeholders funcionais.

---

## Self-Check: PASSED

- `source/skills/spec/SKILL.md` — existe, name:spec, SOURCE OK, R6-13 OK
- `source/skills/spec/lib/spec-validate.sh` — existe, bash -n OK
- `source/skills/spec/lib/spec-merge.sh` — existe, bash -n OK
- `source/rules/common/delta-spec.md` — existe, SOURCE OK, complement OK
- `tests/spec-merge.bats` — existe, 21/21 VERDE
- `manifests/modules.json` — JSON válido, 87 módulos, skill-spec + rule-delta-spec presentes
- Zero `<!--` em source/skills/spec/ e source/rules/common/delta-spec.md
- Commits: df4da31, ba89313, 3e7e33d, 6457784
