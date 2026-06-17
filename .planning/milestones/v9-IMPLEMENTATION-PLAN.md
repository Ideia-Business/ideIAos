# Plano de Implantação — v9: Camada de Alinhamento (Alignment Layer)

**Milestone:** v9 · **Status:** 📋 PLANEJADO (esqueleto detalhado — não executado)
**Documento-mestre.** Amarra os 6 PLAN.md de fase em `.planning/milestones/v9-phases/`.

## Insumos (não reescrever — referenciar)

| Artefato | Caminho |
|----------|---------|
| Relatório de análise | `docs/research/2026-06-16-mattpocock-skills-analise.md` |
| Requisitos R9-01..07 | `.planning/milestones/v9-REQUIREMENTS.md` |
| Roadmap (fases A–F) | `.planning/milestones/v9-ROADMAP.md` |
| ADR de postura (R9-07) | `docs/decisions/v9-mattpocock-skills-absorcao.md` (já existe, Aceito) |
| Quarentena (MIT, scan exit 0) | `security/quarantine/mattpocock-skills/` |

## PLANs de fase (criados por este plano)

| Fase | PLAN | Cobre | Tipo |
|------|------|-------|------|
| A — Quarentena & absorção | `v9-phases/A-quarentena-absorcao/A-01-PLAN.md` | (habilita 01/02/03/05) | auto |
| B — `/grelha` + glossário `CONTEXT.md` | `v9-phases/B-grelha-glossario/B-01-PLAN.md` | R9-01, R9-02 | **caminho crítico** |
| C — ADR inline | `v9-phases/C-adr-inline/C-01-PLAN.md` | R9-03 | fino |
| D — Gate de alinhamento na Deia | `v9-phases/D-gate-deia/D-01-PLAN.md` | R9-04 | cirúrgico |
| E — Ritual de deepening | `v9-phases/E-deepening/E-01-PLAN.md` | R9-05 | SHOULD (pode ser v9.1) |
| F — Propagação + postura + auditoria | `v9-phases/F-propagacao-postura-auditoria/F-01-PLAN.md` | R9-06, R9-07 | saída/ship |

---

## Grafo de dependências

```
A (quarentena, pré-feita)
│
▼
B (/grelha + CONTEXT.md)  ◄── CAMINHO CRÍTICO (maior valor: GAP 1 + GAP 2)
│
├──────────────┬───────────────┐
▼              ▼               ▼
C (ADR inline) D (gate Deia)   │
│              │               │
│              │               ▼
└──────────────┴────────►  E (deepening)   ← depende de B (glossário) + C (ADR)
                               │
        ┌──────────────────────┘
        ▼
F (propagação + postura + auditoria)  ← depende de B,C,D,E (serial, por último)
```

- **A → B:** B precisa dos resources `CONTEXT-FORMAT`/`ADR-FORMAT` capturados em A.
- **B → C, B → D:** C oferece ADR a partir do `/grelha`; D dispara o `/grelha`.
- **B+C → E:** o grilling loop do deepening reusa glossário (B) e ADR inline (C).
- **D ∥ E:** paralelizáveis após B/C (tocam arquivos diferentes: D = `idea/SKILL.md`; E = `improve-architecture/`).
- **F por último:** empacota o que B–E produziram; é a "saída".

## Sequência recomendada

`A (revalidar) → B → C → D → E → F`
Com paralelização possível: depois de B e C fecharem, **D e E em paralelo**; F serial no fim.

## Esforço relativo (T-shirt sizing)

| Fase | Esforço | Por quê |
|------|---------|---------|
| A | **XS** | já pré-feita; só capturar 4 resources + revalidar scan + congelar vereditos |
| B | **L** | caminho crítico: skill completa + resource + template + rule + checkpoint humano |
| C | **S** | 1 resource + wiring; reusa `docs/decisions/` e o espelhamento Obsidian existentes |
| D | **S** | edições cirúrgicas em `idea/SKILL.md` + teste de não-regressão de roteamento |
| E | **M** | skill nova + 2 resources + ADR de decisão; SHOULD (fatiável p/ v9.1) |
| F | **M** | 4 pontos de empacotamento em sincronia + gates + dogfood + auditoria |

**Núcleo MUST (B+C+D+F-parcial):** ~L+S+S+M. **Completo (com E):** +M.

## Gates de qualidade entre fases

