---
name: learning-gate-audits-current-branch-not-other-branch
description: "idea-doctor §7e audita o working-tree da branch EM CHECKOUT — fix de segurança commitado numa branch lateral (sec/) segue FAIL em main até o merge; o FAIL é janela de exposição real, não falso-positivo"
metadata:
  node_type: memory
  type: project
  originSessionId: 0dc39c83-3226-4cda-8042-33b2fb9fe49b
---

O check de contenção Lovable-MCP do `idea-doctor` (§7e) lê `<repo>/.claude/settings.json` (e `settings.local.json`) **direto do filesystem** — o working-tree da branch que está EM CHECKOUT, NÃO um `git show <branch>:...` de branch fixa (`idea-doctor.sh:556-557`; o único `git show` de branch no script é p/ `cockpit`/`planning`, não-relacionado). Consequência: persistir o fix de segurança (deny das 19 tools mutantes `claude_ai_Lovable`) numa branch separada — `sec/lovable-mcp-deny`, criada de main HEAD e pushada, correto pela regra Lovable "nunca commit em main automática" — deixa o gate rodando em `main` em **FAIL (deny=0)** até o PR `sec/→main` ser mergeado. A proteção EXISTE e é durável (verificado: deny=19 em `origin/sec/lovable-mcp-deny` de cfoai e nfideia), mas não na superfície que o gate inspeciona (main, deny=0).

**Janela de exposição (não é falso-positivo):** durante o intervalo entre o push da branch `sec/` e o merge do PR, a `main` fica TRANSITORIAMENTE DESPROTEGIDA — e o `idea-doctor`/`--fleet` corretamente marca FAIL nesses repos. Isso NÃO é ruído: é a janela real de exposição. Trate-a como dívida ABERTA e visível; não declare o item "feito" nem rode SOAK enquanto o doctor mostrar os repos em FAIL por deny=0 em main.

Distinto de [[learning-uncommitted-security-config-ephemeral]]: lá a config era UNCOMMITTED (regride no checkout); aqui está commitada/pushada e durável, só vive numa branch que o gate não inspeciona.

**Why:** "fix commitado e pushado" intuitivamente parece "fix aplicado", mas o auditor só vê a branch corrente — confusão circular fácil quando a regra Lovable força o fix para uma branch lateral. Incidente real que TRAVA DoD de SOAK (que exige `idea_doctor=PASS`). Só a memória nativa é auto-injetada ao vivo, então este gotcha pertence aqui.

**How to apply:** Ao persistir fix de segurança em branch lateral (sec/, work) por causa da regra Lovable: lembre que §7e audita o working-tree da branch EM CHECKOUT. Para o gate passar em main, ou (a) mergeie `sec/→main` de forma controlada (gate humano), ou (b) persista em `.claude/settings.local.json` (gitignored, branch-agnóstico, lido localmente pelo Claude Code). NÃO conclua DoD que exige `idea_doctor=PASS` enquanto o fix estiver só na branch lateral — rode `idea-doctor --json` lendo a branch que será auditada (geralmente main) e confirme deny>=19 ali. Liga a [[feedback-lovable-projects-branch-commit]] e [[learning-stale-autosync-branch-off-main]].
