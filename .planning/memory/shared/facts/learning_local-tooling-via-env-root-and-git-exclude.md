---
name: learning-local-tooling-via-env-root-and-git-exclude
description: Como instalar tooling dev por-repo em repos heterogêneos (husky / Lovable-em-main) com ZERO footprint versionado
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 3eb736d7-c52c-4642-8594-9a57f3761e7b
---

Para dar a CADA repo de uma frota heterogênea uma ferramenta de dev local (ex.: um hook de aviso) **sem versionar nada** — necessário quando alguns repos são Lovable em `main` (qualquer arquivo *tracked* commitado em main dispara rebuild) e outros usam husky:

1. **UM engine, env root-override.** Mantenha o script num lugar central (o IdeiaOS) e dê a ele um override de raiz por env (`SECFRESH_ROOT=<repo>`) — o git e o estado passam a apontar pro repo-alvo. Assim o produto não precisa de cópia versionada do script. O hook chama o engine global por caminho absoluto baked-in no install.
2. **`post-commit`, não `pre-commit`.** post-commit roda DEPOIS do commit; o git ignora o exit code → **impossível bloquear** (advisory por construção). pre-commit pode travar — errado p/ "não enrijecer".
3. **`core.hooksPath` é capturado pelo husky.** Um `.git/hooks/post-commit` é **silenciosamente ignorado** quando o repo seta `core.hooksPath=.husky`. SEMPRE resolva `git config --get core.hooksPath` antes de instalar; se relativo (ex. `.husky`), o hook é *tracked* → adicione-o ao `.git/info/exclude`.
4. **`.git/info/exclude` p/ estado local** (ledger, marcador de throttle, hook-em-dir-tracked). É **branch-agnostic** (vence o `.gitignore` per-branch — ver [[git-info-exclude-branch-agnostic-ignore]]) e protege contra o `git add -A` do autosync em branch `work` E contra commit acidental em `main`.

**Why:** entrega tooling por-repo honrando a restrição Lovable-main (commit em main = rebuild) sem PRs pesados nem dirty working trees (ver [[learning-uncommitted-security-config-ephemeral]]). Provado no rollout v13 opção C ([[project-milestone-v13-security-freshness]]): 4 produtos, 0 tracked churn, husky-safe, autosync-safe (não precisou pausar autosync — footprint 100% local).

**How to apply:** valide em sandbox /tmp com os dois regimes (default hooksPath E husky) antes de tocar repos vivos ([[verify-guards-in-sandbox-not-live-repo]]); verifique com `git status --porcelain | grep <artefatos>` = 0.
