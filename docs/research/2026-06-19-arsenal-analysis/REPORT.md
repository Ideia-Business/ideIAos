# Análise de Arsenal — "Que ferramentas absorver no IdeiaOS"

> **Data:** 2026-06-19
> **Método:** workflow multi-agente (15 agentes, ultracode) — mapeamento do arsenal atual → recon profundo de 5 fontes externas → confronto delta-only → síntese → verificação adversarial.
> **Fontes confrontadas:** `DietrichGebert/ponytail`, `github/spec-kit`, `VoltAgent/awesome-agent-skills`, `mattpocock/skills`, vídeo YouTube `0yS7sSgdJCA`.
> **Princípio:** o IdeiaOS absorve só o **delta** — nunca duplica o que já tem; prefere CLI+skills a MCP; mantém codebase enxuta. Todo conteúdo externo tratado como **dado** (anti-injection).

---

# PARTE I — Relatório de Decisão

## 1. TL;DR

| Fonte | Veredito | Prioridade | Delta principal |
|---|---|---|---|
| **github/spec-kit** | PARTIAL_ABSORB | **MEDIUM** | `/spec --analyze` (lint cross-artefato spec×plan×tasks×código) + `/spec --converge` (gap-to-code brownfield, append-only). **GAP real.** |
| **ponytail** | PARTIAL_ABSORB | LOW | Escada de 6 degraus de simplicidade como algoritmo ordenado (degrau "feature nativa antes de dep" ausente) + marcador de dívida `// debt:` com coletor grep. |
| **voltagent/awesome-agent-skills** | PARTIAL_ABSORB | LOW | 3 garimpos-S: recursive-decomposition (disciplina de consumo de contexto), reflexion (só padrão — código GPL), rubric de promoção de instinct. |
| **youtube/superpowers brainstorming** | PARTIAL_ABSORB | LOW | "Prioridade de Instrução" explícita (CLAUDE.md usuário > skill > default). 1 delta limpo. |
| **mattpocock/skills** | **ALREADY_HAVE** | LOW | Nenhum delta acionável — absorvido no v9 (ADR congelado). Backlog fraco: `resolving-merge-conflicts`. |

Nenhuma fonte justifica absorção massiva. Há **um candidato real a milestone pequeno** (spec-kit → auditoria da camada de spec) e **4–5 deltas-S** que cabem em rules existentes. Confirmado por inspeção: `source/skills/spec/lib/` tem só `spec-merge.sh` + `spec-validate.sh` (syntax-lint intra-delta) — nada cross-artefato, validando o GAP do spec-kit.

## 2. Pontos-chave por fonte

**spec-kit vs /spec+GSD (o ponto central):** spec-kit é greenfield-first (reescreve a spec inteira); nosso `/spec` é delta-brownfield, superior para produto vivo. `specify`/`plan`/`tasks`/`implement`/`constitution`/`taskstoissues` são **redundantes** (cobertos por `/spec`, GSD ~80 skills, AIOX Constitution, `gsd-inbox`). Restam 3 deltas genuínos: `--analyze` (M, lint cross-artefato), `--converge` (M, gap-to-code append-only — o mais alinhado ao nosso diferencial brownfield), taxonomia de 9 eixos (S). Entram como **subcomandos de `/spec`**, não skills novas. Risco: os passes de analyze são LLM, não shell determinístico — o gate só valida que o relatório foi escrito.

**mattpocock (status):** ALREADY_HAVE confirmado ponto-a-ponto — grilling→`/grelha`, CONTEXT.md→`ubiquitous-language.md`, deepening→`/improve-architecture`, ADR inline, todos no v9 com header `# SOURCE`. Upstream evoluiu pós-v9 só com refinamento meta; pipeline issue-tracker já rejeitado por ADR. Único backlog fraco: `resolving-merge-conflicts`, só se a dor reaparecer.

**ponytail:** ferramenta de disciplina de simplicidade. Delta = a escada de 6 degraus como algoritmo ordenado (em especial o degrau "feature nativa antes de dependência", ausente hoje) + marcador `// debt:` com coletor grep.

**voltagent/awesome-agent-skills:** awesome-list — não se absorve a lista, garimpam-se itens. 3 garimpos-S: recursive-decomposition, reflexion (padrão; código é GPL → só conceito), rubric de promoção de instinct (5 eixos).

**vídeo (superpowers brainstorming):** 1 delta limpo — tornar explícita a "Prioridade de Instrução" (CLAUDE.md do usuário > skill > default).

## 3. Recomendações priorizadas

