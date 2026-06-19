---
name: learning-uncommitted-security-config-ephemeral
description: "Config de segurança (deny rules) deixada uncommitted no working tree é EFÊMERA e regride em silêncio — pior numa branch pull-only (main Lovable); persista onde sobrevive e re-audite de leitura fresca"
metadata:
  node_type: memory
  type: project
  originSessionId: 42c36737-b3a2-418a-95f3-f4ec2664e30c
---

Uma sessão anterior aplicou a contenção Lovable MCP (`permissions.deny` de 19 tools mutantes) no `.claude/settings.json` de 4 produtos e **validou binário deny=19 no momento** — mas deixou nfideia/cfoai **uncommitted na main** (raciocínio: "autosync protege main dirty, não commito em main Lovable"). Uma re-auditoria de leitura fresca (`wf_247740a6`) dias depois achou **deny=0** em nfideia/cfoai e **2/5** alvos íntegros: os blocos não-persistidos **regrediram silenciosamente** (checkout/reset/limpeza do working tree os apagou). Uma regressão de SEGURANÇA invisível.

**Why:** "validado deny=19" point-in-time ≠ persistido. Config que vive só no working tree de uma branch **pull-only** (main sob autosync, que nunca commita main) nunca é gravada — o próximo `git checkout`/`reset`/clone a perde, e o gap reabre sem nenhum sinal. A auditoria de fechamento que disse "5 alvos íntegros" leu o mesmo working tree transitório que aplicou — confirmação circular.

**How to apply:**
1. **Persista a contenção onde ela sobrevive:** numa branch **auto-pushada** (ex.: `work` nos produtos Lovable — commit + push), OU, para repo cujo `.claude/` é gitignored, em `settings.local.json` (o Claude Code lê localmente; gitignored = autosync não atropela). NUNCA confie em working-tree uncommitted como mecanismo de persistência de segurança.
2. **Re-audite de LEITURA FRESCA**, não da sessão que aplicou: `jq '.permissions.deny|length'` lido do disco depois de um ciclo, em todos os alvos. A confirmação tem de vir de fora do contexto que escreveu.
3. Para Lovable: a contenção em `main` é impossível de persistir sem violar "nunca commitar em main" → use branch `work` (auto-pushada) ou `settings.local.json` local. Remediado assim em 2026-06-18 (nfideia `e43f35f5`, cfoai `cdfa8d6` na work; ideiapartner local) → 5/5.

Relacionado: [[autosync-races-ai-git-surgery]] (mesma família de footguns autosync×git), [[project-lovable-mcp-v10-candidate]], [[declarative-manifest-vs-imperative-list-drift]] (capability declarada sem o caminho que a entrega persistente).
