---
name: learning-gitignore-third-party-verbatim-snapshot
description: Mecanismo que snapshota conteúdo de terceiro p/ diff deve GITIGNORAR a cópia verbatim quando a fonte é sem-licença — committar = redistribuição silenciosa sem licença
metadata:
  node_type: memory
  type: feedback
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Um mecanismo que **snapshota conteúdo de terceiro** para detectar mudanças (diff
mês-a-mês, baseline de drift, cache de README upstream) tende a querer **versionar o
snapshot** para compartilhá-lo entre máquinas. Mas se a fonte é **all-rights-reserved
(repo sem LICENSE)**, committar a cópia VERBATIM no seu repo é **redistribuição sem
licença** — pior se o repo for público.

**Caso real (v12, refresh-ai-security):** o mecanismo de auto-update mensal do
`muellerberndt/awesome-ai-security` (repo **SEM LICENÇA**) ia committar
`security/intel/awesome-ai-security.snapshot.md` (o README inteiro, verbatim) como
"baseline cross-máquina". A própria spec dizia "snapshot versionado (committed)". Pego
no `git status` antes do commit: o snapshot é prosa de terceiro all-rights-reserved.

**Resolução:** `gitignore` o snapshot + os reports (cópia verbatim) → baseline **LOCAL
por máquina**. O benefício "cross-máquina" cede à conformidade de licença. A detecção de
mudança continua funcionando por máquina (cada uma bootstrapa seu baseline). Os **FATOS
acionáveis** (não a prosa) já vivem na nossa própria distilação (`SECURITY-KNOWLEDGE.md`,
versionada, citando a fonte primária).

**Como aplicar:**
- Antes de committar qualquer artefato derivado de terceiro, pergunte: isto é **cópia
  verbatim** de algo com **licença restritiva ou ausente**? Se sim, **gitignore** —
  só versione a SUA síntese (fatos não-copyrightáveis) com citação da fonte primária.
- Verifique a licença da fonte **autoritativamente**: `gh api repos/<o>/<r> --jq
  .license.spdx_id` (`null`/`NONE` = all-rights-reserved). NUNCA confie em alegação de
  LLM (no v12 um agente alucinou "Hercules=Apache-2.0"; a API confirmou **AGPL-3.0**).
- Um hash (sha256) do conteúdo NÃO é copyrightável — pode versionar como sinal de
  "mudou?" se precisar de cross-máquina sem redistribuir a prosa.
- Mesma família de [[learning-broad-gitignore-sweeps-tracked-ledger]] (gitignore vs o
  que deve/não-deve ser versionado), mas invertida: aqui o problema é committar demais.
