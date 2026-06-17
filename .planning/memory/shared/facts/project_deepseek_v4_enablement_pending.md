---
name: project-deepseek-v4-enablement-pending
description: "DeepSeek V4 Pro: decisão TOMADA (2026-06-16) — habilitar nos PRODUTOS (cfoai/nfideia etc.), não no Claude Code; removido do plano IdeiaOS (escopo de produto)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 56442749-ce6e-43bf-8feb-608638b116a2
---

Usuário tem chave da API DeepSeek e quer habilitar **DeepSeek V4 Pro** na AIOX. Pesquisa e investigação de código concluídas em 2026-06-16; usuário pediu para **adiar a execução para outro momento oportuno**.

**Why:** A pergunta "onde habilitar?" tem duas respostas que mudam tudo, e o usuário percebeu (corretamente) que pode haver conflito com o modo do Claude Code. Decisão ainda não tomada.

**Descoberta-chave (não óbvia — evita re-investigação):** `.aiox-ai-config.yaml` e o Claude Code são **dois planos que NÃO se cruzam**.
- **Claude Code (dev-time)** roda em Claude/Opus e **nunca lê** `.aiox-ai-config.yaml`. Os agentes AIOX usados aqui (`@dev`, `aiox-dev`, `/AIOX:agents:*`) são subagentes do Claude Code com `model: opus` no frontmatter — não passam pela factory.
- **`.aiox-ai-config.yaml` (run-time)** só alimenta o runtime Node `ai-provider-factory.js` (em `/Users/gustavolopespaiva/dev/.aiox-core/infrastructure/integrations/ai-providers/`; cópias byte-idênticas em cada projeto). É a config de qual LLM os **produtos** usam em features de IA (routing keys: chat_support, diagnosis, description_generation, vision_analysis).
- **Blocker real:** nenhum código nos projetos chama `executeWithFallback`/`getProviderForTask` hoje (grep vazio em ~/dev). O `subagent-dispatcher.js` por padrão dá `spawn('claude', …)` (`:704`); o ramo DeepSeek (`executeWithProvider`, `:450-451`) só roda sob flag `multiProviderEnabled` + factory carregada. Ou seja: adicionar o bloco DeepSeek **não faz nada** até o código de produto chamar a factory.

**Decisão TOMADA (2026-06-16):** habilitar o DeepSeek **nos produtos** (cfoai-grupori, nfideia etc.) — **NÃO** no Claude Code. **Removido do plano do IdeiaOS (v7)**: é escopo de produto, não do framework. Caminho: editar o `.aiox-ai-config.yaml` do produto + verificar/ligar as chamadas à factory no código do produto. (A opção descartada era rodar o próprio Claude Code em DeepSeek via proxy `ANTHROPIC_BASE_URL`, já que DeepSeek é OpenAI-compatible.)

**How to apply (quando retomar):** confirmar qual dos dois planos. Se produtos: a factory faz dispatch pelo campo `provider:` (não pelo nome do bloco), então um bloco `deepseek:` com `provider: openai-compatible` é genérico, sem mudança de código. Facts verificados (docs oficiais, alta confiança):
- model: `deepseek-v4-pro` (minúsculo-hífen exato; "V4 Pro"/"v4-pro" falham)
- baseURL: `https://api.deepseek.com` (vira `.../chat/completions`); `/v1` opcional
- apiKeyEnv: `DEEPSEEK_API_KEY`; auth `Authorization: Bearer` automático
- legados `deepseek-chat`/`deepseek-reasoner` **aposentam 2026-07-24** — não fixar
- alternativa barata (~3×): `deepseek-v4-flash`
- thinking-mode ligado por padrão; prompts single-turn da AIOX → sem pegadinha de reasoning_content
- campos `bulk`/`feature_flag_env`/`fallback_to` no YAML **não são lidos** por esta versão do runtime; só `primary`/`fallback`/`routing` valem.

Bloco pronto + fiação recomendada estão na conversa de 2026-06-16. Relacionado: [[project_obsidian_vault_completo]].
