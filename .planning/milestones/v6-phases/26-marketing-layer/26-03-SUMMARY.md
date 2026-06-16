---
phase: 26-marketing-layer
plan: "03"
subsystem: marketing-orchestrator
tags: [marketing, skill, orchestrator, pipeline, deia-routing, plugin, manifests]
dependency_graph:
  requires: [26-01, 26-02]
  provides: [skill-marketing, ideiaos-marketing-plugin, deia-marketing-routing]
  affects: [source/skills/idea/SKILL.md, IDEIAOS.md, marketplace, manifests]
tech_stack:
  added: []
  patterns: [OpenSquad pipeline adapted, format-injection at runtime, binary gates test -s, content approval checkpoint]
key_files:
  created:
    - source/skills/marketing/SKILL.md
    - source/skills/marketing/references/pipeline.md
  modified:
    - source/skills/idea/SKILL.md
    - source/templates/ideiaos/IDEIAOS.md.tmpl
    - .claude-plugin/marketplace.json
    - scripts/build-plugins.sh
    - manifests/modules.json
    - manifests/plugin-membership.md
decisions:
  - "Arquitetura hibrida squad+orquestrador (nao replica maquinaria squads.yaml/state.json do OpenSquad)"
  - "Publish marcado OPCIONAL/MANUAL — MCP-dependente, T-26-10 mitigation"
  - "Checkpoint de copy obrigatorio antes de qualquer passo visual (gate de conteudo irreversivel)"
  - "rules/marketing viajam com o plugin (22 BPs injetadas em runtime por formato — nao hardcoded)"
  - "mkt-estrategista usa opus; mkt-copywriter/designer/revisor usam sonnet (tradeoff custo/qualidade)"
metrics:
  duration: "~45 min"
  completed_date: "2026-06-16"
  tasks_completed: 3
  tasks_total: 3
  files_created: 2
  files_modified: 6
---

# Phase 26 Plan 03: Marketing Layer Integration Summary

Orquestrador `/marketing` criado com pipeline discovery→design→build→review→publish; Deia roteada para marketing via 2 novas linhas na matriz; IDEIAOS.md expandido para 6 camadas; sub-plugin `ideiaos-marketing` registrado no marketplace + build-plugins.sh com 7 novos módulos em manifests/modules.json.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Criar orquestrador /marketing | 57858d1 | source/skills/marketing/SKILL.md, references/pipeline.md |
| 2 | Conectar Deia + IDEIAOS.md 6 camadas | 3206ff7 | source/skills/idea/SKILL.md, source/templates/ideiaos/IDEIAOS.md.tmpl |
| 3 | Empacotar ideiaos-marketing | 8bdc344 | marketplace.json, build-plugins.sh, modules.json, plugin-membership.md |

---

## What Was Built

### Task 1: Orquestrador /marketing

**`source/skills/marketing/SKILL.md`** — skill orquestradora frontmatter-first com `name: marketing`, header `# SOURCE: OpenSquad MIT renatoasse/opensquad | adapted: IdeiaOS v6`, PT-BR.

Pipeline das 5 fases:
1. **Discovery** — classifica formato via índice source/rules/marketing/README.md; máx 3 perguntas; oferece marketing-research opcional
2. **Design** — carrega BP do formato em runtime; recruta `mkt-estrategista` (opus); checkpoint de ângulos obrigatório
3. **Build** — `mkt-copywriter` (sonnet) produz 3 variações hook→body→CTA; checkpoint de aprovação de copy (gate T-26-10); `mkt-designer` (sonnet) gera visual via Suíte de Design só após copy aprovada
4. **Review** — `mkt-revisor` (sonnet) scoring + APPROVE/REJECT; loop máx 2 ciclos com feedback
5. **Publish** — OPCIONAL/MANUAL; entrega arquivos em `docs/marketing/{data}-{slug}/`; instrui publicação manual ou via skill MCP futura

Gates binários `test -s` entre todas as fases (padrão OpenSquad/IdeiaOS).

**`source/skills/marketing/references/pipeline.md`** — detalhamento técnico das 5 fases, tabela de injeção formato→best-practice (22 formatos mapeados), ordem de recrutamento, checkpoints resumidos com fundamento T-26-10.

### Task 2: Deia routing + IDEIAOS.md

**`source/skills/idea/SKILL.md`** (INSERT-ONLY — 5 camadas existentes intactas):
- Tabela "O que é o IdeiaOS": "5 camadas" → "6 camadas", linha Marketing adicionada
- Matriz de roteamento: 2 novas linhas inseridas antes de "Pedido genérico sem rumo claro":
  - `criar post|carrossel|blog|newsletter|VSL|roteiro|campanha|thread|legenda|copy` → `/marketing`
  - `analisa perfil|inspira-se no estilo|investiga concorrente` → `/marketing-research`
- Exemplo 5 canônico: `/idea "cria um carrossel sobre X"` → roteamento transparente completo mostrando todas as fases do /marketing

**`source/templates/ideiaos/IDEIAOS.md.tmpl`** (template para novos projetos):
- "As 5 camadas" → "As 6 camadas"
- Seção `### 6. Marketing` com tabela de componentes, base de conhecimento, sinergia com Suíte de Design
- Fluxo "Produção de conteúdo" em Fluxos típicos
- Footer v1.2

