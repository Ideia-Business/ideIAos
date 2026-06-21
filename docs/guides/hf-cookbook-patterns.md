# SOURCE: IdeiaOS v2 | parecer de absorção de huggingface/cookbook (Apache-2.0)

# Guia — Padrões aproveitáveis do HF Cookbook (e o que ignorar)

**Origem:** avaliação de `huggingface/cookbook` em 2026-06-21 (Ultracode: 6 especialistas + verificação adversarial). Memória: `hf-cookbook-eval-2026-06`.

## Tese (leia antes de tudo)

O HF Cookbook é um recurso de **praticante de ML** (Python + ecossistema HF + GPU + treino/self-host). Nossa stack é **consumidora de API**: IdeiaOS = Claude Code; produtos = React + Supabase **Edge Functions (Deno)** + LLM **hospedado** (OpenRouter / Lovable gateway / DeepSeek), **sem GPU, sem treino**. Logo **só a TÉCNICA transfere — quase nunca o código**, e só nas receitas sem treino.

**Regra de ouro (pré-condição):** antes de adotar um padrão de RAG/cache/rerank, confirme que o produto-alvo **já tem a infra-base** (ex.: pipeline de retrieval / `pgvector`). Hoje os produtos **não têm** retrieval/pgvector — então RAG é **prematuro** (referência, não adoção). Ver learning `absorption-gated-on-adopter-precondition`.

**Não absorver como dependência nem milestone.** O que segue é *pattern-transfer no produto*, sob demanda.

---

## ✅ Acionável agora (ADAPT no produto — verificado)

| # | Padrão | Produto | Fonte (notebook) | Como aplicar (na nossa stack) |
|---|--------|---------|------------------|-------------------------------|
| 1 | **Extração com âncora de origem** — cada campo extraído carrega o **trecho verbatim** da fonte + um score de confiança | **nfideia** | `structured_generation` | No prompt de extração fiscal (NF-e/DANFE), exigir saída JSON `{campo, valor, fonte_verbatim, confianca}`; permite auditoria humana campo-a-campo. Usa `response_format`/JSON-schema do gateway hospedado — zero dep. |
| 2 | **PII pre-send scrubber** — scrubbers regex ordenados ANTES do egress ao LLM | **cfoai / nfideia** | `llm_gateway_pii_detection` | Função fina no `ai-router.ts` (Deno) que mascara e-mail/telefone/cartão/CPF/CNPJ antes de chamar o provider. Compliance financeiro/fiscal. NÃO adotar o repo Wealthsimple (pesado, stack errada) — só o padrão de scrubber ordenado + auditoria de envio. Cruza com `credential-isolation`. |
| 3 | **Seleção de DDL p/ text-to-SQL** — rankear as definições de tabela vs a pergunta e injetar só o subconjunto relevante (não o schema inteiro) | **cfoai** | `rag_with_sql_reranker` | A *seleção* é portável (heurística ou LLM barato escolhe tabelas); o reranker GPU do notebook NÃO. Reduz tokens e melhora a qualidade do SQL conforme o schema cresce. |

**Transversais (disciplina, baixo esforço):**
- **Rubrica de judge** — escala inteira **ancorada** (1–5, cada ponto descrito), **raciocínio antes da nota**, shuffle anti-viés de posição. Para qualquer eval de qualidade de output de produto. (`llm_judge`, `rag_evaluation`) — distinto do `/doubt` (in-flight) e do `gsd-eval-review` (audita cobertura).
- **Schemas de função "constraint-rich"** — docstring com **enum de valores permitidos** + Args tipados melhora function-calling hospedado. (`agent_text_to_sql`)

---

## 📎 Referência (documentar, **não construir agora**)

- **Semantic cache** (embed query → NN em pgvector → threshold → bypass): forte alavanca de custo, mas **gated** em ter `pgvector` + provider de embeddings. Se um dia: alvo natural é ideiapartner `ai-assistant` (read-mostly).
- **Retrieve-then-rerank**: reranker **hospedado** (Cohere/Voyage/Jina) é Deno-native (`fetch`) — adotar **quando** ideiapartner tiver pipeline de retrieval.
- **Harness de regressão RAG** (eval sintético + 3 critique-agents: groundedness/relevance/standalone): vira fixture de regressão **dentro do produto** que tem RAG (ideiapartner), não skill do OS (o eval é data-bound do produto). O `gsd-eval-review`/`gsd-add-tests` continua o gate no nível OS.
- **Padrão critique-filter** (1 agente por defeito, nota 1–5, dropa abaixo do limiar): enriquecimento futuro p/ `gsd-add-tests`.
- **Rubrica graduada de reward** (multi-eixo, penaliza errado≠ausente): só a disciplina de desenho de rubrica p/ judges.
- **Corpus de prompts de judge**: `quotient-ai/judges` (Apache/MIT) — citar, não depender.
- **Convenção OTel/OpenInference** p/ tracing de chamadas LLM.

---

## ❌ Ignorar (maioria do repo)

Todo fine-tuning/treino/GPU/visão (14+ notebooks: TRL/PEFT/GRPO/DPO/MPO, ViT/DETR/segmentação, Stable Diffusion) · self-host infra (TGI, TEI, Ray Serve, dedicated/serverless endpoints, vLLM) · RAG plumbing acoplado a framework (LangChain/LlamaIndex/Milvus/Mongo/Elastic intro) · orquestração multiagente (já temos AIOX + Workflow + waves) · `unstructured`-partitioning (nfideia é XML de NF-e, não office-docs) · knowledge-graph RAG (Neo4j = infra nova) · data-analyst com code-exec (sem code-exec no Deno) · cleanlab/active-learning · test-time-compute (PRM + GPU).

**Motivo único e recorrente:** exige GPU/treino/self-host **ou** adiciona dependência/infra pesada **ou** já é coberto pelo IdeiaOS — incompatível com Deno-edge + API hospedada + `token-economy`.
