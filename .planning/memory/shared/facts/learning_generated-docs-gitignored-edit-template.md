---
name: learning-generated-docs-gitignored-edit-template
description: "No repo IdeiaOS, IDEIAOS.md e docs/ideiaos/* são GERADOS de source/templates/ideiaos/*.tmpl e gitignored — editar o gerado é local-only e é sobrescrito; edite o TEMPLATE"
metadata: 
  node_type: memory
  type: project
  originSessionId: 20e5c7f1-a79a-433a-a0d4-5b4988cd533a
---

No repo **IdeiaOS**, vários docs existem no working tree mas são **artefatos gerados e gitignored** — editá-los diretamente é trabalho perdido (local-only, e o próximo `setup.sh` os sobrescreve).

**Gitignored + gerados:** `IDEIAOS.md` (raiz, `.gitignore:13`), `docs/ideiaos/` inteiro (`.gitignore:15`), `.security/policy.sh` (`.gitignore:66`). A fonte versionada está em `source/templates/ideiaos/{IDEIAOS,GUIDE-HUMANS,GUIDE-AI,DECISION-MATRIX}.md.tmpl`; o `setup.sh` (§ ~467-480) renderiza os templates para cada projeto.

**Why:** os arquivos existem no disco com conteúdo, então a IA assume que editá-los persiste — mas `git status` os ignora e o autosync nunca os versiona; numa outra máquina some. Editei GUIDE-HUMANS/GUIDE-AI/IDEIAOS gerados antes de perceber (verify-don't-assume pegou via `git check-ignore`).

**How to apply:** antes de editar um doc do IdeiaOS, rode `git check-ignore -v <arquivo>`. Se ignorado → encontre o template em `source/templates/` e edite LÁ. O `README.md` da raiz É tracked (porta de entrada) — esse pode editar direto. Para um doc NOVO de análise/decisão, crie em `docs/` (raiz, tracked) ou `docs/decisions/`, NUNCA em `docs/ideiaos/`. Cross-link [[learning-uncommitted-security-config-ephemeral]] (mesma família: mudança que regride em silêncio por não estar versionada).
