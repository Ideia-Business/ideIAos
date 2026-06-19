---
date: 2026-06-18
session_type: security/incident
incident: regressão silenciosa da contenção Lovable MCP (deny 2/5)
commit: n/a
tags: [security, git, persistence, working-tree, pull-only-branch, lovable, deny-rules]
applies_to_projects: [global]
promote_to_vault: true
---

# Config de segurança uncommitted é efêmera — persista onde sobrevive, re-audite de leitura fresca

> O padrão é "regra de segurança que só vive no working tree", não só o caso Lovable MCP.
> Vale para qualquer deny/allow, política, ou config de contenção aplicada mas não persistida.

## Trigger (quando reler isso)

Você aplicou uma config de segurança (deny rules, política de permissão, flag de contenção),
validou que está correta **agora**, mas ainda não a commitou/persistiu — especialmente numa
branch **pull-only** (main sob autosync) ou num working tree que será reusado.

## O padrão (abstrato)

"Validado correto no momento" **não é** "persistido". Uma config que vive só no working tree:

1. Numa branch **pull-only** (ex.: `main` sob autosync, que só faz `git pull` e nunca commita
   main) nunca é gravada — não há escritor que a torne durável.
2. O próximo `git checkout`/`reset`/`clone`/limpeza apaga a mudança não-commitada — e a
   contenção **regride em silêncio**. Sendo segurança, é um gap invisível que reabre sozinho.
3. Uma auditoria que confirma "está aplicado" lendo o **mesmo working tree** que aplicou é
   **confirmação circular** — não prova persistência.

## Evidência (concreta — desta sessão)

- Sessão anterior aplicou `permissions.deny` (19 tools MCP) em 4 produtos e validou `deny=19`
  point-in-time, mas deixou nfideia/cfoai **uncommitted na main** ("autosync protege main dirty").
- Re-auditoria de leitura fresca (`wf_247740a6`, `jq` do disco): **deny=0** em nfideia/cfoai;
  só lapidai+IdeiaOS íntegros (**2/5**). Regressão de segurança silenciosa.
- A auditoria de fechamento anterior dissera "5 alvos íntegros" — refutada (leu o working tree
  transitório).

## Regra prática

1. **Persista onde sobrevive:** branch **auto-pushada** (commit + push — nos produtos Lovable,
   `work`, nunca `main`), OU `settings.local.json` para repo com `.claude/` gitignored (lido
   localmente pelo Claude Code, gitignored = autosync não atropela). Working-tree uncommitted
   NUNCA é mecanismo de persistência.
2. **Re-audite de LEITURA FRESCA**, fora do contexto que escreveu — `jq` do disco, todos os
   alvos, depois de um ciclo.
3. Remediação 2026-06-18: nfideia `e43f35f5` + cfoai `cdfa8d6` (commit na `work`) + ideiapartner
   `settings.local.json` (local) → **5/5** persistido.
