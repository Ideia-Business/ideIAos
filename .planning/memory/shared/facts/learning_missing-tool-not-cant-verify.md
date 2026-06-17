---
name: learning-missing-tool-not-cant-verify
description: "'Ferramenta X ausente' ≠ 'não dá pra verificar' — probe por equivalentes antes de declarar gap; e para YAML de agente AIOX, valide com o parser AUTORITATIVO (js-yaml do aiox-core), não PyYAML"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

Ao validar o bloco YAML de `pm.md` (Patch 14, v9 Fase G), declarei um gap de
verificação porque `import yaml` (PyYAML) não estava instalado. Era um falso
gap: o ambiente tinha **ruby 2.6 (psych/YAML stdlib)** E **node + `js-yaml` em
`.aiox-core/node_modules/`** o tempo todo.

**Why:** equiparar "minha ferramenta preferida está ausente" a "não consigo
verificar" é um modo de falha de verificação — viola o princípio antifragile-gates
(verificação binária, não Read tool). Quase sempre há um equivalente já instalado.
Pior: PyYAML nem seria o parser certo — quem carrega esses arquivos de agente em
runtime é o `js-yaml` do AIOX. Validar com o parser AUTORITATIVO (o mesmo do
runtime) é mais forte que validar com qualquer outro.

**How to apply:**
1. Antes de dizer "não consegui verificar X", faça um probe rápido de
   alternativas: `ruby -ryaml`, `node -e require("js-yaml")`, `yq`, `python3 -c
   "import yaml"`. Em macOS, ruby/psych quase sempre existe.
2. Para artefatos de um framework (YAML de agente AIOX, JSON de schema etc.),
   prefira o parser que o PRÓPRIO framework usa — aqui, `js-yaml` de
   `.aiox-core/node_modules/`. Cross-check com um segundo parser independente
   (ruby) aumenta a confiança.
3. Ruby 2.6 com `-e` lê o source como US-ASCII: evite literais multibyte no
   script (`-E UTF-8` + `File.read(path, encoding:"UTF-8")`, e compare por
   substring ASCII-only).

Cross-link: [[learning_declarative-manifest-vs-imperative-list-drift]] (também
sobre fechar pontos cegos de verificação), e o princípio "Verify, don't assume"
de `ideiaos-common-operating-discipline.md`.
