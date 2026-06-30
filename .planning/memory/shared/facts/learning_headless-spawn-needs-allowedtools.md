---
name: learning-headless-spawn-needs-allowedtools
description: "Spawn headless `claude -p` que escreve exige --allowedTools (senão log 0-byte, agente 'pede permissão'). MAS no loop de instincts isso era só metade: a barreira FATAL era a skill abortar pela própria flag anti-runaway que o hook seta — provado por exit-code (before=0→after=6)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

Um spawn headless (`claude -p "<skill>"` em background, sem terminal) **bloqueia ferramentas que exigem permissão (Bash/Write/Edit) por padrão**. A skill que precisa escrever arquivos **falha em silêncio**: o log fica **0-byte** ou contém o agente "respondendo" algo como *"Autorizo. Prossiga com bash e Write…"* — ele PEDE/narra a permissão em vez de executar.

**Caso real (IdeiaOS):** o loop de instincts produzia **0 `.md` apesar de 2575 observações**. Havia **DUAS barreiras em série**, e diagnosticar só a primeira não destravava nada:
1. **`--allowedTools` faltando** (necessário, não suficiente): spawn headless bloqueia Bash/Write → log 0-byte. Resolvido antes.
2. **A barreira FATAL — a skill abortava pela própria flag anti-runaway do spawn.** O hook spawna `env IDEIAOS_INSTINCT_SPAWN=1 claude -p "/instinct-analyze"`, e a "REGRA INVIOLÁVEL #1 (R4-04)" da skill mandava *encerrar imediatamente se IDEIAOS_INSTINCT_SPAWN setado*. Como o hook SEMPRE seta a flag, a skill abortava na linha 1 — todo spawn, sempre. A flag tinha DOIS papéis conflitantes: conter os hooks observadores (correto: `observe-*.sh` fazem early-exit pela flag) **e** abortar a skill (errado: a skill É a análise, não uma recursão dela).

**Fix:** remover o early-abort da skill. Anti-runaway é responsabilidade dos HOOKS (que já fazem early-exit pela flag), não do consumidor que o spawn quer executar. **Provado por exit-code:** rodar o comando exato do hook (com a flag) após o fix → `before=0 → after=6` instincts, 0 re-spawns, 1 binário claude vivo.

**How to apply:**
- Spawn headless que ESCREVE → `--allowedTools "Read Glob Grep Bash Write Edit"` (least-privilege; nunca `--dangerously-skip-permissions`, que o classifier bloqueia).
- **Anti-padrão a caçar (generalizável):** quando um hook/spawn seta uma env-flag (`*_SPAWN`/`*_GUARD`/`*_LOCK`) E o consumidor que ele invoca aborta por ESSA MESMA flag → o consumidor nunca roda (loop morto silencioso). A flag-guard pertence aos OBSERVADORES (não acumular/re-spawnar), nunca ao EXECUTOR-alvo. Sintoma: log 0-byte/curto + 0 artefatos apesar de matéria-prima abundante; o output do agente diz "bloqueado corretamente pelo guard".
- **Verificação:** não dá para provar em auto mode (bloqueia spawnar child-agent com permissão) — confirme em **sessão interativa real** rodando o comando EXATO do hook (com a flag) e contando os artefatos por exit-code (`test -s`), não pelo Read tool.

Cross-link `mcp-hygiene` (Excessive Agency — capacidade mínima) e [[learning-generated-docs-gitignored-edit-template]].
