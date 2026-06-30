---
name: project-deia-kernel-vision
description: "Visão arquitetural decisiva — a DEIA/IdeiaOS é o HARNESS CENTRAL (kernel-orquestrador); AIOX e GSD viram executores plugáveis por trás dela, não o centro"
metadata: 
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

**Decidido pelo Gustavo (2026-06-30):** o harness central do ecossistema é a **DEIA / IdeiaOS em si** — não AIOX nem GSD.

**Why:** hoje o IdeiaOS é uma *camada de composição* que cola dois upstreams externos (AIOX = npm `.aiox-core/`; GSD = plugin do Claude Code) via 1 roteador (`/idea`) + 3 contratos (`gsd-plan-phase --story`, `qa-gate --verification`, hook Fase A). Atrito real: 2 vocabulários (story×phase), 2 state-stores (`docs/stories/`×`.planning/`), 2 conjuntos de comando (`@persona`×`/gsd-*`). A visão é o IdeiaOS deixar de COLAR e passar a POSSUIR o ciclo de vida (intake→plan→execute→verify→learn), com a Deia como kernel-orquestrador e AIOX/GSD como **executores plugáveis** por trás de uma interface. (= "Abordagem C / kernel-nativo" do judge-panel — confirmada como DESTINO, não opção concorrente.)

**How to apply:** ao planejar evolução do IdeiaOS, o roadmap GSD↔AIOX deve convergir para a Deia-kernel (provável caminho faseado: começar leve por camada de tradução/fachada → evoluir para estado unificado → kernel nativo). Nenhuma proposta deve recolocar AIOX/GSD no centro. Cuidado: são upstreams que o IdeiaOS não controla — preservar a capacidade de receber updates deles.

**Dois eixos de melhoria FUTURA** (tratar em novos projetos de melhoria; por ora apenas incorporados como gaps na análise `docs/ideiaos/AI-OS-GAP-ANALYSIS.md`):
1. **Lifecycle de documentação de planejamento** — padrão único da concepção *greenfield* (app do zero) até assumir um *legado/brownfield* para continuar a evolução. Hoje as peças existem dispersas (`/gsd-new-project`, `/grelha`, `/spec`, `/gsd-map-codebase`, `/gsd-ingest-docs`, brownfield discovery do AIOX) mas sem um lifecycle unificado.
2. **Documentação viva e permanente por projeto** — padronizar uma "living doc" de atualização contínua para CADA projeto assumido dentro do IdeiaOS (hoje disperso em `STATE.md`, `CONTINUATION_HANDOFF.md`, `docs/learnings/`, `CONTEXT.md`).

Cross-link [[project-milestone-v15-team-platform]] e a doc de anatomia (README §Anatomia, GUIDE-AI §Anatomia de instalação).
