---
name: absorption-gated-on-adopter-precondition
description: "Ao avaliar absorção de repo externo, a verificação adversarial DEVE checar a PRÉ-CONDIÇÃO no adotante — recomendar padrão (RAG/rerank/cache) a um produto que ainda NÃO tem a infra-base (ex: pipeline de retrieval/pgvector) é prematuro: vira REFERENCE, não ADAPT"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**O quê:** Na avaliação do `huggingface/cookbook` (2026-06-21), a fase adversarial **rebaixou** vários recs de RAG (semantic-cache, retrieve-then-rerank, knowledge-graph, synthetic-eval) de `ADAPT-PATTERN-IN-PRODUCT` para `REFERENCE`/`SKIP` — não por falta de mérito da técnica, mas porque **a pré-condição não existe no adotante**: um `grep` mostrou **zero pgvector e zero chamadas de embedding** nos produtos. Recomendar "ponha um semantic cache no pgvector" a um produto que não tem pgvector é inventar um projeto de infra, não transferir um padrão.

**Why:** A 1ª passada (geração) tende a julgar a técnica em si ("isso ajudaria cfoai?"); a técnica quase sempre "ajudaria". O sinal real é **a distância entre o estado atual do adotante e o pré-requisito da técnica**. Sem esse check, o parecer infla de "wins" que são, na verdade, projetos-âncora não-pedidos (viola scope-discipline e o próprio token-economy).

**How to apply:**
- Em todo parecer de absorção, antes de marcar `ADAPT`, faça o **precondition-check no código do adotante** (grep pela infra-base que a técnica exige). Sem a base → `REFERENCE` (documenta, não constrói) ou `SKIP`.
- Separe "a técnica é boa" (quase sempre sim) de "é acionável AGORA no estado atual" (só se a pré-condição existe).
- Cruza com [[prevention-in-os-vs-remediation-in-product]] (ONDE construir) — esta é sobre **SE/QUANDO** (maturidade do adotante). E com [[headroom-eval-2026-06]] / [[hf-cookbook-eval-2026-06]] (pattern-transfer ≠ adoção de código).
