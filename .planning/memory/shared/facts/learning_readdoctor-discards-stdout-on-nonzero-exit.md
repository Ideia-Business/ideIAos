---
name: learning-readdoctor-discards-stdout-on-nonzero-exit
description: Coletor que roda uma ferramenta via execSync perde o stdout VÁLIDO quando a ferramenta sai non-zero (estado normal em gates) — e um timeout curto mascara o bug
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

O `readDoctor()` do agentd do Cockpit (IdeiaOS) **nunca coletava o doctor quando havia
qualquer FAIL** — o snapshot vinha `doctor.exit=-1`/`sections=[]` (status vazio honesto, mas
inútil). Dois bugs sobrepostos, que só apareceram quando a re-coleta foi exercitada com FAILs reais:

1. **Timeout curto mascara:** `idea-doctor --json` leva ~16s (todos os checks); o `safeExec`
   default era 10s → `ETIMEDOUT`. Isso escondia o bug nº2 (parecia "lento", não "exit-code").
2. **A causa-raiz real:** `idea-doctor --json` **sai exit 1 quando há FAIL** — que é o estado
   NORMAL de um gate de saúde. O `execSync` do Node trata qualquer exit non-zero como exceção e
   **descarta o stdout válido** (o JSON estava lá, perfeito). O coletor caía no `catch` → fallback vazio.

**Fix:** `safeExec('… --json 2>/dev/null || true', { timeout: 60000 })` — o `|| true` força o
shell a sair 0 preservando o stdout (o exit REAL vem em `JSON.summary.exit`); 60s cobre os 16s.

**Why:** o bug nº1 (timeout) é um falso-culpado que mascara o nº2 (exit-code). Um gate/ferramenta
que reporta saúde por exit-code SEMPRE sairá non-zero no caso que mais importa (quando há
problema) — e é exatamente aí que o coletor o descartava. O dado mais valioso (o FAIL) era o
único que nunca era coletado.

**How to apply:** ao coletar a saída de uma ferramenta-de-gate via `execSync`/`spawnSync`, NUNCA
confie no exit-code para decidir se há output — capture o stdout independente do exit (`|| true`,
ou `e.stdout` no catch) e leia o veredito de DENTRO do payload. E dimensione o timeout ao tempo
REAL da ferramenta (cronometre), senão um ETIMEDOUT mascara o bug verdadeiro. Cross-link
[[learning-aggregator-status-from-verdict-not-absence]] (derive status do veredito explícito, não
da ausência de sinal) e [[antitheater-gate-blind-spot-happy-path]] (exercite o caminho com FAIL real).
