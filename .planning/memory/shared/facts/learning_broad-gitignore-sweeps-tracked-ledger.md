---
name: learning-broad-gitignore-sweeps-tracked-ledger
description: Um arquivo que DEVE ser commitado (ledger cross-máquina) some silenciosamente sob uma regra broad de .gitignore (*.log) — o mecanismo que depende dele falha sem erro
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Um artefato que PRECISA ser versionado pode casar uma regra ampla de `.gitignore`
(ex.: `*.log`, `tmp*`, `*.cache`) e ficar **não-commitável em silêncio** — nenhum
erro, só um `git add` que não pega nada e um commit que sai sem o arquivo.

**Caso real (v11):** o ledger do SOAK gate (`.planning/soak/<m>.log`) é o registro
**cross-máquina** que faz o gate "≥2 máquinas" funcionar. Mas casava o `*.log` do
`.gitignore` → heartbeats de máquinas diferentes NUNCA convergiam → o gate seria
**impossível de satisfazer**, sem nunca acusar erro. Só foi pego porque o commit de
fechamento saiu com 3 arquivos em vez de 4 (o ledger faltou).

**Por quê:** regras broad de ignore (`*.log`) são pensadas para lixo de build/runtime,
mas pegam qualquer arquivo com aquela extensão — inclusive um que é dado durável.

**Como aplicar:**
- Ao criar um arquivo que DEVE ser versionado e compartilhado, rode
  `git check-ignore -v <path>` na hora — não confie em `git add` (que falha mudo).
- Verifique com `git ls-files <path>` (sinal binário: aparece = rastreado) — não com o Read tool.
- Se casar uma regra broad, adicione **negação explícita** (`!.planning/soak/*.log`)
  com um comentário dizendo POR QUE é exceção.
- Vale para qualquer mecanismo cujo estado vive num arquivo de extensão "descartável"
  (ledgers, manifests, fixtures versionadas).