| Transição | Gate |
|-----------|------|
| A → B | scan-absorbed exit 0; **reset de sessão** (higiene de memória) |
| B → C/D | checkpoint humano de B aprovado; smoke do `/grelha` num sandbox `/tmp` (gera CONTEXT.md glossário-only) |
| C → E | smoke do ADR (gate dos 3 critérios pula trivial / oferece em irreversível) |
| D → F | **não-regressão de roteamento** da Deia (evals/ ou casos canônicos) |
| E → F | smoke do relatório HTML em tmp (não suja o repo) |
| F → ship | `check-plugin-membership` 0 deriva · `check-readme-sync` N/N · build-plugins/adapters exit 0 · idea-doctor 0 FAIL · dogfood `/doubt` reconciliado · auditoria PASSED |

## Definition of Done — milestone v9

- [ ] R9-01 — `/grelha` (alias `/grill`) invocável e roteável; grilling 1-a-1, modos `--docs`/`--rapido`; código e não-código. **[GAP 2]**
- [ ] R9-02 — `CONTEXT.md` glossário-only durável + rule `ubiquitous-language` (distinção dos 3 CONTEXT); deploya Claude+Cursor. **[GAP 1]**
- [ ] R9-03 — ADR ultraleve inline (gate dos 3 critérios) em `docs/decisions/`; espelhado ao Obsidian via `/extract-learnings`.
- [ ] R9-04 — Passo 1.5 opcional/escapável na Deia; pedido mecânico não dispara; roteamento transparente; sem regressão. **[GAP 2]**
- [ ] R9-05 — Ritual de deepening (`/improve-architecture`) com glossário de arquitetura + deletion test + relatório HTML + grilling loop. **[GAP 3]** *(pode ser v9.1)*
- [ ] R9-06 — Empacotado (CORE_SKILLS + membership + modules.json em sincronia); README 3 seções; gates binários verdes; atribuição MIT.
- [ ] R9-07 — ADR de postura referenciado/espelhado (já existe).
- [ ] Dogfood `/doubt` sobre o diff do v9 reconciliado.
- [ ] `.planning/v9-MILESTONE-AUDIT.md` PASSED; tag `v9.0` (e `v9.1` se E for fatiado).
- [ ] `ROADMAP.md` (raiz) e `STATE.md` atualizados; sincronizar `.planning/*` no branch `planning`.

---

## Could-haves — Fase G opcional (deltas finos)

Fora do caminho de ship do v9.0; abrir só se houver apetite (relatório §8 COULD):

| Item | Onde | Esforço |
|------|------|---------|
| `to-prd` delta — "sintetiza, não entrevista" + quiz de seams/módulos | enriquecer doc do `@pm`/Morgan (1 parágrafo) | XS |
| achado do `diagnose` — "sem seam de teste correto, isso É o achado → handoff p/ arquitetura" | nota em `/gsd-debug` ou agente | XS |

`caveman` permanece **WON'T** (conflita com clareza + PT-BR). `to-issues`/`triage` permanecem **WON'T** (acoplam a issue tracker externo).

---

## Como executar via nosso próprio tooling

**Opção 1 — GSD nativo (recomendado):**
1. Abrir o milestone: `/gsd-new-milestone "IdeiaOS v9 — Camada de Alinhamento"` (ou já tratar os artefatos `.planning/milestones/v9-*` como o milestone aberto).
2. Por fase, na ordem do grafo: `/gsd-plan-phase <fase>` (refina o PLAN deste esqueleto) → `/gsd-execute-phase <fase>` → SUMMARY.
3. Fechar: `/gsd-complete-milestone` / `/gsd-audit-milestone` → tag.

**Opção 2 — Execução manual orientada pelos PLAN.md:** seguir cada `v9-phases/<fase>/<fase>-01-PLAN.md` task a task, respeitando os checkpoints `human-verify` (B, C, D, E, F têm gates bloqueantes).

**Pré-requisitos antes de começar:**
- Estar no branch `planning` para versionar `.planning/` (gitignored em `work`/`main`); sincronizar ao fim de cada fase.
- Fase A já está pré-feita — basta revalidar (capturar 4 resources + scan + vereditos) e **resetar a sessão** antes de B (higiene pós-quarentena).

## Primeiro comando concreto

```
/gsd-new-milestone "IdeiaOS v9 — Camada de Alinhamento"
```

Depois, como a Fase A já está pré-feita, o primeiro trabalho real é a **Fase B**:

```
/gsd-plan-phase B-grelha-glossario   # refina B-01-PLAN.md e executa o caminho crítico
```

(Antes de B: revalidar a Fase A — `A-01-PLAN.md` Tasks 1-3 — e iniciar sessão nova.)
