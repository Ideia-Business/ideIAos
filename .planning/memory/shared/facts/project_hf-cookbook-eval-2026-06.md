---
name: hf-cookbook-eval-2026-06
description: "huggingface/cookbook (Apache-2.0) avaliado 2026-06-21 — NÃO absorver como dep/milestone; é recurso de praticante-de-ML e somos consumidores de API em Deno. 3 wins de pattern-transfer no produto; RAG gated em ter retrieval primeiro. Guia: docs/guides/hf-cookbook-patterns.md"
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

Avaliação (Ultracode: 6 especialistas + verificação adversarial 8/8 dos pendentes) do **`huggingface/cookbook`** (137 notebooks, Apache-2.0, recipes de IA open-source). Guia de referência durável: `docs/guides/hf-cookbook-patterns.md` (no repo IdeiaOS).

**Veredito: NÃO absorver como dependência nem milestone.** É recurso de *praticante de ML* (Python+HF+GPU+treino/self-host); nós somos *consumidores de API em Deno-edge + hosted (OpenRouter/Lovable/DeepSeek)*. Logo **só a TÉCNICA transfere, nunca o código**, e só nas receitas sem treino. A verificação adversarial deixou a superfície ainda mais enxuta.

**✅ 3 wins imediatos (ADAPT-PATTERN-IN-PRODUCT, verificados):**
1. **Extração com âncora de origem** (campo + trecho verbatim + score) → **nfideia** (auditabilidade NF-e/fiscal) — maior ROI. Fonte: `structured_generation`.
2. **PII pre-send scrubber** (regex ordenado antes do egress) → **cfoai/nfideia** (compliance). Fonte: `llm_gateway_pii_detection`.
3. **Seleção de DDL p/ text-to-SQL** (rankear tabelas, prompt só do subconjunto; a *seleção* é portável, o reranker GPU não) → **cfoai**. Fonte: `rag_with_sql_reranker`.

**Transversal:** disciplina de judge (escala inteira ancorada, raciocínio-antes-da-nota, anti-viés de posição) → eval de produto; schemas de função constraint-rich (enums na docstring) → ai-router dos produtos.

**📎 Referência (não construir agora):** rubrica graduada p/ judges · semantic-cache **gated em pgvector** · retrieve-then-rerank (reranker hospedado Cohere/Voyage/Jina é Deno-native *quando houver retrieval*) · RAG synthetic-eval+critique (vira harness de regressão DENTRO de ideiapartner, não skill OS — eval é data-bound do produto) · padrão critique-filter p/ futuro `gsd-add-tests` · corpus `quotient-ai/judges` · convenção OTel.

**❌ SKIP (maioria):** todo fine-tuning/treino/GPU/visão · self-host (TGI/TEI/Ray/endpoints) · RAG plumbing acoplado a framework · orquestração multiagente (já temos AIOX+Workflow) · KG-RAG (Neo4j) · unstructured-partitioning (nfideia é XML, não office-docs) · data-analyst code-exec · cleanlab/active-learning.

**Meta-insight decisivo:** RAG é **prematuro** p/ nós — os produtos **não têm pipeline de retrieval/pgvector** (zero encontrado). Padrão de RAG só vira absorvível depois de existir retrieval. Ver [[absorption-gated-on-adopter-precondition]]. Pareia com [[headroom-eval-2026-06]] (mesma sessão; mesma tese técnica≠código) e [[project-deepseek-v4-enablement-pending]].