1. **[MEDIUM · SKILL]** spec-kit → `/spec --analyze` + `--converge` (subcomandos em `source/skills/spec/`). Único candidato a milestone.
2. **[LOW · RULE]** ponytail → escada de 6 degraus em `operating-discipline.md` item 4.
3. **[LOW · RULE]** voltagent → recursive-decomposition em `orchestration.md`. Melhor retorno/esforço dos garimpos.
4. **[LOW · RULE]** superpowers → "Prioridade de Instrução" em `operating-discipline.md`.
5. **[LOW · SKILL]** voltagent → rubric de 5 eixos em `/evolve`.
6. **[LOW · RULE]** ponytail → marcador `// debt:` + check WARN no `idea-doctor.sh`.
7. **[LOW]** spec-kit → taxonomia de 9 eixos como `CHECKLIST.md` em `/grelha`.
8. **[LOW · padrão]** voltagent → reflexion (triagem quick-vs-deep) — só o conceito.

**Pular:** mattpocock inteiro (congelado v9); GSD/OpenSpec/agent-skills/context-packet/ui-ux-pro-max (já absorvidos); qualquer plugin/MCP server (viola mcp-hygiene+token-economy); pipeline issue-tracker (ADR); modos ultra/coerção `<EXTREMELY-IMPORTANT>` (colidem com scope-discipline/push-back); LLM-eval de hamelsmu (repo 404).

## 4. Conformidade de licença

MIT (OK, com header `# SOURCE`): spec-kit, ponytail, recursive-decomposition, skill-miner rubric, superpowers. **⚠️ GPL-3.0:** reflexion (context-engineering-kit) — absorver SÓ o conceito; copiar qualquer código contamina. CC-BY-4.0: color-expert (não absorvemos).

## 5. Próximo passo

**Candidato a milestone v11 = "Auditoria da Camada de Spec Brownfield":**
- **R11-01** `/spec --analyze` (passo read-only no `lib/`, 6 passes, relatório gated por `test -s`).
- **R11-02** `/spec --converge` (gerador append-only reusando parser de `spec-merge.sh`, 4 classes de gap, IDs zero-padded).
- **R11-03 (opcional S)** taxonomia de 9 eixos como `CHECKLIST.md` em `/grelha`.
- Atualizar `delta-spec.md` posicionando analyze/converge na fronteira `/spec`×GSD; ADR `v11-spec-kit-analyze-converge.md` ("minerar prompts, não importar premissa greenfield").

Os deltas-S restantes não justificam milestone — são edições diretas em rules propagadas por `build-adapters.sh`, podendo ir num único PR de "hardening de disciplina". **Escopo final é decisão do usuário** (recomendado `/grelha` sobre o recorte v11 antes de implementar).

---

# PARTE II — Inventário do Arsenal & Proveniência (estado atual)

> Base factual usada no confronto. Fontes: `source/{skills,rules,agents,templates}/`, `.claude/rules/`, `.planning/ROADMAP.md` + milestones + audits, `docs/decisions/`, e os headers `# SOURCE:` das skills.

## 1. Inventário

- **46 skills** em `source/skills/` (disciplina/alinhamento: doubt, grelha, context-engineering, improve-architecture, spec; orquestração: idea, ideiaos-setup, ideiaos-catalog; aprendizado: instinct-analyze, instinct-status, learn, evolve, extract-learnings, recall-learnings, memory-sync; continuação: cursor-continuation, two-instance-kickoff; lovable: lovable-handoff, lovable-mcp; qualidade: tdd, e2e-testing, api-design, accessibility, benchmark-optimization-loop; frontend/design: frontend-visual-loop, web-quality, ui-styling, ui-ux-pro-max, motion, design, design-system, banner-design, slides, brand; marketing: marketing, marketing-research; codebase/pesquisa: codebase-onboarding, code-tour, deep-research, llms-txt, forge-agent; custo/infra opt-in: cost-tracking, mcp-to-cli, database-migrations, deprecation-migration, observability).
- **58 rules** em `source/` (8 common + 5 ecc + 2 lovable + 1 supabase + 23 marketing) + **19 ativas** em `.claude/rules/` (8 espelham common + 11 AIOX-específicas).
- **19 subagents** em `source/agents/` (revisores: security/typescript/react/rls-reviewer, silent-failure-hunter, pr-test-analyzer; código: build-error-resolver, code-simplifier, refactor-cleaner, performance-optimizer, code-explorer, planner, doc-updater; continuação/setup: claude-continuation, ideiaos-checker; squad marketing: 4) — **+12 personas AIOX externas** (@dev, @qa, @architect, @pm, @po, @sm, @analyst, @data-engineer, @ux-design-expert, @devops, @aiox-master, squad-creator).
- **6 categorias de templates** em `source/templates/` (hybrid, ideiaos, lovable, memory, learnings, skill).

## 2. Mapa de proveniência — milestones v2.0 → v10

