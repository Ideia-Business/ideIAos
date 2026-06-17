---
name: declarative-manifest-vs-imperative-list-drift
description: "Quando uma fonte declarativa (manifesto) e uma lista imperativa (array de build) precisam concordar, só um gate que as CRUZA pega a deriva — check de existência não basta"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**Por quê:** No IdeiaOS, `manifests/modules.json` declara `plugin:` por módulo, mas o `build-plugins.sh` decide o que empacotar via arrays **hardcoded** (`CORE_SKILLS` etc.). As duas fontes derivaram em silêncio: `spec`/`forge-agent` (v6) e `memory-sync` (v5) estavam `plugin:ideiaos-core` no manifesto mas **fora** dos arrays → nunca eram empacotados; o fix do `/spec` não chegava às máquinas via marketplace. O guard que existia (`validate_exists`) só checava se o arquivo existia, **não** a membership. O drift-guard novo (`check-plugin-membership.sh`) ainda achou 2 a mais na estreia (`memory-import`/`export`, que são patch-installed → corrigidos para `plugin:null`). **Variante (v8/R8-09):** a rule `operating-discipline` declarava `targets: [claude, cursor]` no manifesto, mas o `build-adapters.sh` só tinha código de deploy para o Cursor — o alvo `claude` era uma **declaração sem implementação**. O dogfood doubt-driven pegou; fix: `build_claude_project_rules()`.

**How to apply:** Toda vez que houver **"duas listas que precisam bater"** — config declarativa × código imperativo, manifesto × array, schema × seed, allowlist × roteador — o drift é **invisível** sem um gate que as cruza explicitamente. Crie um check binário bidirecional (cada item de A está em B e vice-versa) e ligue no pre-commit + doctor. Um check de "existe o arquivo?" não detecta "está na lista certa?". Um campo de metadados que **declara um alvo/capability** (`targets:`, `plugin:`) é uma promessa, não uma garantia — confirme que existe código que de fato entrega cada alvo declarado. Generaliza além do IdeiaOS. Pareia com [[learning_version-reset-migration-semver-trap]] e [[dogfood-review-tool-catches-own-defect]].
