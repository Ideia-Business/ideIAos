---
name: project-memory-index-regenerated-from-fact-descriptions
description: MEMORY.md é regenerado pelo memory-import de cada description; compactar à mão não persiste
metadata: 
  node_type: memory
  type: project
  originSessionId: 2bc6b4ee-e331-4ec9-ae8f-bed36cd18a66
---

O `MEMORY.md` (índice da memória nativa) é **regenerado por rebuild-from-scan** pelo
`source/hooks/memory-import.sh` (linha ~221-281) em todo SessionStart: para cada arquivo de fato ele
lê `name` + `description` do frontmatter e emite `- [{description}]({arquivo}) — {name}` (linha 271).

**Consequência:** compactar o `MEMORY.md` à mão **NÃO persiste** — o próximo import sobrescreve com a
regeneração. O hook `PostToolUse` que avisa "compacte o MEMORY.md para <17.1KB" induz exatamente essa
armadilha; editar o índice é trabalho fútil. O tamanho vem das `description:` longas dos fatos antigos
(citações entre aspas inteiras).

**Correção durável (escolher uma, é decisão do dono — toca hook crítico de memória):**
1. Encurtar a `description:` dos fatos antigos com aspas longas (a fonte real do inchaço); ou
2. Truncar `label` a ~120 chars no gerador (`memory-import.sh` ~linha 271) — fix sistêmico, 1 lugar,
   propagado via setup, sem tocar 74 fatos.

Para fatos NOVOS: mantenha `description:` curta (1 linha enxuta) — ela É a linha do índice.
Cross-link [[learning-daemon-cwd-fix-needs-whole-file-sweep]] (mesmo princípio: tratar a causa, não
o sintoma).
