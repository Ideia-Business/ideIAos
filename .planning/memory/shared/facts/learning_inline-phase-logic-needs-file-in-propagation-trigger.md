---
name: learning-inline-phase-logic-needs-file-in-propagation-trigger
description: "Lógica de uma FASE que vive DENTRO do orquestrador (ex.: fase global do setup.sh), não em source/, NÃO propaga se o gatilho de propagação cataloga só os paths de source/ — o próprio arquivo do orquestrador precisa estar no array do gatilho daquela fase, senão muda local mas a frota não recebe"
metadata:
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

No IdeiaOS a propagação (`scripts/propagate-if-changed.sh`) decide o que re-rodar na frota por **path-prefix** do diff: `GLOBAL_PATHS` → `setup.sh --global-only` + `install-global-patches.sh`; `PROJECT_PATHS` → `apply-to-all-projects.sh` → `setup.sh --project-only`. O `setup.sh` contém **duas fases** num arquivo só: a **global** (steps 2–6.x: skills/MCPs/hooks/Deno) e a **de projeto**. Ele estava catalogado **só em `PROJECT_PATHS`**.

**O furo (2026-06-30):** ao cabear o instalador do Deno no **step 6.3 da FASE GLOBAL** do `setup.sh`, a mudança propagava errado — a propagação via `setup.sh` disparava só `--project-only`, que **PULA a fase global**. O branch global (`--global-only`, onde o step 6.3 roda) só dispara quando um `GLOBAL_PATH` muda; mas a fase global vive **dentro do `setup.sh`**, não em `source/`, então **nenhum global-path a representava**. Logo o fix só chegaria à frota se **outra** mudança global "pegasse carona" no mesmo range de propagação — não-determinístico.

**Fix:** adicionar `setup.sh` também a `GLOBAL_PATHS` (mantendo em `PROJECT_PATHS`). Matching provado por exit-code: `setup.sh` casa o global; `setup-dev-machine.sh` NÃO casa (sem falso-positivo, pois começa com `setup-`, não `setup.sh`); `source/skills/` sem regressão.

**Why:** o gatilho de propagação assume implicitamente que o CONTEÚDO de cada fase vive nos paths de `source/`. Quando há lógica de fase **inline no orquestrador** (não num arquivo de `source/`), o gatilho não a "vê" — o orquestrador muda, mas o array de paths daquela fase não inclui o próprio orquestrador.

**How to apply:**
- Ao adicionar lógica de **fase global** dentro do `setup.sh` (ou de qualquer orquestrador), confirme que o **arquivo do orquestrador** está no array do gatilho **daquela fase** — não só na fase cujo nome bate com "onde o arquivo costuma ser editado".
- Regra de bolso: *o gatilho de propagação dispara pelo PATH que mudou; se a lógica nova não tem um path de `source/` que a represente, o path do arquivo que a contém precisa estar no array da fase certa.*
- Verifique o roteamento por exit-code com a própria função de matching (`matches_prefix`) contra o array real — não assuma; cheque o falso-positivo de prefixo (`setup.sh*` vs `setup-dev-machine.sh`).

Mesma família de [[learning-global-skill-deploy-version-gated-misses-lib-changes]] (gatilho de deploy perde mudanças que não casam seu critério) e [[learning-declarative-manifest-vs-imperative-list-drift]] (duas fontes que precisam concordar). Incidente concreto: [[reference-deno-install-local-bin]].
