---
name: project-cfoai-particular
description: cfoai-grupori é projeto PARTICULAR do Gustavo — não incluir em artefatos de onboarding/compartilhamento com devs
metadata: 
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

**`cfoai-grupori` é um projeto PARTICULAR do Gustavo** — outros devs (ex: Lucas) **não têm acesso** a ele no GitHub.

Portanto, **NÃO** incluir cfoai-grupori em nenhum artefato de **onboarding/compartilhamento com devs**: guias de instalação (`INSTALL-WINDOWS.md`, `docs/guides/windows-wsl.md`, `onboarding-novo-dev.md`), loops de `git clone`, write-checks (`gh api repos/...`), lista de repos do autosync, templates de `.env` (`docs/guides/env-setup-dev.md`), e o array `PROJECTS` de `scripts/export-env-dev.sh`. Clonar/checar cfoai falharia para um dev sem acesso.

**Projetos compartilháveis com devs:** `lapidai`, `nfideia`, `ideiapartner` (+ `IdeiaOS`, o framework).

cfoai-grupori **permanece** legitimamente no `setup-dev-machine.sh` (array `REPOS`) e no autosync da **máquina primária do Gustavo** — lá ele trabalha no projeto. O `onboarding §3` tem nota avisando que um dev novo deve editar o `REPOS` removendo repos sem acesso.

**Why:** sinalizado pelo usuário em 2026-06-25 ("já tinha definido que cfoai é particular, não deve ser listado para outros devs"). **How to apply:** ao adicionar um projeto a qualquer artefato de dev novo, confirmar que NÃO é cfoai-grupori (nem outro projeto particular futuro). Cross-link [[project-multi-os-install-architecture]].