**IDEIAOS.md** (raiz do projeto, gitignored por design — é arquivo de projeto alvo):
- Mesmas atualizações aplicadas

### Task 3: Sub-plugin ideiaos-marketing

**`.claude-plugin/marketplace.json`** — 4o plugin registrado:
```json
{ "name": "ideiaos-marketing", "source": "./plugins/ideiaos-marketing", ... }
```
Marketplace agora tem: ideiaos-core, ideiaos-design-suite, ideiaos-lovable, ideiaos-marketing.

**`scripts/build-plugins.sh`**:
- Arrays `MARKETING_SKILLS=(marketing marketing-research)` e `MARKETING_AGENTS=(mkt-estrategista mkt-copywriter mkt-designer mkt-revisor)`
- Função `build_marketing()`: cria dirs, copia skills (cp -R), agents (cp), rules/marketing inteiro (22 BPs viajam com o plugin), gera plugin.json via node
- Case `marketing|ideiaos-marketing) build_marketing ;; ` adicionado
- `all)` inclui `build_marketing`
- `--help` atualizado com opção `marketing`
- `bash -n` syntax check: PASS
- `bash --plugin marketing --dry-run`: exit 0

**`manifests/modules.json`** — 7 novos módulos com `"plugin": "ideiaos-marketing"`:
- `skill-marketing`, `skill-marketing-research`
- `agent-mkt-estrategista` (model: opus), `agent-mkt-copywriter/designer/revisor` (model: sonnet)
- `rule-marketing` (kind: rule, source: source/rules/marketing/, 22 BPs descritas)

**`manifests/plugin-membership.md`** — seção `## ideiaos-marketing` com tabelas de skills (2), agents (4 com model), rules (22 BPs com nota de origem MIT).

---

## Verification Results

| Criterio | Status | Req |
|----------|--------|-----|
| `test -f source/skills/marketing/SKILL.md` + pipeline 5 fases | PASS | R6-05 |
| `grep -qi carrossel source/skills/idea/SKILL.md` | PASS | R6-06 |
| `grep -q /marketing source/skills/idea/SKILL.md` | PASS | R6-06 |
| `grep -Eqi "6 camadas" IDEIAOS.md` | PASS | R6-06 |
| `grep -q ideiaos-marketing .claude-plugin/marketplace.json` | PASS | R6-05 |
| `bash scripts/build-plugins.sh --plugin marketing --dry-run` | exit 0 | R6-05 |
| `bash scripts/build-adapters.sh --target all --dry-run` | exit 0 | constraint |
| `bash scripts/check-readme-sync.sh .` | 102/102 OK, exit 0 | constraint |
| `bash -n scripts/build-plugins.sh` | SYNTAX_OK | constraint |
| modules.json: 7 novos modulos ideiaos-marketing | PASS | R6-05 |

**E2E (human-check):** `/idea "cria um carrossel sobre X"` — verificação manual pendente (requer sessão limpa). Fluxo esperado documentado em SKILL.md Exemplo 5 e verification_e2e do plano.

---

## Deviations from Plan

### Auto-fix Issues

None.

### Enhancements (Rule 2 — não listados no plano)

**1. Template IDEIAOS.md.tmpl atualizado além do escopo mínimo**
- **Found during:** Task 2
- **Issue:** O plano especificava atualizar `IDEIAOS.md` (raiz, gitignored) mas a fonte canônica para novos projetos é `source/templates/ideiaos/IDEIAOS.md.tmpl`. Sem atualizar o template, novos projetos instalados não teriam a 6ª camada.
- **Fix:** Template atualizado com as mesmas mudanças (6 camadas, seção Marketing, fluxo de produção, footer v1.2).
- **Files modified:** `source/templates/ideiaos/IDEIAOS.md.tmpl`
- **Commit:** 3206ff7

**2. Nota sobre IDEIAOS.md (raiz) gitignored**
- IDEIAOS.md na raiz é gitignored por design neste repo (é o provedor dos templates, não um projeto alvo). A modificação foi aplicada localmente e a fonte canônica (template) foi atualizada no commit.

---

## Known Stubs

Nenhum. O orquestrador `/marketing` não usa dados mockados — os checkpoints de conteúdo garantem que aprovação real é necessária antes de avançar.

Publish é intencionalmente marcado como manual/opcional (não é stub — é decisão de design documentada em T-26-10).

---

## Threat Flags

Nenhuma nova superfície de ameaça introduzida além das documentadas no plan threat_model:
- T-26-08: ideia/SKILL.md modificado INSERT-ONLY (verificado)
- T-26-09: build-plugins.sh com validate_exists() + dry-run obrigatório (verificado)
- T-26-10: checkpoint de copy pré-visual implementado (verificado no SKILL.md)

---

## Self-Check: PASSED

Arquivos criados verificados:
- FOUND: source/skills/marketing/SKILL.md
- FOUND: source/skills/marketing/references/pipeline.md

Commits verificados:
- FOUND: 57858d1 (Task 1)
- FOUND: 3206ff7 (Task 2)
- FOUND: 8bdc344 (Task 3)

check-readme-sync.sh: 102/102 OK
build-plugins.sh --plugin marketing --dry-run: exit 0
build-adapters.sh --target all --dry-run: exit 0
