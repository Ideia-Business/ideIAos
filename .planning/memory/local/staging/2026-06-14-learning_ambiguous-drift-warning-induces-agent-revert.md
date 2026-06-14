---
name: learning-ambiguous-drift-warning-induces-agent-revert
description: "Aviso de diagnóstico ambíguo (\"X ≠ Y — corrija se intencional\") induz agente de IA a \"corrigir\" na direção errada — mensagens devem ser direcionais"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d8431dac-280c-4f04-b727-c463ba247aa7
---

Um aviso de drift que só constata divergência sem dizer qual lado está errado convoca o leitor (agente de IA inclusive) a decidir por heurística — e na presença de armadilha semântica, ele reverte com confiança achando que corrige (caso real: commit `3724ee9` no IdeiaOS, agente Cursor re-pinou GSD para o valor legado após ler "re-pin com --bump se intencional").

**Why:** mensagens de ferramenta funcionam como prompts; agentes agem literalmente sobre elas. Aviso ambíguo + domínio traiçoeiro = ação destrutiva plausível.

**How to apply:** ao escrever warnings em scripts de diagnóstico, diagnosticar a direção quando decidível ("instalado é legado, atualize a máquina, NÃO rode --bump") e, quando não decidível, exigir confirmação humana explicitamente. Complementar a mensagem com barreira ativa (hook/gate) — informar não basta. Ver [[learning-version-reset-migration-semver-trap]].