| Milestone | Ship | Entregou | Fonte absorvida |
|---|---|---|---|
| **v2.0 — Canivete Suíço Universal** | 2026-06-12 | Absorção do ECC; 33→70 módulos; 8 fases/29 planos | **ECC** (Enterprise Claude Code) — base massiva |
| **v3 — Refinamento pós-auditoria** | 2026-06-12 | Fases 09-13; 15/15 gaps; loop de instincts ao vivo | Nenhuma (interna) |
| **v4 — Produção do plano maior** | 2026-06-12 | Anti-runaway (3 barreiras), evals LLM, marketplace 3.0.0 | Nenhuma (interna) |
| **v5 — Memória compartilhada entre IDEs** | 2026-06-14 | Memória cross-IDE via branch `planning`, Lovable-safe | Nenhuma (ADR `v5-memory-topology.md`) |
| **v6 — Resiliência + Marketing + GSD/OpenSpec** | 2026-06-16 | `gates.sh`, instinct-recover, `/forge-agent`, `/marketing`, context-packet handoffs, base do `/spec` | **Multi:** OpenSquad (gates.sh + 22 BPs MIT), AIOX (Agent Immortality), context-packet (MIT), conceito OpenSpec |
| **v7 — Delta-Spec Brownfield + Empacotamento** | 2026-06-16 | Piloto `/spec` no nfideia; 4 bugs do motor; drift-guard | **OpenSpec** (Fission-AI/OpenSpec, MIT) |
| **v8 — Camada de Disciplina** | 2026-06-16 | `/doubt` + `operating-discipline` + `/context-engineering` + opt-ins | **addyosmani/agent-skills (MIT)** — só o delta de disciplina |
| **v9 — Camada de Alinhamento** | 2026-06-17 | `/grelha` + `CONTEXT.md` + ADR inline + gate na Deia + `/improve-architecture` | **mattpocock/skills (MIT)** — técnica, não ideologia (ADR `v9-mattpocock-skills-absorcao.md`) |
| **v10 — Integração Lovable MCP** | PARCIAL 2026-06-18 | Fase A: `/lovable-mcp` read-only + harness-deny 19 tools. Fase B: 🔴 bloquear publish. C/D parqueadas | **Lovable MCP server** (ADR `v10-lovable-mcp-readfirst-containment.md`) |

**Nota (não-milestone):** o **GSD** é framework externo **vendorizado** (`@opengsd/get-shit-done-redux` v1.1.0, pin blindado no `versions.lock`; cuidado: redux 1.x ≠ gsd-pi 3.x; semver trap revertido 3×). A suíte `ui-ux-pro-max` também é vendorizada.

## 3. Capacidades que competem com as fontes externas (já temos)

- **(a) `/spec` (delta-spec) + GSD** — `# SOURCE: OpenSpec MIT | adapted v6`. Contratos vivos por capability (SHALL/DEVE + cenários; regra dos 4 hashtags no parser). Fronteira: `/spec` = O QUE; GSD = COMO/QUANDO. 27/27 testes bats. → **não re-absorver OpenSpec.**
- **(b) GSD completo** — vendorizado, ~80 skills `gsd-*`, motor goal-backward wave-based. → **não re-absorver outro framework de execução.**
- **(c) `/grelha` + `CONTEXT.md`** — `# SOURCE: mattpocock/skills MIT | adapted v9`. → **não re-absorver grilling/ubiquitous-language.**
- **(d) `/doubt` + operating-discipline** — `# SOURCE: agent-skills MIT | adapted v8`. → **não re-absorver disciplina de Osmani.**
- **(e) `/improve-architecture`** — `# SOURCE: mattpocock/skills MIT | adapted v9` (deepening de Ousterhout). → **não re-absorver deepening.**
- **(f) context-engineering** — `# SOURCE: agent-skills MIT | adapted v8`. Operacionaliza as rules token-economy/orchestration/context-packet-handoffs. → **não re-absorver.**

## 4. Conclusão — o que NÃO re-absorver

Já cobertos, atribuídos e versionados (header `# SOURCE:` em cada skill, postura congelada em ADR): **OpenSpec** → `/spec`; **addyosmani/agent-skills** → `/doubt`+`operating-discipline`+`/context-engineering`; **mattpocock/skills** → `/grelha`+`CONTEXT.md`+`/improve-architecture`; **OpenSquad** → `gates.sh`+22 BPs; **context-packet** → handoff-packet; **AIOX** → instinct-recover; **GSD redux** e **ui-ux-pro-max** → vendorizados (pin blindado). Qualquer nova proposta de absorção dessas fontes é redundante.

---

*Relatório gerado pelo workflow `arsenal-analysis-2026-06` (run `wf_1020d034-72f`). A camada de validação (2 juízes + revisão NASA) está em `VALIDATION.md` / `SYSTEMS-REVIEW.md` neste mesmo diretório.*
