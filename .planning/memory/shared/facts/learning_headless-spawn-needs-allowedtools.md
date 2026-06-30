---
name: learning-headless-spawn-needs-allowedtools
description: "Um spawn headless `claude -p` bloqueia Bash/Write por padrão e não escreve nada (log 0-byte) — automação que precisa escrever exige --allowedTools; o agente \"responde pedindo permissão\" em vez de agir"
metadata: 
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

Um spawn headless (`claude -p "<skill>"` em background, sem terminal) **bloqueia ferramentas que exigem permissão (Bash/Write/Edit) por padrão**. A skill que precisa escrever arquivos **falha em silêncio**: o log fica **0-byte** ou contém o agente "respondendo" algo como *"Autorizo. Prossiga com bash e Write…"* — ele PEDE/narra a permissão em vez de executar.

**Caso real (IdeiaOS):** o loop de instincts produzia **0 `.md` apesar de 2495+ observações**. Causa-raiz NÃO era timeout — era `observe-session-end.sh`/`instinct-recover.sh` spawnando `claude -p "/instinct-analyze"` **sem flag de permissão**. Sintoma diagnóstico: log do spawn 0-byte + breadcrumbs presos em `status=running` com pid morto.

**How to apply:** para um spawn headless que ESCREVE, conceda permissão. Prefira **least-privilege** `--allowedTools "Read Glob Grep Bash Write Edit"` (só o que a tarefa exige) a `--dangerously-skip-permissions` (desarma tudo — o classifier do harness bloqueia, com razão). Mantenha salvaguardas: env-guard anti-runaway, `timeout`, escopo de escrita restrito, modelo barato. **Verificação:** não dá para provar em auto mode (bloqueia spawnar child-agent com permissão) — confirme em sessão interativa real. Cross-link `mcp-hygiene` (Excessive Agency — capacidade mínima) e [[learning-generated-docs-gitignored-edit-template]].
