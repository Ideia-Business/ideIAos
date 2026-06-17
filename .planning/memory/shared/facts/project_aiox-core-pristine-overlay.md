---
name: project-aiox-core-pristine-overlay
description: "IdeiaOS mantém o .aiox-core vendado PRISTINE — deltas IdeiaOS vão SÓ na cópia instalada via install-global-patches.sh (overlay idempotente), nunca por edição direta dos arquivos versionados do .aiox-core"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2c827553-7be6-4e39-8be2-5d62bdff0604
---

No IdeiaOS, o `.aiox-core/` (framework AIOX vendado) é **tracked no repo mas mantido
PRISTINE** — não se edita `.aiox-core/development/agents/*.md` nem `tasks/*.md` direto.
Os deltas IdeiaOS sobre AIOX/GSD/Claude vão por **overlay idempotente** em
`scripts/install-global-patches.sh`, aplicado na **cópia INSTALADA** (achada por
`find_aiox_core` → `~/dev/.aiox-core` ou `~/Projects/.aiox-core`), não no repo.

**Como confirmei (empiricamente, não estava documentado):** `grep -c "--verification <path>"`
no `.aiox-core/.../agents/qa.md` do repo deu **0** — o delta do Patch 5 NÃO está no repo, só na
cópia instalada. Logo o repo é pristine e o overlay é o caminho.

**Por que importa:** ao adicionar um delta a um agente AIOX (ex.: Patch 14 = `to-prd` no @pm/Morgan)
ou a um skill GSD global (ex.: Patch 15 = nota no `/gsd-debug`), o lar é um **patch novo** no
`install-global-patches.sh` (marker-detection + python3 insertion + re-grep idempotente, modelo
dos Patches 1 e 5) — NÃO editar o `.aiox-core` versionado, NÃO criar uma rule (não alcança a
persona do agente nem o skill global). Custo: a contagem "N patches" tem de sincronizar em
`install-global-patches.sh` + `README.md` + `idea-doctor.sh` (eco de [[declarative-manifest-vs-imperative-list-drift]]).

Skills GSD globais (`~/.claude/skills/gsd-*`) e AIOX-core instalado **não vivem no repo** —
por isso o patch é a única forma versionável de mudá-los, e ele re-aplica se um update upstream
sobrescrever. Validação antifrágil do YAML resultante: `scripts/validate-agent-yaml.sh`
(js-yaml do aiox-core = parser do runtime). Ver [[learning-missing-tool-not-cant-verify]].
